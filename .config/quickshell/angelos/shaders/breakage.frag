#version 440
// The demon's mark on her corner of the screen when it isn't glass (ScreenCracks,
// Y2K → Angel or demon → What she breaks):
//   kind 1  a smashed TV: a hole through the screen with snow inside, dead LCD lines
//           bleeding out of it, sparks at the rim, cracks around
//   kind 2  a hole burnt through: hellfire inside, an ember rim, char and scorch, smoke
//   kind 3  claw marks: four tapered gashes glowing neon red, dripping
//   kind 4  a sigil: a pentagram with runes burnt into the glass, drawing itself, smouldering
// All of it on a pixel grid (one cell = Theme.u·2 screen pixels) and stepped in time like
// the sprites. grow 0 → 1: the mark appears; fall 0 → 1: the angel is back and it goes.
// Drawn in the circle's few colours at the end (cEdge → cRim → cDim by brightness, the
// hottest pixels in its one accent): the mark belongs to the circle, not to a cartoon.
// No constant arrays (the GL 1.20 variant of qsb has none).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float kind;
    float cells;     // the square's side in cells
    float t;         // seconds, stepped
    float grow;
    float fall;
    float seed;
    float weak;      // 1: the cracks are set to "weak": smaller
    float ix;        // where her fist landed, 0..1 of the square
    float iy;
    vec4 cEdge;      // the circle's palette (Theme.hellEdge, hellRim, hellTextDim, hellAccent)
    vec4 cRim;
    vec4 cDim;
    vec4 cAccent;
};

const float PI = 3.14159265;
const float TAU = 6.28318531;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i), b = hash(i + vec2(1.0, 0.0)), c = hash(i + vec2(0.0, 1.0)), d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = p * 2.03 + 7.1;
        a *= 0.5;
    }
    return v;
}
// premultiplied: rgb with alpha a on top of what is there
vec4 over(vec4 dst, vec3 rgb, float a) {
    return vec4(rgb * a, a) + dst * (1.0 - a);
}
float segment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-4), 0.0, 1.0);
    return length(pa - ba * h);
}

