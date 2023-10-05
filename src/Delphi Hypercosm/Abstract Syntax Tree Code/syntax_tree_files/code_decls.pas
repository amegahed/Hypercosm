unit code_decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             code_decls                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The code_decls module defines the code declarations     }
{       used in the abstract syntax tree, the internal          }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  new_memory, addr_types, code_types, decl_attributes, exprs, stmts, decls;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}
{                       code declarations                       }
{***************************************************************}


{***************************************************************}
{                  types of method declarations                 }
{***************************************************************}
{                                                               }
{       actual_decl -                                           }
{              subprogram decl includes implementation code     }
{                                                               }
{       forward_decl -                                          }
{              a unique declaration definining the              }
{              implementation will follow                       }
{                                                               }
{       proto_decl -                                            }
{              a pointer to an non unique actual                }
{              declaration which contains the implementation.   }
{                                                               }
{       native_decl -                                           }
{              a forward declaration for a method for which     }
{              the implimentation is specified outside of       }
{              the interpreter code.                            }
{                                                               }
{***************************************************************}


{***************************************************************}
{                       types of methods                        }
{***************************************************************}
{                                                               }
{       void_method -                                           }
{              a method which does not require a pointer        }
{              to a class instance variable.                    }
{                                                               }
{       static_method -                                         }
{              declaration which is bound to a variable         }
{              at compile time.                                 }
{                                                               }
{       virtual_method -                                        }
{              declaration which is bound to a variable         }
{              at run time based upon the type of the           }
{              variable.                                        }
{                                                               }
{       abstract_method -                                       }
{              declaration which is later overridden by         }
{              either a static or virtual method.               }
{                                                               }
{       final_method -                                          }
{              similar to a virtual method except that it       }
{              may not be overridden.                           }
{                                                               }
{***************************************************************}


