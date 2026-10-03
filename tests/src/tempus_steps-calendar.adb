with Ada.Characters.Handling;

with Fabula.Check.Ints;
with Fabula.Check.Longs;
with Fabula.Numbers;

with Tempus.Calendar;

with Tempus_Steps.Flows;

package body Tempus_Steps.Calendar is

   subtype LLI is Long_Long_Integer;

   --  One state: no calendar step depends on another.
   type State is (Ready);

   type Guard_Kind is (Always, Fields_In_Range, Days_In_Range);

   type Action_Kind is
     (A_Nothing,
      A_Expect_Valid,
      A_Expect_Invalid,
      A_To_Epoch,
      A_Civil,
      A_Refuse_Field,
      A_Refuse_Days);

   ---------------------------------------------------------------------
   --  The civil fields a step names, in capture order, and the range
   --  To_Epoch's precondition allows each.
   ---------------------------------------------------------------------

   type Field_Name is (Year, Month, Day, Hour, Minute, Second, Offset);

   type Bounds is record
      Low, High : LLI;
   end record;

   Two_Digits : constant Bounds := (0, 99);

   Allowed : constant array (Field_Name) of Bounds :=
     [Year => (0, 9_999), Offset => (-86_400, 86_400), others => Two_Digits];

   --  Civil_From_Days's precondition on its count of days.
   Most_Days : constant := 3_000_000;

   Days_Capture : constant := 1;

   --  How many of a step's leading captures are civil fields.
   function Fields_Of (Evt : Step_Kind) return Field_Name
   is (case Evt is
         when E_To_Epoch => Offset,
         when others     => Day);

   function Field_At (F : Field_Name) return Positive
   is (Field_Name'Pos (F) + 1);

   function Field_Fits (Ctx : Step_Context; F : Field_Name) return Boolean
   is (Field_At (F) <= Fabula.Args.Count (Ctx.A)
       and then Fabula.Args.Int (Ctx.A, Field_At (F)).Ok
       and then LLI (Fabula.Args.Int (Ctx.A, Field_At (F)).Value)
                in Allowed (F).Low .. Allowed (F).High);

   function Fields_Fit (Ctx : Step_Context; Last : Field_Name) return Boolean
   is (for all F in Field_Name'First .. Last => Field_Fits (Ctx, F));

   --  Field F of a step whose fields fit.
   function Value (Ctx : Step_Context; F : Field_Name) return LLI
   is (LLI (Fabula.Args.Int (Ctx.A, Field_At (F)).Value))
   with Pre => Field_Fits (Ctx, F);

   function Days_Fit (Ctx : Step_Context) return Boolean
   is (Fabula.Args.Long (Ctx.A, Days_Capture).Ok
       and then Fabula.Args.Long (Ctx.A, Days_Capture).Value
                in 0 .. Most_Days);

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean is
   begin
      return
        (case G is
           when Always          => True,
           when Fields_In_Range => Fields_Fit (Ctx, Fields_Of (Evt)),
           when Days_In_Range   => Days_Fit (Ctx));
   end Evaluate;

   ---------------------------------------------------------------------
   --  Actions.
   ---------------------------------------------------------------------

   function Valid (Ctx : Step_Context) return Boolean
   is (Tempus.Calendar.Valid_Date
         (Value (Ctx, Year), Value (Ctx, Month), Value (Ctx, Day), 0, 0, 0))
   with Pre => Fields_Fit (Ctx, Day);

   function Date_Image (Ctx : Step_Context) return String
   is (Fabula.Args.Text (Ctx.A, Field_At (Year))
       & "-"
       & Fabula.Args.Text (Ctx.A, Field_At (Month))
       & "-"
       & Fabula.Args.Text (Ctx.A, Field_At (Day)));

   procedure Check_To_Epoch (Ctx : in out Step_Context)
   with Pre => Fields_Fit (Ctx, Offset)
   is
      Expected : constant Positive := Field_At (Offset) + 1;
   begin
      Fabula.Check.Longs.Equal
        (Ctx.R,
         Tempus.Calendar.To_Epoch
           (Value (Ctx, Year),
            Value (Ctx, Month),
            Value (Ctx, Day),
            Value (Ctx, Hour),
            Value (Ctx, Minute),
            Value (Ctx, Second),
            Value (Ctx, Offset)),
         Fabula.Args.Long (Ctx.A, Expected));
   end Check_To_Epoch;

   --  Field F of the date that follows a count of days.
   function After_Days
     (Ctx : Step_Context; F : Field_Name) return Fabula.Numbers.Long_Reads.Read
   is (Fabula.Args.Long (Ctx.A, Days_Capture + Field_At (F)));

   procedure Check_Civil (Ctx : in out Step_Context) with Pre => Days_Fit (Ctx)
   is
      Y, M, D : LLI;
   begin
      Tempus.Calendar.Civil_From_Days
        (Fabula.Args.Long (Ctx.A, Days_Capture).Value, Y, M, D);
      Fabula.Check.Longs.Equal (Ctx.R, Y, After_Days (Ctx, Year));
      Fabula.Check.Longs.Equal (Ctx.R, M, After_Days (Ctx, Month));
      Fabula.Check.Longs.Equal (Ctx.R, D, After_Days (Ctx, Day));
   end Check_Civil;

   function Name_Of (F : Field_Name) return String
   is (Ada.Characters.Handling.To_Lower (F'Image));

   --  Why field F does not fit: it does not read, or it is out of range.
   procedure Refuse_Fit (Ctx : in out Step_Context; F : Field_Name) is
      Read : constant Fabula.Numbers.Integer_Reads.Read :=
        Fabula.Args.Int (Ctx.A, Field_At (F));
   begin
      if Read.Ok then
         Fabula.Check.Fail_Step
           (Ctx.R,
            "the "
            & Name_Of (F)
            & " is outside "
            & Fabula.Check.Long_Image (Allowed (F).Low)
            & " .. "
            & Fabula.Check.Long_Image (Allowed (F).High));
      else
         Fabula.Check.Ints.Fail_Read (Ctx.R, Read.Error, "the " & Name_Of (F));
      end if;
   end Refuse_Fit;

   --  The first field of the step that does not fit, and why.
   procedure Refuse_Field (Ctx : in out Step_Context; Last : Field_Name) is
   begin
      for F in Field_Name'First .. Last loop
         if not Field_Fits (Ctx, F) then
            Refuse_Fit (Ctx, F);
            return;
         end if;
      end loop;
   end Refuse_Field;

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind) is
   begin
      case A is
         when A_Nothing        =>
            null;

         when A_Expect_Valid   =>
            Fabula.Check.Is_True
              (Ctx.R, Valid (Ctx), Date_Image (Ctx) & " is not a date");

         when A_Expect_Invalid =>
            Fabula.Check.Is_False
              (Ctx.R, Valid (Ctx), Date_Image (Ctx) & " is a date");

         when A_To_Epoch       =>
            Check_To_Epoch (Ctx);

         when A_Civil          =>
            Check_Civil (Ctx);

         when A_Refuse_Field   =>
            Refuse_Field (Ctx, Fields_Of (Evt));

         when A_Refuse_Days    =>
            Fabula.Check.Fail_Step
              (Ctx.R, "a count of days is a number in 0 .. 3000000");
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

   Valid_Date   : constant Ev := (Kind => E_Valid);
   Invalid_Date : constant Ev := (Kind => E_Invalid);
   To_Epoch     : constant Ev := (Kind => E_To_Epoch);
   Civil        : constant Ev := (Kind => E_Civil);

   --!format off
   Table : constant Transition_Table :=
     [Ready + Valid_Date   (Fields_In_Range) / A_Expect_Valid   >= Ready,
      Ready + Valid_Date                     / A_Refuse_Field   >= Ready,
      Ready + Invalid_Date (Fields_In_Range) / A_Expect_Invalid >= Ready,
      Ready + Invalid_Date                   / A_Refuse_Field   >= Ready,
      Ready + To_Epoch     (Fields_In_Range) / A_To_Epoch       >= Ready,
      Ready + To_Epoch                       / A_Refuse_Field   >= Ready,
      Ready + Civil        (Days_In_Range)   / A_Civil          >= Ready,
      Ready + Civil                          / A_Refuse_Days    >= Ready];
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

end Tempus_Steps.Calendar;
