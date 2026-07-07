--  A compact sml state machine that walks an "HH:MM[:SS]" clock string one
--  character at a time, with structured-logging hooks gated on
--  Trace_Config.Enabled (on in the debug profile, compiled out in release), so
--  you can watch the scanner move between fields.  The toy machine only tracks
--  the walk; Tempus.Time_Of_Day.Parse computes the real answer.  Mirrors
--  sml-ada's hello_world_with_tracing.

with Ada.Text_IO; use Ada.Text_IO;

with Sml.Machines;
with Sml.Machines.Operators;

with Tempus;
with Tempus.Time_Of_Day;

with Trace_Config;

procedure Scan_Trace is

   type State is (Hours, Minutes, Seconds, Complete);
   type Event_Kind is (E_Digit, E_Colon, E_End, E_Other);

   type Event is record
      Kind : Event_Kind;
   end record;

   type Context is null record;
   type Guard_Kind is (Always);
   type Action_Kind is (Nothing);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (G, Ctx, Evt);
   begin
      return True;
   end Evaluate;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event) is
      pragma Unreferenced (A, Ctx, Evt);
   begin
      null;
   end Execute;

   procedure On_Event (Evt : Event_Kind; From : State) is
   begin
      if Trace_Config.Enabled then
         Put_Line ("[trace] event " & Evt'Image & " in " & From'Image);
      end if;
   end On_Event;

   procedure On_Action (Action : Action_Kind; From, To : State) is
      pragma Unreferenced (Action);
   begin
      if Trace_Config.Enabled then
         Put_Line ("[trace]   " & From'Image & " -> " & To'Image);
      end if;
   end On_Action;

   procedure On_Unhandled (Evt : Event_Kind; From : State) is
   begin
      if Trace_Config.Enabled then
         Put_Line ("[trace]   unhandled " & Evt'Image & " in " & From'Image);
      end if;
   end On_Unhandled;

   package SM is new
     Sml.Machines
       (State        => State,
        Event_Kind   => Event_Kind,
        Event        => Event,
        Context      => Context,
        Guard_Kind   => Guard_Kind,
        Action_Kind  => Action_Kind,
        Kind_Of      => Kind_Of,
        Evaluate     => Evaluate,
        Execute      => Execute,
        On_Event     => On_Event,
        On_Action    => On_Action,
        On_Unhandled => On_Unhandled);

   package Op is new SM.Operators (Always => Always, Nothing => Nothing);
   use SM, Op;

   Digit  : constant Ev := (Kind => E_Digit);
   Colon  : constant Ev := (Kind => E_Colon);
   End_Ev : constant Ev := (Kind => E_End);

   --!format off
   Table : constant Transition_Table :=
     [Hours   + Digit  >= Hours,
      Hours   + Colon  >= Minutes,
      Minutes + Digit  >= Minutes,
      Minutes + Colon  >= Seconds,
      Minutes + End_Ev >= Complete,
      Seconds + Digit  >= Seconds,
      Seconds + End_Ev >= Complete];
   --!format on

   function Classify (C : Character) return Event is
   begin
      case C is
         when '0' .. '9' =>
            return (Kind => E_Digit);

         when ':'        =>
            return (Kind => E_Colon);

         when others     =>
            return (Kind => E_Other);
      end case;
   end Classify;

   procedure Trace_Scan (S : String) is
      M   : Machine := Make (Table, Initial => Hours);
      Ctx : Context;
      Ms  : Tempus.Day_Milliseconds;
      Ok  : Boolean;
   begin
      Put_Line ("scanning """ & S & """:");
      for C of S loop
         Process_Event (M, Ctx, Classify (C));
      end loop;
      Process_Event (M, Ctx, (Kind => E_End));
      Put_Line ("  final state: " & State_Of (M)'Image);

      Tempus.Time_Of_Day.Parse (S, Ms, Ok);
      if Ok then
         Put_Line ("  Tempus.Time_Of_Day.Parse ->" & Ms'Image & " ms");
      else
         Put_Line ("  Tempus.Time_Of_Day.Parse -> malformed");
      end if;
      New_Line;
   end Trace_Scan;

begin
   Put_Line
     ("Walking HH:MM[:SS] with a traced sml state machine (tracing is "
      & (if Trace_Config.Enabled then "on" else "off")
      & ").");
   New_Line;
   Trace_Scan ("09:35:00");
   Trace_Scan ("9:5");
   Trace_Scan ("noon");
end Scan_Trace;
