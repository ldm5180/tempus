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
- `make prove`   — SPARK proof, `--checks-as-errors=on`; must exit 0
- `make format`  — `gnatformat --check` over all committed Ada sources
- `make example` — build the examples both ways
- `make run` / `make run-trace` — run the release / debug (traced) example
- `alr --non-interactive build --validation` — warnings-as-errors gate (CI)

## Layout

- `src/`   — the library (pure SPARK; a unit may `with` only other `Tempus.*`
  units and `Sml.*` — never `Ada.Calendar`, files, or sockets).
- `tests/` — AUnit suite (`test_tempus.gpr`, driver `test_runner.adb`), fully
  offline (pure functions, no clock).
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
