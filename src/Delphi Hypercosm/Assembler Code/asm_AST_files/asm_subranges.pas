unit asm_subranges;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            asm_subranges              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The asm_bounds module defines all of the array          }
{       subranges used in the mnemonic assembly code, the       }
{       external representation of the code which is used       }
{       by the interpreter.                                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  arrays, asms;


{*****************************************************}
{ routines for making and referencing array subranges }
{*****************************************************}
procedure Make_new_asm_array_subranges(count: asm_index_type);
function New_asm_array_subrange: array_subrange_ptr_type;
function Ref_asm_array_subrange(index: asm_index_type): array_subrange_ref_type;

{**********************************************************}
{ routines to assemble array subranges from assembly codes }
{**********************************************************}
function Assemble_array_subrange: array_subrange_ptr_type;

{*************************************************************}
{ routines to disassemble array subranges into assembly codes }
{*************************************************************}
procedure Disassemble_array_subrange(var outfile: text;
  array_subrange_ptr: array_subrange_ptr_type);

{****************************************}
{ functions returning assembler progress }
{****************************************}
function Array_subranges_assembled: asm_index_type;
function Array_subranges_disassembled: asm_index_type;


implementation
uses
  new_memory, expr_attributes, exprs, asm_bounds, asm_exprs;


const
  memory_alert = false;


var
  {**************************}
  { array subrange variables }
  {**************************}
  array_subrange_asm_count, array_subrange_disasm_count: asm_index_type;
  array_subrange_block_ptr: array_subrange_ptr_type;
  array_subrange_block_count: asm_index_type;


{*****************************************************}
{ routines for making and referencing array subranges }
{*****************************************************}


procedure Make_new_asm_array_subranges(count: asm_index_type);
var
  array_subrange_block_size: longint;
begin
  if count > 0 then
    begin
      {***********************************}
      { compute array subrange block size }
      {***********************************}
      array_subrange_block_size := longint(count + 1) *
        sizeof(array_subrange_type);

      {*******************************}
      { allocate array subrange block }
      {*******************************}
      if memory_alert then
        writeln('allocating new array subrange block');
      array_subrange_block_ptr :=
        array_subrange_ptr_type(New_ptr(array_subrange_block_size));
      array_subrange_block_count := count;
    end;
end; {procedure Make_new_asm_array_subranges}


function New_asm_array_subrange: array_subrange_ptr_type;
var
  array_subrange_ptr: array_subrange_ptr_type;
begin
  array_subrange_asm_count := array_subrange_asm_count + 1;
  array_subrange_ptr := Ref_asm_array_subrange(array_subrange_asm_count);
  Init_array_subrange(array_subrange_ptr);
  New_asm_array_subrange := array_subrange_ptr;
end; {function New_asm_array_subrange}


function Ref_asm_array_subrange(index: asm_index_type): array_subrange_ref_type;
begin
  if index > array_subrange_block_count then
    Asm_error;
  Ref_asm_array_subrange :=
    array_subrange_ref_type(longint(array_subrange_block_ptr) +
    sizeof(array_subrange_type) * (index - 1));
end; {function Ref_asm_array_subrange}


{**********************************************************}
{ routines to assemble array subranges from assembly codes }
{**********************************************************}


function Assemble_array_subrange: array_subrange_ptr_type;
var
  array_subrange_ptr: array_subrange_ptr_type;
  mnemonic: mnemonic_type;
begin
  {**********************************}
  { assemble array subrange mnemonic }
  {**********************************}
  mnemonic := Assemble_mnemonic;

  if mnemonic <> 'nil' then
    begin
      {*************************}
      { assemble array subrange }
      {*************************}
      if mnemonic = 'asr' then
        begin
          array_subrange_ptr := New_asm_array_subrange;
          array_subrange_ptr^.array_derefs := Assemble_integer;
          array_subrange_ptr^.array_expr_ptr :=
            forward_expr_ptr_type(Assemble_expr);
          array_subrange_ptr^.array_base_ref :=
            forward_expr_ref_type(Assemble_expr);
          array_subrange_ptr^.array_bounds_ref := Assemble_array_bounds;
        end

      else
        begin
          Asm_error;
          array_subrange_ptr := nil;
        end;
    end
  else
    array_subrange_ptr := nil;

  Assemble_array_subrange := array_subrange_ptr;
end; {function Assemble_array_subrange}


{*************************************************************}
{ routines to disassemble array subranges into assembly codes }
{*************************************************************}


procedure Disassemble_array_subrange(var outfile: text;
  array_subrange_ptr: array_subrange_ptr_type);
begin
  if array_subrange_ptr <> nil then
    begin
      array_subrange_disasm_count := array_subrange_disasm_count + 1;

      {*************************************}
      { disassemble array subrange mnemonic }
      {*************************************}
      Disassemble_mnemonic(outfile, 'asr');
      Disassemble_integer(outfile, array_subrange_ptr^.array_derefs);
      Disassemble_expr(outfile,
        expr_ptr_type(array_subrange_ptr^.array_expr_ptr));
      Disassemble_expr(outfile,
        expr_ptr_type(array_subrange_ptr^.array_base_ref));
      Disassemble_array_bounds(outfile, array_subrange_ptr^.array_bounds_ref);
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_array_subrange}


{****************************************}
{ functions returning assembler progress }
{****************************************}


function Array_subranges_assembled: asm_index_type;
begin
  Array_subranges_assembled := array_subrange_asm_count;
end; {function Array_subranges_assembled}


function Array_subranges_disassembled: asm_index_type;
begin
  Array_subranges_disassembled := array_subrange_disasm_count;
end; {function Array_subranges_disassembled}


initialization
  {*************************************}
  { initialize array subrange variables }
  {*************************************}
  array_subrange_asm_count := 0;
  array_subrange_disasm_count := 0;
  array_subrange_block_ptr := nil;
  array_subrange_block_count := 0;
end.
