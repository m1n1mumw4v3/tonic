#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 grainEffect(
    float2 position,
    half4 color,
    float intensity,
    float seed
) {
    // Hash-based noise: fast, static, no texture needed
    float2 p = position + seed;
    float noise = fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);

    // Center around 0 so grain adds and subtracts luminance equally
    half grain = half(noise - 0.5) * half(intensity);

    return half4(color.rgb + grain, color.a);
}
