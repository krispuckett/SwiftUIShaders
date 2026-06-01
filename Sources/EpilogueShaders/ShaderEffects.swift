// ShaderEffects.swift — typed SwiftUI wrappers for every shader in EpilogueShaders.metal.
//
// This file is generated to mirror the Metal function signatures. Each method applies
// one `[[ stitchable ]]` shader as a `layerEffect`. Conventions:
//   • `proxy.size`  is supplied automatically (the shader's `size` argument).
//   • Animated shaders self-drive their `time` argument via `TimelineView(.animation)`.
//   • Interaction points are passed as `UnitPoint` (0...1) and converted to pixels.
//   • `maxSampleOffset` caps how far a shader may sample; raise it if a heavy
//     displacement effect looks clipped at the edges.
//
// Requires iOS 17+ / macOS 14+ (SwiftUI Metal shader effects).

import SwiftUI

/// Applies a static (non-animated) Metal `layerEffect`. The closure receives the
/// view's pixel size and returns the configured `Shader`.
struct _StaticShaderEffect: ViewModifier {
    let maxSampleOffset: CGSize
    let shader: (CGSize) -> Shader
    func body(content: Content) -> some View {
        content.visualEffect { view, proxy in
            view.layerEffect(shader(proxy.size), maxSampleOffset: maxSampleOffset)
        }
    }
}

/// Applies an animated Metal `layerEffect`, driving the shader's `time` argument
/// from `TimelineView(.animation)`. The closure receives pixel size and elapsed time.
struct _AnimatedShaderEffect: ViewModifier {
    let maxSampleOffset: CGSize
    let shader: (CGSize, Float) -> Shader
    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let t = Float(context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 3600))
            content.visualEffect { view, proxy in
                view.layerEffect(shader(proxy.size, t), maxSampleOffset: maxSampleOffset)
            }
        }
    }
}

