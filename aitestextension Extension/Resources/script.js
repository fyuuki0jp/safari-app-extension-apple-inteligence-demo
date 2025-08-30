function extractPageContent() {
    try {
        const content = {
            url: window.location.href,
            title: document.title || 'No title',
            bodyText: document.body ? document.body.innerText : '',
            bodyHTML: document.body ? document.body.innerHTML : '',
            selectedText: window.getSelection().toString(),
            extractedAt: new Date().toISOString(),
            readyState: document.readyState
        };
        
        // Check if document is ready
        if (document.readyState !== 'complete' && document.readyState !== 'interactive') {
            console.log('AI Extension: Document not ready, readyState:', document.readyState);
        }
        
        // Limit content to avoid too much data (keep first 10000 characters)
        if (content.bodyText.length > 10000) {
            content.bodyText = content.bodyText.substring(0, 10000) + '... [content truncated]';
        }
        
        if (content.bodyHTML.length > 20000) {
            content.bodyHTML = content.bodyHTML.substring(0, 20000) + '... [HTML truncated]';
        }
        
        console.log('AI Extension: Content extracted successfully. Text length:', content.bodyText.length, 'HTML length:', content.bodyHTML.length);
        return content;
        
    } catch (error) {
        console.error('AI Extension: Error extracting content:', error);
        return {
            url: window.location.href,
            title: document.title || 'Error',
            bodyText: '',
            bodyHTML: '',
            selectedText: '',
            error: error.message,
            extractedAt: new Date().toISOString(),
            readyState: document.readyState
        };
    }
}

// Store page content for extension to retrieve
function storePageContent() {
    safeExecute('storePageContent', () => {
        console.log('AI Extension: Attempting to store page content...');
        const pageContent = extractPageContent();
        
        if (pageContent) {
            window.aiExtensionPageContent = pageContent;
            console.log('AI Extension: Page content stored successfully:', {
                url: pageContent.url,
                title: pageContent.title,
                bodyTextLength: pageContent.bodyText ? pageContent.bodyText.length : 0,
                bodyHTMLLength: pageContent.bodyHTML ? pageContent.bodyHTML.length : 0,
                readyState: pageContent.readyState
            });
            
            // Automatically try to send content to extension
            sendContentToExtension(pageContent);
        } else {
            console.warn('AI Extension: Failed to extract page content');
        }
    });
}

// Function to send content to Safari App Extension
function sendContentToExtension(pageContent) {
    console.log('AI Extension: Attempting to send content to extension');
    console.log('AI Extension: Safari object available:', typeof safari !== 'undefined');
    console.log('AI Extension: safari.self available:', typeof safari !== 'undefined' && !!safari.self);
    console.log('AI Extension: safari.self.tab available:', typeof safari !== 'undefined' && !!safari.self && !!safari.self.tab);
    
    let messageSent = false;
    
    if (typeof safari !== 'undefined' && safari.self && safari.self.tab) {
        try {
            safari.self.tab.dispatchMessage('pageContentResponse', pageContent);
            console.log('AI Extension: Successfully dispatched content to extension via safari.self.tab');
            messageSent = true;
        } catch (error) {
            console.log('AI Extension: safari.self.tab.dispatchMessage failed:', error);
        }
    }
    
    if (!messageSent && typeof safari !== 'undefined' && safari.self) {
        // Try different Safari messaging approaches
        try {
            console.log('AI Extension: Trying safari.self addEventListener approach');
            // Check what methods are available on safari.self
            console.log('AI Extension: safari.self methods:', Object.getOwnPropertyNames(safari.self));
            
            // Try to use safari.self to send message directly
            const messageEvent = new CustomEvent('safariAppExtensionMessage', {
                detail: {
                    name: 'pageContentResponse',
                    data: pageContent
                }
            });
            window.dispatchEvent(messageEvent);
            console.log('AI Extension: Sent custom event for extension');
            messageSent = true;
        } catch (error) {
            console.log('AI Extension: Alternative safari messaging failed:', error);
        }
    }
    
    if (!messageSent) {
        console.warn('AI Extension: Safari messaging API not fully available, trying alternative methods');
    }
    
    // Always try alternative messaging methods as fallback
    tryAlternativeMessaging(pageContent);
}

