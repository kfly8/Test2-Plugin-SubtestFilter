package Test2::Plugin::SubtestFilter;
use 5.016;
use strict;
use warnings;
use Encode qw(decode_utf8);
use Test2::API qw(context);
use B::Deparse ();
use List::Util qw(any);

our $VERSION = "0.01";

our $SEPARATOR = ' ';

sub import {
    my $class = shift;
    my $caller = caller;

    # Get original subtest function from caller's namespace
    # If it doesn't exist, do nothing
    my $orig = $caller->can('subtest') or return;

    # Override subtest in caller's namespace
    no strict 'refs';
    no warnings 'redefine';
    *{"${caller}::subtest"} = _create_filtered_subtest($orig, $caller);
}

# Get subtest filter regex from environment variable
sub _get_subtest_filter_regex {

    unless ( $ENV{SUBTEST_FILTER} ) {
        return undef;
    }

    my $subtest_filter = $ENV{SUBTEST_FILTER};

    # Decode UTF-8 if necessary
    if ($subtest_filter =~ /[\x80-\xFF]/) {
        $subtest_filter = decode_utf8($subtest_filter);
    }

    my $regexp = eval { qr/$subtest_filter/ };
    die "SUBTEST_FILTER ($regexp) is not a valid regexp: $@" if $@;

    return $regexp;
}

# Create a filtered subtest wrapper
sub _create_filtered_subtest {
    my ($original_subtest, $target_caller) = @_;

    my $deparse = B::Deparse->new('-p', '-sC');

    return sub {
        my $filter = _get_subtest_filter_regex();

        # If no filter is set, run the original subtest
        unless ($filter) {
            goto &$original_subtest;
        }

        my $name = shift;
        my $params = ref($_[0]) eq 'HASH' ? shift(@_) : {};
        my $code = shift;
        my @args = @_;

        my $ctx = context();
        my $hub = $ctx->hub;

        $hub->set_meta(subtest_name => $name);
        my @stacked_subtest_names = map { $_->get_meta('subtest_name') } $ctx->stack->all;
        my $current_subtest_fullname = join $SEPARATOR, @stacked_subtest_names;

        # If a parent subtest matches, run all children
        if ($current_subtest_fullname =~ $filter) {
            my $pass = $original_subtest->($name, $params, $code, @args);
            $ctx->release;
            return $pass;
        }

        # Dry-run the subtest to check for matching child subtests
        my $obj    = B::svref_2object(\$code);
        my $source = $deparse->coderef2text($code);
        my @child_subtest_names = $source =~ /subtest\(['"](.+?)['"]/g;

        if (@child_subtest_names) {
            my @child_subtest_fullnames = map {
                my $decoded = $_;
                # Convert B::Deparse's \x{XXXX} format to actual characters
                $decoded =~ s/\\x\{([0-9a-fA-F]+)\}/chr(hex($1))/ge;
                join $SEPARATOR, $current_subtest_fullname, $decoded;
            } @child_subtest_names;
            if (any { $_ =~ $filter } @child_subtest_fullnames) {
                my $pass = $original_subtest->($name, $params, $code, @args);
                $ctx->release;
                return $pass;
            }
        }

        # No match found, skip the subtest
        $ctx->skip($name);
        $ctx->release;
        return 1;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Test2::Plugin::SubtestFilter - Filter subtests by name using environment variables

=head1 SYNOPSIS

    use Test2::V0;
    use Test2::Plugin::SubtestFilter;

    subtest 'foo' => sub {
        ok 1, 'foo test 1';

        subtest 'nested arithmetic' => sub {
            ok 1, 'arithmetic test';
        };

        subtest 'nested string' => sub {
            ok 1, 'string test';
        };
    };

    subtest 'bar' => sub {
        ok 1, 'bar test';
    };

    done_testing;

=head1 DESCRIPTION

Test2::Plugin::SubtestFilter is a Test2 plugin that allows you to selectively run
specific subtests based on environment variables. This is useful when you want to
run only a subset of your tests during development or debugging.

=head1 USAGE

Load this plugin after loading Test2::V0 or Test2::Tools::Subtest:

    use Test2::V0;
    use Test2::Plugin::SubtestFilter;

Then set the C<SUBTEST_FILTER> environment variable to filter subtests:

    # Run only the 'foo' subtest and all its children
    SUBTEST_FILTER=foo prove -lv t/test.t

    # Run only the 'nested arithmetic' subtest (and its parent 'foo')
    SUBTEST_FILTER='nested arithmetic' prove -lv t/test.t

    # Use regex patterns to match multiple subtests
    SUBTEST_FILTER='ba.*' prove -lv t/test.t  # Matches 'bar', 'baz', etc.

    # Run all tests (no filtering)
    prove -lv t/test.t

=head1 FILTERING BEHAVIOR

The plugin implements smart filtering with the following rules:

=over 4

=item * B<Parent name matches>

When a parent subtest name matches the filter, the parent and ALL its children
are executed without further filtering.

    SUBTEST_FILTER=foo prove -lv t/test.t
    # Executes 'foo' and all its nested subtests

=item * B<Child name matches>

When a child subtest name matches the filter, the parent is executed but only
the matching children are run. Non-matching siblings are skipped.

    SUBTEST_FILTER='nested arithmetic' prove -lv t/test.t
    # Executes 'foo' (parent) but only runs 'nested arithmetic' (child)
    # Other children like 'nested string' are skipped

=item * B<No match>

Subtests that don't match the filter (and have no matching children) are skipped.

=item * B<No filter set>

When C<SUBTEST_FILTER> is not set, all tests run normally.

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item * C<SUBTEST_FILTER>

Regular expression pattern to match subtest names.

=back

The pattern is automatically anchored with C<\A> and C<\z>, so partial matches
won't work unless you use regex wildcards:

    SUBTEST_FILTER=foo        # Matches only 'foo' exactly
    SUBTEST_FILTER='foo.*'    # Matches 'foo', 'foobar', 'foo_test', etc.

=head1 IMPLEMENTATION DETAILS

This plugin works by overriding the C<subtest> function in the caller's namespace.
It uses Test2::API::intercept to perform a dry-run of subtests to determine if
any child subtests would match the filter before actually executing the parent.

The plugin maintains internal state using package variables to track:

=over 4

=item * Whether a parent subtest has matched (all children should run)

=item * Whether we're in checking mode (dry-run to detect matching children)

=item * Whether any child matched during the check

=back

=head1 CAVEATS

=over 4

=item * This plugin must be loaded AFTER Test2::V0 or Test2::Tools::Subtest,
as it needs to override the C<subtest> function that they export.

=item * The plugin modifies the C<subtest> function in the caller's namespace,
which may interact unexpectedly with other code that also modifies C<subtest>.

=item * During the dry-run phase, subtest code blocks are executed but their
test events are intercepted and discarded. Side effects in the code blocks
may still occur during this phase.

=back

=head1 SEE ALSO

=over 4

=item * L<Test2::V0> - Recommended Test2 bundle

=item * L<Test2::Tools::Subtest> - Core subtest functionality

=item * L<Test2::API> - Test2 API for intercepting events

=back

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

