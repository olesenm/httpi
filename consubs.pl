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
	local($infile, $outfile, $fatal) = (@_);
	local $ifl, $def, $j;
	open(S, "$infile") || (print($fatal), exit);
	open(T, ">$outfile") || (print($fatal), exit);

	$ifl = 0;
	while(<S>) {
		if (/^~check/) {
			chomp;
			(/^~check (.+)$/) && ($def = $1);
			eval "\$j = \$DEF_$def;";
			if ($j) {
				$ifl = -2;
			} else {
				$ifl = 1;
			}
			next;
		}
		if (/^~/) {
			$ifl = abs($ifl);
			$ifl--;
			next;
		}
		next if ($ifl > 0);
		while((/(DEF_[A-Z_]+)/) && ($def = $1)) {
			eval "s/DEF_[A-Z_]+/\$$def/";
		}
		print T $_;
	}
	close(S);
	close(T);
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
			push(@answers, $_);
		}
		close(P);
		print "Loaded responses from $ARGV[1].\n\n";
		$DEFAULT = 2;
	}
}

unless ($DEFAULT) {
	$p=0; while(-e "transcript.$p.$0") { $p++; }
	open(L, ">transcript.$p.$0") || (print(<<"EOF"), exit);

Can't open transcript file transcript.$p.$0 for write.
Check your permissions on that file or directory.

EOF
	select(L); $|++; select(stdout);
}

1;

