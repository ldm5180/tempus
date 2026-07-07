--  Parse a 24-hour wall-clock string into milliseconds since midnight.

package Tempus.Time_Of_Day
  with SPARK_Mode
is

   --  Parse "HH:MM" or "HH:MM:SS" into ms-of-day.  Each field is one or more
   --  digits; Ok is False for anything malformed (empty, no colon, a
   --  non-digit, a field out of range, or a fourth field), and Ms is 0
   --  whenever Ok is False so a caller can substitute its own default.
   procedure Parse (Text : String; Ms : out Day_Milliseconds; Ok : out Boolean)
   with
     Pre  => Text'First = 1 and then Text'Length <= 32,
     Post => (if not Ok then Ms = 0);

end Tempus.Time_Of_Day;
