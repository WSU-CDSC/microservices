#!/bin/bash
target="${1}"
project_name=$(basename "${target}" | cut -d'.' -f1)
source_dir=$(dirname "${target}")
outdir="${source_dir}"/"${project_name}"
audio_track="${project_name}"_audio.flac
mkdir "${outdir}"
cd "${outdir}"

#Extract/Convert audio track to mono FLAC at 16 kHz
ffmpeg -i "${target}" -map 0:a:0 -ac 1 -ar 16000 "${audio_track}"
for i in *.flac ; do
    curl -X POST -u USERNAME:PASSWORD \
    --header "Content-Type: audio/flac" \
    --data-binary  @"${outdir}"/"${i}" \
    "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?profanity_filter=false&timestamps=true" >> "${outdir}"/"${project_name}".json
done

#Cleanup
rm "${outdir}"/*.flac
cat "${outdir}"/"${project_name}".json | grep transcript | cut -d'"' -f4 > "${outdir}"/"${project_name}"_parsed.txt