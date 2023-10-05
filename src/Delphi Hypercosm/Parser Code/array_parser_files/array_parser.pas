unit array_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            array_parser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse array            }
{       declarations into an abstract syntax tree               }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  expr_attributes, decl_attributes, exprs, decls;


{******************************************}
{ routines for creating array declarations }
{******************************************}
procedure Dim_array_decl_attributes(expr_attributes_ptr:
  expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  dimensions: integer);
function New_array_decl_dim(expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type): expr_ptr_type;

{*****************************************}
{ routines for parsing array declarations }
{*****************************************}
procedure Parse_array_decl_dims(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  unspecified: boolean);


implementation
uses
  type_attributes, arrays, tokens, tokenizer, parser, dim_parser,
    subrange_parser;


{******************************************}
{ routines for creating array declarations }
{******************************************}


procedure Dim_array_decl_attributes(expr_attributes_ptr:
  expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  dimensions: integer);
begin
  {******************************}
  { add array to type attributes }
  {******************************}
  if decl_attributes_ptr^.base_type_attributes_ref <>
    decl_attributes_ptr^.type_attributes_ptr then
    Dim_base_type_attributes(decl_attributes_ptr^.type_attributes_ptr,
      dimensions)
  else
    Dim_type_attributes(decl_attributes_ptr^.type_attributes_ptr, dimensions);

  {*************************************************}
  { update decl attributes to match type attributes }
  {*************************************************}
  decl_attributes_ptr^.dimensions :=
    Get_data_abs_dims(decl_attributes_ptr^.type_attributes_ptr);

  {*******************************************}
  { also update expr attributes to match decl }
  {*******************************************}
  expr_attributes_ptr^.dimensions := decl_attributes_ptr^.dimensions;
  expr_attributes_ptr^.alias_type_attributes_ptr :=
    decl_attributes_ptr^.type_attributes_ptr;
  expr_attributes_ptr^.type_attributes_ptr :=
    Unalias_type_attributes(expr_attributes_ptr^.alias_type_attributes_ptr);
end; {procedure Dim_array_decl_attributes}


function New_array_decl_dim(expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
begin
  if (expr_attributes_ptr^.dimensions <> 0) then
    begin
      {*********************************}
      { dimensioning an array of arrays }
      {*********************************}
      new_expr_ptr := New_expr(array_array_dim);
      new_expr_ptr^.dim_element_expr_ptr := expr_ptr;
    end
  else
    begin
      {******************************************}
      { dimensioning an array of primitive types }
      {******************************************}
      new_expr_ptr :=
        New_array_dim_expr(expr_attributes_ptr^.type_attributes_ptr);
    end;

  New_array_decl_dim := new_expr_ptr;
end; {function New_array_decl_dim}


{*****************************************}
{ routines for parsing array declarations }
{*****************************************}


procedure Parse_array_decl_dims(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  unspecified: boolean);
const
  predict_set = [left_bracket_tok];
var
  array_bounds_list_ptr: array_bounds_list_ptr_type;
begin
  if parsing_ok then
    begin
      if (next_token.kind in predict_set) then
        begin
          Parse_array_bounds(array_bounds_list_ptr);

          {*****************************************}
          { check for consistency with parent array }
          {*****************************************}
          if unspecified then
            begin
              if (array_bounds_list_ptr^.first <> nil) then
                begin
                  Parse_error;
                  writeln('Can not specify dimensions on');
                  writeln('an element of a dynamic array.');
                  error_reported := true;
                end;
            end
          else
            begin
              if (array_bounds_list_ptr^.first = nil) then
                unspecified := true;
            end;

          {*****************************}
          { parse remaining array decls }
          {*****************************}
          Parse_array_decl_dims(expr_ptr, expr_attributes_ptr,
            decl_attributes_ptr, unspecified);

          {**********************}
          { create new array dim }
          {**********************}
          if parsing_ok then
            begin
              expr_ptr := New_array_decl_dim(expr_ptr, expr_attributes_ptr);
              expr_ptr^.dim_bounds_list_ptr := array_bounds_list_ptr;
            end;

          {*************************************}
          { update attributes to reflect bounds }
          {*************************************}
          Dim_array_decl_attributes(expr_attributes_ptr, decl_attributes_ptr,
            array_bounds_list_ptr^.dimensions);
        end
      else
        expr_ptr := nil;
    end;
end; {procedure Parse_array_decl_dims}


end.
