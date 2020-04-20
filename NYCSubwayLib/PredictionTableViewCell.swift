//
//  PredictionTableViewCell.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 7/29/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import UIKit

class PredictionTableViewCell: UITableViewCell {
    @IBOutlet weak var routeImage: UIImageView!
    @IBOutlet weak var routeLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var deltaLabel: UILabel!
    @IBOutlet weak var visitImageView: UIImageView!
    @IBOutlet weak var visitLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        routeLabel.layer.cornerRadius = 18
        routeLabel.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
