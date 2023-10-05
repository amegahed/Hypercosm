unit implicit_derefs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           implicit_derefs             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to create implicit        }
{       struct and class dereferences into an abstract          }
{       syntax tree representation.                             }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decl_attributes, stmt_attributes, expr_attributes, exprs;


{****************************************}
{ reference or dereference an expression }
{****************************************}
procedure Deref_expr(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Reference_expr(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);

{************************************************************}
{ routines to implicitly dereference struct or class members }
{************************************************************}
procedure Make_implicit_struct_deref(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Make_implicit_class_deref(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Make_implicit_field_deref(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Make_implicit_stack_links(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type);
procedure Make_implicit_derefs(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type);


implementation
uses
  errors, type_attributes, type_decls, scoping;


{****************************************}
{ reference or dereference an expression }
{****************************************}


procedure Deref_expr(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
begin
  if expr_attributes_ptr <> nil then
    if expr_attributes_ptr^.type_attributes_ptr <> nil then
      if expr_attributes_ptr^.type_attributes_ptr^.kind = type_reference then
        begin
          new_expr_ptr := New_expr(deref_op);
          new_expr_ptr^.operand_ptr := expr_ptr;
          expr_ptr := new_expr_ptr;

          {****************************************}
          { dereference expression type attributes }
          {****************************************}
          with expr_attributes_ptr^ do
            begin
              alias_type_attributes_ptr :=
                Deref_type_attributes(type_attributes_ptr);
              type_attributes_ptr :=
                Unalias_type_attributes(alias_type_attributes_ptr);
            end;
        end;
end; {procedure Deref_expr}


procedure Reference_expr(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
begin
  if expr_attributes_ptr <> nil then
    if expr_attributes_ptr^.type_attributes_ptr <> nil then
      if expr_attributes_ptr^.type_attributes_ptr^.kind <> type_reference then
        begin
          new_expr_ptr := New_expr(address_op);
          new_expr_ptr^.operand_ptr := expr_ptr;
          expr_ptr := new_expr_ptr;

          {**********************************}
          { add reference to type attributes }
          {**********************************}
          expr_attributes_ptr^.type_attributes_ptr :=
            New_reference_type_attributes(expr_attributes_ptr^.type_attributes_ptr);
        end;
end; {procedure Reference_expr}


{************************************************************}
{ routines to implicitly dereference class or struct members }
{************************************************************}


procedure Make_implicit_struct_deref(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type;
  struct_type_ptr: type_ptr_type;
  new_expr_ptr: expr_ptr_type;
begin
  decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
  type_decl_attributes_ptr := decl_attributes_ptr^.scope_decl_attributes_ptr;
  if type_decl_attributes_ptr^.type_attributes_ptr^.kind = type_struct then
    begin
      {*******************************************}
      { get type declaration from type descriptor }
      {*******************************************}
      struct_type_ptr :=
        Get_type_decl(type_decl_attributes_ptr^.type_attributes_ptr);

      {************************}
      { dereference expression }
      {************************}
      if struct_type_ptr^.static then
        new_expr_ptr := New_expr(field_offset)
      else
        new_expr_ptr := New_expr(field_deref);

      new_expr_ptr^.field_name_ptr := expr_ptr;
      new_expr_ptr^.implicit_field := true;
      new_expr_ptr^.base_expr_ref := struct_type_ptr^.struct_base_ptr;
      expr_ptr := new_expr_ptr;
    end
  else
    Error('can not apply implicit struct dereference');
end; {procedure Make_implicit_struct_deref}


procedure Make_implicit_class_deref(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type;
  class_type_ptr: type_ptr_type;
  new_expr_ptr: expr_ptr_type;
begin
  decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
  type_decl_attributes_ptr := decl_attributes_ptr^.scope_decl_attributes_ptr;
  if type_decl_attributes_ptr^.type_attributes_ptr^.kind = type_class then
    begin
      {*******************************************}
      { get type declaration from type descriptor }
      {*******************************************}
      class_type_ptr :=
        Get_type_decl(type_decl_attributes_ptr^.type_attributes_ptr);

      {************************}
      { dereference expression }
      {************************}
      if class_type_ptr^.static then
        new_expr_ptr := New_expr(field_offset)
      else
        new_expr_ptr := New_expr(field_deref);

      new_expr_ptr^.field_name_ptr := expr_ptr;
      new_expr_ptr^.implicit_field := true;
      new_expr_ptr^.base_expr_ref := class_type_ptr^.class_base_ptr;
      expr_ptr := new_expr_ptr;
    end
  else
    Error('can not apply implicit class dereference');
end; {procedure Make_implicit_class_deref}


procedure Make_implicit_field_deref(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type;
  context_decl_attributes_ptr: decl_attributes_ptr_type;
begin
  decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
  scope_decl_attributes_ptr := decl_attributes_ptr^.scope_decl_attributes_ptr;
  context_decl_attributes_ptr := Get_scope_decl_attributes;

  if decl_attributes_ptr^.kind = field_decl_attributes then
    if context_decl_attributes_ptr = scope_decl_attributes_ptr then
      case scope_decl_attributes_ptr^.type_attributes_ptr^.kind of

        type_struct:
          Make_implicit_struct_deref(expr_ptr, expr_attributes_ptr);

        type_class:
          Make_implicit_class_deref(expr_ptr, expr_attributes_ptr);

      end;
end; {procedure Make_implicit_field_deref}


procedure Make_implicit_stack_links(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type);
var
  context_decl_attributes_ptr: decl_attributes_ptr_type;
  context_stmt_attributes_ptr: stmt_attributes_ptr_type;
  static_level, dynamic_level: integer;
  context_static_level, context_dynamic_level: integer;
  static_links, dynamic_links: integer;
  new_expr_ptr: expr_ptr_type;
begin
  if expr_ptr^.kind <> global_identifier then
    begin
      with expr_attributes_ptr^ do
        begin
          static_level := decl_attributes_ptr^.static_level;
          context_decl_attributes_ptr := Get_scope_decl_attributes;
          context_stmt_attributes_ptr := Get_scope_stmt_attributes;

          {***************************************************}
          { expression is a parameter inside of a method call }
          {***************************************************}
          if stmt_attributes_ptr <> nil then
            begin
              dynamic_level := stmt_attributes_ptr^.dynamic_level;
              context_dynamic_level :=
                context_stmt_attributes_ptr^.dynamic_level;
              context_static_level :=
                stmt_attributes_ptr^.decl_attributes_ptr^.static_level + 1;
              dynamic_links := context_dynamic_level - dynamic_level;
            end

              {*******************************************************}
              { expression is not a parameter inside of a method call }
              {*******************************************************}
          else
            begin
              {************************************************}
              { find static level of scope of enclosing method }
              {************************************************}
              if context_decl_attributes_ptr <> nil then
                begin
                  if context_decl_attributes_ptr^.kind <> type_decl_attributes
                    then
                    context_static_level :=
                      context_decl_attributes_ptr^.static_level + 1
                  else
                    context_static_level :=
                      context_decl_attributes_ptr^.static_level;
                end
              else
                context_static_level := 1;

              {***************************************}
              { expression is inside of a method call }
              {***************************************}
              if context_stmt_attributes_ptr <> nil then
                dynamic_links := context_stmt_attributes_ptr^.dynamic_level

                {***************************************}
                { expression is inside of a declaration }
                {***************************************}
              else
                dynamic_links := 0;
            end;

          static_links := context_static_level - static_level;
        end;

      if (dynamic_links <> 0) or (static_links <> 0) then
        begin
          new_expr_ptr := New_expr(nested_identifier);
          new_expr_ptr^.dynamic_links := dynamic_links;
          new_expr_ptr^.static_links := static_links;
          new_expr_ptr^.nested_id_expr_ptr := expr_ptr;
          expr_ptr := new_expr_ptr;
        end;
    end; {if}
end; {procedure Make_implicit_stack_links}


procedure Make_implicit_derefs(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type);
begin
  if expr_attributes_ptr^.kind <> value_attributes_kind then
    case expr_attributes_ptr^.decl_attributes_ptr^.kind of

      field_decl_attributes:
        Make_implicit_field_deref(expr_ptr, expr_attributes_ptr);

      data_decl_attributes:
        Make_implicit_stack_links(expr_ptr, expr_attributes_ptr,
          stmt_attributes_ptr);

    end; {case}
end; {procedure Make_implicit_derefs}


end.
