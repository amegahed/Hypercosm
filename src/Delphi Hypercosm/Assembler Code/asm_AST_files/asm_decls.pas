unit asm_decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             asm_decls                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The asm_decls module defines all of the declarations    }
{       used in the mnemonic assembly code, the external        }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decls, type_decls, asms;


{**************************************************}
{ routines for making and referencing declarations }
{**************************************************}
procedure Make_new_asm_decls(count: asm_index_type);
function New_asm_decl(kind: decl_kind_type): decl_ptr_type;
function Ref_asm_decl(index: asm_index_type): decl_ref_type;

{*******************************************************}
{ routines to assemble declarations from assembly codes }
{*******************************************************}
function Assemble_decl: decl_ptr_type;
function Assemble_decls: decl_ptr_type;

{**********************************************************}
{ routines to disassemble declarations into assembly codes }
{**********************************************************}
procedure Disassemble_decl(var outfile: text;
  decl_ptr: decl_ptr_type);
procedure Disassemble_decls(var outfile: text;
  decl_ptr: decl_ptr_type);
procedure Disassemble_decl_list(var outfile: text;
  decl_ptr: decl_ptr_type);

{****************************************}
{ functions returning assembler progress }
{****************************************}
function Decls_assembled: asm_index_type;
function Decls_disassembled: asm_index_type;


implementation
uses
  new_memory, hashtables, stmts, code_decls, asm_bounds, asm_indices, asm_exprs,
  asm_instructs, asm_stmts, asm_code_decls, asm_type_decls;


const
  debug = false;
  memory_alert = false;
  verbose = false;


type
  decl_mnemonic_array_type = array[decl_kind_type] of mnemonic_type;


var
  decl_mnemonic_array: decl_mnemonic_array_type;
  hashtable_ptr: hashtable_ptr_type;
  decl_asm_count, decl_disasm_count: asm_index_type;
  decl_block_ptr: decl_ptr_type;
  decl_block_count: asm_index_type;


procedure Make_decl_mnemonic(kind: decl_kind_type;
  mnemonic: mnemonic_type);
var
  value: hashtable_value_type;
begin
  value := ord(kind);
  if Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    begin
      writeln('Error - duplicate decl mnemonic found for ');
      Write_decl_kind(kind);
      writeln;
    end
  else
    begin
      Enter_hashtable(hashtable_ptr, mnemonic, value);
      decl_mnemonic_array[kind] := mnemonic;
    end;
end; {procedure Make_decl_mnemonic}


procedure Make_decl_mnemonics;
var
  decl_kind: decl_kind_type;
begin
  hashtable_ptr := New_hashtable;

  {***************************************}
  { initialize declaration mnemonic array }
  {***************************************}
  for decl_kind := null_decl to code_decl do
    decl_mnemonic_array[decl_kind] := '';

  {*************************}
  { null or nop declaration }
  {*************************}
  Make_decl_mnemonic(null_decl, 'nld');

  {***********************************}
  { primitive enumerated declarations }
  {***********************************}
  Make_decl_mnemonic(boolean_decl, 'bld');
  Make_decl_mnemonic(char_decl, 'chd');

  {*********************************}
  { primitive integral declarations }
  {*********************************}
  Make_decl_mnemonic(byte_decl, 'byd');
  Make_decl_mnemonic(short_decl, 'shd');
  Make_decl_mnemonic(integer_decl, 'ind');
  Make_decl_mnemonic(long_decl, 'lnd');

  {*******************************}
  { primitive scalar declarations }
  {*******************************}
  Make_decl_mnemonic(scalar_decl, 'scd');
  Make_decl_mnemonic(double_decl, 'dbd');
  Make_decl_mnemonic(complex_decl, 'cmd');
  Make_decl_mnemonic(vector_decl, 'vcd');

  {*******************************************}
  { array, struct, and reference declarations }
  {*******************************************}
  Make_decl_mnemonic(array_decl, 'ard');
  Make_decl_mnemonic(struct_decl, 'std');
  Make_decl_mnemonic(static_struct_decl, 'ssd');
  Make_decl_mnemonic(reference_decl, 'rfd');

  {***********************************************}
  { user defined type and subprogram declarations }
  {***********************************************}
  Make_decl_mnemonic(type_decl, 'tyd');
  Make_decl_mnemonic(code_decl, 'cdd');
  Make_decl_mnemonic(code_array_decl, 'cad');
  Make_decl_mnemonic(code_reference_decl, 'crd');
end; {procedure Make_decl_mnemonics}


{**************************************************}
{ routines for making and referencing declarations }
{**************************************************}


procedure Make_new_asm_decls(count: asm_index_type);
var
  decl_block_size: longint;
