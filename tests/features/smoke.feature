Feature: The feature runner runs a scenario

  The smallest vocabulary that proves the runner: a count kept and
  checked.  It goes when the first real feature lands.

  Scenario: A count is kept and checked
    Given a count of 2
    When the count grows by 3
    Then the count is 5

