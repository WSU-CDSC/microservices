# aip2b2 documentation

## usage 
`aip2b2.rb [INPUT-AIP]`

## Dependencies:
Backblaze B2 CLI

## About
This script controls the Backblaze B2 [CLI tool](https://www.backblaze.com/b2/docs/quick_command_line.html) to upload a target AIP to Backblaze B2 storage. It is designed to work with the directory of AIPs created with [makeaip.rb](https://github.com/WSU-CDSC/microservices/blob/master/Resources/makeaip.md).

It utilizes the `sync` command of the B2 CLI to ensure that file properties are stored and upload checksums are confirmed.

After uploading the target AIP, it will parse the original AIP creation log, add the upload event and store this log in the top level of the target AIP Bag as well as in the AIP stored on B2.
