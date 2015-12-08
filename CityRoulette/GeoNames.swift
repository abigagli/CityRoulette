//
//  GeoNames.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 29/11/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import CoreData

class GeoNamesClient {
    
    //MARK: Singleton
    static let sharedInstance = GeoNamesClient()
    
    //private init enforces singleton usage
    private init() {
        session = NSURLSession.sharedSession()
    }
    
    //MARK:- State
    var session: NSURLSession
    
    //MARK:- Business Logic
    private func getWithParameters (parameters: [String : AnyObject],
        completionHandler: (result: AnyObject?, error: NSError?) -> Void) {
            //Build the URL and URL request specific to the website required.
            let urlString = Constants.BaseURL + GeoNamesClient.escapedParameters(parameters)
            let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            //Make the request.
            let task = session.dataTaskWithRequest(request) {
                data, _, downloadError in
                
                if let _ = downloadError {
                    completionHandler(result: nil, error: downloadError)
                }
                else { //Parse the received data.
                    GeoNamesClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
                }
            }
            
            //Start the request task.
            task.resume()
    }


    //MARK: Helpers
    
    
    //Escape parameters and make them URL-friendly
    private class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringValue = "\(value)"
            let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: .LiteralSearch, range: nil)
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    //Parse the received JSON data and pass it to the completion handler.
    private class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject?, error: NSError?) -> Void) {
        
        var parsingError: NSError?
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            
            completionHandler(result: nil, error: error)
        } else {
            
            completionHandler(result: parsedResult, error: nil)
        }
    }

}

//MARK:- Convenience
extension GeoNamesClient {
    func getCitiesAroundLocation (location: CLLocationCoordinate2D, withRadius radiusInMeters: Double, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        let region = MKCoordinateRegionMakeWithDistance(location, radiusInMeters, radiusInMeters)
        
        let boxH = region.span.longitudeDelta / 2.0
        let boxV = region.span.latitudeDelta / 2.0
        
        //Parameters for API invocation
        let parameters: [String : AnyObject] = [
            
            URLKeys.North       : "\(location.latitude + boxV)",
            URLKeys.South       : "\(location.latitude - boxV)",
            URLKeys.East        : "\(location.longitude + boxH)",
            URLKeys.West        : "\(location.longitude - boxV)",
            /*
            URLKeys.Lat         : location.latitude,
            URLKeys.Lon         : location.longitude,
            URLKeys.Radius      : "10",
            */
            URLKeys.Language    : Constants.Language,
            URLKeys.Username    : Constants.Username
        ]
        
        getWithParameters(parameters) /* And then, on another thread... */ {
            result, error in
            
            if let error = error {
                completionHandler (success: false, error: error)
            }
            else {
                let resultDictionary = result as! [String: AnyObject]
                
                if let status = resultDictionary[JSONResponseKeys.Status] as? [String: AnyObject] {
                    let message = status["message"] as! String
                    let value = status["value"] as! Int
                    let userInfo = [NSLocalizedDescriptionKey: message]
                    completionHandler(success: false, error: NSError (domain: "GeoNames API", code: value, userInfo: userInfo))
                }
                else {
                    guard let cities = resultDictionary[JSONResponseKeys.Geonames] as? [[String: AnyObject]] where cities.count >= 1 else {
                        completionHandler (success: false, error: NSError(domain: "GeoNames Result", code: 1, userInfo: [NSLocalizedDescriptionKey: "City information not found"]))
                        return
                    }
                    
                    //TODO: REMOVEME
                    print ("Cities: \(resultDictionary)")
                    
                    dispatch_async(dispatch_get_main_queue()) { //managedObjectContext must be used on the owner (main in this case) thread only
                        
                        for cityJson in cities {
                            let currentID = Int64(cityJson[JSONResponseKeys.GeonameID] as! Int)
                            
                            if self.alreadyKnown (currentID) {
                                continue
                            }
                            
                            let _ = City(json: cityJson, context: self.sharedContext)
                        }
                    
                    }
                    
                    completionHandler(success: true, error: nil)
                }
            }
        }
    }
    
    //MARK: Core Data
    private var sharedContext: NSManagedObjectContext  {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator  {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).persistentStoreCoordinator
    }
    
    private func deleteCities() {
        let coord = self.persistentStoreCoordinator
        
        let fetchRequest = NSFetchRequest(entityName: "City")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try coord.executeRequest(deleteRequest, withContext: self.sharedContext)
        } catch let error as NSError {
            debugPrint(error)
        }
    }
    
    private func alreadyKnown (geonameID: Int64) -> Bool {
        let fetchRequest = NSFetchRequest (entityName: "City")
        fetchRequest.predicate = NSPredicate (format: "geonameID == %lld", geonameID)
        
        var error: NSError?
        let n = self.sharedContext.countForFetchRequest(fetchRequest, error: &error)
        
        return error == nil && n > 0
    }
    
}
