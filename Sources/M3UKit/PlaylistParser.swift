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
    
    /// All available options.
    public static let all: Options = [
      .removeSeriesInfoFromText,
      .extractIdFromURL,
      .strictURLValidation,
      .skipSessionData,
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
      
      if self.isInfoLine(trimmedLine) {
        lastMetadataLine = trimmedLine
      } else if self.isSessionLine(trimmedLine) && options.contains(.skipSessionData) {
        // Skip session data lines if option is enabled
        continue
      } else if self.isValidURL(trimmedLine) {
        let cleanedURL = self.cleanURL(trimmedLine)
        lastURL = URL(string: cleanedURL)
      } else if !trimmedLine.hasPrefix("#") && !trimmedLine.isEmpty {
        // This should be a URL but it's not valid
        if options.contains(.strictURLValidation) {
          mediaMetadataParsingError = ParsingError.invalidURL(currentLineNumber, trimmedLine)
          // Continue parsing to collect all errors
        }
      }

      if let metadataLine = lastMetadataLine, let url = lastURL {
        do {
          let metadata = try self.parseMetadata(line: currentLineNumber, rawString: metadataLine, url: url)
          let kind = self.parseMediaKind(url)
          medias.append(.init(metadata: metadata, kind: kind, url: url))
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
    let filePrefix = "#EXTM3U"
    guard var rawString = input.rawString else {
      throw ParsingError.invalidSource
    }
    guard rawString.starts(with: filePrefix) else {
      throw ParsingError.invalidSource
    }
    rawString.removeFirst(filePrefix.count)
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
    return input.starts(with: "#EXTINF:")
  }

  internal func isSessionLine(_ input: String) -> Bool {
      return input.starts(with: "#EXT-X-SESSION-DATA:")
  }

  internal func isValidURL(_ input: String) -> Bool {
    guard let url = URL(string: input) else {
      return false
    }
    
    // Basic URL validation
    guard url.scheme != nil && !url.host.isEmpty else {
      return false
    }
    
    // If strict validation is enabled, perform additional checks
    if options.contains(.strictURLValidation) {
      // Check for common streaming protocols
      let validSchemes = ["http", "https", "rtmp", "rtmps", "rtsp", "mms", "mmsh"]
      guard validSchemes.contains(url.scheme?.lowercased() ?? "") else {
        return false
      }
      
      // Check for valid file extensions for streaming
      let validExtensions = ["m3u8", "mp4", "ts", "mpd", "flv", "avi", "mkv"]
      let pathExtension = url.pathExtension.lowercased()
      if !pathExtension.isEmpty && !validExtensions.contains(pathExtension) {
        return false
      }
    }
    
    return true
  }

  internal func extractDuration(line: Int, rawString: String) throws -> Int {
    guard
      let match = durationRegex.firstMatch(in: rawString),
      let duration = Int(match)
    else {
      throw ParsingError.missingDuration(line, rawString)
    }
    return duration
  }

  internal func extractName(_ input: String) -> String {
    return nameRegex.firstMatch(in: input) ?? ""
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
    
    // Remove any trailing whitespace or newlines
    cleaned = cleaned.replacingOccurrences(of: "\r", with: "")
    cleaned = cleaned.replacingOccurrences(of: "\n", with: "")
    
    // Handle common IPTV URL patterns
    if cleaned.contains("|") {
      // Some IPTV providers use | as separator
      cleaned = cleaned.components(separatedBy: "|").first ?? cleaned
    }
    
    return cleaned
  }

  internal func parseAttributes(rawString: String, url: URL) -> Playlist.Media.Attributes {
    var attributes = Playlist.Media.Attributes()
    let id = attributesIdRegex.firstMatch(in: rawString) ?? ""
    attributes.id = id
    if id.isEmpty && options.contains(.extractIdFromURL) {
      attributes.id = extractId(url)
    }
    if let name = attributesNameRegex.firstMatch(in: rawString) {
      let show = parseSeasonEpisode(name)
      attributes.name = show.name
      attributes.seasonNumber = show.se?.s
      attributes.episodeNumber = show.se?.e
    }
    if let country = attributesCountryRegex.firstMatch(in: rawString) {
      attributes.country = country
    }
    if let language = attributesLanguageRegex.firstMatch(in: rawString) {
      attributes.language = language
    }
    if let logo = attributesLogoRegex.firstMatch(in: rawString) {
      attributes.logo = logo
    }
    if let channelNumber = attributesChannelNumberRegex.firstMatch(in: rawString) {
      attributes.channelNumber = channelNumber
    }
    if let shift = attributesShiftRegex.firstMatch(in: rawString) {
      attributes.shift = shift
    }
    if let groupTitle = attributesGroupTitleRegex.firstMatch(in: rawString) {
      attributes.groupTitle = groupTitle
    }
    if let tvgUrl = attributesTvgUrlRegex.firstMatch(in: rawString) {
      attributes.tvgUrl = tvgUrl
    }
    if let tvgShift = attributesTvgShiftRegex.firstMatch(in: rawString) {
      attributes.tvgShift = tvgShift
    }
    if let aspectRatio = attributesAspectRatioRegex.firstMatch(in: rawString) {
      attributes.aspectRatio = aspectRatio
    }
    if let audioTrack = attributesAudioTrackRegex.firstMatch(in: rawString) {
      attributes.audioTrack = audioTrack
    }
    if let subtitles = attributesSubtitlesRegex.firstMatch(in: rawString) {
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

  internal let durationRegex: RegularExpression = #"#EXTINF:\s*(\-*\d+)"#
  internal let nameRegex: RegularExpression = #".*,(.+?)$"#

  internal let mediaKindMoviesRegex: RegularExpression = #"\/movie\/"#
  internal let mediaKindSeriesRegex: RegularExpression = #"\/series\/"#
  internal let mediaKindLiveRegex: RegularExpression = #"\/live\/"#

  internal let seasonEpisodeRegex: RegularExpression = #" (?i)s(\d+) ?(?i)e(\d+)"#

  internal let attributesIdRegex: RegularExpression = #"tvg-id=\"(.?|.+?)\""#
  internal let attributesNameRegex: RegularExpression = #"tvg-name=\"(.?|.+?)\""#
  internal let attributesCountryRegex: RegularExpression = #"tvg-country=\"(.?|.+?)\""#
  internal let attributesLanguageRegex: RegularExpression = #"tvg-language=\"(.?|.+?)\""#
  internal let attributesLogoRegex: RegularExpression = #"tvg-logo=\"(.?|.+?)\""#
  internal let attributesChannelNumberRegex: RegularExpression = #"tvg-chno=\"(.?|.+?)\""#
  internal let attributesShiftRegex: RegularExpression = #"tvg-shift=\"(.?|.+?)\""#
  internal let attributesGroupTitleRegex: RegularExpression = #"group-title=\"(.?|.+?)\""#
  internal let attributesTvgUrlRegex: RegularExpression = #"tvg-url=\"(.?|.+?)\""#
  internal let attributesTvgShiftRegex: RegularExpression = #"tvg-shift=\"(.?|.+?)\""#
  internal let attributesAspectRatioRegex: RegularExpression = #"aspect-ratio=\"(.?|.+?)\""#
  internal let attributesAudioTrackRegex: RegularExpression = #"audio-track=\"(.?|.+?)\""#
  internal let attributesSubtitlesRegex: RegularExpression = #"subtitles=\"(.?|.+?)\""#
}
