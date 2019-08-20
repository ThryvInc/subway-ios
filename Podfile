source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

def import_pods
    pod "SBTextInputView"
    pod "SBNag.swift"
    pod 'SBCategories'
    pod 'ZipArchive'
    pod 'Fabric'
    pod 'Google-Mobile-Ads-SDK'
    pod 'Crashlytics'
    pod 'SQLite.swift', '0.11.4'
    pod 'ThryvUXComponents', git: 'https://github.com/ThryvInc/thryv-ux-components'
end

target 'SubwayMap' do
    pod "GTFSStations", :git => 'https://github.com/schrockblock/gtfs-stations', branch: 'develop'
    import_pods
end

target 'SubwayMapTests' do
    import_pods
    
    pod 'Quick'
    pod 'Nimble'
end

target 'LondonMap' do
    import_pods
end

target 'LondonMapTests' do
    import_pods
end

target 'ParisMap' do
    pod "GTFSStationsParis", :git => 'https://github.com/schrockblock/gtfs-stations-paris'
    import_pods
end

target 'ParisMapTests' do
    import_pods
end

