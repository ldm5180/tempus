with Sml.Machines;
with Sml.Machines.Operators;

package body Tempus.Rfc3339.Scanner
  with SPARK_Mode
is

   --  Parse phases.  Each numeric field is read in its own state; the
   --  separators ('-', 'T', ':') and terminators ('.', 'Z', '+', '-')
   --  advance it.  Done is the sole accepting state.
   type Scan_State is
     (Year,
      Month,
      Day,
      Hour,
      Minute,
      Second,
      Fraction,
      Zone_Z,
      Offset_Hour,
      Offset_Min,
      Done);

   --  One kind per input character class.  '-' is E_Dash in both roles (date
   --  separator early, offset-minus after the seconds) -- the state decides
   --  which; anything unexpected is E_Other, for which no row exists.
   type Event_Kind is
     (E_Digit, E_Dash, E_Colon, E_Time, E_Dot, E_Zulu, E_Plus, E_End, E_Other);

   subtype Digit is Natural range 0 .. 9;

   type Scan_Event (Kind : Event_Kind := E_Other) is record
      case Kind is
         when E_Digit =>
            D : Digit;

         when others =>
            null;
      end case;
   end record;

   --  Extended state: the field accumulators plus the digit count of the
   --  field being read (Len) and the fraction-digit count (Frac_Seen).
   type Ctx_Type is record
      Year      : Natural := 0;
      Month     : Natural := 0;
      Day       : Natural := 0;
      Hour      : Natural := 0;
      Minute    : Natural := 0;
      Second    : Natural := 0;
      Len       : Natural := 0;
      Frac_Seen : Natural := 0;
      Off_Hour  : Natural := 0;
      Off_Min   : Natural := 0;
      Off_Neg   : Boolean := False;
   end record;

   type Guard_Kind is
     (Always, Len_Lt_2, Len_Eq_2, Len_Lt_4, Len_Eq_4, Frac_Ge_1);

   type Action_Kind is
     (Nothing,
      Reset_Len,
      Acc_Year,
      Acc_Month,
      Acc_Day,
      Acc_Hour,
      Acc_Min,
      Acc_Sec,
      Count_Frac,
      Begin_Pos_Off,
      Begin_Neg_Off,
      Acc_Off_H,
      Acc_Off_M);

   function Kind_Of (E : Scan_Event) return Event_Kind
   is (E.Kind);

   function Evaluate
     (G : Guard_Kind; Ctx : Ctx_Type; Evt : Scan_Event) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always    => True,
           when Len_Lt_2  => Ctx.Len < 2,
           when Len_Eq_2  => Ctx.Len = 2,
           when Len_Lt_4  => Ctx.Len < 4,
           when Len_Eq_4  => Ctx.Len = 4,
           when Frac_Ge_1 => Ctx.Frac_Seen >= 1);
   end Evaluate;

   --  Append a digit to a field and count it.  The value cap keeps the
   --  multiply provably in range without leaning on the guards (which the
   --  engine checks but gnatprove cannot see across Execute); the digit-count
   --  guards are what actually stop a field after 2 or 4 digits.
   procedure Push (Field : in out Natural; Len : in out Natural; D : Digit) is
   begin
      if Field <= (Natural'Last - D) / 10 then
         Field := Field * 10 + D;
      end if;
      if Len < Natural'Last then
         Len := Len + 1;
      end if;
   end Push;

   procedure Execute (A : Action_Kind; Ctx : in out Ctx_Type; Evt : Scan_Event)
   is
      D : constant Digit := (if Evt.Kind = E_Digit then Evt.D else 0);
   begin
      case A is
         when Nothing       =>
            null;

         when Reset_Len     =>
            Ctx.Len := 0;

         when Acc_Year      =>
            Push (Ctx.Year, Ctx.Len, D);

         when Acc_Month     =>
            Push (Ctx.Month, Ctx.Len, D);

         when Acc_Day       =>
            Push (Ctx.Day, Ctx.Len, D);

         when Acc_Hour      =>
            Push (Ctx.Hour, Ctx.Len, D);

         when Acc_Min       =>
            Push (Ctx.Minute, Ctx.Len, D);

         when Acc_Sec       =>
            Push (Ctx.Second, Ctx.Len, D);

         when Count_Frac    =>
            if Ctx.Frac_Seen < Natural'Last then
               Ctx.Frac_Seen := Ctx.Frac_Seen + 1;
            end if;

         when Begin_Pos_Off =>
            Ctx.Len := 0;

         when Begin_Neg_Off =>
            Ctx.Off_Neg := True;
            Ctx.Len := 0;

         when Acc_Off_H     =>
            Push (Ctx.Off_Hour, Ctx.Len, D);

         when Acc_Off_M     =>
            Push (Ctx.Off_Min, Ctx.Len, D);
      end case;
   end Execute;

   package SM is new
     Sml.Machines
       (State       => Scan_State,
        Event_Kind  => Event_Kind,
        Event       => Scan_Event,
        Context     => Ctx_Type,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Kind_Of     => Kind_Of,
        Evaluate    => Evaluate,
        Execute     => Execute);

   package Op is new SM.Operators (Always => Always, Nothing => Nothing);
   use SM, Op;

   --  One kind-only wrapper per event, for the operator table below.
   Digit_Ev : constant Ev := (Kind => E_Digit);
   Dash     : constant Ev := (Kind => E_Dash);
   Colon    : constant Ev := (Kind => E_Colon);
   Time_Ev  : constant Ev := (Kind => E_Time);
   Dot      : constant Ev := (Kind => E_Dot);
   Zulu     : constant Ev := (Kind => E_Zulu);
   Plus     : constant Ev := (Kind => E_Plus);
   End_Ev   : constant Ev := (Kind => E_End);

   --  From + Event (Guard) / Action >= To.  A digit stays in the field while
   --  the count guard allows; the separator that closes the field advances the
   --  state and resets the count.
   --!format off
   Table : constant Transition_Table :=
     [Year        + Digit_Ev (Len_Lt_4) / Acc_Year       >= Year,
      Year        + Dash     (Len_Eq_4) / Reset_Len      >= Month,
      Month       + Digit_Ev (Len_Lt_2) / Acc_Month      >= Month,
      Month       + Dash     (Len_Eq_2) / Reset_Len      >= Day,
      Day         + Digit_Ev (Len_Lt_2) / Acc_Day        >= Day,
      Day         + Time_Ev  (Len_Eq_2) / Reset_Len      >= Hour,
      Hour        + Digit_Ev (Len_Lt_2) / Acc_Hour       >= Hour,
      Hour        + Colon    (Len_Eq_2) / Reset_Len      >= Minute,
      Minute      + Digit_Ev (Len_Lt_2) / Acc_Min        >= Minute,
      Minute      + Colon    (Len_Eq_2) / Reset_Len      >= Second,
      Second      + Digit_Ev (Len_Lt_2) / Acc_Sec        >= Second,
      Second      + Dot      (Len_Eq_2)                   >= Fraction,
      Second      + Zulu     (Len_Eq_2)                   >= Zone_Z,
      Second      + Plus     (Len_Eq_2) / Begin_Pos_Off  >= Offset_Hour,
      Second      + Dash     (Len_Eq_2) / Begin_Neg_Off  >= Offset_Hour,
      Fraction    + Digit_Ev            / Count_Frac     >= Fraction,
      Fraction    + Zulu     (Frac_Ge_1)                 >= Zone_Z,
      Fraction    + Plus     (Frac_Ge_1) / Begin_Pos_Off >= Offset_Hour,
      Fraction    + Dash     (Frac_Ge_1) / Begin_Neg_Off >= Offset_Hour,
      Zone_Z      + End_Ev                               >= Done,
      Offset_Hour + Digit_Ev (Len_Lt_2) / Acc_Off_H      >= Offset_Hour,
      Offset_Hour + Colon    (Len_Eq_2) / Reset_Len      >= Offset_Min,
      Offset_Min  + Digit_Ev (Len_Lt_2) / Acc_Off_M      >= Offset_Min,
      Offset_Min  + End_Ev   (Len_Eq_2)                  >= Done];
   --!format on

   function Classify (C : Character) return Scan_Event is
   begin
      case C is
         when '0' .. '9' =>
            return
              (Kind => E_Digit, D => Character'Pos (C) - Character'Pos ('0'));

         when '-'        =>
            return (Kind => E_Dash);

         when ':'        =>
            return (Kind => E_Colon);

         when 'T'        =>
            return (Kind => E_Time);

         when '.'        =>
            return (Kind => E_Dot);

         when 'Z'        =>
            return (Kind => E_Zulu);

         when '+'        =>
            return (Kind => E_Plus);

         when others     =>
            return (Kind => E_Other);
      end case;
   end Classify;

   function Scan (S : String) return Fields is
      M       : Machine := Make (Table, Initial => Year);
      Ctx     : Ctx_Type;
      Handled : Boolean;
      Failed  : Boolean := False;
      Result  : Fields;
   begin
      --  Feed one event per character; an event with no matching row (a
      --  malformed spelling) is reported unhandled and stops the scan.
      for I in S'Range loop
         Process_Event (M, Ctx, Classify (S (I)), Handled);
         if not Handled then
            Failed := True;
            exit;
         end if;
      end loop;

      --  The end-of-input event closes an accepting state (after Z, or after
      --  the offset's minutes); anywhere else it is unhandled.
      if not Failed then
         Process_Event (M, Ctx, (Kind => E_End), Handled);
         Failed := not Handled;
      end if;

      --  The value caps below are always satisfied when Done was reached (the
      --  guards bounded each field's digit count), but stating them gives the
      --  proof the ranges of the constrained Fields components; the offset
      --  bounds also reject a structurally valid but out-of-range zone.
      if not Failed
        and then State_Of (M) = Done
        and then Ctx.Year <= 9_999
        and then Ctx.Month <= 99
        and then Ctx.Day <= 99
        and then Ctx.Hour <= 99
        and then Ctx.Minute <= 99
        and then Ctx.Second <= 99
        and then Ctx.Off_Hour <= 23
        and then Ctx.Off_Min <= 59
      then
         Result :=
           (Valid          => True,
            Year           => Ctx.Year,
            Month          => Ctx.Month,
            Day            => Ctx.Day,
            Hour           => Ctx.Hour,
            Minute         => Ctx.Minute,
            Second         => Ctx.Second,
            Offset_Seconds =>
              (if Ctx.Off_Neg then -1 else 1)
              * (3_600 * Ctx.Off_Hour + 60 * Ctx.Off_Min));
      end if;
      return Result;
   end Scan;

end Tempus.Rfc3339.Scanner;
