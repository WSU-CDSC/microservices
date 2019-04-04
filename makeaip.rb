#!/usr/bin/env ruby

scriptLocation = File.expand_path(File.dirname(__FILE__))
require "#{scriptLocation}/wsu-functions.rb"
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
  opts.on("-a", "--access-extension=val", Array) {|val| $access_extensions << val }
  opts.on("-x","--no-bag") { $nobag = true }
  opts.on("-p","--in-place=val", String) { |val| $inplace = true && $inputDIR = val && $desinationDIR = val }
  opts.parse!
end

# Check for dependencies
dependency_check('rsync')
dependency_check('hashdeep')
dependency_check('exiftool')

# Set package variables

$packagename = File.basename($inputDIR,".*")
if ! $inplace
  $packagedir = "#{$desinationDIR}/#{$packagename}"
else
  $packagedir = $desinationDIR
end
$objectdir = "#{$packagedir}/objects"
$accessdir = "#{$packagedir}/objects/access"
$metadatadir = "#{$packagedir}/metadata"
$logdir = "#{$packagedir}/logs"
$existinghashpass = '0'
EventLogs = Array.new

if File.file?($inputDIR)
  $filetarget = true
end

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
  if $inplace
    dump_location = File.dirname($desinationDIR) + "/OUTCOME_LOG.txt"
  else
    dump_location = $desinationDIR + "/OUTCOME_LOG.txt"
  end
  open(dump_location, "a") do |l|
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
if ! $filetarget && ! $inplace
  if ! File.directory?($inputDIR) || ! File.directory?($desinationDIR)
    red("Please confirm inputs are valid directories. Exiting.)
    exit
  end
end

#Exit if target is in destination
if File.dirname($inputDIR) == File.expand_path($desinationDIR)
  red("Destination directory must be in a different location from target directory!")
  exit
end

# If in place get targets
if $inplace
  @original_files = Dir.glob("#{$packagedir}/**/*")
end

# Create package structure
if ! File.exists?($packagedir)
  green("Creating package at #{$packagedir}")
  Dir.mkdir $packagedir
else
  if ! $inplace
    red("Directory with package name already exists in ouput directory! Exiting.")
    exit
  end
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

# Check for AV contents
AVExtensions = [ '.mp4', '.mkv', '.mpg', '.vob', '.mpeg', '.mp2', '.m2v', '.mp3', '.avi', '.wav' ]
AVExtensions.each do |extensionTest|
  if $filetarget
    if File.extname($inputDIR) == extensionTest
      AVCheck = 'Y'
      break
    end
  else
    if ! Dir.glob("#{$inputDIR}/**/*#{extensionTest}").empty?
      AVCheck = 'Y'
      break
    end
  end
end

begin
  # Copy Target directory structure
  if ! $inplace
    if ! $filetarget
      $command = 'rsync -rtvPih ' + '"' + "#{$inputDIR}/" + '"' + " " + '"' + $objectdir + '"'
    else
      $command = 'rsync -rtvPih ' + '"' + "#{$inputDIR}" + '"' + " " + '"' + $objectdir + '"'
    end
  else
    $command = 'rsync -rtvPih ' + "--exclude objects --exclude logs --exclude metadata " + '"' + "#{$inputDIR}/" + '"' + " " + '"' + "#{$objectdir}/" + '"'
  end


    if system($command)
      green("Files transferred to target successfully")
      premisreport('replication','pass')
    else
      red("Transfer error: Exiting")
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
      puts purple("Moving files with extenstion: #{extension[0]} to access directory")
      access_files = Dir.glob("#{$objectdir}/*.#{extension[0]}")
      access_files.each do |file|
        FileUtils.cp(file,$accessdir)
        FileUtils.rm(file)
      end
    end
  end

  #check for existing metadata and validate
  if File.exist?("#{$objectdir}/metadata") && ! Dir.glob("#{$objectdir}/metadata/*.md5").empty?
    if ! $inplace
      FileUtils.cp_r("#{$objectdir}/metadata/.",$metadatadir)
      FileUtils.rm_rf("#{$objectdir}/metadata")
      purple("Existing Metadata detected, moving to metadata directory")
    end
    priorhashmanifest = Dir.glob("#{$metadatadir}/*.md5")[0]
    if File.exist? priorhashmanifest
      green("Verifying completeness of files compared to prior manifest")
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
        red("The following missing files were discovered! Exiting.")
        puts missingfiles
        premisreport('manifest check','fail')
        exit
      else
        green("All expected files present")
        premisreport('manifest check','pass')
      end

      purple("Attempting to validate using existing hash information for Package:#{$packagename}")
      sorted_hashes = Tempfile.new
      manifest.uniq.each do |line|
        sorted_hashes << line
      end
      sorted_hashes.rewind
      $command = "hashdeep -k '#{sorted_hashes.path}' -xrle '#{$objectdir}'"
      if system($command)
        green("WOO! Existing hash manifest validated correctly")
        premisreport('fixity check','pass')
        $existinghashpass = '1'
      else
        if $inplace
          red("Existing hash manifest did not validate. Exiting.")
          exit
        else
          red("Existing hash manifest did not validate. Will generate new manifest/check transfer integrity")
          FileUtils.rm(priorhashmanifest)
          premisreport('fixity check','fail')
          $existinghashpass = '2'
        end
      end
    end
  end

  if  $existinghashpass != '1'
    purple("Verifying transfer integrity for package: #{$packagename}")
    target_Hashes = Array.new
    if $filetarget
      $target_list = Array.new
      $target_list << $inputDIR
    else
      $target_list = Dir.glob("#{$inputDIR}/**/*")
    end
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
      green("Files copied successfully")
      green("Generating new checksums.")
      hashmanifest = "#{$metadatadir}/#{$packagename}.md5"
      $command = 'hashdeep -rl -c md5 ' + '"' + $objectdir + '"' + ' >> ' +  '"' + hashmanifest + '"'
      if system($command)
        premisreport('message digest calculation','pass')
      else
        premisreport('message digest calculation','fail')
      end
    else
      red("Mismatching hashes detected between target directory and transfer directory. Exiting.")
      puts transferred_Hashes
      puts target_Hashes
      premisreport('fixity check','fail')
      exit
    end
  end

  # Check if technical metadata exists and generate if needed
  exifToolManifest = "#{$metadatadir}/#{$packagename}.json"
  mediaInfoManifest = "#{$metadatadir}/#{$packagename}_mediainfo.json"
  # Clean up old manifests in event of prior fixity fail

  if $existinghashpass == '2'
    if File.exist?(exifToolManifest)
      red("Due to failed hash check, will regenerate exiftool metadata")
      FileUtils.rm(exifToolManifest)
    end
    if File.exist?(mediaInfoManifest)
      red("Due to failed hash check, will regenerate mediainfo metadata")
      FileUtils.rm(mediaInfoManifest)
    end
  end

  if ! File.exist?(exifToolManifest)
    $command = 'exiftool -json -r ' + '"' + $objectdir + '"' + ' >> ' + '"' + exifToolManifest + '"'
    green("Generating exiftool metadata")
    if system($command)
      premisreport('metadata extraction','pass')
    else
      premisreport('metadata extraction','fail')
    end
  end
  if ( ! File.exist?(mediaInfoManifest) && AVCheck == 'Y' )
    green("Generating mediainfo metadata")
    $command = 'mediainfo -f --Output=JSON ' + '"' + $objectdir + '"' + ' >> ' + '"' + mediaInfoManifest + '"'
    if system($command)
      premisreport('metadata extraction','pass')
    else
      premisreport('metadata extraction','fail')
    end
  end

  # Generate log
  File.open("#{$logdir}/#{$packagename}.log",'w') {|file| file.write(@premis_structure.to_json)}

  # Clean up source files if inplace mode
  if $inplace
    purple("Cleaning up source files")
    @original_files.each do |remove_me|
      FileUtils.rm(remove_me)
    end
  end
  
  #Bag Package

  if ! $nobag
    green("Creating bag from package")
    if system('bagit','baginplace','--verbose',$packagedir)
      green"Bag created successfully")
    else
      red("Bag creation failed")
      exit
    end
  end

  # Commented out as not part of current work flow
  # #TAR Bag
  # green("Creating TAR from Bag")
  # Dir.chdir($desinationDIR)
  # if system('tar','--posix','-cvf',"#{$packagedir}.tar",$packagename)
  #   green("TAR Created successfully: Cleaning up")
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

