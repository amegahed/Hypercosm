unit id_expr_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           id_expr_parser              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse expressions      }
{       into an abstract syntax tree representation.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  expr_attributes, exprs;


procedure Parse_type_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_id_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_type_id_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);


implementation
uses
  strings, code_types, make_exprs, symbol_tables, type_attributes,
  code_attributes, stmt_attributes, decl_attributes, value_attributes,
  compare_types, stmts, decls, code_decls, type_decls, tokens, tokenizer,
  parser, match_literals, term_parser, member_parser, scoping, implicit_derefs,
    expr_parser, msg_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}



function New_ptr_cast(class_type_ptr: type_ptr_type;
  expr_ptr: expr_ptr_type): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
begin
  new_expr_ptr := New_expr(ptr_cast);
  new_expr_ptr^.desired_subclass_ref := forward_type_ref_type(class_type_ptr);
  new_expr_ptr^.class_expr_ptr := expr_ptr;
  New_ptr_cast := new_expr_ptr;
end; {function New_ptr_cast}


procedure Parse_ptr_cast(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type);
var
  class_type_ptr: type_ptr_type;
  expr_info_ptr: expr_info_ptr_type;
  castable: boolean;
begin
  if parsing_ok then
    begin
      type_attributes_ptr := Unalias_type_attributes(type_attributes_ptr);

      if type_attributes_ptr^.kind = type_class then
        begin
          {*******************************************}
          { get type declaration from type descriptor }
          {*******************************************}
          class_type_ptr := Get_type_decl(type_attributes_ptr);

          {*****************************}
          { parse expression to be cast }
          {*****************************}
          Parse_unit(expr_ptr, expr_attributes_ptr);

          if parsing_ok then
            begin
              Deref_expr(expr_ptr, expr_attributes_ptr);

              {*************************************}
              { check types for pointer equivalence }
              {*************************************}
              if class_type_ptr^.class_kind <> interface_class then
                castable :=
                  Same_type_attributes(expr_attributes_ptr^.type_attributes_ptr,
                  type_attributes_ptr)
              else
                castable := true;

              {*****************}
              { create ptr cast }
              {*****************}
              if castable then
                begin
                  expr_ptr := New_ptr_cast(class_type_ptr, expr_ptr);
                  if parsing_ok then
                    begin
                      expr_info_ptr := New_expr_info;
                      Set_expr_info(expr_ptr, expr_info_ptr);
                      expr_attributes_ptr :=
                        New_value_expr_attributes(type_attributes_ptr);
                      Set_expr_attributes(expr_ptr, expr_attributes_ptr);
                    end;
                end
              else
                begin
                  Parse_error;
                  write('Can not cast a variable of ');
                  writeln(Get_type_attributes_name(expr_attributes_ptr^.type_attributes_ptr));
                  write('to ', Get_type_attributes_name(type_attributes_ptr));
                  writeln(' because it is not a subclass');
                  writeln('of that type.');
                  error_reported := true;

                  Destroy_exprs(expr_ptr, true);
                  expr_attributes_ptr := nil;
                end;
            end;
        end;
    end;
end; {procedure Parse_ptr_cast}


function New_type_query(class_type_ptr: type_ptr_type;
  expr_ptr: expr_ptr_type): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
begin
  new_expr_ptr := New_expr(type_query);
  new_expr_ptr^.desired_subclass_ref := forward_type_ref_type(class_type_ptr);
  new_expr_ptr^.class_expr_ptr := expr_ptr;
  New_type_query := new_expr_ptr;
end; {function New_type_query}


procedure Parse_type_query(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type);
var
  class_type_ptr: type_ptr_type;
  castable: boolean;
begin
  if parsing_ok then
    begin
      if type_attributes_ptr^.kind = type_class then
        begin
          {*******************************************}
          { get type declaration from type descriptor }
          {*******************************************}
          class_type_ptr := Get_type_decl(type_attributes_ptr);

          {******************************}
          { parse expression in question }
          {******************************}
          Parse_unit(expr_ptr, expr_attributes_ptr);

          if parsing_ok then
            begin
              Deref_expr(expr_ptr^.class_expr_ptr, expr_attributes_ptr);

              {*************************************}
              { check types for pointer equivalence }
              {*************************************}
              if class_type_ptr^.class_kind <> interface_class then
                castable :=
                  Same_type_attributes(expr_attributes_ptr^.type_attributes_ptr,
                  type_attributes_ptr)
              else
                castable := true;

              {*******************}
              { create type query }
              {*******************}
              if castable then
                begin
                  expr_ptr := New_type_query(class_type_ptr, expr_ptr);
                  expr_attributes_ptr := boolean_value_attributes_ptr;
                end
              else
                begin
                  Parse_error;
                  write('Can not cast a variable of ');
                  writeln(Get_type_attributes_name(expr_attributes_ptr^.type_attributes_ptr));
                  write('to ', Get_type_attributes_name(type_attributes_ptr));
                  writeln(' because it is not a subclass');
                  writeln('of that type.');
                  error_reported := true;

                  Destroy_exprs(expr_ptr, true);
                  expr_attributes_ptr := nil;
                end;
            end;
        end;
    end;
