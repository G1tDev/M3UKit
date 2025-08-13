//
// URLMappingFixValidationTests.swift
// M3UKit
//
// Tests to validate the URL mapping fix
//

import XCTest
@testable import M3UKit

final class URLMappingFixValidationTests: XCTestCase {
    
    func testURLMappingAccuracy() {
        // Test specific channels from the problematic playlist
        let currentPath = FileManager.default.currentDirectoryPath
        let notWorkingURL = URL(fileURLWithPath: currentPath).appendingPathComponent("notworking.m3u8")
        
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist = try parser.parse(notWorkingURL)
            
            // Test specific known mappings that were potentially problematic
            XCTAssertGreaterThan(playlist.medias.count, 10, "Should have many channels")
            
            // Find specific channels and validate their URLs
            let multBoom = playlist.medias.first { $0.name.contains("Мульт БУМ") }
            XCTAssertNotNil(multBoom, "Should find 'Мульт БУМ!' channel")
            XCTAssertTrue(multBoom?.url.absoluteString.contains("vsd246.okcdn.ru") ?? false, 
                         "Мульт БУМ! should map to vsd246.okcdn.ru")
            
            let sovietCartoons = playlist.medias.first { $0.name.contains("Советские мультфильмы") }
            XCTAssertNotNil(sovietCartoons, "Should find 'Советские мультфильмы' channel")
            XCTAssertTrue(sovietCartoons?.url.absoluteString.contains("vsd149.okcdn.ru") ?? false,
                         "Советские мультфильмы should map to vsd149.okcdn.ru")
            
            let universeCartoons = playlist.medias.first { $0.name.contains("Вселенная мультфильмов") }
            XCTAssertNotNil(universeCartoons, "Should find 'Вселенная мультфильмов' channel")
            XCTAssertTrue(universeCartoons?.url.absoluteString.contains("rutube.ru") ?? false,
                         "Вселенная мультфильмов should map to rutube.ru")
            
            let retroMult = playlist.medias.first { $0.name.contains("retromult") }
            XCTAssertNotNil(retroMult, "Should find 'retromult' channel")
            XCTAssertTrue(retroMult?.url.absoluteString.contains("trovo.live") ?? false,
                         "retromult should map to trovo.live")
            
            print("✅ All specific URL mappings validated successfully")
            
            // Test that no channels have obviously wrong URL mappings
            var mappingIssues = 0
            for media in playlist.medias.prefix(20) {
                // Basic sanity check - URL should not be a data URL (indicates parsing failure)
                if media.url.scheme == "data" {
                    print("⚠️ Found data URL fallback for '\(media.name)'")
                    mappingIssues += 1
                }
                
                // Check for empty or clearly wrong names
                if media.name.isEmpty || media.name == "Unknown" {
                    print("⚠️ Found channel with missing/default name: '\(media.name)' -> \(media.url)")
                    mappingIssues += 1
                }
            }
            
            XCTAssertEqual(mappingIssues, 0, "Should have no obvious mapping issues")
            
        } catch {
            XCTFail("Failed to parse notworking.m3u8: \(error)")
        }
    }
    
    func testNoUnexpectedURLSwapping() {
        // Parse the same playlist twice and ensure identical results
        let currentPath = FileManager.default.currentDirectoryPath
        let notWorkingURL = URL(fileURLWithPath: currentPath).appendingPathComponent("notworking.m3u8")
        
        let parser = PlaylistParser(options: [])
        
        do {
            let playlist1 = try parser.parse(notWorkingURL)
            let playlist2 = try parser.parse(notWorkingURL)
            
            XCTAssertEqual(playlist1.medias.count, playlist2.medias.count)
            
            // Compare first 10 channels for exact match
            for i in 0..<min(10, playlist1.medias.count) {
                let media1 = playlist1.medias[i]
                let media2 = playlist2.medias[i]
                
                XCTAssertEqual(media1.name, media2.name, 
                              "Channel \(i+1) name should be consistent between parses")
                XCTAssertEqual(media1.url, media2.url,
                              "Channel \(i+1) URL should be consistent between parses")
            }
            
            print("✅ No URL swapping detected - parsing is deterministic")
            
        } catch {
            XCTFail("Failed to parse for swapping test: \(error)")
        }
    }
    
    func testEdgeCaseHandling() {
        // Test the exact pattern that was causing issues
        let problematicPattern = """
#EXTM3U
#EXTINF:-1 tvg-name="Channel 1", Channel 1
#EXTGRP:Group
#EXTVLCOPT:option1
#EXTVLCOPT:option2
https://correct-url-1.com/stream.m3u8
#EXTINF:-1 tvg-name="Channel 2", Channel 2
#EXTGRP:Group
#EXTVLCOPT:option3
https://correct-url-2.com/stream.m3u8
"""
        
        let source = StringPlaylistSource(problematicPattern)
        let parser = PlaylistParser(options: [])
        
        let playlist = try! parser.parse(source)
        
        XCTAssertEqual(playlist.medias.count, 2)
        
        // Ensure correct URL mapping despite intervening lines
        XCTAssertEqual(playlist.medias[0].name, "Channel 1")
        XCTAssertTrue(playlist.medias[0].url.absoluteString.contains("correct-url-1.com"))
        
        XCTAssertEqual(playlist.medias[1].name, "Channel 2")
        XCTAssertTrue(playlist.medias[1].url.absoluteString.contains("correct-url-2.com"))
        
        print("✅ Edge case handling validated - intervening lines don't affect URL mapping")
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