#!/usr/bin/env ruby
# This script adds the RunnerWidget extension target to the existing
# Flutter-managed Xcode project, preserving all Flutter build phases.

require 'xcodeproj'

project_path = File.join(__dir__, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

# Check if the widget target already exists
existing = project.targets.find { |t| t.name == 'RunnerWidget' }
if existing
  puts "RunnerWidget target already exists, skipping."
  exit 0
end

# Create the app extension target
widget_target = project.new_target(
  :app_extension,
  'RunnerWidget',
  :ios,
  '14.0'
)

# Set build settings
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.example.yourapp.Widget'
  config.build_settings['INFOPLIST_FILE'] = 'RunnerWidget/Info.plist'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['CODE_SIGN_IDENTITY'] = ''
  config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
  config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
end

# Add source files to the widget target
widget_group = project.main_group.new_group('RunnerWidget', 'RunnerWidget')
widget_dir = File.join(__dir__, 'RunnerWidget')

Dir.glob(File.join(widget_dir, '*.swift')).each do |file|
  file_ref = widget_group.new_file(file)
  widget_target.source_build_phase.add_file_reference(file_ref)
end

# Add Info.plist as a resource (it's referenced via INFOPLIST_FILE, not compiled)
plist_path = File.join(widget_dir, 'Info.plist')
if File.exist?(plist_path)
  widget_group.new_file(plist_path)
end

# Add the widget as a dependency of the main Runner target
runner_target = project.targets.find { |t| t.name == 'Runner' }
if runner_target
  runner_target.add_dependency(widget_target)

  # Add "Embed App Extensions" build phase
  embed_phase = runner_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.dst_subfolder_spec = '13' # PlugIns folder
  embed_phase.add_file_reference(widget_target.product_reference)
end

project.save

puts "Successfully added RunnerWidget target to Xcode project."
