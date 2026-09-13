/*
 * Copyright 2026 Void Sower Authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;       // Viewport size in pixels
uniform float u_time;            // Animation clock in seconds
uniform float u_intensity;       // Beam intensity [0.0, 1.0]
uniform vec4 u_beam_color;       // Base RGBA color

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / u_resolution.xy;
    
    // Distance from vertical center line of beam
    float distFromCenter = abs(st.x - 0.5);
    
    // Core high-energy axial filament
    float core = exp(-distFromCenter * 32.0) * u_intensity;
    
    // Outer electromagnetic plasma bloom
    float bloom = exp(-distFromCenter * 10.0) * u_intensity * 0.6;
    
    // Axial high-frequency electromagnetic shimmer
    float noise = sin(st.y * 80.0 - u_time * 25.0) * 0.15 + 0.85;
    
    float totalBeam = (core * 1.5 + bloom) * noise;
    
    vec3 color = mix(u_beam_color.rgb, vec3(1.0, 1.0, 1.0), core * 0.75);
    float alpha = clamp(totalBeam * u_beam_color.a, 0.0, 1.0);
    
    fragColor = vec4(color * alpha, alpha);
}
