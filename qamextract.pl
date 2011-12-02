#!/usr/bin/perl -w
# Robert Kulagowski
# qam-info@schedulesdirect.org
# qamextract.pl

# This program is used to extract the QAM information from an
# already-configured MythTV system.  It will allow a user to share what they
# have already determined to be a known-good QAM scan for their lineup.

use strict;
use warnings;
use DBI;
use Getopt::Long;

my $version = 0.03;
my $date = "2011-12-01";
my ($help, $myth, $dbh, $query, $sth, $lineupid, $sourcename);
my $sourceid = -1;
my $qam_frequency = "000000000";

eval 'require MythTV';
if ($@) {
    print "\n\nFatal error: MythTV.pm module not installed, exiting.\n";
    exit;
}

# Set $debugenabled to 0 to reduce output.
my $debugenabled=0;

GetOptions ('debug' => \$debugenabled,
            'sourceid:i' => \$sourceid,
            'help|?' => \$help);

if ($help) {
  print "\nqamextract.pl v$version $date\n" .
        "This script supports the following command line arguments." .
        "\n--debug      Enable debug mode.  Prints additional information " .
        "\n             to assist with troubleshooting." .
        "\n--sourceid   Which sourceid to use." .
        "\n--help       This screen.\n" .
        "\nBug reports to qam-info\@schedulesdirect.org\n\n";
  exit;
}

$myth = new MythTV();

$dbh = $myth->{'dbh'};

if ($sourceid == -1) {
    print "This system has the following sources:\n";
    print "Sourceid\t Name\n";
    $query = "SELECT sourceid, name from videosource;";
    $sth = &query( $dbh, $query );
    my ($source, $name);
    my $i=0;
    while ( ($source,$name) = $sth->fetchrow_array() ) {
        print "$source\t\t $name\n";
        $i++;
        # Save the sourceid in case we only go through the loop once.
        $sourceid = $source;
    }

    if ($i > 1) {
        print "Select sourceid: ";
        chomp ($sourceid = <STDIN>);
    }
if ($debugenabled) { print "sourceid is $sourceid\n"; }
}

$query = "SELECT lineupid from videosource where sourceid=$sourceid;";
$sth = &query( $dbh, $query );

my @row=$sth->fetchrow_array;
($lineupid) = @row;

open MYFILE, ">", "$lineupid.qam.conf";

$query = "SELECT channum, callsign, xmltvid, mplexid, serviceid FROM channel where sourceid=$sourceid;";
$sth = &query( $dbh, $query );

# Get the rows
while( my @row=$sth->fetchrow_array ) {
    my ($channum, $callsign, $xmltvid, $mplexid, $serviceid) = @row;

    my $sth1 = &query($dbh, "SELECT frequency from dtv_multiplex where mplexid=$mplexid;");

    while( my @row1=$sth1->fetchrow_array ) {
        ($qam_frequency) = @row1;
    }

    print MYFILE "$callsign:$qam_frequency:QAM_256:$channum:$xmltvid:$serviceid\n";
}

$dbh->disconnect;
close (MYFILE);

print "\nDone. ";

if ($qam_frequency eq "000000000") {
    print "Did not find any QAM frequency information in this source! $lineupid.qam.conf file " .
    "may be invalid.\n";
}
else {
    print "Please send $lineupid.qam.conf file to qam-info\@schedulesdirect.org\n";
}

exit;

# Subroutine

sub query(){
    # executes query on a connected database
    # exits on error or returns the statement handle
    my ( $dbh, $query ) = @_;
    my $sth = $dbh->prepare($query);
    if (!($sth->execute)) {
        print "Fatal error in local sub query. Could not execute ($query): $!\n";
        exit;
    }
    return $sth;
}
