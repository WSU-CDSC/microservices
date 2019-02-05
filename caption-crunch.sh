#!/bin/bash
# A lazy script for combining Gnu Parallel with the WSU Transcription scripts

targetList="${1}"
outputDir="$(dirname "${targetList}")"
cd "${outputDir}"
echo "Downloading Targets: Please wait!"
cat targets.txt | parallel youtube-dl {}
echo "Sending files to Watson: Please wait!"
find . -iname "*.mp4" | parallel vid2watson.rb {}
if ! [ -d JSON ] ; then
    mkdir JSON
fi
if ! [ -d VTT ] ; then
    mkdir VTT
fi
echo "Moving generating VTT and moving outputs: Please wait!"
find . -iname "*.json" | while read JSON ; do
    watson2vtt.rb "${JSON}"
    cp "${JSON}" JSON
done

find . -iname "*.vtt" | while read VTT ; do
    cp "${VTT}" VTT
done

echo "All done!!"
