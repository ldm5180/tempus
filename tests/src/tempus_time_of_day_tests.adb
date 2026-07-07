with AUnit.Assertions; use AUnit.Assertions;

with Tempus;
use type Tempus.Day_Milliseconds;
with Tempus.Time_Of_Day; use Tempus.Time_Of_Day;

package body Tempus_Time_Of_Day_Tests is

   use AUnit.Test_Cases.Registration;

   procedure Test_Well_Formed (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Ms : Tempus.Day_Milliseconds;
      Ok : Boolean;
   begin
      Parse ("09:35", Ms, Ok);
      Assert (Ok and then Ms = 34_500_000, "09:35 is 09:35 * 60_000 ms");

      Parse ("00:00:00", Ms, Ok);
      Assert (Ok and then Ms = 0, "midnight is zero ms");

      Parse ("23:59:59", Ms, Ok);
      Assert (Ok and then Ms = 86_399_000, "the last second of the day");

      Parse ("9:5", Ms, Ok);
      Assert
        (Ok and then Ms = 32_700_000,
         "single-digit fields accumulate (09:05)");
   end Test_Well_Formed;

   procedure Test_Malformed (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Ms : Tempus.Day_Milliseconds;
      Ok : Boolean;
   begin
      Parse ("24:00", Ms, Ok);
      Assert (not Ok and then Ms = 0, "hour 24 is out of range");

      Parse ("12:60", Ms, Ok);
      Assert (not Ok and then Ms = 0, "minute 60 is out of range");

      Parse ("1234", Ms, Ok);
      Assert (not Ok, "no colon means fewer than two fields");

      Parse ("12:", Ms, Ok);
      Assert (not Ok, "a trailing colon leaves an empty field");

      Parse ("12:30:45:00", Ms, Ok);
      Assert (not Ok, "a fourth field is malformed");

      Parse ("ab:cd", Ms, Ok);
      Assert (not Ok, "non-digits are malformed");

      Parse ("", Ms, Ok);
      Assert (not Ok, "the empty string is malformed");
   end Test_Malformed;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Well_Formed'Access,
         "Parse reads HH:MM and HH:MM:SS into ms-of-day");
      Register_Routine
        (T,
         Test_Malformed'Access,
         "Parse rejects out-of-range, empty, and over-long spellings");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Tempus.Time_Of_Day (HH:MM[:SS] -> ms-of-day)");
   end Name;

end Tempus_Time_Of_Day_Tests;
