# makemeta.rb

### Usage: `makemeta.rb [target-directory]`

__Dependencies:__ hashdeep, mediainfo, exiftool

For detailed set up instructions and configuration see the workflow documentation at https://github.com/WSU-CDSC/Documentation/blob/master/Cloud-AIP-Workflow.md#workflow-dependencies

### About: 
This script will either create, or regenerate the metadata used in WSU preservation workflows.

Generated metadata includes:
* `.md5` file containing file and checksum manifest created by hashdeep.
* `.json` file containing output from exiftool scan of target directory.
* `_mediainfo.json` file (when A/V files are detected). This contains results of mediainfo scan on A/V files in target directory.
* `_PREMIS.log` file that contains a list of [PREMIS](http://id.loc.gov/vocabulary/preservation/eventType.html) actions that have been performed on target directory to date. Events are stored in JSON.

## Sample Structure (with links to example files)
> /home/weaver/Desktop/metadata-test
>
> ├── metadata
>
> │   ├── [metadata-test.json](metadata-test.json)
>
> │   ├── [metadata-test.md5](metadata-test.md5)
>
> │   ├── [metadata-test_mediainfo.json](metadata-test_mediainfo.json)
>
> │   └── [metadata-test_PREMIS.log](metadata-test_PREMIS.log)
>
> ├── sample-audio.mp3
>
> └── sample-text.txt
