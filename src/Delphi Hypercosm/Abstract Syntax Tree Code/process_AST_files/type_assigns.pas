unit type_assigns;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            type_assigns               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The assignments module contains routines to create      }
{       general assignment statements in abstract syntax        }
{       tree representation.                                    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, exprs, stmts;


{*********************************************}
{ routines for creating reference assignments }
{*********************************************}
function Prim_assign_kind(type_kind: type_kind_type): stmt_kind_type;
function New_prim_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
  type_kind: type_kind_type): stmt_ptr_type;

{*********************************************}
{ routines for creating reference assignments }
{*********************************************}
function New_array_ptr_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type):
  stmt_ptr_type;
function New_struct_ptr_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type):
  stmt_ptr_type;
function New_proto_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
  static_level: integer): stmt_ptr_type;
function New_reference_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type):
  stmt_ptr_type;

{***************************************************}
{ routines for creating general purpose assignments }
{***************************************************}
function New_type_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type): stmt_ptr_type;


implementation
uses
  expr_attributes;


{*********************************************}
{ routines for creating reference assignments }
{*********************************************}


function Prim_assign_kind(type_kind: type_kind_type): stmt_kind_type;
var
  stmt_kind: stmt_kind_type;
begin
  stmt_kind := null_stmt;

  case type_kind of

    {************************}
    { enumerated assignments }
    {************************}
    type_boolean:
      stmt_kind := boolean_assign;
    type_char:
      stmt_kind := char_assign;

    {*******************************************}
    { routines for creating integer assignments }
    {*******************************************}
    type_byte:
      stmt_kind := byte_assign;
    type_short:
      stmt_kind := short_assign;
    type_integer:
      stmt_kind := integer_assign;
    type_long:
      stmt_kind := long_assign;

    {******************************************}
    { routines for creating scalar assignments }
    {******************************************}
    type_scalar:
      stmt_kind := scalar_assign;
    type_double:
      stmt_kind := double_assign;
    type_complex:
      stmt_kind := complex_assign;
    type_vector:
      stmt_kind := vector_assign;

  end; {case}

  Prim_assign_kind := stmt_kind;
end; {function Prim_assign_kind}


function New_prim_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
  type_kind: type_kind_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := New_stmt(Prim_assign_kind(type_kind));
  stmt_ptr^.lhs_data_ptr := lhs_data_ptr;
  stmt_ptr^.rhs_expr_ptr := rhs_expr_ptr;

  New_prim_assign := stmt_ptr;
end; {function New_prim_assign}


{*********************************************}
{ routines for creating reference assignments }
{*********************************************}


function New_array_ptr_assign(lhs_data_ptr: expr_ptr_type;
  rhs_expr_ptr: expr_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := New_stmt(array_ptr_assign);
  stmt_ptr^.lhs_data_ptr := lhs_data_ptr;
  stmt_ptr^.rhs_expr_ptr := rhs_expr_ptr;

  New_array_ptr_assign := stmt_ptr;
end; {function New_array_ptr_assign}


function New_struct_ptr_assign(lhs_data_ptr: expr_ptr_type;
  rhs_expr_ptr: expr_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := New_stmt(struct_ptr_assign);
  stmt_ptr^.lhs_data_ptr := lhs_data_ptr;
  stmt_ptr^.rhs_expr_ptr := rhs_expr_ptr;

  New_struct_ptr_assign := stmt_ptr;
end; {function New_struct_ptr_assign}


function New_proto_assign(lhs_data_ptr: expr_ptr_type;
  rhs_expr_ptr: expr_ptr_type;
  static_level: integer): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := New_stmt(proto_assign);
  stmt_ptr^.lhs_data_ptr := lhs_data_ptr;
  stmt_ptr^.rhs_expr_ptr := rhs_expr_ptr;
  stmt_ptr^.static_level := static_level;

  New_proto_assign := stmt_ptr;
end; {function New_proto_assign}


function New_reference_assign(lhs_data_ptr: expr_ptr_type;
  rhs_expr_ptr: expr_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := New_stmt(reference_assign);
  stmt_ptr^.lhs_data_ptr := lhs_data_ptr;
  stmt_ptr^.rhs_expr_ptr := rhs_expr_ptr;

  New_reference_assign := stmt_ptr;
end; {function New_reference_assign}


{***************************************************}
{ routines for creating general purpose assignments }
{***************************************************}


function New_type_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  static_level: integer;
begin
  stmt_ptr := nil;
  
  case type_attributes_ptr^.kind of

    {***********************}
    { primitive assignments }
    {***********************}
    type_boolean..type_vector:
      stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr,
        type_attributes_ptr^.kind);

    {*******************************}
    { user defined type assignments }
    {*******************************}
    type_enum:
      stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr, type_integer);
    type_alias:
      stmt_ptr := New_type_assign(lhs_data_ptr, rhs_expr_ptr,
        type_attributes_ptr^.alias_type_attributes_ptr);
    type_array:
      stmt_ptr := New_array_ptr_assign(lhs_data_ptr, rhs_expr_ptr);
    type_struct, type_class:
      stmt_ptr := New_struct_ptr_assign(lhs_data_ptr, rhs_expr_ptr);
    type_class_alias:
      stmt_ptr := New_type_assign(lhs_data_ptr, rhs_expr_ptr,
        type_attributes_ptr^.class_alias_type_attributes_ptr);
    type_code:
      begin
        expr_attributes_ptr := Get_expr_attributes(lhs_data_ptr);
        static_level := expr_attributes_ptr^.decl_attributes_ptr^.static_level;
        stmt_ptr := New_proto_assign(lhs_data_ptr, rhs_expr_ptr, static_level);
      end;

    {*******************************}
    { general reference assignments }
    {*******************************}
    type_reference:
      stmt_ptr := New_reference_assign(lhs_data_ptr, rhs_expr_ptr);

  end; {case}

  New_type_assign := stmt_ptr;
end; {function New_type_assign}


end.
