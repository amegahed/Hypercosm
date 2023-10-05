unit decl_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             decl_parser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse                  }
{       declarations into an abstract syntax tree               }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decls, type_decls;


{********************************}
{ routines to parse declarations }
{********************************}
procedure Parse_decl(var decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type);
procedure Parse_decls(var decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type);

{*************************************}
{ routines to parse declaration lists }
{*************************************}
procedure Parse_decl_list(var decl_ptr, last_decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type;
  var done: boolean);
procedure Parse_decls_list(var decl_ptr, last_decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type);
procedure Parse_more_decls(var decl_ptr, last_decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type);
procedure Parse_null_decl(var decl_ptr, last_decl_ptr: decl_ptr_type);


implementation
uses
  type_attributes, decl_attributes, comments, code_decls, scanner,
    tokens, tokenizer, parser, data_parser, stmt_parser, method_parser,
    type_parser, class_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                          declarations                         }
{***************************************************************}
{       <decl> ::= <include>                                    }
{       <decl> ::= <enum_decl>                                  }
{       <decl> ::= <struct_decl>                                }
{       <decl> ::= <class_decl>                                 }
{       <decl> ::= <simple_decl>                                }
{       <decl> ::= <complex_decl>                               }
{                                                               }
{       <decls> ::= <decl> <more_decls>                         }
{       <decls> ::=                                             }
{       <more_decls> ::= <decls>                                }
{       <more_decls> ::=                                        }
{***************************************************************}


procedure Parse_body_method_decl(var decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type);
var
  decl_kind: code_decl_kind_type;
  method_kind: method_kind_type;
  static, reference: boolean;
begin
  if parsing_ok then
    begin
      {********************************}
      { set default method attributes  }
      {********************************}
      reference := false;
      static := false;

      if class_type_ptr <> nil then
        method_kind := static_method
      else
        method_kind := void_method;

      {**************************}
      { check for native methods }
      {**************************}
      if parsing_native_decls then
        decl_kind := native_decl
      else
        decl_kind := actual_decl;

      {***************************}
      { check for forward methods }
      {***************************}
      if next_token.kind = forward_tok then
        begin
          Get_next_token;
          decl_kind := forward_decl;
        end;

      {*****************************}
      { check for reference methods }
      {*****************************}
      if next_token.kind = reference_tok then
        begin
          Get_next_token;
          reference := true;
        end;

      {************************}
      { check for void methods }
      {************************}
      if next_token.kind = void_tok then
        begin
          if class_type_ptr <> nil then
            begin
              Get_next_token;
              method_kind := void_method;
            end
          else
            begin
              Parse_error;
              writeln('Objective methods are only allowed within classes.');
              writeln('Outside of classes, all methods are implicitly objective.');
              error_reported := true;
            end;
        end;

      {**************************}
      { check for static methods }
      {**************************}
      if next_token.kind = static_tok then
        begin
          Get_next_token;
          static := true;
        end;

      {********************************************}
      { parse forward or actual method declaration }
      {********************************************}
      Parse_method_decl(decl_ptr, decl_kind, method_kind, static, reference,
        nil, class_type_ptr);
    end; {if parsing_ok}
end; {procedure Parse_body_method_decl}


procedure Parse_method_or_data_decl(var decl_ptr, last_decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type);
var
  decl_kind: code_decl_kind_type;
  storage_class: storage_class_type;
  type_attributes_ptr: type_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  static, reference: boolean;
