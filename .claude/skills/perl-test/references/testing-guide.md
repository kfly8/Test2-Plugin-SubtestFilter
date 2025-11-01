# Testing Guide for Test2::Plugin::SubtestFilter

## Overview

This document provides guidance on testing the Test2::Plugin::SubtestFilter module.

## Test Files

### Core Functionality Tests

- `t/01_subtest_filter.t` - Basic subtest filtering functionality
- `t/02_japanese_filter.t` - Japanese character support in subtest names
- `t/03_emoji_filter.t` - Emoji support in subtest names
- `t/04_debug_mode.t` - Debug mode functionality
- `t/05_deep_nested.t` - Deeply nested subtest structures
- `t/06_syntax_variations.t` - Various subtest syntax patterns
- `t/07_apply_plugin.t` - Plugin application mechanism

### Example Files (in t/examples/)

- `basic.t` - Simple usage examples
- `japanese.t` - Japanese character examples
- `emoji.t` - Emoji usage examples
- `deep_nested.t` - Complex nested structures
- `syntax_variations.t` - Different syntax styles
- `complicated.t` - Complex real-world scenarios
- `edge_cases.t` - Edge cases and corner scenarios

## Environment Variables

### SUBTEST_FILTER

Regular expression pattern for filtering subtests:

```bash
# Match 'foo' anywhere in the name
SUBTEST_FILTER=foo prove -lv t/

# Match exact pattern with regex
SUBTEST_FILTER='^foo$' prove -lv t/

# Match multiple patterns
SUBTEST_FILTER='foo|bar' prove -lv t/

# Match Japanese characters
SUBTEST_FILTER='テスト' prove -lv t/02_japanese_filter.t

# Match emoji
SUBTEST_FILTER='🎉' prove -lv t/03_emoji_filter.t
```

### SUBTEST_FILTER_DEBUG

Enable debug output to see which subtests are being skipped:

```bash
SUBTEST_FILTER_DEBUG=1 SUBTEST_FILTER=foo prove -lv t/
```

## Testing Patterns

### Test Individual Features

Test a specific feature by running its test file:

```bash
prove -lv t/01_subtest_filter.t
```

### Test with Filtering

Test the filtering mechanism itself:

```bash
SUBTEST_FILTER='specific test' prove -lv t/01_subtest_filter.t
```

### Test Nested Subtests

Test deeply nested structures:

```bash
prove -lv t/05_deep_nested.t

# Filter to specific nested level
SUBTEST_FILTER='level 2' prove -lv t/05_deep_nested.t
```

### Test UTF-8 Support

Test Japanese and emoji support:

```bash
prove -lv t/02_japanese_filter.t
prove -lv t/03_emoji_filter.t
```

### Test All Syntax Variations

Ensure all supported syntax patterns work:

```bash
prove -lv t/06_syntax_variations.t
```

## Common Test Scenarios

### Debugging Test Failures

1. Run the failing test with verbose output:
   ```bash
   prove -lv t/failing_test.t
   ```

2. Enable debug mode to see filtering behavior:
   ```bash
   SUBTEST_FILTER_DEBUG=1 prove -lv t/failing_test.t
   ```

3. Check syntax of the module:
   ```bash
   perl -c lib/Test2/Plugin/SubtestFilter.pm
   ```

### Adding New Tests

1. Create test file in `t/` or `t/examples/`
2. Use Test2::V0 for the test framework
3. Load Test2::Plugin::SubtestFilter after Test2::V0
4. Write subtests using various syntax patterns
5. Test with and without SUBTEST_FILTER

### Regression Testing

Run all tests to ensure no regressions:

```bash
prove -lv t/
```

## Module Testing Workflow

### Before Committing Changes

```bash
# 1. Check syntax
perl -c lib/Test2/Plugin/SubtestFilter.pm

# 2. Run all tests
prove -lv t/

# 3. Test with filtering
SUBTEST_FILTER=example prove -lv t/

# 4. Test with debug mode
SUBTEST_FILTER_DEBUG=1 SUBTEST_FILTER=example prove -lv t/
```

### After Making Changes

```bash
# Test specific functionality affected by changes
prove -lv t/affected_test.t

# Run full test suite
prove -lv t/

# Build and test
perl Build.PL && ./Build && ./Build test
```

## Tips

1. **UTF-8 Terminal**: Ensure your terminal supports UTF-8 for Japanese and emoji tests
2. **Verbose Mode**: Use `-lv` flags with prove for detailed output
3. **Test Isolation**: Each test file should be independent
4. **Clean Environment**: Tests should not depend on external state
5. **Documentation**: Update POD documentation when adding features
