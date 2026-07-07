--  gnatprove analyses a unit only when it is in the closure of the project's
--  sources.  This package withs every Tempus unit so a single
--  `gnatprove -P proof/proof.gpr` run covers the whole library; the per-unit
--  harnesses beside it instantiate the generics (gnatprove reasons about a
--  generic only through a concrete instance).  Keep this list complete.
with Tempus;
with Tempus.Calendar;

package Core_Closure_Proof
  with SPARK_Mode
is
end Core_Closure_Proof;
