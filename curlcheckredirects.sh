#!/bin/bash
# THIS IS LIKE CHASER, BUT JUST TAKES LIST OF FULL URLS AND PRINTS DESTINATION RESULTS
while read line           
do           
    echo `curl -s -L -I -w '%{url_effective}' "$line" | tail -1`,"$line" | awk -F "," '{print $2","$1}'
done < $1