end; {procedure Parse_type_query}


procedure Parse_type_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  type_name: string;
  type_decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  {********************}
  { parse name of type }
  {********************}
  type_name := Token_to_id(next_token);
  if Found_type_id(type_name, type_decl_attributes_ptr, stmt_attributes_ptr)
    then
    begin
      Get_next_token;

      Match(s_tok);
      Parse_member_id(expr_ptr, expr_attributes_ptr, type_decl_attributes_ptr);

      if parsing_ok then
        expr_attributes_ptr^.explicit_member := true;

      if parsing_ok then
        Parse_id_fields_and_derefs(expr_ptr, expr_attributes_ptr);
    end
  else
    begin
      Parse_error;
      writeln('Type ', Quotate_str(type_name), ' is not declared.');
      error_reported := true;
    end;
end; {procedure Parse_type_id}


procedure Parse_functional_expr_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type;
  type_ptr: type_ptr_type;
  decl_ptr: decl_ptr_type;
  stmt_ptr: stmt_ptr_type;
begin
  if parsing_ok then
    begin
      {*************************}
      { info kind of identifier }
      {*************************}
      stmt_ptr := nil;
      decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;

      if Found_code_attributes(decl_attributes_ptr, functional_code_kinds) then
        begin
          {*****************************************}
          { parse param values of ordinary function }
          {*****************************************}
          Deref_expr(expr_ptr, expr_attributes_ptr);
          new_expr_ptr := New_expr(user_fn);
          Parse_func_stmt_tail(stmt_ptr, expr_ptr, nil, expr_attributes_ptr);
        end

      else if expr_attributes_ptr^.alias_type_attributes_ptr <> nil then
        begin
          new_expr_ptr := nil;
          type_attributes_ptr :=
            Deref_type_attributes(expr_attributes_ptr^.alias_type_attributes_ptr);
          if type_attributes_ptr^.kind in class_type_kinds then
            if next_token.kind in [static_id_tok, id_tok] then
              begin
                {************************************}
                { get attributes of type declaration }
                {************************************}
                type_ptr := Get_type_decl(type_attributes_ptr);
                decl_ptr := decl_ptr_type(type_ptr^.type_decl_ref);
                type_decl_attributes_ptr := Get_decl_attributes(decl_ptr);

                if Found_class_method_id(next_token.id, decl_attributes_ptr,
                  type_decl_attributes_ptr) then
                  if Found_method_attributes(decl_attributes_ptr,
                    functional_code_kinds) then
                    begin
                      {***************************************}
                      { parse param values of member function }
                      {***************************************}
                      new_expr_ptr := New_expr(user_fn);
                      Deref_expr(expr_ptr, expr_attributes_ptr);
                      Parse_func_method_tail(stmt_ptr, expr_ptr,
                        expr_attributes_ptr);
                    end;
              end;
        end
      else
        new_expr_ptr := nil;

      {****************************************}
      { create user defined function call expr }
      {****************************************}
      if stmt_ptr <> nil then
        begin
          new_expr_ptr^.fn_stmt_ptr := forward_stmt_ptr_type(stmt_ptr);
          expr_attributes_ptr := Copy_expr_attributes(expr_attributes_ptr);
          Set_expr_attributes(new_expr_ptr, expr_attributes_ptr);
          expr_ptr := new_expr_ptr;
        end;

    end;
end; {procedure Parse_functional_expr_tail}


procedure Parse_void_func_method_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_ptr: decl_ptr_type;
  code_ptr: code_ptr_type;
begin
  {************************************}
  { parse function tail if void method }
  {************************************}
  if expr_attributes_ptr^.type_attributes_ptr^.kind = type_code then
    begin
      decl_ptr :=
        decl_ptr_type(expr_attributes_ptr^.decl_attributes_ptr^.decl_ref);
      code_ptr := code_ptr_type(decl_ptr^.code_ptr);
      if (code_ptr^.implicit_param_decls_ptr = nil) then
        Parse_functional_expr_tail(expr_ptr, expr_attributes_ptr)
      else
        begin
          Parse_error;
          write(Quotate_str(Get_expr_attributes_name(expr_attributes_ptr)));
          writeln(' is not a static method.');
          error_reported := true;
        end;
    end
  else if not expr_attributes_ptr^.decl_attributes_ptr^.static then
    begin
      Parse_error;
      writeln(Quotate_str(next_token.id), ' is not a static member.');
      error_reported := true;
    end;
