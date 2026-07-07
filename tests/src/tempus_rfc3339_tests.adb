with AUnit.Assertions; use AUnit.Assertions;

with Tempus;
use type Tempus.Epoch_Seconds;
with Tempus.Rfc3339; use Tempus.Rfc3339;

with Tempus_Test_Support; use Tempus_Test_Support;

package body Tempus_Rfc3339_Tests is

   use AUnit.Test_Cases.Registration;

   procedure Test_Image (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Image (0) = "1970-01-01T00:00:00Z",
         "the epoch itself formats as 1970-01-01");
      Assert
        (Image (Leap_Epoch) = Leap_Utc,
         "leap day 2024-02-29 (civil-from-days handles leap years)");
      Assert
        (Image (Sample_Epoch) = Sample_Utc,
         "an arbitrary 2026 instant with every field double-digit");
   end Test_Image;

   procedure Test_Value (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Epoch : Tempus.Epoch_Seconds;
      Ok    : Boolean;
   begin
      Value ("1970-01-01T00:00:00Z", Epoch, Ok);
      Assert (Ok and then Epoch = 0, "the epoch parses back to 0");

      Value (Sample_Utc, Epoch, Ok);
      Assert (Ok and then Epoch = Sample_Epoch, "a plain Z timestamp");

      Value ("2026-02-15T16:55:56+00:00", Epoch, Ok);
      Assert (Ok and then Epoch = Sample_Epoch, "+00:00 equals Z");

      Value (Sample_Offset_Form, Epoch, Ok);
      Assert
        (Ok and then Epoch = Sample_Epoch,
         "Go's StoredAt shape: nanoseconds truncated, -05:00 applied");

      Value ("2026-02-15 16:55:56Z", Epoch, Ok);
      Assert (not Ok, "a space instead of T is malformed");

      Value ("2026-02-15T16:55:56", Epoch, Ok);
      Assert (not Ok, "a missing Z/offset is malformed");

      Value ("garbage", Epoch, Ok);
      Assert (not Ok, "garbage is malformed");

      Value ("1970-01-01T00:00:00+01:00", Epoch, Ok);
      Assert (not Ok, "an instant before the epoch is rejected");

      Value ("2026-02-30T00:00:00Z", Epoch, Ok);
      Assert (not Ok, "February never has 30 days");

      Value ("2026-04-31T00:00:00Z", Epoch, Ok);
      Assert (not Ok, "April has only 30 days");

      Value ("2025-02-29T00:00:00Z", Epoch, Ok);
      Assert (not Ok, "Feb 29 is invalid in a non-leap year");

      Value (Leap_Utc, Epoch, Ok);
      Assert (Ok, "Feb 29 is valid in a leap year");

      Value ("2026-01-31T00:00:00Z", Epoch, Ok);
      Assert (Ok, "January 31 is a valid day");

      Value ("2026-02-15T16:55:56+24:00", Epoch, Ok);
      Assert (not Ok, "an offset hour past 23 is rejected");

      Value ("2026-02-15T16:55:56.Z", Epoch, Ok);
      Assert (not Ok, "a dot with no fraction digits is malformed");

      Value ("2026-02-15T16:55:56Zextra", Epoch, Ok);
      Assert (not Ok, "trailing junk after Z is malformed");
   end Test_Value;

   procedure Test_Round_Trip (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Epoch : Tempus.Epoch_Seconds;
      Ok    : Boolean;
   begin
      Value (Image (Leap_Epoch), Epoch, Ok);
      Assert
        (Ok and then Epoch = Leap_Epoch,
         "Value (Image (T)) = T for the leap-day vector");
      Value (Image (Sample_Epoch), Epoch, Ok);
      Assert
        (Ok and then Epoch = Sample_Epoch,
         "Value (Image (T)) = T for the sample vector");
   end Test_Round_Trip;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Image'Access,
         "Image renders UTC RFC3339 (YYYY-MM-DDThh:mm:ssZ)");
      Register_Routine
        (T,
         Test_Value'Access,
         "Value parses Z, +-hh:mm, and fractional forms");
      Register_Routine (T, Test_Round_Trip'Access, "Value inverts Image");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Tempus.Rfc3339 (timestamps)");
   end Name;

end Tempus_Rfc3339_Tests;
