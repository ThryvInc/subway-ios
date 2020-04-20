//
//  Swipable.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 2/14/20.
//  Copyright © 2020 Thryv. All rights reserved.
//

import MultiModelTableViewDataSource
import LUX

public protocol Swipable {
    var onSwipe: () -> Void { get }
}

open class SwipableItem<T>: FunctionalMultiModelTableViewDataSourceItem<T>, Swipable where T: UITableViewCell {
    public var onSwipe: () -> Void
    
    public init(identifier: String,
                _ configureCell: @escaping (UITableViewCell) -> Void,
                _ onSwipe: @escaping () -> Void) {
        self.onSwipe = onSwipe
        super.init(identifier: identifier, configureCell)
    }
}

class SwipableFlexDataSource: MultiModelTableViewDataSource {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let _ = sections?[indexPath.section].items?[indexPath.row] as? Swipable {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let item = sections?[indexPath.section].items?[indexPath.row] as? Swipable {
                item.onSwipe()
                sections?[indexPath.section].items?.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
}
