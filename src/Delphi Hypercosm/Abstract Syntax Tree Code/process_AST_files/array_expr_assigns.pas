unit array_expr_assigns;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm         array_expr_assigns            3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The assignments module contains routines to create      }
{       array assignment statements in abstract syntax          }
{       tree representation.                                    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  exprs, stmts;


{*************************************************}
{ routines for creating general array assignments }
{*************************************************}
function New_array_value_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type):
  stmt_ptr_type;

{****************************************************}
{ routines for creating array expression assignments }
{****************************************************}
function New_array_expr_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type):
  stmt_ptr_type;


implementation
uses
  errors, type_attributes, expr_attributes, arrays, type_decls, subranges,
  array_assigns;


const
  debug = false;


  {*************************************************}
  { routines for creating general array assignments }
  {*************************************************}


function New_array_value_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type):
  stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  if rhs_expr_ptr^.kind in array_element_set then
    stmt_ptr := New_array_expr_assign(lhs_data_ptr, rhs_expr_ptr)
  else
    stmt_ptr := New_array_assign(lhs_data_ptr, rhs_expr_ptr);

  New_array_value_assign := stmt_ptr;
end; {function New_array_value_assign}


{****************************************************}
{ routines for creating array expression assignments }
{****************************************************}


function Prim_array_expr_assign_stmt_kind(type_kind: type_kind_type):
  stmt_kind_type;
var
  stmt_kind: stmt_kind_type;
begin
  case type_kind of

    {*****************************************}
    { enumerated array expression assignments }
    {*****************************************}
    type_boolean:
      stmt_kind := boolean_array_expr_assign;
    type_char:
      stmt_kind := char_array_expr_assign;

    {**************************************}
    { integer array expression assignments }
    {**************************************}
    type_byte:
      stmt_kind := byte_array_expr_assign;
    type_short:
      stmt_kind := short_array_expr_assign;
    type_integer:
      stmt_kind := integer_array_expr_assign;
    type_long:
      stmt_kind := long_array_expr_assign;

    {*************************************}
    { scalar array expression assignments }
    {*************************************}
    type_scalar:
      stmt_kind := scalar_array_expr_assign;
    type_double:
      stmt_kind := double_array_expr_assign;
    type_complex:
      stmt_kind := complex_array_expr_assign;
    type_vector:
      stmt_kind := vector_array_expr_assign;

  else
    stmt_kind := null_stmt;
  end; {case}

  Prim_array_expr_assign_stmt_kind := stmt_kind;
end; {function Prim_array_expr_assign_stmt_kind}


function Array_expr_assign_stmt_kind(type_attributes_ptr:
  type_attributes_ptr_type): stmt_kind_type;
var
  stmt_kind: stmt_kind_type;
begin
  case type_attributes_ptr^.kind of

    {****************************************}
    { primitive array expression assignments }
    {****************************************}
    type_boolean..type_vector:
      stmt_kind := Prim_array_expr_assign_stmt_kind(type_attributes_ptr^.kind);

    {************************************************}
    { user defined type array expression assignments }
    {************************************************}
    type_enum:
      stmt_kind := integer_array_expr_assign;
    type_alias:
      stmt_kind :=
        Array_expr_assign_stmt_kind(type_attributes_ptr^.alias_type_attributes_ptr);
    type_array:
      stmt_kind := array_array_expr_assign;
    type_struct, type_class:
      stmt_kind := struct_array_expr_assign;
    type_class_alias:
      stmt_kind :=
        Array_expr_assign_stmt_kind(type_attributes_ptr^.class_alias_type_attributes_ptr);
    type_code:
      stmt_kind := proto_array_expr_assign;

    {************************************************}
    { general reference array expression assignments }
    {************************************************}
    type_reference:
      stmt_kind := reference_array_expr_assign;

  else
    stmt_kind := null_stmt;
  end; {case}

  Array_expr_assign_stmt_kind := stmt_kind;
end; {function Array_expr_assign_stmt_kind}


