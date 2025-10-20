use strict;
use warnings;
use Test2::V0;
use Capture::Tiny qw(capture);
use File::Temp qw(tempfile);
use File::Spec;

my $test_file = File::Spec->catfile('t', 'examples', 'basic.t');

subtest 'no SUBTEST_FILTER - all tests run' => sub {
    local $ENV{SUBTEST_FILTER};
    delete $ENV{SUBTEST_FILTER};

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - foo \{/, 'foo subtest is executed');
    like($stdout, qr/ok \d+ - bar \{/, 'bar subtest is executed');
    like($stdout, qr/ok \d+ - baz \{/, 'baz subtest is executed');
    like($stdout, qr/ok \d+ - nested arithmetic \{/, 'nested arithmetic is executed');
    like($stdout, qr/ok \d+ - nested string \{/, 'nested string is executed');
    like($stdout, qr/ok \d+ - nested deep \{/, 'nested deep is executed');
    like($stdout, qr/ok \d+ - nested very deep \{/, 'nested very deep is executed');
};

subtest 'SUBTEST_FILTER=foo - matches foo only' => sub {
    local $ENV{SUBTEST_FILTER} = 'foo';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - foo \{/, 'foo subtest is executed');
    like($stdout, qr/ok \d+ - nested arithmetic \{/, 'nested arithmetic is executed');
    like($stdout, qr/ok \d+ - nested string \{/, 'nested string is executed');
    # Non-matching tests are skipped
    like($stdout, qr/ok \d+ - bar # skip/, 'bar is skipped');
    like($stdout, qr/ok \d+ - baz # skip/, 'baz is skipped');
};

subtest 'SUBTEST_FILTER=bar - matches bar only' => sub {
    local $ENV{SUBTEST_FILTER} = 'bar';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    # Non-matching tests are skipped
    like($stdout, qr/ok \d+ - foo # skip/, 'foo is skipped');
    like($stdout, qr/ok \d+ - bar \{/, 'bar subtest is executed');
    like($stdout, qr/ok \d+ - baz # skip/, 'baz is skipped');
};

subtest 'SUBTEST_FILTER with substring pattern ba - matches bar and baz' => sub {
    local $ENV{SUBTEST_FILTER} = 'ba';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    # Substring matches work
    like($stdout, qr/ok \d+ - foo # skip/, 'foo is skipped');
    like($stdout, qr/ok \d+ - bar \{/, 'bar matches ba substring');
    like($stdout, qr/ok \d+ - baz \{/, 'baz matches ba substring');
};

subtest 'SUBTEST_FILTER for nested child with space-separated path' => sub {
    local $ENV{SUBTEST_FILTER} = 'foo nested arithmetic';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - foo \{/, 'foo subtest is executed (parent)');
    like($stdout, qr/ok \d+ - nested arithmetic \{/, 'nested arithmetic is executed');
    like($stdout, qr/ok \d+ - nested string \{/, 'nested string also runs in matched parent');
    # Multi-word filters explore all top-level tests
    like($stdout, qr/ok \d+ - bar \{/, 'bar is explored for multi-word filter');
    like($stdout, qr/ok \d+ - baz \{/, 'baz is explored for multi-word filter');
};

subtest 'SUBTEST_FILTER for deeply nested child with partial substring' => sub {
    local $ENV{SUBTEST_FILTER} = 'nested very deep';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    # Multi-word filter explores all top-level tests
    like($stdout, qr/ok \d+ - foo \{/, 'foo explored for multi-word filter');
    like($stdout, qr/ok \d+ - bar \{/, 'bar explored for multi-word filter');
    like($stdout, qr/ok \d+ - baz \{/, 'baz subtest is executed (grandparent)');
    like($stdout, qr/ok \d+ - nested deep \{/, 'nested deep is executed (parent)');
    like($stdout, qr/ok \d+ - nested very deep \{/, 'nested very deep is executed');
};

subtest 'SUBTEST_FILTER="nested arithmetic" - explores top level for multi-word' => sub {
    local $ENV{SUBTEST_FILTER} = 'nested arithmetic';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    # Multi-word filter explores all top-level tests
    like($stdout, qr/ok \d+ - foo \{/, 'foo explored and matches');
    like($stdout, qr/ok \d+ - nested arithmetic \{/, 'nested arithmetic found and executed');
    like($stdout, qr/ok \d+ - bar \{/, 'bar explored but no match');
    like($stdout, qr/ok \d+ - baz \{/, 'baz explored but no match');
};

subtest 'SUBTEST_FILTER with no match - skips all tests' => sub {
    local $ENV{SUBTEST_FILTER} = 'nonexistent';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    # Non-matching tests are skipped
    like($stdout, qr/ok \d+ - foo # skip/, 'foo is skipped');
    like($stdout, qr/ok \d+ - bar # skip/, 'bar is skipped');
    like($stdout, qr/ok \d+ - baz # skip/, 'baz is skipped');
    like($stdout, qr/# skip/, 'all tests are skipped for non-matching filter');
};

subtest 'SUBTEST_FILTER with partial nested path match - skips all (single word)' => sub {
    local $ENV{SUBTEST_FILTER} = 'nested';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    # Single word filters that don't exactly match top-level are skipped
    like($stdout, qr/ok \d+ - foo # skip/, 'foo is skipped');
    like($stdout, qr/ok \d+ - bar # skip/, 'bar is skipped');
    like($stdout, qr/ok \d+ - baz # skip/, 'baz is skipped');
};

subtest 'SUBTEST_FILTER with partial match behavior - substring match works' => sub {
    local $ENV{SUBTEST_FILTER} = 'fo';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    # Partial substring matches work
    like($stdout, qr/ok \d+ - foo \{/, 'foo matches fo substring');
    like($stdout, qr/ok \d+ - bar # skip/, 'bar is skipped');
    like($stdout, qr/ok \d+ - baz # skip/, 'baz is skipped');
};

done_testing;