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
        
        static let Username = "abigagli" //Acts as an API Key for this API
        static let Language = "local"
        
        static let CitiesEndpoint = "http://api.geonames.org/citiesJSON"
        static let CountryInfoEndpoint = "http://api.geonames.org/countryInfoJSON"
    }
    

    //MARK: URL Keys
    
    struct URLKeys {
        static let North        = "north"
        static let South        = "south"
        static let East         = "east"
        static let West         = "west"
        static let Language     = "lang"
        static let MaxRows      = "maxRows"
        static let Username     = "username"
        static let Lat          = "lat"
        static let Lon          = "lng"
        static let Radius       = "radius"
        static let Country      = "country"
    }

    //MARK: JSON Response Keys
    
    struct JSONResponseKeys {
    
        static let Status   = "status"
        static let Geonames = "geonames"
        static let GeonameID = "geonameId"
    }
    
}
