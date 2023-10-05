unit struct_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           struct_parser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse field            }
{       declarations into an abstract syntax tree               }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decl_attributes, decls;


{**************************************}
{ routines to parse field declarations }
{**************************************}
procedure Parse_field_decl(var decl_ptr: decl_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);
procedure Parse_field_decls(var decl_ptr: decl_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);

{*******************************************}
{ routines to parse field declaration lists }
{*******************************************}
procedure Parse_field_decl_list(var decl_ptr, last_decl_ptr: decl_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);
procedure Parse_field_decls_list(var decl_ptr, last_decl_ptr: decl_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);
procedure Parse_more_field_decls(var decl_ptr, last_decl_ptr: decl_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);

{******************************************}
{ routines to parse structure declarations }
{******************************************}
procedure Parse_struct_decl(var decl_ptr: decl_ptr_type;
  static: boolean);


implementation
uses
  strings, symbol_tables, type_attributes, expr_attributes, exprs, stmts,
    code_decls, type_decls, tokens, tokenizer, parser, comment_parser,
    match_literals, match_terms, scope_stacks, scoping, array_parser, data_parser,
    implicit_derefs, struct_assigns, method_parser, decl_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


procedure Parse_field_data_decl_tail(decl_ptr: decl_ptr_type;
  decl_attributes_ptr, struct_decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
  recursive_field: boolean;
begin
  if parsing_ok then
    begin
      type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;
      recursive_field := (type_attributes_ptr =
        struct_decl_attributes_ptr^.type_attributes_ptr);

      if recursive_field then
        begin
          if struct_decl_attributes_ptr^.type_attributes_ptr^.static then
            begin
              Parse_error;
              writeln('A static structure may not contain instances of itself.');
              error_reported := true;
            end
          else if next_token.kind <> is_tok then
            begin
              Parse_error;
              writeln('A structure may not contain (pre-allocated) instances of itself.');
              writeln('This field, howewer, is allowed if allocation is suppressed');
              writeln('by initializing it by reference.');
              error_reported := true;
            end;
        end;

      {**********************************}
      { parse constructor or initializer }
      {**********************************}
      Parse_data_decl_tail(decl_ptr, decl_attributes_ptr, false);
    end; {if parsing_ok}
end; {procedure Parse_field_data_decl_tail}


procedure Parse_field_data_decl(var decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);
var
  expr_ptr, dim_expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_info_ptr: decl_info_ptr_type;
  scope_ptr: scope_ptr_type;
  name: string_type;
begin
  {******************}
  { parse identifier }
  {******************}
  Get_prev_decl_info(decl_info_ptr);
  Match_unique_id(name);

  if parsing_ok then
    begin
      expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);
      Set_scope_decl_attributes(decl_attributes_ptr, scope_ptr);
      Make_implicit_derefs(expr_ptr, expr_attributes_ptr, nil);

      {************************}
      { parse array dimensions }
      {************************}
      Parse_array_decl_dims(dim_expr_ptr, expr_attributes_ptr,
        decl_attributes_ptr, false);

      if parsing_ok then
        begin
          {*****************************}
          { create new data declaration }
          {*****************************}
          decl_ptr := New_data_decl(expr_ptr, expr_attributes_ptr,
            decl_info_ptr);
          decl_ptr^.data_decl.init_expr_ptr := dim_expr_ptr;

          {******************************************}
          { parse implicit and explicit initializers }
          {******************************************}
          Parse_field_data_decl_tail(decl_ptr, decl_attributes_ptr,
            struct_decl_attributes_ptr);

          {***************************}
          { activate data declaration }
          {***************************}
          Enter_scope(scope_ptr, name, decl_attributes_ptr);
        end;
    end; {if parsing_ok}
end; {procedure Parse_field_data_decl}


{************************  productions  ************************}
{       <field_decl> ::= <field_decl_stuff> <more_fields> ;     }
{       <field_decl_stuff> ::= <data_decl> <field_decl_end>     }
{       <more_fields> ::= , <id> <field_decl_end> <more_fields> }
{       <more_fields> ::=                                       }
{                                                               }
{       <field_decl_end> ::=                                    }
{***************************************************************}

