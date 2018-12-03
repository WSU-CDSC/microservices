ABOUT:

This script is for converting EAD XML files into HTML Finding aids using WSU's adaption of the Archivists' Toolkit template. It will target all XMl files in the same directory as the script, creating HTML files with the same names.

INSTALLATION:

This script requires both Ruby to be installed as well as the Ruby gem Nokogiri. On Windows computers, Ruby can be installed by using the tool 'Ruby Installer' (available at https://rubyinstaller.org/). Simply download and open Ruby Installer and follow all command prompts. When this is done, you can test if ruby was installed correctly by opening a terminal window and typing `irb` (without the back-ticks). This will open ruby in that window - if your command prompt changes to a different form of terminal, ruby is installed. If this command throws an error then something went wrong in the process.

Once Ruby is installed, Nokogiri must be installed to support XML parsing within the script. To install Nokogiri, open a terminal window and use the command `gem install nokogiri` to satisfy this dependency.

USAGE:

To use, simply put all target XML files into the script directory, open a command window (or terminal) change into the script directory using 'cd' and run the script with 'ruby make-ead.rb'.

Alternately, an easy way to run the script is to open a terminal window, type ruby, add a space and then drag the script into the window.
