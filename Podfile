# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Mesh Chat' do
  use_frameworks!
  
  # Pods for Mesh Chat
  pod 'MessageKit', '~> 1.0'
  pod 'FCUUID'

  post_install do |installer|
        installer.pods_project.targets.each do |target|
            if target.name == 'MessageKit'
                target.build_configurations.each do |config|
                    config.build_settings['SWIFT_VERSION'] = '4.0'
                end
            end
        end
    end


  target 'Mesh ChatTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