function New_array_expr_assign_stmt(type_attributes_ptr:
  type_attributes_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := New_stmt(Array_expr_assign_stmt_kind(type_attributes_ptr));

  with stmt_ptr^ do
    if kind in [struct_array_expr_assign, static_struct_array_expr_assign] then
      case kind of
        struct_array_expr_assign:
          array_expr_struct_new_ptr :=
            New_implicit_struct_new(type_attributes_ptr);
        static_struct_array_expr_assign:
          array_expr_static_struct_type_ref :=
            forward_type_ref_type(Get_type_decl(type_attributes_ptr));
      end; {case}

  New_array_expr_assign_stmt := stmt_ptr;
end; {function New_array_expr_assign_stmt}


function New_array_expr_assign(lhs_data_ptr: expr_ptr_type;
  rhs_expr_ptr: expr_ptr_type): stmt_ptr_type;
var
  stmt_ptr, last_stmt_ptr, new_stmt_ptr: stmt_ptr_type;
  lhs_expr_attributes_ptr, rhs_expr_attributes_ptr: expr_attributes_ptr_type;
  lhs_dimensions, rhs_dimensions, dimensions: integer;
  lhs_array_subrange_ptr: array_subrange_ptr_type;
  lhs_subrange_expr_ptr, element_expr_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  last_subrange_expr_ptr: expr_ptr_type;
begin
  {*************************************}
  { get left and right array attributes }
  {*************************************}
  lhs_expr_attributes_ptr := Get_expr_attributes(lhs_data_ptr);
  rhs_expr_attributes_ptr := Get_expr_attributes(rhs_expr_ptr);
  lhs_dimensions := lhs_expr_attributes_ptr^.dimensions;
  rhs_dimensions := rhs_expr_attributes_ptr^.dimensions;
  type_attributes_ptr :=
    Base_type_attributes(lhs_expr_attributes_ptr^.type_attributes_ptr);

  if (lhs_dimensions <> rhs_dimensions) then
    begin
      Error('array dimensions do not match');
      dimensions := 0;
    end
  else
    dimensions := lhs_dimensions;

  if debug then
    writeln('dimensions = ', dimensions);

  {************************}
  { add implicit subranges }
  {************************}
  Complete_array_subrange(lhs_data_ptr);

  {****************************}
  { find first subrange arrays }
  {****************************}
  lhs_array_subrange_ptr := New_first_subrange_dimension(lhs_data_ptr,
    lhs_subrange_expr_ptr);

  if debug then
    begin
      write('first subrange = ');
      Write_literal_array_bounds(lhs_array_subrange_ptr^.array_bounds_ref);
      writeln;
    end;

  {*********************************}
  { create array element expression }
  {*********************************}
  element_expr_ptr := New_expr(element_expr);
  element_expr_ptr^.element_array_expr_ptr := rhs_expr_ptr;

  stmt_ptr := nil;
  last_stmt_ptr := nil;
  last_subrange_expr_ptr := nil;
  while dimensions > 0 do
    begin
      {**********************************}
      { add implicit derefs if necessary }
      {**********************************}
      if lhs_array_subrange_ptr = nil then
        begin
          Make_array_subrange(lhs_data_ptr, lhs_expr_attributes_ptr);
          lhs_subrange_expr_ptr := lhs_data_ptr;
          lhs_array_subrange_ptr :=
            New_array_expr_subrange(lhs_subrange_expr_ptr);
        end;

      {******************************}
      { create array expr assignment }
      {******************************}
      if lhs_subrange_expr_ptr <> last_subrange_expr_ptr then
        begin
          if dimensions =
            lhs_subrange_expr_ptr^.subrange_bounds_list_ptr^.dimensions then
            new_stmt_ptr := New_array_expr_assign_stmt(type_attributes_ptr)
          else
            new_stmt_ptr := New_stmt(array_array_expr_assign);

          {************************************************}
          { initialize new array expr assignment statement }
          {************************************************}
          new_stmt_ptr^.array_expr_subrange_ptr := lhs_array_subrange_ptr;
          new_stmt_ptr^.array_expr_bounds_list_ref :=
            lhs_subrange_expr_ptr^.subrange_bounds_list_ptr;
          new_stmt_ptr^.array_expr_element_ref := element_expr_ptr;
        end
      else
        begin
          new_stmt_ptr := New_stmt(subarray_expr_assign);

          {***************************************************}
          { initialize new subarray expr assignment statement }
          {***************************************************}
          new_stmt_ptr^.subarray_expr_subrange_ptr := lhs_array_subrange_ptr;
          new_stmt_ptr^.subarray_expr_element_ref := element_expr_ptr;
        end;

      {****************************}
      { add new statement to chain }
      {****************************}
      last_subrange_expr_ptr := lhs_subrange_expr_ptr;
      if (last_stmt_ptr <> nil) then
        begin
          case last_stmt_ptr^.kind of
            boolean_array_expr_assign..reference_array_expr_assign:
              last_stmt_ptr^.array_expr_assign_stmt_ptr := new_stmt_ptr;
            subarray_expr_assign:
              last_stmt_ptr^.subarray_expr_assign_stmt_ptr := new_stmt_ptr;
          end; {case}
          last_stmt_ptr := new_stmt_ptr;
        end
      else
        begin
          stmt_ptr := new_stmt_ptr;
          last_stmt_ptr := new_stmt_ptr;
        end;

      {***************************}
      { find next subrange arrays }
      {***************************}
      if dimensions > 1 then
        lhs_array_subrange_ptr :=
          New_next_subrange_dimension(lhs_array_subrange_ptr,
          lhs_subrange_expr_ptr);

      dimensions := dimensions - 1;
    end; {while}

  {********************************}
  { create primitive looping stmts }
  {********************************}
  new_stmt_ptr := New_element_assign(lhs_data_ptr, element_expr_ptr,
    type_attributes_ptr);
  case last_stmt_ptr^.kind of
    boolean_array_expr_assign..reference_array_expr_assign:
      last_stmt_ptr^.array_expr_assign_stmt_ptr := new_stmt_ptr;
    subarray_expr_assign:
      last_stmt_ptr^.subarray_expr_assign_stmt_ptr := new_stmt_ptr;
  end; {case}

  New_array_expr_assign := stmt_ptr;
end; {function New_array_expr_assign}


end.
