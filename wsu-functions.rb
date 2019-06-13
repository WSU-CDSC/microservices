#!/usr/bin/env ruby

require 'time'
require 'json'
require 'tempfile'
require 'digest'
require 'mail'

# Load config
scriptLocation = File.expand_path(File.dirname(__FILE__))
load "#{scriptLocation}/wsu-microservices.config"

# functions for PREMIS logging
def set_up_premis(target)
  targetDir = File.expand_path(target)
  baseName = File.basename(targetDir)
  metadata_dir = "#{targetDir}/metadata"
  premisLog = "#{metadata_dir}/#{baseName}_PREMIS.log"
  unless Dir.exist?(metadata_dir)
    Dir.mkdir(metadata_dir)
  end
  unless File.exist?(premisLog)
    premis_meta = Hash.new
    premis_meta['package name'] = File.basename(target)
    premis_meta['package source'] = File.expand_path(target)
    premis_meta['creation time'] = Time.now
    premis_meta['events'] = []
    File.open(premisLog,'w') {|file| file.write(premis_meta.to_json)}
  end
end

def write_premis_event(target,method_name,action_type,outcome)
  targetDir = File.expand_path(target)
  baseName = File.basename(targetDir)
  metadata_dir = "#{targetDir}/metadata"
  premisLog = "#{metadata_dir}/#{baseName}_PREMIS.log"
  unless File.exist?(premisLog)
    set_up_premis(target)
  end
  premis_structure = JSON.parse(File.read(premisLog))
  premis_structure['events'] << {eventType:action_type,eventDetail:method_name,eventDateTime:Time.now,eventOutcome:outcome}
  File.open(premisLog,'w') {|file| file.write(premis_structure.to_json)}
end

def log_premis_pass(target,method_name)
  hash_creation_methods = ['makeHashdeepMeta']
  tech_meta_creation_methods = ['makeExifMeta','make_av_meta']
  hash_verification_methods = ['check_old_manifest']
  manifest_verification_methods = ['CompareContents']
  transfer_methods = ['uploadaip.rb']
  if hash_creation_methods.include?(method_name)
    action_type = 'message digest creation'
  elsif tech_meta_creation_methods.include?(method_name)
    action_type = 'metadata extraction'
  elsif hash_verification_methods.include?(method_name)
    action_type = 'fixity check'
  elsif manifest_verification_methods.include?(method_name)
    action_type = 'manifest check'
  elsif transfer_methods.include?(method_name)
    action_type = 'transfer'
  end
  write_premis_event(target,method_name,action_type,'pass')
end

def log_premis_fail(target,method_name)
  hash_creation_methods = ['makeHashdeepMeta']
  tech_meta_creation_methods = ['makeExifMeta','make_av_meta']
  hash_verification_methods = ['check_old_manifest']
  manifest_verification_methods = ['CompareContents']
  transfer_methods = ['aip2b2.rb']
  if hash_creation_methods.include?(method_name)
    action_type = 'message digest creation'
  elsif tech_meta_creation_methods.include?(method_name)
    action_type = 'metadata extraction'
  elsif hash_verification_methods.include?(method_name)
    action_type = 'fixity check'
  elsif manifest_verification_methods.include?(method_name)
    action_type = 'manifest check'
  elsif transfer_methods.include?(method_name)
    action_type = 'transfer'
  end
  write_premis_event(target,method_name,action_type,'fail')
end

def check_cloud_status(target)
  targetDir = File.expand_path(target)
  baseName = File.basename(targetDir)
  metadata_dir = "#{targetDir}/metadata"
  premisLog = "#{metadata_dir}/#{baseName}_PREMIS.log"
  cloud_status = 0
  if File.exist?(premisLog)
    premis_data = JSON.parse(File.read(premisLog))
    premis_data['events'].each do |event|
      if event['eventDetail'] == 'aip2b2.rb' 
        cloud_status = 1
      end
    end
  end
  return cloud_status
