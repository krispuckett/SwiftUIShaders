# AGENTS.md — architecture for coding agents

This file is for an AI agent (Claude Code, Codex, etc.) asked to **use, extend, modify, or rebuild** these shaders. It explains exactly how the package is wired so you can work without re-deriving the conventions.

## What this package is

- A SwiftPM library, `EpilogueShaders`, with **two source files**:
  - `Sources/EpilogueShaders/Shaders/EpilogueShaders.metal` — ~69 `[[ stitchable ]]` SwiftUI fragment shaders plus 5 shared helper functions. This is the source of truth.
  - `Sources/EpilogueShaders/ShaderEffects.swift` — one typed `View` modifier per shader, plus two private `ViewModifier`s (`_StaticShaderEffect`, `_AnimatedShaderEffect`) that do the actual `layerEffect` plumbing.
- No third-party dependencies. No app code. The `bcs_` prefix is just a namespace (it originated as "book cover shaders").

## How SwiftUI Metal shader effects work (the mental model)

SwiftUI exposes three shader entry points on `View`: `.colorEffect`, `.layerEffect`, and `.distortionEffect`. **Every shader here is a `layerEffect`**, because they all need to sample neighboring pixels (blur, displacement, refraction). A `layerEffect` Metal function has this fixed signature shape:

```metal
[[ stitchable ]] half4 bcs_name(
    float2 position,        // pixel being computed (SwiftUI supplies this)
    SwiftUI::Layer layer,   // the source view, sample it with layer.sample(coord) (SwiftUI supplies this)
    float2 size,            // view size in pixels  <- first user argument
    float time,             // seconds, for animation (only on animated shaders)
    float param1,           // ...effect-specific knobs
    ...
) { ... }
```

`position` and `layer` are provided by SwiftUI automatically. **Everything after `layer` is provided in order by the Swift call**, via `Shader.Argument` values (`.float`, `.float2`, `.color`, …). The arguments must match the Metal parameter order exactly.

At runtime the shaders live in a compiled `default.metallib` inside the package's resource bundle. You reach them with:

```swift
ShaderLibrary.bundle(.module).bcs_name(.float2(size), .float(t), .float(param1), ...)
```

`.module` resolves to the package bundle; `bcs_name` is a dynamic member that returns a `Shader`.

## The wrapper conventions (how `ShaderEffects.swift` maps to Metal)

For each Metal function, the generated `View` method maps parameters like this:

| Metal parameter | Swift wrapper does |
|---|---|
| `float2 position`, `SwiftUI::Layer layer` | nothing — SwiftUI supplies them |
| `float2 size` | passes `proxy.size` from `visualEffect`'s `GeometryProxy` |
| `float time` | passes elapsed seconds from `TimelineView(.animation)`; presence of `time` is what makes a shader "animated" |
| `float2 <point>` (e.g. `touchPos`) | exposes a `UnitPoint` (0...1) param, converts to pixels via `size` |
| any other `float` | exposes a typed `Float` param; default = midpoint of the documented `// lo-hi` range comment |

Two private modifiers carry the plumbing so the per-shader methods stay one-liners:

```swift
struct _StaticShaderEffect: ViewModifier {
    let maxSampleOffset: CGSize
    let shader: (CGSize) -> Shader
    func body(content: Content) -> some View {
        content.visualEffect { view, proxy in
            view.layerEffect(shader(proxy.size), maxSampleOffset: maxSampleOffset)
        }
    }
}

struct _AnimatedShaderEffect: ViewModifier {
    let maxSampleOffset: CGSize
    let shader: (CGSize, Float) -> Shader
    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let t = Float(context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 3600))   // bounded to keep float precision
            content.visualEffect { view, proxy in
                view.layerEffect(shader(proxy.size, t), maxSampleOffset: maxSampleOffset)
            }
        }
    }
}
```

> Why route through `ViewModifier` instead of calling `visualEffect` directly inside `TimelineView`? Because `TimelineView`'s `Content` generic can't be inferred from a bare `self.visualEffect { ... }` call. Inside `body(content:)`, `content` is a concrete `Content`, so inference succeeds. This is the load-bearing reason for the indirection — don't "simplify" it away.

## How to add a new shader

1. **Write the Metal function** in `EpilogueShaders.metal`. Follow the signature shape above. If it animates, include `float time`. Add a `// MARK: - Name` line and a one-line description comment above it, and `// lo-hi: meaning` comments on each parameter — the docs and defaults are derived from those.
2. **Declaration order matters.** A helper or function must be defined *before* anything that calls it. The shared helpers (`bcs_hash`, `bcs_valueNoise`, `bcs_fbm`, `bcs_hsb2rgb`) sit at the top; `bcs_sampleRegion` sits before its first user. Append new entry-point shaders; don't reorder existing ones.
3. **Add the Swift wrapper** in `ShaderEffects.swift`:

```swift
/// My Effect — what it does.
/// - Parameter strength: 0-10: how strong
func bcsMyEffect(strength: Float = 5, maxSampleOffset: CGSize = CGSize(width: 64, height: 64)) -> some View {
    modifier(_AnimatedShaderEffect(maxSampleOffset: maxSampleOffset) { size, t in
        ShaderLibrary.bundle(.module).bcs_myEffect(
            .float2(size), .float(t), .float(strength)
        )
    })
}
```

Use `_StaticShaderEffect { size in ... }` (no `t`) for non-animated effects.
4. **Build with Xcode** (`xcodebuild -scheme EpilogueShaders -destination 'generic/platform=iOS Simulator' build`) — Metal errors only surface through the real toolchain, not `swift build`.

## How to modify an existing shader

- Tweak the Metal body freely; the Swift wrapper only depends on the **parameter list order**. If you add/remove/reorder a Metal parameter, update the wrapper's argument list to match (same order), and update its Swift signature + doc comment.
- Keep `half` precision unless you specifically need `float` color accuracy — these run per-pixel and `half` is the perf default.

## Gotchas

- **`maxSampleOffset` clips sampling.** If a displacement shader looks cut off at the edges, the offset is too small. The wrappers default to `64×64`; expose/raise it for far-reaching effects (`bcsEcho`, `bcsShatter`, `bcsGravityWells`).
- **`bundle(.module)` requires the resource bundle**, which only exists after a real Metal-toolchain build. If you see `type 'Bundle' has no member 'module'`, you built with `swift build` instead of Xcode.
- **Time is unbounded over long sessions** — we modulo it by 3600s to preserve `float` precision in trig. Keep that if you touch the animated modifier.
- **One shader per `layerEffect`.** To chain effects, chain modifiers (`.bcsA().bcsB()`); each is a separate GPU pass.

## Rebuilding from scratch

If asked to regenerate the Swift wrappers from the Metal file: parse each `[[ stitchable ]] half4 bcs_*` signature, drop `position`/`layer`, map `size`→`proxy.size`, `time`→animated time, `float2 <name>`→`UnitPoint`, other `float`→typed param (default from the `// lo-hi` comment), and emit a `View` method routing through the two `ViewModifier`s above. That is exactly how the current `ShaderEffects.swift` was produced.
