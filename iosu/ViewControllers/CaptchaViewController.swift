//
//  CaptchaViewController.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/15/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import UIKit
import Cartography
import WebKit

class CaptchaViewController: UIViewController {
    
    private let song: SongsDownloader.Song
    private let completion: (_ done: Bool) -> Void
    private let webView = WKWebView()
    
    init(song: SongsDownloader.Song, completion: @escaping (_ done: Bool) -> Void) {
        self.song = song
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "CAPTCHA Required"
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelButton
        
        view.addSubview(webView)
        constrain(webView, view) { (webView, view) in
            webView.edges == view.edges
        }
        webView.navigationDelegate = self
        let request = URLRequest(url: song.downloadURL)
        webView.customUserAgent = SongsDownloader.instance.userAgent
        webView.load(request)
    }
    
    @objc func cancel() {
        respondAndDismiss(success: false)
    }
    
    private func respondAndDismiss(success: Bool) {
        let completion = self.completion
        dismiss(animated: true, completion: {
            completion(success)
        })
    }
}

extension CaptchaViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            if let headers = httpResponse.allHeaderFields as? [String: String] {
                if let contentDisposition = headers["Content-Disposition"], contentDisposition.contains("attachment") {
                    webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] (cookies) in
                        cookies.forEach { (cookie) in
                            HTTPCookieStorage.shared.setCookie(cookie)
                        }
                        self?.respondAndDismiss(success: true)
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
}


