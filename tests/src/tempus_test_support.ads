with Tempus;

--  Shared golden vectors for the Rfc3339 tests: one leap-day instant and one
--  arbitrary 2026 instant with every field double-digit, plus the Go
--  time.Time "StoredAt" shape (nanoseconds and a numeric offset) that Value
--  must accept.  All three name the same UTC instant as Sample_Epoch.

package Tempus_Test_Support is

   Sample_Epoch : constant Tempus.Epoch_Seconds := 1_771_174_556;
   Sample_Utc   : constant String := "2026-02-15T16:55:56Z";

   --  11:55:56 at -05:00 is 16:55:56Z; the fraction is truncated.
   Sample_Offset_Form : constant String :=
     "2026-02-15T11:55:56.123456789-05:00";

   Leap_Epoch : constant Tempus.Epoch_Seconds := 1_709_164_800;
   Leap_Utc   : constant String := "2024-02-29T00:00:00Z";

end Tempus_Test_Support;
