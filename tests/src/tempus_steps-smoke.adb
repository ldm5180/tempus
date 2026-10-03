with Fabula.Check.Ints;

with Tempus_Steps.Flows;

package body Tempus_Steps.Smoke is

   --  Empty until a step keeps a count; the other steps read it then.
   type State is (Empty, Counted);

   type Guard_Kind is (Always, Count_Given);

   type Action_Kind is (A_Nothing, A_Keep, A_Add, A_Check, A_Refuse_Count);

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always      => True,
           when Count_Given => Count_Read (Ctx));
   end Evaluate;

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind)
   is
      pragma Unreferenced (Evt);
   begin
      case A is
         when A_Nothing      =>
            null;

         when A_Keep         =>
            Ctx.W.Count := Count (Ctx);

         when A_Add          =>
            Ctx.W.Count := Ctx.W.Count + Count (Ctx);

         when A_Check        =>
            Fabula.Check.Ints.Equal
              (Ctx.R, Ctx.W.Count, Fabula.Args.Int (Ctx.A, 1), "the count");

         when A_Refuse_Count =>
            Refuse_Count (Ctx);
      end case;
   end Execute;

   package Flow is new
     Tempus_Steps.Flows
       (State       => State,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Evaluate    => Evaluate,
        Execute     => Execute,
        Always      => Always,
        Nothing     => A_Nothing);

   use Flow.Machines;
   use Flow.Op;

   Keep_Count  : constant Ev := (Kind => E_Keep_Count);
   Add_Count   : constant Ev := (Kind => E_Add_Count);
   Check_Count : constant Ev := (Kind => E_Check_Count);

   --!format off
   Table : constant Transition_Table :=
     [Empty   + Keep_Count (Count_Given) / A_Keep         >= Counted,
      Empty   + Keep_Count               / A_Refuse_Count >= Empty,
      Counted + Add_Count  (Count_Given) / A_Add          >= Counted,
      Counted + Add_Count                / A_Refuse_Count >= Counted,
      Counted + Check_Count              / A_Check        >= Counted];
   --!format on

   Current : State := Empty;

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean) is
   begin
      Flow.Take (Table, Current, Ctx, Evt, Handled);
   end Offer;

   procedure Reset is
   begin
      Current := Empty;
   end Reset;

   function Phase return String
   is (Current'Image);

end Tempus_Steps.Smoke;
