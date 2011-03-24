# this postgresql local cluster init was first developed for the 
# ITERation project:  http://tbs-sct.ircan.gc.ca/projects/iteration
#

APPNAME=$(shell basename $$(pwd))
TOP=$(shell pwd)
SCRIPTDIR=vendor/plugins/can-o-pg
POSTBIN?=$(shell ${SCRIPTDIR}/findpgsql.sh )
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
export DATABASE

all: ${DBPATH}/postmaster.pid ${SCRIPTDIR}/database.yml

install: 
	ln -f -s vendor/plugins/can-o-pg/Makefile .

run/dirs:
	mkdir -p run run/lock run/log run/log/apache2
	touch run/dirs

run/dbinit: run/dirs ${SCRIPTDIR}/bootstrap.sql
	-[ -f ${DBPATH}/postmaster.pid ] && ${PG_CTL} -D ${DBPATH} stop
	-rm -f ${DBPATH}/postmaster.pid
	-rm -rf ${DBCLUSTER}
	mkdir -p ${DBCLUSTER} ${DBPATH}/log
	chmod u=rwx,g-rx,o-rx ${DBPATH}
	${INITDB} -D ${DBCLUSTER}
	cp ${SCRIPTDIR}/pg_hba.conf ${DBCLUSTER}
	${POSTMASTER} -D ${DBCLUSTER} ${TCPIP} -k ${DBPATH} > run/log/postgresql.log 2>&1 &
	sleep 5
	${PSQL} -h ${DBPATH} -f ${SCRIPTDIR}/bootstrap.sql template1
	${PG_CTL} -D ${DBCLUSTER} stop
	touch run/dbinit

psql:
	${PSQL} -h ${TOP}/run $${DATABASE-template1}

load:
	echo LOADING to database $${DATABASE-template1}
	${PSQL} -h ${TOP}/run $${DATABASE-template1} -f $${INPUTFILE}

#run/dbinit: #sql/schema.sql db_dump/restore.sql
#	make dbrebuild

${DBPATH}/postmaster.pid: run/dbinit #db_dump/restore.sql
	mkdir -p run/postgresql
	${POSTMASTER} -D ${DBCLUSTER} ${TCPIP} -k ${DBPATH} > run/log/postgresql.log 2>&1 &

stop:
	${PG_CTL} -D ${DBCLUSTER} stop

${SCRIPTDIR}/bootstrap.sql: ${SCRIPTDIR}/bootstrap.sql.in Makefile
	sed \
		-e 's,@APP@,${APPNAME},g' \
		-e 's,@APPNAME@,${APPNAME},g' \
		-e 's,@DBPATH@,${DBPATH},g' \
		-e 's,@DBPASSWORD@,${DBPASSWORD},g' \
		${SCRIPTDIR}/bootstrap.sql.in >${SCRIPTDIR}/bootstrap.sql

${SCRIPTDIR}/database.yml: ${SCRIPTDIR}/database.yml.in Makefile
	sed \
		-e 's,@APP@,${APPNAME},g' \
		-e 's,@APPNAME@,${APPNAME},g' \
		-e 's,@DBPATH@,${DBPATH},g' \
		-e 's,@DBPASSWORD@,${DBPASSWORD},g' \
		${SCRIPTDIR}/database.yml.in >${SCRIPTDIR}/database.yml
	@echo You can enable by: cp ${SCRIPTDIR}/database.yml config/database.yml

server: ${DBPATH}/postmaster.pid
	cp ${SCRIPTDIR}/database.yml config/database.yml
	script/rails server

showconfig:
	@echo POSTBIN ${POSTBIN}
	@echo APPNAME ${APPNAME}
	@echo DBPATH  ${DBPATH}



