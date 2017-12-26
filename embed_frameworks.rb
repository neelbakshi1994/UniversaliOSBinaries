require "xcodeproj"
require "fileutils"

project_location = "/path/to/xcodeproj"
project = Xcodeproj::Project.open(project_location)
build_directory = "./PodsBuild"
universal_directory = "#{build_directory}/Universal"

dependencies = {
  "Target1"=> "All",
  "Target2"=> ["Library1", "Library2"]
}

def embed_framework(target, dependencies, project, universal_directory, configuration)

  # Get useful variables
  puts "Started embedding #{dependencies} in #{target}"
  frameworks_group = project.groups.find { |group| group.display_name == 'Frameworks' }
  frameworks_build_phase = target.build_phases.find { |build_phase| build_phase.to_s == 'FrameworksBuildPhase' }

  # Add framework search path to target
  paths = [universal_directory]
  target.build_settings(configuration)["FRAMEWORK_SEARCH_PATHS"] = paths
  puts "Finished adding framework search path to target"

  # Add new "Embed Frameworks" build phase to target
  embed_frameworks_build_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed_frameworks_build_phase.name = "Embed Frameworks"
  embed_frameworks_build_phase.symbol_dst_subfolder_spec = :frameworks
  target.build_phases << embed_frameworks_build_phase
  puts "Finished adding Embed Frameworks build phase to target"

  Dir.glob("#{universal_directory}/*.framework") do |framework_path|
    framework = File.basename(framework_path, ".framework")
    puts "#{framework}"
    if dependencies.eql?("All")
      # Add framework to target as "Embedded Frameworks"
      puts "Adding framework: #{framework}"
      framework_ref = frameworks_group.new_file(framework_path)
      build_file = embed_frameworks_build_phase.add_file_reference(framework_ref)
      frameworks_build_phase.add_file_reference(framework_ref)
      build_file.settings = { "ATTRIBUTES" => ["CodeSignOnCopy", "RemoveHeadersOnCopy"] }
      puts "Finished adding framework: #{framework_path}"
    elsif dependencies.include?(framework)
      puts "Adding framework: #{framework}"
      framework_ref = frameworks_group.new_file(framework_path)
      build_file = embed_frameworks_build_phase.add_file_reference(framework_ref)
      frameworks_build_phase.add_file_reference(framework_ref)
      build_file.settings = { "ATTRIBUTES" => ["CodeSignOnCopy", "RemoveHeadersOnCopy"] }
      puts "Finished adding framework: #{framework_path}"
    end
  end

  # Save Xcode project
  project.save
end

project.targets.each do |target|
  puts "Adding dependencies #{dependencies["#{target}"]}"
  if dependencies["#{target}"] != nil
    embed_framework(target, dependencies["#{target}"], project, universal_directory, 'Debug')
  end
end
