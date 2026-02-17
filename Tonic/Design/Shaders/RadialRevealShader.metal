#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Layer effect: radial alpha mask expanding from tap point.
// Inputs: position, layer, tapPoint (pts), viewSize, progress (0-1), featherWidth (pts).
[[ stitchable ]] half4 radialReveal(
    float2 position,
    SwiftUI::Layer layer,
    float2 tapPoint,
    float2 viewSize,
    float progress,
    float featherWidth
) {
    // Maximum possible distance from tap point to any corner
    float maxDist = length(max(tapPoint, viewSize - tapPoint));

    // Current reveal radius based on progress
    float radius = progress * maxDist;

    // Distance from current pixel to tap point
    float dist = length(position - tapPoint);

    // Feathered alpha: smooth transition at the edge
    float alpha = 1.0 - smoothstep(radius - featherWidth, radius, dist);

    half4 color = layer.sample(position);
    return half4(color.rgb, color.a * half(alpha));
}
