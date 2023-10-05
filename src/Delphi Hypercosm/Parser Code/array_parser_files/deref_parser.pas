unit deref_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            deref_parser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse array and        }
{       structure dereferences into an abstract syntax tree     }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, decl_attributes, expr_attributes, exprs;


{******************************************}
{ routines for parsing array dereferencing }
{******************************************}
procedure Parse_array_deref(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  var abstract_deref: boolean);
procedure Parse_array_deref_or_subrange(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);

{***********************************************************}
{ routines for parsing array dereferencing and dimensioning }
{***********************************************************}
procedure Parse_array_derefs_or_dims(var expr_ptr, dim_expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_derefs_or_dims(var expr_ptr, dim_expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);


implementation
uses
  symbol_tables, value_attributes, arrays, type_decls, tokens, tokenizer,
    parser, match_literals, match_terms, subranges, subrange_parser, field_parser,
    dim_parser, expr_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                            terminals                          }
{***************************************************************}
{       <unit> ::= id <array_indices> <struct_offsets>          }
{                                                               }
{       <array_indices> ::= [ <integer_expr> ] <array_indices>  }
{       <array_indices> ::=                                     }
{                                                               }
{       <struct_offsets> ::= . id <struct_offsets>              }
{       <struct_offsets> ::=                                    }
{***************************************************************}

{***************************************************************}
{                            terminals                          }
{***************************************************************}
{       <array_expr> ::= <derefs> <partial_deref> <sub_range>   }
{       <array_addr> ::= <derefs>                               }
{       <array_bounds> ::= <ranges> <unspecified_ranges>        }
{       <array_dim> ::= <derefs> <ranges>                       }
{       <array_min_max> ::= <derefs> <unspecified_deref>        }
{                                                               }
{       <range> ::=     [ <integer_expr> .. <integer_expr> ]    }
{       <unspecified_range> ::= [ ]                             }
{                                                               }
{       <deref> ::=     [ <integer_expr> ]                      }
{       <unspecified_deref> ::=  [ ]                            }
{***************************************************************}


{******************************************}
{ routines for parsing array dereferencing }
{******************************************}


function Prim_array_deref_expr_kind(type_kind: type_kind_type): expr_kind_type;
var
  expr_kind: expr_kind_type;
begin
  case type_kind of

    {*************************}
    { enumerated array derefs }
    {*************************}
    type_boolean:
      expr_kind := boolean_array_deref;
    type_char:
      expr_kind := char_array_deref;

    {**********************}
    { integer array derefs }
    {**********************}
    type_byte:
      expr_kind := byte_array_deref;
    type_short:
      expr_kind := short_array_deref;
    type_integer:
      expr_kind := integer_array_deref;
    type_long:
      expr_kind := long_array_deref;

    {***************}
    { scalar derefs }
    {***************}
    type_scalar:
      expr_kind := scalar_array_deref;
    type_double:
      expr_kind := double_array_deref;
    type_complex:
      expr_kind := complex_array_deref;
    type_vector:
      expr_kind := vector_array_deref;

  else
    expr_kind := error_expr;
  end; {case}

  Prim_array_deref_expr_kind := expr_kind;
end; {function Prim_array_deref_expr_kind}


function Array_deref_expr_kind(type_attributes_ptr: type_attributes_ptr_type):
  expr_kind_type;
var
  expr_kind: expr_kind_type;
begin
  case type_attributes_ptr^.kind of

    {************************}
    { primitive array derefs }
    {************************}
    type_boolean..type_vector:
      expr_kind := Prim_array_deref_expr_kind(type_attributes_ptr^.kind);

    {********************************}
    { user defined type array derefs }
    {********************************}
    type_enum:
      expr_kind := integer_array_deref;
    type_alias:
      expr_kind :=
        Array_deref_expr_kind(type_attributes_ptr^.alias_type_attributes_ptr);
    type_array:
      expr_kind := array_array_deref;
    type_struct, type_class:
      if type_attributes_ptr^.static then
        expr_kind := static_struct_array_deref
      else
        expr_kind := struct_array_deref;
    type_class_alias:
      expr_kind :=
        Array_deref_expr_kind(type_attributes_ptr^.class_alias_type_attributes_ptr);
    type_code:
      expr_kind := proto_array_deref;

    {********************************}
    { general reference array derefs }
    {********************************}
    type_reference:
      expr_kind := reference_array_deref;

  else
    expr_kind := error_expr;
  end; {case}

  Array_deref_expr_kind := expr_kind;
