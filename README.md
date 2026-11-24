# microservices

This is a repository of scripts/microservices that are being used at WSU Libraries. Usage documentation is provided in links for individual scripts.

## List of Scripts and Microservices

* Metadata Creation & Monitoring
  - [checkmeta.rb](Resources/checkmeta.md)
  - [makemeta.rb](Resources/makemeta.md)
  - [wsumetaedit.rb](wsumetaedit/): A command line tool for automatic insertion of broadcast WAV metadata into WAV files using the BWF Meta Edit tool.
  
* Cloud Migration Scripts
  - [makeaip.rb](Resources/makeaip.md): A script for generating archival packages from source directories.
  - [uploadaip.rb](Resources/uploadaip.md): A script that works to upload AIPs generated with `makeaip.rb` to Backblaze B2. Generates a new JSON file incorporating `makeaip.rb` log and Backblaze upload PREMIS event.

* Caption Workflow Scripts
  - [captioning/wsu_caption.py](captioning/): Generates WebVTT captions for local audio/video files or video links (anything yt-dlp supports) using a local Whisper speech-to-text model. No cloud account or API key needed. Replaces the earlier IBM Watson scripts (`caption-crunch.sh`, `vid2watson.rb`, `watson2vtt.rb`).
  
  

* Misc
  - [extsurvey.rb](Resources/extsurvey.md): A tool for rapidly surveying directories for file types by extension. Can create an output in csv of extension types and counts, a file with complete file paths for a given extension, and a file with complete file paths for all extensions whose total count falls under a certain threshold.
  - [make-ead.rb](EAD-Transform/) A tool for generating finding aids via applying WSU's adaption of Archivists' Toolkit's EAD to HTML style sheet.
  - [ocr_test.rb](/Resources/ocr_test.md) A tool for scanning PDFs for OCR text data. Creates a CSV file with results.
