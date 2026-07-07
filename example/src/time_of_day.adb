--  Parse HH:MM[:SS] wall-clock strings with Tempus.Time_Of_Day, then combine a
--  civil date with a time-of-day into epoch milliseconds with Tempus.Instants.

with Ada.Text_IO; use Ada.Text_IO;

with Tempus;
with Tempus.Time_Of_Day;
with Tempus.Instants;

procedure Time_Of_Day is

   procedure Show (S : String) is
      Ms : Tempus.Day_Milliseconds;
      Ok : Boolean;
   begin
      Tempus.Time_Of_Day.Parse (S, Ms, Ok);
      if Ok then
         Put_Line (S & "  ->" & Ms'Image & " ms of day");
      else
         Put_Line (S & "  ->  malformed");
      end if;
   end Show;

begin
   Put_Line ("Tempus.Time_Of_Day: HH:MM[:SS] -> milliseconds of day.");
   Show ("09:35");
   Show ("23:59:59");
   Show ("24:00");  --  hour out of range: malformed

   Put_Line ("");
   Put_Line
     ("Tempus.Instants: 2026-02-15 at 09:35 is epoch ms"
      & Tempus.Instants.Epoch_Ms (2026_02_15, 34_500_000)'Image);
end Time_Of_Day;
