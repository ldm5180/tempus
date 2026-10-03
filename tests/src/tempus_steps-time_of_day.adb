with Fabula.Check.Longs;

with Tempus_Steps.Flows;

package body Tempus_Steps.Time_Of_Day is

   --  One state: no reading depends on another.
   type State is (Ready);

   type Guard_Kind is (Always, Readable);

   type Action_Kind is
     (A_Nothing, A_Read, A_Expect_Refused, A_Refuse_Long_Text);

   Text_Capture : constant := 1;
   Ms_Capture   : constant := 2;

   --  The step's reading, as written.
   function Written (Ctx : Step_Context) return String
   is (Fabula.Args.Text (Ctx.A, Text_Capture));

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always   => True,
           when Readable => Tod_Readable (Ctx, Text_Capture));
   end Evaluate;

   ---------------------------------------------------------------------
   --  Actions.
   ---------------------------------------------------------------------

   procedure Read
     (Ctx : Step_Context; Ms : out Tempus.Day_Milliseconds; Ok : out Boolean)
   with Pre => Tod_Readable (Ctx, Text_Capture)
   is
   begin
      Read_Tod (Ctx, Text_Capture, Ms, Ok);
   end Read;

   procedure Check_Read (Ctx : in out Step_Context) is
      Ms : Tempus.Day_Milliseconds;
      Ok : Boolean;
   begin
      Read (Ctx, Ms, Ok);
      Fabula.Check.Longs.Equal
        (Ctx.R, Long_Long_Integer (Ms), Fabula.Args.Long (Ctx.A, Ms_Capture));
      Fabula.Check.Is_True (Ctx.R, Ok, Written (Ctx) & " was refused");
   end Check_Read;

   procedure Check_Refused (Ctx : in out Step_Context) is
      Ms : Tempus.Day_Milliseconds;
      Ok : Boolean;
   begin
      Read (Ctx, Ms, Ok);
      Fabula.Check.Is_False
        (Ctx.R, Ok, Written (Ctx) & " read as" & Ms'Image & " ms");
   end Check_Refused;

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind)
   is
      pragma Unreferenced (Evt);
   begin
      case A is
         when A_Nothing          =>
            null;

         when A_Read             =>
            Check_Read (Ctx);

         when A_Expect_Refused   =>
            Check_Refused (Ctx);

         when A_Refuse_Long_Text =>
            Refuse_Tod_Length (Ctx);
      end case;
   end Execute;

   ---------------------------------------------------------------------
   --  The table.
   ---------------------------------------------------------------------

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

   Tod         : constant Ev := (Kind => E_Tod);
   Tod_Refused : constant Ev := (Kind => E_Tod_Refused);

   --!format off
   Table : constant Transition_Table :=
     [Ready + Tod         (Readable) / A_Read             >= Ready,
      Ready + Tod                    / A_Refuse_Long_Text >= Ready,
      Ready + Tod_Refused (Readable) / A_Expect_Refused   >= Ready,
      Ready + Tod_Refused            / A_Refuse_Long_Text >= Ready];
   --!format on

   Current : State := Ready;

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean) is
   begin
      Flow.Take (Table, Current, Ctx, Evt, Handled);
   end Offer;

   procedure Reset is
   begin
      Current := Ready;
   end Reset;

   function Phase return String
   is (Current'Image);

end Tempus_Steps.Time_Of_Day;
