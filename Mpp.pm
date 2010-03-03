use strict;    # -*- Perl -*-
package Mpp;
# ---------------------------------------------------------------------------
# Mpp - Mark's Mini-Pre-Processor
# Copyright (c) 2010 Mark Olesen. All rights reserved.
#
# permission granted for inclusion in HTTPi and for distribution under
# the Floodgap Free Software License
# ---------------------------------------------------------------------------
#
# This implementation has been kept deliberately simple for the current
# purposes.
#
# ---------------------------------------------------------------------------

sub new {
    bless {
        curr => 0,    # current logic level
        prev => 0,    # previous logic level
        exec => 0,    # logic level at which we should exec
    } => $_[0];
}

# ---------------------------------------------------------------------------

#
# test if variable is defined
#
sub isDefined {
    my $self = shift;
    my $def  = shift;

    # for httpi - using global DEF_xxx variables
    # otherwise use tied hashes, etc
    my $n = 0;
    eval qq{\$n += \$::DEF_$def;};
    return $n;

    # # for httpi - using global %DEF hash
    # exists $::DEF{$def};
}


#
# expand macros in the $_ variable
#
sub expandMacros {
    my $self = shift;

    # for httpi - using global DEF_xxx variables
    # otherwise use tied hashes, etc
    while (/(DEF_[A-Z_]+)/) {
        my $def = $1;
        eval qq{s/$def/\$::$def/};
    }

    # # for httpi - using global %DEF hash
    # while (/DEF_([A-Z_]+)/) {
    #     my $def = $1;
    #     exists $::DEF{$def} or die "attempt to substitute an undefined value for DEF_$def\n";
    #     s/DEF_$def/$::DEF{$def}/;
    # }
}


#
# include( file )
#
# return processed file as a string
#
sub include {
    my $self = shift;
    ref $self or $self = $self->new(); ## allow use as a static method

    my ($filename) = @_;

    ## warn "process: $filename\n";

    my $contents = '';

    # older Perl versions cannot handle lexical variables for open
    # thus use localized variables

    local *INCLUDE;
    open INCLUDE, $filename
      or warn "Can't open $filename: $!\n"
      and return $contents;

    ## warn "logic prev:curr:exec\n";

    #
    # process each line
    local $_;
    GETLINE: while (<INCLUDE>) {

        ## strip comments
        if (/^~#/)
        {
            next GETLINE;
        }

        ## warn "line ", join (":" => @{$self}{qw(prev curr exec)}), " : $_";

        ## change logic state
        if (/^~(?:if|endif|else|els?if)/)
        {
            s{\s*~#.*}{};   ## strip trailing comments too

            my $test = '';

            if (/^~endif/) {
                ## match 'endif' ... ignore all trailing junk
                if ( $self->{curr} == $self->{exec} ) {
                    $self->{exec}--;
                    $self->{prev} = $self->{exec}; # pull down prev as well
                }

                $self->{curr}--;
                if ($self->{prev} > $self->{curr})
                {
                    $self->{prev} = $self->{curr};
                }

                next GETLINE;
            }
            elsif (s/^~((?:els?|else\s*)?if(?:n?def)?)(.*?)\s*$/$1/) {
                ## match 'if', 'ifndef', 'ifdef' and 'elif..'
                ## allow 'elif', 'elsif', 'elseif' and 'else if'

                # test required, supply default value
                # drop through to next sectionsx
                ( $test = $2 ) =~ s/^\s+(.+?)$/$1/ or $test = 0;

                s{\s*~#.*}{};   ## strip trailing comments too
            }
            elsif (s/^~(else).*$/$1/) {
                ## strip all trailing junk from 'else'
            }

            if (/^el/) {
                ## else, elif, ...
                if ( ( $self->{curr} == $self->{exec} + 1 )
                    and $self->{curr} != $self->{prev} )
                {
                    ## We are in position to execute
                    if (/^else$/) {    # simple 'else'
                        $self->{exec} = $self->{curr};
                        next GETLINE;
                    }

                    $self->{curr}--;         # now == to exec level
                    s/(?:els?|else\s*)//;    # change elif.. -> if.. for testing
                                             # drop through to 'if..' testing
                }
                else {
                    if ( $self->{curr} == $self->{exec} ) {
                        $self->{exec}--;
                    }
                    next GETLINE;
                }
            }

            ## testing:
            if (/^if(n)?def$/) {             # ifdef ifndef
                my $truth = $1 ? 0 : 1;

                if ( $self->{curr} != $self->{exec} ) {
                    ## Not interested - skip test
                    $self->{curr}++;
                }
                else {
                    $truth = ( $truth == ( $self->isDefined($test) ? 1 : 0 ) );

                    $self->{curr}++;
                    if ($truth) {
                        $self->{exec} = $self->{prev} = $self->{curr};
                    }
                }
            }

            next GETLINE;
        }

        $self->{curr} == $self->{exec} or next GETLINE;    ## too deep anyhow

        ## include <name>
        ## include "name"
        if ( my ($arg) = /^~include \s+ [<\"] ([^<>\"]+) [\">] \s*$/x ) {
            $contents .= $self->include($arg);
            next GETLINE;
        }

        $self->expandMacros();
        $contents .= $_;
    }

    close INCLUDE;    # close old filehandle
    return $contents;
}

1;  # okay loaded

# ------------------------------------------------------------ end-of-file
