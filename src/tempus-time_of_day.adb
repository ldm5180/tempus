package body Tempus.Time_Of_Day
  with SPARK_Mode
is

   procedure Parse (Text : String; Ms : out Day_Milliseconds; Ok : out Boolean)
   is
      subtype Field_Index is Positive range 1 .. 3;

      --  Each colon-separated field, capped well past any real value so the
      --  digit accumulator cannot overflow (range validation is on the parsed
      --  field, below).
      Field_Cap : constant := 100_000;

      Parts     : array (Field_Index) of Natural := [others => 0];
      Count     : Natural := 0;      --  fields closed so far (a 4th is bad)
      Has_Digit : Boolean := False;  --  the field being read holds a digit
      Cur       : Natural := 0;      --  the field being read
      Bad       : Boolean := False;

      --  Close the field just read; an empty field (a stray/leading/trailing
      --  colon) or a fourth field marks the spelling malformed.  The caller
      --  resets Cur/Has_Digit after a colon; the final field needs no reset.
      procedure Close_Field is
      begin
         if not Has_Digit or else Count >= 3 then
            Bad := True;
         else
            Count := Count + 1;
            Parts (Count) := Cur;
         end if;
      end Close_Field;
   begin
      Ms := 0;
      Ok := False;

      for C of Text loop
         pragma Loop_Invariant (Cur <= Field_Cap);
         if C = ':' then
            Close_Field;
            Cur := 0;
            Has_Digit := False;
         elsif C in '0' .. '9' then
            Cur :=
              Natural'Min
                (Cur * 10 + (Character'Pos (C) - Character'Pos ('0')),
                 Field_Cap);
            Has_Digit := True;
         else
            Bad := True;
         end if;
      end loop;
      Close_Field;  --  the final field after the last colon

      if Bad or else Count < 2 then
         return;
      end if;

      declare
         H : constant Natural := Parts (1);
         M : constant Natural := Parts (2);
         S : constant Natural := (if Count = 3 then Parts (3) else 0);
      begin
         if H <= 23 and then M <= 59 and then S <= 59 then
            Ms := Day_Milliseconds ((H * 3_600 + M * 60 + S) * 1_000);
            Ok := True;
         end if;
      end;
   end Parse;

end Tempus.Time_Of_Day;
