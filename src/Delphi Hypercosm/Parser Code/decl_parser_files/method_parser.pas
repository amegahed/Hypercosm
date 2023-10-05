unit method_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            method_parser              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse method           }
{       declarations into an abstract syntax tree               }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, decls, code_decls, type_decls;


procedure Parse_method_decl(var decl_ptr: decl_ptr_type;
  decl_kind: code_decl_kind_type;
  method_kind: method_kind_type;
  static, reference_method: boolean;
  return_type_attributes_ptr: type_attributes_ptr_type;
  class_type_ptr: type_ptr_type);
procedure Check_forward_decls(decl_ptr: decl_ptr_type);


implementation
uses
  chars, strings, code_types, decl_attributes, code_attributes, stmt_attributes,
  expr_attributes, prim_attributes, compare_types, exprs, stmts, syntax_trees,
  make_exprs, tokens, tokenizer, parser, comment_parser, type_assigns,
  match_literals, match_terms, implicit_derefs, expr_parser, assign_parser,
  stmt_parser, param_parser, cons_parser, data_parser, decl_parser, scoping,
  optimizer, native_glue;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                      complex declarations                     }
{***************************************************************}
{       <complex_decl> ::= <proc_decl> <decl_body>              }
{       <complex_decl> ::= <func_decl> <decl_body>              }
{                                                               }
{       <params> ::= <param> <more_params>                      }
{       <params> ::=                                            }
{       <more_params> ::= <params>                              }
{       <more_params> ::=                                       }
{       <param> ::= <data_decl>                                 }
{       <param> ::= id                                          }
{                                                               }
{       <decl_body> ::= is <decls> <stmts> end ;                }
{***************************************************************}


{***************************************************************}
{                      procedural declarations                  }
{***************************************************************}
{       <proc_decl> ::= <proc_type> id <params> <proc_params>   }
{                                                               }
{       <proc_type> ::= procedure                               }
{       <proc_type> ::= object                                  }
{       <proc_type> ::= picture                                 }
{       <proc_type> ::= anim                                    }
{                                                               }
{       <proc_params> ::= <opt_params> <return_params>          }
{                                                               }
{       <opt_params> ::= with <decls> <stmts>                   }
{       <opt_params> ::=                                        }
{                                                               }
{       <return_params> ::= return <decls>                      }
{       <return_params> ::=                                     }
{***************************************************************}


{***************************************************************}
{                      functional declarations                  }
{***************************************************************}
{       <proc_decl> ::= <func_type> id <params> <return_decl>   }
{                                                               }
{       <func_type> ::= function                                }
{       <func_type> ::= shader                                  }
{                                                               }
{       <return_decl> ::= return <var_decl>                     }
{***************************************************************}


function Same_initializers(stmt_ptr1, stmt_ptr2: stmt_ptr_type): boolean;
var
  same: boolean;
begin
  if (stmt_ptr1 <> nil) and (stmt_ptr2 <> nil) then
    begin
      if (stmt_ptr1^.kind = stmt_ptr2^.kind) then
        same := Equal_exprs(stmt_ptr1^.rhs_expr_ptr, stmt_ptr2^.rhs_expr_ptr)
      else
        same := false;
    end
  else
    same := (stmt_ptr1 = stmt_ptr2);

  Same_initializers := same;
end; {function Same_initializers}


function Same_decl_initializers(decl_ptr1, decl_ptr2: decl_ptr_type): boolean;
var
  same: boolean;
begin
  if (decl_ptr1^.kind = decl_ptr2^.kind) then
    case decl_ptr1^.kind of

      null_decl, type_decl:
        same := false;

      boolean_decl..reference_decl:
        same := Same_initializers(decl_ptr1^.data_decl.init_stmt_ptr,
          decl_ptr2^.data_decl.init_stmt_ptr);

      code_decl, code_reference_decl:
        same := Same_initializers(decl_ptr1^.code_data_decl.init_stmt_ptr,
          decl_ptr2^.code_data_decl.init_stmt_ptr);

    else
      same := false;
    end {case}
  else
    same := false;

  Same_decl_initializers := same;
end; {function Same_decl_initializers}


function Same_decls_initializers(var decl_ptr1, decl_ptr2: decl_ptr_type):
  boolean;
var
  same: boolean;
begin
  same := true;

  while (decl_ptr1 <> nil) and (decl_ptr2 <> nil) and same do
    begin
      {********************************}
      { skip through type declarations }
      {********************************}
      while not (decl_ptr1^.kind in data_decl_set) do
        decl_ptr1 := decl_ptr1^.next;
      while not (decl_ptr2^.kind in data_decl_set) do
        decl_ptr2 := decl_ptr2^.next;

      {****************************************}
      { check initializers of next declaration }
      {****************************************}
      if (decl_ptr1 <> nil) and (decl_ptr2 <> nil) then
        begin
          same := Same_decl_initializers(decl_ptr1, decl_ptr2);
          if same then
            begin
              decl_ptr1 := decl_ptr1^.next;
              decl_ptr2 := decl_ptr2^.next;
            end;
        end;
    end;

  if (decl_ptr1 <> nil) or (decl_ptr2 <> nil) then
    same := false;

  Same_decls_initializers := same;
