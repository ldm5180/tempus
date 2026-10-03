with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Fabula.Check.Ints;
with Fabula.Check.Longs;
with Fabula.Numbers;

with Tempus_Steps.Calendar;
with Tempus_Steps.Time_Of_Day;
with Tempus_Steps.Timestamps;

package body Tempus_Steps is

   procedure Then_Take (Ctx : in out Step_Context; Evt : Step_Kind) is
   begin
      Ctx.Has_Next := True;
      Ctx.Next := Evt;
   end Then_Take;

   function Count_Read (Ctx : Step_Context; N : Positive := 1) return Boolean
   is (N <= Fabula.Args.Count (Ctx.A)
       and then Fabula.Args.Int (Ctx.A, N).Ok
       and then Fabula.Args.Int (Ctx.A, N).Value >= 0);

   function Count (Ctx : Step_Context; N : Positive := 1) return Natural
   is (Fabula.Args.Int (Ctx.A, N).Value);

   procedure Refuse_Count (Ctx : in out Step_Context; N : Positive := 1) is
      Read : constant Fabula.Numbers.Integer_Reads.Read :=
        Fabula.Args.Int (Ctx.A, N);
   begin
      if Read.Ok then
         Fabula.Check.Fail_Step (Ctx.R, "a count cannot be negative");
      else
         Fabula.Check.Ints.Fail_Read (Ctx.R, Read.Error);
      end if;
   end Refuse_Count;

   function Instant_Read (Ctx : Step_Context; N : Positive := 1) return Boolean
   is (N <= Fabula.Args.Count (Ctx.A)
       and then Fabula.Args.Long (Ctx.A, N).Ok
       and then Fabula.Args.Long (Ctx.A, N).Value
                in 0 .. Long_Long_Integer (Tempus.Epoch_Seconds'Last));

   function Instant
     (Ctx : Step_Context; N : Positive := 1) return Tempus.Epoch_Seconds
   is (Tempus.Epoch_Seconds (Fabula.Args.Long (Ctx.A, N).Value));

   procedure Refuse_Instant (Ctx : in out Step_Context; N : Positive := 1) is
      Read : constant Fabula.Numbers.Long_Reads.Read :=
        Fabula.Args.Long (Ctx.A, N);
   begin
      if not Read.Ok then
         Fabula.Check.Longs.Fail_Read (Ctx.R, Read.Error, "the instant");
      elsif Read.Value < 0 then
         Fabula.Check.Fail_Step (Ctx.R, "an instant cannot be negative");
      else
         Fabula.Check.Fail_Step (Ctx.R, "past the last instant tempus holds");
      end if;
   end Refuse_Instant;

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

   --!format off
   Regions : constant array (Positive range <>) of Region :=
     [(Timestamps_Name'Access, Timestamps.Offer'Access,  Timestamps.Reset'Access,  Timestamps.Phase'Access),
      (Calendar_Name'Access,   Calendar.Offer'Access,    Calendar.Reset'Access,    Calendar.Phase'Access),
      (Tod_Name'Access,        Time_Of_Day.Offer'Access, Time_Of_Day.Reset'Access, Time_Of_Day.Phase'Access)];
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
            Ctx := (null record);
            for G of Regions loop
               G.Reset.all;
            end loop;
      end case;
   end Run_Hook;

end Tempus_Steps;
