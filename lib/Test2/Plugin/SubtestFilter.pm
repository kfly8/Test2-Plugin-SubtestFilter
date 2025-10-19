package Test2::Plugin::SubtestFilter;
use 5.016;
use strict;
use warnings;

our $VERSION = "0.01";

# Track state with package variables
our $parent_matched = 0;
our $checking_children = 0;
our $child_matched_in_check = 0;

sub import {
    my $class = shift;
    my $caller = caller;

    # Get filter pattern from environment variable
    my $subtest_filter = $ENV{SUBTEST_FILTER} // '.*';
    my $method_regexp = eval { qr/\A$subtest_filter\z/ };
    die "SUBTEST_FILTER ($subtest_filter) is not a valid regexp: $@" if $@;

    # Override subtest in caller's namespace
    no strict 'refs';
    no warnings 'redefine';

    # Save original subtest function
    my $orig = \&{"${caller}::subtest"};

    # Check if subtest exists in caller's namespace
    unless (defined $orig && defined &$orig) {
        require Carp;
        Carp::croak("subtest is not defined in ${caller}. Please load Test2::V0 or Test2::Tools::Subtest before loading Test2::Plugin::SubtestFilter.");
    }

    *{"${caller}::subtest"} = sub {
        my ($name, $code, @rest) = @_;

        # If we're in checking mode and name matches, record it
        if ($checking_children && $name =~ $method_regexp) {
            $child_matched_in_check = 1;
            return 1;  # Don't actually run during check
        }

        # If parent matched, run all children without filtering
        if ($parent_matched) {
            return $orig->($name, $code, @rest);
        }

        # Check if current subtest name matches the filter
        if ($name =~ $method_regexp) {
            local $parent_matched = 1;  # All children should run
            return $orig->($name, $code, @rest);
        }

        # Name doesn't match - check if any children would match
        my $has_matching_child;
        {
            local $checking_children = 1;
            local $child_matched_in_check = 0;

            # Dry-run to see if any children match (intercept events)
            require Test2::API;
            Test2::API::intercept(sub {
                eval { $code->() };
            });

            $has_matching_child = $child_matched_in_check;
        }

        if ($has_matching_child) {
            # At least one child matched, run the parent for real
            # checking_children is now 0 (exited local scope)
            # Children will be filtered by the normal matching logic
            return $orig->($name, $code, @rest);
        }

        # No children matched - skip this subtest
        require Test2::API;
        my $ctx = Test2::API::context();
        $ctx->skip($name);
        $ctx->release;
        return 1;
    };
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

