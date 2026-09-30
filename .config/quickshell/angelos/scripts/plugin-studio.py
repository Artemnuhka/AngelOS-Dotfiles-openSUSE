#!/usr/bin/env python3
"""Plugin Studio worker. One JSON request on stdin; JSON events on stdout.

No generated code is executed by this worker. API credentials never travel in
argv or the generation context. Python standard library only.
"""
import ast
import fcntl
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]
MAX_BYTES = 512 * 1024
MAX_FILES = 24
ID_RE = re.compile(r"[a-z][a-z0-9-]{1,47}\Z")
EXTENSIONS = {".qml", ".js", ".json", ".py", ".sh", ".md", ".txt", ".svg"}
ENTRYPOINTS = ("main", "settings", "desktopWidget", "barWidget", "menuComponent", "launcher", "sidebarWidget")
API_PROVIDERS = ("openai", "anthropic")
# "Sign in with the browser": the local Claude Code / Codex CLIs, logged in with a
# Claude or ChatGPT account. angelOS never sees their credentials.
CLI_PROVIDERS = ("claude-cli", "codex-cli")
CODEX_DISABLE = ("shell_tool", "computer_use", "browser_use", "browser_use_external", "apps")
EFFORTS = ("low", "medium", "high", "xhigh", "max", "ultra")
# how long one request may take, by reasoning level (seconds)
EFFORT_TIMEOUT = {"": 900, "low": 420, "medium": 720, "high": 1080, "xhigh": 1500, "max": 2100, "ultra": 2400}
MAX_REPAIRS = 2
# Claude Code accepts model aliases; effort levels per `claude --help`
CLAUDE_CLI_MODELS = [
    {"id": "", "label": "CLI default", "efforts": ["low", "medium", "high", "xhigh", "max"], "default": ""},
    {"id": "haiku", "label": "Haiku", "efforts": [], "default": "", "speed": "fast"},
    {"id": "sonnet", "label": "Sonnet", "efforts": ["low", "medium", "high", "xhigh", "max"], "default": "medium", "speed": "balanced"},
    {"id": "opus", "label": "Opus", "efforts": ["low", "medium", "high", "xhigh", "max"], "default": "medium", "speed": "smart"},
    {"id": "fable", "label": "Fable", "efforts": ["low", "medium", "high", "xhigh", "max"], "default": "low", "speed": "deep"},
]
ANTHROPIC_MODELS = [
    {"id": "claude-haiku-4-5", "label": "Claude Haiku 4.5", "efforts": [], "default": "", "speed": "fast"},
    {"id": "claude-sonnet-5-5", "label": "Claude Sonnet 5.5", "efforts": ["low", "medium", "high", "xhigh", "max"], "default": "medium", "speed": "balanced"},
    {"id": "claude-opus-5-5", "label": "Claude Opus 5.5", "efforts": ["low", "medium", "high", "xhigh", "max"], "default": "medium", "speed": "smart"},
    {"id": "claude-fable-5-1", "label": "Claude Fable 5.1", "efforts": ["low", "medium", "high", "xhigh", "max"], "default": "low", "speed": "deep"},
]
# models that get the server-side refusal fallback
ANTHROPIC_FALLBACK = ("claude-fable-5-1", "claude-opus-5-5", "claude-opus-5", "claude-sonnet-5-5")
OPENAI_MODELS = [
    {"id": "gpt-5.4-mini", "label": "GPT-5.4 mini", "efforts": ["low", "medium", "high"], "default": "low", "speed": "fast"},
    {"id": "gpt-5.4", "label": "GPT-5.4", "efforts": ["low", "medium", "high", "xhigh"], "default": "medium", "speed": "balanced"},
    {"id": "gpt-5.5", "label": "GPT-5.5", "efforts": ["low", "medium", "high", "xhigh"], "default": "medium", "speed": "smart"},
]


class StudioError(Exception):
    def __init__(self, en, ru=None):
        super().__init__(en)
        self.en, self.ru = en, ru or en


def obj(**properties):
    return {"type": "object", "properties": properties,
            "required": list(properties), "additionalProperties": False}


STRING = {"type": "string"}
STRINGS = {"type": "array", "items": STRING}
SPEC = obj(id=STRING, name=STRING, description=STRING,
           kind={"type": "string", "enum": ["desktop", "bar", "service", "menu", "launcher"]},
           widthUnits={"type": "integer"}, heightUnits={"type": "integer"},
           behavior=STRING, dataSources=STRINGS, settings=STRINGS,
           dependencies=STRINGS, limitations=STRINGS)
PLAN = obj(summary=STRING, questions={"type": "array", "items": obj(question=STRING, options=STRINGS)},
           spec=SPEC)
BUNDLE = obj(summary=STRING, notes=STRINGS,
             files={"type": "array", "items": obj(path=STRING, content=STRING)})


def check_schema(value, schema):
    """Validate the small, shared schema subset without a package dependency."""
    kind = schema["type"]
    types = {"object": dict, "array": list, "string": str, "integer": int}
    if type(value) is not types[kind]:
        raise StudioError("Unexpected response format.", "Неожиданный формат ответа ИИ.")
    if "enum" in schema and value not in schema["enum"]:
        raise StudioError("Unsupported plugin kind.", "Неизвестный тип плагина.")
    if kind == "object":
        if set(value) != set(schema["properties"]):
            raise StudioError("Incomplete response. Try again.", "Ответ неполный. Попробуйте снова.")
        for key, child in schema["properties"].items():
            check_schema(value[key], child)
    elif kind == "array":
        for item in value:
            check_schema(item, schema["items"])


def private_dir(path):
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    if path.is_symlink() or not path.is_dir():
        raise StudioError("Studio directory must not be a symlink.")
    path.chmod(0o700)


def read_json(path, default=None):
    if not path.exists():
        return default
    if path.is_symlink() or not path.is_file() or path.stat().st_size > 4 * MAX_BYTES:
        raise StudioError("Invalid Studio state file.")
    try:
        return json.loads(path.read_text())
    except (ValueError, UnicodeError):
        raise StudioError("Studio state is unreadable. Start a new project.",
                          "Не удалось прочитать проект. Создайте новый.")


