//
//  WikiViewController.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 8/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

class WikiViewController: UIViewController {
    @IBOutlet var webView: UIWebView!
    @IBOutlet weak var goBackwardButton: UIBarButtonItem!
    @IBOutlet weak var goForwardButton: UIBarButtonItem!
    
    //MARK:- Actions
    @IBAction func goForward(sender: UIBarButtonItem) {
        self.webView.goForward()
    }
    @IBAction func goBackward(sender: UIBarButtonItem) {
        self.webView.goBack()
    }
    
    
    //MARK:- State
    var city: City!
    
    //MARK:- Lifetime
    override func viewDidLoad() {
        
        self.navigationItem.title = self.city.name
        
        self.webView.delegate = self
        
        let url: NSURL
        
        if let wikipediaInfo = self.city.wikipedia {
            url = NSURL(string: "http://\(wikipediaInfo)")!
        }
        else {
            let noSpaceName = self.city.name.stringByReplacingOccurrencesOfString(" ", withString: "+", options: .LiteralSearch, range:nil)
            url = NSURL(string:"http://en.wikipedia.org/w/index.php?search=\(noSpaceName)")!
        }
        
        let request = NSURLRequest(URL: url)
        self.webView.loadRequest(request)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}


extension WikiViewController: UIWebViewDelegate {
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        
        return true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        if (webView.canGoBack) {
            self.goBackwardButton.enabled = true
        }
        else {
            self.goBackwardButton.enabled = false
        }
        
        if (webView.canGoForward) {
            self.goForwardButton.enabled = true
        }
        else {
            self.goForwardButton.enabled = false
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    func webViewDidStartLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
}
