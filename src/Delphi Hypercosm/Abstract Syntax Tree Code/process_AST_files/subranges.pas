unit subranges;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             subranges                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The assignments module contains routines to create      }
{       arrays and struct assignments in abstract syntax        }
{       tree representation.                                    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, expr_attributes, arrays, exprs, type_decls;


{*****************************************}
{ routines for creating array dereferenes }
{*****************************************}
function New_array_subrange_expr(var expr_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  implicit: boolean): expr_ptr_type;
function New_array_expr_subrange(subrange_expr_ptr: expr_ptr_type):
  array_subrange_ptr_type;

{*********************************************}
{ routines for navigating subrange dimensions }
{*********************************************}
procedure Find_first_subrange_dimension(var expr_ptr: expr_ptr_type;
  var array_bounds_ptr: array_bounds_ptr_type;
  var array_derefs: integer);
procedure Find_last_subrange_dimension(var expr_ptr: expr_ptr_type;
  var array_bounds_ptr: array_bounds_ptr_type;
  var array_derefs: integer);
procedure Find_next_subrange_dimension(var expr_ptr: expr_ptr_type;
  var array_bounds_ptr: array_bounds_ptr_type;
  var array_derefs: integer);
procedure Find_prev_subrange_dimension(var expr_ptr: expr_ptr_type;
  var array_bounds_ptr: array_bounds_ptr_type;
  var array_derefs: integer);

{********************************************}
{ routines for creating subrange dimensionss }
{********************************************}
function New_first_subrange_dimension(expr_ptr: expr_ptr_type;
  var subrange_expr_ptr: expr_ptr_type): array_subrange_ptr_type;
function New_last_subrange_dimension(expr_ptr: expr_ptr_type;
  var subrange_expr_ptr: expr_ptr_type): array_subrange_ptr_type;
function New_next_subrange_dimension(array_subrange_ptr:
  array_subrange_ptr_type;
  var subrange_expr_ptr: expr_ptr_type): array_subrange_ptr_type;
function New_prev_subrange_dimension(array_subrange_ptr:
  array_subrange_ptr_type;
  var subrange_expr_ptr: expr_ptr_type): array_subrange_ptr_type;

{***************************************}
{ routines for creating array subranges }
{***************************************}
procedure Complete_array_subrange(expr_ptr: expr_ptr_type);
procedure Make_array_subrange(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Make_array_subranges(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);

{*********************}
{ diagnostic routines }
{*********************}
procedure Write_literal_array_bounds(array_bounds_ptr: array_bounds_ptr_type);
procedure Write_literal_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type);


implementation
uses
  expr_subtrees;


const
  debug = false;


  {***************************************************************}
  {                    multiple array subranges                   }
  {***************************************************************}
  {                                                               }
  {       Array subranges are sort of like dimensioning           }
  {       in reverse.  The first array subrange is applied        }
  {       to the most significant (outermost) array and so on.    }
  {                                                               }
  {       For example, to dereference the array:                  }
  {                      i[1..5][1..10][1..20]                    }
  {       we might use the subrange expression:                   }
  {                       i[1..2][2..3][3..4]                     }
  {                                                               }
  {       Note that the subranges are in the same order as        }
  {       the original array bounds.  When this is translated,    }
  {       we will build a chain of array dereferences with the    }
  {       most significant dereference on the outside, since we   }
  {       recursiely traverse the syntax tree and we must         }
  {       evaluate the most sigificant dereference before we      }
  {       can go on to the next dereference and so forth.         }
  {                                                               }
  {       The base ptr always refers to the array that we are     }
  {       dereferencing and the element ref always refers to      }
  {       the element that we will obtain.                        }
  {                                                               }
  {                                |                              }
  {                                v                              }
  {                           /---------\                         }
  {                -----------|subrange3|->[3..4]       (last     }
  {                |          \---------/               executed) }
  {                |             ^   | base ptr                   }
  {                |             |   |                            }
  {                | element ref |   v                            }
  {                |          /---------\                         }
  {                |          |subrange2|->[2..3]       (second   }
  {                |          \---------/               executed) }
  {                |             ^   | base ptr                   }
  {                |             |   |                            }
  {                | element ref |   v                            }
  {                |          /---------\                         }
  {                |          |subrange3|->[1..2]       (first    }
  {                |          \---------/               executed) }
  {                |                 | base ptr                   }
  {                |                 |                            }
  {                | element ref     v                            }
  {                |            /-----\                           }
  {                \----------->|  i  |                           }
  {                             \-----/                           }
  {                                                               }
  {***************************************************************}


{*****************************************}
{ routines for nagigating subrange bounds }
{*****************************************}


function First_subrange_bounds(expr_ptr: expr_ptr_type;
  var array_derefs: integer): array_bounds_ptr_type;
var
  array_bounds_list_ptr: array_bounds_list_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
  array_index_ptr: array_index_ptr_type;
begin
  array_derefs := 0;

  if expr_ptr^.kind in array_subrange_set then
    begin
      array_bounds_list_ptr := expr_ptr^.subrange_bounds_list_ptr;
      array_index_list_ptr := expr_ptr^.subrange_index_list_ptr;
      if (array_bounds_list_ptr <> nil) and (array_index_list_ptr <> nil) then
        begin
          array_bounds_ptr := array_bounds_list_ptr^.first;
          array_index_ptr := array_index_list_ptr^.first;
          while (array_index_ptr <> array_bounds_ptr^.array_index_ref) do
            begin
              array_index_ptr := array_index_ptr^.next;
              array_derefs := array_derefs + 1;
            end;
        end
      else
        array_bounds_ptr := nil;
    end
  else
    array_bounds_ptr := nil;

  First_subrange_bounds := array_bounds_ptr;
end; {function First_subrange_bounds}


function Last_subrange_bounds(expr_ptr: expr_ptr_type;
  var array_derefs: integer): array_bounds_ptr_type;
var
  array_bounds_list_ptr: array_bounds_list_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
  array_index_ptr: array_index_ptr_type;
begin
  array_derefs := 0;

  if expr_ptr^.kind in array_subrange_set then
    begin
      array_bounds_list_ptr := expr_ptr^.subrange_bounds_list_ptr;
      array_index_list_ptr := expr_ptr^.subrange_index_list_ptr;
      if (array_bounds_list_ptr <> nil) and (array_index_list_ptr <> nil) then
        begin
          array_bounds_ptr := array_bounds_list_ptr^.last;
          array_index_ptr := array_index_list_ptr^.first;
          while (array_index_ptr <> array_bounds_ptr^.array_index_ref) do
            begin
              array_index_ptr := array_index_ptr^.next;
              array_derefs := array_derefs + 1;
            end;
        end
      else
        array_bounds_ptr := nil;
    end
  else
    array_bounds_ptr := nil;

  Last_subrange_bounds := array_bounds_ptr;
end; {function Last_subrange_bounds}


{***********************************************}
{ routines for stepping through subrange bounds }
{***********************************************}


function Next_subrange_bounds(array_bounds_ptr: array_bounds_ptr_type;
  var array_derefs: integer): array_bounds_ptr_type;
var
  array_index_ptr: array_index_ptr_type;
begin
  if array_bounds_ptr <> nil then
    begin
      array_index_ptr := array_bounds_ptr^.array_index_ref;
      array_bounds_ptr := nil;

      {*******************************************************}
      { follow array indices looking for corresponding bounds }
      {*******************************************************}
      while (array_index_ptr^.next <> nil) and (array_bounds_ptr = nil) do
        begin
          array_index_ptr := array_index_ptr^.next;
          array_bounds_ptr := array_index_ptr^.array_bounds_ref;
          array_derefs := array_derefs + 1;
        end;
    end;

  Next_subrange_bounds := array_bounds_ptr;
end; {function Next_subrange_bounds}


function Prev_subrange_bounds(array_bounds_ptr: array_bounds_ptr_type;
  var array_derefs: integer): array_bounds_ptr_type;
var
  array_index_ptr: array_index_ptr_type;
begin
  if array_bounds_ptr <> nil then
    begin
      array_index_ptr := array_bounds_ptr^.array_index_ref;
      array_bounds_ptr := nil;

      {*******************************************************}
      { follow array indices looking for corresponding bounds }
      {*******************************************************}
      while (array_index_ptr <> nil) and (array_bounds_ptr = nil) do
        begin
          array_index_ptr := array_index_ptr^.prev;
          if array_index_ptr <> nil then
            begin
              array_bounds_ptr := array_index_ptr^.array_bounds_ref;
              array_derefs := array_derefs - 1;
            end;
        end;
    end;

  Prev_subrange_bounds := array_bounds_ptr;
end; {function Prev_subrange_bounds}


{**********************************************}
{ routines for navigating subrange expressions }
{**********************************************}


function First_subrange_expr(expr_ptr: expr_ptr_type): expr_ptr_type;
begin
  First_subrange_expr := Last_sub_expr(expr_ptr, base_sub_expr,
    array_subrange_set);
end; {function First_subrange_expr}


function Last_subrange_expr(expr_ptr: expr_ptr_type): expr_ptr_type;
begin
  Last_subrange_expr := Last_super_expr(expr_ptr, array_subrange_set)
end; {function Last_subrange_expr}


function Next_subrange_expr(expr_ptr: expr_ptr_type): expr_ptr_type;
begin
  Next_subrange_expr := expr_ptr^.next_subrange_ref;
end; {function Next_subrange_expr}


function Prev_subrange_expr(expr_ptr: expr_ptr_type): expr_ptr_type;
begin
  Prev_subrange_expr := First_sub_expr(expr_ptr, base_sub_expr,
    array_subrange_set);
end; {function Prev_subrange_expr}


{*********************************************}
{ routines for navigating subrange dimensions }
{*********************************************}


procedure Find_first_subrange_dimension(var expr_ptr: expr_ptr_type;
  var array_bounds_ptr: array_bounds_ptr_type;
  var array_derefs: integer);
begin
  expr_ptr := First_subrange_expr(expr_ptr);

  if expr_ptr <> nil then
    array_bounds_ptr := First_subrange_bounds(expr_ptr, array_derefs)
  else
    begin
      array_bounds_ptr := nil;
      array_derefs := 0;
    end;
end; {procedure Find_first_subrange_dimension}


procedure Find_last_subrange_dimension(var expr_ptr: expr_ptr_type;
  var array_bounds_ptr: array_bounds_ptr_type;
  var array_derefs: integer);
begin
  expr_ptr := Last_subrange_expr(expr_ptr);

  if expr_ptr <> nil then
    array_bounds_ptr := Last_subrange_bounds(expr_ptr, array_derefs)
  else
    begin
      array_bounds_ptr := nil;
      array_derefs := 0;
    end;
end; {procedure Find_last_subrange_dimension}


{***************************************************}
{ routines for stepping through subrange dimensions }
{***************************************************}


procedure Find_next_subrange_dimension(var expr_ptr: expr_ptr_type;
  var array_bounds_ptr: array_bounds_ptr_type;
  var array_derefs: integer);
begin
  {*************************************************}
  { first, look for next dimension in same subrange }
  {*************************************************}
  array_bounds_ptr := Next_subrange_bounds(array_bounds_ptr, array_derefs);

  {****************************************}
  { if not found, then go to next subrange }
  {****************************************}
  if array_bounds_ptr = nil then
    begin
      expr_ptr := Next_subrange_expr(expr_ptr);
      if expr_ptr <> nil then
        array_bounds_ptr := First_subrange_bounds(expr_ptr, array_derefs)
      else
        begin
          array_bounds_ptr := nil;
          array_derefs := 0;
        end;
    end;
end; {procedure Find_next_subrange_dimension}


procedure Find_prev_subrange_dimension(var expr_ptr: expr_ptr_type;
  var array_bounds_ptr: array_bounds_ptr_type;
  var array_derefs: integer);
begin
  {*************************************************}
  { first, look for prev dimension in same subrange }
  {*************************************************}
  array_bounds_ptr := Prev_subrange_bounds(array_bounds_ptr, array_derefs);

  {****************************************}
  { if not found, then go to prev subrange }
  {****************************************}
  if array_bounds_ptr = nil then
    begin
      expr_ptr := Prev_subrange_expr(expr_ptr);
      if expr_ptr <> nil then
        array_bounds_ptr := Last_subrange_bounds(expr_ptr, array_derefs)
      else
        begin
          array_bounds_ptr := nil;
          array_derefs := 0;
        end;
    end;
end; {procedure Find_prev_subrange_dimension}


{*******************************************}
{ routines for creating subrange dimensions }
{*******************************************}


function New_array_base(var expr_ptr: expr_ptr_type): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
begin
  new_expr_ptr := New_expr(array_base);
  new_expr_ptr^.array_base_expr_ref := expr_ptr;
  expr_ptr := new_expr_ptr;

  New_array_base := new_expr_ptr;
end; {function New_array_base}


function New_array_expr_subrange(subrange_expr_ptr: expr_ptr_type):
  array_subrange_ptr_type;
var
  new_array_subrange_ptr: array_subrange_ptr_type;
begin
  {***************************}
  { create new array subrange }
  {***************************}
  new_array_subrange_ptr := New_array_subrange;

  {********************************}
  { create new subrange array base }
  {********************************}
  new_array_subrange_ptr^.array_expr_ptr :=
    forward_expr_ptr_type(subrange_expr_ptr^.subrange_base_ptr);
  new_array_subrange_ptr^.array_base_ref :=
    forward_expr_ref_type(New_array_base(subrange_expr_ptr^.subrange_base_ptr));

  {*******************************}
  { initialize new array subrange }
  {*******************************}
  new_array_subrange_ptr^.array_bounds_ref :=
    subrange_expr_ptr^.subrange_bounds_list_ptr^.first;
  new_array_subrange_ptr^.array_derefs := 0;

  New_array_expr_subrange := new_array_subrange_ptr;
end; {function New_array_expr_subrange}


function New_first_subrange_dimension(expr_ptr: expr_ptr_type;
  var subrange_expr_ptr: expr_ptr_type): array_subrange_ptr_type;
var
  new_array_subrange_ptr: array_subrange_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
  array_derefs: integer;
begin
  subrange_expr_ptr := expr_ptr;
  Find_first_subrange_dimension(subrange_expr_ptr, array_bounds_ptr,
    array_derefs);

  {******************************************}
  { create and initialize new array subrange }
  {******************************************}
  if subrange_expr_ptr <> nil then
    begin
      new_array_subrange_ptr := New_array_expr_subrange(subrange_expr_ptr);

      {****************************************}
      { assign subrange array bounds reference }
      {****************************************}
      new_array_subrange_ptr^.array_bounds_ref := array_bounds_ptr;
      new_array_subrange_ptr^.array_derefs := array_derefs;
    end
  else
    new_array_subrange_ptr := nil;

  New_first_subrange_dimension := new_array_subrange_ptr;
end; {function New_first_subrange_dimension}


function New_last_subrange_dimension(expr_ptr: expr_ptr_type;
  var subrange_expr_ptr: expr_ptr_type): array_subrange_ptr_type;
var
  new_array_subrange_ptr: array_subrange_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
  array_derefs: integer;
begin
  subrange_expr_ptr := expr_ptr;
  Find_last_subrange_dimension(subrange_expr_ptr, array_bounds_ptr,
    array_derefs);

  {******************************************}
  { create and initialize new array subrange }
  {******************************************}
  if subrange_expr_ptr <> nil then
    begin
      new_array_subrange_ptr := New_array_expr_subrange(subrange_expr_ptr);

      {****************************************}
      { assign subrange array bounds reference }
      {****************************************}
      new_array_subrange_ptr^.array_bounds_ref := array_bounds_ptr;
      new_array_subrange_ptr^.array_derefs := array_derefs;
    end
  else
    new_array_subrange_ptr := nil;

  New_last_subrange_dimension := new_array_subrange_ptr;
end; {function New_last_subrange_dimension}


function New_next_subrange_dimension(array_subrange_ptr:
  array_subrange_ptr_type;
  var subrange_expr_ptr: expr_ptr_type): array_subrange_ptr_type;
var
  new_array_subrange_ptr: array_subrange_ptr_type;
  expr_ptr: expr_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
  array_derefs: integer;
begin
  expr_ptr := subrange_expr_ptr;
  array_bounds_ptr := array_subrange_ptr^.array_bounds_ref;
  array_derefs := array_subrange_ptr^.array_derefs;
  Find_next_subrange_dimension(subrange_expr_ptr, array_bounds_ptr,
    array_derefs);

  {******************************************}
  { create and initialize new array subrange }
  {******************************************}
  if subrange_expr_ptr <> nil then
    begin
      {***************************************************}
      { create new or borrow existing subrange array base }
      {***************************************************}
      if subrange_expr_ptr <> expr_ptr then
        new_array_subrange_ptr := New_array_expr_subrange(subrange_expr_ptr)
      else
        begin
          new_array_subrange_ptr := New_array_subrange;
          new_array_subrange_ptr^.array_base_ref :=
            array_subrange_ptr^.array_base_ref;
        end;

      {****************************************}
      { assign subrange array bounds reference }
      {****************************************}
      new_array_subrange_ptr^.array_bounds_ref := array_bounds_ptr;
      new_array_subrange_ptr^.array_derefs := array_derefs;
    end
  else
    new_array_subrange_ptr := nil;

  New_next_subrange_dimension := new_array_subrange_ptr;
end; {function New_next_subrange_dimension}


function New_prev_subrange_dimension(array_subrange_ptr:
  array_subrange_ptr_type;
  var subrange_expr_ptr: expr_ptr_type): array_subrange_ptr_type;
var
  new_array_subrange_ptr: array_subrange_ptr_type;
  expr_ptr: expr_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
  array_derefs: integer;
begin
  expr_ptr := subrange_expr_ptr;
  array_bounds_ptr := array_subrange_ptr^.array_bounds_ref;
  array_derefs := array_subrange_ptr^.array_derefs;
  Find_prev_subrange_dimension(subrange_expr_ptr, array_bounds_ptr,
    array_derefs);

  {******************************************}
  { create and initialize new array subrange }
  {******************************************}
  if subrange_expr_ptr <> nil then
    begin
      {***************************************************}
      { create new or borrow existing subrange array base }
      {***************************************************}
      if subrange_expr_ptr <> expr_ptr then
        new_array_subrange_ptr := New_array_expr_subrange(subrange_expr_ptr)
      else
        begin
          new_array_subrange_ptr := New_array_subrange;
          new_array_subrange_ptr^.array_base_ref :=
            array_subrange_ptr^.array_base_ref;
        end;

      {****************************************}
      { assign subrange array bounds reference }
      {****************************************}
      new_array_subrange_ptr^.array_bounds_ref := array_bounds_ptr;
      new_array_subrange_ptr^.array_derefs := array_derefs;
    end
  else
    new_array_subrange_ptr := nil;

  New_prev_subrange_dimension := new_array_subrange_ptr;
end; {function New_prev_subrange_dimension}


{*****************************************}
{ routines for creating array dereferenes }
{*****************************************}


procedure Write_integer_lit_expr(expr_ptr: expr_ptr_type);
begin
  if expr_ptr <> nil then
    if expr_ptr^.kind = integer_lit then
      write(expr_ptr_type(expr_ptr)^.integer_val: 1)
    else
      write('?');
end; {procedure Write_integer_lit_expr}


procedure Write_literal_array_bounds(array_bounds_ptr: array_bounds_ptr_type);
begin
  if array_bounds_ptr <> nil then
    with array_bounds_ptr^ do
      begin
        Write_integer_lit_expr(expr_ptr_type(min_expr_ptr));
        write('..');
        Write_integer_lit_expr(expr_ptr_type(max_expr_ptr));
      end;
end; {procedure Write_literal_array_bounds}


procedure Write_literal_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type);
var
  array_bounds_ptr: array_bounds_ptr_type;
