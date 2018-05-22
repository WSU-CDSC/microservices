#!/usr/bin/ruby
# Parses Watson speech to text output (with timestamps) to a rough .vtt file
require 'json'

ARGV.each do |input|
  outputpath = File.dirname(input)
  outputfile = File.basename(input, ".json")
  source = File.read(input)
  data = JSON.parse(source)
  File.open("#{outputpath}/#{outputfile}.vtt", 'w') do |file|
    file.puts "WEBVTT"
    file.puts ""
    data['results'].each do |results|
      intime = results['alternatives'][0]['timestamps'][0][1]
      outtime = results['alternatives'][0]['timestamps'][-1][-1]
      segment_length = outtime - intime

      if segment_length >= 7
        results['alternatives'][0]['timestamps'].each.with_index do|timestamps, index|
          if timestamps[1] >= intime + 7 || timestamps[1] == results['alternatives'][0]['timestamps'].last[1]
            if ! defined? @segment_position
              @segment_position = 0
            else
              @segment_position = @newsegment_position
            end
            @newsegment_position = index
            @segment_outtime = (timestamps[2] - 0.5).round(2)

            if timestamps[1] == results['alternatives'][0]['timestamps'].last[1]
              segment_text = results['alternatives'][0]['timestamps'][@segment_position..(@newsegment_position)]
              @newsegment_position = 0
            else
              segment_text = results['alternatives'][0]['timestamps'][@segment_position..(@newsegment_position -1)]
            end
            concatinated_text = Array.new
            segment_text.each do |text|
              concatinated_text << text[0]
            end
            intime_normalized = Time.at(intime).utc.strftime("%H:%M:%S.%s0")
            outtime_normalized = Time.at(@segment_outtime).utc.strftime("%H:%M:%S.%s0")
            file.puts "#{intime_normalized} --> #{outtime_normalized}"
            file.puts concatinated_text.join(' ')
            file.puts ""
            intime = timestamps[1]
          end
        end
      else
        intime_normalized = Time.at(intime).utc.strftime("%H:%M:%S.%s0")
        outtime_normalized = Time.at(outtime).utc.strftime("%H:%M:%S.%s0")
        file.puts "#{intime_normalized} --> #{outtime_normalized}"
        file.puts results['alternatives'][0]['transcript']
        file.puts ""
      end
    end
  end
end
