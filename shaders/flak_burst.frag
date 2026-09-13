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

uniform vec2 u_resolution;       // Viewport size
uniform float u_progress;        // Explosion lifetime progress [0.0 to 1.0]
uniform float u_radius;          // Normalized maximum radius
uniform vec4 u_burst_color;      // Burst base RGBA

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / u_resolution.xy;
    vec2 center = vec2(0.5, 0.5);
    float dist = length(st - center);
    
    // Expanding shockwave ring
    float ringRadius = u_progress * u_radius;
    float ringWidth = 0.05 * (1.0 - u_progress);
    
    // Chromatic dispersion offsets for edge aberration
    float ringR = smoothstep(ringRadius - ringWidth * 1.2, ringRadius, dist) -
                  smoothstep(ringRadius, ringRadius + ringWidth * 1.2, dist);
    float ringG = smoothstep(ringRadius - ringWidth, ringRadius, dist) -
                  smoothstep(ringRadius, ringRadius + ringWidth, dist);
    float ringB = smoothstep(ringRadius - ringWidth * 0.8, ringRadius, dist) -
                  smoothstep(ringRadius, ringRadius + ringWidth * 0.8, dist);
    
    // Dissipating central fireball
    float core = exp(-dist * 12.0) * (1.0 - u_progress);
    
    vec3 color = vec3(ringR, ringG, ringB) * u_burst_color.rgb + vec3(core);
    float alpha = clamp((ringG + core) * (1.0 - u_progress) * u_burst_color.a, 0.0, 1.0);
    
    fragColor = vec4(color * alpha, alpha);
}
