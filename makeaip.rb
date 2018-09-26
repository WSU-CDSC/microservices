#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require 'optparse'
require 'digest'
require 'tempfile'


$inputTSV = ''
$inputDIR = ''
$desinationDIR = ''
$access_extensions = Array.new

def dependency_check(dependency)
  if ! system("#{dependency} -h > /dev/null")
    puts "Warning! Dependency:#{dependency} not found. Exiting.".red
    exit
  end
end

ARGV.options do |opts|
  opts.on("-t", "--target=val", String)  { |val| $inputDIR = val }
  opts.on("-o", "--output=val", String)     { |val| $desinationDIR = val }
  opts.on("-a", "--access-extension=val", Array) {|val| $access_extensions << val}
  opts.on("-x","--no-bag") { $nobag = true }
  opts.parse!
end

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end
  def purple
    colorize(95)
  end
end

# Check for dependencies
dependency_check('rsync')
dependency_check('hashdeep')
dependency_check('exiftool')

# Set package variables

$packagename = File.basename($inputDIR)
$packagedir =  "#{$desinationDIR}/#{$packagename}"
$objectdir = "#{$desinationDIR}/#{$packagename}/objects"
$accessdir = "#{$desinationDIR}/#{$packagename}/objects/access"
$metadatadir = "#{$desinationDIR}/#{$packagename}/metadata"
$logdir = "#{$desinationDIR}/#{$packagename}/logs"
$existinghashpass = '0'
EventLogs = Array.new

# Start setting up log output
@premis_structure = Hash.new
@premis_structure['package name'] = $packagename
@premis_structure['package source'] = $inputDIR
@premis_structure['creation time'] = Time.now
@premis_structure['events'] = []

def premisreport(actiontype,outcome)
    @premis_structure['events'] << [{'eventType':actiontype,'eventDetail':$command,'eventDateTime':Time.now,'eventOutcome':outcome}] 
end

def outcomereport(status)
  open("#{$desinationDIR}/OUTCOME_LOG.txt", "a") do |l|
    l.puts ''
    l.puts "Package: #{$packagename}\n"
    if status == 'pass'
      l.puts "No errors detected\n"
    elsif status == 'premis'
      log = JSON.parse(@premis_structure.to_json)
      log['events'].each do |event|
        l.puts event[0]['eventDetail']
        l.puts event[0]['eventOutcome']
        l.puts ''
      end
    elsif status == 'fail'
      l.puts "Errors occured\n"
    end
  end
end
  

#Exit if target not directory
if ! File.directory?($inputDIR) || ! File.directory?($desinationDIR)
  puts "Please confirm inputs are valid directories. Exiting.".red
  exit
end

#Exit if target is in destination
if File.dirname($inputDIR) == File.expand_path($desinationDIR)
  puts "Destination directory must be in a different location from target directory!".red
  exit
end

# Create package structure
if ! File.exists?($packagedir)
  puts "Creating package at #{$packagedir}".green
  Dir.mkdir $packagedir
else
  puts "Directory with package name already exists in ouput directory! Exiting.".red
  exit
end
if ! File.exists?($objectdir)
  Dir.mkdir $objectdir
end
if ! File.exists?($metadatadir)
  Dir.mkdir $metadatadir
end
if ! File.exists?($logdir)
  Dir.mkdir $logdir
end

