// SwiftUIShaders, a collection of SwiftUI Metal effects.
// Extracted from the Epilogue reading app's shader lab. MIT licensed.
// Each [[ stitchable ]] function is a SwiftUI layerEffect. See README / ShaderEffects.swift
// for the typed Swift wrappers. The `bcs_` prefix is just the shader namespace.
#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// MARK: - Shared Noise Utilities
// Prefixed with bcs_ to avoid symbol collisions

static float bcs_hash(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

static float bcs_valueNoise(float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);
    float2 u = f * f * (3.0 - 2.0 * f);

    float a = bcs_hash(i);
    float b = bcs_hash(i + float2(1.0, 0.0));
    float c = bcs_hash(i + float2(0.0, 1.0));
    float d = bcs_hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

static float bcs_fbm(float2 st, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < octaves; i++) {
        value += amplitude * bcs_valueNoise(st * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// HSB to RGB
static half3 bcs_hsb2rgb(half3 c) {
    half3 rgb = clamp(
        abs(fmod(c.x * 6.0h + half3(0.0h, 4.0h, 2.0h), 6.0h) - 3.0h) - 1.0h,
        0.0h, 1.0h
    );
    rgb = rgb * rgb * (3.0h - 2.0h * rgb);
    return c.z * mix(half3(1.0h), rgb, c.y);
}

// MARK: - 1. Emboss / Relief
// Creates a 3D carved look from the cover art using edge detection

[[ stitchable ]] half4 bcs_emboss(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float strength,     // 0-5: how pronounced the relief is
    float angle,        // 0-6.28: light direction in radians
    float mix_amount    // 0-1: blend between original and embossed
) {
    float2 dir = float2(cos(angle), sin(angle));
    float offset = 1.5; // pixel offset for edge detection

    // Sample neighbors along light direction
    half4 ahead = layer.sample(position + dir * offset);
    half4 behind = layer.sample(position - dir * offset);
    half4 center = layer.sample(position);

    // Luminance of neighbors
    float lumAhead = dot(float3(ahead.rgb), float3(0.299, 0.587, 0.114));
    float lumBehind = dot(float3(behind.rgb), float3(0.299, 0.587, 0.114));

    // Height difference = emboss
    float emboss = (lumAhead - lumBehind) * strength;

    // Apply emboss to original color
    half4 embossed = center;
    embossed.rgb += half(emboss);

    return mix(center, embossed, half(mix_amount));
}

// MARK: - 2. Heat Shimmer
// Animated wavering distortion like heat rising off pavement

[[ stitchable ]] half4 bcs_heatShimmer(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float amplitude,    // 0-20: pixel displacement amount
    float frequency,    // 1-30: wave tightness
    float speed,        // 0.5-5: animation speed
    float vertical_bias // 0-1: how much stronger the effect is at top
) {
    float2 uv = position / size;

    // Vertical bias: stronger shimmer toward the top
    float bias = mix(1.0, 1.0 - uv.y, vertical_bias);

    // Two sine waves at different frequencies for organic feel
    float wave1 = sin(uv.y * frequency + time * speed) * amplitude * bias;
    float wave2 = sin(uv.y * frequency * 1.7 + time * speed * 0.8 + 2.0) * amplitude * 0.5 * bias;

    // Add subtle vertical displacement too
    float waveY = cos(uv.x * frequency * 0.5 + time * speed * 1.2) * amplitude * 0.3 * bias;

    float2 displaced = position + float2(wave1 + wave2, waveY);

    // Keep in bounds
    displaced = clamp(displaced, float2(0.0), size);

    return layer.sample(displaced);
}

// MARK: - 3. Holographic / Prismatic
// Rainbow foil effect that shifts with time, like a holographic trading card

[[ stitchable ]] half4 bcs_holographic(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float intensity,    // 0-1: strength of the rainbow overlay
    float scale,        // 1-20: size of the rainbow bands
    float speed,        // 0.1-3: animation speed
    float angle_offset  // 0-6.28: rotate the rainbow direction
) {
    float2 uv = position / size;
    half4 original = layer.sample(position);

    // Diagonal position for rainbow bands
    float diagonal = (uv.x * cos(angle_offset) + uv.y * sin(angle_offset)) * scale;

    // Animated rainbow using phase-offset sine waves
    float phase = diagonal + time * speed;
    half3 rainbow;
    rainbow.r = sin(phase) * 0.5h + 0.5h;
    rainbow.g = sin(phase + 2.094h) * 0.5h + 0.5h;  // 2pi/3
    rainbow.b = sin(phase + 4.189h) * 0.5h + 0.5h;  // 4pi/3

    // Luminance-driven: brighter areas catch more "light"
    float lum = dot(float3(original.rgb), float3(0.299, 0.587, 0.114));
    float hologramMask = smoothstep(0.3, 0.8, lum);

    // Additive blend weighted by luminance
    half4 result = original;
    result.rgb += rainbow * half(intensity * hologramMask);

    // Subtle saturation boost
    half gray = dot(result.rgb, half3(0.299h, 0.587h, 0.114h));
    result.rgb = mix(half3(gray), result.rgb, 1.1h);

    return result;
}

// MARK: - 4. Ink Bleed / Domain Warp
// Makes the cover look like watercolor bleeding into wet paper

[[ stitchable ]] half4 bcs_inkBleed(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float warp_strength,  // 0-50: how far pixels wander
    float scale,          // 1-10: size of the warp patterns
    float speed,          // 0.1-2: animation speed
    float detail          // 2-8: noise octaves (as float, cast to int)
) {
    float2 uv = position / size;

    // Domain warping: noise feeding into noise
    float2 st = uv * scale;

    float2 q = float2(
        bcs_fbm(st + float2(time * speed * 0.1, 0.0), int(detail)),
        bcs_fbm(st + float2(5.2, 1.3 + time * speed * 0.08), int(detail))
    );

    float2 r = float2(
        bcs_fbm(st + 4.0 * q + float2(1.7, 9.2) + time * speed * 0.05, int(detail)),
        bcs_fbm(st + 4.0 * q + float2(8.3, 2.8) + time * speed * 0.04, int(detail))
    );

    // Final warp offset
    float2 warpOffset = (q + r) * warp_strength;

    float2 displaced = position + warpOffset;
    displaced = clamp(displaced, float2(0.0), size);

    return layer.sample(displaced);
}

// MARK: - 5. Frosted Glass
// Partial blur with a clear window, like breathing on cold glass

[[ stitchable ]] half4 bcs_frosted(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float frost_amount,     // 0-1: how frosty (0 = clear, 1 = full frost)
    float grain_size,       // 1-20: size of frost crystals
    float clear_radius,     // 0-1: size of clear center spot
    float clear_softness    // 0-1: how soft the clear/frost edge is
) {
    float2 uv = position / size;

    // Clear window in the center
    float2 center = float2(0.5, 0.5);
    float dist = distance(uv, center);
    float frost_mask = smoothstep(clear_radius, clear_radius + clear_softness, dist);
    frost_mask *= frost_amount;

    // Frost displacement: scatter sampling based on noise
    float2 noise_uv = uv * grain_size;
    float nx = bcs_hash(floor(noise_uv) + float2(0.0, 0.0)) * 2.0 - 1.0;
    float ny = bcs_hash(floor(noise_uv) + float2(7.3, 3.1)) * 2.0 - 1.0;

    // Multi-sample for blur approximation (5 taps)
    float scatter = frost_mask * 8.0;
    half4 sum = layer.sample(position);
    sum += layer.sample(position + float2(nx, ny) * scatter);
    sum += layer.sample(position + float2(-ny, nx) * scatter);
    sum += layer.sample(position + float2(-nx, -ny) * scatter * 0.7);
    sum += layer.sample(position + float2(ny, -nx) * scatter * 0.7);
    sum /= 5.0h;

    // Blend between sharp original and frosted
    half4 original = layer.sample(position);
    half4 result = mix(original, sum, half(frost_mask));

    // Add subtle frost brightness
    result.rgb += half3(frost_mask * 0.05);

    return result;
}

// MARK: - 6. Chromatic Split
// RGB channel separation with directional control

[[ stitchable ]] half4 bcs_chromaticSplit(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float spread,       // 0-30: pixel distance between channels
    float angle,        // 0-6.28: direction of the split
    float edge_only,    // 0-1: limit effect to edges (radial falloff)
    float time,
    float animate       // 0-1: animate the spread
) {
    float2 uv = position / size;

    // Optional edge-only mask
    float2 center = float2(0.5, 0.5);
    float dist = distance(uv, center);
    float mask = mix(1.0, smoothstep(0.1, 0.5, dist), edge_only);

    // Animated spread
    float animatedSpread = spread;
    if (animate > 0.01) {
        animatedSpread += sin(time * 2.0) * spread * 0.3 * animate;
    }

    float effectiveSpread = animatedSpread * mask;

    // Direction vector
    float2 dir = float2(cos(angle), sin(angle)) * effectiveSpread;

    // Sample each channel at offset positions
    half4 r = layer.sample(position + dir);
    half4 g = layer.sample(position);
    half4 b = layer.sample(position - dir);

    return half4(r.r, g.g, b.b, g.a);
}

// MARK: - 7. Live Ripple
// Concentric water ripples expanding outward continuously from center

[[ stitchable ]] half4 bcs_liveRipple(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float amplitude,     // 0-30: pixel displacement
    float frequency,     // 5-60: ring tightness
    float speed,         // 1-10: expansion speed
    float damping,       // 0.5-5: how fast rings fade with distance
    float ring_count     // 1-5: number of simultaneous ripple sources
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float aspectRatio = size.x / size.y;

    float2 totalOffset = float2(0.0);

    for (int i = 0; i < int(ring_count); i++) {
        // Each ring source has a slight offset and phase
        float phase = float(i) * 1.256; // 2pi/5 spacing
        float2 ringCenter = center + float2(
            sin(time * 0.3 + phase) * 0.05,
            cos(time * 0.4 + phase) * 0.05
        );

        float2 delta = uv - ringCenter;
        delta.x *= aspectRatio;
        float dist = length(delta);

        // Expanding concentric rings
        float wave = sin(dist * frequency - time * speed + phase);

        // Fade with distance
        float envelope = exp(-dist * damping);

        // Radial displacement direction
        float2 dir = dist > 0.001 ? normalize(delta) : float2(0.0);
        dir.x /= aspectRatio;

        totalOffset += dir * wave * envelope * amplitude / ring_count;
    }

    float2 displaced = clamp(position + totalOffset, float2(0.0), size);
    return layer.sample(displaced);
}

// MARK: - 8. Touch Ripple
// Ripples expand from a touch point, decay over time

[[ stitchable ]] half4 bcs_touchRipple(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 touchPos,       // touch location in pixels
    float touchAge,        // seconds since touch
    float amplitude,       // 0-30: displacement strength
    float frequency,       // 5-40: ring density
    float speed,           // 50-500: expansion speed (pixels/sec)
    float decay            // 0.5-4: time decay rate
) {
    if (touchAge < 0.01 || touchAge > 5.0) {
        return layer.sample(position);
    }

    float2 delta = position - touchPos;
    float dist = length(delta);

    // Expanding wavefront
    float rippleRadius = touchAge * speed;
    float distFromFront = dist - rippleRadius;

    // Wider, smoother gaussian envelope, more liquid, less sharp
    float waveWidth = 60.0 + touchAge * 40.0;
    float envelope = exp(-(distFromFront * distFromFront) / (2.0 * waveWidth * waveWidth));

    // Time fade
    float timeFade = exp(-touchAge * decay);

    // Multiple layered sine waves for smoother, more organic ripples
    float wave1 = sin(distFromFront * frequency * 0.008);
    float wave2 = sin(distFromFront * frequency * 0.005 + 1.0) * 0.5;
    float wave = (wave1 + wave2) * 0.67 * envelope * timeFade * amplitude;

    // Smooth radial direction
    float2 dir = dist > 0.5 ? normalize(delta) : float2(0.0);

    float2 displaced = clamp(position + dir * wave, float2(0.0), size);
    half4 color = layer.sample(displaced);

    // Subtle chromatic shift on the ripple
    float chromaAmt = abs(wave) * 0.08;
    half4 rSamp = layer.sample(clamp(displaced + dir * chromaAmt, float2(0.0), size));
    half4 bSamp = layer.sample(clamp(displaced - dir * chromaAmt, float2(0.0), size));
    color.r = mix(color.r, rSamp.r, half(envelope * timeFade * 0.3));
    color.b = mix(color.b, bSamp.b, half(envelope * timeFade * 0.3));

    return color;
}

// MARK: - 9. Liquid Chrome
// Metallic mercury reflection with animated highlights

[[ stitchable ]] half4 bcs_liquidChrome(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float distortion,      // 0-30: displacement amount
    float chrome_intensity, // 0-1: metallic highlight strength
    float flow_speed,      // 0.1-3: animation speed
    float reflection_scale // 1-10: size of chrome reflections
) {
    float2 uv = position / size;

    // Flowing noise field for displacement
    float2 st = uv * reflection_scale;
    float n1 = bcs_fbm(st + float2(time * flow_speed * 0.2, time * flow_speed * 0.15), 4);
    float n2 = bcs_fbm(st + float2(5.0, 3.0) + float2(time * flow_speed * 0.18, time * flow_speed * 0.22), 4);

    // Displacement
    float2 offset = float2(n1, n2) * distortion;
    float2 displaced = clamp(position + offset, float2(0.0), size);
    half4 color = layer.sample(displaced);

    // Chrome specular highlights based on noise gradient
    float epsilon = 0.01;
    float h0 = bcs_fbm(st + float2(time * flow_speed * 0.2, time * flow_speed * 0.15), 3);
    float hx = bcs_fbm(st + float2(epsilon, 0.0) + float2(time * flow_speed * 0.2, time * flow_speed * 0.15), 3);
    float hy = bcs_fbm(st + float2(0.0, epsilon) + float2(time * flow_speed * 0.2, time * flow_speed * 0.15), 3);

    // Surface normal from height field
    float3 normal = normalize(float3((h0 - hx) / epsilon, (h0 - hy) / epsilon, 1.0));

    // Specular: how much the surface faces the "camera"
    float specular = pow(max(normal.z, 0.0), 4.0);

    // Chrome highlight, bright white where surface is angled just right
    float highlight = pow(1.0 - abs(dot(normal, float3(0, 0, 1))), 3.0) * chrome_intensity;

    // Desaturate for metallic look, then add highlights
    half lum = dot(color.rgb, half3(0.299h, 0.587h, 0.114h));
    half3 metallic = mix(color.rgb, half3(lum), half(chrome_intensity * 0.5));
    metallic += half3(highlight);
    metallic *= half(0.8 + specular * 0.4);

    return half4(metallic, color.a);
}

// MARK: - 10. Glitch
// Digital glitch with scan lines, block displacement, and color corruption

[[ stitchable ]] half4 bcs_glitch(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float intensity,       // 0-1: overall glitch strength
    float block_size,      // 2-50: size of glitch blocks
    float scan_lines,      // 0-1: scan line darkness
    float color_shift      // 0-20: RGB offset in pixels
) {
    float2 uv = position / size;

    // Pseudo-random glitch trigger (changes every ~0.1 seconds)
    float glitchTime = floor(time * 10.0);
    float glitchRand = bcs_hash(float2(glitchTime, 0.0));

    // Only glitch some of the time
    float glitchActive = step(1.0 - intensity * 0.5, glitchRand);

    // Block displacement
    float blockY = floor(uv.y * (size.y / block_size));
    float blockRand = bcs_hash(float2(blockY, glitchTime));
    float blockShift = (blockRand - 0.5) * 2.0 * intensity * glitchActive;

    float2 displaced = position;
    displaced.x += blockShift * block_size * 2.0;

    // Per-block vertical jitter
    float vertRand = bcs_hash(float2(blockY + 100.0, glitchTime));
    if (vertRand > 0.95 && glitchActive > 0.5) {
        displaced.y += (bcs_hash(float2(blockY, glitchTime + 50.0)) - 0.5) * block_size;
    }

    displaced = clamp(displaced, float2(0.0), size);

    // Color channel separation during glitch
    float shift = color_shift * glitchActive;
    half4 r = layer.sample(displaced + float2(shift, 0.0));
    half4 g = layer.sample(displaced);
    half4 b = layer.sample(displaced - float2(shift, 0.0));

    half4 result = half4(r.r, g.g, b.b, g.a);

    // Scan lines
    float scanLine = sin(position.y * 3.14159 * 2.0) * 0.5 + 0.5;
    scanLine = pow(scanLine, 4.0);
    result.rgb *= 1.0h - half(scanLine * scan_lines * 0.3);

    // Occasional bright flash on glitch blocks
    if (blockRand > 0.92 && glitchActive > 0.5) {
        result.rgb += half3(0.15);
    }

    return result;
}

// MARK: - 11. Vortex Spiral
// Swirling distortion that twists the cover art

[[ stitchable ]] half4 bcs_vortex(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float twist_amount,   // 0-10: how many radians of twist
    float radius,         // 0.1-1: normalized radius of the vortex
    float speed,          // 0.1-3: rotation speed
    float falloff         // 0.5-5: how sharply the twist falls off
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float2 delta = uv - center;

    float aspectRatio = size.x / size.y;
    delta.x *= aspectRatio;

    float dist = length(delta);

    // Twist angle based on distance from center
    float normalizedDist = dist / radius;
    float twistFalloff = exp(-normalizedDist * falloff);
    float angle = twist_amount * twistFalloff + time * speed;

    // Rotate UV around center
    float cosA = cos(angle);
    float sinA = sin(angle);
    float2 rotated = float2(
        delta.x * cosA - delta.y * sinA,
        delta.x * sinA + delta.y * cosA
    );

    rotated.x /= aspectRatio;
    float2 newUV = rotated + center;

    float2 samplePos = clamp(newUV * size, float2(0.0), size);
    return layer.sample(samplePos);
}

// MARK: - 12. Pulse / Heartbeat
// Rhythmic radial expansion and contraction like a breathing cover

[[ stitchable ]] half4 bcs_pulse(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float amplitude,      // 0-30: max pixel displacement
    float bpm,            // 30-180: beats per minute
    float sharpness,      // 1-10: how sharp the pulse is (higher = punchier)
    float glow_intensity  // 0-1: brightness pulse at edges
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float2 delta = uv - center;
    float dist = length(delta);

    // Heartbeat-like pulse: sharp attack, smooth decay
    float beatFreq = bpm / 60.0;
    float beat = sin(time * beatFreq * 3.14159 * 2.0);
    beat = pow(abs(beat), 1.0 / sharpness) * sign(beat);
    beat = beat * 0.5 + 0.5; // 0-1 range

    // Radial displacement: pushes pixels outward on beat
    float2 dir = dist > 0.001 ? normalize(delta) : float2(0.0);
    float displacement = beat * amplitude * smoothstep(0.0, 0.3, dist);

    float2 displaced = position + dir * displacement;
    displaced = clamp(displaced, float2(0.0), size);

    half4 color = layer.sample(displaced);

    // Edge glow on beat
    float edgeDist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    float edgeGlow = (1.0 - smoothstep(0.0, 0.15, edgeDist)) * beat * glow_intensity;
    color.rgb += half3(edgeGlow * 0.5, edgeGlow * 0.3, edgeGlow * 0.6);

    return color;
}

// MARK: - 14. Wave Pool
// Multiple overlapping sine wave displacements creating interference patterns

[[ stitchable ]] half4 bcs_wavePool(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float amplitude,      // 0-25: displacement strength
    float wavelength,     // 5-40: distance between wave crests
    float speed,          // 0.5-5: wave animation speed
    float complexity      // 1-6: number of wave directions
) {
    float2 uv = position / size;
    float2 totalOffset = float2(0.0);

    int waves = int(complexity);

    for (int i = 0; i < waves; i++) {
        float angle = float(i) * 3.14159 / float(waves); // evenly spaced angles
        float2 dir = float2(cos(angle), sin(angle));

        // Wave along this direction
        float phase = dot(uv, dir) * wavelength + time * speed + float(i) * 1.5;
        float wave = sin(phase);

        // Displace perpendicular to wave direction
        float2 perpDir = float2(-dir.y, dir.x);
        totalOffset += perpDir * wave * amplitude / float(waves);
    }

    float2 displaced = clamp(position + totalOffset, float2(0.0), size);
    return layer.sample(displaced);
}

// MARK: - 16. Ethereal Aura (v2)
// The cover BREATHES, edges warp and glow with visible liquid displacement

[[ stitchable ]] half4 bcs_etherealAura(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float aura_width,
    float aura_intensity,
    float pulse_speed,
    float distortion,
    float hue_shift
) {
    float2 uv = position / size;

    // Edge distance field
    float edgeX = min(uv.x, 1.0 - uv.x);
    float edgeY = min(uv.y, 1.0 - uv.y);
    float edgeDist = min(edgeX, edgeY);

    // Organic edge with domain-warped noise
    float2 st = uv * 6.0;
    float2 q = float2(
        bcs_fbm(st + float2(time * 0.15, time * 0.1), 5),
        bcs_fbm(st + float2(5.2, 1.3) + float2(time * 0.12, time * 0.18), 5)
    );
    float edgeWarp = bcs_fbm(st + 3.0 * q, 4);

    float auraMask = smoothstep(aura_width + edgeWarp * aura_width, 0.0, edgeDist);

    // Breathing pulse
    float pulse = 0.6 + 0.4 * sin(time * pulse_speed);
    float pulsedMask = auraMask * pulse;

    // HEAVY displacement everywhere, strongest at edges
    float2 dispSt = uv * 4.0;
    float2 dispQ = float2(
        bcs_fbm(dispSt + float2(time * 0.25, time * 0.2), 5),
        bcs_fbm(dispSt + float2(3.0, 7.0) + float2(time * 0.2, time * 0.3), 5)
    );
    float2 dispR = float2(
        bcs_fbm(dispSt + 3.0 * dispQ + float2(time * 0.1, 0.0), 4),
        bcs_fbm(dispSt + 3.0 * dispQ + float2(0.0, time * 0.08), 4)
    );

    // Displacement pushes inward from edges + organic wander
    float2 edgeDir = float2(
        uv.x < 0.5 ? 1.0 : -1.0,
        uv.y < 0.5 ? 1.0 : -1.0
    );
    float2 disp = float2(dispR.x - 0.5, dispR.y - 0.5) * distortion * pulsedMask;
    disp += edgeDir * pulsedMask * distortion * 0.3; // push inward

    // Apply displacement across the WHOLE image, fading from edges
    float globalDisp = smoothstep(0.3, 0.0, edgeDist);
    disp *= globalDisp;

    float2 displaced = clamp(position + disp, float2(0.0), size);

    // Chromatic aberration at edges
    float chromaAmount = pulsedMask * distortion * 0.12;
    float2 chromaDir = normalize(float2(uv.x - 0.5, uv.y - 0.5) + 0.001) * chromaAmount;

    half4 rr = layer.sample(clamp(displaced + chromaDir, float2(0.0), size));
    half4 gg = layer.sample(displaced);
    half4 bb = layer.sample(clamp(displaced - chromaDir, float2(0.0), size));
    half4 color = half4(rr.r, gg.g, bb.b, gg.a);

    // Aura glow color
    half3 auraColor;
    auraColor.r = sin(half(hue_shift)) * 0.5h + 0.5h;
    auraColor.g = sin(half(hue_shift) + 2.094h) * 0.5h + 0.5h;
    auraColor.b = sin(half(hue_shift) + 4.189h) * 0.5h + 0.5h;

    float glow = pulsedMask * aura_intensity;
    color.rgb += auraColor * half(glow * 0.6);
    color.rgb += half3(glow * 0.15); // white bloom

    return color;
}

// MARK: - 17. Black Hole
// Gravitational lensing, warps space around a singularity

[[ stitchable ]] half4 bcs_blackHole(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float mass,           // 0.05-0.5: size/strength of the singularity
    float spin,           // 0-5: rotation speed of the accretion disk
    float distortion,     // 10-200: warp strength
    float ring_brightness // 0-2: accretion disk glow
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float aspectRatio = size.x / size.y;

    float2 delta = uv - center;
    delta.x *= aspectRatio;
    float dist = length(delta);
    float angle = atan2(delta.y, delta.x);

    // Gravitational lensing: bend light around the mass
    // Closer to the singularity = more bending
    float schwarzschild = mass * 0.3;
    float bendStrength = schwarzschild / max(dist * dist, 0.001);
    bendStrength = min(bendStrength, 5.0); // cap it

    // Warp UV: push pixels radially outward near the hole
    float2 warpDir = dist > 0.001 ? normalize(delta) : float2(0.0);
    float2 warped = delta + warpDir * bendStrength * 0.1;

    // Add rotational frame-dragging
    float dragAngle = spin * schwarzschild / max(dist, 0.01) * time;
    float cosD = cos(dragAngle);
    float sinD = sin(dragAngle);
    warped = float2(warped.x * cosD - warped.y * sinD,
                    warped.x * sinD + warped.y * cosD);

    warped.x /= aspectRatio;
    float2 sampleUV = (warped + center) * size;
    sampleUV = clamp(sampleUV, float2(0.0), size);
    half4 color = layer.sample(sampleUV);

    // Event horizon: fade to black inside schwarzschild radius
    float horizon = smoothstep(schwarzschild * 0.5, schwarzschild * 1.5, dist);
    color.rgb *= half(horizon);

    // Accretion disk: bright ring around the black hole
    float ringDist = abs(dist - schwarzschild * 2.5);
    float ring = exp(-ringDist * ringDist / (schwarzschild * schwarzschild * 0.3));

    // Rotating ring pattern
    float ringPattern = sin(angle * 8.0 - time * spin * 3.0) * 0.5 + 0.5;
    ringPattern = pow(ringPattern, 2.0);
    ring *= (0.5 + ringPattern * 0.5);

    // Ring color: hot blue-white inner, orange outer
    half3 innerRing = half3(0.7h, 0.85h, 1.0h);
    half3 outerRing = half3(1.0h, 0.6h, 0.2h);
    float ringPos = smoothstep(schwarzschild * 1.5, schwarzschild * 4.0, dist);
    half3 ringColor = mix(innerRing, outerRing, half(ringPos));

    color.rgb += ringColor * half(ring * ring_brightness);

    return color;
}

// MARK: - 18. Melt
// The image melts downward like hot wax, gravity pulls pixels down

[[ stitchable ]] half4 bcs_melt(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float melt_amount,    // 0-100: how far pixels drip
    float drip_scale,     // 1-15: width of drip columns
    float speed,          // 0.1-3: melt speed
    float heat            // 0-1: color distortion (warm shift)
) {
    float2 uv = position / size;

    // Per-column drip amount, each vertical strip melts at different rate
    float column = uv.x * drip_scale;
    float dripNoise = bcs_fbm(float2(column, time * speed * 0.3), 4);
    float dripNoise2 = bcs_fbm(float2(column * 1.7 + 3.0, time * speed * 0.25), 3);

    // Drip amount increases toward the bottom
    float gravity = uv.y * uv.y; // quadratic, bottom melts more
    float drip = (dripNoise * 0.7 + dripNoise2 * 0.3) * melt_amount * gravity;

    // Add some horizontal wobble as things melt
    float wobble = sin(uv.y * 10.0 + time * speed * 2.0 + dripNoise * 5.0) * melt_amount * 0.05 * gravity;

    float2 displaced = position + float2(wobble, -drip); // negative Y = pull up = melt down
    displaced = clamp(displaced, float2(0.0), size);

    half4 color = layer.sample(displaced);

    // Heat distortion: warm color shift in melting areas
    float meltFactor = drip / max(melt_amount, 1.0);
    color.r += half(meltFactor * heat * 0.3);
    color.g -= half(meltFactor * heat * 0.1);
    color.b -= half(meltFactor * heat * 0.2);

    // Slight brightening at drip edges (specular on liquid)
    float dripEdge = abs(bcs_fbm(float2(column + 0.01, time * speed * 0.3), 4) - dripNoise);
    float specular = pow(dripEdge * 5.0, 3.0) * gravity * 0.4;
    color.rgb += half3(specular);

    return color;
}

// MARK: - 19. Kaleidoscope
// Mirrors and rotates the cover into mesmerizing symmetrical patterns

[[ stitchable ]] half4 bcs_kaleidoscope(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float segments,       // 2-16: number of mirror segments
    float rotation,       // 0-6.28: manual rotation
    float zoom,           // 0.5-3: zoom level
    float animate_speed   // 0-2: auto-rotation speed
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float2 delta = uv - center;

    float aspectRatio = size.x / size.y;
    delta.x *= aspectRatio;

    // Polar coordinates
    float angle = atan2(delta.y, delta.x) + rotation + time * animate_speed;
    float dist = length(delta);

    // Kaleidoscope: fold angle into segment
    float segAngle = 3.14159 * 2.0 / segments;
    angle = angle - segAngle * floor(angle / segAngle); // mod into segment
    if (angle > segAngle * 0.5) {
        angle = segAngle - angle; // mirror
    }

    // Back to cartesian
    float2 kaleido = float2(cos(angle), sin(angle)) * dist / zoom;
    kaleido.x /= aspectRatio;
    float2 sampleUV = (kaleido + center) * size;
    sampleUV = clamp(sampleUV, float2(0.0), size);

    return layer.sample(sampleUV);
}

// MARK: - 21. Refract Lens (Interactive)
// Thick glass sphere, drag to move the lens around the cover

[[ stitchable ]] half4 bcs_refractLens(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 touch_pos,     // touch position in pixels
    float lens_radius,    // 0.1-0.5: size of the lens
    float refraction,     // 1.0-3.0: index of refraction
    float aberration,     // 0-15: chromatic split
    float wobble          // 0-1: organic lens wobble
) {
    float2 uv = position / size;
    float aspectRatio = size.x / size.y;

    // Lens center from touch position (normalized)
    float2 lensCenter = touch_pos / size;
    // Clamp to valid area
    lensCenter = clamp(lensCenter, float2(0.05), float2(0.95));

    float2 delta = uv - lensCenter;
    delta.x *= aspectRatio;
    float dist = length(delta);

    // Soft edge: slight distortion ring outside the lens
    float outerRing = smoothstep(lens_radius * 1.3, lens_radius, dist);
    if (dist > lens_radius * 1.3) {
        return layer.sample(position);
    }

    if (dist > lens_radius) {
        // Subtle outer distortion ring
        float2 pushDir = dist > 0.001 ? normalize(delta) : float2(0.0);
        pushDir.x /= aspectRatio;
        float pushAmount = outerRing * 8.0;
        float2 pushed = position + pushDir * pushAmount;
        return layer.sample(clamp(pushed, float2(0.0), size));
    }

    // Sphere surface normal
    float normalizedDist = dist / lens_radius;
    float z = sqrt(1.0 - normalizedDist * normalizedDist);
    float3 normal = normalize(float3(delta / lens_radius, z));

    // Refraction via Snell's law
    float3 incident = float3(0, 0, -1);
    float eta = 1.0 / refraction;
    float cosI = -dot(normal, incident);
    float sinT2 = eta * eta * (1.0 - cosI * cosI);
    float3 refracted = eta * incident + (eta * cosI - sqrt(max(0.0, 1.0 - sinT2))) * normal;

    float2 refractedUV = uv + refracted.xy * lens_radius * 0.5;

    // Chromatic aberration, stronger at edges
    float chroma = aberration * (1.0 - z) * 0.01;
    float2 chromaDir = normalize(delta + 0.001);
    chromaDir.x /= aspectRatio;

    half4 rr = layer.sample(clamp((refractedUV + chromaDir * chroma) * size, float2(0.0), size));
    half4 gg = layer.sample(clamp(refractedUV * size, float2(0.0), size));
    half4 bb = layer.sample(clamp((refractedUV - chromaDir * chroma) * size, float2(0.0), size));

    half4 color = half4(rr.r, gg.g, bb.b, 1.0h);

    // Specular highlight
    float3 lightDir = normalize(float3(0.3, -0.3, 1.0));
    float3 halfVec = normalize(lightDir + float3(0, 0, 1));
    float spec = pow(max(dot(normal, halfVec), 0.0), 64.0);
    color.rgb += half3(spec * 0.6);

    // Fresnel rim
    float fresnel = pow(1.0 - z, 4.0);
    color.rgb += half3(fresnel * 0.2);

    // Edge ring glow
    float rimGlow = pow(normalizedDist, 6.0) * 0.3;
    color.rgb += half3(rimGlow * 0.5h, rimGlow * 0.6h, rimGlow * 0.8h);

    return color;
}

// MARK: - 22. Plasma
// Electric plasma tendrils crawling across the surface

[[ stitchable ]] half4 bcs_plasma(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float intensity,      // 0-1: visibility of plasma
    float scale,          // 1-10: size of plasma cells
    float speed,          // 0.5-5: animation speed
    float color_mode      // 0-1: 0=electric blue, 0.5=green, 1=purple
) {
    float2 uv = position / size;
    half4 color = layer.sample(position);

    // Classic plasma function: sum of sines
    float2 st = uv * scale;
    float v1 = sin(st.x + time * speed);
    float v2 = sin(st.y + time * speed * 0.7);
    float v3 = sin(st.x + st.y + time * speed * 0.5);
    float v4 = sin(length(st - float2(scale * 0.5)) + time * speed * 1.3);

    float plasma = (v1 + v2 + v3 + v4) * 0.25; // -1 to 1

    // Sharp plasma lines from the zero-crossings
    float lines = 1.0 / (1.0 + abs(plasma) * 20.0);
    lines = pow(lines, 2.0);

    // Secondary tendrils
    float v5 = sin(st.x * 2.0 - st.y * 1.5 + time * speed * 0.9);
    float v6 = sin(length(st - float2(scale * 0.3, scale * 0.7)) * 2.0 + time * speed);
    float plasma2 = (v5 + v6) * 0.5;
    float lines2 = 1.0 / (1.0 + abs(plasma2) * 15.0);
    lines2 = pow(lines2, 2.0);

    float totalPlasma = (lines + lines2 * 0.5) * intensity;

    // Plasma color based on mode
    half3 plasmaColor;
    if (color_mode < 0.33) {
        // Electric blue
        plasmaColor = half3(0.3h, 0.6h, 1.0h);
    } else if (color_mode < 0.66) {
        // Matrix green
        plasmaColor = half3(0.2h, 1.0h, 0.4h);
    } else {
        // Arcane purple
        plasmaColor = half3(0.8h, 0.2h, 1.0h);
    }

    // Add plasma glow
    color.rgb += plasmaColor * half(totalPlasma);

    // Brighten where plasma is strongest
    color.rgb += half3(totalPlasma * 0.3);

    return color;
}

// MARK: - 23. Echo / Ghost
// Multiple trailing offset copies that create a spectral echo

[[ stitchable ]] half4 bcs_echo(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float echo_count,     // 2-8: number of ghost copies
    float spread,         // 5-50: pixel distance between echoes
    float direction,      // 0-6.28: angle of echo trail
    float fade            // 0.3-0.9: opacity falloff per echo
) {
    half4 base = layer.sample(position);
    half4 result = base;

    float2 dir = float2(cos(direction), sin(direction)) * spread;
    int echoes = int(echo_count);

    float totalWeight = 1.0;

    for (int i = 1; i <= echoes; i++) {
        float weight = pow(fade, float(i));
        float2 offset = dir * float(i);

        // Add slight organic wobble to each echo
        offset.x += sin(time * 2.0 + float(i) * 1.5) * spread * 0.1;
        offset.y += cos(time * 1.7 + float(i) * 2.0) * spread * 0.1;

        float2 samplePos = clamp(position - offset, float2(0.0), size);
        half4 echo = layer.sample(samplePos);

        // Tint echoes: shift toward blue/purple with distance
        echo.r *= half(1.0 - float(i) * 0.08);
        echo.b *= half(1.0 + float(i) * 0.05);

        result.rgb += echo.rgb * half(weight);
        totalWeight += weight;
    }

    result.rgb /= half(totalWeight);
    return result;
}

// MARK: - 24. Shatter
// Refined glass shard explosion with depth, reflections, and shadow

[[ stitchable ]] half4 bcs_shatter(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float shard_count,    // 3-30: number of shatter cells
    float explode,        // 0-1: how far apart the shards are
    float rotation_amt,   // 0-3: how much each shard rotates
    float edge_glow       // 0-2: brightness of shard edges
) {
    float2 uv = position / size;

    // Voronoi for shard geometry
    float2 cellUV = uv * shard_count;
    float2 cellID = floor(cellUV);
    float2 cellF = fract(cellUV);

    float minDist = 10.0;
    float secondDist = 10.0;
    float2 closestCell = float2(0.0);

    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            float2 neighbor = float2(float(i), float(j));
            float2 id = cellID + neighbor;
            float2 point = float2(
                bcs_hash(id),
                bcs_hash(id + float2(37.0, 91.0))
            );
            float2 diff = neighbor + point - cellF;
            float d = length(diff);
            if (d < minDist) {
                secondDist = minDist;
                minDist = d;
                closestCell = id;
            } else if (d < secondDist) {
                secondDist = d;
            }
        }
    }

    // Per-shard deterministic randoms
    float shardRand = bcs_hash(closestCell * 7.3);
    float shardRand2 = bcs_hash(closestCell * 13.7 + float2(5.0, 3.0));
    float shardRand3 = bcs_hash(closestCell * 23.1 + float2(11.0, 7.0));

    // Eased explode for natural feel
    float eased = explode * explode * (3.0 - 2.0 * explode);

    // Shard offset, radial from center with stagger
    float2 center = float2(0.5, 0.5);
    float2 shardCenter = (closestCell + 0.5) / shard_count;
    float2 driftDir = normalize(shardCenter - center + float2(0.001));
    float driftDist = eased * (0.3 + shardRand * 0.7) * 120.0;

    // 3D rotation per shard (tilt in perspective)
    float angle = (shardRand2 - 0.5) * rotation_amt * eased;
    float tiltX = (shardRand3 - 0.5) * eased * 0.15; // perspective tilt
    float ca = cos(angle), sa = sin(angle);
    float2 rotatedOffset = float2(
        ca * driftDir.x - sa * driftDir.y,
        sa * driftDir.x + ca * driftDir.y
    ) * driftDist;

    // Gravity with slight delay per shard
    float delay = shardRand * 0.3;
    float fallEased = max(eased - delay, 0.0);
    float fallAmount = fallEased * fallEased * 100.0 * (0.4 + shardRand * 0.6);

    float2 samplePos = position - rotatedOffset + float2(0.0, -fallAmount);

    // Perspective scale (shards shrink slightly as they fly away)
    float perspectiveScale = 1.0 - eased * shardRand * 0.15;
    float2 shardCenterPx = shardCenter * size;
    samplePos = shardCenterPx + (samplePos - shardCenterPx) / perspectiveScale;

    samplePos = clamp(samplePos, float2(0.0), size);
    half4 color = layer.sample(samplePos);

    // Glass reflection: slight brightness gradient across each shard
    float reflectionGradient = dot(normalize(float2(cellF - 0.5)), float2(0.5, -0.3));
    float glassReflection = smoothstep(-0.3, 0.5, reflectionGradient) * 0.12 * (1.0 + eased);
    color.rgb += half3(glassReflection);

    // Perspective tilt darkening (shards angled away get darker)
    float tiltDarken = 1.0 - abs(tiltX) * eased * 2.0;
    color.rgb *= half(max(tiltDarken, 0.6));

    // Refined edge lines, thin, clean, with glow
    float edgeDist = secondDist - minDist;
    float thinEdge = 1.0 - smoothstep(0.0, 0.03, edgeDist); // thin line
    float softEdge = 1.0 - smoothstep(0.0, 0.1, edgeDist);  // soft glow

    // Edge color: cool glass tint
    half3 edgeColor = half3(0.7h, 0.85h, 1.0h) * half(edge_glow);
    color.rgb += edgeColor * half(thinEdge * 0.8 + softEdge * 0.2);

    // Shadow under separated shards
    float shadowDist = eased * 0.03;
    color.rgb *= half(1.0 - eased * 0.15 * shardRand);

    // Fade shards flying far
    float fadeFactor = 1.0 - eased * shardRand * 0.4;
    color.rgb *= half(fadeFactor);

    return color;
}

// MARK: - 25. Neon Edge
// Glowing neon contour lines extracted from the image

[[ stitchable ]] half4 bcs_neonEdge(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float edge_strength,  // 1-10: edge detection sensitivity
    float glow_amount,    // 0-2: how much the edges glow
    float color_cycle,    // 0-3: speed of color cycling
    float mix_original    // 0-1: blend with original image
) {
    float2 uv = position / size;
    half4 original = layer.sample(position);

    // Sobel edge detection
    float step_x = 1.0;
    float step_y = 1.0;

    half4 tl = layer.sample(position + float2(-step_x, -step_y));
    half4 tc = layer.sample(position + float2(0, -step_y));
    half4 tr = layer.sample(position + float2(step_x, -step_y));
    half4 ml = layer.sample(position + float2(-step_x, 0));
    half4 mr = layer.sample(position + float2(step_x, 0));
    half4 bl = layer.sample(position + float2(-step_x, step_y));
    half4 bc = layer.sample(position + float2(0, step_y));
    half4 br = layer.sample(position + float2(step_x, step_y));

    // Luminance of each sample
    float ltl = dot(float3(tl.rgb), float3(0.299, 0.587, 0.114));
    float ltc = dot(float3(tc.rgb), float3(0.299, 0.587, 0.114));
    float ltr = dot(float3(tr.rgb), float3(0.299, 0.587, 0.114));
    float lml = dot(float3(ml.rgb), float3(0.299, 0.587, 0.114));
    float lmr = dot(float3(mr.rgb), float3(0.299, 0.587, 0.114));
    float lbl = dot(float3(bl.rgb), float3(0.299, 0.587, 0.114));
    float lbc = dot(float3(bc.rgb), float3(0.299, 0.587, 0.114));
    float lbr = dot(float3(br.rgb), float3(0.299, 0.587, 0.114));

    float gx = -ltl - 2.0*lml - lbl + ltr + 2.0*lmr + lbr;
    float gy = -ltl - 2.0*ltc - ltr + lbl + 2.0*lbc + lbr;
    float edgeMag = sqrt(gx*gx + gy*gy) * edge_strength;
    edgeMag = clamp(edgeMag, 0.0, 1.0);

    // Neon color cycling based on edge direction and time
    float edgeAngle = atan2(gy, gx);
    float hue = fract(edgeAngle / 6.2832 + time * color_cycle * 0.3 + uv.y * 0.5);
    half3 neonColor = bcs_hsb2rgb(half3(half(hue), 1.0h, 1.0h));

    // Glow: power curve on edge magnitude for bloom
    float bloom = pow(edgeMag, 0.7) * glow_amount;

    // Dark background + neon edges
    half3 darkBG = original.rgb * half(mix_original * 0.5);
    half3 neon = neonColor * half(edgeMag + bloom);

    half4 result = half4(darkBG + neon, original.a);
    return result;
}

// MARK: - 26. Pixelate Storm
// Dynamic mosaic that pulses, shifts, and swirls

[[ stitchable ]] half4 bcs_pixelateStorm(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float pixel_size,     // 2-40: base pixel block size
    float storm_amount,   // 0-1: how chaotic the pixelation is
    float swirl,          // 0-3: rotational swirl of pixel grid
    float pulse           // 0-3: pulsing speed
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);

    // Pulsing pixel size
    float pxSize = pixel_size * (1.0 + sin(time * pulse) * 0.3 * storm_amount);

    // Swirl the UV coordinates
    float2 delta = uv - center;
    float dist = length(delta);
    float angle = atan2(delta.y, delta.x);
    float swirlAngle = swirl * (1.0 - dist) * sin(time * 0.5);
    float2 swirledUV = center + dist * float2(cos(angle + swirlAngle), sin(angle + swirlAngle));

    // Snap to pixel grid
    float2 pixelUV = floor(swirledUV * size / pxSize) * pxSize / size;

    // Storm: randomly offset some blocks
    float blockRand = bcs_hash(floor(swirledUV * size / pxSize));
    float stormActive = step(1.0 - storm_amount * 0.8, blockRand);
    float2 stormOffset = float2(
        sin(time * 3.0 + blockRand * 20.0) * storm_amount * pxSize * 0.5,
        cos(time * 2.5 + blockRand * 15.0) * storm_amount * pxSize * 0.5
    ) * stormActive;

    float2 samplePos = pixelUV * size + stormOffset;
    samplePos = clamp(samplePos, float2(0.0), size);
    half4 color = layer.sample(samplePos);

    // Scanline overlay for digital feel
    float scanline = sin(position.y * 3.14159 / 2.0) * 0.5 + 0.5;
    color.rgb *= half(0.92 + scanline * 0.08);

    return color;
}

