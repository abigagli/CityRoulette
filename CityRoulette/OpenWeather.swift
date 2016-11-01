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
    fileprivate init() {
        self.consumer = APIConsumer (withSession: URLSession.shared)
    }
    
    //MARK:- State
    let consumer: APIConsumer
    
    fileprivate func getIconNamed(_ fileName: String,
        completionHandler: @escaping (_ icon: UIImage?, _ error: NSError?) -> Void) {
            
            let URLString = Constants.IconImageBaseURL + "/" + fileName
            //Create request with urlString.
            let request = URLRequest(url: URL(string: URLString)!)
            
            //Make the request.
            let task = consumer.session.dataTask(with: request, completionHandler: {
                data, response, downloadError in
                
                if let imageData = data {
                    let filePath = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory.appendingPathComponent(fileName).path
                    
                    FileManager.default.createFile(atPath: filePath, contents: imageData, attributes: nil)
                    
                    let image = UIImage(data: imageData)
                    
        
                    
                    completionHandler(image, nil)
                    
                }
            }) 
            
            //Start the request task.
            task.resume()
    }
    
    fileprivate func storedImageForIconFile (_ fileName: String) -> UIImage? {
        
        let filePath = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory.appendingPathComponent(fileName).path
        
        if let imageData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
            return UIImage (data: imageData)
        }
        else {
            return nil
        }
    }
 
    func getWeatherIconForLocation (_ location: CLLocationCoordinate2D, completionHandler: @escaping (_ icon: UIImage?, _ error: NSError?) -> Void) {
        
        let parameters: [String: AnyObject] = [
            URLKeys.Lat     : "\(location.latitude)" as AnyObject,
            URLKeys.Lon     : "\(location.longitude)" as AnyObject,
            URLKeys.AppID   : Constants.APIKey as AnyObject
        ]
        
        consumer.getWithEndpoint(Constants.ForecastEndpoint, parameters: parameters) /* And then, on another thread... */ {
            result, error in
            
            if let error = error {
                completionHandler (nil, error)
            }
            else {
                let resultDictionary = result as! [String: AnyObject]
                
                if let weatherArray = resultDictionary["weather"] as? [[String: AnyObject]] {
                    
                    for weatherDictionary in weatherArray {
                        if let icon = weatherDictionary["icon"] as? String {
                            
                            let fileName = icon + ".png"
                            
                            if let image = self.storedImageForIconFile (fileName) {
                                completionHandler(image, nil)
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
