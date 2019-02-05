#!/usr/bin/ruby
require 'json'
require 'fileutils'

ARGV.each do |inputFile|
  target = File.expand_path(inputFile)
  projectName = File.basename(target,'.*')
  sourceDirectory = File.dirname(target)
  outputDirectory = "#{sourceDirectory}/#{projectName}"
  outputOgg = "#{outputDirectory}/temp.ogg"
  outputJSON = "#{outputDirectory}/#{projectName}.json"
  Dir.mkdir(outputDirectory)
  command = 'ffmpeg -i ' + '"' + target + '"' + ' -map 0:a:0 -ac 2 -ar 16000 -c:a vorbis -strict -2 ' + '"' + outputOgg + '"'
  system(command)
  watsonCommand = "curl -X POST -u 'apikey:KEY-GOES-HERE' --header 'Content-Type: audio/ogg' --data-binary  @" + '"' + outputOgg + '"' + " 'https://gateway-wdc.watsonplatform.net/speech-to-text/api/v1/recognize?profanity_filter=false&timestamps=true&inactivity_timeout=120'"
  puts watsonCommand
  watsonOutput = JSON.parse(`#{watsonCommand}`)
  File.open(outputJSON, 'w') do |f|
    f.puts watsonOutput.to_json
  end
  FileUtils.rm(outputOgg)
  FileUtils.mv(target, outputDirectory)
end