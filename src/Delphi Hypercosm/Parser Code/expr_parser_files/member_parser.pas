unit member_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           member_parser               3d       }
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
  strings, type_attributes, decl_attributes, expr_attributes, exprs;


{*****************************************************}
{ routines to search a type's scope for an identifier }
{*****************************************************}
function Found_struct_member_id(id: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type): boolean;
function Found_class_member_id(id: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type): boolean;
function Found_class_method_id(id: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type): boolean;
function Found_member_id(id: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var type_decl_attributes_ptr: decl_attributes_ptr_type): boolean;

{********************************************************}
{ routines to parse an identifier from a struct or class }
{********************************************************}
procedure Parse_struct_member_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
procedure Parse_class_member_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
procedure Parse_class_method_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
procedure Parse_member_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);

{*****************************************************************}
{ routines to parse an implicit identifier from a struct or class }
{*****************************************************************}
procedure Parse_implicit_struct_member_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
procedure Parse_implicit_class_member_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
procedure Parse_implicit_class_method_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
procedure Parse_implicit_member_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);

{******************************}
{ auxilliary scopeing routines }
{******************************}
procedure Push_interface_member_scopes(type_attributes_ptr:
  type_attributes_ptr_type);
procedure Push_interface_method_scopes(type_attributes_ptr:
  type_attributes_ptr_type);


implementation
uses
  stmt_attributes, tokens, tokenizer, parser, scoping, match_terms;


procedure Push_interface_member_scopes(type_attributes_ptr:
  type_attributes_ptr_type);
var
  type_attributes_ref_ptr: type_attributes_ref_ptr_type;
begin
  Push_post_scope(type_attributes_ptr^.public_table_ptr);
  Push_post_scope(type_attributes_ptr^.protected_table_ptr);

  type_attributes_ref_ptr := type_attributes_ptr^.interface_type_attributes_ptr;
  while (type_attributes_ref_ptr <> nil) do
    begin
      Push_interface_member_scopes(type_attributes_ref_ptr^.type_attributes_ptr);
      type_attributes_ref_ptr := type_attributes_ref_ptr^.next;
    end;
end; {procedure Push_interface_member_scopes}


procedure Push_interface_method_scopes(type_attributes_ptr:
  type_attributes_ptr_type);
var
  type_attributes_ref_ptr: type_attributes_ref_ptr_type;
begin
  Push_post_scope(type_attributes_ptr^.public_table_ptr);
  Push_post_scope(type_attributes_ptr^.protected_table_ptr);

  type_attributes_ref_ptr := type_attributes_ptr^.interface_type_attributes_ptr;
  while (type_attributes_ref_ptr <> nil) do
    begin
      Push_interface_method_scopes(type_attributes_ref_ptr^.type_attributes_ptr);
      type_attributes_ref_ptr := type_attributes_ref_ptr^.next;
    end;
end; {procedure Push_interface_method_scopes}


procedure Push_class_method_scopes(type_attributes_ptr:
  type_attributes_ptr_type);
var
  type_attributes_ref_ptr: type_attributes_ref_ptr_type;
begin
  while (type_attributes_ptr <> nil) do
    case type_attributes_ptr^.kind of

      type_class_alias:
        begin
          Push_post_scope(type_attributes_ptr^.public_table_ptr);
          Push_post_scope(type_attributes_ptr^.private_table_ptr);
          Push_post_scope(type_attributes_ptr^.protected_table_ptr);
          if type_attributes_ptr^.class_alias_type_attributes_ptr^.kind in
            class_type_kinds then
            type_attributes_ptr :=
              type_attributes_ptr^.class_alias_type_attributes_ptr
          else
            type_attributes_ptr := nil;
        end;

      type_class:
        begin
          {***********************************************}
          { push method scopes of superclasses interfaces }
          {***********************************************}
          type_attributes_ref_ptr :=
            type_attributes_ptr^.interface_type_attributes_ptr;
          while (type_attributes_ref_ptr <> nil) do
            begin
              Push_interface_method_scopes(type_attributes_ref_ptr^.type_attributes_ptr);
              type_attributes_ref_ptr := type_attributes_ref_ptr^.next;
            end;

          {************************************}
          { push method scopes of superclasses }
          {************************************}
          Push_post_scope(type_attributes_ptr^.public_table_ptr);
          Push_post_scope(type_attributes_ptr^.private_table_ptr);
          Push_post_scope(type_attributes_ptr^.protected_table_ptr);
          type_attributes_ptr :=
            type_attributes_ptr^.parent_type_attributes_ptr;
        end;

    end; {case}
end; {procedure Push_class_method_scopes}


procedure Push_class_member_scopes(type_attributes_ptr:
  type_attributes_ptr_type);
