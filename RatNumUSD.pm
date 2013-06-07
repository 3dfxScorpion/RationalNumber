
package RatNumUSD;

use strict;
use warnings;

use Scalar::Util qw{ refaddr };
{
    use overload  '+'  => \&_add,
                  '-'  => \&_sub,
                  '*'  => \&_mul,
                  '/'  => \&_div,
                  '==' => \&_eql,
                  '""' => \&_to_string;

    my %root_of;
    my %frac_of;

    sub new {
        my $class = shift;
        my $frac  = {
            NUMER => undef,
            DENOM => undef,
            WHOLE => undef,
        };
        my $new_object  = bless \do{ my $anon_scalar }, $class;
        $new_object->_make_frac(@_);
        $root_of{ refaddr($new_object) } = $frac;
        return $new_object;
    }
    ### Split string and assign NUMER, DENOM, and WHOLE
    sub _make_frac {
        no warnings;    # expecting occasional empties
        my $self     = shift;
        my $frac_str = shift;
        $frac_str =~ /\A([+-]?\d+)??\s*([+-]?\d+)(\/)(\d+)\z/xms;
        my ( $w, $n, $d ) = ( $3 )  # slash found?
            ? ( $1, $2, $4 )        # fraction
            : ( 1, $frac_str, 0 );  # whole number
    ##  Checks for fraction entries that can be simply "1"
        $n = ( $w == abs($w) ) 
            ? $n + $w * $d                  # to positive improper fraction
            : -1 * ( $n - $w * $d ) if $d;  # to negative improper fraction
    ##  Adjust fraction: "34" -> "34/1" and raise $w flag
        ( $n, $d, $w ) = ( $n, $d || 1, ( $d > 1 ) ? 0 : 1 );
        ( $n, $d, $w ) = (1) x 3 if ( $n == $d );  # when "2/2" equals "1" 
    ##  Checks for "-" in denominator and adjusts accordingly
        $n = -$n and $d = -$d if ( ( $n > 0 ) && ( $d < 0 ) );
        ( $frac_of{ refaddr($self) }->{NUMER},
          $frac_of{ refaddr($self) }->{DENOM},
          $frac_of{ refaddr($self) }->{WHOLE},
        ) = ( $n, $d, $w );
        return;
    }
    ### Stringify object to fracion
    sub _to_string {
        my $self = shift;
        my $frac_ref = $frac_of{ refaddr($self) };
        my ( $n, $d, $w ) = 
           ( $frac_ref->{NUMER}, $frac_ref->{DENOM}, $frac_ref->{WHOLE} );
        return "0" unless ( $n && $d );
        return $n if ( $w );
        if ( abs($n) > $d ) {
            my $a = int( $n / $d );
            my $c = $n - ( $d * $a );
            $c = -$c if ( ( $a < 0 ) && ( $c < 0 ) );
            return "$a $c/$d";
        }
        return "$n/$d";
    }
    ### Overloaded addition operator
    sub _add {
        my ( $x_self, $y_self ) = @_;
        my ( $x, $y ) = ( $frac_of{ refaddr($x_self) },
                          $frac_of{ refaddr($y_self) } );
        my ( $n_sum, $sum_str );
        my ( $n1,    $n2 ) = ( $x->{NUMER}, $y->{NUMER} );
        my ( $d1,    $d2 ) = ( $x->{DENOM}, $y->{DENOM} );
        my $com_denom = ( $d1 == $d2 ) ? $d1 : $d1 * $d2;
        $n_sum =
          ( $d1 == $d2 )
            ? $n1 + $n2
            : do {
                $n1 = $n1 * ( $com_denom / $d1 );
                $n2 = $n2 * ( $com_denom / $d2 );
                $n1 + $n2;
              };
        my $gcd = _simplify( $n_sum, $com_denom );
        ( $n_sum, $com_denom ) = map { $_ / $gcd } ( $n_sum, $com_denom );
        $sum_str =
            ( $com_denom )
              ? ( $n_sum == $com_denom )
                ? "1"
                : "${n_sum}/${com_denom}"
              : "0";
        return $sum_str;
    }
    ### Overloaded subtraction operator
    sub _sub {
        my ( $x_self, $y_self ) = @_;
        my ( $x, $y ) = ( $frac_of{ refaddr($x_self) },
                          $frac_of{ refaddr($y_self) } );
        my ( $n_diff, $diff_str );
        my ( $n1, $n2 ) = ( $x->{NUMER}, $y->{NUMER} );
        my ( $d1, $d2 ) = ( $x->{DENOM}, $y->{DENOM} );
        my $com_denom = ( $d1 == $d2 ) ? $d1 : $d1 * $d2;
        $n_diff =
          ( $d1 == $d2 )
            ? $n1 - $n2
            : do {
                $n1 = $n1 * ( $com_denom / $d1 );
                $n2 = $n2 * ( $com_denom / $d2 );
                $n1 - $n2;
              };
        my $gcd = _simplify( abs($n_diff), $com_denom );
        ( $n_diff, $com_denom ) = map { $_ / $gcd } ( $n_diff, $com_denom );
        $diff_str =
            ( $com_denom )
              ? ( $n_diff == $com_denom )
                ? "1"
                : "${n_diff}/${com_denom}"
              : "0";
        return $diff_str;
    }
    ### Overloaded multiplication operator
    sub _mul {
        my ( $x_self, $y_self ) = @_;
        my ( $x, $y ) = ( $frac_of{ refaddr($x_self) },
                          $frac_of{ refaddr($y_self) } );
        my ( $n_prod ) = ( $x->{NUMER} * $y->{NUMER} );
        my ( $d_prod ) = ( $x->{DENOM} * $y->{DENOM} );
        return "0" unless ( $n_prod && $d_prod );
        my $gcd = _simplify( $n_prod, $d_prod );
        ( $n_prod, $d_prod ) = map { $_ / $gcd } ( $n_prod, $d_prod );
        my $prod_str = ( $n_prod == $d_prod ) ? "1" : "${n_prod}/${d_prod}";
        return $prod_str;
    }
    ### Overloaded division operator
    sub _div {
        my ( $x_self, $y_self ) = @_;
        my ( $x, $y ) = ( $frac_of{ refaddr($x_self) },
                          $frac_of{ refaddr($y_self) } );
        my ( $n_quot ) = ( $x->{NUMER} * $y->{DENOM} );
        my ( $d_quot ) = ( $x->{DENOM} * $y->{NUMER} );
        return "undef" unless ( $n_quot && $d_quot );
        ( $n_quot, $d_quot ) = ( -$n_quot, -$d_quot )
          if ( $n_quot < 0 && $d_quot < 0 );
        my $gcd = _simplify( $n_quot, $d_quot );
        ( $n_quot, $d_quot ) = map { $_ / $gcd } ( $n_quot, $d_quot );
        my $quot_str = ( $n_quot == $d_quot ) ? "1" : "${n_quot}/${d_quot}";
        return $quot_str;
    }
    ### Checks for object equality
    sub _eql {
        my ( $x_self, $y_self ) = @_;
        my ( $x, $y ) = ( $frac_of{ refaddr($x_self) },
                          $frac_of{ refaddr($y_self) } );
        return ( ( $x->{NUMER} == $y->{NUMER} )
              && ( $x->{DENOM} == $y->{DENOM} ) );
    }
    ### Simplify fraction using Euclid's algorithm
    sub _simplify {
        my ( $x, $y ) = @_;
        while ( $y ) {
            ( $x, $y ) = ( $y, $x % $y );
        }
        return $x;
    }
    sub DESTROY { 
        my ($self) = @_; 
        delete $root_of{ refaddr($self) }; 
        delete $frac_of{ refaddr($self) }; 
        return;
    } 
}
1;  # for whenever I make this a separate package file

