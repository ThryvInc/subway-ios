//
//  StationViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 7/27/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import UIKit
import GTFSStations

class StationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var station: Station!
    var stationManager: StationManager!
    var predictions: Array<Prediction>?

    override func viewDidLoad() {
        super.viewDidLoad()

        refresh()
        
        title = station.name
        
        tableView.registerNib(UINib(nibName: "PredictionTableViewCell", bundle: nil), forCellReuseIdentifier: "predCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        refresh()
    }
    
    func refresh() {
        predictions = stationManager.predictions(station, time: NSDate(timeIntervalSince1970: 1438215977))
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (predictions ?? Array<Prediction>()).count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("predCell") as! PredictionTableViewCell
        if let preds = predictions {
            let prediction = preds[indexPath.row]
            var formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.NoStyle
            formatter.timeStyle = NSDateFormatterStyle.ShortStyle
            cell.timeLabel.text = formatter.stringFromDate(prediction.timeOfArrival!)
            if let route = prediction.route {
                cell.routeLabel.text = route.objectId
            }
            if prediction.direction == .Uptown {
                cell.routeLabel.textColor = UIColor.blueColor()
            }else{
                cell.routeLabel.textColor = UIColor.redColor()
            }
        }
        return cell
    }

}
