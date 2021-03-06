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
    fileprivate init() {
        self.consumer = APIConsumer (withSession: URLSession.shared)
    }
    
    //MARK:- State
    let consumer: APIConsumer
    
    func getCitiesAroundLocation (_ location: CLLocationCoordinate2D, withRadius radiusInMeters: Double, maxResults: Int = 10, andStoreIn context: NSManagedObjectContext, completionHandler: @escaping (_ acquireID: Int64, _ error: NSError?) -> Void) {
        
        let region = MKCoordinateRegionMakeWithDistance(location, radiusInMeters, radiusInMeters)
        
        let boxH = region.span.longitudeDelta / 2.0
        let boxV = region.span.latitudeDelta / 2.0
        
        //Parameters for API invocation
        let parameters: [String : AnyObject] = [
            
            URLKeys.North       : "\(location.latitude + boxV)" as AnyObject,
            URLKeys.South       : "\(location.latitude - boxV)" as AnyObject,
            URLKeys.East        : "\(location.longitude + boxH)" as AnyObject,
            URLKeys.West        : "\(location.longitude - boxV)" as AnyObject,
            /*
            URLKeys.Lat         : location.latitude,
            URLKeys.Lon         : location.longitude,
            URLKeys.Radius      : "10",
            */
            URLKeys.Language    : Constants.Language as AnyObject,
            URLKeys.MaxRows     : "\(maxResults)" as AnyObject,
            URLKeys.Username    : Constants.Username as AnyObject
        ]
        
        consumer.getWithEndpoint(Constants.CitiesEndpoint, parameters: parameters) /* And then, on another thread... */ {
            result, error in
            
            if let error = error {
                completionHandler (0, error)
            }
            else {
                let resultDictionary = result as! [String: AnyObject]
                
                if let status = resultDictionary[JSONResponseKeys.Status] as? [String: AnyObject] {
                    let message = status["message"] as! String
                    let value = status["value"] as? Int ?? 0
                    let userInfo = [NSLocalizedDescriptionKey: message]
                    completionHandler(0, NSError (domain: "GeoNames \"cities\" endpoint", code: value, userInfo: userInfo))
                }
                else {
                    guard let cities = resultDictionary[JSONResponseKeys.Geonames] as? [[String: AnyObject]], cities.count >= 1 else {
                        completionHandler (0, NSError(domain: "GeoNames \"cities\" endpoint", code: 1, userInfo: [NSLocalizedDescriptionKey: "City information not found"]))
                        
                        return
                    }
                    
                    let id = Int64(Date().timeIntervalSince1970)
                    
                    //Ensure CoreData context is accessed on whatever queue it's working on
                    context.perform() {

                        for cityJSON in cities {
                            let _ = City(json: cityJSON as NSDictionary, acquireID: id, context: context)
                        }
                    }
                    
                    completionHandler(id, nil)
                }
            }
        }
    }
    
    func getCountryInfo (_ countryCode: String?, andStoreIn context: NSManagedObjectContext, completionHandler: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        
        //Parameters for API invocation
        let parameters: [String : AnyObject] = [
            URLKeys.Country     : countryCode as AnyObject? ?? "" as AnyObject,
            URLKeys.Language    : Constants.Language as AnyObject,
            URLKeys.Username    : Constants.Username as AnyObject
        ]
        
        consumer.getWithEndpoint(Constants.CountryInfoEndpoint, parameters: parameters) /* And then, on another thread... */ {
            result, error in
            
            if let error = error {
                completionHandler (false, error)
            }
            else {
                let resultDictionary = result as! [String: AnyObject]
                
                if let status = resultDictionary[JSONResponseKeys.Status] as? [String: AnyObject] {
                    let message = status["message"] as! String
                    let value = status["value"] as? Int ?? 0
                    let userInfo = [NSLocalizedDescriptionKey: message]
                    completionHandler(false, NSError (domain: "GeoNames \"countryInfo\" endpoint", code: value, userInfo: userInfo))
                }
                else {
                    guard let countries = resultDictionary[JSONResponseKeys.Geonames] as? [[String: AnyObject]], countries.count >= 1 else {
                        completionHandler (false, NSError(domain: "GeoNames \"countryInfo\" endpoint", code: 2, userInfo: [NSLocalizedDescriptionKey: "Country information not found"]))
                        
                        return
                    }
                    
                    //Ensure CoreData context is accessed on whatever queue it's working on
                    context.perform() {
                        
                        for countryJSON in countries {
                            let _ = Country(json: countryJSON as NSDictionary, context: context)
                        }
                    }
                    
                    completionHandler(true, nil)
                }
            }
        }
    }
}
