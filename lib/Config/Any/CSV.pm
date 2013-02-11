package Config::Any::CSV;
#ABSTRACT: Load CSV as config files

use strict;
use warnings;
use v5.10;

use base 'Config::Any::Base';

use Text::CSV;

sub load {
    my ($class, $file, $driver) = @_;

    my $args = { binary => 1, allow_whitespace => 1 };
    if ($driver) {
        $args->{$_} = $driver->{$_} for keys %$driver;
    }
    my $csv = Text::CSV->new( $args );
    my $config = { };
    open my $fh, "<", $file or die $!;

    my $default = $args->{empty_is_undef} ? undef : "";
 
    my $names = $csv->getline($fh);
    if ( $names ) {
        my $columns = scalar @$names - 1;
        while ( my $row = $csv->getline( $fh ) ) {
            next if @$row == 1 and $row->[0] eq ''; # empty line
            $config->{ $row->[0] // "" } = {
                map { ( $names->[$_] // "" ) => ( $row->[$_] // $default ) }
                (1..$columns)
            };
        }
    }
    die $csv->error_diag() unless $csv->eof;
    close $fh;

    return $config;
}

sub extensions {
    return ('csv');
}

1;

=head1 SYNOPSIS

    use Config::Any;
 
    my $config = Config::Any->load_files({files => \@files});

I recommend to use L<Config::ZOMG>:

    use Config::ZOMG;

    # just load a single file
    my $config_hash = Config::ZOMG->open( $csv_file );

    # load foo.csv (and possible foo_local.csv)
    my $config = Config::ZOMG->new( 
        path => '/path/to/config'
        name => 'foo'
    );

=head1 DESCRIPTION

This small module adds support of CSV files to L<Config::Any>. Files with
extension C<.csv> are read with L<Text::CSV> - see that module for
documentation of the particular CSV format. By default, Config::Any::CSV
enables the options C<binary> and C<allow_whitespace>.  One can modify options
with C<driver_args> (L<Config::Any>) or C<driver> (L<Config::ZOMG>). The first
row of a CSV file is always interpreted as a list of field names and the first
field is always interpreted as key field. For instance this CSV file

    name,age,mail
    alice, 42, alice@example.org
    bob, 23, bob@example.org

Is parsed into this Perl structure:

    {
        alice => {
            age  => '42',
            mail => 'alice@example.org',
        },
         bob => {
            age => '23',
            mail => 'bob@example.org'
        }
    }

The name of the first field is irrelevant and the order of rows gets lost. If a
file contains multiple rows with the same first field value, only the last of
these rows is used. Empty lines are ignored.

This module requires Perl 5.10 but it could easily be modified to also run in
more ancient versions of Perl.

=cut
