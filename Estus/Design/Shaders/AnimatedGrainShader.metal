#include <metal_stdlib>
using namespace metal;

// Color effect: animated grain with time-based drift (~8s full cycle).
[[ stitchable ]] half4 animatedGrainEffect(
    float2 position,
    half4 color,
    float intensity,
    float time
) {
    // Drift noise coordinates using sin/cos for ~8s cycle
    float cycle = time * 0.7854; // 2π / 8 ≈ 0.7854
    float2 offset = float2(sin(cycle) * 50.0, cos(cycle) * 50.0);
    float2 p = position + offset;

    // Hash-based noise
    float noise = fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);

    // Center around 0 for balanced luminance shift
    half grain = half(noise - 0.5) * half(intensity);

    return half4(color.rgb + grain, color.a);
}
