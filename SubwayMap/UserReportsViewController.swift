//
//  UserReportsViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 1/29/20.
//  Copyright © 2020 Thryv. All rights reserved.
//

import LUX
import FunNet
import LithoOperators
import Prelude
import Combine
import SubwayStations

class UserReportsViewController: LUXMultiModelTableViewController<LUXModelListViewModel<Visit>> {
    @IBOutlet weak var userSwitch: UISwitch?
    @IBOutlet weak var autoSwitch: UISwitch?
    
    var onFilter: ((Bool, Bool) -> Void)?
    
    var stationManager: StationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Reports"
    }
    
    @IBAction func filterByUser() {
        if let byUser = userSwitch?.isOn, let auto = autoSwitch?.isOn {
            onFilter?(byUser, auto)
        }
    }
    
    @IBAction func filterAuto() {
        if let byUser = userSwitch?.isOn, let auto = autoSwitch?.isOn {
            onFilter?(byUser, auto)
        }
    }
}

func userReportsVC(_ stationManager: StationManager) -> UserReportsViewController {
    let vc = UserReportsViewController.makeFromXIB()
    vc.stationManager = stationManager
    vc.configure()
    vc.onViewDidLoad = { _ in
        vc.onFilter = vc.configure >>> vc.refresh
    }
    return vc
}

extension UserReportsViewController {
    func configure(thisUserOnly: Bool = true, allowAuto: Bool = false) {
        let call = getUserVisitsCall(userId: (thisUserOnly ? UuidProvider.fetch() : nil))
        if allowAuto {
            call.endpoint.getParams.removeValue(forKey: "is_auto")
        } else {
            call.endpoint.getParams.updateValue(false, forKey: "is_auto")
            call.endpoint.getParams.updateValue(25, forKey: "per")
        }
        
        let visitsPub: AnyPublisher<[Visit], Never> = unwrappedModelPublisher(from: call.responder!.$data.eraseToAnyPublisher(), ^\VisitsResponse.visits)
        
        let manager = LUXPageCallModelsManager(call, visitsPub, firstPageValue: 0)
        refreshableModelManager = manager
        
        let vm = LUXModelListViewModel<Visit>.init(modelsPublisher: manager.$models.eraseToAnyPublisher(), modelToItem: stationManager! >||> VisitItem.init)
        viewModel = vm

        let delegate = LUXPageableTableViewDelegate(manager, vm.dataSource)
        delegate.pageSize = 25
        self.tableViewDelegate = delegate
    }
}

extension String {
    func addedUp() -> Int {
        var sum = 0
        for val in Array(self) {
            let char = Character(String(val))
            sum += char.unicodeScalars.first.hashValue % 255
//            if let intVal = Character(String(val)).asciiValue as? Int {
//                sum += intVal
//            }
        }
        return sum
    }
}
