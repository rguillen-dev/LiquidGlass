# LiquidGlass

A SwiftUI modifier that brings Apple's iOS 26 Liquid Glass material to any view, with a high-fidelity fallback for iOS 17 and 18.

![Swift](https://img.shields.io/badge/Swift-6-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

## Installation

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/rguillen-dev/LiquidGlass.git", from: "0.1.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["LiquidGlass"]
    )
]
```

### Xcode

`File ▸ Add Package Dependencies…` and paste:

```
https://github.com/rguillen-dev/LiquidGlass.git
```

## Quick start

```swift
import SwiftUI
import LiquidGlass

struct NowPlayingCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Now Playing").font(.headline)
            Text("Synthwave Drive").font(.subheadline)
        }
        .padding()
        .glass(style: .card, tint: .indigo)
    }
}
```

Use the prebuilt components when you want a complete surface:

```swift
GlassCard(tint: .blue) {
    Text("Hello, glass.")
}

GlassButton(tint: .pink) {
    // action
} label: {
    Label("Continue", systemImage: "arrow.right")
}
```

## API reference

### `.glass(style:tint:cornerRadius:)`

| Parameter      | Type            | Default        | Description                                                                |
| -------------- | --------------- | -------------- | -------------------------------------------------------------------------- |
| `style`        | `GlassStyle`    | `.sheet`       | Visual variant. Controls thickness, depth, and default corner radius.      |
| `tint`         | `Color?`        | `nil`          | Low-opacity color overlay applied on top of the material.                  |
| `cornerRadius` | `CGFloat?`      | `nil`          | Overrides the style's default corner radius when provided.                 |

### `GlassStyle`

| Case        | Role                                  | Default corner radius |
| ----------- | ------------------------------------- | --------------------- |
| `.sheet`    | Floating panel, prominent depth        | 24                    |
| `.card`     | Contained surface, medium depth        | 16                    |
| `.button`   | Compact, interactive feel              | 12                    |
| `.toolbar`  | Inline bar element                     | 10                    |
| `.sidebar`  | Full-height navigation surface         | 20                    |
| `.overlay`  | Full coverage, max blur                | 0                     |

### Components

| Type           | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `GlassCard`    | Container that wraps content with padding and the glass material.    |
| `GlassButton`  | `Button` styled with the glass material and a press-state animation. |

## Fallback behavior

On iOS 26 and later, `LiquidGlass` uses Apple's native `glassEffect(_:in:)`
API directly.

On iOS 17 and 18, the package renders a hand-tuned approximation:

* A `Material` base layer chosen per style (`.ultraThinMaterial` for `.sheet`,
  `.thickMaterial` for `.sidebar`, and so on)
* A 0.5 pt inner stroke at 10–20% white opacity to simulate refracting glass
* A per-style depth shadow that scales with the role of the surface
* Optional tint, layered as a low-opacity fill above the material

The result reads as glass on every supported OS — your UI keeps the same
intent whether it ships on iOS 17 or iOS 26.

## Requirements

* Swift 6.0+
* iOS 17.0+
* Xcode 16.0+ (Xcode 26+ recommended for native Liquid Glass rendering)

## License

MIT — see [LICENSE](LICENSE).

---

Built by Ricardo Guillen · [ricardoguillen.dev](https://ricardoguillen.dev)
