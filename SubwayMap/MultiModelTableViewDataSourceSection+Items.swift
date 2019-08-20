//
//  MultiModelTableViewDataSourceSection+Items.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 1/25/19.
//  Copyright © 2019 Thryv. All rights reserved.
//

import MultiModelTableViewDataSource

public extension MultiModelTableViewDataSourceSection {
    public static func itemsToSection(items: [MultiModelTableViewDataSourceItem]) -> MultiModelTableViewDataSourceSection {
        let section = MultiModelTableViewDataSourceSection()
        section.items = items
        return section
    }
}
