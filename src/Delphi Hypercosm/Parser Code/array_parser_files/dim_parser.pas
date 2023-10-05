unit dim_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             dim_parser                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse array            }
{       instance dimensioning into an abstract syntax tree      }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, decl_attributes, expr_attributes, exprs;


{***************************************}
{ routines to create array dimensioning }
{***************************************}
function New_array_dim_expr(type_attributes_ptr: type_attributes_ptr_type):
  expr_ptr_type;

{**************************************}
{ routines to parse array dimensioning }
{**************************************}
procedure Parse_array_inst_dim(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_array_inst_dims(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_array_inst_dim_tail(var expr_ptr: expr_ptr_type;
  integer_expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);


implementation
uses
  symbol_tables, value_attributes, arrays, type_decls, tokens, tokenizer,
    parser, match_literals, match_terms, subranges, subrange_parser, scoping;


function Array_dim_kind(type_attributes_ptr: type_attributes_ptr_type):
  expr_kind_type;
var
  kind: expr_kind_type;
begin
  case type_attributes_ptr^.kind of

    {*******************************}
    { enumerated array dimensioning }
    {*******************************}
    type_boolean:
      kind := boolean_array_dim;
    type_char:
      kind := char_array_dim;

    {****************************}
    { integer array dimensioning }
    {****************************}
    type_byte:
      kind := byte_array_dim;
    type_short:
      kind := short_array_dim;
    type_integer, type_enum:
      kind := integer_array_dim;
    type_long:
      kind := long_array_dim;

    {***************************}
    { scalar array dimensioning }
    {***************************}
    type_scalar:
      kind := scalar_array_dim;
    type_double:
      kind := double_array_dim;
    type_complex:
      kind := complex_array_dim;
    type_vector:
      kind := vector_array_dim;

    {***********************************}
    { array / struct array dimensioning }
    {***********************************}
    type_array:
      kind := array_array_dim;
    type_struct, type_class:
      if type_attributes_ptr^.static then
        kind := static_struct_array_dim
      else
        kind := struct_array_dim;

    {*********************************************}
    { subprogram and reference array dimensioning }
    {*********************************************}
    type_code:
      kind := proto_array_dim;
    type_reference:
      kind := reference_array_dim;

  else
    kind := error_expr;
  end; {case}

  Array_dim_kind := kind;
end; {function Array_dim_kind}


function New_array_dim_expr(type_attributes_ptr: type_attributes_ptr_type):
  expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
  type_ptr: type_ptr_type;
begin
  expr_ptr := New_expr(Array_dim_kind(type_attributes_ptr));

  if expr_ptr^.kind = static_struct_array_dim then
    begin
      type_ptr := Get_type_decl(type_attributes_ptr);
      expr_ptr^.dim_static_struct_type_ref := forward_type_ref_type(type_ptr);
    end;

  New_array_dim_expr := expr_ptr;
end; {function New_array_dim_expr}


function New_array_expr_dim(var expr_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
begin
  new_expr_ptr := New_array_dim_expr(type_attributes_ptr);

  if expr_ptr <> nil then
    begin
      {*********************************}
      { dimensioning an array of arrays }
      {*********************************}
      new_expr_ptr^.dim_element_expr_ptr := expr_ptr^.dim_element_expr_ptr;
      expr_ptr^.dim_element_expr_ptr := new_expr_ptr;
      expr_ptr^.kind := array_array_dim;
    end
  else
    begin
      {******************************************}
      { dimensioning an array of scalar elements }
      {******************************************}
      new_expr_ptr^.dim_element_expr_ptr := expr_ptr;
      expr_ptr := new_expr_ptr;
    end;

  New_array_expr_dim := new_expr_ptr;
end; {function New_array_expr_dim}


procedure Parse_array_inst_dim(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [left_bracket_tok];
var
  type_attributes_ptr: type_attributes_ptr_type;
  array_bounds_list_ptr: array_bounds_list_ptr_type;
  new_expr_ptr: expr_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        {********************}
        { parse array bounds }
        {********************}
        Get_next_token;

        {*************************}
        { parse array bounds list }
        {*************************}
        array_bounds_list_ptr := New_array_bounds_list;
        Parse_array_ranges(array_bounds_list_ptr);
        Match(right_bracket_tok);

        if parsing_ok then
          begin
            {*******************************************}
            { check array dimensions against attributes }
            {*******************************************}
            type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
            if (Get_data_rel_dims(type_attributes_ptr) <>
              array_bounds_list_ptr^.dimensions) then
              begin
                Parse_error;
                writeln('Dimensions of array bounds are incorrect.');
                error_reported := true;
              end
            else
              begin
                {*******************}
                { dereference array }
                {*******************}
                expr_attributes_ptr^.dimensions :=
                  type_attributes_ptr^.absolute_dimensions;
                expr_attributes_ptr^.alias_type_attributes_ptr :=
                  type_attributes_ptr^.element_type_attributes_ptr;
                expr_attributes_ptr^.alias_type_attributes_ptr :=
                  Unalias_type_attributes(expr_attributes_ptr^.alias_type_attributes_ptr);

                {**********************}
                { create new array dim }
                {**********************}
                new_expr_ptr := New_array_expr_dim(expr_ptr,
                  expr_attributes_ptr^.type_attributes_ptr);
                new_expr_ptr^.dim_bounds_list_ptr := array_bounds_list_ptr;
              end;
          end;
      end;
end; {procedure Parse_array_inst_dim}


procedure Parse_array_inst_dims(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [left_bracket_tok, s_tok];
begin
  if (next_token.kind in predict_set) and parsing_ok then
    begin
      Parse_array_inst_dim(expr_ptr, expr_attributes_ptr);
      Parse_array_inst_dims(expr_ptr^.dim_element_expr_ptr,
        expr_attributes_ptr);
    end;
end; {procedure Parse_array_inst_dims}


procedure Parse_array_inst_dim_tail(var expr_ptr: expr_ptr_type;
  integer_expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  array_bounds_list_ptr: array_bounds_list_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  new_expr_ptr: expr_ptr_type;
begin
  if parsing_ok then
    begin
      {***************************}
      { parse remainder of bounds }
      {***************************}
      array_bounds_list_ptr := New_array_bounds_list;
      Parse_array_range_tail(array_bounds_list_ptr, integer_expr_ptr);

      {********************************}
      { parse remainder of bounds list }
      {********************************}
      if next_token.kind = comma_tok then
        begin
          Get_next_token;
          Parse_array_ranges(array_bounds_list_ptr);
        end;

      Match(right_bracket_tok);

      if parsing_ok then
        begin
          {*******************************************}
          { check array dimensions against attributes }
          {*******************************************}
          type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
          if (Get_data_rel_dims(type_attributes_ptr) <>
            array_bounds_list_ptr^.dimensions) then
            begin
              Parse_error;
              writeln('Dimensions of array bounds are incorrect.');
              error_reported := true;
            end
          else
            begin
              {*******************}
              { dereference array }
              {*******************}
              expr_attributes_ptr^.dimensions :=
                type_attributes_ptr^.absolute_dimensions;
              expr_attributes_ptr^.alias_type_attributes_ptr :=
                type_attributes_ptr^.element_type_attributes_ptr;
              expr_attributes_ptr^.type_attributes_ptr :=
                Unalias_type_attributes(expr_attributes_ptr^.alias_type_attributes_ptr);

              {**********************}
              { create new array dim }
              {**********************}
              new_expr_ptr := New_array_expr_dim(expr_ptr,
                expr_attributes_ptr^.type_attributes_ptr);
              new_expr_ptr^.dim_bounds_list_ptr := array_bounds_list_ptr;
            end;
        end;
    end;
end; {procedure Parse_array_inst_dim_tail}


end.
