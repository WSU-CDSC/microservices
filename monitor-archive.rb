#!/usr/bin/env ruby
scriptLocation = File.expand_path(File.dirname(__FILE__))
#log and compare last runtime of script
logLocation = "#{scriptLocation}/.monitor-archive.log"
File.write(logLocation,Time.now)

require 'time'
require 'json'
require "#{scriptLocation}/wsu-functions.rb"

# function for checking current files agains files contained in .md5 file
def CompareContents(changedDirectory)
  puts changedDirectory
  baseName = File.basename(changedDirectory)
  hashDataFile = Dir.glob("#{changedDirectory}/**/#{baseName}.md5")[0]
  allFiles = Dir.glob("#{changedDirectory}/**/*").reject {|f| File.directory?(f)}
  hashData = File.readlines(hashDataFile)
  hashFileList = Array.new
  currentFileList = Array.new
  hashData.each do |hashLine|
    filepath = hashLine.split(',./')[1]
    if ! filepath.nil?
      hashFileList << File.basename(filepath).chomp
    end
  end

  allFiles.each do |file|
    currentFileList << File.basename(file)
  end

  #lazy cleanup
  hashFileList.delete("#{baseName}.md5")
  hashFileList.delete("#{baseName}.json")
  hashFileList.delete('Thumbs.db')
  currentFileList.delete('filename')
  currentFileList.delete('Thumbs.db')
  currentFileList.delete("#{baseName}.json")
  currentFileList.delete("#{baseName}.md5")

  if currentFileList == hashFileList.uniq
    puts "No file discrepencies found"
  else
    puts ""
    puts "NEW FILES"
    puts currentFileList - hashFileList.uniq
    puts "MISSING FILES"
    puts hashFileList.uniq - currentFileList
    puts "----"
  end
end

#Start of script process

watchDir = ARGV[0]
scanDirList = Dir.glob("#{watchDir}/*")
changedDirs = Array.new
changedWithMeta = Array.new

scanDirList.each do |scanDir|
  if lastProcessingTime < File.mtime(scanDir)
    changedDirs << scanDir
  end
end

changedDirs.each do |checkForMetadata|
  directoryContents = Dir.glob("#{checkForMetadata}/**/*")
  directoryContents.each do |metaCheck|
    if File.basename(metaCheck) == 'metadata'
      if File.mtime(metaCheck) < File.mtime(File.dirname(metaCheck))
        changedWithMeta << File.dirname(metaCheck)
      end
    end
  end
end

changedNoMeta = changedDirs - changedWithMeta
red("Directories found that do not contain metadata")
purple("Will generate metadata")
changedNoMeta.each do |needsMeta|
  green("Generating metadata for: #{needsMeta}")
  CleanUpMeta(needsMeta)
end

red("Directories found with innacurate existing metadata")
changedWithMeta.each do |target|
  CompareContents(target)
end