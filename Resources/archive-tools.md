# WSU Digital Archives Workflow and Scripts

These are the scripts that are used to generate/maintain/validate metadata across WSU Libraries' (on site) Digital Storage. This metadata consists of sidecar files containing preservation, file integrity (fixity) and technical metadata. This metadata consists of a checksum/file manifest created by [Hashdeep](http://md5deep.sourceforge.net/start-hashdeep.html), an [ExifTool](https://www.sno.phy.queensu.ca/~phil/exiftool/) output in JSON, and a [MediaInfo](https://mediaarea.net/en/MediaInfo) output in JSON when A/V files are detected. Additionally, preservation actions such as metadata generation/verification and cloud migration are logged in a JSON file and mapped to [PREMIS vocabulary](http://id.loc.gov/vocabulary/preservation/eventType.html). 

Core scripts include:
* makemetadata.rb
* [aip2b2.rb](https://github.com/WSU-CDSC/microservices/blob/master/Resources/aip2b2.md)
* monitor-archive.rb

Script based workflow is:
* Generate Metadata for collections using `makemetadata.rb`
* Upload collections to Backblaze B2 Storage using `aip2cloud.rb`
* Perform ongoing monitoring of metadata via `monitor-archive.rb`
* After any manual intervention necessitated by results of `monitor-archive.rb` update metadata/modification time logs with `makemetadata.rb` and (as necessary) resync to cloud with `aip2cloud.rb`.

