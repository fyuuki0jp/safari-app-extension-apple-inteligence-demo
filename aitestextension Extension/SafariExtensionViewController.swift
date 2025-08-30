//
//  SafariExtensionViewController.swift
//  aitestextension Extension
//
//  Created by yuuki on 2025/08/30.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:320, height:240)
        return shared
    }()

}
