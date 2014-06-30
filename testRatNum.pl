#!/usr/bin/perl

use strict;
use warnings;
use RatNum;

####################
### Main Program ###
####################
my $command = 0;
print "\nThis program will perform arithmetic operations on fractions.\n";
print "Enter fractions like this: 3/4, 15/16, etc..., or \"exit\" to exit.\n";
while ( $command ne "Q" ) {
    print "\nEnter first fraction: ";
    chomp( my $frac01 = <> );
    if ( $frac01 =~ /\/(\d+)/ ) {
        print "Division by zero not allowed, starting over..." and redo
          unless ( $1 );
    }
    print "Enter second fraction: ";
    chomp( my $frac02 = <> );
    if ( $frac02 =~ /\/(\d+)/ ) {
        print "Division by zero not allowed, starting over..." and redo
          unless ( $1 );
    }
    exit if ( $frac01 eq "exit" || $frac02 eq "exit" );
    my $f1 = RatNum->new($frac01);
    my $f2 = RatNum->new($frac02);

    while ( $command ne "Q" ) {
        print "\nChoose: (A)dd, (S)ubtract, (M)ultiply, (D)ivide\n";
        print "\tTest for (E)quality, or (Q)uit\n";
        print "Answer: ";
        chomp( $command = <> );
        if ( $command eq "A" ) {
            my $total = RatNum->new( $f1 + $f2 );
            print "\n$f1 + $f2 = $total\n";
        }
        elsif ( $command eq "S" ) {
            my $total = RatNum->new( $f1 - $f2 );
            print "\n$f1 - $f2 = $total\n";
        }
        elsif ( $command eq "M" ) {
            my $total = RatNum->new( $f1 * $f2 );
            print "\n$f1 * $f2 = $total\n";
        }
        elsif ( $command eq "D" ) {
            my $total = RatNum->new( $f1 / $f2 );
            print "\n$f1 / $f2 = $total\n";
        }
        elsif ( $command eq "E" ) {
            my $is_equal = ( $f1 == $f2 ) ? q{ } : " not ";
            print "\n$f1 and $f2 are${is_equal}equal\n";
        }
        elsif ( $command eq "Q" ) {
            last;
        }
        else {
            print "Command not recognized...\n";
        }
    }
    print "Type (Q) again to exit or another character to start over: ";
    chomp( $command = <> );
    if ( $command eq "Q" ) {
        print "Goodbye..\n";
        exit;
    }
}
exit;
