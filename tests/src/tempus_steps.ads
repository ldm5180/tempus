with Fabula.Args;
with Fabula.Check;
with Fabula.Frames;
with Fabula.Registry;

with Tempus;

--  The step registry the feature runner dispatches on: one Step_Kind
--  per pattern, one table that reads like the features, and one Execute
--  that offers each step to the features' state machines.

package Tempus_Steps is

   --  The steps, grouped by the feature that reads them.  Each is an
   --  event of that feature's state machine, in its own child package.
   type Step_Kind is
     (E_Image,
      E_Parse,
      E_Refuse,
      E_Round_Trip,
      E_Valid,
      E_Invalid,
      E_To_Epoch,
      E_Civil,
      E_Tod,
      E_Tod_Refused,
      E_Epoch_Ms,
      E_Agree,
      --  An event no pattern names: the instants machine posts it to
      --  itself after the readings whose results the next row's guard
      --  reads.
      E_Compared);

   type Hook_Kind is (Fresh_World);

   --  What a time of day and a timestamp read as, for the comparison
   --  the step takes next.
   type Readings is record
      Ms       : Tempus.Day_Milliseconds := 0;
      Tod_Ok   : Boolean := False;
      Stamp    : Tempus.Epoch_Seconds := 0;
      Stamp_Ok : Boolean := False;
   end record;

   --  What one step carries into the event it takes next.  Every step
   --  names all its inputs, so nothing outlives a step.
   type World is record
      Read : Readings;
   end record;

   --  One step as a machine sees it: the scenario, the step's arguments,
   --  frame and outcome, and the event an action asks to be taken next
   --  (Then_Take), which the runner posts before the step returns.
   type Step_Context is record
      W        : World;
      A        : Fabula.Args.List;
      Info     : Fabula.Frames.Frame;
      R        : Fabula.Check.Outcome;
      Has_Next : Boolean := False;
      Next     : Step_Kind := Step_Kind'First;
   end record;

   procedure Then_Take (Ctx : in out Step_Context; Evt : Step_Kind);

   subtype LLI is Long_Long_Integer;

   --  Whether capture N reads as a whole number in Low .. High: the guard
   --  every bounded capture shares.  Read as a Long, since an instant
   --  need not fit 32 bits.
   function Reads_In
     (Ctx : Step_Context; N : Positive; Low, High : LLI) return Boolean;

   --  Capture N, which Reads_In said reads.
   function Number (Ctx : Step_Context; N : Positive) return LLI
   with
     Pre =>
       N <= Fabula.Args.Count (Ctx.A) and then Fabula.Args.Long (Ctx.A, N).Ok;

   --  Fail the step for capture N, called What: it does not read, or it
   --  is outside Low .. High.
   procedure Refuse_Range
     (Ctx : in out Step_Context; N : Positive; What : String; Low, High : LLI);

   --  Whether capture N is short enough for Tempus.Time_Of_Day.Parse.
   function Tod_Readable (Ctx : Step_Context; N : Positive) return Boolean;

   --  Capture N read as a time of day: its milliseconds, and whether it
   --  read.
   procedure Read_Tod
     (Ctx : Step_Context;
      N   : Positive;
      Ms  : out Tempus.Day_Milliseconds;
      Ok  : out Boolean)
   with Pre => Tod_Readable (Ctx, N);

   --  Fail the step: its time of day is longer than Parse reads.
   procedure Refuse_Tod_Length (Ctx : in out Step_Context);

   package Steps is new
     Fabula.Registry
       (Step_Kind => Step_Kind,
        Hook_Kind => Hook_Kind,
        Context   => World);
   use Steps;

   --!format off
   Step_Defs : constant Steps.Step_Table :=
     [Step ("the instant {int} formats as {word}")       >= E_Image,
      Step ("the instant {int} formats and parses back") >= E_Round_Trip,
      Step ("{word} parses to the instant {int}")        >= E_Parse,
      Step ("the text {string} is refused")              >= E_Refuse,
      Step ("{word} is refused")                         >= E_Refuse,
      Step ("{int}-{int}-{int} is a valid date")         >= E_Valid,
      Step ("{int}-{int}-{int} is not a valid date")     >= E_Invalid,
      Step ("{int}-{int}-{int} {int}:{int}:{int} at offset {int} "
            & "is the instant {int}")                    >= E_To_Epoch,
      Step ("day {int} since the epoch is {int}-{int}-{int}")
                                                         >= E_Civil,
      Step ("{word} is {int} ms into the day")           >= E_Tod,
      Step ("the text {string} is not a time of day")    >= E_Tod_Refused,
      Step ("{word} is not a time of day")               >= E_Tod_Refused,
      Step ("the date {int} at {int} ms is the instant {int} ms")
                                                         >= E_Epoch_Ms,
      Step ("the date {int} at {word} is the same instant as {word}")
                                                         >= E_Agree];
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
