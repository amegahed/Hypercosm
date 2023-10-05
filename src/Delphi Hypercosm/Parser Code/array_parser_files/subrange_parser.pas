unit subrange_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           subrange_parser             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse array bounds     }
{       and indices into an abstract syntax representation.     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  arrays, exprs;


{********************************}
{ routines to parse array bounds }
{********************************}
procedure Parse_array_bounds(var array_bounds_list_ptr:
  array_bounds_list_ptr_type);
procedure Parse_array_range(array_bounds_list_ptr: array_bounds_list_ptr_type);
procedure Parse_array_ranges(array_bounds_list_ptr: array_bounds_list_ptr_type);
procedure Parse_array_range_tail(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  integer_expr_ptr: expr_ptr_type);
procedure Parse_array_subrange(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type);
procedure Parse_array_subrange_tail(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type;
  integer_expr_ptr: expr_ptr_type);

{*********************************}
{ routines to parse array indices }
{*********************************}
procedure Parse_array_indices(array_index_list_ptr: array_index_list_ptr_type;
  integer_expr_ptr: expr_ptr_type;
  var abstract_indices: boolean);
procedure Parse_array_indices_or_subranges(array_index_list_ptr:
  array_index_list_ptr_type;
  var array_bounds_list_ptr: array_bounds_list_ptr_type;
  integer_expr_ptr: expr_ptr_type);


implementation
uses
  expr_attributes, value_attributes, tokens, tokenizer, parser, match_literals,
    expr_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{*************************************************}
{ routines for parsing array ranges and subranges }
{*************************************************}


{************************  productions  ************************}
{       <array_decls> ::= <array_decl> <array_decls>            }
{       <array_decls> ::=                                       }
{       <array_decl> ::= [ <ranges> ]                           }
{       <array_decl> ::=                                        }
{                                                               }
{       <ranges> ::= <range> <more_ranges>                      }
{       <more_ranges> ::= , <ranges>                            }
{       <more_ranges> ::=                                       }
{***************************************************************}

procedure Parse_array_bounds(var array_bounds_list_ptr:
  array_bounds_list_ptr_type);
const
  predict_set = [left_bracket_tok];
var
  done: boolean;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        {********************}
        { parse array bounds }
        {********************}
        Get_next_token;

        array_bounds_list_ptr := New_array_bounds_list;

        if (next_token.kind in [comma_tok, right_bracket_tok]) then
          begin
            {*******************************}
            { parse empty array bounds list }
            {*******************************}
            done := false;
            while parsing_ok and not done do
              begin
                array_bounds_list_ptr^.dimensions :=
                  array_bounds_list_ptr^.dimensions + 1;

                if (next_token.kind = right_bracket_tok) then
                  begin
                    Get_next_token;
                    done := true;
                  end
                else
                  Match(comma_tok);
              end;
          end
        else
          begin
            {*************************}
            { parse array bounds list }
            {*************************}
            Parse_array_ranges(array_bounds_list_ptr);
            Match(right_bracket_tok);
          end;
      end
    else
      array_bounds_list_ptr := nil;
end; {procedure Parse_array_bounds}


{************************  productions  ************************}
{       <range> ::= <min> .. <max>                              }
{       <range> ::=                                             }
{       <min> ::= <integer_expr>                                }
{       <max> ::= <integer_expr>                                }
{***************************************************************}

procedure Parse_array_range(array_bounds_list_ptr: array_bounds_list_ptr_type);
var
  expr_ptr: expr_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
begin
  array_bounds_ptr := New_array_bounds;

  with array_bounds_ptr^ do
    begin
      Parse_equal_expr(expr_ptr, integer_value_attributes_ptr);
      min_expr_ptr := forward_expr_ptr_type(expr_ptr);
      Match(dot_dot_tok);
      Parse_equal_expr(expr_ptr, integer_value_attributes_ptr);
      max_expr_ptr := forward_expr_ptr_type(expr_ptr);
    end;

  {***************************}
  { add bounds to bounds list }
  {***************************}
  Add_array_bounds(array_bounds_list_ptr, array_bounds_ptr);
end; {procedure Parse_array_range}


procedure Parse_array_range_tail(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  integer_expr_ptr: expr_ptr_type);
var
  expr_ptr: expr_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
begin
  array_bounds_ptr := New_array_bounds;

  with array_bounds_ptr^ do
    begin
      min_expr_ptr := forward_expr_ptr_type(integer_expr_ptr);
      Match(dot_dot_tok);
      Parse_equal_expr(expr_ptr, integer_value_attributes_ptr);
      max_expr_ptr := forward_expr_ptr_type(expr_ptr);
    end;

  {***************************}
  { add bounds to bounds list }
  {***************************}
  Add_array_bounds(array_bounds_list_ptr, array_bounds_ptr);
end; {procedure Parse_array_range_tail}


procedure Parse_array_ranges(array_bounds_list_ptr: array_bounds_list_ptr_type);
var
  done: boolean;
begin
  done := false;
  while parsing_ok and not done do
    begin
      Parse_array_range(array_bounds_list_ptr);

      if (next_token.kind = right_bracket_tok) then
        done := true
      else
        Match(comma_tok);
    end;
end; {procedure Parse_array_ranges}


procedure Parse_array_subrange(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type);
var
  expr_ptr: expr_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
  array_index_ptr: array_index_ptr_type;
begin
  array_bounds_ptr := New_array_bounds;
  array_index_ptr := New_array_index;

  with array_bounds_ptr^ do
    begin
      if (next_token.kind <> dot_dot_tok) then
        begin
          Parse_equal_expr(expr_ptr, integer_value_attributes_ptr);
          min_expr_ptr := forward_expr_ptr_type(expr_ptr);
        end;

      Match(dot_dot_tok);

      if not (next_token.kind in [comma_tok, right_bracket_tok]) then
        begin
          Parse_equal_expr(expr_ptr, integer_value_attributes_ptr);
          max_expr_ptr := forward_expr_ptr_type(expr_ptr);
        end;
    end;

  {*************************}
  { add links to each other }
  {*************************}
  array_bounds_ptr^.array_index_ref := array_index_ptr;
  array_index_ptr^.array_bounds_ref := array_bounds_ptr;

  {*******************************}
  { add to bounds and index lists }
  {*******************************}
  Add_array_bounds(array_bounds_list_ptr, array_bounds_ptr);
  Add_array_index(array_index_list_ptr, array_index_ptr);
end; {procedure Parse_array_subrange}


procedure Parse_array_subrange_tail(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type;
  integer_expr_ptr: expr_ptr_type);
var
  expr_ptr: expr_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
  array_index_ptr: array_index_ptr_type;
begin
  array_bounds_ptr := New_array_bounds;
  array_index_ptr := New_array_index;

  if not (next_token.kind in [comma_tok, right_bracket_tok]) then
    with array_bounds_ptr^ do
      begin
        min_expr_ptr := forward_expr_ptr_type(integer_expr_ptr);

        Match(dot_dot_tok);

        if not (next_token.kind in [comma_tok, right_bracket_tok]) then
          begin
            Parse_equal_expr(expr_ptr, integer_value_attributes_ptr);
            max_expr_ptr := forward_expr_ptr_type(expr_ptr);
          end;
      end;

  {*************************}
  { add links to each other }
  {*************************}
  array_bounds_ptr^.array_index_ref := array_index_ptr;
  array_index_ptr^.array_bounds_ref := array_bounds_ptr;

  {*******************************}
  { add to bounds and index lists }
  {*******************************}
  Add_array_bounds(array_bounds_list_ptr, array_bounds_ptr);
  Add_array_index(array_index_list_ptr, array_index_ptr);
end; {procedure Parse_array_subrange_tail}


{************************************}
{ routines for parsing array indices }
{************************************}


{************************  productions  ************************}
{       <array_indices> ::= <array_index> <array_indices>       }
{       <array_index> ::=                                       }
{       <array_index> ::= [ <integer_expr> ]                    }
{***************************************************************}

procedure Parse_array_indices(array_index_list_ptr: array_index_list_ptr_type;
  integer_expr_ptr: expr_ptr_type;
  var abstract_indices: boolean);
var
  expr_ptr: expr_ptr_type;
  array_index_ptr: array_index_ptr_type;
  done, unspecified_indices: boolean;
  counter: integer;
begin
  if parsing_ok then
    begin
      {***************************************}
      { parse list of array index expressions }
      {***************************************}
      done := false;
      unspecified_indices := false;
      abstract_indices := true;
      counter := 0;

      while parsing_ok and (not done) and (counter <
        array_index_list_ptr^.max_indices) do
        begin
          array_index_ptr := New_array_index;

          if (integer_expr_ptr <> nil) then
            begin
              {**********************************}
              { use integer expression from list }
              {**********************************}
              array_index_ptr^.index_expr_ptr :=
                forward_expr_ptr_type(integer_expr_ptr);
              integer_expr_ptr := integer_expr_ptr^.next;
              abstract_indices := false;
            end
          else
            begin
              {*************************************************}
              { parse new integer expression or null expression }
              {*************************************************}
              if (next_token.kind in [comma_tok, right_bracket_tok]) then
                unspecified_indices := true;

              if not unspecified_indices then
                begin
                  Parse_equal_expr(expr_ptr, integer_value_attributes_ptr);
                  array_index_ptr^.index_expr_ptr :=
                    forward_expr_ptr_type(expr_ptr);
                  abstract_indices := false;
                end;
            end;

          Add_array_index(array_index_list_ptr, array_index_ptr);
          counter := counter + 1;

          if (next_token.kind = right_bracket_tok) then
            done := true
          else
            Match(comma_tok);
        end;
    end;
end; {procedure Parse_array_indices}


{************************  productions  ************************}
{       <array_indices> ::= <array_index> <array_indices>       }
{       <array_index> ::=                                       }
{       <array_index> ::= [ <integer_expr> ]                    }
{***************************************************************}

procedure Parse_array_indices_or_subranges(array_index_list_ptr:
  array_index_list_ptr_type;
  var array_bounds_list_ptr: array_bounds_list_ptr_type;
  integer_expr_ptr: expr_ptr_type);
var
  array_index_ptr: array_index_ptr_type;
  counter: integer;
  done: boolean;
begin
  if parsing_ok then
    begin
      {***************************************}
      { parse list of array index expressions }
      {***************************************}
      done := false;
      counter := 0;

      while parsing_ok and (not done) and (counter <
        array_index_list_ptr^.max_indices) do
        begin
          if (integer_expr_ptr <> nil) then
            begin
              {**********************************}
              { use integer expression from list }
              {**********************************}
              array_index_ptr := New_array_index;
              array_index_ptr^.index_expr_ptr :=
                forward_expr_ptr_type(integer_expr_ptr);
              Add_array_index(array_index_list_ptr, array_index_ptr);
            end
          else
            begin
              {*************************************************}
              { parse new integer expression or null expression }
              {*************************************************}
              if not (next_token.kind in [dot_dot_tok, comma_tok,
                right_bracket_tok]) then
                Parse_equal_expr(integer_expr_ptr,
                  integer_value_attributes_ptr);

              if (integer_expr_ptr <> nil) and (next_token.kind <> dot_dot_tok)
                then
                begin
                  array_index_ptr := New_array_index;
                  array_index_ptr^.index_expr_ptr :=
                    forward_expr_ptr_type(integer_expr_ptr);
                  Add_array_index(array_index_list_ptr, array_index_ptr);
                end
              else
                begin
                  if array_bounds_list_ptr = nil then
                    array_bounds_list_ptr := New_array_bounds_list;
                  Parse_array_subrange_tail(array_bounds_list_ptr,
                    array_index_list_ptr, integer_expr_ptr);
                end;
            end;

          if integer_expr_ptr <> nil then
            integer_expr_ptr := integer_expr_ptr^.next;
          counter := counter + 1;

          if (next_token.kind = right_bracket_tok) then
            done := true
          else
            Match(comma_tok);
        end;
    end;
end; {procedure Parse_array_indices_or_subranges}


end.

