Feature: The civil calendar knows its leap days and month lengths

  A date exists only when its month has that day: February has 29 days
  in a year divisible by four but not by a hundred unless by four
  hundred, April, June, September and November have 30, and the rest 31.
  Civil fields and an offset name one instant in seconds since the
  epoch, and a count of days since the epoch names one date.

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
