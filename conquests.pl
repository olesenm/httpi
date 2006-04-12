$HOSTNAME = &wherecheck('Finding hostname', 'hostname');
$DEF_MCANALARM = &yncheck('Can we use alarm()?', 'alarm 0;');
unless ($DEF_CANFORK) {
$DEF_CANFORK = $q = &yncheck("Can we fork()?",
        'if ($pid = fork()) { waitpid($pid,0); } else { exit; }');
}
$DEF_CANDOSETRUID = &yncheck("Can we use setruid()?",
	'$q = $<;$< = 65534;$< = $q;');
&prompt(<<"EOF", "") if (!$DEF_MCANALARM);
Let me guess. You're not using a Unix Perl.

alarm() is no longer required for install, but you should be warned that it
allows better process control, which reduces the chance of system overload.

More importantly, if you intend to use inetd HTTPi on a system that times
inetd processes out if sockets remain open, you will be running a very
unstable server without alarm() support. (This is only an issue with inetd
HTTPi, not Demonic or xinetd HTTPis.)

You can still install HTTPi, but consider running this on a system that
supports alarm() in its Perl port.

Press RETURN or ENTER to continue.
EOF

&prompt(<<"EOF", "");
Cool, we made it that far.

Now you'll need to answer a few questions about your installation options
and some functions that need to be hard-coded into HTTPi. If you just hit
RETURN/ENTER with nothing entered, the default (in [ ]) will be selected.

Answering questions incorrectly, or giving the configure script nonsense or
gibberish (like alpha where a number is expected), will undoubtedly give
you a defective executable. If it parses, it will probably not work quite
right. Common sense is a virtue :-)

Press RETURN or ENTER to continue.
EOF

$INSTALL_PATH = &prompt(<<"EOF", "/usr/local/bin/httpi", 1);
Where do you want the resultant script placed? If you're using configure to
build multiple instances of HTTPi on different ports, make sure this changes
unless you're darn certain that they'll all be configured the same way.
IF YOU'RE USING CONFIGURE TO BUILD MULTIPLE INSTANCES OF HTTPi ON MULTIPLE
IP ADDRESSES (xinetd/Demonic only), THIS *MUST* BE DIFFERENT IN EACH CASE!

WARNING TO xinetd/inetd INSTALLERS: If you are doing a full install to update
(x)inetd's config files simultaneously, THIS MUST BE AN ABSOLUTE PATH!

Install path?
EOF

$q = ($PERL_VERSION >= 5.008) ? 'y' : 'n';
if ($HAS_POSIX) {
	$DEF_MUSEPOSIX = (&prompt(<<"EOF", $q, 1) eq 'y') ? 1 : 0;
As a reminder, you do have POSIX.pm, and the Perl you've decided to build
HTTPi with is version $PERL_VERSION, which is capable of using sigaction().
Let's talk signals.

On Perls 5.005, 5.6 ("5.006") and prior to 5.8, POSIX sigaction() didn't work
properly (if at all). Those systems should continue to use the \$SIG method
of signal handling, which is technically unsafe but mostly functional.

On Perls 5.8 ("5.008") and higher, sigaction() not only works, but works
better than the old \$SIG method for HTTPi's purposes and may be required in
future Perls for HTTPi's signal handling to work at all. You should only use
\$SIG in this case if you are building HTTPi for another system with an older
or impoverished Perl. If that Perl lacks POSIX.pm, consider setting the
environment variable PERL_SIGNALS to 'unsafe' for the previous behaviour.
If you answer 'n' then this will be added to HTTPi for you.

The recommended default for your version of Perl is given, but you can
override it here. If you don't know what to do, choose the default.

Use sigaction()/POSIX.pm for signal handling?
EOF
} else {
	$q = ($q eq 'y') ?
"Because your Perl version is >= 5.8.0 and you don't have any other solution,"
:
"Although you don't need it right now, if you move HTTPi to a Perl >= 5.8.0"
;
	&prompt(<<"EOF", "");
Your system is unable to use sigaction-based signals (no POSIX.pm), although
recent Perls (>= 5.8.0) may benefit strongly from it -- you are using version
$PERL_VERSION. Using \$SIG-based signaling instead.

$q
consider setting the environment variable PERL_SIGNALS to 'unsafe' for the
previous behaviour, which is considered poor form, but will probably work.
This will be added to HTTPi for you.

Press RETURN or ENTER to continue.
EOF
}