begin
  Parse_storage_class(storage_class);

  if next_token.kind in procedural_predict_set then
    begin
      static := (storage_class = static_storage);
      reference := false;
      Parse_method_decl(decl_ptr, actual_decl, static_method, static, reference,
        nil, class_type_ptr);
      last_decl_ptr := decl_ptr;
    end
  else
    begin
      Parse_data_type(type_attributes_ptr);

      if parsing_ok then
        begin
          if next_token.kind = function_tok then
            begin
              if storage_class = static_storage then
                begin
                  Parse_error;
                  writeln('Functions may not return static variables.');
                  error_reported := true;
                end
              else
                begin
                  static := false;
                  reference := false;

                  {**************************}
                  { check for native methods }
                  {**************************}
                  if parsing_native_decls then
                    decl_kind := native_decl
                  else
                    decl_kind := actual_decl;

                  {**************************}
                  { check for static methods }
                  {**************************}
                  if next_token.kind = static_tok then
                    begin
                      Get_next_token;
                      static := true;
                    end;

                  Parse_method_decl(decl_ptr, decl_kind, static_method, static,
                    reference, type_attributes_ptr, class_type_ptr);
                  last_decl_ptr := decl_ptr;
                end;
            end
          else
            begin
              decl_attributes_ptr := New_decl_attributes(data_decl_attributes,
                type_attributes_ptr, nil);
              Set_decl_storage_class(decl_attributes_ptr, storage_class);
              Parse_var_decl_list(decl_ptr, last_decl_ptr, decl_attributes_ptr);
            end;
        end;
    end;
end; {procedure Parse_method_or_data_decl}


{********************************}
{ routines to parse declarations }
{********************************}


procedure Parse_decl(var decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type);
var
  last_decl_ptr: decl_ptr_type;
  done: boolean;
begin
  Parse_decl_list(decl_ptr, last_decl_ptr, class_type_ptr, done);
end; {procedure Parse_decl}


procedure Parse_decls(var decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type);
var
  last_decl_ptr: decl_ptr_type;
begin
  Parse_decls_list(decl_ptr, last_decl_ptr, class_type_ptr);
end; {procedure Parse_decls}


{*************************************}
{ routines to parse declaration lists }
{*************************************}


procedure Parse_decl_list(var decl_ptr, last_decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type;
  var done: boolean);
var
  token: token_type;
begin
  decl_ptr := nil;
  last_decl_ptr := nil;

  if parsing_ok then
    if next_token.kind in decl_predict_set then
      begin
        {*******************************}
        { check for native declarations }
        {*******************************}
        if next_token.kind = native_tok then
          begin
            Get_next_token;
            parsing_native_decls := true;
          end
        else
          parsing_native_decls := false;

        {*********************************************}
        { parse subprogram (method) declarations only }
        {*********************************************}
        if next_token.kind in procedural_predict_set + [shader_tok,
          reference_tok, forward_tok, void_tok] then
          begin
            Parse_body_method_decl(decl_ptr, class_type_ptr);
            last_decl_ptr := decl_ptr;
          end

            {*****************************}
            { parse data declaration only }
            {*****************************}
        else if next_token.kind in [const_tok, final_tok] then
          begin
            Parse_var_decl_list(decl_ptr, last_decl_ptr, nil);
          end

            {***************************************}
            { parse object declaration (or nothing) }
            {***************************************}
        else if next_token.kind = type_id_tok then
          begin
            token := next_token;
            Get_next_token;

            if next_token.kind <> s_tok then
              begin
                {**************************}
                { found object declaration }
                {**************************}
                Put_token(token);
                Parse_method_or_data_decl(decl_ptr, last_decl_ptr,
                  class_type_ptr);
              end
            else
              begin
                {**************************}
                { found static method call }
                {**************************}
                Put_token(token);
                done := true;
              end;
          end

            {**********************************}
            { parse method or data declaration }
            {**********************************}
        else
          Parse_method_or_data_decl(decl_ptr, last_decl_ptr, class_type_ptr);

        parsing_native_decls := false;
      end
    else
      begin
        Parse_error;
        writeln('Expected a declaration here.');
        error_reported := true;
      end;
end; {procedure Parse_decl_list}


{************************  productions  ************************}
{       <decls> ::= <decl> <more_decls>                         }
{       <decls> ::=                                             }
{       <more_decls> ::= <decls>                                }
{       <more_decls> ::=                                        }
{***************************************************************}

procedure Parse_decls_list(var decl_ptr, last_decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type);
var
  token: token_type;
  done: boolean;
