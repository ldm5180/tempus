--  Tempus: pure, SPARK-provable date/time primitives -- RFC3339 timestamps,
--  proleptic-Gregorian ("civil") calendar arithmetic, time-of-day parsing,
--  and a civil-date-plus-time-of-day-to-epoch combiner, all over plain epoch
--  integers.  No IO and no Ada.Calendar: the vocabulary is Unix epoch
--  seconds/milliseconds, milliseconds-of-day, and a packed YYYYMMDD civil
--  date, so the whole library is provable and its callers inject the clock.

package Tempus
  with Pure, SPARK_Mode
is

   --  Unix epoch seconds.  The upper bound is far past year 9999, so a live
   --  clock plus any sane interval stays comfortably in range.
   type Epoch_Seconds is range 0 .. 2**48 - 1;

   --  Unix epoch milliseconds: the same span at millisecond resolution.
   type Epoch_Milliseconds is range 0 .. 2**62 - 1;

   --  Milliseconds since midnight -- a wall-clock time-of-day, no date.  The
   --  inclusive 86_400_000 upper bound admits an end-of-day sentinel.
   type Day_Milliseconds is range 0 .. 86_400_000;

   --  A civil date packed as the decimal integer YYYYMMDD (2026-02-15 is
   --  20_260_215).  A representation, not a validity claim: Valid_Date in
   --  Tempus.Calendar is what rules out Feb 30 and friends.
   type Packed_Date is range 0 .. 99_999_999;

end Tempus;
