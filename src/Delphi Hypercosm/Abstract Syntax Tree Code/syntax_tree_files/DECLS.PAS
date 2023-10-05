unit decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm                decls                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The decls module defines all of the declarations        }
{       used in the abstract syntax tree, the internal          }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  new_memory, strings, type_attributes, decl_attributes, comments, exprs, stmts;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}
{                          declarations                         }
{***************************************************************}


type
  decl_kind_type = (

    {*************************}
    { null or nop declaration }
    {*************************}
    null_decl,

    {********************************}
    { user defined type declarations }
    {********************************}
    type_decl,

    {***********************************}
    { primitive enumerated declarations }
    {***********************************}
    boolean_decl, char_decl,

    {*********************************}
    { primitive integral declarations }
    {*********************************}
    byte_decl, short_decl, integer_decl, long_decl,

    {*******************************}
    { primitive scalar declarations }
    {*******************************}
    scalar_decl, double_decl, complex_decl, vector_decl,

    {*******************************************}
    { array, struct, and reference declarations }
    {*******************************************}
    array_decl, struct_decl, static_struct_decl, reference_decl,

    {**************************************}
    { user defined subprogram declarations }
    {**************************************}
    code_decl, code_array_decl, code_reference_decl);


type
  decl_kind_set_type = set of decl_kind_type;


  forward_type_ptr_type = ptr_type;
  forward_code_ptr_type = ptr_type;


  {***********************************}
  { auxillary declaration information }
  {***********************************}
  decl_info_ptr_type = ^decl_info_type;
  decl_info_type = record
    {***********************************}
    { compile time semantic information }
    {***********************************}
    decl_attributes_ptr: decl_attributes_ptr_type;

    {*********************************}
    { compile time syntax information }
    {*********************************}
    comments_ptr: comments_ptr_type; { line and block comments }
    decl_number: integer; { order of decl in a multiple decl }

    {********************************}
    { run time debugging information }
    {********************************}
    line_number: integer; { line number of decl in source text }
    file_number: integer; { file number of decl in file table  }

    {**********************************************}
    { syntax tree declaration which uses this info }
    {**********************************************}
    decl_ref: forward_decl_ref_type;

    {*******************************}
    { links to active or free lists }
    {*******************************}
    prev, next: decl_info_ptr_type;
  end; {decl_info_type}


  {**************************************}
  { the abstract syntax tree declaration }
  {**************************************}
  decl_ptr_type = ^decl_type;
  decl_ref_type = decl_ptr_type;


  data_decl_type = record

    {*****************}
    { address of data }
    {*****************}
    data_expr_ptr: expr_ptr_type;

    {***************************************}
    { initializing expression and statement }
    {***************************************}
    init_expr_ptr: expr_ptr_type;
    init_stmt_ptr: stmt_ptr_type;

    {*******************}
    { declaration flags }
    {*******************}
    static, native: boolean;
    native_index: integer;

  end; {data_decl_type}


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
  decl_type = record
    decl_info_ptr: decl_info_ptr_type;
    decl_index: integer;
    next: decl_ptr_type;

    case kind: decl_kind_type of

      {*************************}
      { null or nop declaration }
      {*************************}
      null_decl: (
        );

      {********************************}
      { user defined type declarations }
      {********************************}
      type_decl: (
        type_ptr: forward_type_ptr_type;
        );

      {***********************************}
      { primitive enumerated declarations }
      {***********************************}
      boolean_decl, char_decl,

      {*********************************}
      { primitive integral declarations }
      {*********************************}
      byte_decl, short_decl, integer_decl, long_decl,

      {*******************************}
      { primitive scalar declarations }
      {*******************************}
      scalar_decl, double_decl, complex_decl, vector_decl,

      {*******************************************}
      { array, struct, and reference declarations }
      {*******************************************}
      array_decl, struct_decl, static_struct_decl, reference_decl: (
        data_decl: data_decl_type;
        static_struct_type_ref: forward_type_ptr_type;
        );

      {**************************************}
      { user defined subprogram declarations }
      {**************************************}
      code_decl, code_array_decl, code_reference_decl: (
        code_data_decl: data_decl_type;
        code_ptr: forward_code_ptr_type;
        );
  end; {decl_type}


