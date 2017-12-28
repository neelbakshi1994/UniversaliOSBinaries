# UniversaliOSBinaries

## This repo has two files:

1. `universal_pods` -> This script does two things:
    1. Copies all the `.frameworks` downloaded using cococapods and moves them to a universal build folder
    2. Builds all the targets which cocoapods created and creates `.frameworks` out of them and moves them to a universal folder (you need to specify the configuration in this file, I've kept it as debug for now)
  
2. `embed_frameworks` -> Tries to link all the .frameworks from the Universal build folder into your project. This is a work in progress.

3. `stripping_unwanted_architectures.sh` -> Before you archive, this script needs to be added as an run script phase to your main target, so that it removes the simulator architectures from your fat binaries that you built using `universal_pods`

## Requirements

### Xcodeproj
https://github.com/CocoaPods/Xcodeproj

### FileUtils
https://github.com/ruby/fileutils
