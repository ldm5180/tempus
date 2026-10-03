with Fabula.Args;
with Fabula.Check;
with Fabula.Frames;
with Fabula.Registry;

--  The step registry the feature runner dispatches on: one Step_Kind
--  per pattern, one table that reads like the features, and one Execute
--  that offers each step to the features' state machines.

package Tempus_Steps is

   type Step_Kind is (E_Keep_Count, E_Add_Count, E_Check_Count);

   type Hook_Kind is (Fresh_World);

   --  What one scenario reads back: the inputs it named.
   type World is record
      Count : Natural := 0;
   end record;

   --  One step as a machine sees it: the scenario, and the step's
   --  arguments, frame and outcome.
   type Step_Context is record
      W    : World;
      A    : Fabula.Args.List;
      Info : Fabula.Frames.Frame;
      R    : Fabula.Check.Outcome;
   end record;

   package Steps is new
     Fabula.Registry
       (Step_Kind => Step_Kind,
        Hook_Kind => Hook_Kind,
        Context   => World);
   use Steps;

   --!format off
   Step_Defs : constant Steps.Step_Table :=
     [Step ("a count of {int}")         >= E_Keep_Count,
      Step ("the count grows by {int}") >= E_Add_Count,
      Step ("the count is {int}")       >= E_Check_Count];
   --!format on

   Hook_Defs : constant Steps.Hook_Table := [Before >= Fresh_World];

   procedure Execute
     (S    : Step_Kind;
      Ctx  : in out World;
      A    : Fabula.Args.List;
      Info : Fabula.Frames.Frame;
      R    : in out Fabula.Check.Outcome);

   procedure Run_Hook
     (H    : Hook_Kind;
      Ctx  : in out World;
      Info : Fabula.Frames.Frame;
      R    : in out Fabula.Check.Outcome);

end Tempus_Steps;
