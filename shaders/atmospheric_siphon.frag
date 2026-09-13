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

uniform vec2 u_resolution;       // Viewport dimensions
uniform float u_time;            // Animation clock
uniform float u_siphon_rate;     // Energy rate [0.0 to 1.0]

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / u_resolution.xy;
    
    // Scrolling orbital horizon curve at the bottom
    float horizonY = 0.85 + sin(st.x * 3.14159) * 0.05;
    float distFromHorizon = st.y - horizonY;
    
    // Atmospheric ion glow
    float atmosphere = exp(-max(distFromHorizon, 0.0) * 15.0) * (0.5 + u_siphon_rate * 0.5);
    
    // Aurora plasma streams
    float aurora1 = sin(st.x * 12.0 + u_time * 2.0) * 0.5 + 0.5;
    float aurora2 = cos(st.x * 24.0 - u_time * 3.0) * 0.5 + 0.5;
    float plasmaStreams = aurora1 * aurora2 * atmosphere;
    
    vec3 baseSky = vec3(0.02, 0.03, 0.08);
    vec3 horizonGold = vec3(1.0, 0.75, 0.2);
    vec3 plasmaCyan = vec3(0.1, 0.8, 0.95);
    
    vec3 finalColor = baseSky + horizonGold * atmosphere * 0.6 + plasmaCyan * plasmaStreams;
    float alpha = clamp(atmosphere * 0.8, 0.0, 1.0);
    
    fragColor = vec4(finalColor * alpha, alpha);
}
