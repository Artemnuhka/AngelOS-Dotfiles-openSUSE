#!/usr/bin/env python3
"""Codex Companion scanner: limits, today's tokens and live sessions.

Reads Codex's own session logs ($CODEX_HOME/sessions/**/rollout-*.jsonl) and
keeps only three kinds of records: session_meta (cwd, provider), turn_context
(model) and event_msg/token_count (token totals + the rate limits the provider
reported with its last answer). Conversation contents are never parsed. Files
are read incrementally (byte offsets cached in ~/.cache/angelos), so a minute
tick costs next to nothing. No network access.

Prints one JSON object.
"""
import datetime
import json
import os
from pathlib import Path
import sys
import time
import tomllib

CODEX = Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex")
CACHE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "angelos/codex-scan.json"
DAYS = 8
LIVE_WINDOW = 30 * 60
KEEP = ("\"token_count\"", "\"session_meta\"", "\"turn_context\"", "\"task_started\"", "\"task_complete\"")


def codex_running():
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            with open(f"/proc/{pid}/comm") as f:
                if f.read().strip() in ("codex", "codex-tui"):
                    return True
        except OSError:
            pass
    return False


def epoch(stamp):
    try:
        return datetime.datetime.fromisoformat(stamp.replace("Z", "+00:00")).timestamp()
    except (AttributeError, ValueError):
        return 0.0


def load_cache():
    try:
        data = json.loads(CACHE.read_text())
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


def save_cache(cache):
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    tmp = CACHE.with_suffix(".tmp")
    tmp.write_text(json.dumps(cache))
    tmp.replace(CACHE)


def scan_file(path, state):
    """Continue reading `path` from the cached offset, updating `state`."""
    size = path.stat().st_size
    if size < state.get("offset", 0):
        state.clear()
    with path.open("rb") as stream:
        stream.seek(state.get("offset", 0))
        for raw in stream:
            if not raw.endswith(b"\n"):
                break   # a line still being written; read it next time
            state["offset"] = state.get("offset", 0) + len(raw)
            line = raw.decode("utf-8", "replace")
            if not any(k in line for k in KEEP):
                continue
            try:
                record = json.loads(line)
            except ValueError:
                continue
            kind = record.get("type")
            payload = record.get("payload") or {}
            at = epoch(record.get("timestamp"))
            if kind == "session_meta":
                state["cwd"] = os.path.basename(payload.get("cwd") or "")
                state["provider"] = payload.get("model_provider") or ""
            elif kind == "turn_context":
                state["model"] = payload.get("model") or state.get("model", "")
            elif kind == "event_msg":
                sub = payload.get("type")
                if sub == "task_started":
                    state["state"] = "working"
                    state["at"] = at
                elif sub == "task_complete":
                    state["state"] = "done"
                    state["at"] = at
                elif sub == "token_count":
                    info = payload.get("info") or {}
                    total = info.get("total_token_usage") or {}
                    if total:
                        day = datetime.date.fromtimestamp(at).isoformat() if at else ""
                        days = state.setdefault("days", {})
                        # last cumulative total seen on each day: per-day usage is a difference
                        days[day] = {k: int(total.get(k) or 0) for k in
                                     ("input_tokens", "cached_input_tokens", "output_tokens",
                                      "reasoning_output_tokens", "total_tokens")}
                        state["window"] = int(info.get("model_context_window") or 0)
                        last = info.get("last_token_usage") or {}
                        state["context"] = int(last.get("input_tokens") or 0)
                    limits = payload.get("rate_limits")
                    # some providers send the object with every window empty
                    if limits and any(limits.get(k) for k in ("primary", "secondary", "credits")):
                        state["limits"] = limits
                        state["limitsAt"] = at
                    state["at"] = at or state.get("at", 0)
    return state


def main():
    cache = load_cache()
    files = cache.setdefault("files", {})
    now = time.time()
    root = CODEX / "sessions"
    recent = []
    if root.is_dir():
        horizon = now - DAYS * 86400
        for path in root.glob("*/*/*/rollout-*.jsonl"):
            try:
                mtime = path.stat().st_mtime
            except OSError:
                continue
            if mtime >= horizon and not path.is_symlink():
                recent.append((mtime, path))
    recent.sort(reverse=True)
    seen = set()
    for mtime, path in recent[:200]:
        key = str(path)
        seen.add(key)
        state = files.get(key) or {}
        if state.get("mtime") != mtime:
            try:
                scan_file(path, state)
            except OSError:
                continue
            state["mtime"] = mtime
        files[key] = state
    for key in list(files):
        if key not in seen:
            del files[key]

    today = datetime.date.today().isoformat()
    usage = {k: 0 for k in ("input_tokens", "cached_input_tokens", "output_tokens",
                            "reasoning_output_tokens", "total_tokens")}
    limits, limits_at, sessions = None, 0, []
    running = codex_running()
    for key, state in files.items():
        days = state.get("days") or {}
        if today in days:
            before = [d for d in days if d < today]
            base = days[max(before)] if before else {}
            for k in usage:
                usage[k] += max(0, days[today].get(k, 0) - base.get(k, 0))
        if state.get("limits") and state.get("limitsAt", 0) >= limits_at:
            limits, limits_at = state["limits"], state.get("limitsAt", 0)
        age = now - state.get("mtime", 0)
        if running and age < LIVE_WINDOW:
            status = state.get("state", "done")
            if status == "working" and age > 5 * 60:
                status = "done"
            sessions.append({"id": Path(key).stem[-8:], "cwd": state.get("cwd", ""),
                             "model": state.get("model", "?"), "state": status, "age": int(age),
                             "context": state.get("context", 0), "window": state.get("window", 0)})
    save_cache(cache)

    config = {}
    try:
        config = tomllib.loads((CODEX / "config.toml").read_text())
    except (OSError, ValueError):
        pass
    auth = ""
    try:
        auth = json.loads((CODEX / "auth.json").read_text()).get("auth_mode", "") or ""
    except (OSError, ValueError, AttributeError):
        pass   # only the mode is read; tokens and keys are never touched
    print(json.dumps({
        "installed": CODEX.is_dir(),
        "auth": auth,
        "provider": config.get("model_provider", "openai"),
        "model": config.get("model", ""),
        "limits": limits,
        "limitsAt": int(limits_at),
        "today": usage,
        "sessions": sorted(sessions, key=lambda s: s["age"]),
        "running": running,
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:  # a scanner bug must not break the widget
        print(json.dumps({"error": str(error)}))
        sys.exit(1)
