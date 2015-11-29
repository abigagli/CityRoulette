//
//  Utils.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 28/11/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//
import UIKit

func delay(seconds seconds: Double, completion:()->()) {
    let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64( Double(NSEC_PER_SEC) * seconds ))
    
    dispatch_after(popTime, dispatch_get_main_queue()) {
        completion()
    }
}