// MARK: - 27. Shockwave
// Expanding rings of distortion from the center

[[ stitchable ]] half4 bcs_shockwave(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float wave_speed,     // 50-500: ring expansion speed
    float ring_width,     // 5-60: width of the distortion ring
    float strength,       // 5-80: displacement power
    float repeat_rate     // 0.5-5: seconds between waves
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float aspectRatio = size.x / size.y;

    float2 delta = uv - center;
    delta.x *= aspectRatio;
    float dist = length(delta) * size.y; // pixel distance from center

    // Repeating wave
    float cycleTime = fmod(time, repeat_rate);
    float waveFront = cycleTime * wave_speed;

    // Ring shape: distance from the wave front
    float ringDist = abs(dist - waveFront);
    float ringMask = 1.0 - smoothstep(0.0, ring_width, ringDist);
    ringMask *= ringMask; // sharpen

    // Fade wave as it expands
    float fadeWithDist = exp(-waveFront * 0.003);
    ringMask *= fadeWithDist;

    // Displacement: push outward along the radial direction
    float2 dir = dist > 0.001 ? normalize(delta) : float2(0.0);
    float2 disp = dir * ringMask * strength;

    // Second wave slightly behind for depth
    float waveFront2 = max(cycleTime - 0.15, 0.0) * wave_speed * 0.9;
    float ringDist2 = abs(dist - waveFront2);
    float ringMask2 = 1.0 - smoothstep(0.0, ring_width * 0.7, ringDist2);
    ringMask2 *= ringMask2 * fadeWithDist * 0.5;
    disp += dir * ringMask2 * strength * 0.4;

    float2 samplePos = clamp(position + disp, float2(0.0), size);
    half4 color = layer.sample(samplePos);

    // Chromatic split on the ring
    float chromaAmt = ringMask * strength * 0.15;
    float2 chromaDir = float2(dir.x * chromaAmt, dir.y * chromaAmt);
    half4 rSamp = layer.sample(clamp(samplePos + chromaDir, float2(0.0), size));
    half4 bSamp = layer.sample(clamp(samplePos - chromaDir, float2(0.0), size));
    color.r = mix(color.r, rSamp.r, half(ringMask * 0.6));
    color.b = mix(color.b, bSamp.b, half(ringMask * 0.6));

    // Bright flash on the ring edge
    color.rgb += half3(ringMask * 0.15h);

    return color;
}