unless ($DEF_MDEMONIC) {
	$DEF_AF_INET = &prompt(<<"EOF", 2, 1);
In an effort to make non-Demonic HTTPi less Unix-oriented (you decide if this
actually helps any), the one item in HTTPi that used to be a hardcoded
network constant now actually makes an effort to be portable. If you know
that your system's AF_INET macro is something other than two, enter it here.
(I have yet to find an OS where it wasn't, but I'm sure they're out there,
although it was 2 on AIX, Darwin/OS X, SCO, HP/UX, Solaris, NetBSD and Linux.) 

If you don't know what this is, accept the default -- it's probably correct.

Demonic already gets this information in other ways, so its configure script
doesn't need to ask (besides, it's pretty Unix-centric as it is anyhow).

System AF_INET constant (nearly invariably 2)?
EOF
}
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

The settings for the restriction matrix are hardcoded into uservar.in, and
to change your settings you must edit that file and rebuild HTTPi. For help,
please refer to the user's manual.

Enable restriction matrix?
EOF
$DEF_MRESTRICTIONS = ($DEF_MRESTRICTIONS eq 'y') ? 1 : 0;

$bleh = &prompt(<<"EOF", "2", 1);
Webserver logs are a pain, particularly when they get lengthy.

Logging format 1 (here a more CERN compliant variant) was what was supported
in the earliest versions of HTTPi:

host - - [CERNdate] "METHOD address HTTP/V.v" returncode contentlength\\
	 "referer" ""
(example: stockholm.floodgap.com - - [31/Jan/1969:00:00:00] "GET / HTTP/1.0"
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

$DEF_REV_RESOLVE = "gethostbyaddr";
$DEF_MABSOLVER = 0;
$DEF_TO_ABSOLVER = 0;
if ($DEF_MHOSTNAMES) {
	$DEF_MANTISPOOF = (&prompt(<<"EOF", "n", 1) eq 'y') ? 1 : 0;
Since you're resolving hostnames, I'm sure you've seen the phenomenon of some
sites having bad or even fradulent PTRs when trying to reverse-resolve an
address. This minor anti-spoof feature makes all hostnames into the form
hostname/ip.address.of.hostname (example: localhost/127.0.0.1) so that you
can independently see the IP address. If the IP cannot reverse resolve, then
you get a doublet (example: 99.99.99.256/99.99.99.256).

I've found this handy for accounting, but this might break some loggers
or executables expecting a resolvable name, so this option defaults to no.
This will also affect the REMOTE_HOST CGI variable. REMOTE_ADDR is unchanged.

Always use name/address syntax for reverse resolved names?
EOF
	if ($DEF_MCANALARM) {
		$q = &prompt(<<"EOF", "n", 1);
Since your Perl has the alarm() call -- and it might even work -- you can make
reverse lookups more reliable (even when the result you get back is fradulent)
instead of having HTTPi pause on bad or defective DNS servers. This defines a
new subroutine &absolver which kills lagging DNS queries after five seconds.
Without it, you are at the mercy of the timeout specified by your operating
system's implementation (but this may be perfectly adequate, so this option
defaults to no). If you're concerned about this, test reliability both ways.

Use DNS "absolver" for reverse queries?
EOF
		if ($q eq 'y') {
			$DEF_REV_RESOLVE = "absolver";
			$DEF_MABSOLVER = 1;
			$DEF_TO_ABSOLVER = &prompt(<<"EOF", "7", 1);
Your sins are absolved, my son.

How fast do you want the absolver to kill queries? Making this too fast may
have consequences for your log files, as it may take a few requests for a
name to be reverse-resolved. On the other hand, HTTPi will wait patiently
for a response and this may impair performance if set too slow. Five to eight
seconds seems good for well-connected hosts with reasonably reliable DNS. You
may need to tweak this for your locality/network environment.

Setting this to zero means there is NO limit, so don't do that unless you're
weird or something.

Timeout for DNS "absolver" reverse queries (in seconds)?
EOF
		} else {
			print "Not absolved. Confess your sins later.\n\n";
		}
	} else {
		print <<"EOF";
You don't have alarm(), so let's hope your operating system DNS timeouts
are reasonable or this could hang your server on bad queries.

EOF
	}
}

$q = &prompt(<<"EOF", "n", 1);
HTTPi 0.99 and up can do IP-less virtual hosting by redirecting host
aliases to addresses. For example, you might define (as I do) the alias
httpi.floodgap.com to point to http://www.floodgap.com/httpi/.

