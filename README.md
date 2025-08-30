# Safari App Extension Apple Intelligence Demo

A Safari App Extension that demonstrates integration with Apple's FoundationModels framework to provide AI-powered chat assistance with page content context.

## Features

- 🤖 **AI Chat Interface**: Built-in chat interface using Apple's FoundationModels
- 📄 **Page Content Integration**: Automatically extracts and includes webpage content as context
- 🔍 **Smart Content Extraction**: Extracts page titles, body text, and HTML content
- 🛡️ **Privacy-Focused**: All processing happens locally using Apple Intelligence
- 🌐 **Universal Support**: Works with any website (with proper permissions)

## Requirements

- macOS 26.0+ (for FoundationModels framework)
- Xcode 26.0+
- Safari 26.0+
- Apple Silicon Mac (recommended for Apple Intelligence features)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/safari-app-extension-apple-intelligence-demo.git
cd safari-app-extension-apple-intelligence-demo
```

2. Open the project in Xcode:
```bash
open aitestextension.xcodeproj
```

3. Build and run the project (⌘+R)

4. Enable the extension in Safari:
   - Go to Safari > Settings > Extensions
   - Find "AI Chat Assistant" and enable it
   - Set permissions to "Allow" for websites you want to use it with

## Usage

1. **Opening the Extension**: Click the AI Chat Assistant icon in Safari's toolbar
2. **Chat Interface**: Type messages in the input field and click "Send" or press Enter
3. **Page Content**: Toggle "Include page content" to add webpage context to your questions
4. **Clear Chat**: Use the "Clear" button to reset the conversation

## Technical Architecture

### Core Components

- **SafariExtensionViewController**: Main UI controller with chat interface
- **SafariExtensionHandler**: Handles communication between extension and content script
- **Content Script (script.js)**: Extracts page content and manages communication
- **FoundationModels Integration**: Uses Apple's SystemLanguageModel for AI responses

### Content Extraction

The extension uses a sophisticated content extraction system:

- **Multiple Timing Execution**: Extracts content at script load, DOMContentLoaded, window load, and fallback timer
- **Simplified Approach**: Uses `document.body.innerText` and `innerHTML` for reliable extraction
- **Multiple Communication Channels**: Tries various methods to send content to the extension
- **Fallback Mechanisms**: Ensures content extraction works across different website types

### Communication Flow

1. Extension requests page content via `dispatchMessageToScript`
2. Content script extracts page information
3. Multiple sending attempts using various Safari APIs
4. Extension receives and processes the content
5. AI model generates contextual responses

## Development

### Project Structure

```
aitestextension/
├── aitestextension Extension/
│   ├── SafariExtensionViewController.swift    # Main UI controller
│   ├── SafariExtensionHandler.swift          # Message handling
│   ├── Base.lproj/
│   │   └── SafariExtensionViewController.xib  # UI layout
│   ├── Resources/
│   │   └── script.js                         # Content script
│   └── Info.plist                           # Extension configuration
├── aitestextension/                          # Host app
└── README.md
```

### Key Implementation Details

#### Content Script Features
- **Immediate Execution**: Tries content extraction as soon as possible
- **Event-Based Triggers**: Responds to DOMContentLoaded and window load events
- **Safari Message Handling**: Processes messages from the extension
- **Multiple Send Methods**: Uses various APIs to communicate back to extension

#### Swift Extension Features
- **Conditional FoundationModels**: Gracefully handles systems without Apple Intelligence
- **Timeout Handling**: 8-second timeout with fallback content
- **Debug Information**: Comprehensive debugging and status information
- **Message Polling**: Actively requests content at multiple intervals

### Building and Testing

1. Build the project in Xcode
2. The extension will be installed automatically when running
3. Test on various websites (example.com is good for basic testing)
4. Check browser console for "AI Extension:" logs to debug content extraction
5. Use the debug button in the extension for detailed status information

## Troubleshooting

### Common Issues

**"Content extraction timed out"**
- Check Safari extension permissions for the website
- Verify the website allows content script execution
- Check browser console for JavaScript errors

**"FoundationModels not available"**
- Ensure you're running macOS 15.0+
- Check that Apple Intelligence is available on your system
- The extension will still work for page content extraction

**Extension not appearing in Safari**
- Rebuild and run the project from Xcode
- Check Safari > Settings > Extensions
- Ensure the extension is enabled

### Debug Information

The extension provides comprehensive debug information:
- Click "Clear" → "Show Debug Info" for detailed status
- Check browser console for "AI Extension:" messages
- Monitor extension status and content extraction details

## Privacy & Security

- All AI processing happens locally using Apple Intelligence
- No data is sent to external servers
- Page content is only processed when explicitly requested
- Follows Safari App Extension security guidelines

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly across different websites
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Built with Apple's FoundationModels framework
- Uses Safari App Extension APIs
- Inspired by the need for privacy-focused AI browsing assistance

---

**Note**: This is a demonstration project showcasing Safari App Extension capabilities with Apple Intelligence. For production use, consider additional error handling, user experience improvements, and thorough testing across various websites and edge cases.
