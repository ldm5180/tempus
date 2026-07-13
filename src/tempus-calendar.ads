--  Pure proleptic-Gregorian ("civil") calendar arithmetic: a validity
--  predicate and the days-from-civil epoch conversion (Howard Hinnant's
--  algorithms).  These are standalone pure functions -- they take date-time
--  fields and return a result, touching no parsing state -- so they read on
--  their own, are reusable, and can be unit-tested and proved directly.

package Tempus.Calendar
  with SPARK_Mode
is

   subtype LLI is Long_Long_Integer;

   --  A real calendar instant at or after the Unix epoch: the month's actual
   --  length (proleptic-Gregorian leap year for February) rejects Feb 30,
   --  Apr 31, Feb 29 in a common year, etc.
   function Valid_Date (Year, Month, Day, Hour, Min, Sec : LLI) return Boolean
   is (declare
         Is_Leap       : constant Boolean :=
           (Year mod 4 = 0 and then Year mod 100 /= 0)
           or else Year mod 400 = 0;
         Days_In_Month : constant LLI :=
           (if Month = 2
            then (if Is_Leap then 29 else 28)
            elsif Month in 4 | 6 | 9 | 11
            then 30
            else 31);
       begin
         Year >= 1_970
         and then Month in 1 .. 12
         and then Day in 1 .. Days_In_Month
         and then Hour <= 23
         and then Min <= 59
         and then Sec <= 59)
   with Static;

   --  Unix epoch seconds for a validated instant: days-from-civil (Howard
   --  Hinnant's algorithm), then the offset -- a +05:00 stamp is five hours
   --  behind UTC's reading of the same fields, so it is subtracted.  The Pre
   --  bounds every term so the arithmetic cannot overflow (the two-digit
   --  fields a timestamp yields already satisfy it).
   function To_Epoch
     (Year, Month, Day, Hour, Min, Sec, Offset_Seconds : LLI) return LLI
   with
     Pre =>
       Year in 0 .. 9_999
       and then Month in 0 .. 99
       and then Day in 0 .. 99
       and then Hour in 0 .. 99
       and then Min in 0 .. 99
       and then Sec in 0 .. 99
       and then Offset_Seconds in -86_400 .. 86_400;

   --  The civil date for a day count (days since 1970-01-01): civil-from-days
   --  (Howard Hinnant), the inverse of the day step inside To_Epoch.  The Pre
   --  bounds Days (a four-digit-year epoch yields at most ~2.9M) so the
   --  arithmetic cannot overflow; correctness is pinned by the Rfc3339 tests.
   procedure Civil_From_Days (Days : LLI; Year, Month, Day : out LLI)
   with Pre => Days in 0 .. 3_000_000;

end Tempus.Calendar;
