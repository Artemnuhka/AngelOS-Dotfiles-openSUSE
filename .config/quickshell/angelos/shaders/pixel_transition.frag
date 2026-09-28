#version 440
// Pixel transition between two wallpapers.
// style: 0 mosaic + ordered dither, 1 mosaic only, 2 dither only
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float maxBlock;
    float style;
    vec2 resolution;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

// ordered dither threshold without arrays (works on every GLSL profile)
float bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x / 2.0 + a.y * a.y * 0.75);
}
float bayer4(vec2 a) {
    return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

void main() {
    float p = clamp(progress, 0.0, 1.0);
    vec2 px = qt_TexCoord0 * resolution;

    // block size grows to maxBlock at the middle and shrinks back, in power-of-two steps
    float bs = 1.0;
    if (style < 1.5) {
        float m = sin(p * 3.14159265);
        bs = exp2(floor(mix(0.0, log2(max(maxBlock, 1.0)), m * m) + 0.5));
    }
    vec2 cell = floor(px / bs);
    vec2 uv = (cell + 0.5) * bs / resolution;

    vec4 a = texture(fromTex, uv);
    vec4 b = texture(toTex, uv);

    float t;
    if (style > 0.5 && style < 1.5) {
        t = step(0.5, p);
    } else {
        float dg = max(bs, 8.0);
        float th = bayer4(floor(px / dg));
        float q = smoothstep(0.12, 0.88, p);
        t = step(th, q);
    }
    fragColor = mix(a, b, t) * qt_Opacity;
}
