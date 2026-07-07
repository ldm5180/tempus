with AUnit.Assertions; use AUnit.Assertions;

with Tempus;
use type Tempus.Epoch_Milliseconds;
with Tempus.Instants; use Tempus.Instants;

package body Tempus_Instants_Tests is

   use AUnit.Test_Cases.Registration;

   procedure Test_Epoch_Ms (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Epoch_Ms (1970_01_01, 0) = 0, "the epoch itself is 0 ms");

      Assert
        (Epoch_Ms (2024_02_29, 0) = 1_709_164_800_000,
         "leap-day midnight UTC in ms");

      --  2026-02-15 plus 16:55:56 (60_956_000 ms) is the Sample instant.
      Assert
        (Epoch_Ms (2026_02_15, 60_956_000) = 1_771_174_556_000,
         "a date plus a time-of-day");

      Assert
        (Epoch_Ms (0, 5) = 0, "a zero (garbage) date clamps to the epoch");
   end Test_Epoch_Ms;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Epoch_Ms'Access,
         "Epoch_Ms combines a packed date and ms-of-day into epoch ms");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return
        AUnit.Format ("Tempus.Instants (packed date + ms-of-day -> epoch)");
   end Name;

end Tempus_Instants_Tests;