begin
  if count > 0 then
    begin
      {*************************}
      { compute decl block size }
      {*************************}
      decl_block_size := longint(count + 1) * sizeof(decl_type);

      {*********************}
      { allocate decl block }
      {*********************}
      if memory_alert then
        writeln('allocating new decl block');
      decl_block_ptr := decl_ptr_type(New_ptr(decl_block_size));
      decl_block_count := count;
    end;
end; {procedure Make_new_asm_decls}


function New_asm_decl(kind: decl_kind_type): decl_ptr_type;
var
  decl_ptr: decl_ptr_type;
begin
  decl_asm_count := decl_asm_count + 1;
  decl_ptr := Ref_asm_decl(decl_asm_count);
  Init_decl(decl_ptr, kind);
  decl_ptr^.decl_index := decl_asm_count;
  New_asm_decl := decl_ptr;
end; {function New_asm_decl}


function Ref_asm_decl(index: asm_index_type): decl_ref_type;
begin
  if index > decl_block_count then
    Asm_error;
  Ref_asm_decl := decl_ref_type(longint(decl_block_ptr) + sizeof(decl_type) *
    (index - 1));
end; {function Ref_asm_decl}


{************************************************************}
{ routines to covert between assembly codes and declarations }
{************************************************************}


function Decl_kind_to_mnemonic(kind: decl_kind_type): mnemonic_type;
begin
  Decl_kind_to_mnemonic := decl_mnemonic_array[kind];
end; {function Decl_kind_to_mnemonic}


function Mnemonic_to_decl_kind(mnemonic: mnemonic_type): decl_kind_type;
var
  value: hashtable_value_type;
begin
  if not Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    Asm_error;
  Mnemonic_to_decl_kind := decl_kind_type(value);
end; {function Mnemonic_to_decl_kind}


{*******************************************************}
{ routines to assemble declarations from assembly codes }
{*******************************************************}


procedure Assemble_data_decl_properties(var data_decl: data_decl_type);
begin
  with data_decl do
    begin
      static := Assemble_boolean;
      native := Assemble_boolean;
      if native then
        native_index := Assemble_integer;
    end;
end; {procedure Assemble_data_decl_properties}


procedure Assemble_decl_fields(decl_ptr: decl_ptr_type);
begin
  with decl_ptr^ do
    case decl_ptr^.kind of

      {*************************}
      { null or nop declaration }
      {*************************}
      null_decl:
        ;

      {********************************}
      { user defined type declarations }
      {********************************}
      type_decl:
        begin
          type_ptr := forward_type_ptr_type(Assemble_type);
          type_ptr_type(type_ptr)^.type_decl_ref := decl_ptr;
        end;

      {***********************}
      { variable declarations }
      {***********************}
      boolean_decl..reference_decl:
        begin
          Assemble_data_decl_properties(data_decl);
          with data_decl do
            begin
              data_expr_ptr := Assemble_expr;
              if kind in [array_decl, struct_decl] then
                init_expr_ptr := Assemble_expr;
              init_stmt_ptr := Assemble_stmt;
            end;
          if kind = static_struct_decl then
            static_struct_type_ref := forward_type_ptr_type(Assemble_type);
        end;

      {*************************}
      { subprogram declarations }
      {*************************}
      code_decl..code_reference_decl:
        begin
          Assemble_data_decl_properties(code_data_decl);
          with code_data_decl do
            begin
              data_expr_ptr := Assemble_expr;
              if kind = code_array_decl then
                init_expr_ptr := Assemble_expr;
              init_stmt_ptr := Assemble_stmt;
            end;
          code_ptr := forward_code_ptr_type(Assemble_code);
          code_ptr_type(code_ptr)^.code_decl_ref := decl_ptr;
        end;

    end; {case}
end; {procedure Assemble_decl_fields}


function Assemble_decl: decl_ptr_type;
var
  decl_ptr: decl_ptr_type;
  mnemonic: mnemonic_type;
begin
  {*******************************}
  { assemble declaration mnemonic }
  {*******************************}
  mnemonic := Assemble_mnemonic;

  if mnemonic <> 'nil' then
    begin
      {********************************}
      { assemble declaration reference }
      {********************************}
      if mnemonic = 'drf' then
        decl_ptr := Ref_asm_decl(Assemble_index)

        {**********************}
        { assemble declaration }
        {**********************}
      else
        begin
          decl_ptr := New_asm_decl(Mnemonic_to_decl_kind(mnemonic));
          Assemble_decl_fields(decl_ptr);
        end;
    end
  else
    decl_ptr := nil;

  Assemble_decl := decl_ptr;
end; {function Assemble_decl}


function Assemble_decls: decl_ptr_type;
var
  decl_ptr, last_decl_ptr: decl_ptr_type;
