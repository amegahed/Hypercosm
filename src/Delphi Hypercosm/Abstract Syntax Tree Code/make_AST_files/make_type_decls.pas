unit make_type_decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           make_type_decls             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module defines recursive operations which          }
{       are performed on type declaration syntax trees.         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_decls;


{*********************************************************}
{ routines for recursively copying type declaration trees }
{*********************************************************}
function Clone_type(type_ptr: type_ptr_type;
  copy_attributes: boolean): type_ptr_type;
function Clone_types(type_ptr: type_ptr_type;
  copy_attributes: boolean): type_ptr_type;

{*********************************************************}
{ routines for recursively freeing type declaration trees }
{*********************************************************}
procedure Destroy_type(var type_ptr: type_ptr_type;
  free_attributes: boolean);
procedure Destroy_types(var type_ptr: type_ptr_type;
  free_attributes: boolean);

{*********************************************************}
{ routines for recursively marking type declaration trees }
{*********************************************************}
procedure Mark_type(type_ptr: type_ptr_type;
  touched: boolean);
procedure Mark_types(type_ptr: type_ptr_type;
  touched: boolean);
procedure Mark_type_decl(type_ptr: type_ptr_type;
  touched: boolean);
procedure Mark_type_decls(type_ptr: type_ptr_type;
  touched: boolean);
procedure Mark_type_ref(type_ref_ptr: type_reference_ptr_type;
  touched: boolean);
procedure Mark_type_refs(type_ref_ptr: type_reference_ptr_type;
  touched: boolean);

{***********************************************************}
{ routines for recursively comparing type declaration trees }
{***********************************************************}
function Equal_types(type_ptr1, type_ptr2: type_ptr_type): boolean;
function Same_types(type_ptr1, type_ptr2: type_ptr_type): boolean;


implementation
uses
  decls, make_exprs, make_stmts, make_decls;


{*********************************************************}
{ routines for recursively copying type declaration trees }
{*********************************************************}


function Clone_type(type_ptr: type_ptr_type;
  copy_attributes: boolean): type_ptr_type;
var
  new_type_ptr: type_ptr_type;
begin
  if (type_ptr <> nil) then
    begin
      new_type_ptr := Copy_type(type_ptr);

      with new_type_ptr^ do
        case kind of

          enum_type, alias_type:
            ;

          {************************}
          { structure declarations }
          {************************}
          struct_type:
            begin
              {********************************}
              { copy struct field declarations }
              {********************************}
              struct_base_ptr := Clone_expr(struct_base_ptr, copy_attributes);
              field_decls_ptr := Clone_decls(field_decls_ptr, copy_attributes);
              struct_base_assign_stmt_ptr :=
                Clone_stmts(struct_base_assign_stmt_ptr, copy_attributes);
            end;

          {********************}
          { class declarations }
          {********************}
          class_type:
            begin
              {******************************************}
              { copy class method interface declarations }
              {******************************************}
              method_decls_ptr := Clone_decls(method_decls_ptr,
                copy_attributes);

              {********************************}
              { copy class member declarations }
              {********************************}
              class_base_ptr := Clone_expr(class_base_ptr, copy_attributes);
              member_decls_ptr := Clone_decls(member_decls_ptr,
                copy_attributes);
              private_member_decls_ptr := Clone_decls(private_member_decls_ptr,
                copy_attributes);
              class_base_assign_stmt_ptr :=
                Clone_stmts(class_base_assign_stmt_ptr, copy_attributes);

              {****************************************}
              { copy class implementation declarations }
              {****************************************}
              class_decls_ptr := Clone_decls(class_decls_ptr, copy_attributes);
              class_init_ptr := Clone_stmts(class_init_ptr, copy_attributes);
            end;

        end; {case}
    end
  else
    new_type_ptr := nil;

  Clone_type := new_type_ptr;
end; {function Clone_type}


function Clone_types(type_ptr: type_ptr_type;
  copy_attributes: boolean): type_ptr_type;
var
  new_type_ptr: type_ptr_type;
  first_type_ptr, last_type_ptr: type_ptr_type;
begin
  first_type_ptr := nil;
  last_type_ptr := nil;

  while type_ptr <> nil do
    begin
      new_type_ptr := Clone_type(type_ptr, copy_attributes);

      {**********************************}
      { add new type node to end of list }
      {**********************************}
      if (last_type_ptr <> nil) then
        begin
          last_type_ptr^.next := new_type_ptr;
          last_type_ptr := new_type_ptr;
        end
      else
        begin
          first_type_ptr := new_type_ptr;
          last_type_ptr := new_type_ptr;
        end;

      type_ptr := type_ptr^.next;
    end;

  Clone_types := first_type_ptr;
end; {function Clone_types}


{*********************************************************}
{ routines for recursively freeing type declaration trees }
{*********************************************************}


procedure Destroy_type(var type_ptr: type_ptr_type;
  free_attributes: boolean);
begin
  if (type_ptr <> nil) then
    begin
      with type_ptr^ do
        case kind of

          enum_type, alias_type:
            ;

          {************************}
          { structure declarations }
          {************************}
          struct_type:
            begin
              {********************************}
              { free struct field declarations }
              {********************************}
              Destroy_expr(struct_base_ptr, free_attributes);
              Destroy_decls(field_decls_ptr, free_attributes);
              Destroy_stmts(struct_base_assign_stmt_ptr, free_attributes);
            end;

          {********************}
          { class declarations }
          {********************}
          class_type:
            begin
              {******************************************}
              { free class method interface declarations }
              {******************************************}
              Destroy_decls(method_decls_ptr, free_attributes);

              {********************************}
              { free class member declarations }
              {********************************}
              Destroy_expr(class_base_ptr, free_attributes);
              Destroy_decls(member_decls_ptr, free_attributes);
              Destroy_decls(private_member_decls_ptr, free_attributes);
              Destroy_stmts(class_base_assign_stmt_ptr, free_attributes);

              {****************************************}
              { free class implementation declarations }
              {****************************************}
              Destroy_decls(class_decls_ptr, free_attributes);
              Destroy_stmts(class_init_ptr, free_attributes);
            end;
        end; {case}

      {***********************}
      { add type to free list }
      {***********************}
      Free_type(type_ptr);
    end;
end; {procedure Destroy_type}


procedure Destroy_types(var type_ptr: type_ptr_type;
  free_attributes: boolean);
var
  temp: type_ptr_type;
begin
  while (type_ptr <> nil) do
    begin
      temp := type_ptr;
      type_ptr := type_ptr^.next;
      Destroy_type(temp, free_attributes);
    end;
end; {procedure Destroy_types}


{*********************************************************}
{ routines for recursively marking type declaration trees }
{*********************************************************}


procedure Mark_type(type_ptr: type_ptr_type;
  touched: boolean);
begin
  if (type_ptr <> nil) then
    with type_ptr^ do
      case kind of

        enum_type, alias_type:
          ;

        {************************}
        { structure declarations }
        {************************}
        struct_type:
          begin
            {********************************}
            { mark struct field declarations }
            {********************************}
            Mark_expr(struct_base_ptr, touched);
            Mark_decls(field_decls_ptr, touched);
            Mark_stmts(struct_base_assign_stmt_ptr, touched);
          end;

        {********************}
        { class declarations }
        {********************}
        class_type:
          begin
            {******************************}
            { parent and interface classes }
            {******************************}
            Mark_type_decl(parent_class_ref, touched);
            Mark_type_refs(interface_class_ptr, touched);

            {******************************************}
            { mark class method interface declarations }
            {******************************************}
            Mark_decls(method_decls_ptr, touched);

            {********************************}
            { mark class member declarations }
            {********************************}
            Mark_expr(class_base_ptr, touched);
            Mark_decls(member_decls_ptr, touched);
            Mark_decls(private_member_decls_ptr, touched);
            Mark_stmts(class_base_assign_stmt_ptr, touched);

            {****************************************}
            { mark class implementation declarations }
            {****************************************}
            Mark_decls(class_decls_ptr, touched);
            Mark_stmts(class_init_ptr, touched);
          end;

      end; {case}
end; {procedure Mark_type}


procedure Mark_types(type_ptr: type_ptr_type;
  touched: boolean);
begin
  while (type_ptr <> nil) do
    begin
      Mark_type(type_ptr, touched);
      type_ptr := type_ptr^.next;
    end;
end; {procedure Mark_types}


procedure Mark_type_decl(type_ptr: type_ptr_type;
  touched: boolean);
var
  decl_ptr: decl_ptr_type;
begin
  if (type_ptr <> nil) then
    begin
      decl_ptr := decl_ptr_type(type_ptr^.type_decl_ref);
      Mark_decl(decl_ptr, touched);
    end;
end; {procedure Mark_type_decl}


procedure Mark_type_decls(type_ptr: type_ptr_type;
  touched: boolean);
begin
  while (type_ptr <> nil) do
    begin
      Mark_type_decl(type_ptr, touched);
      type_ptr := type_ptr^.next;
    end;
end; {procedure Mark_type_decls}


procedure Mark_type_ref(type_ref_ptr: type_reference_ptr_type;
  touched: boolean);
begin
  Mark_type_decl(type_ref_ptr^.type_ref, touched);
end; {procedure Mark_type_ref}


procedure Mark_type_refs(type_ref_ptr: type_reference_ptr_type;
  touched: boolean);
begin
  while (type_ref_ptr <> nil) do
    begin
      Mark_type_ref(type_ref_ptr, touched);
      type_ref_ptr := type_ref_ptr^.next;
    end;
end; {procedure Mark_type_refs}


{***********************************************************}
{ routines for recursively comparing type declaration trees }
{***********************************************************}


function Equal_types(type_ptr1, type_ptr2: type_ptr_type): boolean;
begin
  Equal_types := type_ptr1 = type_ptr2;
end; {function Equal_types}


function Same_types(type_ptr1, type_ptr2: type_ptr_type): boolean;
begin
  Same_types := type_ptr1 = type_ptr2;
end; {function Same_types}


end.