// ---- 1: the smashed TV ----
vec4 tv(vec2 p, vec2 I, float st, float g, float size) {
    vec4 c = vec4(0.0);
    vec2 d = p - I;
    float r = length(d);
    float a = atan(d.y, d.x);
    float R = cells * 0.27 * size * g;
    // a jagged rim: random radii at 22 points round the hole, straight between them
    float fs = (a + PI) / TAU * 22.0;
    float s0 = floor(fs), s1 = mod(s0 + 1.0, 22.0);
    float edge = R * (0.7 + 0.42 * mix(hash(vec2(s0, seed)), hash(vec2(s1, seed)), fract(fs)));

    // dead LCD lines bleeding out of the hole: columns up, rows to the right
    float hc = hash(vec2(floor(p.x), seed + 11.0));
    if (hc > 0.86 && abs(p.x - I.x) < R * 1.15 && p.y < I.y && r > edge + 2.0) {
        float top = I.y - edge - cells * 0.7 * hash(vec2(floor(p.x), seed + 13.0)) * g;
        if (p.y > top) {
            vec3 lc = hc > 0.955 ? vec3(1.0, 0.2, 0.85) : hc > 0.91 ? vec3(0.2, 1.0, 0.9) : vec3(0.95);
            c = over(c, lc, 0.5 * (0.6 + 0.4 * step(0.3, hash(vec2(floor(p.x), st)))));
        }
    }
    float hr = hash(vec2(floor(p.y), seed + 17.0));
    if (hr > 0.9 && abs(p.y - I.y) < R && p.x > I.x && r > edge + 2.0) {
        float right = I.x + edge + cells * 0.75 * hash(vec2(floor(p.y), seed + 19.0)) * g;
        if (p.x < right)
            c = over(c, hr > 0.96 ? vec3(0.3, 0.45, 1.0) : vec3(0.92, 0.9, 1.0), 0.42);
    }

    // cracks round the hole: eight bent rays, a dark edge under a light one
    for (int k = 0; k < 8; k++) {
        float fk = float(k);
        float ak = -PI + (fk + hash(vec2(fk, seed + 3.0)) * 0.7) / 8.0 * TAU;
        float len = R * (0.6 + 1.5 * hash(vec2(fk, seed + 7.0)));
        for (int sh = 1; sh >= 0; sh--) {
            vec2 dd = d - vec2(float(sh));
            float rr = length(dd);
            float aa = ak + 0.14 * sin(rr * 0.22 + fk * 1.7);
            vec2 dir = vec2(cos(aa), sin(aa));
            float along = dot(dd, dir);
            float off = abs(dd.x * dir.y - dd.y * dir.x);
            if (along > edge * 0.9 && along < edge + len * g && off < 0.6)
                c = over(c, sh == 1 ? vec3(0.03, 0.01, 0.04) : vec3(1.0), sh == 1 ? 0.5 : 0.82);
        }
    }

    if (r < edge) {
        // inside: the dead tube, snow and a rolling band, a last violet glow in the middle
        float depth = r / max(edge, 1.0);
        float snow = hash(p + vec2(st * 17.0, st * 31.0));
        float roll = step(abs(mod(p.y + st * 3.0, 14.0) - 7.0), 1.0);
        float l = (snow > 0.55 ? snow : 0.0) * (0.3 + 0.3 * roll) * (0.5 + 0.5 * depth);
        vec3 col = vec3(0.015, 0.012, 0.02) + vec3(l) + vec3(0.25, 0.05, 0.35) * (1.0 - depth) * 0.3;
        c = over(c, col, 0.97);
    } else if (r < edge + 1.0) {
        c = over(c, vec3(0.95, 0.93, 1.0), 0.85);          // the broken glass' edge
    } else if (r < edge + 2.2) {
        c = over(c, vec3(0.02), 0.55);
    }
    // sparks jump at the rim, a few per frame
    float sector = floor((a + PI) / TAU * 16.0);
    if (hash(vec2(sector, st + seed)) > 0.88 && r > edge - 1.0 && r < edge + 1.5 + 4.0 * hash(vec2(st, sector)) && hash(p + st) > 0.45)
        c = over(c, hash(p * 1.7 + st) > 0.5 ? vec3(1.0, 0.95, 0.6) : vec3(1.0, 0.7, 0.2), 0.95);
    // crumbs of glass round the hole
    if (r > edge + 2.2 && r < edge + 7.0 && hash(p + seed) > 0.975)
        c = over(c, vec3(1.0), 0.7);
    return c;
}

// ---- 2: the hole burnt through ----
vec4 burn(vec2 p, vec2 I, float st, float g, float size) {
    vec4 c = vec4(0.0);
    vec2 d = p - I;
    float r = length(d);
    vec2 n = d / max(r, 0.001);
    float R = cells * 0.25 * size * g;
    float edge = R * (0.68 + 0.62 * fbm(n * 2.2 + seed * 0.01));
    float ring = r - edge;

    // smoke curling up from it
    if (p.y < I.y - edge * 0.3 && abs(p.x - I.x - (I.y - p.y) * 0.18) < edge * 1.3 + 2.0) {
        float s = noise(vec2(p.x * 0.18, p.y * 0.16 + st * 0.6));
        float h = clamp((I.y - p.y) / (cells * 0.75), 0.0, 1.0);
        if (s > 0.6)
            c = over(c, vec3(0.32, 0.28, 0.3), 0.22 * (1.0 - h) * g);
    }

    if (ring < 0.0) {
        // hellfire inside, rising, hotter at the bottom, in five pixel bands
        vec2 q = vec2(p.x * 0.18, p.y * 0.14 + st * 0.35);
        float h = fbm(q) * 1.2 + (p.y - (I.y - edge)) / max(2.0 * edge, 1.0) * 0.55 - 0.25;
        h = floor(clamp(h, 0.0, 0.99) * 5.0);
        vec3 col = h < 1.0 ? vec3(0.18, 0.0, 0.02) : h < 2.0 ? vec3(0.55, 0.03, 0.05) : h < 3.0 ? vec3(0.9, 0.2, 0.04) : h < 4.0 ? vec3(1.0, 0.55, 0.08) : vec3(1.0, 0.88, 0.45);
        c = over(c, col, 0.97);
    } else if (ring < 1.2) {
        c = over(c, hash(p + st) > 0.5 ? vec3(1.0, 0.75, 0.25) : vec3(1.0, 0.35, 0.05), 0.95);   // the ember rim
    } else {
        float charW = 3.0 + 3.5 * noise(n * 4.0 + seed * 0.01 + 2.0);
        if (ring < charW) {
            c = over(c, vec3(0.07, 0.035, 0.02), 0.9);
            if (hash(p + seed) > 0.92)
                c = over(c, vec3(1.0, 0.35 + 0.3 * hash(p + st), 0.05), 0.5 + 0.5 * step(0.4, hash(p * 1.3 + st)));
        } else if (ring < charW + 8.0) {
            float s = 1.0 - (ring - charW) / 8.0;
            if (hash(p * 0.7 + seed) < s * s)
                c = over(c, vec3(0.24, 0.11, 0.04), 0.45 * s);
        }
    }
    return c;
}

