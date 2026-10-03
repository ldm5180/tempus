--  The civil calendar (calendar.feature): which dates exist, the
--  instant civil fields name, and the date a count of days names.  A
--  region of the registry: Offer takes this feature's steps, Reset
--  starts a scenario, Phase names its state.

package Tempus_Steps.Calendar is

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);

   procedure Reset;

   function Phase return String;

end Tempus_Steps.Calendar;
