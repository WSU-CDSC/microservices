#!/usr/bin/ruby
require 'json'
require 'fileutils'

ARGV.each do |inputFile|
  target = File.expand_path(inputFile)
  projectName = File.basename(target,'.*')
  sourceDirectory = File.dirname(target)
  outputDirectory = "#{sourceDirectory}/#{projectName}"
  outputMP3 = "#{outputDirectory}/temp.mp3"
  outputJSON = "#{outputDirectory}/#{projectName}.json"
  if ! File.exist?(outputDirectory)
    Dir.mkdir(outputDirectory)
  end
  command = 'ffmpeg -i ' + '"' + target + '"' + ' -af dynaudnorm -map 0:a:0 -ac 1 -ar 16000 -c:a mp3 ' + '"' + outputMP3 + '"'
  system(command)
  watsonCommand = "curl -X POST -u 'apikey:KEY-GOES-HERE' --header 'Content-Type: audio/mp3' --data-binary  @" + '"' + outputMP3 + '"' + " 'https://gateway-wdc.watsonplatform.net/speech-to-text/api/v1/recognize?profanity_filter=false&timestamps=true&inactivity_timeout=120'"
  puts watsonCommand
  watsonOutput = `#{watsonCommand}`
  File.open(outputJSON, 'w') do |f|
    f.puts watsonOutput
  end
  FileUtils.rm(outputMP3)
  FileUtils.mv(target, outputDirectory)
end