This is useful for large hosting sites and aliases, but probably not for
HTTPi's prototypical usage of a little server on a little system, so it's
not enabled by default. If your HTTPi supports it (both xinetd and Demonic
do), you may wish to consider IP-based virtual hosting where you can do
multihoming with individual HTTPi processes as an alternative.

The settings for IP-less virtual hosting are hardcoded into uservar.in, and
to change your settings you must edit that file and rebuild HTTPi. For help,
please refer to the user's manual.

Enable host name redirects?
EOF

$DEF_NAMEREDIR = (($q eq 'y') ? 1 : 0);

$q = &prompt(<<"EOF", "y", 1);
The New Security Model, introduced in 1.4, adds a additional level of control
over how files are served.

In the older model, HTTPi only changed uid for executables. In this model,
HTTPi changes uid for *all* files, meaning even preparsed documents cannot
take over the webserver. Furthermore, you can specify a uid for which it and
all UIDs lower, is illegal: the server will not change uid to them, and will
not, as a consequence, serve files owned by them (root uid is always illegal)
or run executables on behalf of them (again, root uid is always illegal too).
Other consequences exist -- PLEASE READ THE DOCUMENTATION FIRST.

The New Security Model is ONLY SALIENT IF YOU RUN HTTPi AS ROOT. Otherwise,
it simply adds bulk and overhead.

As of 1.5, the New Security Model is now well-tested enough that it is the
strongly recommended default. It may break old installations, so the choice
is still offered, but if you use the user filesystem or preparsing and you
are running your server as root, it is strongly recommended.

Use the New Security Model?
EOF
$DEF_MNSECMODEL = (($q eq 'y') ? 1 : 0);
if ($DEF_MNSECMODEL) {
	$DEF_NSECUID = &prompt(<<"EOF", 1, 1);
Specify the *lowest* UID that is ALLOWED to serve files. For example, consider
this hypothetical /etc/passwd file (crypts and uids changed to protect the
guilty^Winnocent):

root:xyzPDQ12:0:0:The Root of All Evil:/doom:/usr/local/bin/mammonsh
daemon:xyzPDQ12:1:1::/etc:
bin:xyzPDQ12:2:2::/bin:
sys:xyzPDQ12:3:3::/usr/sys:
adm:xyzPDQ12:4:4::/var/adm:
ftp:xyzPDQ12:100:100:FTP User:/home/ftp:/bin/false
www:xyzPDQ12:500:500:Webmaster Goddess:/usr/local/htdocs:/usr/local/bin/tcsh
joeuser:xyzPDQ12:501:501:Joe User:/home/joeuser:/usr/local/bin/tcsh

Presumably, we only want www and joeuser to serve files, so we specify
uid 500 so that no UID of 499 or lower will be permitted, even users that
haven't been created yet. AGAIN, THIS IS ONLY RELEVANT IF YOU ARE RUNNING
HTTPi as ROOT! Also note that root can NEVER serve files, so specifying zero
as the minimum UID is meaningless.

Lowest UID to serve files (FYI: your euid is $>)? 
EOF
}

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

If you have the New Security Model on, *and* you're running as root, HTTPi
will also change its UID to match the document's, which is useful for
protecting things like /etc/passwd, and for preparsing.

Enable user filesystem?
EOF
	$DEF_MUSERFS = ($q eq 'y') ? 1 : 0;
}

$q = &prompt(<<"EOF", "n", 1);
HTTPi now enables preparsing of selected content types. With the new preparse
module loaded, you can insert inline Perl with the <perl></perl> tags and
access server internals.

Preparsing is done only on files with extensions .sht, .shtm and .shtml, 
unless you say otherwise.

UNLESS YOU HAVE THE NEW SECURITY MODEL ON *AND* YOU'RE RUNNING HTTPi AS ROOT,
preparsing runs as the UID of the webserver and this can be a *huge* security
hole if enabled with the user filesystem. Enable only if you really trust
your users, or if you will be the sole person creating content for HTTPi (or
if you're running HTTPi as some unprivileged user that can't do anything
antisocial) -- under severe, serious advisement!

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

$q = &prompt(<<"EOF", "n", 1);
Now that I actually pay for my bandwidth, I've become a lot more jealous of
it, which is the rationale for building in a primitive throttling facility.

Primitive means exactly that; you are only guaranteed an approximate maximum
K/sec rating, and even then it's not smooth or well-conditioned. However, it
was easy to implement and it does work. Please note that the throttle settings
are PER PROCESS INSTANCE, not per server en toto.

