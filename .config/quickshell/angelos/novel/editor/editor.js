// angelOS novel editor (served by nov-editor.py). The rules — templates, conditions,
// checks, node blanks — are NovelCore.js (loaded before this file as /core.js), the same
// file the shell's engine runs, so the play-test here behaves like the real thing.
"use strict";

const $ = (s, el = document) => el.querySelector(s);
const el = (tag, attrs = {}, ...kids) => {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") e.className = v;
    else if (k.startsWith("on")) e.addEventListener(k.slice(2), v);
    else if (v !== undefined && v !== null && v !== false) e.setAttribute(k, v === true ? "" : v);
  }
  for (const k of kids.flat()) if (k !== null && k !== undefined && k !== false) e.append(k.nodeType ? k : document.createTextNode(String(k)));
  return e;
};
const svg = (tag, attrs = {}) => {
  const e = document.createElementNS("http://www.w3.org/2000/svg", tag);
  for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v);
  return e;
};

const TYPE_INFO = {
  event: { label: "событие", color: "#67e0a3", add: "+ событие" },
  say: { label: "реплика", color: "#ff8fb8", add: "+ реплика" },
  choice: { label: "вопрос", color: "#c8a8ff", add: "+ вопрос" },
  note: { label: "записка", color: "#efe1bd", add: "+ записка" },
  set: { label: "переменные", color: "#7fd3ff", add: "+ переменные" },
  if: { label: "условие", color: "#ffcf5c", add: "+ условие" },
  random: { label: "случайно", color: "#ffa65c", add: "+ случайно" },
  free: { label: "свобода", color: "#9ff0ff", add: "+ свобода" },
  end: { label: "конец", color: "#b59fb0", add: "+ конец" },
};
const WHO_LABEL = { angel: "Ангел", demon: "Демоница", narrator: "Рассказчик" };
const TONE_LABEL = { positive: "добрый", negative: "злой", silent: "молчание", neutral: "нейтральный" };
const WHEN_LABEL = { now: "сразу", click: "по клику на неё", resume: "после сна" };
const COMMON_SPRITES = ["neutral", "smile", "happy", "sad", "angry", "surprised", "shy", "curious", "worried", "sleepy", "smug"];

const S = {
  info: { stories: [], sprites: {} },
  file: "",
  story: null,
  sel: "",
  dirty: false,
  view: { x: 40, y: 40, k: 1 },
  pos: {},          // computed positions (layout + auto)
};

// ---------- server ----------
async function api(path, opts) {
  const r = await fetch(path, opts);
  const j = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(j.error || r.statusText);
  return j;
}
async function loadInfo() {
  S.info = await api("/api/info");
  $("#spriteDir").textContent = S.info.dir + "/sprites";
}
async function loadStory(file) {
  if (S.dirty && !confirm("Есть несохранённые изменения. Открыть другую главу?")) {
    $("#storySel").value = S.file;
    return;
  }
  S.story = await api("/api/story?f=" + encodeURIComponent(file));
  S.story.nodes = S.story.nodes || {};
  S.story.pools = S.story.pools || { questions: [], drops: [] };
  S.story.pools.questions = S.story.pools.questions || [];
  S.story.pools.drops = S.story.pools.drops || [];
  S.story.ambient = S.story.ambient || { questions: [25, 70], drops: [30, 90] };
  S.story.vars = S.story.vars || {};
  S.story.layout = S.story.layout || {};
  S.file = file;
  S.sel = S.story.start || Object.keys(S.story.nodes)[0] || "";
  setDirty(false);
  renderAll();
  fit();
}
async function save() {
  if (!S.story) return;
  try {
    await api("/api/story?f=" + encodeURIComponent(S.file), { method: "PUT", body: JSON.stringify(S.story) });
    setDirty(false);
    status("сохранено ♡ " + new Date().toLocaleTimeString().slice(0, 5));
  } catch (e) {
    status("не сохранилось: " + e.message, true);
  }
}
function status(t, bad) {
  const s = $("#status");
  s.textContent = t;
  s.className = bad ? "dirty" : "";
}
function setDirty(d) {
  S.dirty = d;
  if (d) status("● есть изменения", true);
}
let saveSoon = 0;
function changed(opts = {}) {
  setDirty(true);
  clearTimeout(saveSoon);
  renderList();
  renderGraph();
  renderProblems();
  if (opts.inspector) renderInspector();
  if (opts.pools) renderPools();
}