// ---- 3: claw marks ----
vec4 claws(vec2 p, vec2 I, float st, float g, float size) {
    vec4 c = vec4(0.0);
    vec2 C = I + vec2(0.2, -0.24) * cells;
    vec2 dir = normalize(vec2(-0.55, 1.0));                 // a swipe from top right down to the Start button
    vec2 perp = vec2(-dir.y, dir.x);
    float L = cells * 0.72 * size;
    float spacing = cells * 0.11 * size;
    float maxW = (weak > 0.5 ? 1.6 : 2.5) * max(1.0, cells / 110.0);
    float pulse = 0.75 + 0.25 * sin(t * 3.0);
    vec2 q = p - C;
    float glow = 0.0;
    vec4 gash = vec4(0.0);
    for (int k = 0; k < 4; k++) {
        float fk = float(k);
        float off0 = (fk - 1.5) * spacing;
        float len = L * ((k == 1 || k == 2) ? 1.0 : 0.82) * (0.9 + 0.1 * hash(vec2(fk, seed)));
        float s = dot(q, dir) + len * 0.5 + ((k == 1 || k == 2) ? 0.0 : spacing * 0.6);
        float u = s / len;
        float o = dot(q, perp) - off0 - sin(clamp(u, 0.0, 1.0) * PI) * spacing * 0.35;
        // drips running straight down from two points of the gash
        for (int j = 0; j < 2; j++) {
            float du = 0.3 + 0.4 * hash(vec2(fk * 3.0 + float(j), seed + 5.0));
            if (du > g)
                continue;
            vec2 sp = C + dir * (du * len - len * 0.5 - ((k == 1 || k == 2) ? 0.0 : spacing * 0.6)) + perp * (off0 + sin(du * PI) * spacing * 0.35);
            float dl = mod(t * 2.5 + hash(vec2(fk, float(j) + seed)) * 20.0, 16.0);
            if (abs(p.x - sp.x) < 0.6 && p.y > sp.y && p.y < sp.y + dl)
                gash = over(gash, p.y > sp.y + dl - 1.5 ? vec3(1.0, 0.3, 0.45) : vec3(0.6, 0.0, 0.12), 0.9);
        }
        if (u < 0.0 || u > g)
            continue;
        float w = maxW * pow(sin(u * PI), 0.6);
        float ao = abs(o);
        glow = max(glow, clamp(1.0 - (ao - w) / 4.0, 0.0, 1.0) * 0.3);
        if (ao < w) {
            float core = clamp(1.0 - ao / max(w, 0.5), 0.0, 1.0);
            gash = over(gash, mix(vec3(0.5, 0.0, 0.1), vec3(1.0, 0.35, 0.6), core * pulse), 0.97);
        } else if (ao < w + 1.0) {
            gash = over(gash, vec3(0.05, 0.0, 0.03), 0.85);
        } else if (o > 0.0 && ao < w + 2.0) {
            gash = over(gash, vec3(1.0, 0.8, 0.88), 0.45);  // the torn glass catches the light
        }
    }
    c = over(c, vec3(0.9, 0.05, 0.25), glow * pulse);
    return gash + c * (1.0 - gash.a);
}

