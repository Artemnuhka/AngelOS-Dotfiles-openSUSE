.pragma library

// Helpers for positioning layer-shell popups from a "top-left" … "bottom-right" / "center" id.
function top(p) { return p.indexOf("top") === 0; }
function bottom(p) { return p.indexOf("bottom") === 0; }
function left(p) { return p.indexOf("left") >= 0; }
function right(p) { return p.indexOf("right") >= 0; }
