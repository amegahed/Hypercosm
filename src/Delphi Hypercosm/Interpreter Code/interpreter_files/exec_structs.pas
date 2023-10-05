unit exec_structs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            exec_structs               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       To evaluate the expression, we interpret the syntax     }
{       tree by traversing it and performing the indicated      }
{       operation at each node.                                 }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types, type_decls;


{*****************************************}
{ routines to initialize structure fields }
{*****************************************}
procedure Init_struct_fields(memref: memref_type;
  type_ptr: type_ptr_type);
procedure Init_static_struct_fields(addr: addr_type;
  type_ptr: type_ptr_type);


implementation
uses
  errors, complex_numbers, vectors, data_types, code_decls, decls, data,
  eval_arrays, stacks, heaps, op_stacks, get_heap_data, set_heap_data, get_data,
  set_data, exec_data_decls;


{**************************************}
{ routines to initialize struct fields }
{**************************************}


procedure Init_field(decl_ptr: decl_ptr_type);
begin
  case decl_ptr^.kind of

    null_decl, type_decl:
      ;

    boolean_decl..reference_decl:
      if not decl_ptr^.data_decl.static then
        Interpret_data_decl(decl_ptr);

    code_decl..code_reference_decl:
      if not decl_ptr^.code_data_decl.static then
        Interpret_data_decl(decl_ptr);

  end; {case}
end; {procedure Init_field}


procedure Init_fields(type_ptr: type_ptr_type);
var
  field_decls_ptr: decl_ptr_type;
begin
  case type_ptr^.kind of

    struct_type:
      begin
        {***********************}
        { interpret field decls }
        {***********************}
        field_decls_ptr := type_ptr^.field_decls_ptr;
        while (field_decls_ptr <> nil) do
          begin
            Init_field(field_decls_ptr);
            field_decls_ptr := field_decls_ptr^.next;
          end;
      end;

    class_type:
      begin
        {*************************************************}
        { interpret decls of public and protected members }
        {*************************************************}
        field_decls_ptr := type_ptr^.member_decls_ptr;
        while (field_decls_ptr <> nil) do
          begin
            Init_field(field_decls_ptr);
            field_decls_ptr := field_decls_ptr^.next;
          end;

        {************************************}
        { interpret decls of private members }
        {************************************}
        field_decls_ptr := type_ptr^.private_member_decls_ptr;
        while (field_decls_ptr <> nil) do
          begin
            Init_field(field_decls_ptr);
            field_decls_ptr := field_decls_ptr^.next;
          end;
      end;

  end; {case}
end; {procedure Init_fields}


procedure Init_struct_fields(memref: memref_type;
  type_ptr: type_ptr_type);
begin
  case type_ptr^.kind of

    struct_type:
      begin
        {*********************}
        { set struct base ptr }
        {*********************}
        type_ptr^.struct_base_ptr^.struct_base_memref := memref;

        {***********************}
        { interpret field decls }
        {***********************}
        Init_fields(type_ptr);
      end;

    class_type:
      begin
        {*******************************************}
        { store class decl in first field of object }
        {*******************************************}
        Set_memref_type(memref, 1, abstract_type_ptr_type(type_ptr));

        {*************************************************}
        { interpret field decls of class and superclasses }
        {*************************************************}
        while type_ptr <> nil do
          begin
            {********************}
            { set class base ptr }
            {********************}
            type_ptr^.class_base_ptr^.struct_base_memref := memref;

            {***********************}
            { interpret field decls }
            {***********************}
            Init_fields(type_ptr);

            {********************}
            { go to parent class }
            {********************}
            type_ptr := type_ptr^.parent_class_ref;
          end;
      end;

  end; {case}
end; {procedure Init_struct_fields}


procedure Init_static_struct_fields(addr: addr_type;
  type_ptr: type_ptr_type);
begin
  case type_ptr^.kind of

    struct_type:
      begin
        {*********************}
        { set struct base ptr }
        {*********************}
        type_ptr^.struct_base_ptr^.static_struct_base_addr := addr;

        {***********************}
        { interpret field decls }
        {***********************}
        Init_fields(type_ptr);
      end;

    class_type:
      begin
        {*******************************************}
        { store class decl in first field of object }
        {*******************************************}
        Set_addr_type(addr, abstract_type_ptr_type(type_ptr));

        {*************************************************}
        { interpret field decls of class and superclasses }
        {*************************************************}
        while type_ptr <> nil do
          begin
            {*********************}
            { set class base addr }
            {*********************}
            type_ptr^.class_base_ptr^.static_struct_base_addr := addr;

            {***********************}
            { interpret field decls }
            {***********************}
            Init_fields(type_ptr);

            {********************}
            { go to parent class }
            {********************}
            type_ptr := type_ptr^.parent_class_ref;
          end;
      end;

  end; {case}
end; {procedure Init_static_struct_fields}


end.
