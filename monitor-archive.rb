#!/usr/bin/env ruby

require 'time'
require 'json'

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
# Last Time this script was run
lastProcessingTime = Time.parse('2018-07-19 16:29:18 -0700')

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
puts "FOUND WITH NO METADATA"
puts changedNoMeta

puts "CHANGED WITH METADATA"
changedWithMeta.each do |target|
  CompareContents(target)
end