// ---- 4: the sigil ----
vec2 starPoint(int i, float r) {
    float a = -PI / 2.0 + float(i) * TAU / 5.0;
    return vec2(cos(a), sin(a)) * r;
}
vec4 sigil(vec2 p, vec2 I, float st, float g, float size) {
    vec4 c = vec4(0.0);
    vec2 C = vec2(0.42, 0.6) * cells;
    float Rs = cells * 0.3 * size;
    vec2 q = p - C;
    float r = length(q);
    float ang = mod(atan(q.y, q.x) + PI / 2.0 + TAU, TAU) / TAU;   // clockwise from the top
    float ri = Rs * 0.8;
    float d = 1e5;
    if (ang <= g) {
        d = min(d, abs(r - Rs));
        d = min(d, abs(r - ri));
    }
    float done = g * 5.0;
    for (int s = 0; s < 5; s++) {
        float k = clamp(done - float(s), 0.0, 1.0);
        if (k <= 0.0)
            break;
        vec2 a = starPoint(int(mod(float(2 * s), 5.0)), ri), b = starPoint(int(mod(float(2 * s + 2), 5.0)), ri);
        d = min(d, segment(q, a, a + (b - a) * k));
    }
    // runes between the circles: little 3×3 glyphs round the ring
    bool rune = false;
    float band = Rs - ri;
    if (ang <= g && r > ri + 1.0 && r < Rs - 1.0) {
        float along = ang * TAU * (ri + band * 0.5);
        float cw = max(1.0, (band - 2.0) / 3.0);
        float gx = floor(along / cw);
        float idx = floor(gx / 5.0), col = mod(gx, 5.0);
        float gy = floor((r - ri - 1.0) / cw);
        rune = col < 3.0 && gy < 3.0 && hash(vec2(idx * 7.0 + col * 3.0 + gy, seed)) > 0.48;
    }
    float flick = 0.7 + 0.3 * hash(vec2(floor(p.x / 3.0), floor(p.y / 3.0)) + st * 0.37);
    if (d < 5.0)
        c = over(c, vec3(0.75, 0.05, 0.05), 0.22 * (1.0 - d / 5.0) * flick);           // the glow
    if (d < 2.4 || rune)
        c = over(c, vec3(0.09, 0.03, 0.02), 0.7);                                       // burnt into the glass
    if (d < 0.7 || rune)
        c = over(c, mix(vec3(1.0, 0.4, 0.08), vec3(1.0, 0.85, 0.4), flick - 0.7 > 0.15 ? 1.0 : 0.0), rune ? 0.75 * flick : 0.95);
    return c;
}

void main() {
    vec2 cell = floor(qt_TexCoord0 * cells);
    // the angel is back: it slides down as it goes
    vec2 p = cell + 0.5 - vec2(0.0, fall * fall * cells * 0.35);
    vec2 I = vec2(ix, iy) * cells;
    float st = floor(t * 10.0);
    float g = smoothstep(0.0, 1.0, clamp(grow, 0.0, 1.0));
    float size = weak > 0.5 ? 0.72 : 1.0;
    vec4 c;
    if (kind < 1.5)
        c = tv(p, I, st, g, size);
    else if (kind < 2.5)
        c = burn(p, I, st, g, size);
    else if (kind < 3.5)
        c = claws(p, I, st, g, size);
    else
        c = sigil(p, I, st, g, size);
    if (c.a > 0.001) {
        vec3 rgb = c.rgb / c.a;
        float l = dot(rgb, vec3(0.299, 0.587, 0.114));
        float sat = max(rgb.r, max(rgb.g, rgb.b)) - min(rgb.r, min(rgb.g, rgb.b));
        vec3 o = l < 0.2 ? cEdge.rgb : l < 0.5 ? cRim.rgb : cDim.rgb;
        if (sat > 0.5 && l > 0.45)
            o = mix(cRim.rgb, cAccent.rgb, 0.65);
        c = vec4(o * c.a, c.a);
    }
    fragColor = c * qt_Opacity * (1.0 - fall);
}
