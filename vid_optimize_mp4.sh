#!/bin/bash
# vid_optimize_mp4.sh
# v0.1 - CLATTA - 2016-09-20
# v0.2 CLATTA - 2017-07-23 - carry over last modified timestamp
# COMPRESS MP4 VIDEO file
# REQUIRES: ffmpeg
# If no perams then show usage
if [ -z "$1" ]
    then
    echo "Usage:";
		echo "vid_optimize_mp4.sh video1.mp4 video2.mp4 [etc]";
		exit 1;
fi
# input video file
input=${@};
# for each file
for file in ${input}
do
  file_last_access=$(stat --format=%y ${file} | awk -F "." '{print $1}');
  fileNoExt=${file%.*};
  filename="${fileNoExt}-c${RANDOM}.mp4";
  echo "New file ${filename} with modified timestamp of ${file_last_access}";
  ffmpeg -i ${file} -qscale 0 -acodec copy "${filename}";
  touch -d "${file_last_access}" ${filename};
done
echo "Done processing file(s) ${input}";
