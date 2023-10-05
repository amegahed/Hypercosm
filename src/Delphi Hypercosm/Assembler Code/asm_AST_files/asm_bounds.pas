unit asm_bounds;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             asm_bounds                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The asm_bounds module defines all of the array          }
{       bounds used in the mnemonic assembly code, the          }
{       external representation of the code which is used       }
{       by the interpreter.                                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  arrays, asms;


{**************************************************}
{ routines for making and referencing array bounds }
{**************************************************}
procedure Make_new_asm_array_bounds(count: asm_index_type);
procedure Make_new_asm_array_bounds_lists(count: asm_index_type);
function New_asm_array_bounds: array_bounds_ptr_type;
function New_asm_array_bounds_list: array_bounds_list_ptr_type;
function Ref_asm_array_bounds(index: asm_index_type): array_bounds_ref_type;
function Ref_asm_array_bounds_list(index: asm_index_type):
  array_bounds_list_ref_type;

{*******************************************************}
{ routines to assemble array bounds from assembly codes }
{*******************************************************}
function Assemble_array_bounds: array_bounds_ptr_type;
function Assemble_array_bounds_list: array_bounds_list_ptr_type;

{**********************************************************}
{ routines to disassemble array bounds into assembly codes }
{**********************************************************}
procedure Disassemble_array_bounds(var outfile: text;
  array_bounds_ptr: array_bounds_ptr_type);
procedure Disassemble_array_bounds_list(var outfile: text;
  array_bounds_list_ptr: array_bounds_list_ptr_type);

{****************************************}
{ functions returning assembler progress }
{****************************************}
function Array_bounds_assembled: asm_index_type;
function Array_bounds_lists_assembled: asm_index_type;
function Array_bounds_disassembled: asm_index_type;
function Array_bounds_lists_disassembled: asm_index_type;


implementation
uses
  new_memory, errors, exprs, asm_indices, asm_exprs;


const
  memory_alert = false;


var
  {************************}
  { array bounds variables }
  {************************}
  array_bounds_asm_count, array_bounds_disasm_count: asm_index_type;
  array_bounds_block_ptr: array_bounds_ptr_type;
  array_bounds_block_count: asm_index_type;

  {*****************************}
  { array bounds list variables }
  {*****************************}
  array_bounds_list_asm_count, array_bounds_list_disasm_count: asm_index_type;
  array_bounds_list_block_ptr: array_bounds_list_ptr_type;
  array_bounds_list_block_count: asm_index_type;


{**************************************************}
{ routines for making and referencing array bounds }
{**************************************************}


procedure Make_new_asm_array_bounds(count: asm_index_type);
var
  array_bounds_block_size: longint;
begin
  if count > 0 then
    begin
      {*********************************}
      { compute array bounds block size }
      {*********************************}
      array_bounds_block_size := longint(count + 1) * sizeof(array_bounds_type);

      {*****************************}
      { allocate array bounds block }
      {*****************************}
      if memory_alert then
        writeln('allocating new array bounds block');
      array_bounds_block_ptr :=
        array_bounds_ptr_type(New_ptr(array_bounds_block_size));
      array_bounds_block_count := count;
    end;
end; {procedure Make_new_asm_array_bounds}


function New_asm_array_bounds: array_bounds_ptr_type;
var
  array_bounds_ptr: array_bounds_ptr_type;
begin
  array_bounds_asm_count := array_bounds_asm_count + 1;
  array_bounds_ptr := Ref_asm_array_bounds(array_bounds_asm_count);
  Init_array_bounds(array_bounds_ptr);
  New_asm_array_bounds := array_bounds_ptr;
end; {function New_asm_array_bounds}


function Ref_asm_array_bounds(index: asm_index_type): array_bounds_ref_type;
begin
  if index > array_bounds_block_count then
    Asm_error;
  Ref_asm_array_bounds := array_bounds_ref_type(longint(array_bounds_block_ptr)
    + sizeof(array_bounds_type) * (index - 1));
end; {function Ref_asm_array_bounds}


{********************************************************}
{ routines for making and referencing array bounds lists }
{********************************************************}


procedure Make_new_asm_array_bounds_lists(count: asm_index_type);
var
  array_bounds_list_block_size: longint;
begin
  if count > 0 then
    begin
      {**************************************}
      { compute array bounds list block size }
      {**************************************}
      array_bounds_list_block_size := longint(count + 1) *
        sizeof(array_bounds_list_type);

      {**********************************}
      { allocate array bounds list block }
      {**********************************}
      if memory_alert then
        writeln('allocating new array bounds list block');
      array_bounds_list_block_ptr :=
        array_bounds_list_ptr_type(New_ptr(array_bounds_list_block_size));
      array_bounds_list_block_count := count;
    end;
end; {procedure Make_new_asm_array_bounds_lists}


function New_asm_array_bounds_list: array_bounds_list_ptr_type;
var
  array_bounds_list_ptr: array_bounds_list_ptr_type;
begin
  array_bounds_list_asm_count := array_bounds_list_asm_count + 1;
  array_bounds_list_ptr :=
    Ref_asm_array_bounds_list(array_bounds_list_asm_count);
  Init_array_bounds_list(array_bounds_list_ptr);
  New_asm_array_bounds_list := array_bounds_list_ptr;
end; {function New_asm_array_bounds_list}


function Ref_asm_array_bounds_list(index: asm_index_type):
  array_bounds_list_ref_type;
begin
  if index > array_bounds_list_block_count then
    Asm_error;
  Ref_asm_array_bounds_list :=
    array_bounds_list_ref_type(longint(array_bounds_list_block_ptr) +
    sizeof(array_bounds_list_type) * (index - 1));
end; {function Ref_asm_array_bounds_list}


{*******************************************************}
{ routines to assemble array bounds from assembly codes }
{*******************************************************}


function Assemble_array_bounds: array_bounds_ptr_type;
var
  array_bounds_ptr: array_bounds_ptr_type;
  mnemonic: mnemonic_type;
begin
  {*************************************}
  { assemble array bounds list mnemonic }
  {*************************************}
  mnemonic := Assemble_mnemonic;

  if mnemonic <> 'nil' then
    begin
      {*********************************}
      { assemble array bounds reference }
      {*********************************}
      if mnemonic = 'brf' then
        array_bounds_ptr := Ref_asm_array_bounds(Assemble_index)

        {******************************}
        { assemble static array bounds }
        {******************************}
      else if mnemonic = 'sab' then
        begin
          array_bounds_ptr := New_asm_array_bounds;
          array_bounds_ptr^.min_val := Assemble_integer;
          array_bounds_ptr^.max_val := Assemble_integer;
        end

          {*******************************}
          { assemble dynamic array bounds }
          {*******************************}
      else if mnemonic = 'dab' then
        begin
          array_bounds_ptr := New_asm_array_bounds;
          array_bounds_ptr^.min_expr_ptr :=
            forward_expr_ptr_type(Assemble_expr);
          array_bounds_ptr^.max_expr_ptr :=
            forward_expr_ptr_type(Assemble_expr);
        end

      else
        begin
          Asm_error;
          array_bounds_ptr := nil;
        end;
    end
  else
    array_bounds_ptr := nil;

  Assemble_array_bounds := array_bounds_ptr;
end; {function Assemble_array_bounds}


function Assemble_array_bounds_list: array_bounds_list_ptr_type;
var
  array_bounds_list_ptr: array_bounds_list_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
  mnemonic: mnemonic_type;
begin
  {*************************************}
  { assemble array bounds list mnemonic }
  {*************************************}
  mnemonic := Assemble_mnemonic;

  if mnemonic <> 'nil' then
    begin
      {**************************************}
      { assemble array bounds list reference }
      {**************************************}
      if mnemonic = 'blr' then
        array_bounds_list_ptr := Ref_asm_array_bounds_list(Assemble_index)

        {****************************}
        { assemble array bounds list }
        {****************************}
      else if mnemonic = 'abl' then
        begin
          array_bounds_list_ptr := New_asm_array_bounds_list;
          Assemble_integer;

          {*************************************}
          { assemble array bounds list operands }
          {*************************************}
          array_bounds_ptr := Assemble_array_bounds;
          while array_bounds_ptr <> nil do
            begin
              Add_array_bounds(array_bounds_list_ptr, array_bounds_ptr);
              array_bounds_ptr := Assemble_array_bounds;
            end;
        end

      else
        begin
          Asm_error;
          array_bounds_list_ptr := nil;
        end;
    end
  else
    array_bounds_list_ptr := nil;

  Assemble_array_bounds_list := array_bounds_list_ptr;
end; {function Assemble_array_bounds_list}


{**********************************************************}
{ routines to disassemble array bounds into assembly codes }
{**********************************************************}


procedure Disassemble_array_bounds(var outfile: text;
  array_bounds_ptr: array_bounds_ptr_type);
begin
  if array_bounds_ptr <> nil then
    begin
      {************************************}
      { disassemble array bounds reference }
      {************************************}
      if array_bounds_ptr^.array_bounds_index <> 0 then
        begin
          Disassemble_mnemonic(outfile, 'brf');
          Disassemble_index(outfile, array_bounds_ptr^.array_bounds_index);
        end

          {**************************}
          { disassemble array bounds }
          {**************************}
      else
        begin
          array_bounds_disasm_count := array_bounds_disasm_count + 1;
          array_bounds_ptr^.array_bounds_index := array_bounds_disasm_count;

          if (array_bounds_ptr^.min_expr_ptr <> nil) or
            (array_bounds_ptr^.max_expr_ptr <> nil) then
            begin
              {**********************************}
              { disassemble dynamic array bounds }
              {**********************************}
              Disassemble_mnemonic(outfile, 'dab');
              Disassemble_expr(outfile,
                expr_ptr_type(array_bounds_ptr^.min_expr_ptr));
              Disassemble_expr(outfile,
                expr_ptr_type(array_bounds_ptr^.max_expr_ptr));
            end
          else
            begin
              {*********************************}
              { disassemble static array bounds }
              {*********************************}
              Disassemble_mnemonic(outfile, 'sab');
              Disassemble_integer(outfile, array_bounds_ptr^.min_val);
              Disassemble_integer(outfile, array_bounds_ptr^.max_val);
            end;
        end;
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_array_bounds}


