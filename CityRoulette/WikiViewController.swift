//
//  WikiViewController.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 8/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

class WikiViewController: UIViewController {
    var city: City!
    @IBOutlet var webView: UIWebView!
    
    override func viewDidLoad() {
        let url:NSURL
        if let wikipediaInfo = self.city.wikipedia {
            url = NSURL(string: "http://\(wikipediaInfo)")!
        }
        else {
            url = NSURL(string:"http://en.wikipedia.org/w/index.php?search=\(self.city.name)")!
        }
        let request = NSURLRequest(URL: url)
        self.webView.loadRequest(request)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