def write_json(path, value):
    private_dir(path.parent)
    fd, tmp = tempfile.mkstemp(prefix=".write-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(value, stream, ensure_ascii=False)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def provider_request(provider, model, key, system, messages, schema, tokens, effort=""):
    headers = {"Content-Type": "application/json", "User-Agent": "angelOS-PluginStudio/1"}
    if provider == "openai":
        url = "https://api.openai.com/v1/responses"
        headers["Authorization"] = "Bearer " + key
        body = {"model": model, "instructions": system, "input": messages,
                "max_output_tokens": tokens, "store": False,
                "text": {"format": {"type": "json_schema", "name": "angelos_plugin",
                                    "strict": True, "schema": schema}}}
        if effort:
            body["reasoning"] = {"effort": effort}
    elif provider == "anthropic":
        url = "https://api.anthropic.com/v1/messages"
        headers.update({"x-api-key": key, "anthropic-version": "2023-06-01"})
        output = {"format": {"type": "json_schema", "schema": schema}}
        # effort sets how deeply current models think (Haiku 4.5 does not take it)
        if effort and not model.startswith("claude-haiku"):
            output["effort"] = effort
        body = {"model": model, "system": system, "messages": messages, "max_tokens": tokens,
                "output_config": output}
        if model in ANTHROPIC_FALLBACK:
            # a declined request is retried by the API on a suitable model instead of failing
            headers["anthropic-beta"] = "server-side-fallback-2026-07-01"
            body["fallbacks"] = "default"
    else:
        raise StudioError("Unknown provider.", "Неизвестный провайдер.")
    return urllib.request.Request(url, data=json.dumps(body).encode(), headers=headers)


def parse_response(provider, data):
    if provider == "openai":
        if data.get("status") != "completed":
            raise StudioError("Response incomplete. Increase the output limit or simplify the plugin.",
                              "Ответ не завершён. Увеличьте лимит ответа или упростите плагин.")
        blocks = [b for item in data.get("output", []) if item.get("type") == "message"
                  for b in item.get("content", [])]
        if any(b.get("type") == "refusal" for b in blocks):
            raise StudioError("The provider declined this request.", "Провайдер отклонил запрос.")
        text = "".join(b.get("text", "") for b in blocks if b.get("type") == "output_text")
    else:
        if data.get("stop_reason") == "refusal":
            raise StudioError("The model declined this request. Rephrase the idea or pick another model.",
                              "Модель отказалась выполнять запрос. Переформулируйте идею или выберите другую модель.")
        if data.get("stop_reason") == "max_tokens":
            raise StudioError("The answer hit the output limit. Raise the limit or lower the reasoning level.",
                              "Ответ упёрся в лимит токенов. Увеличьте лимит или снизьте уровень рассуждений.")
        if data.get("stop_reason") != "end_turn":
            raise StudioError("Response incomplete or declined. Check the output limit.",
                              "Ответ неполный или отклонён. Проверьте лимит ответа.")
        text = "".join(b.get("text", "") for b in data.get("content", []) if b.get("type") == "text")
    try:
        return json.loads(text), data.get("usage", {})
    except (ValueError, TypeError):
        raise StudioError("The provider did not return valid JSON. Try again.",
                          "Провайдер вернул некорректный JSON. Повторите запрос.")


def call_provider(request, provider, timeout=600):
    try:
        with urllib.request.build_opener(NoRedirect()).open(request, timeout=timeout) as response:
            raw = response.read(4 * MAX_BYTES + 1)
        if len(raw) > 4 * MAX_BYTES:
            raise StudioError("Provider response is too large.", "Ответ провайдера слишком большой.")
        return parse_response(provider, json.loads(raw))
    except urllib.error.HTTPError as error:
        # Do not echo response bodies: providers can include submitted secrets.
        descriptions = {
            400: ("Model or request unsupported. Check the model supports structured output.",
                  "Модель или запрос не поддерживается. Нужна модель со structured output."),
            401: ("API key rejected.", "API-ключ отклонён."),
            403: ("API access denied for this key or region.", "Доступ к API для ключа или региона запрещён."),
            404: ("Model unavailable. Check its API identifier.", "Модель недоступна. Проверьте её API ID."),
            429: ("API quota or rate limit reached. Check API billing and retry later.",
                  "Достигнут лимит API. Проверьте баланс API и повторите позже."),
        }
        en, ru = descriptions.get(error.code, ("Provider unavailable. Try later.", "Провайдер недоступен. Попробуйте позже."))
        error.close()
        raise StudioError(f"HTTP {error.code}: {en}", f"HTTP {error.code}: {ru}")
    except (urllib.error.URLError, TimeoutError, OSError):
        raise StudioError("Connection failed or timed out. Check your network.",
                          "Ошибка соединения или тайм-аут. Проверьте сеть.")
    except (ValueError, KeyError, TypeError):
        raise StudioError("Invalid provider response.", "Некорректный ответ провайдера.")


def cli_path(name):
    """The CLI from PATH or ~/.local/bin (Quickshell may start with a short PATH)."""
    found = shutil.which(name)
    if found:
        return found
    local = Path.home() / ".local/bin" / name
    return str(local) if os.access(local, os.X_OK) else None


def cli_status():
    """Installed + logged-in state of both CLIs. Only the login *method* is kept."""
    status = {}
    claude = cli_path("claude")
    entry = {"installed": bool(claude), "loggedIn": False, "method": ""}
    if claude:
        try:
            out = subprocess.run([claude, "auth", "status"], capture_output=True, text=True, timeout=20)
            data = json.loads(out.stdout or "{}")
            entry["loggedIn"] = bool(data.get("loggedIn"))
            entry["method"] = str(data.get("authMethod") or "")
        except (OSError, ValueError, subprocess.TimeoutExpired):
            pass
    status["claude-cli"] = entry
    codex = cli_path("codex")
    entry = {"installed": bool(codex), "loggedIn": False, "method": ""}
    if codex:
        try:
            out = subprocess.run([codex, "login", "status"], capture_output=True, text=True, timeout=20)
            text = (out.stdout + out.stderr).lower()
            entry["loggedIn"] = out.returncode == 0 and "not logged in" not in text
            entry["method"] = "chatgpt" if "chatgpt" in text else "apikey" if "api key" in text else ""
        except (OSError, subprocess.TimeoutExpired):
            pass
    status["codex-cli"] = entry
    return status


def codex_models():
    """Models and reasoning levels the local Codex CLI offers (its own catalog)."""
    import tomllib
    home = Path.home() / ".codex"
    config = {}
    try:
        config = tomllib.loads((home / "config.toml").read_text())
    except (OSError, ValueError):
        pass
    sources = [config.get("model_catalog_json"), home / "models_cache.json"]
    items = []
    for src in sources:
        if not src:
            continue
        try:
            data = json.loads(Path(src).expanduser().read_text())
        except (OSError, ValueError):
            continue
        rows = data.get("models", data) if isinstance(data, dict) else data
        for m in rows if isinstance(rows, list) else []:
            if not isinstance(m, dict) or not (m.get("slug") or m.get("id")):
                continue
            levels = m.get("supported_reasoning_levels") or []
            levels = [x.get("effort") if isinstance(x, dict) else x for x in levels]
            items.append({"id": str(m.get("slug") or m.get("id")), "label": str(m.get("display_name") or m.get("slug")),
                          "efforts": [x for x in levels if x in EFFORTS],
                          "default": m.get("default_reasoning_level") if m.get("default_reasoning_level") in EFFORTS else ""})
        if items:
            break
    default = {"id": "", "label": "CLI default" + (" (" + str(config["model"]) + ")" if config.get("model") else ""),
               "efforts": ["low", "medium", "high", "xhigh"], "default": ""}
    return [default] + items[:40], str(config.get("model_reasoning_effort") or "")


def models_catalog():
    codex, codex_effort = codex_models()
    return {"claude-cli": CLAUDE_CLI_MODELS, "codex-cli": codex, "anthropic": ANTHROPIC_MODELS,
            "openai": OPENAI_MODELS, "codexDefaultEffort": codex_effort}


# ---------- what generated code can use, taken from the current sources ----------
DECL_RE = re.compile(r"^    (?:readonly |required |default )*(property\s+\S+\s+\w+|signal\s+\w+(?:\([^)]*\))?|function\s+\w+\([^)]*\))")


def qml_api(path, limit=40):
    """Top-level declarations of a QML file: its public API."""
    out = []
    try:
        lines = path.read_text().splitlines()
    except OSError:
        return out
    doc = next((l.strip("/ ").strip() for l in lines[:12] if l.startswith("//")), "")
    for line in lines:
        m = DECL_RE.match(line)
        if m and not re.search(r"\b_\w", m.group(1)):
            out.append(re.sub(r"\s+", " ", m.group(1)))
    return doc, out[:limit]


def api_reference():
    parts = ["API REFERENCE (generated from the installed angelOS sources; use only what is listed here or in the documents)"]
    parts.append("\n## qs.widgets")
    for f in sorted((ROOT / "widgets").glob("*.qml")):
        doc, decls = qml_api(f, 25)
        parts.append(f"- {f.stem}: {doc}\n    " + "; ".join(decls))
    theme = (ROOT / "config/Theme.qml").read_text()
    props = sorted(set(re.findall(r"^    readonly property \w+ (\w+)", theme, re.M)))
    funcs = sorted(set(re.findall(r"^    function (\w+\([^)]*\))", theme, re.M)))
    parts.append("\n## qs.config Theme (singleton)\nproperties: " + ", ".join(p for p in props if not p.startswith("_"))
                 + "\nfunctions: " + ", ".join(funcs))
    parts.append("## qs.config I18n (singleton): I18n.t(ru, en) returns the string for the UI language; I18n.label(stringOrObject)")
    icons = re.findall(r"^    (\w+): \[", (ROOT / "widgets/Icons.js").read_text(), re.M)
    parts.append("## PxIcon names (name: \"…\"): " + ", ".join(icons))
    parts.append("\n## qs.services (singletons; the most useful ones)")
    for name in ("SystemInfo", "Audio", "Niri", "Shell", "Notifs", "Plugins", "DesktopWidgets", "Lyrics", "Wifi", "Bt", "Clipboard", "Capture"):
        f = ROOT / "services" / (name + ".qml")
        if f.exists():
            doc, decls = qml_api(f, 30)
            parts.append(f"- {name}: {doc}\n    " + "; ".join(decls))
    return "\n".join(parts)


def transcript(messages):
    parts = []
    for message in messages:
        role = "USER" if message.get("role") == "user" else "ASSISTANT"
        parts.append(role + ":\n" + str(message.get("content", "")))
    return "\n\n".join(parts) + "\n\nReply to the last USER message with JSON matching the schema."


def run_cli(provider, model, system, messages, schema, workdir, effort=""):
    """One structured request through a logged-in CLI; returns (value, usage)."""
    env = dict(os.environ)
    if provider == "claude-cli":
        binary = cli_path("claude")
        if not binary:
            raise StudioError("Claude Code (claude) is not installed.", "Claude Code (claude) не установлен.")
        # the subscription login, not an API key that may sit in the environment
        for name in ("ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN"):
            env.pop(name, None)
        system_file = workdir / "system.md"
        system_file.write_text(system)
        argv = [binary, "-p", "--output-format", "json", "--json-schema", json.dumps(schema),
                "--tools", "", "--strict-mcp-config", "--setting-sources", "",
                "--no-session-persistence", "--system-prompt-file", str(system_file)]
        if model:
            argv += ["--model", model]
        if effort and effort != "ultra":
            argv += ["--effort", effort]
        prompt = transcript(messages)
    else:
        binary = cli_path("codex")
        if not binary:
            raise StudioError("Codex CLI (codex) is not installed.", "Codex CLI (codex) не установлен.")
        schema_file, out_file = workdir / "schema.json", workdir / "answer.json"
        schema_file.write_text(json.dumps(schema))
        try:
            listed = subprocess.run([binary, "features", "list"], capture_output=True, text=True, timeout=20).stdout
            known = {line.split()[0] for line in listed.splitlines() if line.strip()}
        except (OSError, subprocess.TimeoutExpired, IndexError):
            known = set()
        argv = [binary, "exec", "--ephemeral", "--skip-git-repo-check", "--sandbox", "read-only",
                "-c", "web_search=disabled", "-c", "mcp_servers={}", "--color", "never",
                "-C", str(workdir), "--output-schema", str(schema_file), "-o", str(out_file)]
        for feature in CODEX_DISABLE:
            if not known or feature in known:
                argv += ["--disable", feature]
        if model:
            argv += ["-m", model]
        if effort:
            argv += ["-c", f'model_reasoning_effort="{effort}"']
        argv.append("-")
        prompt = "SYSTEM INSTRUCTIONS:\n" + system + "\n\nCONVERSATION:\n" + transcript(messages)
    try:
        limit = EFFORT_TIMEOUT.get(effort, 900)
        done = subprocess.run(argv, input=prompt, capture_output=True, text=True,
                              timeout=limit, cwd=workdir, env=env)
    except subprocess.TimeoutExpired:
        minutes = EFFORT_TIMEOUT.get(effort, 900) // 60
        raise StudioError(f"The CLI did not answer in {minutes} minutes. Try a lower reasoning level.",
                          f"CLI не ответил за {minutes} мин. Попробуйте уровень рассуждений пониже.")
    except OSError:
        raise StudioError("Could not start the CLI.", "Не удалось запустить CLI.")
    tail = (done.stderr or done.stdout or "").strip().splitlines()[-1:] or [""]

    def login_hint(text):
        # only inspected on failure: a generated plugin may well mention "login"
        text = text.lower()
        if "not logged in" in text or "please run /login" in text or "codex login" in text or "invalid api key" in text:
            raise StudioError("Sign in first: Plugin Studio → Sign in via browser.",
                              "Сначала войди: Мастер плагинов → «Войти через браузер».")
    if provider == "claude-cli":
        try:
            data = json.loads(done.stdout)
        except ValueError:
            login_hint(done.stdout + done.stderr)
            raise StudioError("Claude Code failed: " + tail[0][:300], "Claude Code: ошибка: " + tail[0][:300])
        if data.get("is_error") or data.get("subtype") != "success":
            login_hint(str(data.get("result") or "") + done.stderr)
            message = str(data.get("result") or data.get("subtype") or "error")[:300]
            raise StudioError("Claude Code: " + message, "Claude Code: " + message)
        value = data.get("structured_output")
        if value is None:
            try:
                value = json.loads(data.get("result") or "")
            except ValueError:
                raise StudioError("Claude Code returned no JSON. Try again.", "Claude Code не вернул JSON. Повторите.")
        usage = data.get("usage") or {}
        return value, {"input_tokens": int(usage.get("input_tokens") or 0) + int(usage.get("cache_read_input_tokens") or 0)
                       + int(usage.get("cache_creation_input_tokens") or 0),
                       "output_tokens": int(usage.get("output_tokens") or 0)}
    if done.returncode:
        login_hint(done.stderr)
        raise StudioError("Codex failed: " + tail[0][:300], "Codex: ошибка: " + tail[0][:300])
    try:
        return json.loads((workdir / "answer.json").read_text()), {}
    except (OSError, ValueError):
        raise StudioError("Codex returned no JSON. Try again.", "Codex не вернул JSON. Повторите.")


def valid_path(name):
    if not isinstance(name, str) or len(name) > 150 or "\\" in name:
        return False
    path = PurePosixPath(name)
    return (not path.is_absolute() and str(path) == name and 0 < len(path.parts) <= 4
            and all(re.fullmatch(r"[A-Za-z0-9_-][A-Za-z0-9_.-]*", p) for p in path.parts)
            and (path.suffix in EXTENSIONS or path.name == "qmldir"))


def bundle_files(bundle):
    check_schema(bundle, BUNDLE)
    rows = bundle["files"]
    if not 1 <= len(rows) <= MAX_FILES:
        raise StudioError("A plugin must contain 1–24 files.", "Плагин должен содержать 1–24 файла.")
    files = {}
    for row in rows:
        name, text = row["path"], row["content"]
        if not valid_path(name) or name in files or "\x00" in text:
            raise StudioError("Invalid or duplicate plugin path.", "Недопустимый или повторяющийся путь файла.")
        files[name] = text
    if sum(len(v.encode()) for v in files.values()) > MAX_BYTES:
        raise StudioError("Plugin exceeds 512 KiB.", "Плагин превышает 512 КиБ.")
    for name in files:
        if any(str(p) in files for p in PurePosixPath(name).parents):
            raise StudioError("Conflicting file paths.", "Конфликт путей файлов.")
    return files


def digest(files):
    return hashlib.sha256(json.dumps(files, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def qml_formatter():
    # On Arch, unqualified qmlformat can be Qt 5. Bound components require Qt 6.
    candidates = ["/usr/lib/qt6/bin/qmlformat", "/usr/lib64/qt6/bin/qmlformat",
                  shutil.which("qmlformat6"), shutil.which("qmlformat")]
    for candidate in candidates:
        if not candidate or not os.access(candidate, os.X_OK):
            continue
        try:
            version = subprocess.run([candidate, "--version"], capture_output=True,
                                     text=True, timeout=5)
            if re.search(r"\b6\.\d+", version.stdout + version.stderr):
                return candidate
        except (OSError, subprocess.TimeoutExpired):
            continue
    return None


def validate_files(files, directory, spec, taken):
    errors = []
    try:
        manifest = json.loads(files.get("manifest.json", ""))
        if not isinstance(manifest, dict):
            raise ValueError()
    except (ValueError, TypeError):
        return {}, ["manifest.json: invalid JSON object"]
    pid = manifest.get("id", "")
    if not isinstance(pid, str) or not ID_RE.fullmatch(pid) or pid != spec["id"]:
        errors.append("manifest.id must match the approved plan (2–48 lowercase letters/digits/hyphens)")
    if isinstance(pid, str) and pid in taken:
        errors.append("Plugin ID already exists; choose another ID")
    for field in ("name", "description", "version"):
        if not isinstance(manifest.get(field), str) or not manifest[field].strip():
            errors.append("manifest." + field + " must be a nonempty string")
    if manifest.get("enabledByDefault") is not False:
        errors.append("manifest.enabledByDefault must be false")
    if not manifest.get("settings"):
        errors.append("A settings component is required")
    if "README.md" not in files:
        errors.append("README.md is required")
    if any(k in manifest for k in ("dir", "bundled")):
        errors.append("manifest must not set dir or bundled")
    for field in ENTRYPOINTS:
        name = manifest.get(field)
        if name is not None and (not isinstance(name, str) or name not in files or not name.endswith(".qml")):
            errors.append("Missing or invalid QML entry point: " + field)
    expected = {"desktop": "desktopWidget", "bar": "barWidget", "service": "main",
                "menu": "menu", "launcher": "launcher"}[spec["kind"]]
    if not manifest.get(expected) and not (expected == "menu" and manifest.get("menuComponent")):
        errors.append("Missing integration point: " + expected)
    if "menu" in manifest and (not isinstance(manifest["menu"], list)
                              or any(not isinstance(m, dict) for m in manifest["menu"])):
        errors.append("manifest.menu must be an array of objects")
    formatter = qml_formatter()
    if not formatter:
        errors.append("Qt 6 qmlformat is required to check QML (install qt6-declarative)")
    for name, text in files.items():
        suffix = Path(name).suffix
        try:
            if suffix == ".json":
                json.loads(text)
            elif suffix == ".py":
                ast.parse(text, filename=name)
            elif suffix in (".qml", ".sh"):
                argv = [formatter, "-n", str(directory / name)] if suffix == ".qml" and formatter else (
                    ["bash", "-n", str(directory / name)] if suffix == ".sh" else None)
                if argv:
                    checked = subprocess.run(argv, capture_output=True, text=True, timeout=10)
                    if checked.returncode:
                        errors.append(name + ": " + (checked.stderr or "syntax check failed").replace(str(directory) + "/", "")[:1800])
        except (ValueError, SyntaxError) as error:
            errors.append(name + ": " + str(error)[:1000])
        except (OSError, subprocess.TimeoutExpired):
            errors.append(name + ": syntax checker failed or timed out")
    desktop = manifest.get("desktopWidget")
    if isinstance(desktop, str) and desktop in files:
        source = files[desktop]
        for prop in ("implicitWidth", "implicitHeight", "screenName", "widget", "plugin"):
            if not re.search(r"\b" + prop + r"\b", source):
                errors.append(desktop + ": missing " + prop)
        if re.search(r"\b(?:PanelWindow|PopupWindow|Window)\s*\{", source):
            errors.append(desktop + ": return content Item, not a window")
    return manifest, errors[:30]


HARNESS = """//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell
@IMPORTS@
// angelOS Plugin Studio: loads each entry point of a draft the way the shell
// hosts do and reports what fails. Runs offscreen inside bubblewrap.
ShellRoot {
    Item {
        id: host
        width: 900
        height: 700
    }
    readonly property var check: JSON.parse(Quickshell.env("ANGELOS_CHECK") || "{}")
    Component.onCompleted: {
        const store = {};
        const plugin = {"id": check.id, "dir": check.dir, "manifest": check.manifest,
            "url": rel => "file://" + check.dir + "/" + rel, "settings": () => store,
            "get": (k, d) => store[k] === undefined ? d : store[k], "set": (k, v) => { store[k] = v; }};
        for (const e of check.entries || []) {
            const c = Qt.createComponent(e.url);
            if (c.status === Component.Error) {
                console.log("CHECK-FAIL " + e.kind + " :: " + c.errorString().replace(/\\n/g, " | "));
                continue;
            }
            const props = {"plugin": plugin};
            if (e.kind === "desktopWidget") { props.screenName = "CHECK-1"; props.widget = {"uid": "check", "x": 0, "y": 0, "settings": {}}; }
            if (e.kind === "barWidget") { props.screenName = "CHECK-1"; props.barWindow = null; }
            if (e.kind === "launcher") props.pluginId = check.id;
            if (e.kind === "menuComponent") props.menu = {"close": () => {}};
            if (e.kind === "sidebarWidget") props.width = 300;
            const o = c.createObject(host, props);
            if (!o) { console.log("CHECK-FAIL " + e.kind + " :: could not be created"); continue; }
            if (e.kind === "launcher" && typeof o.query === "function") {
                try { o.query("test", false); } catch (err) { console.log("CHECK-FAIL launcher :: query() threw " + err); }
            }
            console.log("CHECK-OK " + e.kind + " " + Math.round(o.implicitWidth) + "x" + Math.round(o.implicitHeight));
        }
        done.start();
    }
    // let timers and first process runs fire once
    Timer {
        id: done
        interval: 2500
        onTriggered: { console.log("CHECK-DONE"); Qt.quit(); }
    }
}
"""
ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


def quickshell_binary():
    """(binary, env, read-only binds) for running quickshell inside the sandbox."""
    system = shutil.which("quickshell", path="/usr/bin:/usr/local/bin")
    if system:
        return system, {}, []
    local = Path.home() / ".local/opt/quickshell/usr"
    if (local / "bin/quickshell").exists():
        return str(local / "bin/quickshell"), {"LD_LIBRARY_PATH": str(local / "lib"),
                                                "QML_IMPORT_PATH": str(local / "lib/qt6/qml")}, [str(local)]
    return None, {}, []


def sandbox_probe(bwrap):
    """Check that this host can create the isolated namespaces before loading QML."""
    argv = [bwrap, "--ro-bind", "/", "/", "--dev", "/dev", "--proc", "/proc",
            "--tmpfs", "/tmp", "--tmpfs", "/run", "--tmpfs", str(Path.home()),
            "--unshare-all", "--die-with-parent", "--new-session", "--cap-drop", "ALL",
            "--clearenv", "--setenv", "HOME", "/tmp", "--setenv", "XDG_RUNTIME_DIR", "/tmp",
            "--", "/usr/bin/true"]
    try:
        result = subprocess.run(argv, capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired) as error:
        return False, str(error).splitlines()[-1][:180]
    if result.returncode == 0:
        return True, ""
    detail = (result.stderr or result.stdout or "sandbox setup failed").strip().splitlines()
    return False, detail[-1][:180] if detail else "sandbox setup failed"


class Studio:
    def __init__(self, home=None, emit=None, api=None, cli=None, runtime=True):
        self.home = Path(home) if home else Path.home()
        self.config = self.home / ".config/angelos"
        self.state = self.home / ".local/state/angelos/studio"
        self.keys = self.config / "studio/credentials.json"
        self.session_file = self.state / "session.json"
        self.plugins = self.config / "plugins"
        self.emit = emit or (lambda event: None)
        self.api = api or call_provider
        self.cli = cli or run_cli
        self.runtime = runtime
        self._sandbox_status = None

    def session(self):
        return read_json(self.session_file, {"messages": [], "plan": None, "draft": None, "installed": ""})

    def save(self, session):
        write_json(self.session_file, session)

    def credentials(self):
        result = read_json(self.keys, {})
        if self.keys.exists():
            self.keys.chmod(0o600)
        return result

    def taken_ids(self):
        return {p.name for base in (self.plugins, ROOT / "plugins")
                if base.is_dir() for p in base.iterdir() if not p.name.startswith(".")}

    def context(self, language, generate=False):
        names = ["docs/STUDIO_CONTRACT.md", "docs/PLUGINS.md"]
        if generate:
            # a small, real plugin that works, plus the scaffold for every entry point
            names += ["plugins/_template/manifest.json", "plugins/_template/DesktopWidget.qml",
                      "plugins/_template/BarWidget.qml", "plugins/_template/Main.qml",
                      "plugins/_template/Settings.qml", "plugins/cat/manifest.json",
                      "plugins/cat/BarWidget.qml", "plugins/cat/Settings.qml", "plugins/cat/Cpu.qml"]
        text = "\n\n".join("FILE " + name + "\n" + (ROOT / name).read_text() for name in names if (ROOT / name).exists())
        if generate:
            text += "\n\n" + api_reference()
        return (text + "\n\nRespond in " + ("English" if language == "en" else "Russian")
                + ". Existing IDs (do not reuse): " + ", ".join(sorted(self.taken_ids()))
                + "\nReturn exactly the requested JSON schema.")

    def ask(self, request, messages, schema, generate=False):
        provider = request.get("provider")
        effort = request.get("effort", "")
        if effort not in ("",) + EFFORTS:
            raise StudioError("Unknown reasoning level.", "Неизвестный уровень рассуждений.")
        if provider in CLI_PROVIDERS:
            model = request.get("model", "")
            if not isinstance(model, str) or not re.fullmatch(r"[A-Za-z0-9_.:\[\]-]{0,100}", model):
                raise StudioError("Enter a valid model name or leave it empty.", "Введите корректное имя модели или оставьте пустым.")
            system = self.context(request.get("language"), generate)
            self.emit({"event": "progress", "stage": "request"})
            private_dir(self.state)
            workdir = Path(tempfile.mkdtemp(prefix="cli-", dir=self.state))
            try:
                value, usage = self.cli(provider, model, system, messages, schema, workdir, effort)
            finally:
                shutil.rmtree(workdir, ignore_errors=True)
            check_schema(value, schema)
            return value, usage
        if provider not in API_PROVIDERS:
            raise StudioError("Choose an API provider.", "Выберите провайдера API.")
        key = self.credentials().get(provider, "")
        if not key:
            raise StudioError("Save an API key first.", "Сначала сохраните API-ключ.")
        model = request.get("model", "")
        if not isinstance(model, str) or not re.fullmatch(r"[A-Za-z0-9_.:-]{1,100}", model):
            raise StudioError("Enter a valid API model ID.", "Введите корректный API ID модели.")
        tokens = request.get("maxOutputTokens", 32000)
        if type(tokens) is not int or not 2048 <= tokens <= 64000:
            raise StudioError("Output limit must be 2048–64000 tokens.", "Лимит ответа: 2048–64000 токенов.")
        system = self.context(request.get("language"), generate)
        wire = provider_request(provider, model, key, system, messages, schema,
                                tokens if generate else min(tokens, 12000), effort)
        self.emit({"event": "progress", "stage": "request"})
        value, usage = self.api(wire, provider, EFFORT_TIMEOUT.get(effort, 900))
        check_schema(value, schema)
        # Guard against an accidentally pasted key being echoed into generated files/history.
        serialized = json.dumps(value, ensure_ascii=False)
        if any(secret and secret in serialized for secret in self.credentials().values()):
            raise StudioError("The response contains a saved API key and was discarded.",
                              "Ответ содержит сохранённый API-ключ и был отброшен.")
        return value, usage

    def store_draft(self, session, value, usage):
        files = bundle_files(value)
        token = uuid.uuid4().hex
        directory = self.state / "drafts" / token
        private_dir(directory)
        for name, text in files.items():
            target = directory / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text)
            target.chmod(0o600)
        old = session.get("draft") or {}
        if old.get("token") and old["token"] != token:
            shutil.rmtree(self.state / "drafts" / old["token"], ignore_errors=True)
        self.emit({"event": "progress", "stage": "validation"})
        session.update({"draft": {"token": token, "summary": value["summary"], "notes": value["notes"]}, "usage": usage})

    def draft_dir(self, token):
        if not isinstance(token, str) or not re.fullmatch(r"[a-f0-9]{32}", token):
            raise StudioError("Invalid draft.", "Некорректный черновик.")
        path = self.state / "drafts" / token
        if path.is_symlink() or not path.is_dir():
            raise StudioError("Draft is missing.", "Черновик не найден.")
        return path

    def load_draft_files(self, token):
        path = self.draft_dir(token)
        files = []
        size = 0
        for entry in sorted(path.rglob("*")):
            if entry.is_symlink():
                raise StudioError("Symlinks are not allowed in drafts.", "Символические ссылки в черновиках запрещены.")
            if entry.is_dir():
                continue
            if not stat.S_ISREG(entry.stat().st_mode):
                raise StudioError("Only regular files are allowed.", "Разрешены только обычные файлы.")
            size += entry.stat().st_size
            if size > MAX_BYTES or len(files) >= MAX_FILES:
                raise StudioError("Draft is too large.", "Черновик слишком большой.")
            files.append({"path": entry.relative_to(path).as_posix(), "content": entry.read_text()})
        return bundle_files({"summary": "", "notes": [], "files": files})

    def runtime_check(self, directory, manifest):
        """Load every QML entry point offscreen in a bubblewrap sandbox (no network, no home,
        no sockets). Returns (errors, note). Skipped when bwrap or quickshell is missing."""
        bwrap = shutil.which("bwrap")
        binary, extra_env, extra_binds = quickshell_binary()
        if not bwrap:
            return [], "runtime check skipped: bubblewrap (bwrap) is not installed"
        if not binary:
            return [], "runtime check skipped: quickshell not found"
        if self._sandbox_status is None:
            self._sandbox_status = sandbox_probe(bwrap)
        if not self._sandbox_status[0]:
            detail = self._sandbox_status[1]
            suffix = f" ({detail})" if detail else ""
            return [], "runtime check skipped: bubblewrap sandbox unavailable" + suffix
        entries = [{"kind": f, "url": "file://" + str(directory / manifest[f])}
                   for f in ENTRYPOINTS if isinstance(manifest.get(f), str) and manifest[f].endswith(".qml")]
        if not entries:
            return [], ""
        private_dir(self.state)
        tmp = Path(tempfile.mkdtemp(prefix="check-", dir=self.state))
        try:
            root, home, run = tmp / "shell", tmp / "home", tmp / "run"
            (home / ".config/angelos").mkdir(parents=True)
            run.mkdir(mode=0o700)
            imports, binds = [], []
            for sub in ("config", "services", "widgets", "modules", "plugins", "scripts", "shaders", "templates", "bin"):
                if not (ROOT / sub).is_dir():
                    continue
                (root / sub).mkdir(parents=True)
                binds += ["--ro-bind", str(ROOT / sub), str(root / sub)]
                if sub in ("config", "services", "widgets", "modules"):
                    for d in [ROOT / sub] + sorted(p for p in (ROOT / sub).rglob("*") if p.is_dir()):
                        if "__pycache__" not in d.parts and any(d.glob("*.qml")):
                            imports.append("import qs." + ".".join(d.relative_to(ROOT).parts))
            (root / "shell.qml").write_text(HARNESS.replace("@IMPORTS@", "\n".join(imports)))
            check = {"id": manifest.get("id", ""), "dir": str(directory), "manifest": manifest, "entries": entries}
            env = {"HOME": str(home), "XDG_RUNTIME_DIR": str(run), "QT_QPA_PLATFORM": "offscreen",
                   "ANGELOS_DEV": "1", "PATH": "/usr/bin:/bin", "LANG": "C.UTF-8", "ANGELOS_CHECK": json.dumps(check)}
            env.update(extra_env)
            # the home is hidden; the scratch dir first, then the read-only shell parts inside it
            argv = [bwrap, "--ro-bind", "/", "/", "--dev", "/dev", "--proc", "/proc",
                    "--tmpfs", "/tmp", "--tmpfs", "/run", "--tmpfs", str(Path.home()), "--bind", str(tmp), str(tmp)]
            for b in extra_binds:
                argv += ["--ro-bind", b, b]
            argv += binds + ["--ro-bind", str(directory), str(directory),
                             "--unshare-all", "--die-with-parent", "--new-session", "--cap-drop", "ALL", "--clearenv"]
            for k, v in env.items():
                argv += ["--setenv", k, v]
            argv += [binary, "-p", str(root)]
            try:
                done = subprocess.run(argv, capture_output=True, text=True, timeout=30)
                output = ANSI_RE.sub("", done.stdout + done.stderr)
            except subprocess.TimeoutExpired as e:
                output = ANSI_RE.sub("", (e.stdout or b"").decode(errors="replace") if isinstance(e.stdout, bytes) else (e.stdout or ""))
                output += "\nCHECK-TIMEOUT"
        finally:
            shutil.rmtree(tmp, ignore_errors=True)
        errors, where = [], str(directory) + "/"
        for line in output.splitlines():
            text = line.strip()
            if "CHECK-FAIL" in text:
                errors.append("runtime: " + text.split("CHECK-FAIL", 1)[1].strip().replace("file://" + where, "").replace(where, ""))
            elif where in text and re.search(r"\b(WARN|ERROR|CRIT)", text):
                errors.append("runtime: " + re.sub(r"^.*?(WARN|ERROR|CRIT)\S*\s*", "", text).replace("file://" + where, "").replace(where, ""))
            else:
                m = re.search(r"CHECK-OK (\w+) (\d+)x(\d+)", text)
                if m and m.group(1) in ("desktopWidget", "barWidget", "sidebarWidget") and (m.group(2) == "0" or m.group(3) == "0"):
                    errors.append(f"runtime: {m.group(1)} has zero implicit size ({m.group(2)}x{m.group(3)}); set implicitWidth/implicitHeight")
        if "CHECK-DONE" not in output:
            errors.append("runtime: the QML check did not finish (crash, hang or a blocking call at load time)")
        # the same warning can repeat per binding evaluation
        return list(dict.fromkeys(errors))[:25], "runtime check: entry points loaded in a sandbox"

    def review(self, session):
        draft = session.get("draft")
        if not draft:
            raise StudioError("Generate a plugin first.", "Сначала создайте плагин.")
        files = self.load_draft_files(draft["token"])
        if any(secret and any(secret in text for text in files.values())
               for secret in self.credentials().values()):
            raise StudioError("Remove the saved API key from the draft before continuing.",
                              "Уберите сохранённый API-ключ из черновика перед продолжением.")
        manifest, errors = validate_files(files, self.draft_dir(draft["token"]),
                                          session["plan"]["spec"], self.taken_ids())
        note = ""
        if not errors and self.runtime:
            self.emit({"event": "progress", "stage": "runtime"})
            runtime_errors, note = self.runtime_check(self.draft_dir(draft["token"]), manifest)
            errors = runtime_errors
        draft["check"] = note
        draft.update({"manifest": manifest, "errors": errors, "digest": digest(files),
                      "files": [{"path": name, "content": text} for name, text in files.items()],
                      "directory": str(self.draft_dir(draft["token"]))})
        return draft

    def install(self, session, expected):
        if session.get("installed"):
            raise StudioError("This project is already installed.", "Этот проект уже установлен.")
        draft = self.review(session)
        if not expected or draft["digest"] != expected:
            raise StudioError("Files changed. Review them again before installing.",
                              "Файлы изменились. Просмотрите результат перед установкой.")
        if draft["errors"]:
            raise StudioError("Fix the validation errors first.", "Сначала исправьте ошибки проверки.")
        pid = draft["manifest"]["id"]
        self.plugins.mkdir(parents=True, exist_ok=True)
        destination = self.plugins / pid
        if destination.exists() or destination.is_symlink():
            raise StudioError("A plugin with this ID already exists.", "Плагин с таким ID уже существует.")
        # Same filesystem: readers can only see the complete final directory.
        temp = Path(tempfile.mkdtemp(prefix=".studio-", dir=self.plugins))
        try:
            for row in draft["files"]:
                path = temp / row["path"]
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(row["content"])
            # mkdir reserves the name without replacing an existing file/plugin.
            destination.mkdir()
            try:
                os.replace(temp, destination)
            except BaseException:
                destination.rmdir()
                raise
        finally:
            if temp.exists():
                shutil.rmtree(temp)
        session["installed"] = pid
        self.save(session)
        return {"id": pid, "desktop": bool(draft["manifest"].get("desktopWidget")),
                "directory": str(destination)}

    def dispatch(self, request):
        action = request.get("action")
        if action not in ("status",):
            settings = read_json(self.config / "settings.json", {})
            if not settings.get("developer", {}).get("enabled", False):
                raise StudioError("Enable developer mode in Settings → System.",
                                  "Включите режим разработчика в Настройки → System.")
        if action == "status":
            keys = self.credentials()
            return {"keys": {p: bool(keys.get(p)) for p in API_PROVIDERS},
                    "cli": cli_status(), "session": self.session(), "models": models_catalog()}
        if action in ("save_key", "delete_key"):
            provider = request.get("provider")
            if provider not in API_PROVIDERS:
                raise StudioError("Unknown provider.")
            keys = self.credentials()
            if action == "delete_key":
                keys.pop(provider, None)
            else:
                key = request.get("key", "").strip()
                if not 16 <= len(key) <= 1024 or not re.fullmatch(r"[!-~]+", key):
                    raise StudioError("Invalid API key.", "Некорректный API-ключ.")
                keys[provider] = key
            write_json(self.keys, keys)
            return {"keys": {p: bool(keys.get(p)) for p in ("openai", "anthropic")}}
        if action == "reset":
            session = {"messages": [], "plan": None, "draft": None, "installed": ""}
            self.save(session)
            return {"session": session}
        session = self.session()
        if action == "plan":
            prompt = request.get("prompt", "").strip()
            if not prompt or len(prompt) > 16000:
                raise StudioError("Enter a request (up to 16000 characters).", "Введите запрос (до 16000 символов).")
            if any(key and key in prompt for key in self.credentials().values()):
                raise StudioError("Enter API keys only in the key field.", "Вводите API-ключи только в поле ключа.")
            if session.get("installed"):
                raise StudioError("Start a new project first.", "Сначала создайте новый проект.")
            messages = session["messages"] + [{"role": "user", "content": prompt}]
            if len(json.dumps(messages)) > 150000:
                raise StudioError("Conversation is full. Start a new project.", "Диалог заполнен. Создайте новый проект.")
            value, usage = self.ask(request, messages, PLAN)
            if len(value["questions"]) > 3:
                raise StudioError("Too many questions in response. Try again.", "Слишком много вопросов в ответе. Повторите запрос.")
            if not ID_RE.fullmatch(value["spec"]["id"]):
                raise StudioError("Invalid proposed plugin ID. Try again.", "Некорректный ID плагина. Повторите запрос.")
            if value["spec"]["kind"] in ("desktop", "bar") and not (
                    1 <= value["spec"]["widthUnits"] <= 1000
                    and 1 <= value["spec"]["heightUnits"] <= 1000):
                raise StudioError("Invalid proposed widget size. Try again.",
                                  "Некорректный размер виджета в плане. Повторите запрос.")
            session.update({"messages": messages + [{"role": "assistant", "content": json.dumps(value, ensure_ascii=False)}],
                            "plan": value, "draft": None, "usage": usage})
            self.save(session)
        elif action == "generate":
            plan = session.get("plan")
            if not plan or plan["questions"]:
                raise StudioError("Answer the questions first.", "Сначала ответьте на вопросы.")
            if session.get("installed"):
                raise StudioError("Start a new project first.", "Сначала создайте новый проект.")
            messages = session["messages"] + [{"role": "user", "content": "Implement this approved plan:\n" + json.dumps(plan, ensure_ascii=False)}]
            if session.get("draft"):
                previous = self.review(session)
                messages[-1]["content"] += "\nRepair/replace this complete previous bundle:\n" + json.dumps(
                    {key: previous[key] for key in ("files", "errors", "summary", "notes")}, ensure_ascii=False)
            rounds = request.get("autoRepair", 1)
            rounds = rounds if type(rounds) is int and 0 <= rounds <= MAX_REPAIRS else 1
            total = {"input_tokens": 0, "output_tokens": 0}
            attempt = 0
            while True:
                value, usage = self.ask(request, messages, BUNDLE, True)
                for k in total:
                    total[k] += int((usage or {}).get(k) or 0)
                self.store_draft(session, value, total)
                draft = self.review(session)
                self.save(session)
                if not draft["errors"] or attempt >= rounds:
                    break
                attempt += 1
                # feed the failures back once or twice before bothering the user
                self.emit({"event": "progress", "stage": "repair", "round": attempt, "of": rounds})
                messages = session["messages"] + [{"role": "user", "content":
                    "Implement this approved plan:\n" + json.dumps(plan, ensure_ascii=False)
                    + "\nYour previous bundle failed the automatic checks below (static checks, then loading every "
                    "entry point in Quickshell). Fix every item, keep what works, and return the complete corrected "
                    "bundle:\n" + json.dumps({key: draft[key] for key in ("files", "errors")}, ensure_ascii=False)}]
        elif action == "review":
            self.review(session)
            self.save(session)
        elif action == "install":
            installed = self.install(session, request.get("digest"))
            return {"session": session, "installed": installed}
        else:
            raise StudioError("Unknown Studio action.")
        return {"session": session}


def main():
    os.umask(0o077)
    def emit(event):
        print(json.dumps(event, ensure_ascii=False), flush=True)
    request = {}
    try:
        raw = sys.stdin.readline(4 * MAX_BYTES + 1)
        if len(raw) > 4 * MAX_BYTES:
            raise StudioError("Request is too large.")
        request = json.loads(raw)
        if not isinstance(request, dict):
            raise StudioError("Invalid request.")
        studio = Studio(emit=emit)
        private_dir(studio.state)
        with (studio.state / "worker.lock").open("w") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise StudioError("Studio is busy in another window.", "Мастер занят в другом окне.")
            result = studio.dispatch(request)
        emit({"event": "result", **result})
    except StudioError as error:
        emit({"event": "error", "message": error.en
              if isinstance(request, dict) and request.get("language") == "en" else error.ru})
    except (OSError, ValueError, TypeError, KeyError, AttributeError, UnicodeError):
        emit({"event": "error", "message": "Could not read/write Studio files. Check disk space and permissions."
              if isinstance(request, dict) and request.get("language") == "en"
              else "Не удалось прочитать или записать файлы мастера. Проверьте место на диске и права."})


if __name__ == "__main__":
    main()
