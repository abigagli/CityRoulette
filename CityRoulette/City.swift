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
    
    init (json: [String: AnyObject], context: NSManagedObjectContext, parent: City? = nil) {
        
        let entity = NSEntityDescription.entityForName("City", inManagedObjectContext: context)
        
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        //@NSManaged properties acts as inherited properties and must be initialized in phase2
        self.parent = parent
        
        self.name = json["toponymName"] as! String
        self.countryCode = json["countrycode"] as? String
        self.population = (json["population"] as? Int32) ?? 0
        self.wikipedia = json["wikipedia"] as? String
        self.latitude = json["lat"] as! Double
        self.longitude = json["lng"] as! Double
        self.geonameID = Int64(json["geonameId"] as! Int)
    }
}

extension City: MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D (latitude: self.latitude, longitude: self.longitude)
        }
        
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
    }
}

