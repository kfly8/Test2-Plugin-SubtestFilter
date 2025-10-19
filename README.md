
# NAME

Test2::Plugin::SubtestFilter - Filter subtests by name using environment variables

# SYNOPSIS

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

# DESCRIPTION

Test2::Plugin::SubtestFilter is a Test2 plugin that allows you to selectively run
specific subtests based on environment variables. This is useful when you want to
run only a subset of your tests during development or debugging.

# USAGE

Load this plugin after loading Test2::V0 or Test2::Tools::Subtest:

    use Test2::V0;
    use Test2::Plugin::SubtestFilter;

Then set the `SUBTEST_FILTER` environment variable to filter subtests:

    # Run only the 'foo' subtest and all its children
    SUBTEST_FILTER=foo prove -lv t/test.t

    # Run only the 'nested arithmetic' subtest (and its parent 'foo')
    SUBTEST_FILTER='nested arithmetic' prove -lv t/test.t

    # Use regex patterns to match multiple subtests
    SUBTEST_FILTER='ba.*' prove -lv t/test.t  # Matches 'bar', 'baz', etc.

    # Run all tests (no filtering)
    prove -lv t/test.t

# FILTERING BEHAVIOR

The plugin implements smart filtering with the following rules:

- **Parent name matches**

    When a parent subtest name matches the filter, the parent and ALL its children
    are executed without further filtering.

        SUBTEST_FILTER=foo prove -lv t/test.t
        # Executes 'foo' and all its nested subtests

- **Child name matches**

    When a child subtest name matches the filter, the parent is executed but only
    the matching children are run. Non-matching siblings are skipped.

        SUBTEST_FILTER='nested arithmetic' prove -lv t/test.t
        # Executes 'foo' (parent) but only runs 'nested arithmetic' (child)
        # Other children like 'nested string' are skipped

- **No match**

    Subtests that don't match the filter (and have no matching children) are skipped.

- **No filter set**

    When `SUBTEST_FILTER` is not set, all tests run normally.

# ENVIRONMENT VARIABLES

- `SUBTEST_FILTER`

    Regular expression pattern to match subtest names.

The pattern is automatically anchored with `\A` and `\z`, so partial matches
won't work unless you use regex wildcards:

    SUBTEST_FILTER=foo        # Matches only 'foo' exactly
    SUBTEST_FILTER='foo.*'    # Matches 'foo', 'foobar', 'foo_test', etc.

# IMPLEMENTATION DETAILS

This plugin works by overriding the `subtest` function in the caller's namespace.
It uses Test2::API::intercept to perform a dry-run of subtests to determine if
any child subtests would match the filter before actually executing the parent.

The plugin maintains internal state using package variables to track:

- Whether a parent subtest has matched (all children should run)
- Whether we're in checking mode (dry-run to detect matching children)
- Whether any child matched during the check

# CAVEATS

- This plugin must be loaded AFTER Test2::V0 or Test2::Tools::Subtest,
as it needs to override the `subtest` function that they export.
- The plugin modifies the `subtest` function in the caller's namespace,
which may interact unexpectedly with other code that also modifies `subtest`.
- During the dry-run phase, subtest code blocks are executed but their
test events are intercepted and discarded. Side effects in the code blocks
may still occur during this phase.

# SEE ALSO

- [Test2::V0](https://metacpan.org/pod/Test2%3A%3AV0) - Recommended Test2 bundle
- [Test2::Tools::Subtest](https://metacpan.org/pod/Test2%3A%3ATools%3A%3ASubtest) - Core subtest functionality
- [Test2::API](https://metacpan.org/pod/Test2%3A%3AAPI) - Test2 API for intercepting events

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>
