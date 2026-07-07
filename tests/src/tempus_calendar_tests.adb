with AUnit.Assertions; use AUnit.Assertions;

with Tempus.Calendar; use Tempus.Calendar;

package body Tempus_Calendar_Tests is

   use AUnit.Test_Cases.Registration;

   procedure Test_Valid_Date (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Valid_Date (2024, 2, 29, 0, 0, 0), "Feb 29 is valid in a leap year");
      Assert
        (not Valid_Date (2025, 2, 29, 0, 0, 0),
         "Feb 29 is invalid in a common year");
      Assert
        (not Valid_Date (2026, 2, 30, 0, 0, 0), "February never has 30 days");
      Assert (not Valid_Date (2026, 4, 31, 0, 0, 0), "April has only 30 days");
      Assert
        (Valid_Date (2026, 1, 31, 23, 59, 59),
         "Jan 31 23:59:59 is a valid instant");
      Assert
        (not Valid_Date (1969, 12, 31, 0, 0, 0),
         "before the Unix epoch is rejected");
      Assert (not Valid_Date (2026, 13, 1, 0, 0, 0), "month 13 is rejected");
      Assert (not Valid_Date (2026, 1, 1, 24, 0, 0), "hour 24 is rejected");
   end Test_Valid_Date;

   procedure Test_To_Epoch (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (To_Epoch (1970, 1, 1, 0, 0, 0, 0) = 0, "the epoch itself is 0");
      Assert
        (To_Epoch (2024, 2, 29, 0, 0, 0, 0) = 1_709_164_800,
         "leap-day midnight UTC");
      Assert
        (To_Epoch (2026, 2, 15, 16, 55, 56, 0) = 1_771_174_556,
         "an arbitrary UTC instant");

      --  A -05:00 stamp reads 11:55:56 locally for the same UTC instant; the
      --  offset (negative seconds) is subtracted, adding the five hours back.
      Assert
        (To_Epoch (2026, 2, 15, 11, 55, 56, -18_000) = 1_771_174_556,
         "the offset shifts the fields to the right UTC instant");
   end Test_To_Epoch;

   procedure Test_Civil_From_Days (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Y, M, D : LLI;
   begin
      Civil_From_Days (0, Y, M, D);
      Assert (Y = 1970 and then M = 1 and then D = 1, "day 0 is 1970-01-01");
      Civil_From_Days (19_782, Y, M, D);  --  1_709_164_800 / 86_400
      Assert (Y = 2024 and then M = 2 and then D = 29, "the 2024 leap day");
      Civil_From_Days (20_499, Y, M, D);  --  the Sample instant's day
      Assert (Y = 2026 and then M = 2 and then D = 15, "an arbitrary date");
   end Test_Civil_From_Days;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Valid_Date'Access,
         "Valid_Date accepts real dates and rejects impossible ones");
      Register_Routine
        (T,
         Test_To_Epoch'Access,
         "To_Epoch converts validated fields to epoch");
      Register_Routine
        (T,
         Test_Civil_From_Days'Access,
         "Civil_From_Days inverts the day step");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Tempus.Calendar (pure calendar arithmetic)");
   end Name;

end Tempus_Calendar_Tests;
