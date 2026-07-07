--  Parse a few RFC3339 timestamps with Tempus.Rfc3339.Value, then format the
--  resulting instant back with Image.  This is the release "run" example.

with Ada.Text_IO; use Ada.Text_IO;

with Tempus;
use type Tempus.Epoch_Seconds;
with Tempus.Rfc3339; use Tempus.Rfc3339;

procedure Parse_Rfc3339 is

   procedure Show (S : String) is
      T  : Tempus.Epoch_Seconds;
      Ok : Boolean;
   begin
      Value (S, T, Ok);
      if Ok and then T <= Max_Formattable then
         Put_Line (S & "  ->  epoch" & T'Image & "  ->  " & Image (T));
      elsif Ok then
         Put_Line (S & "  ->  epoch" & T'Image);
      else
         Put_Line (S & "  ->  malformed");
      end if;
   end Show;

begin
   Put_Line ("Tempus.Rfc3339: parse a timestamp, then format it back.");
   Show ("1970-01-01T00:00:00Z");
   Show ("2026-02-15T16:55:56Z");
   Show ("2026-02-15T11:55:56.123456789-05:00");  --  Go's StoredAt shape
   Show ("2026-02-30T00:00:00Z");                 --  Feb 30 is malformed
end Parse_Rfc3339;