function tryAlternativeMessaging(pageContent) {
    console.log('AI Extension: Trying alternative messaging methods');
    
    // Method 1: Try safari.extension (legacy API that might work for sending back)
    try {
        if (typeof safari !== 'undefined' && safari.extension) {
            console.log('AI Extension: Trying safari.extension.dispatchMessage');
            safari.extension.dispatchMessage('pageContentResponse', pageContent);
            console.log('AI Extension: Successfully sent via safari.extension.dispatchMessage');
        }
    } catch (error) {
        console.log('AI Extension: safari.extension.dispatchMessage failed:', error);
    }
    
    // Method 2: Set a global flag that the extension can poll
    window.aiExtensionContentReady = true;
    window.aiExtensionContentTimestamp = Date.now();
    
    // Method 3: Try different property on safari.self
    try {
        if (typeof safari !== 'undefined' && safari.self) {
            // Try to find dispatchMessage on safari.self directly
            if (typeof safari.self.dispatchMessage === 'function') {
                console.log('AI Extension: Found safari.self.dispatchMessage, trying...');
                safari.self.dispatchMessage('pageContentResponse', pageContent);
                console.log('AI Extension: Successfully sent via safari.self.dispatchMessage');
            }
        }
    } catch (error) {
        console.log('AI Extension: safari.self.dispatchMessage failed:', error);
    }
    
    // Method 4: Try localStorage (if allowed)
    try {
        localStorage.setItem('aiExtensionPageContent', JSON.stringify({
            timestamp: Date.now(),
            data: pageContent
        }));
        console.log('AI Extension: Stored content in localStorage');
    } catch (error) {
        console.log('AI Extension: localStorage failed:', error);
    }
    
    // Method 5: Create a custom DOM event
    try {
        const event = new CustomEvent('aiExtensionContentReady', {
            detail: pageContent,
            bubbles: true,
            cancelable: true
        });
        document.dispatchEvent(event);
        window.dispatchEvent(event);
        console.log('AI Extension: Dispatched DOM custom event');
    } catch (error) {
        console.log('AI Extension: DOM event dispatch failed:', error);
    }
    
    // Method 6: Try direct property setting with notification
    try {
        window.aiExtensionContentUpdated = Date.now();
        console.log('AI Extension: Set content updated timestamp');
        
        // Try to trigger a notification event that the extension might be listening for
        if (document.body) {
            document.body.setAttribute('data-ai-extension-ready', 'true');
            document.body.setAttribute('data-ai-extension-timestamp', Date.now().toString());
            console.log('AI Extension: Set body attributes for extension detection');
        }
    } catch (error) {
        console.log('AI Extension: Direct property setting failed:', error);
    }
}

// Enhanced error handling wrapper
function safeExecute(functionName, func, fallback = null) {
    try {
        return func();
    } catch (error) {
        console.error(`AI Extension: Error in ${functionName}:`, error);
        if (fallback && typeof fallback === 'function') {
            try {
                return fallback();
            } catch (fallbackError) {
                console.error(`AI Extension: Fallback error in ${functionName}:`, fallbackError);
            }
        }
        return null;
    }
}

// API availability check
function checkAPIAvailability() {
    const apiStatus = {
        windowObject: typeof window !== 'undefined',
        documentObject: typeof document !== 'undefined',
        location: typeof window.location !== 'undefined',
        console: typeof console !== 'undefined',
        setTimeout: typeof setTimeout !== 'undefined',
        setInterval: typeof setInterval !== 'undefined',
        addEventListener: typeof window.addEventListener !== 'undefined',
        querySelector: typeof document.querySelector !== 'undefined',
        safariSelf: !!(window.safari && window.safari.self),
        safariSelfAddEventListener: !!(window.safari && window.safari.self && window.safari.self.addEventListener)
    };
    
    console.log('AI Extension: API Availability Check:', apiStatus);
    return apiStatus;
}


// Listen for messages from Safari App Extension
if (typeof safari !== 'undefined' && safari.self && safari.self.addEventListener) {
    safari.self.addEventListener("message", function(event) {
        safeExecute('safariMessage', () => {
            console.log('AI Extension: Received Safari message:', event.name);
            
            if (event.name === 'getPageContent' || event.name === 'extractAndStoreContent' || event.name === 'forceContentExtraction') {
                console.log('AI Extension: Processing', event.name, 'request');
                const pageContent = extractPageContent();
                
                // Store content for any potential retrieval
                window.aiExtensionPageContent = pageContent;
                
                console.log('AI Extension: Content extracted and stored:', {
                    title: pageContent.title,
                    bodyTextLength: pageContent.bodyText ? pageContent.bodyText.length : 0,
                    bodyHTMLLength: pageContent.bodyHTML ? pageContent.bodyHTML.length : 0,
                    url: pageContent.url
                });
                
                // Always try to send content back
                sendContentToExtension(pageContent);
                
                console.log('AI Extension: Page content processed and stored');
            } else if (event.name === 'checkAndSendContent') {
                console.log('AI Extension: Check and send content request');
                
                if (window.aiExtensionPageContent) {
                    console.log('AI Extension: Content available, sending to extension');
                    sendContentToExtension(window.aiExtensionPageContent);
                } else {
                    console.log('AI Extension: No content available, extracting now');
                    storePageContent();
                }
            } else if (event.name === 'checkContentReady') {
                console.log('AI Extension: Content ready check - content available:', !!window.aiExtensionPageContent);
                
                if (window.aiExtensionPageContent) {
                    console.log('AI Extension: Available content:', {
                        title: window.aiExtensionPageContent.title,
                        bodyTextLength: window.aiExtensionPageContent.bodyText ? window.aiExtensionPageContent.bodyText.length : 0,
                        bodyHTMLLength: window.aiExtensionPageContent.bodyHTML ? window.aiExtensionPageContent.bodyHTML.length : 0
                    });
                }
            }
        });
    });
    console.log('AI Extension: Safari message listener added successfully');
} else {
    console.warn('AI Extension: Safari messaging API not available');
}

