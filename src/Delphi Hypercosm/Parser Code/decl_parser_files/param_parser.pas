unit param_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            param_parser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse parameter        }
{       declarations into an abstract syntax tree               }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, type_attributes, code_attributes, decl_attributes, decls, code_decls;


procedure Make_implicit_param_decl(var decl_ptr: decl_ptr_type;
  var signature_ptr: signature_ptr_type;
  id: string_type;
  type_attributes_ptr: type_attributes_ptr_type;
  reference_method: boolean);
procedure Parse_param_decls(code_ptr: code_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);


implementation
uses
  symbol_tables, code_types, exprs, type_decls, expr_attributes, tokens,
  tokenizer, parser, scope_stacks, scoping, comment_parser, match_literals,
  match_terms, value_parser, array_parser, data_parser, stmt_parser,
  cons_parser, type_parser, implicit_derefs, method_parser, decl_parser;


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


const
  memory_alert = false;
  class_stack_size = 8;



procedure Parse_param_data_decl_tail(var data_decl: data_decl_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  signature_ptr: signature_ptr_type;
  inits_allowed: boolean);
var
  init_required: boolean;
begin
  {****************************}
   { parse optional initializer }
   {****************************}
  if inits_allowed then
    begin
      if signature_ptr^.parameter_ptr = nil then
        begin
          {*************************}
          { first parameter in list }
          {*************************}
          init_required := decl_attributes_ptr^.final;
          signature_ptr^.optional := false;

          if parsing_optional_param_decls then
            if (decl_attributes_ptr^.dimensions = 0) then
              init_required := true;

          if (next_token.kind in initializer_predict_set) or init_required then
            begin
              Parse_initializer(data_decl.init_stmt_ptr, decl_attributes_ptr);
              signature_ptr^.optional := true;
            end;
        end
      else
        begin
          {**************************************************************}
          { if first param in list has initializers, all must have them. }
          { if first param in list has no initializers, all must not.    }
          {**************************************************************}
          if signature_ptr^.optional then
            Parse_initializer(data_decl.init_stmt_ptr, decl_attributes_ptr);
        end;
    end; {if inits_allowed}
end; {procedure Parse_param_data_decl_tail}


procedure Parse_param_data_decl(var decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  signature_ptr: signature_ptr_type;
  inits_allowed: boolean);
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
          Parse_param_data_decl_tail(decl_ptr^.data_decl, decl_attributes_ptr,
            signature_ptr, inits_allowed);

          {***************************}
          { activate data declaration }
          {***************************}
          Enter_scope(scope_ptr, name, decl_attributes_ptr);

          {*****************}
          { store parameter }
          {*****************}
          with signature_ptr^ do
            begin
              if last_parameter_ptr <> nil then
                begin
                  last_parameter_ptr^.next :=
                    New_parameter(decl_attributes_ptr^.id_ptr);
                  last_parameter_ptr := last_parameter_ptr^.next;
                end
              else
                begin
                  parameter_ptr := New_parameter(decl_attributes_ptr^.id_ptr);
                  last_parameter_ptr := parameter_ptr;
                end;
            end; {with}

        end; {if parsing_ok}
    end; {if parsing_ok}
end; {procedure Parse_param_data_decl}


{************************  productions  ************************}
{       <param> ::= data_decl                                   }
{***************************************************************}

procedure Parse_param_data_decls(var decl_ptr: decl_ptr_type;
  var last_decl_ptr: decl_ptr_type;
  var signature_ptr: signature_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  inits_allowed: boolean);
