unit array_assigns;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           array_assigns               3d       }
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
  type_attributes, exprs, stmts, type_decls;


{****************************************************}
{ routines for creating particular array assignments }
{****************************************************}
function New_array_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type):
  stmt_ptr_type;
function New_array_ptr_array_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type):
  stmt_ptr_type;

{***************************************************}
{ routines for creating array assignment components }
{***************************************************}
function New_implicit_struct_new(type_attributes_ptr: type_attributes_ptr_type):
  expr_ptr_type;
function New_element_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type): stmt_ptr_type;


implementation
uses
  errors, expr_attributes, arrays, subranges, type_assigns, struct_assigns;


const
  debug = false;


  {***************************************************}
  { routines for creating array assignment components }
  {***************************************************}


function New_implicit_struct_new(type_attributes_ptr: type_attributes_ptr_type):
  expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
begin
  if type_attributes_ptr^.kind in structured_type_kinds then
    begin
      new_expr_ptr := New_expr(struct_new);
      new_expr_ptr^.new_struct_type_ref :=
        forward_type_ref_type(Get_type_decl(type_attributes_ptr));
    end
  else
    new_expr_ptr := nil;

  New_implicit_struct_new := new_expr_ptr;
end; {function New_implicit_struct_new}


function New_element_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  {****************************************************}
  { structures are assigned by value, not by reference }
  {****************************************************}
  if type_attributes_ptr^.kind in [type_struct, type_class] then
    stmt_ptr := New_struct_assign(lhs_data_ptr, rhs_expr_ptr)
  else
    stmt_ptr := New_type_assign(lhs_data_ptr, rhs_expr_ptr,
      type_attributes_ptr);

  New_element_assign := stmt_ptr;
end; {function New_element_assign}


{****************************************************}
{ routines for creating particular array assignments }
{****************************************************}


function Prim_array_assign_stmt_kind(type_kind: type_kind_type): stmt_kind_type;
var
  stmt_kind: stmt_kind_type;
begin
  case type_kind of

    {******************************}
    { enumerated array assignments }
    {******************************}
    type_boolean:
      stmt_kind := boolean_array_assign;
    type_char:
      stmt_kind := char_array_assign;

    {***************************}
    { integer array assignments }
    {***************************}
    type_byte:
      stmt_kind := byte_array_assign;
    type_short:
      stmt_kind := short_array_assign;
    type_integer:
      stmt_kind := integer_array_assign;
    type_long:
      stmt_kind := long_array_assign;

    {**************************}
    { scalar array assignments }
    {**************************}
    type_scalar:
      stmt_kind := scalar_array_assign;
    type_double:
      stmt_kind := double_array_assign;
    type_complex:
      stmt_kind := complex_array_assign;
    type_vector:
      stmt_kind := vector_array_assign;

  else
    stmt_kind := null_stmt;
  end; {case}

  Prim_array_assign_stmt_kind := stmt_kind;
end; {function Prim_array_assign_stmt_kind}


function Array_assign_stmt_kind(type_attributes_ptr: type_attributes_ptr_type):
  stmt_kind_type;
var
  stmt_kind: stmt_kind_type;
begin
  case type_attributes_ptr^.kind of

    {*****************************}
    { primitive array assignments }
    {*****************************}
    type_boolean..type_vector:
      stmt_kind := Prim_array_assign_stmt_kind(type_attributes_ptr^.kind);

    {*************************************}
    { user defined type array assignments }
    {*************************************}
    type_enum:
      stmt_kind := integer_array_assign;
    type_alias:
      stmt_kind :=
        Array_assign_stmt_kind(type_attributes_ptr^.alias_type_attributes_ptr);
    type_array:
      stmt_kind := array_array_assign;
    type_struct, type_class:
      stmt_kind := struct_array_assign;
    type_class_alias:
      stmt_kind :=
        Array_assign_stmt_kind(type_attributes_ptr^.class_alias_type_attributes_ptr);
    type_code:
      stmt_kind := proto_array_assign;

    {*************************************}
    { general reference array assignments }
    {*************************************}
    type_reference:
      stmt_kind := reference_array_assign;

  else
    stmt_kind := null_stmt;
  end; {case}

  Array_assign_stmt_kind := stmt_kind;
end; {function Array_assign_stmt_kind}


function New_array_assign_stmt(type_attributes_ptr: type_attributes_ptr_type):
  stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := New_stmt(Array_assign_stmt_kind(type_attributes_ptr));

  with stmt_ptr^ do
    if kind in [struct_array_assign, static_struct_array_assign] then
      case kind of
        struct_array_assign:
          array_struct_new_ptr := New_implicit_struct_new(type_attributes_ptr);
        static_struct_array_assign:
          array_static_struct_type_ref :=
            forward_type_ref_type(Get_type_decl(type_attributes_ptr));
      end; {case}

  New_array_assign_stmt := stmt_ptr;
