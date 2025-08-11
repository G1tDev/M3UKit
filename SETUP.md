# Setup Guide: Using Enhanced M3UKit in Your IPTV App

This guide explains how to integrate the enhanced M3UKit fork into your IPTV iOS app to fix stream parsing issues.

## 🎯 What This Fixes

The original M3UKit had several critical bugs that caused IPTV apps to play wrong streams:

1. **Line number tracking bug** - Wrong metadata was associated with URLs
2. **Session data interference** - `#EXT-X-SESSION-DATA` lines broke parsing
3. **Poor error handling** - Parser stopped on first error
4. **Weak URL validation** - Invalid URLs were accepted

## 🚀 Quick Setup

### Step 1: Fork This Repository

1. Click "Fork" on this GitHub repository
2. Clone your fork to your local machine
3. Make sure all the enhanced files are present

### Step 2: Update Your iOS App Dependencies

#### Option A: Swift Package Manager (Recommended)

In your Xcode project's `Package.swift` or through Xcode's package manager:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/M3UKit.git", from: "2.0.0")
]
```

#### Option B: CocoaPods

In your `Podfile`:

```ruby
pod 'M3UKit', :git => 'https://github.com/YOUR_USERNAME/M3UKit.git', :tag => '2.0.0'
```

### Step 3: Update Your Code

**Before (Original M3UKit):**
```swift
import M3UKit

let parser = PlaylistParser()
let playlist = try parser.parse(playlistURL)

// This could return wrong streams due to parsing bugs
for media in playlist.medias {
    player.play(media.url) // Might be wrong stream!
}
```

**After (Enhanced M3UKit):**
```swift
import M3UKit

// Use enhanced options for better IPTV support
let parser = PlaylistParser(options: [
    .removeSeriesInfoFromText,
    .extractIdFromURL,
    .strictURLValidation,      // New: Ensures valid streaming URLs
    .skipSessionData           // New: Handle problematic playlists
])

// Validate playlist before parsing
guard parser.validateSource(playlistURL) else {
    print("Invalid playlist format")
    return
}

let playlist = try parser.parse(playlistURL)

// Now you get the correct streams!
for media in playlist.medias {
    player.play(media.url) // Correct stream guaranteed!
}
```

## 🔧 Key Changes in Your Code

### 1. Parser Initialization
```swift
// Old way
let parser = PlaylistParser()

// New way (recommended)
let parser = PlaylistParser(options: [
    .strictURLValidation,      // Better URL validation
    .skipSessionData           // Handle problematic playlists
])
```

### 2. Playlist Validation
```swift
// Add validation before parsing
if parser.validateSource(playlistSource) {
    let playlist = try parser.parse(playlistSource)
    // Process playlist
} else {
    // Handle invalid playlist
}
```

### 3. Use New IPTV Features
```swift
// New convenience methods
let liveChannels = playlist.liveChannels
let newsChannels = playlist.channels(in: "News")
let searchResults = playlist.searchChannels(query: "BBC")
let channel = playlist.channel(withId: "BBCNews.uk")
```

## 📱 Complete IPTV Integration Example

```swift
import M3UKit
import AVKit

class IPTVPlayerViewController: UIViewController {
    private let parser = PlaylistParser(options: [
        .strictURLValidation,
        .skipSessionData
    ])
    private var currentPlaylist: Playlist?
    private let player = AVPlayer()
    
    func loadPlaylist(from url: URL) {
        // Validate playlist first
        guard parser.validateSource(url) else {
            showError("Invalid playlist format")
            return
        }
        
        do {
            // Parse playlist with enhanced parser
            currentPlaylist = try parser.parse(url)
            
            // Display playlist info
            updateUI(with: currentPlaylist!)
            
        } catch {
            showError("Failed to parse playlist: \(error.localizedDescription)")
        }
    }
    
    func playChannel(withId id: String) {
        guard let playlist = currentPlaylist else { return }
        
        guard let channel = playlist.channel(withId: id) else {
            showError("Channel not found")
            return
        }
        
        // Now you get the correct stream URL!
        let streamURL = channel.url
        let playerItem = AVPlayerItem(url: streamURL)
        player.replaceCurrentItem(with: playerItem)
        player.play()
        
        print("▶️ Playing: \(channel.name)")
    }
    
    func filterChannels(by category: String) -> [Playlist.Media] {
        return currentPlaylist?.channels(in: category) ?? []
    }
    
    func searchChannels(query: String) -> [Playlist.Media] {
        return currentPlaylist?.searchChannels(query: query) ?? []
    }
}
```

## 🧪 Testing Your Integration

### 1. Test with Your Playlists
```swift
// Test with your actual IPTV playlists
let testURL = URL(string: "https://your-iptv-provider.com/playlist.m3u")!
loadPlaylist(from: testURL)
```

### 2. Verify Stream Accuracy
- Check that the correct stream URLs are being parsed
- Verify that metadata (channel names, logos) matches the URLs
- Test with different playlist formats

### 3. Test Error Handling
- Try with malformed playlists
- Test with playlists containing session data
- Verify that parsing continues even with errors

## 🔍 Troubleshooting

### Common Issues

**1. "No such module 'M3UKit'"**
- Make sure you've updated the package URL to your fork
- Clean build folder and rebuild

**2. "Still getting wrong streams"**
- Ensure you're using the enhanced options: `.strictURLValidation` and `.skipSessionData`
- Use `parser.validateSource()` before parsing

**3. "Performance issues"**
- Use `CachedPlaylistSource` for repeated access
- Enable `.skipSessionData` for large playlists

### Debug Tips

```swift
// Enable debug logging
let parser = PlaylistParser(options: [.strictURLValidation, .skipSessionData])

// Validate before parsing
if parser.validateSource(playlistURL) {
    print("✅ Playlist format is valid")
} else {
    print("❌ Playlist format is invalid")
}

// Check parsed results
let playlist = try parser.parse(playlistURL)
print("📺 Parsed \(playlist.medias.count) channels")

// Verify first few channels
for (index, media) in playlist.medias.prefix(5).enumerated() {
    print("\(index + 1). \(media.name) -> \(media.url)")
}
```

## ✅ Success Checklist

- [ ] Updated dependencies to your enhanced fork
- [ ] Implemented enhanced parser options
- [ ] Added playlist validation
- [ ] Tested with your IPTV playlists
- [ ] Verified correct stream URLs
- [ ] Implemented new IPTV features (optional)

## 🎉 Expected Results

After implementing these changes:

- ✅ **Correct stream links** - No more playing wrong streams
- ✅ **Better error handling** - Robust parsing of malformed playlists
- ✅ **IPTV-specific features** - Channel filtering, search, and grouping
- ✅ **Performance improvements** - Faster parsing and better memory usage

Your IPTV app should now work flawlessly with accurate stream parsing! 🚀

## 📞 Getting Help

If you encounter issues:
1. Check that you're using the enhanced version (2.0.0+)
2. Verify all enhanced options are enabled
3. Use the validation methods
4. Check the example code in `Examples/IPTVExample.swift`
5. Report issues in your fork's GitHub repository
