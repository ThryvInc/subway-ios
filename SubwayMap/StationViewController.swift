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

class StationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, LineChoiceViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lineChoice1: LineChoiceView!
    @IBOutlet weak var lineChoice2: LineChoiceView!
    @IBOutlet weak var lineChoice3: LineChoiceView!
    @IBOutlet weak var lineChoice4: LineChoiceView!
    var station: Station!
    var stationManager: StationManager!
    var predictions: [Prediction]?
    var predictionModels: [PredictionViewModel]?
    var filteredPredictionModels: [PredictionViewModel]?
    var routes: [Route] = [Route]()
    var lineModels: [LineViewModel] = [LineViewModel]()
    var lineViews = [LineChoiceView]()
    var favManager: FavoritesManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge.None
        
        tableView.registerNib(UINib(nibName: "PredictionTableViewCell", bundle: nil), forCellReuseIdentifier: "predCell")
        tableView.dataSource = self
        tableView.delegate = self

        refresh()
        
        title = station.name
        favManager = FavoritesManager(stationManager: stationManager)
        setupFavoritesButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        refresh()
        tableView.reloadData()
    }
    
    func setupFavoritesButton() {
        let favButton = UIButton()
        favButton.frame = CGRectMake(0, 0, 30, 30)
        
        if favManager.isFavorite(station.name){
            favButton.setImage(UIImage(named: "STARyellow")?.imageWithRenderingMode(.AlwaysOriginal), forState: .Normal)
        } else {
            favButton.setImage(UIImage(named: "STARgrey")?.imageWithRenderingMode(.AlwaysOriginal), forState: .Normal)
        }
        
        favButton.addTarget(self, action: #selector(StationViewController.toggleFavoriteStation), forControlEvents: .TouchUpInside)
        
        let favBarButton = UIBarButtonItem()
        favBarButton.customView = favButton
        self.navigationItem.rightBarButtonItem = favBarButton
    }

    func toggleFavoriteStation() {
        if favManager.isFavorite(station.name) {
            favManager.removeFavorites([self.station])
        } else {
            favManager.addFavorites([station])
        }
        setupFavoritesButton()
    }

    @IBAction func favoriteThisStation() {
        favManager.addFavorites([station])
        setupFavoritesButton()
    }
    
    func refresh() {
        do {
            predictions = try stationManager.predictions(station, time: NSDate())//timeIntervalSince1970: 1438215977))
        }catch{}
        predictions!.sortInPlace({ $0.secondsToArrival < $1.secondsToArrival })
        
        let uptown = predictions!.filter({ (prediction) -> Bool in
            return prediction.direction == .Uptown
        })
        let downtown = predictions!.filter({ (prediction) -> Bool in
            return prediction.direction == .Downtown
        })
        
        predictionModels = [PredictionViewModel]()
        
        for prediction in uptown ?? [Prediction]() {
            let model = PredictionViewModel(routeId: prediction.route?.objectId, direction: prediction.direction)
            if !predictionModels!.contains(model) {
                model.setupWithPredictions(predictions)
                predictionModels?.append(model)
            }
        }
        
        for prediction in downtown ?? [Prediction]() {
            let model = PredictionViewModel(routeId: prediction.route?.objectId, direction: prediction.direction)
            if !predictionModels!.contains(model) {
                model.setupWithPredictions(predictions)
                predictionModels?.append(model)
            }
        }
        
        predictionModels?.sortInPlace {$0.prediction.secondsToArrival < $1.prediction.secondsToArrival}
        
        filteredPredictionModels = predictionModels
        
        setLines()
    }
    
    func setLines() {
        setLineModels()
        setLineViews()
    }
    
    func setLineModels(){
        let predictionRouteIds = predictionModels!.map { $0.routeId }
        
        for routeId in predictionRouteIds {
            let lineModel = LineViewModel()
            lineModel.routeIds = [routeId]
            lineModel.color = NYCRouteColorManager.colorForRouteId(routeId)
            let lineIndex = lineModels.indexOf(lineModel)
            if let index = lineIndex {
                if !lineModels[index].routeIds.contains(routeId) {
                    lineModels[index].routeIds.append(routeId)
                }
            }else{
                lineModels.append(lineModel)
            }
        }
    }
    
    func setLineViews(){
        lineViews = [lineChoice1, lineChoice2, lineChoice3, lineChoice4]
        var count = 0
        while count < lineViews.count {
            let lineView = lineViews[count]
            if count < lineModels.count {
                lineView.hidden = false
                lineView.lineLabel.text = lineModels[count].routesString()
                let image = UIImage(named: "Grey")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate);
                lineView.dotImageView.image = image
                lineView.dotImageView.tintColor = lineModels[count].color
            }else{
                lineView.hidden = true
            }
            lineView.delegate = self
            lineView.updateConstraints()
            lineView.setNeedsLayout()
            lineView.layoutIfNeeded()
            count += 1
        }
    }
    
    func configurePredictionCell(cell: PredictionTableViewCell, indexPath: NSIndexPath) {
        let model = filteredPredictionModels![indexPath.row]
        let prediction = model.prediction
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.NoStyle
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        cell.timeLabel.text = formatter.stringFromDate(prediction.timeOfArrival!).lowercaseString
        cell.deltaLabel.text = "\(prediction.secondsToArrival! / 60)m"
        
        if let route = prediction.route {
            cell.routeLabel.text = route.objectId
            let image = UIImage(named: "Train")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate);
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
    
    //MARK: line choice delegate
    
    func didSelectLineWithColor(color: UIColor) {
        for lineView in lineViews {
            if lineView.dotImageView.tintColor != color {
                lineView.isSelected = false
            }
        }
        
        filteredPredictionModels = predictionModels?.filter({NYCRouteColorManager.colorForRouteId($0.routeId) == color})
        tableView.reloadData()
    }
    
    func didDeselectLineWithColor(color: UIColor) {
        filteredPredictionModels = predictionModels
        tableView.reloadData()
    }
    
    //MARK: table data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (filteredPredictionModels ?? [PredictionViewModel]()).count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("predCell") as! PredictionTableViewCell
        configurePredictionCell(cell, indexPath: indexPath)
        return cell
    }

}
