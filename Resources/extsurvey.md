# extsurvey.rb

## Usage:

extensionsurvey.rb [option] [inputdirectory1] [inputdirectory2] ...

Options:

* -t, --threshold  Records file paths for files whose extension count falls under specified threshold.

Example: `extensionsurvey.rb -t 10 INPUT`


* -e, --extension  Records file paths for all files of specified extension.

Example: `extensionsurvey.rb -e .ogv INPUT`

* -h, --help  Displays basic help

## Function
A tool for rapidly surveying directories for file types by extension. If multiple directories are input it will collate all results into one output.

If run with no options script will output a csv listing all found file types (by extension) and the total count for each extension.

The `-t` or `--threshold` flag will output an additional file containing file paths for all file types whose count falls below the specified threshold.

The `-e` or `--extension` flag will output an additional file containing file paths for every file with the specified extension.


