with Tempus.Calendar;
with Tempus.Rfc3339.Scanner;

package body Tempus.Rfc3339
  with SPARK_Mode
is

   subtype Digit is Natural range 0 .. 9;

   function Digit_Char (D : Digit) return Character
   is (Character'Val (Character'Pos ('0') + D));

   subtype Datetime_String is String (1 .. 19);
   --  "YYYY-MM-DDThh:mm:ss": the date-time part Image wraps with a 'Z'.

   function Format_Datetime (T : Tempus.Epoch_Seconds) return Datetime_String
   with Pre => T <= Max_Formattable;

   function Format_Datetime (T : Tempus.Epoch_Seconds) return Datetime_String
   is
      subtype LLI is Long_Long_Integer;

      Days : constant LLI := LLI (T / 86_400);
      Rest : constant LLI := LLI (T mod 86_400);

      Hour   : constant LLI := Rest / 3_600;
      Minute : constant LLI := (Rest / 60) mod 60;
      Second : constant LLI := Rest mod 60;

      Year, Month, Day : LLI;

      Result : Datetime_String := "0000-00-00T00:00:00";

      --  Digits are extracted with a final `mod 10` (a no-op for in-range
      --  values) so the proof only owes absence of runtime errors, not
      --  nonlinear bounds on the calendar values.
      procedure Put_2 (Position : Positive; Value : LLI)
      with Pre => Position in 1 .. Result'Last - 1;

      procedure Put_2 (Position : Positive; Value : LLI) is
      begin
         Result (Position) := Digit_Char (Digit ((Value / 10) mod 10));
         Result (Position + 1) := Digit_Char (Digit (Value mod 10));
      end Put_2;

      procedure Put_4 (Position : Positive; Value : LLI)
      with Pre => Position in 1 .. Result'Last - 3;

      procedure Put_4 (Position : Positive; Value : LLI) is
      begin
         Result (Position) := Digit_Char (Digit ((Value / 1_000) mod 10));
         Result (Position + 1) := Digit_Char (Digit ((Value / 100) mod 10));
         Put_2 (Position + 2, Value);
      end Put_4;

   begin
      Calendar.Civil_From_Days (Days, Year, Month, Day);
      Put_4 (1, Year);
      Put_2 (6, Month);
      Put_2 (9, Day);
      Put_2 (12, Hour);
      Put_2 (15, Minute);
      Put_2 (18, Second);
      return Result;
   end Format_Datetime;

   function Image (T : Tempus.Epoch_Seconds) return Timestamp_String
   is (Format_Datetime (T) & "Z");

   procedure Value (S : String; T : out Tempus.Epoch_Seconds; Ok : out Boolean)
   is
      subtype LLI is Long_Long_Integer;
   begin
      T := 0;
      Ok := False;

      --  A well-formed value is 20 to 64 characters ("...Z" up to a paranoid
      --  cap that also bounds the scanner's work).  The bounded, 1-based copy
      --  satisfies Scan's precondition.
      if S'Length < 20 or else S'Length > 64 then
         return;
      end if;

      declare
         Buf : constant String (1 .. S'Length) := S;
         F   : constant Scanner.Fields := Scanner.Scan (Buf);
      begin
         if not F.Valid then
            return;
         end if;

         if not Calendar.Valid_Date
                  (LLI (F.Year),
                   LLI (F.Month),
                   LLI (F.Day),
                   LLI (F.Hour),
                   LLI (F.Minute),
                   LLI (F.Second))
         then
            return;
         end if;

         declare
            Total : constant LLI :=
              Calendar.To_Epoch
                (LLI (F.Year),
                 LLI (F.Month),
                 LLI (F.Day),
                 LLI (F.Hour),
                 LLI (F.Minute),
                 LLI (F.Second),
                 LLI (F.Offset_Seconds));
         begin
            if Total < 0 or else Total > LLI (Tempus.Epoch_Seconds'Last) then
               return;
            end if;
            T := Tempus.Epoch_Seconds (Total);
            Ok := True;
         end;
      end;
   end Value;

end Tempus.Rfc3339;
