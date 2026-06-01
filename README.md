# EpilogueShaders

A collection of **69 SwiftUI Metal shader effects** — luminous pools, liquid marble, holographic foil, gravity wells, chromatic glitch, watercolor bleed, and more. Each is a `[[ stitchable ]]` Metal function wrapped in a typed, drop-in SwiftUI `View` modifier.

These were built as the shader lab inside [Epilogue](https://apps.apple.com), a reading app. They're shared here so you can drop them into your own SwiftUI project, play with them, and remix them. They're also meant to be **handed to a coding agent** (Claude Code, Codex) as a working reference — see [AGENTS.md](AGENTS.md) for the architecture an agent needs to extend or rebuild them.

> The `bcs_` prefix on the Metal functions is just the shader namespace. Nothing here is tied to Epilogue's app code.

## Requirements

- iOS 17+ / macOS 14+ / tvOS 17+ / visionOS 1+
- Xcode 15+ (the Metal toolchain compiles the shaders into the package's `default.metallib`)

> Note: build with **Xcode / `xcodebuild`**, not bare `swift build`. SwiftPM's command-line driver on macOS doesn't run the Metal toolchain, so `Bundle.module` / `default.metallib` won't be produced. In Xcode it just works.

## Install

Swift Package Manager — in Xcode: **File ▸ Add Package Dependencies…** and point at this repo's URL. Or in `Package.swift`:

```swift
.package(url: "https://github.com/USERNAME/EpilogueShaders.git", from: "1.0.0")
```

Then add `EpilogueShaders` to your target's dependencies.

## Quick start

```swift
import SwiftUI
import EpilogueShaders

struct ContentView: View {
    var body: some View {
        Image("book-cover")
            .resizable()
            .scaledToFit()
            .bcsHolographic(intensity: 0.6, scale: 12, speed: 1.2)  // animated, self-driving
    }
}
```

Every shader is a `View` modifier. Animated shaders drive themselves via `TimelineView(.animation)` — no timer to manage. All parameters have sensible defaults, so `.bcsLiquidMarble()` works on its own.

```swift
Text("Chapter One")
    .font(.largeTitle)
    .bcsChromaticSplit(spread: 8, angle: .pi / 4)

Color.indigo
    .bcsLuminousPool()       // ambient animated glow

myView
    .bcsEmboss(strength: 3)  // static relief
```

## How it works (conventions)

Each wrapper applies one Metal `layerEffect`. The mapping is uniform:

| Shader argument | Supplied by the wrapper |
|---|---|
| `position`, `layer` | SwiftUI (automatic) |
| `size` | The view's pixel size, from `GeometryProxy` |
| `time` | Elapsed seconds, from `TimelineView(.animation)` (animated shaders only) |
| interaction point (e.g. `touchPos`) | A `UnitPoint` (0...1) you pass, converted to pixels |
| everything else | Typed `Float` parameters with defaults |

Every method also takes `maxSampleOffset:` (default `64×64`) — raise it if a heavy displacement effect looks clipped at the edges, lower it for a small perf win on cheap effects.

## The shaders

65 animate; 4 are static (`bcsEmboss`, `bcsFrosted`, and the two interaction-driven ripples). Parameter ranges in parentheses are the documented sweet spots; defaults sit mid-range.

| Shader | Animated | Parameters |
|---|---|---|
| **`.bcsAurora`** — Aurora | ✅ | `intensity` (0–1), `bands` (1–8), `speed` (0.3–3), `colorShift` (0–1) |
| **`.bcsBlackHole`** — Black Hole | ✅ | `mass` (0.05–0.5), `spin` (0–5), `distortion` (10–200), `ringBrightness` (0–2) |
| **`.bcsCaustics`** — Caustics | ✅ | `intensity` (0–1), `scale` (1–15), `speed` (0.5–5), `distortion` (0–15) |
| **`.bcsChromaticFog`** — Chromatic Fog | ✅ | `fogDensity` (20–100), `separation` (0–30), `driftSpeed` (0.2–2), `depth` (0.3–1) |
| **`.bcsChromaticSplit`** — Chromatic Split | ✅ | `spread` (0–30), `angle` (0–6.28), `edgeOnly` (0–1), `animate` (0–1) |
| **`.bcsCrystalPrism`** — Crystal Prism | ✅ | `facetSize` (2–20), `dispersion` (2–30), `rotation` (0–3), `sparkle` (0–2) |
| **`.bcsDatamosh`** — Datamosh | ✅ | `blockCorruption` (0–1), `smearAmount` (0–60), `colorBleed` (0–1), `glitchRate` (0.5–5) |
| **`.bcsDisintegrate`** — Disintegrate | ✅ | `threshold` (0–1), `edgeWidth` (0.05–0.3), `driftAmount` (0–50), `direction` (0–6.28) |
| **`.bcsDissolve`** — Dissolve | ✅ | `threshold` (0–1), `edgeWidth` (0.01–0.2), `noiseScale` (1–15), `edgeGlow` (0–3) |
| **`.bcsDreamBlur`** — Dream Blur | ✅ | `blurRadius` (20–120), `warpStrength` (0–1), `breatheSpeed` (0.2–2), `satBoost` (0–1) |
| **`.bcsDuochrome`** — Duochrome | ✅ | `intensity` (0–1), `hue1` (0–1), `hue2` (0–1), `contrast` (0.5–2) |
| **`.bcsEcho`** — Echo / Ghost | ✅ | `echoCount` (2–8), `spread` (5–50), `direction` (0–6.28), `fade` (0.3–0.9) |
| **`.bcsEchoTrails`** — Echo Trails | ✅ | `trailCount` (2–8), `trailSpread` (0.02–0.15), `fadeRate` (0.3–0.8), `driftAngle` (0–6.28) |
| **`.bcsEmboss`** — Emboss / Relief | — | `strength` (0–5), `angle` (0–6.28), `mixAmount` (0–1) |
| **`.bcsEtherealAura`** — Ethereal Aura (v2) | ✅ | `auraWidth`, `auraIntensity`, `pulseSpeed`, `distortion`, `hueShift` |
| **`.bcsFluidMesh`** — Fluid Mesh | ✅ | `gridSize` (3–8), `fluidity` (0.1–0.5), `blendRadius` (1–5), `satBoost` (0–1) |
| **`.bcsFractalMirror`** — Fractal Mirror | ✅ | `segments` (2–12), `zoom` (0.5–3), `rotationSpeed` (0–1), `blendSoft` (0–1) |
| **`.bcsFrosted`** — Frosted Glass | — | `frostAmount` (0–1), `grainSize` (1–20), `clearRadius` (0–1), `clearSoftness` (0–1) |
| **`.bcsGaussianSplats`** — Gaussian Splats | ✅ | `splatDensity` (4–12), `splatRadius` (0.03–0.15), `jitter` (0–1), `satBoost` (0–1) |
| **`.bcsGeometricWarp`** — Geometric Warp | ✅ | `spiralTight` (1–8), `zoomRepeat` (0.3–2), `rotation` (0–6.28), `blend` (0–1) |
| **`.bcsGlitch`** — Glitch | ✅ | `intensity` (0–1), `blockSize` (2–50), `scanLines` (0–1), `colorShift` (0–20) |
| **`.bcsGravityPool`** — Gravity Pool | ✅ | `pullStrength` (0.05–0.3), `wellCount` (1–4), `orbitSpeed` (0.1–1), `softness` (10–50) |
| **`.bcsGravityWells`** — Gravity Wells | ✅ | `wellStrength` (10–200), `wellCount` (1–5), `orbitSpeed` (0.1–3), `warpFalloff` (0.5–5) |
| **`.bcsHeatMirage`** — Heat Mirage | ✅ | `distortion` (5–60), `waveScale` (2–15), `riseSpeed` (0.5–3), `blurAmount` (0–1) |
| **`.bcsHeatShimmer`** — Heat Shimmer | ✅ | `amplitude` (0–20), `frequency` (1–30), `speed` (0.5–5), `verticalBias` (0–1) |
| **`.bcsHolographic`** — Holographic / Prismatic | ✅ | `intensity` (0–1), `scale` (1–20), `speed` (0.1–3), `angleOffset` (0–6.28) |
| **`.bcsHorizonMelt`** — Horizon Melt | ✅ | `horizonY` (0.3–0.7), `meltAmount` (10–80), `waveSpeed` (0.2–2), `reflection` (0–1) |
| **`.bcsInkBleed`** — Ink Bleed / Domain Warp | ✅ | `warpStrength` (0–50), `scale` (1–10), `speed` (0.1–2), `detail` (2–8) |
| **`.bcsInkDiffusion`** — Ink Diffusion | ✅ | `spreadRate` (0.1–0.5), `ringCount` (1–5), `turbulence` (0–1), `saturation` (0.5–2) |
| **`.bcsKaleidoscope`** — Kaleidoscope | ✅ | `segments` (2–16), `rotation` (0–6.28), `zoom` (0.5–3), `animateSpeed` (0–2) |
| **`.bcsLiquidBloom`** — Liquid Bloom | ✅ | `bloomRadius` (0.1–0.8), `turbulence` (0–1), `flowSpeed` (0.2–2), `colorIntensity` (0.5–2) |
| **`.bcsLiquidChrome`** — Liquid Chrome | ✅ | `distortion` (0–30), `chromeIntensity` (0–1), `flowSpeed` (0.1–3), `reflectionScale` (1–10) |
| **`.bcsLiquidMarble`** — Liquid Marble | ✅ | `veinScale` (1–8), `swirl` (0.1–0.5), `mixRatio` (0–1), `smoothness` (10–60) |
| **`.bcsLiquidMirror`** — Liquid Mirror | ✅ | `mirrorAxis` (0.3–0.7), `ripple` (2–30), `speed` (0.5–3), `depth` (0–1) |
| **`.bcsLiquidSilk`** — Liquid Silk | ✅ | `ribbonCount` (2–6), `flowSpeed` (0.2–2), `warpAmount` (0.05–0.3), `blendMode` (0–1) |
| **`.bcsLiveRipple`** — Live Ripple | ✅ | `amplitude` (0–30), `frequency` (5–60), `speed` (1–10), `damping` (0.5–5), `ringCount` (1–5) |
| **`.bcsLuminousPool`** — Luminous Pool (v2) | ✅ | `glowHeight`, `glowIntensity`, `distortion`, `warpScale`, `speed`, `colorShift` |
| **`.bcsMagneticField`** — Magnetic Field | ✅ | `fieldStrength` (5–80), `lineCount` (3–20), `fieldTurbulence` (0–1), `polarity` (0–1) |
| **`.bcsMagneticFluid`** — Magnetic Fluid | ✅ | `fieldStrength` (0.05–0.3), `poleCount` (2–6), `flowSpeed` (0.2–2), `blurring` (5–40) |
| **`.bcsMelt`** — Melt | ✅ | `meltAmount` (0–100), `dripScale` (1–15), `speed` (0.1–3), `heat` (0–1) |
| **`.bcsMeshGradient`** — Mesh Gradient | ✅ | `warpAmount` (0–1), `smoothness` (1–5), `speed` (0.2–3), `satBoost` (0–1) |
| **`.bcsMoltenGlass`** — Molten Glass | ✅ | `viscosity` (0.5–3), `refraction` (10–80), `heatDistort` (0–1), `clarity` (0–1) |
| **`.bcsMorphBreathe`** — Morph Breathe | ✅ | `breatheDepth` (5–50), `breatheRate` (0.3–3), `warpComplexity` (1–8), `organic` (0–1) |
| **`.bcsNeonEdge`** — Neon Edge | ✅ | `edgeStrength` (1–10), `glowAmount` (0–2), `colorCycle` (0–3), `mixOriginal` (0–1) |
| **`.bcsNoirSketch`** — Noir Sketch | ✅ | `lineWeight` (0.5–3), `crossHatch` (0–1), `paperTone` (0–1), `inkAmount` (0.3–1) |
| **`.bcsPixelateMosaic`** — Pixelate Mosaic | ✅ | `pixelSize` (4–60), `bevel` (0–1), `animateAssemble` (0–1), `gap` (0–0.3) |
| **`.bcsPixelateStorm`** — Pixelate Storm | ✅ | `pixelSize` (2–40), `stormAmount` (0–1), `swirl` (0–3), `pulse` (0–3) |
| **`.bcsPlasma`** — Plasma | ✅ | `intensity` (0–1), `scale` (1–10), `speed` (0.5–5), `colorMode` (0–1) |
| **`.bcsPlasmaFlow`** — Plasma Flow | ✅ | `curlStrength` (0.05–0.4), `flowScale` (1–5), `speed` (0.2–2), `mixSharpness` (0–1) |
| **`.bcsPulse`** — Pulse / Heartbeat | ✅ | `amplitude` (0–30), `bpm` (30–180), `sharpness` (1–10), `glowIntensity` (0–1) |
| **`.bcsRadialSmear`** — Radial Smear | ✅ | `smearLength` (0.05–0.4), `rotation` (0–1), `pulseSpeed` (0.2–2), `clarity` (0–1) |
| **`.bcsRefractLens`** — Refract Lens (Interactive) | — | `touchPos` (UnitPoint), `lensRadius` (0.1–0.5), `refraction` (1–3), `aberration` (0–15), `wobble` (0–1) |
| **`.bcsShatter`** — Shatter | ✅ | `shardCount` (3–30), `explode` (0–1), `rotationAmt` (0–3), `edgeGlow` (0–2) |
| **`.bcsShatterGlass`** — Shatter Glass | ✅ | `crackDensity` (3–15), `glassRefraction` (0–20), `prismStrength` (0–1), `shatterSpread` (0–1) |
| **`.bcsShockwave`** — Shockwave | ✅ | `waveSpeed` (50–500), `ringWidth` (5–60), `strength` (5–80), `repeatRate` (0.5–5) |
| **`.bcsSmokeDissolve`** — Smoke Dissolve | ✅ | `dissolveAmount` (0–1), `curlScale` (2–8), `riseSpeed` (0.5–3), `smokeDensity` (0.3–1) |
| **`.bcsSmokeReveal`** — Smoke Reveal | ✅ | `smokeAmount` (0–1), `smokeScale` (2–10), `windSpeed` (0.5–3), `smokeTurb` (0.5–3) |
| **`.bcsSolarize`** — Solarize | ✅ | `threshold` (0.2–0.8), `curveIntensity` (0–3), `colorSeparation` (0–1), `animate` (0–1) |
| **`.bcsThermal`** — Thermal | ✅ | `intensity` (0–1), `shimmer` (0–15), `noiseSpeed` (0.5–3), `paletteShift` (0–1) |
| **`.bcsTidalPull`** — Tidal Pull | ✅ | `amplitude` (10–60), `frequency` (1–6), `speed` (0.3–2), `verticalMix` (0–1) |
| **`.bcsTiltShift`** — Tilt Shift | ✅ | `focusCenter` (0.2–0.8), `focusWidth` (0.05–0.3), `maxBlur` (20–80), `saturation` (1–2) |
| **`.bcsTopographic`** — Topographic | ✅ | `lineCount` (5–40), `lineWidth` (0.01–0.15), `colorize` (0–1), `animate` (0–1) |
| **`.bcsTouchRipple`** — Touch Ripple | — | `touchPos` (UnitPoint), `touchAge`, `amplitude` (0–30), `frequency` (5–40), `speed` (50–500), `decay` (0.5–4) |
| **`.bcsUnderwaterCaustics`** — Underwater Caustics | ✅ | `causticScale` (2–15), `causticIntensity` (0–2), `waterDistortion` (0–30), `waterDepth` (0–1) |
| **`.bcsVortex`** — Vortex Spiral | ✅ | `twistAmount` (0–10), `radius` (0.1–1), `speed` (0.1–3), `falloff` (0.5–5) |
| **`.bcsWatercolorBleed`** — Watercolor Bleed | ✅ | `bleedAmount` (10–80), `wetness` (0–1), `paperGrain` (0–1), `flowAngle` (0–6.28) |
| **`.bcsWavePool`** — Wave Pool | ✅ | `amplitude` (0–25), `wavelength` (5–40), `speed` (0.5–5), `complexity` (1–6) |
| **`.bcsWormhole`** — Wormhole | ✅ | `depth` (1–8), `speed` (0.3–3), `twist` (0–5), `radius` (0.1–0.5) |
| **`.bcsXray`** — X-Ray | ✅ | `xrayIntensity` (0–1), `edgeEnhance` (0–5), `scanLine` (0–1), `densityContrast` (0.5–3) |

### Interaction-driven shaders

`bcsTouchRipple` and `bcsRefractLens` take a `touchPos: UnitPoint`. Feed them a drag location for a touch-reactive effect:

```swift
@State private var touch: UnitPoint = .center

myView
    .bcsRefractLens(touchPos: touch, lensRadius: 0.3)
    .gesture(DragGesture(minimumDistance: 0).onChanged { v in
        touch = UnitPoint(x: v.location.x / size.width, y: v.location.y / size.height)
    })
```

## Performance notes

- These are GPU fragment effects. Most are cheap, but multi-tap blur shaders (`bcsDreamBlur`, `bcsLiquidBloom`, `bcsTiltShift`) sample many neighbors — profile before stacking them on large, fast-scrolling views.
- Animated shaders re-render every frame while on screen. Don't leave dozens running off-screen.
- `half`-precision is used throughout for speed; expect subtle banding on extreme parameter values.

## License

MIT — see [LICENSE](LICENSE). Use them, ship them, remix them. Attribution appreciated, not required.
