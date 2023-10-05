unit field_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            field_parser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse structure        }
{       dereferences into an abstract syntax tree               }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, decl_attributes, expr_attributes, exprs;


{*************************}
{ structure dereferencing }
{*************************}
procedure Parse_struct_field(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);


implementation
uses
  symbol_tables, value_attributes, arrays, type_decls, tokens, tokenizer,
    parser, match_literals, match_terms, subranges, subrange_parser, scoping;


{*************************}
{ structure dereferencing }
{*************************}


procedure Parse_field_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type;
  subrange_dimensions: integer;
begin
  decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
  type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
  subrange_dimensions := expr_attributes_ptr^.dimensions;

  case type_attributes_ptr^.kind of

    type_struct:
      begin
        symbol_table_ptr :=
          expr_attributes_ptr^.type_attributes_ptr^.field_table_ptr;
        Push_local_scope(decl_attributes_ptr);
        Push_prev_scope(symbol_table_ptr);
        Match_local_id(expr_ptr, expr_attributes_ptr);
        Pop_local_scope;
      end;

    type_class:
      begin
        type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
        Push_local_scope(decl_attributes_ptr);
        while (type_attributes_ptr <> nil) do
          begin
            Push_post_scope(type_attributes_ptr^.public_table_ptr);
            Push_post_scope(type_attributes_ptr^.private_table_ptr);
            Push_post_scope(type_attributes_ptr^.protected_table_ptr);
            type_attributes_ptr :=
              type_attributes_ptr^.parent_type_attributes_ptr;
          end;
        Match_id(expr_ptr, expr_attributes_ptr);
        Pop_local_scope;
      end;

  end; {case}

  if parsing_ok then
    with expr_attributes_ptr^ do
      dimensions := dimensions + subrange_dimensions;
end; {procedure Parse_field_id}


procedure Parse_struct_deref(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  base_expr_ptr: expr_ptr_type;
begin
  if parsing_ok then
    if (expr_attributes_ptr^.type_attributes_ptr^.kind in structured_type_kinds)
      then
      begin
        base_expr_ptr := expr_ptr;
        expr_ptr := New_expr(struct_deref);
        expr_ptr^.base_expr_ptr := base_expr_ptr;
        Parse_field_id(expr_ptr^.field_expr_ptr, expr_attributes_ptr);
      end
    else
      begin
        Parse_error;
        writeln('An object or struct is required here.');
        error_reported := true;
      end;
end; {procedure Parse_struct_deref}


procedure Parse_struct_offset(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  base_expr_ptr: expr_ptr_type;
begin
  if parsing_ok then
    if (expr_attributes_ptr^.type_attributes_ptr^.kind in structured_type_kinds)
      then
      begin
        base_expr_ptr := expr_ptr;
        expr_ptr := New_expr(struct_offset);
        expr_ptr^.base_expr_ptr := base_expr_ptr;
        Parse_field_id(expr_ptr^.field_expr_ptr, expr_attributes_ptr);
      end
    else
      begin
        Parse_error;
        writeln('An object or struct is required here.');
        error_reported := true;
      end;
end; {procedure Parse_struct_offset}


{**************************************************}
{ routines to parse struct or static struct fields }
{**************************************************}


procedure Parse_struct_field(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    if expr_attributes_ptr^.type_attributes_ptr^.static then
      Parse_struct_offset(expr_ptr, expr_attributes_ptr)
    else
      Parse_struct_deref(expr_ptr, expr_attributes_ptr);
end; {procedure Parse_struct_field}


end.
