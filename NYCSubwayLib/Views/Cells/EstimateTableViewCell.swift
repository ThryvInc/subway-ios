//
//  EstimateTableViewCell.swift
//  NYCSubwayLib
//
//  Created by Elliot Schrock on 4/23/20.
//  Copyright © 2020 Thryv. All rights reserved.
//

import UIKit

class EstimateTableViewCell: UITableViewCell {
    @IBOutlet weak var routeImage: UIImageView!
    @IBOutlet weak var routeLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var deltaLabel: UILabel!
    @IBOutlet weak var visitImageView: UIImageView!
    @IBOutlet weak var visitLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.autoresizingMask = .flexibleHeight
        setupCircleCappedView(routeLabel)
    }
}
