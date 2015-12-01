//
//  ShowCitiesViewController.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 29/11/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ShowCitiesViewController: UIViewController {

    enum SourceType {
        case coordinates (CLLocationCoordinate2D)
        case city (String)
        
    }
    
    var referenceCity: SourceType!
    
    //MARK:- Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK:- Actions
    @IBAction func doneTapped(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK:- State
    
    //MARK:- Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView.delegate = self
        self.mapView.userInteractionEnabled = false
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        //self.fetchedResultsController.delegate = self

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        populateData()
        updateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Core Data
    private var sharedContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        
        //create fetch request with sort descriptor
        let fetchRequest = NSFetchRequest(entityName: "CityInfo")
        //fetchRequest.predicate = NSPredicate(format: "mapPin == %@", self.pin)
        fetchRequest.sortDescriptors = []
        
        //create controller from fetch request
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        //fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    //MARK:- Business Logic
    
    private func updateUI() {
        
    }
    
    private func populateData() {
        
        self.activityIndicator.startAnimating()
        switch self.referenceCity! {
        case let .coordinates (location):
        GeoNamesClient.sharedInstance.getCitiesAroundLocation(location) /* And then, on another thread...*/ {
            success, error in
            
            dispatch_async(dispatch_get_main_queue()) { //Touch the UI on the main thread only
                self.activityIndicator.stopAnimating()
                if success {
                    print ("Got some cities")
                }
                else {
                    self.alertUserWithTitle ("Failed Retrieving Nearby Cities", message: error!.localizedDescription, retryHandler: nil)
                }
            }
        }
        default:
            ()
        }
    }
}
//MARK:- Protocol Conformance

//MARK: MKMapViewDelegate
extension ShowCitiesViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "travelLocationPin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = UIColor.greenColor()
            
            pinView!.animatesDrop = false
            
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
}

//MARK: UITableViewDataSource, UITableViewDelegate
extension ShowCitiesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cityInfoCell", forIndexPath: indexPath)

        cell.textLabel?.text = "text"

        cell.detailTextLabel?.text = "detail"
        
        return cell
    }
    
}

//MARK: NSFetchedResultsControllerDelegate
extension ShowCitiesViewController: NSFetchedResultsControllerDelegate {

}