// MARK: - 28. Thermal
// Thermal / infrared vision with heat shimmer

[[ stitchable ]] half4 bcs_thermal(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float intensity,      // 0-1: strength of thermal colorization
    float shimmer,        // 0-15: heat distortion amount
    float noise_speed,    // 0.5-3: shimmer animation speed
    float palette_shift   // 0-1: shifts the color palette
) {
    float2 uv = position / size;

    // Shimmer distortion, rising heat waves
    float2 st = uv * 8.0;
    float n1 = bcs_valueNoise(st + float2(0.0, time * noise_speed * 2.0));
    float n2 = bcs_valueNoise(st * 1.3 + float2(time * noise_speed * 1.5, 0.0));
    float2 heatDisp = float2(
        (n1 - 0.5) * shimmer,
        (n2 - 0.5) * shimmer * 0.6 - shimmer * 0.3 // rising bias
    );

    float2 samplePos = clamp(position + heatDisp, float2(0.0), size);
    half4 original = layer.sample(samplePos);

    // Convert to "heat" value (luminance)
    float heat = dot(float3(original.rgb), float3(0.299, 0.587, 0.114));

    // Add some noise to break up flat areas
    heat += (bcs_valueNoise(uv * 20.0 + time * 0.5) - 0.5) * 0.05;
    heat = clamp(heat + palette_shift * 0.3, 0.0, 1.0);

    // Thermal palette: black → blue → purple → red → orange → yellow → white
    half3 thermal;
    if (heat < 0.15) {
        thermal = mix(half3(0.0h), half3(0.0h, 0.0h, 0.3h), half(heat / 0.15));
    } else if (heat < 0.35) {
        thermal = mix(half3(0.0h, 0.0h, 0.3h), half3(0.5h, 0.0h, 0.5h), half((heat - 0.15) / 0.2));
    } else if (heat < 0.55) {
        thermal = mix(half3(0.5h, 0.0h, 0.5h), half3(1.0h, 0.0h, 0.0h), half((heat - 0.35) / 0.2));
    } else if (heat < 0.75) {
        thermal = mix(half3(1.0h, 0.0h, 0.0h), half3(1.0h, 0.6h, 0.0h), half((heat - 0.55) / 0.2));
    } else if (heat < 0.9) {
        thermal = mix(half3(1.0h, 0.6h, 0.0h), half3(1.0h, 1.0h, 0.0h), half((heat - 0.75) / 0.15));
    } else {
        thermal = mix(half3(1.0h, 1.0h, 0.0h), half3(1.0h, 1.0h, 1.0h), half((heat - 0.9) / 0.1));
    }

    half3 result = mix(original.rgb, thermal, half(intensity));
    return half4(result, original.a);
}