end

# Function to check if dependencies are installed

def CheckDependencies(dependencyList)
  missingDependencyCount = 0
  dependencyList.each do |dependency|
    unless dependency == 'b2'
      checkCommand = "#{dependency} -h > /dev/null"
    else
      checkCommand = "#{dependency} version > /dev/null"
    end
    unless system(checkCommand)
      puts "Missing dependency: #{dependency}. Please install and try again!"
      missingDependencyCount = missingDependencyCount + 1
    end
  end
  exit if missingDependencyCount > 0
end

# function for checking current files agains files contained in .md5 file
def CompareContents(changedDirectory)
  puts "Checking status of: #{changedDirectory}"
  baseName = File.basename(changedDirectory)
  hashDataFile = "#{changedDirectory}/metadata/#{baseName}.md5"
  allFiles = Dir.glob("#{changedDirectory}/**/*").reject { |line| (File.directory?(line) || line.include?('/metadata')) }
  hashData = File.readlines(hashDataFile).reject { |line| line.include?('/metadata') }
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
  hashFileList.delete_if {|line| line.include?('/metadata')}
  hashFileList.delete('Thumbs.db')
  currentFileList.delete('filename')
  currentFileList.delete('Thumbs.db')

  if currentFileList.sort == hashFileList.uniq.sort
    purple("Will verify hashes for existing files")
    log_premis_pass(changedDirectory,__method__.to_s)
    manifest_status = 'no change'
    fixity_check = check_old_manifest(changedDirectory)
    contents_results = [manifest_status]
    fixity_check.each { |check| contents_results << check }
  else
    newFiles = (currentFileList - hashFileList.uniq)
    missingFiles = (hashFileList.uniq - currentFileList)
    if ! newFiles.empty? && missingFiles.empty?
      manifest_status = 'new files'
      log_premis_fail(changedDirectory,__method__.to_s)
      purple("Will verify hashes for existing files")
      fixity_check = check_old_manifest(changedDirectory)
      contents_results = [manifest_status]
      fixity_check.each { |check| contents_results << check }
    elsif ! missingFiles.empty?
      log_premis_fail(changedDirectory,__method__.to_s)
      manifest_status = 'missing files'
      contents_results = [manifest_status, missingFiles, newFiles]
    end
  end
  return contents_results
end

def check_old_manifest(fileInput)
  old_hash_list = []
  new_hash_list = []
  progress_count = 1
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  hashMeta = "#{targetDir}/metadata/#{baseName}.md5"
  target_list = Dir["#{targetDir}/**/*"].reject { |target| File.directory?(target) }
  target_list.uniq!
  hash_file = File.readlines(hashMeta).reject {|line| line.include?('%%%%') || line.include?('##') || line.include?('Thumbs.db') || line.include?('/metadata/')}
  hash_file.each {|line| old_hash_list << line.split(',')[1]}
  target_list.each {|target_file| new_hash_list << Digest::MD5.file(File.open(target_file)).hexdigest
  printf("\rChecking file %d of #{target_list.count}",progress_count)
  progress_count += 1
  }
  puts ""
  hash_difference = old_hash_list - new_hash_list

  if hash_difference.count == 0
    puts "Fixity infomation valid"
    log_premis_pass(fileInput,__method__.to_s)
    fixity_check = ['pass','']
  else
    log_premis_fail(fileInput,__method__.to_s)
    hash_fail_list = []
    hash_difference.each do |hash|
      hash_fail_list << hash_file.select { |line| line.include?(hash)}
    end
    fixity_check = ['fail', hash_fail_list]
  end
  return fixity_check
end

# Makes metadata directory or deletes current contents of existing metadata directory
def CleanUpMeta(fileInput)
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  exifMeta = "#{targetDir}/metadata/#{baseName}.json"
  hashMeta = "#{targetDir}/metadata/#{baseName}.md5"
  avMeta = "#{targetDir}/metadata/#{baseName}_mediainfo.json"
  makeHashdeepMeta(fileInput)
  makeExifMeta(fileInput)
  make_av_meta(fileInput)