begin
  if array_bounds_list_ptr <> nil then
    begin
      write('[');
      array_bounds_ptr := array_bounds_list_ptr^.first;
      while array_bounds_ptr <> nil do
        begin
          Write_literal_array_bounds(array_bounds_ptr);
          if array_bounds_ptr^.next <> nil then
            write(', ');
          array_bounds_ptr := array_bounds_ptr^.next;
        end; {while}
      write(']');
    end; {if}
end; {procedure Write_literal_array_bounds_list}


function Prim_array_subrange_expr_kind(type_kind: type_kind_type):
  expr_kind_type;
var
  expr_kind: expr_kind_type;
begin
  case type_kind of

    {****************************}
    { enumerated array subranges }
    {****************************}
    type_boolean:
      expr_kind := boolean_array_subrange;
    type_char:
      expr_kind := char_array_subrange;

    {*************************}
    { integer array subranges }
    {*************************}
    type_byte:
      expr_kind := byte_array_subrange;
    type_short:
      expr_kind := short_array_subrange;
    type_integer:
      expr_kind := integer_array_subrange;
    type_long:
      expr_kind := long_array_subrange;

    {******************}
    { scalar subranges }
    {******************}
    type_scalar:
      expr_kind := scalar_array_subrange;
    type_double:
      expr_kind := double_array_subrange;
    type_complex:
      expr_kind := complex_array_subrange;
    type_vector:
      expr_kind := vector_array_subrange;

  else
    expr_kind := error_expr;
  end; {case}

  Prim_array_subrange_expr_kind := expr_kind;
