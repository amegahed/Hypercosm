unit value_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            value_parser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse expression       }
{       values into an abstract syntax tree representation.     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  code_attributes, expr_attributes, exprs, stmts, tokens;


const
  param_delimeter_set = [with_tok, is_tok, return_tok, end_tok];


  {**************************************************}
  { routine to create assign based on parameter type }
  {**************************************************}
function New_param_expr(parameter_ptr: parameter_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type): expr_ptr_type;
function New_param_assign(lhs_data_ptr: expr_ptr_type;
  rhs_expr_ptr: expr_ptr_type;
  lhs_expr_attributes_ptr: expr_attributes_ptr_type): stmt_ptr_type;

{***************************************************}
{ routines to parse formatted parameter assignments }
{***************************************************}
procedure Parse_formatted_param_values(code_attributes_ptr:
  code_attributes_ptr_type;
  var stmt_ptr: stmt_ptr_type);
procedure Parse_formatted_return_values(code_attributes_ptr:
  code_attributes_ptr_type;
  var stmt_ptr: stmt_ptr_type);


implementation
uses
  strings, code_types, symbol_tables, type_attributes, decl_attributes,
    compare_types, type_assigns, struct_assigns, array_assigns,
    array_expr_assigns, tokenizer, parser, comment_parser, match_terms,
    expr_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


type
  value_kind_type = (unit_value, expr_value);
  param_kind_type = (in_param, out_param);


  {*********************************************}
  { routines for creating parameter assignments }
  {*********************************************}


function New_param_expr(parameter_ptr: parameter_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type): expr_ptr_type;
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  expr_ptr: expr_ptr_type;
begin
  decl_attributes_ptr :=
    decl_attributes_ptr_type(Get_id_value(parameter_ptr^.id_ptr));
  expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);

  New_param_expr := expr_ptr;
end; {function New_param_expr}