// Note: DOMContentLoaded handling moved to the new multiple timing execution section below

// Also store content when page changes (for SPAs)
if (document.body) {
    let lastUrl = window.location.href;
    
    try {
        const observer = new MutationObserver(() => {
            if (window.location.href !== lastUrl) {
                console.log('AI Extension: URL changed, updating content');
                lastUrl = window.location.href;
                setTimeout(() => {
                    storePageContent();
                }, 1000);
            }
        });
        
        observer.observe(document.body, { childList: true, subtree: true });
        console.log('AI Extension: Mutation observer set up successfully');
        
    } catch (error) {
        console.error('AI Extension: Error setting up mutation observer:', error);
    }
} else {
    console.warn('AI Extension: document.body not available for mutation observer');
}

// Store script loaded info for extension to retrieve
safeExecute('scriptLoaded', () => {
    console.log('AI Extension: Script loaded successfully');
    
    // Check API availability
    const apiStatus = checkAPIAvailability();
    
    // Store script loaded info
    window.aiExtensionScriptInfo = {
        timestamp: new Date().toISOString(),
        url: window.location.href,
        readyState: document.readyState,
        apiAvailability: apiStatus,
        loaded: true
    };
    
    console.log('AI Extension: Script info stored for extension retrieval');
});

// === IMMEDIATE AND MULTIPLE TIMING EXECUTION ===

// 1. Immediate execution - try to store content right away
console.log('AI Extension: Attempting immediate content extraction on script load');
console.log('AI Extension: Current readyState:', document.readyState);
console.log('AI Extension: Document body available:', !!document.body);

// Try immediate extraction if document and body are available
if (document.body) {
    console.log('AI Extension: Document body available, attempting immediate extraction');
    storePageContent();
} else {
    console.log('AI Extension: Document body not yet available, will try later');
}

// 2. Document ready state check and execution
function tryContentExtractionByState() {
    console.log('AI Extension: Checking document state for content extraction');
    console.log('AI Extension: readyState:', document.readyState);
    console.log('AI Extension: body available:', !!document.body);
    console.log('AI Extension: Current aiExtensionPageContent:', !!window.aiExtensionPageContent);
    
    if (document.readyState === 'complete' || document.readyState === 'interactive') {
        if (document.body && !window.aiExtensionPageContent) {
            console.log('AI Extension: Document ready, extracting content');
            storePageContent();
        } else if (window.aiExtensionPageContent) {
            console.log('AI Extension: Content already extracted, skipping');
        } else {
            console.log('AI Extension: Document ready but body not available');
        }
    }
}

// 3. Multiple execution timings
if (document.readyState === 'loading') {
    console.log('AI Extension: Document still loading, setting up event listeners');
    
    document.addEventListener('DOMContentLoaded', function() {
        console.log('AI Extension: DOMContentLoaded fired');
        setTimeout(() => {
            tryContentExtractionByState();
        }, 100);
    });
    
    window.addEventListener('load', function() {
        console.log('AI Extension: Window load fired');
        setTimeout(() => {
            tryContentExtractionByState();
        }, 200);
    });
} else {
    console.log('AI Extension: Document already loaded, trying extraction');
    tryContentExtractionByState();
}

// 4. Fallback timer - ensure content is extracted within 2 seconds
setTimeout(() => {
    if (!window.aiExtensionPageContent && document.body) {
        console.log('AI Extension: Fallback timer - forcing content extraction');
        storePageContent();
    } else if (window.aiExtensionPageContent) {
        console.log('AI Extension: Fallback timer - content already available');
    } else {
        console.log('AI Extension: Fallback timer - document body still not available');
    }
}, 2000);