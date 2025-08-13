//
// URLMappingTests.swift
// M3UKit
//
// Tests for URL-to-metadata mapping accuracy
//

import XCTest
@testable import M3UKit

final class URLMappingTests: XCTestCase {
    
    func testURLMappingWithInterveningLines() {
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-name="Channel 1" group-title="Group A", Channel 1
#EXTGRP:Group A
#EXTVLCOPT:http-user-agent=Mozilla
https://example1.com/stream1.m3u8
#EXTINF:-1 tvg-name="Channel 2" group-title="Group B", Channel 2
#EXTGRP:Group B
#EXTVLCOPT:http-user-agent=Mozilla
https://example2.com/stream2.m3u8
#EXTINF:-1 tvg-name="Channel 3" group-title="Group C", Channel 3
https://example3.com/stream3.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        XCTAssertNoThrow(try parser.parse(source))
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 3)
        
        // Test exact URL-to-name mapping
        let media1 = playlist.medias[0]
        let media2 = playlist.medias[1] 
        let media3 = playlist.medias[2]
        
        print("Media 1: \(media1.name) -> \(media1.url)")
        print("Media 2: \(media2.name) -> \(media2.url)")
        print("Media 3: \(media3.name) -> \(media3.url)")
        
        // Critical test: ensure correct URL mapping
        XCTAssertEqual(media1.name, "Channel 1")
        XCTAssertTrue(media1.url.absoluteString.contains("stream1"), "Channel 1 should map to stream1, got: \(media1.url)")
        
        XCTAssertEqual(media2.name, "Channel 2")
        XCTAssertTrue(media2.url.absoluteString.contains("stream2"), "Channel 2 should map to stream2, got: \(media2.url)")
        
        XCTAssertEqual(media3.name, "Channel 3")
        XCTAssertTrue(media3.url.absoluteString.contains("stream3"), "Channel 3 should map to stream3, got: \(media3.url)")
    }
    
    func testActualNotWorkingPlaylistMapping() {
        let notWorkingURL = URL(fileURLWithPath: "/Users/benabid/Documents/Workspace/iOS/Jannaj/M3UKit/notworking.m3u8")
        
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist = try parser.parse(notWorkingURL)
            
            // Test the first few channels from the problematic playlist
            guard playlist.medias.count >= 3 else {
                XCTFail("Should have at least 3 channels")
                return
            }
            
            let channel1 = playlist.medias[0]
            let channel2 = playlist.medias[1]
            let channel3 = playlist.medias[2]
            
            print("=== Problematic Playlist URL Mapping ===")
            print("Channel 1: '\(channel1.name)' -> \(channel1.url)")
            print("Channel 2: '\(channel2.name)' -> \(channel2.url)")
            print("Channel 3: '\(channel3.name)' -> \(channel3.url)")
            
            // Expected: Channel 1 should be "Мульт БУМ!" with vsd246.okcdn.ru URL
            XCTAssertEqual(channel1.name, "Мульт БУМ!")
            XCTAssertTrue(channel1.url.absoluteString.contains("vsd246.okcdn.ru"), 
                         "Channel 1 should map to vsd246 URL, got: \(channel1.url)")
            
            // Expected: Channel 2 should be "Советские мультфильмы" with vsd149.okcdn.ru URL  
            XCTAssertEqual(channel2.name, "Советские мультфильмы")
            XCTAssertTrue(channel2.url.absoluteString.contains("vsd149.okcdn.ru"),
                         "Channel 2 should map to vsd149 URL, got: \(channel2.url)")
            
            // Expected: Channel 3 should be "Вселенная мультфильмов" with rutube.ru URL
            XCTAssertEqual(channel3.name, "Вселенная мультфильмов")
            XCTAssertTrue(channel3.url.absoluteString.contains("rutube.ru"),
                         "Channel 3 should map to rutube URL, got: \(channel3.url)")
            
        } catch {
            XCTFail("Failed to parse notworking.m3u8: \(error)")
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