procedure Disassemble_array_bounds_list(var outfile: text;
  array_bounds_list_ptr: array_bounds_list_ptr_type);
var
  array_bounds_ptr: array_bounds_ptr_type;
begin
  if array_bounds_list_ptr <> nil then
    begin
      {*****************************************}
      { disassemble array bounds list reference }
      {*****************************************}
      if array_bounds_list_ptr^.array_bounds_list_index <> 0 then
        begin
          Disassemble_mnemonic(outfile, 'blr');
          Disassemble_index(outfile,
            array_bounds_list_ptr^.array_bounds_list_index);
        end

          {*******************************}
          { disassemble array bounds list }
          {*******************************}
      else
        begin
          array_bounds_list_disasm_count := array_bounds_list_disasm_count + 1;
          array_bounds_list_ptr^.array_bounds_list_index :=
            array_bounds_list_disasm_count;

          {****************************************}
          { disassemble array bounds list mnemonic }
          {****************************************}
          Disassemble_mnemonic(outfile, 'abl');

          {****************************************}
          { disassemble array bounds list operands }
          {****************************************}
          Disassemble_integer(outfile, array_bounds_list_ptr^.dimensions);
          array_bounds_ptr := array_bounds_list_ptr^.first;
          while (array_bounds_ptr <> nil) do
            begin
              Disassemble_array_bounds(outfile, array_bounds_ptr);
              array_bounds_ptr := array_bounds_ptr^.next;
            end;

          Disassemble_mnemonic(outfile, 'nil');
        end;
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_array_bounds_list}


