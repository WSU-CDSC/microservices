# checkmeta.rb

__Usage__: `checkmeta.rb [target-directory]`

__Optional flags:__
* `-t`: Allows the explicit targeting of a directory to be scanned for metadata. This directory will be treated as an archival package, rather than a directory of archival packages to be scanned.
* `-x`: Allows a directory to be tagged for ignoring by `checkmeta.rb`. This directory will be removed from the list of discovered packages to be scanned.

## Dependencies:
[hashdeep](http://md5deep.sourceforge.net/start-hashdeep.html), [mediainfo](https://mediaarea.net/en/MediaInfo), [exiftool](https://www.sno.phy.queensu.ca/~phil/exiftool/)

#### Ruby Gems
`mail`

## About:
This script is the core of ongoing monitoring of metadata in current workflows. When run on a target directory, it will treat all folders in the top level of that directory as archival packages and scan their metadata (unless the `-t` flag has been used on the input).

## How Script Works:
This script will take a top level collection directory (such as 'CT - Cassette Tape') and spider through its subdirectories to compare their modification times against a central log file. If it finds a directory that has been modified more recently than either the last stored scan date for that directory, or in the case of no previous scan date, the baseline date set in the script, it will take actions to either confirm or generate metadata.

In its normal mode, the script will treat __ALL__ directories in the first level of the target directory as AIPs that are expected to have metadata, so be careful about target directories if that is not the desired outcome. For more targeted approaches, either use the `-x` flag to specify which sub directories to ignore, or the `-t` flag to run it on particular target directories.

This will consist of the following actions:

* Script checks for the existence of expected metadata. If no metadata is present, it will generate metadata used in WSU preservation workflows.
* If metadata is found, the script will attempt to first verify if the manifest in the metadata reflects the current contents of the directory. If no new or missing files are detected, the script will attempt to verify checksums for the files in the directory. If missing files are detected, the script will add the directory and directory changes to the output warning. If only new files are detected, the script will verify the checksums of existing files, and then if successful, will generate new metadata for the directory. If a checksum mismatch is detected at any point, this will be added to the output warning along with the list of files that failed checksum verification.
* If a directory is found to have been changed in any way, its PREMIS metadata will also be checked for its status regarding cloud upload. If the changed directory has been uploaded to B2, this will also be reflected in the script output.

After the script has run, its output report will be created either in the default location (the user's home directory) or in the location specified in the configuration file. This report will also then be emailed to the address(s) set in the configuration file.
