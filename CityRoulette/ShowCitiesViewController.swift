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

    
    //MARK:- Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK:- State
    //TODO: Remove if using dynamic radius
    var radius: Double!
    var currentCoreDataContext: NSManagedObjectContext!
    var acquireID: Int64 = 0
    
    //MARK:- UI
    private func updateUI() {
        if (self.fetchedResultsController.fetchedObjects?.count ?? 0) > 0 {
            self.navigationItem.rightBarButtonItem!.enabled = true
        }
        else {
            super.setEditing(false, animated: true)
            self.navigationItem.rightBarButtonItem!.enabled = false
        }
        self.navigationItem.leftBarButtonItem!.enabled = !self.editing
    }
    

    //MARK:- Lifetime
    override func prepareForSegue(segue: UIStoryboardSegue, sender dataForNextVC: AnyObject?) {
        
        super.prepareForSegue(segue, sender: dataForNextVC)
        
        var destination: UIViewController? = segue.destinationViewController

        if segue.identifier == "showWiki" {
            
            //Be nice and do the right thing regardless the destination being embedded in
            //a navigation controller or not
            if let navCon = destination as? UINavigationController {
                destination = navCon.visibleViewController
            }
            
            if let wikiVC = destination as? WikiViewController {
                wikiVC.city = dataForNextVC as! City
            }
        }
        else if segue.identifier == "returnToInitialVC" {
            
            if self.currentCoreDataContext.hasChanges {
                do {
                    //Severe our connection with the fetchedResultsController to avoid
                    //receiving notifications due to potential conflicts being resolved while saving
                    //as we are segue-ing away
                    self.fetchedResultsController.delegate = nil
                    
                    try self.currentCoreDataContext.save()
                    
                } catch {
                    let nserror = error as NSError
                    
                    self.alertUserWithTitle("Error saving cities"
                        , message: nserror.localizedDescription
                        , retryHandler: nil)

                }
            }
            //TODO: REMOVEME
            print ("Scratch Context After: \(self.currentCoreDataContext.registeredObjects.count)")
            print ("Main Context: \(CoreDataStackManager.sharedInstance.managedObjectContext.registeredObjects.count)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.mapView.delegate = self
        self.mapView.showsCompass = true
        //self.mapView.tintAdjustmentMode = .Normal

        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        
        self.fetchedResultsController.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
            
            var topCity: City?
            for city in self.fetchedResultsController.fetchedObjects as! [City] {
                self.mapView.addAnnotation(city)
            
                //self.mapView.showAnnotations(self.mapView.annotations, animated: true)
                
                if topCity == nil {
                    topCity = city
                    let region = MKCoordinateRegionMakeWithDistance(topCity!.coordinate, self.radius * 1.1, self.radius * 1.1)
                    
                    self.mapView.setRegion(region, animated: false)
                }
            }
        }
        catch {
            self.alertUserWithTitle("Error"
                                    , message: "Failed to retrieve list of cities"
                                    , retryHandler: nil)
        }

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateUI()
    }

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)
        updateUI()
    }

    //MARK: Core Data
    //TODO: REMOVEME?
    /*
    private var sharedContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    */
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        
        //create fetch request with sort descriptor
        let fetchRequest = NSFetchRequest(entityName: "City")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "population", ascending: false)]
        
        if self.acquireID > 0 {
            fetchRequest.predicate = NSPredicate(format: "acquireID == %lld", self.acquireID)
        }
        
        //create controller from fetch request
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.currentCoreDataContext, sectionNameKeyPath: nil, cacheName: nil)
        
        //fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
}
//MARK:- Protocol Conformance

//MARK: MKMapViewDelegate
extension ShowCitiesViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
                return nil
        }
        
        let reuseId = "cityPin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.animatesDrop = false
            pinView!.canShowCallout = true
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
        
        cell.textLabel?.text = city.name + "  " + (city.countryCode ?? "")
        cell.detailTextLabel?.text = "Population: \(city.population)"
        
        if let wikipedia = city.wikipedia where !wikipedia.isEmpty {
            cell.accessoryType = .DetailDisclosureButton
        }
        else {
            cell.accessoryType = .None
        }
        

        return cell
    }
    
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        //TODO: REMOVEME
        print ("accessory button tapped")
        self.performSegueWithIdentifier("showWiki", sender: self.fetchedResultsController.objectAtIndexPath(indexPath))
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !editing {
            //TODO: REMOVEME AFTER SYNCING WITH MAPVIEW
            print ("row tapped")
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            self.currentCoreDataContext.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            
        }
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
            self.mapView.addAnnotation(anObject as! MKAnnotation)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            self.mapView.removeAnnotation(anObject as! MKAnnotation)
        default:
            return
        }
    }
    
    // When endUpdates() is invoked, the table makes the changes visible.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
        self.updateUI()
        
        //print ("Scratch Context: \(self.currentCoreDataContext.registeredObjects.count)")
        //print ("Main Context: \(CoreDataStackManager.sharedInstance.managedObjectContext.registeredObjects.count)")
    }
    
    
}
