use Test2::V0;
use Test2::Plugin::UTF8;
use Capture::Tiny qw(capture);
use File::Spec ();
use Encode qw(encode_utf8);

my $test_file = File::Spec->catfile('t', 'examples', 'japanese.t');

subtest 'Run with SUBTEST_FILTER=ユーザー認証' => sub {
    local $ENV{SUBTEST_FILTER} = encode_utf8 'ユーザー認証';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - ユーザー認証 \{/);
    like($stdout, qr/データベース操作 # skip/);
    like($stdout, qr/文字列処理 # skip/);
    like($stdout, qr/テスト用データ # skip/);
};

# subtest 'Run with SUBTEST_FILTER=データベース操作' => sub {
#     local $ENV{SUBTEST_FILTER} = encode_utf8 'データベース操作';
#
#     my ($stdout, $stderr, $exit) = capture {
#         system($^X, '-Ilib', $test_file);
#     };
#
#     is($exit >> 8, 0, 'exit code is 0');
#     like($stdout, qr/ok \d+ -.+\{/, 'データベース操作 executed');
#     like($stdout, qr/# skip/, 'non-matching tests are skipped');
# };
#
# subtest 'Run with Japanese substring 処理' => sub {
#     local $ENV{SUBTEST_FILTER} = encode_utf8 '処理';
#
#     my ($stdout, $stderr, $exit) = capture {
#         system($^X, '-Ilib', $test_file);
#     };
#
#     is($exit >> 8, 0, 'exit code is 0');
#     like($stdout, qr/ok \d+ -.+\{/, 'subtests matching 処理 executed');
#     # Filtering now works correctly
#     like($stdout, qr/# skip/, 'non-matching tests are skipped');
# };
#
# subtest 'Run with space-separated Japanese path' => sub {
#     local $ENV{SUBTEST_FILTER} = encode_utf8 'データベース操作 トランザクション処理';
#
#     my ($stdout, $stderr, $exit) = capture {
#         system($^X, '-Ilib', $test_file);
#     };
#
#     is($exit >> 8, 0, 'exit code is 0');
#     like($stdout, qr/ok \d+ -.+\{/, 'parent and target subtest executed');
#     # Current implementation runs all tests due to heuristic
#     unlike($stdout, qr/# skip/, 'all tests run due to heuristic');
# };
#
# subtest 'No match with Japanese filter 存在しないテスト - skips all' => sub {
#     local $ENV{SUBTEST_FILTER} = encode_utf8 '存在しないテスト';
#
#     my ($stdout, $stderr, $exit) = capture {
#         system($^X, '-Ilib', $test_file);
#     };
#
#     is($exit >> 8, 0, 'exit code is 0');
#     # Non-matching filters now properly skip tests
#     like($stdout, qr/# skip/, 'tests are skipped for non-matching filter');
#     unlike($stdout, qr/ok \d+ -.+\{/, 'no tests executed for non-matching filter');
# };

done_testing;
