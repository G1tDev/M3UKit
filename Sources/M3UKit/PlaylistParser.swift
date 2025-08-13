//
// M3UKit
//
// Copyright (c) 2022 Omar Albeik
// Enhanced by [Your Name] - Fixed parsing issues and improved stream handling
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

/// A class to parse `Playlist` objects from a `PlaylistSource`.
public final class PlaylistParser {

  /// Playlist parser options
  public struct Options: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    /// Remove season number and episode number "S--E--" from the name of media.
    public static let removeSeriesInfoFromText = Options(rawValue: 1 << 0)

    /// Extract id from the URL (usually last path component removing the extension)
    public static let extractIdFromURL = Options(rawValue: 1 << 1)
    
    /// Strict URL validation - only accept valid URLs
    public static let strictURLValidation = Options(rawValue: 1 << 2)
    
    /// Skip session data lines that might interfere with parsing
    public static let skipSessionData = Options(rawValue: 1 << 3)
    
    /// Maximum resilience mode - handles any playlist format with fallbacks
    public static let maxResilience = Options(rawValue: 1 << 4)
    
    /// All available options.
    public static let all: Options = [
      .removeSeriesInfoFromText,
      .extractIdFromURL,
      .strictURLValidation,
      .skipSessionData,
      .maxResilience
    ]
    
