with Fabula.Check.Longs;

with Tempus.Instants;
with Tempus.Rfc3339;

with Tempus_Steps.Flows;

package body Tempus_Steps.Instants is

   --  Ready for a step; Parsed while an agreement step's two readings
   --  are in and their comparison, the event it takes next, is not.
   type State is (Ready, Parsed);

   type Guard_Kind is
     (Always,
      Date_Fits,
      Date_And_Ms_Fit,
      Date_And_Tod_Fit,
      Tod_Parsed,
      Both_Parsed);

   type Action_Kind is
     (A_Nothing,
      A_Epoch_Ms,
      A_Read_Both,
      A_Compare,
      A_Refuse_Date,
      A_Refuse_Ms,
      A_Refuse_Tod_Length,
      A_Refuse_Tod,
      A_Refuse_Stamp);

   Date_Capture   : constant := 1;
   Second_Capture : constant := 2;
   Third_Capture  : constant := 3;

   Ms_Per_Second : constant := 1_000;

   function Date_Read (Ctx : Step_Context) return Boolean
   is (Reads_In (Ctx, Date_Capture, 0, LLI (Tempus.Packed_Date'Last)));

   function Ms_Read (Ctx : Step_Context) return Boolean
   is (Reads_In (Ctx, Second_Capture, 0, LLI (Tempus.Day_Milliseconds'Last)));

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always           => True,
           when Date_Fits        => Date_Read (Ctx),
           when Date_And_Ms_Fit  => Date_Read (Ctx) and then Ms_Read (Ctx),
           when Date_And_Tod_Fit =>
             Date_Read (Ctx) and then Tod_Readable (Ctx, Second_Capture),
           when Tod_Parsed       => Ctx.W.Read.Tod_Ok,
           when Both_Parsed      =>
             Ctx.W.Read.Tod_Ok and then Ctx.W.Read.Stamp_Ok);
   end Evaluate;

   ---------------------------------------------------------------------
   --  Actions.
   ---------------------------------------------------------------------

   function Date (Ctx : Step_Context) return Tempus.Packed_Date
   is (Tempus.Packed_Date (Number (Ctx, Date_Capture)))
   with Pre => Date_Read (Ctx);

   procedure Check_Epoch_Ms (Ctx : in out Step_Context)
   with Pre => Date_Read (Ctx) and then Ms_Read (Ctx)
   is
   begin
      Fabula.Check.Longs.Equal
        (Ctx.R,
         LLI
           (Tempus.Instants.Epoch_Ms
              (Date (Ctx),
               Tempus.Day_Milliseconds (Number (Ctx, Second_Capture)))),
         Fabula.Args.Long (Ctx.A, Third_Capture));
   end Check_Epoch_Ms;

   --  Read the time of day and the timestamp, then take the comparison.
   procedure Read_Both (Ctx : in out Step_Context)
   with Pre => Tod_Readable (Ctx, Second_Capture)
   is
      Got : Readings;
   begin
      Read_Tod (Ctx, Second_Capture, Got.Ms, Got.Tod_Ok);
      Tempus.Rfc3339.Value
        (Fabula.Args.Text (Ctx.A, Third_Capture), Got.Stamp, Got.Stamp_Ok);
      Ctx.W.Read := Got;
      Then_Take (Ctx, E_Compared);
   end Read_Both;

   procedure Compare (Ctx : in out Step_Context) with Pre => Date_Read (Ctx) is
   begin
      Fabula.Check.Longs.Equal
        (Ctx.R,
         LLI (Tempus.Instants.Epoch_Ms (Date (Ctx), Ctx.W.Read.Ms)),
         LLI (Ctx.W.Read.Stamp) * Ms_Per_Second);
   end Compare;

   procedure Refuse_Unread (Ctx : in out Step_Context; N : Positive) is
   begin
      Fabula.Check.Fail_Step
        (Ctx.R, Fabula.Args.Text (Ctx.A, N) & " was refused");
   end Refuse_Unread;

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind)
   is
      pragma Unreferenced (Evt);
   begin
      case A is
         when A_Nothing           =>
            null;

         when A_Epoch_Ms          =>
            Check_Epoch_Ms (Ctx);

         when A_Read_Both         =>
            Read_Both (Ctx);

         when A_Compare           =>
            Compare (Ctx);

         when A_Refuse_Date       =>
            Refuse_Range
              (Ctx,
               Date_Capture,
               "the date",
               0,
               LLI (Tempus.Packed_Date'Last));

         when A_Refuse_Ms         =>
            Refuse_Range
              (Ctx,
               Second_Capture,
               "the time into the day",
               0,
               LLI (Tempus.Day_Milliseconds'Last));

         when A_Refuse_Tod_Length =>
            Refuse_Tod_Length (Ctx);

         when A_Refuse_Tod        =>
            Refuse_Unread (Ctx, Second_Capture);

         when A_Refuse_Stamp      =>
            Refuse_Unread (Ctx, Third_Capture);
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

   Epoch_Ms : constant Ev := (Kind => E_Epoch_Ms);
   Agree    : constant Ev := (Kind => E_Agree);
   Compared : constant Ev := (Kind => E_Compared);

   --!format off
   Table : constant Transition_Table :=
     [Ready  + Epoch_Ms (Date_And_Ms_Fit)  / A_Epoch_Ms          >= Ready,
      Ready  + Epoch_Ms (Date_Fits)        / A_Refuse_Ms         >= Ready,
      Ready  + Epoch_Ms                    / A_Refuse_Date       >= Ready,
      Ready  + Agree    (Date_And_Tod_Fit) / A_Read_Both         >= Parsed,
      Ready  + Agree    (Date_Fits)        / A_Refuse_Tod_Length >= Ready,
      Ready  + Agree                       / A_Refuse_Date       >= Ready,
      Parsed + Compared (Both_Parsed)      / A_Compare           >= Ready,
      Parsed + Compared (Tod_Parsed)       / A_Refuse_Stamp      >= Ready,
      Parsed + Compared                    / A_Refuse_Tod        >= Ready];
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

end Tempus_Steps.Instants;
