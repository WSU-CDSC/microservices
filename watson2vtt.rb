#!/usr/bin/ruby
# Parses Watson speech to text output (with timestamps) to a rough .vtt file
require 'json'

ARGV.each do |input|
  outputpath = File.dirname(input)
  outputfile = File.basename(input, ".json")
  source = File.read(input)
  data = JSON.parse(source)
  # Check for errors
  if data["code_descripttion"]
    puts "Watson reported an error for this transcript. Skipping!"
    next
  elsif data["results"].nil?
    puts "No text detected to parse. Skipping!"
    next
  end
    
  File.open("#{outputpath}/#{outputfile}.en.vtt", 'w') do |file|
    file.puts "WEBVTT"
    file.puts ""
    data['results'].each_with_index do |results, index|
      intime = results['alternatives'][0]['timestamps'][0][1].round(2)
      outtime = results['alternatives'][0]['timestamps'][-1][-1].round(2)
      if ! data['results'][index+1].nil?
        next_intime = data['results'][index+1]['alternatives'][0]['timestamps'][0][1].round(2)
      else
        next_intime = outtime
      end

      segment_length = outtime - intime

      # Check length of Watson 'transcript' sections and break up into ~4 second chunks if longer than 4 seconds
      if segment_length >= 4
        # If timestamp for word is more than 4 seconds from previous intime (or equals previous outtime) start new chunk loop
        results['alternatives'][0]['timestamps'].each.with_index do|timestamps, index|
          if timestamps[1] >= intime + 4 || timestamps[1] == results['alternatives'][0]['timestamps'].last[1]
            if ! defined? @segment_position
              @segment_position = 0
            else
              @segment_position = @newsegment_position
            end
            @newsegment_position = index

            # Concatenate text from four second chunks for output
            if timestamps[1] == results['alternatives'][0]['timestamps'].last[1]
              #If last chunk of 'transcript' block reset segment position for next chunk
              segment_text = results['alternatives'][0]['timestamps'][@segment_position..(@newsegment_position)]
              @segment_outtime = timestamps[2].round(2)
              @newsegment_position = 0
            else
              segment_text = results['alternatives'][0]['timestamps'][@segment_position..(@newsegment_position -1)]
              @segment_outtime = timestamps[1].round(2)
            end
            concatinated_text = Array.new
            segment_text.each do |text|
              concatinated_text << text[0]
            end
            #Normalize time from SS.ss to suitable time for .vtt
            intime_normalized = Time.at(intime).utc.strftime("%H:%M:%S.%L")
            #Extend if last chunk is less than two seconds
            if intime - @segment_outtime < 2 && timestamps[1] == results['alternatives'][0]['timestamps'].last[1]
              outtime_normalized = Time.at(next_intime - 0.2 ).utc.strftime("%H:%M:%S.%L")
            else
              outtime_normalized = Time.at(@segment_outtime).utc.strftime("%H:%M:%S.%L")
            end
            file.puts "#{intime_normalized} --> #{outtime_normalized}"
            file.puts concatinated_text.join(' ').gsub "\%HESITATION" , '(PAUSE)'
            file.puts ""
            intime = timestamps[1]
          end
        end
      else
        # If less than four seconds parse the normal way
        #If less than two seconds, extend to just prior to next start point and normalize from SS.ss to suitable time for .vtt
        intime_normalized = Time.at(intime).utc.strftime("%H:%M:%S.%L")
        if segment_length < 2
          outtime_normalized = Time.at(next_intime - 0.2 ).utc.strftime("%H:%M:%S.%L")
        else
          outtime_normalized = Time.at(outtime).utc.strftime("%H:%M:%S.%L")
        end
        file.puts "#{intime_normalized} --> #{outtime_normalized}"
        file.puts results['alternatives'][0]['transcript'].gsub "\%HESITATION" , '(PAUSE)'
        file.puts ""
      end
    end
  end
end
