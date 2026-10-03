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
      E_Tod_Refused);

   type Hook_Kind is (Fresh_World);

   --  What one scenario carries from step to step: nothing yet, since
   --  every timestamp step names all its inputs.
   type World is null record;

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

   --  Whether capture N reads as a whole number of zero or more: the
   --  guard every counting step's rows share.
   function Count_Read (Ctx : Step_Context; N : Positive := 1) return Boolean;

   --  Capture N, which Count_Read said reads.
   function Count (Ctx : Step_Context; N : Positive := 1) return Natural
   with Pre => Count_Read (Ctx, N);

   --  Fail the step for capture N: why it does not read as a count.
   procedure Refuse_Count (Ctx : in out Step_Context; N : Positive := 1);

   --  Whether capture N reads as an instant: whole seconds since the
   --  epoch, inside Tempus.Epoch_Seconds.  Read as a Long, since an
   --  instant need not fit 32 bits.
   function Instant_Read
     (Ctx : Step_Context; N : Positive := 1) return Boolean;

   --  Capture N, which Instant_Read said reads.
   function Instant
     (Ctx : Step_Context; N : Positive := 1) return Tempus.Epoch_Seconds
   with Pre => Instant_Read (Ctx, N);

   --  Fail the step for capture N: why it does not read as an instant.
   procedure Refuse_Instant (Ctx : in out Step_Context; N : Positive := 1);

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
      Step ("{word} is not a time of day")               >= E_Tod_Refused];
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
