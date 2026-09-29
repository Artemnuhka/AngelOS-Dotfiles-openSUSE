#version 440
// Workspace switch flourishes drawn over the screen (the switch itself is instant).
// mode: 0 pixel dissolve, 1 glitch, 2 heart iris, 3 ender teleport particles.
// progress runs 0 → 1; everything is transparent at 1.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float mode;
    float cell;
    float seed;
    vec2 resolution;
    vec4 color1;
    vec4 color2;
};

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21) + seed);
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
float bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x / 2.0 + a.y * a.y * 0.75);
}
float bayer8(vec2 a) {
    return bayer2(0.25 * a) * 0.0625 + bayer2(0.5 * a) * 0.25 + bayer2(a);
}
// heart shape, |p| ~ 1 at the edge (classic implicit curve)
float heart(vec2 p) {
    p.y = -p.y + 0.25;
    float a = p.x * p.x + p.y * p.y - 1.0;
    return a * a * a - p.x * p.x * p.y * p.y * p.y;
}

void main() {
    float p = clamp(progress, 0.0, 1.0);
    vec2 px = qt_TexCoord0 * resolution;
    vec2 blockPx = floor(px / cell) * cell;
    vec4 outc = vec4(0.0);

    if (mode < 0.5) {
        // pixel dissolve: blocks vanish in an ordered-dither sequence
        vec2 b = floor(px / cell);
        float t = bayer8(b);
        float h = hash(b) * 0.25;
        if (t * 0.75 + h > p) {
            // mostly the desk colour, a sprinkle of accent pixels
            vec4 c = mix(color2, color1, step(0.93, hash(b + 5.0)));
            outc = vec4(c.rgb * (0.92 + 0.08 * hash(b + 2.0)), 1.0);
        }
    } else if (mode < 1.5) {
        // glitch: shifted bars, RGB fringes and scanlines fading out
        float row = floor(px.y / (cell * 2.0));
        float r = hash(vec2(row, floor(p * 12.0)));
        float strength = (1.0 - p);
        if (r < 0.35 * strength + 0.05) {
            float band = step(0.5, hash(vec2(row, 7.0)));
            vec3 c = band > 0.5 ? color1.rgb : color2.rgb;
            float edge = hash(vec2(row, floor(px.x / (cell * 6.0))));
            outc = vec4(c, 0.55 * strength * step(0.3, edge));
        }
        float scan = step(0.5, fract(px.y / 4.0));
        outc = max(outc, vec4(0.0, 0.0, 0.0, 0.18 * strength * scan));
    } else if (mode < 2.5) {
        // heart iris: a heart-shaped hole grows from the centre
        vec2 c = (blockPx + cell * 0.5 - resolution * 0.5) / (min(resolution.x, resolution.y) * 0.5);
        float radius = 0.02 + p * p * 3.2;
        float inside = step(heart(c / radius), 0.0);
        float rim = step(heart(c / (radius * 1.06)), 0.0) - inside;
        outc = vec4(color2.rgb, 1.0) * (1.0 - inside);
        outc = mix(outc, vec4(color1.rgb, 1.0), rim);
    } else {
        // ender teleport: purple pixel particles drifting up and twinkling out
        vec2 grid = floor(px / (cell * 3.0));
        float h = hash(grid);
        vec2 local = fract(px / (cell * 3.0));
        vec2 at = vec2(hash(grid + 1.7), hash(grid + 3.1));
        at.y = fract(at.y + p * (0.6 + h));   // drift
        float size = 0.12 + 0.12 * hash(grid + 9.0);
        vec2 d = abs(local - at);
        float dot1 = step(max(d.x, d.y), size);
        float alive = step(h, 0.55 * (1.0 - p) + 0.08) * step(0.25, fract(h * 13.0 + p * 6.0));
        vec3 purple = mix(vec3(0.80, 0.0, 0.98), vec3(0.24, 0.02, 0.35), fract(h * 7.0));
        outc = vec4(purple, dot1 * alive);
        // purple flash / vignette at the start
        vec2 q = qt_TexCoord0 - 0.5;
        float vig = smoothstep(0.2, 0.75, length(q)) * (1.0 - p);
        outc = max(outc, vec4(0.35, 0.0, 0.5, 0.55 * vig + 0.25 * (1.0 - p) * (1.0 - p)));
    }
    fragColor = vec4(outc.rgb * outc.a, outc.a) * qt_Opacity;
}
