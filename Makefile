# this postgresql local cluster init was first developed for the 
# ITERation project:  http://tbs-sct.ircan.gc.ca/projects/iteration
#

APPNAME:=$(shell basename $$(pwd))
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

APACHE2_MODDIR=$(shell if [ -d /usr/lib/apache2/modules ]; then echo /usr/lib/apache2/modules; else echo WHERE IS APACHE; fi; )
WEBSERVER=$(shell if [ -x /usr/sbin/httpd2 ]; then echo  /usr/sbin/httpd2; elif [ -x /usr/sbin/apache2 ]; then echo /usr/sbin/apache2; fi)
PHP5_MODDIR=${APACHE2_MODDIR}
SYSTEMPORT=$(./etc/portnum.sh )
IPADDRESS=127.0.0.1
MIMETYPES=$(shell if [ -f /etc/apache2/mime.types ]; then echo /etc/apache2/mime.types; elif [ -f /etc/mime.types ]; then echo /etc/mime.types; fi)
SYSTEMURL=$(echo 'http://localhost:'${SYSTEMPORT}'/')

-include can-o-pg.settings

export LANG=C
export LC_TIME=C
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
	${INITDB} --encoding=utf8 -D ${DBCLUSTER}
	cp ${SCRIPTDIR}/pg_hba.conf ${DBCLUSTER}
	${POSTMASTER} -D ${DBCLUSTER} ${TCPIP} -k ${DBPATH} > run/log/postgresql.log 2>&1 &
	sleep 10
	${PSQL} -h ${DBPATH} -f ${SCRIPTDIR}/bootstrap.sql template1
	${PG_CTL} -D ${DBCLUSTER} stop
	touch run/dbinit

psql:
	@${PSQL} -h ${TOP}/run $${PSQLUSER} $${DATABASE-template1}

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

${SCRIPTDIR}/%: ${SCRIPTDIR}/%.in Makefile
	sed \
		-e 's,@APP@,${APPNAME},g' \
		-e 's,@APPNAME@,${APPNAME},g' \
		-e 's,@DBPATH@,${DBPATH},g' \
		-e 's,@DBPASSWORD@,${DBPASSWORD},g' \
		-e 's,@SCRIPTDIR@,${SCRIPTDIR},g' \
		-e 's,@TOPDIR@,'${TOP}',g' \
	        -e 's,@APACHE2_MODDIR@,'${APACHE2_MODDIR}',g' \
	        -e 's,@WEBSERVER@,'${WEBSERVER}',g' \
	        -e 's,@MIMETYPES@,'${MIMETYPES}',g' \
	        -e 's,@PHP5_MODDIR@,'${PHP5_MODDIR}',g' \
		$< >$@ 
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
	@echo You can enable by: cp ${SCRIPTDIR}/database.yml config/database.yml

clean:
	@rm -f ${SCRIPTDIR}/database.yml ${SCRIPTDIR}/bootstrap.sql
	@rm -f ${SCRIPTDIR}/apache2.conf ${SCRIPTDIR}/runweb.sh ${SCRIPTDIR}/php.ini ${SCRIPTDIR}/php/conf/config.inc.php
	@rm -f ${SCRIPTDIR}/shutit.sh  

apache: ${SCRIPTDIR}/apache2.conf ${SCRIPTDIR}/runweb.sh ${SCRIPTDIR}/php.ini ${SCRIPTDIR}/php/conf/config.inc.php
	${SCRIPTDIR}/runweb.sh

apachestop: ${SCRIPTDIR}/shutit.sh  
	${SCRIPTDIR}/shutit.sh

server: ${DBPATH}/postmaster.pid
	cp ${SCRIPTDIR}/database.yml config/database.yml
	script/rails server

dbpath:
	@echo ${DBPATH}

showconfig:
	@echo POSTBIN ${POSTBIN}
	@echo APPNAME ${APPNAME}
	@echo DBPATH: ${DBPATH}
	@echo DBPASSWORD: ${DBPASSWORD}
	@echo SCRIPTDIR:  ${SCRIPTDIR}
	@echo TOP:        ${TOP}
	@echo APACHE2_MODDIR: ${APACHE2_MODDIR}
	@echo WEBSERVER:  ${WEBSERVER}
	@echo MIMETYPES:  ${MIMETYPES}
	@echo PHP5_MODDIR:${PHP5_MODDIR}
	@echo DATABASE:   ${DATABASE}



