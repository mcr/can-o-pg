# this postgresql local cluster init was first developed for the
# ITERation project:  http://tbs-sct.ircan.gc.ca/projects/iteration
#

APPNAME:=$(shell basename $$(pwd))
APPDIR=.
TOP=$(shell pwd)
SCRIPTDIR=vendor/plugins/can-o-pg
PSQL=${POSTBIN}/psql
PG_DUMP=${POSTBIN}/pg_dump
PG_RESTORE=${POSTBIN}/pg_restore
POSTMASTER=${POSTBIN}/postmaster
INITDB=${POSTBIN}/initdb
PG_CTL=${POSTBIN}/pg_ctl
TCPIP=-h ''
# make up your own, put it in can-o-pg.settings
DBPASSWORD=baesheDaic5OhGh2
DBPATH=${TOP}/run
RUNDIR=${TOP}/run
LOGDIR=${RUNDIR}/log
DBCLUSTER=${DBPATH}/dbcluster
DATABASE=${APPNAME}_development

APACHE2_MODDIR=$(shell if [ -d /usr/lib/apache2/modules ]; then echo /usr/lib/apache2/modules; else echo WHERE IS APACHE; fi; )
WEBSERVER=$(shell if [ -x /usr/sbin/httpd2 ]; then echo  /usr/sbin/httpd2; elif [ -x /usr/sbin/apache2 ]; then echo /usr/sbin/apache2; fi)
DATABASEYML=${SCRIPTDIR}/database.yml
PHP5_MODDIR=${APACHE2_MODDIR}
IPADDRESS=127.0.0.1
MIMETYPES=$(shell if [ -f /etc/apache2/mime.types ]; then echo /etc/apache2/mime.types; elif [ -f /etc/mime.types ]; then echo /etc/mime.types; fi)
SEDFILE=sed \
		-e 's,@APP@,${APPNAME},g' \
		-e 's,@APPNAME@,${APPNAME},g' \
		-e 's,@DATABASE@,${DATABASE},g' \
		-e 's,@DBPATH@,${DBPATH},g' \
		-e 's,@RUNDIR@,${RUNDIR},g' \
		-e 's,@LOGDIR@,${LOGDIR},g' \
		-e 's,@DBPASSWORD@,${DBPASSWORD},g' \
		-e 's,@SCRIPTDIR@,${SCRIPTDIR},g' \
		-e 's,@TOPDIR@,'${TOP}',g' \
	        -e 's,@APACHE2_MODDIR@,'${APACHE2_MODDIR}',g' \
	        -e 's,@WEBSERVER@,'${WEBSERVER}',g' \
	        -e 's,@MIMETYPES@,'${MIMETYPES}',g' \
	        -e 's,@PHP5_MODDIR@,'${PHP5_MODDIR}',g'


export LANG=C
export LC_TIME=C
export DATABASE

-include can-o-pg.settings
SYSTEMPORT=$(shell ${SCRIPTDIR}/portnum.sh )
POSTBIN?=$(shell ${SCRIPTDIR}/findpgsql.sh )
SYSTEMURL?=http://localhost:${SYSTEMPORT}/

all:: ${DBPATH}/postmaster.pid ${DATABASEYML}

install:
	ln -f -s ${SCRIPTDIR}/Makefile .

run/dirs:
	mkdir -p run run/lock ${LOGDIR} ${LOGDIR}/apache2
	touch run/dirs

run/dbinit: run/dirs ${SCRIPTDIR}/bootstrap.sql ${EXTRAFILES}
	-[ -f ${DBPATH}/postmaster.pid ] && ${PG_CTL} -D ${DBPATH} stop
	-rm -f ${DBPATH}/postmaster.pid
	echo following will bail and keep your data
	[ ! -f ${RUNDIR}/precious ]
	-rm -rf ${DBCLUSTER}
	mkdir -p ${DBCLUSTER} ${LOGDIR}
	chmod u=rwx,g-rx,o-rx ${DBPATH}
	${INITDB} --encoding=utf8 -D ${DBCLUSTER}
	cp ${SCRIPTDIR}/pg_hba.conf ${DBCLUSTER}
	echo "superuser ${USER} postgres" >${DBCLUSTER}/pg_ident.conf
	${POSTMASTER} -D ${DBCLUSTER} ${TCPIP} -k ${DBPATH} > ${LOGDIR}/postgresql.log 2>&1 &
	sleep 10
	${PSQL} -h ${DBPATH} -f ${SCRIPTDIR}/bootstrap.sql template1
	if [ -f can-o-pg.sql ]; then ${PSQL} -h ${DBPATH} -f can-o-pg.sql template1; fi
	${PG_CTL} -D ${DBCLUSTER} stop
	touch run/dbinit

