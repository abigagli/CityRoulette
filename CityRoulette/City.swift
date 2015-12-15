//
//  City.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 1/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class City: NSManagedObject {
    
    convenience init (json: NSDictionary, acquireID: Int64, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("City", inManagedObjectContext: context)
        
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        //@NSManaged properties acts as inherited properties and must be initialized in phase2
        
        self.name = json["toponymName"] as! String
        self.countryCode = json["countrycode"] as? String
        self.population = Int32((json["population"]?.integerValue) ?? 0)
        self.wikipedia = json["wikipedia"] as? String
        self.latitude = json["lat"] as! Double
        self.longitude = json["lng"] as! Double
        self.geonameID = Int64(json["geonameId"]!.integerValue)
        self.acquireID = acquireID
        self.favorite = false
    }
}

extension City: MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D (latitude: self.latitude, longitude: self.longitude)
        }
        
        //TODO: REMOVEME if not dragging
        /*
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
        */
    }
    
    var title: String? {
        return self.name
    }
    
    var subtitle: String? {
        return self.population > 0 ? "Pop: \(self.population)" : ""
    }
}

