#!/bin/bash 
# cq_pub_healthcheck.sh - Creates quick report of health of aem servers and instances
# v0.1 - CLATTA - 2017-05-02 - First version
#
#
pub_error_log='/app01/cq/publish6/crx-quickstart/logs/error.log';
pub_access_log='/app01/cq/publish6/crx-quickstart/logs/access.log';
#GET LOAD AVG OF EACH PUBLISHER SERVER
echo -e "\n\nLOAD AVERAGE\n--------------------"
for server in $@
do
    loadavg=$(ssh ${server} cat /proc/loadavg);
	echo ${server} ${loadavg};
done
#
#BUILD VARS FOR TIMES
datem10=$(date -d "-10 min" +"%d.%m.%Y\ %H:%M");
datem5=$(date -d "-5 min" +"%d.%m.%Y\ %H:%M");
#
#GET ERROR INFO FOR PAST FEW MINS FOR EACH SERVER
echo -e "\n\nERRORS SUMMARY\n--------------------";
for server in $@
do
	total_errors="$(ssh ${server} grep "\*ERROR\*" ${pub_error_log} | wc -l)";
	past10min_errors="$(ssh ${server} grep -A9999999999 "${datem10}" ${pub_error_log} | grep "\*ERROR\*" | wc -l)";
	past5min_errors="$(ssh ${server} grep -A9999999999 "${datem10}" ${pub_error_log} | grep "\*ERROR\*" | wc -l)";
	echo "${server}";
	echo "	Total Errors: ${total_errors}";
	echo "	Past 10 mins: ${past10min_errors}";
	echo "	Past  5 mins: ${past5min_errors}";
done
#
#GET ERROR REPORT FOR EACH SERVER
echo -e "\n\nERROR LOG REPORT\n--------------------";
for server in $@
do
    errors="$(ssh ${server} grep -A9999999999 "${datem10}" ${pub_error_log} | /app01/bin/cq_error_report.sh | head -20)";
	echo "${server} past 10 mins";
	echo "----------";
	echo "${errors}";
	echo -e "\n\n";
done
