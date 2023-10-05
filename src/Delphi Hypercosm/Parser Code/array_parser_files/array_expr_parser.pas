unit array_expr_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          array_expr_parser            3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse array or         }
{       structure elements into an abstract syntax tree         }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, expr_attributes, exprs;


procedure Parse_array_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_struct_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_string_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

{************************************************}
{ routines for creating array exprs from strings }
{************************************************}
procedure Make_string_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  string_ptr: string_ptr_type);


implementation
uses
  symbol_tables, type_attributes, decl_attributes, value_attributes, arrays,
  tokens, tokenizer, parser, match_literals, comment_parser, expr_parser;


procedure Parse_array_subexpr(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  array_bounds_list_ptr: array_bounds_list_ptr_type;
  var array_bounds_ptr: array_bounds_ptr_type); forward;


function New_char_lit_exprs(string_ptr: string_ptr_type): expr_ptr_type;
var
  expr_ptr, last_expr_ptr, new_expr_ptr: expr_ptr_type;
  string_node_ptr: string_node_ptr_type;
  counter: integer;
begin
  expr_ptr := nil;
  last_expr_ptr := nil;

  {***********************************************}
  { convert string space to list of char elements }
  {***********************************************}
  string_node_ptr := string_ptr^.first;
  for counter := 1 to string_ptr^.length do
    begin
      {***************************}
      { go to next block of chars }
      {***************************}
      if (counter mod string_size = 0) then
        string_node_ptr := string_node_ptr^.next;

      {***********************}
      { make new char literal }
      {***********************}
      new_expr_ptr := New_expr(char_lit);
      new_expr_ptr^.char_val := string_node_ptr^.str[(counter - 1) mod
        string_size + 1];

      {*****************************}
      { add element to tail of list }
      {*****************************}
      if last_expr_ptr <> nil then
        begin
          last_expr_ptr^.next := new_expr_ptr;
          last_expr_ptr := new_expr_ptr;
        end
      else
        begin
          expr_ptr := new_expr_ptr;
          last_expr_ptr := new_expr_ptr;
        end;
    end; {for}

  New_char_lit_exprs := expr_ptr;
end; {procedure New_char_lit_exprs}


procedure Make_string_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  string_ptr: string_ptr_type);
var
  array_bounds_ptr: array_bounds_ptr_type;
begin
  {***************************************}
  { create new bounds list for array expr }
  {***************************************}
  expr_ptr := New_expr(char_array_expr);
  expr_attributes_ptr := Copy_expr_attributes(string_value_attributes_ptr);
  Set_expr_attributes(expr_ptr, expr_attributes_ptr);

  {**************************}
  { create array bounds list }
  {**************************}
  expr_ptr^.array_expr_bounds_list_ptr := New_array_bounds_list;
  array_bounds_ptr := New_array_bounds;
  with array_bounds_ptr^ do
    begin
      min_val := 1;
      max_val := string_ptr^.length;
    end;
  Add_array_bounds(expr_ptr^.array_expr_bounds_list_ptr, array_bounds_ptr);

  {***************************}
  { parse char array elements }
  {***************************}
  expr_ptr^.array_element_exprs_ptr := New_char_lit_exprs(string_ptr);
end; {procedure Make_string_expr}


