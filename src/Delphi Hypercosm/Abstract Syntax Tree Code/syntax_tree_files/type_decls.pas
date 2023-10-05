unit type_decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             type_decls                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The type_decls module defines the type declarations     }
{       used in the abstract syntax tree, the internal          }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  chars, strings, addr_types, type_attributes, exprs, stmts, decls, code_decls;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}
{                       type declarations                       }
{***************************************************************}


const
  dispatch_table_size = 256;


type
  class_kind_type = (normal_class, abstract_class, final_class, interface_class,
    alias_class);
  class_kind_set_type = set of class_kind_type;


  {**************************************}
  { the abstract syntax tree declaration }
  {**************************************}
  type_decl_kind_type = (enum_type, alias_type, struct_type, class_type);
  type_decl_kind_set_type = set of type_decl_kind_type;


  {******************************************************}
  { Note:                                                }
  { the names 'expr_ptr', 'stmt_ptr' and 'decl_ptr' are  }
  { intentionally not used as fields so that they may be }
  { used as locals inside of a 'with decl_ptr^' block.   }
  {                                                      }
  { Otherwise be wary of 'with decl_ptr^' blocks because }
  { the decl node has so many fields that an identifier  }
  { clash may easily cause a misunderstanding not found  }
  { by the compiler.                                     }
  {******************************************************}
  type_ptr_type = ^type_type;
  type_ref_type = type_ptr_type;


  {***************************************}
  { array of ptrs to virtual method decls }
  {***************************************}
  dispatch_table_ptr_type = ^dispatch_table_type;
  dispatch_table_type = record
    entries: integer;
    dispatch_table: array[1..dispatch_table_size] of code_ptr_type;
    next: dispatch_table_ptr_type;
  end; {dispatch_table_type}


  type_reference_ptr_type = ^type_reference_type;
  type_reference_type = record
    type_ref: type_ref_type;
    index: integer;
    next: type_reference_ptr_type;
  end; {type_reference_type}


  type_type = record
    type_decl_ref: decl_ref_type;
    type_index: longint;
    next: type_ptr_type;

    {********************************}
    { runtime allocation information }
    {********************************}
    static: boolean;
    size: heap_index_type;

    case kind: type_decl_kind_type of

      enum_type, alias_type: (
        );

      {************************}
      { structure declarations }
      {************************}
      struct_type: (

        {***************************}
        { struct field declarations }
        {***************************}
        struct_base_ptr: expr_ptr_type;
        field_decls_ptr: decl_ptr_type;
        struct_base_assign_stmt_ptr: stmt_ptr_type;
        );

      {********************}
      { class declarations }
      {********************}
      class_type: (

        {*******************************}
        { class declaration information }
        {*******************************}
        class_kind: class_kind_type;
        copyable, subclass_copyable: boolean;

        {******************************}
        { parent and interface classes }
        {******************************}
        parent_class_ref: type_ref_type;
        interface_class_ptr: type_reference_ptr_type;

        {*************************************}
        { class method interface declarations }
        {*************************************}
        method_decls_ptr: decl_ptr_type;
        dispatch_table_ptr: dispatch_table_ptr_type;

        {***************************}
        { class member declarations }
        {***************************}
        class_base_ptr: expr_ptr_type;
        member_decls_ptr: decl_ptr_type;
        private_member_decls_ptr: decl_ptr_type;
        class_base_assign_stmt_ptr: stmt_ptr_type;

        {***********************************}
        { class implementation declarations }
        {***********************************}
        class_decls_ptr: decl_ptr_type;
        class_init_ptr: stmt_ptr_type;

        {***********************}
        { special class methods }
        {***********************}
        constructor_code_ref: code_ref_type;
        destructor_code_ref: code_ref_type;
        );
  end; {type_type}


{************************************************}
{ routines for allocating and initializing decls }
{************************************************}
function New_type(kind: type_decl_kind_type;
  decl_ptr: decl_ptr_type): type_ptr_type;