You may specify how many bytes to suck in and spit out at a swallow, and
how long said swallows take (so, 32,768 bytes and 1 second wait time means,
roughly, 32K/sec maximum output rate per process instance).

Throttling does not yet apply to executable output, virtual file output,
or preparsed file output. These omissions, however, may be useful for
finer-grained throttle control. See the manual for more information.

With throttling off, HTTPi spews files as fast as it can, subject to network
and connection speed.

Use throttling?
EOF
$DEF_MTHROTTLE = ($q eq 'y') ? 1 : 0;
unless ($DEF_MTHROTTLE) {
	print "Hmm, bandwidth leeches ahoy, eh? ;-)\nSkipping onward ...\n\n";
	$DEF_READBUFFER = 32768;
	$DEF_THROTWAIT = 0;
} else {
	$DEF_READBUFFER = &prompt(<<"EOF", "32768", 1);
How much to consume at one gulp? Remember, larger numbers mean larger
HTTPi, but mean faster throughput, so make your decision based on how
practical you want large transfers to be.

The default is 32K, which is good for most sites. Entering multi-megabytes
here is probably silly and unnecessary, but the option is offered anyway.
ENTER THIS NUMBER IN BYTES, NOT KILOBYTES, NOT MEGABYTES, NOT GIGABYTES!
(Remember, 1MB = 1024KB = 1048576 bytes; 1K = 1024 bytes)

Enter a higher number like 32768 or 65536 for 32K and 64K respectively,
which may be appropriate for bigger LANs, or your private internal network.

Number of bytes to consume per gulp?
EOF
	$DEF_THROTWAIT = &prompt(<<"EOF", "1", 1);
How long to wait between gulps? If you're pathological, or want your
bandwidth usage curves to decline really fast by setting the 'bytes per
gulp' high and this high as well, you can set this to two or more seconds.
Otherwise, waiting one second between gulps is usually plenty, and is as
granular as this gets. There are reasons for being weird with this (see the
manual).

Since this uses 'sleep' to achieve its voodoo, it is subject to all the
limitations thereof, including that it may not sleep the complete time
given, *and* most implementations that I know of do not support fractions.

If you enter 1 here (the default), then your theoretical max throughput is
bytes per gulp/sec (so using default for both, you get 32K/sec per
individual process instance).

Gulp delay (in seconds)?
EOF
}
	
if ($DEF_MCANALARM) {
	$q = &prompt(<<"EOF", "n", 1);
Now the ugly kludge section. This is really only relevant to inetd users, but
this option may be occasionally useful to Demonic and xinetd installs.

Some inetds will time out, and then shut down, services that hold sockets
open for longer than a critical period of time (some Linux inetds are most
notorious). This usually happens when a very large file is being downloaded
over a very slow link. The upshot is, HTTPi will be turned off by inetd and
fail to respond to requests until inetd gets another -HUP signal. This might
be the basis of a nasty DoS attack, so here it is as a configure option.
HTTPi will simply kill the link if too much time passes, and save itself, if
this option is enabled. You can adjust the timeout with the next question.
You might also want to enable this if you get besieged with requests that
just hang sockets up on your system, but you don't need it if you're not
running inetd HTTPi.

Note that many inetds will not require this (AIX and HP/UX don't seem to).
Don't turn it on unless you think it's necessary for your OS or security.

This may have interesting interactions with the throttling option, by the way.

Auto-kill the link on slow data transfers?
EOF
	$DEF_MAUTOKILL = ($q eq 'y') ? 1 : 0;
	if ($DEF_MAUTOKILL) {
		$DEF_AK_TIMEOUT = &prompt(<<"EOF", "25", 1);
Enter the timeout (in seconds) before HTTPi should auto-kill the link. This
is system dependent. Some inetds will kick HTTPi down after as little as
thirty seconds but most are usually up to sixty. Tune this to whatever seems
to give the best performance and stability, which usually is five or ten
seconds before inetd will actually close the port down.

If this is just for security purposes, set it to whatever you like. Sixty
seconds seems good for not-too-busy sites with not-too-big files.

Remember, throttling may cause unusual interaction if this is set too low.

Auto-kill timeout?
EOF
	} else {
		print <<"EOF";
Murderous tendencies quelled.

EOF
	}
} else {
	print <<"EOF";
You don't support alarm(), so I can't give you the ugly kludge for keeping
inetd HTTPis stable on certain platforms (notably some Linux inetds) even
though you might need it.

EOF
}
# leave alone
1;

