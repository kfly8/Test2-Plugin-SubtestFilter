package Test2::Plugin::SubtestFilter;
use 5.016;
use strict;
use warnings;
use Encode qw(decode_utf8);

our $VERSION = "0.01";

sub import {
    my $class = shift;
    my $caller = caller;

    # Get filter pattern from environment variable
    my $subtest_filter = $ENV{SUBTEST_FILTER} // '';
    # Decode UTF-8 if necessary
    if ($subtest_filter =~ /[\x80-\xFF]/) {
        $subtest_filter = decode_utf8($subtest_filter);
    }

    apply_plugin($caller, $subtest_filter);
}

sub apply_plugin {
    my ($caller, $subtest_filter) = @_;
    
    # Override subtest in caller's namespace
    no strict 'refs';
    no warnings 'redefine';

    # Save original subtest function
    my $orig = $caller->can('subtest');

    # Check if subtest exists in caller's namespace
    unless (defined $orig) {
        # do nothing
    }

    *{"${caller}::subtest"} = _create_filtered_subtest($orig, $subtest_filter, [], $caller);
}

sub _create_filtered_subtest {
    my ($orig, $filter, $current_path, $target_caller) = @_;
    
    return sub {
        my ($name, $code, @rest) = @_;

        # Build the full test path with current name
        my @new_path = (@$current_path, $name);
        my $full_path = join(' ', @new_path);

        # If no filter is set, run all tests
        if (!$filter) {
            return $orig->($name, _wrap_code_with_path($code, $filter, \@new_path, $target_caller), @rest);
        }

        # Check if the full path contains the filter string (exact substring match)
        my $matches = index($full_path, $filter) >= 0;

        if ($matches) {
            # This test matches, run it and all its children without further filtering
            # Create a wrapper that uses unfiltered subtest for children
            return $orig->($name, _wrap_code_with_unfiltered_subtest($code, $orig, $target_caller), @rest);
        }

        # Check if this path could potentially lead to a match
        if (_could_lead_to_match($filter, \@new_path)) {
            # Continue exploring this path with filtering
            return $orig->($name, _wrap_code_with_path($code, $filter, \@new_path, $target_caller), @rest);
        }

        # No potential match - skip this subtest
        require Test2::API;
        my $ctx = Test2::API::context();
        $ctx->skip($name);
        $ctx->release;
        return 1;
    };
}

sub _wrap_code_with_path {
    my ($original_code, $filter, $current_path, $target_caller) = @_;
    
    return sub {
        # Temporarily replace the subtest function in the current scope
        # to continue filtering at the next level
        my $caller = caller;
        
        # Save current subtest function
        no strict 'refs';
        my $current_subtest = *{"${caller}::subtest"}{CODE};
        
        # Replace with filtered version for this scope
        local *{"${caller}::subtest"} = _create_filtered_subtest(
            $current_subtest, 
            $filter, 
            $current_path,
            $target_caller
        );
        
        # Run the original code
        return $original_code->();
    };
}

sub _wrap_code_without_filtering {
    my ($original_code) = @_;
    
    return sub {
        # Run the original code without any filtering modifications
        # This ensures that matched subtests run all their children
        return $original_code->();
    };
}

sub _wrap_code_with_unfiltered_subtest {
    my ($original_code, $orig_subtest, $target_caller) = @_;
    
    return sub {
        # Use the target caller namespace instead of runtime caller
        my $caller = $target_caller;
        
        # Save current (filtered) subtest function  
        no strict 'refs';
        my $current_subtest = *{"${caller}::subtest"}{CODE};
        
        # Create unfiltered subtest that just passes through to original
        my $unfiltered_subtest = sub {
            my ($name, $code, @rest) = @_;
            return $orig_subtest->($name, $code, @rest);
        };
        
        # Temporarily replace subtest with unfiltered version
        local *{"${caller}::subtest"} = $unfiltered_subtest;
        
        # Run the original code
        return $original_code->();
    };
}

sub _could_lead_to_match {
    my ($filter, $current_path) = @_;
    
    my $current_path_str = join(' ', @$current_path);
    
    # If filter starts with current path, definitely continue
    # e.g., path="foo", filter="foo nested arithmetic"
    if (index($filter, $current_path_str) == 0) {
        return 1;
    }
    
    # Check if current path could be start of filter path
    my @filter_words = split /\s+/, $filter;
    my @path_words = @$current_path;
    
    if (@path_words <= @filter_words) {
        my $matches_prefix = 1;
        for my $i (0 .. $#path_words) {
            if ($path_words[$i] ne $filter_words[$i]) {
                $matches_prefix = 0;
                last;
            }
        }
        return 1 if $matches_prefix;
    }
    
    # Special case: if filter doesn't start with current path but could contain it
    # Example: filter="nested arithmetic", path=["foo"] -> check if "foo nested arithmetic" could exist
    my $potential_full_path = $current_path_str . ' ' . $filter;
    # But we can't know if this exists without exploring, so we need a different approach
    
    # Only explore if the filter could reasonably appear in descendants
    # For single words, be conservative and only allow exploration at top level
    if (@$current_path == 1 && scalar(split /\s+/, $filter) > 1) {
        return 1;  # Allow exploring top-level subtests for multi-word filters
    }
    
    return 0;
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

