# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

def available_pods
  pod 'DefaultsKit'
  pod 'Alamofire'
  pod 'SwiftyJSON'
  pod 'CountdownLabel'
  pod 'Localize-Swift'
  pod 'Kingfisher', '~> 7.0'
  pod 'RealmSwift'
  pod 'Wormholy', :configurations => ['Debug']
  pod 'EasyTipView', '~> 2.1'
  pod 'CryptoSwift', '~> 1.4.1'
  pod 'FloatingPanel'
  pod 'YPImagePicker'
  pod 'MessageKit'
  pod 'SKCountryPicker'
  pod 'Starscream', '~> 4.0.6'

  # Pods for Firebase
  pod 'Firebase/Core'
  pod 'Firebase/Analytics'
  pod 'Firebase/Messaging'

  # Pods for Facebook
  pod 'FacebookCore'
  pod 'FacebookLogin'

  # Pods for Google Sign In
  pod 'GoogleSignIn'
end

target 'WishingWell' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WishingWell
  available_pods

  target 'WishingWellTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'WishingWellUITests' do
    # Pods for testing
  end

end

target 'WishingWellStag' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WishingWellStag
  available_pods
end

post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
               end
          end
   end
end
