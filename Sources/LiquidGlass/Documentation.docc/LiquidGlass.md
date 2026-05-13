# ``LiquidGlass``

Apple's iOS 26 Liquid Glass material, as a single SwiftUI modifier — with a high-fidelity fallback for iOS 17 and 18.

## Overview

`LiquidGlass` is a tiny SwiftUI package that lets any view wear the Liquid
Glass material introduced in iOS 26. On older systems the package renders a
hand-tuned approximation that combines `Material`, a subtle inner stroke and
a per-style depth shadow, so your UI looks intentional everywhere — not
just on the latest OS.

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

## Topics

### Applying the material

- ``SwiftUI/View/glass(style:tint:cornerRadius:)``

### Styles

- ``GlassStyle``

### Components

- ``GlassCard``
- ``GlassButton``
