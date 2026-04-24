# Frontend Test Results

## Command to Run

Run this command from the project root (watchlist-app):

```bash
npm --prefix client run test
```

If you want to run only the 2 integration tests:

```bash
npm --prefix client run test -- src/tests/integration.test.tsx
```

## Terminal Output

```text
> watchlist-app-client@0.1.0 test
> vitest run


 RUN  v2.1.9 /Users/zakariakhan/Documents/COP4331/large project/watchlist-app/client

 ✓ src/tests/integration.test.tsx (2) 1148ms
 ✓ src/utils/validation.test.ts (16)
   ✓ isEmailFormatValid (8)
     ✓ accepts a valid normal email
     ✓ accepts a valid email with numbers
     ✓ rejects an email missing @
     ✓ rejects an email missing domain
     ✓ rejects an email missing username
     ✓ rejects an empty string
     ✓ rejects whitespace-only input
     ✓ rejects malformed email format
   ✓ isPasswordStrong (8)
     ✓ accepts a valid strong password
     ✓ rejects a password that is too short
     ✓ rejects a password missing uppercase letters
     ✓ rejects a password missing lowercase letters
     ✓ rejects a password missing a number
     ✓ rejects a password missing a special character
     ✓ rejects an empty string
     ✓ rejects whitespace-only input

 Test Files  2 passed (2)
      Tests  18 passed (18)
   Start at  21:55:16
   Duration  2.20s (transform 105ms, setup 0ms, collect 284ms, tests 1.15s, environment 1.01s, prepare 129ms)
```

## Summary

- What was tested:
  - Integration flow 1: search input -> API mock call -> results rendered
  - Integration flow 2: click "+ Watchlist" -> API mock call -> success feedback shown
  - Unit validation tests: email format + password strength
- Number of test cases: 18 total (2 integration + 16 unit)
- Test result: All tests passed (18/18)

## Results Table

| Test Area | Cases Tested | Result |
| --- | --- | --- |
| Integration: Search flow | 1 | Passed |
| Integration: Add to watchlist flow | 1 | Passed |
| Email format validation | 8 | Passed |
| Password strength checker | 8 | Passed |
| Total | 18 | Passed |
