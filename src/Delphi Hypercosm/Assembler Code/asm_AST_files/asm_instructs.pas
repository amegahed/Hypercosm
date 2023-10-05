unit asm_instructs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            asm_instructs              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The asm_instructs module defines all of the built       }
{       in statements used in the mnemonic assembly code,       }
{       the external representation of the code which is        }
{       used by the interpreter.                                }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  instructs, asms;


{**************************************************}
{ routines for making and referencing instructions }
{**************************************************}
procedure Make_new_asm_instructs(count: asm_index_type);
function New_asm_instruct(kind: instruct_kind_type): instruct_ptr_type;
function Ref_asm_instruct(index: asm_index_type): instruct_ptr_type;

{*******************************************************}
{ routines to assemble instructions from assembly codes }
{*******************************************************}
function Assemble_instruct: instruct_ptr_type;
function Assemble_instructs: instruct_ptr_type;

{**********************************************************}
{ routines to disassemble instructions into assembly codes }
{**********************************************************}
procedure Disassemble_instruct(var outfile: text;
  instruct_ptr: instruct_ptr_type);
procedure Disassemble_instructs(var outfile: text;
  instruct_ptr: instruct_ptr_type);

{****************************************}
{ functions returning assembler progress }
{****************************************}
function Instructs_assembled: asm_index_type;
function Instructs_disassembled: asm_index_type;


implementation
uses
  new_memory, hashtables, asm_exprs;


const
  memory_alert = false;
  debug = false;


type
  instruct_mnemonic_array_type = array[instruct_kind_type] of mnemonic_type;


var
  instruct_mnemonic_array: instruct_mnemonic_array_type;
  hashtable_ptr: hashtable_ptr_type;
  instruct_asm_count, instruct_disasm_count: asm_index_type;
  instruct_block_ptr: instruct_ptr_type;
  instruct_block_count: asm_index_type;


procedure Make_instruct_mnemonic(kind: instruct_kind_type;
  mnemonic: mnemonic_type);
var
  value: hashtable_value_type;
begin
  value := ord(kind);
  if Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    begin
      writeln('Error - duplicate instruct mnemonic found for ');
      Write_instruct_kind(kind);
      writeln;
    end
  else
    begin
      Enter_hashtable(hashtable_ptr, mnemonic, value);
      instruct_mnemonic_array[kind] := mnemonic;
    end;
end; {procedure Make_instruct_mnemonic}


procedure Make_instruct_mnemonics;
var
  instruct_kind: instruct_kind_type;
begin
  hashtable_ptr := New_hashtable;

  {***************************************}
  { initialize instruction mnemonic array }
  {***************************************}
  for instruct_kind := boolean_write to read_newline do
    instruct_mnemonic_array[instruct_kind] := '';

  {***************************************************************}
  {                       output instructions                     }
  {***************************************************************}

  {******************}
  { enumerated types }
  {******************}
  Make_instruct_mnemonic(boolean_write, 'blw');
  Make_instruct_mnemonic(char_write, 'chw');

  {****************}
  { integral types }
  {****************}
  Make_instruct_mnemonic(byte_write, 'byw');
  Make_instruct_mnemonic(integer_write, 'inw');
  Make_instruct_mnemonic(short_write, 'shw');
  Make_instruct_mnemonic(long_write, 'lnw');

  {**************}
  { scalar types }
  {**************}
  Make_instruct_mnemonic(scalar_write, 'scw');
  Make_instruct_mnemonic(double_write, 'dbw');
  Make_instruct_mnemonic(complex_write, 'cmw');
  Make_instruct_mnemonic(vector_write, 'vcw');

  {***************}
  { complex types }
  {***************}
  Make_instruct_mnemonic(string_write, 'stw');

  {*************************}
  { new line (no arguments) }
  {*************************}
  Make_instruct_mnemonic(write_newline, 'nlw');

  {***************************************************************}
  {                        input instructions                     }
  {***************************************************************}

  {******************}
  { enumerated types }
  {******************}
  Make_instruct_mnemonic(boolean_read, 'blr');
  Make_instruct_mnemonic(char_read, 'chr');

  {****************}
  { integral types }
  {****************}
  Make_instruct_mnemonic(byte_read, 'byr');
  Make_instruct_mnemonic(integer_read, 'inr');
  Make_instruct_mnemonic(short_read, 'shr');
  Make_instruct_mnemonic(long_read, 'lnr');

  {**************}
  { scalar types }
  {**************}
  Make_instruct_mnemonic(scalar_read, 'scr');
  Make_instruct_mnemonic(double_read, 'dbr');
  Make_instruct_mnemonic(complex_read, 'cmr');
  Make_instruct_mnemonic(vector_read, 'vcr');

  {***************}
  { complex types }
  {***************}
  Make_instruct_mnemonic(string_read, 'str');

  {*************************}
  { new line (no arguments) }
  {*************************}
  Make_instruct_mnemonic(read_newline, 'nlr');
end; {procedure Make_instruct_mnemonics}


