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
        bannerView.adUnitID = "ca-app-pub-6130214134299389/8804430959"
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.backgroundColor = UIColor.blueColor()
        
        view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        bannerBottomConstraint = NSLayoutConstraint(item: bannerView, attribute: .Bottom,
                                                    relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 50)
        view.addConstraint(bannerBottomConstraint!)
        view.addConstraint(NSLayoutConstraint(item: bannerView, attribute: .CenterX,
            relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0))
        
        view.updateConstraints()
        
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID]
        bannerView.loadRequest(request)
    }
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        bannerBottomConstraint?.constant = 0
        UIView.animateWithDuration(0.3) {
            self.view.updateConstraints()
            self.view.layoutIfNeeded()
        }
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        bannerBottomConstraint?.constant = bannerView.bounds.size.height
        UIView.animateWithDuration(0.3) {
            self.view.updateConstraints()
            self.view.layoutIfNeeded()
        }
    }

}
