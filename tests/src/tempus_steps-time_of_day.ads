--  A wall-clock reading in milliseconds (time-of-day.feature): read a
--  time of day, refuse what is not one.  A region of the registry:
--  Offer takes this feature's steps, Reset starts a scenario, Phase
--  names its state.

package Tempus_Steps.Time_Of_Day is

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);

   procedure Reset;

   function Phase return String;

end Tempus_Steps.Time_Of_Day;
