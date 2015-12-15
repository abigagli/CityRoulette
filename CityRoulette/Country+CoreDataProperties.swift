//
//  Country+CoreDataProperties.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 14/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Country {

    @NSManaged var capital: String
    @NSManaged var countryCode: String
    @NSManaged var countryName: String
    @NSManaged var continent: String
    @NSManaged var continentName: String
    @NSManaged var population: Int32
    @NSManaged var geonameID: Int64
    @NSManaged var north: Double
    @NSManaged var east: Double
    @NSManaged var south: Double
    @NSManaged var west: Double

}