procedure Init_type(type_ptr: type_ptr_type;
  kind: type_decl_kind_type);
function Copy_type(type_ptr: type_ptr_type): type_ptr_type;
function Copy_types(type_ptr: type_ptr_type): type_ptr_type;
procedure Free_type(var type_ptr: type_ptr_type);
procedure Free_types(var type_ptr: type_ptr_type);
function Type_count: longint;

{*************************************************************}
{ routine for finding the type declaration from the data type }
{*************************************************************}
function Get_type_decl(type_attributes_ptr: type_attributes_ptr_type):
  type_ptr_type;

{******************************************************}
{ routines for allocating and freeing auxilliary nodes }
{******************************************************}
function New_dispatch_table: dispatch_table_ptr_type;
function New_type_ref(type_ptr: type_ptr_type): type_reference_ptr_type;
procedure Free_dispatch_table(var dispatch_table_ptr: dispatch_table_ptr_type);
procedure Free_type_ref(var type_ref_ptr: type_reference_ptr_type);
procedure Free_type_refs(var type_ref_ptr: type_reference_ptr_type);

{******************************************************}
{ routine for finding if class is a member of a family }
{******************************************************}
function Root_class(class_type_ptr: type_ptr_type): boolean;
function Member_class(class_type_ptr: type_ptr_type;
  parent_type_ptr: type_ptr_type): boolean;
function Get_method_name(code_ptr: code_ptr_type): string_type;

