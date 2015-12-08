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
        
        self.fetchedResultsController.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
            
            /*
            //Update mapView based on the user's pin.
            self.mapView.addAnnotation(pin)
            
            let region = MKCoordinateRegionMakeWithDistance(pin.coordinate, PhotoAlbumViewController.miniMapSpanMeters, PhotoAlbumViewController.miniMapSpanMeters)
            
            self.mapView.setRegion(region, animated: false)
            */
            
        }
        catch {
            self.alertUserWithTitle("Error"
                                    , message: "Couldn't obtain list of photos for this pin. Please try to remove it and add it again"
                                    , retryHandler: nil)
        }

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        /*
        let region = MKCoordinateRegionMakeWithDistance(self.referenceCity.coordinates, 10000.0, 10000.0)
        
        self.mapView.setRegion(region, animated: false)
        */
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
        let fetchRequest = NSFetchRequest(entityName: "City")
        //fetchRequest.predicate = NSPredicate(format: "mapPin == %@", self.pin)
        fetchRequest.sortDescriptors = []
        
        //create controller from fetch request
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        //fetchedResultsController.delegate = self
        return fetchedResultsController
    }()


    //MARK:- Business Logic
    
    private func updateUI() {
        
    }
    
}
//MARK:- Protocol Conformance

//MARK: MKMapViewDelegate
extension ShowCitiesViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "cityPin"
        
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections!.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections![section].numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cityInfoCell", forIndexPath: indexPath)

        let city = fetchedResultsController.objectAtIndexPath(indexPath) as! City
        cell.textLabel?.text = city.name + (city.parent != nil ? "" : " ROOT")

        cell.detailTextLabel?.text = city.wikipedia
        
        return cell
    }
    
}

//MARK: NSFetchedResultsControllerDelegate
extension ShowCitiesViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // This invocation prepares the table to recieve a number of changes. It will store them up
        // until it receives endUpdates(), and then perform them all at once.
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    // When endUpdates() is invoked, the table makes the changes visible.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    
}
