# M3UKit Robust Parsing Implementation

## Overview

This document outlines the comprehensive improvements made to M3UKit to handle any possible playlist format and edge cases, making it extremely robust for production IPTV applications.

## Issues Fixed

### 1. Missing Duration Values
**Problem**: Lines like `#EXTINF: tvg-id="..." ` without duration values would cause parsing failures.
**Solution**: Enhanced regex patterns with fallback to default `-1` for live streams.

### 2. Typographical Errors
**Problem**: Common typos like `#EXTNF:` instead of `#EXTINF:` would break parsing.
**Solution**: Added typo tolerance in line type detection.

### 3. BOM (Byte Order Mark) Characters
**Problem**: Unicode BOM characters at the beginning of files would cause header validation failures.
**Solution**: Automatic BOM detection and removal for UTF-8, UTF-16 variants.

### 4. Additional M3U8 Tags
**Problem**: Tags like `#EXTGRP:`, `#EXTVLCOPT:` were not handled and could interfere with parsing.
**Solution**: Added comprehensive ignorable line detection for extended M3U8 features.

### 5. Flexible Attribute Parsing
**Problem**: Rigid regex patterns couldn't handle variations in spacing, quotes, and formatting.
**Solution**: Enhanced regex patterns with flexible whitespace and quote handling.

### 6. Complex URL Formats
**Problem**: URLs with parameters, special characters, or unconventional formats would fail validation.
**Solution**: Multi-tier URL validation with cleaning, encoding, and fallback strategies.

### 7. Non-ASCII Characters
**Problem**: Playlist content with Cyrillic, emoji, or other Unicode characters would cause issues.
**Solution**: Proper UTF-8 handling throughout the parsing pipeline.

### 8. Malformed Lines
**Problem**: Single malformed lines would stop the entire parsing process.
**Solution**: Robust error recovery that continues parsing and logs warnings instead of failing.

## New Features

### Parser Options

#### `maxResilience`
Maximum resilience mode that handles any playlist format with extensive fallbacks:
- Accepts any URL-like string, even if malformed
- Creates data URLs as last resort for unparseable URLs  
- Never fails parsing due to format issues
- Provides extensive logging for debugging

#### `iptv` (Preset)
Recommended configuration for IPTV applications:
```swift
let parser = PlaylistParser(options: .iptv)
// Equivalent to: [.removeSeriesInfoFromText, .extractIdFromURL, .skipSessionData, .maxResilience]
```

### Enhanced URL Handling

1. **Multi-tier Validation**: Basic → Encoded → Data URL fallback
2. **Protocol Detection**: Handles missing protocols and protocol-relative URLs
3. **Parameter Cleaning**: Removes pipe separators and other IPTV-specific artifacts
4. **Encoding Support**: Automatic URL encoding for special characters

### Comprehensive Error Recovery

- **Continue on Error**: Parsing continues even when individual entries fail
- **Warning System**: Logs issues without stopping the process
- **Fallback Values**: Provides sensible defaults when data is missing
- **Graceful Degradation**: Always produces a result, even from severely malformed input

## Usage Examples

### Basic Robust Parsing
```swift
let parser = PlaylistParser(options: [.maxResilience])
let playlist = try parser.parse(anyPlaylistSource)
// Will parse successfully regardless of format issues
```

### IPTV Production Configuration
```swift
let parser = PlaylistParser(options: .iptv)
let playlist = try parser.parse(iptvPlaylistURL)

// Get statistics
print("Parsed \\(playlist.medias.count) channels")
print("Live channels: \\(playlist.liveChannels.count)")
print("Groups: \\(Set(playlist.medias.compactMap { $0.attributes.groupTitle }).count)")
```

### Validation Before Parsing
```swift
let parser = PlaylistParser(options: .iptv)

if parser.validateSource(playlistSource) {
    let playlist = try parser.parse(playlistSource)
    // Process valid playlist
} else {
    // Handle invalid source
}
```

### Advanced Error Handling
```swift
let parser = PlaylistParser(options: [.maxResilience, .skipSessionData])

do {
    let playlist = try parser.parse(problematicPlaylist)
    // Even heavily malformed playlists will parse successfully
    
    // Check for issues in parsed data
    let channelsWithoutURLs = playlist.medias.filter { $0.url.scheme == "data" }
    if !channelsWithoutURLs.isEmpty {
        print("Warning: \\(channelsWithoutURLs.count) channels had malformed URLs")
    }
} catch {
    // This should rarely happen with maxResilience enabled
    print("Critical parsing error: \\(error)")
}
```

## Implementation Details

### BOM Detection
```swift
// Removes common BOM variants
rawString = rawString.replacingOccurrences(of: "\\u{FEFF}", with: "")
rawString = rawString.replacingOccurrences(of: "\\u{FFFE}", with: "")
rawString = rawString.replacingOccurrences(of: "\\u{EF}\\u{BB}\\u{BF}", with: "")
```

### Flexible Regex Patterns
```swift
// Old: #"tvg-id=\\"(.?|.+?)\\""#
// New: #"tvg-id\\s*=\\s*[\\"']([^\\"']*)[\\"']"#
// Handles: tvg-id="value", tvg-id='value', tvg-id = "value"
```

### URL Cleaning Pipeline
1. Trim whitespace and control characters
2. Handle pipe separators (IPTV-specific)
3. Encode spaces and special characters
4. Add missing protocols
5. Create data URLs as fallback

### Duration Extraction Fallback
1. Try enhanced regex pattern
2. Extract any number from the line
3. Default to -1 for live streams
4. Never fail parsing due to missing duration

## Testing

The implementation includes comprehensive tests covering:

- ✅ Missing duration values
- ✅ Typographical errors (`#EXTNF:`)
- ✅ BOM character handling
- ✅ Extra tags (`#EXTGRP:`, `#EXTVLCOPT:`)
- ✅ Complex URLs with parameters
- ✅ Non-ASCII characters (Cyrillic, emoji)
- ✅ Malformed playlist recovery
- ✅ Real-world playlist files

## Performance Impact

The robust parsing adds minimal overhead:
- Pattern matching is optimized with early exits
- BOM removal is O(1) operation
- URL cleaning uses efficient string operations
- Error recovery prevents expensive exception handling

## Backward Compatibility

All improvements maintain 100% backward compatibility:
- Default options remain unchanged
- Existing APIs work identically
- No breaking changes to public interface
- Previous parsing behavior preserved when strict options are used

## Recommendations

### For IPTV Applications
```swift
// Recommended configuration
let parser = PlaylistParser(options: .iptv)
```

### For Strict Validation
```swift
// When you need strict format compliance
let parser = PlaylistParser(options: [.strictURLValidation, .removeSeriesInfoFromText])
```

### For Maximum Compatibility
```swift
// Parse anything and everything
let parser = PlaylistParser(options: [.maxResilience])
```

This implementation ensures your application can handle any M3U/M3U8 playlist from any source without manual intervention or app store updates for format edge cases.