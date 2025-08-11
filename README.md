# M3UKit - Enhanced IPTV Playlist Parser

A Swift library for parsing M3U/M3U8 playlists with enhanced IPTV support and bug fixes.

## 🚀 What's New in This Enhanced Version

This is an enhanced fork of the original [M3UKit](https://github.com/omaralbeik/M3UKit) with critical bug fixes and IPTV-specific improvements:

### 🔧 Critical Bug Fixes
- **Fixed line number tracking bug** that was causing incorrect parsing
- **Improved session data handling** to prevent interference with stream parsing
- **Enhanced URL validation** with strict mode for better stream link accuracy
- **Better error handling** that continues parsing instead of stopping on first error

### 🆕 New Features
- **Strict URL validation** option to ensure only valid streaming URLs are accepted
- **Session data skipping** option to handle problematic playlist formats
- **Enhanced attribute parsing** for modern IPTV playlist features
- **Playlist format detection** (M3U, M3U8, PLS)
- **Caching support** for better performance
- **IPTV-specific convenience methods** for channel filtering and search

### 📱 IPTV Player Improvements
- **Better stream link accuracy** - no more playing wrong streams
- **Support for complex playlist formats** commonly used by IPTV providers
- **Enhanced channel metadata** including EPG URLs, aspect ratios, audio tracks
- **Robust error handling** for malformed playlists

## 📦 Installation

### Swift Package Manager

Add this repository to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/M3UKit.git", from: "2.0.0")
]
```

### CocoaPods

Add this to your `Podfile`:

```ruby
pod 'M3UKit', :git => 'https://github.com/YOUR_USERNAME/M3UKit.git', :tag => '2.0.0'
```

## 🎯 Usage

### Basic Parsing

```swift
import M3UKit

let parser = PlaylistParser(options: .all)
let playlist = try parser.parse(playlistURL)
```

### Enhanced Options

```swift
let parser = PlaylistParser(options: [
    .removeSeriesInfoFromText,
    .extractIdFromURL,
    .strictURLValidation,      // New: Ensures valid streaming URLs
    .skipSessionData           // New: Skips problematic session data
])
```

### IPTV-Specific Features

```swift
// Get all live channels
let liveChannels = playlist.liveChannels

// Filter by group
let newsChannels = playlist.channels(in: "News")

// Search channels
let searchResults = playlist.searchChannels(query: "BBC")

// Get channel by ID
let channel = playlist.channel(withId: "BBCNews.uk")
```

### Validation

```swift
// Validate playlist before parsing
if parser.validateSource(playlistSource) {
    let playlist = try parser.parse(playlistSource)
    // Process playlist
}
```

## 🔍 What Was Fixed

### Original Issues
1. **Line number tracking bug** - The parser was incorrectly tracking line numbers, causing wrong metadata association
2. **Session data interference** - `#EXT-X-SESSION-DATA` lines were interfering with stream parsing
3. **Poor error handling** - Parser stopped on first error instead of continuing
4. **Weak URL validation** - Accepted invalid URLs that could cause playback issues

### How It's Fixed
1. **Proper line enumeration** using `enumerated()` instead of manual counting
2. **Session data handling** with option to skip problematic lines
3. **Enhanced error handling** that continues parsing and collects errors
4. **Strict URL validation** with streaming protocol and extension checks
5. **Better playlist structure** with IPTV-specific convenience methods

## 🧪 Testing

The enhanced version includes comprehensive tests and can handle the same test cases as the original, plus new edge cases:

```bash
swift test
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Original M3UKit by [Omar Albeik](https://github.com/omaralbeik)
- Enhanced for IPTV use cases with better error handling and validation

## 🐛 Reporting Issues

If you find any issues with this enhanced version, please report them in the GitHub issues section. This fork specifically addresses IPTV playlist parsing problems and aims to provide a more robust solution for streaming applications.
