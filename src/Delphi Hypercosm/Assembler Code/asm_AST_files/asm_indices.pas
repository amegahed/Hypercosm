unit asm_indices;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            asm_indices                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The asm_indices module defines all of the array         }
{       indices used in the mnemonic assembly code, the         }
{       external representation of the code which is used       }
{       by the interpreter.                                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  arrays, asms;


{***************************************************}
{ routines for making and referencing array indices }
{***************************************************}
procedure Make_new_asm_array_indices(count: asm_index_type);
procedure Make_new_asm_array_index_lists(count: asm_index_type);
function New_asm_array_index: array_index_ptr_type;
function New_asm_array_index_list(max_indices: integer):
  array_index_list_ptr_type;
function Ref_asm_array_index(index: asm_index_type): array_index_ref_type;
function Ref_asm_array_index_list(index: asm_index_type):
  array_index_list_ref_type;

{******************************************************}
{ routines to assemble array index from assembly codes }
{******************************************************}
function Assemble_array_index: array_index_ptr_type;
function Assemble_array_index_list: array_index_list_ptr_type;

{*********************************************************}
{ routines to disassemble array index into assembly codes }
{*********************************************************}
procedure Disassemble_array_index(var outfile: text;
  array_index_ptr: array_index_ptr_type);
procedure Disassemble_array_index_list(var outfile: text;
  array_index_list_ptr: array_index_list_ptr_type);

{****************************************}
{ functions returning assembler progress }
{****************************************}
function Array_indices_assembled: asm_index_type;
function Array_index_lists_assembled: asm_index_type;
function Array_indices_disassembled: asm_index_type;
function Array_index_lists_disassembled: asm_index_type;


implementation
uses
  new_memory, errors, exprs, asm_exprs;


const
  memory_alert = false;


var
  {***********************}
  { array index variables }
  {***********************}
  array_index_asm_count, array_index_disasm_count: asm_index_type;
  array_index_block_ptr: array_index_ptr_type;
  array_index_block_count: asm_index_type;

  {****************************}
  { array index list variables }
  {****************************}
  array_index_list_asm_count, array_index_list_disasm_count: asm_index_type;
  array_index_list_block_ptr: array_index_list_ptr_type;
  array_index_list_block_count: asm_index_type;


{***************************************************}
{ routines for making and referencing array indices }
{***************************************************}


procedure Make_new_asm_array_indices(count: asm_index_type);
var
  array_index_block_size: longint;
begin
  if count > 0 then
    begin
      {********************************}
      { compute array index block size }
      {********************************}
      array_index_block_size := longint(count + 1) * sizeof(array_index_type);

      {****************************}
      { allocate array index block }
      {****************************}
      if memory_alert then
        writeln('allocating new array index block');
      array_index_block_ptr :=
        array_index_ptr_type(New_ptr(array_index_block_size));
      array_index_block_count := count;
    end;
end; {procedure Make_new_asm_array_indices}


function New_asm_array_index: array_index_ptr_type;
var
  array_index_ptr: array_index_ptr_type;
begin
  array_index_asm_count := array_index_asm_count + 1;
  array_index_ptr := Ref_asm_array_index(array_index_asm_count);
  Init_array_index(array_index_ptr);
  New_asm_array_index := array_index_ptr;
end; {function New_asm_array_index}


function Ref_asm_array_index(index: asm_index_type): array_index_ref_type;
begin
  if index > array_index_block_count then
    Asm_error;
  Ref_asm_array_index := array_index_ref_type(longint(array_index_block_ptr) +
    sizeof(array_index_type) * (index - 1));
end; {function Ref_asm_array_index}


{*******************************************************}
{ routines for making and referencing array index lists }
{*******************************************************}


procedure Make_new_asm_array_index_lists(count: asm_index_type);
var
  array_index_list_block_size: longint;
begin
  if count > 0 then
    begin
      {*************************************}
      { compute array index list block size }
      {*************************************}
      array_index_list_block_size := longint(count + 1) *
        sizeof(array_index_list_type);

      {*********************************}
      { allocate array index list block }
      {*********************************}
      if memory_alert then
        writeln('allocating new array index list block');
      array_index_list_block_ptr :=
        array_index_list_ptr_type(New_ptr(array_index_list_block_size));
      array_index_list_block_count := count;
    end;
end; {procedure Make_new_asm_array_index_lists}


function New_asm_array_index_list(max_indices: integer):
  array_index_list_ptr_type;
var
  array_index_list_ptr: array_index_list_ptr_type;
begin
  array_index_list_asm_count := array_index_list_asm_count + 1;
  array_index_list_ptr := Ref_asm_array_index_list(array_index_list_asm_count);
  Init_array_index_list(array_index_list_ptr, max_indices);
  New_asm_array_index_list := array_index_list_ptr;
end; {function New_asm_array_index_list}


function Ref_asm_array_index_list(index: asm_index_type):
  array_index_list_ref_type;
begin
  if index > array_index_list_block_count then
    Asm_error;
  Ref_asm_array_index_list :=
    array_index_list_ref_type(longint(array_index_list_block_ptr) +
    sizeof(array_index_list_type) * (index - 1));
end; {function Ref_asm_array_index_list}


{********************************************************}
{ routines to assemble array indices from assembly codes }
{********************************************************}


function Assemble_array_index: array_index_ptr_type;
var
  array_index_ptr: array_index_ptr_type;
  mnemonic: mnemonic_type;
begin
  {*******************************}
  { assemble array index mnemonic }
  {*******************************}
  mnemonic := Assemble_mnemonic;

  if mnemonic <> 'nil' then
    begin
      {********************************}
      { assemble array index reference }
      {********************************}
      if mnemonic = 'irf' then
        array_index_ptr := Ref_asm_array_index(Assemble_index)

        {**********************}
        { assemble array index }
        {**********************}
      else if mnemonic = 'idx' then
        begin
          array_index_ptr := New_asm_array_index;

          {*******************************}
          { assemble array index operands }
          {*******************************}
          with array_index_ptr^ do
            index_expr_ptr := forward_expr_ptr_type(Assemble_expr);
        end

      else
        begin
          Asm_error;
          array_index_ptr := nil;
        end;
    end
  else
    array_index_ptr := nil;

  Assemble_array_index := array_index_ptr;
end; {function Assemble_array_index}


function Assemble_array_index_list: array_index_list_ptr_type;
var
  array_index_list_ptr: array_index_list_ptr_type;
  array_index_ptr: array_index_ptr_type;
  max_indices: integer;
  mnemonic: mnemonic_type;
begin
  {************************************}
  { assemble array index list mnemonic }
  {************************************}
  mnemonic := Assemble_mnemonic;

  if mnemonic <> 'nil' then
    begin
      {*************************************}
      { assemble array index list reference }
      {*************************************}
      if mnemonic = 'ilr' then
        array_index_list_ptr := Ref_asm_array_index_list(Assemble_index)

        {***************************}
        { assemble array index list }
        {***************************}
      else if mnemonic = 'ail' then
        begin
          max_indices := Assemble_integer;
          array_index_list_ptr := New_asm_array_index_list(max_indices);

          {************************************}
          { assemble array index list operands }
          {************************************}
          array_index_ptr := Assemble_array_index;
          while (array_index_ptr <> nil) do
            begin
              Add_array_index(array_index_list_ptr, array_index_ptr);
              array_index_ptr := Assemble_array_index;
            end;
        end

      else
        begin
          Asm_error;
          array_index_list_ptr := nil;
        end;
    end
  else
    array_index_list_ptr := nil;

  Assemble_array_index_list := array_index_list_ptr;
end; {function Assemble_array_index_list}


{***********************************************************}
{ routines to disassemble array indices into assembly codes }
{***********************************************************}


procedure Disassemble_array_index(var outfile: text;
  array_index_ptr: array_index_ptr_type);
begin
  if array_index_ptr <> nil then
    begin
      {***********************************}
      { disassemble array index reference }
      {***********************************}
      if array_index_ptr^.array_index_index <> 0 then
        begin
          Disassemble_mnemonic(outfile, 'irf');
          Disassemble_index(outfile, array_index_ptr^.array_index_index);
        end

          {*************************}
          { disassemble array index }
          {*************************}
      else
        begin
          array_index_disasm_count := array_index_disasm_count + 1;
          array_index_ptr^.array_index_index := array_index_disasm_count;

          {**********************************}
          { disassemble array index mnemonic }
          {**********************************}
          Disassemble_mnemonic(outfile, 'idx');

          {**********************************}
          { disassemble array index operands }
          {**********************************}
          with array_index_ptr^ do
            Disassemble_expr(outfile, expr_ptr_type(index_expr_ptr));
        end;
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_array_index}


