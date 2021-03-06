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
    
    //NOTE: This is a bit backward as I would have preferred to define the 
    //enum in this VC as its strings represents the segue identifiers, which
    //are defined in the storyboard's scene for this VC, but for some
    //reason, defining the enum here and typealias-ing it in 
    //the ShowCitiesViewController causes a segmentation fault in the swift compiler
    typealias ShowCitiesMode = ShowCitiesViewController.Mode
    
    //MARK:- Constants
    
    let k_randomAttempts = 4
    
    //Try to add some more randomness by preventing the same country to be
    //chosen for at least k_randomCountryNoRepeatHistory times
    let k_randomCountryNoRepeatHistory = 10
    
    
    //NOTE: These would be ideally configurable, but lacked time to implement
    //a proper UI that would allow the user to drag a circle around current location on
    //a map. So decided to leave as hard-coded defaults for now
    let k_radius = 10000.0
    let k_maxImportAtOnce = 30
    
    
    
    //MARK:- Outlets
    
    @IBOutlet weak var authorView: UIView!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var surpriseMeButton: UIButton!
    @IBOutlet weak var browseButton: UIButton!
    @IBOutlet weak var aroundMeButton: UIButton!
    
    @IBOutlet weak var aroundMeTopSpace: NSLayoutConstraint!
    @IBOutlet weak var browseBottomSpace: NSLayoutConstraint!
    
    //MARK:- Actions
    @IBAction func unwindFromSave (_ segue: UIStoryboardSegue) {
        CoreDataStackManager.sharedInstance.saveContext()
        self.acquireID = 0
    }
    
    @IBAction func unwindFromCancel (_ segue: UIStoryboardSegue) {
        self.acquireID = 0
    }
    
    @IBAction func browseTapped(_ sender: UIButton) {
        self.hideButtons()
        
        self.performSegue(withIdentifier: ShowCitiesMode.browseArchivedCities.rawValue, sender: CoreDataStackManager.sharedInstance.managedObjectContext)
    }
    
    @IBAction func surpriseMeTapped(_ sender: UIButton) {
        
        //self.springAnimate(sender, repeating: true)
        
        self.hideButtons()
        self.busyStatusManager.setBusyStatus(true)
        
        let importingContext = self.scratchContext()
        
        if let randomLocation = self.randomLocation {
            //We already were able to choose a random location,
            //let's go and pick up some cites...
            self.importCitiesAroundLocation (randomLocation, intoContext: importingContext, randomAttempts: self.k_randomAttempts)
        }
        else {
            //Info for all countries hasn't yet been downloaded.
            //Let's call the API and store into the main context, as this info has to be persisted for sure
            GeoNamesClient.sharedInstance.getCountryInfo (nil, andStoreIn: CoreDataStackManager.sharedInstance.managedObjectContext) /* And then, on another thread...*/ {
                success, error in
                
                DispatchQueue.main.async { //Touch the UI on the main thread only
                    
                    if success {
                        
                        //Persist the main context to save all the country info we got from the API
                        CoreDataStackManager.sharedInstance.saveContext()
                        
                        //With all the info succesfully retrieved from the API, we know
                        //we can finally pick up some random city, and let the process repeat 
                        //for a certain amount of attempts, as the random coordinate might
                        //fall where there are no cities around...
                        self.importCitiesAroundLocation (self.randomLocation!, intoContext: importingContext, randomAttempts: self.k_randomAttempts)
                        
                    }
                    else {
                        self.alertUserWithTitle ("Failed Retrieving Countries", message: error!.localizedDescription, retryHandler: nil, okHandler: { _ in
                            self.busyStatusManager.setBusyStatus(false)
                            self.showButtons()
                            })
                    }
                }
            }
        }
    }
    
    
    @IBAction func aroundMeTapped(_ sender: UIButton) {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        self.locationManager.distanceFilter = 3000
        
        switch CLLocationManager.authorizationStatus()
        {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            fallthrough
        case .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
        default:
            //Don't want to receive a notification in case the user change settings 
            //while we're in another part of the application...
            self.locationManager.delegate = nil
            self.alertUserWithTitle ("Location unavailable", message: "Please ensure location services are enabled for this application and retry", retryHandler: nil)
        }
    }
    
    //MARK:- State
    fileprivate var verticalConstraintConstant: CGFloat = 0
    fileprivate var colorImage: UIImageView?
    fileprivate lazy var locationManager = CLLocationManager()
    fileprivate var busyStatusManager: BusyStatusManager!
    fileprivate var acquireID: Int64 = 0
    fileprivate var countries = [Country]()
    
    fileprivate lazy var countryHistoryFilePath: String = {
        let url = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
        return url.appendingPathComponent("countryHistory").path
    }()

    fileprivate var randomCountriesHistory = [String]()
    
    fileprivate var randomLocation: CLLocation? {
        if self.countries.count == 0 {
            self.countries = self.fetchAllCountries()
        }
        
        let numCountries = UInt32(self.countries.count)
        
        guard numCountries >= 1 else {return nil}
        
        var randomCountry: Country
        
        //Keep choosing a random country if its countryName is for whatever reason empty
        //or it has been already chosen in the previous k_randomCountryNoRepeatHistory attempts
        repeat {
            randomCountry = self.countries[Int(arc4random_uniform (numCountries))]
        } while (randomCountry.countryCode == "")
             || (self.randomCountriesHistory.contains(randomCountry.countryCode))
        
        self.randomCountriesHistory.append(randomCountry.countryCode)
        
        if self.randomCountriesHistory.count > self.k_randomCountryNoRepeatHistory {
            self.randomCountriesHistory.remove(at: 0)
        }
        
        self.saveCountryHistory()
        
        let minLat = randomCountry.south
        let maxLat = randomCountry.north
        let minLong = randomCountry.west
        let maxLong = randomCountry.east
        
        
        let randomLat = Double.random(min: minLat, max: maxLat)
        let randomLong = Double.random(min: minLong, max: maxLong)
        
        return CLLocation(latitude: randomLat, longitude: randomLong)
    }
    

    //MARK:- UI
    fileprivate func hideButtons()
    {
        self.aroundMeTopSpace.constant = 0
        self.surpriseMeButton.alpha = 0
        self.browseBottomSpace.constant = 0
        
        self.view.layoutIfNeeded()
    }
    
    fileprivate func springAnimate (_ button: UIButton, repeating: Bool = false)
    {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: {
                button.transform = CGAffineTransform(scaleX: 0.50, y: 0.50).concatenating(CGAffineTransform(rotationAngle: CGFloat(M_PI_2)))
                //button.layer.cornerRadius = 0
                //button.layer.borderWidth = 2

            }, completion: {_ in
                let springBackOptions: UIViewAnimationOptions = repeating ? [.repeat] : []
                UIView.animate(withDuration: 1.0, delay: 0.1, usingSpringWithDamping: 0.20, initialSpringVelocity: 0, options: springBackOptions, animations: {
                    
                    button.transform = CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(rotationAngle: 0))
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
    
    fileprivate func showButtons()
    {
        self.aroundMeTopSpace.constant = self.verticalConstraintConstant
        self.browseBottomSpace.constant = self.verticalConstraintConstant
        self.surpriseMeButton.alpha = 1

        UIView.animate(withDuration: 1.0, animations: {
            self.view.layoutIfNeeded()
        }) 
        
        self.springAnimate(self.surpriseMeButton)
    }
    
    fileprivate func fadeColorImage(andThen: ((Bool) -> Void)?) {
        
        UIView.animate(withDuration: 4, delay: 0.5, options: .curveEaseOut, animations: {
            self.colorImage!.alpha = 0.0
            }
            , completion: andThen)
    }
    
    
    //MARK:- Lifetime
    override func prepare(for segue: UIStoryboardSegue, sender dataForNextVC: Any?) {

        super.prepare (for: segue, sender: dataForNextVC)

        
        //Make sure we can reach into ShowCitiesViewController regardless
        //of it being contained in a navigation controller or not
        var destination: UIViewController? = segue.destination
        
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController
        }
        
        
        
        if let citiesInfoVC = destination as? ShowCitiesViewController {
            
            //Configure destination viewcontroller
            citiesInfoVC.currentCoreDataContext = dataForNextVC as! NSManagedObjectContext
            citiesInfoVC.acquireID = self.acquireID
            citiesInfoVC.radius = self.k_radius
            
            
            //I do really like how mapping segue identifiers' strings to enum values
            //allows me to safely and easily determine the operating mode of the destination viewcontroller....
            citiesInfoVC.operatingMode = ShowCitiesMode(rawValue: segue.identifier!)!
            
            
            //print ("Scratch Context: \(citiesInfoVC.currentCoreDataContext.registeredObjects.count)")
            //print ("Main Context: \(CoreDataStackManager.sharedInstance.managedObjectContext.registeredObjects.count)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.verticalConstraintConstant = self.aroundMeTopSpace.constant
        
        self.colorImage = UIImageView(image: UIImage(named: "Florence"))
        
        self.busyStatusManager = BusyStatusManager(forView: self.view)
        
        self.loadCountryHistory()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult> (entityName: "City")
        
        if let n = try? CoreDataStackManager.sharedInstance.managedObjectContext.count(for: fetchRequest), n > 0 {
        
        self.browseButton.setTitle("Browse \(n) archived cities", for: UIControlState())
        self.browseButton.isHidden = false
        }
        else {
            self.browseButton.isHidden = true
        }
        self.hideButtons()
        self.busyStatusManager.setBusyStatus(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let _ = self.colorImage{
            self.fadeColorImage(andThen: {_ in
                self.colorImage!.removeFromSuperview()
                self.colorImage = nil
                self.authorView.isHidden = true
                self.showButtons()
            })
        }
        else {
            self.showButtons()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.locationManager.delegate = nil
        self.locationManager.stopUpdatingLocation()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let colorImage = self.colorImage, colorImage.superview == nil {
            
            colorImage.contentMode = self.backgroundImage.contentMode
            colorImage.frame = self.backgroundImage.frame
            
            self.view.insertSubview(colorImage, aboveSubview: self.backgroundImage)
        }
    }
    
    
    //MARK:- Business Logic
    
    fileprivate func importCitiesAroundLocation (_ location: CLLocation, intoContext importingContext: NSManagedObjectContext, randomAttempts: Int?) {
        
        GeoNamesClient.sharedInstance.getCitiesAroundLocation(location.coordinate, withRadius: self.k_radius, maxResults:self.k_maxImportAtOnce, andStoreIn: importingContext) /* And then, on another thread...*/ {
            acquireID, error in
            
            DispatchQueue.main.async { //Touch the UI on the main thread only
                if acquireID > 0 {
                    self.acquireID = acquireID
                    
                    let segueIdentifier: String
                    
                    if let _ = randomAttempts {
                        segueIdentifier = ShowCitiesMode.importFromRandomLocation.rawValue
                    }
                    else {
                        segueIdentifier = ShowCitiesMode.importFromCurrentLocation.rawValue
                    }
                    
                    self.performSegue(withIdentifier: segueIdentifier, sender: importingContext)
                }
                else {
                    //Couldn't find cities around this location.
                    //If this is a random search, let's do some additional attempts
                    if let randomAttempts = randomAttempts, randomAttempts > 0 {
                        self.importCitiesAroundLocation(self.randomLocation!, intoContext: importingContext, randomAttempts: randomAttempts - 1)
                    }
                    else {
                        self.alertUserWithTitle ("Failed Retrieving Nearby Cities", message: error!.localizedDescription, retryHandler: nil, okHandler: {_ in
                            self.busyStatusManager.setBusyStatus(false)
                            self.showButtons()
                        })
                    }
                }
            }
        }
    }

    fileprivate func saveCountryHistory() {
        NSKeyedArchiver.archiveRootObject(self.randomCountriesHistory, toFile: self.countryHistoryFilePath)
    }

    fileprivate func loadCountryHistory() {
        if let savedCountries = NSKeyedUnarchiver.unarchiveObject(withFile: self.countryHistoryFilePath) as? [String] {
            self.randomCountriesHistory = savedCountries
        }
    }
    
    
    
    //MARK:- Core Data
    
    //When importing, we use a sort of "scratch" context which is a child of the main coredata
    //context, so that we can be more flexible in case we just want to discard everything during
    //the import phase.
    //Only if the user decides to import, then the contents of this child scratch context are pushed
    //up into the main one
    fileprivate func scratchContext() -> NSManagedObjectContext {
        //let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        //context.persistentStoreCoordinator = CoreDataStackManager.sharedInstance.persistentStoreCoordinator
        context.parent = CoreDataStackManager.sharedInstance.managedObjectContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        //context.undoManager = nil
        return context
    }
    
    fileprivate func fetchAllCountries() -> [Country] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Country")
        do {
            return try CoreDataStackManager.sharedInstance.managedObjectContext.fetch(fetchRequest) as! [Country]
        }
        catch let error as NSError {
            self.alertUserWithTitle("Error"
                                    , message: error.localizedDescription
                                    , retryHandler: nil)
        }
        
        return [Country]()
    }
    
}

//MARK:- Protocol conformance
//MARK: CLLocationManagerDelegate

extension InitialViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.delegate = nil
        manager.stopUpdatingLocation()
        let lastLocation = locations.last!
        
        self.hideButtons()
        self.busyStatusManager.setBusyStatus(true)
        
       
        let importingContext = self.scratchContext()
        
        self.importCitiesAroundLocation(lastLocation, intoContext: importingContext, randomAttempts: nil)
    }
    
    func locationManager(_ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus)
    {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
        else if status != .notDetermined {
            //Don't want to receive a notification in case the user change settings 
            //while we're in another part of the application...
            manager.delegate = nil
        }
    }

}

