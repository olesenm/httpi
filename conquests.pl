$INSTALL_PATH = &prompt(<<"EOF", "/usr/local/bin/httpi", 1);

Cool, we made it that far.

Now you'll need to answer a few questions about your installation options
and some functions that need to be hard-coded into HTTPi. If you just hit
ENTER with nothing entered, the default (in [ ]) will be selected.

Where do you want the resultant script placed? If you're using configure to
build multiple instances of HTTPi on different ports, make sure this changes
unless the timeout, mount directory and log file path are identical.

WARNING: If you're doing a full install, including modifying inetd's config
files, THIS MUST BE AN ABSOLUTE PATH.

Install path?
EOF
$DEF_HTDOCS_PATH = &prompt(<<"EOF", "/usr/local/htdocs", 1);
Where do you want the server to serve documents from? All files that HTTPi
will make available, executables included, must be under this tree (i.e.
no ~ or user filesystem). This is the webserver's mount directory.

EOF
print <<"EOF" if (!-d $DEF_HTDOCS_PATH);
WARNING: That directory hasn't been created yet. Make sure you create it.

EOF
$DEF_ACCESS_LOG = &prompt(<<"EOF", "$DEF_HTDOCS_PATH/access.log", 1);

Where do you want the server to put the access log? If you don't want
logging, specify /dev/null. This is the webserver's log file path.

EOF
print <<"EOF";
WARNING: Make sure the access log is writeable, or there won't be much in it.
Check the file's permissions, just to be safe.

EOF

$q = 0; $j = '';
($ENV{'TZ'} =~ /[A-Z]+([0-9]+)[A-Z]+/) && ($q = "-" . substr("0${1}00", 
	length("0${1}00") - 4, 4));
$j = <<"EOF" if ($q);
(I made a guess based on your TZ environment variable, which is $ENV{'TZ'}.
But I sometimes don't guess right, so check to be sure.)
EOF
$DEF_TIME_ZONE = &prompt(<<"EOF", $q || "+0000", 1);
HTTPi does CERN logging format making it compatible with most log analysers.
However, to make it as compatible as possible on as wide a range of Perls as
possible, it doesn't do locale() work to find out what your timezone is. 
$j
If you don't care, you can accept the default. If you do, enter a
five-character timezone here (e.g., if you're on Pacific time, like I am,
enter -0800 for 8 hours behind Greenwich mean).
EOF

$DEF_HTTP11WAIT = &prompt(<<"EOF", "n", 1);
HTTPi supports HTTP/1.1 persistent connections, but very few clients do right
now. It's nice to have though, for those that do, and it means that it will
spawn fewer processes sum total if the client is nice enough to do all its
requests on a single socket.

The downside is, due to the current implementation, clients that do not
properly support HTTP/1.1 persistent connections (but advertise they do) will
have slightly slower access. As of this writing, Netscape is particularly bad
on this point. Unfortunately, there's nothing the server can do about that.

Enable HTTP/1.1 support?
EOF
$DEF_HTTP11WAIT = ($DEF_HTTP11WAIT eq 'y') ? 1 : 0;

$DEF_TIME_OUT = &prompt(<<"EOF", "1", 1) unless (!$DEF_HTTP11WAIT);
And speaking of supposedly compliant clients ...

HTTPi has a funky kludge in it to better handle supposedly HTTP/1.1-compliant
clients that really aren't by waiting a specified number of seconds before
dying off to see if another request comes down the pike. Increasing this
number makes it more tolerant of slower clients, but degrades overall
connection speed. This only applies to clients that advertise the
"Connection: Keep-Alive" header. The default should be satisfactory here.

SPECIAL CASE: If you answer zero to this question, it will wait forever.
This is probably NOT what you want, but I guess one of you might ...

Number of seconds to wait for slow HTTP/1.1 clients?
EOF
$DEF_TIME_OUT += 0;

$DEF_MRESTRICTIONS = &prompt(<<"EOF", "y", 1);
New in HTTPi/0.4 is the restriction matrix, allowing you to restrict resources
to particular IP addresses or browsers. The restriction matrix allows very
sophisticated security and management, but at the cost of slightly degrading
runtime speed. If you aren't running any services that require strong security,
browser restrictions, or network restrictions, you'll gain a speed increase
by turning the restriction matrix off. (You can always enable it later.)

Please read the manual section about the restriction matrix for more info.

Note that xinetd, and possibly others, implement similar IP restriction
services and do so much quickly than HTTPi. TCP wrappers might also be useful.
In such cases, the restriction matrix may not be necessary, though it may
be more flexible. See your (x)inetd's manual, or your OS's.

Enable restriction matrix?
EOF
$DEF_MRESTRICTIONS = ($DEF_MRESTRICTIONS eq 'y') ? 1 : 0;

$bleh = &prompt(<<"EOF", "2", 1);
Webserver logs are a pain in the butt, if you'll pardon the pun and the
expression, particularly when they get lengthy.

Earlier versions of HTTPi only supported logging type 1:

host referer - [CERNdate] "METHOD address HTTP/V.v" returncode contentlength
(example: stockholm.ptloma.edu - - [31/Jan/1969:00:00:00] "GET / HTTP/1.0"
200 1000)

This is a compatible and valid CERN-style log entry, but it doesn't keep or
know about user agents, and it could be smaller. So 0.4 supports two other
formats:

Type 2 for more "complete" logging, in the Apache/NCSA style:
host referer useragent [CERNdate] "METHOD address HTTP/V.v" returncode length

... and type 3 for ultra-terse logging:
host - - [CERNdate] "METHOD address HTTP/V.v" returncode length

Which type of logging should be used, 1, 2 or 3?
EOF

$bleh += 0;
($bleh == 1) && ($DEF_ORIG_LOG = 1);
($bleh == 2) && ($DEF_GROSS_LOG = 1);
($bleh == 3) && ($DEF_TERSE_LOG = 1);
