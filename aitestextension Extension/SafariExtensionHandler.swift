//
//  SafariExtensionHandler.swift
//  aitestextension Extension
//
//  Created by yuuki on 2025/08/30.
//

import SafariServices
import os.log

class SafariExtensionHandler: SFSafariExtensionHandler {

    override func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let profile: UUID?
        if #available(iOS 26.0, macOS 26.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }

        os_log(.default, "The extension received a request for profile: %@", profile?.uuidString ?? "none")
    }

    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        page.getPropertiesWithCompletionHandler { properties in
            os_log(.default, "The extension received a message (%@) from a script injected into (%@) with userInfo (%@)", messageName, String(describing: properties?.url), userInfo ?? [:])
            
            // Special handling for pageContentResponse with direct content
            if messageName == "pageContentResponse" && userInfo != nil {
                os_log(.default, "Direct page content response received for: %@", String(describing: properties?.url))
                DispatchQueue.main.async {
                    SafariExtensionViewController.shared.updatePageContent(userInfo!, from: page)
                }
                return
            }
            
            // Handle webkit message handler messages
            if let messageData = userInfo?["name"] as? String,
               let data = userInfo?["data"] as? [String: Any] {
                self.handleWebKitMessage(messageData, data: data, from: page, properties: properties)
                return
            }
            
            // Handle direct messages (fallback)
            self.handleDirectMessage(messageName, userInfo: userInfo, from: page, properties: properties)
        }
    }
    
    private func handleWebKitMessage(_ messageName: String, data: [String: Any], from page: SFSafariPage, properties: SFSafariPageProperties?) {
        os_log(.default, "WebKit message received: %@", messageName)
        
        if messageName == "pageContentLoaded" || messageName == "pageContentUpdated" || messageName == "pageContent" || messageName == "pageContentResponse" {
            os_log(.default, "Successfully received page content via WebKit for: %@", String(describing: properties?.url))
            DispatchQueue.main.async {
                SafariExtensionViewController.shared.updatePageContent(data, from: page)
            }
        } else if messageName == "scriptLoaded" {
            os_log(.default, "Content script loaded successfully via WebKit for: %@", String(describing: properties?.url))
            // Script loaded confirmation - no additional action needed
        } else {
            os_log(.default, "Received unknown WebKit message: %@", messageName)
        }
    }
    
    private func handleDirectMessage(_ messageName: String, userInfo: [String: Any]?, from page: SFSafariPage, properties: SFSafariPageProperties?) {
        // Handle page content messages (legacy fallback)
        if messageName == "pageContentLoaded" || messageName == "pageContentUpdated" || messageName == "pageContent" || messageName == "pageContentResponse" {
            if let pageContent = userInfo {
                os_log(.default, "Successfully received page content (direct) for: %@", String(describing: properties?.url))
                DispatchQueue.main.async {
                    SafariExtensionViewController.shared.updatePageContent(pageContent, from: page)
                }
            } else {
                os_log(.error, "Received page content message but userInfo is nil")
            }
        } else if messageName == "scriptLoaded" {
            os_log(.default, "Content script loaded successfully (direct) for: %@", String(describing: properties?.url))
            // Script loaded confirmation - no additional action needed
        } else {
            os_log(.default, "Received unknown direct message: %@", messageName)
        }
    }
    
    func requestPageContent(from page: SFSafariPage) {
        // Send message to content script to extract content
        page.dispatchMessageToScript(withName: "getPageContent", userInfo: nil)
        os_log(.default, "Sent getPageContent message to script")
    }

    override func toolbarItemClicked(in window: SFSafariWindow) {
        os_log(.default, "The extension's toolbar item was clicked")
    }

    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        validationHandler(true, "")
    }

    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }

}
