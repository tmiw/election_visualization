#!/usr/bin/perl -w

# San Diego County election results to SQL converter
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
use XML::Simple;
use DBI;

our $dsn;
our $db_user;
our $db_password;
require "db_config.pl";

# List of URLs to fetch per run.
my %races =
    ( 
        "SD County Ballot Measures" => "http://www.sdcounty.ca.gov/voters/results/election.xml",
    );

# Connect to database here.
my $db_conn = DBI->connect($dsn, $db_user, $db_password)
    or die "Can’t connect to the DB: $DBI::errstr\n"; 

# Fetch race associations.
my %race_ids = ( );
my $sth = $db_conn->prepare("SELECT * FROM election_race_type");
$sth->execute();
while(my($id, $type) = $sth->fetchrow_array())
{
    $race_ids{$type} = $id;
}

# Main scraping logic: split into individual queries.
sub results_to_sql
{
    my ($key, $urlOutput, $startTime, $db_conn, $race_id) = @_;
   
    my ($xmldoc) = (XML::Simple->new())->XMLin($urlOutput);

    foreach my $key (keys (%{$xmldoc->{SUMMARY}->{CONTEST}}))
    {
        my ($yes, $no);
        my $name = $xmldoc->{SUMMARY}->{CONTEST}->{$key}->{title};
        my $query = "";

        foreach my $candidate (keys (%{$xmldoc->{SUMMARY}->{CONTEST}->{$key}->{CANDIDATE}}))
        {
            $yes = $xmldoc->{SUMMARY}->{CONTEST}->{$key}->{CANDIDATE}->{$candidate}->{pct}
                if ($candidate eq "YES");
            $no = $xmldoc->{SUMMARY}->{CONTEST}->{$key}->{CANDIDATE}->{$candidate}->{pct}
                if ($candidate eq "NO");
        }
        
        next if ($name !~ /^PROP [A-Z]/);

        # Grab if already exists.
        $query = "SELECT democrat_percent, gop_percent, ind_percent FROM election_result WHERE race_type='$race_id' AND race_name='$name'";
        $sth = $db_conn->prepare($query);
        $sth->execute;
        my $found = 0;
        while (my @row = $sth->fetchrow_array())
        {
            $found = 1;
            if (($row[0] != $yes) or ($row[1] != $no))
            {
                $query = "UPDATE election_result SET democrat_percent=$yes, gop_percent=$no, ind_percent=0, last_update='$startTime'";
                $query .= " WHERE race_type='$race_id' AND race_name='$name'";
                $db_conn->prepare($query)->execute();
            }
            last;
        }
        
        if ($found == 0)
        {
            $query = 'INSERT INTO election_result (race_type, race_name, democrat_percent, gop_percent, ind_percent, last_update)';
            $query .= " VALUES ($race_id, '$name', $yes, $no, 0, ";
            $query .= "'$startTime') ";
            $db_conn->prepare($query)->execute();
        }
    }
}

# Get start time of run.
my $startTime = strftime('%Y-%m-%d %T',localtime);
 
# Main loop: fetch each of these URLs and run processing logic on results.
foreach my $key (keys %races)
{
    my $urlOutput = get($races{$key});
    results_to_sql($key, $urlOutput, $startTime, $db_conn, $race_ids{$key});
}
