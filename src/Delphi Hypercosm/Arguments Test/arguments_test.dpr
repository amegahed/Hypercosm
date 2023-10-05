program arguments_test;


{$APPTYPE CONSOLE}


uses
  SysUtils;


var
  param_count: integer;
  counter: integer;


begin
  param_count := ParamCount;

  writeln('# of Params = ', param_count);
  for counter := 1 to param_count do
    begin
      writeln('Parameter #', counter, ' = ',  ParamStr(counter));
    end;

  readln;
end.
