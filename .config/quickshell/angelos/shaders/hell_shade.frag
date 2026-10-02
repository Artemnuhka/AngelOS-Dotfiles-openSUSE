#version 440
// The demon in her corner while hell rules (modules/y2k/AngelHelper): her own pictures, but
// in the circle's few colours and half in shadow — no neon. Brightness picks one of four
// palette steps (edge → rim → dim text → text); the neon (wings, ribbons) sinks to the rim
// and only its brightest pixels keep a dull ember of the accent; the dark rises from her feet.
// Whole art pixels only (`cells`): it stays pixel art.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 cells;     // the sprite in art pixels
    float shadow;   // 0..1: how far the dark climbs up her (from the feet)
    vec4 cEdge;
    vec4 cRim;
    vec4 cDim;
    vec4 cText;
    vec4 cAccent;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = (floor(qt_TexCoord0 * cells) + 0.5) / cells;
    vec4 s = texture(source, uv);
    if (s.a < 0.01) {
        fragColor = vec4(0.0);
        return;
    }
    vec3 rgb = s.rgb / s.a;
    float l = dot(rgb, vec3(0.299, 0.587, 0.114));
    float sat = max(rgb.r, max(rgb.g, rgb.b)) - min(rgb.r, min(rgb.g, rgb.b));
    vec3 o;
    if (l < 0.16)
        o = cEdge.rgb;
    else if (l < 0.38)
        o = cRim.rgb;
    else if (l < 0.66)
        o = cDim.rgb;
    else
        o = cText.rgb;
    // the loud colours (wings, ribbons) sink to the rim; only the brightest of them — the
    // eyes, a highlight — keep a dull ember of the accent
    if (sat > 0.45)
        o = l > 0.55 ? mix(cRim.rgb, cAccent.rgb, 0.6) : mix(cEdge.rgb, cRim.rgb, l > 0.3 ? 1.0 : 0.5);
    // the dark rising from her feet, in steps of whole art pixels
    float fromFeet = 1.0 - uv.y;
    float d = clamp((shadow - fromFeet) / max(0.001, shadow), 0.0, 1.0);
    o = mix(o, cEdge.rgb, floor(d * 4.0) / 4.0 * 0.85);
    fragColor = vec4(o * s.a, s.a) * qt_Opacity;
}
