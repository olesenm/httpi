
print <<"EOF";

Don't run this -- this is here to stop autotest scripts.
Look at the INSTALL file.

EOF
if($ENV{'AUTOMATED_TESTING'}) {
	rename("Makefile", "NOT.A.MAKEFILE"); # ha ha
	exit 0;
}
exit 255;

