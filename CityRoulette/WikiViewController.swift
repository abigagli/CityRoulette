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
    @IBAction func goForward(_ sender: UIBarButtonItem) {
        self.webView.goForward()
    }
    @IBAction func goBackward(_ sender: UIBarButtonItem) {
        self.webView.goBack()
    }
    
    @IBAction func refresh(_ sender: UIBarButtonItem) {
        self.reloadCurrentOrInitialRequest()
    }
    
    //MARK:- State
    var city: City!
    
    fileprivate var initialRequest: URLRequest!
    
    //MARK:- Lifetime
    override func viewDidLoad() {
        
        self.navigationItem.title = self.city.name
        
        self.webView.delegate = self
        
        let url: URL
        
        if let wikipediaInfo = self.city.wikipedia {
            url = URL(string: "http://\(wikipediaInfo)")!
        }
        else {
            let noSpaceName = self.city.name.replacingOccurrences(of: " ", with: "+", options: .literal, range:nil)
            url = URL(string:"http://en.wikipedia.org/w/index.php?search=\(noSpaceName)")!
        }
        
        self.initialRequest = URLRequest(url: url)
        self.webView.loadRequest(self.initialRequest)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    //MARK:- Business Logic
    func reloadCurrentOrInitialRequest() {
        if let currentURLString = self.webView.request?.url?.absoluteString, currentURLString != "" {
            self.webView.reload()
        }
        else {
            self.webView.loadRequest(self.initialRequest)
        }
        
    }
}


extension WikiViewController: UIWebViewDelegate {
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.alertUserWithTitle("Error loading webpage"
            , message: error.localizedDescription
            , retryHandler: {_ in
                self.reloadCurrentOrInitialRequest()})

        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        self.refreshButton.isEnabled = true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if (webView.canGoBack) {
            self.goBackwardButton.isEnabled = true
        }
        else {
            self.goBackwardButton.isEnabled = false
        }
        
        if (webView.canGoForward) {
            self.goForwardButton.isEnabled = true
        }
        else {
            self.goForwardButton.isEnabled = false
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        self.refreshButton.isEnabled = true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        self.refreshButton.isEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
}