public extension View {
    /// Aurora — Northern lights: flowing bands of colored light across the image
    /// - Parameter intensity: 0-1: aurora visibility
    /// - Parameter bands: 1-8: number of light bands
    /// - Parameter speed: 0.3-3: flow speed
    /// - Parameter colorShift: 0-1: shifts the base hue palette
    /// Self-animates via `TimelineView(.animation)`.
    func bcsAurora(intensity: Float = 0.5, bands: Float = 4.5, speed: Float = 1.65, colorShift: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_aurora(
                .float2(size),
                .float(t),
                .float(intensity),
                .float(bands),
                .float(speed),
                .float(colorShift)
            )
        })
    }

    /// Black Hole — Gravitational lensing — warps space around a singularity
    /// - Parameter mass: 0.05-0.5: size/strength of the singularity
    /// - Parameter spin: 0-5: rotation speed of the accretion disk
    /// - Parameter distortion: 10-200: warp strength
    /// - Parameter ringBrightness: 0-2: accretion disk glow
    /// Self-animates via `TimelineView(.animation)`.
    func bcsBlackHole(mass: Float = 0.28, spin: Float = 2.5, distortion: Float = 105, ringBrightness: Float = 1, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_blackHole(
                .float2(size),
                .float(t),
                .float(mass),
                .float(spin),
                .float(distortion),
                .float(ringBrightness)
            )
        })
    }

    /// Caustics — Underwater light patterns dancing across the cover
    /// - Parameter intensity: 0-1: brightness of caustic patterns
    /// - Parameter scale: 1-15: size of the caustic cells
    /// - Parameter speed: 0.5-5: animation speed
    /// - Parameter distortion: 0-15: pixel displacement from caustics
    /// Self-animates via `TimelineView(.animation)`.
    func bcsCaustics(intensity: Float = 0.5, scale: Float = 8, speed: Float = 2.75, distortion: Float = 7.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_caustics(
                .float2(size),
                .float(t),
                .float(intensity),
                .float(scale),
                .float(speed),
                .float(distortion)
            )
        })
    }

    /// Chromatic Fog — The cover dissolves into colored fog — each RGB channel warps independently, creating a soft chromatic separation that feels like colored mist.
    /// - Parameter fogDensity: 20-100: blur/fog amount
    /// - Parameter separation: 0-30: RGB channel separation distance
    /// - Parameter driftSpeed: 0.2-2: fog movement speed
    /// - Parameter depth: 0.3-1: how deep into fog
    /// Self-animates via `TimelineView(.animation)`.
    func bcsChromaticFog(fogDensity: Float = 60, separation: Float = 15, driftSpeed: Float = 1.1, depth: Float = 0.65, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_chromaticFog(
                .float2(size),
                .float(t),
                .float(fogDensity),
                .float(separation),
                .float(driftSpeed),
                .float(depth)
            )
        })
    }

    /// Chromatic Split — RGB channel separation with directional control
    /// - Parameter spread: 0-30: pixel distance between channels
    /// - Parameter angle: 0-6.28: direction of the split
    /// - Parameter edgeOnly: 0-1: limit effect to edges (radial falloff
    /// - Parameter animate: 0-1: animate the spread
    /// Self-animates via `TimelineView(.animation)`.
    func bcsChromaticSplit(spread: Float = 15, angle: Float = 3.14, edgeOnly: Float = 0.5, animate: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_chromaticSplit(
                .float2(size),
                .float(spread),
                .float(angle),
                .float(edgeOnly),
                .float(t),
                .float(animate)
            )
        })
    }

    /// Crystal Prism — Prismatic dispersion — facet boundaries are implicit through color separation
    /// - Parameter facetSize: 2-20: size of crystal facets
    /// - Parameter dispersion: 2-30: rainbow spread
    /// - Parameter rotation: 0-3: facet rotation speed
    /// - Parameter sparkle: 0-2: specular highlight intensity
    /// Self-animates via `TimelineView(.animation)`.
    func bcsCrystalPrism(facetSize: Float = 11, dispersion: Float = 16, rotation: Float = 1.5, sparkle: Float = 1, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_crystalPrism(
                .float2(size),
                .float(t),
                .float(facetSize),
                .float(dispersion),
                .float(rotation),
                .float(sparkle)
            )
        })
    }

    /// Datamosh — Digital codec corruption — smeared motion vectors, macro-blocking, I-frame bleed
    /// - Parameter blockCorruption: 0-1: how many blocks are corrupted
    /// - Parameter smearAmount: 0-60: pixel displacement of smear
    /// - Parameter colorBleed: 0-1: channel separation in corrupted areas
    /// - Parameter glitchRate: 0.5-5: speed of corruption changes
    /// Self-animates via `TimelineView(.animation)`.
    func bcsDatamosh(blockCorruption: Float = 0.5, smearAmount: Float = 30, colorBleed: Float = 0.5, glitchRate: Float = 2.75, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_datamosh(
                .float2(size),
                .float(t),
                .float(blockCorruption),
                .float(smearAmount),
                .float(colorBleed),
                .float(glitchRate)
            )
        })
    }

    /// Disintegrate — Thanos-snap style particle dissolution — pixels scatter into dust
    /// - Parameter threshold: 0-1: how much has dissolved
    /// - Parameter edgeWidth: 0.05-0.3: width of the burning edge
    /// - Parameter driftAmount: 0-50: how far particles drift
    /// - Parameter direction: 0-6.28: drift direction angle
    /// Self-animates via `TimelineView(.animation)`.
    func bcsDisintegrate(threshold: Float = 0.5, edgeWidth: Float = 0.17, driftAmount: Float = 25, direction: Float = 3.14, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_disintegrate(
                .float2(size),
                .float(t),
                .float(threshold),
                .float(edgeWidth),
                .float(driftAmount),
                .float(direction)
            )
        })
    }

    /// Dissolve — Noise-driven dissolve that eats away the image — particles scatter
    /// - Parameter threshold: 0-1: how dissolved (0=solid, 1=gone
    /// - Parameter edgeWidth: 0.01-0.2: width of the burning edge
    /// - Parameter noiseScale: 1-15: size of dissolve pattern
    /// - Parameter edgeGlow: 0-3: brightness of the dissolve edge
    /// Self-animates via `TimelineView(.animation)`.
    func bcsDissolve(threshold: Float = 0.5, edgeWidth: Float = 0.11, noiseScale: Float = 8, edgeGlow: Float = 1.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_dissolve(
                .float2(size),
                .float(t),
                .float(threshold),
                .float(edgeWidth),
                .float(noiseScale),
                .float(edgeGlow)
            )
        })
    }

    /// Dream Blur — Effects below transform the actual book cover image into atmospheric backgrounds. They sample and warp the cover's own pixels — not just its colors. The cover image dissolves into a soft, breathing, domain-warped blur. Like seeing the cover through frosted glass that slowly shifts.
    /// - Parameter blurRadius: 20-120: how blurred/dissolved the cover becomes
    /// - Parameter warpStrength: 0-1: how much the blur field warps
    /// - Parameter breatheSpeed: 0.2-2: speed of the breathing motion
    /// - Parameter satBoost: 0-1: saturation enhancement
    /// Self-animates via `TimelineView(.animation)`.
    func bcsDreamBlur(blurRadius: Float = 70, warpStrength: Float = 0.5, breatheSpeed: Float = 1.1, satBoost: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_dreamBlur(
                .float2(size),
                .float(t),
                .float(blurRadius),
                .float(warpStrength),
                .float(breatheSpeed),
                .float(satBoost)
            )
        })
    }

    /// Duochrome — Two-tone color mapping with contrast control — dramatic poster effect
    /// - Parameter intensity: 0-1: strength of the effect
    /// - Parameter hue1: 0-1: shadow hue
    /// - Parameter hue2: 0-1: highlight hue
    /// - Parameter contrast: 0.5-2: contrast boost
    /// Self-animates via `TimelineView(.animation)`.
    func bcsDuochrome(intensity: Float = 0.5, hue1: Float = 0.5, hue2: Float = 0.5, contrast: Float = 1.25, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_duochrome(
                .float2(size),
                .float(t),
                .float(intensity),
                .float(hue1),
                .float(hue2),
                .float(contrast)
            )
        })
    }

    /// Echo / Ghost — Multiple trailing offset copies that create a spectral echo
    /// - Parameter echoCount: 2-8: number of ghost copies
    /// - Parameter spread: 5-50: pixel distance between echoes
    /// - Parameter direction: 0-6.28: angle of echo trail
    /// - Parameter fade: 0.3-0.9: opacity falloff per echo
    /// Self-animates via `TimelineView(.animation)`.
    func bcsEcho(echoCount: Float = 5, spread: Float = 28, direction: Float = 3.14, fade: Float = 0.6, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_echo(
                .float2(size),
                .float(t),
                .float(echoCount),
                .float(spread),
                .float(direction),
                .float(fade)
            )
        })
    }

    /// Echo Trails — The cover image echoes outward in ghostly copies that trail off at different angles, like seeing the cover's spirit leave its body.
    /// - Parameter trailCount: 2-8: number of echo ghosts
    /// - Parameter trailSpread: 0.02-0.15: how far apart echoes are
    /// - Parameter fadeRate: 0.3-0.8: how quickly echoes fade
    /// - Parameter driftAngle: 0-6.28: direction echoes drift
    /// Self-animates via `TimelineView(.animation)`.
    func bcsEchoTrails(trailCount: Float = 5, trailSpread: Float = 0.08, fadeRate: Float = 0.55, driftAngle: Float = 3.14, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_echoTrails(
                .float2(size),
                .float(t),
                .float(trailCount),
                .float(trailSpread),
                .float(fadeRate),
                .float(driftAngle)
            )
        })
    }

    /// Emboss / Relief — Creates a 3D carved look from the cover art using edge detection
    /// - Parameter strength: 0-5: how pronounced the relief is
    /// - Parameter angle: 0-6.28: light direction in radians
    /// - Parameter mixAmount: 0-1: blend between original and embossed
    func bcsEmboss(strength: Float = 2.5, angle: Float = 3.14, mixAmount: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_StaticShaderEffect(maxSampleOffset: maxSampleOffset) { size in
            ShaderLibrary.bundle(.module).bcs_emboss(
                .float2(size),
                .float(strength),
                .float(angle),
                .float(mixAmount)
            )
        })
    }

    /// Ethereal Aura (v2) — The cover BREATHES — edges warp and glow with visible liquid displacement
    /// - Parameter auraWidth:
    /// - Parameter auraIntensity:
    /// - Parameter pulseSpeed:
    /// - Parameter distortion:
    /// - Parameter hueShift:
    /// Self-animates via `TimelineView(.animation)`.
    func bcsEtherealAura(auraWidth: Float = 1, auraIntensity: Float = 1, pulseSpeed: Float = 1, distortion: Float = 1, hueShift: Float = 1, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_etherealAura(
                .float2(size),
                .float(t),
                .float(auraWidth),
                .float(auraIntensity),
                .float(pulseSpeed),
                .float(distortion),
                .float(hueShift)
            )
        })
    }

    /// Fluid Mesh — Dense grid sampling with flowing interpolation — a more liquid mesh gradient.
    /// - Parameter gridSize: 3-8: mesh grid density
    /// - Parameter fluidity: 0.1-0.5: how much grid points move
    /// - Parameter blendRadius: 1-5: softness of cell blending
    /// - Parameter satBoost: 0-1: saturation enhancement
    /// Self-animates via `TimelineView(.animation)`.
    func bcsFluidMesh(gridSize: Float = 5.5, fluidity: Float = 0.3, blendRadius: Float = 3, satBoost: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_fluidMesh(
                .float2(size),
                .float(t),
                .float(gridSize),
                .float(fluidity),
                .float(blendRadius),
                .float(satBoost)
            )
        })
    }

    /// Fractal Mirror — The cover is reflected and tiled in kaleidoscopic fashion, creating mandala-like patterns from the cover's own imagery.
    /// - Parameter segments: 2-12: number of kaleidoscope segments
    /// - Parameter zoom: 0.5-3: zoom into the pattern
    /// - Parameter rotationSpeed: 0-1: rotation animation speed
    /// - Parameter blendSoft: 0-1: softness of the mirrored sampling
    /// Self-animates via `TimelineView(.animation)`.
    func bcsFractalMirror(segments: Float = 7, zoom: Float = 1.75, rotationSpeed: Float = 0.5, blendSoft: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_fractalMirror(
                .float2(size),
                .float(t),
                .float(segments),
                .float(zoom),
                .float(rotationSpeed),
                .float(blendSoft)
            )
        })
    }

    /// Frosted Glass — Partial blur with a clear window — like breathing on cold glass
    /// - Parameter frostAmount: 0-1: how frosty (0 = clear, 1 = full frost
    /// - Parameter grainSize: 1-20: size of frost crystals
    /// - Parameter clearRadius: 0-1: size of clear center spot
    /// - Parameter clearSoftness: 0-1: how soft the clear/frost edge is
    func bcsFrosted(frostAmount: Float = 0.5, grainSize: Float = 10, clearRadius: Float = 0.5, clearSoftness: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_StaticShaderEffect(maxSampleOffset: maxSampleOffset) { size in
            ShaderLibrary.bundle(.module).bcs_frosted(
                .float2(size),
                .float(frostAmount),
                .float(grainSize),
                .float(clearRadius),
                .float(clearSoftness)
            )
        })
    }

    /// Gaussian Splats — ============================================================================= Each treats the book cover as DNA — extracting its unique color composition and spatial relationships to generate one-of-a-kind living gradients. ============================================================================= Reconstruct the cover from overlapping soft gaussian dots, creating a pointillist gradient. Each splat picks up color from its cover position. The result is impressionistic — a soft, painterly gradient field.
    /// - Parameter splatDensity: 4-12: grid density of splat centers
    /// - Parameter splatRadius: 0.03-0.15: size of each splat
    /// - Parameter jitter: 0-1: randomness of splat placement
    /// - Parameter satBoost: 0-1: saturation enhancement
    /// Self-animates via `TimelineView(.animation)`.
    func bcsGaussianSplats(splatDensity: Float = 8, splatRadius: Float = 0.09, jitter: Float = 0.5, satBoost: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_gaussianSplats(
                .float2(size),
                .float(t),
                .float(splatDensity),
                .float(splatRadius),
                .float(jitter),
                .float(satBoost)
            )
        })
    }

    /// Geometric Warp — Droste effect / Escher-inspired infinite spiral zoom
    /// - Parameter spiralTight: 1-8: tightness of the spiral
    /// - Parameter zoomRepeat: 0.3-2: how fast the zoom repeats
    /// - Parameter rotation: 0-6.28: base rotation
    /// - Parameter blend: 0-1: blend between spiral and kaleidoscope
    /// Self-animates via `TimelineView(.animation)`.
    func bcsGeometricWarp(spiralTight: Float = 4.5, zoomRepeat: Float = 1.15, rotation: Float = 3.14, blend: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_geometricWarp(
                .float2(size),
                .float(t),
                .float(spiralTight),
                .float(zoomRepeat),
                .float(rotation),
                .float(blend)
            )
        })
    }

    /// Glitch — Digital glitch with scan lines, block displacement, and color corruption
    /// - Parameter intensity: 0-1: overall glitch strength
    /// - Parameter blockSize: 2-50: size of glitch blocks
    /// - Parameter scanLines: 0-1: scan line darkness
    /// - Parameter colorShift: 0-20: RGB offset in pixels
    /// Self-animates via `TimelineView(.animation)`.
    func bcsGlitch(intensity: Float = 0.5, blockSize: Float = 26, scanLines: Float = 0.5, colorShift: Float = 10, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_glitch(
                .float2(size),
                .float(t),
                .float(intensity),
                .float(blockSize),
                .float(scanLines),
                .float(colorShift)
            )
        })
    }

    /// Gravity Pool — Pixels are pulled toward orbiting gravity wells, pooling and blending.
    /// - Parameter pullStrength: 0.05-0.3: how strongly pixels are pulled
    /// - Parameter wellCount: 1-4: number of gravity centers
    /// - Parameter orbitSpeed: 0.1-1: how fast wells orbit
    /// - Parameter softness: 10-50: blur/blending
    /// Self-animates via `TimelineView(.animation)`.
    func bcsGravityPool(pullStrength: Float = 0.17, wellCount: Float = 2.5, orbitSpeed: Float = 0.55, softness: Float = 30, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_gravityPool(
                .float2(size),
                .float(t),
                .float(pullStrength),
                .float(wellCount),
                .float(orbitSpeed),
                .float(softness)
            )
        })
    }

    /// Gravity Wells — Multiple points of gravitational distortion pulling the image
    /// - Parameter wellStrength: 10-200: pull force
    /// - Parameter wellCount: 1-5: number of gravity wells
    /// - Parameter orbitSpeed: 0.1-3: how fast wells move
    /// - Parameter warpFalloff: 0.5-5: how quickly gravity falls off
    /// Self-animates via `TimelineView(.animation)`.
    func bcsGravityWells(wellStrength: Float = 105, wellCount: Float = 3, orbitSpeed: Float = 1.55, warpFalloff: Float = 2.75, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_gravityWells(
                .float2(size),
                .float(t),
                .float(wellStrength),
                .float(wellCount),
                .float(orbitSpeed),
                .float(warpFalloff)
            )
        })
    }

    /// Heat Mirage — The cover image shimmers like a desert mirage — vertical ripples distort the cover as if seen through rising heat waves.
    /// - Parameter distortion: 5-60: pixel displacement amount
    /// - Parameter waveScale: 2-15: density of heat waves
    /// - Parameter riseSpeed: 0.5-3: speed of rising heat
    /// - Parameter blurAmount: 0-1: atmospheric blur
    /// Self-animates via `TimelineView(.animation)`.
    func bcsHeatMirage(distortion: Float = 32, waveScale: Float = 8.5, riseSpeed: Float = 1.75, blurAmount: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_heatMirage(
                .float2(size),
                .float(t),
                .float(distortion),
                .float(waveScale),
                .float(riseSpeed),
                .float(blurAmount)
            )
        })
    }

    /// Heat Shimmer — Animated wavering distortion like heat rising off pavement
    /// - Parameter amplitude: 0-20: pixel displacement amount
    /// - Parameter frequency: 1-30: wave tightness
    /// - Parameter speed: 0.5-5: animation speed
    /// - Parameter verticalBias: 0-1: how much stronger the effect is at top
    /// Self-animates via `TimelineView(.animation)`.
    func bcsHeatShimmer(amplitude: Float = 10, frequency: Float = 16, speed: Float = 2.75, verticalBias: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_heatShimmer(
                .float2(size),
                .float(t),
                .float(amplitude),
                .float(frequency),
                .float(speed),
                .float(verticalBias)
            )
        })
    }

    /// Holographic / Prismatic — Rainbow foil effect that shifts with time — like a holographic trading card
    /// - Parameter intensity: 0-1: strength of the rainbow overlay
    /// - Parameter scale: 1-20: size of the rainbow bands
    /// - Parameter speed: 0.1-3: animation speed
    /// - Parameter angleOffset: 0-6.28: rotate the rainbow direction
    /// Self-animates via `TimelineView(.animation)`.
    func bcsHolographic(intensity: Float = 0.5, scale: Float = 10, speed: Float = 1.55, angleOffset: Float = 3.14, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_holographic(
                .float2(size),
                .float(t),
                .float(intensity),
                .float(scale),
                .float(speed),
                .float(angleOffset)
            )
        })
    }

    /// Horizon Melt — The cover stretches vertically as if melting at the horizon — sky above, reflection below, the image smears at the split.
    /// - Parameter horizonY: 0.3-0.7: where the horizon line sits
    /// - Parameter meltAmount: 10-80: vertical smear distance
    /// - Parameter waveSpeed: 0.2-2: undulation speed
    /// - Parameter reflection: 0-1: reflection intensity below horizon
    /// Self-animates via `TimelineView(.animation)`.
    func bcsHorizonMelt(horizonY: Float = 0.5, meltAmount: Float = 45, waveSpeed: Float = 1.1, reflection: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_horizonMelt(
                .float2(size),
                .float(t),
                .float(horizonY),
                .float(meltAmount),
                .float(waveSpeed),
                .float(reflection)
            )
        })
    }

    /// Ink Bleed / Domain Warp — Makes the cover look like watercolor bleeding into wet paper
    /// - Parameter warpStrength: 0-50: how far pixels wander
    /// - Parameter scale: 1-10: size of the warp patterns
    /// - Parameter speed: 0.1-2: animation speed
    /// - Parameter detail: 2-8: noise octaves (as float, cast to int
    /// Self-animates via `TimelineView(.animation)`.
    func bcsInkBleed(warpStrength: Float = 25, scale: Float = 5.5, speed: Float = 1.05, detail: Float = 5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_inkBleed(
                .float2(size),
                .float(t),
                .float(warpStrength),
                .float(scale),
                .float(speed),
                .float(detail)
            )
        })
    }

    /// Ink Diffusion — The cover spreads like ink dropped into still water — concentric rings of the cover's pixels ripple outward while blurring and blending.
    /// - Parameter spreadRate: 0.1-0.5: how far the ink has spread
    /// - Parameter ringCount: 1-5: concentric diffusion rings
    /// - Parameter turbulence: 0-1: organic irregularity
    /// - Parameter saturation: 0.5-2: color vibrancy
    /// Self-animates via `TimelineView(.animation)`.
    func bcsInkDiffusion(spreadRate: Float = 0.3, ringCount: Float = 3, turbulence: Float = 0.5, saturation: Float = 1.25, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_inkDiffusion(
                .float2(size),
                .float(t),
                .float(spreadRate),
                .float(ringCount),
                .float(turbulence),
                .float(saturation)
            )
        })
    }

    /// Kaleidoscope — Mirrors and rotates the cover into mesmerizing symmetrical patterns
    /// - Parameter segments: 2-16: number of mirror segments
    /// - Parameter rotation: 0-6.28: manual rotation
    /// - Parameter zoom: 0.5-3: zoom level
    /// - Parameter animateSpeed: 0-2: auto-rotation speed
    /// Self-animates via `TimelineView(.animation)`.
    func bcsKaleidoscope(segments: Float = 9, rotation: Float = 3.14, zoom: Float = 1.75, animateSpeed: Float = 1, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_kaleidoscope(
                .float2(size),
                .float(t),
                .float(segments),
                .float(rotation),
                .float(zoom),
                .float(animateSpeed)
            )
        })
    }

    /// Liquid Bloom — The cover image melts and blooms outward like ink dropped in water. Pixels from the cover smear radially from center with organic turbulence.
    /// - Parameter bloomRadius: 0.1-0.8: how far the bloom spreads
    /// - Parameter turbulence: 0-1: organic distortion amount
    /// - Parameter flowSpeed: 0.2-2: speed of the liquid flow
    /// - Parameter colorIntensity: 0.5-2: vibrancy of the result
    /// Self-animates via `TimelineView(.animation)`.
    func bcsLiquidBloom(bloomRadius: Float = 0.45, turbulence: Float = 0.5, flowSpeed: Float = 1.1, colorIntensity: Float = 1.25, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_liquidBloom(
                .float2(size),
                .float(t),
                .float(bloomRadius),
                .float(turbulence),
                .float(flowSpeed),
                .float(colorIntensity)
            )
        })
    }

    /// Liquid Chrome — Metallic mercury reflection with animated highlights
    /// - Parameter distortion: 0-30: displacement amount
    /// - Parameter chromeIntensity: 0-1: metallic highlight strength
    /// - Parameter flowSpeed: 0.1-3: animation speed
    /// - Parameter reflectionScale: 1-10: size of chrome reflections
    /// Self-animates via `TimelineView(.animation)`.
    func bcsLiquidChrome(distortion: Float = 15, chromeIntensity: Float = 0.5, flowSpeed: Float = 1.55, reflectionScale: Float = 5.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_liquidChrome(
                .float2(size),
                .float(t),
                .float(distortion),
                .float(chromeIntensity),
                .float(flowSpeed),
                .float(reflectionScale)
            )
        })
    }

    /// Liquid Marble — The cover swirls into marble patterns — two fluid layers mix like oil and water, creating organic veining from the cover's own pixels.
    /// - Parameter veinScale: 1-8: scale of marble veining
    /// - Parameter swirl: 0.1-0.5: swirl intensity
    /// - Parameter mixRatio: 0-1: balance between two fluid layers
    /// - Parameter smoothness: 10-60: blur/blending amount
    /// Self-animates via `TimelineView(.animation)`.
    func bcsLiquidMarble(veinScale: Float = 4.5, swirl: Float = 0.3, mixRatio: Float = 0.5, smoothness: Float = 35, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_liquidMarble(
                .float2(size),
                .float(t),
                .float(veinScale),
                .float(swirl),
                .float(mixRatio),
                .float(smoothness)
            )
        })
    }

    /// Liquid Mirror — Seamless water-like reflection — no visible mirror line
    /// - Parameter mirrorAxis: 0.3-0.7: where the reflection starts
    /// - Parameter ripple: 2-30: ripple displacement
    /// - Parameter speed: 0.5-3: ripple animation speed
    /// - Parameter depth: 0-1: how far the reflection extends / fade
    /// Self-animates via `TimelineView(.animation)`.
    func bcsLiquidMirror(mirrorAxis: Float = 0.5, ripple: Float = 16, speed: Float = 1.75, depth: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_liquidMirror(
                .float2(size),
                .float(t),
                .float(mirrorAxis),
                .float(ripple),
                .float(speed),
                .float(depth)
            )
        })
    }

    /// Liquid Silk — The cover melts into flowing silk ribbons — multiple warped copies of the cover blend together at different flow speeds, creating iridescent layers.
    /// - Parameter ribbonCount: 2-6: number of flowing layers
    /// - Parameter flowSpeed: 0.2-2: speed of silk flow
    /// - Parameter warpAmount: 0.05-0.3: displacement per ribbon
    /// - Parameter blendMode: 0-1: 0 = screen blend, 1 = overlay blend
    /// Self-animates via `TimelineView(.animation)`.
    func bcsLiquidSilk(ribbonCount: Float = 4, flowSpeed: Float = 1.1, warpAmount: Float = 0.17, blendMode: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_liquidSilk(
                .float2(size),
                .float(t),
                .float(ribbonCount),
                .float(flowSpeed),
                .float(warpAmount),
                .float(blendMode)
            )
        })
    }

    /// Live Ripple — Concentric water ripples expanding outward continuously from center
    /// - Parameter amplitude: 0-30: pixel displacement
    /// - Parameter frequency: 5-60: ring tightness
    /// - Parameter speed: 1-10: expansion speed
    /// - Parameter damping: 0.5-5: how fast rings fade with distance
    /// - Parameter ringCount: 1-5: number of simultaneous ripple sources
    /// Self-animates via `TimelineView(.animation)`.
    func bcsLiveRipple(amplitude: Float = 15, frequency: Float = 32, speed: Float = 5.5, damping: Float = 2.75, ringCount: Float = 3, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_liveRipple(
                .float2(size),
                .float(t),
                .float(amplitude),
                .float(frequency),
                .float(speed),
                .float(damping),
                .float(ringCount)
            )
        })
    }

    /// Luminous Pool (v2) — Aggressive liquid displacement at the bottom — the image MELTS into light
    /// - Parameter glowHeight: max glow band thickness
    /// - Parameter glowIntensity:
    /// - Parameter distortion:
    /// - Parameter warpScale:
    /// - Parameter speed:
    /// - Parameter colorShift:
    /// Self-animates via `TimelineView(.animation)`.
    func bcsLuminousPool(glowHeight: Float = 1, glowIntensity: Float = 1, distortion: Float = 1, warpScale: Float = 1, speed: Float = 1, colorShift: Float = 1, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_luminousPool(
                .float2(size),
                .float(t),
                .float(glowHeight),
                .float(glowIntensity),
                .float(distortion),
                .float(warpScale),
                .float(speed),
                .float(colorShift)
            )
        })
    }

    /// Magnetic Field — Ferrofluid-inspired displacement — lines of force warp the image
    /// - Parameter fieldStrength: 5-80: displacement amount
    /// - Parameter lineCount: 3-20: number of field lines
    /// - Parameter fieldTurbulence: 0-1: organic disturbance
    /// - Parameter polarity: 0-1: dipole vs quadrupole
    /// Self-animates via `TimelineView(.animation)`.
    func bcsMagneticField(fieldStrength: Float = 42, lineCount: Float = 12, fieldTurbulence: Float = 0.5, polarity: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_magneticField(
                .float2(size),
                .float(t),
                .float(fieldStrength),
                .float(lineCount),
                .float(fieldTurbulence),
                .float(polarity)
            )
        })
    }

    /// Magnetic Fluid — The cover's pixels flow along magnetic field lines — ferrofluid effect. Pixels stretch into organic tendrils following invisible field lines.
    /// - Parameter fieldStrength: 0.05-0.3: how strongly pixels follow field lines
    /// - Parameter poleCount: 2-6: number of magnetic poles
    /// - Parameter flowSpeed: 0.2-2: animation speed
    /// - Parameter blurring: 5-40: blur amount
    /// Self-animates via `TimelineView(.animation)`.
    func bcsMagneticFluid(fieldStrength: Float = 0.17, poleCount: Float = 4, flowSpeed: Float = 1.1, blurring: Float = 22, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_magneticFluid(
                .float2(size),
                .float(t),
                .float(fieldStrength),
                .float(poleCount),
                .float(flowSpeed),
                .float(blurring)
            )
        })
    }

    /// Melt — The image melts downward like hot wax — gravity pulls pixels down
    /// - Parameter meltAmount: 0-100: how far pixels drip
    /// - Parameter dripScale: 1-15: width of drip columns
    /// - Parameter speed: 0.1-3: melt speed
    /// - Parameter heat: 0-1: color distortion (warm shift
    /// Self-animates via `TimelineView(.animation)`.
    func bcsMelt(meltAmount: Float = 50, dripScale: Float = 8, speed: Float = 1.55, heat: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_melt(
                .float2(size),
                .float(t),
                .float(meltAmount),
                .float(dripScale),
                .float(speed),
                .float(heat)
            )
        })
    }

    /// Mesh Gradient — Samples a 3x3 grid of colors from the cover and creates a flowing animated mesh gradient — like iOS MeshGradient but derived from the actual cover
    /// - Parameter warpAmount: 0-1: how much the mesh points move
    /// - Parameter smoothness: 1-5: interpolation smoothness
    /// - Parameter speed: 0.2-3: animation speed
    /// - Parameter satBoost: 0-1: saturation enhancement
    /// Self-animates via `TimelineView(.animation)`.
    func bcsMeshGradient(warpAmount: Float = 0.5, smoothness: Float = 3, speed: Float = 1.6, satBoost: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_meshGradient(
                .float2(size),
                .float(t),
                .float(warpAmount),
                .float(smoothness),
                .float(speed),
                .float(satBoost)
            )
        })
    }

    /// Molten Glass — The cover melts as if behind warped glass — multiple refraction layers create depth and liquid movement. Thick, syrupy distortion.
    /// - Parameter viscosity: 0.5-3: how thick/syrupy the glass feels
    /// - Parameter refraction: 10-80: displacement amount
    /// - Parameter heatDistort: 0-1: additional heat-shimmer on top
    /// - Parameter clarity: 0-1: mix back in sharp original
    /// Self-animates via `TimelineView(.animation)`.
    func bcsMoltenGlass(viscosity: Float = 1.75, refraction: Float = 45, heatDistort: Float = 0.5, clarity: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_moltenGlass(
                .float2(size),
                .float(t),
                .float(viscosity),
                .float(refraction),
                .float(heatDistort),
                .float(clarity)
            )
        })
    }

    /// Morph Breathe — The image breathes and morphs like a living organism
    /// - Parameter breatheDepth: 5-50: displacement depth
    /// - Parameter breatheRate: 0.3-3: breathing speed
    /// - Parameter warpComplexity: 1-8: noise octave complexity
    /// - Parameter organic: 0-1: how organic/irregular the breathing is
    /// Self-animates via `TimelineView(.animation)`.
    func bcsMorphBreathe(breatheDepth: Float = 28, breatheRate: Float = 1.65, warpComplexity: Float = 4.5, organic: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_morphBreathe(
                .float2(size),
                .float(t),
                .float(breatheDepth),
                .float(breatheRate),
                .float(warpComplexity),
                .float(organic)
            )
        })
    }

    /// Neon Edge — Glowing neon contour lines extracted from the image
    /// - Parameter edgeStrength: 1-10: edge detection sensitivity
    /// - Parameter glowAmount: 0-2: how much the edges glow
    /// - Parameter colorCycle: 0-3: speed of color cycling
    /// - Parameter mixOriginal: 0-1: blend with original image
    /// Self-animates via `TimelineView(.animation)`.
    func bcsNeonEdge(edgeStrength: Float = 5.5, glowAmount: Float = 1, colorCycle: Float = 1.5, mixOriginal: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_neonEdge(
                .float2(size),
                .float(t),
                .float(edgeStrength),
                .float(glowAmount),
                .float(colorCycle),
                .float(mixOriginal)
            )
        })
    }

    /// Noir Sketch — Pencil/charcoal cross-hatching — moody graphic novel illustration
    /// - Parameter lineWeight: 0.5-3: thickness of sketch lines
    /// - Parameter crossHatch: 0-1: amount of cross-hatching
    /// - Parameter paperTone: 0-1: paper color (0=white, 1=cream
    /// - Parameter inkAmount: 0.3-1: darkness intensity
    /// Self-animates via `TimelineView(.animation)`.
    func bcsNoirSketch(lineWeight: Float = 1.75, crossHatch: Float = 0.5, paperTone: Float = 0.5, inkAmount: Float = 0.65, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_noirSketch(
                .float2(size),
                .float(t),
                .float(lineWeight),
                .float(crossHatch),
                .float(paperTone),
                .float(inkAmount)
            )
        })
    }

    /// Pixelate Mosaic — 3D beveled tiles with animated assembly — not flat pixelation
    /// - Parameter pixelSize: 4-60: size of each tile
    /// - Parameter bevel: 0-1: 3D bevel depth on tiles
    /// - Parameter animateAssemble: 0-1: tiles slide in from scattered positions
    /// - Parameter gap: 0-0.3: gap between tiles (grout
    /// Self-animates via `TimelineView(.animation)`.
    func bcsPixelateMosaic(pixelSize: Float = 32, bevel: Float = 0.5, animateAssemble: Float = 0.5, gap: Float = 0.15, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_pixelateMosaic(
                .float2(size),
                .float(t),
                .float(pixelSize),
                .float(bevel),
                .float(animateAssemble),
                .float(gap)
            )
        })
    }

    /// Pixelate Storm — Dynamic mosaic that pulses, shifts, and swirls
    /// - Parameter pixelSize: 2-40: base pixel block size
    /// - Parameter stormAmount: 0-1: how chaotic the pixelation is
    /// - Parameter swirl: 0-3: rotational swirl of pixel grid
    /// - Parameter pulse: 0-3: pulsing speed
    /// Self-animates via `TimelineView(.animation)`.
    func bcsPixelateStorm(pixelSize: Float = 21, stormAmount: Float = 0.5, swirl: Float = 1.5, pulse: Float = 1.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_pixelateStorm(
                .float2(size),
                .float(t),
                .float(pixelSize),
                .float(stormAmount),
                .float(swirl),
                .float(pulse)
            )
        })
    }

    /// Plasma — Electric plasma tendrils crawling across the surface
    /// - Parameter intensity: 0-1: visibility of plasma
    /// - Parameter scale: 1-10: size of plasma cells
    /// - Parameter speed: 0.5-5: animation speed
    /// - Parameter colorMode: 0-1: 0=electric blue, 0.5=green, 1=purple
    /// Self-animates via `TimelineView(.animation)`.
    func bcsPlasma(intensity: Float = 0.5, scale: Float = 5.5, speed: Float = 2.75, colorMode: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_plasma(
                .float2(size),
                .float(t),
                .float(intensity),
                .float(scale),
                .float(speed),
                .float(colorMode)
            )
        })
    }

    /// Plasma Flow — The cover dissolves into flowing plasma — the image's own pixels stretch and curl along organic flow lines, like the cover is being stirred.
    /// - Parameter curlStrength: 0.05-0.4: strength of the curl/flow
    /// - Parameter flowScale: 1-5: scale of flow patterns
    /// - Parameter speed: 0.2-2: animation speed
    /// - Parameter mixSharpness: 0-1: 0 = fully flowed, 1 = mix in some original
    /// Self-animates via `TimelineView(.animation)`.
    func bcsPlasmaFlow(curlStrength: Float = 0.23, flowScale: Float = 3, speed: Float = 1.1, mixSharpness: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_plasmaFlow(
                .float2(size),
                .float(t),
                .float(curlStrength),
                .float(flowScale),
                .float(speed),
                .float(mixSharpness)
            )
        })
    }

    /// Pulse / Heartbeat — Rhythmic radial expansion and contraction like a breathing cover
    /// - Parameter amplitude: 0-30: max pixel displacement
    /// - Parameter bpm: 30-180: beats per minute
    /// - Parameter sharpness: 1-10: how sharp the pulse is (higher = punchier
    /// - Parameter glowIntensity: 0-1: brightness pulse at edges
    /// Self-animates via `TimelineView(.animation)`.
    func bcsPulse(amplitude: Float = 15, bpm: Float = 105, sharpness: Float = 5.5, glowIntensity: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_pulse(
                .float2(size),
                .float(t),
                .float(amplitude),
                .float(bpm),
                .float(sharpness),
                .float(glowIntensity)
            )
        })
    }

    /// Radial Smear — The cover radiates outward from center in streaks, like a long-exposure zoom blur. The cover's composition bleeds in all directions.
    /// - Parameter smearLength: 0.05-0.4: length of radial streaks
    /// - Parameter rotation: 0-1: rotational component to the smear
    /// - Parameter pulseSpeed: 0.2-2: pulsing animation speed
    /// - Parameter clarity: 0-1: 0 = fully smeared, 1 = mix with original
    /// Self-animates via `TimelineView(.animation)`.
    func bcsRadialSmear(smearLength: Float = 0.23, rotation: Float = 0.5, pulseSpeed: Float = 1.1, clarity: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_radialSmear(
                .float2(size),
                .float(t),
                .float(smearLength),
                .float(rotation),
                .float(pulseSpeed),
                .float(clarity)
            )
        })
    }

    /// Refract Lens (Interactive) — Thick glass sphere — drag to move the lens around the cover
    /// - Parameter touchPos: touch position in pixels
    /// - Parameter lensRadius: 0.1-0.5: size of the lens
    /// - Parameter refraction: 1.0-3.0: index of refraction
    /// - Parameter aberration: 0-15: chromatic split
    /// - Parameter wobble: 0-1: organic lens wobble
    func bcsRefractLens(touchPos: UnitPoint = .center, lensRadius: Float = 0.3, refraction: Float = 2, aberration: Float = 7.5, wobble: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_StaticShaderEffect(maxSampleOffset: maxSampleOffset) { size in
            ShaderLibrary.bundle(.module).bcs_refractLens(
                .float2(size),
                .float2(CGSize(width: size.width * touchPos.x, height: size.height * touchPos.y)),
                .float(lensRadius),
                .float(refraction),
                .float(aberration),
                .float(wobble)
            )
        })
    }

    /// Shatter — Refined glass shard explosion with depth, reflections, and shadow
    /// - Parameter shardCount: 3-30: number of shatter cells
    /// - Parameter explode: 0-1: how far apart the shards are
    /// - Parameter rotationAmt: 0-3: how much each shard rotates
    /// - Parameter edgeGlow: 0-2: brightness of shard edges
    /// Self-animates via `TimelineView(.animation)`.
    func bcsShatter(shardCount: Float = 16, explode: Float = 0.5, rotationAmt: Float = 1.5, edgeGlow: Float = 1, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_shatter(
                .float2(size),
                .float(t),
                .float(shardCount),
                .float(explode),
                .float(rotationAmt),
                .float(edgeGlow)
            )
        })
    }

    /// Shatter Glass — Cracked glass with refraction and prismatic splitting at cracks
    /// - Parameter crackDensity: 3-15: number of shatter cells
    /// - Parameter glassRefraction: 0-20: displacement at crack edges
    /// - Parameter prismStrength: 0-1: rainbow splitting at cracks
    /// - Parameter shatterSpread: 0-1: how much shards separate
    /// Self-animates via `TimelineView(.animation)`.
    func bcsShatterGlass(crackDensity: Float = 9, glassRefraction: Float = 10, prismStrength: Float = 0.5, shatterSpread: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_shatterGlass(
                .float2(size),
                .float(t),
                .float(crackDensity),
                .float(glassRefraction),
                .float(prismStrength),
                .float(shatterSpread)
            )
        })
    }

    /// Shockwave — Expanding rings of distortion from the center
    /// - Parameter waveSpeed: 50-500: ring expansion speed
    /// - Parameter ringWidth: 5-60: width of the distortion ring
    /// - Parameter strength: 5-80: displacement power
    /// - Parameter repeatRate: 0.5-5: seconds between waves
    /// Self-animates via `TimelineView(.animation)`.
    func bcsShockwave(waveSpeed: Float = 275, ringWidth: Float = 32, strength: Float = 42, repeatRate: Float = 2.75, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_shockwave(
                .float2(size),
                .float(t),
                .float(waveSpeed),
                .float(ringWidth),
                .float(strength),
                .float(repeatRate)
            )
        })
    }

    /// Smoke Dissolve — The cover dissolves into wisps of smoke rising upward.
    /// - Parameter dissolveAmount: 0-1: how dissolved the image is
    /// - Parameter curlScale: 2-8: scale of smoke curls
    /// - Parameter riseSpeed: 0.5-3: how fast smoke rises
    /// - Parameter smokeDensity: 0.3-1: smoke opacity/density
    /// Self-animates via `TimelineView(.animation)`.
    func bcsSmokeDissolve(dissolveAmount: Float = 0.5, curlScale: Float = 5, riseSpeed: Float = 1.75, smokeDensity: Float = 0.65, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_smokeDissolve(
                .float2(size),
                .float(t),
                .float(dissolveAmount),
                .float(curlScale),
                .float(riseSpeed),
                .float(smokeDensity)
            )
        })
    }

    /// Smoke Reveal — Swirling smoke that clears to reveal the image underneath
    /// - Parameter smokeAmount: 0-1: smoke coverage
    /// - Parameter smokeScale: 2-10: size of smoke wisps
    /// - Parameter windSpeed: 0.5-3: how fast smoke moves
    /// - Parameter smokeTurb: 0.5-3: how chaotic the smoke is
    /// Self-animates via `TimelineView(.animation)`.
    func bcsSmokeReveal(smokeAmount: Float = 0.5, smokeScale: Float = 6, windSpeed: Float = 1.75, smokeTurb: Float = 1.75, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_smokeReveal(
                .float2(size),
                .float(t),
                .float(smokeAmount),
                .float(smokeScale),
                .float(windSpeed),
                .float(smokeTurb)
            )
        })
    }

    /// Solarize — Film solarization — psychedelic inversion at selective luminance thresholds
    /// - Parameter threshold: 0.2-0.8: luminance threshold for inversion
    /// - Parameter curveIntensity: 0-3: how sharp the solarization curve is
    /// - Parameter colorSeparation: 0-1: separate channels for psychedelic color
    /// - Parameter animate: 0-1: how much the threshold oscillates
    /// Self-animates via `TimelineView(.animation)`.
    func bcsSolarize(threshold: Float = 0.5, curveIntensity: Float = 1.5, colorSeparation: Float = 0.5, animate: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_solarize(
                .float2(size),
                .float(t),
                .float(threshold),
                .float(curveIntensity),
                .float(colorSeparation),
                .float(animate)
            )
        })
    }

    /// Thermal — Thermal / infrared vision with heat shimmer
    /// - Parameter intensity: 0-1: strength of thermal colorization
    /// - Parameter shimmer: 0-15: heat distortion amount
    /// - Parameter noiseSpeed: 0.5-3: shimmer animation speed
    /// - Parameter paletteShift: 0-1: shifts the color palette
    /// Self-animates via `TimelineView(.animation)`.
    func bcsThermal(intensity: Float = 0.5, shimmer: Float = 7.5, noiseSpeed: Float = 1.75, paletteShift: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_thermal(
                .float2(size),
                .float(t),
                .float(intensity),
                .float(shimmer),
                .float(noiseSpeed),
                .float(paletteShift)
            )
        })
    }

    /// Tidal Pull — Horizontal waves stretch and compress the cover cyclically, like breathing.
    /// - Parameter amplitude: 10-60: wave displacement
    /// - Parameter frequency: 1-6: wave density
    /// - Parameter speed: 0.3-2: wave speed
    /// - Parameter verticalMix: 0-1: add vertical waves too
    /// Self-animates via `TimelineView(.animation)`.
    func bcsTidalPull(amplitude: Float = 35, frequency: Float = 3.5, speed: Float = 1.15, verticalMix: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_tidalPull(
                .float2(size),
                .float(t),
                .float(amplitude),
                .float(frequency),
                .float(speed),
                .float(verticalMix)
            )
        })
    }

    /// Tilt Shift — Miniature/diorama effect — the cover stays sharp in a band but blurs heavily above and below, with boosted saturation for toy-like quality.
    /// - Parameter focusCenter: 0.2-0.8: where the sharp band is (y position
    /// - Parameter focusWidth: 0.05-0.3: width of the sharp band
    /// - Parameter maxBlur: 20-80: maximum blur at edges
    /// - Parameter saturation: 1-2: color boost for miniature effect
    /// Self-animates via `TimelineView(.animation)`.
    func bcsTiltShift(focusCenter: Float = 0.5, focusWidth: Float = 0.17, maxBlur: Float = 50, saturation: Float = 1.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_tiltShift(
                .float2(size),
                .float(t),
                .float(focusCenter),
                .float(focusWidth),
                .float(maxBlur),
                .float(saturation)
            )
        })
    }

    /// Topographic — Contour map visualization — converts image into elevation lines
    /// - Parameter lineCount: 5-40: number of contour lines
    /// - Parameter lineWidth: 0.01-0.15: thickness
    /// - Parameter colorize: 0-1: blend between original and topo colors
    /// - Parameter animate: 0-1: animation speed of elevation shift
    /// Self-animates via `TimelineView(.animation)`.
    func bcsTopographic(lineCount: Float = 22, lineWidth: Float = 0.08, colorize: Float = 0.5, animate: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_topographic(
                .float2(size),
                .float(t),
                .float(lineCount),
                .float(lineWidth),
                .float(colorize),
                .float(animate)
            )
        })
    }

    /// Touch Ripple — Ripples expand from a touch point, decay over time
    /// - Parameter touchPos: touch location in pixels
    /// - Parameter touchAge: seconds since touch
    /// - Parameter amplitude: 0-30: displacement strength
    /// - Parameter frequency: 5-40: ring density
    /// - Parameter speed: 50-500: expansion speed (pixels/sec
    /// - Parameter decay: 0.5-4: time decay rate
    func bcsTouchRipple(touchPos: UnitPoint = .center, touchAge: Float = 1, amplitude: Float = 15, frequency: Float = 22, speed: Float = 275, decay: Float = 2.25, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_StaticShaderEffect(maxSampleOffset: maxSampleOffset) { size in
            ShaderLibrary.bundle(.module).bcs_touchRipple(
                .float2(size),
                .float2(CGSize(width: size.width * touchPos.x, height: size.height * touchPos.y)),
                .float(touchAge),
                .float(amplitude),
                .float(frequency),
                .float(speed),
                .float(decay)
            )
        })
    }

    /// Underwater Caustics — Dancing light refractions like sunlight through water
    /// - Parameter causticScale: 2-15: scale of caustic pattern
    /// - Parameter causticIntensity: 0-2: brightness of caustic highlights
    /// - Parameter waterDistortion: 0-30: water surface displacement
    /// - Parameter waterDepth: 0-1: how deep underwater
    /// Self-animates via `TimelineView(.animation)`.
    func bcsUnderwaterCaustics(causticScale: Float = 8.5, causticIntensity: Float = 1, waterDistortion: Float = 15, waterDepth: Float = 0.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_underwaterCaustics(
                .float2(size),
                .float(t),
                .float(causticScale),
                .float(causticIntensity),
                .float(waterDistortion),
                .float(waterDepth)
            )
        })
    }

    /// Vortex Spiral — Swirling distortion that twists the cover art
    /// - Parameter twistAmount: 0-10: how many radians of twist
    /// - Parameter radius: 0.1-1: normalized radius of the vortex
    /// - Parameter speed: 0.1-3: rotation speed
    /// - Parameter falloff: 0.5-5: how sharply the twist falls off
    /// Self-animates via `TimelineView(.animation)`.
    func bcsVortex(twistAmount: Float = 5, radius: Float = 0.55, speed: Float = 1.55, falloff: Float = 2.75, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_vortex(
                .float2(size),
                .float(t),
                .float(twistAmount),
                .float(radius),
                .float(speed),
                .float(falloff)
            )
        })
    }

    /// Watercolor Bleed — The cover image bleeds as if painted in watercolor — edges dissolve, colors run into each other, with wet paper texture.
    /// - Parameter bleedAmount: 10-80: how much colors bleed
    /// - Parameter wetness: 0-1: how wet/active the bleeding is
    /// - Parameter paperGrain: 0-1: paper texture visibility
    /// - Parameter flowAngle: 0-6.28: direction gravity pulls the paint
    /// Self-animates via `TimelineView(.animation)`.
    func bcsWatercolorBleed(bleedAmount: Float = 45, wetness: Float = 0.5, paperGrain: Float = 0.5, flowAngle: Float = 3.14, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_watercolorBleed(
                .float2(size),
                .float(t),
                .float(bleedAmount),
                .float(wetness),
                .float(paperGrain),
                .float(flowAngle)
            )
        })
    }

    /// Wave Pool — Multiple overlapping sine wave displacements creating interference patterns
    /// - Parameter amplitude: 0-25: displacement strength
    /// - Parameter wavelength: 5-40: distance between wave crests
    /// - Parameter speed: 0.5-5: wave animation speed
    /// - Parameter complexity: 1-6: number of wave directions
    /// Self-animates via `TimelineView(.animation)`.
    func bcsWavePool(amplitude: Float = 12, wavelength: Float = 22, speed: Float = 2.75, complexity: Float = 3.5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_wavePool(
                .float2(size),
                .float(t),
                .float(amplitude),
                .float(wavelength),
                .float(speed),
                .float(complexity)
            )
        })
    }

    /// Wormhole — Tunnel zoom into the image center with spiral distortion
    /// - Parameter depth: 1-8: tunnel depth / zoom factor
    /// - Parameter speed: 0.3-3: travel speed
    /// - Parameter twist: 0-5: spiral twist amount
    /// - Parameter radius: 0.1-0.5: tunnel opening radius
    /// Self-animates via `TimelineView(.animation)`.
    func bcsWormhole(depth: Float = 4.5, speed: Float = 1.65, twist: Float = 2.5, radius: Float = 0.3, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_wormhole(
                .float2(size),
                .float(t),
                .float(depth),
                .float(speed),
                .float(twist),
                .float(radius)
            )
        })
    }

    /// X-Ray — Inverted luminance with edge enhancement — like a digital radiograph
    /// - Parameter xrayIntensity: 0-1: how much x-ray vs original
    /// - Parameter edgeEnhance: 0-5: edge detection strength
    /// - Parameter scanLine: 0-1: animated scan line
    /// - Parameter densityContrast: 0.5-3: contrast of density visualization
    /// Self-animates via `TimelineView(.animation)`.
    func bcsXray(xrayIntensity: Float = 0.5, edgeEnhance: Float = 2.5, scanLine: Float = 0.5, densityContrast: Float = 1.75, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
        modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
            ShaderLibrary.bundle(.module).bcs_xray(
                .float2(size),
                .float(t),
                .float(xrayIntensity),
                .float(edgeEnhance),
                .float(scanLine),
                .float(densityContrast)
            )
        })
    }
}
