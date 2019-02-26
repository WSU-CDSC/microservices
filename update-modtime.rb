#!/usr/bin/env ruby
scriptLocation = File.expand_path(File.dirname(__FILE__))
require "#{scriptLocation}/wsu-functions.rb"

inputDirs = ARGV
inputDirs.each do |targetDir|
  green("Updating metadata and log time for #{targetDir}")
  CleanUpMeta(targetDir)
  logTimeWrite(targetDir)
end