// MARK: - 29. Morph Breathe
// The image breathes and morphs like a living organism

[[ stitchable ]] half4 bcs_morphBreathe(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float breathe_depth,  // 5-50: displacement depth
    float breathe_rate,   // 0.3-3: breathing speed
    float warp_complexity, // 1-8: noise octave complexity
    float organic         // 0-1: how organic/irregular the breathing is
) {
    float2 uv = position / size;

    // Multi-layered breathing rhythms
    float breathe1 = sin(time * breathe_rate) * 0.5 + 0.5;
    float breathe2 = sin(time * breathe_rate * 0.7 + 1.5) * 0.5 + 0.5;
    float breathe3 = sin(time * breathe_rate * 1.3 + 3.0) * 0.5 + 0.5;

    // Organic displacement field
    float t = time * breathe_rate * 0.3;
    float2 st = uv * warp_complexity;

    float2 q = float2(
        bcs_fbm(st + float2(t * 0.5, t * 0.3), 4),
        bcs_fbm(st + float2(5.2, 1.3) + float2(t * 0.4, t * 0.6), 4)
    );

    // Mix organic warping with simple radial breathing
    float2 center = float2(0.5, 0.5);
    float2 fromCenter = uv - center;
    float dist = length(fromCenter);

    // Radial breathe: expand/contract from center
    float radialPulse = breathe1 * (1.0 - organic) + breathe2 * organic;
    float2 radialDisp = fromCenter * (radialPulse - 0.5) * 2.0;

    // Organic warp: flowing noise displacement
    float2 organicDisp = float2(
        (q.x - 0.5) * 2.0 * breathe2,
        (q.y - 0.5) * 2.0 * breathe3
    );

    float2 disp = mix(radialDisp, organicDisp, organic) * breathe_depth;

    // Edge softening, less displacement at edges to prevent harsh cutoff
    float edgeFade = smoothstep(0.0, 0.15, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
    disp *= edgeFade;

    float2 samplePos = clamp(position + disp, float2(0.0), size);
    half4 color = layer.sample(samplePos);

    // Subtle color shift with breathing
    float colorPulse = breathe1 * 0.05;
    color.r *= half(1.0 + colorPulse);
    color.b *= half(1.0 - colorPulse);

    // Slight brightness pulse
    float brightPulse = 1.0 + (breathe1 - 0.5) * 0.08;
    color.rgb *= half(brightPulse);

    return color;
}

// MARK: - 30. Gravity Wells
// Multiple points of gravitational distortion pulling the image

[[ stitchable ]] half4 bcs_gravityWells(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float well_strength,  // 10-200: pull force
    float well_count,     // 1-5: number of gravity wells
    float orbit_speed,    // 0.1-3: how fast wells move
    float warp_falloff    // 0.5-5: how quickly gravity falls off
) {
    float2 uv = position / size;
    float aspectRatio = size.x / size.y;
    float2 totalDisp = float2(0.0);

    int wells = int(clamp(well_count, 1.0, 5.0));

    for (int i = 0; i < wells; i++) {
        // Each well orbits on its own path
        float phase = float(i) * 6.2832 / float(wells);
        float speed1 = orbit_speed * (0.7 + float(i) * 0.15);
        float orbitRadius = 0.2 + float(i) * 0.06;

        float2 wellPos = float2(
            0.5 + cos(time * speed1 + phase) * orbitRadius,
            0.5 + sin(time * speed1 * 0.8 + phase * 1.3) * orbitRadius
        );

        float2 delta = uv - wellPos;
        delta.x *= aspectRatio;
        float dist = length(delta);

        // Gravity: inverse power law
        float pull = well_strength / (pow(dist, warp_falloff) * size.y + 10.0);
        pull = min(pull, well_strength * 0.5);

        float2 dir = dist > 0.001 ? normalize(delta) : float2(0.0);
        totalDisp -= dir * pull;
    }

    float2 samplePos = clamp(position + totalDisp, float2(0.0), size);
    half4 color = layer.sample(samplePos);

    // Chromatic aberration proportional to total displacement
    float dispMag = length(totalDisp) * 0.1;
    float2 chromaDir = totalDisp * 0.08;
    half4 rSamp = layer.sample(clamp(samplePos + chromaDir, float2(0.0), size));
    half4 bSamp = layer.sample(clamp(samplePos - chromaDir, float2(0.0), size));
    float chromaBlend = clamp(dispMag * 0.02, 0.0, 0.5);
    color.r = mix(color.r, rSamp.r, half(chromaBlend));
    color.b = mix(color.b, bSamp.b, half(chromaBlend));

    return color;
}

// MARK: - 32. Liquid Mirror
// Seamless water-like reflection, no visible mirror line

[[ stitchable ]] half4 bcs_liquidMirror(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float mirror_axis,    // 0.3-0.7: where the reflection starts
    float ripple,         // 2-30: ripple displacement
    float speed,          // 0.5-3: ripple animation speed
    float depth           // 0-1: how far the reflection extends / fade
) {
    float2 uv = position / size;

    // Soft transition zone instead of a hard line
    float transitionWidth = 0.08;
    float reflectionStart = mirror_axis - transitionWidth;
    float reflectionFull = mirror_axis + transitionWidth;

    // How deep into the reflection zone (0=start, 1=bottom of screen)
    float reflectionDepth = smoothstep(reflectionStart, 1.0, uv.y);
    // Blend factor: 0 in original image, ramps to 1 in full reflection
    float reflectionBlend = smoothstep(reflectionStart, reflectionFull, uv.y);

    // Mirror UV: flip around the axis
    float2 mirrorUV = uv;
    if (uv.y > reflectionStart) {
        mirrorUV.y = mirror_axis - (uv.y - mirror_axis);
    }

    // Liquid ripple displacement, only in reflected area
    float t = time * speed;
    float2 rippleSt = mirrorUV * 6.0;

    float ripple1 = sin(rippleSt.x * 4.0 + t * 1.3) * cos(rippleSt.y * 3.0 + t * 0.9);
    float ripple2 = sin(rippleSt.x * 7.0 - t * 1.7) * cos(rippleSt.y * 5.0 + t * 1.1);
    float ripple3 = bcs_valueNoise(rippleSt + float2(t * 0.5, t * 0.3));

    float rippleStrength = reflectionBlend * reflectionDepth;
    float2 rippleDisp = float2(
        (ripple1 * 0.5 + ripple2 * 0.3 + (ripple3 - 0.5) * 0.4),
        (ripple1 * 0.3 + ripple2 * 0.5 + (ripple3 - 0.5) * 0.3)
    ) * ripple * rippleStrength;

    // Sample reflected image
    float2 reflectedPos = clamp(mirrorUV * size + rippleDisp, float2(0.0), size);
    half4 reflectedColor = layer.sample(reflectedPos);

    // Sample original image
    half4 originalColor = layer.sample(position);

    // Fade reflection based on depth parameter
    float fadeFactor = 1.0 - reflectionDepth * depth;
    reflectedColor.rgb *= half(max(fadeFactor, 0.2));

    // Slight desaturation on reflection for realism
    half luma = dot(reflectedColor.rgb, half3(0.299h, 0.587h, 0.114h));
    reflectedColor.rgb = mix(reflectedColor.rgb, half3(luma), half(reflectionDepth * 0.2));

    // Blend: smooth crossfade from original to reflection
    half4 color = mix(originalColor, reflectedColor, half(reflectionBlend));

    // Subtle caustic highlight shimmer on the water
    float caustic = pow(max(ripple1 * ripple2 + 0.5, 0.0), 10.0) * 0.15 * rippleStrength;
    color.rgb += half3(caustic);

    return color;
}

// MARK: - 33. Aurora
// Northern lights: flowing bands of colored light across the image

[[ stitchable ]] half4 bcs_aurora(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float intensity,      // 0-1: aurora visibility
    float bands,          // 1-8: number of light bands
    float speed,          // 0.3-3: flow speed
    float color_shift     // 0-1: shifts the base hue palette
) {
    float2 uv = position / size;
    half4 color = layer.sample(position);

    float t = time * speed;

    // Aurora is brightest in the upper portion
    float heightMask = smoothstep(0.8, 0.1, uv.y);
    heightMask *= smoothstep(0.0, 0.15, uv.y); // fade at very top

    // Flowing bands using layered sine waves
    float auroraVal = 0.0;
    float hueAccum = 0.0;

    for (int i = 0; i < int(bands); i++) {
        float fi = float(i);
        float freq = 2.0 + fi * 1.5;
        float phase = fi * 1.7;

        // Wavy band shape
        float wave = sin(uv.x * freq * 3.14159 + t * (0.8 + fi * 0.3) + phase);
        wave += sin(uv.x * freq * 1.7 + t * 0.5 + fi * 2.3) * 0.5;

        // Band position oscillates vertically
        float bandY = 0.3 + fi / bands * 0.4 + wave * 0.08;
        float bandDist = abs(uv.y - bandY);

        // Soft band shape
        float band = exp(-bandDist * bandDist * 200.0) * (0.6 + fi * 0.1);

        // Noise-driven intensity variation along the band
        float noiseVal = bcs_fbm(float2(uv.x * 3.0 + t * 0.3, fi * 5.0 + t * 0.1), 3);
        band *= noiseVal;

        auroraVal += band;
        hueAccum += band * (fi / bands);
    }

    auroraVal = clamp(auroraVal, 0.0, 1.0) * heightMask * intensity;

    // Color: aurora greens, teals, purples, pinks
    float hue = fract(color_shift + hueAccum * 0.3 + 0.35); // base green
    half3 auroraColor = bcs_hsb2rgb(half3(half(hue), 0.7h, 1.0h));

    // Additive blend, light overlay
    color.rgb += auroraColor * half(auroraVal * 0.7);

    // Subtle vertical shimmer
    float shimmer = sin(uv.y * 80.0 + t * 5.0) * 0.02 * auroraVal;
    color.rgb += half3(shimmer);

    return color;
}

// MARK: - 34. Wormhole
// Tunnel zoom into the image center with spiral distortion

[[ stitchable ]] half4 bcs_wormhole(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float depth,          // 1-8: tunnel depth / zoom factor
    float speed,          // 0.3-3: travel speed
    float twist,          // 0-5: spiral twist amount
    float radius          // 0.1-0.5: tunnel opening radius
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float aspectRatio = size.x / size.y;

    float2 delta = uv - center;
    delta.x *= aspectRatio;
    float dist = length(delta);
    float angle = atan2(delta.y, delta.x);

    // Tunnel mapping: remap distance to depth
    float t = time * speed;
    float tunnelDepth = radius / max(dist, 0.001);

    // Spiral twist increases with depth
    float twistAngle = angle + twist * tunnelDepth * 0.3 + t * 0.5;

    // Map tunnel coordinates back to image space
    float zoomFactor = fract(tunnelDepth * depth * 0.1 - t * 0.3);
    float scale = mix(0.2, 2.0, zoomFactor);

    float2 tunnelUV = center + float2(
        cos(twistAngle) * scale * 0.3,
        sin(twistAngle) * scale * 0.3
    );

    // Keep in bounds with wrapping feel
    tunnelUV = fract(tunnelUV);

    float2 samplePos = clamp(tunnelUV * size, float2(0.0), size);
    half4 color = layer.sample(samplePos);

    // Depth fog: darker toward the center (deeper in tunnel)
    float fog = smoothstep(0.0, radius * 2.0, dist);
    color.rgb *= half(0.3 + fog * 0.7);

    // Tunnel ring highlights
    float ringPattern = fract(tunnelDepth * depth * 0.1 - t * 0.3);
    float ring = exp(-pow((ringPattern - 0.5) * 8.0, 2.0)) * 0.2;
    color.rgb += half3(ring * 0.5h, ring * 0.6h, ring * 1.0h);

    // Edge vignette
    float vignette = 1.0 - smoothstep(0.3, 0.7, dist);
    color.rgb += half3(vignette * 0.05h);

    // Chromatic aberration at tunnel edges
    float chromaAmt = (1.0 - fog) * 3.0;
    float2 chromaDir = dist > 0.001 ? normalize(delta) * chromaAmt : float2(0.0);
    chromaDir.x /= aspectRatio;
    half4 rSamp = layer.sample(clamp((tunnelUV + chromaDir * 0.003) * size, float2(0.0), size));
    half4 bSamp = layer.sample(clamp((tunnelUV - chromaDir * 0.003) * size, float2(0.0), size));
    float chromaBlend = (1.0 - fog) * 0.4;
    color.r = mix(color.r, rSamp.r, half(chromaBlend));
    color.b = mix(color.b, bSamp.b, half(chromaBlend));

    return color;
}

// MARK: - 35. Duochrome
// Two-tone color mapping with contrast control, dramatic poster effect

[[ stitchable ]] half4 bcs_duochrome(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float intensity,      // 0-1: strength of the effect
    float hue1,           // 0-1: shadow hue
    float hue2,           // 0-1: highlight hue
    float contrast        // 0.5-2: contrast boost
) {
    half4 original = layer.sample(position);

    // Luminance
    float luma = dot(float3(original.rgb), float3(0.299, 0.587, 0.114));

    // Contrast curve
    luma = clamp((luma - 0.5) * contrast + 0.5, 0.0, 1.0);

    // Slow hue animation
    float animHue1 = fract(hue1 + sin(time * 0.3) * 0.02);
    float animHue2 = fract(hue2 + cos(time * 0.25) * 0.02);

    // Two-tone mapping: shadows → hue1, highlights → hue2
    half3 shadowColor = bcs_hsb2rgb(half3(half(animHue1), 0.85h, 0.4h));
    half3 highlightColor = bcs_hsb2rgb(half3(half(animHue2), 0.7h, 1.0h));

    // Smooth interpolation with midtone richness
    half3 duoColor;
    if (luma < 0.5) {
        float t = luma * 2.0;
        // Dark to shadow color
        duoColor = mix(half3(0.02h), shadowColor, half(t));
    } else {
        float t = (luma - 0.5) * 2.0;
        // Shadow to highlight
        duoColor = mix(shadowColor, highlightColor, half(t));
    }

    half3 result = mix(original.rgb, duoColor, half(intensity));
    return half4(result, original.a);
}

// MARK: - Disintegrate
// Thanos-snap style particle dissolution, pixels scatter into dust

[[ stitchable ]] half4 bcs_disintegrate(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float threshold,    // 0-1: how much has dissolved
    float edgeWidth,    // 0.05-0.3: width of the burning edge
    float driftAmount,  // 0-50: how far particles drift
    float direction     // 0-6.28: drift direction angle
) {
    float2 uv = position / size;
    half4 original = layer.sample(position);

    if (original.a < 0.01h) return original;

    // Multi-octave noise for organic dissolve pattern
    float noise = bcs_fbm(uv * 6.0 + float2(time * 0.1), 5);
    float noise2 = bcs_fbm(uv * 12.0 + float2(17.0, 31.0), 4);
    float combinedNoise = noise * 0.7 + noise2 * 0.3;

    // Dissolve threshold with spatial sweep (bottom-right to top-left)
    float sweep = (uv.x * 0.4 + (1.0 - uv.y) * 0.6);
    float dissolveValue = combinedNoise * 0.6 + sweep * 0.4;

    // Core dissolve mask
    float edge = smoothstep(threshold - edgeWidth, threshold, dissolveValue);
    float innerEdge = smoothstep(threshold - edgeWidth * 0.3, threshold, dissolveValue);

    if (dissolveValue < threshold - edgeWidth * 1.5) {
        return half4(0.0h);
    }

    // Ember/glow edge
    float edgeMask = edge - innerEdge;
    half3 emberColor = half3(1.0h, 0.4h, 0.05h);
    half3 whiteHot = half3(1.0h, 0.95h, 0.8h);
    half3 glowColor = mix(emberColor, whiteHot, half(innerEdge * 0.8));

    // Particle drift at the edge
    float2 driftDir = float2(cos(direction), sin(direction));
    float particleDrift = (1.0 - edge) * driftAmount;
    float scatter = bcs_valueNoise(uv * 30.0 + time * 2.0);
    float2 driftOffset = driftDir * particleDrift + float2(scatter - 0.5, scatter - 0.5) * particleDrift * 0.5;

    float2 driftedPos = clamp(position + driftOffset, float2(0.0), size);
    half4 driftedColor = layer.sample(driftedPos);

    half4 result = mix(driftedColor, original, half(edge));
    result.rgb = mix(result.rgb, glowColor, half(edgeMask * 3.0));
    result.rgb += glowColor * half(edgeMask * 2.0);
    result.a *= half(edge);

    // Flickering sparks
    float sparkle = step(0.97, bcs_valueNoise(uv * 50.0 + time * 5.0)) * edgeMask * 5.0;
    result.rgb += half3(sparkle * 1.0, sparkle * 0.7, sparkle * 0.3);

    return result;
}

// MARK: - Solarize
// Film solarization, psychedelic inversion at selective luminance thresholds

[[ stitchable ]] half4 bcs_solarize(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float threshold,      // 0.2-0.8: luminance threshold for inversion
    float curveIntensity, // 0-3: how sharp the solarization curve is
    float colorSeparation,// 0-1: separate channels for psychedelic color
    float animate         // 0-1: how much the threshold oscillates
) {
    half4 original = layer.sample(position);
    float2 uv = position / size;

    float animOffset = sin(time * 1.5 + uv.x * 3.0) * animate * 0.15;
    float t = threshold + animOffset;

    half3 result;
    for (int ch = 0; ch < 3; ch++) {
        float channelOffset = float(ch) * colorSeparation * 0.08;
        float channelThreshold = t + channelOffset;
        float val = float(original.rgb[ch]);
        float dist = abs(val - channelThreshold);
        float curve = 1.0 - pow(dist * curveIntensity, 2.0);
        curve = clamp(curve, 0.0, 1.0);
        float inverted = 1.0 - val;
        float solarized = mix(val, inverted, curve);
        result[ch] = half(solarized);
    }

    float grain = (bcs_hash(uv * 500.0 + fract(time * 0.1)) - 0.5) * 0.04;
    result += half3(grain);

    return half4(result, original.a);
}

// MARK: - Pixelate Mosaic
// 3D beveled tiles with animated assembly, not flat pixelation

[[ stitchable ]] half4 bcs_pixelateMosaic(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float pixelSize,       // 4-60: size of each tile
    float bevel,           // 0-1: 3D bevel depth on tiles
    float animateAssemble, // 0-1: tiles slide in from scattered positions
    float gap              // 0-0.3: gap between tiles (grout)
) {
    float2 uv = position / size;

    float2 gridUV = floor(uv * size / pixelSize) * pixelSize / size;
    float2 cellUV = fract(uv * size / pixelSize);

    float gapMask = 1.0;
    if (gap > 0.001) {
        float2 gapEdge = step(float2(gap * 0.5), cellUV) * step(float2(gap * 0.5), 1.0 - cellUV);
        gapMask = gapEdge.x * gapEdge.y;
    }

    if (gapMask < 0.5) {
        return half4(0.02h, 0.02h, 0.03h, 1.0h);
    }

    float2 tileCenter = (gridUV + 0.5 * pixelSize / size);
    float tileHash = bcs_hash(gridUV * 100.0);
    float assembleProgress = clamp(time * 0.5 - tileHash * animateAssemble * 2.0, 0.0, 1.0);
    assembleProgress = assembleProgress * assembleProgress * (3.0 - 2.0 * assembleProgress);

    float2 scatteredPos = tileCenter + float2(
        (bcs_hash(gridUV * 200.0) - 0.5) * 0.5,
        (bcs_hash(gridUV * 300.0) - 0.5) * 0.5
    ) * (1.0 - assembleProgress);

    float2 samplePos = clamp(scatteredPos * size, float2(0.0), size);
    half4 tileColor = layer.sample(samplePos);

    // 3D bevel lighting
    float2 bevelUV = (cellUV - 0.5) * 2.0;
    float topLight = smoothstep(0.0, -0.8, bevelUV.y) * bevel;
    float leftLight = smoothstep(0.0, -0.8, bevelUV.x) * bevel * 0.5;
    float bottomShadow = smoothstep(0.0, 0.8, bevelUV.y) * bevel;

    tileColor.rgb += half3(topLight * 0.15 + leftLight * 0.1);
    tileColor.rgb -= half3(bottomShadow * 0.2);

    float edgeDist = min(min(cellUV.x, 1.0 - cellUV.x), min(cellUV.y, 1.0 - cellUV.y));
    float edgeHighlight = (1.0 - smoothstep(0.0, 0.08, edgeDist)) * bevel * 0.3;
    tileColor.rgb += half3(edgeHighlight);

    tileColor.a *= half(assembleProgress * 0.5 + 0.5);

    return tileColor;
}

// MARK: - Datamosh
// Digital codec corruption, smeared motion vectors, macro-blocking, I-frame bleed

[[ stitchable ]] half4 bcs_datamosh(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float blockCorruption, // 0-1: how many blocks are corrupted
    float smearAmount,     // 0-60: pixel displacement of smear
    float colorBleed,      // 0-1: channel separation in corrupted areas
    float glitchRate       // 0.5-5: speed of corruption changes
) {
    float2 uv = position / size;
    half4 original = layer.sample(position);

    float blockSize = 16.0;
    float2 blockUV = floor(uv * size / blockSize) / (size / blockSize);
    float blockHash = bcs_hash(blockUV * 73.0 + floor(time * glitchRate) * 0.1);

    float isCorrupted = step(1.0 - blockCorruption, blockHash);

    if (isCorrupted < 0.5) {
        return original;
    }

    float smearAngle = bcs_hash(blockUV * 137.0 + floor(time * glitchRate * 0.5) * 0.3) * 6.28;
    float2 smearDir = float2(cos(smearAngle), sin(smearAngle));
    float blockSmear = smearAmount * (0.5 + blockHash * 0.5);
    float2 smearOffset = smearDir * blockSmear;

    float2 smearPos = clamp(position + smearOffset, float2(0.0), size);
    half4 smeared = layer.sample(smearPos);

    float2 rOffset = smearOffset * (1.0 + colorBleed * 0.3);
    float2 bOffset = smearOffset * (1.0 - colorBleed * 0.2);
    half4 rSamp = layer.sample(clamp(position + rOffset, float2(0.0), size));
    half4 bSamp = layer.sample(clamp(position + bOffset, float2(0.0), size));

    half4 result = smeared;
    result.r = mix(smeared.r, rSamp.r, half(colorBleed));
    result.b = mix(smeared.b, bSamp.b, half(colorBleed));

    float quantize = 16.0;
    result.rgb = floor(result.rgb * half(quantize)) / half(quantize);

    float2 blockCell = fract(uv * size / blockSize);
    float blockEdge = 1.0 - step(0.03, min(blockCell.x, blockCell.y));
    result.rgb += half3(blockEdge * 0.1);

    return result;
}

// MARK: - Magnetic Field
// Ferrofluid-inspired displacement, lines of force warp the image

[[ stitchable ]] half4 bcs_magneticField(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float fieldStrength,  // 5-80: displacement amount
    float lineCount,      // 3-20: number of field lines
    float fieldTurbulence,// 0-1: organic disturbance
    float polarity        // 0-1: dipole vs quadrupole
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);

    float2 pole1 = center + float2(-0.25, 0.0);
    float2 pole2 = center + float2(0.25, 0.0);

    float2 toP1 = uv - pole1;
    float2 toP2 = uv - pole2;
    float r1 = max(length(toP1), 0.001);
    float r2 = max(length(toP2), 0.001);

    float2 field = toP1 / (r1 * r1) - toP2 / (r2 * r2);

    if (polarity > 0.01) {
        float2 pole3 = center + float2(0.0, -0.2);
        float2 pole4 = center + float2(0.0, 0.2);
        float2 toP3 = uv - pole3;
        float2 toP4 = uv - pole4;
        float r3 = max(length(toP3), 0.001);
        float r4 = max(length(toP4), 0.001);
        float2 quadField = toP3 / (r3 * r3) - toP4 / (r4 * r4);
        field = mix(field, field + quadField, polarity);
    }

    float fieldMag = length(field);
    float2 fieldDir = fieldMag > 0.001 ? field / fieldMag : float2(0.0);

    float angle = atan2(field.y, field.x);
    float stripes = sin(angle * lineCount + time * 2.0);
    stripes = stripes * stripes;

    float turb = bcs_fbm(uv * 8.0 + time * 0.5, 4) * fieldTurbulence;

    float2 offset = fieldDir * fieldStrength * stripes * (0.5 + turb);
    float2 perpDir = float2(-fieldDir.y, fieldDir.x);
    float perpStripe = sin(dot(uv, fieldDir) * lineCount * 10.0 + time);
    offset += perpDir * perpStripe * fieldStrength * 0.15;

    float2 displaced = clamp(position + offset, float2(0.0), size);
    half4 color = layer.sample(displaced);

    float sheen = stripes * fieldMag * 0.3;
    color.rgb += half3(sheen * 0.3, sheen * 0.35, sheen * 0.4);

    return color;
}

