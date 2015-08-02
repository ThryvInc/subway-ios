//
//  StationViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 7/27/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import UIKit
import GTFSStations
import CoreGraphics

class StationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var station: Station!
    var stationManager: StationManager!
    var predictions: Array<Prediction>?
    var predictionModels: Array<PredictionViewModel>?

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
        predictions = stationManager.predictions(station, time: NSDate())//timeIntervalSince1970: 1438215977))
        predictions!.sort({ $0.secondsToArrival < $1.secondsToArrival })
    }
    
    func configurePredictionCell(cell: PredictionTableViewCell, indexPath: NSIndexPath) {
        if let preds = predictions {
            let model = predictionModels![indexPath.row]
            model.setupWithPredictions(preds)
            let prediction = model.prediction
            var formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.NoStyle
            formatter.timeStyle = NSDateFormatterStyle.ShortStyle
            cell.timeLabel.text = formatter.stringFromDate(prediction.timeOfArrival!).lowercaseString
            cell.deltaLabel.text = "\(prediction.secondsToArrival! / 60)m"
            
            if let route = prediction.route {
                cell.routeLabel.text = route.objectId
                var image = UIImage(named: "Train")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate);
                cell.routeImage.image = image
                cell.routeImage.tintColor = NYCRouteColorManager.colorForRouteId(route.objectId)
            }
            
            if prediction.direction == .Uptown {
                cell.routeImage.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
                cell.routeLabelOffset.constant = 5
            }else{
                cell.routeImage.transform = CGAffineTransformMakeRotation(0)
                cell.routeLabelOffset.constant = -5
            }
            
            if let nextPrediction = model.onDeckPrediction {
                cell.onDeckLabel.text = formatter.stringFromDate(nextPrediction.timeOfArrival!).lowercaseString
            }
            
            if let finalPrediction = model.inTheHolePrediction {
                cell.inTheHoleLabel.text = formatter.stringFromDate(finalPrediction.timeOfArrival!).lowercaseString
            }
            
            cell.contentView.updateConstraints();
        }
    }
    
    //MARK: table data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var uptown = predictions!.filter({ (prediction) -> Bool in
            return prediction.direction == .Uptown
        })
        var downtown = predictions!.filter({ (prediction) -> Bool in
            return prediction.direction == .Downtown
        })
        
        predictionModels = Array<PredictionViewModel>()
        
        for prediction in uptown ?? Array<Prediction>() {
            var model = PredictionViewModel(routeId: prediction.route?.objectId, direction: prediction.direction)
            if !contains(predictionModels!, model) {
                predictionModels?.append(model)
            }
        }
        
        for prediction in downtown ?? Array<Prediction>() {
            var model = PredictionViewModel(routeId: prediction.route?.objectId, direction: prediction.direction)
            if !contains(predictionModels!, model) {
                predictionModels?.append(model)
            }
        }
        
        return (predictionModels ?? Array<PredictionViewModel>()).count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("predCell") as! PredictionTableViewCell
        configurePredictionCell(cell, indexPath: indexPath)
        return cell
    }

}
