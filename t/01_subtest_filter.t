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

subtest 'SUBTEST_FILTER=foo - foo and all its children run' => sub {
    local $ENV{SUBTEST_FILTER} = 'foo';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - foo \{/, 'foo subtest is executed');
    like($stdout, qr/ok \d+ - nested arithmetic \{/, 'nested arithmetic is executed');
    like($stdout, qr/ok \d+ - nested string \{/, 'nested string is executed');
    unlike($stdout, qr/ok \d+ - bar \{/, 'bar subtest is not executed');
    unlike($stdout, qr/ok \d+ - baz \{/, 'baz subtest is not executed');
};

subtest 'SUBTEST_FILTER=bar - only bar runs' => sub {
    local $ENV{SUBTEST_FILTER} = 'bar';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    unlike($stdout, qr/ok \d+ - foo \{/, 'foo subtest is not executed');
    like($stdout, qr/ok \d+ - bar \{/, 'bar subtest is executed');
    unlike($stdout, qr/ok \d+ - baz \{/, 'baz subtest is not executed');
};

subtest 'SUBTEST_FILTER with regex pattern ba.*' => sub {
    local $ENV{SUBTEST_FILTER} = 'ba.*';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    unlike($stdout, qr/ok \d+ - foo \{/, 'foo subtest is not executed');
    like($stdout, qr/ok \d+ - bar \{/, 'bar subtest is executed');
    like($stdout, qr/ok \d+ - baz \{/, 'baz subtest is executed');
    like($stdout, qr/ok \d+ - nested deep \{/, 'nested deep is executed (parent of baz)');
    like($stdout, qr/ok \d+ - nested very deep \{/, 'nested very deep is executed');
};

subtest 'SUBTEST_FILTER for nested child - parent runs with only matching child' => sub {
    local $ENV{SUBTEST_FILTER} = 'nested arithmetic';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - foo \{/, 'foo subtest is executed (parent)');
    like($stdout, qr/ok \d+ - nested arithmetic \{/, 'nested arithmetic is executed');
    unlike($stdout, qr/ok \d+ - nested string \{/, 'nested string is not executed');
    unlike($stdout, qr/ok \d+ - bar \{/, 'bar subtest is not executed');
    unlike($stdout, qr/ok \d+ - baz \{/, 'baz subtest is not executed');
};

subtest 'SUBTEST_FILTER for deeply nested child' => sub {
    local $ENV{SUBTEST_FILTER} = 'nested very deep';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    unlike($stdout, qr/ok \d+ - foo \{/, 'foo subtest is not executed');
    unlike($stdout, qr/ok \d+ - bar \{/, 'bar subtest is not executed');
    like($stdout, qr/ok \d+ - baz \{/, 'baz subtest is executed (grandparent)');
    like($stdout, qr/ok \d+ - nested deep \{/, 'nested deep is executed (parent)');
    like($stdout, qr/ok \d+ - nested very deep \{/, 'nested very deep is executed');
};

subtest 'SUBTEST_FILTER with no match - all tests are skipped' => sub {
    local $ENV{SUBTEST_FILTER} = 'nonexistent';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    unlike($stdout, qr/ok \d+ - foo \{/, 'foo subtest is not executed');
    unlike($stdout, qr/ok \d+ - bar \{/, 'bar subtest is not executed');
    unlike($stdout, qr/ok \d+ - baz \{/, 'baz subtest is not executed');
    like($stdout, qr/ok \d+ - foo # skip/, 'foo is skipped');
    like($stdout, qr/ok \d+ - bar # skip/, 'bar is skipped');
    like($stdout, qr/ok \d+ - baz # skip/, 'baz is skipped');
};

subtest 'invalid regex in SUBTEST_FILTER causes error' => sub {
    local $ENV{SUBTEST_FILTER} = '(invalid';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    isnt($exit >> 8, 0, 'exit code is not 0');
    like($stderr, qr/SUBTEST_FILTER.*is not a valid regexp/, 'error message about invalid regex');
};

subtest 'SUBTEST_FILTER with regex metacharacters' => sub {
    local $ENV{SUBTEST_FILTER} = 'nested.*arithmetic';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - foo \{/, 'foo subtest is executed (parent)');
    like($stdout, qr/ok \d+ - nested arithmetic \{/, 'nested arithmetic matches pattern');
    unlike($stdout, qr/ok \d+ - nested string \{/, 'nested string does not match');
};

subtest 'SUBTEST_FILTER with exact match anchoring' => sub {
    local $ENV{SUBTEST_FILTER} = 'fo';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    unlike($stdout, qr/ok \d+ - foo \{/, 'foo is not executed (no partial match)');
    like($stdout, qr/ok \d+ - foo # skip/, 'foo is skipped');
};

done_testing;