end; {function Prim_array_subrange_expr_kind}


function Array_subrange_expr_kind(type_attributes_ptr:
  type_attributes_ptr_type): expr_kind_type;
var
  expr_kind: expr_kind_type;
begin
  case type_attributes_ptr^.kind of

    {***************************}
    { primitive array subranges }
    {***************************}
    type_boolean..type_vector:
      expr_kind := Prim_array_subrange_expr_kind(type_attributes_ptr^.kind);

    {***********************************}
    { user defined type array subranges }
    {***********************************}
    type_enum:
      expr_kind := integer_array_subrange;
    type_alias:
      expr_kind :=
        Array_subrange_expr_kind(type_attributes_ptr^.alias_type_attributes_ptr);
    type_array:
      expr_kind := array_array_subrange;
    type_struct, type_class:
      if type_attributes_ptr^.static then
        expr_kind := static_struct_array_subrange
      else
        expr_kind := struct_array_subrange;
    type_class_alias:
      expr_kind :=
        Array_subrange_expr_kind(type_attributes_ptr^.class_alias_type_attributes_ptr);
    type_code:
      expr_kind := proto_array_subrange;

    {***********************************}
    { general reference array subranges }
    {***********************************}
    type_reference:
      expr_kind := reference_array_subrange;

  else
    expr_kind := error_expr;
  end; {case}

  Array_subrange_expr_kind := expr_kind;
