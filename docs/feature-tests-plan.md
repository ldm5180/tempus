# Feature tests plan

**Status:** planned 2026-10-03; F0-F2 done 2026-10-03, F3-F8 not started.

The crate's behavior, stated in Gherkin and run against the proven
functions.  `*.feature` files under `tests/features/` say what the
calendar does -- a leap day exists every fourth year but not every
hundredth, an instant formats the way a Go peer reads it, a date and a
time of day name the same instant a timestamp does -- and a small Ada
step registry on [fabula](https://github.com/ldm5180/fabula) runs
them.  The AUnit suite keeps the function-level detail, assertion by
assertion; the features keep the story.

This is the third of a family: `fructus/docs/feature-tests-plan.md`
and `nuntius/docs/feature-tests-plan.md` came first, and the nuntius
one was implemented (nuntius PR #4, merged 2026-10-03), which settled
four things every later plan starts from: the step code is sml state
machines from the first line, `make features` streams its report in
colour, the features are published as living documentation, and the
unit tests stay.  What is different here is the world: nuntius is the
wire and stands up loopback sockets; tempus is a pure core with no IO
at all, so a feature's world is nothing but the inputs it names.

## How to use this plan

Work the items in order; each is one TDD cycle (RED first, the exact
assertion given) and one commit, logged in `docs/tdd-log.md`.  F0 is
the dependency, F1 the runner and the Makefile target, F2 the machine
runner and the registry, with nothing of the crate's behavior in
them; F3-F6 are the four features, each lifted from the named AUnit
tests; F7 is the living documentation; F8 the docs.  After each item:
`alr --non-interactive build --validation`, `make test`,
`make features`, `make format`.  Nothing in this plan touches `src/`,
so `make prove` is never owed by it.

Five decisions, taken up front -- each is a lesson the nuntius work
paid for, recorded in the memory the plans share:

- **The steps are sml machines from the start.**  Each feature's
  steps are a state machine in a child package: the steps are its
  events, every condition that would choose between bodies is a
  guard, the bodies are actions, and a guarded row is followed by an
  unguarded fallback row whose action fails the step with the reason.
  A step taken out of order fails, naming every feature's state.
  nuntius was written with `case` dispatch first and refactored; this
  crate skips that round.
- **One test project, two mains.**  `tests/test_tempus.gpr` gains
  `with "fabula"` and a second main; the step packages live in
  `tests/src/` beside `Tempus_Test_Support`, whose golden vectors they
  reuse.  `make format`'s `tests/src/*.ad[sb]` glob covers them.
- **The features are published.**  `make features-report` renders the
  runner's `--report-json` with multiple-cucumber-html-reporter; CI
  keeps the page with every run and deploys it from main to GitHub
  Pages.
- **No AUnit test is removed.**  The settled guidance: a unit test
  tests a single function, or a simple interaction between two, and
  the unit tests always cover their function completely; a feature
  tests the larger interactions that form a higher-level conceptual
  feature; a test is removed only when it is an integration test a
  scenario fully supplants.  Every tempus test exercises one function
  of one unit (`Image`, `Value`, `Valid_Date`, `Parse`, `Epoch_Ms`,
  ...), so none qualifies, and the plan has no pruning item -- the
  features duplicate them on purpose.
- **A feature binds behavior; the unit tests hold the mechanism.**
  Every check in a feature is something a consumer of tempus could
  observe at the crate's edge -- what a function returns, what it
  refuses -- and would want promised; never how it gets there: no
  field of a result the contract does not promise, no bound's number,
  no branch of a step machine made visible.  Setup may be white-box
  (an input is an input).  A step that wants the how is not written;
  the unit test for that function is extended instead.  Three such
  checks came out of this plan in its last pass (Revision notes).

### Do not

- Do not reach for a clock.  The crate has none and the features
  have none: every instant is a number in the feature file.
- Do not let a `{float}` capture carry an instant.  An epoch in
  seconds fits `Fabula.Args.Int` (32-bit); an epoch in milliseconds
  does not and reads through `Fabula.Args.Long` -- never through
  `Long_Float`.  Fractions of a second appear only inside a timestamp
  word, which `Tempus.Rfc3339.Value` parses itself.
- Do not quote a timestamp.  fabula's `{string}` is double-quoted
  only; a timestamp, a date or a time of day is a `{word}` capture,
  which holds `:`, `+`, `-`, `.`, `T` and `Z` -- verified, section 5.
- Do not restate a unit test's assertions line for line.  "February
  never has 30 days" is a feature; the exact `Timestamp_String`
  bound, the `Max_Formattable` constant, the `Pre` on `Civil_From_Days`
  are the unit tests' and the proof's.
- Do not write a step body with an `if` over the step's arguments.
  The condition is a guard; the two bodies are two rows.
- Do not check how.  A step that wants a byte, an internal count, a
  result's field beyond what the contract promises, a bound's number
  or which branch ran is a unit test; the feature keeps the outcome.
  The `Ms = 0` a refused time of day leaves, the formattable bound and
  the clamp of a garbage packed date stay with `Test_Malformed`,
  `Test_Image` and `Test_Epoch_Ms`.
- Do not name a package or a subprogram in a scenario's title or a
  feature's description.  If the sentence needs one to make sense, it
  is a unit test.
- Do not add fabula to `proof/proof.gpr`.  It is a test dependency;
  the proof tree sources `src/` and withs only `sml`.
- Do not fix fabula's `-gnatwu` warning (`fabula-run.adb:258`, a GNAT
  15 false positive) from here.  Under the dependency profile it is a
  warning, and this crate builds clean with it under `--validation`.

## 1. What fabula is, in the terms this crate uses

A fabula binary is one instantiation of `Fabula.Main` over a
`Fabula.Registry` instance: an enumeration of step kinds, a table
mapping a Cucumber-expression pattern to a kind
(`Step ("{word} parses to the instant {int}") >= E_Parse`), an
enumeration of hook kinds with its table, a `Context` record one
scenario owns, and two procedures -- `Execute (Kind, Ctx, Args, Frame,
Outcome)` and `Run_Hook`.  Checks record into an `Outcome`
(`Fabula.Check.Ints.Equal`, `Fabula.Check.Longs.Equal`,
`Fabula.Check.Text_Equal`, `Fabula.Check.Is_True`, `Fail_Step`); a step
body that raises becomes a failed step and the run goes on.  Captures
read 1-based (`Fabula.Args.Int`, `.Long`, `.Text`, `.Word`); a step's
data table reads as raw cells or as hashes.  The binary walks its
paths sorted, exits 1 on any failed scenario, and prints
`N Scenarios (...)`.

The registry does not dispatch the steps itself.  `Execute` offers
each step to every feature's machine (a region), each machine takes
only its own events, and a step no machine takes fails with every
machine's state in the message.  The machines are instances of one
generic runner, `Tempus_Steps.Flows` (section 2), over
`Sml.Simple_Machines`: the whole `Step_Kind` is the event type, a
`Step_Context` -- the scenario's `World`, the step's arguments, frame
and outcome, and an optional follow-up event -- is the context, and
`Take` makes the machine at the feature's current state, processes the
step, then any follow-up an action asked for, and keeps the state.

fabula copies the `Context` once per step.  Here that costs nothing:
a tempus scenario's world is a handful of numbers and one short
string.

## 2. Where things live

```
tests/
  features/
    timestamps.feature         F3  an instant formats, parses, round-trips
    calendar.feature           F4  leap years, month lengths, days since the epoch
    time-of-day.feature        F5  HH:MM and HH:MM:SS as milliseconds into a day
    instants.feature           F6  a date and a time of day name an instant
  src/
    tempus_features.ads        F1  the main: Fabula.Main instantiated
    tempus_steps.ads/.adb      F1  Step_Kind, the tables, Step_Context, the regions
    tempus_steps-flows.ads/.adb    F2  the generic machine runner
    tempus_steps-timestamps.ads/.adb   F3  one machine per feature
    tempus_steps-calendar.ads/.adb     F4
    tempus_steps-time_of_day.ads/.adb  F5
    tempus_steps-instants.ads/.adb     F6
    tempus_test_support.ads        unchanged: the golden vectors
  test_tempus.gpr              F1  with "fabula"; a second main
tools/
  features-report/             F7  report.js, package.json, package-lock.json
```

No `tests/features/bytes/`: nothing in tempus is longer than a
feature line (`Fabula.Limits.Max_Line_Length` is 2 048; the longest
input here is a 35-character timestamp).  The convention stands if
that changes: one `<name>.hex` per sequence, named from a step.

## 3. The step vocabulary

Every pattern, the kind it names, and the action behind it.  A
timestamp, a date or a time of day is written as the operator reads
it and captured as a `{word}`; an epoch in seconds is an `{int}`; an
epoch in milliseconds or a day-milliseconds count is an `{int}` read
with `Fabula.Args.Long`.  Civil fields (`2026`, `2`, `29`) are `{int}`s.

| Pattern | Kind | Action |
|---|---|---|
| `the instant {int} formats as {word}` | `E_Image` | `Rfc3339.Image (T)` equals the word |
| `{word} parses to the instant {int}` | `E_Parse` | `Rfc3339.Value`; Ok and the value |
| `{word} is refused` | `E_Refuse` | `Rfc3339.Value`; not Ok |
| `the instant {int} formats and parses back` | `E_Round_Trip` | `Value (Image (T)) = T` |
| `{int}-{int}-{int} is a valid date` | `E_Valid` | `Calendar.Valid_Date` at midnight |
| `{int}-{int}-{int} is not a valid date` | `E_Invalid` | its negation |
| `{int}-{int}-{int} {int}:{int}:{int} at offset {int} is the instant {int}` | `E_To_Epoch` | `Calendar.To_Epoch` |
| `day {int} since the epoch is {int}-{int}-{int}` | `E_Civil` | `Calendar.Civil_From_Days` |
| `{word} is {int} ms into the day` | `E_Tod` | `Time_Of_Day.Parse`; Ok and the value (`Long`) |
| `{word} is not a time of day` | `E_Tod_Refused` | `Time_Of_Day.Parse`; not Ok (the `Ms = 0` it leaves is `Test_Malformed`'s) |
| `the date {int} at {int} ms is the instant {int} ms` | `E_Epoch_Ms` | `Instants.Epoch_Ms`; both counts `Long` |
| `the date {int} at {word} is the same instant as {word}` | `E_Agree` | `Epoch_Ms (Date, Parse (Tod)) / 1000 = Value (Stamp)` |

The `{int}-{int}-{int}` date patterns are three captures with literal
hyphens between them: `-` is literal in a fabula pattern (`{int}`'s
own grammar is `-?[0-9]+`, and a capture takes the longest digit run
before the literal).  A `/` would not be: after a word letter it is a
choice operator and cannot be escaped, which is why no pattern here
spells a date with slashes.

### 3.1 Guards, and what a refusal says

Each machine's guards are the conditions a `case`-and-`if` body would
have tested, with the fallback row saying why the step did not run:

- `Count_Given (N)` -- capture N reads as a whole number of zero or
  more (the shared `Count_Read`); the fallback fails with the read's
  own reason (`Fabula.Check.Ints.Fail_Read`) or "a count cannot be
  negative".
- `Formattable` -- the captured instant is at most
  `Rfc3339.Max_Formattable`; the fallback says "past the formattable
  bound".
- `Epoch_Seconds_Given` -- the captured instant fits
  `Tempus.Epoch_Seconds` (48 bits; read through `Args.Long`).
- `Field_Ranges` -- the six civil fields are inside `To_Epoch`'s
  precondition (`0 .. 9_999`, `0 .. 99` ...), so a feature cannot make
  a proven precondition fail at run time; the fallback names the
  field.
- `Days_In_Range` -- `Civil_From_Days`'s `0 .. 3_000_000`.
- `Day_Ms_Given` -- a day-milliseconds count is at most `86_400_000`.

A refusal is a `Fail_Step` with the reason, never a raise: the
proven preconditions are honored by the guard, not discovered by a
`Constraint_Error` in the step.  A guard's fallback is how a feature
reports a vector it cannot take; it is never itself a scenario -- a
scenario that exists to show a guard refusing tests the step machine,
not the crate.

### 3.2 States

A pure core has little to sequence, and the machines say so rather
than pretend: `timestamps` has one state and every row loops on it,
because an `Image` and a `Parse` do not depend on each other.  The
one real sequence is `instants`: `Agreed` is reached only through a
`Then_Take` follow-up event after the two parses succeed, so the
comparison row's guard reads their outcome -- the "act, then branch
on the result" shape, and the one place this crate's machines show
it.  A feature whose steps never depend on order still fails an
unknown step with every machine's state named, which is what the
region dispatch buys.

## 4. Items

### F0 -- fabula is a test dependency

- **Where:** `alire.toml:16` (`aunit`, the one existing test
  dependency), `:22` (`[[pins]]`, whose comment already states the
  rule: a consumer must pin the same `sml`).
- **What is wrong:** nothing runs a `.feature` file.
- **Why:** the suite is AUnit end to end.
- **Fix:** `fabula = "*"` after `aunit`, and under `[[pins]]`
  `fabula = { url = "https://github.com/ldm5180/fabula.git", commit = "746a234df5581c2e38c4202aeee8b07473fb6a51" }`
  with a comment in the house shape.  fabula pins `sml 3ccd0e4`,
  which is this crate's pin since the 2026-10-03 bump; Alire refuses
  two links to one crate at different commits, so that equality is
  the precondition and the comment at `:22` is where it is stated.
  No chain is needed: nothing but sml sits under fabula.
- **RED first:** `alr --non-interactive build --validation` with only
  the dependency line and no pin warns `Generating possibly incomplete
  configuration because of missing dependencies` (fabula is in no
  index); with the pin it builds, verified in section 5 at 2.6 s.

### F1 -- The feature binary builds, and `make features` streams it in colour

- **Where:** `tests/test_tempus.gpr:1-2` (`with "aunit"; with
  "../tempus.gpr";`) and `:16` (`for Main`); `alire.toml:35-50` (the
  four `[[actions]]` of type `test`); `Makefile:8` (`.PHONY`), `:17-21`
  (`test:`), `:29-34` (`format:`); `.github/workflows/ci.yml:39-44`
  (the `alr test` step).
- **Fix:** `with "fabula";` beside `aunit` and
  `for Main use ("test_runner.adb", "tempus_features.ads");` -- a
  generic instantiation is a SPEC, so the main is an `.ads`.
  `tests/src/tempus_features.ads` instantiates `Fabula.Main` over
  `Tempus_Steps`.  For this item alone, `Tempus_Steps` holds the
  three-step smoke vocabulary of section 5 (a count kept and checked),
  already in the machine shape F2 generalizes, so the runner is proved
  before any feature is written.  Two more `[[actions]]` after the
  existing four, argv-only like them:
  `["alr", "exec", "--", "tests/bin/release/tempus_features", "tests/features"]`
  and its `debug` twin.  The `features` target, taken from nuntius's
  Makefile as it stands after PR #4 -- streaming, and in colour when
  make writes to a terminal:

  ```make
  ## features    Build and run the Gherkin features in both modes, printing
  ##             the runner's report as it goes -- in colour when make writes
  ##             to a terminal: fabula colours only a terminal, so the runner
  ##             then runs under script(1) for a pseudo-terminal while tee
  ##             keeps a copy.  fabula exits 0 for a missing path or an empty
  ##             file, so the summary line, not the exit status alone, is
  ##             what says every scenario passed
  features:
  	alr exec -- gprbuild -p -j0 -XMODE=debug -P tests/test_tempus.gpr
  	alr exec -- gprbuild -p -j0 -XMODE=release -P tests/test_tempus.gpr
  	@log=$$(mktemp) && rc=$$(mktemp) && trap 'rm -f $$log $$rc' EXIT && \
  	if [ -t 1 ]; then tty=yes; else tty=; fi; \
  	for mode in debug release; do \
  	  echo "== features ($$mode)"; \
  	  run="alr exec -- tests/bin/$$mode/tempus_features tests/features"; \
  	  { if [ -n "$$tty" ]; then script -qefc "$$run" /dev/null; \
  	    else $$run; fi; echo $$? > $$rc; } | tee $$log; \
  	  [ "$$(cat $$rc)" = 0 ] || \
  	    { echo "features: $$mode: the runner failed"; exit 1; }; \
  	  sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\r$$//' $$log | \
  	    grep -qE '^[1-9][0-9]* Scenarios? \([0-9]+ passed\)$$' || \
  	    { echo "features: $$mode: a scenario did not pass"; exit 1; }; \
  	done; echo 'features: every scenario passed in both modes'
  ```

  `features` joins `.PHONY`.  The CI workflow needs no new step for
  this item: `alr test` runs the actions.  New files must be
  `git add -N`'d before `make format` sees them -- its globs are
  `git ls-files`.
- **RED first:** `make features` -- "No rule to make target".  Then,
  with the target and an empty step table, the smoke scenario's first
  step is `UNDEFINED` and the binary exits 1; the rows turn it green,
  and a check before any count is refused as out of order (section 5
  shows both outputs).

### F2 -- The machine runner and the registry as regions

- **Where:** `tests/src/tempus_steps.ads/.adb` (from F1),
  `tests/src/tempus_steps-flows.ads/.adb` (new); the shape is
  nuntius's `tests/src/nuntius_steps-flows.ads/.adb` and
  `nuntius_steps.adb` after PR #4, which this item copies.
- **What is wrong:** F1's registry dispatches its one machine by
  hand; four features need the general form.
- **Why:** the smoke registry was the smallest thing that could prove
  the runner.
- **Fix:** `Tempus_Steps.Flows`, generic over `State`, `Guard_Kind`,
  `Action_Kind`, `Evaluate`, `Execute`, `Always` and `Nothing`: an
  `Sml.Simple_Machines` instance over `Step_Kind` and `Step_Context`,
  `Machines.Engine.Operators` for the tables (so `with
  Sml.Machines.Operators` in the spec), and `Take` -- make the machine
  at the feature's state, `Process_Event` the step, then up to four
  follow-ups from `Then_Take`, and keep the state.  In the registry:
  `Step_Context` with `W`, `A`, `Info`, `R`, `Has_Next`, `Next`;
  `Then_Take`; the shared `Count_Read`/`Count`/`Refuse_Count` (and
  their `Long_Read`/`Long_Count` twins for the millisecond captures);
  a `Regions` table of `(Name, Offer, Reset, Phase)` access values,
  one row per feature child; `Execute` offers the step to every region
  and fails an untaken step with every region's `Phase`; `Run_Hook`'s
  `Before` resets the world and every region.  Guards are a body with
  `pragma Unreferenced (Evt)` -- an expression function cannot carry
  the pragma.  An action helper never shares a name with an event
  wrapper (`Count_It`, not `Count`): they conflict.
- **RED first:** the smoke child rewritten over `Tempus_Steps.Flows`
  fails to compile until the generic exists (`"Flows" is not declared
  in "Tempus_Steps"`); green when `make features` passes as before
  and the out-of-order message now reads every region's state.
  Refactor pass: the smoke child and feature go once F3 lands -- the
  first real feature replaces them.

### F3 -- `timestamps.feature`: an instant the way a Go peer reads it

- **Where:** `tests/src/tempus_rfc3339_tests.adb:13-25` (`Test_Image`),
  `:27-81` (`Test_Value`, sixteen assertions), `:83-96`
  (`Test_Round_Trip`); `tests/src/tempus_test_support.ads:10-18` (the
  golden vectors); `CLAUDE.md:87-93` ("Compatibility contract (do not
  break)").
- **What is wrong:** the contract a Go peer relies on -- `Image` emits
  exactly `YYYY-MM-DDThh:mm:ssZ`, `Value` reads that plus the
  fractional and offset forms Go marshals -- is stated in `CLAUDE.md`
  and asserted in a 55-line test nobody reads as a list.
- **Why:** the vectors were pinned as the port's parity evidence.
- **Fix:** the first feature and the one that defines most of the
  vocabulary.  Its machine has one state (`Ready`), the guards
  `Formattable`, `Epoch_Seconds_Given` and `Count_Given`, and the
  actions `A_Image`, `A_Parse`, `A_Refuse`, `A_Round_Trip` with their
  refusing twins.

  ```gherkin
  Feature: An instant formats and parses the way a Go peer reads it

    An instant formats as exactly YYYY-MM-DDThh:mm:ssZ, and that form,
    the fractional-second form and the numeric-offset form a Go peer
    marshals all parse back to the instant, so an instant round-trips
    through a Go peer unchanged.

    Scenario Outline: An instant formats as its UTC timestamp
      Then the instant <epoch> formats as <stamp>

      Examples:
        | epoch      | stamp                |
        | 0          | 1970-01-01T00:00:00Z |
        | 1709164800 | 2024-02-29T00:00:00Z |
        | 1771174556 | 2026-02-15T16:55:56Z |

    Scenario Outline: Every form Go marshals parses to the same instant
      Then <stamp> parses to the instant 1771174556

      Examples:
        | stamp                               |
        | 2026-02-15T16:55:56Z                |
        | 2026-02-15T16:55:56+00:00           |
        | 2026-02-15T11:55:56.123456789-05:00 |

    Scenario Outline: A timestamp that is not one is refused
      Then <text> is refused

      Examples:
        | text                      |
        | 2026-02-15T16:55:56       |
        | garbage                   |
        | 1970-01-01T00:00:00+01:00 |
        | 2026-02-30T00:00:00Z      |
        | 2026-04-31T00:00:00Z      |
        | 2025-02-29T00:00:00Z      |
        | 2026-02-15T16:55:56+24:00 |
        | 2026-02-15T16:55:56.Z     |
        | 2026-02-15T16:55:56Zextra |

    Scenario: A space where the T belongs is refused
      Then the text "2026-02-15 16:55:56Z" is refused

    Scenario Outline: An instant survives the round trip
      Then the instant <epoch> formats and parses back

      Examples:
        | epoch      |
        | 1709164800 |
        | 1771174556 |
  ```

  The space case is the one row that cannot be a `{word}` -- a word
  ends at a blank -- so it is its own scenario over a `{string}`
  pattern, `the text {string} is refused`, a second row of the same
  `E_Refuse` kind.  The formattable bound is not a scenario: that
  `Image` is never asked past `Max_Formattable` is the precondition's
  business and `Test_Image`'s, and the `Formattable` guard refuses
  such an instant with a message -- how the feature would report a
  bad vector, not a behavior it states.
- **RED first:** `make features` reports the Background-free first
  scenario's step `UNDEFINED`; each row turns one step green.  The
  cells are `Test_Image`'s and `Test_Value`'s own vectors, so a green
  here restates their outcomes at the feature layer; the AUnit tests
  and their assertions stay exactly where they are.

### F4 -- `calendar.feature`: the civil calendar

- **Where:** `tests/src/tempus_calendar_tests.adb:9-28`
  (`Test_Valid_Date`), `:30-46` (`Test_To_Epoch`), `:48-59`
  (`Test_Civil_From_Days`); `src/tempus-calendar.ads:16-34`
  (`Valid_Date`, the static leap-year rule), `:41-55` (`To_Epoch` and
  its precondition), `:57-58` (`Civil_From_Days` and its).
- **What is wrong:** the leap-year rule and the month lengths are the
  things a reader asks about first, and they live in a static
  expression function and eight `Assert`s.
- **Fix:** outlines over `E_Valid`/`E_Invalid`, `E_To_Epoch` and
  `E_Civil`; the machine has one state and the guards `Count_Given`
  (per field), `Field_Ranges` and `Days_In_Range`:

  ```gherkin
  Feature: The civil calendar knows its leap days and month lengths

    Scenario Outline: A date exists, or it does not
      Then <year>-<month>-<day> is <verdict>

      Examples:
        | year | month | day | verdict          |
        | 2024 | 2     | 29  | a valid date     |
        | 2025 | 2     | 29  | not a valid date |
        | 2026 | 2     | 30  | not a valid date |
        | 2026 | 4     | 31  | not a valid date |
        | 2026 | 1     | 31  | a valid date     |
        | 1969 | 12    | 31  | not a valid date |
        | 2026 | 13    | 1   | not a valid date |

    Scenario Outline: Civil fields and an offset name one instant
      Then <y>-<m>-<d> <h>:<mi>:<s> at offset <off> is the instant <epoch>

      Examples:
        | y    | m | d  | h  | mi | s  | off    | epoch      |
        | 1970 | 1 | 1  | 0  | 0  | 0  | 0      | 0          |
        | 2024 | 2 | 29 | 0  | 0  | 0  | 0      | 1709164800 |
        | 2026 | 2 | 15 | 16 | 55 | 56 | 0      | 1771174556 |
        | 2026 | 2 | 15 | 11 | 55 | 56 | -18000 | 1771174556 |

    Scenario Outline: A count of days since the epoch is a date
      Then day <days> since the epoch is <year>-<month>-<day>

      Examples:
        | days  | year | month | day |
        | 0     | 1970 | 1     | 1   |
        | 19782 | 2024 | 2     | 29  |
        | 20499 | 2026 | 2     | 15  |
  ```

  `is <verdict>` is two patterns (`is a valid date`, `is not a valid
  date`) of two kinds, which an outline cell may choose between;
  "hour 24 is rejected" (`Valid_Date (2026, 1, 1, 24, 0, 0)`) stays a
  unit assertion, since the date patterns take a date and no time --
  the function-level detail belongs below.  `Test_Valid_Date`,
  `Test_To_Epoch` and `Test_Civil_From_Days` keep every assertion they
  have; the feature restates their outcomes only.
- **RED first:** `2024-2-29 is a valid date` is `UNDEFINED`; green on
  `Valid_Date (2024, 2, 29, 0, 0, 0)`.

### F5 -- `time-of-day.feature`: a wall-clock reading in milliseconds

- **Where:** `tests/src/tempus_time_of_day_tests.adb:11-29`
  (`Test_Well_Formed`), `:31-56` (`Test_Malformed`);
  `src/tempus-time_of_day.ads:11-14` (`Parse`'s contract: a refused
  text leaves `Ms = 0`).
- **What is wrong:** "9:5 is 09:05" and "12:30:45:00 is not a time"
  are the operator's questions and are eleven `Assert`s.
- **Fix:** two outlines over `E_Tod` and `E_Tod_Refused`; the day
  count is an `{int}` read with `Args.Long` (86 399 000 fits `Integer`
  too, but the millisecond captures read one way everywhere).  The
  refused outline says only that the text is refused; the `Ms = 0` a
  refusal leaves is the `Post`'s and `Test_Malformed`'s, a field of
  the result the feature does not reach into.  `Test_Well_Formed` and
  `Test_Malformed` keep their assertions; the feature restates the
  outcomes.  The empty text is its own scenario over `the text
  {string} is not a time of day` -- an empty word is not a word.
- **RED first:** `09:35 is 34500000 ms into the day` is `UNDEFINED`;
  green on `Parse ("09:35")`.

### F6 -- `instants.feature`: a date and a time of day name an instant

- **Where:** `tests/src/tempus_instants_tests.adb:11-27`
  (`Test_Epoch_Ms`); `src/tempus-instants.ads:11-12`; and the three
  units it joins -- `Time_Of_Day.Parse`, `Instants.Epoch_Ms`,
  `Rfc3339.Value`.
- **What is wrong:** the one behavior in this crate that is larger
  than a function -- a packed date and a wall-clock time name the
  same instant a timestamp does -- is nowhere stated, because each
  unit test tests its own unit.
- **Why:** that is what the unit tests are for.  This is the feature
  a pure core still has: the conceptual whole its functions compose.
- **Fix:** `E_Epoch_Ms` for three of `Test_Epoch_Ms`'s four vectors
  -- the fourth, a garbage packed date clamping to the epoch, is a
  single function's edge and stays in that test -- and `E_Agree`, the
  cross-unit scenario, the one check here that no unit test could
  make.  `Test_Epoch_Ms` keeps its assertions.  The machine has the states `Ready` and
  `Agreed`: `E_Agree`'s action parses the time of day and the
  timestamp, then `Then_Take`s the internal event `E_Compared`, whose
  guarded rows read whether both parses succeeded (`Both_Parsed`) and
  compare, or fail naming the one that did not -- the follow-up shape.

  ```gherkin
  Feature: A date and a time of day name the instant a timestamp names

    Scenario Outline: A packed date plus milliseconds into the day
      Then the date <date> at <ms> ms is the instant <epoch_ms> ms

      Examples:
        | date     | ms       | epoch_ms      |
        | 19700101 | 0        | 0             |
        | 20240229 | 0        | 1709164800000 |
        | 20260215 | 60956000 | 1771174556000 |

    Scenario Outline: Three units agree on one instant
      Then the date <date> at <tod> is the same instant as <stamp>

      Examples:
        | date     | tod      | stamp                               |
        | 20260215 | 16:55:56 | 2026-02-15T16:55:56Z                |
        | 20260215 | 16:55:56 | 2026-02-15T11:55:56.123456789-05:00 |
        | 20240229 | 00:00    | 2024-02-29T00:00:00Z                |
  ```
- **RED first:** `the date 20260215 at 16:55:56 is the same instant as
  2026-02-15T16:55:56Z` is `UNDEFINED`; green when
  `Epoch_Ms (2026_02_15, 60_956_000) / 1_000 = 1_771_174_556`, which no
  unit test states.

### F7 -- The features as living documentation

- **Where:** `Makefile` (after `features:`), `.gitignore:1-9`,
  `.github/workflows/ci.yml:39-52` (the test and example steps of
  `build-and-test`); nuntius's `tools/features-report/` and its
  `ci.yml` after PR #4, which this item copies.
- **What is wrong:** the features are readable only with a checkout.
- **Fix:** `tools/features-report/` -- `package.json` (name
  `tempus-features-report`, dependency
  `multiple-cucumber-html-reporter ^3.9.0`), the committed
  `package-lock.json` (so CI can `npm ci`), and `report.js` (page
  title "tempus — features", report name "tempus — what the calendar
  does", the commit and run from the `GITHUB_*` environment).
  `/tools/features-report/node_modules/` in `.gitignore`.  The target:

  ```make
  ## features-report  The living documentation: run the features (release)
  ##             with --report-json and render it into
  ##             obj/features-report/html with multiple-cucumber-html-reporter
  ##             (tools/features-report).  The page is made even when a
  ##             scenario fails, and the target then fails with the runner.
  features-report:
  	alr exec -- gprbuild -p -j0 -XMODE=release -P tests/test_tempus.gpr
  	@rm -rf obj/features-report && mkdir -p obj/features-report/json
  	@alr exec -- tests/bin/release/tempus_features tests/features \
  	   --report-json obj/features-report/json/features.json; rc=$$?; \
  	 npm ci --prefix tools/features-report --no-audit --no-fund && \
  	 node tools/features-report/report.js obj/features-report/json \
  	   obj/features-report/html && exit $$rc
  ```

  In CI, after the example steps of `build-and-test`: `actions/setup-node@v7`
  (node 22, `cache: npm` on the lockfile), `make features-report`,
  `actions/upload-artifact@v7` of `obj/features-report/html` -- the
  three with `if: success() || failure()`, so a failing scenario still
  renders -- and, on a push to main, `actions/upload-pages-artifact@v5`;
  then a `pages` job (`needs: build-and-test`, `permissions: pages:
  write, id-token: write`, environment `github-pages`) running
  `actions/deploy-pages@v5`.  Pages is enabled once, outside the
  repository: `gh api -X POST repos/ldm5180/tempus/pages -f build_type=workflow`.
  The page then lives at `https://ldm5180.github.io/tempus/`.
- **RED first:** `make features-report` -- "No rule to make target";
  green when `obj/features-report/html/index.html` exists and names
  four features; and with one expectation broken, the page is still
  made and the target exits non-zero.

### F8 -- The docs say so

- **Where:** `CLAUDE.md:16-24` ("Commands"), `:30-31` (the `tests/`
  layout line), `:50-59` ("TDD protocol"); `README.md:38-48`
  ("Develop").
- **Fix:** `make features` and `make features-report` in both; the
  layout line names `tests/features/`, `tempus_features.ads` and the
  machines; a TDD bullet states the layers as the settled guidance
  has them (a unit test tests one function and covers it completely;
  a feature tests the larger interaction; duplication across the two
  is fine; none of this crate's tests is removed); the README links
  the published page.

## 5. Verified in a scratch worktree (iteration 3)

Against the tree at `51712384`, in a detached worktree under the
session scratchpad, GNAT 15.2.0, gprbuild 26.0.1, 2026-10-03:

1. `fabula = "*"` pinned at `746a234` beside `aunit`:
   `alr --non-interactive build --validation` succeeds in 2.6 s (4.5 s
   wall), deploying exactly `fabula_746a234d` and `sml_3ccd0e4b` -- no
   pin conflict, as F0 says.
2. The F1 and F2 sketches typed in together, in the machine shape:
   `with "fabula"`, the second main `tempus_features.ads`,
   `tempus_steps.ads/.adb` with `Step_Context`, `Then_Take` and the
   count helpers, `tempus_steps-flows.ads/.adb` (the runner, copied
   from nuntius with the names changed), one child machine
   `tempus_steps-smoke.adb` (states `Empty`/`Counted`, guard
   `Count_Given`, a refusing fallback row per guarded row), and
   `tests/features/smoke.feature` with two scenarios.
   `gprbuild -P tests/test_tempus.gpr` builds both mains in 2.4 s with
   no warning.  The run: the counting scenario passes all four steps;
   the second scenario -- a check before any count -- fails its step
   with `E_CHECK_COUNT is not a step this scenario can take now:
   smoke=EMPTY`, exit 1.  That is F2's out-of-order refusal working
   before any feature exists.
3. The vocabulary's one risk probed: a pattern `{word} names the
   instant {int} and the ms {int}` run over
   `2026-02-15T11:55:56.123456789-05:00` and `2026-02-15T16:55:56Z`.
   Both capture as one word, `Tempus.Rfc3339.Value` parses both to
   `1_771_174_556`, and `Fabula.Args.Long` reads the 13-digit
   `1771174556000` that `Args.Int` could not.  So a timestamp is a
   `{word}` and an epoch in milliseconds is an `{int}` read with
   `Long`, as section 3 says.
4. Not verified here, and the reason it is F3's RED: a `{string}`
   pattern beside a `{word}` pattern for the same kind (the space
   case).  fabula's table takes any number of rows per kind, so the
   F3 item names it as the first thing its RED proves.

## 6. The second wave, sketched

- **`Tempus.Rfc3339.Scanner`** on its own: the sml scanning machine's
  states as a feature ("after the T, two digits and a colon are
  expected").  Today it is reached only through `Value`; a feature at
  the scanner's level would be a unit-level restatement, which is why
  it waits.
- **The runner shared across crates.**  `Tempus_Steps.Flows` is
  nuntius's `Nuntius_Steps.Flows` with the names changed, and fasti,
  graecus, lector and tabula will copy it again.  Its home is fabula
  (a `Fabula.Flows` generic over `Sml.Simple_Machines`) -- out of
  scope for this crate's plan, noted for fabula's.

## Revision notes

- **Iteration 1 (draft):** the four features, the vocabulary, the
  world as inputs, nine items -- the nuntius plan's shape with the
  socket world removed and the four settled adjustments folded in as
  up-front decisions and items (machines from the start, streaming
  colour, living docs, no pruning).
- **Iteration 2 (as a newcomer):** added "How to use this plan", the
  Do-not list (no clock, no `{float}` instant, no quoted timestamp,
  no `if` over a capture), section 1 with the region dispatch
  explained before any item relies on it, sections 3.1 (every guard
  and what its refusal says) and 3.2 (why most machines have one
  state, and the one that does not), full Gherkin for F3, F4 and F6
  and the Makefile and CI text for F1 and F7, and a RED per item.
  Moved the `hour 24` and `Max_Formattable` facts out of the features
  and into "stays a unit assertion", since they are function-level
  detail; made F6's cross-unit scenario the item that justifies a
  features suite for a pure core at all.
- **Iteration 3 (against the tree at `51712384`, and the scratch
  builds of section 5):** every `file:line` re-located.  Corrected:
  the draft had the epoch-millisecond captures as `{int}` through
  `Args.Int`, which overflows a 32-bit `Integer` at 1 771 174 556 000 --
  they read through `Fabula.Args.Long`, and the date patterns' literal
  hyphens were checked against fabula's grammar (literal; only `/` is
  an operator).  The `[[actions]]` span is `35-50`, not four lines;
  `Test_Value` is `27-81` with sixteen assertions, not twelve;
  `Valid_Date` is `tempus-calendar.ads:16-34` and `To_Epoch` `:41-55`
  (the draft had both a dozen lines early), `Civil_From_Days` `:57-58`,
  `Parse` `tempus-time_of_day.ads:11-14`, `Epoch_Ms`
  `tempus-instants.ads:11-12`; `Test_Civil_From_Days` ends at 59,
  `Test_Malformed` at 56 and `Test_Epoch_Ms` at 27.  Confirmed: `aunit` at
  `alire.toml:16`, `[[pins]]` at `:22`, `for Main` at
  `tests/test_tempus.gpr:16`, `test:` at `Makefile:17`, the CI test
  step at `ci.yml:39`, the compatibility contract at `CLAUDE.md:87`.
  The scratch run also showed the one-state machines are not a
  weakness: the out-of-order refusal still fires on the first step
  that has a precondition (a check before a count).
- **After the behavior guidelines (2026-10-03):** the plan was read
  against the rule that a feature binds externally visible behavior
  and the unit tests hold the mechanism.  Three checks came out of the
  features and stay in the unit tests: the "past the formattable
  bound, Image is not asked" scenario (it tested the step machine's
  own guard, and named a subprogram), the `Ms = 0` half of "is not a
  time of day" (a field of the result the `Post` and `Test_Malformed`
  pin), and the `0 | 5 | 0` garbage-date row of `instants.feature`
  (a single function's edge).  F3's feature description was reworded
  from `Tempus.Rfc3339.Image`/`Value` to the consumer's words, and the
  feature map in section 2 likewise.  Added: the fifth up-front
  decision, two Do-not entries, and under F3-F6 the sentence that the
  lifted tests keep every assertion while the feature restates the
  outcome.  Everything else was already at the crate's edge -- what a
  function returns or refuses -- and the cross-unit `instants`
  scenario is the model case.