begin
  decl_ptr := nil;
  last_decl_ptr := nil;

  if parsing_ok and (next_token.kind in decl_predict_set) then
    begin
      done := false;

      if next_token.kind in decl_predict_set then
        begin
          {*************************}
          { parse type declarations }
          {*************************}
          if (next_token.kind in simple_type_decl_predict_set) then
            Parse_type_decls(decl_ptr, last_decl_ptr);

          {*************************}
          { parse class declaration }
          {*************************}
          if decl_ptr = nil then
            if next_token.kind in class_decl_predict_set then
              begin
                if not (next_token.kind in [final_tok, static_tok]) then
                  begin
                    Parse_class_decl(decl_ptr);
                    last_decl_ptr := decl_ptr;
                  end
                else
                  begin
                    token := next_token;
                    Get_next_token;
                    if (next_token.kind = class_tok) then
                      begin
                        {*******************************}
                        { parse final class declaration }
                        {*******************************}
                        Put_token(token);
                        Parse_class_decl(decl_ptr);
                        last_decl_ptr := decl_ptr;
                      end
                    else
                      begin
                        {****************************************}
                        { parse final or static data declaration }
                        {****************************************}
                        Put_token(token);
                        Parse_decl_list(decl_ptr, last_decl_ptr, class_type_ptr,
                          done);
                      end;
                  end;
              end;

          {************************}
          { parse data declaration }
          {************************}
          if decl_ptr = nil then
            if (next_token.kind in decl_predict_set) then
              Parse_decl_list(decl_ptr, last_decl_ptr, class_type_ptr, done);

          {*************************}
          { parse more declarations }
          {*************************}
          if parsing_ok and not done then
            if next_token.kind in decl_predict_set then
              Parse_more_decls(decl_ptr, last_decl_ptr, class_type_ptr);
        end {if next_token}
      else
        begin
          {decl_ptr := nil;}
          {last_decl_ptr := nil;}
          {Parse_null_decl(decl_ptr, last_decl_ptr);}
        end;

      if parsing_ok then
        Check_forward_decls(decl_ptr);
    end; {if parsing_ok}
end; {procedure Parse_decls_list}


procedure Parse_more_decls(var decl_ptr, last_decl_ptr: decl_ptr_type;
  class_type_ptr: type_ptr_type);
var
  new_last_decl_ptr: decl_ptr_type;
begin
  if next_token.kind in decl_predict_set then
    begin
      if last_decl_ptr <> nil then
        begin
          Parse_decls_list(last_decl_ptr^.next, new_last_decl_ptr,
            class_type_ptr);
          if new_last_decl_ptr <> nil then
            last_decl_ptr := new_last_decl_ptr;
        end
      else
        Parse_decls_list(decl_ptr, last_decl_ptr, class_type_ptr);
    end;
end; {procedure Parse_more_decls}


procedure Parse_null_decl(var decl_ptr, last_decl_ptr: decl_ptr_type);
var
  comments_ptr: comments_ptr_type;
  decl_info_ptr: decl_info_ptr_type;
begin
  if parsing_ok then
    begin
      comments_ptr := nil;
      Get_prev_token_comments(comments_ptr);

      if comments_ptr <> nil then
        begin
          {************************************}
          { create null decl to store comments }
          {************************************}
          if last_decl_ptr <> nil then
            begin
              last_decl_ptr^.next := New_decl(null_decl);
              last_decl_ptr := last_decl_ptr^.next;
            end
          else
            begin
              decl_ptr := New_decl(null_decl);
              last_decl_ptr := decl_ptr;
            end;

          {***************}
          { save comments }
          {***************}
          decl_info_ptr := New_decl_info;
          decl_info_ptr^.comments_ptr := comments_ptr;
          decl_info_ptr^.line_number := Get_line_number;
          decl_info_ptr^.file_number := current_file_index;
          Set_decl_info(last_decl_ptr, decl_info_ptr);
        end;
    end;
end; {procedure Parse_null_decl}


end.
