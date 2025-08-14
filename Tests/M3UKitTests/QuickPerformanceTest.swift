//
// QuickPerformanceTest.swift
// M3UKit
//
// Quick test to verify high-performance parser works
//

import XCTest
@testable import M3UKit

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class QuickPerformanceTest: XCTestCase {
    
    func testBasicHighPerformanceParser() async throws {
        let playlist = """
#EXTM3U url-tvg="https://example.com/epg.xml"
#EXTINF:-1 tvg-id="test1" tvg-name="Test 1" group-title="Test", Test Channel 1
https://example.com/stream1.m3u8
#EXTINF:-1 tvg-id="test2" tvg-name="Test 2" group-title="Test", Test Channel 2
https://example.com/stream2.m3u8
"""
        
        let source = StringPlaylistSource(playlist)
        let parser = HighPerformanceParser()
        
        let result = try await parser.parse(source)
        
        XCTAssertEqual(result.medias.count, 2)
        XCTAssertEqual(result.medias[0].name, "Test Channel 1")
        XCTAssertEqual(result.medias[1].name, "Test Channel 2")
        XCTAssertEqual(result.attributes?.epgUrl, "https://example.com/epg.xml")
        
        print("✅ High-performance parser basic test passed!")
    }
    
    func testStandardParser() throws {
        let playlist = generateTestPlaylist(channelCount: 100)
        let source = StringPlaylistSource(playlist)
        
        let standardParser = PlaylistParser(options: .iptv)
        let standardResult = try standardParser.parse(source)
        
        XCTAssertEqual(standardResult.medias.count, 100)
        print("✅ Standard parser produced \(standardResult.medias.count) channels")
    }
    
    func testHighPerformanceParserAsync() async throws {
        let playlist = generateTestPlaylist(channelCount: 100)
        let source = StringPlaylistSource(playlist)
        
        let highPerfParser = HighPerformanceParser()
        let highPerfResult = try await highPerfParser.parse(source)
        
        XCTAssertEqual(highPerfResult.medias.count, 100)
        print("✅ High-performance parser produced \(highPerfResult.medias.count) channels")
    }
    
    private func generateTestPlaylist(channelCount: Int) -> String {
        var playlist = "#EXTM3U url-tvg=\"https://test.com/epg.xml\"\n"
        
        for i in 1...channelCount {
            playlist += "#EXTINF:-1 tvg-id=\"test\(i)\" tvg-name=\"Test \(i)\" group-title=\"Group\(i % 5)\", Test Channel \(i)\n"
            playlist += "https://example.com/stream\(i).m3u8\n"
        }
        
        return playlist
    }
}

// Helper class
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