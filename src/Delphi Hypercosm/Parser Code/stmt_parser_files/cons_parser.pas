unit cons_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            cons_parser                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse constructors     }
{       (method calls) into an abstract syntax tree.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, expr_attributes, exprs, stmts, type_decls;


{*************************************************}
{ routine to create implicit default constructors }
{*************************************************}
function New_struct_new(struct_type_ptr: type_ptr_type): expr_ptr_type;

{********************************}
{ routines to parse constructors }
{********************************}
procedure Parse_constructor_stmt(var constructor_stmt_ptr: stmt_ptr_type;
  class_type_ptr: type_ptr_type);
procedure Parse_implicit_struct_new(var expr_ptr: expr_ptr_type;
  struct_type_ptr: type_ptr_type);
procedure Parse_explicit_struct_new(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  struct_type_ptr: type_ptr_type);
procedure Parse_struct_array_new(expr_ptr: expr_ptr_type;
  struct_type_ptr: type_ptr_type);
procedure Parse_superclass_constructor(var stmt_ptr: stmt_ptr_type;
  class_type_ptr: type_ptr_type);


implementation
uses
  symbol_tables, decl_attributes, decls, tokens, tokenizer, parser,
    match_literals, match_terms, expr_parser, member_parser, msg_parser;


function New_struct_new(struct_type_ptr: type_ptr_type): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
begin
  new_expr_ptr := New_expr(struct_new);
  new_expr_ptr^.new_struct_type_ref := forward_type_ref_type(struct_type_ptr);
  New_struct_new := new_expr_ptr;
end; {function New_struct_new}


procedure Parse_constructor_stmt(var constructor_stmt_ptr: stmt_ptr_type;
  class_type_ptr: type_ptr_type);
var
  decl_ptr: decl_ptr_type;
  expr_ptr, method_data_ptr: expr_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  last_stmt_ptr: stmt_ptr_type;
begin
  if class_type_ptr^.constructor_code_ref <> nil then
    begin
      method_data_ptr := New_expr(new_itself);
      method_data_ptr^.new_type_ref := forward_type_ref_type(class_type_ptr);

      decl_ptr := class_type_ptr^.constructor_code_ref^.code_decl_ref;
      decl_attributes_ptr := Get_decl_attributes(decl_ptr);
      expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);
      last_stmt_ptr := nil;

      Parse_proc_stmt_tail(constructor_stmt_ptr, last_stmt_ptr, expr_ptr,
        method_data_ptr, expr_attributes_ptr);
    end
  else
    constructor_stmt_ptr := nil;
end; {procedure Parse_constructor_stmt}


procedure Parse_constructor_fn(var constructor_stmt_ptr: stmt_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  class_type_ptr: type_ptr_type);
var
  decl_ptr: decl_ptr_type;
  expr_ptr, method_data_ptr: expr_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if class_type_ptr^.constructor_code_ref <> nil then
    begin
      method_data_ptr := New_expr(new_itself);
      method_data_ptr^.new_type_ref := forward_type_ref_type(class_type_ptr);

      decl_ptr := class_type_ptr^.constructor_code_ref^.code_decl_ref;
      decl_attributes_ptr := Get_decl_attributes(decl_ptr);
      expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);

      Parse_func_stmt_tail(constructor_stmt_ptr, expr_ptr, method_data_ptr,
        expr_attributes_ptr);
    end
  else
    constructor_stmt_ptr := nil;
end; {procedure Parse_constructor_fn}


procedure Parse_explicit_struct_new(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  struct_type_ptr: type_ptr_type);
var
  constructor_stmt_ptr: stmt_ptr_type;
  expr_info_ptr: expr_info_ptr_type;
begin
  if parsing_ok then
    begin
      expr_info_ptr := New_expr_info;

      case struct_type_ptr^.kind of

        struct_type:
          begin
            {****************************}
            { create default constructor }
            {****************************}
            expr_ptr := New_struct_new(struct_type_ptr);
            expr_attributes_ptr := nil;
          end;

        class_type:
          begin
            if struct_type_ptr^.class_kind <> abstract_class then
              begin
                {****************************}
                { create default constructor }
                {****************************}
                expr_ptr := New_struct_new(struct_type_ptr);

                {************************}
                { parse constructor tail }
                {************************}
                Parse_constructor_fn(constructor_stmt_ptr, expr_attributes_ptr,
                  struct_type_ptr);
                expr_ptr^.new_struct_init_stmt_ptr :=
                  forward_stmt_ptr_type(constructor_stmt_ptr);
              end
            else
              begin
                Parse_error;
                writeln('Can not create an instance of an abstract type.');
                error_reported := true;
              end;
          end;

      end; {case}

      if parsing_ok then
        Set_expr_info(expr_ptr, expr_info_ptr);
    end; {if parsing_ok}
