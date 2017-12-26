# UniversaliOSBinaries

## This repo has two files:

1. `universal_pods` -> This script does two things:
  1. Copies all the `.frameworks` downloaded but cococapods and moves them to a universal build folder
  2. Builds all the targets which cocoapods created and creates `.frameworks` out of them and moves them to a universal folder (you need to specify the configuration in this file, I've kept it as debug for now)
  
2. `embed_frameworks` -> Tries to link all the .frameworks from the Universal build folder into your project. This is a work in progress.

## Requirements

### Xcodeproj
https://github.com/CocoaPods/Xcodeproj

### FileUtils
https://github.com/ruby/fileutils
