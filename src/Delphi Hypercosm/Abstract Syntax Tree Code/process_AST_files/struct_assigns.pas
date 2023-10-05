unit struct_assigns;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           struct_assigns              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The assignments module contains routines to create      }
{       structure assignment statements in abstract syntax      }
{       tree representation.                                    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  exprs, stmts, type_decls;


{*********************************************}
{ routines for creating structure assignments }
{*********************************************}
function New_struct_base_assign(struct_type_ptr: type_ptr_type): stmt_ptr_type;
function New_struct_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type):
  stmt_ptr_type;


implementation
uses
  type_attributes, decl_attributes, expr_attributes, decls, make_exprs,
  type_assigns;


{*****************************************}
{ routines for creating field assignments }
{*****************************************}


function New_field_expr(field_name_ptr: expr_ptr_type;
  struct_base_ptr: expr_ptr_type): expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
begin
  expr_ptr := New_expr(field_deref);
  expr_ptr^.base_expr_ref := struct_base_ptr;
  expr_ptr^.field_name_ptr := Clone_expr(field_name_ptr, true);

  New_field_expr := expr_ptr;
end; {function New_field_expr}


function New_static_field_expr(field_name_ptr: expr_ptr_type;
  struct_base_ptr: expr_ptr_type): expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
begin
  expr_ptr := New_expr(field_offset);
  expr_ptr^.base_expr_ref := struct_base_ptr;
  expr_ptr^.field_name_ptr := Clone_expr(field_name_ptr, true);

  New_static_field_expr := expr_ptr;
end; {function New_static_field_expr}


function New_field_assign(decl_ptr: decl_ptr_type;
  lhs_struct_base_ptr, rhs_struct_base_ptr: expr_ptr_type;
  static: boolean): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
  expr_ptr: expr_ptr_type;
  lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
begin
  stmt_ptr := nil;

  if not (decl_ptr^.kind in [type_decl, null_decl]) then
    begin
      {***********************************}
      { create left and right expressions }
      {***********************************}
      case decl_ptr^.kind of
        boolean_decl..reference_decl:
          expr_ptr := decl_ptr^.data_decl.data_expr_ptr^.field_name_ptr;
        code_decl..code_reference_decl:
          expr_ptr := decl_ptr^.code_data_decl.data_expr_ptr^.field_name_ptr;
      else
        expr_ptr := nil;
      end; {case}

      {***********************************************}
      { create implicit field dereferences or offsets }
      {***********************************************}
      if static then
        begin
          lhs_data_ptr := New_static_field_expr(expr_ptr, lhs_struct_base_ptr);
          rhs_expr_ptr := New_static_field_expr(expr_ptr, rhs_struct_base_ptr);
        end
      else
        begin
          lhs_data_ptr := New_field_expr(expr_ptr, lhs_struct_base_ptr);
          rhs_expr_ptr := New_field_expr(expr_ptr, rhs_struct_base_ptr);
        end;

      {*****************************}
      { create assignment statement }
      {*****************************}
      case decl_ptr^.kind of

        {***********************************}
        { primitive enumerated declarations }
        {***********************************}
        boolean_decl:
          stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr, type_boolean);
        char_decl:
          stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr, type_char);

        {*********************************}
        { primitive integral declarations }
        {*********************************}
        byte_decl:
          stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr, type_byte);
        short_decl:
          stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr, type_short);
        integer_decl:
          stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr, type_integer);
        long_decl:
          stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr, type_long);

        {*******************************}
        { primitive scalar declarations }
        {*******************************}
        scalar_decl:
          stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr, type_scalar);
        double_decl:
          stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr, type_double);
        complex_decl:
          stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr, type_complex);
        vector_decl:
          stmt_ptr := New_prim_assign(lhs_data_ptr, rhs_expr_ptr, type_vector);

        {*******************************************}
        { array, struct, and reference declarations }
        {*******************************************}
        array_decl, code_array_decl:
          stmt_ptr := New_array_ptr_assign(lhs_data_ptr, rhs_expr_ptr);
        struct_decl:
          stmt_ptr := New_struct_ptr_assign(lhs_data_ptr, rhs_expr_ptr);
        static_struct_decl:
          stmt_ptr := New_struct_assign(lhs_data_ptr, rhs_expr_ptr);
        reference_decl, code_reference_decl:
          stmt_ptr := New_reference_assign(lhs_data_ptr, rhs_expr_ptr);

        {**************************************}
        { user defined subprogram declarations }
        {**************************************}
        code_decl:
          stmt_ptr := New_proto_assign(lhs_data_ptr, rhs_expr_ptr, 1);

      end; {case}
    end
  else
    stmt_ptr := nil;

  New_field_assign := stmt_ptr;
end; {function New_field_assign}


procedure Create_field_assigns(stmt_ptr: stmt_ptr_type;
  var last_stmt_ptr: stmt_ptr_type;
  decl_ptr: decl_ptr_type;
  static: boolean);
