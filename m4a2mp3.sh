#!/bin/sh
# m4a2mp3.sh originally by Nikesh Jauhari. 
# Modified to use ffmpeg by lattatude@gmail.com 2015-03-04
# m4a to mp3
bitrate=320k
for i in *.m4a; do
  inname=$i
  outname=`echo "$i"|sed -e 's/.m4a/.mp3/'`
  echo "Creating $outname"
  ffmpeg -v 5 -y -i $inname -acodec libmp3lame -ac 2 -ab $bitrate $outname
done
