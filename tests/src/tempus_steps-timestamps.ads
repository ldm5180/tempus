--  An instant the way a Go peer reads it (timestamps.feature): format
--  an instant, parse a timestamp, refuse what is not one.  A region of
--  the registry: Offer takes this feature's steps, Reset starts a
--  scenario, Phase names its state.

package Tempus_Steps.Timestamps is

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);

   procedure Reset;

   function Phase return String;

end Tempus_Steps.Timestamps;
