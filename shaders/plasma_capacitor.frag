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

uniform vec2 u_resolution;       // Bay cell size
uniform float u_time;            // Animation clock
uniform float u_charge_level;    // Normalized charge mass M [0.0 to 1.0]
uniform vec4 u_glow_color;       // Plasma hue (e.g. Solar Gold or Cyan)

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / u_resolution.xy;
    vec2 center = vec2(0.5, 0.5);
    float dist = length(st - center);
    
    // Pulsing frequency scales with charge level
    float pulseSpeed = 4.0 + (u_charge_level * 10.0);
    float pulse = sin(u_time * pulseSpeed) * 0.15 + 0.85;
    
    // Core radial containment field
    float core = exp(-dist * (6.0 - u_charge_level * 2.0)) * u_charge_level * pulse;
    
    // Perimeter containment corona
    float rim = smoothstep(0.4, 0.48, dist) - smoothstep(0.48, 0.52, dist);
    float rimGlow = rim * u_charge_level * (sin(u_time * 6.0) * 0.2 + 0.8);
    
    float total = core + rimGlow;
    vec3 color = mix(u_glow_color.rgb, vec3(1.0, 1.0, 1.0), core * 0.5);
    float alpha = clamp(total * u_glow_color.a, 0.0, 1.0);
    
    fragColor = vec4(color * alpha, alpha);
}