begin
  # Copy Target directory structure
  $command = 'rsync -rtvPih ' + "'" + "#{$inputDIR}/" + "'" + " " + "'" + $objectdir + "'"
  puts $command
  if system($command)
    puts "Files transferred to target successfully".green
    premisreport('replication','pass')
  else
    puts "Transfer error: Exiting".red
    premisreport('replication','fail')
    exit
  end

  ## OPTIONAL
  ## Move certain files to access directory
  if ! $access_extensions.empty?
    if ! File.exists?($accessdir)
      Dir.mkdir($accessdir)
    end
    $access_extensions.each do |extension|
      puts "Moving files with extenstion: #{extension[0]} to access directory".purple
      access_files = Dir.glob("#{$objectdir}/*.#{extension[0]}")
      access_files.each do |file|
        FileUtils.cp(file,$accessdir)
        FileUtils.rm(file)
      end
    end
  end

  #check for existing metadata and validate
  if File.exist?("#{$objectdir}/metadata")
    FileUtils.cp_r("#{$objectdir}/metadata/.",$metadatadir)
    FileUtils.rm_rf("#{$objectdir}/metadata")
    puts "Existing Metadata detected, moving to metadata directory".purple
    priorhashmanifest = Dir.glob("#{$metadatadir}/*.md5")[0]
    if File.exist? priorhashmanifest
      puts "Verifying completeness of files compared to prior manifest".green
      manifest = File.readlines(priorhashmanifest)
      missingfiles = Array.new
      manifest.each do |line|
        path = line.split(',')[2]
        if ! path.nil?
          filename = File.basename(path).chomp
          if filename != 'filename'
            $command = $objectdir + '/**/' + filename
            filesearch = (Dir.glob($command)[0])
            if ! filesearch.nil?
              if ! File.exist?(filesearch)
                 missingfiles << filesearch
              end
            end
          end
        end
      end
      
      if missingfiles.count > 0
        puts "The following missing files were discovered! Exiting.".red
        puts missingfiles
        premisreport('manifest check','fail')
        exit
      else
        puts "All expected files present".green
        premisreport('manifest check','pass')
      end

      puts "Attempting to validate using existing hash information for Package:#{$packagename}".purple
      sorted_hashes = Tempfile.new
      manifest.uniq.each do |line|
        sorted_hashes << line
      end
      sorted_hashes.rewind
      $command = "hashdeep -k '#{sorted_hashes.path}' -xrle '#{$objectdir}'"
      if system($command)
        puts "WOO! Existing hash manifest validated correctly".green
        premisreport('fixity check','pass')
        $existinghashpass = '1'
      else
        puts "Existing hash manifest did not validate. Will generate new manifest/check transfer integrity".red
        FileUtils.rm(priorhashmanifest)
        premisreport('fixity check','fail')
        $existinghashpass = '2'
      end
    end
  end

  if  $existinghashpass != '1'
    puts "Verifying transfer integrity for package: #{$packagename}".purple
    target_Hashes = Array.new
    $target_list = Dir.glob("#{$inputDIR}/**/*")
    $target_list.each do |target|
      if ! File.directory?(target) && ! File.dirname(target).include?('metadata')
        target_hash = Digest::MD5.file(target).to_s
        target_Hashes << target_hash
      end
    end

    transferred_Hashes = Array.new
    $transferred_list = Dir.glob("#{$objectdir}/**/*")
    $transferred_list.each do |transfer|
      if ! File.directory?(transfer)
        transfer_hash = Digest::MD5.file(transfer).to_s
        transferred_Hashes << transfer_hash
      end
    end
    #compare generated hashes to verify transfer integrity
    hashcomparison = transferred_Hashes - target_Hashes | target_Hashes - transferred_Hashes
    if hashcomparison.empty?
      $command = 'transferred_Hashes - target_Hashes | target_Hashes - transferred_Hashes'
      premisreport('fixity check','pass')
      puts "Files copied successfully".green
      puts "Generating new checksums.".green
      hashmanifest = "#{$metadatadir}/#{$packagename}.md5"
      $command = 'hashdeep -rl -c md5 ' + $objectdir + ' >> ' +  hashmanifest
      if system($command)
          premisreport('message digest calculation','pass')
      end
    else
      puts "Mismatching hashes detected between target directory and transfer directory. Exiting.".red
      premisreport('fixity check','fail')
      exit
    end
  end

  # Check if exiftool metadata exists and generate if needed
  technicalmanifest = "#{$metadatadir}/#{$packagename}.json"
  $command = 'exiftool -json -r ' + $objectdir + ' >> ' +  technicalmanifest
  if Dir.glob("#{$metadatadir}/*.json")[0].nil?
    puts "Generating technical metadata".green
    if system($command)
      premisreport('metadata extraction','pass')
    else
      premisreport('metadata extraction','fail')
    end
  else
    priorhashmanifest = Dir.glob("#{$metadatadir}/*.json")[0]
    if File.exist?(priorhashmanifest)
      if $existinghashpass == '2'
        puts "As original hash manifest was inaccurate, generating new technical metadata".green
        FileUtils.rm(technicalmanifest)
        if system($command)
          premisreport('metadata extraction','pass')
        else
          premisreport('metadata extraction','fail')
        end
      end
    end
  end

  # Generate log
  File.open("#{$logdir}/#{$packagename}.log",'w') {|file| file.write(@premis_structure.to_json)}


  #Bag Package

  if ! $nobag
    puts "Creating bag from package".green
    if system('bagit','baginplace','--verbose',"#{$desinationDIR}/#{$packagename}")
      puts "Bag created successfully".green
    else
      puts "Bag creation failed".red
      exit
    end
  end

  # Commented out as not part of current work flow
  # #TAR Bag
  # puts "Creating TAR from Bag".green
  # Dir.chdir($desinationDIR)
  # if system('tar','--posix','-cvf',"#{$packagedir}.tar",$packagename)
  #   puts "TAR Created successfully: Cleaning up".green
  #   FileUtils.rm_rf($packagename)
  #   system('cowsay',"Package creation finished for:#{$packagename}")
  # else
  #   puts "TAR creation failed. Exiting.".red
  #   exit
  # end
  outcomereport('premis')
rescue
  outcomereport('fail')
end

