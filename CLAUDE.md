# CLAUDE.md

This package's working guide for AI agents lives in **[AGENTS.md](AGENTS.md)** — read it before extending, modifying, or rebuilding the shaders.

Quick orientation:

- `Sources/EpilogueShaders/Shaders/EpilogueShaders.metal` — 41 `[[ stitchable ]]` SwiftUI fragment shaders (source of truth) + shared helpers.
- `Sources/EpilogueShaders/ShaderEffects.swift` — one typed `View` modifier per shader + the two `ViewModifier`s that do the `layerEffect` plumbing.
- All shaders are `layerEffect`-style. Argument order must match the Metal signature exactly. Runtime lookup is `ShaderLibrary.bundle(.module).bcs_name(...)`.
- **Build with Xcode / `xcodebuild`, not `swift build`** — only the full Metal toolchain produces `default.metallib` / `Bundle.module`.

See AGENTS.md for the parameter-mapping conventions, how to add a shader, and the gotchas.
