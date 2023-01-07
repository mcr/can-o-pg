#!/bin/sh

POSTGRESQLlib=/usr/lib/postgresql

# Fedora puts it here.
if [ -x /usr/bin/initdb ]; then echo /usr/bin; exit; fi

for pgdir in $(cd ${POSTGRESQLlib} && ls -1 | sort -nr)
do
	if [ -x ${POSTGRESQLlib}/${pgdir}/bin/initdb ]; then echo ${POSTGRESQLlib}/${pgdir}/bin; exit; fi
done

echo WHERE IS POSTGRESQL; exit 2

