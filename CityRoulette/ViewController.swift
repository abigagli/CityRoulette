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
    
    private func deColorize() {
        let desatImage = UIImageView(image: UIImage(named: "Florence-desat"))
        desatImage.contentMode = self.backgroundImage.contentMode
        desatImage.frame = self.backgroundImage.frame
        
        view.insertSubview(desatImage, belowSubview: self.backgroundImage)
        
        UIView.animateWithDuration(5, delay: 0.5, options: .CurveEaseOut, animations: {
            self.backgroundImage.alpha = 0.0
            }, completion: {_ in
                self.backgroundImage.removeFromSuperview()
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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        deColorize()
    }
}