    /// Recommended options for IPTV applications
    public static let iptv: Options = [
      .removeSeriesInfoFromText,
      .extractIdFromURL,
      .skipSessionData,
      .maxResilience
    ]
  }

  /// Parser options.
  public let options: Options

  /// Create a new parser.
  /// - Parameter options: Parser options, defaults to .all
  public init(options: Options = []) {
    self.options = options
  }

  /// Parse a playlist.
  /// - Parameter input: source.
  /// - Returns: playlist.
  public func parse(_ input: PlaylistSource) throws -> Playlist {
    let rawString = try extractRawString(from: input)

    var medias: [Playlist.Media] = []
    var lastMetadataLine: String?
    var lastURL: URL?
    var mediaMetadataParsingError: Error?
    var currentLineNumber = 0

    let lines = rawString.components(separatedBy: .newlines)
    
    for (index, line) in lines.enumerated() {
      let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
      
      // Skip empty lines
      guard !trimmedLine.isEmpty else { continue }
      
      currentLineNumber = index + 1
      
      // Skip ignorable lines (EXTGRP, EXTVLCOPT, etc.)
      if self.isIgnorableLine(trimmedLine) {
        continue
      }
      
      if self.isInfoLine(trimmedLine) {
        lastMetadataLine = trimmedLine
      } else if self.isSessionLine(trimmedLine) && options.contains(.skipSessionData) {
        // Skip session data lines if option is enabled
        continue
      } else if self.isValidURL(trimmedLine) {
        let cleanedURL = self.cleanURL(trimmedLine)
        lastURL = URL(string: cleanedURL)
      } else if !trimmedLine.hasPrefix("#") && !trimmedLine.isEmpty {
        // This might be a URL - try to process it anyway
        let cleanedURL = self.cleanURL(trimmedLine)
        if let url = URL(string: cleanedURL) {
          lastURL = url
        } else if options.contains(.strictURLValidation) && !options.contains(.maxResilience) {
          mediaMetadataParsingError = ParsingError.invalidURL(currentLineNumber, trimmedLine)
          // Continue parsing to collect all errors
        } else {
          // In lenient mode or max resilience, try to create a URL anyway
          if let encodedURL = trimmedLine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
             let url = URL(string: encodedURL) {
            lastURL = url
          } else if options.contains(.maxResilience) {
            // Max resilience: create a data URL as last resort
            lastURL = URL(string: "data:text/plain," + (trimmedLine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmedLine))
          }
        }
      }

      // Try to create media entry if we have both metadata and URL
      if let metadataLine = lastMetadataLine, let url = lastURL {
        do {
          let metadata = try self.parseMetadata(line: currentLineNumber, rawString: metadataLine, url: url)
          let kind = self.parseMediaKind(url)
          medias.append(.init(metadata: metadata, kind: kind, url: url))
          lastMetadataLine = nil
          lastURL = nil
        } catch {
          // Log the error but continue parsing
          print("Warning: Failed to parse metadata at line \(currentLineNumber): \(error.localizedDescription)")
          // Don't stop parsing - continue with next entry
          lastMetadataLine = nil
          lastURL = nil
        }
      }
    }
    
    // Check if we have any media entries
    if medias.isEmpty {
      throw ParsingError.emptyPlaylist
    }

    if let error = mediaMetadataParsingError {
      throw error
    }

    return Playlist(medias: medias)
  }

  /// Walk over a playlist and return its medias one-by-one.
  /// - Parameters:
  ///   - input: source.
  ///   - handler: Handler to be called with the parsed medias.
  public func walk(
    _ input: PlaylistSource,
    handler: @escaping (Playlist.Media) -> Void
  ) throws {
    let rawString = try extractRawString(from: input)

    var lastMetadataLine: String?
    var lastURL: URL?
    var mediaMetadataParsingError: Error?
    var currentLineNumber = 0

    let lines = rawString.components(separatedBy: .newlines)
    
    for (index, line) in lines.enumerated() {
      let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
      
      // Skip empty lines
      guard !trimmedLine.isEmpty else { continue }
      
      currentLineNumber = index + 1
      
      if self.isInfoLine(trimmedLine) {
        lastMetadataLine = trimmedLine
      } else if self.isSessionLine(trimmedLine) && options.contains(.skipSessionData) {
        // Skip session data lines if option is enabled
        continue
      } else if self.isValidURL(trimmedLine) {
        lastURL = URL(string: trimmedLine)
      }

      if let metadataLine = lastMetadataLine, let url = lastURL {
        do {
          let metadata = try self.parseMetadata(line: currentLineNumber, rawString: metadataLine, url: url)
          let kind = self.parseMediaKind(url)
          handler(.init(metadata: metadata, kind: kind, url: url))
          lastMetadataLine = nil
          lastURL = nil
        } catch {
          mediaMetadataParsingError = error
          // Continue parsing instead of stopping on first error
          lastMetadataLine = nil
          lastURL = nil
        }
      }
    }

    if let error = mediaMetadataParsingError {
      throw error
    }
  }

  /// Parse a playlist on a queue with a completion handler.
  /// - Parameters:
  ///   - input: source.
  ///   - processingQueue: queue to perform parsing on. Defaults to `.global(qos: .background)`
  ///   - callbackQueue: queue to call callback on. Defaults to `.main`
  ///   - completion: completion handler to call with the result.
  public func parse(
    _ input: PlaylistSource,
    processingQueue: DispatchQueue = .global(qos: .background),
    callbackQueue: DispatchQueue = .main,
    completion: @escaping (Result<Playlist, Error>) -> Void
  ) {
    processingQueue.async {
      do {
        let playlist = try self.parse(input)
        callbackQueue.async {
          completion(.success(playlist))
        }
      } catch {
        callbackQueue.async {
          completion(.failure(error))
        }
      }
    }
  }
  
  /// Validate a playlist source without parsing it completely
  /// - Parameter input: source to validate
  /// - Returns: true if the source appears to be a valid M3U playlist
  public func validateSource(_ input: PlaylistSource) -> Bool {
    guard let rawString = input.rawString else {
      return false
    }
    
    let lines = rawString.components(separatedBy: .newlines)
    var hasExtM3U = false
    var hasExtInf = false
    var hasURL = false
    
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty { continue }
      
      if trimmed.starts(with: "#EXTM3U") {
        hasExtM3U = true
      } else if trimmed.starts(with: "#EXTINF:") {
        hasExtInf = true
      } else if !trimmed.hasPrefix("#") && self.isValidURL(trimmed) {
        hasURL = true
      }
    }
    
    return hasExtM3U && hasExtInf && hasURL
  }

  @available(iOS 15, tvOS 15, macOS 12, watchOS 8, *)
  /// Parse a playlist.
  /// - Parameter input: source.
  /// - Parameter priority: Processing task priority. Defaults to `.background`
  /// - Returns: playlist.
  public func parse(
    _ input: PlaylistSource,
    priority: TaskPriority = .background
  ) async throws -> Playlist {
    let processingTask = Task(priority: priority) {
      try self.parse(input)
    }
    return try await processingTask.value
  }

  // MARK: - Helpers

  internal func extractRawString(from input: PlaylistSource) throws -> String {
    guard var rawString = input.rawString else {
      throw ParsingError.invalidSource
    }
    
    // Remove BOM characters if present
    rawString = rawString.replacingOccurrences(of: "\u{FEFF}", with: "")
    rawString = rawString.replacingOccurrences(of: "\u{FFFE}", with: "")
    rawString = rawString.replacingOccurrences(of: "\u{EF}\u{BB}\u{BF}", with: "")
    
    // Normalize line endings
    rawString = rawString.replacingOccurrences(of: "\r\n", with: "\n")
    rawString = rawString.replacingOccurrences(of: "\r", with: "\n")
    
    // Check for #EXTM3U header (case insensitive, flexible whitespace)
    let lines = rawString.components(separatedBy: .newlines)
    guard let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
          firstLine.hasPrefix("#EXTM3U") else {
      throw ParsingError.invalidSource
    }
    
    // Remove the first line containing #EXTM3U
    if let firstLineOriginal = lines.first {
      let startIndex = rawString.index(rawString.startIndex, offsetBy: firstLineOriginal.count)
      if startIndex < rawString.endIndex {
        rawString = String(rawString[startIndex...])
      } else {
        rawString = ""
      }
    }
    
    return rawString
  }

  internal enum ParsingError: LocalizedError {
    case invalidSource
    case missingDuration(Int, String)
    case invalidURL(Int, String)
    case malformedMetadata(Int, String)
    case emptyPlaylist

    internal var errorDescription: String? {
      switch self {
      case .invalidSource:
        return "The playlist is invalid or doesn't start with #EXTM3U"
      case .missingDuration(let line, let raw):
        return "Line \(line): Missing duration in line \"\(raw)\""
      case .invalidURL(let line, let raw):
        return "Line \(line): Invalid URL format \"\(raw)\""
      case .malformedMetadata(let line, let raw):
        return "Line \(line): Malformed metadata line \"\(raw)\""
      case .emptyPlaylist:
        return "The playlist contains no valid media entries"
      }
    }
  }

  internal typealias Show = (name: String, se: (s: Int, e: Int)?)

  internal func parseMetadata(line: Int, rawString: String, url: URL) throws -> Playlist.Media.Metadata {
    let duration = try extractDuration(line: line, rawString: rawString)
    let attributes = parseAttributes(rawString: rawString, url: url)
    let name = parseSeasonEpisode(extractName(rawString)).name
    return (duration, attributes, name)
  }

  internal func isInfoLine(_ input: String) -> Bool {
    let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    return cleaned.hasPrefix("#EXTINF:") || cleaned.hasPrefix("#EXTNF:") // Handle typos
  }

  internal func isSessionLine(_ input: String) -> Bool {
    return input.starts(with: "#EXT-X-SESSION-DATA:")
  }
  
  internal func isIgnorableLine(_ input: String) -> Bool {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return true }
    
    let ignorablePatterns = [
      "#EXTGRP:",
      "#EXTVLCOPT:", 
      "#EXT-X-",
      "#EXTENC:",
      "#PLAYLIST:",
      "#EXTBYT:",
      "#EXTBIN:"
    ]
    
    return ignorablePatterns.contains { trimmed.hasPrefix($0) }
  }

  internal func isValidURL(_ input: String) -> Bool {
    let cleaned = cleanURL(input)
    guard let url = URL(string: cleaned) else {
      // Try with percent encoding
      if let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
         let _ = URL(string: encoded) {
        return true
      }
      return false
    }
    
    // Basic URL validation
    guard let scheme = url.scheme, !scheme.isEmpty else {
      return false
    }
    
    // Allow more flexible host validation
    if let host = url.host, host.isEmpty {
      return false
    }
    
    // If strict validation is enabled, perform additional checks
    if options.contains(.strictURLValidation) {
      // Check for common streaming protocols
      let validSchemes = ["http", "https", "rtmp", "rtmps", "rtsp", "rtsps", "mms", "mmsh", "hls", "dash"]
      guard validSchemes.contains(scheme.lowercased()) else {
        return false
      }
      
      // Check for valid file extensions for streaming
      let validExtensions = ["m3u8", "m3u", "mp4", "ts", "mpd", "flv", "avi", "mkv", "mov", "webm", "3gp"]
      let pathExtension = url.pathExtension.lowercased()
      if !pathExtension.isEmpty && !validExtensions.contains(pathExtension) && !url.absoluteString.contains(".m3u8") {
        return false
      }
    }
    
    return true
  }

  internal func extractDuration(line: Int, rawString: String) throws -> Int {
    // Try enhanced regex first
    if let match = durationRegex.firstMatch(in: rawString) {
      if let duration = Int(match) {
        return duration
      }
      if let doubleValue = Double(match) {
        return Int(doubleValue)
      }
    }
    
    // Fallback: try to extract any number from the line
    let numberRegex: RegularExpression = #"(\-?\d+(?:\.\d+)?)"#
    if let match = numberRegex.firstMatch(in: rawString) {
      if let doubleValue = Double(match) {
        return Int(doubleValue)
      }
    }
    
    // Ultimate fallback: default to -1 for live streams
    print("Warning: Could not extract duration from line \(line), defaulting to -1 (live stream)")
    return -1
  }

  internal func extractName(_ input: String) -> String {
    // Try main regex first
    if let name = nameRegex.firstMatch(in: input), !name.isEmpty {
      return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Fallback: try to extract anything after comma
    if let commaIndex = input.lastIndex(of: ",") {
      let nameSubstring = input[input.index(after: commaIndex)...]
      let name = String(nameSubstring).trimmingCharacters(in: .whitespacesAndNewlines)
      if !name.isEmpty {
        return name
      }
    }
    
    // Ultimate fallback: return "Unknown"
    return "Unknown"
  }

  internal func extractId(_ input: URL) -> String {
    String(input.lastPathComponent.split(separator: ".").first ?? "")
  }

  internal func parseMediaKind(_ input: URL) -> Playlist.Media.Kind {
    let string = input.absoluteString
    if mediaKindSeriesRegex.numberOfMatches(source: string) == 1 {
      return .series
    }
    if mediaKindMoviesRegex.numberOfMatches(source: string) == 1 {
      return .movie
    }
    if mediaKindLiveRegex.numberOfMatches(source: string) == 1 {
      return .live
    }
    return .unknown
  }
  
  /// Clean and validate a URL string for better compatibility
  internal func cleanURL(_ urlString: String) -> String {
    var cleaned = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Remove any control characters and normalize
    cleaned = cleaned.replacingOccurrences(of: "\r", with: "")
    cleaned = cleaned.replacingOccurrences(of: "\n", with: "")
    cleaned = cleaned.replacingOccurrences(of: "\t", with: "")
    
    // Handle common IPTV URL patterns and separators
    if cleaned.contains("|") {
      // Some IPTV providers use | as separator - take first part
      cleaned = cleaned.components(separatedBy: "|").first ?? cleaned
    }
    
    if cleaned.contains(" ") {
      // Some URLs might have spaces - encode them
      cleaned = cleaned.replacingOccurrences(of: " ", with: "%20")
    }
    
    // Handle URLs that start with // (protocol-relative)
    if cleaned.hasPrefix("//") {
      cleaned = "https:" + cleaned
    }
    
    // Ensure URL has a valid protocol
    if !cleaned.contains("://") && !cleaned.hasPrefix("data:") {
      // Assume http if no protocol specified
      if cleaned.hasPrefix("/") {
        // Relative path - can't make absolute without base URL
        return cleaned
      } else {
        cleaned = "http://" + cleaned
      }
    }
    
    return cleaned
  }

  internal func parseAttributes(rawString: String, url: URL) -> Playlist.Media.Attributes {
    var attributes = Playlist.Media.Attributes()
    
    // Enhanced attribute parsing with fallbacks
    let id = attributesIdRegex.firstMatch(in: rawString) ?? ""
    attributes.id = id.isEmpty ? nil : id
    if (attributes.id?.isEmpty ?? true) && options.contains(.extractIdFromURL) {
      attributes.id = extractId(url)
    }
    
    // Parse tvg-name or fallback to title extraction
    if let name = attributesNameRegex.firstMatch(in: rawString) {
      let show = parseSeasonEpisode(name)
      attributes.name = show.name.isEmpty ? nil : show.name
      attributes.seasonNumber = show.se?.s
      attributes.episodeNumber = show.se?.e
    }
    
    // Parse other attributes with nil checks
    if let country = attributesCountryRegex.firstMatch(in: rawString), !country.isEmpty {
      attributes.country = country
    }
    
    if let language = attributesLanguageRegex.firstMatch(in: rawString), !language.isEmpty {
      attributes.language = language
    }
    
    if let logo = attributesLogoRegex.firstMatch(in: rawString), !logo.isEmpty {
      attributes.logo = logo
    }
    
    if let channelNumber = attributesChannelNumberRegex.firstMatch(in: rawString), !channelNumber.isEmpty {
      attributes.channelNumber = channelNumber
    }
    
    if let shift = attributesShiftRegex.firstMatch(in: rawString), !shift.isEmpty {
      attributes.shift = shift
    }
    
    if let groupTitle = attributesGroupTitleRegex.firstMatch(in: rawString), !groupTitle.isEmpty {
      attributes.groupTitle = groupTitle
    }
    
    if let tvgUrl = attributesTvgUrlRegex.firstMatch(in: rawString), !tvgUrl.isEmpty {
      attributes.tvgUrl = tvgUrl
    }
    
    if let tvgShift = attributesTvgShiftRegex.firstMatch(in: rawString), !tvgShift.isEmpty {
      attributes.tvgShift = tvgShift
    }
    
    if let aspectRatio = attributesAspectRatioRegex.firstMatch(in: rawString), !aspectRatio.isEmpty {
      attributes.aspectRatio = aspectRatio
    }
    
    if let audioTrack = attributesAudioTrackRegex.firstMatch(in: rawString), !audioTrack.isEmpty {
      attributes.audioTrack = audioTrack
    }
    
    if let subtitles = attributesSubtitlesRegex.firstMatch(in: rawString), !subtitles.isEmpty {
      attributes.subtitles = subtitles
    }
    
    return attributes
  }

  internal func parseSeasonEpisode(_ input: String) -> Show {
    let ranges = seasonEpisodeRegex.matchingRanges(in: input)
    guard
      ranges.count == 3,
      let s = Int(input[ranges[1]]),
      let e = Int(input[ranges[2]])
    else {
      return (name: input, se: nil)
    }
    var name = input
    if options.contains(.removeSeriesInfoFromText) {
      name.removeSubrange(ranges[0])
    }
    return (name: name, se: (s, e))
  }

  // MARK: - Regex

  // Enhanced regex patterns for robust parsing
  internal let durationRegex: RegularExpression = #"#EXT[IN]*F:\s*(\-?\d+(?:\.\d+)?)"#
  internal let nameRegex: RegularExpression = #".*?,\s*(.+?)\s*$"#

  internal let mediaKindMoviesRegex: RegularExpression = #"\/movie\/"#
  internal let mediaKindSeriesRegex: RegularExpression = #"\/series\/"#
  internal let mediaKindLiveRegex: RegularExpression = #"\/live\/"#

  internal let seasonEpisodeRegex: RegularExpression = #" (?i)s(\d+) ?(?i)e(\d+)"#

  internal let attributesIdRegex: RegularExpression = #"tvg-id\s*=\s*[\"']([^\"']*)[\"']"#
  internal let attributesNameRegex: RegularExpression = #"tvg-name\s*=\s*[\"']([^\"']*)[\"']"#
  internal let attributesCountryRegex: RegularExpression = #"tvg-country\s*=\s*[\"']([^\"']*)[\"']"#
  internal let attributesLanguageRegex: RegularExpression = #"tvg-language=\"(.?|.+?)\""#
  internal let attributesLogoRegex: RegularExpression = #"tvg-logo\s*=\s*[\"']([^\"']*)[\"']"#
  internal let attributesChannelNumberRegex: RegularExpression = #"tvg-chno=\"(.?|.+?)\""#
  internal let attributesShiftRegex: RegularExpression = #"tvg-shift=\"(.?|.+?)\""#
  internal let attributesGroupTitleRegex: RegularExpression = #"group-title\s*=\s*[\"']([^\"']*)[\"']"#
  internal let attributesTvgUrlRegex: RegularExpression = #"tvg-url=\"(.?|.+?)\""#
  internal let attributesTvgShiftRegex: RegularExpression = #"tvg-shift=\"(.?|.+?)\""#
  internal let attributesAspectRatioRegex: RegularExpression = #"aspect-ratio=\"(.?|.+?)\""#
  internal let attributesAudioTrackRegex: RegularExpression = #"audio-track=\"(.?|.+?)\""#
  internal let attributesSubtitlesRegex: RegularExpression = #"subtitles=\"(.?|.+?)\""#
}
