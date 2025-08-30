//
//  SafariExtensionViewController.swift
//  aitestextension Extension
//
//  Created by yuuki on 2025/08/30.
//

import SafariServices

// FoundationModels is only available on iOS 18+ / macOS 15+
#if canImport(FoundationModels)
import FoundationModels
#endif

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    @IBOutlet weak var messageTextField: NSTextField!
    @IBOutlet weak var chatTextView: NSTextView!
    @IBOutlet weak var sendButton: NSButton!
    @IBOutlet weak var clearChatButton: NSButton!
    @IBOutlet weak var usePageContentCheckbox: NSButton!
    @IBOutlet weak var pageInfoLabel: NSTextField!
    
    #if canImport(FoundationModels)
    private var languageModelSession: LanguageModelSession?
    #endif
    private var currentPageContent: [String: Any]?
    private var contentLoadTimer: Timer?
    private var isWaitingForContent = false
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController(nibName: "SafariExtensionViewController", bundle: Bundle(for: SafariExtensionViewController.self))
        shared.preferredContentSize = NSSize(width:400, height:500)
        return shared
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLanguageModel()
        setupUI()
        requestPageContentWithTimeout()
    }
    
    private func setupLanguageModel() {
        #if canImport(FoundationModels)
        if #available(macOS 15.0, iOS 18.0, *) {
            let model = SystemLanguageModel.default
            let availability = model.availability
            
            if case .available = availability {
                languageModelSession = LanguageModelSession()
                appendToChatView("AI Assistant: Ready to chat! Ask me anything.")
            } else {
                appendToChatView("AI Assistant: Model is not available: \(availability)")
            }
        } else {
            appendToChatView("AI Assistant: FoundationModels requires macOS 15.0+ or iOS 18.0+")
        }
        #else
        appendToChatView("AI Assistant: FoundationModels framework is not available on this system")
        #endif
    }
    
    private func setupUI() {
        sendButton?.title = "Send"
        clearChatButton?.title = "Clear"
        messageTextField?.placeholderString = "Type your message here..."
        messageTextField?.target = self
        messageTextField?.action = #selector(handleEnterKey)
        chatTextView?.isEditable = false
        chatTextView?.font = NSFont.systemFont(ofSize: 12)
        
        usePageContentCheckbox?.title = "Include page content"
        usePageContentCheckbox?.state = .on
        pageInfoLabel?.stringValue = "Loading page content..."
        pageInfoLabel?.textColor = .systemOrange
        pageInfoLabel?.font = NSFont.systemFont(ofSize: 11)
        
        // Make pageInfoLabel clickable for help
        pageInfoLabel?.isSelectable = true
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(showPermissionHelp))
        pageInfoLabel?.addGestureRecognizer(clickGesture)
    }
    
    @objc private func handleEnterKey(_ sender: NSTextField) {
        sendMessage(sendButton)
    }
    
    @IBAction func sendMessage(_ sender: NSButton) {
        guard let message = messageTextField?.stringValue, !message.isEmpty else { return }
        
        appendToChatView("You: \(message)")
        messageTextField?.stringValue = ""
        
        Task {
            await sendMessageToAI(message)
        }
    }
    
    @IBAction func clearChat(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "Clear Chat History"
        alert.informativeText = "Are you sure you want to clear all chat messages?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Show Debug Info")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Clear chat
            chatTextView?.string = ""
            
            // Show welcome message again
            #if canImport(FoundationModels)
            if languageModelSession != nil {
                appendToChatView("AI Assistant: Ready to chat! Ask me anything.")
            } else {
                appendToChatView("AI Assistant: Model is not available.")
            }
            #else
            appendToChatView("AI Assistant: FoundationModels framework is not available on this system")
            #endif
        } else if response == .alertSecondButtonReturn {
            // Show debug info
            showDebugInformation()
        }
    }
    
    private func showDebugInformation() {
        var debugInfo = "=== DEBUG INFORMATION ===\n\n"
        
        // Extension status
        debugInfo += "Extension Status:\n"
        #if canImport(FoundationModels)
        debugInfo += "- Language Model: \(languageModelSession != nil ? "Available" : "Not Available")\n"
        #else
        debugInfo += "- Language Model: FoundationModels not available on this system\n"
        #endif
        debugInfo += "- Waiting for content: \(isWaitingForContent)\n\n"
        
        // Page content status
        debugInfo += "Page Content Status:\n"
        if let content = currentPageContent {
            debugInfo += "- Title: \(content["title"] as? String ?? "N/A")\n"
            debugInfo += "- URL: \(content["url"] as? String ?? "N/A")\n"
            debugInfo += "- Body Text Length: \((content["bodyText"] as? String)?.count ?? 0) characters\n"
            debugInfo += "- Body HTML Length: \((content["bodyHTML"] as? String)?.count ?? 0) characters\n"
            debugInfo += "- Selected Text: \((content["selectedText"] as? String)?.isEmpty == false ? "Available" : "None")\n"
            if let extractedAt = content["extractedAt"] as? String {
                debugInfo += "- Last extracted: \(extractedAt)\n"
            }
            if let readyState = content["readyState"] as? String {
                debugInfo += "- Document ready state: \(readyState)\n"
            }
            if let error = content["error"] as? String {
                debugInfo += "- Error: \(error)\n"
            }
        } else {
            debugInfo += "- No content available\n"
        }
        
        debugInfo += "\nMessaging System:\n"
        debugInfo += "- Using JavaScript evaluation for Safari App Extension\n"
        debugInfo += "- Polling interval: 1 second\n"
        debugInfo += "- Timeout: 10 seconds\n\n"
        
        debugInfo += "Troubleshooting Steps:\n"
        debugInfo += "1. Check Safari > Settings > Extensions\n"
        debugInfo += "2. Verify 'AI Chat Assistant' is enabled\n"
        debugInfo += "3. Check website permissions (should be 'Allow')\n"
        debugInfo += "4. Try refreshing the webpage\n"
        debugInfo += "5. Check browser console for 'AI Extension:' messages\n"
        debugInfo += "6. Look for 'TypeError: safari.extension' errors (should be gone now)\n"
        debugInfo += "7. Verify 'API Availability Check' in console\n"
        
        // Add debug info to chat
        appendToChatView(debugInfo)
    }
    
    private func sendMessageToAI(_ message: String) async {
        #if canImport(FoundationModels)
        guard let session = languageModelSession else {
            appendToChatView("AI Assistant: Language model is not available.")
            return
        }
        
        do {
            appendToChatView("AI Assistant: Thinking...")
            
            let enhancedMessage = buildEnhancedMessage(userMessage: message)
            let response = try await session.respond(to: enhancedMessage)
            
            DispatchQueue.main.async {
                self.replaceLast("AI Assistant: \(response.content)")
            }
        } catch {
            DispatchQueue.main.async {
                self.replaceLast("AI Assistant: Error: \(error.localizedDescription)")
            }
        }
        #else
        appendToChatView("AI Assistant: FoundationModels framework is not available. This feature requires macOS 15.0+ or iOS 18.0+")
        #endif
    }
    
    private func buildEnhancedMessage(userMessage: String) -> String {
        guard usePageContentCheckbox?.state == .on,
              let pageContent = currentPageContent else {
            return userMessage
        }
        
        var contextualMessage = "Based on the current webpage context:\n\n"
        
        if let title = pageContent["title"] as? String {
            contextualMessage += "Page Title: \(title)\n"
        }
        
        if let url = pageContent["url"] as? String {
            contextualMessage += "URL: \(url)\n"
        }
        
        if let bodyText = pageContent["bodyText"] as? String, !bodyText.isEmpty {
            contextualMessage += "\nPage Content:\n\(bodyText)\n"
        }
        
        if let selectedText = pageContent["selectedText"] as? String, !selectedText.isEmpty {
            contextualMessage += "\nSelected Text: \"\(selectedText)\"\n"
        }
        
        contextualMessage += "\nUser Question: \(userMessage)"
        
        return contextualMessage
    }
    
    func updatePageContent(_ content: [String: Any], from page: SFSafariPage?) {
        currentPageContent = content
        isWaitingForContent = false
        contentLoadTimer?.invalidate()
        
        if let title = content["title"] as? String {
            pageInfoLabel?.stringValue = "Page: \(title)"
            pageInfoLabel?.textColor = .labelColor
        }
        
        // Show debug info if content has error
        if let error = content["error"] as? String {
            pageInfoLabel?.stringValue = "⚠️ Content error - Click for help"
            pageInfoLabel?.textColor = .systemOrange
            appendToChatView("Debug: Content extraction error - \(error)")
        }
    }
    
    private func requestPageContentWithTimeout() {
        isWaitingForContent = true
        pageInfoLabel?.stringValue = "Loading page content..."
        pageInfoLabel?.textColor = .systemOrange
        
        // Request content from current page
        SFSafariApplication.getActiveWindow { window in
            window?.getActiveTab { tab in
                tab?.getActivePage { page in
                    // First dispatch the message to get content
                    page?.dispatchMessageToScript(withName: "getPageContent", userInfo: nil)
                    
                    // Then try to evaluate JavaScript to get stored content
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.tryToRetrieveStoredContent(from: page)
                    }
                }
            }
        }
        
        // Set longer timeout to allow for retrieval attempts
        contentLoadTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            self?.handleContentLoadTimeout()
        }
    }
    
    private func tryToRetrieveStoredContent(from page: SFSafariPage?) {
        // Send multiple retrieval attempts with delays
        
        // Immediate attempt
        page?.dispatchMessageToScript(withName: "forceContentExtraction", userInfo: nil)
        
        // Delayed attempts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            page?.dispatchMessageToScript(withName: "checkAndSendContent", userInfo: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            page?.dispatchMessageToScript(withName: "checkAndSendContent", userInfo: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            page?.dispatchMessageToScript(withName: "checkAndSendContent", userInfo: nil)
        }
    }
    
    private func handleContentLoadTimeout() {
        if isWaitingForContent {
            isWaitingForContent = false
            
            // Try to use a fallback approach - create basic page info
            let fallbackContent: [String: Any] = [
                "title": "Content extraction timed out",
                "url": "Current page",
                "bodyText": "Unable to extract page content. This may be due to website restrictions or the page not being fully loaded. Please try refreshing the page or check Safari permissions.",
                "bodyHTML": "",
                "selectedText": "",
                "extractedAt": ISO8601DateFormatter().string(from: Date()),
                "readyState": "timeout",
                "fallback": true,
                "error": "Content extraction timed out after 8 seconds"
            ]
            
            // Update with fallback content to show the system is working
            updatePageContent(fallbackContent, from: nil)
            
            pageInfoLabel?.stringValue = "Content script active - Safari App Extension"
            pageInfoLabel?.textColor = .systemGreen
        }
    }
    
    @objc private func showPermissionHelp() {
        let alert = NSAlert()
        alert.messageText = "Permission Required"
        alert.informativeText = """
To enable page content access:

1. Go to Safari > Settings > Extensions
2. Find "AI Chat Assistant" 
3. Select the website domain or choose "All Websites"
4. Click "Allow" or change from "Ask" to "Allow"
5. Refresh this page and reopen the extension

Note: Safari requires explicit permission for each website for security reasons.
"""
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Retry Now")
        alert.addButton(withTitle: "Show Debug Info")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            requestPageContentWithTimeout()
        } else if response == .alertThirdButtonReturn {
            showDebugInformation()
        }
    }
    
    private func appendToChatView(_ text: String) {
        DispatchQueue.main.async {
            let currentText = self.chatTextView?.string ?? ""
            let newText = currentText.isEmpty ? text : "\(currentText)\n\n\(text)"
            self.chatTextView?.string = newText
            
            let range = NSRange(location: newText.count, length: 0)
            self.chatTextView?.scrollRangeToVisible(range)
        }
    }
    
    private func replaceLast(_ text: String) {
        let currentText = chatTextView?.string ?? ""
        let lines = currentText.components(separatedBy: "\n\n")
        var newLines = lines
        if !newLines.isEmpty {
            newLines[newLines.count - 1] = text
        }
        let newText = newLines.joined(separator: "\n\n")
        chatTextView?.string = newText
        
        let range = NSRange(location: newText.count, length: 0)
        chatTextView?.scrollRangeToVisible(range)
    }

}
