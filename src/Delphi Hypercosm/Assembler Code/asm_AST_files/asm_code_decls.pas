unit asm_code_decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           asm_code_decls              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The asm_codes module defines the code declarations      }
{       used in the mnemonic assembly code, the external        }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  code_types, decls, code_decls, type_decls, asms;


{*******************************************************}
{ routines for making and referencing code declarations }
{*******************************************************}
procedure Make_new_asm_codes(count: asm_index_type);
function New_asm_code(kind: code_kind_type): code_ptr_type;
function Ref_asm_code(index: asm_index_type): code_ref_type;

{*******************************************************}
{ routines to assemble declarations from assembly codes }
{*******************************************************}
function Assemble_code: code_ptr_type;

{**********************************************************}
{ routines to disassemble declarations into assembly codes }
{**********************************************************}
procedure Disassemble_code(var outfile: text;
  code_ptr: code_ptr_type);

{****************************************}
{ functions returning assembler progress }
{****************************************}
function Codes_assembled: asm_index_type;
function Codes_disassembled: asm_index_type;


implementation
uses
  new_memory, hashtables, data_types, code_attributes, exprs, asm_exprs,
  asm_stmts, asm_decls, asm_type_decls;


const
  memory_alert = false;


type
  code_mnemonic_array_type = array[code_kind_type] of mnemonic_type;


var
  code_mnemonic_array: code_mnemonic_array_type;
  hashtable_ptr: hashtable_ptr_type;
  code_asm_count, code_disasm_count: asm_index_type;
  code_block_ptr: code_ptr_type;
  code_block_count: asm_index_type;


procedure Make_code_mnemonic(kind: code_kind_type;
  mnemonic: mnemonic_type);
var
  value: hashtable_value_type;
begin
  value := ord(kind);
  if Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    begin
      writeln('Error - duplicate decl mnemonic found for ');
      Write_code_kind(kind);
      writeln;
    end
  else
    begin
      Enter_hashtable(hashtable_ptr, mnemonic, value);
      code_mnemonic_array[kind] := mnemonic;
    end;
end; {procedure Make_code_mnemonic}


procedure Make_code_mnemonics;
var
  code_kind: code_kind_type;
begin
  hashtable_ptr := New_hashtable;

  {***************************************}
  { initialize declaration mnemonic array }
  {***************************************}
  for code_kind := procedure_code to anim_code do
    code_mnemonic_array[code_kind] := '';

  {************}
  { code kinds }
  {************}
  Make_code_mnemonic(procedure_code, 'pro');
  Make_code_mnemonic(function_code, 'fun');
  Make_code_mnemonic(constructor_code, 'con');
  Make_code_mnemonic(destructor_code, 'des');
  Make_code_mnemonic(shader_code, 'sha');
  Make_code_mnemonic(object_code, 'obj');
  Make_code_mnemonic(picture_code, 'pic');
  Make_code_mnemonic(anim_code, 'anm');
end; {procedure Make_code_mnemonics}


{*******************************************************}
{ routines for making and referencing code declarations }
{*******************************************************}


procedure Make_new_asm_codes(count: asm_index_type);
var
  code_block_size: longint;
begin
  if count > 0 then
    begin
      {*************************}
      { compute code block size }
      {*************************}
      code_block_size := longint(count + 1) * sizeof(code_type);

      {*********************}
      { allocate code block }
      {*********************}
      if memory_alert then
        writeln('allocating new code block');
      code_block_ptr := code_ptr_type(New_ptr(code_block_size));
      code_block_count := count;
    end;
end; {procedure Make_new_asm_codes}


function New_asm_code(kind: code_kind_type): code_ptr_type;
var
  code_ptr: code_ptr_type;
begin
  code_asm_count := code_asm_count + 1;
  code_ptr := Ref_asm_code(code_asm_count);
  Init_code(code_ptr, kind);
  code_ptr^.code_index := code_asm_count;
  New_asm_code := code_ptr;
end; {function New_asm_code}


function Ref_asm_code(index: asm_index_type): code_ref_type;
begin
  if index > code_block_count then
    Asm_error;
  Ref_asm_code := code_ref_type(longint(code_block_ptr) + sizeof(code_type) *
    (index - 1));
end; {function Ref_asm_code}


{**********************************************************}
{ routines to covert between assembly codes and statements }
{**********************************************************}


function Code_kind_to_mnemonic(kind: code_kind_type): mnemonic_type;
begin
  Code_kind_to_mnemonic := code_mnemonic_array[kind];
end; {function Code_kind_to_mnemonic}


function Mnemonic_to_code_kind(mnemonic: mnemonic_type): code_kind_type;
var
  value: hashtable_value_type;
begin
  if not Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    Asm_error;
  Mnemonic_to_code_kind := code_kind_type(value);
end; {function Mnemonic_to_code_kind}


{*******************************************************}
{ routines to assemble declarations from assembly codes }
{*******************************************************}


