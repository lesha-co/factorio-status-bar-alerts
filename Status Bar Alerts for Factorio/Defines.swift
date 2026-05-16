//
//  Menu.swift
//  factorio-statusbar
//
//  Created by lesha on 16. 4. 2026..
//

import SwiftUI

let modName = "macos-status-bar-alerts"

enum FactorioAlert: Int, CaseIterable {
    case entity_destroyed = 0
    case entity_under_attack = 1
    case not_enough_construction_robots = 2
    case no_material_for_construction = 3
    case not_enough_repair_packs = 4
    // case platform_tile_building_blocked = 5
    // case turret_out_of_ammo = 6
    case turret_fire = 7
    case custom = 8
    case no_storage = 9
    case train_out_of_fuel = 10
    case train_no_path = 11
    // case no_platform_storage = 12
    // case collector_path_blocked = 13
    // case unclaimed_carg = 14
    // case no_roboport_storage = 15
    // case pipeline_overextended = 16
}

struct Icon: Hashable {
    let name: String
    let UIDarkThemeColor: Color
    let UILightThemeColor: Color
    let statusBarButtonContentTintColor: Color
}

func icon(_ alert: FactorioAlert) -> Icon {
    switch alert {
    case .entity_under_attack:
        .init(
            name: "exclamationmark.triangle.fill",
            UIDarkThemeColor: .red,
            UILightThemeColor: .red,
            statusBarButtonContentTintColor: .red
        )
    case .entity_destroyed:
        .init(
            name: "xmark.diamond.fill",
            UIDarkThemeColor: .red,
            UILightThemeColor: .red,
            statusBarButtonContentTintColor: .red
        )
    case .no_material_for_construction:
        .init(
            name: "gearshape.fill",
            UIDarkThemeColor: .yellow,
            UILightThemeColor: .primary,
            statusBarButtonContentTintColor: .yellow
        )
    case .no_storage:
        .init(
            name: "suitcase.fill",
            UIDarkThemeColor: .yellow,
            UILightThemeColor: .primary,
            statusBarButtonContentTintColor: .yellow
        )
    case .not_enough_construction_robots:
        .init(
            name: "drone",
            UIDarkThemeColor: .yellow,
            UILightThemeColor: .primary,
            statusBarButtonContentTintColor: .yellow
        )
    case .not_enough_repair_packs:
        .init(
            name: "wrench.and.screwdriver.fill",
            UIDarkThemeColor: .yellow,
            UILightThemeColor: .primary,
            statusBarButtonContentTintColor: .yellow
        )
    case .turret_fire:
        .init(
            name: "exclamationmark.triangle.fill",
            UIDarkThemeColor: .yellow,
            UILightThemeColor: .primary,
            statusBarButtonContentTintColor: .yellow
        )
    case .train_out_of_fuel:
        .init(
            name: "fuelpump.exclamationmark.fill",
            UIDarkThemeColor: .red,
            UILightThemeColor: .red,
            statusBarButtonContentTintColor: .red
        )
    case .train_no_path:
        .init(
            name: "arrow.trianglehead.branch",
            UIDarkThemeColor: .orange,
            UILightThemeColor: .orange,
            statusBarButtonContentTintColor: .orange
        )
    case .custom:
        .init(
            name: "questionmark.diamond",
            UIDarkThemeColor: .purple,
            UILightThemeColor: .purple,
            statusBarButtonContentTintColor: .purple
        )

    }
}
