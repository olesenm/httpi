print "\nSeeing if you have some optional utilities ...\n\n";
$HOSTNAME = &wherecheck('Finding hostname', 'hostname');

print "\nChecking some system facilities I really could use ...\n\n";
$DEF_MCANALARM = &yncheck('Can we use alarm()?', 'alarm 0;');
&prompt(<<"EOF", "") if (!$DEF_MCANALARM);
Let me guess. You're not using a Unix Perl.

alarm() is no longer required for install, but you should be warned that
you cannot use HTTP/1.1 Keep-Alive connections without it. Also, alarm()
allows better process control, which reduces the chance of system overload.
You can still install HTTPi, but consider running this on a system that
supports alarm() in its Perl port.

Press ENTER to continue.
EOF

$INSTALL_PATH = &prompt(<<"EOF", "/usr/local/bin/httpi", 1);

Cool, we made it that far.

Now you'll need to answer a few questions about your installation options
and some functions that need to be hard-coded into HTTPi. If you just hit
ENTER with nothing entered, the default (in [ ]) will be selected.

Where do you want the resultant script placed? If you're using configure to
build multiple instances of HTTPi on different ports, make sure this changes
unless you're darn certain that they'll all be configured the same way.
IF YOU'RE USING CONFIGURE TO BUILD MULTIPLE INSTANCES OF HTTPi ON MULTIPLE
IP ADDRESSES (xinetd/Demonic only), THIS *MUST* BE DIFFERENT IN EACH CASE!

WARNING: If you're doing a full install, including modifying inetd (or
whatever)'s config files, THIS MUST BE AN ABSOLUTE PATH AS WELL!

Install path?
EOF
$DEF_HTDOCS_PATH = &prompt(<<"EOF", "/usr/local/htdocs", 1);
Where do you want the server to serve documents from? All files that HTTPi
will make available, executables included, must be under this tree (except
for the user filesystem option if enabled, coming up shortly). This is the
webserver's mount directory.

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

chomp($j = `$HOSTNAME`) if ($HOSTNAME);
$DEF_SERVER_HOST = &prompt(<<"EOF", $j, 1);
What will the server's name be? This should be a Fully Qualified Domain Name,
like limburgher.cheese.com.

Server host name?
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

print "You can't use alarm(), so no HTTP/1.1 for you.\n\n"
	unless ($DEF_MCANALARM);

$DEF_HTTP11WAIT = &prompt(<<"EOF", "n", 1) unless (!$DEF_MCANALARM);
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
HTTPi's answer to .htaccess and access control is the restriction matrix, 
allowing access control based on IP address, agent/browser type, and, in
0.99 and up, a user list you can specify. For example, the restriction
matrix can restrict access to a certain page only to user fred from the
local LAN, and *then* only if he's using Netscape. This code is slightly
complex, however, so it will add bulk and execution time to your build.

Note that if you plan to only do IP address-based restriction, solutions
like TCP wrappers are probably faster. xinetd also has IP address-based
restriction built in. In those cases, you would probably do better without
the restriction matrix involved.

The settings for the restriction matrix are hardcoded into httpi.in. If you
choose to enable this option, you must edit httpi.in to change your settings.
Please refer to the programming manual.

Enable restriction matrix?
EOF
$DEF_MRESTRICTIONS = ($DEF_MRESTRICTIONS eq 'y') ? 1 : 0;

$bleh = &prompt(<<"EOF", "2", 1);
Webserver logs are a pain in the butt, if you'll pardon the pun and the
expression, particularly when they get lengthy.

Logging format 1 (here a more CERN compliant variant) was what was supported
in earlier version of HTTPi:

host - - [CERNdate] "METHOD address HTTP/V.v" returncode contentlength\\
	 "referer" ""
(example: stockholm.ptloma.edu - - [31/Jan/1969:00:00:00] "GET / HTTP/1.0"
200 1000 "http://somewhere.com/" "")

This is a compatible and valid CERN-style log entry, but it doesn't keep or
know about user agents, and it could be smaller. So HTTPi also supports two
other formats:

Type 2 for more "complete" logging, in the Apache/NCSA style:
host - - [CERNdate] "METHOD address HTTP/V.v" returncode length "referer"\\
	"useragent"

... and type 3 for ultra-terse logging:
host - - [CERNdate] "METHOD address HTTP/V.v" returncode length "" ""

Which type of logging should be used, 1, 2 or 3?
EOF

$bleh += 0;
($bleh == 1) && ($DEF_ORIG_LOG = 1);
($bleh == 2) && ($DEF_GROSS_LOG = 1);
($bleh == 3) && ($DEF_TERSE_LOG = 1);