procedure Assemble_code_fields(code_ptr: code_ptr_type);
begin
  with code_ptr^ do
    begin
      {*****************************}
      { code declaration attributes }
      {*****************************}
      decl_kind := code_decl_kind_type(Assemble_integer);
      method_kind := method_kind_type(Assemble_integer);
      reference_method := Assemble_boolean;

      {*******************************}
      { declaration's computed values }
      {*******************************}
      stack_frame_size := Assemble_integer;
      params_size := Assemble_integer;
      method_id := Assemble_integer;

      {************************}
      { declaration references }
      {************************}
      class_type_ref := forward_type_ref_type(Assemble_type);

      {*******************}
      { initial paramters }
      {*******************}
      implicit_param_decls_ptr := Assemble_decls;
      initial_param_decls_ptr := Assemble_decls;

      {*********************}
      { optional parameters }
      {*********************}
      optional_param_decls_ptr := Assemble_decls;
      optional_param_stmts_ptr := Assemble_stmts;

      {*******************}
      { return parameters }
      {*******************}
      return_param_decls_ptr := Assemble_decls;

      {****************}
      { implementation }
      {****************}
      if decl_kind = actual_decl then
        begin
          local_decls_ptr := Assemble_decls;
          local_stmts_ptr := Assemble_stmts;
        end;

      {***************************************}
      { add virtual methods to dispatch table }
      {***************************************}
      if method_kind in dynamic_method_set then
        if method_id <> 0 then
          Set_virtual_method(type_ptr_type(class_type_ref), code_ptr);
    end; {with}
end; {procedure Assemble_code_fields}


function Assemble_code: code_ptr_type;
var
  code_ptr: code_ptr_type;
  mnemonic: mnemonic_type;
begin
  {************************}
  { assemble code mnemonic }
  {************************}
  mnemonic := Assemble_mnemonic;

  if mnemonic <> 'nil' then
    begin
      {*************************}
      { assemble code reference }
      {*************************}
      if mnemonic = 'crf' then
        code_ptr := Ref_asm_code(Assemble_index)

        {***************}
        { assemble code }
        {***************}
      else
        begin
          code_ptr := New_asm_code(Mnemonic_to_code_kind(mnemonic));
          Assemble_code_fields(code_ptr);
        end;
    end
  else
    code_ptr := nil;

  Assemble_code := code_ptr;
end; {function Assemble_code}


{**********************************************************}
{ routines to disassemble declarations into assembly codes }
{**********************************************************}


procedure Disassemble_code_fields(var outfile: text;
  code_ptr: code_ptr_type);
begin
  with code_ptr^ do
    begin
      {*****************************}
      { code declaration attributes }
      {*****************************}
      Disassemble_integer(outfile, integer_type(decl_kind));
      Disassemble_integer(outfile, integer_type(method_kind));
      Disassemble_boolean(outfile, reference_method);

      {*******************************}
      { declaration's computed values }
      {*******************************}
      Disassemble_integer(outfile, stack_frame_size);
      Disassemble_integer(outfile, params_size);
      Disassemble_integer(outfile, method_id);

      {************************}
      { declaration references }
      {************************}
      Disassemble_type(outfile, type_ptr_type(class_type_ref));

      {*******************}
      { initial paramters }
      {*******************}
      Disassemble_decls(outfile, implicit_param_decls_ptr);
      Disassemble_decls(outfile, initial_param_decls_ptr);

      {*********************}
      { optional parameters }
      {*********************}
      Disassemble_decls(outfile, optional_param_decls_ptr);
      Disassemble_stmts(outfile, optional_param_stmts_ptr);

      {*******************}
      { return parameters }
      {*******************}
      Disassemble_decls(outfile, return_param_decls_ptr);

      {****************}
      { implementation }
      {****************}
      if decl_kind = actual_decl then
        begin
          Disassemble_decls(outfile, local_decls_ptr);
          Disassemble_stmts(outfile, local_stmts_ptr);
        end;
    end; {with}
end; {procedure Disassemble_code_fields}


procedure Disassemble_code(var outfile: text;
  code_ptr: code_ptr_type);
begin
  if code_ptr <> nil then
    begin
      {****************************}
      { disassemble code reference }
      {****************************}
      if code_ptr^.code_index <> 0 then
        begin
          Disassemble_mnemonic(outfile, 'crf');
          Disassemble_index(outfile, code_ptr^.code_index);
        end

          {******************}
          { disassemble code }
          {******************}
      else
        begin
          code_disasm_count := code_disasm_count + 1;
          code_ptr^.code_index := code_disasm_count;

          {***************************}
          { disassemble code mnemonic }
          {***************************}
          Disassemble_mnemonic(outfile, Code_kind_to_mnemonic(code_ptr^.kind));
          Disassemble_code_fields(outfile, code_ptr);
        end;
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_code}


{****************************************}
{ functions returning assembler progress }
{****************************************}


function Codes_assembled: asm_index_type;
begin
  Codes_assembled := code_asm_count;
end; {function Codes_assembled}


function Codes_disassembled: asm_index_type;
begin
  Codes_disassembled := code_disasm_count;
end; {function Codes_disassembled}


initialization
  Make_code_mnemonics;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  code_asm_count := 0;
  code_disasm_count := 0;
  code_block_ptr := nil;
  code_block_count := 0;
end.
