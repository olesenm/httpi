# Useless makefile for managing HTTPi versions (C) 1999 Cameron Kaiser
# This is really only needed for my use, but if you want, here it is, no
# support or strings attached.

SHELL		= /bin/sh
RM		= /bin/rm
CP		= /bin/cp
MV		= /bin/mv
CAT		= /bin/cat
LS		= /bin/ls
LN		= /usr/bin/ln
SLEEP		= /usr/bin/sleep
GREP		= /usr/bin/grep
HEAD		= /usr/bin/head
TAR		= /usr/bin/tar
GZIP		= /usr/local/bin/gzip

REPOSITORY	= /home/spectre/htdocs/httpi

default_target: install

spotless: clean
realclean: clean

clean:
	${RM} -f transcript.* sockcons

version:
	@${CAT} VERSION
	@${SLEEP} 2

configure: install
configure.inetd: install
configure.demonic: install
configure.xinetd: install
configure.generic: install

install: version
	@echo "Do one of: 'perl configure.inetd'"
	@echo "           'perl configure.demonic'"
	@echo "           'perl configure.xinetd'"
	@echo "           'perl configure.generic'"
	@echo
	@echo "If you don't know which to use, read the INSTALL file."

dist: version clean
	@echo "ABOUT TO OVERWRITE OLD INSTALL! CHECK THIS IS CORRECT!!!!!"
	@${SLEEP} 3
	${RM} -f configure Manifest
	echo "${RM} -rf ../`${HEAD} -1 VERSION` ../`${HEAD} -1 VERSION`.ta*"\			> /tmp/httpinst
	echo "${CP} -r . ../`${HEAD} -1 VERSION`" >> /tmp/httpinst
	echo "cd ../`${HEAD} -1 VERSION`" >> /tmp/httpinst
	echo "${LN} -s configure.inetd configure"\
		>> /tmp/httpinst
	echo "${LS} -lRF > /tmp/Manifest" >> /tmp/httpinst
	echo "${MV} /tmp/Manifest ." >> /tmp/httpinst
	echo "cd .." >> /tmp/httpinst
	echo\
	"${TAR} cvf `${HEAD} -1 VERSION`.tar `${HEAD} -1 VERSION`/*"\
		>> /tmp/httpinst
	echo "${GZIP} `${HEAD} -1 VERSION`.tar" >> /tmp/httpinst
	echo "${MV} `${HEAD} -1 VERSION`.tar.gz ${REPOSITORY}"\
		>>/tmp/httpinst
	${SHELL} /tmp/httpinst
	${RM} -f /tmp/httpinst
	${LN} -s configure.inetd configure
