unit asm_type_decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           asm_type_decls              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The asm_types module defines the type declarations      }
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


{*******************************************************}
{ routines for making and referencing type declarations }
{*******************************************************}
procedure Make_new_asm_types(count: asm_index_type);
function New_asm_type(kind: type_decl_kind_type): type_ptr_type;
function Ref_asm_type(index: asm_index_type): type_ref_type;

{*******************************************************}
{ routines to assemble declarations from assembly codes }
{*******************************************************}
function Assemble_type: type_ptr_type;

{**********************************************************}
{ routines to disassemble declarations into assembly codes }
{**********************************************************}
procedure Disassemble_type(var outfile: text;
  type_ptr: type_ptr_type);

{****************************************}
{ functions returning assembler progress }
{****************************************}
function Types_assembled: asm_index_type;
function Types_disassembled: asm_index_type;


implementation
uses
  new_memory, hashtables, data_types, asm_exprs, asm_stmts, asm_code_decls,
  asm_decls;


const
  memory_alert = false;


type
  type_mnemonic_array_type = array[type_decl_kind_type] of mnemonic_type;


var
  type_mnemonic_array: type_mnemonic_array_type;
  hashtable_ptr: hashtable_ptr_type;
  type_asm_count, type_disasm_count: asm_index_type;
  type_block_ptr: type_ptr_type;
  type_block_count: asm_index_type;


procedure Make_type_mnemonic(kind: type_decl_kind_type;
  mnemonic: mnemonic_type);
var
  value: hashtable_value_type;
begin
  value := ord(kind);
  if Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    begin
      writeln('Error - duplicate decl mnemonic found for ');
      Write_type_decl_kind(kind);
      writeln;
    end
  else
    begin
      Enter_hashtable(hashtable_ptr, mnemonic, value);
      type_mnemonic_array[kind] := mnemonic;
    end;
end; {procedure Make_type_mnemonic}


procedure Make_type_mnemonics;
var
  type_decl_kind: type_decl_kind_type;
begin
  hashtable_ptr := New_hashtable;

  {***************************************}
  { initialize declaration mnemonic array }
  {***************************************}
  for type_decl_kind := enum_type to class_type do
    type_mnemonic_array[type_decl_kind] := '';

  {************}
  { code kinds }
  {************}
  Make_type_mnemonic(enum_type, 'enm');
  Make_type_mnemonic(alias_type, 'als');
  Make_type_mnemonic(struct_type, 'str');
  Make_type_mnemonic(class_type, 'cls');
end; {procedure Make_code_mnemonics}


{*******************************************************}
{ routines for making and referencing type declarations }
{*******************************************************}


procedure Make_new_asm_types(count: asm_index_type);
var
  type_block_size: longint;
begin
  if count > 0 then
    begin
      {*************************}
      { compute type block size }
      {*************************}
      type_block_size := longint(count + 1) * sizeof(type_type);

      {*********************}
      { allocate type block }
      {*********************}
      if memory_alert then
        writeln('allocating new type block');
      type_block_ptr := type_ptr_type(New_ptr(type_block_size));
      type_block_count := count;
    end;
end; {procedure Make_new_asm_types}


function New_asm_type(kind: type_decl_kind_type): type_ptr_type;
var
  type_ptr: type_ptr_type;
begin
  type_asm_count := type_asm_count + 1;
  type_ptr := Ref_asm_type(type_asm_count);
  Init_type(type_ptr, kind);
  type_ptr^.type_index := type_asm_count;
  New_asm_type := type_ptr;
end; {function New_asm_type}


function Ref_asm_type(index: asm_index_type): type_ref_type;
begin
  if index > type_block_count then
    Asm_error;
  Ref_asm_type := type_ref_type(longint(type_block_ptr) + sizeof(type_type) *
    (index - 1));
end; {function Ref_asm_type}


{**********************************************************}
{ routines to covert between assembly codes and statements }
{**********************************************************}


