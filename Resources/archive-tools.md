# WSU Digital Archives Workflow and Scripts

These are the scripts that are used to generate/maintain/validate metadata across WSU Libraries' (on site) Digital Storage. This metadata consists of sidecar files containing preservation, file integrity (fixity) and technical metadata. This metadata consists of a checksum/file manifest created by [Hashdeep](http://md5deep.sourceforge.net/start-hashdeep.html), an [ExifTool](https://www.sno.phy.queensu.ca/~phil/exiftool/) output in JSON, and a [MediaInfo](https://mediaarea.net/en/MediaInfo) output in JSON when A/V files are detected. Additionally, preservation actions such as metadata generation/verification and cloud migration are logged in a JSON file and mapped to [PREMIS vocabulary](http://id.loc.gov/vocabulary/preservation/eventType.html). 

Core scripts include:
* [makemeta.rb](./makemeta.md)
* [uploadaip.rb](./uploadaip.md)
* checkmeta.rb

Script based workflow is:
* Generate Metadata for collections using `makemeta.rb`
* Upload collections to Backblaze B2 Storage using `uploadaip.rb`
* Perform ongoing monitoring of metadata via `checkmeta.rb`
* After any manual intervention necessitated by results of `checkmeta.rb` update metadata/modification time logs with `makemeta.rb` and (as necessary) resync to cloud with `uploadaip.rb`.