end; {function New_array_assign_stmt}


function New_array_assign(lhs_data_ptr: expr_ptr_type;
  rhs_expr_ptr: expr_ptr_type): stmt_ptr_type;
var
  stmt_ptr, last_stmt_ptr, new_stmt_ptr: stmt_ptr_type;
  lhs_expr_attributes_ptr, rhs_expr_attributes_ptr: expr_attributes_ptr_type;
  lhs_dimensions, rhs_dimensions, dimensions: integer;
  lhs_array_subrange_ptr, rhs_array_subrange_ptr: array_subrange_ptr_type;
  lhs_subrange_expr_ptr, rhs_subrange_expr_ptr: expr_ptr_type;
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
  Complete_array_subrange(rhs_expr_ptr);

  {****************************}
  { find first subrange arrays }
  {****************************}
  lhs_array_subrange_ptr := New_first_subrange_dimension(lhs_data_ptr,
    lhs_subrange_expr_ptr);
  rhs_array_subrange_ptr := New_first_subrange_dimension(rhs_expr_ptr,
    rhs_subrange_expr_ptr);

  if debug then
    begin
      write('first subranges = ');
      Write_literal_array_bounds(lhs_array_subrange_ptr^.array_bounds_ref);
      write(', ');
      Write_literal_array_bounds(rhs_array_subrange_ptr^.array_bounds_ref);
      writeln;
    end;

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
      if rhs_array_subrange_ptr = nil then
        begin
          Make_array_subrange(rhs_expr_ptr, rhs_expr_attributes_ptr);
          rhs_subrange_expr_ptr := rhs_expr_ptr;
          rhs_array_subrange_ptr :=
            New_array_expr_subrange(rhs_subrange_expr_ptr);
        end;

      {*************************}
      { create array assignment }
      {*************************}
      if lhs_subrange_expr_ptr <> last_subrange_expr_ptr then
        begin
          if dimensions =
            lhs_subrange_expr_ptr^.subrange_bounds_list_ptr^.dimensions then
            new_stmt_ptr := New_array_assign_stmt(type_attributes_ptr)
          else
            new_stmt_ptr := New_stmt(array_array_assign);

          {*******************************************}
          { initialize new array assignment statement }
          {*******************************************}
          new_stmt_ptr^.lhs_array_subrange_ptr := lhs_array_subrange_ptr;
          new_stmt_ptr^.rhs_array_subrange_ptr := rhs_array_subrange_ptr;
          new_stmt_ptr^.array_assign_bounds_list_ref :=
            lhs_subrange_expr_ptr^.subrange_bounds_list_ptr;
        end
      else
        begin
          new_stmt_ptr := New_stmt(subarray_assign);

          {**********************************************}
          { initialize new subarray assignment statement }
          {**********************************************}
          new_stmt_ptr^.lhs_subarray_subrange_ptr := lhs_array_subrange_ptr;
          new_stmt_ptr^.rhs_subarray_subrange_ptr := rhs_array_subrange_ptr;
        end;

      {****************************}
      { add new statement to chain }
      {****************************}
      last_subrange_expr_ptr := lhs_subrange_expr_ptr;
      if (last_stmt_ptr <> nil) then
        begin
          case last_stmt_ptr^.kind of
            boolean_array_assign..reference_array_assign:
              last_stmt_ptr^.array_assign_stmt_ptr := new_stmt_ptr;
            subarray_assign:
              last_stmt_ptr^.subarray_assign_stmt_ptr := new_stmt_ptr;
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
        begin
          {******************************}
          { find next range of next loop }
          {******************************}
          lhs_array_subrange_ptr :=
            New_next_subrange_dimension(lhs_array_subrange_ptr,
            lhs_subrange_expr_ptr);
          rhs_array_subrange_ptr :=
            New_next_subrange_dimension(rhs_array_subrange_ptr,
            rhs_subrange_expr_ptr);

          if debug then
            begin
              write('next subranges = ');
              Write_literal_array_bounds(lhs_array_subrange_ptr^.array_bounds_ref);
              write(', ');
              Write_literal_array_bounds(rhs_array_subrange_ptr^.array_bounds_ref);
              writeln;
            end;
        end; {if}

      dimensions := dimensions - 1;
    end; {while}

  {*****************************}
  { create primitive assignment }
  {*****************************}
  new_stmt_ptr := New_element_assign(lhs_data_ptr, rhs_expr_ptr,
    type_attributes_ptr);
  case last_stmt_ptr^.kind of
    boolean_array_assign..reference_array_assign:
      last_stmt_ptr^.array_assign_stmt_ptr := new_stmt_ptr;
    subarray_assign:
      last_stmt_ptr^.subarray_assign_stmt_ptr := new_stmt_ptr;
  end; {case}

  New_array_assign := stmt_ptr;
end; {function New_array_assign}


