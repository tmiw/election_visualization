#!/usr/bin/perl -w

# NYTimes election results to CSV converter
# Copyright (C) 2010 Mooneer Salem <mooneer@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
#    * Redistributions of source code must retain the above copyright notice, this 
#      list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice, 
#      this list of conditions and the following disclaimer in the documentation 
#      and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.

use strict;
use POSIX qw/strftime/;
use LWP::Simple;

# List of URLs to fetch per run.
my %races =
    ( 
        "House" => "http://elections.nytimes.com/2010/results/house/big-board",
        "Senate" => "http://elections.nytimes.com/2010/results/senate/big-board",
        "Governor" => "http://elections.nytimes.com/2010/results/governor/big-board",
    );

# Main scraping logic: split into individual CSV lines.
sub results_to_csv
{
    my ($key, $urlOutput, $startTime) = @_;
    
    my (@raceNames) = $urlOutput =~ m@<td class="nytint-state-col"><a.*?>([^<]+)</a></td>@gs;
    my (@demPercent) = $urlOutput =~ m@<td class="nytint-big-board-entry nytint-pct nytint-pct-dem">.*?(\d+%|Unc\.).*?</td>@gs;
    my (@gopPercent) = $urlOutput =~ m@<td class="nytint-big-board-entry nytint-pct nytint-pct-gop">.*?(\d+%|Unc\.).*?</td>@gs;
    my (@othPercent) = $urlOutput =~ m@<td class="nytint-big-board-entry nytint-pct nytint-pct-oth">.*?(\d+%|Unc\.).*?</td>@gs;
    
    for (my $i = 0; $i < $#raceNames; $i++)
    {
        print "$key," . $raceNames[$i] . "," . $demPercent[$i] . "," . $gopPercent[$i];
        if ($#othPercent == $#raceNames)
        {
            print "," . $othPercent[$i];
        }
        else
        {
            print ",N/A";
        }
        print ",$startTime\n";
    }
}

# Get start time of run.
my $startTime = strftime('%D %T',localtime);
 
# Main loop: fetch each of these URLs and run processing logic on results.
foreach my $key (keys %races)
{
    my $urlOutput = get($races{$key});
    results_to_csv($key, $urlOutput, $startTime);
}