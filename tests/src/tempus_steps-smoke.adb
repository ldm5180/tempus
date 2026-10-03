with Fabula.Check.Ints;
with Fabula.Numbers;

with Sml.Machines.Operators;
with Sml.Simple_Machines;

package body Tempus_Steps.Smoke is

   --  Empty until a step keeps a count; the other steps read it then.
   type State is (Empty, Counted);

   type Guard_Kind is (Always, Count_Given);

   type Action_Kind is (A_Nothing, A_Keep, A_Add, A_Check, A_Refuse_Count);

   First_Capture : constant := 1;

   function Read (Ctx : Step_Context) return Fabula.Numbers.Integer_Reads.Read
   is (Fabula.Args.Int (Ctx.A, First_Capture));

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always      => True,
           when Count_Given => Read (Ctx).Ok and then Read (Ctx).Value >= 0);
   end Evaluate;

   procedure Refuse_Count (Ctx : in out Step_Context) is
   begin
      if Read (Ctx).Ok then
         Fabula.Check.Fail_Step (Ctx.R, "a count cannot be negative");
      else
         Fabula.Check.Ints.Fail_Read (Ctx.R, Read (Ctx).Error);
      end if;
   end Refuse_Count;

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind)
   is
      pragma Unreferenced (Evt);
   begin
      case A is
         when A_Nothing      =>
            null;

         when A_Keep         =>
            Ctx.W.Count := Read (Ctx).Value;

         when A_Add          =>
            Ctx.W.Count := Ctx.W.Count + Read (Ctx).Value;

         when A_Check        =>
            Fabula.Check.Ints.Equal
              (Ctx.R, Ctx.W.Count, Read (Ctx).Value, "the count");

         when A_Refuse_Count =>
            Refuse_Count (Ctx);
      end case;
   end Execute;

   package Machines is new
     Sml.Simple_Machines
       (State       => State,
        Event       => Step_Kind,
        Context     => Step_Context,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Evaluate    => Evaluate,
        Execute     => Execute);

   package Op is new Machines.Engine.Operators (Always, A_Nothing);

   use Machines;
   use Op;

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
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean)
   is
      M : Machine := Make (Table, Initial => Current);
   begin
      Engine.Process_Event (M, Ctx, Evt, Handled);
      Current := State_Of (M);
   end Offer;

   procedure Reset is
   begin
      Current := Empty;
   end Reset;

   function Phase return String
   is (Current'Image);

end Tempus_Steps.Smoke;
