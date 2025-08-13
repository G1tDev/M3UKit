//
// IntegrationTest.swift
// M3UKit
//
// Integration test to verify the new playlist attributes feature works correctly
//

import XCTest
@testable import M3UKit

final class IntegrationTest: XCTestCase {
    
    func testRealWorldEPGIntegration() {
        // Test the exact scenario described in the enhancement request
        let realWorldPlaylist = """
#EXTM3U url-tvg="https://iptv-org.github.io/epg/guides/uk/bt.com.epg.xml" description="UK IPTV Channels"
#EXTINF:-1 tvg-id="bbc.one.hd" tvg-name="BBC One HD" tvg-logo="https://example.com/logo.png" group-title="UK", BBC One HD
https://example.com/bbc_one_hd.m3u8
#EXTINF:-1 tvg-id="itv.hd" tvg-name="ITV HD" group-title="UK", ITV HD
https://example.com/itv_hd.m3u8
"""
        
        let source = StringPlaylistSource(realWorldPlaylist)
        let parser = PlaylistParser(options: .iptv)
        
        do {
            let playlist = try parser.parse(source)
            
            // Verify the core functionality works
            XCTAssertEqual(playlist.medias.count, 2)
            
            // Test the new playlist-level attributes
            XCTAssertNotNil(playlist.attributes, "Playlist should have attributes")
            
            // Test clean API access to EPG URL - this was the main request
            XCTAssertEqual(playlist.attributes?.epgUrl, "https://iptv-org.github.io/epg/guides/uk/bt.com.epg.xml")
            XCTAssertEqual(playlist.attributes?.description, "UK IPTV Channels")
            
            // Verify media parsing still works correctly
            XCTAssertEqual(playlist.medias[0].name, "BBC One HD")
            XCTAssertEqual(playlist.medias[0].attributes.id, "bbc.one.hd")
            XCTAssertEqual(playlist.medias[0].attributes.groupTitle, "UK")
            
            XCTAssertEqual(playlist.medias[1].name, "ITV HD")
            XCTAssertEqual(playlist.medias[1].attributes.id, "itv.hd")
            
            print("✅ Real-world EPG integration test passed!")
            print("  🔗 EPG URL: \(playlist.attributes?.epgUrl ?? "None")")
            print("  📝 Description: \(playlist.attributes?.description ?? "None")")
            print("  📺 Channels: \(playlist.medias.count)")
            
        } catch {
            XCTFail("Integration test failed: \(error)")
        }
    }
    
    func testBackwardCompatibility() {
        // Ensure existing code without playlist attributes still works
        let oldStylePlaylist = """
#EXTM3U
#EXTINF:-1 tvg-id="test" tvg-name="Test Channel", Test Channel
https://example.com/test.m3u8
"""
        
        let source = StringPlaylistSource(oldStylePlaylist)
        let parser = PlaylistParser()
        
        do {
            let playlist = try parser.parse(source)
            
            // Should still work but with no attributes
            XCTAssertEqual(playlist.medias.count, 1)
            XCTAssertNotNil(playlist.attributes, "Should have empty attributes object")
            XCTAssertNil(playlist.attributes?.epgUrl, "Should have no EPG URL")
            
            // Media parsing should work as before
            XCTAssertEqual(playlist.medias[0].name, "Test Channel")
            XCTAssertEqual(playlist.medias[0].attributes.id, "test")
            
            print("✅ Backward compatibility verified!")
            
        } catch {
            XCTFail("Backward compatibility test failed: \(error)")
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