{****************************************************}
{ routine for finding a class type's special methods }
{****************************************************}
function Get_type_constructor(type_ptr: type_ptr_type): code_ptr_type;
function Get_type_destructor(type_ptr: type_ptr_type): code_ptr_type;
function Get_type_copier(type_ptr: type_ptr_type): stmt_ptr_type;
function Get_abstract_type_destructor(type_ptr: forward_type_ptr_type):
  forward_code_ptr_type;

{*******************************************}
{ routines to create dynamic binding tables }
{*******************************************}
procedure Add_virtual_method(class_ptr: type_ptr_type;
  method_ptr: code_ptr_type);
procedure Add_virtual_methods(class_ptr, extension_class_ptr: type_ptr_type);
procedure Override_virtual_method(method_ptr: code_ptr_type;
  overriding_method_ptr: code_ptr_type;
  class_ptr: type_ptr_type);
procedure Set_virtual_method(class_ptr: type_ptr_type;
  method_ptr: code_ptr_type);

{****************************}
{ routines for writing decls }
{****************************}
procedure Write_type_decl_kind(kind: type_decl_kind_type);
procedure Write_class_kind(kind: class_kind_type);


implementation
uses
  new_memory, decl_attributes;


const
  block_size = 512;
  memory_alert = false;
  verbose = false;


type
  type_block_ptr_type = ^type_block_type;
  type_block_type = array[0..block_size] of type_type;


var
  type_free_list: type_ptr_type;
  type_block_ptr: type_block_ptr_type;
  type_counter: longint;

  {*********************************}
  { free lists for auxilliary nodes }
  {*********************************}
  type_ref_free_list: type_reference_ptr_type;
  dispatch_table_free_list: dispatch_table_ptr_type;


{*****************************************************}
{ routines for allocating and initializing type decls }
{*****************************************************}


procedure Init_type(type_ptr: type_ptr_type;
  kind: type_decl_kind_type);
begin
  type_ptr^.kind := kind;
  type_ptr^.type_decl_ref := nil;
  type_ptr^.type_index := 0;
  type_ptr^.next := nil;

  with type_ptr^ do
    begin
      {*******************************************}
      { initialize runtime allocation information }
      {*******************************************}
      static := false;
      size := 0;

      case kind of

        enum_type, alias_type:
          ;

        {************************}
        { structure declarations }
        {************************}
        struct_type:
          begin
            {**************************************}
            { initialize struct field declarations }
            {**************************************}
            struct_base_ptr := nil;
            field_decls_ptr := nil;
            struct_base_assign_stmt_ptr := nil;
          end; {struct_type}

        {********************}
        { class declarations }
        {********************}
        class_type:
          begin
            {******************************************}
            { initialize class declaration information }
            {******************************************}
            class_kind := normal_class;
            copyable := false;
            subclass_copyable := false;

            {******************************}
            { parent and interface classes }
            {******************************}
            parent_class_ref := nil;
            interface_class_ptr := nil;

            {************************************************}
            { initialize class method interface declarations }
            {************************************************}
            method_decls_ptr := nil;
            dispatch_table_ptr := nil;

            {**************************************}
            { initialize class member declarations }
            {**************************************}
            class_base_ptr := nil;
            member_decls_ptr := nil;
            private_member_decls_ptr := nil;
            class_base_assign_stmt_ptr := nil;

            {**********************************************}
            { initialize class implementation declarations }
            {**********************************************}
            class_decls_ptr := nil;
            class_init_ptr := nil;

            {**********************************}
            { initialize special class methods }
            {**********************************}
            constructor_code_ref := nil;
            destructor_code_ref := nil;
          end; {class_type}

      end; {case}
    end; {with}
end; {procedure Init_type}


function New_type(kind: type_decl_kind_type;
  decl_ptr: decl_ptr_type): type_ptr_type;
var
  type_ptr: type_ptr_type;
  index: integer;
begin
  {******************************}
  { get type node from free list }
  {******************************}
  if type_free_list <> nil then
    begin
      type_ptr := type_free_list;
      type_free_list := type_free_list^.next;
    end
  else
    begin
      index := type_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new type block');
          new(type_block_ptr);
        end;
      type_ptr := @type_block_ptr^[index];
    end;

  {************************}
  { increment type counter }
  {************************}
  type_counter := type_counter + 1;

  {**********************}
  { initialize type node }
  {**********************}
  Init_type(type_ptr, kind);

  {*******************}
  { set back pointers }
  {*******************}
  type_ptr^.type_decl_ref := decl_ptr;
  if decl_ptr <> nil then
    decl_ptr^.type_ptr := forward_type_ptr_type(type_ptr);

  New_type := type_ptr;
end; {function New_type}


function Type_count: longint;
begin
  Type_count := type_counter;
end; {function Type_count}


{*************************************************************}
{ routine for finding the type declaration from the data type }
{*************************************************************}


function Get_type_decl(type_attributes_ptr: type_attributes_ptr_type):
  type_ptr_type;
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  decl_ptr: decl_ptr_type;
  type_ptr: type_ptr_type;
begin
  type_ptr := nil;

  if type_attributes_ptr <> nil then
    begin
      decl_attributes_ptr :=
        Get_id_decl_attributes(type_attributes_ptr^.id_ptr);
      if decl_attributes_ptr <> nil then
        begin
          decl_ptr := decl_ptr_type(decl_attributes_ptr^.decl_ref);
          if decl_ptr <> nil then
            type_ptr := type_ptr_type(decl_ptr^.type_ptr);
        end;
    end;

  Get_type_decl := type_ptr;
end; {function Get_type_decl}


{*************************************************************}
{ routines for copying type declarations and associated nodes }
{*************************************************************}


function Copy_type(type_ptr: type_ptr_type): type_ptr_type;
var
  new_type_ptr: type_ptr_type;
begin
  if (type_ptr <> nil) then
    begin
      new_type_ptr := New_type(type_ptr^.kind, nil);
      new_type_ptr^ := type_ptr^;
      new_type_ptr^.next := nil;
    end
  else
    new_type_ptr := nil;

  Copy_type := new_type_ptr;
end; {function Copy_type}


function Copy_types(type_ptr: type_ptr_type): type_ptr_type;
var
  new_type_ptr: type_ptr_type;
  first_type_ptr, last_type_ptr: type_ptr_type;
begin
  first_type_ptr := nil;
  last_type_ptr := nil;

  while type_ptr <> nil do
    begin
      new_type_ptr := Copy_type(type_ptr);

      {**********************************}
      { add new type node to end of list }
      {**********************************}
      if (last_type_ptr <> nil) then
        begin
          last_type_ptr^.next := new_type_ptr;
          last_type_ptr := new_type_ptr;
        end
      else
        begin
          first_type_ptr := new_type_ptr;
          last_type_ptr := new_type_ptr;
        end;

      type_ptr := type_ptr^.next;
    end;

  Copy_types := first_type_ptr;
end; {function Copy_types}


{*************************************************************}
{ routines for freeing type declarations and associated nodes }
{*************************************************************}


procedure Free_type(var type_ptr: type_ptr_type);
begin
  if (type_ptr <> nil) then
    begin
      {***********************}
      { add type to free list }
      {***********************}
      type_ptr^.next := type_free_list;
      type_free_list := type_ptr;
      type_ptr := nil;

      {************************}
      { decrement type counter }
      {************************}
      type_counter := type_counter - 1;
    end;
end; {procedure Free_type}


procedure Free_types(var type_ptr: type_ptr_type);
var
  temp: type_ptr_type;
begin
  while (type_ptr <> nil) do
    begin
      temp := type_ptr;
      type_ptr := type_ptr^.next;
      Free_type(temp);
    end;
end; {procedure Free_types}


{*******************************************************}
{ routines for finding if class is a member of a family }
{*******************************************************}


function Superclass_parent(type_ptr: type_ptr_type;
  parent_type_ptr: type_ptr_type): boolean;
var
  found: boolean;
begin
  {****************************************************}
  { search for parent class in class's superclass list }
  {****************************************************}
  found := false;
  while (type_ptr <> nil) and not found do
    begin
      if type_ptr = parent_type_ptr then
        found := true;

      {********************}
      { go to parent class }
      {********************}
      if not found then
        type_ptr := type_ptr^.parent_class_ref;
    end;

  Superclass_parent := found;
end; {function Superclass_parent}


function Interface_parent(type_ptr: type_ptr_type;
  parent_type_ptr: type_ptr_type): boolean;
var
  found: boolean;
  type_reference_ptr: type_reference_ptr_type;
begin
  {****************************************************}
  { search for parent class in superclass's interfaces }
  {****************************************************}
  found := false;
  while (type_ptr <> nil) and not found do
    begin
      type_reference_ptr := type_ptr^.interface_class_ptr;
      while (type_reference_ptr <> nil) and not found do
        begin
          if type_reference_ptr^.type_ref = parent_type_ptr then
            found := true;

          if not found then
            type_reference_ptr := type_reference_ptr^.next;
        end;

      {********************}
      { go to parent class }
      {********************}
      if not found then
        type_ptr := type_ptr^.parent_class_ref;
    end;

  Interface_parent := found;
end; {function Interface_parent}


function Root_class(class_type_ptr: type_ptr_type): boolean;
var
  root: boolean;
begin
  if class_type_ptr^.static then
    root := false
  else
    root := class_type_ptr^.parent_class_ref = nil;

  Root_class := root;
end; {function Root_class}


function Member_class(class_type_ptr: type_ptr_type;
  parent_type_ptr: type_ptr_type): boolean;
begin
  if parent_type_ptr^.class_kind <> interface_class then
    Member_class := Superclass_parent(class_type_ptr, parent_type_ptr)
  else
    Member_class := Interface_parent(class_type_ptr, parent_type_ptr);
end; {function Member_class}


function Get_method_name(code_ptr: code_ptr_type): string_type;
var
  type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  method_name, class_name: string_type;
begin
  decl_attributes_ptr := Get_decl_attributes(code_ptr^.code_decl_ref);
  method_name := Get_decl_attributes_name(decl_attributes_ptr);

  if code_ptr^.class_type_ref <> nil then
    begin
      type_ptr := type_ptr_type(code_ptr^.class_type_ref);
      decl_attributes_ptr := Get_decl_attributes(type_ptr^.type_decl_ref);
      class_name := Get_decl_attributes_name(decl_attributes_ptr);
      class_name := concat(class_name, Char_to_str(single_quote));
      class_name := concat(class_name, 's ');
      method_name := concat(class_name, method_name);
    end;

  Get_method_name := method_name;
end; {function Get_method_name}


{****************************************************}
{ routine for finding a class type's special methods }
{****************************************************}


function Get_type_constructor(type_ptr: type_ptr_type): code_ptr_type;
begin
  Get_type_constructor := type_ptr^.constructor_code_ref;
end; {function Get_type_constructor}


function Get_type_destructor(type_ptr: type_ptr_type): code_ptr_type;
begin
  Get_type_destructor := type_ptr^.destructor_code_ref;
end; {function Get_type_destructor}


function Get_type_copier(type_ptr: type_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := nil;

  case type_ptr^.kind of
    struct_type:
      stmt_ptr := type_ptr^.struct_base_assign_stmt_ptr;
    class_type:
      stmt_ptr := type_ptr^.class_base_assign_stmt_ptr;
  end; {case}

  Get_type_copier := stmt_ptr;
end; {function Get_type_copier}


function Get_abstract_type_destructor(type_ptr: forward_type_ptr_type):
  forward_code_ptr_type;
begin
  Get_abstract_type_destructor :=
    forward_code_ptr_type(Get_type_destructor(type_ptr_type(type_ptr)));
end; {procedure Get_abstract_type_destructor}


{******************************************}
{ routines for allocating auxilliary nodes }
{******************************************}


function New_dispatch_table: dispatch_table_ptr_type;
var
  dispatch_table_ptr: dispatch_table_ptr_type;
  counter: integer;
begin
  {***********************************}
  { get dispatch table from free list }
  {***********************************}
  if (dispatch_table_free_list <> nil) then
    begin
      dispatch_table_ptr := dispatch_table_free_list;
      dispatch_table_free_list := dispatch_table_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new dispatch table');
      new(dispatch_table_ptr);
    end;

  {***************************}
  { initialize dispatch table }
  {***************************}
  with dispatch_table_ptr^ do
    begin
      entries := 0;
      for counter := 1 to dispatch_table_size do
        dispatch_table[counter] := nil;
      next := nil;
    end;

  New_dispatch_table := dispatch_table_ptr;
end; {function New_dispatch_table}


function New_type_ref(type_ptr: type_ptr_type): type_reference_ptr_type;
var
  type_ref_ptr: type_reference_ptr_type;
begin
  {*****************************}
  { get type ref from free list }
  {*****************************}
  if (type_ref_free_list <> nil) then
    begin
      type_ref_ptr := type_ref_free_list;
      type_ref_free_list := type_ref_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new type ref');
      new(type_ref_ptr);
    end;

  {*********************}
  { initialize type ref }
  {*********************}
  type_ref_ptr^.type_ref := type_ptr;
  type_ref_ptr^.index := 0;
  type_ref_ptr^.next := nil;

  New_type_ref := type_ref_ptr;
end; {function New_type_ref}


{***************************************}
{ routines for freeing auxilliary nodes }
{***************************************}


procedure Free_dispatch_table(var dispatch_table_ptr: dispatch_table_ptr_type);
begin
  {*********************************}
  { add dispatch table to free list }
  {*********************************}
  dispatch_table_ptr^.next := dispatch_table_free_list;
  dispatch_table_free_list := dispatch_table_ptr;
  dispatch_table_ptr := nil;
end; {procedure Free_dispatch_table}


procedure Free_type_ref(var type_ref_ptr: type_reference_ptr_type);
begin
  {***************************}
  { add type ref to free list }
  {***************************}
  type_ref_ptr^.next := type_ref_free_list;
  type_ref_free_list := type_ref_ptr;
  type_ref_ptr := nil;
end; {procedure Free_type_ref}


procedure Free_type_refs(var type_ref_ptr: type_reference_ptr_type);
var
  temp: type_reference_ptr_type;
begin
  while (type_ref_ptr <> nil) do
    begin
      temp := type_ref_ptr;
      type_ref_ptr := type_ref_ptr^.next;
      Free_type_ref(temp);
    end;
end; {procedure Free_type_refs}


{*******************************************}
{ routines to create dynamic binding tables }
{*******************************************}


procedure Add_virtual_method(class_ptr: type_ptr_type;
  method_ptr: code_ptr_type);
begin
  with class_ptr^.dispatch_table_ptr^ do
    begin
      entries := entries + 1;
      dispatch_table[entries] := method_ptr;
      method_ptr^.method_id := entries;
    end;
end; {procedure Add_virtual_method}


procedure Set_virtual_method(class_ptr: type_ptr_type;
  method_ptr: code_ptr_type);
begin
  with class_ptr^.dispatch_table_ptr^ do
    dispatch_table[method_ptr^.method_id] := method_ptr;
end; {procedure Set_virtual_method}


procedure Add_virtual_methods(class_ptr: type_ptr_type;
  extension_class_ptr: type_ptr_type);
var
  counter, entries: integer;
  dispatch_table_ptr: dispatch_table_ptr_type;
  extension_table_ptr: dispatch_table_ptr_type;
  code_ptr: code_ptr_type;
begin
  dispatch_table_ptr := class_ptr^.dispatch_table_ptr;
  extension_table_ptr := extension_class_ptr^.dispatch_table_ptr;

  entries := dispatch_table_ptr^.entries;
  for counter := 1 to extension_table_ptr^.entries do
    begin
      entries := entries + 1;
      code_ptr := extension_table_ptr^.dispatch_table[counter];
      code_ptr^.method_id := entries;
      dispatch_table_ptr^.dispatch_table[entries] := code_ptr;
    end;

  dispatch_table_ptr^.entries := entries;
end; {procedure Add_virtual_methods}


procedure Override_virtual_method(method_ptr: code_ptr_type;
  overriding_method_ptr: code_ptr_type;
  class_ptr: type_ptr_type);
var
  dispatch_table_ptr: dispatch_table_ptr_type;
  method_id: integer;
begin
  method_id := method_ptr^.method_id;
  overriding_method_ptr^.method_id := method_id;

  dispatch_table_ptr := class_ptr^.dispatch_table_ptr;
  dispatch_table_ptr^.dispatch_table[method_id] := overriding_method_ptr;
end; {procedure Override_virtual_method}


{****************************}
{ routines for writing types }
{****************************}


procedure Write_type_decl_kind(kind: type_decl_kind_type);
begin
  case kind of
    enum_type:
      write('enum_type');
    alias_type:
      write('alias_type');
    struct_type:
      write('struct_type');
    class_type:
      write('class_type');
  end; {case}
end; {procedure Write_type_decl_kind}


procedure Write_class_kind(kind: class_kind_type);
begin
  case kind of
    normal_class:
      write('normal_class');
    abstract_class:
      write('abstract_class');
    final_class:
      write('final_class');
    interface_class:
      write('interface_class');
    alias_class:
      write('alias_class');
  end; {case}
end; {procedure Write_class_kind}


initialization
  type_free_list := nil;
  type_block_ptr := nil;
  type_counter := 0;

  {***********************}
  { initialize free lists }
  {***********************}
  type_ref_free_list := nil;
  dispatch_table_free_list := nil;
end.