end; {function Array_subrange_expr_kind}


function New_array_subrange_expr(var expr_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  implicit: boolean): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
  base_subrange_ptr: expr_ptr_type;
begin
  new_expr_ptr := New_expr(Array_subrange_expr_kind(type_attributes_ptr));
  new_expr_ptr^.implicit_subrange := implicit;

  if new_expr_ptr^.kind = static_struct_array_subrange then
    new_expr_ptr^.subrange_static_struct_type_ref :=
      forward_type_ref_type(Get_type_decl(type_attributes_ptr));

  {********************}
  { find last subrange }
  {********************}
  base_subrange_ptr := Last_subrange_expr(expr_ptr);

  if (expr_ptr^.kind in array_deref_set) then
    begin
      case expr_ptr^.kind of
        boolean_array_deref..reference_array_deref:
          begin
            new_expr_ptr^.subrange_base_ptr := expr_ptr;
            new_expr_ptr^.subrange_element_ref := expr_ptr^.deref_element_ref;
            expr_ptr^.subrange_element_ref := new_expr_ptr;
            expr_ptr := new_expr_ptr;
          end;
        boolean_array_subrange..reference_array_subrange:
          begin
            new_expr_ptr^.subrange_base_ptr := expr_ptr;
            new_expr_ptr^.subrange_element_ref :=
              expr_ptr^.subrange_element_ref;
            expr_ptr^.subrange_element_ref := new_expr_ptr;
            expr_ptr := new_expr_ptr;
          end;
      end; {case}
    end
  else
    begin
      new_expr_ptr^.subrange_base_ptr := expr_ptr;
      new_expr_ptr^.subrange_element_ref := expr_ptr;
      expr_ptr := new_expr_ptr;
    end;

  {*********************************************************}
  { set last subrange's next subrange field to new subrange }
  {*********************************************************}
  if base_subrange_ptr <> nil then
    base_subrange_ptr^.next_subrange_ref := new_expr_ptr;

  New_array_subrange_expr := new_expr_ptr;
end; {function New_array_subrange_expr}


{***************************************}
{ routines for creating array subranges }
{***************************************}


procedure Complete_array_subrange(expr_ptr: expr_ptr_type);
var
  dimensions, counter: integer;
  bounds_dimensions, index_dimensions: integer;
begin
  if (expr_ptr^.kind in array_subrange_set) then
    begin
      dimensions := expr_ptr^.subrange_index_list_ptr^.max_indices;

      if dimensions <> 0 then
        begin
          if (expr_ptr^.subrange_bounds_list_ptr = nil) then
            expr_ptr^.subrange_bounds_list_ptr := New_array_bounds_list;

          bounds_dimensions := expr_ptr^.subrange_bounds_list_ptr^.dimensions;
          index_dimensions := expr_ptr^.subrange_index_list_ptr^.indices;

          for counter := bounds_dimensions + index_dimensions + 1 to dimensions
            do
            Add_array_subrange(expr_ptr^.subrange_bounds_list_ptr,
              expr_ptr^.subrange_index_list_ptr, New_array_bounds);
        end;
    end;
end; {procedure Complete_array_subrange}


procedure Make_array_subrange(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
  new_expr_ptr: expr_ptr_type;
  dimensions, counter: integer;
begin
  {**************************}
  { find subrange dimensions }
  {**************************}
  type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
  dimensions := type_attributes_ptr^.relative_dimensions;

  {******************************}
  { dereference array attributes }
  {******************************}
  expr_attributes_ptr^.dimensions := expr_attributes_ptr^.dimensions -
    dimensions;
  expr_attributes_ptr^.alias_type_attributes_ptr :=
    type_attributes_ptr^.element_type_attributes_ptr;
  expr_attributes_ptr^.type_attributes_ptr :=
    Unalias_type_attributes(expr_attributes_ptr^.alias_type_attributes_ptr);

  {*********************}
  { create new subrange }
  {*********************}
  new_expr_ptr := New_array_subrange_expr(expr_ptr,
    expr_attributes_ptr^.type_attributes_ptr, true);
  new_expr_ptr^.subrange_bounds_list_ptr := New_array_bounds_list;
  new_expr_ptr^.subrange_index_list_ptr := New_array_index_list(dimensions);

  if debug then
    writeln('subrange dimensions = ', dimensions);

  {************************}
  { create empty subranges }
  {************************}
  for counter := 1 to dimensions do
    with new_expr_ptr^ do
      Add_array_subrange(subrange_bounds_list_ptr, subrange_index_list_ptr,
        New_array_bounds);
end; {procedure Make_array_subrange}


procedure Make_array_subranges(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
begin
  while expr_attributes_ptr^.type_attributes_ptr^.kind = type_array do
    Make_array_subrange(expr_ptr, expr_attributes_ptr);
end; {procedure Make_array_subranges}


end.
