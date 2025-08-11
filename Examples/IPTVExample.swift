import Foundation
import M3UKit

/// Example usage of Enhanced M3UKit for IPTV applications
class IPTVExample {
    
    /// Parse an IPTV playlist with enhanced options
    func parseIPTVPlaylist(from url: URL) throws -> Playlist {
        // Use enhanced options for better IPTV support
        let parser = PlaylistParser(options: [
            .removeSeriesInfoFromText,
            .extractIdFromURL,
            .strictURLValidation,      // Ensures valid streaming URLs
            .skipSessionData           // Skips problematic session data lines
        ])
        
        // Validate playlist before parsing
        guard parser.validateSource(url) else {
            throw IPTVError.invalidPlaylist
        }
        
        // Parse the playlist
        return try parser.parse(url)
    }
    
    /// Get live channels from playlist
    func getLiveChannels(from playlist: Playlist) -> [Playlist.Media] {
        return playlist.liveChannels
    }
    
    /// Filter channels by category
    func getChannelsByCategory(from playlist: Playlist, category: String) -> [Playlist.Media] {
        return playlist.channels(in: category)
    }
    
    /// Search for specific channels
    func searchChannels(in playlist: Playlist, query: String) -> [Playlist.Media] {
        return playlist.searchChannels(query: query)
    }
    
    /// Get channel by ID
    func getChannelById(from playlist: Playlist, id: String) -> Playlist.Media? {
        return playlist.channel(withId: id)
    }
    
    /// Display playlist statistics
    func displayPlaylistInfo(_ playlist: Playlist) {
        print("📺 Playlist Information:")
        print("   Total channels: \(playlist.medias.count)")
        print("   Live channels: \(playlist.liveChannels.count)")
        print("   Movies: \(playlist.movies.count)")
        print("   Series: \(playlist.series.count)")
        
        // Group channels by category
        let categories = Set(playlist.medias.compactMap { $0.attributes.groupTitle })
        print("   Categories: \(categories.count)")
        
        for category in categories.sorted() {
            let count = playlist.channels(in: category).count
            print("     - \(category): \(count) channels")
        }
    }
    
    /// Example of handling different playlist formats
    func handlePlaylistFormat(_ source: PlaylistSource) {
        switch source.format {
        case .m3u:
            print("📋 M3U playlist detected")
        case .m3u8:
            print("📋 M3U8 playlist detected")
        case .pls:
            print("📋 PLS playlist detected")
        case .unknown:
            print("❓ Unknown playlist format")
        }
    }
    
    /// Example of using cached playlist source for better performance
    func parseWithCaching(from url: URL) throws -> Playlist {
        let cachedSource = CachedPlaylistSource(url)
        let parser = PlaylistParser(options: .all)
        
        // First access - will cache the content
        let playlist1 = try parser.parse(cachedSource)
        
        // Second access - uses cached content (faster)
        let playlist2 = try parser.parse(cachedSource)
        
        // Clear cache if needed
        cachedSource.clearCache()
        
        return playlist1
    }
}

/// Custom error types for IPTV operations
enum IPTVError: Error, LocalizedError {
    case invalidPlaylist
    case parsingFailed
    case noChannelsFound
    
    var errorDescription: String? {
        switch self {
        case .invalidPlaylist:
            return "The playlist format is invalid or unsupported"
        case .parsingFailed:
            return "Failed to parse the playlist"
        case .noChannelsFound:
            return "No channels found in the playlist"
        }
    }
}

/// Example usage in a real IPTV app
class IPTVPlayer {
    private let parser = PlaylistParser(options: [.strictURLValidation, .skipSessionData])
    private var currentPlaylist: Playlist?
    
    /// Load and parse a playlist
    func loadPlaylist(from url: URL) throws {
        // Validate playlist first
        guard parser.validateSource(url) else {
            throw IPTVError.invalidPlaylist
        }
        
        // Parse playlist
        currentPlaylist = try parser.parse(url)
        
        print("✅ Playlist loaded successfully!")
        print("📺 Found \(currentPlaylist?.medias.count ?? 0) channels")
    }
    
    /// Play a specific channel
    func playChannel(withId id: String) throws -> URL {
        guard let playlist = currentPlaylist else {
            throw IPTVError.noChannelsFound
        }
        
        guard let channel = playlist.channel(withId: id) else {
            throw IPTVError.noChannelsFound
        }
        
        print("▶️ Playing channel: \(channel.name)")
        return channel.url
    }
    
    /// Get all news channels
    func getNewsChannels() -> [Playlist.Media] {
        return currentPlaylist?.channels(in: "News") ?? []
    }
    
    /// Search for channels
    func searchChannels(query: String) -> [Playlist.Media] {
        return currentPlaylist?.searchChannels(query: query) ?? []
    }
}

// MARK: - Usage Examples

func runExamples() {
    let example = IPTVExample()
    
    // Example URL (replace with your actual playlist URL)
    guard let url = URL(string: "https://example.com/playlist.m3u") else {
        print("❌ Invalid URL")
        return
    }
    
    do {
        // Parse playlist with enhanced options
        let playlist = try example.parseIPTVPlaylist(from: url)
        
        // Display playlist information
        example.displayPlaylistInfo(playlist)
        
        // Get live channels
        let liveChannels = example.getLiveChannels(from: playlist)
        print("📡 Live channels: \(liveChannels.count)")
        
        // Search for specific channels
        let bbcChannels = example.searchChannels(in: playlist, query: "BBC")
        print("🔍 BBC channels found: \(bbcChannels.count)")
        
        // Get channels by category
        let newsChannels = example.getChannelsByCategory(from: playlist, category: "News")
        print("📰 News channels: \(newsChannels.count)")
        
    } catch {
        print("❌ Error: \(error.localizedDescription)")
    }
}

// Uncomment to run examples
// runExamples()
