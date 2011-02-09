package Sub::Spec::Pod;
BEGIN {
  $Sub::Spec::Pod::VERSION = '0.01';
}
# ABSTRACT: Generate POD documentation for subs

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use Sub::Spec::CmdLine; #tmp

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(gen_pod);

# currently we cheat by only parsing a limited subset of schema. this is because
# Data::Sah is not available yet.
sub _parse_schema {
    Sub::Spec::CmdLine::_parse_schema(@_);
}

sub _gen_sub_pod($;$) {
    require Data::Dump::Partial;
    require List::MoreUtils;

    my ($sub_spec, $opts) = @_;
    $opts //= {};

    my $pod = "";

    die "No name in spec" unless $sub_spec->{name};
    $pod .= "=head2 $sub_spec->{name}(\%args) -> RES\n\n";

    if ($sub_spec->{summary}) {
        $pod .= "$sub_spec->{summary}.\n\n";
    }

    my $desc = $sub_spec->{description};
    if ($desc) {
        $desc =~ s/^\n+//; $desc =~ s/\n+$//;
        $pod .= "$desc\n\n";
    }

    my $args  = $sub_spec->{args} // {};
    my $rargs = $sub_spec->{required_args};
    $args = { map {$_ => _parse_schema($args->{$_})} keys %$args };
    my $prev_cat;
    for my $name (sort {
        (($args->{$a}{attr_hashes}[0]{arg_category} // "") cmp
             ($args->{$b}{attr_hashes}[0]{arg_category} // "")) ||
                 (($args->{$a}{attr_hashes}[0]{arg_pos} // 9999) <=>
                      ($args->{$b}{attr_hashes}[0]{arg_pos} // 9999)) ||
                          ($a cmp $b) } keys %$args) {
        my $arg = $args->{$name};
        my $ah0 = $arg->{attr_hashes}[0];

        my $cat = $ah0->{arg_category} // "";
        if (!defined($prev_cat) || $prev_cat ne $cat) {
            $pod .= ($cat ? "$cat arguments" : "Arguments") .
                ": (* denotes required arguments):\n\n";
            $pod .= "=back\n\n" if defined($prev_cat);
            $pod .= "=over 4\n\n";
            $prev_cat = $cat;
        }

        $pod .= "=item * $name".($ah0->{required} ? "*" : "")." => ";
        if ($arg->{type} eq 'any') {
            my @schemas = map {_parse_schema($_)} @{$ah0->{of}};
            my @types   = map {$_->{type}} @schemas;
            @types      = sort List::MoreUtils::uniq(@types);
            $pod .= uc join("|", @types);
        } else {
            $pod .= uc $arg->{type};
        }
        $pod .= " (default ".
            (defined($ah0->{default}) ?
                 Data::Dump::Partial::dumpp($ah0->{default}) : "none").
                       ")\n\n"
                           if defined($ah0->{default});

        $pod .= "One of: ".
            Data::Dump::Partial::dumpp($ah0->{choices})."\n\n"
                  if defined($ah0->{choices});

             #my $o = $ah0->{arg_pos};
        #my $g = $ah0->{arg_greedy};

        $pod .= "$ah0->{summary}.\n\n" if $ah0->{summary};

        my $desc = $ah0->{description};
        if ($desc) {
            $desc =~ s/^\n+//; $desc =~ s/\n+$//;
            # XXX format/rewrap
            $pod .= "$desc\n\n";
        }
    }
    $pod .= "=back\n\n";

    $pod;
}

sub gen_pod {
    my %args = @_;
    my $module = $args{module};

    # require module and get specs
    my $modulep = $module;
    $modulep =~ s!::!/!g; $modulep .= ".pm";
    if ($args{require} // 1) {
        eval { require $modulep };
        die $@ if $@;
    }
    no strict 'refs';
    my $specs = \%{$module."::SUBS"};
    die "Can't find \%SUBS in package $module\n" unless $specs;

    for (keys %$specs) {
        $specs->{$_}{_package} = $module;
        $specs->{$_}{name}     = $_;
    }

    join("", map { _gen_sub_pod($specs->{$_}) } sort keys %$specs);
}

1;


=pod

=head1 NAME

Sub::Spec::Pod - Generate POD documentation for subs

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 perl -MSub::Spec::Pod=gen_pod -e'print gen_pod(module=>"MyModule")'

=head1 DESCRIPTION

This module generates API POD documentation for all subs in specified module.
Example output:

 =head2 sub1(%args) -> RES

 Summary of sub1.

 Description of sub1...

 Arguments (* denotes required arguments):

 =over 4

 =item * arg1* => int (default 0)

 Blah ...

 =item * arg2 => str (default none)

 Blah blah ...

 =back

 =head2 sub2(%args) -> RES

 ...

=head1 FUNCTIONS

None of the functions are exported by default, but they are exportable.

=head2 gen_pod(%args) -> POD

Generate POD documentation.

Arguments:

=over 4

=item * module* => STR

=back

=head1 SEE ALSO

L<Sub::Spec>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

