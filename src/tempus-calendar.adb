package body Tempus.Calendar
  with SPARK_Mode
is

   function Valid_Date (Year, Month, Day, Hour, Min, Sec : LLI) return Boolean
   is
      Is_Leap       : constant Boolean :=
        (Year mod 4 = 0 and then Year mod 100 /= 0) or else Year mod 400 = 0;
      Days_In_Month : constant LLI :=
        (if Month = 2
         then (if Is_Leap then 29 else 28)
         elsif Month in 4 | 6 | 9 | 11
         then 30
         else 31);
   begin
      return
        Year >= 1_970
        and then Month in 1 .. 12
        and then Day in 1 .. Days_In_Month
        and then Hour <= 23
        and then Min <= 59
        and then Sec <= 59;
   end Valid_Date;

   function To_Epoch
     (Year, Month, Day, Hour, Min, Sec, Offset_Seconds : LLI) return LLI
   is
      YA   : constant LLI := Year - (if Month <= 2 then 1 else 0);
      Era  : constant LLI := YA / 400;
      YOE  : constant LLI := YA - Era * 400;
      MP   : constant LLI := (if Month > 2 then Month - 3 else Month + 9);
      DOY  : constant LLI := (153 * MP + 2) / 5 + Day - 1;
      DOE  : constant LLI := YOE * 365 + YOE / 4 - YOE / 100 + DOY;
      Days : constant LLI := Era * 146_097 + DOE - 719_468;
   begin
      return 86_400 * Days + 3_600 * Hour + 60 * Min + Sec - Offset_Seconds;
   end To_Epoch;

   procedure Civil_From_Days (Days : LLI; Year, Month, Day : out LLI) is
      Z   : constant LLI := Days + 719_468;
      Era : constant LLI := Z / 146_097;
      DOE : constant LLI := Z - Era * 146_097;
      YOE : constant LLI :=
        (DOE - DOE / 1_460 + DOE / 36_524 - DOE / 146_096) / 365;
      DOY : constant LLI := DOE - (365 * YOE + YOE / 4 - YOE / 100);
      MP  : constant LLI := (5 * DOY + 2) / 153;
      M   : constant LLI := (if MP < 10 then MP + 3 else MP - 9);
   begin
      Day := DOY - (153 * MP + 2) / 5 + 1;
      Month := M;
      Year := YOE + Era * 400 + (if M <= 2 then 1 else 0);
   end Civil_From_Days;

end Tempus.Calendar;
