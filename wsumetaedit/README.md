# wsumetaedit.rb

## Usage:

`wsumetaedit.rb [inputfile1] [inputfile2] ...`

Options:

* `-e`, `--edit` Opens configuration file in text editor.

Example: `wsumetaedit -e`

* `-h`, `--help` Displays basic help

Helpful links for related documentation at [pugetsoundandvision](https://github.com/pugetsoundandvision/). **Note**: These examples are for the related tool `uwmetaedit` so they include some minor differences with `wsumetaedit.rb`, but are largely applicable.

**For configuration instructions and metadata examples see [the examples section](https://github.com/pugetsoundandvision/audiotools/blob/master/supplemental/bwfmetadataexamples.md).**

For guidlines on metadata for broadcast WAV files, see the [FADGI guidelines](http://www.digitizationguidelines.gov/audio-visual/documents/Embed_Guideline_20120423.pdf)

## Function

A command line tool for automatic insertion of broadcast WAV metadata into WAV files using the BWF Meta Edit tool. To use, first customize your configuration file (by running wsumetaedit.rb -e or opening with a text editor) with values to be written in the broadcast WAV file.  Other values such as time of creation and a checksum for the audio stream will be embedded automatically.
