#version 440
// Duotone recolor for icons: luminance -> mix(dark, light), posterized to a few steps.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 dark;
    vec4 light;
    float levels;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec4 c = texture(source, qt_TexCoord0);
    float a = c.a;
    vec3 rgb = a > 0.001 ? c.rgb / a : vec3(0.0);
    float l = dot(rgb, vec3(0.299, 0.587, 0.114));
    l = clamp(0.15 + l * 1.1, 0.0, 1.0);
    if (levels > 1.0)
        l = floor(l * levels + 0.5) / levels;
    vec3 o = mix(dark.rgb, light.rgb, l);
    fragColor = vec4(o * a, a) * qt_Opacity;
}
