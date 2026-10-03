--  The runner's smoke vocabulary (smoke.feature): a count kept and
--  checked.  Offer takes its steps, Reset starts a scenario, Phase names
--  its state.

package Tempus_Steps.Smoke is

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);

   procedure Reset;

   function Phase return String;

end Tempus_Steps.Smoke;