begin
  decl_ptr := Assemble_decl;
  last_decl_ptr := decl_ptr;

  while (last_decl_ptr <> nil) do
    begin
      last_decl_ptr^.next := Assemble_decl;
      last_decl_ptr := last_decl_ptr^.next;
    end;

  Assemble_decls := decl_ptr;
end; {function Assemble_decls}


{**********************************************************}
{ routines to disassemble declarations into assembly codes }
{**********************************************************}


procedure Disassemble_data_decl_properties(var outfile: text;
  data_decl: data_decl_type);
begin
  with data_decl do
    begin
      Disassemble_boolean(outfile, static);
      Disassemble_boolean(outfile, native);
      if native then
        Disassemble_integer(outfile, native_index);
    end;
end; {procedure Disassemble_data_decl_properties}


procedure Disassemble_decl_fields(var outfile: text;
  decl_ptr: decl_ptr_type);
begin
  with decl_ptr^ do
    case decl_ptr^.kind of

      {*************************}
      { null or nop declaration }
      {*************************}
      null_decl:
        ;

      {********************************}
      { user defined type declarations }
      {********************************}
      type_decl:
        Disassemble_type(outfile, type_ptr_type(type_ptr));

      {***********************}
      { variable declarations }
      {***********************}
      boolean_decl..reference_decl:
        begin
          Disassemble_data_decl_properties(outfile, data_decl);
          with data_decl do
            begin
              Disassemble_expr(outfile, data_expr_ptr);
              if kind in [array_decl, struct_decl] then
                Disassemble_expr(outfile, init_expr_ptr);
              Disassemble_stmt(outfile, init_stmt_ptr);
            end;
          if kind = static_struct_decl then
            begin
              if static_struct_type_ref <> nil then
                Disassemble_type(outfile, type_ptr_type(static_struct_type_ref))
              else
                Disasm_error;
            end;
        end;

      {*************************}
      { subprogram declarations }
      {*************************}
      code_decl..code_reference_decl:
        begin
          Disassemble_data_decl_properties(outfile, code_data_decl);
          with code_data_decl do
            begin
              Disassemble_expr(outfile, data_expr_ptr);
              if kind = code_array_decl then
                Disassemble_expr(outfile, init_expr_ptr);
              Disassemble_stmt(outfile, init_stmt_ptr);
            end;
          Disassemble_code(outfile, code_ptr_type(code_ptr));
        end;

    end; {case}
end; {procedure Disassemble_decl_fields}


procedure Disassemble_decl(var outfile: text;
  decl_ptr: decl_ptr_type);
begin
  if decl_ptr <> nil then
    begin
      if debug then
        with decl_ptr^ do
          if decl_info_ptr <> nil then
            with decl_info_ptr^ do
              if decl_attributes_ptr <> nil then
                if not decl_attributes_ptr^.used then
                  Disasm_error;

      {***********************************}
      { disassemble declaration reference }
      {***********************************}
      if decl_ptr^.decl_index <> 0 then
        begin
          Disassemble_mnemonic(outfile, 'drf');
          Disassemble_index(outfile, decl_ptr^.decl_index);
        end

          {*************************}
          { disassemble declaration }
          {*************************}
      else
        begin
          decl_disasm_count := decl_disasm_count + 1;
          decl_ptr^.decl_index := decl_disasm_count;

          {**********************************}
          { disassemble declaration mnemonic }
          {**********************************}
          Disassemble_mnemonic(outfile, Decl_kind_to_mnemonic(decl_ptr^.kind));
          Disassemble_decl_fields(outfile, decl_ptr);
        end;
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_decl}


procedure Disassemble_decls(var outfile: text;
  decl_ptr: decl_ptr_type);
begin
  while (decl_ptr <> nil) do
    begin
      Disassemble_decl(outfile, decl_ptr);
      decl_ptr := decl_ptr^.next;
    end;
  Disassemble_decl(outfile, nil);
end; {procedure Disassemble_decls}


procedure Disassemble_decl_list(var outfile: text;
  decl_ptr: decl_ptr_type);
begin
  while (decl_ptr <> nil) do
    begin
      Disassemble_decl(outfile, decl_ptr);
      decl_ptr := decl_ptr^.next;
    end;
end; {procedure Disassemble_decl_list}


{****************************************}
{ functions returning assembler progress }
{****************************************}


function Decls_assembled: asm_index_type;
begin
  Decls_assembled := decl_asm_count;
end; {function Decls_assembled}


function Decls_disassembled: asm_index_type;
begin
  Decls_disassembled := decl_disasm_count;
end; {function Decls_disassembled}


initialization
  Make_decl_mnemonics;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  decl_asm_count := 0;
  decl_disasm_count := 0;
  decl_block_ptr := nil;
  decl_block_count := 0;
end.
