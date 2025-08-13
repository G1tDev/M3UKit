//
// LongURLTests.swift
// M3UKit
//
// Tests for handling extremely long URLs that might cause mapping issues
//

import XCTest
@testable import M3UKit

final class LongURLTests: XCTestCase {
    
    func testLongURLWithParameters() {
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-name="Channel with Long URL" group-title="Test", Channel with Long URL
#EXTGRP:Test
#EXTVLCOPT:http-referrer=https://trovo.live/
https://liveplay.trovo.live/live/73846_116776568_116776568.flv?bizid=73846&txSecret=5cd01b416c148b1cbb1b2a43d847ba73&txTime=686b04b0&_bmlj_t=ChxSTysrUGJJem5seThZY1orWlZrcG5NejJ2bTA9EiQzNWJiOGVhZi1mNzVhLTQ5NzYtOTM3Mi03MTZmZWI1OTI0NGMaHjExNjc3NjU2OF8xMTY3NzY1NjhfMTc1MTIzOTE3NyDZ0InDBiiP%2BMQ3Mhk3Mzg0Nl8xMTY3NzY1NjhfMTE2Nzc2NTY4Qg40Ni4xMzguMTUxLjIzMUobbGl2ZS1yZWFkZXItc3ZyX0dldExpdmVJbmZvUARgAnoQNDgwMzE3NDQyNTA0MTkwOJABBA%3D%3D&playScene=innerSite&pvid=4803174425041908&_f_=1751279710051
#EXTINF:-1 tvg-name="Second Channel" group-title="Test", Second Channel
https://example.com/stream2.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        XCTAssertNoThrow(try parser.parse(source))
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 2)
        
        let firstChannel = playlist.medias[0]
        let secondChannel = playlist.medias[1]
        
        print("First Channel: '\(firstChannel.name)' -> \(firstChannel.url)")
        print("Second Channel: '\(secondChannel.name)' -> \(secondChannel.url)")
        
        // Critical test: ensure long URL is properly associated
        XCTAssertEqual(firstChannel.name, "Channel with Long URL")
        XCTAssertTrue(firstChannel.url.absoluteString.contains("liveplay.trovo.live"), 
                     "First channel should have the long trovo URL, got: \(firstChannel.url)")
        
        XCTAssertEqual(secondChannel.name, "Second Channel")
        XCTAssertTrue(secondChannel.url.absoluteString.contains("example.com"),
                     "Second channel should have example.com URL, got: \(secondChannel.url)")
    }
    
    func testRTMPURLs() {
        let playlistContent = """
#EXTM3U
#EXTINF:-1 tvg-name="RTMP Channel" group-title="Test", RTMP Channel
#EXTGRP:Test
#EXTVLCOPT:http-user-agent=Mozilla
rtmp://vkvsd163.okcdn.ru/playback/9617415285537?stkn=7rG8jAJ_-nsgBzwhMK0YMXnxU1lCKkv9ovPNX2TNniYZq7NsMZGTGN8xMQH1FHtYphA4-vhgtOs&uid=0&sp=uid,sp&sig=vlibqm4nyu&fromCache=1
#EXTINF:-1 tvg-name="HTTP Channel" group-title="Test", HTTP Channel
https://example.com/stream.m3u8
"""
        
        let source = StringPlaylistSource(playlistContent)
        let parser = PlaylistParser(options: [])
        
        XCTAssertNoThrow(try parser.parse(source))
        
        let playlist = try! parser.parse(source)
        XCTAssertEqual(playlist.medias.count, 2)
        
        let rtmpChannel = playlist.medias[0]
        let httpChannel = playlist.medias[1]
        
        print("RTMP Channel: '\(rtmpChannel.name)' -> \(rtmpChannel.url)")
        print("HTTP Channel: '\(httpChannel.name)' -> \(httpChannel.url)")
        
        // Test RTMP URL mapping
        XCTAssertEqual(rtmpChannel.name, "RTMP Channel")
        XCTAssertEqual(rtmpChannel.url.scheme, "rtmp")
        XCTAssertTrue(rtmpChannel.url.absoluteString.contains("vkvsd163.okcdn.ru"))
        
        // Test HTTP URL mapping
        XCTAssertEqual(httpChannel.name, "HTTP Channel")
        XCTAssertEqual(httpChannel.url.scheme, "https")
        XCTAssertTrue(httpChannel.url.absoluteString.contains("example.com"))
    }
    
    func testDetailedNotWorkingPlaylistAnalysis() {
        let currentPath = FileManager.default.currentDirectoryPath
        let notWorkingURL = URL(fileURLWithPath: currentPath).appendingPathComponent("notworking.m3u8")
        
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist = try parser.parse(notWorkingURL)
            
            print("=== Detailed Playlist Analysis ===")
            print("Total channels parsed: \(playlist.medias.count)")
            
            // Analyze first 10 channels for URL mapping accuracy
            for (index, media) in playlist.medias.prefix(10).enumerated() {
                print("Channel \(index + 1): '\(media.name)'")
                print("  URL: \(media.url)")
                print("  Scheme: \(media.url.scheme ?? "none")")
                print("  Host: \(media.url.host ?? "none")")
                print("---")
            }
            
            // Look for specific issues
            let rtmpChannels = playlist.medias.filter { $0.url.scheme == "rtmp" }
            let httpChannels = playlist.medias.filter { $0.url.scheme == "https" || $0.url.scheme == "http" }
            let dataChannels = playlist.medias.filter { $0.url.scheme == "data" }
            
            print("URL Scheme Distribution:")
            print("  RTMP: \(rtmpChannels.count)")
            print("  HTTP/HTTPS: \(httpChannels.count)")
            print("  Data URLs (fallback): \(dataChannels.count)")
            
            if !dataChannels.isEmpty {
                print("WARNING: Found data URLs (fallback URLs), indicating parsing issues:")
                for dataChannel in dataChannels.prefix(3) {
                    print("  - \(dataChannel.name): \(dataChannel.url)")
                }
            }
            
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