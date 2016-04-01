# Uncomment this line to define a global platform for your project
platform :ios, '8.0'
use_frameworks!

def import_pods
    pod "GTFSStations", :git => 'https://github.com/schrockblock/gtfs-stations', branch: 'develop'
    pod 'SQLite.swift', git: 'https://github.com/stephencelis/SQLite.swift.git'
    pod "SBTextInputView", :git => 'https://github.com/schrockblock/SBTextInputView'
    pod 'NagController', :git => 'https://github.com/schrockblock/nag-controller'
    pod 'SBCategories'
    pod 'ZipArchive'
    pod 'Fabric'
    pod 'Crashlytics'
end

target 'SubwayMap' do
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