function Type_decl_kind_to_mnemonic(kind: type_decl_kind_type): mnemonic_type;
begin
  Type_decl_kind_to_mnemonic := type_mnemonic_array[kind];
end; {function Type_decl_kind_to_mnemonic}


function Mnemonic_to_type_decl_kind(mnemonic: mnemonic_type):
  type_decl_kind_type;
var
  value: hashtable_value_type;
begin
  if not Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    Asm_error;
  Mnemonic_to_type_decl_kind := type_decl_kind_type(value);
end; {function Mnemonic_to_type_decl_kind}


{*******************************************************}
{ routines to assemble declarations from assembly codes }
{*******************************************************}


function Assemble_type_references: type_reference_ptr_type;
var
  type_reference_ptr, first, last: type_reference_ptr_type;
  type_ref: type_ref_type;
begin
  type_ref := Assemble_type;

  if type_ref <> nil then
    begin
      type_reference_ptr := New_type_ref(type_ref);
      type_reference_ptr^.index := Assemble_integer;
    end
  else
    type_reference_ptr := nil;

  first := type_reference_ptr;
  last := type_reference_ptr;
  while (last <> nil) do
    begin
      type_ref := Assemble_type;

      if type_ref <> nil then
        begin
          type_reference_ptr := New_type_ref(type_ref);
          type_reference_ptr^.index := Assemble_integer;

          {*********************}
          { add to tail of list }
          {*********************}
          last^.next := type_reference_ptr;
          last := type_reference_ptr;
        end
      else
        last := nil;
    end;

  Assemble_type_references := first;
end; {function Assemble_type_references}


procedure Assemble_type_fields(type_ptr: type_ptr_type);
begin
  with type_ptr^ do
    if kind in [struct_type, class_type] then
      begin
        {*****************************************}
        { assemble runtime allocation information }
        {*****************************************}
        static := Assemble_boolean;
        size := Assemble_integer;

        case kind of

          struct_type:
            begin
              {************************************}
              { assemble struct field declarations }
              {************************************}
              struct_base_ptr := Assemble_expr;
              field_decls_ptr := Assemble_decls;
            end; {struct_type}

          class_type:
            begin
              {****************************************}
              { assemble class declaration information }
              {****************************************}
              class_kind := class_kind_type(Assemble_integer);

              {*******************************}
              { assemble superclass reference }
              {*******************************}
              parent_class_ref := Assemble_type;

              dispatch_table_ptr := New_dispatch_table;
              if parent_class_ref <> nil then
                dispatch_table_ptr^ := parent_class_ref^.dispatch_table_ptr^;

              {*********************************}
              { assemble interfaces implemented }
              {*********************************}
              interface_class_ptr := Assemble_type_references;

              {****************************}
              { assemble interface methods }
              {****************************}
              method_decls_ptr := Assemble_decls;

              {************************************}
              { assemble class member declarations }
              {************************************}
              class_base_ptr := Assemble_expr;
              member_decls_ptr := Assemble_decls;
              private_member_decls_ptr := Assemble_decls;

              {********************************************}
              { assemble class implementation declarations }
              {********************************************}
              class_decls_ptr := Assemble_decls;
              class_init_ptr := Assemble_stmts;

              {**************************}
              { assemble special methods }
              {**************************}
              constructor_code_ref := Assemble_code;
              destructor_code_ref := Assemble_code;
            end; {class_type}

        end; {case}
      end; {if}
end; {procedure Assemble_type_fields}


function Assemble_type: type_ptr_type;
var
  type_ptr: type_ptr_type;
  mnemonic: mnemonic_type;
begin
  {************************}
  { assemble code mnemonic }
  {************************}
  mnemonic := Assemble_mnemonic;

  if mnemonic <> 'nil' then
    begin
      {*************************}
      { assemble type reference }
      {*************************}
      if mnemonic = 'trf' then
        type_ptr := Ref_asm_type(Assemble_index)

        {***************}
        { assemble type }
        {***************}
      else
        begin
          type_ptr := New_asm_type(Mnemonic_to_type_decl_kind(mnemonic));
          Assemble_type_fields(type_ptr);
        end;
    end
  else
    type_ptr := nil;

  Assemble_type := type_ptr;
