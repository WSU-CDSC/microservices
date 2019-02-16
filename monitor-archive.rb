#!/usr/bin/env ruby
scriptLocation = File.expand_path(File.dirname(__FILE__))

require "#{scriptLocation}/wsu-functions.rb"

#Start of script process

watchDir = ARGV[0]
scanDirList = Dir.glob("#{watchDir}/*")
changedDirs = Array.new
changedWithMeta = Array.new

scanDirList.each do |scanDir|
  logTimeRead(scanDir)
  if (File.mtime(scanDir) - @priorRunTime) > 10
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
  logTimeWrite(needsMeta)
end

red("Directories found with inacurate existing metadata")
changedWithMeta.each do |target|
  CompareContents(target)
end