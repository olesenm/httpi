$version_key = "HTTPi/1.3";
$my_version_key = 0;
$ACTUAL_VERSION = "1.3.2";

sub yncheck {
	local ($prompt, $evals, $fatal) = (@_);
	local $setv;

	print stdout "$prompt ... ";
	eval $evals;
	if (!$@) {
		print "yes\n"; $setv = 1;
	} else {
		chomp($q = $@);
		print "no ($q)\n"; $setv = 0;
		(print($fatal), exit) if ($fatal);
	}
	return $setv;
}

sub wherecheck {
	local ($prompt, $filename, $fatal) = (@_);
	local(@paths) = split(/\:/, $ENV{'PATH'});
	unshift(@paths, '/usr/bin'); # the usual place
	@paths = ('') if ($filename =~ m#^/#); # for absolute paths
	local $setv = 0;

	print stdout "$prompt ... ";
	foreach(@paths) {
		if (-r "$_/$filename") {
			$setv = "$_/$filename";
			1 while $setv =~ s#//#/#;
			print "$setv\n";
			last;
		}
	}
	if (!$setv) {
		print "not found.\n";
		(print($fatal),exit) if ($fatal);
	}
	return $setv;
}

sub preproc {
	local ($mf) = (@_);
	local $kvbuf, $ifl;

	$ifl = 0;
	while(<$mf>) {
		chomp;
		if (/^~$/) {
			next if (!$ifl);
			$ifl = abs($ifl);
			$ifl--;
			next;
		}
		next if ($ifl > 0);
		if (/^~check/) {
			(/^~check (.+)$/) && ($def = $1);
			eval "\$j = \$DEF_$def;";
			if ($j) {
				$ifl = -2;
			} else {
				$ifl = 1;
			}
			next;
		}
		if (/^~insert/) {
			(/^~insert (.+)$/) && ($def = $1);
			open(Q, $def) || (print(stdout <<"EOF"), exit);

COMPILATION FAILURE: Could not include file $def.
($@ $!)

EOF
			$kvbuf .= &preproc(\*Q);
			close(Q);
			next;
		}
		while((/(DEF_[A-Z_]+)/) && ($def = $1)) {
			eval "s/DEF_[A-Z_]+/\$$def/";
		}
		$kvbuf .= "$_\n";
	}
	return $kvbuf;
}

sub prompt {
	local($prompt, $default, $dontcare) = (@_);
	local $entry;

	if (!$DEFAULT) {
		chomp $prompt;
		print stdout "$prompt [$default]: ";
		chomp($entry = <STDIN>);
		$entry = (length($entry) ? $entry : $default);
	} else {
		return if (!$dontcare);
		$entry = $default if ($DEFAULT == 1);
		$entry = shift(@answers) if ($DEFAULT == 2);
	}
	print <<"EOF" unless ($entry eq '');

$entry selected.

EOF
	printf(L "%s\n", $entry) if ($dontcare && !$DEFAULT);
	return $entry;
}			

if ($ARGV[0] =~ /^--?d/) {
	print <<"EOF";
** DEFAULT MODE ENABLED ** -- $0 will autoconfigure everything!
(Installation questions relevant to inetd or xinetd will not be asked, if any.)
HIT CTRL-C NOW IF THIS IS NOT WHAT YOU WANT!

EOF
	sleep 1;
	$DEFAULT = 1;
	if (-e $ARGV[1]) {
		open(P, "$ARGV[1]");
		while(<P>) {
			chomp;
			if (!$my_version_key) {
				$my_version_key = $_;
				if ($my_version_key ne $version_key) {
					$my_version_key =
						"0.99 or earlier"
						if ($my_version_key !~
							/^HTTPi/);
					print <<"EOF";
Whoops, screeching halt time, bud.

This is a transcript file from an earlier and incompatible HTTPi configure
sequence (looks like version $my_version_key).

Since the question sequence and possible choices have changed, the responses
you gave in this transcript file are no longer valid. Please start over and
run $0 from scratch.

EOF
					exit;
				}
				next;
			}
			push(@answers, $_);
		}
		close(P);
		print "Loaded responses from $ARGV[1].\n\n";
		$DEFAULT = 2;
	}
}

unless ($DEFAULT) {
	($0 =~ m#/?([^/]+)$#) && ($f = $1);
	$p=0; while(-e "transcript.$p.$f") { $p++; }
	open(L, ">transcript.$p.$f") || (print(<<"EOF"), exit);

Can't open transcript file transcript.$p.$f for write.
Check your permissions on that file or directory.

EOF
	select(L); $|++; select(stdout);
	print L "$version_key\n";
}

1;

