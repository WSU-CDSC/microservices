#!/usr/bin/env ruby
scriptLocation = File.expand_path(File.dirname(__FILE__))
require "#{scriptLocation}/wsu-functions.rb"

inputDirs = ARGV.select { |dir| File.directory?(dir) }
inputDirs.each do |targetDir|
  green("Generating metadata and updating log time for #{targetDir}")
  set_up_premis(targetDir)
  CleanUpMeta(targetDir)
  logTimeWrite(targetDir)
end