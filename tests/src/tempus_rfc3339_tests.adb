with AUnit.Assertions; use AUnit.Assertions;

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

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Image'Access,
         "Image renders UTC RFC3339 (YYYY-MM-DDThh:mm:ssZ)");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Tempus.Rfc3339 (timestamps)");
   end Name;

end Tempus_Rfc3339_Tests;
