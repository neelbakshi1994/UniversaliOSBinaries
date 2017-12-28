require "fileutils"
require "xcodeproj"

pods_directory = "./Pods"
pods_project = "#{pods_directory}/Pods.xcodeproj"
build_directory = "./PodsBuild"
configuration = "Release"
iphoneos_libs_directory = "#{build_directory}/#{configuration}-iphoneos"
iphonesimulator_libs_directory = "#{build_directory}/#{configuration}-iphonesimulator"
universal_directory = "#{build_directory}/Universal"

puts "Making build directory directory at #{build_directory}"
FileUtils::mkdir_p("#{universal_directory}")

#==================== Building simulator and device versions =================
#================ Adding new target for building all libraries =================
project = Xcodeproj::Project.open("./Pods/Pods.xcodeproj")
puts "Using project: #{project}"
project.native_targets.each do |target|
    #if target.name.start_with?("name_of_target_in_the_pods_project_you_want_to_build") 
    if !target.name.start_with?("Pods-")
        puts "Building target #{target} for iphone os"
        system("xcodebuild -project \"#{pods_project}\" -target #{target} BITCODE_GENERATION_MODE=bitcode ONLY_ACTIVE_ARCH=NO -configuration #{configuration} -sdk iphoneos  BUILD_DIR=\"../PodsBuild\" OTHER_CFLAGS=\"-fembed-bitcode\" build")
        puts "Building target #{target} for iphone simulator"
        system("xcodebuild -project \"#{pods_project}\" -target #{target} -configuration #{configuration} -sdk iphonesimulator BITCODE_GENERATION_MODE=bitcode ONLY_ACTIVE_ARCH=NO BUILD_DIR=\"../PodsBuild\" OTHER_CFLAGS=\"-fembed-bitcode\" build")
    else
        puts "Not building #{target}"
    end
end

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
  puts("Creating universal framework for #{framework_name}")
  system("lipo -create -output \"#{framework}/#{framework_name}\" \"#{iphonesimulator_libs_directory}/#{framework_name}/#{framework_name}.framework/#{framework_name}\" \"#{iphoneos_libs_directory}/#{framework_name}/#{framework_name}.framework/#{framework_name}\"")
end

#=================== Moving already built frameworks =============
#This is optional, you can comment the below code
puts "Copying already build frameworks to #{universal_directory}"
Dir.glob("./Pods/**/*.framework") do |framework_path|
    FileUtils.cp_r(framework_path, universal_directory)
end