function New_param_assign(lhs_data_ptr: expr_ptr_type;
  rhs_expr_ptr: expr_ptr_type;
  lhs_expr_attributes_ptr: expr_attributes_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
  rhs_expr_attributes_ptr: expr_attributes_ptr_type;
  lhs_type_attributes_ptr, rhs_type_attributes_ptr: type_attributes_ptr_type;
begin
  if lhs_expr_attributes_ptr^.type_attributes_ptr^.kind = type_reference then
    stmt_ptr := New_reference_assign(lhs_data_ptr, rhs_expr_ptr)
  else
    begin
      lhs_type_attributes_ptr := lhs_expr_attributes_ptr^.type_attributes_ptr;

      if lhs_expr_attributes_ptr^.dimensions = 0 then
        begin
          {***********************}
          { non array assignments }
          {***********************}
          if lhs_type_attributes_ptr^.kind in [type_struct, type_class] then
            begin
              if lhs_type_attributes_ptr^.static then
                stmt_ptr := New_struct_assign(lhs_data_ptr, rhs_expr_ptr)
              else
                stmt_ptr := New_struct_ptr_assign(lhs_data_ptr, rhs_expr_ptr);
            end
          else
            stmt_ptr := New_type_assign(lhs_data_ptr, rhs_expr_ptr,
              lhs_type_attributes_ptr);
        end
      else
        begin
          {*******************}
          { array assignments }
          {*******************}
          if rhs_expr_ptr^.kind in array_element_set then
            stmt_ptr := New_array_expr_assign(lhs_data_ptr, rhs_expr_ptr)
          else
            begin
              rhs_expr_attributes_ptr := Get_expr_attributes(rhs_expr_ptr);
              rhs_type_attributes_ptr :=
                rhs_expr_attributes_ptr^.type_attributes_ptr;

              if Same_type_attributes(lhs_type_attributes_ptr,
                rhs_type_attributes_ptr) then
                stmt_ptr := New_array_ptr_assign(lhs_data_ptr, rhs_expr_ptr)
              else
                stmt_ptr := New_array_value_assign(lhs_data_ptr, rhs_expr_ptr);
            end;
        end;
    end;

  New_param_assign := stmt_ptr;
end; {function New_param_assign}


{*******************************}
{ parsing parameter expressions }
{*******************************}


procedure Parse_param_assign(var stmt_ptr: stmt_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  value_kind: value_kind_type;
  param_kind: param_kind_type);
var
  expr_ptr, param_expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      {****************************}
      { create parameter reference }
      {****************************}
      param_expr_ptr := New_identifier(decl_attributes_ptr,
        expr_attributes_ptr);

      {********************************}
      { parse value unit or expression }
      {********************************}
      if (param_kind = in_param) and
        (decl_attributes_ptr^.type_attributes_ptr^.kind <> type_reference) or
        (decl_attributes_ptr^.implicit_reference) then
        case value_kind of
          unit_value:
            Parse_equal_unit(expr_ptr, expr_attributes_ptr);
          expr_value:
            Parse_equal_expr(expr_ptr, expr_attributes_ptr);
        end
      else
        case value_kind of
          unit_value:
            Parse_same_unit(expr_ptr, expr_attributes_ptr);
          expr_value:
            Parse_same_expr(expr_ptr, expr_attributes_ptr);
        end;

      if parsing_ok then
        begin
          case param_kind of
            in_param:
              stmt_ptr := New_param_assign(param_expr_ptr, expr_ptr,
                expr_attributes_ptr);
            out_param:
              stmt_ptr := New_param_assign(expr_ptr, param_expr_ptr,
                expr_attributes_ptr);
          end; {case}

          if stmt_ptr = nil then
            begin
              Parse_error;
              writeln('Invalid parameter assignment.');
              error_reported := true;
            end;
        end;

    end; {if parsing_ok}
end; {procedure Parse_param_assign}


procedure Parse_parameter(var stmt_ptr: stmt_ptr_type;
  var last_stmt_ptr: stmt_ptr_type;
  parameter_ptr: parameter_ptr_type;
  value_kind: value_kind_type;
  param_kind: param_kind_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  new_stmt_ptr: stmt_ptr_type;
begin
  {****************************}
  { parse parameter assignment }
  {****************************}
  if parsing_ok then
    begin
      {***************************}
      { create new parameter expr }
      {***************************}
      decl_attributes_ptr :=
        decl_attributes_ptr_type(Get_id_value(parameter_ptr^.id_ptr));

      {***************************************************}
      { make reference or value parameter assignment stmt }
      {***************************************************}
      Parse_param_assign(new_stmt_ptr, decl_attributes_ptr, value_kind,
        param_kind);

      {************************************}
      { add assignment stmt to end of list }
      {************************************}
      if (last_stmt_ptr <> nil) then
        begin
          last_stmt_ptr^.next := new_stmt_ptr;
          last_stmt_ptr := new_stmt_ptr;
        end
      else
        begin
          stmt_ptr := new_stmt_ptr;
          last_stmt_ptr := new_stmt_ptr;
        end;
    end;
end; {procedure Parse_parameter}


procedure Parse_parameters(var stmt_ptr: stmt_ptr_type;
  var last_stmt_ptr: stmt_ptr_type;
  parameter_ptr: parameter_ptr_type;
  value_kind: value_kind_type;
  param_kind: param_kind_type);
begin
  {*************************************}
  { parse list of parameter assignments }
  {*************************************}
  while (parameter_ptr <> nil) and parsing_ok do
    begin
      if (last_stmt_ptr <> nil) then
        Parse_parameter(last_stmt_ptr^.next, last_stmt_ptr, parameter_ptr,
          value_kind, param_kind)
      else
        Parse_parameter(stmt_ptr, last_stmt_ptr, parameter_ptr, value_kind,
          param_kind);

      parameter_ptr := parameter_ptr^.next;
    end;
end; {procedure Parse_parameters}


procedure Parse_keywords(keyword_ptr: keyword_ptr_type);
var
  found: boolean;
begin
  {************************************************}
  { parse the remaining keywords for the parameter }
  {************************************************}
  while (keyword_ptr <> nil) and parsing_ok do
    begin
      found := next_token.kind in reserved_word_set + id_expr_predict_set;
      if found then
        found := Token_to_id(next_token) = keyword_ptr^.keyword;

      if found then
        begin
          Get_next_token;
          keyword_ptr := keyword_ptr^.next;
        end
      else
        begin
          Parse_error;
          writeln('Expected the keyword, ', Quotate_str(keyword_ptr^.keyword),
            ', here.');
          error_reported := true;
        end;
    end;
end; {procedure Parse_keywords}


{************************  productions  ************************}
{       <param_value> ::= <expr>                                }
{***************************************************************}

procedure Parse_optional_params(code_attributes_ptr: code_attributes_ptr_type;
  var stmt_ptr: stmt_ptr_type;
  var last_stmt_ptr: stmt_ptr_type;
  param_kind: param_kind_type);
var
  keyword: string_type;
  signature_ptr: signature_ptr_type;
  id_ptr: id_ptr_type;
  keyword_count: integer;
  value_kind: value_kind_type;
begin
  if parsing_ok then
    if next_token.kind in reserved_word_set + id_expr_predict_set then
      if not (next_token.kind in param_delimeter_set) then
        begin
          keyword := Token_to_id(next_token);

          if Found_id_by_name(code_attributes_ptr^.keyword_table_ptr, id_ptr,
            keyword) then
            begin
              {*************************************}
              { advance to proper keyword parameter }
              {*************************************}
              signature_ptr := code_attributes_ptr^.signature_ptr;
              keyword_count := 0;
              while (keyword_count < id_ptr^.value) do
                begin
                  while (signature_ptr^.keyword_ptr = nil) do
                    signature_ptr := signature_ptr^.next;
                  keyword_count := keyword_count + 1;
                  if (keyword_count < id_ptr^.value) then
                    signature_ptr := signature_ptr^.next;
                end;

              {*************************}
              { parse keyword parameter }
              {*************************}
              if signature_ptr^.optional then
                begin
                  if code_attributes_ptr^.kind in functional_code_kinds then
                    value_kind := unit_value
                  else
                    value_kind := expr_value;

                  with signature_ptr^ do
                    begin
                      Parse_keywords(keyword_ptr);
                      Parse_parameters(stmt_ptr, last_stmt_ptr, parameter_ptr,
                        value_kind, param_kind);
                    end;

                  if parsing_ok then
                    if last_stmt_ptr <> nil then
                      Parse_optional_params(code_attributes_ptr,
                        last_stmt_ptr^.next, last_stmt_ptr, param_kind)
                    else
                      Parse_optional_params(code_attributes_ptr, stmt_ptr,
                        last_stmt_ptr, param_kind);
                end;
            end;
        end;
end; {procedure Parse_optional_params}


{************************  productions  ************************}
{       <param_value> ::= <expr>                                }
{***************************************************************}

procedure Parse_param_value(var stmt_ptr: stmt_ptr_type;
  var last_stmt_ptr: stmt_ptr_type;
  signature_ptr: signature_ptr_type;
  value_kind: value_kind_type;
  param_kind: param_kind_type);
begin
  if parsing_ok then
    begin
      {***********************}
      { match mandatory param }
      {***********************}
      if signature_ptr <> nil then
        with signature_ptr^ do
          begin
            if (signature_ptr^.keyword_ptr <> nil) then
              begin
                {*************************************}
                { matched mandatory keyword parameter }
                {*************************************}
                Parse_keywords(keyword_ptr);
                Parse_parameters(stmt_ptr, last_stmt_ptr, parameter_ptr,
                  value_kind, param_kind);
              end
            else
              begin
                {*****************}
                { non-identifiers }
                {*****************}
                Parse_parameters(stmt_ptr, last_stmt_ptr, parameter_ptr,
                  value_kind, param_kind);
              end;
          end;
    end;
end; {procedure Parse_param_value}


{************************  productions  ************************}
{       <more_param_values> ::= <param_values>                  }
{       <more_param_values> ::=                                 }
{***************************************************************}

procedure Parse_more_param_values(code_attributes_ptr: code_attributes_ptr_type;
  var stmt_ptr: stmt_ptr_type;
  var last_stmt_ptr: stmt_ptr_type;
  signature_ptr: signature_ptr_type;
  param_kind: param_kind_type);
var
  optional_stmt_ptr, last_optional_stmt_ptr: stmt_ptr_type;
  value_kind: value_kind_type;
  done: boolean;
begin
  if parsing_ok then
    begin
      {*****************************************}
      { try to match one of the optional params }
      {*****************************************}
      optional_stmt_ptr := nil;
      last_optional_stmt_ptr := nil;
      Parse_optional_params(code_attributes_ptr, optional_stmt_ptr,
        last_optional_stmt_ptr, param_kind);

      {******************************}
      { scan through optional params }
      {******************************}
      done := false;
      while not done do
        begin
          if (signature_ptr = nil) then
            done := true
          else if (not signature_ptr^.optional) then
            done := true
          else
            signature_ptr := signature_ptr^.next;
        end;

      if code_attributes_ptr^.kind in functional_code_kinds then
        value_kind := unit_value
      else
        value_kind := expr_value;

      {************************}
      { parse mandatory params }
      {************************}
      Parse_param_value(stmt_ptr, last_stmt_ptr, signature_ptr, value_kind,
        param_kind);
      if (stmt_ptr <> nil) and parsing_ok then
        Parse_more_param_values(code_attributes_ptr, last_stmt_ptr^.next,
          last_stmt_ptr, signature_ptr^.next, param_kind);

      {*************************************************}
      { add optional param assigns to beginning of list }
      {*************************************************}
      if (optional_stmt_ptr <> nil) then
        begin
          if (last_stmt_ptr <> nil) then
            begin
              last_optional_stmt_ptr^.next := stmt_ptr;
              last_stmt_ptr := last_optional_stmt_ptr;
              stmt_ptr := optional_stmt_ptr;
            end
          else
            begin
              stmt_ptr := optional_stmt_ptr;
              last_stmt_ptr := last_optional_stmt_ptr;
            end;
        end;
    end;
end; {procedure Parse_more_param_values}


{************************  productions  ************************}
{       <param_values> ::= <param_value> <more_param_values>    }
{       <param_values> ::=                                      }
{***************************************************************}

procedure Parse_formatted_param_values(code_attributes_ptr:
  code_attributes_ptr_type;
  var stmt_ptr: stmt_ptr_type);
var
  last_stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := nil;
  last_stmt_ptr := nil;
  Parse_more_param_values(code_attributes_ptr, stmt_ptr, last_stmt_ptr,
    code_attributes_ptr^.signature_ptr, in_param);
end; {procedure Parse_formatted_param_values}


procedure Parse_formatted_return_values(code_attributes_ptr:
  code_attributes_ptr_type;
  var stmt_ptr: stmt_ptr_type);
var
  last_stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := nil;
  last_stmt_ptr := nil;
  Parse_more_param_values(code_attributes_ptr, stmt_ptr, last_stmt_ptr,
    code_attributes_ptr^.return_signature_ptr, out_param);
end; {procedure Parse_formatted_return_values}


end.
