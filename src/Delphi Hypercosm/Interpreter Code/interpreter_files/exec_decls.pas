unit exec_decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             exec_decls                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The interpreter controls all aspects of the renderer.   }
{       It instructs the geometry layer to build the database   }
{       and the rendering layers to build their data structs    }
{       and when and how to render the database.                }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decls;


var
  current_decl_ptr: decl_ptr_type;


  {****************************************}
  { routines for interpreting declarations }
  {****************************************}
procedure Interpret_decl(decl_ptr: decl_ptr_type);
procedure Interpret_decls(decls_ptr: decl_ptr_type);
procedure Interpret_static_decls(decls_ptr: decl_ptr_type);


implementation
uses
  addr_types, exprs, stmts, code_decls, type_decls, data, stacks,
  op_stacks, set_data, exec_stmts, exec_native, eval_addrs, exec_data_decls,
  struct_assigns;


const
  debug = false;
  memory_alert = false;


  {*****************************************}
  { routines to interpret type declarations }
  {*****************************************}


procedure Interpret_type_decl(type_ptr: type_ptr_type);
begin
  with type_ptr^ do
    case kind of

      enum_type, alias_type:
        ;

      struct_type:
        struct_base_assign_stmt_ptr := New_struct_base_assign(type_ptr);

      class_type:
        begin
          class_base_assign_stmt_ptr := New_struct_base_assign(type_ptr);
          Interpret_static_decls(method_decls_ptr);
          Interpret_static_decls(member_decls_ptr);
          Interpret_static_decls(private_member_decls_ptr);
          Interpret_static_decls(class_decls_ptr);
          Interpret_decls(class_decls_ptr);
          Interpret_stmts(class_init_ptr);
        end;

    end; {case}
end; {procedure Interpret_type_decl}


{*****************************************}
{ routines to interpret data declarations }
{*****************************************}


procedure Interpret_decl(decl_ptr: decl_ptr_type);
begin
  current_decl_ptr := decl_ptr;

  with decl_ptr^ do
    case kind of

      {*************************}
      { null or nop declaration }
      {*************************}
      null_decl:
        ;

      {*******************}
      { data declarations }
      {*******************}
      boolean_decl..reference_decl:
        if not data_decl.static then
          Interpret_data_decl(decl_ptr);

      {*******************}
      { type declarations }
      {*******************}
      type_decl:
        ;

      {*************************}
      { subprogram declarations }
      {*************************}
      code_decl, code_reference_decl:
        if not code_data_decl.static then
          Interpret_data_decl(decl_ptr);

    end; {case}
end; {procedure Interpret_decl}


procedure Interpret_decls(decls_ptr: decl_ptr_type);
begin
  while (decls_ptr <> nil) do
    begin
      Interpret_decl(decls_ptr);
      decls_ptr := decls_ptr^.next;
    end; {while}
end; {procedure Interpret_decls}


procedure Interpret_static_decl(decl_ptr: decl_ptr_type);
begin
  current_decl_ptr := decl_ptr;

  with decl_ptr^ do
    case kind of

      {*************************}
      { null or nop declaration }
      {*************************}
      null_decl:
        ;

      {*******************}
      { data declarations }
      {*******************}
      boolean_decl..reference_decl:
        if data_decl.static then
          Interpret_data_decl(decl_ptr);

      {*******************}
      { type declarations }
      {*******************}
      type_decl:
        Interpret_type_decl(type_ptr_type(type_ptr));

      {*************************}
      { subprogram declarations }
      {*************************}
      code_decl, code_reference_decl:
        begin
          with code_ptr_type(code_ptr)^ do
            begin
              decl_static_link := Get_static_link;
              Interpret_static_decls(initial_param_decls_ptr);
              Interpret_static_decls(optional_param_decls_ptr);
              Interpret_static_decls(local_decls_ptr);
            end;
          if code_data_decl.static then
            Interpret_data_decl(decl_ptr);
        end;

    end; {case}
end; {procedure Interpret_static_decl}


procedure Interpret_static_decls(decls_ptr: decl_ptr_type);
begin
  while (decls_ptr <> nil) do
    begin
      Interpret_static_decl(decls_ptr);
      decls_ptr := decls_ptr^.next;
    end;
end; {procedure Interpret_static_decls}


end.