var
  new_stmt_ptr: stmt_ptr_type;
  lhs_struct_base_ptr, rhs_struct_base_ptr: expr_ptr_type;
begin
  {****************************}
  { get bases of struct assign }
  {****************************}
  lhs_struct_base_ptr := stmt_ptr^.lhs_struct_base_ptr;
  rhs_struct_base_ptr := stmt_ptr^.rhs_struct_base_ptr;

  {*************************************}
  { create field assignments for struct }
  {*************************************}
  while (decl_ptr <> nil) do
    begin
      new_stmt_ptr := New_field_assign(decl_ptr, lhs_struct_base_ptr,
        rhs_struct_base_ptr, static);

      {************************}
      { add assignment to list }
      {************************}
      if (new_stmt_ptr <> nil) then
        begin
          if (last_stmt_ptr <> nil) then
            begin
              last_stmt_ptr^.next := new_stmt_ptr;
              last_stmt_ptr := new_stmt_ptr;
            end
          else
            begin
              stmt_ptr^.field_assign_stmts_ptr := new_stmt_ptr;
              last_stmt_ptr := new_stmt_ptr;
            end;
        end;

      decl_ptr := decl_ptr^.next;
    end;
end; {procedure Create_field_assigns}


procedure Make_struct_assign_bases(stmt_ptr: stmt_ptr_type;
  struct_type_ptr: type_ptr_type);
begin
  if struct_type_ptr^.static then
    begin
      stmt_ptr^.lhs_struct_base_ptr := New_expr(static_struct_base);
      stmt_ptr^.rhs_struct_base_ptr := New_expr(static_struct_base);
    end
  else
    begin
      stmt_ptr^.lhs_struct_base_ptr := New_expr(struct_base);
      stmt_ptr^.rhs_struct_base_ptr := New_expr(struct_base);
    end;
end; {procedure Make_struct_assign_bases}


function Get_parent_class_copier(class_type_ptr: type_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  {***************}
  { derived class }
  {***************}
  if class_type_ptr^.parent_class_ref <> nil then
    stmt_ptr := Get_type_copier(class_type_ptr^.parent_class_ref)

    {************}
    { base class }
    {************}
  else
    stmt_ptr := nil;

  Get_parent_class_copier := stmt_ptr;
end; {function Get_parent_class_copier}


{*********************************************}
{ routines for creating structure assignments }
{*********************************************}


function New_struct_base_assign(struct_type_ptr: type_ptr_type): stmt_ptr_type;
var
  stmt_ptr, last_stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := nil;
  last_stmt_ptr := nil;

  case struct_type_ptr^.kind of

    struct_type:
      begin
        stmt_ptr := New_stmt(struct_base_assign);
        Make_struct_assign_bases(stmt_ptr, struct_type_ptr);
        Create_field_assigns(stmt_ptr, last_stmt_ptr,
          struct_type_ptr^.field_decls_ptr, struct_type_ptr^.static);
      end;

    class_type:
      begin
        if struct_type_ptr^.copyable then
          begin
            stmt_ptr := New_stmt(struct_base_assign);
            Make_struct_assign_bases(stmt_ptr, struct_type_ptr);
            stmt_ptr^.parent_base_assign_ref :=
              Get_parent_class_copier(struct_type_ptr);
            Create_field_assigns(stmt_ptr, last_stmt_ptr,
              struct_type_ptr^.member_decls_ptr, struct_type_ptr^.static);
            Create_field_assigns(stmt_ptr, last_stmt_ptr,
              struct_type_ptr^.private_member_decls_ptr,
                struct_type_ptr^.static);
          end
        else
          stmt_ptr := nil;
      end;

  end; {case}

  New_struct_base_assign := stmt_ptr;
end; {function New_struct_base_assign}


function New_struct_assign(lhs_data_ptr: expr_ptr_type;
  rhs_expr_ptr: expr_ptr_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
  struct_type_ptr: type_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  copyable: boolean;
begin
  {*******************************************}
  { get type declaration from type descriptor }
  {*******************************************}
  expr_attributes_ptr := Get_expr_attributes(lhs_data_ptr);
  struct_type_ptr := Get_type_decl(expr_attributes_ptr^.type_attributes_ptr);

  case struct_type_ptr^.kind of
    struct_type:
      copyable := true;
    class_type:
      copyable := struct_type_ptr^.copyable;
  else
    copyable := false;
  end; {case}

  if copyable then
    begin
      {******************************}
      { initialize struct assignment }
      {******************************}
      stmt_ptr := New_stmt(struct_assign);
      stmt_ptr^.lhs_struct_expr_ptr := lhs_data_ptr;
      stmt_ptr^.rhs_struct_expr_ptr := rhs_expr_ptr;
      stmt_ptr^.assign_struct_type_ref :=
        forward_type_ref_type(struct_type_ptr);
    end
  else
    stmt_ptr := nil;

  New_struct_assign := stmt_ptr;
end; {function New_struct_assign}


end.
