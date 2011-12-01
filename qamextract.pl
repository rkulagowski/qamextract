#!/usr/bin/perl -w
# Robert Kulagowski
# qam-info@schedulesdirect.org

use strict;
use warnings;
use DBI;
use Getopt::Long; # Command Line Interface options

my $version = 0.01;
my $date = "2011-12-01";
my $help;
my $sourceid;
my $qam_frequency;

eval 'require MythTV';
if ($@) {
    print "\n\nMythTV.pm module not installed.\n";
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
        "\n             to assist with any issues." .
        "\n--sourceid   Which sourceid to use." .
        "\n--help       This screen.\n" .
        "\nBug reports to qam-info\@schedulesdirect.org\n\n";
  exit;
}

my $myth = new MythTV();

my $dbh = $myth->{'dbh'};

my $query = "SELECT channum, callsign, xmltvid, mplexid, serviceid FROM channel where sourceid=$sourceid;";
my $sth = &query( $dbh, $query );

# Get the rows
while( my @row=$sth->fetchrow_array ) {
    my ($channum, $callsign, $xmltvid, $mplexid, $serviceid) = @row;
    my $sth1 = &query($dbh, "SELECT frequency from dtv_multiplex where mplexid=$mplexid;");

    while( my @row1=$sth1->fetchrow_array ) {
        ($qam_frequency) = @row1;
    }

    print "$callsign:$qam_frequency:QAM_256:$channum:$xmltvid:$serviceid\n";
}

$dbh->disconnect;

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
