//
//  Utils.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 28/11/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//
import UIKit

func delay(seconds seconds: Double, completion:()->()) {
    let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64( Double(NSEC_PER_SEC) * seconds ))
    
    dispatch_after(popTime, dispatch_get_main_queue()) {
        completion()
    }
}


extension UIViewController {
    func alertUserWithTitle(title: String, message: String, retryHandler: (()->Void)?) {
        
        let alert = UIAlertController(title: title,
            message: message,
            preferredStyle: .Alert)
        
        let alertOkAction = UIAlertAction(title: "OK",
            style: .Default,
            handler: nil)
        
        if let userRetry = retryHandler {
            
            let alertRetryAction = UIAlertAction(title: "Retry",
                style: UIAlertActionStyle.Destructive,
                handler: {
                    _ in
                    userRetry()
            })
            alert.addAction(alertRetryAction)
        }
        
        alert.addAction(alertOkAction)
        
        //Ensure presentation is always done by a visible viewcontroller, since with
        //particularly slow network connections, the user might have pushed/popped
        //before the alert is presented
        self.presentViewController(alert, animated: true, completion: nil)
    }
}


