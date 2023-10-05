unit msg_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             msg_parser                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse messages         }
{       (method calls) into an abstract syntax tree.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  expr_attributes, exprs, stmts, type_decls;


{*******************************************}
{ routines to parse subprogram param values }
{*******************************************}
procedure Parse_proc_stmt_tail(var stmt_ptr, last_stmt_ptr: stmt_ptr_type;
  expr_ptr, method_data_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_func_stmt_tail(var stmt_ptr: stmt_ptr_type;
  expr_ptr, method_data_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_shader_stmt_tail(var stmt_ptr, last_stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);

{***************************************}
{ routines to parse method param values }
{***************************************}
procedure Parse_proc_method_tail(var stmt_ptr, last_stmt_ptr: stmt_ptr_type;
  method_data_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_func_method_tail(var stmt_ptr: stmt_ptr_type;
  method_data_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

{**********************************************}
{ routines to parse static method param values }
{**********************************************}
procedure Parse_void_proc_method_stmt(var stmt_ptr, last_stmt_ptr:
  stmt_ptr_type);


implementation
uses
  strings, code_types, symbol_tables, type_attributes, code_attributes,
  stmt_attributes, decl_attributes, arrays, decls, code_decls, make_exprs,
  tokens, scanner, tokenizer, parser, match_literals, match_terms, term_parser,
  expr_parser, value_parser, member_parser, scoping, implicit_derefs,
  stmt_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                       complex statements                      }
{***************************************************************}
{       <cmplx_stmt> ::= id <shader_stmt_tail> <object_stmt> ;  }
{       <cmplx_stmt> ::= id <cmplx_stmt_tail> ;                 }
{       <object_stmt> ::= id <cmplx_stmt_tail> ;                }
{       <shader_stmt_tail> ::= <param_values> <edge_shader_stmt>}
{       <edge_shader_stmt> ::= id <param_values>                }
{       <cmplx_stmt_tail> ::= <param_values> <cmplx_stmt_body>  }
{       <cmplx_stmt_body> ::= <opt_stmts> <return_stmts> end    }
{       <opt_stmts> ::= with <stmts>                            }
{       <return_stmts> ::= return <stmts>                       }
{***************************************************************}


const
  memory_alert = false;


  {**********************}
  { forward declarations }
  {**********************}
procedure Increment_expr_dynamic_links(var expr_ptr: expr_ptr_type);
  forward;
procedure Decrement_expr_dynamic_links(var expr_ptr: expr_ptr_type);
  forward;


function Get_context_code: code_ptr_type;
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  decl_ptr: decl_ptr_type;
  code_ptr: code_ptr_type;
begin
  code_ptr := nil;
  decl_attributes_ptr := Get_scope_decl_attributes;
  if decl_attributes_ptr <> nil then
    begin
      decl_ptr := decl_ptr_type(decl_attributes_ptr^.decl_ref);
      if decl_ptr^.kind = code_decl then
        code_ptr := code_ptr_type(decl_ptr^.code_ptr);
    end;
  Get_context_code := code_ptr;
end; {function Get_context_code}


procedure Check_context(decl_code_ptr, stmt_code_ptr: code_ptr_type);
const
  unrestricted_decls = [procedure_code, function_code, constructor_code,
    destructor_code];
begin
  if decl_code_ptr <> nil then
    if stmt_code_ptr <> nil then
      if not (stmt_code_ptr^.kind in unrestricted_decls) then
        case decl_code_ptr^.kind of

          {*********************************}
          { stmt called from procedure decl }
          {*********************************}
          procedure_code, constructor_code, destructor_code:
            begin
              Parse_error;
              writeln('Only procedures and functions');
              writeln('may be called from a procedure.');
              error_reported := true;
            end;

          {********************************}
          { stmt called from function decl }
          {********************************}
          function_code:
            begin
              Parse_error;
              writeln('Only procedures and functions');
              writeln('may be called from a function.');
              error_reported := true;
            end;

          {******************************}
          { stmt called from shader decl }
          {******************************}
          shader_code:
            if (stmt_code_ptr^.kind <> shader_code) then
              begin
                Parse_error;
                writeln('Only procedures and functions, and shaders');
                writeln('may be called from a shader.');
                error_reported := true;
              end;

          {******************************}
          { stmt called from object decl }
          {******************************}
          object_code:
            if not (stmt_code_ptr^.kind in [object_code, shader_code]) then
              begin
                Parse_error;
                writeln('Only procedures, functions, shaders,');
                writeln('and objects may be called from a shape.');
                error_reported := true;
              end;

          {*******************************}
          { stmt called from picture decl }
          {*******************************}
          picture_code:
            if not (stmt_code_ptr^.kind in [object_code, shader_code]) then
              begin
                Parse_error;
                writeln('Only procedures, functions, shaders, objects,');
                writeln('and pictures may be called from a picture.');
                error_reported := true;
              end;

          {****************************}
          { stmt called from anim decl }
          {****************************}
          anim_code:
            if not (stmt_code_ptr^.kind in [picture_code, anim_code]) then
              begin
                Parse_error;
                writeln('Only procedures, functions, pictures, and anims');
                writeln('may be called from an anim.');
                error_reported := true;
              end;
        end; {case}
end; {procedure Check_context}


procedure Parse_proc_method_tail(var stmt_ptr, last_stmt_ptr: stmt_ptr_type;
  method_data_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  expr_ptr: expr_ptr_type;
  static_binding: boolean;
  type_attributes_ptr: type_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      {**************************}
      { override dynamic binding }
      {**************************}
      static_binding := (next_token.kind = static_id_tok);

      {*******************}
      { parse method name }
      {*******************}
      type_attributes_ptr := expr_attributes_ptr^.alias_type_attributes_ptr;
      type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);
      decl_attributes_ptr :=
        Get_id_decl_attributes(type_attributes_ptr^.id_ptr);
      Parse_class_method_id(expr_ptr, expr_attributes_ptr, decl_attributes_ptr);

      {*****************************}
      { parse method and parameters }
      {*****************************}
      if parsing_ok then
        if Found_method_attributes(expr_attributes_ptr^.decl_attributes_ptr,
          procedural_code_kinds) then
          begin
            Parse_proc_stmt_tail(stmt_ptr, last_stmt_ptr, expr_ptr,
              method_data_ptr, expr_attributes_ptr);

            if parsing_ok then
              begin
                {****************************}
                { deactivate dynamic binding }
                {****************************}
                if static_binding then
                  if stmt_ptr^.kind = dynamic_method_stmt then
                    stmt_ptr^.kind := static_method_stmt;
              end;
          end
        else
          begin
            Parse_error;
            writeln('Expected a procedural method here.');
            error_reported := true;
          end;

    end; {if parsing_ok}
end; {procedure Parse_proc_method_tail}


procedure Parse_func_method_tail(var stmt_ptr: stmt_ptr_type;
  method_data_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  expr_ptr: expr_ptr_type;
  static_binding: boolean;
  type_attributes_ptr: type_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      {**************************}
      { override dynamic binding }
      {**************************}
      static_binding := (next_token.kind = static_id_tok);

      {*******************}
      { parse method name }
      {*******************}
      type_attributes_ptr := expr_attributes_ptr^.alias_type_attributes_ptr;
      type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);
      decl_attributes_ptr :=
        Get_id_decl_attributes(type_attributes_ptr^.id_ptr);
      Parse_class_method_id(expr_ptr, expr_attributes_ptr, decl_attributes_ptr);

      {*****************************}
      { parse method and parameters }
      {*****************************}
      if parsing_ok then
        if Found_method_attributes(expr_attributes_ptr^.decl_attributes_ptr,
          functional_code_kinds) then
          begin
            Parse_func_stmt_tail(stmt_ptr, expr_ptr, method_data_ptr,
              expr_attributes_ptr);

            if parsing_ok then
              begin
                {****************************}
                { deactivate dynamic binding }
                {****************************}
                if static_binding then
                  if stmt_ptr^.kind = dynamic_method_stmt then
                    stmt_ptr^.kind := static_method_stmt;
              end;
          end
        else
          begin
            Parse_error;
            writeln('Expected a functional method here.');
            error_reported := true;
          end;

    end; {if parsing_ok}
end; {procedure Parse_func_method_tail}


procedure Parse_void_proc_method_tail(var stmt_ptr, last_stmt_ptr:
  stmt_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_ptr: decl_ptr_type;
  expr_ptr: expr_ptr_type;
  code_ptr: code_ptr_type;
begin
  if parsing_ok then
    begin
      if next_token.kind = id_tok then
        begin
          {*******************}
          { parse method name }
          {*******************}
          Parse_class_method_id(expr_ptr, expr_attributes_ptr,
            decl_attributes_ptr);

          if Found_method_attributes(expr_attributes_ptr^.decl_attributes_ptr,
            procedural_code_kinds) then
            begin
              {**************************************}
              { get code declaration from attributes }
              {**************************************}
              decl_ptr :=
                decl_ptr_type(expr_attributes_ptr^.decl_attributes_ptr^.decl_ref);
              code_ptr := code_ptr_type(decl_ptr^.code_ptr);

              if (code_ptr^.implicit_param_decls_ptr = nil) then
                begin
                  Parse_proc_stmt_tail(stmt_ptr, last_stmt_ptr, expr_ptr, nil,
                    expr_attributes_ptr);

                  if parsing_ok then
                    begin
                      {****************************}
                      { deactivate dynamic binding }
                      {****************************}
                      if stmt_ptr^.kind = dynamic_method_stmt then
                        stmt_ptr^.kind := static_method_stmt;
                      stmt_ptr^.stmt_info_ptr^.implicit_method := false;
                    end;
                end
              else
                begin
                  Parse_error;
                  write(Quotate_str(Get_expr_attributes_name(expr_attributes_ptr)));
                  writeln(' is not a static method.');
                  error_reported := true;
                end;
            end
          else
            begin
              Parse_error;
              write(Quotate_str(Get_expr_attributes_name(expr_attributes_ptr)));
              writeln(' is not a procedural method.');
              error_reported := true;
            end;
        end
      else
        begin
          Parse_error;
          writeln('Expected the name of a class here.');
          error_reported := true;
        end;

    end; {if parsing_ok}
end; {procedure Parse_void_proc_method_tail}


procedure Parse_void_proc_method_stmt(var stmt_ptr, last_stmt_ptr:
  stmt_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  class_name: string_type;
begin
  {*********************}
  { parse name of class }
  {*********************}
  if parsing_ok then
    begin
      class_name := Token_to_id(next_token);
      if Found_type_id(class_name, decl_attributes_ptr, stmt_attributes_ptr)
        then
        begin
          type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;
          if type_attributes_ptr^.kind in class_type_kinds then
            begin
              Get_next_token;
              Match(s_tok);
              Parse_void_proc_method_tail(stmt_ptr, last_stmt_ptr,
                decl_attributes_ptr);
            end;
        end
      else
        begin
          Parse_error;
          writeln(Quotate_str(class_name), ' is not a class.');
          error_reported := true;
        end;
    end; {if parsing_ok}
end; {procedure Parse_void_proc_method_stmt}


{************************  productions  ************************}
{       <shader_stmt_tail> ::= <param_values> <edge_shader_stmt>}
{       <edge_shader_stmt> ::= id <param_values>                }
{***************************************************************}

procedure Parse_shader_stmt_tail(var stmt_ptr, last_stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  shader_stmt_ptr: stmt_ptr_type;
begin
  if parsing_ok then
    begin
      stmt_ptr := nil;
      last_stmt_ptr := nil;

      {******************************************}
      { extract shader statement from expression }
      {******************************************}
      shader_stmt_ptr := stmt_ptr_type(expr_ptr^.fn_stmt_ptr);
      expr_ptr^.fn_stmt_ptr := nil;
      Destroy_expr(expr_ptr, true);

      {*****************************}
      { parse object statement name }
      {*****************************}
      Parse_expr(expr_ptr, expr_attributes_ptr);
      Deref_expr(expr_ptr, expr_attributes_ptr);

      {*************************}
      { parse object parameters }
      {*************************}
      if parsing_ok then
        begin
          if Found_method_attributes(expr_attributes_ptr^.decl_attributes_ptr,
            [object_code]) then
            Parse_proc_stmt_tail(stmt_ptr, last_stmt_ptr, expr_ptr, nil,
              expr_attributes_ptr)
          else if expr_attributes_ptr^.alias_type_attributes_ptr^.kind in
            class_type_kinds then
            Parse_proc_method_tail(stmt_ptr, last_stmt_ptr, expr_ptr,
              expr_attributes_ptr)
          else
            begin
              Parse_error;
              writeln('A shape stmt is required following a shader stmt.');
              error_reported := true;
            end;

          {**********************}
          { add shaders to shape }
          {**********************}
          if parsing_ok then
            begin
              stmt_ptr^.stmt_data_ptr := New_stmt_data;
              stmt_ptr^.stmt_data_ptr^.shader_stmt_ptr := shader_stmt_ptr;
            end;
        end; {if parsing_ok}
    end; {if parsing_ok}
end; {procedure Parse_shader_stmt_tail}


function New_method_stmt(code_ptr: code_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
  type_ptr: type_ptr_type;
begin
  if code_ptr^.decl_kind = proto_decl then
    stmt_ptr := New_stmt(proto_method_stmt)
  else
    case code_ptr^.method_kind of

      void_method, static_method, final_method:
        stmt_ptr := New_stmt(static_method_stmt);

      virtual_method:
        stmt_ptr := New_stmt(dynamic_method_stmt);

      abstract_method:
        begin
          type_ptr := type_ptr_type(code_ptr^.class_type_ref);
          if type_ptr^.class_kind = interface_class then
            stmt_ptr := New_stmt(interface_method_stmt)
          else
            stmt_ptr := New_stmt(dynamic_method_stmt);
        end;

      else
        stmt_ptr := nil;
    end;

  New_method_stmt := stmt_ptr;
end; {function New_method_stmt}


{*****************************************************}
{ routines to increment an expression's dynamic links }
{*****************************************************}


function Local_to_nested(expr_ptr: expr_ptr_type): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
begin
  new_expr_ptr := New_expr(nested_identifier);
  new_expr_ptr^.dynamic_links := 1;
  new_expr_ptr^.nested_id_expr_ptr := expr_ptr;

  Local_to_nested := new_expr_ptr;
end; {function Local_to_nested}


procedure Increment_array_bounds_list_dynamic_links(array_bounds_list_ptr:
  array_bounds_list_ptr_type);
var
  array_bounds_ptr: array_bounds_ptr_type;
  min_expr_ptr, max_expr_ptr: expr_ptr_type;
begin
  if array_bounds_list_ptr <> nil then
    begin
      array_bounds_ptr := array_bounds_list_ptr^.first;
      while (array_bounds_ptr <> nil) do
        begin
          min_expr_ptr := expr_ptr_type(array_bounds_ptr^.min_expr_ptr);
          max_expr_ptr := expr_ptr_type(array_bounds_ptr^.max_expr_ptr);
          Increment_expr_dynamic_links(min_expr_ptr);
          Increment_expr_dynamic_links(max_expr_ptr);
          array_bounds_ptr^.min_expr_ptr := forward_expr_ptr_type(min_expr_ptr);
          array_bounds_ptr^.max_expr_ptr := forward_expr_ptr_type(max_expr_ptr);
          array_bounds_ptr := array_bounds_ptr^.next;
        end;
    end;
end; {procedure Increment_array_bounds_list_dynamic_links}


procedure Increment_array_index_list_dynamic_links(array_index_list_ptr:
  array_index_list_ptr_type);
var
  array_index_ptr: array_index_ptr_type;
  expr_ptr: expr_ptr_type;
begin
  if array_index_list_ptr <> nil then
    begin
      array_index_ptr := array_index_list_ptr^.first;
      while (array_index_ptr <> nil) do
        begin
          expr_ptr := expr_ptr_type(array_index_ptr^.index_expr_ptr);
          Increment_expr_dynamic_links(expr_ptr);
          array_index_ptr^.index_expr_ptr := forward_expr_ptr_type(expr_ptr);
          array_index_ptr := array_index_ptr^.next;
        end;
    end;
end; {procedure Increment_array_index_list_dynamic_links}


procedure Increment_expr_dynamic_links(var expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do

    {*******************}
    { local identifiers }
    {*******************}
    if kind = local_identifier then
      expr_ptr := Local_to_nested(expr_ptr)

    else if kind in nonterminal_id_set then
      case kind of

        {************************}
        { identifier expressions }
        {************************}
        nested_identifier:
          expr_ptr^.dynamic_links := expr_ptr^.dynamic_links + 1;
        deref_op, address_op:
          Increment_expr_dynamic_links(operand_ptr);

        {****************************}
        { ptr conversion expressions }
        {****************************}
        ptr_cast, type_query:
          Increment_expr_dynamic_links(class_expr_ptr);

        {*******************}
        { array expressions }
        {*******************}
        boolean_array_dim..reference_array_dim:
          begin
            Increment_expr_dynamic_links(dim_element_expr_ptr);
            Increment_array_bounds_list_dynamic_links(dim_bounds_list_ptr);
          end;

        {*********************}
        { array dereferencing }
        {*********************}
        boolean_array_deref..reference_array_deref:
          begin
            Increment_expr_dynamic_links(deref_base_ptr);
            Increment_array_index_list_dynamic_links(deref_index_list_ptr);
          end;

        {****************************}
        { array subrange expressions }
        {****************************}
        boolean_array_subrange..reference_array_subrange:
          begin
            Increment_expr_dynamic_links(subrange_base_ptr);
            Increment_array_index_list_dynamic_links(subrange_index_list_ptr);
            Increment_array_bounds_list_dynamic_links(subrange_bounds_list_ptr);
          end;

        {***********************}
        { structure expressions }
        {***********************}
        struct_deref, struct_offset:
          Increment_expr_dynamic_links(base_expr_ptr);
        field_deref, field_offset:
          ;

        {*************}
        { addr caches }
        {*************}
        itself, new_itself:
          ;

      end; {case}
end; {procedure Increment_dynamic_links}


{*****************************************************}
{ routines to decrement an expression's dynamic links }
{*****************************************************}


function Nested_to_local(expr_ptr: expr_ptr_type): expr_ptr_type;
var
  temp_expr_ptr: expr_ptr_type;
begin
  temp_expr_ptr := expr_ptr;
  expr_ptr := expr_ptr^.nested_id_expr_ptr;
  temp_expr_ptr^.nested_id_expr_ptr := nil;
  Destroy_expr(temp_expr_ptr, false);

  Nested_to_local := expr_ptr;
end; {function Nested_to_local}


procedure Decrement_array_bounds_list_dynamic_links(array_bounds_list_ptr:
  array_bounds_list_ptr_type);
var
  array_bounds_ptr: array_bounds_ptr_type;
begin
  if array_bounds_list_ptr <> nil then
    begin
      array_bounds_ptr := array_bounds_list_ptr^.first;
      while (array_bounds_ptr <> nil) do
        begin
          Decrement_expr_dynamic_links(expr_ptr_type(array_bounds_ptr^.min_expr_ptr));
          Decrement_expr_dynamic_links(expr_ptr_type(array_bounds_ptr^.max_expr_ptr));
          array_bounds_ptr := array_bounds_ptr^.next;
        end;
    end;
end; {procedure Decrement_array_bounds_list_dynamic_links}


procedure Decrement_array_index_list_dynamic_links(array_index_list_ptr:
  array_index_list_ptr_type);
var
  array_index_ptr: array_index_ptr_type;
begin
  if array_index_list_ptr <> nil then
    begin
      array_index_ptr := array_index_list_ptr^.first;
      while (array_index_ptr <> nil) do
        begin
          Decrement_expr_dynamic_links(expr_ptr_type(array_index_ptr^.index_expr_ptr));
          array_index_ptr := array_index_ptr^.next;
        end;
    end;
end; {procedure Decrement_array_index_list_dynamic_links}


procedure Decrement_expr_dynamic_links(var expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do
    if kind in nonterminal_id_set then
      case kind of

        {************************}
        { identifier expressions }
        {************************}
        nested_identifier:
          begin
            if (expr_ptr^.dynamic_links = 1) and (expr_ptr^.static_links = 0)
              then
              expr_ptr := Nested_to_local(expr_ptr)
            else
              expr_ptr^.dynamic_links := expr_ptr^.dynamic_links - 1;
          end;
        deref_op, address_op:
          Decrement_expr_dynamic_links(operand_ptr);

        {****************************}
        { ptr conversion expressions }
        {****************************}
        ptr_cast, type_query:
          Decrement_expr_dynamic_links(class_expr_ptr);

        {*******************}
        { array expressions }
        {*******************}
        boolean_array_dim..reference_array_dim:
          begin
            Decrement_expr_dynamic_links(dim_element_expr_ptr);
            Decrement_array_bounds_list_dynamic_links(dim_bounds_list_ptr);
          end;

        {*********************}
        { array dereferencing }
        {*********************}
        boolean_array_deref..reference_array_deref:
          begin
            Decrement_expr_dynamic_links(deref_base_ptr);
            Decrement_array_index_list_dynamic_links(deref_index_list_ptr);
          end;

        {****************************}
        { array subrange expressions }
        {****************************}
        boolean_array_subrange..reference_array_subrange:
          begin
            Decrement_expr_dynamic_links(subrange_base_ptr);
            Decrement_array_index_list_dynamic_links(subrange_index_list_ptr);
            Decrement_array_bounds_list_dynamic_links(subrange_bounds_list_ptr);
          end;

        {***********************}
        { structure expressions }
        {***********************}
        struct_deref, struct_offset:
          Decrement_expr_dynamic_links(base_expr_ptr);
        field_deref, field_offset:
          ;

      end; {case}
end; {procedure Decrement_dynamic_links}


{****************************************************}
{ routines to creating implicit method param assigns }
{****************************************************}


procedure Make_method_data_assign(stmt_ptr: stmt_ptr_type;
  var method_data_ptr: expr_ptr_type;
  context_code_ptr: code_ptr_type);
var
  code_ptr: code_ptr_type;
  decl_ptr: decl_ptr_type;
  expr_ptr: expr_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
  parameter_ptr: parameter_ptr_type;
  counter, dynamic_level: integer;
begin
  with stmt_ptr^ do
    begin
      code_ptr := code_ptr_type(stmt_code_ref);
      if code_ptr^.forward_code_ref <> nil then
        code_ptr := code_ptr^.forward_code_ref;

      {*****************************************************}
      { check that a method is not called from a non method }
      {*****************************************************}
      if (method_data_ptr = nil) then
        if code_ptr^.method_kind <> void_method then
          if context_code_ptr <> nil then
            if context_code_ptr^.method_kind = void_method then
              begin
                Parse_error;
                writeln('Methods may not be implicitly called from void methods.');
                error_reported := true;
              end;

      {**************}
      { method calls }
      {**************}
      if method_data_ptr = nil then
        stmt_info_ptr^.implicit_method := true;

      if (code_ptr^.implicit_param_decls_ptr <> nil) and parsing_ok then
        begin
          if method_data_ptr = nil then
            begin
              if context_code_ptr <> nil then
                begin
                  {*******************************************}
                  { create implicit parameter for method data }
                  {*******************************************}
                  decl_attributes_ptr :=
                    Get_decl_attributes(context_code_ptr^.implicit_param_decls_ptr);
                  method_data_ptr := New_identifier(decl_attributes_ptr,
                    expr_attributes_ptr);

                  {****************************************}
                  { reach context method from nested calls }
                  {****************************************}
                  dynamic_level := Get_dynamic_scope_level - 1;
                  for counter := 1 to dynamic_level do
                    Increment_expr_dynamic_links(method_data_ptr);
                end
              else
                begin
                  Parse_error;
                  writeln('This method must be called from an object.');
                  error_reported := true;
                end;
            end
          else
            expr_attributes_ptr := Get_expr_attributes(method_data_ptr);

          if parsing_ok then
            begin
              {************************************}
              { create dynamic parameter reference }
              {************************************}
              Increment_expr_dynamic_links(method_data_ptr);

              {********************************************}
              { take address of method data, if neccessary }
              {********************************************}
              if code_ptr^.reference_method then
                Reference_expr(method_data_ptr, expr_attributes_ptr)
              else if context_code_ptr <> nil then
                if context_code_ptr^.reference_method then
                  Deref_expr(method_data_ptr, expr_attributes_ptr);

              {******************************************************}
              { create implicit parameter assignment for method data }
              {******************************************************}
              decl_ptr := code_ptr^.code_decl_ref;
              decl_attributes_ptr := Get_decl_attributes(decl_ptr);
              code_attributes_ptr :=
                decl_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr;
              parameter_ptr :=
                code_attributes_ptr^.implicit_signature_ptr^.parameter_ptr;
              expr_ptr := New_param_expr(parameter_ptr, expr_attributes_ptr);
              implicit_stmts_ptr := New_param_assign(expr_ptr, method_data_ptr,
                expr_attributes_ptr);
            end;
        end;
    end; {with}
end; {procedure Make_method_data_assign}


procedure Parse_param_values(stmt_ptr: stmt_ptr_type;
  var method_data_ptr: expr_ptr_type;
  context_code_ptr: code_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
  procedural_params: boolean);
var
  temp: boolean;
  found_with_block: boolean;
begin
  if parsing_ok then
    begin
      temp := parsing_param_values;
      found_with_block := false;
      parsing_param_values := true;
      Push_dynamic_scope(Get_stmt_attributes(stmt_ptr));

      {**********************************}
      { create implicit param assignment }
      {**********************************}
      Make_method_data_assign(stmt_ptr, method_data_ptr, context_code_ptr);

      {******************************}
      { parse formatted param values }
      {******************************}
      Push_prev_scope(code_attributes_ptr^.public_param_table_ptr);
      Parse_formatted_param_values(code_attributes_ptr,
        stmt_ptr^.param_assign_stmts_ptr);

      {*****************************************}
      { parse unformatted parameter assignments }
      {*****************************************}
      if (next_token.kind = with_tok) then
        begin
          Get_next_token;
          found_with_block := true;
          Push_prev_scope(code_attributes_ptr^.protected_param_table_ptr);
          Parse_stmts(stmt_ptr^.param_stmts_ptr);
          Pop_prev_scope;
        end; {if}

      if (next_token.kind = return_tok) then
        begin
          Get_next_token;

          {*************************************}
          { parse formatted return param values }
          {*************************************}
          if code_attributes_ptr^.return_signature_ptr <> nil then
            begin
              Push_prev_scope(code_attributes_ptr^.public_return_table_ptr);
              Parse_formatted_return_values(code_attributes_ptr,
                stmt_ptr^.return_assign_stmts_ptr);
              Pop_prev_scope;
            end;

          {************************************************}
          { parse unformatted return parameter assignments }
          {************************************************}
          if (next_token.kind = with_tok) then
            begin
              Get_next_token;
              found_with_block := true;
              Push_prev_scope(code_attributes_ptr^.protected_return_table_ptr);
              Parse_stmts(stmt_ptr^.return_stmts_ptr);
              Pop_prev_scope;
            end;
        end;

      if procedural_params then
        if found_with_block then
          if (next_token.kind <> comma_tok) then
            Match(end_tok);

      parsing_param_values := temp;
      Pop_dynamic_scope;
    end; {if parsing_ok}
end; {procedure Parse_param_values}


{************************  productions  ************************}
{       <cmplx_stmt> ::= id <shader_stmt_tail> <object_stmt> ;  }
{       <cmplx_stmt> ::= id <func_stmt_tail> ;                  }
{       <cmplx_stmt_tail> ::= <param_values> <func_stmt_body>   }
{       <cmplx_stmt_body> ::= with <stmts> end                  }
{***************************************************************}

procedure Parse_func_stmt_tail(var stmt_ptr: stmt_ptr_type;
  expr_ptr, method_data_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_ptr: decl_ptr_type;
  code_ptr, context_code_ptr: code_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
begin
  if parsing_ok then
    begin
      {**************************************}
      { get code declaration from attributes }
      {**************************************}
      decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
      decl_ptr := decl_ptr_type(decl_attributes_ptr^.decl_ref);
      code_ptr := code_ptr_type(decl_ptr^.code_ptr);
      context_code_ptr := Get_context_code;

      if parsing_ok then
        begin
          {******************************************}
          { create and initialize new statement info }
          {******************************************}
          stmt_info_ptr := New_stmt_info;
          stmt_info_ptr^.line_number := Get_line_number;

          {*************************************}
          { create and initialize new statement }
          {*************************************}
          stmt_ptr := New_method_stmt(code_ptr);
          Set_stmt_info(stmt_ptr, stmt_info_ptr);

          {********************************}
          { assign fields of function call }
          {********************************}
          stmt_ptr^.stmt_name_ptr := expr_ptr;
          if code_ptr^.actual_code_ref <> nil then
            stmt_ptr^.stmt_code_ref :=
              forward_code_ref_type(code_ptr^.actual_code_ref)
          else
            stmt_ptr^.stmt_code_ref := forward_code_ref_type(code_ptr);

          {*********************************}
          { create new statement attributes }
          {*********************************}
          stmt_attributes_ptr := New_stmt_attributes(decl_attributes_ptr);
          Set_stmt_attributes(stmt_ptr, stmt_attributes_ptr);

          with stmt_ptr^ do
            begin
              {*****************************************}
              { parse mandatory and optional parameters }
              {*****************************************}
              code_attributes_ptr :=
                expr_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr;
              Parse_param_values(stmt_ptr, method_data_ptr, context_code_ptr,
                code_attributes_ptr, false);

              {***********************************}
              { return attributes of return value }
              {***********************************}
              expr_attributes_ptr :=
                expr_attributes_ptr_type(code_attributes_ptr^.return_value_attributes_ptr);
            end; {with}

        end; {if parsing_ok}
    end; {if parsing_ok}
end; {procedure Parse_func_stmt_tail}


{************************  productions  ************************}
{       <proc_stmt> ::= id <shader_stmt_tail> <proc_stmt> ;     }
{       <proc_stmt> ::= id <proc_stmt_tail> ;                   }
{       <proc_stmt_tail> ::= <param_values> <proc_stmt_body>    }
{       <proc_stmt_body> ::= <opt_stmts> <return_stmts> end     }
{       <opt_stmts> ::= with <stmts>                            }
{       <return_stmts> ::= return <stmts>                       }
{***************************************************************}

procedure Parse_proc_stmt_tail(var stmt_ptr: stmt_ptr_type;
  var last_stmt_ptr: stmt_ptr_type;
  expr_ptr, method_data_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_ptr: decl_ptr_type;
  code_ptr, context_code_ptr: code_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
begin
  if parsing_ok then
    begin
      {**************************************}
      { get code declaration from attributes }
      {**************************************}
      decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
      decl_ptr := decl_ptr_type(decl_attributes_ptr^.decl_ref);
      code_ptr := code_ptr_type(decl_ptr^.code_ptr);
      context_code_ptr := Get_context_code;

      {*********************************************************}
      { check context - some statements such as object stmts    }
      { and picture stmts can only occur within certain kinds   }
      { of decls, for instance, it doesn't make sense to make   }
      { an object instance inside of a function declaration,    }
      { but it does make sense inside of a picture declaration. }
      {*********************************************************}
      Check_context(context_code_ptr, code_ptr);

      if parsing_ok then
        begin
          {******************************************}
          { create and initialize new statement info }
          {******************************************}
          stmt_info_ptr := New_stmt_info;
          stmt_info_ptr^.line_number := Get_line_number;

          {*************************************}
          { create and initialize new statement }
          {*************************************}
          stmt_ptr := New_method_stmt(code_ptr);
          Set_stmt_info(stmt_ptr, stmt_info_ptr);
          last_stmt_ptr := stmt_ptr;

          {*********************************}
          { assign fields of procedure call }
          {*********************************}
          stmt_ptr^.stmt_name_ptr := expr_ptr;
          if code_ptr^.actual_code_ref <> nil then
            stmt_ptr^.stmt_code_ref :=
              forward_code_ref_type(code_ptr^.actual_code_ref)
          else
            stmt_ptr^.stmt_code_ref := forward_code_ref_type(code_ptr);

          {*********************************}
          { create new statement attributes }
          {*********************************}
          stmt_attributes_ptr := New_stmt_attributes(decl_attributes_ptr);
          Set_stmt_attributes(stmt_ptr, stmt_attributes_ptr);

          {*****************************************}
          { parse mandatory and optional parameters }
          {*****************************************}
          code_attributes_ptr :=
            expr_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr;
          Parse_param_values(stmt_ptr, method_data_ptr, context_code_ptr,
            code_attributes_ptr, true);

          {******************************************}
          { parse additional procedure calls in stmt }
          {******************************************}
          if code_ptr^.kind <> constructor_code then
            while (next_token.kind = comma_tok) do
              begin
                Get_next_token;

                {******************************************}
                { create and initialize new statement info }
                {******************************************}
                stmt_info_ptr := New_stmt_info;
                stmt_info_ptr^.stmt_number :=
                  last_stmt_ptr^.stmt_info_ptr^.stmt_number + 1;

                {*************************************}
                { create and initialize new statement }
                {*************************************}
                last_stmt_ptr^.next := New_stmt(stmt_ptr^.kind);
                last_stmt_ptr := last_stmt_ptr^.next;
                Set_stmt_info(last_stmt_ptr, stmt_info_ptr);

                {*********************************}
                { assign fields of procedure call }
                {*********************************}
                last_stmt_ptr^.stmt_name_ptr := stmt_ptr^.stmt_name_ptr;
                last_stmt_ptr^.stmt_code_ref := stmt_ptr^.stmt_code_ref;

                {*********************************}
                { create new statement attributes }
                {*********************************}
                stmt_attributes_ptr := New_stmt_attributes(decl_attributes_ptr);
                Set_stmt_attributes(last_stmt_ptr, stmt_attributes_ptr);

                {*****************************************}
                { parse mandatory and optional parameters }
                {*****************************************}
                method_data_ptr := Clone_expr(method_data_ptr, true);
                if method_data_ptr <> nil then
                  Decrement_expr_dynamic_links(method_data_ptr);
                Parse_param_values(last_stmt_ptr, method_data_ptr,
                  context_code_ptr, code_attributes_ptr, true);
              end;

        end; {if parsing_ok}
    end; {if parsing_ok}
end; {procedure Parse_proc_stmt_tail}


end.

