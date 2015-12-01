//
//  City+CoreDataProperties.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 1/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension City {

    @NSManaged var name: String
    @NSManaged var geonameID: Int64
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var wikipedia: String?
    @NSManaged var population: Int32
    @NSManaged var countryCode: String?
    @NSManaged var neighbours: [City]
    @NSManaged var root: City?

}