procedure Disassemble_array_index_list(var outfile: text;
  array_index_list_ptr: array_index_list_ptr_type);
var
  array_index_ptr: array_index_ptr_type;
begin
  if array_index_list_ptr <> nil then
    begin
      {****************************************}
      { disassemble array index list reference }
      {****************************************}
      if array_index_list_ptr^.array_index_list_index <> 0 then
        begin
          Disassemble_mnemonic(outfile, 'ilr');
          Disassemble_index(outfile,
            array_index_list_ptr^.array_index_list_index);
        end

          {******************************}
          { disassemble array index list }
          {******************************}
      else
        begin
          array_index_list_disasm_count := array_index_list_disasm_count + 1;
          array_index_list_ptr^.array_index_list_index :=
            array_index_list_disasm_count;

          {***************************************}
          { disassemble array index list mnemonic }
          {***************************************}
          Disassemble_mnemonic(outfile, 'ail');

          {***************************************}
          { disassemble array index list operands }
          {***************************************}
          Disassemble_integer(outfile, array_index_list_ptr^.max_indices);
          array_index_ptr := array_index_list_ptr^.first;
          while (array_index_ptr <> nil) do
            begin
              Disassemble_array_index(outfile, array_index_ptr);
              array_index_ptr := array_index_ptr^.next;
            end;

          Disassemble_array_index(outfile, nil);
        end;
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_array_index_list}


{****************************************}
{ functions returning assembler progress }
{****************************************}


function Array_indices_assembled: asm_index_type;
begin
  Array_indices_assembled := array_index_asm_count;
end; {function Array_indices_assembled}


function Array_index_lists_assembled: asm_index_type;
begin
  Array_index_lists_assembled := array_index_list_asm_count;
end; {function Array_index_lists_assembled}


function Array_indices_disassembled: asm_index_type;
begin
  Array_indices_disassembled := array_index_disasm_count;
end; {function Array_indices_disassembled}


function Array_index_lists_disassembled: asm_index_type;
begin
  Array_index_lists_disassembled := array_index_list_disasm_count;
end; {function Array_index_lists_disassembled}


initialization
  {**********************************}
  { initialize array index variables }
  {**********************************}
  array_index_asm_count := 0;
  array_index_disasm_count := 0;
  array_index_block_ptr := nil;
  array_index_block_count := 0;

  {***************************************}
  { initialize array index list variables }
  {***************************************}
  array_index_list_asm_count := 0;
  array_index_list_disasm_count := 0;
  array_index_list_block_ptr := nil;
  array_index_list_block_count := 0;
end.
