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
    
    //MARK:- Actions
    @IBAction func doneTapped(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK:- State
    var radius: Double!

    //MARK:- Lifetime
    override func prepareForSegue(segue: UIStoryboardSegue, sender dataForNextVC: AnyObject?) {
        var destination: UIViewController? = segue.destinationViewController
        
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController
        }
        
        if let wikiVC = destination as? WikiViewController {
            wikiVC.city = dataForNextVC as! City
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.mapView.delegate = self
        //self.mapView.userInteractionEnabled = false
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        
        self.fetchedResultsController.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
            
            var topCity: City?
            for city in self.fetchedResultsController.fetchedObjects as! [City] {
                self.mapView.addAnnotation(city)
            
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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)
    }

    //MARK: Core Data
    private var sharedContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        
        //create fetch request with sort descriptor
        let fetchRequest = NSFetchRequest(entityName: "City")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "population", ascending: false)]
        
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
            self.sharedContext.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            
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
    }
    
    
}
