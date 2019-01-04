#!/bin/bash
target="${1}"
project_name=$(basename "${target}" | cut -d'.' -f1)
source_dir=$(dirname "${target}")
outdir="${source_dir}"/"${project_name}"
audio_track="${project_name}"_audio.ogg
mkdir "${outdir}"

#Extract/Convert audio track to mono ogg/vorbis at 16 kHz
ffmpeg -i "${target}" -map 0:a:0 -ac 2 -ar 16000 -c:a vorbis -strict -2 "${outdir}/${audio_track}"
cd "${outdir}"
for i in *.ogg ; do
    curl -X POST -u "apikey:API-KEY-HERE" \
    --header "Content-Type: audio/ogg" \
    --data-binary  @"${outdir}"/"${i}" \
    "https://gateway-wdc.watsonplatform.net/speech-to-text/api/v1/recognize?profanity_filter=false&timestamps=true&inactivity_timeout=120" >> "${outdir}"/"${project_name}".json
done

#Cleanup
rm "${outdir}"/*.ogg
cat "${outdir}"/"${project_name}".json | grep transcript | cut -d'"' -f4 > "${outdir}"/"${project_name}"_parsed.txt
