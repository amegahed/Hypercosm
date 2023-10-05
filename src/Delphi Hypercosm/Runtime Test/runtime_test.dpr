program runtime_test;


{$APPTYPE CONSOLE}


uses
  SysUtils,
  get_data in '..\Runtime Code\heap_files\get_data.pas',
  get_heap_data in '..\Runtime Code\heap_files\get_heap_data.pas',
  handles in '..\Runtime Code\heap_files\handles.pas',
  heaps in '..\Runtime Code\heap_files\heaps.pas',
  memrefs in '..\Runtime Code\heap_files\memrefs.pas',
  query_data in '..\Runtime Code\heap_files\query_data.pas',
  set_data in '..\Runtime Code\heap_files\set_data.pas',
  set_heap_data in '..\Runtime Code\heap_files\set_heap_data.pas',
  load_operands in '..\Runtime Code\operand_stack_files\load_operands.pas',
  op_stacks in '..\Runtime Code\operand_stack_files\op_stacks.pas',
  store_operands in '..\Runtime Code\operand_stack_files\store_operands.pas',
  data in '..\Runtime Code\stack_files\data.pas',
  get_params in '..\Runtime Code\stack_files\get_params.pas',
  get_stack_data in '..\Runtime Code\stack_files\get_stack_data.pas',
  params in '..\Runtime Code\stack_files\params.pas',
  set_stack_data in '..\Runtime Code\stack_files\set_stack_data.pas',
  stacks in '..\Runtime Code\stack_files\stacks.pas',
  strings in '..\Common Code\basic_files\strings.pas',
  errors in '..\Nonportable Code\system_files\errors.pas',
  chars in '..\Common Code\basic_files\chars.pas',
  complex_numbers in '..\Common Code\math_files\complex_numbers.pas',
  constants in '..\Common Code\math_files\constants.pas',
  math_utils in '..\Common Code\math_files\math_utils.pas',
  trigonometry in '..\Common Code\math_files\trigonometry.pas',
  vectors in '..\Common Code\vector_files\vectors.pas',
  colors in '..\Common Code\display_files\colors.pas',
  data_types in '..\Abstract Syntax Tree Code\type_files\data_types.pas',
  addr_types in '..\Abstract Syntax Tree Code\type_files\addr_types.pas',
  new_memory in '..\Nonportable Code\system_files\new_memory.pas',
  array_limits in '..\Runtime Code\heap_files\array_limits.pas',
  exec_methods in 'exec_methods.pas',
  interpreter in 'interpreter.pas';


var
  ch: char;


procedure Test_handles1;
var
  handle1: handle_type;
  handle2: handle_type;
  handle3: handle_type;
  data: data_type;
  counter: integer;
begin
  writeln('allocating space...');
  handle1 := New_handle(10);
  handle2 := New_handle(10);
  handle3 := New_handle(10);
  writeln('done allocating space.');

  for counter := 1 to 10 do
    begin
      data.kind := integer_data;
      data.integer_val := counter;
      Set_handle_data(handle1, counter, data);
    end;

  for counter := 1 to 10 do
    begin
      data.kind := integer_data;
      data.integer_val := counter + 10;
      Set_handle_data(handle2, counter, data);
    end;

  for counter := 1 to 10 do
    begin
      data := Get_handle_data(handle1, counter);
      writeln('data[', counter: 1, '] = ', data.integer_val);
    end;
  Free_handle(handle1);

  for counter := 1 to 10 do
    begin
      data.kind := integer_data;
      data.integer_val := counter + 20;
      Set_handle_data(handle3, counter, data);
    end;

  for counter := 1 to 10 do
    begin
      data := Get_handle_data(handle2, counter);
      writeln('data[', counter: 1, '] = ', data.integer_val);
    end;

  for counter := 1 to 10 do
    begin
      data := Get_handle_data(handle3, counter);
      writeln('data[', counter: 1, '] = ', data.integer_val);
    end;

  Free_handle(handle2);
  Free_handle(handle3);
  writeln('done freeing space');
end; {procedure Test_handles1}


procedure Test_handles2;
const
  max_handle_size = 100;
  max_handles = 10;
var
  handle1: handle_type;
  size, handles, counter: integer;
  handle_array: array[1..max_handles] of handle_type;
begin
  while true do
    begin
      handles := Trunc((Rnd + 1) / 2 * 10) + 1;

      writeln('allocating ', handles: 1, ' handles...');
      for counter := 1 to handles do
        begin
          size := Trunc((Rnd + 1) / 2 * max_handle_size) + 1;
          writeln('allocating handle of size = ', size: 1);
          handle_array[counter] := New_handle(size);
        end;

      writeln('freeing ', handles: 1, ' handles...');
      for counter := 1 to handles do
        begin
          Free_handle(handle_array[counter]);
        end;
    end;
end; {procedure Test_handles2}


procedure Test_memrefs2;
const
  max_memref_size = 100;
  max_memrefs = 10;
var
  memref1: memref_type;
  size, memrefs, counter: integer;
  memref_array: array[1..max_memrefs] of memref_type;
begin
  while true do
    begin
      memrefs := Trunc((Rnd + 1) / 2 * 10) + 1;

      writeln('allocating ', memrefs: 1, ' memrefs...');
      for counter := 1 to memrefs do
        begin
          size := Trunc((Rnd + 1) / 2 * max_memref_size) + 1;
          writeln('allocating memref of size = ', size: 1);
          memref_array[counter] := New_memref(size);
        end;

      writeln('freeing ', memrefs: 1, ' memrefs...');
      for counter := 1 to memrefs do
        begin
          Free_memref(memref_array[counter]);
        end;
    end;
end; {procedure Test_memrefs2}


begin
  Init_rnd(17);
  Test_memrefs2;
  readln(ch);
end.
 