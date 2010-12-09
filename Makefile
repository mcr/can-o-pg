# this postgresql local cluster init was first developed for the 
# ITERation project:  http://tbs-sct.ircan.gc.ca/projects/iteration
#

APPNAME=$(shell basename $$(pwd))
TOP=$(shell pwd)
POSTBIN?=$(shell etc/findpgsql.sh )
PSQL=${POSTBIN}/psql
POSTMASTER=${POSTBIN}/postmaster
INITDB=${POSTBIN}/initdb
PG_CTL=${POSTBIN}/pg_ctl
TCPIP=-h ''
# make up your own.
DBPASSWORD=baesheDaic5OhGh2
DBPATH=${TOP}/run
DBCLUSTER=${DBPATH}/dbcluster
DATABASE=${APPNAME}_development

all: ${DBPATH}/postmaster.pid etc/database.yml

${TOP}/run/dirs:
	mkdir -p run run/lock run/log run/log/apache2
	touch run/dirs

run/dbinit: ${TOP}/run/dirs etc/bootstrap.sql
	-[ -f ${DBPATH}/postmaster.pid ] && ${PG_CTL} -D ${DBPATH} stop
	-rm -f ${DBPATH}/postmaster.pid
	-rm -rf ${DBPATH}
	mkdir -p ${DBCLUSTER} ${DBPATH}/log
	chmod u=rwx,g-rx,o-rx ${DBPATH}
	${INITDB} -D ${DBCLUSTER}
	cp etc/pg_hba.conf ${DBCLUSTER}
	${POSTMASTER} -D ${DBCLUSTER} ${TCPIP} -k ${DBPATH} > run/log/postgresql.log 2>&1 &
	sleep 5
	${PSQL} -h ${DBPATH} -f etc/bootstrap.sql template1
	${PG_CTL} -D ${DBCLUSTER} stop
	touch run/dbinit

psql:
	${PSQL} -h ${TOP}/run $${DATABASE-template1}

load:
	${PSQL} -h ${TOP}/run $${DATABASE-template1} -f $${INPUTFILE}

#run/dbinit: #sql/schema.sql db_dump/restore.sql
#	make dbrebuild

${DBPATH}/postmaster.pid: run/dbinit #db_dump/restore.sql
	mkdir -p run/postgresql
	${POSTMASTER} -D ${DBCLUSTER} ${TCPIP} -k ${DBPATH} > run/log/postgresql.log 2>&1 &

stop:
	${PG_CTL} -D ${DBCLUSTER} stop

etc/bootstrap.sql: etc/bootstrap.sql.in Makefile
	sed \
		-e 's,@APP@,${APPNAME},' \
		-e 's,@APPNAME@,${APPNAME},' \
		-e 's,@DBPATH@,${DBPATH},' \
		-e 's,@DBPASSWORD@,${DBPASSWORD},' \
		etc/bootstrap.sql.in >etc/bootstrap.sql

etc/database.yml: etc/database.yml.in Makefile
	sed \
		-e 's,@APP@,${APPNAME},' \
		-e 's,@APPNAME@,${APPNAME},' \
		-e 's,@DBPATH@,${DBPATH},' \
		-e 's,@DBPASSWORD@,${DBPASSWORD},' \
		etc/database.yml.in >etc/database.yml
	@echo You can enable by: cp etc/database.yml config/database.yml

showconfig:
	@echo POSTBIN ${POSTBIN}
	@echo APPNAME ${APPNAME}
	@echo DBPATH  ${DBPATH}



