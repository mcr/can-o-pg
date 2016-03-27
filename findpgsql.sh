#!/bin/sh

POSTGRESQLlib=/usr/lib/postgresql

if [ -x /ITER/bin/initdb ]; then echo /ITER/bin; exit; fi

for pgdir in $(/bin/ls -1d ${POSTGRESQLlib}/9.* ${POSTGRESQLlib}/8.* 2>/dev/null | sort -nr)
do
	if [ -x ${pgdir}/bin/initdb ]; then echo ${pgdir}/bin; exit; fi
done

echo WHERE IS POSTGRESQL; exit 2

