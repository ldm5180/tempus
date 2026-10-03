# tempus

SPARK-provable date/time primitives for Ada 2022 — RFC3339 timestamps,
proleptic-Gregorian ("civil") calendar arithmetic, time-of-day parsing, and a
civil-date + time-of-day → epoch combiner, packaged as a reusable,
independently proven crate.

The library is **pure**: zero IO, no `Ada.Calendar`. Everything is expressed
over plain epoch integers (`Tempus.Epoch_Seconds`, `Epoch_Milliseconds`,
`Day_Milliseconds`, `Packed_Date`), so callers inject the wall clock. The
RFC3339 parser (`Tempus.Rfc3339.Value`) is backed by an
[sml-ada](https://github.com/ldm5180/sml-ada) scanning state machine
(`Tempus.Rfc3339.Scanner`) that lexes the fields; the proven civil arithmetic
(`Tempus.Calendar`) turns them into an instant.

## Commands

- `make build`   — build the library (`alr build`)
- `make test`    — AUnit suite in BOTH modes (release -O3, debug -O0), offline
- `make features` — the Gherkin features under `tests/features/` in both
  modes, on fabula, printing the report as it goes (in colour on a
  terminal); checks the summary line, since fabula exits 0 for a
  missing path.  `alr test` runs them too
- `make features-report` — the living documentation: the features with
  `--report-json`, rendered by multiple-cucumber-html-reporter
  (`tools/features-report`, node) into `obj/features-report/html`.  CI
  keeps it with every run and publishes it from main to
  https://ldm5180.github.io/tempus/
- `make prove`   — SPARK proof, `--checks-as-errors=on`; must exit 0
- `make format`  — `gnatformat --check` over all committed Ada sources
- `make example` — build the examples both ways
- `make run` / `make run-trace` — run the release / debug (traced) example
- `alr --non-interactive build --validation` — warnings-as-errors gate (CI)

## Layout

- `src/`   — the library (pure SPARK; a unit may `with` only other `Tempus.*`
  units and `Sml.*` — never `Ada.Calendar`, files, or sockets).
- `tests/` — AUnit suite (`test_tempus.gpr`, driver `test_runner.adb`), fully
  offline (pure functions, no clock), and the features:
  `tests/features/*.feature` run by `tempus_features.ads` (Fabula.Main
  over `Tempus_Steps`).  Each feature's steps are an sml machine in its
  own child -- steps are its events, the conditions that chose a body
  its guards, the bodies its actions -- driven by `Tempus_Steps.Flows`;
  the registry offers every step to each feature as a region, and a
  step none takes fails, naming every region's state.  A feature's
  world is only the inputs its steps name: no clock, no IO.
- `proof/` — gnatprove harness (`proof.gpr`; sources `../src` directly and
  withs only `sml`, keeping foreign code out of the proof tree).
- `example/` — standalone demo mains (sml + tempus); example tracing is swapped
  in by the per-mode `cfg/{debug,release}/trace_config.ads` source dir.
- `docs/tdd-log.md` — git-ignored TDD audit log.

## SPARK

- Every `src/` unit carries `SPARK_Mode`. After any change, `make prove` must
  exit 0 (level 2, checks-as-errors). CI enforces the same.
- Prefer `Ok : out Boolean` results over exceptions; document and prove
  behavior with contracts (`Pre`, `Post`, loop invariants).
- `proof/proof.gpr` sources `src/` directly and withs only `sml` (never the
  Alire config gpr — that would drag dependencies into the proof tree).
  gnatprove reasons about a generic only through a concrete instance, so
  `proof/src/core_closure_proof.ads` withs every unit and the per-unit
  harnesses instantiate the generics.

## TDD protocol (strict)

- Red/green/refactor, always: failing test first (RED = compile error or failed
  assertion), then the minimal code (GREEN), then refactor under green. No
  production code without a preceding failing test.
- Log every cycle in `docs/tdd-log.md` (git-ignored, newest entries on top):
  date, what changed, exact RED output, GREEN pass counts.
- One `<unit>_tests.ads/.adb` pair per library unit under `tests/src/`,
  registered in `tempus_suite.adb`. Test routines use `AUnit.Assertions.Assert`
  and are wired via `Register_Routine`.
- Tests are layers -- guidance for judgement, not a mechanical rule.
  A unit test tests a single function, or at most a simple interaction
  between two, and the unit tests always cover the function they test
  completely.  A feature (BDD) tests the larger interactions that form
  a higher-level, conceptual feature, in a consumer's words, one fact
  per step, and checks only what a consumer could observe -- what a
  function returns or refuses, never how.  Duplication across the
  layers is fine: a test is removed only when it is an integration test
  a scenario fully supplants, and every tempus test exercises one
  function, so none has been.

## Programming best practices

- Lean hard into the type system; keep code DRY.
- Extract pure functions whenever possible — it forces naming and generality.
- Keep functions and procedures short and focused; move any second code block
  into its own named subprogram.
- Push exceptions and defensive programming into contracts and let the proof
  system do the heavy lifting; `SPARK_Mode => On` as much as possible.

## Style

- Formatting is `gnatformat`-enforced; wrap hand-aligned transition tables in
  `--!format off` / `--!format on`.
- Event enumeration literals take an `E_` prefix (sml convention), so operator
  wrapper constants can use the bare name.
- Follow the Alire validation-profile switch set; fix warnings, never suppress
  them without a comment saying why.

## Commit style

- gitmoji `:code:` shortcode prefix + capitalized, imperative subject, no
  trailing period (`:sparkles:` feature, `:bug:` fix, `:recycle:` refactor,
  `:white_check_mark:` tests, `:wrench:` tooling, `:memo:` docs, `:fire:`
  removal).
- Never put test / prove / format result counts in commit messages.

## Compatibility contract (do not break)

`Rfc3339.Image` emits exactly `YYYY-MM-DDThh:mm:ssZ` (UTC), and `Rfc3339.Value`
parses that plus the fractional and numeric-offset forms Go's `time.Time`
marshals, so an instant round-trips through a Go peer unchanged. The golden
vectors live in the tests — keep them green, and never change `Image`'s output
shape.
