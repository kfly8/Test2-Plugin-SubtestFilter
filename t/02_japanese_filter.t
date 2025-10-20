use Test2::V0;
use Test2::Plugin::UTF8;
use Capture::Tiny qw(capture);
use File::Spec;

my $test_file = File::Spec->catfile('t', 'examples', 'japanese.t');

# Test that Japanese filters work
subtest 'Run with SUBTEST_FILTER=ユーザー認証 - filters correctly' => sub {
    local $ENV{SUBTEST_FILTER} = 'ユーザー認証';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    # Check that matching tests ran
    like($stdout, qr/ok \d+ -.+\{/, 'matching subtests executed');
    like($stdout, qr/# skip/, 'non-matching tests are skipped');
};

subtest 'Run with SUBTEST_FILTER=データベース操作 - filters correctly' => sub {
    local $ENV{SUBTEST_FILTER} = 'データベース操作';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ -.+\{/, 'データベース操作 executed');
    # Filtering now works correctly
    like($stdout, qr/# skip/, 'non-matching tests are skipped');
};

subtest 'Run with Japanese substring 処理 - filters correctly' => sub {
    local $ENV{SUBTEST_FILTER} = '処理';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ -.+\{/, 'subtests matching 処理 executed');
    # Filtering now works correctly
    like($stdout, qr/# skip/, 'non-matching tests are skipped');
};

subtest 'Run with space-separated Japanese path' => sub {
    local $ENV{SUBTEST_FILTER} = 'データベース操作 トランザクション処理';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ -.+\{/, 'parent and target subtest executed');
    # Current implementation runs all tests due to heuristic
    unlike($stdout, qr/# skip/, 'all tests run due to heuristic');
};

subtest 'No match with Japanese filter 存在しないテスト - skips all' => sub {
    local $ENV{SUBTEST_FILTER} = '存在しないテスト';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    # Non-matching filters now properly skip tests
    like($stdout, qr/# skip/, 'tests are skipped for non-matching filter');
    unlike($stdout, qr/ok \d+ -.+\{/, 'no tests executed for non-matching filter');
};

# Direct test to verify Japanese matching works at the Perl level
subtest 'Direct Japanese substring matching' => sub {
    my $filter = 'ユーザー認証';
    my $name = 'ユーザー認証';

    ok(index($name, $filter) >= 0, 'Japanese string matches Japanese substring');

    my $filter2 = '処理';
    my $name2 = '文字列処理';

    ok(index($name2, $filter2) >= 0, 'Japanese string matches substring');

    my $path = 'データベース操作 トランザクション処理';
    my $filter3 = 'データベース操作 トランザクション';

    ok(index($path, $filter3) >= 0, 'Japanese space-separated path matches substring');
};

done_testing;