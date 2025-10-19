use Test2::V0;
use Test2::Plugin::UTF8;
use Capture::Tiny qw(capture);
use File::Spec;

my $test_file = File::Spec->catfile('t', 'examples', 'japanese.t');

# Test that Japanese filters work
subtest 'Run with SUBTEST_FILTER=ユーザー認証' => sub {
    local $ENV{SUBTEST_FILTER} = 'ユーザー認証';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    # Check that some tests ran and some were skipped
    like($stdout, qr/ok \d+ -.+\{/, 'some subtests executed');
    like($stdout, qr/# skip/, 'some subtests were skipped');
};

subtest 'Run with SUBTEST_FILTER=データベース操作' => sub {
    local $ENV{SUBTEST_FILTER} = 'データベース操作';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ -.+\{/, 'データベース操作 executed');
    like($stdout, qr/# skip/, 'other subtests were skipped');
};

subtest 'Run with Japanese regex .*処理' => sub {
    local $ENV{SUBTEST_FILTER} = '.*処理';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ -.+\{/, 'subtests matching .*処理 executed');
    like($stdout, qr/# skip/, 'non-matching subtests were skipped');
};

subtest 'Run with nested Japanese filter トランザクション処理' => sub {
    local $ENV{SUBTEST_FILTER} = 'トランザクション処理';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ -.+\{/, 'parent and target subtest executed');
    like($stdout, qr/# skip/, 'other subtests were skipped');
};

subtest 'No match with Japanese filter 存在しないテスト' => sub {
    local $ENV{SUBTEST_FILTER} = '存在しないテスト';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    unlike($stdout, qr/ok \d+ -.+\{/, 'no subtests executed');
    like($stdout, qr/# skip/, 'all subtests were skipped');
};

# Direct test to verify Japanese matching works at the Perl level
subtest 'Direct Japanese regex matching' => sub {
    my $filter = 'ユーザー認証';
    my $name = 'ユーザー認証';
    my $regex = qr/\A$filter\z/u;

    ok($name =~ $regex, 'Japanese string matches Japanese regex');

    my $filter2 = '.*処理';
    my $name2 = '文字列処理';
    my $regex2 = qr/\A$filter2\z/u;

    ok($name2 =~ $regex2, 'Japanese string matches wildcard Japanese regex');
};

done_testing;
