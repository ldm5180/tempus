--  A date and a time of day name an instant (instants.feature): the
--  milliseconds a packed date and a time into it name, and their
--  agreement with a timestamp.  A region of the registry: Offer takes
--  this feature's steps, Reset starts a scenario, Phase names its state.

package Tempus_Steps.Instants is

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);

   procedure Reset;

   function Phase return String;

end Tempus_Steps.Instants;