// ---------- helpers ----------
function nodes() { return S.story ? S.story.nodes : {}; }
function ids() { return Object.keys(nodes()); }
function newId(base) {
  let n = 1;
  base = (base || "node").replace(/[^\wа-яё-]/gi, "_");
  while (nodes()[base + "_" + n]) n++;
  return base + "_" + n;
}
function preview(n) {
  if (!n) return "";
  switch (n.type) {
    case "note": return (n.title ? n.title + ": " : "") + (n.text || "");
    case "if": return n.cond || "(без условия)";
    case "set": return Object.entries(n.set || {}).map(([k, v]) => k + " " + v).join(", ") || "(ничего)";
    case "event": return { resume: "после сна", start: "при запуске", manual: "вручную" }[n.trigger] || n.trigger || "";
    case "random": return (Array.isArray(n.next) ? n.next : []).join(" / ");
    case "free": return "вопросы и записки сами по себе";
    case "end": return n.chapter ? "→ " + n.chapter : "конец главы";
  }
  return n.text || "";
}
function spriteUrl(who, name) {
  return "/sprites/" + encodeURIComponent(who || "angel") + "/" + encodeURIComponent(name || "neutral") + ".png";
}
function hasSprite(who, name) {
  return (S.info.sprites[who] || []).includes(name);
}
// all places that point at a node id
function renameRefs(from, to) {
  for (const n of Object.values(nodes())) {
    if (n.next === from) n.next = to;
    if (Array.isArray(n.next)) n.next = n.next.map(x => x === from ? to : x);
    if (n.then === from) n.then = to;
    if (n["else"] === from) n["else"] = to;
    for (const c of n.choices || []) if (c.next === from) c.next = to;
  }
  const q = S.story.pools.questions;
  S.story.pools.questions = q.map(x => x === from ? to : x).filter(x => x);
  if (S.story.start === from) S.story.start = to;
  if (S.story.layout[from]) {
    if (to) S.story.layout[to] = S.story.layout[from];
    delete S.story.layout[from];
  }
}
function addNode(type, linkFrom) {
  const id = newId({ say: "line", choice: "q", note: "note", set: "set", if: "if", random: "rand", free: "free", end: "end", event: "event" }[type] || type);
  const n = NovelCore_blank(type);
  if (S.sel && nodes()[S.sel] && (n.who !== undefined)) {
    const cur = nodes()[S.sel];
    if (cur.who) n.who = cur.who;
  }
  nodes()[id] = n;
  // placed right of the selected node
  const p = S.pos[linkFrom || S.sel];
  if (p) S.story.layout[id] = { x: p.x + 280, y: p.y + 40 };
  if (linkFrom) {
    const f = nodes()[linkFrom];
    if (f && f.type !== "choice" && f.type !== "if" && f.type !== "random" && !f.next) f.next = id;
  }
  S.sel = id;
  changed({ inspector: true });
  return id;
}
function deleteNode(id) {
  if (!confirm("Удалить узел «" + id + "»? Ссылки на него станут пустыми.")) return;
  delete nodes()[id];
  renameRefs(id, "");
  S.sel = S.story.start || "";
  changed({ inspector: true, pools: true });
}

// NovelCore is loaded as a plain script: its functions are globals
const NovelCore_blank = typeof blank === "function" ? blank : (t) => ({ type: t });

// ---------- left: list ----------
function renderList() {
  const box = $("#list");
  box.innerHTML = "";
  if (!S.story) return;
  const q = $("#find").value.trim().toLowerCase();
  const bad = new Set(validate(S.story).filter(p => p.level === "error").map(p => p.node));
  for (const id of ids()) {
    const n = nodes()[id];
    const tx = preview(n);
    if (q && !(id + " " + tx + " " + JSON.stringify(n.choices || "")).toLowerCase().includes(q)) continue;
    box.append(el("div", { class: "item" + (id === S.sel ? " sel" : ""), onclick: () => select(id, true) },
      el("span", { class: "tag", style: "color:" + (TYPE_INFO[n.type] || {}).color }, (TYPE_INFO[n.type] || {}).label || n.type),
      el("span", { class: "id" }, id),
      id === S.story.start ? el("span", { class: "tag start" }, "старт") : null,
      bad.has(id) ? el("span", { class: "tag", style: "color:var(--bad)" }, "!") : null,
      el("span", { class: "tx" }, tx)));
  }
}
function select(id, center) {
  S.sel = id;
  renderList();
  renderGraph();
  renderInspector();
  if (center && S.pos[id]) {
    const r = $("#graph").getBoundingClientRect();
    S.view.x = r.width / 2 - (S.pos[id].x + 110) * S.view.k;
    S.view.y = r.height / 2 - (S.pos[id].y + 40) * S.view.k;
    applyView();
  }
}

