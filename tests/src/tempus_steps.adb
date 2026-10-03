with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Fabula.Check.Longs;
with Fabula.Numbers;

with Tempus.Time_Of_Day;

with Tempus_Steps.Calendar;
with Tempus_Steps.Instants;
with Tempus_Steps.Time_Of_Day;
with Tempus_Steps.Timestamps;

package body Tempus_Steps is

   procedure Then_Take (Ctx : in out Step_Context; Evt : Step_Kind) is
   begin
      Ctx.Has_Next := True;
      Ctx.Next := Evt;
   end Then_Take;

   function Reads_In
     (Ctx : Step_Context; N : Positive; Low, High : LLI) return Boolean
   is (N <= Fabula.Args.Count (Ctx.A)
       and then Fabula.Args.Long (Ctx.A, N).Ok
       and then Fabula.Args.Long (Ctx.A, N).Value in Low .. High);

   function Number (Ctx : Step_Context; N : Positive) return LLI
   is (Fabula.Args.Long (Ctx.A, N).Value);

   procedure Refuse_Range
     (Ctx : in out Step_Context; N : Positive; What : String; Low, High : LLI)
   is
      Read : constant Fabula.Numbers.Long_Reads.Read :=
        Fabula.Args.Long (Ctx.A, N);
   begin
      if Read.Ok then
         Fabula.Check.Fail_Step
           (Ctx.R,
            What
            & " is outside "
            & Fabula.Check.Long_Image (Low)
            & " .. "
            & Fabula.Check.Long_Image (High));
      else
         Fabula.Check.Longs.Fail_Read (Ctx.R, Read.Error, What);
      end if;
   end Refuse_Range;

   --  The longest text Tempus.Time_Of_Day.Parse's precondition takes.
   Longest_Tod : constant := 32;

   function Tod_Readable (Ctx : Step_Context; N : Positive) return Boolean
   is (N <= Fabula.Args.Count (Ctx.A)
       and then Fabula.Args.Text (Ctx.A, N)'Length <= Longest_Tod);

   procedure Read_Tod
     (Ctx : Step_Context;
      N   : Positive;
      Ms  : out Tempus.Day_Milliseconds;
      Ok  : out Boolean)
   is
      Written : constant String := Fabula.Args.Text (Ctx.A, N);
      Text    : constant String (1 .. Written'Length) := Written;
   begin
      Tempus.Time_Of_Day.Parse (Text, Ms, Ok);
   end Read_Tod;

   procedure Refuse_Tod_Length (Ctx : in out Step_Context) is
   begin
      Fabula.Check.Fail_Step
        (Ctx.R,
         "a time of day is read from at most "
         & Fabula.Check.Integer_Image (Longest_Tod)
         & " characters");
   end Refuse_Tod_Length;

   ---------------------------------------------------------------------
   --  The features as orthogonal regions: every step is offered to each,
   --  and each takes only its own.
   ---------------------------------------------------------------------

   type Offer_Access is
     access procedure
       (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);
   type Reset_Access is access procedure;
   type Phase_Access is access function return String;
   type Name_Access is access constant String;

   type Region is record
      Name  : Name_Access;
      Offer : Offer_Access;
      Reset : Reset_Access;
      Phase : Phase_Access;
   end record;

   Timestamps_Name : aliased constant String := "timestamps";
   Calendar_Name   : aliased constant String := "calendar";
   Tod_Name        : aliased constant String := "time of day";
   Instants_Name   : aliased constant String := "instants";

   --!format off
   Regions : constant array (Positive range <>) of Region :=
     [(Timestamps_Name'Access, Timestamps.Offer'Access,  Timestamps.Reset'Access,  Timestamps.Phase'Access),
      (Calendar_Name'Access,   Calendar.Offer'Access,    Calendar.Reset'Access,    Calendar.Phase'Access),
      (Tod_Name'Access,        Time_Of_Day.Offer'Access, Time_Of_Day.Reset'Access, Time_Of_Day.Phase'Access),
      (Instants_Name'Access,   Instants.Offer'Access,    Instants.Reset'Access,    Instants.Phase'Access)];
   --!format on

   --  Every region's state, for the step no region would take.
   function Phases return String is
      Text : Unbounded_String;
   begin
      for G of Regions loop
         Append (Text, " " & G.Name.all & "=" & G.Phase.all);
      end loop;
      return To_String (Text);
   end Phases;

   procedure Execute
     (S    : Step_Kind;
      Ctx  : in out World;
      A    : Fabula.Args.List;
      Info : Fabula.Frames.Frame;
      R    : in out Fabula.Check.Outcome)
   is
      Step    : Step_Context :=
        (W => Ctx, A => A, Info => Info, R => R, others => <>);
      Taken   : Boolean := False;
      Handled : Boolean;
   begin
      for G of Regions loop
         G.Offer (Step, S, Handled);
         Taken := Taken or else Handled;
      end loop;
      Ctx := Step.W;
      R := Step.R;
      if not Taken then
         Fabula.Check.Fail_Step
           (R,
            S'Image & " is not a step this scenario can take now:" & Phases);
      end if;
   end Execute;

   procedure Run_Hook
     (H    : Hook_Kind;
      Ctx  : in out World;
      Info : Fabula.Frames.Frame;
      R    : in out Fabula.Check.Outcome)
   is
      pragma Unreferenced (Info, R);
   begin
      case H is
         when Fresh_World =>
            Ctx := (others => <>);
            for G of Regions loop
               G.Reset.all;
            end loop;
      end case;
   end Run_Hook;

end Tempus_Steps;
