//
//  GeoNames.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 29/11/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import CoreLocation
import MapKit
import CoreData

class GeoNamesClient {
    
    //MARK: Singleton
    static let sharedInstance = GeoNamesClient()
    
    //private init enforces singleton usage
    private init() {
        self.consumer = APIConsumer (withSession: NSURLSession.sharedSession())
    }
    
    //MARK:- State
    let consumer: APIConsumer
    
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
        
        consumer.getWithEndpoint(Constants.CitiesEndpoint, parameters: parameters) /* And then, on another thread... */ {
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
        
        consumer.getWithEndpoint(Constants.CountryInfoEndpoint, parameters: parameters) /* And then, on another thread... */ {
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
}
