# This is a generated file; do not edit or check into version control.

def flutter_install_all_ios_pods(ios_application_path = nil)
  flutter_install_ios_plugin_pods(ios_application_path)
end

def flutter_install_ios_plugin_pods(ios_application_path = nil)
  ios_application_path ||= File.dirname(File.realpath(__FILE__))
  File.foreach(File.join(ios_application_path, '..', 'Flutter', 'generated_podhelper.rb.snapshot')) do |line|
    matches = line.match(/\A  pod '(.*)', :path => '(.*)'\n\z/)
    if matches
      pod matches[1], :path => matches[2]
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
