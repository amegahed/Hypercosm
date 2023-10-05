unit type_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            type_unparser              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module traverses the syntax tree and writes out    }
{       the original program declarations from it.              }
{       This is useful for debugging and to tell if the         }
{       parsers have produced the correct syntax tree.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, decl_attributes, decls, type_decls;


{***************************************}
{ routines to unparse type declarations }
{***************************************}
procedure Unparse_type_decl(var outfile: text;
  decl_ptr: decl_ptr_type);
procedure Unparse_type_name(var outfile: text;
  type_ptr: type_ptr_type);

{*************************************************}
{ routines to find access levels of class members }
{*************************************************}
function Found_public_member(decl_attributes_ptr: decl_attributes_ptr_type):
  boolean;
function Found_private_member(decl_attributes_ptr: decl_attributes_ptr_type):
  boolean;
function Found_protected_member(decl_attributes_ptr: decl_attributes_ptr_type):
  boolean;

{*************************************************}
{ routines to unparse type declaration components }
{*************************************************}
function Type_decl_kind_to_str(kind: type_decl_kind_type): string_type;


implementation
uses
  symbol_tables, type_attributes, expr_attributes, comments, exprs, unparser,
    term_unparser, expr_unparser, data_unparser, stmt_unparser, decl_unparser;


function Type_decl_kind_to_str(kind: type_decl_kind_type): string_type;
var
  str: string_type;
begin
  case kind of

    enum_type:
      str := 'enum';

    alias_type:
      str := 'type';

    struct_type:
      str := 'struct';

    class_type:
      str := 'subject';

  end; {case}

  Type_decl_kind_to_str := str;
end; {function Type_decl_kind_to_str}


{*************************************************}
{ routines to find access levels of class members }
{*************************************************}


function Found_public_member(decl_attributes_ptr: decl_attributes_ptr_type):
  boolean;
var
  found: boolean;
  name: string_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type;
  id_ptr: id_ptr_type;
begin
  scope_decl_attributes_ptr := decl_attributes_ptr^.scope_decl_attributes_ptr;
  if scope_decl_attributes_ptr <> nil then
    if scope_decl_attributes_ptr^.type_attributes_ptr^.kind = type_class then
      begin
        name := Get_decl_attributes_name(decl_attributes_ptr);
        found :=
          Found_id_by_name(scope_decl_attributes_ptr^.type_attributes_ptr^.public_table_ptr, id_ptr, name);
      end
    else
      found := false
  else
    found := false;

  Found_public_member := found;
end; {function Found_public_member}


function Found_private_member(decl_attributes_ptr: decl_attributes_ptr_type):
  boolean;
var
  found: boolean;
  name: string_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type;
  id_ptr: id_ptr_type;
begin
  scope_decl_attributes_ptr := decl_attributes_ptr^.scope_decl_attributes_ptr;
  if scope_decl_attributes_ptr <> nil then
    if scope_decl_attributes_ptr^.type_attributes_ptr^.kind = type_class then
      begin
        name := Get_decl_attributes_name(decl_attributes_ptr);
        found :=
          Found_id_by_name(scope_decl_attributes_ptr^.type_attributes_ptr^.private_table_ptr, id_ptr, name);
      end
    else
      found := false
  else
    found := false;

  Found_private_member := found;
end; {function Found_private_member}


function Found_protected_member(decl_attributes_ptr: decl_attributes_ptr_type):
  boolean;
var
  found: boolean;
  name: string_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type;
  id_ptr: id_ptr_type;
begin
  scope_decl_attributes_ptr := decl_attributes_ptr^.scope_decl_attributes_ptr;
  if scope_decl_attributes_ptr <> nil then
    if scope_decl_attributes_ptr^.type_attributes_ptr^.kind = type_class then
      begin
        name := Get_decl_attributes_name(decl_attributes_ptr);
        found :=
          Found_id_by_name(scope_decl_attributes_ptr^.type_attributes_ptr^.protected_table_ptr, id_ptr, name);
      end
    else
      found := false
  else
    found := false;

  Found_protected_member := found;
end; {function Found_protected_member}


{******************************************}
{ routine to unparse all type declarations }
{******************************************}


procedure Unparse_type_name(var outfile: text;
  type_ptr: type_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  decl_attributes_ptr := Get_decl_attributes(type_ptr^.type_decl_ref);
  Unparse_str(outfile, Get_decl_attributes_name(decl_attributes_ptr));
end; {procedure Unparse_type_name}


procedure Unparse_type_refs(var outfile: text;
  type_ref_ptr: type_reference_ptr_type);
begin
  while type_ref_ptr <> nil do
    begin
      Unparse_type_name(outfile, type_ref_ptr^.type_ref);
      type_ref_ptr := type_ref_ptr^.next;
      if (type_ref_ptr <> nil) then
        begin
          Unparse_str(outfile, ',');
          Unparse_space(outfile);
        end;
    end;
end; {procedure Unpares_type_refs}


procedure Unparse_enum_type_decl(var outfile: text;
  decl_ptr: decl_ptr_type);
var
  type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type;
  id_ptr: id_ptr_type;
  counter: integer;
begin
  type_ptr := type_ptr_type(decl_ptr^.type_ptr);
  decl_attributes_ptr := Get_decl_attributes(decl_ptr);

  Indent(outfile);
  Unparse_str(outfile, 'enum');
  Unparse_space(outfile);

  Unparse_type_name(outfile, type_ptr);
  Unparse_space(outfile);

  Unparse_str(outfile, 'is');
  Unparse_space(outfile);

  symbol_table_ptr := decl_attributes_ptr^.type_attributes_ptr^.enum_table_ptr;
  for counter := 1 to symbol_table_ptr^.id_number do
    begin
      if Found_id_by_value(symbol_table_ptr, id_ptr, counter) then
        Unparse_str(outfile, Get_id_name(id_ptr));
      if counter < symbol_table_ptr^.id_number then
        begin
          Unparse_str(outfile, ',');
          Unparse_space(outfile);
        end;
    end;

  Unparseln(outfile, ';');
end; {procedure Unparse_enum_type_decl}


procedure Unparse_alias_type_decl(var outfile: text;
  decl_ptr: decl_ptr_type);
var
  type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  type_ptr := type_ptr_type(decl_ptr^.type_ptr);
  decl_attributes_ptr := Get_decl_attributes(decl_ptr);

  Indent(outfile);
  Unparse_str(outfile, 'type');
  Unparse_space(outfile);

  Unparse_type_name(outfile, type_ptr);
  Unparse_space(outfile);

  Unparse_str(outfile, 'is');
  Unparse_space(outfile);
  Unparse_type_attributes(outfile,
    decl_attributes_ptr^.type_attributes_ptr^.alias_type_attributes_ptr);

  Unparseln(outfile, ';');
end; {procedure Unparse_alias_type_decl}


procedure Unparse_struct_type_decl(var outfile: text;
  decl_ptr: decl_ptr_type);
var
  type_ptr: type_ptr_type;
  comment_ptr: comment_ptr_type;
begin
  type_ptr := type_ptr_type(decl_ptr^.type_ptr);

  Indent(outfile);

  if type_ptr^.static then
    begin
      Unparse_str(outfile, 'static');
      Unparse_space(outfile);
    end;

  Unparse_str(outfile, 'struct');
  Unparse_space(outfile);

  Unparse_type_name(outfile, type_ptr);
  Unparse_space(outfile);

  Unparseln(outfile, 'has');
  Unparse_space(outfile);

  Push_margin;
  Unparse_decls(outfile, type_ptr^.field_decls_ptr);
  Pop_margin;

  Indent(outfile);
  Unparse_str(outfile, 'end;');

  {***************************************}
  { unparse comment at end of declaration }
  {***************************************}
  if decl_ptr^.decl_info_ptr <> nil then
    with decl_ptr^.decl_info_ptr^ do
      begin
        comment_ptr := Get_post_comments(comments_ptr);
        if comment_ptr <> nil then
          begin
            Unparse_tab(outfile);
            Unparse_comments(outfile, comment_ptr);
          end
        else
          begin
            Unparse_tab(outfile);
            Unparse_str(outfile, '// ');
            Unparse_type_name(outfile, type_ptr);
            Unparseln(outfile, '');
          end;
      end;
end; {procedure Unparse_struct_type_decl}


procedure Unparse_class_type_decl(var outfile: text;
  decl_ptr: decl_ptr_type);
var
  type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  comment_ptr: comment_ptr_type;
  empty_class: boolean;
begin
  type_ptr := type_ptr_type(decl_ptr^.type_ptr);
  decl_attributes_ptr := Get_decl_attributes(decl_ptr);

  with type_ptr^ do
    begin
      if static then
        begin
          Unparse_str(outfile, 'static');
          Unparse_space(outfile);
        end;

      if not (class_kind in [normal_class, alias_class]) then
        begin
          case class_kind of
            abstract_class:
              Unparse_str(outfile, 'abstract');
            final_class:
              Unparse_str(outfile, 'final');
            interface_class:
              Unparse_str(outfile, 'interface');
          end;
          Unparse_space(outfile);
        end;

      if class_kind <> interface_class then
        begin
          Unparse_str(outfile, 'subject');
          Unparse_space(outfile);
        end;

      Unparse_str(outfile, Get_decl_attributes_name(decl_attributes_ptr));
      if (class_decls_ptr <> nil) or (class_init_ptr <> nil) then
        Unparse_space(outfile)
      else if (member_decls_ptr <> nil) or (private_member_decls_ptr <> nil)
        then
        Unparse_space(outfile);

      {******************************}
      { does class have any contents }
      {******************************}
      empty_class := false;
      if method_decls_ptr = nil then
        if member_decls_ptr = nil then
          if private_member_decls_ptr = nil then
            if class_decls_ptr = nil then
              if class_init_ptr = nil then
                empty_class := true;

      {********************}
      { unparse superclass }
      {********************}
      if parent_class_ref <> nil then
        if parent_class_ref^.parent_class_ref <> nil then
          begin
            if empty_class then
              begin
                Unparse_space(outfile);
                Unparse_str(outfile, 'extends');
                Unparse_space(outfile);
                Unparse_type_name(outfile, parent_class_ref);
              end
            else
              begin
                Unparseln(outfile, '');
                Unparseln(outfile, 'extends');
                Push_margin;
                Indent(outfile);
                Unparse_type_name(outfile, parent_class_ref);
                Pop_margin;
              end;
          end;

      {*********************}
      { unparse class alias }
      {*********************}
      if class_kind = alias_class then
        begin
          decl_attributes_ptr := Get_decl_attributes(decl_ptr);
          if empty_class then
            begin
              Unparse_space(outfile);
              Unparse_str(outfile, 'extends');
              Unparse_space(outfile);
              Unparse_type_attributes(outfile,
                decl_attributes_ptr^.type_attributes_ptr^.class_alias_type_attributes_ptr);
            end
          else
            begin
              Unparseln(outfile, '');
              Unparseln(outfile, 'extends');
              Push_margin;
              Indent(outfile);
              Unparse_type_attributes(outfile,
                decl_attributes_ptr^.type_attributes_ptr^.class_alias_type_attributes_ptr);
              Pop_margin;
            end;
        end;

      {********************}
      { unparse interfaces }
      {********************}
      if interface_class_ptr <> nil then
        begin
          if empty_class then
            begin
              Unparse_space(outfile);
              Unparse_str(outfile, 'implements');
              Unparse_space(outfile);
              Unparse_type_refs(outfile, interface_class_ptr);
            end
          else
            begin
              Unparseln(outfile, '');
              Unparseln(outfile, 'implements');
              Push_margin;
              Indent(outfile);
              Unparse_type_refs(outfile, interface_class_ptr);
              Pop_margin;
            end;
        end;

      {***********************}
      { unparse class methods }
      {***********************}
      if (method_decls_ptr <> nil) then
        begin
          Unparseln(outfile, '');
          Unparseln(outfile, 'does');

          Push_margin;
          Unparse_decls(outfile, method_decls_ptr);
          Pop_margin;

          Indent(outfile);
        end;

      {***********************}
      { unparse class members }
      {***********************}
      if (member_decls_ptr <> nil) or (private_member_decls_ptr <> nil) then
        begin
          Unparseln(outfile, 'has');

          Push_margin;
          Unparse_decls(outfile, member_decls_ptr);
          Pop_margin;

          if (private_member_decls_ptr <> nil) then
            begin
              Unparseln(outfile, 'private');

              Push_margin;
              Unparse_decls(outfile, private_member_decls_ptr);
              Pop_margin;
            end;

          Indent(outfile);
        end;

      {******************************}
      { unparse class implementation }
      {******************************}
      if (class_decls_ptr <> nil) or (class_init_ptr <> nil) then
        begin
          Unparseln(outfile, 'is');

          {*********************}
          { unparse class decls }
          {*********************}
          Push_margin;
          Unparse_decls(outfile, class_decls_ptr);

          {***************************************************}
          { unparse space between class decls and initializer }
          {***************************************************}
          if (class_decls_ptr <> nil) and (class_init_ptr <> nil) then
            Unparseln(outfile, '');

          {***************************}
          { unparse class initializer }
          {***************************}
          Unparse_stmts(outfile, class_init_ptr);
          Pop_margin;

          Indent(outfile);
        end;

      if not empty_class then
        Unparse_str(outfile, 'end');
      Unparse_char(outfile, ';');

      {******************************************}
      { unparse comment at end of implementation }
      {******************************************}
      if decl_ptr^.decl_info_ptr <> nil then
        comment_ptr := Get_post_comments(decl_ptr^.decl_info_ptr^.comments_ptr)
      else
        comment_ptr := nil;

      if comment_ptr <> nil then
        begin
          Unparse_tab(outfile);
          Unparse_comments(outfile, comment_ptr);
        end
      else if not empty_class then
        begin
          Unparse_tab(outfile);
          Unparse_str(outfile, '// ');
          Unparse_type_name(outfile, type_ptr);
          Unparseln(outfile, '');
        end
      else
        Unparseln(outfile, '');
    end;
end; {procedure Unparse_class_type_decl}


procedure Unparse_type_decl(var outfile: text;
  decl_ptr: decl_ptr_type);
var
  type_ptr: type_ptr_type;
begin
  if decl_ptr <> nil then
    begin
      type_ptr := type_ptr_type(decl_ptr^.type_ptr);
      if type_ptr <> nil then
        with type_ptr^ do
          case kind of

            enum_type:
              Unparse_enum_type_decl(outfile, decl_ptr);

            alias_type:
              Unparse_alias_type_decl(outfile, decl_ptr);

            struct_type:
              Unparse_struct_type_decl(outfile, decl_ptr);

            class_type:
              Unparse_class_type_decl(outfile, decl_ptr);

          end; {case}
    end;
end; {procedure Unparse_type_decl}


end.
