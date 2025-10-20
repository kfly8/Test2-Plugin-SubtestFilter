use Test2::V0;
use Test2::Plugin::UTF8;
use Capture::Tiny qw(capture);
use File::Spec ();
use Encode qw(encode_utf8 decode_utf8);

my $test_file = File::Spec->catfile('t', 'examples', 'japanese.t');

subtest 'no SUBTEST_FILTER - all tests run' => sub {
    local $ENV{SUBTEST_FILTER};
    delete $ENV{SUBTEST_FILTER};

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };
    $stdout = decode_utf8($stdout);

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - ユーザー認証 \{/, 'ユーザー認証 is executed');
    like($stdout, qr/ok \d+ - データベース操作 \{/, 'データベース操作 is executed');
    like($stdout, qr/ok \d+ - 文字列処理 \{/, '文字列処理 is executed');
    like($stdout, qr/ok \d+ - テスト用データ \{/, 'テスト用データ is executed');
    like($stdout, qr/ok \d+ - パスワード検証 \{/, 'パスワード検証 is executed');
    like($stdout, qr/ok \d+ - トークン管理 \{/, 'トークン管理 is executed');
    like($stdout, qr/ok \d+ - トランザクション処理 \{/, 'トランザクション処理 is executed');
    like($stdout, qr/ok \d+ - 正規表現マッチング \{/, '正規表現マッチング is executed');
    like($stdout, qr/ok \d+ - 漢字かな混じり \{/, '漢字かな混じり is executed');
};

subtest 'Run with SUBTEST_FILTER=ユーザー認証' => sub {
    local $ENV{SUBTEST_FILTER} = encode_utf8 'ユーザー認証';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };
    $stdout = decode_utf8($stdout);

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - ユーザー認証 \{/);
    like($stdout, qr/データベース操作 # skip/);
    like($stdout, qr/文字列処理 # skip/);
    like($stdout, qr/テスト用データ # skip/);
};

subtest 'Run with SUBTEST_FILTER=データベース操作' => sub {
    local $ENV{SUBTEST_FILTER} = encode_utf8 'データベース操作';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };
    $stdout = decode_utf8($stdout);

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - データベース操作 \{/, 'データベース操作 executed');
    like($stdout, qr/ユーザー認証 # skip/, 'non-matching tests are skipped');
};

subtest 'Run with Japanese substring 処理 - matches multiple' => sub {
    local $ENV{SUBTEST_FILTER} = encode_utf8 '処理';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };
    $stdout = decode_utf8($stdout);

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - ユーザー認証 # skip/, 'ユーザー認証 is skipped');
    like($stdout, qr/ok \d+ - データベース操作 \{/, 'データベース操作 matches 処理 substring');
    like($stdout, qr/ok \d+ - 文字列処理 \{/, '文字列処理 matches 処理 substring');
    like($stdout, qr/ok \d+ - テスト用データ # skip/, 'テスト用データ is skipped');
};

subtest 'Run with space-separated Japanese path' => sub {
    local $ENV{SUBTEST_FILTER} = encode_utf8 'データベース操作 トランザクション処理';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };
    $stdout = decode_utf8($stdout);

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - データベース操作 \{/, 'parent subtest executed');
    like($stdout, qr/ok \d+ - トランザクション処理 \{/, 'target subtest executed');
    like($stdout, qr/ユーザー認証 # skip/, 'non-matching tests are skipped');
};

subtest 'SUBTEST_FILTER for deeply nested child 漢字かな混じり' => sub {
    local $ENV{SUBTEST_FILTER} = encode_utf8 '漢字かな混じり';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };
    $stdout = decode_utf8($stdout);

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - ユーザー認証 # skip/, 'ユーザー認証 is skipped');
    like($stdout, qr/ok \d+ - データベース操作 # skip/, 'データベース操作 is skipped');
    like($stdout, qr/ok \d+ - 文字列処理 \{/, '文字列処理 is executed (grandparent)');
    like($stdout, qr/ok \d+ - 正規表現マッチング \{/, '正規表現マッチング is executed (parent)');
    like($stdout, qr/ok \d+ - 漢字かな混じり \{/, '漢字かな混じり is executed');
    like($stdout, qr/ok \d+ - テスト用データ # skip/, 'テスト用データ is skipped');
};

subtest 'SUBTEST_FILTER="パスワード検証" - explores top level for multi-word' => sub {
    local $ENV{SUBTEST_FILTER} = encode_utf8 'パスワード検証';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };
    $stdout = decode_utf8($stdout);

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - ユーザー認証 \{/, 'ユーザー認証 explored and matches');
    like($stdout, qr/ok \d+ - パスワード検証 \{/, 'パスワード検証 found and executed');
    like($stdout, qr/ok \d+ - トークン管理 # skip/, 'トークン管理 is skipped');
    like($stdout, qr/ok \d+ - データベース操作 # skip/, 'データベース操作 is skipped');
    like($stdout, qr/ok \d+ - 文字列処理 # skip/, '文字列処理 is skipped');
    like($stdout, qr/ok \d+ - テスト用データ # skip/, 'テスト用データ is skipped');
};

subtest 'No match with Japanese filter 存在しないテスト - skips all' => sub {
    local $ENV{SUBTEST_FILTER} = encode_utf8 '存在しないテスト';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };
    $stdout = decode_utf8($stdout);

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - ユーザー認証 # skip/, 'ユーザー認証 is skipped');
    like($stdout, qr/ok \d+ - データベース操作 # skip/, 'データベース操作 is skipped');
    like($stdout, qr/ok \d+ - 文字列処理 # skip/, '文字列処理 is skipped');
    like($stdout, qr/ok \d+ - テスト用データ # skip/, 'テスト用データ is skipped');
    like($stdout, qr/# skip/, 'tests are skipped for non-matching filter');
};

subtest 'SUBTEST_FILTER with partial nested path match - single word' => sub {
    local $ENV{SUBTEST_FILTER} = encode_utf8 'トラン';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };
    $stdout = decode_utf8($stdout);

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - ユーザー認証 # skip/, 'ユーザー認証 is skipped');
    like($stdout, qr/ok \d+ - データベース操作 \{/, 'データベース操作 explored and matches');
    like($stdout, qr/ok \d+ - トランザクション処理 \{/, 'トランザクション処理 found and executed');
    like($stdout, qr/ok \d+ - 文字列処理 # skip/, '文字列処理 is skipped');
    like($stdout, qr/ok \d+ - テスト用データ # skip/, 'テスト用データ is skipped');
};

subtest 'SUBTEST_FILTER with partial nested path match - two words' => sub {
    local $ENV{SUBTEST_FILTER} = encode_utf8 '文字列処理 正規';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };
    $stdout = decode_utf8($stdout);

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - ユーザー認証 # skip/, 'ユーザー認証 is skipped');
    like($stdout, qr/ok \d+ - データベース操作 # skip/, 'データベース操作 is skipped');
    like($stdout, qr/ok \d+ - 文字列処理 \{/, '文字列処理 explored and matches');
    like($stdout, qr/ok \d+ - 正規表現マッチング \{/, '正規表現マッチング found and executed');
    like($stdout, qr/ok \d+ - テスト用データ # skip/, 'テスト用データ is skipped');
};

subtest 'SUBTEST_FILTER with partial match behavior - short substring' => sub {
    local $ENV{SUBTEST_FILTER} = encode_utf8 'デ';

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $test_file);
    };
    $stdout = decode_utf8($stdout);

    is($exit >> 8, 0, 'exit code is 0');
    like($stdout, qr/ok \d+ - ユーザー認証 # skip/, 'ユーザー認証 is skipped');
    like($stdout, qr/ok \d+ - データベース操作 \{/, 'データベース操作 matches デ substring');
    like($stdout, qr/ok \d+ - 文字列処理 # skip/, '文字列処理 is skipped');
    like($stdout, qr/ok \d+ - テスト用データ \{/, 'テスト用データ matches デ substring');
};

done_testing;