{**************************************************}
{ routines for making and referencing instructions }
{**************************************************}


procedure Make_new_asm_instructs(count: asm_index_type);
var
  instruct_block_size: longint;
begin
  if count > 0 then
    begin
      {*****************************}
      { compute instruct block size }
      {*****************************}
      instruct_block_size := longint(count + 1) * sizeof(instruct_type);

      {*************************}
      { allocate instruct block }
      {*************************}
      if memory_alert then
        writeln('allocating new instruct block');
      instruct_block_ptr := instruct_ptr_type(New_ptr(instruct_block_size));
      instruct_block_count := count;
    end;
end; {procedure Make_new_asm_instructs}


function New_asm_instruct(kind: instruct_kind_type): instruct_ptr_type;
var
  instruct_ptr: instruct_ptr_type;
begin
  instruct_asm_count := instruct_asm_count + 1;
  instruct_ptr := Ref_asm_instruct(instruct_asm_count);
  Init_instruct(instruct_ptr, kind);
  New_asm_instruct := instruct_ptr;
end; {function New_asm_instruct}


function Ref_asm_instruct(index: asm_index_type): instruct_ptr_type;
begin
  if index > instruct_block_count then
    Asm_error;
  Ref_asm_instruct := instruct_ptr_type(longint(instruct_block_ptr) +
    sizeof(instruct_type) * (index - 1));
end; {function Ref_asm_instruct}


{************************************************************}
{ routines to covert between assembly codes and instructions }
{************************************************************}


function Instruct_kind_to_mnemonic(kind: instruct_kind_type): mnemonic_type;
begin
  Instruct_kind_to_mnemonic := instruct_mnemonic_array[kind];
end; {function Instruct_kind_to_mnemonic}


function Mnemonic_to_instruct_kind(mnemonic: mnemonic_type): instruct_kind_type;
var
  value: hashtable_value_type;
begin
  if not Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    Asm_error;
  Mnemonic_to_instruct_kind := instruct_kind_type(value);
end; {function Mnemonic_to_instruct_kind}


{*******************************************************}
{ routines to assemble instructions from assembly codes }
{*******************************************************}


function Assemble_instruct: instruct_ptr_type;
var
  instruct_ptr: instruct_ptr_type;
  mnemonic: mnemonic_type;
begin
  mnemonic := Assemble_mnemonic;
  if mnemonic <> 'nil' then
    begin
      {*******************************}
      { assemble instruction mnemonic }
      {*******************************}
      if debug then
        writeln('Read instruct: ', mnemonic, '.');
      instruct_ptr := New_instruct(Mnemonic_to_instruct_kind(mnemonic));

      {*******************************}
      { assemble instruction operands }
      {*******************************}
      instruct_ptr^.argument_ptr := Assemble_expr;
    end
  else
    instruct_ptr := nil;

  Assemble_instruct := instruct_ptr;
end; {function Assemble_instruct}


function Assemble_instructs: instruct_ptr_type;
var
  instruct_ptr, last_instruct_ptr: instruct_ptr_type;
begin
  instruct_ptr := Assemble_instruct;
  last_instruct_ptr := instruct_ptr;

  while (last_instruct_ptr <> nil) do
    begin
      last_instruct_ptr^.next := Assemble_instruct;
      last_instruct_ptr := last_instruct_ptr^.next;
    end;

  Assemble_instructs := instruct_ptr;
end; {function Assemble_instructs}


{**********************************************************}
{ routines to disassemble instructions into assembly codes }
{**********************************************************}


procedure Disassemble_instruct(var outfile: text;
  instruct_ptr: instruct_ptr_type);
begin
  if instruct_ptr <> nil then
    begin
      {**********************************}
      { disassemble instruction mnemonic }
      {**********************************}
      Disassemble_mnemonic(outfile,
        Instruct_kind_to_mnemonic(instruct_ptr^.kind));
      instruct_disasm_count := instruct_disasm_count + 1;

      {**********************************}
      { disassemble instruction operands }
      {**********************************}
      Disassemble_expr(outfile, instruct_ptr^.argument_ptr);
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_instruct}


procedure Disassemble_instructs(var outfile: text;
  instruct_ptr: instruct_ptr_type);
begin
  while (instruct_ptr <> nil) do
    begin
      Disassemble_instruct(outfile, instruct_ptr);
      instruct_ptr := instruct_ptr^.next;
    end;
  Disassemble_instruct(outfile, nil);
end; {procedure Disassemble_instructs}


{****************************************}
{ functions returning assembler progress }
{****************************************}


function Instructs_assembled: asm_index_type;
begin
  Instructs_assembled := instruct_asm_count;
end; {function Instructs_assembled}


function Instructs_disassembled: asm_index_type;
begin
  Instructs_disassembled := instruct_disasm_count;
end; {function Instructs_disassembled}


initialization
  Make_instruct_mnemonics;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  instruct_asm_count := 0;
  instruct_disasm_count := 0;
  instruct_block_ptr := nil;
  instruct_block_count := 0;
end.