{****************************************}
{ functions returning assembler progress }
{****************************************}


function Array_bounds_assembled: asm_index_type;
begin
  Array_bounds_assembled := array_bounds_asm_count;
end; {function Array_bounds_assembled}


function Array_bounds_lists_assembled: asm_index_type;
begin
  Array_bounds_lists_assembled := array_bounds_list_asm_count;
end; {function Array_bounds_lists_assembled}


function Array_bounds_disassembled: asm_index_type;
begin
  Array_bounds_disassembled := array_bounds_disasm_count;
end; {function Array_bounds_disassembled}


function Array_bounds_lists_disassembled: asm_index_type;
begin
  Array_bounds_lists_disassembled := array_bounds_list_disasm_count;
end; {function Array_bounds_lists_disassembled}


initialization
  {***********************************}
  { initialize array bounds variables }
  {***********************************}
  array_bounds_asm_count := 0;
  array_bounds_disasm_count := 0;
  array_bounds_block_ptr := nil;
  array_bounds_block_count := 0;

  {****************************************}
  { initialize array bounds list variables }
  {****************************************}
  array_bounds_list_asm_count := 0;
  array_bounds_list_disasm_count := 0;
  array_bounds_list_block_ptr := nil;
  array_bounds_list_block_count := 0;
end.
