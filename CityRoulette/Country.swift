//
//  Country.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 14/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import Foundation
import CoreData


class Country: NSManagedObject {

    convenience init (json: NSDictionary, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Country", inManagedObjectContext: context)
        
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        //@NSManaged properties acts as inherited properties and must be initialized in phase2
        
        self.capital = json["capital"] as! String
        self.countryCode = json["countryCode"] as! String
        self.countryName = json["countryName"] as! String
        self.continent = json["continent"] as! String
        self.continentName = json["continentName"] as! String
        self.population = Int32((json["population"]?.integerValue) ?? 0)
        self.geonameID = Int64(json["geonameId"]!.integerValue)
        self.north = json["north"] as! Double
        self.east = json["east"] as! Double
        self.south = json["south"] as! Double
        self.west = json["west"] as! Double
    }

}