// ---------- graph ----------
const NW = 230;
function nodeHeight(n) {
  const base = 58;
  if (n.type === "choice") return base + 18 * (n.choices || []).length;
  return base;
}
// top to bottom: the story runs down the page, a choice's answers fan out side by side.
// The start's tree first, then each pool question's tree in its own column group to the right.
const COLW = 260, GAPY = 46;
function layout() {
  const st = S.story;
  const pos = {};
  const roots = [st.start].concat(st.pools.questions).filter(id => nodes()[id]);
  for (const id of ids()) if (!roots.includes(id) && !Object.values(nodes()).some(n => exits(n).some(x => x.to === id))) roots.push(id);
  const placed = {};
  let groupX = 0;
  for (const r of roots) {
    if (placed[r]) continue;
    // depth by breadth-first search, inside this group only
    const depth = { [r]: 0 };
    const order = [r];
    placed[r] = true;
    for (let i = 0; i < order.length; i++) {
      for (const e of exits(nodes()[order[i]])) {
        if (nodes()[e.to] && !placed[e.to]) {
          placed[e.to] = true;
          depth[e.to] = depth[order[i]] + 1;
          order.push(e.to);
        }
      }
    }
    const rows = {};
    for (const id of order) (rows[depth[id]] = rows[depth[id]] || []).push(id);
    const width = Math.max(...Object.values(rows).map(r => r.length));
    let y = 0;
    for (let d = 0; rows[d]; d++) {
      const row = rows[d];
      const off = (width - row.length) * COLW / 2;
      row.forEach((id, i) => pos[id] = { x: groupX + off + i * COLW, y });
      y += Math.max(...row.map(id => nodeHeight(nodes()[id]))) + GAPY;
    }
    groupX += width * COLW + 80;
  }
  return pos;
}
function computePos() {
  const auto = layout();
  S.pos = {};
  for (const id of ids()) S.pos[id] = S.story.layout[id] ? { x: S.story.layout[id].x, y: S.story.layout[id].y } : auto[id];
}
function applyView() {
  const g = $("#graph").querySelector("g.root");
  if (g) g.setAttribute("transform", `translate(${S.view.x},${S.view.y}) scale(${S.view.k})`);
}
function wrapText(t, max) {
  t = String(t || "").replace(/\s+/g, " ");
  return t.length > max ? t.slice(0, max - 1) + "…" : t;
}
function renderGraph() {
  const g0 = $("#graph");
  g0.innerHTML = "";
  if (!S.story) return;
  computePos();
  const defs = svg("defs");
  for (const k of ["next", "positive", "negative", "silent", "neutral", "then", "else", "random"]) {
    const m = svg("marker", { id: "arr-" + k, viewBox: "0 0 10 10", refX: 9, refY: 5, markerWidth: 7, markerHeight: 7, orient: "auto-start-reverse" });
    const p = svg("path", { d: "M0,0 L10,5 L0,10 z", class: "edge " + k, style: "fill:currentColor;stroke:none" });
    m.append(p);
    defs.append(m);
  }
  g0.append(defs);
  const root = svg("g", { class: "root" });
  g0.append(root);
  const bad = new Set(validate(S.story).filter(p => p.level === "error").map(p => p.node));
  const edges = svg("g");
  root.append(edges);
  for (const id of ids()) {
    const n = nodes()[id], a = S.pos[id];
    exits(n).forEach((e, i) => {
      const b = S.pos[e.to];
      if (!b) return;
      const h = nodeHeight(n);
      const outs = exits(n).length;
      // leave from the bottom, spread when there are several ways out; arrive on the top
      const x1 = a.x + NW * (outs > 1 ? (i + 1) / (outs + 1) : 0.5), y1 = a.y + h;
      const x2 = b.x + NW / 2, y2 = b.y;
      const back = y2 <= y1;
      const dy = Math.max(30, Math.abs(y2 - y1) / 2);
      const side = Math.max(a.x, b.x) + NW + 40;
      const d = back
        ? `M${x1},${y1} C${x1},${y1 + 40} ${side},${y1 + 40} ${side},${(y1 + y2) / 2} S${x2},${y2 - 40} ${x2},${y2}`
        : `M${x1},${y1} C${x1},${y1 + dy} ${x2},${y2 - dy} ${x2},${y2}`;
      const kind = e.kind;
      const path = svg("path", { d, class: "edge " + kind, "marker-end": "url(#arr-" + kind + ")" });
      edges.append(path);
      if (e.label && n.type !== "choice") {
        const t = svg("text", { x: (x1 + x2) / 2, y: (y1 + y2) / 2 - 4, class: "edgeLabel", "text-anchor": "middle" });
        t.textContent = e.label;
        edges.append(t);
      }
    });
  }
  for (const id of ids()) {
    const n = nodes()[id], p = S.pos[id];
    const h = nodeHeight(n);
    const info = TYPE_INFO[n.type] || { label: n.type, color: "#888" };
    const g = svg("g", { class: "node" + (id === S.sel ? " sel" : "") + (bad.has(id) ? " bad" : ""), transform: `translate(${p.x},${p.y})` });
    g.append(svg("rect", { class: "box", width: NW, height: h }));
    g.append(svg("rect", { width: NW, height: 18, fill: info.color }));
    const tt = svg("text", { x: 6, y: 13, class: "type" });
    tt.textContent = info.label.toUpperCase() + (n.when && n.when !== "now" ? " · " + (WHEN_LABEL[n.when] || n.when.replace("minutes:", "через ") + (n.when.startsWith("minutes:") ? " мин" : "")) : "");
    g.append(tt);
    const head = svg("text", { x: 6, y: 34, class: "head" });
    head.textContent = (id === S.story.start ? "▶ " : "") + id;
    g.append(head);
    if (n.who) {
      const w = svg("text", { x: NW - 6, y: 34, class: "who", "text-anchor": "end" });
      w.textContent = (WHO_LABEL[n.who] || n.who) + (n.sprite ? " · " + n.sprite : "");
      g.append(w);
    }
    const body = svg("text", { x: 6, y: 50, class: "body" });
    body.textContent = wrapText(preview(n), 34);
    g.append(body);
    if (n.type === "choice")
      (n.choices || []).forEach((c, i) => {
        const t = svg("text", { x: 14, y: 68 + 18 * i, class: "body", style: "fill:" + ({ positive: "#67e0a3", negative: "#ff5d73", silent: "#9a9aaa" }[c.tone] || "#c8a8ff") });
        t.textContent = (i + 1) + ". " + wrapText(c.text, 30);
        g.append(t);
      });
    g.addEventListener("mousedown", ev => startDrag(ev, id));
    g.addEventListener("dblclick", ev => { ev.stopPropagation(); openPlayer(id); });
    root.append(g);
  }
  applyView();
}
// dragging nodes and panning
let drag = null;
function startDrag(ev, id) {
  ev.stopPropagation();
  if (ev.button !== 0) return;
  drag = { id, sx: ev.clientX, sy: ev.clientY, x: S.pos[id].x, y: S.pos[id].y, moved: false };
}
function graphEvents() {
  const g = $("#graph");
  let pan = null;
  g.addEventListener("mousedown", ev => {
    if (ev.button !== 0 && ev.button !== 1) return;
    pan = { sx: ev.clientX, sy: ev.clientY, x: S.view.x, y: S.view.y };
    g.classList.add("panning");
  });
  window.addEventListener("mousemove", ev => {
    if (drag) {
      const dx = (ev.clientX - drag.sx) / S.view.k, dy = (ev.clientY - drag.sy) / S.view.k;
      if (Math.abs(dx) + Math.abs(dy) > 3) drag.moved = true;
      if (drag.moved) {
        S.story.layout[drag.id] = { x: Math.round((drag.x + dx) / 10) * 10, y: Math.round((drag.y + dy) / 10) * 10 };
        renderGraph();
      }
    } else if (pan) {
      S.view.x = pan.x + ev.clientX - pan.sx;
      S.view.y = pan.y + ev.clientY - pan.sy;
      applyView();
    }
  });
  window.addEventListener("mouseup", () => {
    if (drag) {
      if (drag.moved) setDirty(true);
      else select(drag.id);
    }
    drag = null;
    pan = null;
    g.classList.remove("panning");
  });
  g.addEventListener("wheel", ev => {
    ev.preventDefault();
    const r = g.getBoundingClientRect();
    const mx = ev.clientX - r.left, my = ev.clientY - r.top;
    const k = Math.min(2.5, Math.max(0.2, S.view.k * (ev.deltaY < 0 ? 1.12 : 1 / 1.12)));
    S.view.x = mx - (mx - S.view.x) * k / S.view.k;
    S.view.y = my - (my - S.view.y) * k / S.view.k;
    S.view.k = k;
    applyView();
  }, { passive: false });
}
function fit() {
  if (!S.story || !ids().length) return;
  computePos();
  const xs = ids().map(i => S.pos[i].x), ys = ids().map(i => S.pos[i].y);
  const minX = Math.min(...xs), maxX = Math.max(...xs) + NW, minY = Math.min(...ys), maxY = Math.max(...ys) + 120;
  const r = $("#graph").getBoundingClientRect();
  // the whole width if it fits readably, else the start's column at a readable size
  let k = Math.min(1.1, r.width / (maxX - minX + 80));
  if (k < 0.55) k = 0.8;
  const sx = k < r.width / (maxX - minX + 80) + 0.001 ? (r.width - (maxX - minX) * k) / 2 - minX * k : 40 - minX * k;
  S.view = { k, x: sx, y: 30 - minY * k };
  applyView();
}

