# makeaip documentation

## About:

`makeaip.rb` is a script designed to build AIP structures from archival source directories. It creates pacakges compliant with the Bagit structure. It maintains file properties while also generating and/or validating checksums and technical metadata sidecar files.

## Usage:
Create AIP: `makeaip.rb -t TARGET-DIRECTORY -o OUTPUT-DIRECTORY`

Display help: `makeaip.rb -h`

## Dependencies:
This script relies on the following dependencies being installed: `bagit` (Java CLI - can be installed via [Linuxbrew](http://linuxbrew.sh/)), `hashdeep`, `exiftool` and `rsync`.


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