begin
  if parsing_ok then
    begin
      if parsing_ok then
        begin
          {*****************************}
          { store parameter's signature }
          {*****************************}
          signature_ptr := New_signature;

          {***********************************}
          { parse first parameter declaration }
          {***********************************}
          Parse_param_data_decl(decl_ptr, decl_attributes_ptr, signature_ptr,
            inits_allowed);

          if parsing_ok then
            begin
              {******************************************}
               { parse additional parameters in same decl }
               {******************************************}
              last_decl_ptr := decl_ptr;
              while (next_token.kind = comma_tok) and parsing_ok do
                begin
                  {*****************}
                  { store data decl }
                  {*****************}
                  Get_next_token;

                  {*************************************}
                  { save comments at end of declaration }
                  {*************************************}
                  Get_post_decl_info(last_decl_ptr^.decl_info_ptr);

                  decl_attributes_ptr :=
                    Copy_base_decl_attributes(decl_attributes_ptr);
                  Parse_param_data_decl(last_decl_ptr^.next,
                    decl_attributes_ptr, signature_ptr, inits_allowed);

                  if parsing_ok then
                    begin
                      last_decl_ptr^.next^.decl_info_ptr^.decl_number :=
                        last_decl_ptr^.decl_info_ptr^.decl_number + 1;
                      last_decl_ptr := last_decl_ptr^.next;
                    end;
                end; {while}

              Match(semi_colon_tok);

              {*************************************}
              { save comments at end of declaration }
              {*************************************}
              if parsing_ok then
                Get_post_decl_info(last_decl_ptr^.decl_info_ptr);
            end;
        end;
    end;
end; {procedure Parse_param_data_decls}


procedure Parse_param_method_decl(var decl_ptr: decl_ptr_type;
  var signature_ptr: signature_ptr_type;
  return_type_attributes_ptr: type_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      Parse_method_decl(decl_ptr, proto_decl, void_method, false, false,
        return_type_attributes_ptr, nil);

      {*****************************}
      { store parameter's signature }
      {*****************************}
      if parsing_ok then
        begin
          signature_ptr := New_signature;
          decl_attributes_ptr := Get_decl_attributes(decl_ptr);
          signature_ptr^.parameter_ptr :=
            New_parameter(decl_attributes_ptr^.id_ptr);
          signature_ptr^.last_parameter_ptr := signature_ptr^.parameter_ptr;
          signature_ptr^.optional := (decl_ptr^.code_data_decl.init_stmt_ptr <>
            nil);
        end;
    end
end; {procedure Parse_param_method_decl}


procedure Parse_param_method_or_data_decls(var decl_ptr, last_decl_ptr:
  decl_ptr_type;
  var signature_ptr: signature_ptr_type;
  inits_allowed: boolean);
var
  storage_class: storage_class_type;
  type_attributes_ptr: type_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  {**************************************}
  { method (procedure) declarations only }
  {**************************************}
  if next_token.kind in procedural_predict_set + [shader_tok] then
    begin
      Parse_param_method_decl(decl_ptr, signature_ptr, nil);
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
      Parse_storage_class(storage_class);
      Parse_data_type(type_attributes_ptr);

      if parsing_ok then
        begin
          {*****************************}
          { create parameter attributes }
          {*****************************}
          if next_token.kind = function_tok then
            begin
              Parse_param_method_decl(decl_ptr, signature_ptr,
                type_attributes_ptr);
              last_decl_ptr := decl_ptr;
            end
          else
            begin
              decl_attributes_ptr := New_decl_attributes(data_decl_attributes,
                type_attributes_ptr, nil);
              Set_decl_storage_class(decl_attributes_ptr, storage_class);
              Parse_param_data_decls(decl_ptr, last_decl_ptr, signature_ptr,
                decl_attributes_ptr, inits_allowed);
            end;
        end; {if parsing_ok}
    end;
end; {procedure Parse_param_method_or_data_decls}


procedure Make_implicit_param_decl(var decl_ptr: decl_ptr_type;
  var signature_ptr: signature_ptr_type;
  id: string_type;
  type_attributes_ptr: type_attributes_ptr_type;
  reference_method: boolean);
var
  new_decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      if reference_method then
        type_attributes_ptr :=
          New_reference_type_attributes(type_attributes_ptr);

      decl_attributes_ptr := New_decl_attributes(data_decl_attributes,
        type_attributes_ptr, nil);
      new_decl_ptr := New_implicit_data_decl(id, decl_attributes_ptr);

      {**************************}
      { add to head of decl list }
      {**************************}
      new_decl_ptr^.next := decl_ptr;
      decl_ptr := new_decl_ptr;

      {*****************}
      { store data decl }
      {*****************}
      if parsing_ok then
        begin
          {*****************************}
          { store parameter's signature }
          {*****************************}
          signature_ptr := New_signature;
          signature_ptr^.parameter_ptr :=
            New_parameter(decl_attributes_ptr^.id_ptr);
        end;
    end; {if parsing_ok}
end; {procedure Make_implicit_param_decl}


{************************  productions  ************************}
{       <param> ::= id                                          }
{***************************************************************}

procedure Parse_keyword_decls(var decl_ptr: decl_ptr_type;
  var last_decl_ptr: decl_ptr_type;
  var signature_ptr: signature_ptr_type;
  var keyword_table_ptr: symbol_table_ptr_type);
var
  keyword: string_type;
  keyword_ptr, last_keyword_ptr, new_keyword_ptr: keyword_ptr_type;
  id_ptr: id_ptr_type;
  index: integer;
  done: boolean;
begin
  if parsing_ok then
    begin
      done := false;

      {******************************************************}
      { check if next identifier is a type name or delimeter }
      {******************************************************}
      if next_token.kind in param_delimeter_set then
        done := true
      else if next_token.kind in storage_class_predict_set then
        done := true
      else if next_token.kind in data_predict_set then
        done := true
      else if next_token.kind in subprogram_predict_set then
        done := true
      else if not (next_token.kind in reserved_word_set + [id_tok]) then
        done := true;

      if not done then
        begin
          keyword := Token_to_id(next_token);

          if not Found_id_by_name(keyword_table_ptr, id_ptr, keyword) then
            begin
              {***************}
              { store keyword }
              {***************}
              index := Symbol_table_size(keyword_table_ptr) + 1;
              id_ptr := Enter_id(keyword_table_ptr, keyword, index);

              {************************}
              { parse list of keywords }
              {************************}
              keyword_ptr := nil;
              last_keyword_ptr := nil;
              done := false;
              while not done do
                begin
                  {********************************}
                  { insert keyword at tail of list }
                  {********************************}
                  new_keyword_ptr := New_keyword(keyword);
                  if (last_keyword_ptr <> nil) then
                    begin
                      last_keyword_ptr^.next := new_keyword_ptr;
                      last_keyword_ptr := new_keyword_ptr;
                    end
                  else
                    begin
                      keyword_ptr := new_keyword_ptr;
                      last_keyword_ptr := new_keyword_ptr;
                    end;

                  Get_next_token;

                  {******************************************************}
                  { check if next identifier is a type name or delimeter }
                  {******************************************************}
                  if next_token.kind in param_delimeter_set then
                    done := true
                  else if next_token.kind in storage_class_predict_set then
                    done := true
                  else if next_token.kind in data_predict_set then
                    done := true
                  else if next_token.kind in subprogram_predict_set then
                    done := true
                  else if not (next_token.kind in reserved_word_set + [id_tok])
                    then
                    done := true;

                  if not done then
                    keyword := Token_to_id(next_token);
                end;

              {********************}
              { done with keywords }
              {********************}
              if (next_token.kind in subprogram_predict_set + data_predict_set +
                storage_class_predict_set) then
                Parse_param_method_or_data_decls(decl_ptr, last_decl_ptr,
                  signature_ptr, true)
              else
                begin
                  Parse_error;
                  writeln('A keyword must be followed by a parameter declaration.');
                  error_reported := true;
                end;

              {*********************************}
              { add keywords to first parameter }
              {*********************************}
              if parsing_ok then
                signature_ptr^.keyword_ptr := keyword_ptr;
            end
          else
            begin
              Parse_error;
              writeln('This is a duplicate keyword.');
              error_reported := true;
            end;
        end;
    end; {if parsing_ok}
end; {procedure Parse_keyword_decls}


{************************  productions  ************************}
{       <params> ::= <param> <more_params>                      }
{       <params> ::=                                            }
{       <more_params> ::= <params>                              }
{       <more_params> ::=                                       }
{       <param> ::= data_decl                                   }
{       <param> ::= id                                          }
{***************************************************************}

procedure Parse_formatted_param_decls(var decl_ptr, last_decl_ptr:
  decl_ptr_type;
  var signature_ptr: signature_ptr_type;
  public_table_ptr: symbol_table_ptr_type;
  keyword_table_ptr: symbol_table_ptr_type);
var
  type_decl_ptr, last_type_decl_ptr: decl_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in reserved_word_set + [id_tok, type_id_tok] then
      if not (next_token.kind in param_delimeter_set) then
        begin
          type_decl_ptr := nil;
          last_type_decl_ptr := nil;

          {**************************************************}
          { parse any type declarations mixed in with params }
          {**************************************************}
          if next_token.kind in type_decl_predict_set then
            begin
              Push_prev_scope(public_table_ptr);
              Parse_type_decls(type_decl_ptr, last_type_decl_ptr);
              Pop_prev_scope;
            end;

          {************************}
          { parse param or keyword }
          {************************}
          if (next_token.kind in subprogram_predict_set + data_predict_set +
            storage_class_predict_set) then
            Parse_param_method_or_data_decls(decl_ptr, last_decl_ptr,
              signature_ptr, false)
          else
            Parse_keyword_decls(decl_ptr, last_decl_ptr, signature_ptr,
              keyword_table_ptr);

          {********************************}
          { add type decls to head of list }
          {********************************}
          if (type_decl_ptr <> nil) then
            begin
              last_type_decl_ptr^.next := decl_ptr;
              decl_ptr := type_decl_ptr;
            end;

          {**********************************}
          { parse more formatted param decls }
          {**********************************}
          if parsing_ok then
            Parse_formatted_param_decls(last_decl_ptr^.next, last_decl_ptr,
              signature_ptr^.next, public_table_ptr, keyword_table_ptr);
        end
      else
        begin
          decl_ptr := nil;
          signature_ptr := nil;
        end;
end; {procedure Parse_formatted_param_decls}


{***************************************************************}
{                 method parameter declarations                 }
{***************************************************************}
{       <proc_params> ::= <params> <opt_params> <return_params> }
{                                                               }
{       <opt_params> ::= with <decls> <stmts>                   }
{       <opt_params> ::=                                        }
{                                                               }
{       <return_params> ::= return <decls>                      }
{       <return_params> ::=                                     }
{***************************************************************}

procedure Parse_param_decls(code_ptr: code_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  last_decl_ptr, last_return_decl_ptr: decl_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
  temp1, temp2, temp3: boolean;
begin
  if parsing_ok then
    begin
      last_decl_ptr := nil;
      last_return_decl_ptr := nil;

      {********************}
      { save parsing state }
      {********************}
      temp1 := parsing_param_decls;
      temp2 := parsing_optional_param_decls;
      temp3 := parsing_return_decls;

      {*******************}
      { set parsing state }
      {*******************}
      parsing_param_decls := true;
      parsing_optional_param_decls := false;
      parsing_return_decls := false;

      {*********************}
      { get code attributes }
      {*********************}
      type_attributes_ptr :=
        Deref_type_attributes(decl_attributes_ptr^.type_attributes_ptr);
      code_attributes_ptr := type_attributes_ptr^.code_attributes_ptr;

      {****************************}
      { parse formatted parameters }
      {****************************}
      with code_attributes_ptr^ do
        begin
          Push_prev_scope(public_param_table_ptr);
          Push_prev_scope(private_param_table_ptr);
          Parse_formatted_param_decls(code_ptr^.initial_param_decls_ptr,
            last_decl_ptr, signature_ptr, public_param_table_ptr,
            keyword_table_ptr);
        end;

      {******************************}
      { parse unformatted parameters }
      {******************************}
      if (next_token.kind = with_tok) then
        begin
          Get_next_token;
          parsing_optional_param_decls := true;
          Push_prev_scope(code_attributes_ptr^.protected_param_table_ptr);
          Parse_decls(code_ptr^.optional_param_decls_ptr, nil);
          parsing_optional_param_decls := false;
          Parse_stmts(code_ptr^.optional_param_stmts_ptr);
        end;

      {*************************}
      { parse return parameters }
      {*************************}
      if (next_token.kind = return_tok) then
        begin
          Get_next_token;

          {***********************************}
          { parse formatted return parameters }
          {***********************************}
          if (next_token.kind <> with_tok) then
            with code_attributes_ptr^ do
              begin
                Push_prev_scope(public_return_table_ptr);
                Push_prev_scope(private_return_table_ptr);
                Parse_formatted_param_decls(code_ptr^.return_param_decls_ptr,
                  last_return_decl_ptr, return_signature_ptr,
                  public_return_table_ptr, keyword_return_table_ptr);
              end;

          {*************************************}
          { parse unformatted return parameters }
          {*************************************}
          if (next_token.kind = with_tok) then
            begin
              Get_next_token;
              parsing_return_decls := true;
              Push_prev_scope(code_attributes_ptr^.protected_return_table_ptr);
              Parse_more_decls(code_ptr^.return_param_decls_ptr,
                last_return_decl_ptr, nil);
              parsing_return_decls := false;
            end;
        end;

      {***********************}
      { restore parsing state }
      {***********************}
      parsing_param_decls := temp1;
      parsing_optional_param_decls := temp2;
      parsing_return_decls := temp3;
    end;
end; {procedure Parse_param_decls}


end.

