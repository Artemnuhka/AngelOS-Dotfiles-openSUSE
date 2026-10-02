#version 440
// The bar's content in hell (BarContent): every pixel takes one of five colours of the
// circle's palette by what it is — near black (outlines) → `plate`, dark (button faces, a
// dark sprite's body) → `face`, mid → `dim`, light → `text`, coloured (the hearts, the
// active, tinted icons) → `accent`. Alpha is
// cut at a half: no soft edges, so text keeps the contrast its colour was picked for
// (tests check text, dim and accent against the plate it sits on).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 plate;
    vec4 face;
    vec4 dim;
    vec4 text;
    vec4 accent;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    if (c.a < 0.5) {
        fragColor = vec4(0.0);
        return;
    }
    vec3 rgb = c.rgb / c.a;
    float l = dot(rgb, vec3(0.299, 0.587, 0.114));
    float sat = max(rgb.r, max(rgb.g, rgb.b)) - min(rgb.r, min(rgb.g, rgb.b));
    vec3 o;
    if (sat > 0.32 && l > 0.16)
        o = accent.rgb;
    else if (l < 0.05)
        o = plate.rgb;
    else if (l < 0.2)
        o = face.rgb;
    else if (l < 0.6)
        o = dim.rgb;
    else
        o = text.rgb;
    fragColor = vec4(o, 1.0) * qt_Opacity;
}
