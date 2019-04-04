#!/usr/bin/env ruby

require 'time'
require 'json'
require 'tempfile'
require 'digest'

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

  if currentFileList.sort == hashFileList.uniq.sort
    purple("Will verify hashes for existing files")
    @noChange = 'true'
    check_old_manifest(changedDirectory)
  else
    @newFiles = (currentFileList - hashFileList.uniq)
    @missingFiles = (hashFileList.uniq - currentFileList)
    if ! @newFiles.empty? && @missingFiles.empty?
      red("New Files Found in #{changedDirectory}!")
      purple("Will verify hashes for existing files")
      check_old_manifest(changedDirectory)
      if @fixityCheck == 'pass'
        green("Existing hashes for #{changedDirectory} were valid: Will generate new metadata to reflect new files.")
        CleanUpMeta(changedDirectory)
      elsif
        @fixityCheck == 'fail'
        red("Warning: Invalid hash information detected. Please examine #{changedDirectory} for changes")
      end
    elsif ! @missingFiles.empty?
      red("Warning! Missing files found in #{changedDirectory}!")
        puts 'missing:'
        puts @missingFiles
        puts "-----"
        puts 'new'
        puts @newFiles
    end
  end
end

def check_old_manifest(fileInput)
  old_hash_list = []
  new_hash_list = []
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  hashMeta = "#{targetDir}/metadata/#{baseName}.md5"
  target_list = Dir["#{targetDir}/**/*"].reject { |target| File.directory?(target) }
  target_list.uniq!
  hash_file = File.readlines(hashMeta).reject {|line| line.include?('%%%%') || line.include?('##') || line.include?('Thumbs.db') || line.include?('/metadata/')}
  hash_file.each {|line| old_hash_list << line.split(',')[1]}
  target_list.each {|target_file| new_hash_list << Digest::MD5.file(File.open(target_file)).hexdigest}
  hash_difference = old_hash_list - new_hash_list

  if hash_difference.count == 0
    puts "Fixity infomation valid"
    @fixityCheck = 'pass'
  else
    red("Bad fixity information or missing files present!")
    @fixityCheck = 'fail'
    hash_fail_list = []
    hash_difference.each do |hash|
      hash_fail_list << hash_file.select { |line| line.include?(hash)}
    end
    puts hash_fail_list
  end
end

# Makes metadata directory or deletes current contents of existing metadata directory
def CleanUpMeta(fileInput)
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  exifMeta = "#{targetDir}/metadata/#{baseName}.json"
  hashMeta = "#{targetDir}/metadata/#{baseName}.md5"
  avMeta = "#{targetDir}/metadata/#{baseName}_mediainfo.json"
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
    if File.exist?(avMeta)
      File.delete(avMeta)
    end
  end
  makeHashdeepMeta(fileInput)
  makeExifMeta(fileInput)
  make_av_meta(fileInput)
end

# Find fixity failed files
def checkHashFail(fileInput)
  sorted_hashes = Tempfile.new
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  hashMeta = "#{targetDir}/metadata/#{baseName}.md5"
  manifest = File.readlines(hashMeta)
  @fixityCheck = ''
  failedHashes = Array.new
  manifest.uniq.each do |line|
    if ! line.include? ('Thumbs.db')
      sorted_hashes << line
    end
  end
  sorted_hashes.rewind
  sorted_hashesArray = File.readlines(sorted_hashes)
  command = "hashdeep -k '#{sorted_hashes.path}' -xrle '#{fileInput}'"
  changedOrNew = `#{command}`
  changedOrNew.split("\n").each do |problemFile|
    sorted_hashesArray.each do |meh|
      if meh.include?(File.basename(problemFile))
        failedHashes << problemFile
      end
    end
  end
  if ! failedHashes.empty?
    puts "FOUND!"
    puts failedHashes
  else
    puts "Array was empty!"
  end
  puts
  changedOrNew
end

# Makes a hashdeep md5 sidecar
def makeHashdeepMeta(fileInput)
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  hashMeta = "#{targetDir}/metadata/#{baseName}.md5"
  unless Dir.exist?("#{targetDir}/metadata")
    Dir.mkdir("#{targetDir}/metadata")
  end
  unless File.exist?(hashMeta)
    Dir.chdir(targetDir)
    hashDeepCommand = "hashdeep -c md5 -r -l ./"
    hashDeepOutput = `#{hashDeepCommand}`
    File.write(hashMeta,hashDeepOutput)
  else
    puts "Hashdeep metadata already exists!"
  end
end

# makes an exiftool sidecar in JSON
def makeExifMeta(fileInput)
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  exifMeta = "#{targetDir}/metadata/#{baseName}.json"
  unless Dir.exist?("#{targetDir}/metadata")
    Dir.mkdir("#{targetDir}/metadata")
  end
  unless File.exist?(exifMeta)
    Dir.chdir(targetDir)
    exifCommand = "exiftool -r -json ./"
    exifOutput = `#{exifCommand}`
    File.write(exifMeta,exifOutput)
  else
    puts "Exiftool metadata already exists!"
  end
end

# makes a mediainfo sidecar in JSON
def make_av_meta(fileInput)
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  avMeta = "#{targetDir}/metadata/#{baseName}_mediainfo.json"
  unless Dir.exist?("#{targetDir}/metadata")
    Dir.mkdir("#{targetDir}/metadata")
  end
  unless File.exist?(avMeta)
    av_extensions = [ '.mp4', '.mkv', '.mpg', '.vob', '.mpeg', '.mp2', '.m2v', '.mp3', '.avi', '.wav' ]
    av_files = av_extensions.flat_map { |ext| Dir.glob "#{targetDir}/**/*#{ext}" }
    unless av_files.empty?
      mediainfo_out = []
      av_files.each do |mediainfo_target|
        mediainfo_command = 'mediainfo -f --Output=JSON ' + '"' + mediainfo_target + '"'
        mediainfo_out << JSON.parse(`#{mediainfo_command}`)
      end
      File.write(avMeta,JSON.pretty_generate(mediainfo_out))
    end
  else
    puts "AV metadata already exists!"
  end
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

