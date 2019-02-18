#!/usr/bin/env ruby
require 'time'
require 'json'
require 'tempfile'

# function for checking current files agains files contained in .md5 file
def CompareContents(changedDirectory)
  puts "Changed directory found: #{changedDirectory}"
  baseName = File.basename(changedDirectory)
  hashDataFile = "#{changedDirectory}/metadata/#{baseName}.md5"
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
    @newFiles = (currentFileList - hashFileList.uniq)
    if ! @newFiles.empty? && @missingFiles.nil?
      red("New Files Found in #{changedDirectory}!")
      purple("Will verify hashes for existing files")
      verifyExistingHashManifest(changedDirectory)
      if @fixityCheck == 'pass'
        green("Existing hashes for #{changedDirectory} were valid: Will generate new metadata to reflect new files.")
        CleanUpMeta(changedDirectory)
      elsif
        @fixityCheck == 'fail'
        red("Warning: Invalid hash information detected. Please examine #{changedDirectory} for changes")
      end
    end
    @missingFiles = (hashFileList.uniq - currentFileList)
    if ! @missingFiles.empty?
      red("Warning! Missing files found in #{changedDirectory}!")
    end
  end
end

def verifyExistingHashManifest(fileInput)
  sorted_hashes = Tempfile.new
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  hashMeta = "#{targetDir}/metadata/#{baseName}.md5"
  manifest = File.readlines(hashMeta)
  manifest.uniq.each do |line|
    sorted_hashes << line
  end
  sorted_hashes.rewind
  command = "hashdeep -k '#{sorted_hashes.path}' -xrle '#{fileInput}'"
  if system(command)
    puts "Fixity infomation valid"
    @fixityCheck = 'pass'
  else
    puts "Bad fixity information present!"
    @fixityCheck = 'fail'
  end
end

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
  File.write(hashMeta,hashDeepOutput)
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

