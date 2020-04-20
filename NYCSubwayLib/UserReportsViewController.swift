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
import FlexDataSource

class UserReportsViewController: LUXFlexViewController<UserReportsViewModel<Visit>> {
    @IBOutlet weak var userSwitch: UISwitch?
    @IBOutlet weak var autoSwitch: UISwitch?
    
    var onFilter: ((Bool, Bool) -> Void)?
    var deleteCall: CombineNetCall?
    private var cancelBag = Set<AnyCancellable?>()
    
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
    
    func swiped(visit: inout Visit) {
        if let id = visit.id {
            let call = deleteVisitCall(id: "\(id)")
            cancelBag.insert(call.responder?.$data.sink { _ in
                self.deleteCall = nil
                self.refresh()
            })
            deleteCall = call
            call.fire()
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
        
        let vm = UserReportsViewModel<Visit>(modelsPublisher: manager.$models.eraseToAnyPublisher(), modelToItem: visitItemFactory(stationManager!, swiped(visit:)))
        viewModel = vm

        let delegate = LUXFunctionalTableDelegate(onSelect: vm.dataSource.tappableOnSelect, onWillDisplay: manager.willDisplayFunction(pageSize: 25))
        self.tableViewDelegate = delegate
    }
}

open class UserReportsViewModel<T>: LUXModelTableViewModel<T>, LUXDataSourceProvider {
    public let dataSource: FlexDataSource
    
    public override init(modelsPublisher: AnyPublisher<[T], Never>, modelToItem: @escaping (T) -> FlexDataSourceItem) {
        dataSource = SwipableFlexDataSource()
        super.init(modelsPublisher: modelsPublisher, modelToItem: modelToItem)
        
        cancelBag.insert(self.sectionsPublisher.sink {
            self.dataSource.sections = $0
            self.dataSource.tableView?.reloadData()
        })
    }
}

func visitItemFactory(_ stationManager: StationManager, _ onSwipe: @escaping (inout Visit) -> Void) -> (Visit) -> FlexDataSourceItem {
    return { visit in
        VisitItem(visit, stationManager, {
            var v = visit
            onSwipe(&v)
        })
    }
}

extension String {
    func addedUp() -> Int {
        var sum = 0
        for val in Array(self) {
            let char = Character(String(val))
            sum += char.unicodeScalars.first.hashValue % 255
        }
        return sum
    }
}
