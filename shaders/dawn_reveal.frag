#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uSize;

out vec4 fragColor;

void main() {
    // Normalize coordinates
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Create a smooth dawn sweep from bottom-left to top-right
    float sweepProgress = uTime; // 0.0 to 1.0 over animation duration
    
    // Create diagonal sweep pattern
    float diagonal = (uv.x + uv.y) * 0.5;
    
    // Smooth transition with easing
    float reveal = smoothstep(0.0, 0.8, sweepProgress - diagonal + 0.4);
    
    // Dark color (near black)
    vec3 darkColor = vec3(0.067, 0.067, 0.067); // #111111
    
    // Light color (cream)
    vec3 lightColor = vec3(0.961, 0.953, 0.933); // #f5f3ee
    
    // Add subtle golden glow at the sweep edge
    float glowEdge = smoothstep(0.0, 0.1, reveal) - smoothstep(0.9, 1.0, reveal);
    vec3 goldenGlow = vec3(0.961, 0.773, 0.094) * glowEdge * 0.3; // #F5C518
    
    // Mix colors based on reveal progress
    vec3 finalColor = mix(darkColor, lightColor, reveal) + goldenGlow;
    
    fragColor = vec4(finalColor, 1.0);
}
