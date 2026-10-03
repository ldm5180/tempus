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

  Scenario Outline: The leap day and the last day of a month parse
    Then <stamp> parses to the instant <epoch>

    Examples:
      | stamp                | epoch      |
      | 1970-01-01T00:00:00Z | 0          |
      | 2024-02-29T00:00:00Z | 1709164800 |
      | 2026-01-31T00:00:00Z | 1769817600 |

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
