--  The lexer behind Rfc3339.Value, modeled as an sml state machine: one
--  character per event, walking the fixed RFC3339 layout field by field.  It
--  is purely structural -- it accepts the spelling and range-checks the zone
--  offset, but a scanned Fields can still name an impossible date (Feb 30);
--  Tempus.Calendar.Valid_Date is the semantic gate applied by the caller.

package Tempus.Rfc3339.Scanner
  with SPARK_Mode
is

   subtype Year_Number is Natural range 0 .. 9_999;
   subtype Two_Digit is Natural range 0 .. 99;
   subtype Offset_Range is Integer range -86_400 .. 86_400;

   --  The six calendar fields plus a signed UTC offset in seconds, as lexed
   --  from an RFC3339 string.  The field values are meaningful only when
   --  Valid; a non-Valid result means the spelling was malformed or the zone
   --  offset was out of range.
   type Fields is record
      Valid          : Boolean := False;
      Year           : Year_Number := 0;
      Month          : Two_Digit := 0;
      Day            : Two_Digit := 0;
      Hour           : Two_Digit := 0;
      Minute         : Two_Digit := 0;
      Second         : Two_Digit := 0;
      Offset_Seconds : Offset_Range := 0;
   end record;

   function Scan (S : String) return Fields
   with Pre => S'First = 1 and then S'Length <= 64;

end Tempus.Rfc3339.Scanner;
