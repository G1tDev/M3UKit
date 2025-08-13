//
// URLMappingRegressionTests.swift
// M3UKit
//
// Comprehensive tests to prevent URL mapping regression
//

import XCTest
@testable import M3UKit

final class URLMappingRegressionTests: XCTestCase {
    
    func testStrictURLMetadatapairing() {
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-name="Channel A", Channel A
https://url-a.com/stream.m3u8
#EXTINF:-1 tvg-name="Channel B", Channel B
#EXTGRP:Group
#EXTVLCOPT:option
https://url-b.com/stream.m3u8
#EXTINF:-1 tvg-name="Channel C", Channel C
#EXTVLCOPT:option1
#EXTVLCOPT:option2
#EXTGRP:Group
https://url-c.com/stream.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 3)
        
        // Test exact pairing
        XCTAssertEqual(playlist.medias[0].name, "Channel A")
        XCTAssertTrue(playlist.medias[0].url.absoluteString.contains("url-a.com"))
        
        XCTAssertEqual(playlist.medias[1].name, "Channel B")
        XCTAssertTrue(playlist.medias[1].url.absoluteString.contains("url-b.com"))
        
        XCTAssertEqual(playlist.medias[2].name, "Channel C")
        XCTAssertTrue(playlist.medias[2].url.absoluteString.contains("url-c.com"))
    }
    
    func testMultipleURLsPerEntry() {
        // This should NOT happen in valid playlists, but test our handling
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-name="Channel with Multiple URLs", Channel with Multiple URLs
https://first-url.com/stream.m3u8
https://second-url.com/stream.m3u8
https://third-url.com/stream.m3u8
#EXTINF:-1 tvg-name="Next Channel", Next Channel
https://next-url.com/stream.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        let playlist = try! parser.parse(source)
        
        // Should only get 2 channels (not confused by multiple URLs)
        XCTAssertEqual(playlist.medias.count, 2)
        
        // First channel should use the first URL only
        XCTAssertEqual(playlist.medias[0].name, "Channel with Multiple URLs")
        XCTAssertTrue(playlist.medias[0].url.absoluteString.contains("first-url.com"))
        
        // Second channel should be correct
        XCTAssertEqual(playlist.medias[1].name, "Next Channel")
        XCTAssertTrue(playlist.medias[1].url.absoluteString.contains("next-url.com"))
    }
    
    func testMissingURLHandling() {
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-name="Channel with URL", Channel with URL
https://valid-url.com/stream.m3u8
#EXTINF:-1 tvg-name="Channel without URL", Channel without URL
#EXTINF:-1 tvg-name="Another Channel with URL", Another Channel with URL
https://another-valid-url.com/stream.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        let playlist = try! parser.parse(source)
        
        // Should only get 2 channels (skip the one without URL)
        XCTAssertEqual(playlist.medias.count, 2)
        
        XCTAssertEqual(playlist.medias[0].name, "Channel with URL")
        XCTAssertTrue(playlist.medias[0].url.absoluteString.contains("valid-url.com"))
        
        XCTAssertEqual(playlist.medias[1].name, "Another Channel with URL")
        XCTAssertTrue(playlist.medias[1].url.absoluteString.contains("another-valid-url.com"))
    }
    
    func testComplexRealWorldScenario() {
        // Based on the actual problematic patterns from notworking.m3u8
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-name="Мульт БУМ!" tvg-logo="https://example.com/logo1.png" group-title="МультStream", Мульт БУМ!
#EXTGRP:МультStream
#EXTVLCOPT:http-user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64)
https://vsd246.okcdn.ru/hls/4087812852332.m3u8/sig/Mul5VVYyYpk/expires/1755151241980/srcIp/46.138.146.223/urls/185.226.53.66/clientType/0/srcAg/CHROME_YA/mid/5385622068844/video.m3u8?p
#EXTINF:-1 tvg-name="Советские мультфильмы" tvg-logo="https://example.com/logo2.jpg" group-title="МультStream", Советские мультфильмы
#EXTGRP:МультStream
#EXTVLCOPT:http-user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64)
https://vsd149.okcdn.ru/hls/4087089138284.m3u8/sig/a7fyWTn6Szg/expires/1755151284766/srcIp/46.138.146.223/urls/45.136.21.82/clientType/0/srcAg/CHROME_YA/mid/5385000066668/video.m3u8?p
#EXTINF:-1 tvg-name="retromult" group-title="МультStream", retromult
#EXTGRP:МультStream
#EXTVLCOPT:http-referrer=https://trovo.live/
https://liveplay.trovo.live/live/73846_116776568_116776568.flv?bizid=73846&txSecret=5cd01b416c148b1cbb1b2a43d847ba73&txTime=686b04b0&playScene=innerSite&pvid=4803174425041908
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 3)
        
        // Test exact mapping for each channel
        let channel1 = playlist.medias[0]
        XCTAssertEqual(channel1.name, "Мульт БУМ!")
        XCTAssertTrue(channel1.url.absoluteString.contains("vsd246.okcdn.ru"))
        XCTAssertEqual(channel1.attributes.groupTitle, "МультStream")
        
        let channel2 = playlist.medias[1]
        XCTAssertEqual(channel2.name, "Советские мультфильмы")
        XCTAssertTrue(channel2.url.absoluteString.contains("vsd149.okcdn.ru"))
        XCTAssertEqual(channel2.attributes.groupTitle, "МультStream")
        
        let channel3 = playlist.medias[2]
        XCTAssertEqual(channel3.name, "retromult")
        XCTAssertTrue(channel3.url.absoluteString.contains("liveplay.trovo.live"))
        XCTAssertEqual(channel3.attributes.groupTitle, "МультStream")
        
        print("=== Complex Scenario Test Results ===")
        for (index, media) in playlist.medias.enumerated() {
            print("Channel \(index + 1): '\(media.name)' -> \(media.url.host ?? "no-host")")
        }
    }
    
    func testActualPlaylistConsistency() {
        // Test the actual problematic playlist multiple times to check for consistency
        let currentPath = FileManager.default.currentDirectoryPath
        let notWorkingURL = URL(fileURLWithPath: currentPath).appendingPathComponent("notworking.m3u8")
        
        let parser = PlaylistParser(options: [])
        
        var results: [(String, String)] = []
        
        // Parse the same playlist 5 times
        for i in 1...5 {
            do {
                let playlist = try parser.parse(notWorkingURL)
                
                // Record first 5 channels each time
                for j in 0..<min(5, playlist.medias.count) {
                    let media = playlist.medias[j]
                    results.append((media.name, media.url.host ?? "no-host"))
                }
                
                print("Parse \(i): \(playlist.medias.count) channels")
            } catch {
                XCTFail("Parse \(i) failed: \(error)")
            }
        }
        
        // Check consistency - all parses should produce the same results
        let firstParseResults = Array(results[0..<5])
        
        for parseIndex in 1..<5 {
            let parseResults = Array(results[(parseIndex * 5)..<(parseIndex * 5 + 5)])
            for (index, result) in parseResults.enumerated() {
                XCTAssertEqual(result.0, firstParseResults[index].0, 
                              "Channel \(index + 1) name inconsistent between parses")
                XCTAssertEqual(result.1, firstParseResults[index].1, 
                              "Channel \(index + 1) host inconsistent between parses")
            }
        }
        
        print("✅ Consistency test passed - all parses produced identical results")
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