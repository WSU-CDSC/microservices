#!/usr/bin/env ruby

# Makes metadata directory or deletes current contents of existing metadata directory
def CleanUpMeta(fileInput)
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  exifMeta = "#{targetDir}/metadata/#{baseName}.json"
  hashMeta = "#{targetDir}/metadata/#{baseName}.md5"
  hashDeepCommand = "hashdeep -c md5 -r -l ./"
  Dir.chdir(targetDir)

  if ! Dir.exist?('metadata')
    Dir.mkdir("#{targetDir}/metadata")
  else
    if File.exist?(exifMeta)
      File.delete(exifMeta)
    end
    if File.exist?(hashMeta)
      File.delete(hashMeta)
    end
  end
  makeHashdeepMeta(targetDir,hashMeta)
  makeExifMeta(targetDir,exifMeta)
end

# Makes a hashdeep md5 sidecar
def makeHashdeepMeta(targetDir,hashMeta)
  Dir.chdir(targetDir)
  hashDeepCommand = "hashdeep -c md5 -r -l ./"
  hashDeepOutput = `#{hashDeepCommand}`
  File.write(hashMeta,"'" + hashDeepOutput + "'")
end

# makes an exiftool sidecar in JSON
def makeExifMeta(targetDir,exifMeta)
  Dir.chdir(targetDir)
  exifCommand = "exiftool -r -json ./"
  exifOutput = `#{exifCommand}`
  File.write(exifMeta,"'" + exifOutput + "'")
end

# Functions for colored text output
  # colorization

def purple(input)
  puts "\e[95m#{input}\e[0m"
end

def green(input)
  puts "\e[32m#{input}\e[0m"
end

def red(input)
  puts "\e[31m#{input}\e[0m"
end

# Logs time of script being run on target in JSON file
def logTimeRead(target)
  scriptLocation = File.expand_path(File.dirname(__FILE__))
  scriptName = File.basename(__FILE__)
  logName = "#{scriptLocation}/.#{scriptName}_time.log"
  if ! File.exists?(logName)
    targetTimes = Hash.new
    targetTimes["Initial Run"] = Time.now
    File.write(logName,targetTimes.to_json)
  end
  loggedTimes = JSON.parse(File.read(logName))
  if loggedTimes[target].nil?
    @priorRunTime = Time.parse('2018-06-25 09:30:16 -0700')
  else
    @priorRunTime = Time.parse(loggedTimes[target])
  end
end

def logTimeWrite(target)
  scriptLocation = File.expand_path(File.dirname(__FILE__))
  scriptName = File.basename(__FILE__)
  logName = "#{scriptLocation}/.#{scriptName}_time.log"
  if ! File.exists?(logName)
    targetTimes = Hash.new
    targetTimes["Initial Run"] = Time.now
    File.write(logName,targetTimes.to_json)
  end
  loggedTimes = JSON.parse(File.read(logName))
  loggedTimes[target] = Time.now
  File.write(logName,loggedTimes.to_json)
end