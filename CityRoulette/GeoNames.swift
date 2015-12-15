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
    private func getWithEndpoint (apiEndpoint: String, parameters: [String : AnyObject],
        completionHandler: (result: AnyObject?, error: NSError?) -> Void) {
            //Build the URL and URL request specific to the website required.
            let urlString = apiEndpoint + GeoNamesClient.escapedParameters(parameters)
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
    func getCitiesAroundLocation (location: CLLocationCoordinate2D, withRadius radiusInMeters: Double, maxResults: Int = 10, andStoreIn context: NSManagedObjectContext, completionHandler: (acquireID: Int64, error: NSError?) -> Void) {
        
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
            URLKeys.MaxRows     : "\(maxResults)",
            URLKeys.Username    : Constants.Username
        ]
        
        getWithEndpoint(Constants.CitiesEndpoint, parameters: parameters) /* And then, on another thread... */ {
            result, error in
            
            if let error = error {
                completionHandler (acquireID: 0, error: error)
            }
            else {
                let resultDictionary = result as! [String: AnyObject]
                
                if let status = resultDictionary[JSONResponseKeys.Status] as? [String: AnyObject] {
                    let message = status["message"] as! String
                    let value = status["value"] as? Int ?? 0
                    let userInfo = [NSLocalizedDescriptionKey: message]
                    completionHandler(acquireID: 0, error: NSError (domain: "GeoNames \"cities\" endpoint", code: value, userInfo: userInfo))
                }
                else {
                    guard let cities = resultDictionary[JSONResponseKeys.Geonames] as? [[String: AnyObject]] where cities.count >= 1 else {
                        completionHandler (acquireID: 0, error: NSError(domain: "GeoNames \"cities\" endpoint", code: 1, userInfo: [NSLocalizedDescriptionKey: "City information not found"]))
                        
                        return
                    }
                    
                    let id = Int64(NSDate().timeIntervalSince1970)
                    
                    //Ensure CoreData context is accessed on whatever queue it's working on
                    context.performBlock() {

                        for cityJSON in cities {
                            let _ = City(json: cityJSON, acquireID: id, context: context)
                        }
                    }
                    
                    completionHandler(acquireID: id, error: nil)
                }
            }
        }
    }
    
    func getCountryInfo (countryCode: String?, andStoreIn context: NSManagedObjectContext, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        //Parameters for API invocation
        let parameters: [String : AnyObject] = [
            URLKeys.Country     : countryCode ?? "",
            URLKeys.Language    : Constants.Language,
            URLKeys.Username    : Constants.Username
        ]
        
        getWithEndpoint(Constants.CountryInfoEndpoint, parameters: parameters) /* And then, on another thread... */ {
            result, error in
            
            if let error = error {
                completionHandler (success: false, error: error)
            }
            else {
                let resultDictionary = result as! [String: AnyObject]
                
                if let status = resultDictionary[JSONResponseKeys.Status] as? [String: AnyObject] {
                    let message = status["message"] as! String
                    let value = status["value"] as? Int ?? 0
                    let userInfo = [NSLocalizedDescriptionKey: message]
                    completionHandler(success: false, error: NSError (domain: "GeoNames \"countryInfo\" endpoint", code: value, userInfo: userInfo))
                }
                else {
                    guard let countries = resultDictionary[JSONResponseKeys.Geonames] as? [[String: AnyObject]] where countries.count >= 1 else {
                        completionHandler (success: false, error: NSError(domain: "GeoNames \"countryInfo\" endpoint", code: 2, userInfo: [NSLocalizedDescriptionKey: "Country information not found"]))
                        
                        return
                    }
                    
                    //Ensure CoreData context is accessed on whatever queue it's working on
                    context.performBlock() {
                        
                        for countryJSON in countries {
                            let _ = Country(json: countryJSON, context: context)
                        }
                    }
                    
                    completionHandler(success: true, error: nil)
                }
            }
        }
    }

    
    //MARK: Core Data
    
    //TODO: REMOVEME
    /* 
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

    private func alreadyKnown (geonameID: Int64, inContext context: NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest (entityName: "City")
        fetchRequest.predicate = NSPredicate (format: "geonameID == %lld", geonameID)
        
        var error: NSError?
        let n = context.countForFetchRequest(fetchRequest, error: &error)
        
        return error == nil && n > 0
    }
    
    */
}
