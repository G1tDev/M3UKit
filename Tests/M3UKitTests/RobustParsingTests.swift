//
// RobustParsingTests.swift
// M3UKit
//
// Tests for robust playlist parsing capabilities
//

import XCTest
@testable import M3UKit

final class RobustParsingTests: XCTestCase {
    
    func testParsingWithMissingDuration() {
        let playlistContent = """
#EXTM3U
#EXTINF: tvg-id="BBCNews.uk" tvg-country="INT" tvg-language="English" tvg-logo="https://example.com/logo.png" group-title="News",BBC News HD
https://example.com/stream.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        XCTAssertNoThrow(try parser.parse(source))
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 1)
        
        let media = playlist.medias[0]
        XCTAssertEqual(media.duration, -1) // Should default to -1 for live streams
        XCTAssertEqual(media.name, "BBC News HD")
        XCTAssertEqual(media.attributes.id, "BBCNews.uk")
        XCTAssertEqual(media.attributes.groupTitle, "News")
    }
    
    func testParsingWithTypos() {
        let playlistContent = """
#EXTM3U
#EXTNF:-1 tvg-id="BR6TV.nl" tvg-country="NL",BR6 TV
https://example.com/stream.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        XCTAssertNoThrow(try parser.parse(source))
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 1)
        
        let media = playlist.medias[0]
        XCTAssertEqual(media.name, "BR6 TV")
        XCTAssertEqual(media.attributes.id, "BR6TV.nl")
    }
    
    func testParsingWithBOMCharacters() {
        let playlistContent = "\\u{FEFF}#EXTM3U\\n#EXTINF:-1 tvg-name=\"Test Channel\" group-title=\"Test\",Test Channel\\nhttps://example.com/stream.m3u8"
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        XCTAssertNoThrow(try parser.parse(source))
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 1)
        XCTAssertEqual(playlist.medias[0].name, "Test Channel")
    }
    
    func testParsingWithExtraLines() {
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-name="Test Channel" group-title="Test",Test Channel
#EXTGRP:Test
#EXTVLCOPT:http-user-agent=Mozilla
https://example.com/stream.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        XCTAssertNoThrow(try parser.parse(source))
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 1)
        XCTAssertEqual(playlist.medias[0].name, "Test Channel")
    }
    
    func testParsingComplexURLs() {
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-name="Complex URL" group-title="Test",Complex URL
https://example.com/stream.m3u8?token=abc123&user=test|backup=https://backup.com/stream
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        XCTAssertNoThrow(try parser.parse(source))
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 1)
        
        // Should handle URL cleaning
        let url = playlist.medias[0].url.absoluteString
        XCTAssertFalse(url.contains("|")) // Pipe should be removed
        XCTAssertTrue(url.contains("token=abc123"))
    }
    
    func testParsingWithNonASCIICharacters() {
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-name="Мульт БУМ!" group-title="🎞️ МультStream",Мульт БУМ!
https://example.com/stream.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        XCTAssertNoThrow(try parser.parse(source))
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 1)
        XCTAssertEqual(playlist.medias[0].name, "Мульт БУМ!")
        XCTAssertEqual(playlist.medias[0].attributes.groupTitle, "🎞️ МультStream")
    }
    
    func testValidationMethod() {
        let validPlaylist = """
#EXTM3U
#EXTINF:-1 tvg-name="Test" group-title="Test",Test
https://example.com/stream.m3u8
"""
        
        let invalidPlaylist = """
NOT A PLAYLIST
Some random content
"""
        
        let parser = PlaylistParser()
        
        XCTAssertTrue(parser.validateSource(StringPlaylistSource(validPlaylist)))
        XCTAssertFalse(parser.validateSource(StringPlaylistSource(invalidPlaylist)))
    }
    
    func testLenientURLParsing() {
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-name="Encoded URL" group-title="Test",Encoded URL
https://example.com/stream with spaces.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: []) // No strict validation
        
        XCTAssertNoThrow(try parser.parse(source))
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 1)
        
        // Should handle URL encoding
        let url = playlist.medias[0].url.absoluteString
        XCTAssertTrue(url.contains("%20")) // Spaces should be encoded
    }
}

// Helper class for string-based playlist sources
private class StringPlaylistSource: PlaylistSource {
    private let content: String
    
    init(_ content: String) {
        self.content = content
    }
    
    var rawString: String? {
        return content
    }
    
    var isValid: Bool {
        return content.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: "#EXTM3U")
    }
    
    var format: PlaylistFormat {
        return content.format
    }
}