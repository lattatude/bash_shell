#!/bin/bash
# PURPOSE: Input file list of target urls and destinations, outputs csv report to show 
#  if each target matches destination. Requries CURL
#d USAGE: curlcheckredirects.sh urllist.csv FULL|" "
# CLATTA 2013-12-01 v1.0
# CLATTA 2015-05-22 v2.0 total overhaul
# CLATTA 2016-10-10 v2.1 added urlEncodeSpaces function and applied to input URLs
#							and check for https urls curing input check
# CLATTA 2017-01-20 v3.0 added checkLinksFull type of report that prints a more
#							more verbose output with every redirect
# CLATTA 2017-01-27 v3.11 bug fix on checkLinksFull() function, output format order change
# CLATTA 2017-01-27 v3.2 added countRepCode and countDiffSame functions and report/summary
#
#
# FUNCTION: checkFormat $1
# Checks a line to try to determin if it has valid URL text
function checkForHTTPstr()
{
	echo $1 | grep -v 'http://\|https://';
}
# FUNCTION: isSame $1 $2
# Checks if two strings are the same
function isSame()
{
	if [ -n "${2}" ]
	then
		if [[ "${1}" == "${2}" ]]
		then
			echo "SAME";
		else
			echo "DIFF";
		fi	
	fi
}
# FUNCTION: urlEncodeSpaces $1
# Accepts URL string and outputs URL string with spaces url encoded
function urlEncodeSpaces()
{
	#REMOVE SPACE FROM BEGINNING AND END OF STRING
	str=$(echo "${@}" | awk '{$1=$1};1');
	#CONVERT REMAINING INTERIOR SPACES TO $20 AND PRINT
	echo "$str" | sed 's/ /%20/g';
}
# FUNCTION: checkInput $1
# Accepts CSV data input and checks for common issues in data
function checkInput()
{
	local COUNT=1;
	#EXECUTE TEST OF INPUT DATA
	while read line
	do
		#GET THE TWO URLS
		local URL1=$(urlEncodeSpaces $(echo "$line" | cut -f1 -d,));
		local URL2=$(urlEncodeSpaces $(echo "$line" | cut -f2 -d,));
		#REMOVE WHITESPACE AND URLENCODE INTERIOR SPACES
		
		
		#CHECK IF THE TARGET IS SAME AS DESTINATION
		#COULD BE THAT IT IS JUST MISSING A DESTINATION URL
		local ISSAME=`isSame "${URL1}" "${URL2}"`;
		if [[ $ISSAME == "SAME" ]]
		then
			echo "Line $COUNT is either missing the destination URL or it is the same as the target";
		fi
		#CHECK IF FIRST URL HAS HTTP/S
		local URL1_HTTP_CHK=`checkForHTTPstr "${URL1}"`;
		if [ -n "$URL1_HTTP_CHK" ]; then
			echo "Line $COUNT does not have 'http://' in the target URL";
		fi
		#CHECK IF SECOND URL HAS HTTP/S
		local URL2_HTTP_CHK=`checkForHTTPstr "${URL2}"`;
		if [ -n "$URL2_HTTP_CHK" ]; then
			echo "Line $COUNT does not have 'http(s)://' in the destination URL";
		fi
		COUNT=$((COUNT+1));
	done < ${LISTDATA}
}
# FUNCTION: countRepCode
function countRepCode()
{
	repcode=${1};
	if [[ ${repcode} ]]
	then
		#INCREMENT ASSOCIATIVE ARRAY
		repCodeCnt[${repcode}]=$((repCodeCnt[${repcode}]+1));
	else
		#PRINT THE REPORT
		for rCodeVal in "${!repCodeCnt[@]}"
		do
			echo "${rCodeVal} ${repCodeCnt[$rCodeVal]}";
		done
	fi
}
# FUNCTION: countDiffSame
# SHOULD DECLARE ASSOCIATIVE ARRAY BEFORE EXECUTING: declare -A diffSameCnt
function countDiffSame()
{
	diffSame=${1};
	if [[ ${diffSame} ]]
	then
		#INCREMENT ASSOCIATIVE ARRAY
		diffSameCnt["${diffSame}"]=$((diffSameCnt["${diffSame}"]+1));
	else
		#PRINT THE REPORT
		for dSameVal in "${!diffSameCnt[@]}"
		do
			echo "${dSameVal} ${diffSameCnt[$dSameVal]}";
		done
	fi
}
# FUNCTION: checkLinksSum $1
# Accepts CSV data input and performs a link check, outputs CSV report
function checkLinksSum()
{
	while read line || [[ -n "$line" ]]
	do          
		#STRIP WHITESPACE FROM LINE
		line=$(echo ${line} | awk '{$1=$1};1');
		#CHECK IF DATA EXISTS IN LINE
		[[ -z "${line}" ]] && continue 1;
		#DEFINE TARGET URL
		local URL1=$(urlEncodeSpaces $(echo "${line}" | cut -f1 -d,));
		#DEFINE EXPECTED DESTINATION URL
		local URL2=$(urlEncodeSpaces $(echo "${line}" | cut -f2 -d,));
		#RUN CURL COMMAND
		local RESULT=`curl -s -L -I -w "%{url_effective},%{http_code},%{num_redirects}" "${URL1}" | tail -1`;
		#GET URL EFFECTIVE
		local URL_EFFECTIVE=$(echo $RESULT | cut -f1 -d,);
		#GET RESPONSE CODE AND INCREMENT RESPONSE CODE COUNTER
		local HTTP_CODE=$(echo $RESULT | cut -f2 -d,);
		countRepCode ${HTTP_CODE};
		#GET NUMBER OF REDIRECTS
		local NUM_REDIRECTS=$(echo $RESULT | cut -f3 -d,);
		#DETERMINE IF REAL DESINATION SAME/DIFFERENT FROM EXPECTED DESTINATION URL
		local MATCH=`isSame "${URL2}" "${URL_EFFECTIVE}"`;
		countDiffSame ${MATCH};
		#PUT THE OUTPUT TOGETHER TO RETURN
		local OUTPUT="${MATCH},${HTTP_CODE},${NUM_REDIRECTS},${URL1},${URL2},${URL_EFFECTIVE}";
		#TEXT THAT TELL YOU WHAT THE FIELDS ARE
		echo ${OUTPUT};
		#echo `curl -s -L -I -w "%{url_effective} %{http_code} %{num_redirects}" "$line" | tail -1`,"$line" | awk -F "," '{print $2" "$1}' | tr " " ",";
done < ${LISTDATA}
}
# FUNCTION: checkLinksFull $1
# Accepts CSV data input and performs a link check, outputs CSV columns of results
function checkLinksFull()
{
	while read line || [[ -n "$line" ]]
	do           
		#STRIP WHITESPACE FROM LINE
		line=$(echo ${line} | awk '{$1=$1};1');
		#CHECK IF DATA EXISTS IN LINE
		[[ -z "${line}" ]] && continue 1;
		#GET THE DATA TOGETHER
		local URL1=$(urlEncodeSpaces $(echo "${line}" | cut -f1 -d,));
		local URL2=$(urlEncodeSpaces $(echo "${line}" | cut -f2 -d,));
		local RESULT="$(curl -s -L -I -w 'Location: %{url_effective}' ${URL1} | grep -e 'Location:' -e 'HTTP/' | awk '{print $2}')";
		local URL_EFFECTIVE=$(echo "${RESULT}" | tail -n1);
		#DETERMINE IF REAL DESINATION SAME/DIFFERENT FROM EXPECTED DESTINATION URL
		local MATCH=`isSame "${URL2}" "${URL_EFFECTIVE}"`;
		local OUTPUT="$(echo ${MATCH},${URL1},${URL2},${RESULT}  | tr "\n" ',' | tr ' ' ',')";
		#URL1='http://www.devry.edu/aa/' && echo $URL1 $(curl -s -L -I -w "Location: %{url_effective}" "$URL1" | grep -e 'Location:' -e 'HTTP/' | awk '{print $2}') | tr ' ' ','
		echo ${OUTPUT};
		#echo ${URL_EFFECTIVE} "ssssssss"
done < $LISTDATA
}
#START EXECUTING HERE
LISTDATA=${1}
echo "Checking data for common mistakes";
checkInput ${LISTDATA};
echo "";
echo "Starting link check, this is CSV output...";
#string='My string';
#DECLEAR SOME ARRAYS
declare -A diffSameCnt; # NEEDED FOR countDiffSame
#IF PERAMETER 'FULL' EXISTS DO checkLinksFull, ELSE DO checkLinksSum
if [[ $2 == 'FULL' ]]
then
	#OUTPUT USING FULL DATA REPORT
	echo "Diff/Same,Target URL, Expected URL, Path...";
	checkLinksFull ${LISTDATA};
else
	#OUTPUT SUMMARY REPORT
	echo "Diff/Same,Response,Hops,Target URL,Expected URL,Final URL";
	checkLinksSum ${LISTDATA};
fi
echo -e "\nDestination Response Codes Summary:"
countRepCode;
echo -e "\nExpected Destination DIFF/SAME Summary:"
countDiffSame;

echo "";
