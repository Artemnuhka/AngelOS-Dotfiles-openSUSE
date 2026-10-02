#version 440
// Any Start look in hell (StartOverlay, Y2K → Angel or demon → Start in hell: "hell version"):
// the whole menu re-inked in hell's palette by brightness — the darks obsidian, the middle
// blood and embers, the light bone; saturated colours (the accent, app icons) catch fire,
// keeping a little of their own hue so icons still read. The same map as the widgets'
// re-ink (hell_widget.frag, hellMap), plus `keep` of the original colour.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float keep;      // 0..1 of the original hue left in saturated colours
};
layout(binding = 1) uniform sampler2D source;

const vec3 OBSIDIAN = vec3(0.055, 0.016, 0.024);
const vec3 BLOOD = vec3(0.55, 0.06, 0.11);
const vec3 EMBER = vec3(1.0, 0.42, 0.10);
const vec3 FLAME = vec3(1.0, 0.69, 0.18);
const vec3 BONE = vec3(0.95, 0.85, 0.75);

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    if (c.a < 0.003) {
        fragColor = vec4(0.0);
        return;
    }
    vec3 rgb = c.rgb / c.a;
    float l = dot(rgb, vec3(0.299, 0.587, 0.114));
    float sat = max(rgb.r, max(rgb.g, rgb.b)) - min(rgb.r, min(rgb.g, rgb.b));
    vec3 o = mix(OBSIDIAN, BLOOD, smoothstep(0.08, 0.38, l));
    o = mix(o, EMBER, smoothstep(0.38, 0.62, l));
    o = mix(o, BONE, smoothstep(0.66, 0.92, l));
    float hot = smoothstep(0.25, 0.6, sat);
    o = mix(o, mix(EMBER, FLAME, smoothstep(0.5, 0.85, l)), hot * 0.7);
    // a little of the icon's own colour, warmed
    o = mix(o, rgb * vec3(1.0, 0.75, 0.7), hot * keep);
    fragColor = vec4(o * c.a, c.a) * qt_Opacity;
}