// MARK: - Underwater Caustics
// Dancing light refractions like sunlight through water

[[ stitchable ]] half4 bcs_underwaterCaustics(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float causticScale,    // 2-15: scale of caustic pattern
    float causticIntensity,// 0-2: brightness of caustic highlights
    float waterDistortion, // 0-30: water surface displacement
    float waterDepth       // 0-1: how deep underwater
) {
    float2 uv = position / size;

    float n1 = bcs_fbm(uv * 4.0 + float2(time * 0.3, time * 0.2), 4);
    float n2 = bcs_fbm(uv * 4.0 + float2(-time * 0.25, time * 0.35) + 10.0, 4);
    float2 waterDisp = float2(n1 - 0.5, n2 - 0.5) * waterDistortion;

    float2 displaced = clamp(position + waterDisp, float2(0.0), size);
    half4 color = layer.sample(displaced);

    // Voronoi-based caustic pattern
    float2 causticUV = uv * causticScale;
    float2 animUV1 = causticUV + float2(time * 0.4, time * 0.3);
    float2 animUV2 = causticUV * 1.3 + float2(-time * 0.35, time * 0.45);

    float caustic1 = 0.0;
    float caustic2 = 0.0;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 neighbor = float2(float(x), float(y));
            float2 cell1 = floor(animUV1) + neighbor;
            float2 point1 = cell1 + float2(bcs_hash(cell1), bcs_hash(cell1 + 100.0));
            caustic1 = max(caustic1, 1.0 - length(fract(animUV1) - fract(point1)) * 2.5);

            float2 cell2 = floor(animUV2) + neighbor;
            float2 point2 = cell2 + float2(bcs_hash(cell2 + 50.0), bcs_hash(cell2 + 150.0));
            caustic2 = max(caustic2, 1.0 - length(fract(animUV2) - fract(point2)) * 2.5);
        }
    }

    float caustic = caustic1 * caustic2;
    caustic = pow(max(caustic, 0.0), 3.0) * causticIntensity;

    half3 causticColor = half3(0.95h, 0.98h, 1.0h);
    color.rgb += causticColor * half(caustic);

    half3 depthTint = half3(0.2h, 0.5h, 0.7h);
    color.rgb = mix(color.rgb, color.rgb * (1.0h - half(waterDepth * 0.3)) + depthTint * half(waterDepth * 0.15), half(waterDepth));

    float rays = sin(uv.x * 20.0 + time * 0.5) * 0.5 + 0.5;
    rays *= smoothstep(1.0, 0.0, uv.y) * waterDepth * 0.1;
    color.rgb += half3(rays * 0.3, rays * 0.5, rays * 0.6);

    return color;
}

