use Test2::V0;

use lib 't/lib';
use TestHelper;

my $test_file = 't/examples/syntax_variations.t';

my @tests = (
    {
        name => 'no SUBTEST_FILTER - all tests run',
        filter => undef,
        expect => {
            'standard_single'       => 'executed',
            'standard_double'       => 'executed',
            'paren_fat_comma'       => 'executed',
            'paren_comma'           => 'executed',
            'bareword'              => 'executed',
            'あああ'                => 'executed',
            'いいい'                => 'executed',
            '🎉🎊'                  => 'executed',
            'parent'                => 'executed',
            'parent > nested_paren' => 'executed',
            'parent > nested_bareword' => 'executed',
            'parent > ネスト'       => 'executed',
            'mixed-chars_123'       => 'executed',
            'foo: bar'              => 'executed',
            'ううう'                => 'executed',
            'dynamic_value'         => 'executed',  # Variable $var_name resolves to this at runtime
            'variable_parent'       => 'executed',
            'variable_parent > nested_dynamic' => 'executed',  # Variable $nested_var resolves to this
        },
    },
    {
        name => 'SUBTEST_FILTER=paren - matches parenthesized calls',
        filter => 'paren',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'executed',
            'paren_comma'           => 'executed',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'executed',
            'parent > nested_paren' => 'executed',
            # When parent matches, all children are executed
            'parent > nested_bareword' => 'executed',
            'parent > ネスト'       => 'executed',
            'mixed-chars_123'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=bareword - matches bareword',
        filter => 'bareword',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'executed',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            # parent is executed because it has a matching child (nested_bareword)
            'parent'                => 'executed',
            'parent > nested_paren' => 'skipped',
            'parent > nested_bareword' => 'executed',
            'parent > ネスト'       => 'skipped',
            'mixed-chars_123'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=あああ - matches Japanese',
        filter => 'あああ',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'executed',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'skipped',
            'mixed-chars_123'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=🎉 - matches emoji',
        filter => '🎉',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'executed',
            'parent'                => 'skipped',
            'mixed-chars_123'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER="parent nested_paren" - nested with paren',
        filter => 'parent nested_paren',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'executed',
            'parent > nested_paren' => 'executed',
            'parent > nested_bareword' => 'skipped',
            'parent > ネスト'       => 'skipped',
            'mixed-chars_123'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER="parent ネスト" - nested with Japanese',
        filter => 'parent ネスト',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'executed',
            'parent > nested_paren' => 'skipped',
            'parent > nested_bareword' => 'skipped',
            'parent > ネスト'       => 'executed',
            'mixed-chars_123'       => 'skipped',
            'foo: bar'              => 'skipped',
            'ううう'                => 'skipped',
            # Note: variable-based subtests are not checked as they cannot be parsed statically
            'variable_parent'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=ううう - matches non-ASCII bareword',
        filter => 'ううう',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'skipped',
            'mixed-chars_123'       => 'skipped',
            'foo: bar'              => 'skipped',
            'ううう'                => 'executed',
            'variable_parent'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=dynamic_value - matches runtime variable value',
        filter => 'dynamic_value',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'skipped',
            'mixed-chars_123'       => 'skipped',
            'foo: bar'              => 'skipped',
            'ううう'                => 'skipped',
            # At runtime, $var_name = 'dynamic_value', so it matches
            'dynamic_value'         => 'executed',
            'variable_parent'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=nested_dynamic - cannot match (not in parsed structure)',
        filter => 'nested_dynamic',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'skipped',
            'mixed-chars_123'       => 'skipped',
            'foo: bar'              => 'skipped',
            'ううう'                => 'skipped',
            'dynamic_value'         => 'skipped',
            # Variable-based subtests cannot be matched via static parsing
            # They would need runtime filtering (not currently supported)
            'variable_parent'       => 'skipped',
        },
    },
);

for my $tc (@tests) {
    subtest $tc->{name} => sub {
        my $stdout = run_test_file($tc->{file} // $test_file, $tc->{filter});

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
