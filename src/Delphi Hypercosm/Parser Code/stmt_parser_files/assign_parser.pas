unit assign_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            assign_parser              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse assignments      }
{       into an abstract syntax tree representation.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  expr_attributes, exprs, stmts;


{*************************************************}
{ routines to parse general assignment statements }
{*************************************************}
procedure Parse_assign_stmt_tail(var stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);

{********************************}
{ routines to parse initializers }
{********************************}
procedure Parse_assign_tail(var stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_ptr_assign_tail(var stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_ref_assign_tail(var stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);

{*************************************}
{ routines to help parse initializers }
{*************************************}
function Same_identifiers(expr_ptr1, expr_ptr2: expr_ptr_type): boolean;


implementation
uses
  strings, code_types, type_attributes, code_attributes, decl_attributes,
    code_decls, type_decls, scanner, tokens, tokenizer, parser, comment_parser,
    match_literals, term_parser, expr_parser, type_assigns, struct_assigns,
    array_assigns, array_expr_assigns, implicit_derefs;


function Same_identifiers(expr_ptr1, expr_ptr2: expr_ptr_type): boolean;
var
  same: boolean;
  expr_attributes_ptr1, expr_attributes_ptr2: expr_attributes_ptr_type;
  decl_attributes_ptr1, decl_attributes_ptr2: decl_attributes_ptr_type;
begin
  same := true;
  if (expr_ptr1 = expr_ptr2) then
    same := true
  else if (expr_ptr1^.kind <> expr_ptr2^.kind) then
    same := false
  else
    case expr_ptr1^.kind of

      {*************}
      { identifiers }
      {*************}
      global_identifier, local_identifier, field_identifier:
        begin
          expr_attributes_ptr1 := expr_ptr1^.expr_info_ptr^.expr_attributes_ptr;
          expr_attributes_ptr2 := expr_ptr2^.expr_info_ptr^.expr_attributes_ptr;
          decl_attributes_ptr1 := expr_attributes_ptr1^.decl_attributes_ptr;
          decl_attributes_ptr2 := expr_attributes_ptr2^.decl_attributes_ptr;
          same := (decl_attributes_ptr1 = decl_attributes_ptr2);
        end;
      nested_identifier:
        same := Same_identifiers(expr_ptr1^.nested_id_expr_ptr,
          expr_ptr2^.nested_id_expr_ptr);

      {**************************}
      { identifier dereferencing }
      {**************************}
      deref_op, address_op:
        same := Same_identifiers(expr_ptr1^.operand_ptr,
          expr_ptr2^.operand_ptr);

      {*********************}
      { array dereferencing }
      {*********************}
      boolean_array_deref..reference_array_deref:
        same := false;

      {****************************}
      { array subrange expressions }
      {****************************}
      boolean_array_subrange..reference_array_subrange:
        same := false;

      {*************************}
      { structure dereferencing }
      {*************************}
      struct_deref, struct_offset:
        begin
          same := Same_identifiers(expr_ptr1^.base_expr_ptr,
            expr_ptr2^.base_expr_ptr);
          if same then
            same := Same_identifiers(expr_ptr1^.field_expr_ptr,
              expr_ptr2^.field_expr_ptr);
        end;
      field_deref, field_offset:
        same := Same_identifiers(expr_ptr1^.field_name_ptr,
          expr_ptr2^.field_name_ptr);
    end;

  Same_identifiers := same;
end; {function Same_identifiers}


function New_value_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  if expr_attributes_ptr^.dimensions = 0 then
    stmt_ptr := New_element_assign(lhs_data_ptr, rhs_expr_ptr,
      expr_attributes_ptr^.type_attributes_ptr)
  else
    stmt_ptr := New_array_value_assign(lhs_data_ptr, rhs_expr_ptr);

  New_value_assign := stmt_ptr;
end; {function New_value_assign}


procedure Parse_struct_assign_tail(var stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type);
var
  rhs_expr_ptr: expr_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
begin
  if parsing_ok then
    begin
      {******************************************}
      { create and initialize new statement info }
      {******************************************}
      stmt_info_ptr := New_stmt_info;
      stmt_info_ptr^.line_number := Get_line_number;

      Deref_expr(expr_ptr, expr_attributes_ptr);
      Match(equal_tok);

      {********************************************}
      { search scope for possible antecedent 'its' }
      {********************************************}
      Push_antecedent_scope(expr_ptr, expr_attributes_ptr);
      Parse_same_expr(rhs_expr_ptr, expr_attributes_ptr);
      Pop_antecedent_scope;

      if parsing_ok then
        begin
          stmt_ptr := New_struct_assign(expr_ptr, rhs_expr_ptr);

          if stmt_ptr <> nil then
            begin
              {************************************}
              { save comments at end of expression }
              {************************************}
              Get_post_stmt_info(stmt_info_ptr);
              Set_stmt_info(stmt_ptr, stmt_info_ptr);
            end
          else
            begin
              Parse_error;
              writeln('Invalid value assignment.');
              error_reported := true;
            end;
        end;

      {********************************}
      { check to see that we are not   }
      { assigning a variable to itself }
      {********************************}
      if parsing_ok then
        if Same_identifiers(expr_ptr, rhs_expr_ptr) then
          begin
            Parse_error;
            writeln('Can not assign a variable to itself.');
            error_reported := true;
          end;

    end; {if parsing_ok}
end; {procedure Parse_struct_assign_tail}


{************************  productions  ************************}
{       <assign_tail> ::= = <expr> ;                            }
{       <assign_tail> ::= is <expr> ;                           }
{       <assign_tail> ::= does <expr> ;                         }
{***************************************************************}

procedure Parse_assign_tail(var stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  rhs_expr_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
begin
  if parsing_ok then
    begin
      type_attributes_ptr :=
        Deref_type_attributes(expr_attributes_ptr^.type_attributes_ptr);
      type_attributes_ptr := Unalias_type_attributes(type_attributes_ptr);

      if type_attributes_ptr^.kind in structured_type_kinds then
        Parse_struct_assign_tail(stmt_ptr, expr_ptr, expr_attributes_ptr,
          type_attributes_ptr)
      else
        begin
          {******************************************}
          { create and initialize new statement info }
          {******************************************}
          stmt_info_ptr := New_stmt_info;
          stmt_info_ptr^.line_number := Get_line_number;
          Deref_expr(expr_ptr, expr_attributes_ptr);

          {***********************************************}
          { match is or = depending upon type enumeration }
          {***********************************************}
          if expr_attributes_ptr^.dimensions = 0 then
            case expr_attributes_ptr^.type_attributes_ptr^.kind of

              type_boolean, type_char, type_enum:
                Match(is_tok);

              type_byte, type_short, type_integer, type_long:
                Match(equal_tok);

              type_scalar, type_double, type_complex, type_vector:
                Match(equal_tok);

              type_array:
                Match(equal_tok);

              type_code:
                Match(does_tok);

            end {case}
          else
            begin
              {************}
              { sub arrays }
              {************}
              Match(equal_tok);
            end;

          Parse_equal_expr(rhs_expr_ptr, expr_attributes_ptr);

          if parsing_ok then
            begin
              stmt_ptr := New_value_assign(expr_ptr, rhs_expr_ptr,
                expr_attributes_ptr);

              if stmt_ptr <> nil then
                begin
                  {************************************}
                  { save comments at end of expression }
                  {************************************}
                  Get_post_stmt_info(stmt_info_ptr);
                  Set_stmt_info(stmt_ptr, stmt_info_ptr);
                end
              else
                begin
                  Parse_error;
                  writeln('Invalid value assignment.');
                  error_reported := true;
                end;
            end;

          {********************************}
          { check to see that we are not   }
          { assigning a variable to itself }
          {********************************}
          if parsing_ok then
            if Same_identifiers(expr_ptr, rhs_expr_ptr) then
              begin
                Parse_error;
                writeln('Can not assign a variable to itself.');
                error_reported := true;
              end;
        end;
    end; {if parsing_ok}
end; {procedure Parse_assign_tail}


procedure Parse_array_ptr_assign_rhs(var stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  rhs_expr_ptr: expr_ptr_type;
  structural_dimensions, logical_dimensions: integer;
begin
  if parsing_ok then
    begin
      structural_dimensions :=
        expr_attributes_ptr^.type_attributes_ptr^.absolute_dimensions;
      logical_dimensions := expr_attributes_ptr^.dimensions;

      if logical_dimensions = structural_dimensions then
        begin
          if not (next_token.kind in [string_lit_tok, left_bracket_tok]) then
            begin
              {***************************}
              { assign a single array ptr }
              {***************************}
              Parse_same_expr(rhs_expr_ptr, expr_attributes_ptr);
              if parsing_ok then
                stmt_ptr := New_array_ptr_assign(expr_ptr, rhs_expr_ptr);
            end
          else
            begin
              {****************************}
              { assign an array expression }
              {****************************}
              Parse_equal_expr(rhs_expr_ptr, expr_attributes_ptr);
              if parsing_ok then
                stmt_ptr := New_array_ptr_assign(expr_ptr, rhs_expr_ptr);
            end;
        end
      else
        begin
          {*******************************}
          { assign an array of array ptrs }
          {*******************************}
          Parse_equal_expr(rhs_expr_ptr, expr_attributes_ptr);
          if parsing_ok then
            stmt_ptr := New_array_ptr_array_assign(expr_ptr, rhs_expr_ptr);
        end;

      {********************************}
      { check to see that we are not   }
      { assigning a variable to itself }
      {********************************}
      if parsing_ok then
        if Same_identifiers(expr_ptr, rhs_expr_ptr) then
          begin
            Parse_error;
            writeln('Can not assign a variable to itself.');
            error_reported := true;
          end;
    end; {if parsing_ok}
end; {procedure Parse_array_ptr_assign_rhs}


procedure Parse_struct_ptr_assign_rhs(var stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  rhs_expr_ptr: expr_ptr_type;
begin
  if parsing_ok then
    begin
      {******************************************}
      { push scope for possible antecedent 'its' }
      {******************************************}
      Push_antecedent_scope(expr_ptr, expr_attributes_ptr);
      Parse_same_expr(rhs_expr_ptr, expr_attributes_ptr);

      if parsing_ok then
        stmt_ptr := New_struct_ptr_assign(expr_ptr, rhs_expr_ptr);

      {*****************************************}
      { pop scope for possible antecedent 'its' }
      {*****************************************}
      Pop_antecedent_scope;

      {********************************}
      { check to see that we are not   }
      { assigning a variable to itself }
      {********************************}
      if parsing_ok then
        if Same_identifiers(expr_ptr, rhs_expr_ptr) then
          begin
            Parse_error;
            writeln('Can not assign a variable to itself.');
            error_reported := true;
          end;
    end; {if parsing_ok}
end; {procedure Parse_struct_ptr_assign_rhs}


{************************  productions  ************************}
{       <assign_tail> ::= is <expr> ;                           }
{***************************************************************}

procedure Parse_ptr_assign_tail(var stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
begin
  if parsing_ok then
    begin
      {******************************************}
      { create and initialize new statement info }
      {******************************************}
      stmt_info_ptr := New_stmt_info;
      stmt_info_ptr^.line_number := Get_line_number;

      Deref_expr(expr_ptr, expr_attributes_ptr);
      if expr_attributes_ptr^.type_attributes_ptr^.static then
        begin
          Parse_error;
          writeln('Can not assign static types by reference.');
          error_reported := true;
        end
      else if not expr_attributes_ptr^.decl_attributes_ptr^.dynamic then
        begin
          Parse_error;
          writeln('Can not assign static types by reference.');
          error_reported := true;
        end
      else
        begin
          Match(is_tok);

          case expr_attributes_ptr^.type_attributes_ptr^.kind of

            {**********************}
            { array ptr assignment }
            {**********************}
            type_array:
              Parse_array_ptr_assign_rhs(stmt_ptr, expr_ptr,
                expr_attributes_ptr);

            {**************************}
            { structure ptr assignment }
            {**************************}
            type_struct, type_class:
              Parse_struct_ptr_assign_rhs(stmt_ptr, expr_ptr,
                expr_attributes_ptr);

          end; {case}
        end;

      if parsing_ok then
        Set_stmt_info(stmt_ptr, stmt_info_ptr);
    end; {if parsing_ok}
end; {procedure Parse_ptr_assign_tail}


{************************  productions  ************************}
{       <assign_tail> ::= refers to <expr> ;                    }
{***************************************************************}

procedure Parse_ref_assign_tail(var stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  rhs_expr_ptr: expr_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
begin
  if parsing_ok then
    if expr_attributes_ptr^.type_attributes_ptr^.kind <> type_reference then
      begin
        Parse_error;
        writeln('Expected a reference here.');
        error_reported := true;
      end
    else
      begin
        {******************************************}
        { create and initialize new statement info }
        {******************************************}
        stmt_info_ptr := New_stmt_info;
        stmt_info_ptr^.line_number := Get_line_number;

        Match(refers_tok);
        Match(to_tok);

        {**************************************************}
        { push and pop scope for possible antecedent 'its' }
        {**************************************************}
        if expr_attributes_ptr^.type_attributes_ptr^.kind in
          structured_type_kinds then
          begin
            Push_antecedent_scope(expr_ptr, expr_attributes_ptr);
            Parse_same_expr(rhs_expr_ptr, expr_attributes_ptr);
            Pop_antecedent_scope;
          end
        else
          Parse_same_expr(rhs_expr_ptr, expr_attributes_ptr);

        if parsing_ok then
          begin
            stmt_ptr := New_reference_assign(expr_ptr, rhs_expr_ptr);

            if stmt_ptr <> nil then
              begin
                {************************************}
                { save comments at end of expression }
                {************************************}
                Get_post_stmt_info(stmt_info_ptr);
                Set_stmt_info(stmt_ptr, stmt_info_ptr);
              end
            else
              begin
                Parse_error;
                writeln('Invalid reference assignment.');
                error_reported := true;
              end;
          end;

        {********************************}
        { check to see that we are not   }
        { assigning a variable to itself }
        {********************************}
        if parsing_ok then
          if Same_identifiers(expr_ptr, rhs_expr_ptr) then
            begin
              Parse_error;
              writeln('Can not assign a variable to itself.');
              error_reported := true;
            end;

      end; {if parsing_ok}
end; {procedure Parse_ref_assign_tail}


{*************************************************}
{ routines to parse general assignment statements }
{*************************************************}


procedure Parse_assign_stmt_tail(var stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
begin
  decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
  type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;

  {*********************************}
  { check lhs expression attributes }
  {*********************************}
  if (decl_attributes_ptr = nil) then
    begin
      Parse_error;
      writeln('Can not assign to this expression');
      error_reported := true;
    end

  else if decl_attributes_ptr^.kind = type_decl_attributes then
    begin
      Parse_error;
      writeln('Can not assign to a type.');
      error_reported := true;
    end

  else if next_token.kind <> refers_tok then
    begin
      if (decl_attributes_ptr^.final and (type_attributes_ptr^.kind <>
        type_reference)) or (decl_attributes_ptr^.final_reference) then
        begin
          Parse_error;
          writeln('Can not assign to a constant or final value.');
          error_reported := true;
        end
      else
        begin
          {*****************}
          { primitive types }
          {*****************}
          type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);
          type_attributes_ptr := Unalias_type_attributes(type_attributes_ptr);

          if not (type_attributes_ptr^.kind in reference_type_kinds) then
            Parse_assign_tail(stmt_ptr, expr_ptr, expr_attributes_ptr)

            {*****************}
            { reference types }
            {*****************}
          else
            case next_token.kind of
              equal_tok, does_tok:
                Parse_assign_tail(stmt_ptr, expr_ptr, expr_attributes_ptr);

              is_tok:
                Parse_ptr_assign_tail(stmt_ptr, expr_ptr, expr_attributes_ptr);
            end;
        end;
    end

      {***********************}
      { reference assignments }
      {***********************}
  else
    begin
      if (type_attributes_ptr^.kind = type_reference) and not
        decl_attributes_ptr^.implicit_reference then
        begin
          if decl_attributes_ptr^.final then
            begin
              Parse_error;
              writeln('Can not assign to a constant or final reference.');
              error_reported := true;
            end
          else
            Parse_ref_assign_tail(stmt_ptr, expr_ptr, expr_attributes_ptr);
        end
      else
        begin
          Parse_error;
          writeln('Expected a reference here');
          error_reported := true;
        end;
    end;
end; {procedure Parse_assign_stmt_tail}


end.
