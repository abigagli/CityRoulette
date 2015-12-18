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
    
    //MARK:- Segues
    enum SegueFromHere: String {
        case showWiki = "showKiki"
        case saveAndReturnToInitialVC = "saveAndReturnToInitialVC"
        case exitToInitialVC = "exitToInitialVC"
    }

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
            }
        }
    }
    
    //MARK:- State
    //TODO: Remove if using dynamic radius
    var radius: Double!
    var currentCoreDataContext: NSManagedObjectContext!
    var acquireID: Int64 = 0
    private var numUnfavorites: Int = 0
    private let searchController = UISearchController(searchResultsController: nil)
    
    //MARK: Operating mode
    //This VC is (re-)used for three different purposes,
    //So we'd better be sure in which mode we're operating to adjust
    //some behaviours
    //NOTE: The associated string values are the segue identifiers
    //that lead here, and so it would probably make more sense to define this enum 
    //in the InitialViewController (i.e. in the VC the segues originate from)
    //but see my other NOTE there at the top of the file
    //tl;dr doing in that way causes the swift compiler to crash
    enum Mode: String {
        case importFromCurrentLocation = "importFromCurrentLocation"
        case importFromRandomLocation = "importFromRandomLocation"
        case browseArchivedCities = "browseArchivedCities"
    }
    var operatingMode: Mode!
    
    var isImportingFromCurrentLocation: Bool {
        return self.operatingMode == .importFromCurrentLocation
    }
    var isImportingFromRandomLocation: Bool {
        return self.operatingMode == .importFromRandomLocation
    }
    
    var isImporting: Bool {
        return self.isImportingFromCurrentLocation || self.isImportingFromRandomLocation
    }
    var isBrowsing: Bool {
        return self.operatingMode == .browseArchivedCities
    }
    
    
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
    
    //Need to factor some parts of edit-mode transitioning logic in a separate
    //function that can be called by different places
    private func setVCEditingMode (editing: Bool, animated: Bool)
    {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)
        self.showBottomToolbar(self.editing)
    }
    
    private func updateUI() {
        var recordsToSave = false
        if (self.fetchedResultsController.fetchedObjects?.count ?? 0) > 0 {
            recordsToSave = true
            self.navigationItem.rightBarButtonItem!.enabled = true
            self.deleteUnfavoritesButton.enabled = self.numUnfavorites > 0
        }
        else {
            self.setVCEditingMode(false, animated: true)
            self.navigationItem.rightBarButtonItem!.enabled = false
            //self.deleteUnfavoritesButton.enabled = false
        }
        
        //We only want to enable the save/import button if 
        //1) We are not editing 
        //   AND
        //      2) either we are browsing and we made some changes
        //         OR
        //         we are importing and there are some records to import
        if (!self.editing && (self.isBrowsing && self.currentCoreDataContext.hasChanges ||
                              self.isImporting && recordsToSave)) {
            self.saveBarButton.enabled = true
        }
        else {
            self.saveBarButton.enabled = false
        }
        
        self.cancelBarButton.enabled = !self.editing
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        self.setVCEditingMode(editing, animated: animated)
        updateUI()
    }

    //MARK:- Lifetime
    override func prepareForSegue(segue: UIStoryboardSegue, sender dataForNextVC: AnyObject?) {
        
        super.prepareForSegue(segue, sender: dataForNextVC)
        
        var destination: UIViewController? = segue.destinationViewController

        switch SegueFromHere (rawValue: segue.identifier!) {
        
        case .showWiki?:
            //Be nice and do the right thing regardless the destination being embedded in
            //a navigation controller or not
            if let navCon = destination as? UINavigationController {
                destination = navCon.visibleViewController
            }
            
            if let wikiVC = destination as? WikiViewController {
                wikiVC.city = dataForNextVC as! City
            }
            
        case .saveAndReturnToInitialVC?:
            
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
            
        case .exitToInitialVC?:
           self.currentCoreDataContext.reset()
            
        case nil:
            fatalError ("Unexpected segue identifier: \(segue.identifier)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if self.isBrowsing{
            self.saveBarButton.title = "Save"
        }
        else {
            self.saveBarButton.title = "Import"
        }
        
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
        catch let error as NSError {
            self.alertUserWithTitle("Error"
                                    , message: error.localizedDescription
                                    , retryHandler: nil)
        }
        
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.definesPresentationContext = true
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.searchController.searchBar.scopeButtonTitles = ["All", "Favorites", "Unfavorites"]
        self.searchController.searchBar.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.toolbarBottomConstraint.constant = -self.toolbar.frame.height

        updateUI()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    deinit {
        //Apparently there's a bug that causes a 
        //"Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior (<UISearchController: 0x7f9acb000380>)"
        //warning if, when dismissing the current viewcontroller, UISearchController has
        //not yet loaded its view.
        //The following (new in iOS9) API call, will ensure UISearchController has its view
        //loaded when we're being dismissed
        self.searchController.loadViewIfNeeded()
    }
    
    //MARK:- Core Data
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        
        //create fetch request with sort descriptor
        let fetchRequest = NSFetchRequest(entityName: "City")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "favorite", ascending: false), NSSortDescriptor(key: "population", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)]
        
        if self.isImporting {
            fetchRequest.predicate = NSPredicate(format: "acquireID == %lld", self.acquireID)
        }
        
        //create controller from fetch request
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.currentCoreDataContext, sectionNameKeyPath: nil, cacheName: nil)
        
        //fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    //MARK:- Searching
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        var predicateFormatString = ""
        var predicateArgs = [AnyObject]()
        
        //If we're doing an import, prepend acquireID filtering
        if self.isImporting {
            predicateFormatString = "acquireID == %lld"
            let id = NSNumber(longLong: self.acquireID)
            predicateArgs.append(id)
        }
        
        if searchText != "" {
            predicateFormatString += (predicateFormatString != "" ? " AND " : "") + "name contains[c] %@"
            predicateArgs.append(searchText)
        }
        
        if scope == "Favorites" {
            predicateFormatString += (predicateFormatString != "" ? " AND " : "") + "favorite==true"
        }
        else if scope == "Unfavorites" {
            predicateFormatString += (predicateFormatString != "" ? " AND " : "") + "favorite==false"
        }

        var predicateToUse: NSPredicate?
        if predicateFormatString != "" {
            predicateToUse = NSPredicate(format: predicateFormatString, argumentArray: predicateArgs)
        }

        self.fetchedResultsController.fetchRequest.predicate = predicateToUse
        do {
            try self.fetchedResultsController.performFetch()
            let cities = self.fetchedResultsController.fetchedObjects as! [City]
            
            //Re-evaluate the number of unfavorite entries after every new fetch
            self.numUnfavorites = cities.reduce(0, combine: { val, city in
                return val + (city.favorite ? 0 : 1)
            })
            
            self.tableView.reloadData()
            self.updateUI()
        }
        catch {
            let nserror = error as NSError
            self.alertUserWithTitle("Error"
                                    , message: nserror.localizedDescription
                                    , retryHandler: nil)
        }
    }
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
    
    func mapViewWillStartLoadingMap(mapView: MKMapView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
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
            let city = anObject as! City
            
            if !city.favorite {
                self.numUnfavorites++
            }
            
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            self.mapView.addAnnotation(anObject as! MKAnnotation)
        case .Delete:
            let city = anObject as! City

            if !city.favorite {
                self.numUnfavorites--
            }
            
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

//MARK: CityTableViewCellDelegate
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

//MARK: UISearchResultsUpdating
extension ShowCitiesViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchBar = self.searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        self.filterContentForSearchText(self.searchController.searchBar.text!, scope: scope)
    }
}

//MARK: UISearchBarDelegate
extension ShowCitiesViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}
