#
# this postgresql local cluster init was first developed for the 
# ITERation project:  http://tbs-sct.ircan.gc.ca/projects/iteration
# 
# It was adapted at CREDIL to make the DJANGO variant.
#

APPNAME=clientportal
TOP=$(shell pwd)
POSTBIN?=$(shell etc/findpgsql.sh )
PSQL=${POSTBIN}/psql
POSTMASTER=${POSTBIN}/postmaster
INITDB=${POSTBIN}/initdb
PG_CTL=${POSTBIN}/pg_ctl
DBPATH=${TOP}/run
CLUSTER=${DBPATH}/dbcluster
# make up your own.
DBPASSWORD=baesheDaic5OhGh2
TCPIP=-h ''

all: ${CLUSTER}/postmaster.pid

server: ${CLUSTER}/postmaster.pid
	cd ${APPNAME} && python manage.py runserver

run/dirs:
	mkdir -p run run/lock run/log run/log/apache2
	touch run/dirs

run/dbinit: run/dirs etc/settings.py etc/bootstrap.sql
	-[ -f ${CLUSTER}/postmaster.pid ] && ${PG_CTL} -D ${CLUSTER} stop
	-rm -f ${CLUSTER}/postmaster.pid
	-rm -rf ${CLUSTER}
	mkdir -p ${CLUSTER}
	chmod u=rwx,g-rx,o-rx ${CLUSTER}
	${INITDB} -D ${CLUSTER}
	cp etc/pg_hba.conf ${CLUSTER}
	${POSTMASTER} -D ${CLUSTER} ${TCPIP} -k ${DBPATH} > run/log/postgresql.log 2>&1 &
	sleep 5
	${PSQL} -h ${TOP}/run -f etc/bootstrap.sql template1
	cp etc/settings.py clientportal
	${PG_CTL} -D ${CLUSTER} stop
	touch run/dbinit

psql:
	${PSQL} -h ${TOP}/run $${DATABASE-template1}

load:
	${PSQL} -h ${TOP}/run $${DATABASE-template1} -f $${INPUTFILE}

#run/dbinit: #sql/schema.sql db_dump/restore.sql
#	make dbrebuild

etc/bootstrap.sql: etc/bootstrap.sql.in Makefile
	sed \
		-e 's,@APP@,${APPNAME},' \
		-e 's,@APPNAME@,${APPNAME},' \
		-e 's,@DBPATH@,${DBPATH},' \
		-e 's,@DBPASSWORD@,${DBPASSWORD},' \
		etc/bootstrap.sql.in >etc/bootstrap.sql

etc/settings.py: etc/settings.py.in Makefile
	sed \
		-e 's,@APP@,${APPNAME},' \
		-e 's,@APPNAME@,${APPNAME},' \
		-e 's,@DBPATH@,${DBPATH},' \
		-e 's,@DBPASSWORD@,${DBPASSWORD},' \
		etc/settings.py.in >etc/settings.py

${CLUSTER}/postmaster.pid: run/dbinit #db_dump/restore.sql
	mkdir -p run/postgresql
	${POSTMASTER} -D ${CLUSTER} ${TCPIP} -k ${TOP}/run > run/log/postgresql.log 2>&1 &

stop:
	${PG_CTL} -D ${CLUSTER} stop

showconfig:
	@echo POSTBIN ${POSTBIN}



