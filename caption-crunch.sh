#!/bin/bash
# A lazy script for combining Gnu Parallel with the WSU Transcription scripts
# Input needs to be a file containing a list of download links

targetList="${1}"
script_dir=$(dirname "$0")
outputDir="$(dirname "${targetList}")"
cd "${outputDir}"
echo "Downloading Targets: Please wait!"
cat "${targetList}" | parallel youtube-dl {}
echo "Sending files to Watson: Please wait!"
find . -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.m4a" | parallel ruby "${script_dir}/vid2watson.rb" "{}"
if ! [ -d JSON ] ; then
    mkdir JSON
fi
if ! [ -d VTT ] ; then
    mkdir VTT
fi
echo "Generating VTT and moving outputs: Please wait!"
find . -iname "*.json" | while read JSON ; do
    ruby "${script_dir}/vid2watson.rb" "${JSON}"
    cp "${JSON}" JSON
done

find . -iname "*.vtt" | while read VTT ; do
    cp "${VTT}" VTT
done

echo "All done!!"
