# This is a generated file; do not edit or check into version control.

require 'json'

def flutter_install_all_ios_pods(ios_application_path = nil)
  flutter_install_ios_plugin_pods(ios_application_path)
end

def flutter_install_ios_plugin_pods(ios_application_path = nil)
  ios_application_path ||= File.dirname(File.realpath(__FILE__))
  package_config_path = File.join(ios_application_path, '..', '..', '.dart_tool', 'package_config.json')
  
  return unless File.exist?(package_config_path)
  
  package_config = JSON.parse(File.read(package_config_path))
  package_config['packages'].each do |package|
    # Look for plugins with ios support
    root_uri = package['rootUri']
    # rootUri is usually relative like 'file:///...' or '../...'
    # We need to handle relative paths
    path = if root_uri.start_with?('file://')
             URI.decode_www_form_component(root_uri.sub('file://', ''))
           else
             File.expand_path(File.join(ios_application_path, '..', '..', '.dart_tool', root_uri))
           end
    
    podspec_path = File.join(path, 'ios', "#{package['name']}.podspec")
    if File.exist?(podspec_path)
      pod package['name'], :path => File.join(path, 'ios')
    end
  end
end

def flutter_additional_ios_build_settings(target)
  return unless target.platform_name == :ios
  target.build_configurations.each do |config|
    config.build_settings['ENABLE_BITCODE'] = 'NO'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  end
end
