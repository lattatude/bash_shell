#! /bin/bash
# v1 CLATTA 2019-01-27
# Needed easy way to input list of domains and 
#  use whois to get the registrar

# Path to whois command
whois_cmd='/usr/bin/whois';
# FUNCTION: Get all the domain info, minus the terms of use, etc
whois_most(){
    echo "$(whois ${1} | grep '   ')";
}
# FUNCTION: Get just the registrar
whois_registrar(){
    whois ${1} | grep '   Registrar:';
}
# FUNCTION: Get just the name servers
whois_nameservers(){
    whois ${1} | grep '   Name Server:';
}
# FUNCTION: Print the usage text
print_usage(){
    echo "USAGE: command [DOMAIN]  OR  command [OPTIONS]";
    echo -e "\n OPTIONS:"
    echo "-d DOMAIN         Domain to query";
    echo "-n NAMESERVERS    Return name servers";
    echo "-r REGISTRAR      Return registrar name";
    echo -e "\nEXAMPLES:"
    echo "whoisit.sh dtube.com bitchute.com";
    echo "whoisit.sh -rn -d dtube.com bitchute.com";
    echo "";
}
#
# Start processing ####
#
# If no input then print usage and exit
if [[ -z "$1" ]]
    then
        print_usage;
        exit;
fi
#
# This is options mode
# Get opts
while getopts d:rn option
do
    case "${option}"
    in
        d) DOMAIN=${OPTARG}
           opts=1;;
        n) NAMESERVERS=1
           opts=1;;
        r) REGISTRAR=1
           opts=1;;
    esac
done 
#
# Start processing
#
if [ -z ${opts} ]
    then
        echo "No options"
        for x in "$@"; do
            echo ${x};
            whois_most ${x};
            echo '--------------------';
        done 
elif [ ${opts} ]
    then
        if [ "${DOMAIN}" ]
        then
            for d in ${DOMAIN}; do
                echo ${d};
                [[ "${REGISTRAR}" ]] && whois_registrar ${d};
                [[ "${NAMESERVERS}" ]] && whois_nameservers ${d};
            done
        else
            echo "You need to specify a domain to continue";
            print_usage;
        fi
else
    #Something is wrong
    print_usage;
fi
