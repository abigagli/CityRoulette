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
        case showWiki = "showWiki"
        case saveAndReturnToInitialVC = "saveAndReturnToInitialVC"
        case exitToInitialVC = "exitToInitialVC"
        case embedTVC = "embedTVC"
    }

    //MARK:- Outlets
    @IBOutlet weak var mapView: MKMapView!
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
    
    @IBAction func cancelTapped(sender: AnyObject) {
        //If Cancel-ing out might cause some loss of data, then
        //give the user one opportunity to think again
        
        let recordsToSave = self.currentCoreDataContext.registeredObjects.count > 0
        let userCanLoseData = self.isBrowsing && self.currentCoreDataContext.hasChanges ||
                              self.isImporting && recordsToSave
        
        if userCanLoseData {
            let alert = UIAlertController(title: "Warning",
                message: "You have new data or unsaved modifications, are you sure?",
                preferredStyle: .Alert)
            
            let alertOkAction = UIAlertAction(title: "OK",
                style: .Destructive,
                handler: {_ in
                    self.performSegueWithIdentifier("exitToInitialVC", sender: self)
            })
            
            let alertCancelAction = UIAlertAction(title: "Cancel",
                style: .Cancel,
                handler: {_ in return false})
            
            alert.addAction(alertOkAction)
            alert.addAction(alertCancelAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            self.performSegueWithIdentifier("exitToInitialVC", sender: self)
        }
    }
    
    //MARK:- State
    
    
    /*** The following constitute the "configurables" for this VC to be set by the presenting VC
    e.g. during prepare for segue ***/
    var radius: Double!
    var currentCoreDataContext: NSManagedObjectContext!
    var acquireID: Int64 = 0
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
    /***************************************************************************/

    
    
    private var numUnfavorites: Int = 0
    private let searchController = UISearchController(searchResultsController: nil)
    
    
    private var isImportingFromCurrentLocation: Bool {
        return self.operatingMode == .importFromCurrentLocation
    }
    
    private var isImportingFromRandomLocation: Bool {
        return self.operatingMode == .importFromRandomLocation
    }
    
    private var isImporting: Bool {
        return self.isImportingFromCurrentLocation || self.isImportingFromRandomLocation
    }
    
    private var isBrowsing: Bool {
        return self.operatingMode == .browseArchivedCities
    }
    
    private var embeddedTVC: UITableViewController!
    
    //embeddedTVC is set while preparing for the embed segue, which is guaranteed to
    //be called before viewDidLoad, so accessing it here to "proxy" its tableView
    //is safe as any access to self.tableView won't be done until viewDidLoad
    private var tableView: UITableView {
        return embeddedTVC.tableView
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
    
    func updateWeather (sender: UIRefreshControl) {
        
        //We can't easily alert the user directly upon failure to retrieve weather conditions
        //because we might have many failures due to API requests being made while configuring cells,
        //and so some complex stateful logic would be necessary.
        //To keep things simple, just prevent the whole update to start if no connection is available
        if isConnectedToNetwork() {
            
            //Invalidate the cached images for weather icons, so that the openweather API will
            //be used again to refresh weather conditions
            for city in self.fetchedResultsController.fetchedObjects as! [City] {
                city.weatherImage = nil
            }
            
            //Just reload what's visible, the rest will be handled as usual while scrolling
            if let visibleIndexPaths = self.tableView.indexPathsForVisibleRows {
                self.tableView.reloadRowsAtIndexPaths(visibleIndexPaths, withRowAnimation: .Fade)
            }
        
        }
        else {
            self.alertUserWithTitle("Error", message: "Weather Update requires internet connection", retryHandler: nil)
        }
        
        sender.endRefreshing()
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
    
    
    private func configureCell (cell: CityTableViewCell, forCity city: City, atIndexPath indexPath: NSIndexPath) {
        cell.nameLabel.text = city.name
        cell.countryCodeLabel.text! = "Country: " + (city.countryCode ?? " na")
        
        cell.delegate = self
        cell.favoriteButton.isFavorite = city.favorite
        
        if let wikipedia = city.wikipedia where !wikipedia.isEmpty {
            cell.accessoryType = .DetailButton
        }
        else {
            cell.accessoryType = .None
        }
        
        cell.weatherIcon.image = nil
        
        //If we already got a weather icon for this city...
        if let weatherImage = city.weatherImage {
            //... just reuse it
            cell.weatherIcon.image = weatherImage
        }
        else { //Otherwise, get the appropriate (possibly cached) weather icon image throgh the OpenWeather API
            let cityCoordinates = CLLocationCoordinate2D (latitude: city.latitude, longitude: city.longitude)
            OpenWeatherClient.sharedInstance.getWeatherIconForLocation(cityCoordinates) {
                iconImage, error in
                
                guard let weatherImage = iconImage else { return }
                
                //Use the model as a cache while we're looking at the same set of cities
                city.weatherImage = weatherImage
                
                dispatch_async(dispatch_get_main_queue()) {
                    //As we're asynchronos, ensure the cell hasn't been off-screen and reused
                    if let cellToUpdate = self.tableView.cellForRowAtIndexPath(indexPath) as? CityTableViewCell {
                        cellToUpdate.weatherIcon.image = weatherImage
                        cellToUpdate.setNeedsLayout()
                    }
                }
            }
        }
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
                    
                    //When importing, we want "Import" to apply to the currently visualized search result
                    //if any, so we perform a sort of manual removal of the complement of the current
                    //fetchedResultsController objects set from the working managedObjectContext
                    //NOTE: Would probably be better to build a complement predicate and then perform a NSBatchDeleteRequest
                    //on the persistentStoreCoordinator...
                    if self.isImporting, let currentPredicate = self.fetchedResultsController.fetchRequest.predicate {
                        
                        for obj in self.currentCoreDataContext.registeredObjects {
                            if !currentPredicate.evaluateWithObject(obj) {
                                self.currentCoreDataContext.deleteObject(obj)
                            }
                        }
                    }
                    try self.currentCoreDataContext.save()
                    
                } catch {
                    let nserror = error as NSError
                    
                    self.alertUserWithTitle("Error saving cities"
                        , message: nserror.localizedDescription
                        , retryHandler: nil)

                }
            }
            
            //print ("Scratch Context After: \(self.currentCoreDataContext.registeredObjects.count)")
            //print ("Main Context: \(CoreDataStackManager.sharedInstance.managedObjectContext.registeredObjects.count)")
            
        case .exitToInitialVC?:
           self.currentCoreDataContext.reset()
            
        case .embedTVC?:
            self.embeddedTVC = destination as! UITableViewController
            
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
        self.searchController.searchBar.scopeButtonTitles = ["All", "Favorites", "Unfavorites", "WithWiki"]
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
        else if scope == "WithWiki" {
            predicateFormatString += (predicateFormatString != "" ? " AND " : "") + "wikipedia!=\"\""
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
        guard let city = view.annotation as? City else {return}

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
        if self.fetchedResultsController.sections![section].numberOfObjects > 0 {
            self.tableView.backgroundView = nil
            self.tableView.separatorStyle = .SingleLine
            self.tableView.scrollEnabled = true
            
            return self.fetchedResultsController.sections![section].numberOfObjects
        }
        else {
            // Display a message when the table is empty
            let messageLabel = UILabel(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
            
            messageLabel.text = "No cities to display"
            messageLabel.textColor = UIColor.blackColor()
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = .Center
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel;
            self.tableView.separatorStyle = .None
            self.tableView.scrollEnabled = false
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cityInfoCell", forIndexPath: indexPath) as! CityTableViewCell

        let city = fetchedResultsController.objectAtIndexPath(indexPath) as! City
        
        self.configureCell (cell, forCity: city, atIndexPath: indexPath)
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
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
        
        //If the tableview is empty we cannot scroll anymore, so ensure
        //the tableView's header (i.e. the UISearchBar in this case) is visible
        if !self.tableView.scrollEnabled {
            let headerFrame = self.tableView.tableHeaderView!.frame
            self.tableView.scrollRectToVisible(headerFrame, animated: true)
        }
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
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        self.embeddedTVC.refreshControl = nil
        return true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.embeddedTVC.refreshControl = (self.embeddedTVC as! CitiesTableViewController).updateWeatherRefreshControl
    }
}

//MARK:- HACK 
//Encapsulated in an extension a hack I used to make UIRefreshControl work
//with a non-tableviwecontroller-based tableview.
//Basically, I tried the following in viewDidLoad or viewDidAppear, but it gave
//a lot of problems with the UIRefreshControl
//Appearing on top of the table view and jumping down when refreshing
/*
self.refreshControl = UIRefreshControl()
self.refreshControl.attributedTitle = NSAttributedString(string:"Update Weather")
self.refreshControl.addTarget(self, action: "updateWeather:", forControlEvents: .ValueChanged)
self.tableView.addSubview(self.refreshControl)
*/
//So I looked around and found inspiration on 
//http://stackoverflow.com/questions/12497940/uirefreshcontrol-without-uitableviewcontroller/12502450#12502450

/*
extension ShowCitiesViewController /* Hacking a bit for UIRefreshControl to work */{ 
    private var refreshControl: UIRefreshControl? {
        get {
            return self.updateWeatherRefreshControl
        }
        
        set {
            let tempTVC = UITableViewController()
            tempTVC.tableView = self.tableView
            
            
            tempTVC.refreshControl = newValue
        }
    }
}
*/
