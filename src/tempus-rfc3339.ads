--  RFC3339 timestamps.  Image always emits UTC "YYYY-MM-DDThh:mm:ssZ" (which
--  Go's time.Time parses back); reading the fractional / numeric-offset forms
--  Go marshals is Value's job (added in the scanner cycle).

package Tempus.Rfc3339
  with SPARK_Mode
is

   subtype Timestamp_String is String (1 .. 20);
   --  Exactly "YYYY-MM-DDThh:mm:ssZ".

   Max_Formattable : constant Tempus.Epoch_Seconds := 253_402_300_799;
   --  9999-12-31T23:59:59Z, the last instant with a four-digit year.

   function Image (T : Tempus.Epoch_Seconds) return Timestamp_String
   with Pre => T <= Max_Formattable;

end Tempus.Rfc3339;
