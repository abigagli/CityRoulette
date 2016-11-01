//
//  APIConsumer.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 19/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import Foundation

class APIConsumer {
    
    let session: URLSession
    init (withSession: URLSession) {
       self.session = withSession
    }
    
    //MARK:- Business Logic
    func getWithEndpoint (_ apiEndpoint: String, parameters: [String : AnyObject],
        completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) {
            //Build the URL and URL request specific to the website required.
            let urlString = apiEndpoint + APIConsumer.escapedParameters(parameters)
            let request = URLRequest(url: URL(string: urlString)!)
            
            //Make the request.
            let task = session.dataTask(with: request, completionHandler: {
                data, _, downloadError in
                
                if let _ = downloadError {
                    completionHandler(nil, downloadError as NSError?)
                }
                else { //Parse the received data.
                    APIConsumer.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
                }
            }) 
            
            //Start the request task.
            task.resume()
    }
    
    
    //MARK: Helpers
    
    
    //Escape parameters and make them URL-friendly
    fileprivate class func escapedParameters(_ parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringValue = "\(value)"
            let replaceSpaceValue = stringValue.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }
    
    //Parse the received JSON data and pass it to the completion handler.
    fileprivate class func parseJSONWithCompletionHandler(_ data: Data, completionHandler: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsingError: NSError?
        let parsedResult: Any?
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            
            completionHandler(nil, error)
        } else {
            
            completionHandler(parsedResult as AnyObject?, nil)
        }
    }
    

}
