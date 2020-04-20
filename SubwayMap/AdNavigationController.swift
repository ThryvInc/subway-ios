//
//  AdNavigationController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 5/9/16.
//  Copyright © 2016 Thryv. All rights reserved.
//

import UIKit
import GoogleMobileAds

class AdNavigationController: UINavigationController, GADBannerViewDelegate {
    var navBannerView: GADBannerView?
    var bannerBottomConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.adUnitID = Bundle.main.infoDictionary!["AdUnitId"] as? String
        bannerView.rootViewController = self
        bannerView.delegate = self
        
        view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        bannerBottomConstraint = NSLayoutConstraint(item: bannerView, attribute: .bottom,
                                                    relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 50)
        view.addConstraint(bannerBottomConstraint!)
        view.addConstraint(NSLayoutConstraint(item: bannerView, attribute: .centerX,
            relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))

        view.updateConstraints()

        let request = GADRequest()
        request.testDevices = [kGADSimulatorID/*, "2ce97d5238d2f9678b7256b3a5b6cb10"*/]
        bannerView.load(request)
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        bannerBottomConstraint?.constant = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.view.updateConstraints()
            self.view.layoutIfNeeded()
        }) 
    }
    
    func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        bannerBottomConstraint?.constant = bannerView.bounds.size.height
        UIView.animate(withDuration: 0.3, animations: {
            self.view.updateConstraints()
            self.view.layoutIfNeeded()
        }) 
    }

}
