with Tempus.Calendar;

package body Tempus.Instants
  with SPARK_Mode
is

   function Epoch_Ms
     (Date : Packed_Date; Ms : Day_Milliseconds) return Epoch_Milliseconds
   is
      use Tempus.Calendar;

      --  Year 9999 (the largest a packed date can spell) is epoch second
      --  253_402_214_400; anything outside [0, that] is a garbage date and
      --  clamps, which also hands the proof the bound To_Epoch's spec omits.
      Max_Seconds : constant LLI := 253_500_000_000;

      Seconds : constant LLI :=
        To_Epoch
          (Year           => LLI (Date) / 10_000,
           Month          => (LLI (Date) / 100) mod 100,
           Day            => LLI (Date) mod 100,
           Hour           => 0,
           Min            => 0,
           Sec            => 0,
           Offset_Seconds => 0);
   begin
      if Seconds not in 0 .. Max_Seconds then
         return 0;
      end if;
      return Epoch_Milliseconds (Seconds) * 1_000 + Epoch_Milliseconds (Ms);
   end Epoch_Ms;

end Tempus.Instants;
