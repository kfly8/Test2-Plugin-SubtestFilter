---
name: perl-test
description: Run Perl tests, check code quality, and build the Test2::Plugin::SubtestFilter module
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
---

# Perl Test Skill

This skill helps with common Perl testing and development tasks for the Test2::Plugin::SubtestFilter project.

## Context

Test2::Plugin::SubtestFilter is a Test2 plugin that allows selective running of specific subtests based on environment variables. This is useful during development and debugging.

## Common Tasks

### 1. Running Tests

**Run all tests:**
```bash
prove -lv t/
```

**Run specific test file:**
```bash
prove -lv t/01_subtest_filter.t
```

**Run tests with subtest filtering:**
```bash
SUBTEST_FILTER='pattern' prove -lv t/
```

**Run tests with debug mode:**
```bash
SUBTEST_FILTER_DEBUG=1 SUBTEST_FILTER='pattern' prove -lv t/
```

### 2. Code Quality

**Check Perl syntax:**
```bash
perl -c lib/Test2/Plugin/SubtestFilter.pm
```

**Check all test files:**
```bash
find t/ -name '*.t' -exec perl -c {} \;
```

### 3. Building

**Build the module:**
```bash
perl Build.PL && ./Build
```

**Run tests through Build:**
```bash
./Build test
```

### 4. Development with Minil

This project uses Minil for development.

**Run minil test:**
```bash
minil test
```

**Build distribution:**
```bash
minil dist
```

### 5. Dependencies

**Install dependencies:**
```bash
cpanm --installdeps .
```

## Workflow Examples

**Quick test cycle:**
1. Make code changes
2. Run syntax check: `perl -c lib/Test2/Plugin/SubtestFilter.pm`
3. Run specific test: `prove -lv t/01_subtest_filter.t`
4. Run all tests: `prove -lv t/`

**Test specific functionality:**
1. Identify the subtest name to test
2. Use SUBTEST_FILTER: `SUBTEST_FILTER='pattern' prove -lv t/filename.t`
3. Enable debug mode if needed: `SUBTEST_FILTER_DEBUG=1`

**Before committing:**
1. Run all tests: `prove -lv t/`
2. Check code quality
3. Update Changes file if needed
4. Verify POD documentation is up to date

## Project Structure

- `lib/Test2/Plugin/SubtestFilter.pm` - Main module
- `t/` - Test files
- `t/examples/` - Example test files
- `Build.PL` - Build configuration
- `minil.toml` - Minilla configuration
- `cpanfile` - Dependencies

## Important Notes

- This project uses Test2::V0 for testing
- UTF-8 support is important (handles Japanese and emoji in test names)
- The plugin must be loaded AFTER Test2::V0 or Test2::Tools::Subtest
- Environment variable `SUBTEST_FILTER` controls test filtering
- Environment variable `SUBTEST_FILTER_DEBUG` enables debug output