var
  primitive_decl_set, reference_decl_set, data_decl_set: decl_kind_set_type;
  active_decl_info_list: decl_info_ptr_type;


{************************************************}
{ routines for allocating and initializing decls }
{************************************************}
function New_decl(kind: decl_kind_type): decl_ptr_type;
procedure Init_decl(decl_ptr: decl_ptr_type;
  kind: decl_kind_type);
function Copy_decl(decl_ptr: decl_ptr_type): decl_ptr_type;
function Copy_decls(decl_ptr: decl_ptr_type): decl_ptr_type;
procedure Free_decl(var decl_ptr: decl_ptr_type);
procedure Free_decls(var decl_ptr: decl_ptr_type);
function Decl_count: longint;

{**********************************************************}
{ routines for allocating and freeing auxiliiary decl info }
{**********************************************************}
function New_decl_info: decl_info_ptr_type;
procedure Init_decl_info(decl_info_ptr: decl_info_ptr_type);
function Copy_decl_info(decl_info_ptr: decl_info_ptr_type;
  copy_attributes: boolean): decl_info_ptr_type;
procedure Free_decl_info(var decl_info_ptr: decl_info_ptr_type;
  free_attributes: boolean);
function Decl_info_count: longint;

{************************************************}
{ routines for manipulating auxilliary decl info }
{************************************************}
procedure Set_decl_info(decl_ptr: decl_ptr_type;
  decl_info_ptr: decl_info_ptr_type);
function Get_decl_info(decl_ptr: decl_ptr_type): decl_info_ptr_type;

