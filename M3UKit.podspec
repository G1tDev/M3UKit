Pod::Spec.new do |s|
    s.name = 'M3UKit'
    s.version = '2.2.0'
    s.summary = 'Robust M3U/M3U8 playlist parser with enhanced IPTV support'
    s.description = <<-DESC
    Enhanced M3UKit with robust parsing capabilities for IPTV applications.
    Handles any playlist format with comprehensive error recovery and validation.
    Includes high-performance parser optimized for large playlists (100MB+) with
    concurrent processing, streaming mode, and progress reporting.
    DESC
    s.homepage = 'https://github.com/omaralbeik/M3UKit'
    s.license = { :type => 'MIT', :file => 'LICENSE' }
    s.authors = { 'Omar Albeik' => 'https://twitter.com/omaralbeik' }
    s.module_name  = 'M3UKit'
    s.source = { :git => 'https://github.com/omaralbeik/M3UKit.git', :tag => s.version }
    s.source_files = 'Sources/**/*.swift'
    s.swift_versions = ['5.5', '5.6', '5.7']
    s.ios.deployment_target = '11.0'
    s.osx.deployment_target = '10.13'
    s.tvos.deployment_target = '11.0'
end