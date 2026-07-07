--  Combine a civil date and a time-of-day into a Unix epoch instant.

package Tempus.Instants
  with SPARK_Mode
is

   --  Epoch milliseconds for a packed civil date (YYYYMMDD) at Ms into its
   --  day.  A date outside the representable range clamps to 0 (the epoch):
   --  the packed form can spell impossible dates, so a garbage value yields a
   --  harmless instant rather than a wild one.
   function Epoch_Ms
     (Date : Packed_Date; Ms : Day_Milliseconds) return Epoch_Milliseconds;

end Tempus.Instants;