procedure Parse_field_data_decls(var decl_ptr: decl_ptr_type;
  var last_decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      Parse_field_data_decl(decl_ptr, decl_attributes_ptr,
        struct_decl_attributes_ptr);

      if parsing_ok then
        begin
          {**************************************}
          { parse additional fields in same decl }
          {**************************************}
          last_decl_ptr := decl_ptr;
          while (next_token.kind = comma_tok) and parsing_ok do
            begin
              Get_next_token;

              {*************************************}
              { save comments at end of declaration }
              {*************************************}
              Get_post_decl_info(last_decl_ptr^.decl_info_ptr);

              decl_attributes_ptr :=
                Copy_base_decl_attributes(decl_attributes_ptr);
              Parse_field_data_decl(last_decl_ptr^.next, decl_attributes_ptr,
                struct_decl_attributes_ptr);

              last_decl_ptr^.next^.decl_info_ptr^.decl_number :=
                last_decl_ptr^.decl_info_ptr^.decl_number + 1;
              last_decl_ptr := last_decl_ptr^.next;
            end; {while}

          Match(semi_colon_tok);

          {*************************************}
          { save comments at end of declaration }
          {*************************************}
          Get_post_decl_info(last_decl_ptr^.decl_info_ptr);

        end; {if parsing_ok}
    end; {if parsing_ok}
end; {procedure Parse_field_data_decls}


{**************************************}
{ routines to parse field declarations }
{**************************************}


procedure Parse_field_decl(var decl_ptr: decl_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);
var
  last_decl_ptr: decl_ptr_type;
begin
  Parse_field_decl_list(decl_ptr, last_decl_ptr, struct_decl_attributes_ptr);
end; {procedure Parse_field_decl}


procedure Parse_field_decls(var decl_ptr: decl_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);
var
  last_decl_ptr: decl_ptr_type;
begin
  Parse_field_decls_list(decl_ptr, last_decl_ptr, struct_decl_attributes_ptr);
end; {procedure Parse_field_decls}


{*******************************************}
{ routines to parse field declaration lists }
{*******************************************}


procedure Parse_field_decl_list(var decl_ptr, last_decl_ptr: decl_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);
var
  static: boolean;
  storage_class: storage_class_type;
  type_attributes_ptr: type_attributes_ptr_type;
  decl_attributes_kind: decl_attributes_kind_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  static := false;

  {**************************}
  { check for static methods }
  {**************************}
  if next_token.kind = static_tok then
    begin
      Get_next_token;
      static := true;
    end;

  {**************************************}
  { method (procedure) declarations only }
  {**************************************}
  if next_token.kind in procedural_predict_set + [shader_tok] then
    begin
      Parse_method_decl(decl_ptr, proto_decl, void_method, static, false, nil,
        nil);
      last_decl_ptr := decl_ptr;
    end

      {****************************************}
      { data or method (function) declarations }
      {****************************************}
  else
    begin
      {*********************************************}
      { parse parameter storage class and base type }
      {*********************************************}
      Parse_data_type(type_attributes_ptr);

      if parsing_ok then
        begin
          if next_token.kind = function_tok then
            begin
              {*****************************}
              { set return value attributes }
              {*****************************}
              Parse_method_decl(decl_ptr, proto_decl, void_method, static,
                false, type_attributes_ptr, nil);
              last_decl_ptr := decl_ptr;
            end
          else
            begin
              {**********************}
              { set field attributes }
              {**********************}
              if static then
                begin
                  decl_attributes_kind := data_decl_attributes;
                  storage_class := static_storage;
                end
              else
                begin
                  decl_attributes_kind := field_decl_attributes;
                  storage_class := local_storage;
                end;

              decl_attributes_ptr := New_decl_attributes(decl_attributes_kind,
                type_attributes_ptr, nil);
              Set_decl_storage_class(decl_attributes_ptr, storage_class);

              Parse_field_data_decls(decl_ptr, last_decl_ptr,
                decl_attributes_ptr, struct_decl_attributes_ptr);
            end;
        end; {if parsing_ok}
    end;
end; {procedure Parse_field_decl_list}


procedure Parse_field_decls_list(var decl_ptr, last_decl_ptr: decl_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);
begin
  decl_ptr := nil;
  last_decl_ptr := nil;

  if parsing_ok then
    if (next_token.kind in decl_predict_set) then
      begin
        {************************}
        { parse data declaration }
        {************************}
        Parse_field_decl_list(decl_ptr, last_decl_ptr,
          struct_decl_attributes_ptr);

        {*************************}
        { parse more declarations }
        {*************************}
        if next_token.kind in decl_predict_set then
          Parse_more_field_decls(decl_ptr, last_decl_ptr,
            struct_decl_attributes_ptr);

        {*******************************************}
        { add trailing comments to end of decl list }
        {*******************************************}
        Parse_null_decl(decl_ptr, last_decl_ptr);
      end;
end; {procedure Parse_field_decls_list}


procedure Parse_more_field_decls(var decl_ptr, last_decl_ptr: decl_ptr_type;
  struct_decl_attributes_ptr: decl_attributes_ptr_type);
var
  new_last_decl_ptr: decl_ptr_type;
begin
  if next_token.kind in decl_predict_set then
    begin
      if last_decl_ptr <> nil then
        begin
          Parse_field_decls_list(last_decl_ptr^.next, new_last_decl_ptr,
            struct_decl_attributes_ptr);
          if new_last_decl_ptr <> nil then
            last_decl_ptr := new_last_decl_ptr;
        end
      else
        Parse_field_decls_list(decl_ptr, last_decl_ptr,
          struct_decl_attributes_ptr);
    end;
end; {procedure Parse_more_field_decls}


{************************  productions  ************************}
{       <struct_decl> ::= struct id is <fields> ;               }
{       <fields> ::= <field> <more_fields>                      }
{       <more_fields> ::= , <fields>                            }
{       <fields> ::= <data_decl>                                }
{***************************************************************}

procedure Parse_struct_decl(var decl_ptr: decl_ptr_type;
  static: boolean);
var
  type_ptr: type_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  decl_info_ptr: decl_info_ptr_type;
begin
  if parsing_ok then
    begin
      Get_prev_decl_info(decl_info_ptr);
      Match(struct_tok);

      {*******************************************}
      { create new type descriptor and attributes }
      {*******************************************}
      type_attributes_ptr := New_type_attributes(type_struct, static);
      type_attributes_ptr^.field_table_ptr := New_symbol_table;
      decl_attributes_ptr := New_decl_attributes(type_decl_attributes,
        type_attributes_ptr, nil);

      {*****************************}
      { create new type declaration }
      {*****************************}
      decl_ptr := New_decl(type_decl);
      type_ptr := New_type(struct_type, decl_ptr);
      type_ptr^.static := static;

      if static then
        type_ptr^.struct_base_ptr := New_expr(static_struct_base)
      else
        type_ptr^.struct_base_ptr := New_expr(struct_base);

      Set_decl_info(decl_ptr, decl_info_ptr);

      {*****************}
      { parse type name }
      {*****************}
      Match_new_type_id(decl_attributes_ptr);

      if parsing_ok then
        begin
          {**********************************}
          { set links to and from attributes }
          {**********************************}
          Set_decl_attributes(decl_ptr, decl_attributes_ptr);
          Match(has_tok);

          {**********************}
          { push structure scope }
          {**********************}
          Push_static_scope(decl_attributes_ptr);
          Push_prev_scope(type_attributes_ptr^.field_table_ptr);
          Parse_field_decls(type_ptr^.field_decls_ptr, decl_attributes_ptr);
          Pop_static_scope;

          Match(end_tok);
          Match(semi_colon_tok);

          {************************************}
          { get comments at end of declaration }
          {************************************}
          Get_post_decl_info(decl_info_ptr);

        end; {if parsing_ok}
    end; {if parsing_ok}
end; {procedure Parse_struct_decl}


end.
