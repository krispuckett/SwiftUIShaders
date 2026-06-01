# SwiftUIShaders

41 SwiftUI Metal shaders. Holographic foil, kaleidoscope mandalas, magnetic fields, glitch, neon edges, and a pile more. Each one is a `[[ stitchable ]]` Metal function with a typed SwiftUI `View` modifier wrapped around it, so dropping one onto a view is a single line.

<p align="center">
  <img src="Docs/demo.gif" width="280" alt="SwiftUIShaders running live in the shader lab" />
</p>

These started as a hidden shader lab inside Epilogue, my reading app. I built way more than I ever shipped, so I pulled the good ones out to share. Every shader here got rendered on a real book cover and kept only if it actually looked good. The duds, the washed-out ones, and the ones that only work on a blank gradient got cut. What's left is the set I'd reach for myself.

Drop them into your own project and mess around. They're also built to hand straight to a coding agent like Claude Code or Codex. If one sparks an idea, point your agent at [AGENTS.md](AGENTS.md) and let it riff.

> The `bcs_` prefix is just the shader namespace. Nothing here is wired to Epilogue's actual app code.

## Requirements

- iOS 17+ / macOS 14+ / tvOS 17+ / visionOS 1+
- Xcode 15+ (the Metal toolchain compiles the shaders into the package's `default.metallib`)

> One gotcha: build with Xcode or `xcodebuild`, not bare `swift build`. SwiftPM's command-line driver on macOS doesn't run the Metal toolchain, so `Bundle.module` and `default.metallib` never get produced. In Xcode it just works.

## Install

Swift Package Manager. In Xcode, go to **File ▸ Add Package Dependencies** and point it at this repo's URL. Or add it in `Package.swift`:

```swift
.package(url: "https://github.com/krispuckett/SwiftUIShaders.git", from: "1.0.0")
```

Then add `SwiftUIShaders` to your target's dependencies.

## Quick start

```swift
import SwiftUI
import SwiftUIShaders

struct ContentView: View {
    var body: some View {
        Image("book-cover")
            .resizable()
            .scaledToFit()
            .bcsHolographic(intensity: 0.6, scale: 12, speed: 1.2)  // animated, self-driving
    }
}
```

Every shader is a `View` modifier. The animated ones run themselves with `TimelineView(.animation)`, so there's no timer for you to babysit. Every parameter has a sensible default, so `.bcsKaleidoscope()` works on its own.

```swift
Text("Chapter One")
    .font(.largeTitle)
    .bcsChromaticSplit(spread: 8, angle: .pi / 4)

bookCover
    .bcsAurora()             // ambient animated glow

myView
    .bcsEmboss(strength: 3)  // static relief
```

One heads up: these want real content. Photos, book covers, illustrations, text. Drop one on a flat single-color fill and the displacement and edge effects have nothing to grab onto.

## How it works (conventions)

Each wrapper applies one Metal `layerEffect`. The mapping is uniform:

| Shader argument | Supplied by the wrapper |
|---|---|
| `position`, `layer` | SwiftUI (automatic) |
| `size` | The view's pixel size, from `GeometryProxy` |
| `time` | Elapsed seconds, from `TimelineView(.animation)` (animated shaders only) |
| interaction point (e.g. `touchPos`) | A `UnitPoint` (0...1) you pass, converted to pixels |
| everything else | Typed `Float` parameters with defaults |

Every method also takes `maxSampleOffset:` (default `64×64`). Raise it if a heavy displacement effect looks clipped at the edges. Lower it for a small perf win on cheap effects.

## The shaders

37 animate. 4 are static (`bcsEmboss`, `bcsFrosted`, and the two interaction-driven ripples). Ranges in parentheses are the sweet spots. The defaults are tuned values that look good out of the box, so you can call any of these with no arguments and get something real.

| Shader | Type | Parameters |
|---|---|---|
| **`.bcsAurora`**: Aurora | animated | `intensity` (0–1), `bands` (1–8), `speed` (0.3–3), `colorShift` (0–1) |
| **`.bcsBlackHole`**: Black Hole | animated | `mass` (0.05–0.5), `spin` (0–5), `distortion` (10–200), `ringBrightness` (0–2) |
| **`.bcsChromaticSplit`**: Chromatic Split | animated | `spread` (0–30), `angle` (0–6.28), `edgeOnly` (0–1), `animate` (0–1) |
| **`.bcsDatamosh`**: Datamosh | animated | `blockCorruption` (0–1), `smearAmount` (0–60), `colorBleed` (0–1), `glitchRate` (0.5–5) |
| **`.bcsDisintegrate`**: Disintegrate | animated | `threshold` (0–1), `edgeWidth` (0.05–0.3), `driftAmount` (0–50), `direction` (0–6.28) |
| **`.bcsDuochrome`**: Duochrome | animated | `intensity` (0–1), `hue1` (0–1), `hue2` (0–1), `contrast` (0.5–2) |
| **`.bcsEcho`**: Echo / Ghost | animated | `echoCount` (2–8), `spread` (5–50), `direction` (0–6.28), `fade` (0.3–0.9) |
| **`.bcsEmboss`**: Emboss / Relief | static | `strength` (0–5), `angle` (0–6.28), `mixAmount` (0–1) |
| **`.bcsEtherealAura`**: Ethereal Aura (v2) | animated | `auraWidth`, `auraIntensity`, `pulseSpeed`, `distortion`, `hueShift` |
| **`.bcsFrosted`**: Frosted Glass | static | `frostAmount` (0–1), `grainSize` (1–20), `clearRadius` (0–1), `clearSoftness` (0–1) |
| **`.bcsGeometricWarp`**: Geometric Warp | animated | `spiralTight` (1–8), `zoomRepeat` (0.3–2), `rotation` (0–6.28), `blend` (0–1) |
| **`.bcsGlitch`**: Glitch | animated | `intensity` (0–1), `blockSize` (2–50), `scanLines` (0–1), `colorShift` (0–20) |
| **`.bcsGravityWells`**: Gravity Wells | animated | `wellStrength` (10–200), `wellCount` (1–5), `orbitSpeed` (0.1–3), `warpFalloff` (0.5–5) |
| **`.bcsHeatShimmer`**: Heat Shimmer | animated | `amplitude` (0–20), `frequency` (1–30), `speed` (0.5–5), `verticalBias` (0–1) |
| **`.bcsHolographic`**: Holographic / Prismatic | animated | `intensity` (0–1), `scale` (1–20), `speed` (0.1–3), `angleOffset` (0–6.28) |
| **`.bcsInkBleed`**: Ink Bleed / Domain Warp | animated | `warpStrength` (0–50), `scale` (1–10), `speed` (0.1–2), `detail` (2–8) |
| **`.bcsKaleidoscope`**: Kaleidoscope | animated | `segments` (2–16), `rotation` (0–6.28), `zoom` (0.5–3), `animateSpeed` (0–2) |
| **`.bcsLiquidChrome`**: Liquid Chrome | animated | `distortion` (0–30), `chromeIntensity` (0–1), `flowSpeed` (0.1–3), `reflectionScale` (1–10) |
| **`.bcsLiquidMirror`**: Liquid Mirror | animated | `mirrorAxis` (0.3–0.7), `ripple` (2–30), `speed` (0.5–3), `depth` (0–1) |
| **`.bcsLiveRipple`**: Live Ripple | animated | `amplitude` (0–30), `frequency` (5–60), `speed` (1–10), `damping` (0.5–5), `ringCount` (1–5) |
| **`.bcsMagneticField`**: Magnetic Field | animated | `fieldStrength` (5–80), `lineCount` (3–20), `fieldTurbulence` (0–1), `polarity` (0–1) |
| **`.bcsMelt`**: Melt | animated | `meltAmount` (0–100), `dripScale` (1–15), `speed` (0.1–3), `heat` (0–1) |
| **`.bcsMorphBreathe`**: Morph Breathe | animated | `breatheDepth` (5–50), `breatheRate` (0.3–3), `warpComplexity` (1–8), `organic` (0–1) |
| **`.bcsNeonEdge`**: Neon Edge | animated | `edgeStrength` (1–10), `glowAmount` (0–2), `colorCycle` (0–3), `mixOriginal` (0–1) |
| **`.bcsPixelateMosaic`**: Pixelate Mosaic | animated | `pixelSize` (4–60), `bevel` (0–1), `animateAssemble` (0–1), `gap` (0–0.3) |
| **`.bcsPixelateStorm`**: Pixelate Storm | animated | `pixelSize` (2–40), `stormAmount` (0–1), `swirl` (0–3), `pulse` (0–3) |
| **`.bcsPlasma`**: Plasma | animated | `intensity` (0–1), `scale` (1–10), `speed` (0.5–5), `colorMode` (0–1) |
| **`.bcsPulse`**: Pulse / Heartbeat | animated | `amplitude` (0–30), `bpm` (30–180), `sharpness` (1–10), `glowIntensity` (0–1) |
| **`.bcsRefractLens`**: Refract Lens (Interactive) | static | `touchPos` (UnitPoint), `lensRadius` (0.1–0.5), `refraction` (1–3), `aberration` (0–15), `wobble` (0–1) |
| **`.bcsShatter`**: Shatter | animated | `shardCount` (3–30), `explode` (0–1), `rotationAmt` (0–3), `edgeGlow` (0–2) |
| **`.bcsShatterGlass`**: Shatter Glass | animated | `crackDensity` (3–15), `glassRefraction` (0–20), `prismStrength` (0–1), `shatterSpread` (0–1) |
| **`.bcsShockwave`**: Shockwave | animated | `waveSpeed` (50–500), `ringWidth` (5–60), `strength` (5–80), `repeatRate` (0.5–5) |
| **`.bcsSmokeReveal`**: Smoke Reveal | animated | `smokeAmount` (0–1), `smokeScale` (2–10), `windSpeed` (0.5–3), `smokeTurb` (0.5–3) |
| **`.bcsSolarize`**: Solarize | animated | `threshold` (0.2–0.8), `curveIntensity` (0–3), `colorSeparation` (0–1), `animate` (0–1) |
| **`.bcsThermal`**: Thermal | animated | `intensity` (0–1), `shimmer` (0–15), `noiseSpeed` (0.5–3), `paletteShift` (0–1) |
| **`.bcsTopographic`**: Topographic | animated | `lineCount` (5–40), `lineWidth` (0.01–0.15), `colorize` (0–1), `animate` (0–1) |
| **`.bcsTouchRipple`**: Touch Ripple | static | `touchPos` (UnitPoint), `touchAge`, `amplitude` (0–30), `frequency` (5–40), `speed` (50–500), `decay` (0.5–4) |
| **`.bcsUnderwaterCaustics`**: Underwater Caustics | animated | `causticScale` (2–15), `causticIntensity` (0–2), `waterDistortion` (0–30), `waterDepth` (0–1) |
| **`.bcsVortex`**: Vortex Spiral | animated | `twistAmount` (0–10), `radius` (0.1–1), `speed` (0.1–3), `falloff` (0.5–5) |
| **`.bcsWavePool`**: Wave Pool | animated | `amplitude` (0–25), `wavelength` (5–40), `speed` (0.5–5), `complexity` (1–6) |
| **`.bcsWormhole`**: Wormhole | animated | `depth` (1–8), `speed` (0.3–3), `twist` (0–5), `radius` (0.1–0.5) |

### Interaction-driven shaders

`bcsTouchRipple` and `bcsRefractLens` take a `touchPos: UnitPoint`. Feed them a drag location for a touch-reactive effect, and use a `GeometryReader` to normalize the point:

```swift
@State private var touch: UnitPoint = .center

GeometryReader { geo in
    myView
        .bcsRefractLens(touchPos: touch, lensRadius: 0.3)
        .gesture(DragGesture(minimumDistance: 0).onChanged { v in
            touch = UnitPoint(x: v.location.x / geo.size.width,
                              y: v.location.y / geo.size.height)
        })
}
```

## Performance notes

- These are GPU fragment effects. Most are cheap, but the blur and displacement-heavy ones (`bcsFrosted`, `bcsShatterGlass`, `bcsMagneticField`) sample a lot of neighbors, so profile before you stack them on big, fast-scrolling views.
- Animated shaders re-render every frame while they're on screen. Don't leave dozens running off-screen.
- `half`-precision is used throughout for speed. Expect a little banding at extreme parameter values.

## License

MIT. See [LICENSE](LICENSE). Use them, ship them, remix them. Attribution's appreciated, never required.