// ---------- right: inspector ----------
function field(label, input, hint) {
  return [el("label", { class: "f" }, label), input].concat(hint ? [el("div", { class: "hint" }, hint)] : []);
}
function textInput(obj, key, ph, after) {
  return el("input", { value: obj[key] || "", placeholder: ph || "", oninput: e => { obj[key] = e.target.value; changed(); if (after) after(); } });
}
function textArea(obj, key, ph) {
  const ta = el("textarea", { placeholder: ph || "", spellcheck: "true", oninput: e => { obj[key] = e.target.value; changed(); } });
  ta.value = obj[key] || "";
  return ta;
}
function templateButtons(ta, obj, key) {
  const ins = s => {
    const a = ta.selectionStart, b = ta.selectionEnd;
    ta.value = ta.value.slice(0, a) + s + ta.value.slice(b);
    ta.focus();
    ta.selectionStart = ta.selectionEnd = a + s.length;
    obj[key] = ta.value;
    changed();
  };
  return el("div", { class: "tmpl" },
    el("button", { title: "Слово по полу: парень|девушка|не указан", onclick: () => ins("{g:хотел|хотела|хотел(а)}") }, "{g:…|…}"),
    ...["{name}", "{app}", "{song}", "{time}", "{daypart}"].map(t => el("button", { onclick: () => ins(t) }, t)));
}
function nodeSelect(value, onpick, allowNew = true) {
  const s = el("select", {
    onchange: e => {
      const v = e.target.value;
      if (v.startsWith("+new:")) {
        const id = addNode(v.slice(5));
        onpick(id);
        changed({ inspector: false });
        select(S.sel);
      } else {
        onpick(v);
        changed();
      }
    }
  });
  s.append(el("option", { value: "" }, "— никуда —"));
  for (const id of ids()) s.append(el("option", { value: id, selected: id === value }, id + " · " + wrapText(preview(nodes()[id]), 26)));
  if (allowNew) for (const t of ["say", "choice", "note", "if", "set", "random", "free", "end"]) s.append(el("option", { value: "+new:" + t }, "＋ новый: " + TYPE_INFO[t].label));
  s.value = value || "";
  return s;
}
function whoSelect(obj, after) {
  const s = el("select", { onchange: e => { obj.who = e.target.value; changed(); if (after) after(); } });
  for (const w of ["angel", "demon", "narrator"]) s.append(el("option", { value: w, selected: obj.who === w }, WHO_LABEL[w]));
  return s;
}
function spritePicker(obj) {
  const who = obj.who || "angel";
  const have = S.info.sprites[who] || [];
  const names = [...new Set(have.concat(COMMON_SPRITES))];
  const list = "dl-" + Math.random().toString(36).slice(2);
  const dl = el("datalist", { id: list }, names.map(n => el("option", { value: n }, hasSprite(who, n) ? "есть" : "нет файла")));
  const img = el("img", { src: spriteUrl(who, obj.sprite), alt: "" });
  const miss = el("div", { class: "thumb missing" }, "нет файла");
  const upd = () => {
    const ok = hasSprite(who, obj.sprite || "neutral");
    img.hidden = !ok;
    miss.hidden = ok;
    img.src = spriteUrl(who, obj.sprite);
  };
  const inp = el("input", { value: obj.sprite || "", list, placeholder: "neutral", oninput: e => { obj.sprite = e.target.value; upd(); changed(); } });
  upd();
  return el("div", { class: "spritePick" }, img, miss, el("div", { style: "flex:1" }, inp, dl,
    el("div", { class: "hint" }, "файл: sprites/" + who + "/" + (obj.sprite || "neutral") + ".png")));
}
function whenSelect(n) {
  const s = el("select", {
    onchange: e => {
      const v = e.target.value;
      if (v === "minutes") n.when = "minutes:" + (parseInt(prompt("Через сколько минут?", "20")) || 20);
      else if (v === "now") delete n.when;
      else n.when = v;
      changed({ inspector: true });
    }
  });
  const cur = n.when || "now";
  for (const [v, l] of [["now", "сразу"], ["click", "когда нажмут на неё («?» над головой)"], ["resume", "после выхода из сна"], ["minutes", cur.startsWith("minutes:") ? "через " + cur.slice(8) + " мин (изменить…)" : "через N минут…"]])
    s.append(el("option", { value: v, selected: v === cur || (v === "minutes" && cur.startsWith("minutes:")) }, l));
  return s;
}
function setEditor(obj, key) {
  obj[key] = obj[key] || {};
  const box = el("div");
  const draw = () => {
    box.innerHTML = "";
    for (const [k, v] of Object.entries(obj[key])) {
      box.append(el("div", { class: "kv" },
        el("input", { value: k, onchange: e => { const nv = e.target.value.trim(); const val = obj[key][k]; delete obj[key][k]; if (nv) obj[key][nv] = val; changed(); draw(); } }),
        el("input", { value: typeof v === "string" ? v : JSON.stringify(v), title: "+1 / -1 — прибавить; иначе — значение", oninput: e => { obj[key][k] = parseValue(e.target.value); changed(); } }),
        el("button", { class: "danger", onclick: () => { delete obj[key][k]; changed(); draw(); } }, "✕")));
    }
    box.append(el("button", { onclick: () => { obj[key][newVarName()] = "+1"; changed(); draw(); } }, "+ изменить переменную"));
  };
  draw();
  return box;
}
function newVarName() {
  const vs = Object.keys(S.story.vars);
  return vs.find(v => v !== "gender" && v !== "setupGender") || "trust";
}
function parseValue(s) {
  s = String(s).trim();
  if (/^[+-]\d+(\.\d+)?$/.test(s)) return s;
  if (/^-?\d+(\.\d+)?$/.test(s)) return parseFloat(s);
  if (s === "true" || s === "false") return s === "true";
  return s.replace(/^"(.*)"$/, "$1");
}
function renderInspector() {
  const box = $("#inspector");
  box.innerHTML = "";
  const n = nodes()[S.sel];
  if (!S.story || !n) {
    box.append(el("p", { class: "empty" }, "Выбери узел на графе или в списке."));
    return;
  }
  const id = S.sel;
  const info = TYPE_INFO[n.type] || { label: n.type, color: "#888" };
  box.append(el("h2", {}, el("span", { class: "tag", style: "color:" + info.color }, info.label), id));
  const idInput = el("input", { value: id });
  box.append(el("div", { class: "row" }, idInput,
    el("button", {
      onclick: () => {
        const nv = idInput.value.trim().replace(/\s+/g, "_");
        if (!nv || nv === id) return;
        if (nodes()[nv]) return alert("Такой узел уже есть");
        nodes()[nv] = n;
        delete nodes()[id];
        renameRefs(id, nv);
        S.sel = nv;
        changed({ inspector: true, pools: true });
      }
    }, "переименовать"),
    el("button", { onclick: () => { S.story.start = id; changed({ inspector: true }); }, disabled: S.story.start === id }, id === S.story.start ? "старт ✓" : "сделать стартом"),
    el("button", { onclick: () => openPlayer(id) }, "▶ отсюда"),
    el("button", { class: "danger", onclick: () => deleteNode(id) }, "удалить")));

  if (n.type !== "event" && n.type !== "end")
    box.append(...field("Когда", whenSelect(n), "«по клику» — ангел ждёт, пока на неё нажмут (над головой «?»)."));

  switch (n.type) {
    case "event": {
      const s = el("select", { onchange: e => { n.trigger = e.target.value; changed(); } });
      for (const [v, l] of [["resume", "после выхода компьютера из сна"], ["start", "при запуске angelOS"], ["manual", "только вручную (angelos novel start)"]])
        s.append(el("option", { value: v, selected: n.trigger === v }, l));
      box.append(...field("Глава начинается", s));
      box.append(...field("Дальше", nodeSelect(n.next, v => n.next = v)));
      break;
    }
    case "say":
    case "choice": {
      box.append(...field("Кто говорит", whoSelect(n, renderInspector)));
      box.append(...field("Спрайт (эмоция)", spritePicker(n)));
      const ta = textArea(n, "text", n.type === "choice" ? "Вопрос…" : "Реплика…");
      box.append(...field(n.type === "choice" ? "Вопрос" : "Текст", ta), templateButtons(ta, n, "text"));
      if (n.type === "say") box.append(...field("Дальше", nodeSelect(n.next, v => n.next = v)));
      else {
        box.append(el("label", { class: "f" }, "Варианты ответа (обычно три)"));
        (n.choices || []).forEach((c, i) => box.append(choiceEditor(n, c, i)));
        box.append(el("button", { onclick: () => { n.choices.push({ text: "", tone: "neutral", next: "" }); changed({ inspector: true }); } }, "+ вариант"));
      }
      break;
    }
    case "note": {
      const s = el("select", { onchange: e => { n.from = e.target.value; changed(); } });
      for (const [v, l] of [["desk", "лежит на обоях (скомканный листок)"], ["angel", "ангел роняет его"]]) s.append(el("option", { value: v, selected: (n.from || "desk") === v }, l));
      box.append(...field("Откуда", s));
      box.append(...field("Заголовок", textInput(n, "title", "Скомканный листок")));
      const ta = textArea(n, "text", "Что написано на листке…");
      ta.style.fontFamily = "var(--hand)";
      ta.style.fontSize = "20px";
      box.append(...field("Текст записки", ta), templateButtons(ta, n, "text"));
      box.append(...field("Когда прочитают — дальше", nodeSelect(n.next, v => n.next = v)));
      break;
    }
    case "set":
      box.append(el("label", { class: "f" }, "Изменить переменные"), setEditor(n, "set"));
      box.append(...field("Дальше", nodeSelect(n.next, v => n.next = v)));
      break;
    case "if": {
      const inp = textInput(n, "cond", 'trust >= 2 and gender == "f"', () => { err.textContent = checkCond(n.cond) ? "⚠ " + checkCond(n.cond) : "✓"; });
      const err = el("div", { class: "hint" }, checkCond(n.cond) ? "⚠ " + checkCond(n.cond) : "✓");
      box.append(...field("Условие", inp), err,
        el("div", { class: "hint" }, "сравнения == != > < >= <=, и/или/не (and/or/not), seen(\"узел\") — был ли узел. Переменные: " + Object.keys(S.story.vars).join(", ")));
      box.append(...field("Если да", nodeSelect(n.then, v => n.then = v)));
      box.append(...field("Если нет", nodeSelect(n["else"], v => n["else"] = v)));
      break;
    }
    case "random": {
      n.next = Array.isArray(n.next) ? n.next : (n.next ? [n.next] : []);
      box.append(el("label", { class: "f" }, "Один из (наугад)"));
      n.next.forEach((to, i) => box.append(el("div", { class: "row" }, nodeSelect(to, v => n.next[i] = v),
        el("button", { class: "danger", onclick: () => { n.next.splice(i, 1); changed({ inspector: true }); } }, "✕"))));
      box.append(el("button", { onclick: () => { n.next.push(""); changed({ inspector: true }); } }, "+ вариант"));
      break;
    }
    case "free":
      box.append(el("p", { class: "hint" }, "С этого узла ангел сама время от времени задаёт вопросы из пула (слева) и роняет записки. Дальше может идти главная линия — например, вопрос «через 20 минут»."));
      box.append(...field("Дальше", nodeSelect(n.next, v => n.next = v)));
      break;
    case "end":
      box.append(...field("Следующая глава (файл без .json)", textInput(n, "chapter", "chapter2")));
      break;
  }
  box.append(...field("Заметка для себя", textArea(n, "note", "не видно в игре")));
  if (["choice", "say"].includes(n.type)) {
    const inPool = S.story.pools.questions.includes(id);
    if (n.type === "choice")
      box.append(el("div", { class: "row" }, el("label", { class: "inline" },
        el("input", { type: "checkbox", checked: inPool, onchange: e => { const q = S.story.pools.questions; if (e.target.checked && !q.includes(id)) q.push(id); if (!e.target.checked) S.story.pools.questions = q.filter(x => x !== id); changed({ pools: true }); } }),
        "в пуле случайных вопросов")));
  }
}
function choiceEditor(n, c, i) {
  const box = el("div", { class: "choice " + (c.tone || "neutral") });
  const tone = el("select", { onchange: e => { c.tone = e.target.value; changed({ inspector: true }); } });
  for (const t of ["positive", "negative", "silent", "neutral"]) tone.append(el("option", { value: t, selected: c.tone === t }, TONE_LABEL[t]));
  box.append(el("div", { class: "row" }, el("b", {}, (i + 1) + "."), el("div", { style: "flex:1" }, textInput(c, "text", "Ответ игрока")), tone,
    el("button", { title: "выше", onclick: () => { if (i > 0) { n.choices.splice(i - 1, 0, n.choices.splice(i, 1)[0]); changed({ inspector: true }); } } }, "↑"),
    el("button", { class: "danger", onclick: () => { n.choices.splice(i, 1); changed({ inspector: true }); } }, "✕")));
  // her reaction
  c.reply = c.reply || null;
  const rep = el("div", { class: "reply" });
  if (!c.reply) rep.append(el("button", { onclick: () => { c.reply = { who: n.who || "angel", sprite: "happy", text: "" }; changed({ inspector: true }); } }, "+ её реакция"));
  else {
    rep.append(el("div", { class: "row" }, el("span", { class: "hint" }, "реакция:"), whoSelect(c.reply, renderInspector),
      el("button", { class: "danger", onclick: () => { c.reply = null; delete c.reply; changed({ inspector: true }); } }, "без реакции")));
    rep.append(spritePicker(c.reply));
    const ta = textArea(c.reply, "text", "Что она ответит…");
    ta.style.minHeight = "44px";
    rep.append(ta, templateButtons(ta, c.reply, "text"));
  }
  box.append(rep);
  box.append(el("label", { class: "f" }, "Меняет переменные"), setEditor(c, "set"));
  box.append(...field("Потом", nodeSelect(c.next, v => c.next = v)));
  return box;
}

