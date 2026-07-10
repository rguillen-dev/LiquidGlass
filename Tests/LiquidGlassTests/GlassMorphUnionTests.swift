//
//  GlassMorphUnionTests.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 07/09/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import Testing
import SwiftUI
@testable import LiquidGlass

@Suite("GlassMorphUnionReducer grouping")
struct GlassMorphUnionReducerTests {

    private func namespace() -> Namespace.ID {
        // `Namespace.ID` has no public initializer; a `@Namespace` property
        // wrapper only produces one inside a `View`'s body. `_NamespaceID`
        // isn't accessible either, so tests derive one the same way the rest
        // of the suite works around SwiftUI's environment-only types: through
        // a tiny host view that captures the id via `.onAppear`-free direct
        // property wrapper access, resolved synchronously since `Namespace`'s
        // wrapped value is available immediately on `wrappedValue` access.
        Namespace().wrappedValue
    }

    @Test("Entries sharing a group key union into one rect")
    func mergesSharedGroupKey() {
        let ns = namespace()
        let key = GlassMorphUnionGroupKey(id: AnyHashable("group"), namespace: ns)
        let entries = [
            GlassMorphUnionResolvedEntry(
                groupKey: key,
                rect: CGRect(x: 0, y: 0, width: 40, height: 40),
                style: .toolbar,
                tint: nil,
                cornerRadius: 12
            ),
            GlassMorphUnionResolvedEntry(
                groupKey: key,
                rect: CGRect(x: 60, y: 0, width: 40, height: 40),
                style: .toolbar,
                tint: nil,
                cornerRadius: 12
            )
        ]

        let grouped = GlassMorphUnionReducer.group(entries, padding: 0)
        #expect(grouped.count == 1)
        #expect(grouped[0].rect == CGRect(x: 0, y: 0, width: 100, height: 40))
    }

    @Test("Entries with different group keys stay separate")
    func keepsDistinctGroupKeysSeparate() {
        let ns = namespace()
        let keyA = GlassMorphUnionGroupKey(id: AnyHashable("a"), namespace: ns)
        let keyB = GlassMorphUnionGroupKey(id: AnyHashable("b"), namespace: ns)
        let entries = [
            GlassMorphUnionResolvedEntry(
                groupKey: keyA,
                rect: CGRect(x: 0, y: 0, width: 20, height: 20),
                style: .toolbar,
                tint: nil,
                cornerRadius: 10
            ),
            GlassMorphUnionResolvedEntry(
                groupKey: keyB,
                rect: CGRect(x: 100, y: 0, width: 20, height: 20),
                style: .toolbar,
                tint: nil,
                cornerRadius: 10
            )
        ]

        let grouped = GlassMorphUnionReducer.group(entries, padding: 0)
        #expect(grouped.count == 2)
    }

    @Test("Padding expands the unioned rect outward on every edge")
    func paddingExpandsRect() {
        let ns = namespace()
        let key = GlassMorphUnionGroupKey(id: AnyHashable("group"), namespace: ns)
        let entry = GlassMorphUnionResolvedEntry(
            groupKey: key,
            rect: CGRect(x: 10, y: 10, width: 30, height: 30),
            style: .toolbar,
            tint: nil,
            cornerRadius: 10
        )

        let grouped = GlassMorphUnionReducer.group([entry], padding: 5)
        #expect(grouped.count == 1)
        #expect(grouped[0].rect == CGRect(x: 5, y: 5, width: 40, height: 40))
    }

    @Test("A group's styling comes from its first entry")
    func stylingComesFromFirstEntry() {
        let ns = namespace()
        let key = GlassMorphUnionGroupKey(id: AnyHashable("group"), namespace: ns)
        let entries = [
            GlassMorphUnionResolvedEntry(
                groupKey: key,
                rect: CGRect(x: 0, y: 0, width: 20, height: 20),
                style: .sheet,
                tint: .indigo,
                cornerRadius: 18
            ),
            GlassMorphUnionResolvedEntry(
                groupKey: key,
                rect: CGRect(x: 40, y: 0, width: 20, height: 20),
                style: .overlay,
                tint: .pink,
                cornerRadius: 2
            )
        ]

        let grouped = GlassMorphUnionReducer.group(entries, padding: 0)
        #expect(grouped.count == 1)
        #expect(grouped[0].style == .sheet)
        #expect(grouped[0].tint == .indigo)
        #expect(grouped[0].cornerRadius == 18)
    }

    @Test("No entries produce no groups")
    func emptyEntriesProduceNoGroups() {
        #expect(GlassMorphUnionReducer.group([]).isEmpty)
    }

    @Test("Default padding matches the documented constant")
    func defaultPaddingConstant() {
        #expect(GlassMorphUnionReducer.defaultPadding == 6)
    }
}

@Suite("GlassMorphUnionSurfaces fallback stroke parity")
struct GlassMorphUnionSurfacesStrokeTests {

    // `GlassMorphUnionSurfaces.surface(for:)` renders its stroke through the
    // same `GlassMaterial.borderOpacity(reduceTransparency:contrast:)` /
    // `borderLineWidth(contrast:)` computations `GlassRenderingModifier` uses,
    // rather than duplicating the Reduce Transparency / Increased Contrast
    // logic locally. These tests pin that contract at the `GlassMaterial`
    // level so a merged union surface never drifts from every other fallback
    // glass surface in the package — including the combined state.

    @Test("Combined Reduce Transparency + Increased Contrast stays within range for every style a union group can carry")
    func combinedStateStaysInRange() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            let opacity = material.borderOpacity(reduceTransparency: true, contrast: .increased)
            #expect(opacity >= material.fallbackBorderOpacity)
            #expect(opacity <= 1)
        }
    }

    @Test("Increased Contrast widens the union surface's stroke regardless of Reduce Transparency")
    func increasedContrastWidensStrokeRegardlessOfReduceTransparency() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            #expect(material.borderLineWidth(contrast: .increased) == 1.0)
            #expect(material.borderLineWidth(contrast: .standard) == 0.5)
        }
    }
}

@Suite("GlassMorphUnionGroupKey identity")
struct GlassMorphUnionGroupKeyTests {

    @Test("Equal id and namespace produce equal keys")
    func equalIDAndNamespaceAreEqual() {
        let ns = Namespace().wrappedValue
        let a = GlassMorphUnionGroupKey(id: AnyHashable("shared"), namespace: ns)
        let b = GlassMorphUnionGroupKey(id: AnyHashable("shared"), namespace: ns)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Different ids in the same namespace produce different keys")
    func differentIDsAreNotEqual() {
        let ns = Namespace().wrappedValue
        let a = GlassMorphUnionGroupKey(id: AnyHashable("one"), namespace: ns)
        let b = GlassMorphUnionGroupKey(id: AnyHashable("two"), namespace: ns)
        #expect(a != b)
    }
}
