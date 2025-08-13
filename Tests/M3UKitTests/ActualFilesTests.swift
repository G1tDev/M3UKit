//
// ActualFilesTests.swift
// M3UKit
//
// Tests using the actual provided playlist files
//

import XCTest
@testable import M3UKit

final class ActualFilesTests: XCTestCase {
    
    func testWorkingM3U8File() {
        let workingURL = URL(fileURLWithPath: "/Users/benabid/Documents/Workspace/iOS/Jannaj/M3UKit/working.m3u8")
        
        let parser = PlaylistParser(options: [])
        
        XCTAssertNoThrow(try parser.parse(workingURL))
        
        do {
            let playlist = try parser.parse(workingURL)
            print("✅ Working M3U8 - Successfully parsed \\(playlist.medias.count) channels")
            
            // Verify we got channels
            XCTAssertGreaterThan(playlist.medias.count, 0)
            
            // Test some channels
            for (index, media) in playlist.medias.prefix(3).enumerated() {
                print("  Channel \\(index + 1): \\(media.name)")
                print("    URL: \\(media.url)")
                print("    Group: \\(media.attributes.groupTitle ?? \"None\")")
                print("    Duration: \\(media.duration)")
            }
            
        } catch {
            XCTFail("Failed to parse working.m3u8: \\(error)")
        }
    }
    
    func testNotWorkingM3U8File() {
        let notWorkingURL = URL(fileURLWithPath: "/Users/benabid/Documents/Workspace/iOS/Jannaj/M3UKit/notworking.m3u8")
        
        let parser = PlaylistParser(options: [])
        
        XCTAssertNoThrow(try parser.parse(notWorkingURL))
        
        do {
            let playlist = try parser.parse(notWorkingURL)
            print("✅ Not Working M3U8 - Successfully parsed \\(playlist.medias.count) channels")
            
            // Verify we got channels
            XCTAssertGreaterThan(playlist.medias.count, 0)
            
            // Test some channels with issues
            for (index, media) in playlist.medias.prefix(3).enumerated() {
                print("  Channel \\(index + 1): \\(media.name)")
                print("    URL: \\(media.url)")
                print("    Group: \\(media.attributes.groupTitle ?? \"None\")")
                print("    Duration: \\(media.duration)")
                print("    ID: \\(media.attributes.id ?? \"None\")")
            }
            
        } catch {
            XCTFail("Failed to parse notworking.m3u8: \\(error)")
        }
    }
    
    func testComparisonBetweenFiles() {
        let workingURL = URL(fileURLWithPath: "/Users/benabid/Documents/Workspace/iOS/Jannaj/M3UKit/working.m3u8")
        let notWorkingURL = URL(fileURLWithPath: "/Users/benabid/Documents/Workspace/iOS/Jannaj/M3UKit/notworking.m3u8")
        
        let parser = PlaylistParser(options: [])
        
        do {
            let workingPlaylist = try parser.parse(workingURL)
            let notWorkingPlaylist = try parser.parse(notWorkingURL)
            
            print("📊 Comparison:")
            print("  Working file: \\(workingPlaylist.medias.count) channels")
            print("  Not working file: \\(notWorkingPlaylist.medias.count) channels")
            
            // Both should parse successfully now
            XCTAssertGreaterThan(workingPlaylist.medias.count, 0)
            XCTAssertGreaterThan(notWorkingPlaylist.medias.count, 0)
            
        } catch {
            XCTFail("Failed to parse files for comparison: \\(error)")
        }
    }
}