// ---------- pools, variables, sprites ----------
function renderPools() {
  if (!S.story) return;
  const q = $("#poolQ");
  q.innerHTML = "";
  for (const id of S.story.pools.questions)
    q.append(el("div", { class: "row" }, el("a", { href: "#", onclick: e => { e.preventDefault(); select(id, true); } }, id),
      el("span", { class: "hint", style: "flex:1;margin:0" }, wrapText(preview(nodes()[id]), 28)),
      el("button", { class: "danger", onclick: () => { S.story.pools.questions = S.story.pools.questions.filter(x => x !== id); changed({ pools: true }); } }, "✕")));
  const add = $("#poolQAdd");
  add.innerHTML = "";
  for (const id of ids().filter(i => nodes()[i].type === "choice" && !S.story.pools.questions.includes(i))) add.append(el("option", { value: id }, id));
  const d = $("#poolD");
  d.innerHTML = "";
  S.story.pools.drops.forEach((dr, i) => {
    const ta = el("textarea", { oninput: e => { dr.text = e.target.value; changed(); } });
    ta.value = dr.text || "";
    ta.style.minHeight = "40px";
    d.append(el("div", { class: "choice neutral" }, el("div", { class: "row" }, whoSelect(dr), el("span", { class: "grow" }),
      el("button", { class: "danger", onclick: () => { S.story.pools.drops.splice(i, 1); changed({ pools: true }); } }, "✕")), ta));
  });
  const a = S.story.ambient;
  $("#ambQ1").value = a.questions[0]; $("#ambQ2").value = a.questions[1];
  $("#ambD1").value = a.drops[0]; $("#ambD2").value = a.drops[1];
  renderVars();
  renderSprites();
}
function renderVars() {
  const box = $("#vars");
  box.innerHTML = "";
  for (const [k, v] of Object.entries(S.story.vars))
    box.append(el("div", { class: "kv" },
      el("input", { value: k, onchange: e => { const nv = e.target.value.trim(); const val = S.story.vars[k]; delete S.story.vars[k]; if (nv) S.story.vars[nv] = val; changed({ pools: true }); } }),
      el("input", { value: typeof v === "string" ? '"' + v + '"' : String(v), oninput: e => { S.story.vars[k] = parseValue(e.target.value); changed(); } }),
      el("button", { class: "danger", onclick: () => { delete S.story.vars[k]; changed({ pools: true }); } }, "✕")));
}
function renderSprites() {
  const box = $("#sprites");
  box.innerHTML = "";
  for (const [who, list] of Object.entries(S.info.sprites)) {
    box.append(el("div", { class: "row" }, el("b", {}, WHO_LABEL[who] || who), el("span", { class: "hint", style: "margin:0" }, list.length ? list.length + " шт." : "пусто"),
      el("span", { class: "grow" }), el("button", { onclick: () => api("/api/open?sub=sprites/" + who, { method: "POST" }) }, "📁")));
    const grid = el("div", { class: "spriteGrid" });
    for (const name of list) grid.append(el("figure", {}, el("img", { src: spriteUrl(who, name), alt: name, title: name }), el("figcaption", {}, name)));
    box.append(grid);
  }
}

