//
//  APIConsumer.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 19/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import Foundation

class APIConsumer {
    
    private let session: NSURLSession
    init (withSession: NSURLSession) {
       self.session = withSession
    }
    
    //MARK:- Business Logic
    func getWithEndpoint (apiEndpoint: String, parameters: [String : AnyObject],
        completionHandler: (result: AnyObject?, error: NSError?) -> Void) {
            //Build the URL and URL request specific to the website required.
            let urlString = apiEndpoint + APIConsumer.escapedParameters(parameters)
            let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            //Make the request.
            let task = session.dataTaskWithRequest(request) {
                data, _, downloadError in
                
                if let _ = downloadError {
                    completionHandler(result: nil, error: downloadError)
                }
                else { //Parse the received data.
                    APIConsumer.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
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