psql:
	@${PSQL} -h ${DBPATH} $${DATABASE-template1} $${PSQLUSER}

load:
	echo LOADING to database $${DATABASE-template1}
	${PSQL} -q -o /dev/null -h ${DBPATH} $${DATABASE-template1} -f $${INPUTFILE}

restore:
	echo RESTORING to database $${DATABASE-template1}
	${PG_RESTORE} -h ${DBPATH} -d $${DATABASE-template1} $${INPUTFILE}

dump:
	echo DUMPING to database $${OUTFILE-${APPDIR}/db/output.sql}
	${PG_DUMP} --data-only --column-inserts -h ${TOP}/run ${TABLE} ${DATABASE} >$${OUTFILE-${APPDIR}/db/output.sql}

dumpschema:
	echo DUMPING SCHEMA to database $${OUTFILE-${APPDIR}/db/schema.sql}
	mkdir -p ${APPDIR}/db
	${PG_DUMP} --create --schema-only -h ${TOP}/run ${TABLE} ${DATABASE} >$${OUTFILE-${APPDIR}/db/schema.sql}

loadschema:
	echo Loading SCHEMA from database $${OUTFILE-${APPDIR}/db/schema.sql}
	${PSQL} -q -h ${DBPATH} ${DATABASE} -f ${APPDIR}/db/schema.sql

#run/dbinit: #sql/schema.sql db_dump/restore.sql
#	make dbrebuild

${DBPATH}/postmaster.pid: run/dbinit #db_dump/restore.sql
	mkdir -p run/postgresql
	${POSTMASTER} -D ${DBCLUSTER} ${TCPIP} -k ${DBPATH} > ${LOGDIR}/postgresql.log 2>&1 &

stop::
	if [ -r ${DBCLUSTER}/postmaster.pid ]; then ${PG_CTL} -D ${DBCLUSTER} stop; fi

${SCRIPTDIR}/%.sh:${SCRIPTDIR}/%.sh.in Makefile
	${SEDFILE} $< >$@
	chmod +x $@

%: %.in Makefile
	${SEDFILE} $< >$@
	chmod +x $@

${SCRIPTDIR}/%: ${SCRIPTDIR}/%.in Makefile
	${SEDFILE} $< > $@
	@if [ -x $< ]; then chmod +x $@; fi

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
	@echo You can enable by: cp ${SCRIPTDIR}/database.yml ${APPDIR}/config/database.yml

clean:
	@rm -f ${SCRIPTDIR}/database.yml ${SCRIPTDIR}/bootstrap.sql
	@rm -f ${SCRIPTDIR}/apache2.conf ${SCRIPTDIR}/runweb.sh ${SCRIPTDIR}/php.ini ${SCRIPTDIR}/php/conf/config.inc.php
	@rm -f ${SCRIPTDIR}/shutit.sh

apache: ${SCRIPTDIR}/apache2.conf ${SCRIPTDIR}/runapp.sh ${SCRIPTDIR}/runweb.sh ${SCRIPTDIR}/php.ini ${SCRIPTDIR}/php/conf/config.inc.php httpd.conf
	${SCRIPTDIR}/runweb.sh

apachestop: ${SCRIPTDIR}/shutit.sh
	${SCRIPTDIR}/shutit.sh

server: ${DBPATH}/postmaster.pid
	cp ${SCRIPTDIR}/database.yml ${APPDIR}/config/database.yml
	ruby ${APPDIR}/script/server

dbpath:
	@echo ${DBPATH}

dbpass:
	@echo ${DBPASSWORD}

dbredo:
	-make stop
	rm -rf run/postgresql
	rm run/dbinit
	make

reload:
	${PG_CTL} -D ${DBCLUSTER} reload

showconfig:
	@echo TOP=${TOP}
	@echo RUNDIR=${RUNDIR}
	@echo POSTBIN=${POSTBIN}
	@echo APPNAME=${APPNAME}
	@echo SCRIPTDIR=${SCRIPTDIR}
	@echo APACHE2_MODDIR=${APACHE2_MODDIR}
	@echo WEBSERVER=${WEBSERVER}
	@echo MIMETYPES=${MIMETYPES}
	@echo PHP5_MODDIR=${PHP5_MODDIR}
	@echo SYSTEMPORT=${SYSTEMPORT}
	@echo SYSTEMURL=${SYSTEMURL}
	@echo
	@echo "# the following can be put in can-o-pg.settings"
	@echo DBPATH=${DBPATH}
	@echo DBPASSWORD=${DBPASSWORD}
	@echo DATABASE=${DATABASE}
	@echo DBCLUSTER=${DBCLUSTER}
	@echo APPDIR=${APPDIR}


