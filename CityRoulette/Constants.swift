//
//  Constants.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 29/11/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

extension GeoNamesClient {
    
    //MARK: Constants
    
    struct Constants {
        
        static let Username = "abigagli"
        static let Language = "local"
        
        static let BaseURL = "http://api.geonames.org/citiesJSON"
        //static let BaseURL = "http://api.geonames.org/findNearbyPlaceNameJSON"
    }
    

    //MARK: URL Keys
    
    struct URLKeys {
        static let North        = "north"
        static let South        = "south"
        static let East         = "east"
        static let West         = "west"
        static let Language     = "lang"
        static let Username     = "username"
        
        static let Lat          = "lat"
        static let Lon          = "lng"
        static let Radius       = "radius"
    }

    //MARK: JSON Response Keys
    
    struct JSONResponseKeys {
    
        static let Status   = "status"
        static let Geonames = "geonames"
        static let GeonameID = "geonameId"
    }
    
}