// MARK: - Topographic
// Contour map visualization, converts image into elevation lines

[[ stitchable ]] half4 bcs_topographic(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float lineCount,   // 5-40: number of contour lines
    float lineWidth,   // 0.01-0.15: thickness
    float colorize,    // 0-1: blend between original and topo colors
    float animate      // 0-1: animation speed of elevation shift
) {
    float2 uv = position / size;
    half4 original = layer.sample(position);

    float lum = dot(float3(original.rgb), float3(0.299, 0.587, 0.114));
    float elevation = lum + time * animate * 0.05;

    float contourValue = fract(elevation * lineCount);
    float contourLine = 1.0 - smoothstep(lineWidth, lineWidth + 0.02, contourValue)
                       + 1.0 - smoothstep(lineWidth, lineWidth + 0.02, 1.0 - contourValue);
    contourLine = clamp(contourLine, 0.0, 1.0);

    float majorContour = fract(elevation * lineCount / 5.0);
    float majorLine = 1.0 - smoothstep(lineWidth * 2.0, lineWidth * 2.0 + 0.03, majorContour)
                     + 1.0 - smoothstep(lineWidth * 2.0, lineWidth * 2.0 + 0.03, 1.0 - majorContour);
    majorLine = clamp(majorLine, 0.0, 1.0);

    half3 topoColor;
    if (lum < 0.2) {
        topoColor = mix(half3(0.1h, 0.3h, 0.5h), half3(0.15h, 0.45h, 0.3h), half(lum * 5.0));
    } else if (lum < 0.5) {
        topoColor = mix(half3(0.15h, 0.45h, 0.3h), half3(0.8h, 0.75h, 0.4h), half((lum - 0.2) * 3.33));
    } else if (lum < 0.75) {
        topoColor = mix(half3(0.8h, 0.75h, 0.4h), half3(0.65h, 0.45h, 0.3h), half((lum - 0.5) * 4.0));
    } else {
        topoColor = mix(half3(0.65h, 0.45h, 0.3h), half3(0.95h, 0.95h, 0.97h), half((lum - 0.75) * 4.0));
    }

    half3 baseColor = mix(original.rgb, topoColor, half(colorize));
    half3 lineColor = half3(0.15h, 0.12h, 0.1h);
    half3 majorLineColor = half3(0.05h, 0.04h, 0.03h);

    half3 result = baseColor;
    result = mix(result, lineColor, half(contourLine * 0.7));
    result = mix(result, majorLineColor, half(majorLine * 0.9));

    float paper = bcs_valueNoise(uv * 200.0) * 0.06 - 0.03;
    result += half3(paper);

    return half4(result, original.a);
}

