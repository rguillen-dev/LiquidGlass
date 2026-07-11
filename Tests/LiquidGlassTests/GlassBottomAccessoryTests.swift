//
//  GlassBottomAccessoryTests.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 07/09/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import Testing
import SwiftUI
@testable import LiquidGlass

@Suite("GlassBottomAccessoryHost")
struct GlassBottomAccessoryHostTests {

    @Test("Both documented hosts are present in allCases")
    func allCasesCovered() {
        #expect(GlassBottomAccessoryHost.allCases.count == 2)
        let expected: Set<GlassBottomAccessoryHost> = [.tabView, .customTabBar]
        #expect(Set(GlassBottomAccessoryHost.allCases) == expected)
    }

    @Test(".tabView and .customTabBar are distinct")
    func hostsAreDistinct() {
        #expect(GlassBottomAccessoryHost.tabView != GlassBottomAccessoryHost.customTabBar)
    }
}

@Suite("GlassBottomAccessory configuration")
struct GlassBottomAccessoryConfigurationTests {

    @Test("Defaults to the .tabView host and enabled state")
    func defaults() {
        let accessory = GlassBottomAccessory(tint: .indigo) {
            Text("content")
        } accessory: {
            Text("accessory")
        }
        #expect(accessory.host == .tabView)
        #expect(accessory.isEnabled)
        #expect(accessory.tint == .indigo)
    }

    @Test("An explicit .customTabBar host is preserved")
    func customTabBarHostPreserved() {
        let accessory = GlassBottomAccessory(host: .customTabBar) {
            Text("content")
        } accessory: {
            Text("accessory")
        }
        #expect(accessory.host == .customTabBar)
    }

    @Test("isEnabled false is preserved")
    func disabledStatePreserved() {
        let accessory = GlassBottomAccessory(isEnabled: false) {
            Text("content")
        } accessory: {
            Text("accessory")
        }
        #expect(!accessory.isEnabled)
    }

    @Test("A nil tint and a set tint produce different configurations")
    func tintNilVersusSet() {
        let untinted = GlassBottomAccessory {
            Text("content")
        } accessory: {
            Text("accessory")
        }
        let tinted = GlassBottomAccessory(tint: .teal) {
            Text("content")
        } accessory: {
            Text("accessory")
        }
        #expect(untinted.tint == nil)
        #expect(tinted.tint == .teal)
    }
}
