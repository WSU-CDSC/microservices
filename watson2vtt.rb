#!/usr/bin/ruby
# Parses Watson speech to text output (with timestamps) to a rough .vtt file
require 'json'

ARGV.each do |input|
  outputpath = File.dirname(input)

  source = File.read(input)
  data = JSON.parse(source)
  File.open("#{outputpath}/test.vtt", 'w') do |file|
    file.puts "WEBVTT"
    file.puts ""
    data['results'].each do |result|
      result['alternatives'].each do |alternative|
        intime = Time.at(alternative['timestamps'][0][1]).utc.strftime("%H:%M:%S.%s0")
        text = alternative['transcript']
        outtime = Time.at(alternative['timestamps'][-1][-1]).utc.strftime("%H:%M:%S.%s0")
        file.puts "#{intime} --> #{outtime}"
        file.puts text
        file.puts ""
      end
    end
  end
end