// MARK: - Smoke Reveal
// Swirling smoke that clears to reveal the image underneath

[[ stitchable ]] half4 bcs_smokeReveal(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float smokeAmount,  // 0-1: smoke coverage
    float smokeScale,   // 2-10: size of smoke wisps
    float windSpeed,    // 0.5-3: how fast smoke moves
    float smokeTurb     // 0.5-3: how chaotic the smoke is
) {
    float2 uv = position / size;
    half4 original = layer.sample(position);

    float2 smokeUV = uv * smokeScale;
    float warp1x = bcs_fbm(smokeUV + float2(time * windSpeed * 0.3, time * windSpeed * 0.1), 5);
    float warp1y = bcs_fbm(smokeUV + float2(time * windSpeed * 0.1, -time * windSpeed * 0.2) + 5.2, 5);

    float2 warped = smokeUV + float2(warp1x, warp1y) * smokeTurb;
    float smokeDensity = bcs_fbm(warped + float2(time * windSpeed * 0.15, time * windSpeed * 0.08), 6);

    smokeDensity = smokeDensity * smokeDensity;
    smokeDensity *= smokeAmount * 1.5;
    smokeDensity = clamp(smokeDensity, 0.0, 1.0);

    float lightVariation = bcs_valueNoise(uv * 3.0 + time * 0.2);
    half3 smokeColor = half3(0.7h + half(lightVariation) * 0.15h,
                             0.68h + half(lightVariation) * 0.12h,
                             0.66h + half(lightVariation) * 0.1h);

    float edgeGlow = smoothstep(0.2, 0.5, smokeDensity) - smoothstep(0.5, 0.8, smokeDensity);
    smokeColor += half3(edgeGlow * 0.2);

    float2 smokeDisp = float2(warp1x - 0.5, warp1y - 0.5) * 8.0 * smokeDensity;
    float2 displacedPos = clamp(position + smokeDisp, float2(0.0), size);
    half4 displacedColor = layer.sample(displacedPos);

    half4 result;
    result.rgb = mix(displacedColor.rgb, smokeColor, half(smokeDensity));
    result.a = original.a;

    float ray = sin(uv.x * 8.0 + time * 0.3) * 0.5 + 0.5;
    ray *= smoothstep(1.0, 0.3, uv.y) * smokeDensity * 0.15;
    result.rgb += half3(ray * 0.8, ray * 0.7, ray * 0.5);

    return result;
}

