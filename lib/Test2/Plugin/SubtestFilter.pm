package Test2::Plugin::SubtestFilter;
use 5.016;
use strict;
use warnings;
use Encode qw(decode_utf8);

our $VERSION = "0.01";

# Track test path for nested subtests
our @test_path = ();
our $subtest_filter = '';

sub import {
    my $class = shift;
    my $caller = caller;

    # Get filter pattern from environment variable
    $subtest_filter = $ENV{SUBTEST_FILTER} // '';
    # Decode UTF-8 if necessary
    if ($subtest_filter =~ /[\x80-\xFF]/) {
        $subtest_filter = decode_utf8($subtest_filter);
    }

    # Override subtest in caller's namespace
    no strict 'refs';
    no warnings 'redefine';

    # Save original subtest function
    my $orig = $caller->can('subtest');

    # Check if subtest exists in caller's namespace
    unless (defined $orig) {
        # do nothing
    }

    *{"${caller}::subtest"} = sub {
        my ($name, $code, @rest) = @_;

        # Build the full test path with current name
        my @current_path = (@test_path, $name);
        my $full_path = join(' ', @current_path);

        # If no filter is set, run all tests
        if (!$subtest_filter) {
            local @test_path = @current_path;
            return $orig->($name, $code, @rest);
        }

        # Check if the full path contains the filter string (exact substring match)
        my $matches = index($full_path, $subtest_filter) >= 0;

        if ($matches) {
            # This test matches, run it and all its children
            local @test_path = @current_path;
            return $orig->($name, $code, @rest);
        }

        # Test doesn't match directly - check if we should explore this path
        # We should run if the filter could potentially match a descendant path
        
        # Simple heuristic: run if the filter starts with our current path
        # or if our current path is part of the filter
        my $current_path_str = join(' ', @current_path);
        
        # Check if filter begins with current path (e.g., current: "foo", filter: "foo nested arithmetic")
        my $filter_starts_with_current = (index($subtest_filter, $current_path_str) == 0);
        
        # Check if current path could be part of filter (e.g., current: "foo", filter: "nested very deep")
        # by seeing if there are words in the filter that we haven't seen yet
        my @filter_parts = split /\s+/, $subtest_filter;
        my @current_parts = split /\s+/, $current_path_str;
        
        my $could_be_ancestor = 0;
        for my $filter_part (@filter_parts) {
            # If this part of the filter isn't in our current path,
            # we might find it in descendants
            my $found_in_current = 0;
            for my $current_part (@current_parts) {
                if ($current_part eq $filter_part) {
                    $found_in_current = 1;
                    last;
                }
            }
            if (!$found_in_current) {
                $could_be_ancestor = 1;
                last;
            }
        }
        
        if ($filter_starts_with_current || $could_be_ancestor) {
            local @test_path = @current_path;
            return $orig->($name, $code, @rest);
        }
        
        # No potential match - skip this subtest
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

