#!/bin/sh

POSTGRESQLlib=/usr/lib/postgresql

if [ -x /ITER/bin/initdb ]; then echo /ITER/bin; exit; fi

for pgdir in ${POSTGRESQLlib}/9.* ${POSTGRESQLlib}/8.*
do
	if [ -x ${pgdir}/bin/initdb ]; then echo ${pgdir}/bin; exit; fi
done

echo WHERE IS POSTGRESQL; exit 2

