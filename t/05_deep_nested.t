use Test2::V0;

use lib 't/lib';
use TestHelper;

my $test_file_deep = 't/examples/deep_nested.t';
my $test_file_basic = 't/examples/basic.t';

my @tests = (
    {
        name => 'SUBTEST_FILTER for 5-level deep path - full path match',
        file => $test_file_deep,
        filter => 'level1 level2 level3 level4 level5',
        expect => {
            'level1'                                => 'executed',
            'level1 > level2'                       => 'executed',
            'level1 > level2 > level3'              => 'executed',
            'level1 > level2 > level3 > level4'     => 'executed',
            'level1 > level2 > level3 > level4 > level5' => 'executed',
            'another' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER for deeply nested baz path - basic.t',
        file => $test_file_basic,
        filter => 'baz nested deep nested very deep',
        expect => {
            'foo'  => 'skipped',
            'bar'  => 'skipped',
            'baz'  => 'executed',
            'baz > nested deep' => 'executed',
            'baz > nested deep > nested very deep' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER for another branch deep path',
        file => $test_file_deep,
        filter => 'another branch deep deeper deepest',
        expect => {
            'level1'   => 'skipped',
            'another'  => 'executed',
            'another > branch' => 'executed',
            'another > branch > deep' => 'executed',
            'another > branch > deep > deeper' => 'executed',
            'another > branch > deep > deeper > deepest' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER with partial deep match - level5',
        file => $test_file_deep,
        filter => 'level5',
        expect => {
            'level1'  => 'executed',
            'level1 > level2' => 'executed',
            'level1 > level2 > level3' => 'executed',
            'level1 > level2 > level3 > level4' => 'executed',
            'level1 > level2 > level3 > level4 > level5' => 'executed',
            'another' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with partial deep match - deepest',
        file => $test_file_deep,
        filter => 'deepest',
        expect => {
            'level1'   => 'skipped',
            'another'  => 'executed',
            'another > branch' => 'executed',
            'another > branch > deep' => 'executed',
            'another > branch > deep > deeper' => 'executed',
            'another > branch > deep > deeper > deepest' => 'executed',
        },
    },
);

for my $tc (@tests) {
    subtest $tc->{name} => sub {
        my $stdout = run_test_file($tc->{file}, $tc->{filter});

        for my $name (sort keys %{$tc->{expect}}) {
            my $status = $tc->{expect}{$name};
            if ($status eq 'executed') {
                like($stdout, match_executed($name), "$name is executed");
            } elsif ($status eq 'skipped') {
                like($stdout, match_skipped($name), "$name is skipped");
            }
        }
    };
}

done_testing;