end; {function Same_decls_initializers}


procedure Check_decls_initializers(forward_decls_ptr, actual_decls_ptr:
  decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      if not Same_decls_initializers(forward_decls_ptr, actual_decls_ptr) then
        begin
          Parse_error;
          write('The method ');
          write(Quotate_str(Get_decl_attributes_name(decl_attributes_ptr)));
          write(' has a parameter, ');
          write(Quotate_str(Get_decl_attributes_name(Get_decl_attributes(actual_decls_ptr))));
          writeln(',');
          writeln('whose initializer does not match its forward declaration.');
          error_reported := true;
        end
    end;
end; {procedure Check_decls_initializers}


procedure Check_forward_decl(forward_code_ptr, actual_code_ptr: code_ptr_type;
  forward_decl_attributes_ptr, actual_decl_attributes_ptr:
  decl_attributes_ptr_type);
var
  forward_type_attributes_ptr, actual_type_attributes_ptr:
  type_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      forward_type_attributes_ptr :=
        forward_decl_attributes_ptr^.type_attributes_ptr;
      actual_type_attributes_ptr :=
        actual_decl_attributes_ptr^.type_attributes_ptr;

      {*********************************}
      { check for logical compatability }
      {*********************************}
      if not Same_type_attributes(forward_type_attributes_ptr,
        actual_type_attributes_ptr) then
        begin
          Parse_error;
          write(Quotate_str(Get_decl_attributes_name(actual_decl_attributes_ptr)));
          writeln(' does not match its forward declaration.');
          error_reported := true;
        end;

      {*********************************}
      { check initializers for equality }
      {*********************************}
      Check_decls_initializers(forward_code_ptr^.initial_param_decls_ptr,
        actual_code_ptr^.initial_param_decls_ptr, actual_decl_attributes_ptr);
      Check_decls_initializers(forward_code_ptr^.optional_param_decls_ptr,
        actual_code_ptr^.optional_param_decls_ptr, actual_decl_attributes_ptr);
      Check_decls_initializers(forward_code_ptr^.return_param_decls_ptr,
        actual_code_ptr^.return_param_decls_ptr, actual_decl_attributes_ptr);
    end;
end; {procedure Check_forward_decl}


procedure Assign_forward_code_decls(forward_code_ptr, actual_code_ptr:
  code_ptr_type);
  forward;


procedure Assign_forward_decls(decl_ptr1, decl_ptr2: decl_ptr_type);
var
  code_ptr1, code_ptr2: code_ptr_type;
begin
  while (decl_ptr1 <> nil) and (decl_ptr2 <> nil) do
    begin
      if decl_ptr1^.kind = code_decl then
        if decl_ptr2^.kind = code_decl then
          begin
            code_ptr1 := code_ptr_type(decl_ptr1^.code_ptr);
            code_ptr2 := code_ptr_type(decl_ptr2^.code_ptr);
            Assign_forward_code_decls(code_ptr1, code_ptr2);
          end;
      decl_ptr1 := decl_ptr1^.next;
      decl_ptr2 := decl_ptr2^.next;
    end;
end; {procedure Assign_forward_decls}


procedure Assign_forward_code_decls(forward_code_ptr, actual_code_ptr:
  code_ptr_type);
var
  decl_ptr1, decl_ptr2: decl_ptr_type;
begin
  forward_code_ptr^.actual_code_ref := actual_code_ptr;

  {*********************************************}
  { assign actual decls of any prototype params }
  {*********************************************}
  decl_ptr1 := forward_code_ptr^.initial_param_decls_ptr;
  decl_ptr2 := actual_code_ptr^.initial_param_decls_ptr;
  Assign_forward_decls(decl_ptr1, decl_ptr2);

  decl_ptr1 := forward_code_ptr^.optional_param_decls_ptr;
  decl_ptr2 := actual_code_ptr^.optional_param_decls_ptr;
  Assign_forward_decls(decl_ptr1, decl_ptr2);

  decl_ptr1 := forward_code_ptr^.return_param_decls_ptr;
  decl_ptr2 := actual_code_ptr^.return_param_decls_ptr;
  Assign_forward_decls(decl_ptr1, decl_ptr2);
end; {procedure Assign_forward_code_decls}


procedure Make_implicit_superclass_decls(var decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type;
  reference_method: boolean);
var
  type_attributes_ptr: type_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  class_decl_attributes_ptr: decl_attributes_ptr_type;
  new_decl_ptr: decl_ptr_type;
  class_name: string_type;
  last_decl_ptr: decl_ptr_type;
begin
  last_decl_ptr := decl_ptr;
  while class_type_ptr <> nil do
    begin
      {*******************************************}
      { get type descriptor from type declaration }
      {*******************************************}
      class_decl_attributes_ptr :=
        Get_decl_attributes(class_type_ptr^.type_decl_ref);
      type_attributes_ptr := class_decl_attributes_ptr^.type_attributes_ptr;
      if reference_method then
        type_attributes_ptr :=
          New_reference_type_attributes(type_attributes_ptr);

      {***********************************}
      { create new declaration attributes }
      {***********************************}
      decl_attributes_ptr := New_decl_attributes(data_decl_attributes,
        type_attributes_ptr, nil);
      decl_attributes_ptr^.stack_index := 1;
      decl_attributes_ptr^.dynamic := true;

      {*****************************}
      { create implicit declaration }
      {*****************************}
      class_name := Get_decl_attributes_name(class_decl_attributes_ptr);
      new_decl_ptr := New_implicit_data_decl(class_name, decl_attributes_ptr);
      class_type_ptr := class_type_ptr^.parent_class_ref;

      {***************************************}
      { add to tail of list of implicit decls }
      {***************************************}
      if last_decl_ptr <> nil then
        begin
          last_decl_ptr^.next := new_decl_ptr;
          last_decl_ptr := new_decl_ptr;
        end
      else
        begin
          decl_ptr := new_decl_ptr;
          last_decl_ptr := new_decl_ptr;
        end;
    end;
end; {procedure Make_implicit_superclass_decls}


procedure Parse_special_method_name(var code_kind: code_kind_type;
  var method_kind: method_kind_type;
  class_type_ptr: type_ptr_type);
begin
  if next_token.kind in [new_tok, free_tok] then
    begin
      if (class_type_ptr <> nil) then
        begin
          case next_token.kind of

            new_tok:
              begin
                code_kind := constructor_code;
                next_token.kind := id_tok;
                next_token.id := 'new';
              end;

            free_tok:
              begin
                code_kind := destructor_code;
                next_token.kind := id_tok;
                next_token.id := 'free';
              end;

          end; {case}

          {****************************}
          { deactivate dynamic binding }
          {****************************}
          method_kind := static_method;
        end
      else
        begin
          Parse_error;
          writeln('Constructors and destructors are only allowed in classes.');
          error_reported := true;
        end;
    end;
end; {procedure Parse_special_method_name}


procedure Make_actual_method_name(name: string_type;
  decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  var forward_decl_attributes_ptr: decl_attributes_ptr_type);
var
  code_ptr, forward_code_ptr: code_ptr_type;
  forward_decl_ptr: decl_ptr_type;
begin
  if parsing_ok then
    begin
      {***********************************************}
      { get forward decl from forward decl attributes }
      {***********************************************}
      code_ptr := code_ptr_type(decl_ptr^.code_ptr);
      forward_decl_ptr := decl_ptr_type(forward_decl_attributes_ptr^.decl_ref);
      forward_code_ptr := code_ptr_type(forward_decl_ptr^.code_ptr);

      {*******************************************************}
      { set actual virtual method id and dispatch table entry }
      {*******************************************************}
      if forward_code_ptr^.method_id <> 0 then
        begin
          code_ptr^.method_id := forward_code_ptr^.method_id;
          Set_virtual_method(type_ptr_type(code_ptr^.class_type_ref), code_ptr);
        end;

      if parsing_ok then
        begin
          {**************************************************}
          { parse resolution of abstract method declarations }
          {**************************************************}
          if forward_decl_attributes_ptr^.abstract then
            begin
              if not decl_attributes_ptr^.forward then
                if forward_code_ptr^.class_type_ref = code_ptr^.class_type_ref
                  then
                  begin
                    Parse_error;
                    writeln('The method, ', Quotate_str(next_token.id),
                      ', is abstract.');
                    writeln('No implementation is allowed.');
                    error_reported := true;
                  end;

              if parsing_ok then
                begin
                  Store_id(name, decl_attributes_ptr);
                  expr_ptr := New_identifier(decl_attributes_ptr,
                    expr_attributes_ptr);
                end;
            end

              {*********************************************************}
              { parse resolution of regular forward method declarations }
              {*********************************************************}
          else
            begin
              decl_attributes_ptr^.id_ptr :=
                forward_decl_attributes_ptr^.id_ptr;
              decl_attributes_ptr^.static_level :=
                forward_decl_attributes_ptr^.static_level;
              expr_ptr := New_identifier(decl_attributes_ptr,
                expr_attributes_ptr);

              if code_ptr^.method_kind = static_method then
                code_ptr^.method_kind := forward_code_ptr^.method_kind
              else if forward_code_ptr^.method_kind <> abstract_method then
                if code_ptr^.method_kind <> forward_code_ptr^.method_kind then
                  begin
                    Parse_error;
                    writeln(Quotate_str(Get_decl_attributes_name(decl_attributes_ptr)));
                    writeln(' does not match its forward declaration.');
                    error_reported := true;
                  end;
            end;

        end; {if parsing_ok}
    end; {if parsing_ok}
end; {procedure Make_actual_method_name}


procedure Parse_code_kind(var kind: code_kind_type);
begin
  if parsing_ok then
    begin
      case next_token.kind of

        {******************}
        { basic code kinds }
        {******************}
        procedure_tok:
          kind := procedure_code;
        function_tok:
          kind := function_code;

        {**********************}
        { modelling code kinds }
        {**********************}
        object_tok:
          kind := object_code;
        shader_tok:
          kind := shader_code;

        {**********************}
        { rendering code kinds }
        {**********************}
        picture_tok:
          kind := picture_code;
        anim_tok:
          kind := anim_code;

      end; {case}

      Get_next_token;
    end;
end; {function Parse_code_kind}


procedure Parse_return_type(var type_attributes_ptr: type_attributes_ptr_type);
begin
  if next_token.kind <> shader_tok then
    begin
      Parse_data_type(type_attributes_ptr);
      if next_token.kind <> function_tok then
        begin
          Parse_error;
          writeln('Expected a function declaration here.');
          error_reported := true;
        end;
    end
  else
    type_attributes_ptr := vector_type_attributes_ptr;
end; {procedure Parse_return_type}


procedure Check_native_method(decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  class_type_ptr: type_ptr_type);
const
  valid_native_method_kinds = [procedure_code, constructor_code,
    destructor_code, function_code, object_code];
var
  type_decl_ptr: decl_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type;
  code_ptr: code_ptr_type;
  class_name, method_name: string_type;
  native_index: integer;
begin
  if parsing_ok then
    if decl_attributes_ptr^.native then
      begin
        code_ptr := code_ptr_type(decl_ptr^.code_ptr);

        if code_ptr^.kind in valid_native_method_kinds then
          begin
            {*****************}
            { get method name }
            {*****************}
            method_name := Get_decl_attributes_name(decl_attributes_ptr);

            {****************}
            { get class name }
            {****************}
            if class_type_ptr <> nil then
              begin
                type_decl_ptr := decl_ptr_type(class_type_ptr^.type_decl_ref);
                type_decl_attributes_ptr := Get_decl_attributes(type_decl_ptr);
                class_name :=
                  Get_decl_attributes_name(type_decl_attributes_ptr);
                method_name := concat(class_name, concat(' ', method_name));
              end;

            if Found_native_method_by_name(method_name, native_index) then
              decl_ptr^.code_data_decl.native_index := native_index
            else
              begin
                Parse_error;
                writeln('Unrecognized native method.');
                error_reported := true;
              end;
          end
        else
          begin
            Parse_error;
            writeln('Unrecognized native method kind.');
            error_reported := true;
          end;
      end;
end; {procedure Check_native_method}


procedure Check_forward_method_decl(decl_attributes_ptr:
  decl_attributes_ptr_type;
  forward_decl_attributes_ptr: decl_attributes_ptr_type;
  forward_decl_ptr: decl_ptr_type);
var
  code_attributes_ptr, forward_code_attributes_ptr: code_attributes_ptr_type;
  name: string_type;
begin
  if parsing_ok then
    begin
      name := Get_decl_attributes_name(forward_decl_attributes_ptr);

      {********************************************}
      { check if previous decl is forward declared }
      {********************************************}
      if (not forward_decl_attributes_ptr^.forward) then
        begin
          Parse_error;
          writeln(Quotate_str(name), ' has already been declared.');
          write('on ');
          Write_decl_location(forward_decl_ptr^.decl_info_ptr);
          writeln;
          error_reported := true;
        end

          {************************************}
          { check if previous decl is abstract }
          {************************************}
      else if (not forward_decl_attributes_ptr^.abstract) and
        decl_attributes_ptr^.forward then
        begin
          Parse_error;
          writeln(Quotate_str(name), ' has already been forward declared.');
          write('on ');
          Write_decl_location(forward_decl_ptr^.decl_info_ptr);
          writeln;
          error_reported := true;
        end

          {***********************************}
          { check if forward decl is a method }
          {***********************************}
      else if forward_decl_attributes_ptr^.type_attributes_ptr^.kind <> type_code
        then
        begin
          Parse_error;
          writeln(Quotate_str(name), ' has already been declared');
          write('on ');
          Write_decl_location(forward_decl_ptr^.decl_info_ptr);
          writeln;
          error_reported := true;
        end

          {**********************************}
          { check if method code kinds match }
          {**********************************}
      else
        begin
          code_attributes_ptr :=
            decl_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr;
          forward_code_attributes_ptr :=
            forward_decl_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr;

          if forward_code_attributes_ptr^.kind <> code_attributes_ptr^.kind then
            begin
              Parse_error;
              writeln(Quotate_str(name), single_quote,
                's method kind does not match its forward declaration');
              write('on ');
              Write_decl_location(forward_decl_ptr^.decl_info_ptr);
              writeln;
              error_reported := true;
            end;
        end;

    end; {if parsing_ok}
end; {procedure Check_forward_method_decl}


procedure Parse_proto_initializer(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  if next_token.kind = does_tok then
    begin
      {****************************************}
      { parse initializer for prototype method }
      {****************************************}
      Get_next_token;
      Parse_unit(expr_ptr, expr_attributes_ptr);

      if parsing_ok then
        if (expr_attributes_ptr^.type_attributes_ptr <> nil) then
          if (expr_attributes_ptr^.type_attributes_ptr^.kind <>
            decl_attributes_ptr^.type_attributes_ptr^.kind) then
            begin
              Parse_error;
              writeln('This initializer must be a method of the same type.');
              error_reported := true;
            end;
    end
  else
    expr_ptr := nil;
end; {procedure Parse_proto_initializer}


procedure Check_proto_initializer(decl_attributes_ptr: decl_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  lhs_type_attributes_ptr, rhs_type_attributes_ptr: type_attributes_ptr_type;
begin
  lhs_type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;
  rhs_type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;

  if not Equal_type_attributes(lhs_type_attributes_ptr, rhs_type_attributes_ptr)
    then
    begin
      Parse_error;
      writeln('The type of this method does not match its initializer.');
      error_reported := true;
    end;

  {********************************}
  { check to see that we are not   }
  { assigning a variable to itself }
  {********************************}
  if decl_attributes_ptr = expr_attributes_ptr^.decl_attributes_ptr then
    begin
      Parse_error;
      writeln('Can not initialize a method to itself.');
      error_reported := true;
    end;
end; {procedure Check_proto_initializer}


procedure Make_proto_initializer(var stmt_ptr: stmt_ptr_type;
  init_expr_ptr: expr_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  lhs_data_ptr: expr_ptr_type;
begin
  if parsing_ok then
    begin
      {*********************************}
      { create unique reference to data }
      {*********************************}
      lhs_data_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);
      Make_implicit_derefs(lhs_data_ptr, expr_attributes_ptr, nil);

      {*****************************}
      { create assignment statement }
      {*****************************}
      stmt_ptr := New_proto_assign(lhs_data_ptr, init_expr_ptr,
        decl_attributes_ptr^.static_level);
    end; {if parsing_ok}
end; {procedure Make_proto_initializer}


{***************************************************************}
{                       method declarations                     }
{***************************************************************}
{       <proc_decl> ::= <proc_type> id <params> <proc_params>   }
{       <func_decl> ::= <func_type> id <func_params>            }
{                                                               }
{       <proc_type> ::= procedure                               }
{       <proc_type> ::= object                                  }
{       <proc_type> ::= picture                                 }
{       <proc_type> ::= anim                                    }
{                                                               }
{       <func_type> ::= function                                }
{       <func_type> ::= shader                                  }
{***************************************************************}

procedure Parse_method_decl(var decl_ptr: decl_ptr_type;
  decl_kind: code_decl_kind_type;
  method_kind: method_kind_type;
  static, reference_method: boolean;
  return_type_attributes_ptr: type_attributes_ptr_type;
  class_type_ptr: type_ptr_type);
var
  code_kind: code_kind_type;
  code_ptr: code_ptr_type;
  forward_decl_ptr, last_decl_ptr: decl_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
  decl_attributes_ptr, forward_decl_attributes_ptr: decl_attributes_ptr_type;
  context_decl_attributes_ptr, class_decl_attributes_ptr:
  decl_attributes_ptr_type;
  class_type_attributes_ptr, parent_type_attributes_ptr:
  type_attributes_ptr_type;
  init_expr_attributes_ptr: expr_attributes_ptr_type;
  init_expr_ptr: expr_ptr_type;
  decl_info_ptr: decl_info_ptr_type;
  field_method, temp: boolean;
  method_name, class_name: string_type;
begin
  if parsing_ok then
    if next_token.kind in (subprogram_predict_set + data_predict_set) then
      begin
        Get_prev_decl_info(decl_info_ptr);

        {****************************}
        { parse function return type }
        {****************************}
        if not (next_token.kind in procedural_predict_set) then
          if return_type_attributes_ptr = nil then
            Parse_return_type(return_type_attributes_ptr);

        {************************************}
        { parse code kind and make code info }
        {************************************}
        Parse_code_kind(code_kind);
        code_attributes_ptr := New_code_attributes(code_kind);
        expr_attributes_ptr :=
          New_value_expr_attributes(return_type_attributes_ptr);
        code_attributes_ptr^.return_value_attributes_ptr :=
          forward_expr_attributes_ptr_type(expr_attributes_ptr);

        {*****************************************}
        { make new type descriptor and attributes }
        {*****************************************}
        type_attributes_ptr := New_type_attributes(type_code, true);
        type_attributes_ptr^.code_attributes_ptr := code_attributes_ptr;

        {*******************************************}
        { is method a field of a class or structure }
        {*******************************************}
        field_method := false;
        if decl_kind = proto_decl then
          begin
            context_decl_attributes_ptr := Get_scope_decl_attributes;
            if context_decl_attributes_ptr <> nil then
              if context_decl_attributes_ptr^.kind = type_decl_attributes then
                field_method := true;
          end;

        if field_method then
          decl_attributes_ptr := New_decl_attributes(field_decl_attributes,
            type_attributes_ptr, nil)
        else
          decl_attributes_ptr := New_decl_attributes(data_decl_attributes,
            type_attributes_ptr, nil);

        {***************************}
        { set scope decl attributes }
        {***************************}
        decl_attributes_ptr^.scope_decl_attributes_ptr := Get_scope_decl_attributes;

        {*******************}
        { check method kind }
        {*******************}
        if class_type_ptr = nil then
          method_kind := void_method
        else if class_type_ptr^.static then
          reference_method := true;

        {***************************}
        { init code decl attributes }
        {***************************}
        decl_attributes_ptr^.final := true;
        decl_attributes_ptr^.forward := (decl_kind = forward_decl);
        decl_attributes_ptr^.abstract := (method_kind = abstract_method);
        decl_attributes_ptr^.native := (decl_kind = native_decl);
        decl_attributes_ptr^.static := static;

        {********************}
        { make new code decl }
        {********************}
        decl_ptr := New_decl(code_decl);
        Set_decl_info(decl_ptr, decl_info_ptr);

        {******************************}
        { constructors and destructors }
        {******************************}
        if code_kind = procedure_code then
          begin
            Parse_special_method_name(code_kind, method_kind, class_type_ptr);
            code_attributes_ptr^.kind := code_kind;
          end;

        {**********************************************************}
        { parse method name and check against forward declarations }
        {**********************************************************}
        Match_name(method_name);

        {******************************}
        { allocate or borrow code decl }
        {******************************}
        forward_decl_attributes_ptr := nil;
        code_ptr := nil;

        if Found_local_id(method_name, forward_decl_attributes_ptr,
          stmt_attributes_ptr) then
          begin
            {*******************************************************}
            { check forward decl attributes against decl attributes }
            {*******************************************************}
            forward_decl_ptr :=
              decl_ptr_type(forward_decl_attributes_ptr^.decl_ref);
            Check_forward_method_decl(decl_attributes_ptr,
              forward_decl_attributes_ptr, forward_decl_ptr);

            if parsing_ok then
              if not forward_decl_attributes_ptr^.abstract then
                begin
                  {*******************************************}
                  { borrow actual code decl from forward decl }
                  {*******************************************}
                  code_ptr :=
                    code_ptr_type(forward_decl_ptr^.code_ptr)^.actual_code_ref;

                  {****************************}
                  { assign actual code to decl }
                  {****************************}
                  code_ptr^.code_decl_ref := decl_ptr;
                  decl_ptr^.code_ptr := forward_code_ptr_type(code_ptr);
                end;
          end;

        {**********************}
        { create new code decl }
        {**********************}
        if code_ptr = nil then
          begin
            code_ptr := New_code(code_kind, decl_ptr);

            {************************************}
            { if its a forward declaration, then }
                   { create actual code decl in advance }
            {************************************}
            if decl_attributes_ptr^.forward and not decl_attributes_ptr^.abstract
              then
              begin
                code_ptr^.actual_code_ref := New_code(code_kind, nil);
                code_ptr^.actual_code_ref^.forward_code_ref := code_ptr;
              end;
          end;

        {**********************}
        { initialize code decl }
        {**********************}
        code_ptr^.decl_kind := decl_kind;
        code_ptr^.method_kind := method_kind;
        code_ptr^.reference_method := reference_method;
        code_ptr^.class_type_ref := forward_type_ref_type(class_type_ptr);

        {********************}
        { create method name }
        {********************}
        if forward_decl_attributes_ptr <> nil then
          Make_actual_method_name(method_name, decl_ptr, decl_attributes_ptr,
            decl_ptr^.code_data_decl.data_expr_ptr, expr_attributes_ptr,
            forward_decl_attributes_ptr)
        else
          Make_implicit_new_id(method_name,
            decl_ptr^.code_data_decl.data_expr_ptr, expr_attributes_ptr,
            decl_attributes_ptr);

        if parsing_ok then
          begin
            temp := false;
            Check_native_method(decl_ptr, decl_attributes_ptr, class_type_ptr);

            {***********************************************}
            { set class constructor / destructor references }
            {***********************************************}
            if code_ptr^.kind in special_code_kinds then
              case code_ptr^.kind of
                constructor_code:
                  class_type_ptr^.constructor_code_ref := code_ptr;
                destructor_code:
                  class_type_ptr^.destructor_code_ref := code_ptr;
              end; {case}

            {**********************************}
            { set links to and from attributes }
            {**********************************}
            Set_decl_attributes(decl_ptr, decl_attributes_ptr);
            Set_expr_attributes(expr_ptr_type(expr_attributes_ptr^.expr_ref),
              expr_attributes_ptr);

            {********************************}
            { set decl flags from attributes }
            {********************************}
            Set_decl_properties(decl_ptr, decl_attributes_ptr);

            {**********************************}
            { set static level from attributes }
            {**********************************}
            code_ptr^.decl_static_level := decl_attributes_ptr^.static_level;
            type_attributes_ptr^.id_ptr := decl_attributes_ptr^.id_ptr;

            {*************************************************************}
            { for static procedures, bypass current scope to global scope }
            {*************************************************************}
            if static then
              begin
                temp := global_mode;
                global_mode := true;
              end;

            {********************}
            { push method scopes }
            {********************}
            if method_kind <> void_method then
              begin
                {*****************************}
                { push member scopes of class }
                {*****************************}
                class_decl_attributes_ptr :=
                  Get_decl_attributes(class_type_ptr^.type_decl_ref);
                Push_static_scope(class_decl_attributes_ptr);
                class_type_attributes_ptr :=
                  class_decl_attributes_ptr^.type_attributes_ptr;
                Push_post_scope(class_type_attributes_ptr^.public_table_ptr);
                Push_post_scope(class_type_attributes_ptr^.protected_table_ptr);
                Push_post_scope(class_type_attributes_ptr^.private_table_ptr);

                {************************************}
                { push member scopes of superclasses }
                {************************************}
                parent_type_attributes_ptr :=
                  class_type_attributes_ptr^.parent_type_attributes_ptr;
                while (parent_type_attributes_ptr <> nil) do
                  begin
                    Push_post_scope(parent_type_attributes_ptr^.public_table_ptr);
                    Push_post_scope(parent_type_attributes_ptr^.protected_table_ptr);
                    parent_type_attributes_ptr :=
                      parent_type_attributes_ptr^.parent_type_attributes_ptr;
                  end;

                {*************************************************************}
                { for member functions, first parameter is ptr to object data }
                {*************************************************************}
                Push_static_scope(decl_attributes_ptr);
                Push_post_scope(code_attributes_ptr^.implicit_table_ptr);
                with code_attributes_ptr^ do
                  begin
                    class_name :=
                      Get_decl_attributes_name(class_decl_attributes_ptr);
                    Make_implicit_param_decl(code_ptr^.implicit_param_decls_ptr,
                      implicit_signature_ptr, class_name,
                      class_decl_attributes_ptr^.type_attributes_ptr,
                      code_ptr^.reference_method);
                    Make_implicit_superclass_decls(code_ptr^.implicit_param_decls_ptr, class_type_ptr^.parent_class_ref, code_ptr^.reference_method);
                  end;
              end
            else
              class_type_ptr := nil;

            {*****************************************}
            { parse initializer for method prototypes }
            {*****************************************}
            init_expr_ptr := nil;
            init_expr_attributes_ptr := expr_attributes_ptr;
            Parse_proto_initializer(init_expr_ptr, init_expr_attributes_ptr,
              decl_attributes_ptr);
            if init_expr_ptr <> nil then
              code_ptr^.decl_kind := proto_decl;

            {*************************************}
            { parse method parameter declarations }
            {*************************************}
            Push_static_scope(decl_attributes_ptr);
            Parse_param_decls(code_ptr, decl_attributes_ptr);

            {***********************************}
            { compare parameters with prototype }
            {***********************************}
            if (code_ptr^.forward_code_ref <> nil) then
              begin
                Check_forward_decl(code_ptr^.forward_code_ref, code_ptr,
                  forward_decl_attributes_ptr, decl_attributes_ptr);
                Assign_forward_code_decls(code_ptr^.forward_code_ref, code_ptr);
              end;

            {***********************************************}
            { compare prototype method with its initializer }
            {***********************************************}
            if parsing_ok then
              if init_expr_ptr <> nil then
                Check_proto_initializer(decl_attributes_ptr,
                  init_expr_attributes_ptr);

            if (next_token.kind = is_tok) and (code_ptr^.decl_kind = actual_decl)
              then
              begin
                {**********************}
                { parse implementation }
                {**********************}
                last_decl_ptr := nil;

                {**************************}
                { parse local declarations }
                {**************************}
                Get_next_token;
                Push_prev_scope(code_attributes_ptr^.local_table_ptr);
                Parse_decls_list(code_ptr^.local_decls_ptr, last_decl_ptr,
                  class_type_ptr);

                {***************************}
                { parse chained constructor }
                {***************************}
                if code_ptr^.kind = constructor_code then
                  if class_type_ptr^.parent_class_ref <> nil then
                    if class_type_ptr^.parent_class_ref^.constructor_code_ref <>
                      nil then
                      begin
                        Parse_superclass_constructor(code_ptr^.local_stmts_ptr,
                          class_type_ptr);
                        Match(semi_colon_tok);
                      end;

                {************************}
                { parse local statements }
                {************************}
                if code_ptr^.local_stmts_ptr <> nil then
                  Parse_stmts(code_ptr^.local_stmts_ptr^.next)
                else
                  Parse_stmts(code_ptr^.local_stmts_ptr);

                Match(end_tok);
              end
            else
              begin
                {**********************************}
                { prototype or forward declaration }
                {**********************************}
                if code_ptr^.decl_kind = actual_decl then
                  code_ptr^.decl_kind := proto_decl;
                if code_ptr^.decl_kind = proto_decl then
                  decl_attributes_ptr^.final := false;

                {*******************************}
                { match final end, if necessary }
                {*******************************}
                if code_ptr^.initial_param_decls_ptr <> nil then
                  Match(end_tok)
                else if code_ptr^.optional_param_decls_ptr <> nil then
                  Match(end_tok)
                else if code_ptr^.optional_param_stmts_ptr <> nil then
                  Match(end_tok)
                else if code_ptr^.return_param_decls_ptr <> nil then
                  Match(end_tok);
              end;

            {***************************************************}
            { check for return assignment of functional methods }
            {***************************************************}
            if parsing_ok then
              if code_ptr^.kind in functional_code_kinds then
                if code_ptr^.decl_kind = actual_decl then
                  if not Stmts_return(code_ptr^.local_stmts_ptr) then
                    begin
                      Parse_error;
                      writeln('The last statement of a function or shader');
                      writeln('must always assign the return value.');
                      error_reported := true;
                    end;

            {************************************}
            { get comments at end of declaration }
            {************************************}
            Match(semi_colon_tok);
            Get_post_decl_info(decl_info_ptr);

            {***********************}
            { mark method as unused }
            {***********************}
            if forward_decl_attributes_ptr <> nil then
              begin
                forward_decl_attributes_ptr^.used := true;
                decl_attributes_ptr^.used := true;
              end
            else
              decl_attributes_ptr^.used := false;

            {*********************}
            { pop scope of method }
            {*********************}
            Pop_static_scope;

            {*********************************************}
            { pop member scopes of class and superclasses }
            {*********************************************}
            if method_kind <> void_method then
              begin
                Pop_static_scope;
                Pop_static_scope;
              end;

            {******************************}
            { create prototype initializer }
            {******************************}
            if parsing_ok then
              if init_expr_ptr <> nil then
                Make_proto_initializer(decl_ptr^.code_data_decl.init_stmt_ptr,
                  init_expr_ptr, decl_attributes_ptr, init_expr_attributes_ptr);

            {*****************************************}
            { for static procedures, pop global scope }
            {*****************************************}
            if static then
              global_mode := temp;

            {*******************************}
            { check for unused declarations }
            {*******************************}
            if parsing_ok then
              begin
                Report_unused_code_decls(code_ptr);
                Remove_unused_code_decls(code_ptr, false);
              end;
          end; {if parsing_ok}
      end {if}
    else
      begin
        Parse_error;
        writeln('Expected a method declaration here.');
        error_reported := true;
      end;
end; {procedure Parse_method_decl}


procedure Check_forward_decls(decl_ptr: decl_ptr_type);
var
  code_ptr: code_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  while (decl_ptr <> nil) and parsing_ok do
    begin
      if decl_ptr^.kind = code_decl then
        begin
          code_ptr := code_ptr_type(decl_ptr^.code_ptr);
          expr_ptr := decl_ptr^.code_data_decl.data_expr_ptr;
          expr_attributes_ptr := Get_expr_attributes(expr_ptr);

          if code_ptr^.decl_kind = forward_decl then
            if code_ptr^.method_kind <> abstract_method then
              if code_ptr^.actual_code_ref^.code_decl_ref = nil then
                begin
                  Parse_error;
                  write('The forward decl, ');
                  write(Quotate_str(Get_expr_attributes_name(expr_attributes_ptr)));
                  write(', lacks an actual implementation.');
                  writeln;
                  error_reported := true;
                end;
        end;

      decl_ptr := decl_ptr^.next;
    end;
end; {procedure Check_forward_decls}


end.

