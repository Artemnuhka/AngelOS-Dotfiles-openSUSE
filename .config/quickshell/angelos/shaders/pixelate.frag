#version 440
// Static pixelation (lock screen / plates).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float block;
    vec2 resolution;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec2 px = qt_TexCoord0 * resolution;
    vec2 uv = (floor(px / block) + 0.5) * block / resolution;
    fragColor = texture(source, uv) * qt_Opacity;
}