end; {procedure Parse_void_func_method_tail}


procedure Parse_type_id_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  stmt_ptr: stmt_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  expecting_proto: boolean;
  type_name: string;
begin
  if (next_token.kind = type_id_tok) then
    begin
      expecting_proto := false;
      if expr_attributes_ptr <> nil then
        if expr_attributes_ptr^.type_attributes_ptr^.kind = type_code then
          expecting_proto := true;

      {*********************}
      { parse name of class }
      {*********************}
      type_name := Token_to_id(next_token);
      if Found_type_id(type_name, decl_attributes_ptr, stmt_attributes_ptr) then
        begin
          Get_next_token;

          if next_token.kind = s_tok then
            begin
              {*******************}
              { parse member name }
              {*******************}
              Get_next_token;
              Parse_member_id(expr_ptr, expr_attributes_ptr,
                decl_attributes_ptr);

              if parsing_ok then
                expr_attributes_ptr^.explicit_member := true;

              if parsing_ok then
                if not expecting_proto then
                  begin
                    {************************}
                    { parse void method tail }
                    {************************}
                    Parse_void_func_method_tail(expr_ptr, expr_attributes_ptr);

                    if parsing_ok then
                      if expr_ptr^.kind = user_fn then
                        begin
                          {****************************}
                          { deactivate dynamic binding }
                          {****************************}
                          stmt_ptr := stmt_ptr_type(expr_ptr^.fn_stmt_ptr);
                          stmt_ptr^.stmt_info_ptr^.implicit_method := false;
                        end;
                  end;
            end
          else
            begin
              {*************************}
              { parse ptr cast or query }
              {*************************}
              type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;
              if expr_attributes_ptr <> boolean_value_attributes_ptr then
                Parse_ptr_cast(expr_ptr, expr_attributes_ptr,
                  type_attributes_ptr)
              else
                Parse_type_query(expr_ptr, expr_attributes_ptr,
                  type_attributes_ptr);
            end;
        end
      else
        begin
          Parse_error;
          writeln('Type ', Quotate_str(type_name), ' is not declared.');
          error_reported := true;
        end;
    end
  else
    begin
      Parse_error;
      writeln('Expected the name of a type here.');
      error_reported := true;
    end;
end; {procedure Parse_type_id_expr}


{************************  productions  ************************}
{       <array_id> ::= id <array_indices>                       }
{***************************************************************}

procedure Parse_id_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  expecting_proto: boolean;
  expecting_enum, found_enum: boolean;
  symbol_table_ptr: symbol_table_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  id_ptr: id_ptr_type;
begin
  if parsing_ok then
    begin
      if next_token.kind = type_id_tok then
        Parse_type_id_expr(expr_ptr, expr_attributes_ptr)
      else
        begin
          expecting_proto := false;
          expecting_enum := false;
          found_enum := false;

          if expr_attributes_ptr <> nil then
            begin
              type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
              if type_attributes_ptr^.kind = type_code then
                expecting_proto := true;
              if type_attributes_ptr^.kind = type_enum then
                expecting_enum := true;
            end
          else
            type_attributes_ptr := nil;

          {*************************}
          { check for enum literals }
          {*************************}
          if expecting_enum then
            if next_token.kind in [id_tok, none_tok] then
              case next_token.kind of

                id_tok:
                  begin
                    symbol_table_ptr := type_attributes_ptr^.enum_table_ptr;
                    if Found_id_by_name(symbol_table_ptr, id_ptr, next_token.id)
                      then
                      begin
                        Match_enum_lit(expr_ptr, expr_attributes_ptr,
                          type_attributes_ptr);
                        found_enum := true;
                      end;
                  end;

                none_tok:
                  begin
                    Match_enum_lit(expr_ptr, expr_attributes_ptr,
                      type_attributes_ptr);
                    found_enum := true;
                  end;

              end; {case}

          if not found_enum then
            Parse_id(expr_ptr, expr_attributes_ptr);

          {******************************************}
          { parse function or (non void) method tail }
          {******************************************}
          if parsing_ok then
            if not expecting_proto then
              if not (next_token.kind in [does_tok, doesnt_tok, refers_tok])
                then
                Parse_functional_expr_tail(expr_ptr, expr_attributes_ptr);
        end;
    end; {if parsing_ok}
end; {procedure Parse_id_expr}


end.

