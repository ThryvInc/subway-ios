//
//  StationItem.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 1/25/19.
//  Copyright © 2019 Thryv. All rights reserved.
//

import SubwayStations
import MultiModelTableViewDataSource

class StationItem: ConcreteMultiModelTableViewDataSourceItem<StationTableViewCell> {
    let stationManager: StationManager
    let station: Station
    
    init(identifier: String, _ stationManager: StationManager, _ station: Station) {
        self.stationManager = stationManager
        self.station = station
        super.init(identifier: identifier)
    }
    
    static func item(_ station: Station, _ stationManager: StationManager) -> StationItem {
        return StationItem(identifier: "stationCell", stationManager, station)
    }
    
    override func configureCell(_ cell: UITableViewCell) {
        if let cell = cell as? StationTableViewCell {
            configureCellLines(cell)
        }
    }
    
    func configureCellLines(_ cell: StationTableViewCell){
        cell.stationNameLabel?.text = station.name
        for imageView in cell.orderedLineImageViews! {
            imageView.image = nil
        }
        if let shouldShowLines = Bundle.main.infoDictionary!["ShowLines"] as? Bool {
            if shouldShowLines {
                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                    if let lines = self.stationManager.linesForStation(self.station) {
                        DispatchQueue.main.async {
                            if cell.stationNameLabel.text != self.station.name {
                                return
                            }
                            cell.firstLineImageView.image = nil
                            cell.secondLineImageView.image = nil
                            cell.thirdLineImageView.image = nil
                            cell.fourthLineImageView.image = nil
                            for line in lines {
                                let image = UIImage(named: "Grey")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate);
                                if cell.firstLineImageView.image == nil {
                                    cell.firstLineImageView.image = image
                                    cell.firstLineImageView.tintColor = line.color
                                }else if cell.secondLineImageView.image == nil {
                                    cell.secondLineImageView.image = image
                                    cell.secondLineImageView.tintColor = line.color
                                }else if cell.thirdLineImageView.image == nil {
                                    cell.thirdLineImageView.image = image
                                    cell.thirdLineImageView.tintColor = line.color
                                }else if cell.fourthLineImageView.image == nil {
                                    cell.fourthLineImageView.image = image
                                    cell.fourthLineImageView.tintColor = line.color
                                }
                            }
                        };
                    }
                };
            }
        }
    }
}
