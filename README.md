# tempus

SPARK-provable RFC3339 timestamps and civil-calendar arithmetic for Ada 2022.

`tempus` is a small, pure library: no IO, no `Ada.Calendar`. It works entirely
over Unix epoch integers, so every unit is SPARK-provable and callers inject the
wall clock.

## What's in it

- **`Tempus.Rfc3339`** — format and parse `YYYY-MM-DDThh:mm:ssZ` (plus the
  fractional-second and `+hh:mm` / `-hh:mm` offset forms Go's `time.Time`
  marshals). The parser is an
  [sml-ada](https://github.com/ldm5180/sml-ada) scanning state machine.
- **`Tempus.Calendar`** — proleptic-Gregorian ("civil") arithmetic:
  `Valid_Date`, `To_Epoch`, and `Civil_From_Days` (Howard Hinnant's algorithms).
- **`Tempus.Time_Of_Day`** — parse `HH:MM` / `HH:MM:SS` into milliseconds
  since midnight.
- **`Tempus.Instants`** — combine a packed `YYYYMMDD` date with a time-of-day
  into Unix epoch milliseconds.

## Use it

Add the dependency (via a git pin until it is in the community index):

```toml
[[depends-on]]
tempus = "*"
```

```ada
with Tempus.Rfc3339;

Stamp : constant String := Tempus.Rfc3339.Image (1_771_174_556);
--  "2026-02-15T16:55:56Z"
```

## Develop

```sh
make build    # build the library
make test     # AUnit suite, both -O modes, fully offline
make prove    # SPARK proof, --checks-as-errors=on
make format   # gnatformat --check
make run      # run the RFC3339 example
make help     # all targets
```

Conventions (SPARK, strict TDD, commit style) live in [CLAUDE.md](CLAUDE.md).

## License

MIT — see [LICENSE](LICENSE).