$DEF_MHTTPERL = &prompt(<<"EOF", "n", 1);
Want faster CGIs? Meet HTTPi's answer to mod_perl, HTTPerl. mod_perl works its
magic by implementing a Perl interpreter in Apache; HTTPerl takes the obvious
step of reusing the interpreter already running HTTPi to run your executables.

The major advantages:
	* Can be faster (see below for when it won't be), especially if
Perl keeps getting paged out.
	* Your executables have access to all the HTTPi internal globals and
subroutines, including HTTP negotiation and logging subroutines.
	* Works better with POST (lets you manipulate the socket directly).

The major disadvantages:
	* EVERY EXECUTABLE HTTPi RUNS HAS TO BE IN PERL. NO EXCEPTIONS! If you
must run a precompiled binary, write a Perl wrapper, and have HTTPi run that.

Please read the docs, there's important information in there about this!
Enable HTTPerl?
EOF

$DEF_MHTTPERL = (($DEF_MHTTPERL eq 'y') ? 1 : 0);

$q = &prompt(<<"EOF", "y", 1);
If you don't really care if a hostname or an IP address appears in your
access logs, you can save (in some cases substantial) time by instructing
HTTPi not to bother doing name lookups when logging. Most of you will
probably want the names resolved, but for a really sleek server you might not,
so it's now a configurable option.

Resolve IP addresses to hostnames?
EOF

$DEF_MHOSTNAMES = (($q eq 'y') ? 1 : 0);

$q = &prompt(<<"EOF", "n", 1);
HTTPi 0.99 and up can do IP-less virtual hosting by redirecting host
aliases to addresses. For example, you might define (as I do) the alias
httpi.ptloma.edu to point to http://stockholm.ptloma.edu/httpi.

This is useful for large hosting sites and aliases, but probably not for
HTTPi's prototypical usage of a little server on a little system, so it's
not enabled by default. If your HTTPi supports it (both xinetd and Demonic
do), you may wish to consider IP-based virtual hosting where you can do
multihoming with individual HTTPi processes as an alternative.

The settings for IP-less virtual hosting are hardcoded into httpi.in. If you
choose to enable this option, you must edit httpi.in to change your settings.
Please refer to the programming manual.

Enable host name redirects?
EOF

$DEF_NAMEREDIR = (($q eq 'y') ? 1 : 0);

if (!&yncheck("Can we use getpwnam()?",
	"print scalar(getpwnam('root')), ' ... '")) {
		print
	"The user filesystem option isn't available without getpwnam().\n\n";
	$DEF_MUSERFS = 0;
} else {
	$q = &prompt(<<"EOF", "n", 1);
Used to be that HTTPi was a tiny webserver for one person to run on his
machine, but the busy beavers in the HTTPi laboratories have been working
on ways of supporting a user filesystem while keeping HTTPi the slim beast
it is.

If you enable this option, users can now serve files from their own home
directories under ~/public_html. Note, however, that HTTPi draws no difference
between the root server documents and users', so users may also run executables
(and if HTTPi can't change its uid to the executable's owner, this could be
a rather large security hole). For this reason, this option defaults to no.

Enable user filesystem?
EOF
	$DEF_MUSERFS = ($q eq 'y') ? 1 : 0;
}

$q = &prompt(<<"EOF", "n", 1);
HTTPi now enables preparsing of selected content types. With the new preparse
module loaded, you can:

	* insert inline Perl with the <perl></perl> tags and access server
	  internals

Preparsing is done only on files with extensions .sht, .shtm and .shtml, 
unless you say otherwise.

Because this runs as the UID of the webserver, this can be a VERY BIG security
hole if enabled with the user filesystem. Enable only if you really trust
your users, or if you will be the sole person creating content for HTTPi (or
if you're running HTTPi as some unprivileged user that can't do anything
antisocial). Enable only under severe, serious advisement!

For information on how to program with inline Perl, see the programming manual.

Enable preparsing?
EOF
$DEF_MPREPARSE = ($q eq 'y') ? 1 : 0;
unless ($DEF_MPREPARSE) {
	print <<"EOF";
You said no preparsing, so I won't ask you any more questions about that.
Neener, neener; et la neener. That's French for phooey on you.

EOF
} else {
	$q = &prompt(<<"EOF", "n", 1);
You may have all HTML files, or just ones with the .sht, .shtm or .shtml
extensions preparsed for inline Perl. Preparsing is not that big of a
performance hit, but you may not want it occurring everywhere just the same,
so the default only parses .sht, .shtm and .shtml.

Parse all HTML files?
EOF
	$DEF_PREGEXPA = ($q eq 'y') ? '?' : '';
#	$DEF_PREGEXPB = ($q eq 'y') ? '' : '?';
}

# leave alone
1;

