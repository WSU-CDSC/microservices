# uploadaip.rb documentation

## usage 
`uploadaip.rb -p [PATH-TO-B2-DESTINATION] [INPUT-AIP]`

__Optonal Flags__
`-d`: Dry Run mode. This will perform a simulated upload and not generate any logs.

`-x`: Delete existing b2 data. Normally B2 will store multiple versions of files if a file is synced more than once. This flag allows storing only the version currently being uploaded by flagging previously uploaded versions for deletion.

## Dependencies:
For detailed set up instructions and configuration see the workflow documentation at https://github.com/WSU-CDSC/Documentation/blob/master/Cloud-AIP-Workflow.md#workflow-dependencies

Depends on Backblaze B2 CLI (available with `sudo  pip install b2`)

The B2 CLI app must be installed and configured with the correct account ID and key. These can be found in the B2 Web interface and then configured with the command `b2 authorize-account [<accountIdOrKeyId>] [<applicationKey>]`

B2 CLI instructions are [available from Backblaze](https://www.backblaze.com/b2/docs/quick_command_line.html) 

## About
This script controls the Backblaze B2 [CLI tool](https://www.backblaze.com/b2/docs/quick_command_line.html) to upload a target AIP to Backblaze B2 storage. It is designed to work with the directory of AIPs created with [makeaip.rb](https://github.com/WSU-CDSC/microservices/blob/master/Resources/makeaip.md).

It utilizes the `sync` command of the B2 CLI to ensure that file properties are stored and upload checksums are confirmed.

To use, specify the desired B2 path with the `-p` flag. This will be `b2://`followed by the appropriate bucket and path within bucket. It is __strongly__ recommended to confirm command/paths with a test command using the `-d` flag prior to your actual upload.

After uploading the target AIP, it will parse the original AIP creation log, add the upload event and store this log in the top level of the target AIP Bag as well as in the AIP stored on B2. To aid in verification of script success, it will also modify or create a log dump file in the same manner as `makeaip.rb`.