procedure Parse_struct_expr_list(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [less_than_tok];
var
  id_ptr: id_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  field_attributes_ptr: expr_attributes_ptr_type;
  field_ptr, last_field_ptr: expr_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        Get_next_token;
        id_ptr :=
          expr_attributes_ptr^.type_attributes_ptr^.field_table_ptr^.id_list;

        {*****************************************}
        { get comments at beginning of expression }
        {*****************************************}
        Get_prev_expr_info(expr_ptr^.expr_info_ptr);

        last_field_ptr := nil;
        while (id_ptr <> nil) do
          begin
            decl_attributes_ptr := Get_id_decl_attributes(id_ptr);
            field_attributes_ptr :=
              Get_prim_value_attributes(decl_attributes_ptr^.type_attributes_ptr^.kind);
            Parse_equal_expr(field_ptr, field_attributes_ptr);
            id_ptr := id_ptr^.next;

            {***********************************}
            { add array element to tail of list }
            {***********************************}
            if last_field_ptr <> nil then
              begin
                last_field_ptr^.next := field_ptr;
                last_field_ptr := field_ptr;
              end
            else
              begin
                expr_ptr^.field_exprs_ptr := field_ptr;
                last_field_ptr := field_ptr;
              end;
          end; {while}

        Match(greater_than_tok);

        {***********************************}
        { get comments at end of expression }
        {***********************************}
        Get_post_expr_info(expr_ptr^.expr_info_ptr);
      end
    else
      begin
        Parse_error;
        writeln('Expected a struct expression here.');
        error_reported := true;
      end;
end; {procedure Parse_struct_expr_list}


{************************  productions  ************************}
{       <struct_expr> ::= < <exprs> >                           }
{       <struct_expr> ::= <array_id>                            }
{***************************************************************}

procedure Parse_struct_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [less_than_tok];
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        expr_ptr := New_expr(struct_expr);
        expr_ptr^.struct_expr_size :=
          expr_attributes_ptr^.type_attributes_ptr^.size;
        Parse_struct_expr_list(expr_ptr, expr_attributes_ptr);
      end
    else
      begin
        Parse_error;
        writeln('Expected a struct expression here.');
        error_reported := true;
      end;
end; {procedure Parse_struct_expr}


procedure Parse_array_subexpr_elements(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  var array_bounds_list_ptr: array_bounds_list_ptr_type;
  var array_bounds_ptr: array_bounds_ptr_type;
  dereferenced: boolean);
var
  new_element_ptr, last_element_ptr: expr_ptr_type;
  element_bounds_ptr: array_bounds_ptr_type;
  counter: integer;
begin
  {***********************************}
  { parse array elements or subarrays }
  {***********************************}
  if array_bounds_ptr <> nil then
    begin
      {*********************************************}
      { sub arrays make link to parent array bounds }
      {*********************************************}
      expr_ptr^.array_expr_bounds_ref := array_bounds_ptr;
      element_bounds_ptr := array_bounds_ptr^.next;

      {**************************}
      { bounds are predetermined }
      {**************************}
      last_element_ptr := nil;
      counter := array_bounds_ptr^.min_val;
      while (counter <= array_bounds_ptr^.max_val) and parsing_ok do
        begin
          if dereferenced then
            Parse_equal_expr(new_element_ptr, expr_attributes_ptr)
          else
            Parse_array_subexpr(new_element_ptr, expr_attributes_ptr,
              array_bounds_list_ptr, element_bounds_ptr);

          counter := counter + 1;

          {***********************************}
          { add array element to tail of list }
          {***********************************}
          if (last_element_ptr <> nil) then
            begin
              last_element_ptr^.next := new_element_ptr;
              last_element_ptr := new_element_ptr;
            end
          else
            begin
              expr_ptr^.subarray_element_exprs_ptr := new_element_ptr;
              last_element_ptr := new_element_ptr;
            end;
        end; {while}
    end

  else
    begin
      {******************************}
      { bounds are not predetermined }
      {******************************}
      array_bounds_ptr := New_array_bounds;
      Add_array_bounds(array_bounds_list_ptr, array_bounds_ptr);
      expr_ptr^.array_expr_bounds_ref := array_bounds_ptr;
      element_bounds_ptr := nil;

      last_element_ptr := nil;
      counter := 0;
      while (next_token.kind <> right_bracket_tok) and parsing_ok do
        begin
          if dereferenced then
            Parse_equal_expr(new_element_ptr, expr_attributes_ptr)
          else
            Parse_array_subexpr(new_element_ptr, expr_attributes_ptr,
              array_bounds_list_ptr, element_bounds_ptr);

          counter := counter + 1;

          {***********************************}
          { add array element to tail of list }
          {***********************************}
          if (last_element_ptr <> nil) then
            begin
              last_element_ptr^.next := new_element_ptr;
              last_element_ptr := new_element_ptr;
            end
          else
            begin
              expr_ptr^.subarray_element_exprs_ptr := new_element_ptr;
              last_element_ptr := new_element_ptr;
            end;
        end; {while}

      {**********************}
      { set sub array bounds }
      {**********************}
      with array_bounds_ptr^ do
        begin
          min_val := 1;
          max_val := counter;
        end;
    end;
end; {procedure Parse_array_subexpr_elements}


procedure Parse_array_subexpr(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  array_bounds_list_ptr: array_bounds_list_ptr_type;
  var array_bounds_ptr: array_bounds_ptr_type);
const
  predict_set = [left_bracket_tok];
var
  relative_dimensions, absolute_dimensions: integer;
  type_attributes_ptr: type_attributes_ptr_type;
  dereferenced: boolean;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        {***************************************}
        { create new bounds list for array expr }
        {***************************************}
        Get_next_token;
        expr_ptr := New_expr(subarray_expr);

        {*****************************************}
        { get comments at beginning of expression }
        {*****************************************}
        Get_prev_expr_info(expr_ptr^.expr_info_ptr);

        {****************************}
        { find array attributes info }
        {****************************}
        type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
        relative_dimensions := type_attributes_ptr^.relative_dimensions;
        absolute_dimensions := type_attributes_ptr^.absolute_dimensions;

        {*******************************************************}
        { find element attributes, dereferencing, if neccessary }
        {*******************************************************}
        expr_attributes_ptr^.dimensions := expr_attributes_ptr^.dimensions - 1;
        if expr_attributes_ptr^.dimensions = absolute_dimensions -
          relative_dimensions then
          begin
            dereferenced := true;
            expr_attributes_ptr^.type_attributes_ptr :=
              expr_attributes_ptr^.type_attributes_ptr^.element_type_attributes_ptr;
          end
        else
          dereferenced := false;

        Parse_array_subexpr_elements(expr_ptr, expr_attributes_ptr,
          array_bounds_list_ptr, array_bounds_ptr, dereferenced);
        Match(right_bracket_tok);

        {********************}
        { restore attributes }
        {********************}
        expr_attributes_ptr^.type_attributes_ptr := type_attributes_ptr;
        expr_attributes_ptr^.dimensions := expr_attributes_ptr^.dimensions + 1;

        {***********************************}
        { get comments at end of expression }
        {***********************************}
        Get_post_expr_info(expr_ptr^.expr_info_ptr);
      end
    else
      begin
        Parse_error;
        writeln('Expected an array sub expression here.');
        error_reported := true;
      end;
end; {procedure Parse_array_subexpr}


function Prim_array_expr_kind(type_kind: type_kind_type): expr_kind_type;
var
  expr_kind: expr_kind_type;
begin
  case type_kind of

    {******************************}
    { enumerated array expressions }
    {******************************}
    type_boolean:
      expr_kind := boolean_array_expr;
    type_char:
      expr_kind := char_array_expr;

    {***************************}
    { integer array expressions }
    {***************************}
    type_byte:
      expr_kind := byte_array_expr;
    type_short:
      expr_kind := short_array_expr;
    type_integer:
      expr_kind := integer_array_expr;
    type_long:
      expr_kind := long_array_expr;

    {**************************}
    { scalar array expressions }
    {**************************}
    type_scalar:
      expr_kind := scalar_array_expr;
    type_double:
      expr_kind := double_array_expr;
    type_complex:
      expr_kind := complex_array_expr;
    type_vector:
      expr_kind := vector_array_expr;

    else
      expr_kind := error_expr;
  end; {case}

  Prim_array_expr_kind := expr_kind;
end; {function Prim_array_expr_kind}


function Array_expr_kind(type_attributes_ptr: type_attributes_ptr_type):
  expr_kind_type;
var
  expr_kind: expr_kind_type;
begin
  case type_attributes_ptr^.kind of

    {*****************************}
    { primitive array expressions }
    {*****************************}
    type_boolean..type_vector:
      expr_kind := Prim_array_expr_kind(type_attributes_ptr^.kind);

    {************************************************}
    { user defined type array expression assignments }
    {************************************************}
    type_enum:
      expr_kind := integer_array_expr;
    type_alias:
      expr_kind :=
        Array_expr_kind(type_attributes_ptr^.alias_type_attributes_ptr);
    type_array:
      expr_kind := array_array_expr;
    type_struct, type_class:
      expr_kind := struct_array_expr;
    type_class_alias:
      expr_kind :=
        Array_expr_kind(type_attributes_ptr^.class_alias_type_attributes_ptr);
    type_code:
      expr_kind := proto_array_expr;

    {************************************************}
    { general reference array expression assignments }
    {************************************************}
    type_reference:
      expr_kind := reference_array_expr;

    else
      expr_kind := error_expr;
  end; {case}

  Array_expr_kind := expr_kind;
end; {function Array_expr_kind}


procedure Parse_array_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [left_bracket_tok];
var
  new_element_ptr, last_element_ptr: expr_ptr_type;
  array_bounds_ptr, element_bounds_ptr: array_bounds_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  relative_dimensions, absolute_dimensions: integer;
  dereferenced: boolean;
  counter: integer;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        Get_next_token;

        if expr_attributes_ptr^.dimensions <> 0 then
          begin
            {****************************}
            { find array attributes info }
            {****************************}
            type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
            relative_dimensions := type_attributes_ptr^.relative_dimensions;
            absolute_dimensions := expr_attributes_ptr^.dimensions;

            {*******************************}
            { create new element attributes }
            {*******************************}
            expr_attributes_ptr :=
              New_value_expr_attributes(type_attributes_ptr);

            {*******************************************************}
            { find element attributes, dereferencing, if neccessary }
            {*******************************************************}
            expr_attributes_ptr^.dimensions := expr_attributes_ptr^.dimensions -
              1;
            if expr_attributes_ptr^.dimensions = absolute_dimensions -
              relative_dimensions then
              begin
                expr_attributes_ptr^.type_attributes_ptr :=
                  type_attributes_ptr^.element_type_attributes_ptr;
                dereferenced := true;
              end
            else
              dereferenced := false;

            {*****************************}
            { create new array expression }
            {*****************************}
            expr_ptr :=
              New_expr(Array_expr_kind(Unalias_type_attributes(type_attributes_ptr)^.element_type_attributes_ptr));

            {*****************************************}
            { get comments at beginning of expression }
            {*****************************************}
            Get_prev_expr_info(expr_ptr^.expr_info_ptr);

            {***************************************}
            { create new bounds list for array expr }
            {***************************************}
            expr_ptr^.array_expr_bounds_list_ptr := New_array_bounds_list;
            array_bounds_ptr := New_array_bounds;
            Add_array_bounds(expr_ptr^.array_expr_bounds_list_ptr,
              array_bounds_ptr);
            element_bounds_ptr := nil;

            {***********************************}
            { parse array elements or subarrays }
            {***********************************}
            counter := 0;
            last_element_ptr := nil;
            while (next_token.kind <> right_bracket_tok) and parsing_ok do
              begin
                if dereferenced then
                  Parse_equal_expr(new_element_ptr, expr_attributes_ptr)
                else
                  Parse_array_subexpr(new_element_ptr, expr_attributes_ptr,
                    expr_ptr^.array_expr_bounds_list_ptr, element_bounds_ptr);

                counter := counter + 1;

                {***********************************}
                { add array element to tail of list }
                {***********************************}
                if (last_element_ptr <> nil) then
                  begin
                    last_element_ptr^.next := new_element_ptr;
                    last_element_ptr := new_element_ptr;
                  end
                else
                  begin
                    expr_ptr^.array_element_exprs_ptr := new_element_ptr;
                    last_element_ptr := new_element_ptr;
                  end;
              end; {while}

            {******************}
            { set array bounds }
            {******************}
            with array_bounds_ptr^ do
              begin
                min_val := 1;
                max_val := counter;
              end;

            {**********************}
            { set array attributes }
            {**********************}
            expr_attributes_ptr^.type_attributes_ptr := type_attributes_ptr;
            expr_attributes_ptr^.dimensions := absolute_dimensions;
            Set_expr_attributes(expr_ptr, expr_attributes_ptr);

            Match(right_bracket_tok);

            {***********************************}
            { get comments at end of expression }
            {***********************************}
            Get_post_expr_info(expr_ptr^.expr_info_ptr);
          end
        else
          begin
            Parse_error;
            writeln('An array is not expected here.');
            error_reported := true;
          end;
      end
    else
      begin
        Parse_error;
        writeln('Expected an array expression here.');
        error_reported := true;
      end;
end; {procedure Parse_array_expr}


procedure Parse_string_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if next_token.kind = string_lit_tok then
    begin
      Make_string_expr(expr_ptr, expr_attributes_ptr, next_token.string_ptr);
      Get_next_token;
    end
  else
    begin
      Parse_error;
      writeln('Expected a string literal here.');
      error_reported := true;
    end;
end; {procedure Parse_string_expr}


end.

