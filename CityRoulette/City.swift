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

// Insert code here to add functionality to your managed object subclass
    convenience init(json: [String: AnyObject], context: NSManagedObjectContext){
        let entity = NSEntityDescription.entityForName("City", inManagedObjectContext: context)
        
        //Superclass' init(entity:insertIntoManagedObjectContext) designated initializer is inherited
        //because we don't define ourselves any designated initializer, so we can call such inherited designated initializer
        //by simple self.init delegation here
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        print ("Creating city from \(json)")
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

