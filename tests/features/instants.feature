Feature: A date and a time of day name the instant a timestamp names

  A date packed as YYYYMMDD and a count of milliseconds into that day
  name one instant in milliseconds since the epoch.  Read from a
  wall-clock time, it is the same instant a timestamp of that date and
  time names, whatever offset and fraction the timestamp is written in.

  Scenario Outline: A packed date plus milliseconds into the day
    Then the date <date> at <ms> ms is the instant <epoch_ms> ms

    Examples:
      | date     | ms       | epoch_ms      |
      | 19700101 | 0        | 0             |
      | 20240229 | 0        | 1709164800000 |
      | 20260215 | 60956000 | 1771174556000 |

  Scenario Outline: A date, a time of day and a timestamp agree on one instant
    Then the date <date> at <tod> is the same instant as <stamp>

    Examples:
      | date     | tod      | stamp                               |
      | 20260215 | 16:55:56 | 2026-02-15T16:55:56Z                |
      | 20260215 | 16:55:56 | 2026-02-15T11:55:56.123456789-05:00 |
      | 20240229 | 00:00    | 2024-02-29T00:00:00Z                |
