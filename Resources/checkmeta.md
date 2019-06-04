# checkmeta.rb

## Usage: `checkmeta.rb [target-directory]`

__Optional flags:__
* `-t`: Allows the explicit targeting of a directory to be scanned for metadata. This directory will be treated as an archival package, rather than a directory of archival packages to be scanned.
* `-x`: Allows a directory to be tagged for ignoring by `checkmeta.rb`. This directory will be removed from the list of discovered packages to be scanned.

## Dependencies: hashdeep, mediainfo, exiftool

This script is the core of ongoing monitoring of metadata in current workflows. When run on a target directory, it will treat all folders in the top level of that directory as archival packages and scan their metadata (unless the `-t` flag has been used on the input).