// MARK: - Geometric Warp
// Droste effect / Escher-inspired infinite spiral zoom

[[ stitchable ]] half4 bcs_geometricWarp(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float spiralTight,  // 1-8: tightness of the spiral
    float zoomRepeat,   // 0.3-2: how fast the zoom repeats
    float rotation,     // 0-6.28: base rotation
    float blend         // 0-1: blend between spiral and kaleidoscope
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float2 delta = uv - center;

    float r = length(delta);
    float theta = atan2(delta.y, delta.x);

    float logR = log(max(r, 0.0001));
    float spiralAngle = theta + logR * spiralTight + time * 0.5 + rotation;

    float zoomPhase = fract(logR * zoomRepeat + time * 0.2);
    float repeatedR = exp(zoomPhase / zoomRepeat);

    float segments = 6.0;
    float kAngle = fmod(spiralAngle, 6.28 / segments);
    if (fmod(floor(spiralAngle / (6.28 / segments)), 2.0) > 0.5) {
        kAngle = 6.28 / segments - kAngle;
    }

    float finalAngle = mix(spiralAngle, kAngle, blend);

    float2 warpedUV = center + float2(cos(finalAngle), sin(finalAngle)) * repeatedR * 0.3;
    warpedUV = fract(warpedUV);

    float2 samplePos = clamp(warpedUV * size, float2(0.0), size);
    half4 color = layer.sample(samplePos);

    float centerGlow = exp(-r * r * 8.0) * 0.15;
    color.rgb += half3(centerGlow * 0.5, centerGlow * 0.7, centerGlow);

    float boundary = 1.0 - smoothstep(0.0, 0.02, abs(fract(logR * zoomRepeat + time * 0.2) - 0.5) - 0.48);
    color.rgb += half3(boundary * 0.05, boundary * 0.02, boundary * 0.08);

    return color;
}

// MARK: - Shatter Glass
// Cracked glass with refraction and prismatic splitting at cracks

[[ stitchable ]] half4 bcs_shatterGlass(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float crackDensity,   // 3-15: number of shatter cells
    float glassRefraction,// 0-20: displacement at crack edges
    float prismStrength,  // 0-1: rainbow splitting at cracks
    float shatterSpread   // 0-1: how much shards separate
) {
    float2 uv = position / size;

    float2 cellUV = uv * crackDensity;
    float2 iCell = floor(cellUV);
    float2 fCell = fract(cellUV);

    float minDist = 10.0;
    float secondDist = 10.0;
    float2 nearestPoint = float2(0.0);
    float2 secondPoint = float2(0.0);
    float nearestHash = 0.0;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 neighbor = float2(float(x), float(y));
            float2 cell = iCell + neighbor;
            float2 point = float2(
                bcs_hash(cell),
                bcs_hash(cell + float2(127.1, 311.7))
            );

            float2 diff = neighbor + point - fCell;
            float d = length(diff);

            if (d < minDist) {
                secondDist = minDist;
                secondPoint = nearestPoint;
                minDist = d;
                nearestPoint = diff;
                nearestHash = bcs_hash(cell + 500.0);
            } else if (d < secondDist) {
                secondDist = d;
                secondPoint = diff;
            }
        }
    }

    float edgeDist = secondDist - minDist;
    float crackLine = 1.0 - smoothstep(0.0, 0.06, edgeDist);

    float2 shardOffset = nearestPoint * shatterSpread * 15.0;
    float shardAngle = nearestHash * 0.3 * shatterSpread;
    float2 rotatedPos = float2(
        cos(shardAngle) * shardOffset.x - sin(shardAngle) * shardOffset.y,
        sin(shardAngle) * shardOffset.x + cos(shardAngle) * shardOffset.y
    );

    float2 displaced = clamp(position + rotatedPos, float2(0.0), size);

    float2 refrDir = normalize(nearestPoint - secondPoint);
    float2 refrOffset = refrDir * glassRefraction * crackLine;
    displaced = clamp(displaced + refrOffset, float2(0.0), size);

    half4 color = layer.sample(displaced);

    if (prismStrength > 0.01 && crackLine > 0.1) {
        float2 rPos = clamp(displaced + refrDir * prismStrength * 5.0, float2(0.0), size);
        float2 bPos = clamp(displaced - refrDir * prismStrength * 5.0, float2(0.0), size);
        color.r = layer.sample(rPos).r;
        color.b = layer.sample(bPos).b;
    }

    float edgeHighlight = crackLine * (0.5 + 0.5 * sin(edgeDist * 100.0 + time));
    color.rgb += half3(edgeHighlight * 0.6);

    float shardBrightness = nearestHash * 0.15 - 0.075;
    color.rgb += half3(shardBrightness);

    float crackShadow = crackLine * 0.4;
    color.rgb -= half3(crackShadow);

    return color;
}

// ============================================================================
// MARK: - MESH BACKGROUND GENERATORS
// These shaders sample colors from the book cover image and use them
// to generate procedural animated backgrounds
// ============================================================================

// Shared helper: sample a blurred region from the cover (average of nearby pixels)
static half3 bcs_sampleRegion(SwiftUI::Layer layer, float2 center, float2 size, float radius) {
    half3 total = half3(0.0h);
    float samples = 0.0;
    for (float dy = -radius; dy <= radius; dy += radius * 0.5) {
        for (float dx = -radius; dx <= radius; dx += radius * 0.5) {
            float2 pos = clamp(center + float2(dx, dy), float2(0.0), size);
            total += layer.sample(pos).rgb;
            samples += 1.0;
        }
    }
    return total / half(samples);
}

// (End of cover gradient generators)