function New_array_ptr_array_assign(lhs_data_ptr: expr_ptr_type;
  rhs_expr_ptr: expr_ptr_type): stmt_ptr_type;
var
  stmt_ptr, last_stmt_ptr, new_stmt_ptr: stmt_ptr_type;
  lhs_expr_attributes_ptr, rhs_expr_attributes_ptr: expr_attributes_ptr_type;
  lhs_dimensions, rhs_dimensions, dimensions: integer;
  lhs_array_subrange_ptr, rhs_array_subrange_ptr: array_subrange_ptr_type;
  lhs_subrange_expr_ptr, rhs_subrange_expr_ptr: expr_ptr_type;
  last_subrange_expr_ptr: expr_ptr_type;
begin
  {*************************************}
  { get left and right array attributes }
  {*************************************}
  lhs_expr_attributes_ptr := Get_expr_attributes(lhs_data_ptr);
  rhs_expr_attributes_ptr := Get_expr_attributes(rhs_expr_ptr);
  lhs_dimensions := lhs_expr_attributes_ptr^.dimensions;
  rhs_dimensions := rhs_expr_attributes_ptr^.dimensions;

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
  Complete_array_subrange(rhs_expr_ptr);

  {****************************}
  { find first subrange arrays }
  {****************************}
  lhs_array_subrange_ptr := New_first_subrange_dimension(lhs_data_ptr,
    lhs_subrange_expr_ptr);
  rhs_array_subrange_ptr := New_first_subrange_dimension(rhs_expr_ptr,
    rhs_subrange_expr_ptr);

  if debug then
    begin
      write('first subranges = ');
      Write_literal_array_bounds(lhs_array_subrange_ptr^.array_bounds_ref);
      write(', ');
      Write_literal_array_bounds(rhs_array_subrange_ptr^.array_bounds_ref);
      writeln;
    end;

  stmt_ptr := nil;
  last_stmt_ptr := nil;
  last_subrange_expr_ptr := nil;
  while dimensions > 0 do
    begin
      {*************************}
      { create array assignment }
      {*************************}
      if lhs_subrange_expr_ptr <> last_subrange_expr_ptr then
        begin
          new_stmt_ptr := New_stmt(array_array_assign);

          {*******************************************}
          { initialize new array assignment statement }
          {*******************************************}
          new_stmt_ptr^.lhs_array_subrange_ptr := lhs_array_subrange_ptr;
          new_stmt_ptr^.rhs_array_subrange_ptr := rhs_array_subrange_ptr;
          new_stmt_ptr^.array_assign_bounds_list_ref :=
            lhs_subrange_expr_ptr^.subrange_bounds_list_ptr;
        end
      else
        begin
          new_stmt_ptr := New_stmt(subarray_assign);

          {**********************************************}
          { initialize new subarray assignment statement }
          {**********************************************}
          new_stmt_ptr^.lhs_subarray_subrange_ptr := lhs_array_subrange_ptr;
          new_stmt_ptr^.rhs_subarray_subrange_ptr := rhs_array_subrange_ptr;
        end;

      {****************************}
      { add new statement to chain }
      {****************************}
      last_subrange_expr_ptr := lhs_subrange_expr_ptr;
      if (last_stmt_ptr <> nil) then
        begin
          case last_stmt_ptr^.kind of
            array_array_assign:
              last_stmt_ptr^.array_assign_stmt_ptr := new_stmt_ptr;
            subarray_assign:
              last_stmt_ptr^.subarray_assign_stmt_ptr := new_stmt_ptr;
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
        begin
          {******************************}
          { find next range of next loop }
          {******************************}
          lhs_array_subrange_ptr :=
            New_next_subrange_dimension(lhs_array_subrange_ptr,
            lhs_subrange_expr_ptr);
          rhs_array_subrange_ptr :=
            New_next_subrange_dimension(rhs_array_subrange_ptr,
            rhs_subrange_expr_ptr);

          if debug then
            begin
              write('next subranges = ');
              Write_literal_array_bounds(lhs_array_subrange_ptr^.array_bounds_ref);
              write(', ');
              Write_literal_array_bounds(rhs_array_subrange_ptr^.array_bounds_ref);
              writeln;
            end;
        end; {if}

      dimensions := dimensions - 1;
    end; {while}

  {*****************************}
  { create primitive assignment }
  {*****************************}
  new_stmt_ptr := New_array_ptr_assign(lhs_data_ptr, rhs_expr_ptr);
  case last_stmt_ptr^.kind of
    array_array_assign:
      last_stmt_ptr^.array_assign_stmt_ptr := new_stmt_ptr;
    subarray_assign:
      last_stmt_ptr^.subarray_assign_stmt_ptr := new_stmt_ptr;
  end; {case}

  New_array_ptr_array_assign := stmt_ptr;
end; {function New_array_ptr_array_assign}


end.
