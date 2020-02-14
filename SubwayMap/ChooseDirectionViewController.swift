//
//  ChooseDirectionViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 6/14/18.
//  Copyright © 2018 Thryv. All rights reserved.
//

import LUX
import SubwayStations
import Combine

class ChooseDirectionViewController: UIViewController {
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var rightLabel: UILabel!
    var callingViewController: UIViewController?
    var station: Station!
    var stationManager: StationManager!
    var routeId: String!
    var reportCall: CombineNetCall?
    private var cancelBag = Set<AnyCancellable?>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChoice(imageView: leftImageView, label: leftLabel, directionId: 0)
        setupChoice(imageView: rightImageView, label: rightLabel, directionId: 1)
    }
    
    func setupChoice(imageView: UIImageView, label: UILabel, directionId: Int) {
        label.text = NYCDirectionNameProvider.directionName(for: directionId, routeId: routeId)
        let directionEnum = NYCDirectionNameProvider.directionEnum(for: directionId, routeId: routeId)
        switch directionEnum {
        case .left:
            imageView.image = UIImage(named: "ic_arrow_back_black_24dp")
            break
        case .right:
            imageView.image = UIImage(named: "ic_arrow_forward_black_24dp")
            break
        case .up:
            imageView.image = UIImage(named: "ic_arrow_upward_black_24dp")
            break
        case .down:
            imageView.image = UIImage(named: "ic_arrow_downward_black_24dp")
            break
        }
    }
    
    @IBAction func leftButtonPressed() {
        reportVisit(with: 0)
    }
    
    @IBAction func rightButtonPressed() {
        reportVisit(with: 1)
    }
    
    func reportVisit(with direction: Int) {
        let visit = Visit()
        visit.directionId = direction
        visit.routeId = routeId
        visit.stationId = station.stops.first?.objectId
        reportCall = reportVisitCall(visit: visit)
        cancelBag.insert(reportCall?.responder?.$httpResponse.sink { _ in
            self.thankYou()
        })
        reportCall?.fire()
    }
    
    func thankYou() {
        let trainReports = UserDefaults.standard.integer(forKey: "trains") + 1
        UserDefaults.standard.set(trainReports, forKey: "trains")
        
        let trainPlural = trainReports == 1 ? "train" : "trains"
        let alert = UIAlertController(title: "Thank you!", message: "You've reported \(trainReports) \(trainPlural).", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hooray!", style: .default, handler: { _ in self.pop() }))
        self.present(alert, animated: true)
    }
    
    func pop() {
        if let vc = self.callingViewController {
            self.navigationController?.popToViewController(vc, animated: true)
        }
    }
}
