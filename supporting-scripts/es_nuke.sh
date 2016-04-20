#!/bin/sh
# stop logstash, NUKE ALL data in elasticsearch, remove the sincedb, restart logstash
# this is incredibly destructive!

# source function library
. /etc/rc.d/init.d/functions

sourceloc=/usr/local/logstash-*
sincedb=/var/db/logstash/sincedb

ARGC=$#

if [ ${ARGC} -ne 1 ]; then
    echo "ERROR: This script takes exactly one argument - the basename of the index to delete."
    echo "       Basename of index is something like 'syslog', 'netflow', or 'httpdlog'"
    echo "Exiting."
    exit 2
fi

BASEINDEX=$1
DOCCOUNT=$( http://localhost:9200/${BASEINDEX}-*/_count )

echo "WARNING!!  THIS COMMAND CAN DESTROY DATA!  READ CAREFULY!"
echo "---------------------------------------------------------"
echo "This script will permanently delete data from the elasticsearch server."
echo
echo -e "There are currently \e1m${DOCCOUNT}\e[0m documents in the \e[1m${BASEINDEX}-*\e[0m indices."
echo

echo
echo -e "To delete all of the '\e[1m${BASEINDEX}\e[0m' indices from the server, type \"\e[1m\e[91mYES\e[0m\" below and press return."
read RESPONSE

if [ ${RESPONSE} != "YES" ]; then
    echo "Not deleting anything without explicit confirmation."
    exit
else
    echo -n "Deleting all data from the ${BASEINDEX}-* indices: "
    curl -s -XDELETE "http://localhost:9200/${BASEINDEX}-*" > /dev/null && success || failure
    echo

    echo
    echo "NOTE: This script does not delete the 'sincedb' file, which tracks progress through existing"
    echo "  log files. If you want to re-parse existing files, you'll need to run the following commands:"
    echo "sudo rm ${sincedb}"
    echo "sudo /usr/local/sbin/ls_restart.sh"
    echo
fi