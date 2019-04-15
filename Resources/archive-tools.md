# WSU Archival Monitoring Scripts

## These are the scripts that are used to generate/maintain/validate metadata across WSU Libraries' (on site) Digital Storage. This metadata consists of sidecar files containing both file integrity (fixity) and technical metadata. This metadata consists of a checksum/file manifest created by [Hashdeep](http://md5deep.sourceforge.net/start-hashdeep.html), an [ExifTool](https://www.sno.phy.queensu.ca/~phil/exiftool/) output in JSON, and a MediaInfo output in JSON when A/V files are detected. Scripts are built around the following workflow:

* Generate Metadata for collections using _SCRIPT-GOES-HERE_
* Perform ongoing monitoring of metadata via `monitor-archive.rb`
* After any manual intervention necessitated by results of `monitor-archive.rb` update metadata/modification time logs with `update-modtime.rb`