// ---------- problems ----------
function renderProblems() {
  if (!S.story) return;
  const probs = validate(S.story);
  const errs = probs.filter(p => p.level === "error").length;
  $("#probCount").textContent = errs ? errs : probs.length ? "·" + probs.length : "✓";
  const box = $("#problemList");
  box.innerHTML = "";
  box.className = "probs";
  if (!probs.length) box.append(el("p", { class: "hint" }, "Всё связано, проблем нет ♡"));
  for (const p of probs)
    box.append(el("div", { class: "p " + p.level, onclick: () => p.node && select(p.node, true) }, (p.node ? p.node + ": " : "") + p.text));
}

// ---------- the play-test ----------
const P = { vars: {}, seen: [], node: "", queue: [] };
function ctx() {
  return { vars: P.vars, name: "ты", app: "kitty", song: "любимая песня", now: new Date() };
}
function openPlayer(from) {
  if (!S.story) return;
  $("#player").hidden = false;
  P.vars = Object.assign({}, S.story.vars, { gender: $("#pGender").value, setupGender: $("#pSetup").value });
  P.seen = [];
  run(from || S.story.start);
}
function showLine(who, sprite, text) {
  $("#pPaper").hidden = true;
  const name = $("#pName");
  name.textContent = WHO_LABEL[who] || "";
  name.className = who === "demon" ? "demon" : "";
  const img = $("#pSprite");
  const ok = hasSprite(who, sprite || "neutral");
  img.hidden = !ok || who === "narrator";
  $("#pNoSprite").hidden = ok || who === "narrator";
  $("#pNoSprite").textContent = "нет спрайта «" + (sprite || "neutral") + "»";
  if (ok) img.src = spriteUrl(who, sprite);
  $("#pText").textContent = render(text, ctx());
}
function continueBtn(label, fn) {
  $("#pChoices").append(el("button", { onclick: fn }, label));
}
function run(id) {
  const n = nodes()[id];
  $("#pChoices").innerHTML = "";
  $("#pWhen").textContent = "";
  $("#pNode").textContent = id ? "узел: " + id : "";
  $("#pVars").textContent = Object.entries(P.vars).map(([k, v]) => k + "=" + (v === "" ? '""' : v)).join("  ");
  if (!n) {
    showLine("narrator", "", id ? "(узла «" + id + "» нет)" : "(тут ветка заканчивается)");
    continueBtn("закрыть", closePlayer);
    return;
  }
  P.node = id;
  if (!P.seen.includes(id)) P.seen.push(id);
  if (n.when && n.when !== "now")
    $("#pWhen").textContent = "в игре этот узел ждёт: " + (WHEN_LABEL[n.when] || n.when.replace("minutes:", "") + " мин");
  switch (n.type) {
    case "event":
      showLine("narrator", "", "▶ " + ({ resume: "компьютер вышел из сна…", start: "angelOS запустился…", manual: "глава запущена вручную" }[n.trigger] || ""));
      continueBtn("дальше →", () => run(n.next));
      break;
    case "say":
      showLine(n.who, n.sprite, n.text);
      continueBtn("дальше →", () => run(n.next));
      break;
    case "choice":
      showLine(n.who, n.sprite, n.text);
      (n.choices || []).forEach((c, i) => {
        $("#pChoices").append(el("button", {
          class: c.tone || "", onclick: () => {
            P.vars = applySet(P.vars, c.set);
            if (c.reply && c.reply.text) {
              $("#pChoices").innerHTML = "";
              showLine(c.reply.who || n.who, c.reply.sprite, c.reply.text);
              $("#pVars").textContent = Object.entries(P.vars).map(([k, v]) => k + "=" + v).join("  ");
              continueBtn("дальше →", () => run(c.next));
            } else run(c.next);
          }
        }, (i + 1) + ". " + render(c.text, ctx())));
      });
      break;
    case "note": {
      showLine("narrator", "", n.from === "angel" ? "Ангел роняет листок…" : "На обоях лежит скомканный листок.");
      continueBtn("развернуть", () => {
        const p = $("#pPaper");
        p.hidden = false;
        $(".paperTitle", p).textContent = render(n.title, ctx());
        $(".paperText", p).textContent = render(n.text, ctx());
        $("#pPaperClose").onclick = () => { p.hidden = true; run(n.next); };
      });
      break;
    }
    case "set":
      P.vars = applySet(P.vars, n.set);
      run(n.next);
      return;
    case "if": {
      let ok = false;
      try { ok = evalCond(n.cond, P.vars, P.seen); } catch (e) { showLine("narrator", "", "⚠ условие: " + e.message); return; }
      run(ok ? n.then : n["else"]);
      return;
    }
    case "random": {
      const list = (Array.isArray(n.next) ? n.next : [n.next]).filter(x => x);
      run(list[Math.floor(Math.random() * list.length)]);
      return;
    }
    case "free":
      showLine("narrator", "", "✧ Свобода: теперь вопросы и записки приходят сами (кнопки «случайный вопрос» и «записка» сверху).");
      continueBtn("дальше →", () => run(n.next));
      break;
    case "end":
      showLine("narrator", "", "— конец главы —" + (n.chapter ? " Следующая: " + n.chapter : ""));
      continueBtn("закрыть", closePlayer);
      break;
  }
}
function closePlayer() {
  $("#player").hidden = true;
}

