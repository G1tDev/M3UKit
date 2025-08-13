//
// PlaylistAttributesTests.swift
// M3UKit
//
// Tests for playlist-level attributes parsing from #EXTM3U headers
//

import XCTest
@testable import M3UKit

final class PlaylistAttributesTests: XCTestCase {
    
    func testBasicPlaylistAttributesParsing() {
        let playlistContent = """
#EXTM3U url-tvg="https://iptv-org.github.io/epg/guides/uk/bt.com.epg.xml" description="IPTV Playlist"
#EXTINF:-1 tvg-id="channel1" tvg-name="Channel 1", Channel 1
https://example.com/stream1.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist = try parser.parse(source)
            
            XCTAssertNotNil(playlist.attributes)
            XCTAssertEqual(playlist.attributes?.epgUrl, "https://iptv-org.github.io/epg/guides/uk/bt.com.epg.xml")
            XCTAssertEqual(playlist.attributes?.description, "IPTV Playlist")
            
            print("✅ Basic playlist attributes parsed successfully:")
            print("  EPG URL: \(playlist.attributes?.epgUrl ?? "None")")
            print("  Description: \(playlist.attributes?.description ?? "None")")
            
        } catch {
            XCTFail("Failed to parse playlist with basic attributes: \(error)")
        }
    }
    
    func testMultipleEPGURLs() {
        let playlistContent = """
#EXTM3U x-tvg-url="http://epg1.com/guide.xml,http://epg2.com/backup.xml" description="Multi-EPG"
#EXTINF:-1 tvg-id="channel1" tvg-name="Channel 1", Channel 1
https://example.com/stream1.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist = try parser.parse(source)
            
            XCTAssertNotNil(playlist.attributes)
            XCTAssertEqual(playlist.attributes?.epgUrl, "http://epg1.com/guide.xml,http://epg2.com/backup.xml")
            XCTAssertEqual(playlist.attributes?.description, "Multi-EPG")
            
            print("✅ Multiple EPG URLs handled successfully:")
            print("  EPG URLs: \(playlist.attributes?.epgUrl ?? "None")")
            
        } catch {
            XCTFail("Failed to parse playlist with multiple EPG URLs: \(error)")
        }
    }
    
    func testCaseInsensitiveEPGAttributes() {
        let playlistContent = """
#EXTM3U URL-TVG="https://epg.example.com/guide.xml" X-TVG-URL="https://backup.example.com/guide.xml"
#EXTINF:-1 tvg-id="channel1" tvg-name="Channel 1", Channel 1
https://example.com/stream1.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist = try parser.parse(source)
            
            XCTAssertNotNil(playlist.attributes)
            // Should combine both EPG URLs
            XCTAssertEqual(playlist.attributes?.epgUrl, "https://epg.example.com/guide.xml,https://backup.example.com/guide.xml")
            
            print("✅ Case-insensitive EPG attributes handled successfully:")
            print("  Combined EPG URLs: \(playlist.attributes?.epgUrl ?? "None")")
            
        } catch {
            XCTFail("Failed to parse playlist with case-insensitive EPG attributes: \(error)")
        }
    }
    
    func testAllSupportedAttributes() {
        let playlistContent = """
#EXTM3U url-tvg="https://epg.example.com/guide.xml" description="Full IPTV List" size="Large" background="#000000" custom-attr="custom-value"
#EXTINF:-1 tvg-id="channel1" tvg-name="Channel 1", Channel 1
https://example.com/stream1.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist = try parser.parse(source)
            
            XCTAssertNotNil(playlist.attributes)
            XCTAssertEqual(playlist.attributes?.epgUrl, "https://epg.example.com/guide.xml")
            XCTAssertEqual(playlist.attributes?.description, "Full IPTV List")
            XCTAssertEqual(playlist.attributes?.size, "Large")
            XCTAssertEqual(playlist.attributes?.background, "#000000")
            XCTAssertEqual(playlist.attributes?.other["custom-attr"], "custom-value")
            
            print("✅ All supported attributes parsed successfully:")
            print("  EPG URL: \(playlist.attributes?.epgUrl ?? "None")")
            print("  Description: \(playlist.attributes?.description ?? "None")")
            print("  Size: \(playlist.attributes?.size ?? "None")")
            print("  Background: \(playlist.attributes?.background ?? "None")")
            print("  Custom attributes: \(playlist.attributes?.other)")
            
        } catch {
            XCTFail("Failed to parse playlist with all attributes: \(error)")
        }
    }
    
    func testPlaylistWithoutAttributes() {
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-id="channel1" tvg-name="Channel 1", Channel 1
https://example.com/stream1.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist = try parser.parse(source)
            
            // Should still have attributes object but with nil values
            XCTAssertNotNil(playlist.attributes)
            XCTAssertNil(playlist.attributes?.epgUrl)
            XCTAssertNil(playlist.attributes?.description)
            XCTAssertTrue(playlist.attributes?.other.isEmpty ?? false)
            
            print("✅ Playlist without attributes handled correctly")
            
        } catch {
            XCTFail("Failed to parse playlist without attributes: \(error)")
        }
    }
    
    func testUnquotedAttributeValues() {
        let playlistContent = """
#EXTM3U url-tvg=https://epg.example.com/guide.xml description=Simple size=small
#EXTINF:-1 tvg-id="channel1" tvg-name="Channel 1", Channel 1
https://example.com/stream1.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist = try parser.parse(source)
            
            XCTAssertNotNil(playlist.attributes)
            XCTAssertEqual(playlist.attributes?.epgUrl, "https://epg.example.com/guide.xml")
            XCTAssertEqual(playlist.attributes?.description, "Simple")
            XCTAssertEqual(playlist.attributes?.size, "small")
            
            print("✅ Unquoted attribute values handled successfully:")
            print("  EPG URL: \(playlist.attributes?.epgUrl ?? "None")")
            print("  Description: \(playlist.attributes?.description ?? "None")")
            print("  Size: \(playlist.attributes?.size ?? "None")")
            
        } catch {
            XCTFail("Failed to parse playlist with unquoted attributes: \(error)")
        }
    }
    
    func testMixedQuotedAndUnquotedAttributes() {
        let playlistContent = """
#EXTM3U url-tvg="https://epg.example.com/guide.xml" description=Mixed size="Large" background=white
#EXTINF:-1 tvg-id="channel1" tvg-name="Channel 1", Channel 1
https://example.com/stream1.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist = try parser.parse(source)
            
            XCTAssertNotNil(playlist.attributes)
            XCTAssertEqual(playlist.attributes?.epgUrl, "https://epg.example.com/guide.xml")
            XCTAssertEqual(playlist.attributes?.description, "Mixed")
            XCTAssertEqual(playlist.attributes?.size, "Large")
            XCTAssertEqual(playlist.attributes?.background, "white")
            
            print("✅ Mixed quoted/unquoted attributes handled successfully")
            
        } catch {
            XCTFail("Failed to parse playlist with mixed attributes: \(error)")
        }
    }
    
    func testEPGAttributeAccess() {
        // Test the main use case - easy access to EPG URL
        let playlistContent = """
#EXTM3U url-tvg="https://iptv-org.github.io/epg/guides/uk/bt.com.epg.xml"
#EXTINF:-1 tvg-id="channel1" tvg-name="Channel 1", Channel 1
https://example.com/stream1.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist = try parser.parse(source)
            
            // This is the main use case - clean API access to EPG URL
            if let epgUrl = playlist.attributes?.epgUrl {
                print("✅ Clean EPG URL access: \(epgUrl)")
                XCTAssertEqual(epgUrl, "https://iptv-org.github.io/epg/guides/uk/bt.com.epg.xml")
            } else {
                XCTFail("EPG URL should be accessible")
            }
            
        } catch {
            XCTFail("Failed to access EPG URL: \(error)")
        }
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