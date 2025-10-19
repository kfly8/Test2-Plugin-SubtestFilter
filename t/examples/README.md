# Test Examples

This directory contains example test files used as fixtures for testing the Test2::Plugin::SubtestFilter module.

## Files

- `basic.t` - Basic test structure with nested subtests in English
- `japanese.t` - Test structure with Japanese subtest names (UTF-8)

## Purpose

These files are NOT meant to be run directly as part of the test suite. They are used by:
- `t/01_subtest_filter.t` - Tests the SUBTEST_FILTER functionality
- `t/02_japanese_filter.t` - Tests SUBTEST_FILTER with Japanese text

The actual tests use these files to verify that the SUBTEST_FILTER environment variable correctly filters subtests based on their names.