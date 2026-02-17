#include <metal_stdlib>
using namespace metal;

// Color effect: S-curved light band sweep with warm gold tint.
// Inputs: position, color, viewSize, progress (0-1), bandWidthFraction, peakIntensity.
[[ stitchable ]] half4 completionShimmer(
    float2 position,
    half4 color,
    float2 viewSize,
    float progress,
    float bandWidthFraction,
    float peakIntensity
) {
    // Normalized x position
    float nx = position.x / viewSize.x;

    // Sweep center moves from -bandWidthFraction to 1+bandWidthFraction
    float range = 1.0 + 2.0 * bandWidthFraction;
    float center = -bandWidthFraction + progress * range;

    // Distance from sweep center
    float dist = abs(nx - center);

    // S-curve falloff within band
    float halfBand = bandWidthFraction * 0.5;
    float t = 1.0 - smoothstep(0.0, halfBand, dist);

    // Warm gold tint (roughly #E8C94A mapped to 0-1)
    half3 goldTint = half3(0.91, 0.79, 0.29);

    // Blend: additive light band
    float intensity = t * peakIntensity;
    half3 result = color.rgb + half3(goldTint * half(intensity));

    return half4(result, color.a);
}
