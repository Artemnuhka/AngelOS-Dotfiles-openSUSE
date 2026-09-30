#version 440
// Workspace transitions: the frozen frame of the old workspace (`source`) is
// taken away over the live new one. Transparent where the new workspace shows.
// mode: 0 pixel dissolve, 1 shape iris, 2 ender teleport.
// shape (mode 1, the desk sprite): 0 heart, 1 sparkle star ✦, 2 CD.
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
    vec4 accent;
    vec4 purple;
    float shape;
};
layout(binding = 1) uniform sampler2D source;

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
// classic implicit heart; < 0 inside
float heart(vec2 p) {
    p.y = -p.y + 0.25;
    float a = p.x * p.x + p.y * p.y - 1.0;
    return a * a * a - p.x * p.x * p.y * p.y * p.y;
}

// a four-point sparkle star ✦ (concave sides); < 0 inside
float star(vec2 p) {
    p = abs(p);
    return sqrt(p.x) + sqrt(p.y) - 1.0;
}
vec3 rainbow(float h) {
    return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void main() {
    float p = clamp(progress, 0.0, 1.0);
    vec2 uv = qt_TexCoord0;
    if (p <= 0.0) {
        // the frozen frame, whole, until the switch has happened underneath
        fragColor = vec4(texture(source, uv).rgb, 1.0) * qt_Opacity;
        return;
    }
    vec2 px = uv * resolution;
    vec4 outc = vec4(0.0);

    if (mode < 0.5) {
        // pixel dissolve: blocks leave in an ordered-dither order, a sparkling edge
        vec2 b = floor(px / cell);
        float t = bayer8(b) * 0.82 + hash(b) * 0.18;
        float edge = t - p;
        if (edge > 0.0) {
            // sample the block's own centre: the old screen turns into pixel art as it goes
            vec2 centre = (b + 0.5) * cell / resolution;
            vec4 c = texture(source, mix(uv, centre, smoothstep(0.0, 0.5, p)));
            if (edge < 0.07)
                c.rgb = mix(c.rgb, accent.rgb, 0.75);
            outc = vec4(c.rgb, 1.0);
        }
    } else if (mode < 1.5) {
        // shape iris: a heart / star / CD-shaped hole grows from the centre, the old frame dims
        float e = p < 0.5 ? 4.0 * p * p * p : 1.0 - pow(-2.0 * p + 2.0, 3.0) / 2.0;
        vec2 cellPx = floor(px / (cell * 0.5)) * cell * 0.5 + cell * 0.25;
        vec2 c = (cellPx - resolution * 0.5) / (min(resolution.x, resolution.y) * 0.5);
        vec4 old = texture(source, uv);
        old.rgb *= 1.0 - 0.35 * e;
        vec3 rimColor = accent.rgb;
        float inside, rim;
        if (shape < 0.5) {
            float radius = 0.001 + e * 3.4;
            inside = step(heart(c / radius), 0.0);
            rim = step(heart(c / (radius * 1.08 + 0.02)), 0.0) - inside;
        } else if (shape < 1.5) {
            // the star's points reach the corners late: it grows further
            float radius = 0.001 + e * 6.4;
            inside = step(star(c / radius), 0.0);
            rim = step(star(c / (radius * 1.12 + 0.03)), 0.0) - inside;
            // a white glint runs along the rim
            rimColor = mix(accent.rgb, vec3(1.0), step(0.8, fract(atan(c.y, c.x) * 0.955 + p * 3.0)));
        } else {
            // a CD: a disc with a rainbow sheen that spins, and a hole in the middle
            float radius = 0.001 + e * 2.25;
            float d = length(c);
            float hole = radius * 0.2 * (1.0 - smoothstep(0.55, 0.95, p));
            inside = step(d, radius) * step(hole, d);
            float band = radius * 0.06 + 0.02;
            rim = step(d, radius + band) * (1.0 - step(d, radius)) + step(d, hole) * step(hole - band * 0.6, d);
            float a = atan(c.y, c.x) / 6.2832 + p * 1.5;
            rimColor = mix(rainbow(fract(a * 2.0)), accent.rgb, 0.35);
        }
        outc = vec4(old.rgb, 1.0) * (1.0 - inside);
        outc = mix(outc, vec4(rimColor, 1.0), clamp(rim, 0.0, 1.0));
    } else {
        // ender teleport: the old screen breaks into squares that shrink, turn
        // purple and float up; purple bits twinkle where they were
        float size = cell * 1.5;
        vec4 acc = vec4(0.0);
        // content drifts up, so this fragment can show its own square or the one below
        for (int k = 0; k < 2; k++) {
            vec2 home = floor(px / size) + vec2(0.0, float(k));
            float d = hash(home) * 0.55 + (1.0 - home.y * size / resolution.y) * 0.2;
            float q = clamp((p - d) / 0.45, 0.0, 1.0);
            float s = 1.0 - q;                          // square scale
            vec2 centre = (home + 0.5) * size - vec2(0.0, q * q * size * 1.6);
            vec2 local = (px - centre) / (size * 0.5 * max(s, 0.001));
            if (s > 0.0 && abs(local.x) <= 1.0 && abs(local.y) <= 1.0) {
                vec2 src = ((home + 0.5) * size + local * size * 0.5) / resolution;
                vec4 c = texture(source, src);
                c.rgb = mix(c.rgb, purple.rgb, smoothstep(0.0, 0.7, q));
                acc = vec4(c.rgb, 1.0 - q * q);
                break;
            }
        }
        outc = acc;
        // sparkles
        vec2 g = floor(px / (cell * 0.5));
        float h = hash(g + 7.0);
        float life = clamp((p - h * 0.6) / 0.3, 0.0, 1.0);
        if (h > 0.93 && life > 0.0 && life < 1.0 && fract(h * 91.0 + p * 7.0) > 0.4)
            outc = max(outc, vec4(mix(purple.rgb, vec3(0.95, 0.6, 1.0), fract(h * 13.0)), 1.0 - life));
    }
    fragColor = vec4(outc.rgb * outc.a, outc.a) * qt_Opacity;
}
