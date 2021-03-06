//
//  City.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 1/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import MapKit

class City: NSManagedObject {
    
    //A non-persisted property used to cache weather icons while displaying cities
    //on a table view
    var weatherImage: UIImage?
    
    
    convenience init (json: NSDictionary, acquireID: Int64, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "City", in: context)
        
        //Superclass' init(entity:insertIntoManagedObjectContext) designated initializer is inherited
        //because we don't define ourselves any designated initializer, so we can call such inherited designated initializer
        //by simple self.init delegation here
        self.init(entity: entity!, insertInto: context)
        
        //@NSManaged properties acts as inherited properties and must be initialized in phase2
        
        self.name = json["toponymName"] as! String
        self.countryCode = json["countrycode"] as? String
        self.population = Int32(((json["population"] as AnyObject).intValue) ?? 0)
        self.wikipedia = json["wikipedia"] as? String
        self.latitude = json["lat"] as! Double
        self.longitude = json["lng"] as! Double
        self.geonameID = Int64((json["geonameId"]! as! NSNumber).intValue)
        self.acquireID = acquireID
        self.favorite = false
    }
}

extension City: MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D (latitude: self.latitude, longitude: self.longitude)
        }
    }
    
    var title: String? {
        return self.name
    }
    
    var subtitle: String? {
        return self.population > 0 ? "Pop: \(self.population)" : ""
    }
}