begin
  while (type_attributes_ptr <> nil) do
    begin
      {************************************}
      { push method scopes of superclasses }
      {************************************}
      Push_post_scope(type_attributes_ptr^.public_table_ptr);
      Push_post_scope(type_attributes_ptr^.private_table_ptr);
      Push_post_scope(type_attributes_ptr^.protected_table_ptr);
      type_attributes_ptr := type_attributes_ptr^.parent_type_attributes_ptr;
    end;
end; {procedure Push_class_member_scopes}


{*****************************************************}
{ routines to search a type's scope for an identifier }
{*****************************************************}


function Found_struct_member_id(id: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type): boolean;
var
  type_attributes_ptr: type_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  found: boolean;
begin
  if type_decl_attributes_ptr <> nil then
    begin
      type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
      type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

      if type_attributes_ptr^.kind = type_struct then
        begin
          {**********************}
          { push scope of struct }
          {**********************}
          Push_local_scope(type_decl_attributes_ptr);
          Push_prev_scope(type_attributes_ptr^.field_table_ptr);

          {******************************}
          { search local scope of struct }
          {******************************}
          found := Found_local_id(id, decl_attributes_ptr, stmt_attributes_ptr);
          Pop_local_scope;
        end
      else
        found := false;
    end
  else
    found := false;

  Found_struct_member_id := found;
end; {function Found_struct_member_id}


function Found_class_member_id(id: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type): boolean;
var
  type_attributes_ptr: type_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  found: boolean;
begin
  if type_decl_attributes_ptr <> nil then
    begin
      type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
      type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

      if type_attributes_ptr^.kind in class_type_kinds then
        begin
          {***************************************}
          { push scopes of class and superclasses }
          {***************************************}
          Push_local_scope(type_decl_attributes_ptr);
          Push_class_member_scopes(type_attributes_ptr);

          {******************************}
          { search for id in local scope }
          {******************************}
          found := Found_local_id(id, decl_attributes_ptr, stmt_attributes_ptr);
          Pop_local_scope;
        end
      else
        found := false;
    end
  else
    found := false;

  Found_class_member_id := found;
end; {function Found_class_member_id}


function Found_class_method_id(id: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type): boolean;
var
  type_attributes_ptr: type_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  found: boolean;
begin
  if type_decl_attributes_ptr <> nil then
    begin
      type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
      type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

      if type_attributes_ptr^.kind in class_type_kinds then
        begin
          {***************************************}
          { push scopes of class and superclasses }
          {***************************************}
          Push_local_scope(type_decl_attributes_ptr);
          Push_class_method_scopes(type_attributes_ptr);

          {******************************}
          { search for id in local scope }
          {******************************}
          found := Found_local_id(id, decl_attributes_ptr, stmt_attributes_ptr);
          Pop_local_scope;
        end
      else
        found := false;
    end
  else
    found := false;

  Found_class_method_id := found;
end; {function Found_class_method_id}


function Found_member_id(id: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var type_decl_attributes_ptr: decl_attributes_ptr_type): boolean;
var
  type_attributes_ptr: type_attributes_ptr_type;
  found: boolean;
begin
  if type_decl_attributes_ptr <> nil then
    begin
      type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
      type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

      {**********************}
      { parse field of class }
      {**********************}
      if type_attributes_ptr^.kind in class_type_kinds then
        found := Found_class_member_id(id, decl_attributes_ptr,
          type_decl_attributes_ptr)

        {***********************}
        { parse field of struct }
        {***********************}
      else if type_attributes_ptr^.kind = type_struct then
        found := Found_struct_member_id(id, decl_attributes_ptr,
          type_decl_attributes_ptr)

      else
        found := false;
    end
  else
    found := false;

  Found_member_id := found;
end; {function Found_member_id}


{********************************************************}
{ routines to parse an identifier from a struct or class }
{********************************************************}


procedure Parse_struct_member_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      if next_token.kind = id_tok then
        begin
          type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
          type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

          {*******************}
          { push struct scope }
          {*******************}
          if type_attributes_ptr^.kind = type_struct then
            begin
              Push_local_scope(type_decl_attributes_ptr);
              Push_prev_scope(type_attributes_ptr^.field_table_ptr);
            end;

          {************************}
          { parse struct member id }
          {************************}
          Match_local_id(expr_ptr, expr_attributes_ptr);
          Pop_local_scope;
        end
      else
        begin
          Parse_error;
          writeln('Expected a struct member name here.');
          error_reported := true;
        end;
    end; {if parsing_ok}
end; {procedure Parse_struct_member_id}


procedure Parse_class_member_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      if next_token.kind = id_tok then
        begin
          type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
          type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

          {***************************************}
          { push scopes of class and superclasses }
          {***************************************}
          if type_attributes_ptr^.kind in class_type_kinds then
            begin
              Push_local_scope(type_decl_attributes_ptr);
              Push_class_member_scopes(type_attributes_ptr);
            end;

          {***********************}
          { parse class member id }
          {***********************}
          Match_local_id(expr_ptr, expr_attributes_ptr);
          Pop_local_scope;
        end
      else
        begin
          Parse_error;
          writeln('Expected a class member name here.');
          error_reported := true;
        end;

    end; {if parsing_ok}
end; {procedure Parse_class_member_id}


procedure Parse_class_method_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      if next_token.kind in [id_tok, static_id_tok] then
        begin
          type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
          type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

          {***************************************}
          { push scopes of class and superclasses }
          {***************************************}
          if type_attributes_ptr^.kind in class_type_kinds then
            begin
              Push_local_scope(type_decl_attributes_ptr);
              Push_class_method_scopes(type_attributes_ptr);
            end;

          {***********************}
          { parse class member id }
          {***********************}
          Match_local_id(expr_ptr, expr_attributes_ptr);
          Pop_local_scope;
        end
      else
        begin
          Parse_error;
          writeln('Expected a class member name here.');
          error_reported := true;
        end;

    end; {if parsing_ok}
end; {procedure Parse_class_method_id}


procedure Parse_member_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
      type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

      {**********************}
      { parse field of class }
      {**********************}
      if type_attributes_ptr^.kind in class_type_kinds then
        Parse_class_member_id(expr_ptr, expr_attributes_ptr,
          type_decl_attributes_ptr)

        {***********************}
        { parse field of struct }
        {***********************}
      else if type_attributes_ptr^.kind = type_struct then
        Parse_struct_member_id(expr_ptr, expr_attributes_ptr,
          type_decl_attributes_ptr)

      else
        begin
          Parse_error;
          writeln(Quotate_str(next_token.id), ' is not a struct or a class.');
          error_reported := true;
        end;
    end; {if parsing_ok}
end; {procedure Parse_member_id}


{*****************************************************************}
{ routines to parse an implicit identifier from a struct or class }
{*****************************************************************}


procedure Parse_implicit_struct_member_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
      type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

      {*******************}
      { push struct scope }
      {*******************}
      if type_attributes_ptr^.kind = type_struct then
        begin
          Push_local_scope(type_decl_attributes_ptr);
          Push_prev_scope(type_attributes_ptr^.field_table_ptr);
        end;

      {********************************}
      { make implicit struct member id }
      {********************************}
      Make_implicit_local_id(id, expr_ptr, expr_attributes_ptr);
      Pop_local_scope;
    end; {if parsing_ok}
end; {procedure Parse_implicit_struct_member_id}


procedure Parse_implicit_class_member_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
      type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

      {***************************************}
      { push scopes of class and superclasses }
      {***************************************}
      if type_attributes_ptr^.kind in class_type_kinds then
        begin
          Push_local_scope(type_decl_attributes_ptr);
          Push_class_member_scopes(type_attributes_ptr);
        end;

      {*******************************}
      { make implicit class member id }
      {*******************************}
      Make_implicit_local_id(id, expr_ptr, expr_attributes_ptr);
      Pop_local_scope;
    end; {if parsing_ok}
end; {procedure Parse_implicit_class_member_id}


procedure Parse_implicit_class_method_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
      type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

      {***************************************}
      { push scopes of class and superclasses }
      {***************************************}
      if type_attributes_ptr^.kind in class_type_kinds then
        begin
          Push_local_scope(type_decl_attributes_ptr);
          Push_class_method_scopes(type_attributes_ptr);
        end;

      {*******************************}
      { make implicit class member id }
      {*******************************}
      Make_implicit_local_id(id, expr_ptr, expr_attributes_ptr);
      Pop_local_scope;
    end; {if parsing_ok}
end; {procedure Parse_implicit_class_method_id}


procedure Parse_implicit_member_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
      type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

      {******************************}
      { make implicit field of class }
      {******************************}
      if type_attributes_ptr^.kind in class_type_kinds then
        Parse_implicit_class_member_id(id, expr_ptr, expr_attributes_ptr,
          type_decl_attributes_ptr)

        {*******************************}
        { make implicit field of struct }
        {*******************************}
      else if type_attributes_ptr^.kind = type_struct then
        Parse_implicit_struct_member_id(id, expr_ptr, expr_attributes_ptr,
          type_decl_attributes_ptr)

      else
        begin
          Parse_error;
          writeln(Quotate_str(next_token.id), ' is not a struct or a class.');
          error_reported := true;
        end;
    end; {if parsing_ok}
end; {procedure Parse_implicit_member_id}


end.
