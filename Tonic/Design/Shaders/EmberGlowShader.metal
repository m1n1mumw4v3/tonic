#include <metal_stdlib>
using namespace metal;

// Color effect: slow-drifting warm ember glow for streak badge.
// Adds organic warm highlights that breathe and shift like embers.
[[ stitchable ]] half4 emberGlow(
    float2 position,
    half4 color,
    float2 viewSize,
    float time,
    float intensity
) {
    // Normalized coordinates
    float2 uv = position / viewSize;

    // Slow drifting noise coordinates
    float2 p1 = uv * 3.0 + float2(time * 0.15, time * 0.1);
    float2 p2 = uv * 2.0 + float2(-time * 0.12, time * 0.18);

    // Two layers of hash noise for organic movement
    float n1 = fract(sin(dot(floor(p1), float2(127.1, 311.7))) * 43758.5453);
    float n2 = fract(sin(dot(floor(p2), float2(269.5, 183.3))) * 43758.5453);

    // Smooth interpolation within cells
    float2 f1 = smoothstep(0.0, 1.0, fract(p1));
    float2 f2 = smoothstep(0.0, 1.0, fract(p2));

    // Bilinear noise blend for each layer
    float c00 = fract(sin(dot(floor(p1), float2(127.1, 311.7))) * 43758.5453);
    float c10 = fract(sin(dot(floor(p1) + float2(1, 0), float2(127.1, 311.7))) * 43758.5453);
    float c01 = fract(sin(dot(floor(p1) + float2(0, 1), float2(127.1, 311.7))) * 43758.5453);
    float c11 = fract(sin(dot(floor(p1) + float2(1, 1), float2(127.1, 311.7))) * 43758.5453);
    float noise1 = mix(mix(c00, c10, f1.x), mix(c01, c11, f1.x), f1.y);

    float d00 = fract(sin(dot(floor(p2), float2(269.5, 183.3))) * 43758.5453);
    float d10 = fract(sin(dot(floor(p2) + float2(1, 0), float2(269.5, 183.3))) * 43758.5453);
    float d01 = fract(sin(dot(floor(p2) + float2(0, 1), float2(269.5, 183.3))) * 43758.5453);
    float d11 = fract(sin(dot(floor(p2) + float2(1, 1), float2(269.5, 183.3))) * 43758.5453);
    float noise2 = mix(mix(d00, d10, f2.x), mix(d01, d11, f2.x), f2.y);

    // Combine noise layers with slow breathing
    float breath = sin(time * 0.8) * 0.3 + 0.7;
    float combined = (noise1 * 0.6 + noise2 * 0.4) * breath;

    // Warm ember tint (orange-gold blend)
    half3 ember = half3(0.95, 0.55, 0.15);

    // Additive blend, scaled by intensity
    half glow = half(combined * intensity);
    half3 result = color.rgb + ember * glow;

    return half4(result, color.a);
}
