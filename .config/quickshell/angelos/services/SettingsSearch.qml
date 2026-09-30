pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Settings search: pages, groups and single settings, found by name or by a
// rough description ("прозрачность панели", "display", "ифк" typed in the wrong
// layout). The index comes from the pages' own QML (scripts/settings-index.py);
// the synonyms below connect everyday words to the angelOS names.
Singleton {
    id: root

    property var entries: []
    property bool loaded: false
    function load() {
        if (!indexer.running)
            indexer.running = true;
    }
    Process {
        id: indexer
        command: ["python3", Quickshell.shellDir + "/scripts/settings-index.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.entries = JSON.parse(text);
                    root.loaded = true;
                } catch (e) {}
            }
        }
    }

    // everyday words per page, both languages (also used for completion)
    readonly property var aliases: ({
            // only words the page itself doesn't say (its rows are found by their own names)
            "appearance": ["тема", "цвет", "цвета", "палитра", "акцент", "язык", "оформление", "theme", "color", "colour", "palette", "accent", "language", "look"],
            "fonts": ["шрифт", "текст", "размер текста", "буквы", "font", "text size", "typeface"],
            "wallpaper": ["обои", "фон", "картинка", "заставка стола", "wallpaper", "background", "picture", "image"],
            "capture": ["скриншот", "снимок экрана", "запись экрана", "screenshot", "recording", "capture"],
            "cursor": ["курсор", "указатель", "cursor", "pointer"],
            "widgets": ["виджет", "часы", "визуализатор", "cava", "widget", "clock", "visualizer"],
            "bar": ["панель", "таскбар", "пуск", "трей", "меню пуск", "кнопки окон", "taskbar", "panel", "start", "start menu", "tray", "dock"],
            "workspaces": ["рабочие столы", "воркспейсы", "столы", "сердечки", "переход", "desks", "virtual desktops", "workspaces", "transition"],
            "lyrics": ["лирика", "текст песни", "караоке", "песня", "музыка", "lyrics", "song", "karaoke", "music"],
            "monitor": ["экран", "дисплей", "монитор", "разрешение", "частота", "герцы", "масштаб", "display", "screen", "monitor", "resolution", "refresh rate", "hz", "scale"],
            "keyboard": ["клавиатура", "мышь", "мышка", "раскладка", "тачпад", "чувствительность", "keyboard", "mouse", "layout", "touchpad", "sensitivity"],
            "shortcuts": ["горячие клавиши", "хоткеи", "сочетания", "бинды", "клавиши", "shortcuts", "hotkeys", "keybinds", "bindings", "keys"],
            "windows": ["окна", "закрытие окон", "анимация закрытия", "отступы", "колонки", "диспетчер", "windows", "close", "gaps", "columns"],
            "sound": ["звук", "громкость", "микрофон", "аудио", "колонки", "наушники", "sound", "audio", "volume", "microphone", "speakers", "headphones"],
            "network": ["сеть", "интернет", "вайфай", "wifi", "network", "internet"],
            "bluetooth": ["блютуз", "беспроводные", "bluetooth", "wireless"],
            "gamepad": ["геймпад", "джойстик", "контроллер", "gamepad", "controller", "joystick"],
            "defaults": ["по умолчанию", "браузер", "терминал", "редактор", "файловый менеджер", "default apps", "browser", "terminal", "editor", "file manager"],
            "notifications": ["уведомления", "не беспокоить", "notifications", "do not disturb", "dnd"],
            "plugins": ["плагины", "расширения", "plugins", "extensions", "addons"],
            "lock": ["блокировка", "заставка", "пароль", "экран блокировки", "lock", "idle", "lock screen", "screensaver"],
            "updates": ["обновления", "версия", "updates", "upgrade", "version"],
            "system": ["система", "диспетчер задач", "производительность", "отрисовка", "system", "task manager", "performance", "renderer"]
        })
    // words that mean the same thing; a query word pulls in its whole group
    readonly property var synonyms: [
        ["блюр", "размытие", "blur", "стекло", "glass"],
        ["прозрачность", "непрозрачность", "opacity", "transparency", "прозрачный"],
        ["экран", "дисплей", "монитор", "display", "screen", "monitor"],
        ["звук", "аудио", "sound", "audio"],
        ["громкость", "volume", "громко", "тихо"],
        ["микрофон", "mic", "microphone", "мик"],
        ["обои", "фон", "wallpaper", "background"],
        ["тема", "theme", "оформление"],
        ["цвет", "цвета", "color", "colour", "палитра", "palette", "акцент", "accent"],
        ["тёмная", "темная", "dark", "ночная"],
        ["светлая", "light", "дневная"],
        ["шрифт", "font", "шрифты", "fonts"],
        ["клавиатура", "keyboard", "раскладка", "layout"],
        ["мышь", "мышка", "mouse", "курсор", "cursor", "указатель"],
        ["хоткей", "хоткеи", "горячие", "сочетание", "shortcut", "hotkey", "keybind", "бинд"],
        ["панель", "таскбар", "bar", "taskbar", "panel"],
        ["пуск", "start", "меню"],
        ["окно", "окна", "window", "windows"],
        ["закрыть", "закрытие", "close", "closing"],
        ["анимация", "анимации", "animation", "переход", "transition", "эффект"],
        ["стол", "столы", "воркспейс", "воркспейсы", "workspace", "desk"],
        ["уведомления", "notifications", "оповещения"],
        ["блокировка", "lock", "замок"],
        ["заставка", "idle", "screensaver"],
        ["лирика", "lyrics", "текст песни", "караоке"],
        ["сеть", "network", "wifi", "интернет", "вайфай"],
        ["размер", "size", "масштаб", "scale", "ширина", "width", "высота", "height"],
        ["скриншот", "screenshot", "снимок"],
        ["язык", "language", "english", "русский"],
        ["плагин", "plugin", "расширение"],
        ["обновление", "обновления", "update", "updates"],
        ["больше", "меньше", "крупнее", "мельче", "увеличить", "уменьшить", "bigger", "smaller", "larger", "размер", "масштаб", "scale", "size"],
        ["центр", "центру", "посередине", "середина", "center", "centre", "middle"],
        ["слева", "левый", "left"],
        ["справа", "правый", "right"],
        ["задач", "диспетчер", "task", "tasks", "монитор ресурсов", "btop"]
    ]
    // intent words that say nothing about *which* setting
    readonly property var stopwords: ["как", "где", "что", "это", "мне", "мой", "моя", "мои", "свой", "чтобы", "для", "на", "в", "во", "с", "со", "по", "и", "или", "не", "а", "у", "к", "от", "из", "сделать", "сменить", "поменять", "изменить", "включить", "выключить", "отключить", "настроить", "настройка", "настройки", "поставить", "убрать", "хочу", "нужно", "можно", "how", "to", "do", "i", "the", "a", "an", "my", "where", "what", "is", "change", "set", "enable", "disable", "turn", "on", "off", "make", "settings", "setting", "want"]
    // completion prefers these, in this order ("D" → Display, "Bl" → Blur)
    readonly property var common: ["Display", "Wallpaper", "Blur", "Bar", "Sound", "Theme", "Fonts", "Keyboard", "Mouse", "Monitor", "Lyrics", "Lock screen", "Notifications", "Network", "Bluetooth", "Cursor", "Widgets", "Workspaces", "Start menu", "Shortcuts", "Hotkeys", "Plugins", "Updates", "Screenshots", "Gamepad", "Transparency", "Opacity", "Animation", "Volume", "Microphone", "Language", "Task manager", "Close animation", "Обои", "Блюр", "Звук", "Тема", "Шрифты", "Экран", "Монитор", "Панель", "Пуск", "Клавиатура", "Мышь", "Лирика", "Блокировка", "Уведомления", "Сеть", "Курсор", "Виджеты", "Воркспейсы", "Горячие клавиши", "Плагины", "Обновления", "Скриншоты", "Прозрачность", "Размытие", "Громкость", "Микрофон", "Язык", "Анимация", "Диспетчер задач", "Закрытие окон"]

    // ---- text helpers ----
    function norm(s) {
        return String(s || "").toLowerCase().replace(/ё/g, "е").replace(/[«»"“”'’`.,:;!?()\[\]{}…·|/\\+*=<>#~_—–-]+/g, " ").replace(/\s+/g, " ").trim();
    }
    function words(s) {
        const n = norm(s);
        return n ? n.split(" ") : [];
    }
    readonly property string _en: "qwertyuiop[]asdfghjkl;'zxcvbnm,.`"
    readonly property string _ru: "йцукенгшщзхъфывапролджэячсмитьбюё"
    // the same keys typed in the other layout: "ифк" → "bar", "pdzr" → "звук"
    function swapLayout(s) {
        let out = "";
        for (const ch of String(s || "").toLowerCase()) {
            let i = _en.indexOf(ch);
            if (i >= 0) {
                out += _ru[i];
                continue;
            }
            i = _ru.indexOf(ch);
            out += i >= 0 ? _en[i] : ch;
        }
        return out;
    }
    function dist(a, b) {
        // Damerau–Levenshtein (optimal string alignment), small words only
        const m = a.length, n = b.length;
        if (Math.abs(m - n) > 2)
            return 9;
        const d = [];
        for (let i = 0; i <= m; i++) {
            d.push([i]);
            for (let j = 1; j <= n; j++)
                d[i].push(i === 0 ? j : 0);
        }
        for (let i = 1; i <= m; i++)
            for (let j = 1; j <= n; j++) {
                const c = a[i - 1] === b[j - 1] ? 0 : 1;
                d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + c);
                if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1])
                    d[i][j] = Math.min(d[i][j], d[i - 2][j - 2] + 1);
            }
        return d[m][n];
    }
    // how well query word q matches text word t (0..1)
    function wordScore(q, t) {
        if (!q || !t)
            return 0;
        if (q === t)
            return 1;
        if (t.startsWith(q))
            return q.length === 1 ? 0.55 : 0.9;
        if (q.length < 3)
            return 0;
        // same stem: "панели" ~ "панелей", "обоями" ~ "обои"
        let k = 0;
        while (k < q.length && k < t.length && q[k] === t[k])
            k++;
        if (k >= 4 && k >= Math.max(q.length, t.length) - 3)
            return 0.8;
        if (k >= 3 && k === Math.min(q.length, t.length))
            return 0.75;
        if (t.includes(q))
            return 0.6;
        if (q.length >= 4 && q[0] === t[0]) {
            // a typo in the whole word or in the part typed so far ("blru" → "blur…")
            const best = Math.min(dist(q, t), dist(q, t.slice(0, q.length)));
            if (best <= 1)
                return 0.65;
            if (best <= 2 && q.length >= 7)
                return 0.5;
        }
        return 0;
    }
    function expand(q) {
        // a query word and the words of its synonym groups
        const out = [q];
        for (const g of synonyms)
            if (g.some(w => wordScore(q, norm(w)) >= 0.8))
                for (const w of g)
                    for (const x of words(w))
                        if (!out.includes(x))
                            out.push(x);
        return out;
    }

    // ---- entries with their searchable fields, rebuilt when the index or pages change ----
    property var pageInfo: ({})       // id -> {label, icon} from the settings sidebar
    readonly property var docs: {
        const lang = I18n.english ? "en" : "ru", other = I18n.english ? "ru" : "en";
        const out = [];
        const seenPages = {};
        for (const e of entries) {
            const info = pageInfo[e.page];
            if (!info)
                continue;   // hidden (owner/developer) or unknown pages
            const title = e.kind === "page" ? info.label : (e[lang] || e[other]);
            if (e.kind === "page")
                seenPages[e.page] = true;
            out.push({
                "page": e.page,
                "kind": e.kind,
                "title": title,
                "target": e.kind === "page" ? "" : e[lang],
                "crumb": e.kind === "row" && e.group && e.group[lang] ? info.label + " › " + e.group[lang] : e.kind === "page" ? "" : info.label,
                "hint": e.hint ? e.hint[lang] : "",
                "icon": info.icon,
                "primary": words(title + (e.kind === "page" ? " " + (e[lang] || "") : "")),
                "other": words(e[other] || ""),
                "aliasNames": e.kind === "page" ? (aliases[e.page] || []).map(a => norm(a)) : [],
                "alias": e.kind === "page" ? words((aliases[e.page] || []).join(" ")) : [],
                "secondary": words((e.hint ? e.hint[lang] + " " + e.hint[other] : "") + " " + (e.words ? e.words[lang].join(" ") + " " + e.words[other].join(" ") : "")),
                "context": words(e.kind === "row" && e.group ? e.group[lang] + " " + e.group[other] : "")
            });
        }
        // pages without an index entry (plugins): name only
        for (const id in pageInfo)
            if (!seenPages[id])
                out.push({
                    "page": id,
                    "kind": "page",
                    "title": pageInfo[id].label,
                    "target": "",
                    "crumb": "",
                    "hint": "",
                    "icon": pageInfo[id].icon,
                    "primary": words(pageInfo[id].label),
                    "other": [],
                    "aliasNames": (aliases[id] || []).map(a => norm(a)),
                    "alias": words((aliases[id] || []).join(" ")),
                    "secondary": [],
                    "context": []
                });
        return out;
    }

    // query words with their synonyms, prepared once per search: [[ [word, weight], … ], …]
    function prepare(qwords) {
        return qwords.map(q => expand(q).map(v => [v, v === q ? 1 : 0.85]));
    }
    property var _cache: ({})
    function cachedScore(v, t) {
        const k = v + "\u0001" + t;
        let r = _cache[k];
        if (r === undefined) {
            r = wordScore(v, t);
            _cache[k] = r;
        }
        return r;
    }
    function bestIn(list, v, weight, best) {
        for (const t of list) {
            const x = cachedScore(v, t) * weight;
            if (x > best)
                best = x;
        }
        return best;
    }
    function scoreDoc(doc, prepared, phrase) {
        let total = 0, hit = 0;
        for (const exp of prepared) {
            let best = 0;
            for (const pair of exp) {
                const v = pair[0], syn = pair[1];
                best = bestIn(doc.primary, v, 3 * syn, best);
                if (best < 2.5)
                    best = bestIn(doc.other, v, 2.5 * syn, best);
                if (best < 2.6)
                    best = bestIn(doc.alias, v, 2.6 * syn, best);
                if (best < 1.3)
                    best = bestIn(doc.secondary, v, 1.3 * syn, best);
                if (best < 1)
                    best = bestIn(doc.context, v, syn, best);
            }
            if (best > 0)
                hit++;
            total += best;
        }
        const qwords = prepared;
        if (!hit)
            return 0;
        const cover = hit / qwords.length;
        let s = total * Math.pow(cover, 1.5);
        const title = norm(doc.title);
        if (title === phrase)
            s += 3;
        else if (title.startsWith(phrase))
            s += 1;
        else if (phrase.length > 2 && title.includes(phrase))
            s += 0.8;
        // a page's everyday name typed as is: "экран" → Monitor, "display" → Monitor
        if (doc.aliasNames.includes(phrase))
            s += 3.5;
        return s + (doc.kind === "page" ? 0.4 : doc.kind === "group" ? 0.2 : 0);
    }

    function meaningful(phrase) {
        const w = phrase.split(" ").filter(x => x && !stopwords.includes(x));
        return w.length ? w.join(" ") : phrase;
    }
    function search(text, limit) {
        const phrase = meaningful(norm(text));
        if (!phrase)
            return [];
        const variants = [phrase];
        const swapped = meaningful(norm(swapLayout(phrase)));
        if (swapped !== phrase)
            variants.push(swapped);
        // what the ghost completion suggests counts too ("Bl" → Blur ranks first)
        const ghost = complete(text);
        if (ghost)
            variants.push(meaningful(norm(text + ghost)));
        const res = [];
        const prepared = variants.map(v => prepare(v.split(" ")));
        if (Object.keys(_cache).length > 50000)
            _cache = {};
        for (const doc of docs) {
            let best = 0;
            for (let i = 0; i < variants.length; i++)
                best = Math.max(best, scoreDoc(doc, prepared[i], variants[i]) * (i === 0 ? 1 : variants[i] === swapped ? 0.92 : 1.1));
            // one or two letters only count against names, not descriptions
            if (best >= (phrase.length <= 2 ? 2.2 : 1.2))
                res.push({
                    "doc": doc,
                    "score": best
                });
        }
        res.sort((a, b) => b.score - a.score || a.doc.title.length - b.doc.title.length);
        const out = [], seen = {};
        for (const r of res) {
            const key = r.doc.page + "|" + r.doc.title;
            if (seen[key])
                continue;
            seen[key] = true;
            out.push(Object.assign({
                "score": r.score
            }, r.doc));
            if (out.length >= (limit || 12))
                break;
        }
        return out;
    }

    readonly property var vocabulary: {
        const v = {};
        for (const d of docs)
            for (const w of d.primary.concat(d.other, d.alias))
                v[w] = true;
        for (const c of common)
            for (const w of words(c))
                v[w] = true;
        return v;
    }
    // ghost completion for what is typed: the rest of the word or name ("Bl" → "ur")
    function complete(text) {
        const raw = String(text || "");
        if (!raw.trim() || /\s$/.test(raw))
            return "";
        const low = raw.toLowerCase();
        const lastStart = raw.search(/\S+$/);
        const last = raw.slice(lastStart).toLowerCase();
        // a finished word ("display") needs no completion
        if (last.length >= 3 && vocabulary[norm(last)])
            return "";
        const fit = w => w.toLowerCase().startsWith(low) && w.length > raw.length ? w.slice(raw.length) : "";
        const fitLast = w => w.toLowerCase().startsWith(last) && w.length > last.length ? w.slice(last.length) : "";
        // whole names first: common words, then page / group / row names
        const names = common.concat(docs.filter(d => d.kind === "page").map(d => d.title), docs.filter(d => d.kind === "group").map(d => d.title), docs.filter(d => d.kind === "row").map(d => d.title));
        for (const n of names) {
            const r = fit(n);
            if (r)
                return r;
        }
        if (lastStart > 0 && last.length >= 2)
            for (const n of names)
                for (const w of n.split(/\s+/)) {
                    const r = fitLast(w);
                    if (r)
                        return r;
                }
        return "";
    }
}