end; {procedure Parse_explicit_struct_new}


procedure Parse_implicit_struct_new(var expr_ptr: expr_ptr_type;
  struct_type_ptr: type_ptr_type);
var
  constructor_stmt_ptr: stmt_ptr_type;
begin
  if parsing_ok then
    begin
      case struct_type_ptr^.kind of

        struct_type:
          begin
            {****************************}
            { create default constructor }
            {****************************}
            expr_ptr := New_struct_new(struct_type_ptr);
          end;

        class_type:
          begin
            if struct_type_ptr^.class_kind <> abstract_class then
              begin
                {****************************}
                { create default constructor }
                {****************************}
                expr_ptr := New_struct_new(struct_type_ptr);

                {************************}
                { parse constructor tail }
                {************************}
                Parse_constructor_stmt(constructor_stmt_ptr, struct_type_ptr);
                expr_ptr^.new_struct_init_stmt_ptr :=
                  forward_stmt_ptr_type(constructor_stmt_ptr);
              end
            else
              begin
                Parse_error;
                writeln('Can not create an instance of an abstract type.');
                error_reported := true;
              end;
          end;

      end; {case}
    end; {if parsing_ok}
end; {procedure Parse_implicit_struct_new}


procedure Parse_struct_array_new(expr_ptr: expr_ptr_type;
  struct_type_ptr: type_ptr_type);
var
  constructor_stmt_ptr: stmt_ptr_type;
begin
  if parsing_ok then
    begin
      if expr_ptr <> nil then
        if expr_ptr^.dim_bounds_list_ptr^.first <> nil then
          case expr_ptr^.kind of

            array_array_dim:
              Parse_struct_array_new(expr_ptr^.dim_element_expr_ptr,
                struct_type_ptr);

            struct_array_dim:
              Parse_implicit_struct_new(expr_ptr^.dim_element_expr_ptr,
                struct_type_ptr);

            static_struct_array_dim:
              case struct_type_ptr^.kind of

                struct_type:
                  expr_ptr^.dim_static_struct_type_ref :=
                    forward_type_ref_type(struct_type_ptr);

                class_type:
                  begin
                    Parse_constructor_stmt(constructor_stmt_ptr,
                      struct_type_ptr);
                    expr_ptr^.dim_static_struct_type_ref :=
                      forward_type_ref_type(struct_type_ptr);
                    expr_ptr^.dim_static_struct_init_stmt_ptr :=
                      forward_stmt_ptr_type(constructor_stmt_ptr);
                  end;

              end; {case}
          end; {case}

    end; {if parsing_ok}
end; {procedure Parse_struct_array_new}


procedure Parse_superclass_constructor(var stmt_ptr: stmt_ptr_type;
  class_type_ptr: type_ptr_type);
var
  expr_ptr: expr_ptr_type;
  decl_ptr: decl_ptr_type;
  method_data_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  last_stmt_ptr: stmt_ptr_type;
begin
  if parsing_ok then
    if class_type_ptr <> nil then
      if class_type_ptr^.parent_class_ref^.constructor_code_ref <> nil then
        begin
          if next_token.kind = id_tok then
            begin
              expr_attributes_ptr := nil;
              Parse_expr(method_data_ptr, expr_attributes_ptr);

              if parsing_ok then
                begin
                  {***********************************************}
                  { check to see if we are refering to the parent }
                  {***********************************************}
                  decl_ptr :=
                    class_type_ptr^.constructor_code_ref^.implicit_param_decls_ptr^.next;
                  decl_attributes_ptr := Get_decl_attributes(decl_ptr);

                  if expr_attributes_ptr^.decl_attributes_ptr =
                    decl_attributes_ptr then
                    begin
                      Match(new_tok);

                      {************************}
                      { parse constructor name }
                      {************************}
                      Parse_implicit_class_member_id('new', expr_ptr,
                        expr_attributes_ptr, decl_attributes_ptr);

                      {******************************}
                      { parse constructor parameters }
                      {******************************}
                      Parse_proc_stmt_tail(stmt_ptr, last_stmt_ptr, expr_ptr,
                        method_data_ptr, expr_attributes_ptr);
                    end
                  else
                    begin
                      Parse_error;
                      writeln('The first line of a constructor must be a');
                      writeln('call to its superclass constructor if its');
                      writeln('superclass has an explicit constructor.');
                      error_reported := true;
                    end;
                end; {if parsing_ok}
            end
          else
            begin
              Parse_error;
              writeln('The first line of a constructor must be a');
              writeln('call to its superclass constructor if its');
              writeln('superclass has an explicit constructor.');
              error_reported := true;
            end;

        end;
end; {procedure Parse_superclass_constructor}


end.