end

# Makes a hashdeep md5 sidecar
def makeHashdeepMeta(fileInput)
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  metadata_dir = "#{targetDir}/metadata"
  hashMeta = "#{metadata_dir}/#{baseName}.md5"
  unless Dir.exist?(metadata_dir)
    Dir.mkdir(metadata_dir)
  end
  Dir.chdir(targetDir)
  hashDeepCommand = "hashdeep -c md5 -r -l ./"
  hashDeepOutput = `#{hashDeepCommand}`
  File.write(hashMeta,hashDeepOutput)
  log_premis_pass(fileInput,__method__.to_s)
end

# makes an exiftool sidecar in JSON
def makeExifMeta(fileInput)
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  metadata_dir = "#{targetDir}/metadata"
  exifMeta = "#{metadata_dir}/#{baseName}.json"
  unless Dir.exist?(metadata_dir)
    Dir.mkdir(metadata_dir)
  end
  Dir.chdir(targetDir)
  exifCommand = "exiftool -r -json ./"
  exifOutput = `#{exifCommand}`
  File.write(exifMeta,exifOutput)
  log_premis_pass(fileInput,__method__.to_s)
end

# makes a mediainfo sidecar in JSON
def make_av_meta(fileInput)
  targetDir = File.expand_path(fileInput)
  baseName = File.basename(targetDir)
  metadata_dir = "#{targetDir}/metadata"
  avMeta = "#{metadata_dir}/#{baseName}_mediainfo.json"
  unless Dir.exist?(metadata_dir)
    Dir.mkdir(metadata_dir)
  end
  av_extensions = [ '.mp4', '.mkv', '.mpg', '.vob', '.mpeg', '.mp2', '.m2v', '.mp3', '.avi', '.wav' ]
  av_files = av_extensions.flat_map { |ext| Dir.glob "#{targetDir}/**/*#{ext}" }
  unless av_files.empty?
    mediainfo_out = []
    av_files.each do |mediainfo_target|
      mediainfo_command = 'mediainfo -f --Output=JSON ' + '"' + mediainfo_target + '"'
      mediainfo_out << JSON.parse(`#{mediainfo_command}`)
    end
    File.write(avMeta,JSON.pretty_generate(mediainfo_out))
    log_premis_pass(fileInput,__method__.to_s)
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
  scriptName = File.basename(__FILE__,".*")
  logName = "#{scriptLocation}/#{scriptName}_time.log"
  if ! File.exist?(logName)
    targetTimes = Hash.new
    targetTimes["Initial Run"] = Time.now
    File.write(logName,targetTimes.to_json)
  end
  loggedTimes = JSON.parse(File.read(logName))
  if loggedTimes[target].nil?
    @priorRunTime = Time.parse('2019-04-11 09:30:16 -0700')
  else
    @priorRunTime = Time.parse(loggedTimes[target])
  end
end

def logTimeWrite(target)
  scriptLocation = File.expand_path(File.dirname(__FILE__))
  scriptName = File.basename(__FILE__,".*")
  logName = "#{scriptLocation}/#{scriptName}_time.log"
  if ! File.exist?(logName)
    targetTimes = Hash.new
    targetTimes["Initial Run"] = Time.now
    File.write(logName,targetTimes.to_json)
  end
  loggedTimes = JSON.parse(File.read(logName))
  loggedTimes[target] = Time.now
  File.write(logName,loggedTimes.to_json)
end

#Function for sending email

def sendMail(logfile,destination)
  destination.each do |address|
    mail = Mail.new do
      from     'wsu-meta-script@wsu.edu'
      to       address
      subject  'Metadata scan report'
      body     "Metadata report from #{Time.now} attached."
      add_file :filename => File.basename(logfile), :content => File.read(logfile)
    end
    mail.deliver!
  end
end

