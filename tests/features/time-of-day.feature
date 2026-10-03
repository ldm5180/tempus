Feature: A wall-clock reading is a count of milliseconds into the day

  HH:MM and HH:MM:SS read as milliseconds since midnight, a single digit
  standing for its two-digit field.  An hour past 23, a minute past 59,
  a missing or extra field, anything but digits, and the empty text are
  not times of day.

  Scenario Outline: A time of day reads as milliseconds into the day
    Then <time> is <ms> ms into the day

    Examples:
      | time     | ms       |
      | 09:35    | 34500000 |
      | 00:00:00 | 0        |
      | 23:59:59 | 86399000 |
      | 9:5      | 32700000 |

  Scenario Outline: A reading that is not a time of day is refused
    Then <text> is not a time of day

    Examples:
      | text        |
      | 24:00       |
      | 12:60       |
      | 1234        |
      | 12:         |
      | 12:30:45:00 |
      | ab:cd       |

  Scenario: The empty text is not a time of day
    Then the text "" is not a time of day
