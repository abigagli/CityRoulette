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
    
    init(json: [String: AnyObject], context: NSManagedObjectContext, parent: City? = nil){
        let entity = NSEntityDescription.entityForName("City", inManagedObjectContext: context)
        
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.parent = parent
        
        //TODO: fill from json
        print ("Creating city from \(json)")
    }
    
    /*
    @NSManaged func addNeighboursObject (neighbour: City)
    @NSManaged func removeNeighboursObject (neighbour: City)
    @NSManaged func addNeighbours (neighbours: NSSet)
    @NSManaged func removeNeighbours (neighbours: NSSet)
    */
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

