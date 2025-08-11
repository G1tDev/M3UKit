//
// M3UKit
//
// Copyright (c) 2022 Omar Albeik
// Enhanced by [Your Name] - Added better error handling and playlist format support
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

/// Playlist source.
public protocol PlaylistSource {
  /// Playlist contents raw string.
  var rawString: String? { get }
  
  /// Validate if this source is a valid playlist
  var isValid: Bool { get }
  
  /// Get the playlist format type
  var format: PlaylistFormat { get }
}

/// Supported playlist formats
public enum PlaylistFormat: String, CaseIterable {
  case m3u = "M3U"
  case m3u8 = "M3U8"
  case pls = "PLS"
  case unknown = "Unknown"
}

extension String: PlaylistSource {
  public var rawString: String? {
    return self
  }
  
  public var isValid: Bool {
    return self.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: "#EXTM3U")
  }
  
  public var format: PlaylistFormat {
    if self.contains("#EXTM3U") {
      return .m3u
    } else if self.contains("#EXT-X-VERSION") {
      return .m3u8
    } else if self.contains("[playlist]") {
      return .pls
    }
    return .unknown
  }
}

extension URL: PlaylistSource {
  public var rawString: String? {
    do {
      let content = try String(contentsOf: self, encoding: .utf8)
      // Try alternative encodings if UTF-8 fails
      if content.isEmpty {
        return try String(contentsOf: self, encoding: .isoLatin1)
      }
      return content
    } catch {
      // Try with different encoding
      do {
        return try String(contentsOf: self, encoding: .isoLatin1)
      } catch {
        return nil
      }
    }
  }
  
  public var isValid: Bool {
    guard let content = rawString else { return false }
    return content.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: "#EXTM3U")
  }
  
  public var format: PlaylistFormat {
    guard let content = rawString else { return .unknown }
    return content.format
  }
}

/// Enhanced playlist source with caching and validation
public class CachedPlaylistSource: PlaylistSource {
  private let source: PlaylistSource
  private var cachedString: String?
  private var lastValidation: Bool?
  
  public init(_ source: PlaylistSource) {
    self.source = source
  }
  
  public var rawString: String? {
    if let cached = cachedString {
      return cached
    }
    cachedString = source.rawString
    return cachedString
  }
  
  public var isValid: Bool {
    if let cached = lastValidation {
      return cached
    }
    lastValidation = source.isValid
    return lastValidation ?? false
  }
  
  public var format: PlaylistFormat {
    return source.format
  }
  
  /// Clear the cache
  public func clearCache() {
    cachedString = nil
    lastValidation = nil
  }
}
