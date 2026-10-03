with Fabula.Check.Longs;

with Tempus.Rfc3339;

with Tempus_Steps.Flows;

package body Tempus_Steps.Timestamps is

   use type Tempus.Epoch_Seconds;

   --  One state: a format and a parse do not depend on each other, so
   --  every row loops on Ready.
   type State is (Ready);

   type Guard_Kind is (Always, Formattable, Instant_Given);

   type Action_Kind is
     (A_Nothing,
      A_Image,
      A_Parse,
      A_Expect_Refused,
      A_Round_Trip,
      A_Refuse_Unformattable,
      A_Refuse_Instant);

   First_Capture  : constant := 1;
   Second_Capture : constant := 2;

   --  The step's instant, its first capture: whole seconds since the
   --  epoch, inside Tempus.Epoch_Seconds.
   function Instant_Read (Ctx : Step_Context) return Boolean
   is (Reads_In (Ctx, First_Capture, 0, LLI (Tempus.Epoch_Seconds'Last)));

   function Instant (Ctx : Step_Context) return Tempus.Epoch_Seconds
   is (Tempus.Epoch_Seconds (Number (Ctx, First_Capture)))
   with Pre => Instant_Read (Ctx);

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always        => True,
           when Formattable   =>
             Instant_Read (Ctx)
             and then Instant (Ctx) <= Tempus.Rfc3339.Max_Formattable,
           when Instant_Given => Instant_Read (Ctx));
   end Evaluate;

   ---------------------------------------------------------------------
   --  Actions.
   ---------------------------------------------------------------------

   --  The step's first capture, a timestamp or a text, as written.
   function Written (Ctx : Step_Context) return String
   is (Fabula.Args.Text (Ctx.A, First_Capture));

   procedure Check_Image (Ctx : in out Step_Context)
   with Pre => Instant_Read (Ctx)
   is
   begin
      Fabula.Check.Text_Equal
        (Ctx.R,
         Tempus.Rfc3339.Image (Instant (Ctx)),
         Fabula.Args.Text (Ctx.A, Second_Capture));
   end Check_Image;

   procedure Check_Parse (Ctx : in out Step_Context) is
      T  : Tempus.Epoch_Seconds;
      Ok : Boolean;
   begin
      Tempus.Rfc3339.Value (Written (Ctx), T, Ok);
      Fabula.Check.Longs.Equal
        (Ctx.R,
         Long_Long_Integer (T),
         Fabula.Args.Long (Ctx.A, Second_Capture));
      Fabula.Check.Is_True (Ctx.R, Ok, Written (Ctx) & " was refused");
   end Check_Parse;

   procedure Check_Refused (Ctx : in out Step_Context) is
      T  : Tempus.Epoch_Seconds;
      Ok : Boolean;
   begin
      Tempus.Rfc3339.Value (Written (Ctx), T, Ok);
      Fabula.Check.Is_False
        (Ctx.R, Ok, Written (Ctx) & " parsed to" & T'Image);
   end Check_Refused;

   procedure Check_Round_Trip (Ctx : in out Step_Context)
   with Pre => Instant_Read (Ctx)
   is
      Stamp : constant String := Tempus.Rfc3339.Image (Instant (Ctx));
      T     : Tempus.Epoch_Seconds;
      Ok    : Boolean;
   begin
      Tempus.Rfc3339.Value (Stamp, T, Ok);
      Fabula.Check.Longs.Equal
        (Ctx.R, Long_Long_Integer (T), Long_Long_Integer (Instant (Ctx)));
      Fabula.Check.Is_True (Ctx.R, Ok, Stamp & " was refused");
   end Check_Round_Trip;

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind)
   is
      pragma Unreferenced (Evt);
   begin
      case A is
         when A_Nothing              =>
            null;

         when A_Image                =>
            Check_Image (Ctx);

         when A_Parse                =>
            Check_Parse (Ctx);

         when A_Expect_Refused       =>
            Check_Refused (Ctx);

         when A_Round_Trip           =>
            Check_Round_Trip (Ctx);

         when A_Refuse_Unformattable =>
            Fabula.Check.Fail_Step (Ctx.R, "past the formattable bound");

         when A_Refuse_Instant       =>
            Refuse_Range
              (Ctx,
               First_Capture,
               "the instant",
               0,
               LLI (Tempus.Epoch_Seconds'Last));
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

   Image      : constant Ev := (Kind => E_Image);
   Parse      : constant Ev := (Kind => E_Parse);
   Refuse     : constant Ev := (Kind => E_Refuse);
   Round_Trip : constant Ev := (Kind => E_Round_Trip);

   --!format off
   Table : constant Transition_Table :=
     [Ready + Image      (Formattable)   / A_Image                >= Ready,
      Ready + Image      (Instant_Given) / A_Refuse_Unformattable >= Ready,
      Ready + Image                      / A_Refuse_Instant       >= Ready,
      Ready + Round_Trip (Formattable)   / A_Round_Trip           >= Ready,
      Ready + Round_Trip (Instant_Given) / A_Refuse_Unformattable >= Ready,
      Ready + Round_Trip                 / A_Refuse_Instant       >= Ready,
      Ready + Parse                      / A_Parse                >= Ready,
      Ready + Refuse                     / A_Expect_Refused       >= Ready];
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

end Tempus_Steps.Timestamps;