// ---------- boot ----------
function renderAll() {
  if (!S.story) return;
  $("#title").value = S.story.title || "";
  $("#with").value = S.story.with || "angel";
  renderList();
  renderGraph();
  renderInspector();
  renderPools();
  renderProblems();
}
async function refreshStories(pick) {
  await loadInfo();
  const sel = $("#storySel");
  sel.innerHTML = "";
  for (const f of S.info.stories) sel.append(el("option", { value: f }, f.replace(/\.json$/, "")));
  const f = pick || S.file || S.info.stories[0];
  if (f) {
    sel.value = f;
    await loadStory(f);
  }
}
function wire() {
  const add = $("#addrow");
  for (const t of ["say", "choice", "note", "if", "set", "random", "free", "end", "event"])
    add.append(el("button", { onclick: () => addNode(t, S.sel) }, TYPE_INFO[t].add));
  $("#storySel").onchange = e => loadStory(e.target.value);
  $("#newStory").onclick = async () => {
    let name = prompt("Имя файла новой главы (латиница): chapter2", "chapter" + (S.info.stories.length + 1));
    if (!name) return;
    name = name.replace(/\.json$/, "") + ".json";
    try {
      await api("/api/new?f=" + encodeURIComponent(name), { method: "POST" });
      await refreshStories(name);
    } catch (e) { alert(e.message); }
  };
  $("#title").oninput = e => { S.story.title = e.target.value; setDirty(true); };
  $("#with").onchange = e => { S.story.with = e.target.value; setDirty(true); };
  $("#save").onclick = save;
  $("#folder").onclick = () => api("/api/open", { method: "POST" });
  $("#find").oninput = renderList;
  $("#check").onclick = () => { renderProblems(); $("#problems").hidden = !$("#problems").hidden; };
  $("#play").onclick = () => openPlayer(S.story.start);
  $("#relayout").onclick = () => { if (confirm("Разложить все узлы заново (ручные позиции забудутся)?")) { S.story.layout = {}; changed(); fit(); } };
  $("#zoomIn").onclick = () => { S.view.k = Math.min(2.5, S.view.k * 1.2); applyView(); };
  $("#zoomOut").onclick = () => { S.view.k = Math.max(0.2, S.view.k / 1.2); applyView(); };
  $("#zoomFit").onclick = fit;
  for (const b of document.querySelectorAll("[data-close]")) b.onclick = () => { b.closest("#player, .sheet").hidden = true; };
  $("#pRestart").onclick = () => openPlayer(S.story.start);
  $("#pGender").onchange = $("#pSetup").onchange = () => { P.vars.gender = $("#pGender").value; P.vars.setupGender = $("#pSetup").value; run(P.node); };
  $("#pQuestion").onclick = () => {
    const q = S.story.pools.questions;
    if (q.length) run(q[Math.floor(Math.random() * q.length)]);
  };
  $("#pDrop").onclick = () => {
    const d = S.story.pools.drops;
    if (!d.length) return;
    const dr = d[Math.floor(Math.random() * d.length)];
    const p = $("#pPaper");
    p.hidden = false;
    $(".paperTitle", p).textContent = "записка от " + (dr.who === "demon" ? "демоницы" : "ангела");
    $(".paperText", p).textContent = render(dr.text, ctx());
    $("#pPaperClose").onclick = () => { p.hidden = true; };
  };
  $("#poolQAddBtn").onclick = () => { const v = $("#poolQAdd").value; if (v) { S.story.pools.questions.push(v); changed({ pools: true }); } };
  $("#poolDAdd").onclick = () => { S.story.pools.drops.push({ who: "angel", text: "" }); changed({ pools: true }); };
  for (const [idx, key, i] of [["#ambQ1", "questions", 0], ["#ambQ2", "questions", 1], ["#ambD1", "drops", 0], ["#ambD2", "drops", 1]])
    $(idx).oninput = e => { S.story.ambient[key][i] = Math.max(1, parseInt(e.target.value) || 1); setDirty(true); };
  $("#varAdd").onclick = () => { let k = "var", n = 1; while (S.story.vars[k + n] !== undefined) n++; S.story.vars[k + n] = 0; changed({ pools: true }); };
  $("#spritesReload").onclick = async () => { await loadInfo(); renderSprites(); renderInspector(); };
  window.addEventListener("keydown", e => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "s") { e.preventDefault(); save(); }
    if (e.key === "Escape") { $("#player").hidden = true; $("#problems").hidden = true; }
  });
  window.addEventListener("beforeunload", e => { if (S.dirty) { e.preventDefault(); e.returnValue = ""; } });
  graphEvents();
  setInterval(() => fetch("/api/ping").catch(() => status("редактор отключён от сервера", true)), 10000);
  fetch("/api/ping");
}
wire();
refreshStories().then(() => {
  // links into the editor: #node=<id> selects a node, #play runs the chapter
  const h = location.hash.slice(1);
  if (h.startsWith("node=")) select(decodeURIComponent(h.slice(5)), true);
  else if (h.startsWith("play")) openPlayer(h.slice(5) ? decodeURIComponent(h.slice(5)) : S.story.start);
}).catch(e => status(e.message, true));
