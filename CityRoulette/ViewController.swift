//
//  ViewController.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 26/11/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    //MARK:- Outlets
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    //MARK:- Actions
    
    
    //MARK:- State
    var mustDecolorize = true
    
    private func deColorize() {
        let colorImage = UIImageView(image: UIImage(named: "Florence"))
        colorImage.contentMode = self.backgroundImage.contentMode
        colorImage.frame = self.backgroundImage.frame
        
        view.insertSubview(colorImage, aboveSubview: self.backgroundImage)
        
        UIView.animateWithDuration(5, delay: 0, options: .CurveEaseOut, animations: {
            colorImage.alpha = 0.0
            }, completion: {_ in
                colorImage.removeFromSuperview()
                self.mustDecolorize = false
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //deColorize()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if mustDecolorize {
            deColorize()
        }
    }
}

