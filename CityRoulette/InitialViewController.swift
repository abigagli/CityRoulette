//
//  ViewController.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 26/11/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class InitialViewController: UIViewController {
    //MARK:- Constants
    //TODO: MAKE THIS CONFIGURABLE
    let k_radius = 10000.0
    
    //MARK:- Outlets
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var surpriseMe: UIButton!
    @IBOutlet weak var choose: UIButton!
    @IBOutlet weak var aroundMe: UIButton!
    
    @IBOutlet weak var aroundMeTopSpace: NSLayoutConstraint!
    @IBOutlet weak var chooseBottomSpace: NSLayoutConstraint!
    
    //MARK:- Actions
    @IBAction func saveCities (segue: UIStoryboardSegue) {
        CoreDataStackManager.sharedInstance.saveContext()
    }
    
    
    @IBAction func chooseTapped(sender: UIButton) {
        self.hideButtons()
        self.showButtons()
    }
    
    @IBAction func surpriseMeTapped(sender: UIButton) {
        self.springAnimate(sender, repeating: true)
    }
    
    @IBAction func aroundMeTapped(sender: UIButton) {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        self.locationManager.distanceFilter = 3000
        
        switch CLLocationManager.authorizationStatus()
        {
        case .NotDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .AuthorizedAlways:
            fallthrough
        case .AuthorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
        default:
            //Don't want to receive a notification in case the user change settings 
            //while we're in another part of the application...
            self.locationManager.delegate = nil
            self.alertUserWithTitle ("Location unavailable", message: "Please ensure location services are enabled for this application and retry", retryHandler: nil)
        }
    }
    
    //MARK:- State
    private var verticalConstraintConstant: CGFloat = 0
    private var colorImage: UIImageView?
    private lazy var locationManager = CLLocationManager()
    private var busyStatusManager: BusyStatusManager!

    
    //MARK: - UI
    private func hideButtons()
    {
        self.aroundMeTopSpace.constant = 0
        self.surpriseMe.alpha = 0
        self.chooseBottomSpace.constant = 0
        
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
        self.aroundMeTopSpace.constant = self.verticalConstraintConstant
        self.chooseBottomSpace.constant = self.verticalConstraintConstant
        self.surpriseMe.alpha = 1

        UIView.animateWithDuration(1.0) {
            self.view.layoutIfNeeded()
        }
        
        self.springAnimate(self.surpriseMe)
    }
    
    private func fadeColorImage(andThen andThen: ((Bool) -> Void)?) {
        
        UIView.animateWithDuration(4, delay: 0.5, options: .CurveEaseOut, animations: {
            self.colorImage!.alpha = 0.0
            }
            , completion: andThen)
    }
    
    
    //MARK:- Lifetime
    override func prepareForSegue(segue: UIStoryboardSegue, sender dataForNextVC: AnyObject?) {

        super.prepareForSegue (segue, sender: dataForNextVC)

        var destination: UIViewController? = segue.destinationViewController
        
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController
        }
        
        if let citiesInfoVC = destination as? ShowCitiesViewController {
            citiesInfoVC.currentCoreDataContext = dataForNextVC as! NSManagedObjectContext
            citiesInfoVC.radius = self.k_radius
            
            //TODO: REMOVEME
            print ("Scratch Context: \(citiesInfoVC.currentCoreDataContext.registeredObjects.count)")
            print ("Main Context: \(CoreDataStackManager.sharedInstance.managedObjectContext.registeredObjects.count)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.verticalConstraintConstant = self.aroundMeTopSpace.constant
        
        self.colorImage = UIImageView(image: UIImage(named: "Florence"))
        
        self.busyStatusManager = BusyStatusManager(forView: self.view)
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
        
        if let _ = self.colorImage{
            self.fadeColorImage(andThen: {_ in
                self.colorImage!.removeFromSuperview()
                self.colorImage = nil
                self.showButtons()
            })
        }
        else {
            self.showButtons()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let colorImage = self.colorImage where colorImage.superview == nil {
            
            colorImage.contentMode = self.backgroundImage.contentMode
            colorImage.frame = self.backgroundImage.frame
            
            self.view.insertSubview(colorImage, aboveSubview: self.backgroundImage)
        }
    }
    
    //MARK:- Core Data
    func scratchContext() -> NSManagedObjectContext {
        //let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        //context.persistentStoreCoordinator = CoreDataStackManager.sharedInstance.persistentStoreCoordinator
        context.parentContext = CoreDataStackManager.sharedInstance.managedObjectContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

}

//MARK:- Protocol conformance
//MARK: CLLocationManagerDelegate

extension InitialViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.delegate = nil
        manager.stopUpdatingLocation()
        let lastLocation = locations.last!
        
        self.hideButtons()
        self.busyStatusManager.setBusyStatus(true)
        
        let context = self.scratchContext()
        
        GeoNamesClient.sharedInstance.getCitiesAroundLocation(lastLocation.coordinate, withRadius: self.k_radius, andStoreIn: context) /* And then, on another thread...*/ {
            success, error in
            
            dispatch_async(dispatch_get_main_queue()) { //Touch the UI on the main thread only
                self.busyStatusManager.setBusyStatus(false)
                if success {
                    self.performSegueWithIdentifier("showCitiesInfo", sender: context)
                }
                else {
                    self.alertUserWithTitle ("Failed Retrieving Nearby Cities", message: error!.localizedDescription, retryHandler: nil, okHandler: { _ in
                        self.showButtons()
                    })
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        }
        else if status != .NotDetermined {
            //Don't want to receive a notification in case the user change settings 
            //while we're in another part of the application...
            manager.delegate = nil
        }
    }

}