type
  {******************************}
  { types of method declarations }
  {******************************}
  code_decl_kind_type = (actual_decl, forward_decl, proto_decl, native_decl);
  code_decl_kind_set_type = set of code_decl_kind_type;


  {******************}
  { types of methods }
  {******************}
  method_kind_type = (void_method, static_method, virtual_method,
    abstract_method, final_method);
  method_kind_set_type = set of method_kind_type;


  {**************************************}
  { the abstract syntax tree declaration }
  {**************************************}
  code_ptr_type = ^code_type;
  code_ref_type = code_ptr_type;
  forward_code_data_ptr_type = ptr_type;


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
  code_type = record

    {*****************************}
    { code declaration attributes }
    {*****************************}
    kind: code_kind_type;
    decl_kind: code_decl_kind_type;
    method_kind: method_kind_type;
    reference_method: boolean;

    {*******************************}
    { declaration's computed values }
    {*******************************}
    decl_static_link: stack_index_type;
    decl_static_level: integer;
    stack_frame_size: integer;
    params_size: integer;
    method_id: integer;

    {************************}
    { declaration references }
    {************************}
    class_type_ref: forward_type_ref_type;
    code_decl_ref: decl_ref_type;
    forward_code_ref: code_ref_type;
    actual_code_ref: code_ref_type;

    {*******************}
    { initial paramters }
    {*******************}
    implicit_param_decls_ptr: decl_ptr_type;
    initial_param_decls_ptr: decl_ptr_type;

    {*********************}
    { optional parameters }
    {*********************}
    optional_param_decls_ptr: decl_ptr_type;
    optional_param_stmts_ptr: stmt_ptr_type;

    {*******************}
    { return parameters }
    {*******************}
    return_param_decls_ptr: decl_ptr_type;
    param_free_stmts_ptr: stmt_ptr_type;

    {****************}
    { implementation }
    {****************}
    local_decls_ptr: decl_ptr_type;
    local_stmts_ptr: stmt_ptr_type;

    code_data_ptr: forward_code_data_ptr_type;
    code_index: longint;
    next: code_ptr_type;
  end; {code_type}


var
  static_method_set, dynamic_method_set, overrideable_method_set:
  method_kind_set_type;


{************************************************}
{ routines for allocating and initializing codes }
{************************************************}
function New_code(kind: code_kind_type;
  decl_ptr: decl_ptr_type): code_ptr_type;
procedure Init_code(code_ptr: code_ptr_type;
  kind: code_kind_type);
function Copy_code(code_ptr: code_ptr_type): code_ptr_type;
function Copy_codes(code_ptr: code_ptr_type): code_ptr_type;
procedure Free_code(var code_ptr: code_ptr_type);
procedure Free_codes(var code_ptr: code_ptr_type);
function Code_count: longint;

{*****************************************}
{ routine for examining method attributes }
{*****************************************}
function Found_code_attributes(decl_attributes_ptr: decl_attributes_ptr_type;
  code_kind_set: code_kind_set_type): boolean;
function Found_method_attributes(decl_attributes_ptr: decl_attributes_ptr_type;
  code_kind_set: code_kind_set_type): boolean;
function Found_proto_attributes(decl_attributes_ptr: decl_attributes_ptr_type;
  code_kind_set: code_kind_set_type): boolean;

{***************************************}
{ routines for writing enumerated types }
{***************************************}
procedure Write_code_decl_kind(kind: code_decl_kind_type);
procedure Write_method_kind(kind: method_kind_type);


implementation
uses
  errors, data_types, code_attributes, type_attributes;


const
  block_size = 512;
  memory_alert = false;
  verbose = false;


type
  code_block_ptr_type = ^code_block_type;
  code_block_type = array[0..block_size] of code_type;


var
  code_free_list: code_ptr_type;
  code_block_ptr: code_block_ptr_type;
  code_counter: longint;


procedure Init_code_sets;
begin
  static_method_set := [void_method, static_method];
  dynamic_method_set := [virtual_method, abstract_method, final_method];
  overrideable_method_set := [virtual_method, abstract_method];
end; {procedure Init_code_sets}


{************************************************}
{ routines for allocating and initializing codes }
{************************************************}


procedure Init_code(code_ptr: code_ptr_type;
  kind: code_kind_type);
begin
  code_ptr^.kind := kind;
  with code_ptr^ do
    begin
      {*****************************}
      { code declaration attributes }
      {*****************************}
      decl_kind := actual_decl;
      method_kind := void_method;
      reference_method := false;

      {*******************************}
      { declaration's computed values }
      {*******************************}
      decl_static_link := 0;
      decl_static_level := 0;
      stack_frame_size := 0;
      params_size := 0;
      method_id := 0;

      {************************}
      { declaration references }
      {************************}
      code_decl_ref := nil;
      class_type_ref := nil;
      forward_code_ref := nil;
      actual_code_ref := nil;

      {*******************}
      { initial paramters }
      {*******************}
      implicit_param_decls_ptr := nil;
      initial_param_decls_ptr := nil;

      {*********************}
      { optional parameters }
      {*********************}
      optional_param_decls_ptr := nil;
      optional_param_stmts_ptr := nil;

      {*******************}
      { return parameters }
      {*******************}
      return_param_decls_ptr := nil;
      param_free_stmts_ptr := nil;

      {****************}
      { implementation }
      {****************}
      local_decls_ptr := nil;
      local_stmts_ptr := nil;

      code_data_ptr := nil;
      code_index := 0;
      next := nil;
    end;
end; {procedure Init_code}


function New_code(kind: code_kind_type;
  decl_ptr: decl_ptr_type): code_ptr_type;
var
  code_ptr: code_ptr_type;
  index: integer;
begin
  {******************************}
  { get code node from free list }
  {******************************}
  if code_free_list <> nil then
    begin
      code_ptr := code_free_list;
      code_free_list := code_free_list^.next;
    end
  else
    begin
      index := code_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new code block');
          new(code_block_ptr);
        end;
      code_ptr := @code_block_ptr^[index];
    end;

  {************************}
  { increment code counter }
  {************************}
  code_counter := code_counter + 1;

  {**********************}
  { initialize code node }
  {**********************}
  Init_code(code_ptr, kind);

  {*******************}
  { set back pointers }
  {*******************}
  code_ptr^.code_decl_ref := decl_ptr;
  if decl_ptr <> nil then
    decl_ptr^.code_ptr := forward_code_ptr_type(code_ptr);

  New_code := code_ptr;
end; {function New_code}


function Code_count: longint;
begin
  Code_count := code_counter;
end; {function Code_count}


{********************************************************}
{ routines for copying declarations and associated nodes }
{********************************************************}


function Copy_code(code_ptr: code_ptr_type): code_ptr_type;
var
  new_code_ptr: code_ptr_type;
begin
  if (code_ptr <> nil) then
    begin
      new_code_ptr := New_code(code_ptr^.kind, nil);
      new_code_ptr^ := code_ptr^;
      new_code_ptr^.next := nil;
    end
  else
    new_code_ptr := nil;

  Copy_code := new_code_ptr;
end; {function Copy_code}


function Copy_codes(code_ptr: code_ptr_type): code_ptr_type;
var
  new_code_ptr: code_ptr_type;
  first_code_ptr, last_code_ptr: code_ptr_type;
begin
  first_code_ptr := nil;
  last_code_ptr := nil;

  while code_ptr <> nil do
    begin
      new_code_ptr := Copy_code(code_ptr);

      {**********************************}
      { add new code node to end of list }
      {**********************************}
      if (last_code_ptr <> nil) then
        begin
          last_code_ptr^.next := new_code_ptr;
          last_code_ptr := new_code_ptr;
        end
      else
        begin
          first_code_ptr := new_code_ptr;
          last_code_ptr := new_code_ptr;
        end;

      code_ptr := code_ptr^.next;
    end;

  Copy_codes := first_code_ptr;
end; {function Copy_codes}


{*************************************************************}
{ routines for freeing code declarations and associated nodes }
{*************************************************************}


procedure Free_code(var code_ptr: code_ptr_type);
begin
  if (code_ptr <> nil) then
    begin
      {***********************}
      { add code to free list }
      {***********************}
      code_ptr^.next := code_free_list;
      code_free_list := code_ptr;
      code_ptr := nil;

      {************************}
      { decrement code counter }
      {************************}
      code_counter := code_counter - 1;
    end;
end; {procedure Free_code}


procedure Free_codes(var code_ptr: code_ptr_type);
var
  temp: code_ptr_type;
begin
  while (code_ptr <> nil) do
    begin
      temp := code_ptr;
      code_ptr := code_ptr^.next;
      Free_code(temp);
    end;
end; {procedure Free_codes}


{*****************************************}
{ routine for examining method attributes }
{*****************************************}


function Found_code_attributes(decl_attributes_ptr: decl_attributes_ptr_type;
  code_kind_set: code_kind_set_type): boolean;
var
  type_attributes_ptr: type_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
  found: boolean;
begin
  found := false;

  if decl_attributes_ptr <> nil then
    begin
      type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;
      if type_attributes_ptr^.kind = type_code then
        begin
          code_attributes_ptr := type_attributes_ptr^.code_attributes_ptr;
          if code_attributes_ptr^.kind in code_kind_set then
            found := true;
        end;
    end;

  Found_code_attributes := found;
end; {function Found_code_attributes}


function Found_method_attributes(decl_attributes_ptr: decl_attributes_ptr_type;
  code_kind_set: code_kind_set_type): boolean;
var
  type_attributes_ptr: type_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
  decl_ptr: decl_ptr_type;
  code_ptr: code_ptr_type;
  found: boolean;
begin
  found := false;

  if decl_attributes_ptr <> nil then
    begin
      type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;
      if type_attributes_ptr^.kind = type_code then
        begin
          code_attributes_ptr := type_attributes_ptr^.code_attributes_ptr;
          if code_attributes_ptr^.kind in code_kind_set then
            begin
              decl_ptr := decl_ptr_type(decl_attributes_ptr^.decl_ref);
              code_ptr := code_ptr_type(decl_ptr^.code_ptr);
              if code_ptr^.decl_kind <> proto_decl then
                found := true;
            end;
        end;
    end;

  Found_method_attributes := found;
end; {function Found_method_attributes}


function Found_proto_attributes(decl_attributes_ptr: decl_attributes_ptr_type;
  code_kind_set: code_kind_set_type): boolean;
var
  type_attributes_ptr: type_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
  decl_ptr: decl_ptr_type;
  code_ptr: code_ptr_type;
  found: boolean;
begin
  found := false;

  if decl_attributes_ptr <> nil then
    begin
      type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;
      if type_attributes_ptr^.kind = type_code then
        begin
          code_attributes_ptr := type_attributes_ptr^.code_attributes_ptr;
          if code_attributes_ptr^.kind in code_kind_set then
            begin
              decl_ptr := decl_ptr_type(decl_attributes_ptr^.decl_ref);
              code_ptr := code_ptr_type(decl_ptr^.code_ptr);
              if code_ptr^.decl_kind = proto_decl then
                found := true;
            end;
        end;
    end;

  Found_proto_attributes := found;
end; {function Found_proto_attributes}


{***************************************}
{ routines for writing enumerated types }
{***************************************}


procedure Write_code_decl_kind(kind: code_decl_kind_type);
begin
  case kind of
    actual_decl:
      write('actual_decl');
    forward_decl:
      write('forward_decl');
    proto_decl:
      write('proto_decl');
    native_decl:
      write('native_decl');
  end; {case}
end; {procedure Write_code_decl_kind}


procedure Write_method_kind(kind: method_kind_type);
begin
  case kind of
    void_method:
      write('void_method');
    static_method:
      write('static_method');
    virtual_method:
      write('virtual_method');
    abstract_method:
      write('abstract_method');
    final_method:
      write('final_method');
  end; {case}
end; {procedure Write_method_kind}


initialization
  Init_code_sets;

  {***********************}
  { initialize free lists }
  {***********************}
  code_free_list := nil;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  code_block_ptr := nil;
  code_counter := 0;
end.
