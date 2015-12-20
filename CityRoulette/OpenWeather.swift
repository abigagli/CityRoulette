//
//  OpenWeather.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 19/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit
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
    
    private func getIconNamed(fileName: String,
        completionHandler: (icon: UIImage?, error: NSError?) -> Void) {
            
            let URLString = Constants.IconImageBaseURL + "/" + fileName
            //Create request with urlString.
            let request = NSMutableURLRequest(URL: NSURL(string: URLString)!)
            
            //Make the request.
            let task = consumer.session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                if let imageData = data {
                    let filePath = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory.URLByAppendingPathComponent(fileName).path!
                    
                    NSFileManager.defaultManager().createFileAtPath(filePath, contents: imageData, attributes: nil)
                    
                    let image = UIImage(data: imageData)
                    
        
                    
                    completionHandler(icon: image, error: nil)
                    
                }
            }
            
            //Start the request task.
            task.resume()
    }
    
    private func storedImageForIconFile (fileName: String) -> UIImage? {
        
        let filePath = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory.URLByAppendingPathComponent(fileName).path!
        
        if let imageData = NSData(contentsOfFile: filePath) {
            return UIImage (data: imageData)
        }
        else {
            return nil
        }
    }
 
    func getWeatherIconForLocation (location: CLLocationCoordinate2D, completionHandler: (icon: UIImage?, error: NSError?) -> Void) {
        
        let parameters: [String: AnyObject] = [
            URLKeys.Lat     : "\(location.latitude)",
            URLKeys.Lon     : "\(location.longitude)",
            URLKeys.AppID   : Constants.APIKey
        ]
        
        consumer.getWithEndpoint(Constants.ForecastEndpoint, parameters: parameters) /* And then, on another thread... */ {
            result, error in
            
            if let error = error {
                completionHandler (icon: nil, error: error)
            }
            else {
                let resultDictionary = result as! [String: AnyObject]
                
                if let weatherArray = resultDictionary["weather"] as? [[String: AnyObject]] {
                    
                    for weatherDictionary in weatherArray {
                        if let icon = weatherDictionary["icon"] as? String {
                            
                            let fileName = icon + ".png"
                            
                            if let image = self.storedImageForIconFile (fileName) {
                                completionHandler(icon: image, error: nil)
                            }
                            else {
                                self.getIconNamed(fileName, completionHandler: completionHandler)
                            }
                            
                            break
                        }
                    }
                }
            }
        }
    }
}