end; {function Array_deref_expr_kind}


function New_array_deref_expr(var expr_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
begin
  new_expr_ptr := New_expr(Array_deref_expr_kind(type_attributes_ptr));

  if new_expr_ptr^.kind = static_struct_array_deref then
    new_expr_ptr^.deref_static_struct_type_ref :=
      forward_type_ref_type(Get_type_decl(type_attributes_ptr));

  if (expr_ptr^.kind in array_deref_set) then
    begin
      case expr_ptr^.kind of
        boolean_array_deref..reference_array_deref:
          begin
            new_expr_ptr^.deref_base_ptr := expr_ptr;
            new_expr_ptr^.deref_element_ref := expr_ptr^.deref_element_ref;
            expr_ptr^.deref_element_ref := new_expr_ptr;
            expr_ptr := new_expr_ptr;
          end;
        boolean_array_subrange..reference_array_subrange:
          begin
            new_expr_ptr^.deref_base_ptr := expr_ptr;
            new_expr_ptr^.deref_element_ref := expr_ptr^.subrange_element_ref;
            expr_ptr^.deref_element_ref := new_expr_ptr;
            expr_ptr := new_expr_ptr;
          end;
      end; {case}
    end
  else
    begin
      new_expr_ptr^.deref_base_ptr := expr_ptr;
      new_expr_ptr^.deref_element_ref := expr_ptr;
      expr_ptr := new_expr_ptr;
    end;

  New_array_deref_expr := new_expr_ptr;
end; {function New_array_deref_expr}


{************************  productions  ************************}
{       <array_derefs> ::= <array_deref> <array_derefs>         }
{       <array_derefs> ::=                                      }
{       <array_deref> ::= [ <indices> ]                         }
{       <array_deref> ::=                                       }
{                                                               }
{       <array_indices> ::= <array_index> <more_indices>        }
{       <more_indices> ::= , <array_indices>                    }
{       <more_indices> ::=                                      }
{***************************************************************}

procedure Parse_array_deref(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  var abstract_deref: boolean);
const
  predict_set = [left_bracket_tok];
var
  new_expr_ptr: expr_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  indices, max_indices: integer;
begin
  if parsing_ok then
    if (next_token.kind in predict_set) then
      if (expr_attributes_ptr^.dimensions <> 0) then
        begin
          Get_next_token;

          type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
          max_indices := type_attributes_ptr^.relative_dimensions;
          array_index_list_ptr := New_array_index_list(max_indices);
          Parse_array_indices(array_index_list_ptr, nil, abstract_deref);
          Match(right_bracket_tok);

          {*********************************}
          { is array deref real or abstract }
          {*********************************}
          if parsing_ok then
            begin
              if abstract_deref then
                begin
                  if (Get_data_rel_dims(type_attributes_ptr)) <= 1 then
                    begin
                      Parse_error;
                      writeln('Expected a multidimensional array here.');
                      error_reported := true;
                    end;
                end;

              if parsing_ok then
                begin
                  {******************************}
                  { dereference array attributes }
                  {******************************}
                  indices := array_index_list_ptr^.indices;
                  expr_attributes_ptr^.dimensions :=
                    expr_attributes_ptr^.dimensions - indices;
                  expr_attributes_ptr^.alias_type_attributes_ptr :=
                    type_attributes_ptr^.element_type_attributes_ptr;
                  expr_attributes_ptr^.type_attributes_ptr :=
                    Unalias_type_attributes(expr_attributes_ptr^.alias_type_attributes_ptr);

                  {******************************}
                  { create new array dereference }
                  {******************************}
                  new_expr_ptr := New_array_deref_expr(expr_ptr,
                    expr_attributes_ptr^.type_attributes_ptr);
                  new_expr_ptr^.deref_index_list_ptr := array_index_list_ptr;
                end;
            end;
        end
      else
        begin
          Parse_error;
          writeln('Array dereference requires an array.');
          error_reported := true;
        end;
end; {procedure Parse_array_deref}


procedure Parse_array_deref_or_subrange(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [left_bracket_tok];
var
  new_expr_ptr: expr_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type;
  array_bounds_list_ptr: array_bounds_list_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  indices, max_indices: integer;
  counter: integer;
begin
  if parsing_ok then
    if (next_token.kind in predict_set) then
      if (expr_attributes_ptr^.dimensions <> 0) then
        begin
          Get_next_token;

          type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
          max_indices := type_attributes_ptr^.relative_dimensions;
          array_index_list_ptr := New_array_index_list(max_indices);

          array_bounds_list_ptr := nil;
          Parse_array_indices_or_subranges(array_index_list_ptr,
            array_bounds_list_ptr, nil);
          Match(right_bracket_tok);

          {***********************************}
          { find number of array dereferences }
          {***********************************}
          if array_bounds_list_ptr <> nil then
            indices := array_index_list_ptr^.indices -
              array_bounds_list_ptr^.dimensions
          else
            indices := array_index_list_ptr^.indices;

          {******************************}
          { dereference array attributes }
          {******************************}
          expr_attributes_ptr^.dimensions := expr_attributes_ptr^.dimensions -
            indices;
          expr_attributes_ptr^.alias_type_attributes_ptr :=
            type_attributes_ptr^.element_type_attributes_ptr;
          expr_attributes_ptr^.type_attributes_ptr :=
            Unalias_type_attributes(expr_attributes_ptr^.alias_type_attributes_ptr);

          if array_bounds_list_ptr <> nil then
            begin
              {****************}
              { array subrange }
              {****************}
              new_expr_ptr := New_array_subrange_expr(expr_ptr,
                expr_attributes_ptr^.type_attributes_ptr, false);
              new_expr_ptr^.subrange_index_list_ptr := array_index_list_ptr;
              new_expr_ptr^.subrange_bounds_list_ptr := array_bounds_list_ptr;

              {******************************************************}
              { add extra dimensions for unspecified array subranges }
              {******************************************************}
              if array_index_list_ptr^.indices < max_indices then
                for counter := 1 to (max_indices -
                  array_bounds_list_ptr^.dimensions) do
                  Add_array_subrange(array_bounds_list_ptr,
                    array_index_list_ptr, New_array_bounds);
            end
          else
            begin
              {*************}
              { array deref }
              {*************}
              new_expr_ptr := New_array_deref_expr(expr_ptr,
                expr_attributes_ptr^.type_attributes_ptr);
              new_expr_ptr^.deref_index_list_ptr := array_index_list_ptr;
            end;
        end
      else
        begin
          Parse_error;
          writeln('Array dereference requires an array.');
          error_reported := true;
        end;
end; {procedure Parse_array_deref_or_subrange}


{***********************************************************}
{ routines for parsing array dereferencing and dimensioning }
{***********************************************************}


{*****************************************************}
{         array dimensioning or dereferencing         }
{*****************************************************}
{ when dimensioning sub arrays, array dim expressions }
{ include derefs as well as dims: ex. dim a[4][1..10] }
{*****************************************************}


procedure Parse_array_deref_tail(var expr_ptr: expr_ptr_type;
  integer_expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  indices, max_indices: integer;
  abstract_indices: boolean;
begin
  if parsing_ok then
    if (expr_attributes_ptr^.dimensions <> 0) then
      begin
        type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
        max_indices := type_attributes_ptr^.relative_dimensions;
        array_index_list_ptr := New_array_index_list(max_indices);
        Parse_array_indices(array_index_list_ptr, integer_expr_ptr,
          abstract_indices);
        Match(right_bracket_tok);

        if parsing_ok then
          begin
            {******************************}
            { dereference array attributes }
            {******************************}
            indices := array_index_list_ptr^.indices;
            expr_attributes_ptr^.dimensions := expr_attributes_ptr^.dimensions -
              indices;
            expr_attributes_ptr^.alias_type_attributes_ptr :=
              type_attributes_ptr^.element_type_attributes_ptr;
            expr_attributes_ptr^.type_attributes_ptr :=
              Unalias_type_attributes(expr_attributes_ptr^.alias_type_attributes_ptr);

            {************************}
            { create new array deref }
            {************************}
            new_expr_ptr := New_array_deref_expr(expr_ptr,
              expr_attributes_ptr^.type_attributes_ptr);
            new_expr_ptr^.deref_index_list_ptr := array_index_list_ptr;
          end;
      end
    else
      begin
        Parse_error;
        writeln('Array dereference requires an array.');
        error_reported := true;
      end;
end; {procedure Parse_array_deref_tail}


procedure Parse_array_deref_or_dim(var expr_ptr, dim_expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [left_bracket_tok];
var
  integer_expr_ptr: expr_ptr_type;
begin
  if parsing_ok then
    if (next_token.kind in predict_set) then
      if (expr_attributes_ptr^.dimensions <> 0) then
        begin
          Get_next_token;
          Parse_equal_expr(integer_expr_ptr, integer_value_attributes_ptr);

          if (next_token.kind = dot_dot_tok) then
            begin
              {******************************}
              { parse remainder of array dim }
              {******************************}
              Parse_array_inst_dim_tail(dim_expr_ptr, integer_expr_ptr,
                expr_attributes_ptr);
            end
          else
            begin
              {********************************}
              { parse remainder of array deref }
              {********************************}
              Parse_array_deref_tail(expr_ptr, integer_expr_ptr,
                expr_attributes_ptr);
              dim_expr_ptr := nil;
            end;
        end
      else
        begin
          Parse_error;
          writeln('Array dereference requires an array.');
          error_reported := true;
        end;
end; {procedure Parse_array_deref_or_dim}


procedure Parse_array_derefs_or_dims(var expr_ptr, dim_expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [left_bracket_tok];
begin
  if (next_token.kind in predict_set) and parsing_ok then
    begin
      {*************************************}
      { parse array derefs followed by dims }
      {*************************************}
      if (expr_ptr^.kind in dim_expr_kinds) then
        begin
          Parse_array_deref_or_dim(expr_ptr, dim_expr_ptr, expr_attributes_ptr);

          if parsing_ok then
            if dim_expr_ptr <> nil then
              Parse_array_inst_dims(expr_ptr^.dim_element_expr_ptr,
                expr_attributes_ptr)
            else
              Parse_array_derefs_or_dims(expr_ptr, dim_expr_ptr,
                expr_attributes_ptr);
        end
      else
        begin
          Parse_error;
          writeln('Expected an array here.');
          error_reported := true;
        end;
    end;
end; {procedure Parse_array_derefs_or_dims}


procedure Parse_derefs_or_dims(var expr_ptr, dim_expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [left_bracket_tok, s_tok];
begin
  if (next_token.kind in predict_set) and parsing_ok then
    begin
      if (expr_ptr^.kind in dim_expr_kinds) then
        case next_token.kind of

          {*********************}
          { parse struct derefs }
          {*********************}
          s_tok:
            begin
              Get_next_token;
              Parse_struct_field(expr_ptr, expr_attributes_ptr);
              Parse_derefs_or_dims(expr_ptr, dim_expr_ptr, expr_attributes_ptr);
            end;

          {*************************************}
          { parse array derefs followed by dims }
          {*************************************}
          left_bracket_tok:
            begin
              Parse_array_derefs_or_dims(expr_ptr, dim_expr_ptr,
                expr_attributes_ptr);
              Parse_derefs_or_dims(expr_ptr, dim_expr_ptr, expr_attributes_ptr);
            end;

        end {case}
      else
        begin
          Parse_error;
          writeln('Expected an array here.');
          error_reported := true;
        end;
    end;
end; {procedure Parse_derefs_or_dims}


end.
