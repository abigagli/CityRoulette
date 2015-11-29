//
//  ViewController.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 26/11/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController {
    //MARK:- Outlets
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var surpriseMe: UIButton!
    @IBOutlet weak var choose: UIButton!
    @IBOutlet weak var aroundMe: UIButton!
    
    @IBOutlet weak var aroundMeTopSpace: NSLayoutConstraint!
    @IBOutlet weak var chooseBottomSpace: NSLayoutConstraint!
    //MARK:- Actions
    
    @IBAction func chooseTapped(sender: UIButton) {
        self.hideButtons()
        self.showButtons()
    }
    
    @IBAction func surpriseMeTapped(sender: UIButton) {
        self.springAnimate(sender, repeating: true)
    }
    
    //MARK:- State
    private var mustDecolorize = true
    private var verticalConstraintConstant: CGFloat = 0
    
    
    //MARK: - UI
    private func hideButtons()
    {
        self.aroundMeTopSpace.constant -= self.verticalConstraintConstant
        self.surpriseMe.alpha = 0
        self.chooseBottomSpace.constant -= self.verticalConstraintConstant
        self.view.layoutIfNeeded()
    }
    
    private func springAnimate (button: UIButton, repeating: Bool = false)
    {
        UIView.animateWithDuration(0.25, delay: 0, options: [.CurveEaseOut], animations: {
                button.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.50, 0.50), CGAffineTransformMakeRotation(CGFloat(M_PI_2)))
                //button.layer.cornerRadius = 0
                //button.layer.borderWidth = 2

            }, completion: {_ in
                let springBackOptions: UIViewAnimationOptions = repeating ? [.Repeat] : []
                UIView.animateWithDuration(1.0, delay: 0.1, usingSpringWithDamping: 0.20, initialSpringVelocity: 0, options: springBackOptions, animations: {
                    
                    self.surpriseMe.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(1, 1), CGAffineTransformMakeRotation(0))
                    //button.layer.cornerRadius = 30
                    //button.layer.borderWidth = 0
                    
                    }, completion: {_ in
                        delay (seconds: 1, completion: {
                            //self.surpriseMe.layer.speed = 0
                            //self.surpriseMe.layer.timeOffset = CACurrentMediaTime()
                            //self.surpriseMe.layer.removeAllAnimations()
                        })
                    })
            })
        
    }
    
    private func showButtons()
    {
        self.aroundMeTopSpace.constant += self.verticalConstraintConstant
        self.chooseBottomSpace.constant += self.verticalConstraintConstant

        UIView.animateWithDuration(1.0) {
            self.view.layoutIfNeeded()
        }
        
        self.surpriseMe.alpha = 1
        
        self.springAnimate(self.surpriseMe)
    }
    
    private func deColorize() {
        let colorImage = UIImageView(image: UIImage(named: "Florence"))
        colorImage.contentMode = self.backgroundImage.contentMode
        colorImage.frame = self.backgroundImage.frame
        
        view.insertSubview(colorImage, aboveSubview: self.backgroundImage)
        
        UIView.animateWithDuration(4, delay: 0, options: .CurveEaseOut, animations: {
            colorImage.alpha = 0.0
            }, completion: {_ in
                colorImage.removeFromSuperview()
                self.mustDecolorize = false
                self.showButtons()
        })
    }
    
    
    //MARK:- Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.verticalConstraintConstant = self.aroundMeTopSpace.constant
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.hideButtons()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if mustDecolorize {
            self.deColorize()
        }
        else {
            self.showButtons()
        }
    }
}

