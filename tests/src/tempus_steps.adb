with Tempus_Steps.Smoke;

package body Tempus_Steps is

   procedure Execute
     (S    : Step_Kind;
      Ctx  : in out World;
      A    : Fabula.Args.List;
      Info : Fabula.Frames.Frame;
      R    : in out Fabula.Check.Outcome)
   is
      Step    : Step_Context := (W => Ctx, A => A, Info => Info, R => R);
      Handled : Boolean;
   begin
      Smoke.Offer (Step, S, Handled);
      Ctx := Step.W;
      R := Step.R;
      if not Handled then
         Fabula.Check.Fail_Step
           (R,
            S'Image
            & " is not a step this scenario can take now: smoke="
            & Smoke.Phase);
      end if;
   end Execute;

   procedure Run_Hook
     (H    : Hook_Kind;
      Ctx  : in out World;
      Info : Fabula.Frames.Frame;
      R    : in out Fabula.Check.Outcome)
   is
      pragma Unreferenced (H, Info, R);
   begin
      Ctx := (others => <>);
      Smoke.Reset;
   end Run_Hook;

end Tempus_Steps;
