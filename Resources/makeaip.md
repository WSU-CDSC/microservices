# makeaip documentation

## About:

`makeaip.rb` is a script designed to build AIP structures from archival source directories. It creates pacakges compliant with the Bagit standard. It maintains file properties while also generating and/or validating checksums and technical metadata sidecar files.

## Usage:
Create AIP: `makeaip.rb -t TARGET-DIRECTORY -o OUTPUT-DIRECTORY`

_Optional Flags:_ 

* `-a [file extenstion]` This allows the specification of files (by extenstion) to be deemed 'access' files and moved to an access directory within the AIP. All file types of this extenstion(s) will be moved.

* `-x` Do not bag outputs - this is useful if you will perform any manual tweaks to AIPs before bagging.

Display help: `makeaip.rb -h`

`makeaip.rb` will copy the contents of the target directory (set with the `-t` flag) into the output directory (set with the `-o` flag where it will then restructure them into an AIP compliant with the Bagit specification. Optionally, it can be set to separate Access files into a sub-directory in the AIP via file extension. This can be set using the `-a` flag along with the desired file extension. For example `-a pdf` or `-a mp3 -a m4a`.

## Dependencies:
This script relies on the following dependencies being installed: `bagit` (Java CLI - can be installed via [Linuxbrew](http://linuxbrew.sh/)), `hashdeep`, `exiftool` and `rsync`.

## Actions in AIP creation

* Files from `TARGET-DIRECTORY` are copied using `rsync` to the `OUTPUT-DIRECTORY`. The settings used in `rsync` preserve file characteristics such as creation/modification time. Rsync also contains a level of checksum verification during (but not after) transfer. Files are placed in an `Objects` directory within the AIP in progress. On completion of transfer PREMIS log is updated.
* The new `Objects` directory is checked for existing metadata sidecar files (specifically a hashdeep manifest and an exiftool .json output). If discovered these files are moved to a `Metadata` directory within the AIP in progress.
* If existing checksum metadata is discovered:
  - Files in AIP are checked against list of files in hashdeep manifest to verify all expected files are present. (If files are not present script will exit).
  - Checksums for files in AIP are checked against hashdeep manifest to verify file integrity. If checksums validate, script will update PREMIS log and move on to next step. If checksums do not validate, script will update PREMIS log with a failure. It then will generate and compare checksums of target and source files to test if file change occured during transfer. If this check fails, script will report and exit. If this check passes, new hashdeep and exiftool outputs will be generated.
  
  __If an initial failure is logged, care should be taken to investigate if this was caused by an intentional or unintentional file change.__
  
 * If existing checksum metadata is not discovered:
   - Checksums will be generated for source material and transferred material. These are compared to validate post-transfer file integrity. If this is successful, PREMIS log is updated and a `hashdeep` manifest is generated. If unsuccessful, the script will exit.
 * If existing `exiftool`metadata is not detected it will be generated and the PREMIS log updated to reflect this.
 * PREMIS log is finalized in the `Logs` directory within the AIP in progress.
 * AIP contents are turned into a `Bag` according to the LoC's Baggit Standard. (Unless the `-x` flag is selected).
 * Human readable log is written (or appended to) in the target directory listing pass/fail of events and script.

## AIP Structure

<pre><code>├── bag-info.txt [Contains information about the Bag, such as size and date of creation]
├── bagit.txt [This contains information about the version of the Bagit Standard bag was created in] 
├── manifest-md5.txt [Manifest of all files contained in Bag 'data' directory. Includes relative paths and checksums.]
├── tagmanifest-md5.txt [Manifest and checksums of top level manifest files in Bag.]
└──data [Directory that houses Bag contents. (Part of Bagit Standard)]
   ├── logs [Houses log of AIP creation]
   │   └── MY_PACKAGE.log [Contains PREMIS event log for AIP creation in JSON]
   ├── metadata [Houses metadata associated with Bag contents]
   │   ├── MY_PACKAGE.json [JSON file containing exiftool output for Bag contents]
   │   └── MY_PACKAGE.md5 [File containing md5 checksums for Bag contents]
   └── objects [Houses Bag items]
       ├── access [Houses items that were set by filetype during AIP creation to be identified as access files]
       │   ├── MY_ITEM.pdf [Example access file (assuming makeaip was set to assume pdfs as access files)]
       └── MY_ITEM [Target directory used in the makeaip process]
           ├── MY_ITEM_Page01.tif [Example contents of target directory]
           └──  MY_ITEM_Page02.tif [Example contents of target directory]</pre></code>