{***************************************}
{ routines dealing with decl attributes }
{***************************************}
procedure Set_decl_attributes(decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
procedure Set_decl_properties(decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);

{****************************************}
{ routines for dealing with declarations }
{****************************************}
function Get_decl_attributes(decl_ptr: decl_ptr_type): decl_attributes_ptr_type;
function Get_decl_expr(decl_ptr: decl_ptr_type): expr_ptr_type;
function Get_decl_name(decl_ptr: decl_ptr_type): string_type;

{****************************}
{ routines for writing decls }
{****************************}
procedure Write_decl_kind(kind: decl_kind_type);


implementation
uses
  errors;


const
  block_size = 512;
  memory_alert = false;
  verbose = false;


type
  {************************}
  { block allocation types }
  {************************}
  decl_block_ptr_type = ^decl_block_type;
  decl_block_type = array[0..block_size] of decl_type;

  decl_info_block_ptr_type = ^decl_info_block_type;
  decl_info_block_type = array[0..block_size] of decl_info_type;


var
  {************}
  { free lists }
  {************}
  decl_free_list: decl_ptr_type;
  decl_info_free_list: decl_info_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  decl_block_ptr: decl_block_ptr_type;
  decl_counter: longint;

  decl_info_block_ptr: decl_info_block_ptr_type;
  decl_info_counter: longint;

  {**************}
  { active lists }
  {**************}
  last_active_decl_info_ptr: decl_info_ptr_type;


procedure Init_decl_sets;
begin
  primitive_decl_set := [boolean_decl..vector_decl];
  reference_decl_set := [array_decl, struct_decl, reference_decl, code_decl,
    code_array_decl, code_reference_decl];
  data_decl_set := primitive_decl_set + reference_decl_set +
    [static_struct_decl];
end; {procedure Init_decl_sets}


{**********************************************************}
{ routines for allocating and freeing auxiliiary decl info }
{**********************************************************}


procedure Init_decl_info(decl_info_ptr: decl_info_ptr_type);
begin
  with decl_info_ptr^ do
    begin
      {**********************************************}
      { initialize compile time semantic information }
      {**********************************************}
      decl_attributes_ptr := nil;

      {********************************************}
      { initialize compile time syntax information }
      {********************************************}
      comments_ptr := nil;
      decl_number := 1;

      {*******************************************}
      { initialize run time debugging information }
      {*******************************************}
      line_number := 0;
      file_number := 0;

      {**********************************************}
      { initialize syntax tree declaration reference }
      {**********************************************}
      decl_ref := nil;

      {******************************************}
      { initialize links to active or free lists }
      {******************************************}
      prev := nil;
      next := nil;
    end;
end; {function Init_decl_info}


function New_decl_info: decl_info_ptr_type;
var
  decl_info_ptr: decl_info_ptr_type;
  index: integer;
begin
  {******************************}
  { get decl info from free list }
  {******************************}
  if decl_info_free_list <> nil then
    begin
      decl_info_ptr := decl_info_free_list;
      decl_info_free_list := decl_info_free_list^.next;
    end
  else
    begin
      index := decl_info_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new decl info block');
          new(decl_info_block_ptr);
        end;
      decl_info_ptr := @decl_info_block_ptr^[index];
    end;

  {*****************************}
  { increment decl info counter }
  {*****************************}
  decl_info_counter := decl_info_counter + 1;

  {**********************}
  { initialize decl info }
  {**********************}
  Init_decl_info(decl_info_ptr);

  {***************************}
  { add to end of active list }
  {***************************}
  if last_active_decl_info_ptr <> nil then
    begin
      last_active_decl_info_ptr^.next := decl_info_ptr;
      decl_info_ptr^.prev := last_active_decl_info_ptr;
      last_active_decl_info_ptr := decl_info_ptr;
      decl_info_ptr^.next := nil;
    end
  else
    begin
      active_decl_info_list := decl_info_ptr;
      last_active_decl_info_ptr := decl_info_ptr;
      decl_info_ptr^.prev := nil;
      decl_info_ptr^.next := nil;
    end;

  New_decl_info := decl_info_ptr;
end; {function New_decl_info}


function Copy_decl_info(decl_info_ptr: decl_info_ptr_type;
  copy_attributes: boolean): decl_info_ptr_type;
var
  new_decl_info_ptr: decl_info_ptr_type;
  next, prev: decl_info_ptr_type;
begin
  if decl_info_ptr <> nil then
    begin
      new_decl_info_ptr := New_decl_info;

      {****************************************}
      { copy all fields except for link fields }
      {****************************************}
      next := new_decl_info_ptr^.next;
      prev := new_decl_info_ptr^.prev;
      new_decl_info_ptr^ := decl_info_ptr^;
      new_decl_info_ptr^.next := next;
      new_decl_info_ptr^.prev := prev;

      if copy_attributes then
        with new_decl_info_ptr^ do
          decl_attributes_ptr := Copy_decl_attributes(decl_attributes_ptr);
    end
  else
    new_decl_info_ptr := nil;

  Copy_decl_info := new_decl_info_ptr;
end; {function Copy_decl_info}


procedure Free_decl_info(var decl_info_ptr: decl_info_ptr_type;
  free_attributes: boolean);
begin
  if decl_info_ptr <> nil then
    begin
      if free_attributes then
        Free_decl_attributes(decl_info_ptr^.decl_attributes_ptr);

      {*******************************}
      { link neighbors in active list }
      {*******************************}
      if decl_info_ptr^.prev <> nil then
        decl_info_ptr^.prev^.next := decl_info_ptr^.next
      else
        active_decl_info_list := decl_info_ptr^.next;

      if decl_info_ptr^.next <> nil then
        decl_info_ptr^.next^.prev := decl_info_ptr^.prev
      else
        last_active_decl_info_ptr := decl_info_ptr^.prev;

      {****************************}
      { add decl info to free list }
      {****************************}
      decl_info_ptr^.prev := nil;
      decl_info_ptr^.next := decl_info_free_list;
      decl_info_free_list := decl_info_ptr;
      decl_info_ptr := nil;

      {*****************************}
      { decrement decl info counter }
      {*****************************}
      decl_info_counter := decl_info_counter - 1;
    end;
end; {procedure Free_decl_info}


function Decl_info_count: longint;
begin
  Decl_info_count := decl_info_counter;
end; {function Decl_info_count}


{************************************************}
{ routines for manipulating auxilliary decl info }
{************************************************}


procedure Set_decl_info(decl_ptr: decl_ptr_type;
  decl_info_ptr: decl_info_ptr_type);
begin
  {**************************************}
  { link declaration and its information }
  {**************************************}
  decl_ptr^.decl_info_ptr := decl_info_ptr;
  if decl_info_ptr <> nil then
    decl_info_ptr^.decl_ref := forward_decl_ref_type(decl_ptr);

  {*************************************}
  { link declaration and its attributes }
  {*************************************}
  if decl_info_ptr <> nil then
    Set_decl_attributes(decl_ptr, decl_info_ptr^.decl_attributes_ptr);
end; {procedure Set_decl_info}


function Get_decl_info(decl_ptr: decl_ptr_type): decl_info_ptr_type;
begin
  if decl_ptr <> nil then
    Get_decl_info := decl_ptr^.decl_info_ptr
  else
    Get_decl_info := nil;
end; {function Get_decl_info}


{***************************************}
{ routines dealing with decl attributes }
{***************************************}


procedure Set_data_decl_properties(var data_decl: data_decl_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  implicitly_static: boolean;
begin
  if decl_attributes_ptr <> nil then
    begin
      {*************************}
      { mark new decl as unused }
      {*************************}
      decl_attributes_ptr^.used := false;
      implicitly_static := false;

      if decl_attributes_ptr^.native then
        begin
          {****************************}
          { flag native parent as well }
          {****************************}
          if decl_attributes_ptr^.scope_decl_attributes_ptr <> nil then
            decl_attributes_ptr^.scope_decl_attributes_ptr^.native := true;
        end
      else
        begin
          {*****************************}
          { implicitly static variables }
          {*****************************}
          if decl_attributes_ptr^.kind = data_decl_attributes then
            if decl_attributes_ptr^.scope_decl_attributes_ptr = nil then
              if decl_attributes_ptr^.static_level = 1 then
                implicitly_static := true;
        end;

      data_decl.static := decl_attributes_ptr^.static or implicitly_static;
      data_decl.native := decl_attributes_ptr^.native;
    end; {if}
end; {procedure Set_data_decl_properties}


procedure Set_decl_properties(decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  case decl_ptr^.kind of

    boolean_decl..reference_decl:
      Set_data_decl_properties(decl_ptr^.data_decl, decl_attributes_ptr);

    code_decl..code_reference_decl:
      Set_data_decl_properties(decl_ptr^.code_data_decl, decl_attributes_ptr);

  end; {case}
end; {procedure Set_decl_properties}


procedure Set_decl_attributes(decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  decl_info_ptr: decl_info_ptr_type;
begin
  if decl_ptr^.decl_info_ptr = nil then
    begin
      decl_info_ptr := New_decl_info;
      Set_decl_info(decl_ptr, decl_info_ptr);
    end;

  {***********************************}
  { link statement and its attributes }
  {***********************************}
  decl_ptr^.decl_info_ptr^.decl_attributes_ptr := decl_attributes_ptr;
  if decl_attributes_ptr <> nil then
    decl_attributes_ptr^.decl_ref := forward_decl_ref_type(decl_ptr);
end; {procedure Set_decl_attributes}


{****************************************}
{ routines for dealing with declarations }
{****************************************}


function Get_decl_attributes(decl_ptr: decl_ptr_type): decl_attributes_ptr_type;
var
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if decl_ptr <> nil then
    begin
      if decl_ptr^.decl_info_ptr <> nil then
        decl_attributes_ptr := decl_ptr^.decl_info_ptr^.decl_attributes_ptr
      else
        decl_attributes_ptr := nil;
    end
  else
    decl_attributes_ptr := nil;

  Get_decl_attributes := decl_attributes_ptr;
end; {function Get_decl_attributes}


function Get_decl_expr(decl_ptr: decl_ptr_type): expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
begin
  expr_ptr := nil;

  case decl_ptr^.kind of

    {*******************}
    { data declarations }
    {*******************}
    boolean_decl..reference_decl:
      expr_ptr := decl_ptr^.data_decl.data_expr_ptr;

    {*************************}
    { subprogram declarations }
    {*************************}
    code_decl..code_reference_decl:
      expr_ptr := decl_ptr^.code_data_decl.data_expr_ptr;

  end; {case}

  Get_decl_expr := expr_ptr;
end; {function Get_decl_expr}


function Get_decl_name(decl_ptr: decl_ptr_type): string_type;
begin
  Get_decl_name := Get_decl_attributes_name(Get_decl_attributes(decl_ptr));
end; {function Get_decl_name}


{************************************************}
{ routines for allocating and initializing decls }
{************************************************}


procedure Init_data_decl(var data_decl: data_decl_type);
begin
  with data_decl do
    begin
      {*****************}
      { address of data }
      {*****************}
      data_expr_ptr := nil;

      {***************************************}
      { initializing expression and statement }
      {***************************************}
      init_expr_ptr := nil;
      init_stmt_ptr := nil;

      {*******************}
      { declaration flags }
      {*******************}
      static := false;
      native := false;
      native_index := 0;
    end;
end; {procedure Init_data_decl}


procedure Init_decl(decl_ptr: decl_ptr_type;
  kind: decl_kind_type);
begin
  {********************}
  { init common fields }
  {********************}
  decl_ptr^.kind := kind;
  decl_ptr^.decl_info_ptr := nil;
  decl_ptr^.decl_index := 0;
  decl_ptr^.next := nil;

  {**********************}
  { init specific fields }
  {**********************}
  with decl_ptr^ do
    if kind <> null_decl then
      case kind of

        {********************************}
        { user defined type declarations }
        {********************************}
        type_decl:
          type_ptr := nil;

        {*******************}
        { data declarations }
        {*******************}
        boolean_decl..reference_decl:
          begin
            Init_data_decl(data_decl);
            static_struct_type_ref := nil;
          end;

        {*************************}
        { subprogram declarations }
        {*************************}
        code_decl..code_reference_decl:
          begin
            Init_data_decl(code_data_decl);
            code_ptr := nil;
          end;

      end; {case}
end; {procedure Init_decl}


function New_decl(kind: decl_kind_type): decl_ptr_type;
var
  decl_ptr: decl_ptr_type;
  index: integer;
begin
  {******************************}
  { get decl node from free list }
  {******************************}
  if decl_free_list <> nil then
    begin
      decl_ptr := decl_free_list;
      decl_free_list := decl_free_list^.next;
    end
  else
    begin
      index := decl_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new decl block');
          new(decl_block_ptr);
        end;
      decl_ptr := @decl_block_ptr^[index];
    end;

  {************************}
  { increment decl counter }
  {************************}
  decl_counter := decl_counter + 1;

  {**********************}
  { initialize decl node }
  {**********************}
  Init_decl(decl_ptr, kind);

  New_decl := decl_ptr;
end; {function New_decl}


function Decl_count: longint;
begin
  Decl_count := decl_counter;
end; {function Decl_count}


{********************************************************}
{ routines for copying declarations and associated nodes }
{********************************************************}


function Copy_data_decl(data_decl: data_decl_type): data_decl_type;
var
  data_decl2: data_decl_type;
begin
  data_decl2.data_expr_ptr := Copy_expr(data_decl.data_expr_ptr);
  data_decl2.init_expr_ptr := Copy_expr(data_decl.init_expr_ptr);
  data_decl2.init_stmt_ptr := Copy_stmt(data_decl.init_stmt_ptr);

  Copy_data_decl := data_decl2;
end; {procedure Copy_data_decl}


function Copy_decl(decl_ptr: decl_ptr_type): decl_ptr_type;
var
  new_decl_ptr: decl_ptr_type;
begin
  if (decl_ptr <> nil) then
    begin
      new_decl_ptr := New_decl(decl_ptr^.kind);
      new_decl_ptr^ := decl_ptr^;
      new_decl_ptr^.next := nil;
    end
  else
    new_decl_ptr := nil;

  Copy_decl := new_decl_ptr;
end; {function Copy_decl}


function Copy_decls(decl_ptr: decl_ptr_type): decl_ptr_type;
var
  new_decl_ptr: decl_ptr_type;
  first_decl_ptr, last_decl_ptr: decl_ptr_type;
begin
  first_decl_ptr := nil;
  last_decl_ptr := nil;

  while decl_ptr <> nil do
    begin
      new_decl_ptr := Copy_decl(decl_ptr);

      {**********************************}
      { add new decl node to end of list }
      {**********************************}
      if (last_decl_ptr <> nil) then
        begin
          last_decl_ptr^.next := new_decl_ptr;
          last_decl_ptr := new_decl_ptr;
        end
      else
        begin
          first_decl_ptr := new_decl_ptr;
          last_decl_ptr := new_decl_ptr;
        end;

      decl_ptr := decl_ptr^.next;
    end;

  Copy_decls := first_decl_ptr;
end; {function Copy_decls}


{********************************************************}
{ routines for freeing declarations and associated nodes }
{********************************************************}


procedure Free_data_decl(var data_decl: data_decl_type);
begin
  with data_decl do
    begin
      Free_expr(data_expr_ptr);
      Free_expr(init_expr_ptr);
      Free_stmt(init_stmt_ptr);
    end;
end; {procedure Free_data_decl}


procedure Free_decl(var decl_ptr: decl_ptr_type);
begin
  if (decl_ptr <> nil) then
    begin
      {***********************}
      { add decl to free list }
      {***********************}
      decl_ptr^.next := decl_free_list;
      decl_free_list := decl_ptr;
      decl_ptr := nil;

      {************************}
      { decrement decl counter }
      {************************}
      decl_counter := decl_counter - 1;
    end;
end; {procedure Free_decl}


procedure Free_decls(var decl_ptr: decl_ptr_type);
var
  temp: decl_ptr_type;
begin
  while (decl_ptr <> nil) do
    begin
      temp := decl_ptr;
      decl_ptr := decl_ptr^.next;
      Free_decl(temp);
    end;
end; {procedure Free_decls}


{****************************}
{ routines for writing decls }
{****************************}


procedure Write_decl_kind(kind: decl_kind_type);
begin
  case kind of

    {*************************}
    { null or nop declaration }
    {*************************}
    null_decl,

    {********************************}
    { user defined type declarations }
    {********************************}
    type_decl:
      write('type_decl');

    {***********************************}
    { primitive enumerated declarations }
    {***********************************}
    boolean_decl:
      write('boolean_decl');
    char_decl:
      write('char_decl');

    {*********************************}
    { primitive integral declarations }
    {*********************************}
    byte_decl:
      write('byte_decl');
    short_decl:
      write('short_decl');
    integer_decl:
      write('integer_decl');
    long_decl:
      write('long_decl');

    {*******************************}
    { primitive scalar declarations }
    {*******************************}
    scalar_decl:
      write('scalar_decl');
    double_decl:
      write('double_decl');
    complex_decl:
      write('complex_decl');
    vector_decl:
      write('vector_decl');

    {*******************************************}
    { array, struct, and reference declarations }
    {*******************************************}
    array_decl:
      write('array_decl');
    struct_decl:
      write('struct_decl');
    static_struct_decl:
      write('static_struct_decl');
    reference_decl:
      write('reference_decl');

    {*************************}
    { subprogram declarations }
    {*************************}
    code_decl:
      write('code_decl');
    code_array_decl:
      write('code_array_decl');
    code_reference_decl:
      write('code_reference_decl');

  end; {case}
end; {procedure Write_decl_kind}


initialization
  Init_decl_sets;

  {***********************}
  { initialize free lists }
  {***********************}
  decl_free_list := nil;
  decl_info_free_list := nil;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  decl_block_ptr := nil;
  decl_counter := 0;

  decl_info_block_ptr := nil;
  decl_info_counter := 0;

  {*************************}
  { initialize active lists }
  {*************************}
  active_decl_info_list := nil;
  last_active_decl_info_ptr := nil;
end.
