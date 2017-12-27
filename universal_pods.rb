require "fileutils"
require "xcodeproj"

#================ Adding new target for building all libraries =================
#Put this file in your Project folder
project = Xcodeproj::Project.open("./Pods/Pods.xcodeproj")
puts "Using project: #{project}"
targets = project.native_targets
agg_target = project.new_aggregate_target("Pods", targets)
puts "Created new target with name: #{agg_target}"
project.save
puts "Target saved"

pods_directory = "./Pods"
pods_project = "#{pods_directory}/Pods.xcodeproj"
build_directory = "./PodsBuild"
configuration = "Release"
iphoneos_libs_directory = "#{build_directory}/#{configuration}-iphoneos"
iphonesimulator_libs_directory = "#{build_directory}/#{configuration}-iphonesimulator"
universal_directory = "#{build_directory}/Universal"

puts "Making build directory directory at #{build_directory}"
FileUtils::mkdir_p("#{universal_directory}")

#=================== Moving already built frameworks =============
puts "Copying already build frameworks to #{universal_directory}"
Dir.glob("./Pods/**/*.framework") do |framework_path|
  FileUtils.cp_r(framework_path, universal_directory)
end

#==================== Building simulator and device versions =================
system("xcodebuild -project \"#{pods_project}\" -target \"Pods\" ONLY_ACTIVE_ARCH=NO -configuration #{configuration} -sdk iphoneos  BUILD_DIR=\"../PodsBuild\" OTHER_CFLAGS=\"-fembed-bitcode\" clean build")
system("xcodebuild -project \"#{pods_project}\" -target \"Pods\" -configuration #{configuration} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO BUILD_DIR=\"../PodsBuild\" OTHER_CFLAGS=\"-fembed-bitcode\" clean build")

puts "Copying iphone os libraries to #{universal_directory}"
system("find #{iphoneos_libs_directory} -name '*.framework' -exec cp -rpv \'{}\' #{universal_directory} \';\'")

puts "Copying swift modules from simulator build directory to universal directory"
#This is done because the simulator builds have the library structure built for simulator processors
Dir.glob("#{iphonesimulator_libs_directory}/*/*/Modules/*.swiftmodule") do |framework|
  framework_name =  File.basename(framework, ".swiftmodule")
  destination = "#{universal_directory}/#{framework_name}.framework/Modules/"
  puts "Copying #{framework} to #{destination}"
  FileUtils.cp_r(framework, destination)
end

Dir.glob("#{iphoneos_libs_directory}/*") do |folder_path|
  folder = File.basename(folder_path)
  renamed_folder = folder.gsub(/[@-]/, '_')
  if !folder.eql?(renamed_folder)
    FileUtils.mv("#{iphoneos_libs_directory}/#{folder}", "#{iphoneos_libs_directory}/#{renamed_folder}")
  end
end

Dir.glob("#{iphonesimulator_libs_directory}/*") do |folder_path|
  folder = File.basename(folder_path)
  renamed_folder = folder.gsub(/[@-]/, '_')
  if !folder.eql?(renamed_folder)
    FileUtils.mv("#{iphonesimulator_libs_directory}/#{folder}", "#{iphonesimulator_libs_directory}/#{renamed_folder}")
  end
end

Dir.glob("#{universal_directory}/*.framework") do |framework|
  framework_name = File.basename(framework, ".framework")
  FileUtils.rm_f("#{framework}/#{framework_name}")
  system("lipo -create -output \"#{framework}/#{framework_name}\" \"#{iphonesimulator_libs_directory}/#{framework_name}/#{framework_name}.framework/#{framework_name}\" \"#{iphoneos_libs_directory}/#{framework_name}/#{framework_name}.framework/#{framework_name}\"")
end
