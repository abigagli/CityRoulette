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
    @IBOutlet weak var deleteUnfavoritesButton: UIBarButtonItem!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    
    //MARK:- Actions
    @IBAction func deleteUnfavoritesTapped(sender: UIBarButtonItem) {
        for city in self.fetchedResultsController.fetchedObjects as! [City] {
            if !city.favorite {
                self.currentCoreDataContext.deleteObject(city)
                self.numUnfavorites--
            }
        }
        self.updateUI()
    }
    
    //MARK:- State
    //TODO: Remove if using dynamic radius
    var radius: Double!
    var currentCoreDataContext: NSManagedObjectContext!
    var acquireID: Int64 = 0
    private var numUnfavorites: Int = 0
    

    //MARK:- UI
    private func showBottomToolbar(show: Bool) {
    
        if show == true {
            self.toolbarBottomConstraint.constant = 0
        }
        else {
            self.toolbarBottomConstraint.constant = -self.toolbar.frame.height
        }
        
        UIView.animateWithDuration(0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateUI() {
        if (self.fetchedResultsController.fetchedObjects?.count ?? 0) > 0 {
            self.navigationItem.rightBarButtonItem!.enabled = true
            self.deleteUnfavoritesButton.enabled = self.numUnfavorites > 0
        }
        else {
            super.setEditing(false, animated: true)
            self.navigationItem.rightBarButtonItem!.enabled = false
            self.deleteUnfavoritesButton.enabled = false
        }
        
        self.saveBarButton.enabled = self.currentCoreDataContext.hasChanges && !self.editing
        self.cancelBarButton.enabled = !self.editing
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
        else if segue.identifier == "saveAndReturnToInitialVC" {
            
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
        else if segue.identifier == "exitToInitialVC" {
           self.currentCoreDataContext.reset()
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
                
                if !city.favorite {
                    self.numUnfavorites++
                }
                
                //Just set the map to show the first city in the center
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
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.toolbarBottomConstraint.constant = -self.toolbar.frame.height

        updateUI()
    }

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)
        self.showBottomToolbar(self.editing)
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
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "favorite", ascending: false), NSSortDescriptor(key: "population", ascending: false)]
        
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
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let city = view.annotation as! City

        let indexPath = self.fetchedResultsController.indexPathForObject(city)
        self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Middle)
        
        delay(seconds: 2) {
            mapView.deselectAnnotation(view.annotation, animated: true)
            self.tableView.deselectRowAtIndexPath(indexPath!, animated: true)
        }
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cityInfoCell", forIndexPath: indexPath) as! CityTableViewCell

        let city = fetchedResultsController.objectAtIndexPath(indexPath) as! City
        
        cell.nameLabel.text = city.name + "  " + (city.countryCode ?? "")
        cell.delegate = self
        cell.favoriteButton.isFavorite = city.favorite
        
        if let wikipedia = city.wikipedia where !wikipedia.isEmpty {
            cell.accessoryType = .DetailButton
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
        let city = fetchedResultsController.objectAtIndexPath(indexPath) as! City
        self.mapView.selectAnnotation(city, animated: true)
        
        delay(seconds: 2) {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            self.mapView.deselectAnnotation(city, animated: true)
        }
    }
    
    /*
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let city = fetchedResultsController.objectAtIndexPath(indexPath) as! City
        self.mapView.deselectAnnotation(city, animated: false)
    }
    */
    
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
        case .Move:
            self.tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        default:
            return
        }
    }
    
    // When endUpdates() is invoked, the table makes the changes visible.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
        self.updateUI()
    }
    
    
}

extension ShowCitiesViewController: CityTableViewCellDelegate {
    func favoriteButtonTapped(sender: FavoritedUIButton, cell: CityTableViewCell) {
        let indexPath = self.tableView.indexPathForCell (cell)
        let city = self.fetchedResultsController.objectAtIndexPath(indexPath!) as! City
        
        if sender.isFavorite {
            self.numUnfavorites--
        }
        else {
            self.numUnfavorites++
        }
        
        city.favorite = sender.isFavorite
    }
}