end; {function Assemble_type}


{**********************************************************}
{ routines to disassemble declarations into assembly codes }
{**********************************************************}


procedure Disassemble_type_references(var outfile: text;
  type_reference_ptr: type_reference_ptr_type);
begin
  while (type_reference_ptr <> nil) do
    begin
      Disassemble_type(outfile, type_reference_ptr^.type_ref);
      Disassemble_integer(outfile, type_reference_ptr^.index);
      type_reference_ptr := type_reference_ptr^.next;
    end;
  Disassemble_type(outfile, nil);
end; {procedure Disassemble_type_references}


procedure Disassemble_type_fields(var outfile: text;
  type_ptr: type_ptr_type);
begin
  with type_ptr^ do
    if kind in [struct_type, class_type] then
      begin
        {********************************************}
        { disassemble runtime allocation information }
        {********************************************}
        Disassemble_boolean(outfile, static);
        Disassemble_integer(outfile, size);

        if size = 0 then
          Disasm_error;

        case kind of

          struct_type:
            begin
              {***************************************}
              { disassemble struct field declarations }
              {***************************************}
              Disassemble_expr(outfile, struct_base_ptr);
              Disassemble_decls(outfile, field_decls_ptr);
            end; {struct_type}

          class_type:
            begin
              {*******************************************}
              { disassemble class declaration information }
              {*******************************************}
              Disassemble_integer(outfile, integer_type(class_kind));

              {************************}
              { disassemble superclass }
              {************************}
              Disassemble_type(outfile, parent_class_ref);

              {************************************}
              { disassemble interfaces implemented }
              {************************************}
              Disassemble_type_references(outfile, interface_class_ptr);

              {*******************************}
              { disassemble interface methods }
              {*******************************}
              Disassemble_decls(outfile, method_decls_ptr);

              {***************************************}
              { disassemble class member declarations }
              {***************************************}
              Disassemble_expr(outfile, class_base_ptr);
              Disassemble_decls(outfile, member_decls_ptr);
              Disassemble_decls(outfile, private_member_decls_ptr);

              {***********************************************}
              { disassemble class implementation declarations }
              {***********************************************}
              Disassemble_decls(outfile, class_decls_ptr);
              Disassemble_stmts(outfile, class_init_ptr);

              {*****************************}
              { disassemble special methods }
              {*****************************}
              Disassemble_code(outfile, constructor_code_ref);
              Disassemble_code(outfile, destructor_code_ref);
            end; {class_type}

        end; {case}
      end; {if}
end; {procedure Disassemble_type_fields}


procedure Disassemble_type(var outfile: text;
  type_ptr: type_ptr_type);
begin
  if type_ptr <> nil then
    begin
      {****************************}
      { disassemble type reference }
      {****************************}
      if type_ptr^.type_index <> 0 then
        begin
          Disassemble_mnemonic(outfile, 'trf');
          Disassemble_index(outfile, type_ptr^.type_index);
        end

          {******************}
          { disassemble type }
          {******************}
      else
        begin
          type_disasm_count := type_disasm_count + 1;
          type_ptr^.type_index := type_disasm_count;

          {***************************}
          { disassemble type mnemonic }
          {***************************}
          Disassemble_mnemonic(outfile,
            Type_decl_kind_to_mnemonic(type_ptr^.kind));
          Disassemble_type_fields(outfile, type_ptr);
        end;
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_type}


{****************************************}
{ functions returning assembler progress }
{****************************************}


function Types_assembled: asm_index_type;
begin
  Types_assembled := type_asm_count;
end; {function Types_assembled}


function Types_disassembled: asm_index_type;
begin
  Types_disassembled := type_disasm_count;
end; {function Types_disassembled}


initialization
  Make_type_mnemonics;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  type_asm_count := 0;
  type_disasm_count := 0;
  type_block_ptr := nil;
  type_block_count := 0;
end.
