//
// M3UKit
//
// Copyright (c) 2022 Omar Albeik
// Enhanced by [Your Name] - Added IPTV-specific features and improvements
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

/// Object representing a playlist containing media items.
public struct Playlist: Equatable, Hashable, Codable {

  /// Object representing a media.
  public struct Media: Equatable, Hashable, Codable {

    /// Object representing attributes for a media.
    public struct Attributes: Equatable, Hashable, Codable {
      /// Create a new attributes object.
      /// - Parameters:
      ///   - id: id.
      ///   - name: name.
      ///   - country: country.
      ///   - language: language.
      ///   - logo: logo.
      ///   - channelNumber: channel number.
      ///   - shift: shift.
      ///   - groupTitle: group title.
      ///   - seasonNumber: Season number (for TV shows).
      ///   - episodeNumber: Episode number (for TV shows).
      ///   - tvgUrl: EPG URL for this channel.
      ///   - tvgShift: Time shift for EPG.
      ///   - aspectRatio: Video aspect ratio.
      ///   - audioTrack: Audio track information.
      ///   - subtitles: Subtitles information.
      public init(
        id: String? = nil,
        name: String? = nil,
        country: String? = nil,
        language: String? = nil,
        logo: String? = nil,
        channelNumber: String? = nil,
        shift: String? = nil,
        groupTitle: String? = nil,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        tvgUrl: String? = nil,
        tvgShift: String? = nil,
        aspectRatio: String? = nil,
        audioTrack: String? = nil,
        subtitles: String? = nil
      ) {
        self.id = id
        self.name = name
        self.country = country
        self.language = language
        self.logo = logo
        self.channelNumber = channelNumber
        self.shift = shift
        self.groupTitle = groupTitle
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.tvgUrl = tvgUrl
        self.tvgShift = tvgShift
        self.aspectRatio = aspectRatio
        self.audioTrack = audioTrack
        self.subtitles = subtitles
      }

      /// tvg-id.
      public var id: String?

      /// tvg-name.
      public var name: String?

      /// tvg-country.
      public var country: String?

      /// tvg-language.
      public var language: String?

      /// tvg-logo.
      public var logo: String?

      /// tvg-chno.
      public var channelNumber: String?

      /// tvg-shift.
      public var shift: String?

      /// group-title.
      public var groupTitle: String?

      /// Season number (for TV shows).
      public var seasonNumber: Int?

      /// Episode number (for TV shows).
      public var episodeNumber: Int?
      
      /// tvg-url for EPG data.
      public var tvgUrl: String?
      
      /// tvg-shift for timezone adjustment.
      public var tvgShift: String?
      
      /// Video aspect ratio.
      public var aspectRatio: String?
      
      /// Audio track information.
      public var audioTrack: String?
      
      /// Subtitles information.
      public var subtitles: String?
    }

    /// Enum representing media kind.
    public enum Kind: String, Equatable, Hashable, Codable {
      case movie
      case series
      case live
      case unknown
    }

    internal typealias Metadata = (
      duration: Int,
      attributes: Attributes,
      name: String
    )

    internal init(
      metadata: Metadata,
      kind: Kind,
      url: URL
    ) {
      self.init(
        duration: metadata.duration,
        attributes: metadata.attributes,
        kind: kind,
        name: metadata.name,
        url: url
      )
    }

    /// Create a new media object.
    /// - Parameters:
    ///   - duration: duration.
    ///   - attributes: attributes.
    ///   - kind: kind.
    ///   - name: name.
    ///   - url: url.
    public init(
      duration: Int,
      attributes: Attributes,
      kind: Kind,
      name: String,
      url: URL
    ) {
      self.duration = duration
      self.attributes = attributes
      self.kind = kind
      self.name = name
      self.url = url
    }

    /// Duration, Usually -1 for live stream content.
    public var duration: Int

    /// Attributes.
    public var attributes: Attributes

    /// Kind.
    public var kind: Kind

    /// Media name.
    public var name: String

    /// Media URL.
    public var url: URL
  }

  /// Create a playlist.
  /// - Parameter medias: medias.
  public init(medias: [Media]) {
    self.medias = medias
  }

  /// Medias.
  public var medias: [Media]
  
  // MARK: - IPTV Convenience Methods
  
  /// Get all live channels from the playlist
  public var liveChannels: [Media] {
    return medias.filter { $0.kind == .live }
  }
  
  /// Get all movies from the playlist
  public var movies: [Media] {
    return medias.filter { $0.kind == .movie }
  }
  
  /// Get all series from the playlist
  public var series: [Media] {
    return medias.filter { $0.kind == .series }
  }
  
  /// Get channels by group title
  /// - Parameter groupTitle: The group title to filter by
  /// - Returns: Array of media in the specified group
  public func channels(in groupTitle: String) -> [Media] {
    return medias.filter { $0.attributes.groupTitle == groupTitle }
  }
  
  /// Get channels by country
  /// - Parameter country: The country code to filter by
  /// - Returns: Array of media from the specified country
  public func channels(from country: String) -> [Media] {
    return medias.filter { $0.attributes.country == country }
  }
  
  /// Get channels by language
  /// - Parameter language: The language to filter by
  /// - Returns: Array of media in the specified language
  public func channels(inLanguage language: String) -> [Media] {
    return medias.filter { $0.attributes.language == language }
  }
  
  /// Search channels by name
  /// - Parameter query: The search query
  /// - Returns: Array of media matching the search query
  public func searchChannels(query: String) -> [Media] {
    let lowercasedQuery = query.lowercased()
    return medias.filter { media in
      if let name = media.attributes.name {
        return name.lowercased().contains(lowercasedQuery)
      }
      return media.name.lowercased().contains(lowercasedQuery)
    }
  }
  
  /// Get channel by ID
  /// - Parameter id: The channel ID to search for
  /// - Returns: The media with the specified ID, or nil if not found
  public func channel(withId id: String) -> Media? {
    return medias.first { $0.attributes.id == id }
  }
  
  /// Get channel by URL
  /// - Parameter url: The URL to search for
  /// - Returns: The media with the specified URL, or nil if not found
  public func channel(withURL url: URL) -> Media? {
    return medias.first { $0.url == url }
  }
}
