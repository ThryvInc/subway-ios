//
//  Styles.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 4/20/20.
//  Copyright © 2020 Thryv. All rights reserved.
//

import LUX
import LithoOperators

public extension UIColor {
    static func primary() -> UIColor {
        return UIColor(hex: 0x4d55a2)
    }
    
    static func primaryDark() -> UIColor {
        return UIColor(hex: 0x333972)
    }
    
    static func accent() -> UIColor {
        return UIColor(hex: 0xdf03a6)
    }
}

let setupEdges = set(\UIViewController.edgesForExtendedLayout, UIRectEdge())

let setupBackgroundColor = set(\UIView.backgroundColor, UIColor(named: "backgroundColor"))
let setupPrimaryBackgroundColor = set(\UIView.backgroundColor, UIColor(named: "primaryBgColor"))

func setupCircleCappedView(_ view: UIView) {
    view.layer.cornerRadius = view.bounds.size.width / 2
    view.clipsToBounds = true
}

func setupTableView(_ tableView: UITableView?) {
    tableView?.tableFooterView = UIView()
    tableView?.backgroundColor = UIColor(named: "backgroundColor")
}

func setupActionButtonPosition(_ actionButtonBottomConstraint: NSLayoutConstraint?) { actionButtonBottomConstraint?.constant = Current.adsEnabled ? 62 : 12 }
