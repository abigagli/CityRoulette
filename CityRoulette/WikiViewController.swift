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
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    //MARK:- Actions
    @IBAction func goForward(sender: UIBarButtonItem) {
        self.webView.goForward()
    }
    @IBAction func goBackward(sender: UIBarButtonItem) {
        self.webView.goBack()
    }
    
    @IBAction func refresh(sender: UIBarButtonItem) {
        self.reloadCurrentOrInitialRequest()
    }
    
    //MARK:- State
    var city: City!
    
    private var initialRequest: NSURLRequest!
    
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
        
        self.initialRequest = NSURLRequest(URL: url)
        self.webView.loadRequest(self.initialRequest)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    //MARK:- Business Logic
    func reloadCurrentOrInitialRequest() {
        if let currentURLString = self.webView.request?.URL?.absoluteString where currentURLString != "" {
            self.webView.reload()
        }
        else {
            self.webView.loadRequest(self.initialRequest)
        }
        
    }
}


extension WikiViewController: UIWebViewDelegate {
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        self.alertUserWithTitle("Error loading webpage"
            , message: error?.localizedDescription ?? "unspecified error"
            , retryHandler: {_ in
                self.reloadCurrentOrInitialRequest()})

        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        self.refreshButton.enabled = true
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
        self.refreshButton.enabled = true
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        self.refreshButton.enabled = false
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
}
