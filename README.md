# microservices

This is a repository of scripts/microservices that are being used at WSU Libraries. Usage documentation is provided in links for individual scripts.

## List of Scripts and Microservices
* [extsurvey.rb](Resources/extsurvey.md): A tool for rapidly surveying directories for file types by extension. Can create an output in csv of extension types and counts, a file with complete file paths for a given extension, and a file with complete file paths for all extensions whose total count falls under a certain threshold.

* [vid2watson.sh](Resources/transcription-scripts.md): Converts audio track of input file and runs it through IBM Watson speech to text service (must be edited with valid Watson login information). Creates a folder with raw JSON output as well as roughly parsed content.

* [wastson2vtt.rb](Resources/transcription-scripts.md): Takes the JSON output of `vid2watson.sh` and attempts to parse it into a .vtt subtitle file by using time stamps associated with identified words.

* [wsumetaedit.rb](wsumetaedit/) A command line tool for automatic insertion of broadcast WAV metadata into WAV files using the BWF Meta Edit tool.
