with Fabula.Main;

with Tempus_Steps;

--  The feature runner: Fabula.Main over the crate's step registry,
--  run over tests/features/ by `make features` and `alr test`.

procedure Tempus_Features is new
  Fabula.Main
    (Steps     => Tempus_Steps.Steps,
     Step_Defs => Tempus_Steps.Step_Defs,
     Hook_Defs => Tempus_Steps.Hook_Defs,
     Execute   => Tempus_Steps.Execute,
     Run_Hook  => Tempus_Steps.Run_Hook);
