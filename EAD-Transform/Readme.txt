MAKE-EAD.rb:
This script is for converting EAD XML files into HTML Finding aids using WSU's adaption of the Archivists' Toolkit template. It will target all XMl files in the same directory as the script, creating HTML files with the same names.

To use, simply put all target XML files into the script directory, open a command window (or terminal) change into the script directory using 'cd' and run the script with 'ruby make-ead.rb'.

Alternately, an easy way to run the script is to open a terminal window, type ruby, add a space and then drag the script into the window.

This script requires both Ruby to be installed as well as the Ruby gem Nokogiri. Once Ruby is installed, use the command `gem install nokogiri` to satisfy this dependency.

MAKE-CSV.rb

This script is for extracting information out of an EAD file and creating a CSV. It will attempt to create CSVs for all XML files located in a single target directory.

To use it on a target directory containing EAD files, open a command window (or terminal) and run the script with:
'ruby make-csv.rb [drag directory here]'

This script requires both Ruby to be installed as well as the Ruby gem Nokogiri. Once Ruby is installed, use the command `gem install nokogiri` to satisfy this dependency.
