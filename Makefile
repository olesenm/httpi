# Useless makefile for managing HTTPi versions (C)1999-2001 Cameron Kaiser
#
# This is really only needed for my use, but if you want, here it is, no
# support or strings attached, if you want to roll your own dists. The guts
# are in the dist target, natch.
#
# The only other thing an end user might use this for is "make revert" (q.v.)
# to restore their *.in files after they've irreversibly munged them.
#
# Okay, nimrods who don't read directions: YOU DO NOT USE MAKE TO MAKE
# ANY HTTPi VERSIONS, EVER! RUN configure! Sheesh, for the last time,
# the presence of a Makefile does not necessarily mean it does anything! :-P

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

REPOSITORY	= /usr/local/htdocs/httpi

default_target: install

spotless: clean revert
realclean: clean revert

unrevert:
	${CP} -f *.in stock

revert:
	${CP} -f stock/*.in .
	
clean:
	${RM} -f transcript.* sockcons testtpi uttpi

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

# DO NOT RUN THIS TARGET DIRECTLY
_testdir: version clean unrevert
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

dist: _testdir
	echo\
	"${TAR} cvf `${HEAD} -1 VERSION`.tar `${HEAD} -1 VERSION`/*"\
		>> /tmp/httpinst
	echo "${GZIP} `${HEAD} -1 VERSION`.tar" >> /tmp/httpinst
	echo "${MV} `${HEAD} -1 VERSION`.tar.gz ${REPOSITORY}"\
		>>/tmp/httpinst
	${SHELL} /tmp/httpinst
	${RM} -f /tmp/httpinst
	${LN} -s configure.inetd configure

playbox: _testdir
	${SHELL} /tmp/httpinst
	${RM} -f /tmp/httpinst
	${LN} -s configure.inetd configure

