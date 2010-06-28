# this postgresql local cluster init was first developed for the 
# ITERation project:  http://tbs-sct.ircan.gc.ca/projects/iteration
#

TOP=$(shell pwd)
POSTBIN?=$(shell etc/findpgsql.sh )
PSQL=${POSTBIN}/psql
POSTMASTER=${POSTBIN}/postmaster
INITDB=${POSTBIN}/initdb
PG_CTL=${POSTBIN}/pg_ctl
TCPIP=-h ''

all: run/dbcluster/postmaster.pid

run/dirs:
	mkdir -p run run/lock run/log run/log/apache2
	touch run/dirs

run/dbinit: run/dirs 
	-[ -f run/dbcluster/postmaster.pid ] && ${PG_CTL} -D run/dbcluster stop
	-rm -f run/dbcluster/postmaster.pid
	-rm -rf run/dbcluster
	mkdir -p run/dbcluster
	chmod u=rwx,g-rx,o-rx run/dbcluster
	${INITDB} -D run/dbcluster
	cp etc/pg_hba.conf run/dbcluster
	${POSTMASTER} -D run/dbcluster ${TCPIP} -k ${TOP}/run > run/log/postgresql.log 2>&1 &
	sleep 5
	${PSQL} -h ${TOP}/run -f etc/bootstrap.sql template1
	${PG_CTL} -D run/dbcluster stop
	touch run/dbinit

psql:
	${PSQL} -h ${TOP}/run $${DATABASE-template1}

load:
	${PSQL} -h ${TOP}/run $${DATABASE-template1} -f $${INPUTFILE}

#run/dbinit: #sql/schema.sql db_dump/restore.sql
#	make dbrebuild

run/dbcluster/postmaster.pid: run/dbinit #db_dump/restore.sql
	mkdir -p run/postgresql
	${POSTMASTER} -D run/dbcluster ${TCPIP} -k ${TOP}/run > run/log/postgresql.log 2>&1 &

stop:
	${PG_CTL} -D run/dbcluster stop

showconfig:
	@echo POSTBIN ${POSTBIN}


