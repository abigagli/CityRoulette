//
//  CitiesTableViewController.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 27/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

class CitiesTableViewController: UITableViewController {

    @IBOutlet var updateWeatherRefreshControl: UIRefreshControl!
    @IBAction func updateWeather(sender: UIRefreshControl) {
        (self.parentViewController as! ShowCitiesViewController).updateWeather (sender)
    }
}
