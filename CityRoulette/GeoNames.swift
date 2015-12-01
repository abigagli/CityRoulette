//
//  GeoNames.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 29/11/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import CoreLocation

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
    func getCitiesAroundLocation (location: CLLocationCoordinate2D, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        let accuracy = 0.2
        //Parameters for API invocation
        let parameters: [String : AnyObject] = [
            
            URLKeys.North       : "\(location.latitude + accuracy)",
            URLKeys.South       : "\(location.latitude - accuracy)",
            URLKeys.East        : "\(location.longitude + accuracy)",
            URLKeys.West        : "\(location.longitude - accuracy)",
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
                    print ("result: \(result)")
                    completionHandler(success: true, error: nil)
                }
            }
        }
    }
}
