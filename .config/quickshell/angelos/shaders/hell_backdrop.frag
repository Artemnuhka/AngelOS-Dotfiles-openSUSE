#version 440
// Hell's backdrop (modules/background/WallpaperView while Theme.hell): the circle lays its
// dark over whatever wallpaper there is (HellLook.backdrop) — the colour drained a little,
// most of the light taken, and the edges closing in. The vignette steps down in whole art
// pixels with an ordered dither, so it stays pixel art. Still: drawn once per wallpaper.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float dim;       // 0..1: how much of the light the dark takes
    float desat;     // 0..1: how much of the colour drains
    float vignette;  // 0..1: how far the edges close in
    float cell;      // one art pixel, in screen pixels
    vec2 resolution;
    vec4 tint;       // the dark itself
};
layout(binding = 1) uniform sampler2D source;

float bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x / 2.0 + a.y * a.y * 0.75);
}
float bayer4(vec2 a) {
    return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

void main() {
    vec4 s = texture(source, qt_TexCoord0);
    vec3 rgb = s.rgb;
    float l = dot(rgb, vec3(0.299, 0.587, 0.114));
    rgb = mix(rgb, vec3(l), desat);
    rgb = mix(rgb, tint.rgb, dim);
    vec2 px = floor(qt_TexCoord0 * resolution / max(1.0, cell));
    vec2 d = (qt_TexCoord0 - 0.5) * vec2(resolution.x / max(1.0, resolution.y), 1.0);
    float v = clamp((length(d) - 0.35) / 0.55, 0.0, 1.0) * vignette;
    float steps = 5.0;
    float q = floor(v * steps + bayer4(px)) / steps;
    rgb = mix(rgb, tint.rgb, clamp(q, 0.0, 1.0));
    fragColor = vec4(rgb * s.a, s.a) * qt_Opacity;
}
