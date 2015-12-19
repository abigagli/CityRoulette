//
//  OpenWeather.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 19/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import Foundation
import CoreLocation

class OpenWeatherClient {
    
    //MARK: Singleton
    static let sharedInstance = OpenWeatherClient()
    
    //private init enforces singleton usage
    private init() {
        self.consumer = APIConsumer (withSession: NSURLSession.sharedSession())
    }
    
    //MARK:- State
    let consumer: APIConsumer
 
    func getForecastForLocation (location: CLLocationCoordinate2D, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        let parameters: [String: AnyObject] = [
            URLKeys.Lat     : "\(location.latitude)",
            URLKeys.Lon     : "\(location.longitude)",
            URLKeys.AppID   : Constants.APIKey
        ]
        
        consumer.getWithEndpoint(Constants.ForecastEndpoint, parameters: parameters) /* And then, on another thread... */ {
            result, error in
            
            if let error = error {
                completionHandler (success: false, error: error)
            }
            else {
                let resultDictionary = result as! [String: AnyObject]
                
                if let forecastList = resultDictionary["list"] as? [AnyObject] {
                    print ("Got list: \(forecastList)")
                }
            }
        }
    }
}
