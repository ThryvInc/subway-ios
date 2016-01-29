//
//  LineCoiceView.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 11/4/15.
//  Copyright © 2015 Thryv. All rights reserved.
//

import UIKit

protocol LineChoiceViewDelegate {
    func didSelectLineWithColor(color: UIColor)
    func didDeselectLineWithColor(color: UIColor)
}

class LineChoiceView: UIView {
    var delegate: LineChoiceViewDelegate?
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var backgroundView: UILabel!
    @IBOutlet weak var dotImageView: UIImageView!
    @IBOutlet weak var lineLabel: UILabel!
    private var _isSelected: Bool = false
    var isSelected: Bool {
        set(shouldBeSelected) {
            _isSelected = shouldBeSelected
            setupView()
        }
        get {
            return _isSelected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupXib()
    }
    
    func setupXib(){
        NSBundle.mainBundle().loadNibNamed("LineChoiceView", owner: self, options: nil)
        addSubview(self.view)
        
        translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view]-0-|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["view" : view]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[view]-0-|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["view" : view]))
        
        clipsToBounds = true
        view.clipsToBounds = true
        
        setupView()
    }
    
    func setupView(){
        if isSelected {
            lineLabel.textColor = UIColor.darkGrayColor()
            
            backgroundView.layer.borderWidth = 0
            backgroundView.backgroundColor = UIColor.whiteColor()
        }else{
            lineLabel.textColor = UIColor.whiteColor()
            
            backgroundView.layer.borderColor = UIColor.lightGrayColor().CGColor
            backgroundView.layer.borderWidth = 2
            backgroundView.layer.cornerRadius = view.bounds.size.height / 2
            backgroundView.backgroundColor = UIColor.clearColor()
        }
        backgroundView.clipsToBounds = true
    }
    
    @IBAction func toggleSelectedPressed() {
        isSelected = !isSelected
        if isSelected {
            delegate?.didSelectLineWithColor(dotImageView.tintColor)
        }else{
            delegate?.didDeselectLineWithColor(dotImageView.tintColor)
        }
    }
}
