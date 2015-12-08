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
class BusyStatusManager {
    
    private var interactionDisabled = false
    private var activityIndicatorEnhancer: UIView!
    private var activityIndicator: UIActivityIndicatorView!
    private unowned var managedView: UIView
    
    //Using lazy initialization here is a bit overkill, but conceptually I think this
    //is the correct thing to do given that in this application the geometry of views cannot change
    //once they appear on screen (no rotation/transformation is ever performed) and hence
    //it shouldn't be necessary to re-evaluate the frame geometry every time we go into busy mode.
    //So, also test my understanding of lazy stored properties, I've used a "called-when-declared" closure whose
    //return value is the frame we need, and that has the nice side effect to call addSubview, which we can
    //do since we're guaranteed this will be called only once
    //Of course it would be much easier if we could do these thing in viewDidLoad, but I'm quite sure
    //working with view geometry there is not the right thing to do...
    private lazy var managedViewFrame: CGRect = {
        self.managedView.addSubview(self.activityIndicatorEnhancer)
        return CGRectMake(0, 0, CGRectGetWidth(self.managedView.bounds), CGRectGetHeight(self.managedView.bounds))
    }()
    
    
    init (forView view: UIView) {
        self.activityIndicatorEnhancer = UIView()
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        self.activityIndicatorEnhancer.addSubview(self.activityIndicator)
        self.activityIndicatorEnhancer.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.5)
        self.activityIndicatorEnhancer.hidden = true
        managedView = view
    }
    
    func setBusyStatus(busy: Bool, disableUserInteraction: Bool = false) {
        
        if busy {
            self.activityIndicatorEnhancer.frame = self.managedViewFrame //Let lazy property do the magic...
            self.activityIndicator.center = self.activityIndicatorEnhancer.center
        
            self.activityIndicatorEnhancer.hidden = false
            self.activityIndicator.startAnimating()
            if disableUserInteraction {
                UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                interactionDisabled = true
            }
        } else {
            self.activityIndicator.stopAnimating()
            self.activityIndicatorEnhancer.hidden = true
            //Of course when disabling busy status, the passed in disableUseInterface argument is a don't care, and we just revert if/what we have done wrt user interactions when setting busy to true
            if interactionDisabled {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                interactionDisabled = false
            }
        }
    }
}

extension UIViewController {
    func alertUserWithTitle(title: String, message: String, retryHandler: (()->Void)?, okHandler: ((UIAlertAction) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title,
            message: message,
            preferredStyle: .Alert)
        
        let alertOkAction = UIAlertAction(title: "OK",
            style: .Default,
            handler: okHandler)
        
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


