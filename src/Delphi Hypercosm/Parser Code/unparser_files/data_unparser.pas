unit data_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            data_unparser              3d       }
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
  type_attributes, decl_attributes, stmts, decls;


procedure Unparse_storage_class(var outfile: text;
  decl_attributes_ptr: decl_attributes_ptr_type);
procedure Unparse_type_attributes(var outfile: text;
  type_attributes_ptr: type_attributes_ptr_type);
procedure Unparse_data_name(var outfile: text;
  data_decl: data_decl_type;
  decl_attributes_ptr: decl_attributes_ptr_type);


implementation
uses
  exprs, unparser, term_unparser, expr_unparser, msg_unparser, assign_unparser;


procedure Unparse_storage_class(var outfile: text;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  with decl_attributes_ptr^ do
    begin
      if static and final then
        begin
          Unparse_str(outfile, 'constant');
          Unparse_space(outfile);
        end

      else if static then
        begin
          Unparse_str(outfile, 'static');
          Unparse_space(outfile);
        end

      else if final then
        begin
          Unparse_str(outfile, 'final');
          Unparse_space(outfile);
        end;
    end;
end; {procedure Unparse_storage_class}


procedure Unparse_data_dims(var outfile: text;
  type_attributes_ptr: type_attributes_ptr_type);
var
  counter: integer;
begin
  while type_attributes_ptr^.kind = type_array do
    begin
      Unparse_char(outfile, '[');
      for counter := 1 to type_attributes_ptr^.relative_dimensions - 1 do
        begin
          Unparse_char(outfile, ',');
          Unparse_space(outfile);
        end;
      Unparse_char(outfile, ']');
      type_attributes_ptr := type_attributes_ptr^.element_type_attributes_ptr;
    end;
end; {procedure Unparse_data_dims}


procedure Unparse_type_attributes(var outfile: text;
  type_attributes_ptr: type_attributes_ptr_type);
begin
  with type_attributes_ptr^ do
    begin
      {********************}
      { user defined types }
      {********************}
      if (kind in [type_alias, type_struct, type_class, type_class_alias,
        type_enum]) then
        Unparse_str(outfile, Get_type_attributes_name(type_attributes_ptr))

        {*********************}
        { derived array types }
        {*********************}
      else if kind = type_array then
        begin
          Unparse_type_attributes(outfile, element_type_attributes_ptr);
          Unparse_data_dims(outfile, type_attributes_ptr);
        end

          {*************************}
          { derived reference types }
          {*************************}
      else if kind = type_reference then
        begin
          Unparse_type_attributes(outfile, reference_type_attributes_ptr);
          Unparse_str(outfile, ' reference');
        end

          {*****************}
          { primitive types }
          {*****************}
      else
        case type_attributes_ptr^.kind of
          type_boolean:
            Unparse_str(outfile, 'boolean');
          type_char:
            Unparse_str(outfile, 'char');

          type_byte:
            Unparse_str(outfile, 'byte');
          type_short:
            Unparse_str(outfile, 'short');

          type_integer:
            Unparse_str(outfile, 'integer');
          type_long:
            Unparse_str(outfile, 'long');

          type_scalar:
            Unparse_str(outfile, 'scalar');
          type_double:
            Unparse_str(outfile, 'double');

          type_complex:
            Unparse_str(outfile, 'complex');
          type_vector:
            Unparse_str(outfile, 'vector');
        end;
    end;
end; {procedure Unparse_type_attributes}


procedure Unparse_data_name(var outfile: text;
  data_decl: data_decl_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  with data_decl do
    begin
      {****************************}
      { unparse name of identifier }
      {****************************}
      Unparse_expr(outfile, data_expr_ptr);

      {*****************************}
      { show diagnostic information }
      {*****************************}
      Unparse_decl_addr(outfile, decl_attributes_ptr);

      {*****************************************}
      { unparse addr actually used in init stmt }
      {*****************************************}
      if show_init_addrs then
        Unparse_expr_addr(outfile, data_expr_ptr);

      {*************************************************}
      { unparse array dimensions or constructor, if any }
      {*************************************************}
      if init_expr_ptr <> nil then
        begin
          if init_expr_ptr^.kind <> struct_new then
            Unparse_expr(outfile, init_expr_ptr)
          else
            Unparse_initializer(outfile,
              stmt_ptr_type(init_expr_ptr^.new_struct_init_stmt_ptr));
        end;

      {**************************}
      { unparse data initializer }
      {**************************}
      if init_stmt_ptr <> nil then
        Unparse_initializer(outfile, init_stmt_ptr);
    end;
end; {procedure Unparse_data_name}


end.
