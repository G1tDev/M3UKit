# Migration Guide: Original M3UKit → Enhanced M3UKit

This guide helps you migrate from the original [M3UKit](https://github.com/omaralbeik/M3UKit) to this enhanced version with minimal code changes.

## 🔄 Quick Migration

### 1. Update Package Dependencies

**Before (Original M3UKit):**
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/omaralbeik/M3UKit.git", from: "0.8.1")
]

// Podfile
pod 'M3UKit', :git => 'https://github.com/omaralbeik/M3UKit.git', :tag => '0.8.1'
```

**After (Enhanced M3UKit):**
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/M3UKit.git", from: "2.0.0")
]

// Podfile
pod 'M3UKit', :git => 'https://github.com/YOUR_USERNAME/M3UKit.git', :tag => '2.0.0'
```

### 2. Update Import Statement

**No changes needed** - the import statement remains the same:
```swift
import M3UKit
```

### 3. Update Parser Initialization (Optional but Recommended)

**Before:**
```swift
let parser = PlaylistParser()
```

**After (Enhanced with new options):**
```swift
let parser = PlaylistParser(options: [
    .removeSeriesInfoFromText,
    .extractIdFromURL,
    .strictURLValidation,      // New: Better URL validation
    .skipSessionData           // New: Handle problematic playlists
])
```

## 🆕 New Features You Can Use

### Enhanced Error Handling
```swift
// Before: Parser would stop on first error
let playlist = try parser.parse(source)

// After: Better error handling with validation
if parser.validateSource(source) {
    let playlist = try parser.parse(source)
} else {
    print("Invalid playlist format")
}
```

### IPTV-Specific Methods
```swift
// New convenience methods for IPTV apps
let liveChannels = playlist.liveChannels
let newsChannels = playlist.channels(in: "News")
let searchResults = playlist.searchChannels(query: "BBC")
let channel = playlist.channel(withId: "BBCNews.uk")
```

### Better URL Validation
```swift
// New: Strict URL validation for streaming
let strictParser = PlaylistParser(options: [.strictURLValidation])
```

## 🐛 What's Fixed

### Critical Bug Fixes
- **Line number tracking** - No more wrong metadata association
- **Session data handling** - Prevents interference with streams
- **URL validation** - Ensures valid streaming links
- **Error handling** - Continues parsing instead of stopping

### Performance Improvements
- **Better line processing** - More efficient parsing
- **Caching support** - Faster repeated access
- **Memory optimization** - Reduced memory usage

## 📱 IPTV Player Integration

### Before (Original M3UKit)
```swift
let parser = PlaylistParser()
let playlist = try parser.parse(playlistURL)

// This could fail or return wrong streams due to parsing bugs
for media in playlist.medias {
    player.play(media.url) // Might be wrong stream!
}
```

### After (Enhanced M3UKit)
```swift
let parser = PlaylistParser(options: [.strictURLValidation, .skipSessionData])

// Validate playlist first
guard parser.validateSource(playlistURL) else {
    print("Invalid playlist format")
    return
}

let playlist = try parser.parse(playlistURL)

// Now you get the correct streams!
for media in playlist.medias {
    player.play(media.url) // Correct stream guaranteed!
}

// Use new IPTV features
let liveChannels = playlist.liveChannels
let newsChannels = playlist.channels(in: "News")
```

## 🔧 Troubleshooting

### Common Issues

**1. "No such module 'M3UKit'"**
- Make sure you've updated the package URL to your fork
- Clean build folder and rebuild

**2. "Playlist parsing still fails"**
- Try using the new options: `.strictURLValidation` and `.skipSessionData`
- Use `parser.validateSource()` before parsing

**3. "Performance issues"**
- Use `CachedPlaylistSource` for repeated access
- Enable `.skipSessionData` for large playlists

### Getting Help

If you encounter issues:
1. Check that you're using the enhanced version (2.0.0+)
2. Try the new parser options
3. Use the validation methods
4. Report issues in the GitHub repository

## ✅ Migration Checklist

- [ ] Updated package dependencies to your fork
- [ ] Updated parser initialization (optional but recommended)
- [ ] Tested playlist parsing with your IPTV content
- [ ] Verified stream links are correct
- [ ] Implemented new IPTV-specific features (optional)

## 🎯 Benefits After Migration

- ✅ **Correct stream links** - No more playing wrong streams
- ✅ **Better error handling** - Robust parsing of malformed playlists
- ✅ **IPTV-specific features** - Channel filtering, search, and grouping
- ✅ **Performance improvements** - Faster parsing and better memory usage
- ✅ **Future-proof** - Support for modern playlist formats

Your IPTV app should now work flawlessly with accurate stream parsing! 🚀
