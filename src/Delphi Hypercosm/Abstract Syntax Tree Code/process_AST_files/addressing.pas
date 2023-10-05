unit addressing;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             addressing                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module provides functions for computing the        }
{       addresses of all identifier references in the           }
{       syntax tree.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  syntax_trees;


procedure Find_addrs(syntax_tree_ptr: syntax_tree_ptr_type);


implementation
uses
  strings, data_types, addr_types, type_attributes, decl_attributes,
  expr_attributes, exprs, stmts, decls, code_decls, type_decls;


const
  debug = false;


var
  static_size: stack_index_type;


  {**********************}
  { forward declarations }
  {**********************}
procedure Find_stmts_addrs(stmt_ptr: stmt_ptr_type);
  forward;
procedure Find_decl_addrs(decl_ptr: decl_ptr_type);
  forward;
procedure Find_decls_addrs(decl_ptr: decl_ptr_type);
  forward;
procedure Find_static_decls_addrs(decl_ptr: decl_ptr_type);
  forward;
procedure Find_nonstatic_decls_addrs(decl_ptr: decl_ptr_type);
  forward;
procedure Find_syntax_trees_addrs(syntax_tree_ptr: syntax_tree_ptr_type);
  forward;


{**************************}
{ data allocation routines }
{**************************}


procedure Allocate_field_space(decl_attributes_ptr: decl_attributes_ptr_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type);
var
  size: stack_index_type;
begin
  size := decl_attributes_ptr^.type_attributes_ptr^.size;
  decl_attributes_ptr^.field_index := scope_decl_attributes_ptr^.scope_size + 1;
  scope_decl_attributes_ptr^.scope_size := scope_decl_attributes_ptr^.scope_size
    + size;
end; {procedure Allocate_field_space}


procedure Allocate_static_space(decl_attributes_ptr: decl_attributes_ptr_type);
var
  size: stack_index_type;
begin
  size := decl_attributes_ptr^.type_attributes_ptr^.size;
  decl_attributes_ptr^.stack_index := static_size + 1;
  static_size := static_size + size;
end; {procedure Allocate_static_space}


procedure Allocate_local_space(decl_attributes_ptr: decl_attributes_ptr_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type);
var
  size: stack_index_type;
begin
  if scope_decl_attributes_ptr <> nil then
    begin
      if scope_decl_attributes_ptr^.kind <> type_decl_attributes then
        begin
          size := decl_attributes_ptr^.type_attributes_ptr^.size;
          decl_attributes_ptr^.stack_index :=
            scope_decl_attributes_ptr^.scope_size + 1;
          scope_decl_attributes_ptr^.scope_size :=
            scope_decl_attributes_ptr^.scope_size + size;
        end
      else
        begin
          scope_decl_attributes_ptr :=
            scope_decl_attributes_ptr^.scope_decl_attributes_ptr;
          Allocate_local_space(decl_attributes_ptr, scope_decl_attributes_ptr);
        end;
    end
  else
    Allocate_static_space(decl_attributes_ptr);
end; {procedure Allocate_local_space}


procedure Find_data_decl_addr(decl_ptr: decl_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type;
begin
  decl_attributes_ptr := Get_decl_attributes(decl_ptr);
  scope_decl_attributes_ptr := decl_attributes_ptr^.scope_decl_attributes_ptr;

  {***************************}
  { structure or class fields }
  {***************************}
  if decl_attributes_ptr^.kind = field_decl_attributes then
    Allocate_field_space(decl_attributes_ptr, scope_decl_attributes_ptr)

    {*****************************}
    { static variables or methods }
    {*****************************}
  else if decl_attributes_ptr^.static then
    Allocate_static_space(decl_attributes_ptr)

    {*****************}
    { local variables }
    {*****************}
  else
    Allocate_local_space(decl_attributes_ptr, scope_decl_attributes_ptr)
end; {procedure Find_data_decl_addr}


{**************************************}
{ routines for finding statement addrs }
{**************************************}


procedure Find_case_addrs(case_constant_ptr: case_constant_ptr_type;
  switch_array_ptr: switch_array_ptr_type);
var
  switch_case_ptr: switch_case_ptr_type;
begin
  while case_constant_ptr <> nil do
    begin
      switch_case_ptr :=
        switch_array_ptr^.switch_case_array[case_constant_ptr^.value];
      Find_decls_addrs(decl_ptr_type(switch_case_ptr^.case_decls_ptr));
      Find_stmts_addrs(switch_case_ptr^.case_stmts_ptr);
      case_constant_ptr := case_constant_ptr^.next;
    end;
end; {procedure Find_case_addrs}


procedure Find_stmt_addrs(stmt_ptr: stmt_ptr_type);
begin
  if stmt_ptr <> nil then
    with stmt_ptr^ do
      if kind in decl_stmt_set then
        case kind of

          {************************}
          { conditional statements }
          {************************}
          if_then_else:
            begin
              Find_decls_addrs(decl_ptr_type(then_decls_ptr));
              Find_stmts_addrs(then_stmts_ptr);
              Find_decls_addrs(decl_ptr_type(else_decls_ptr));
              Find_stmts_addrs(else_stmts_ptr);
            end;
          case_char_stmt, case_enum_stmt:
            begin
              Find_case_addrs(switch_case_constant_ptr, switch_array_ptr);
              Find_decls_addrs(decl_ptr_type(switch_else_decls_ptr));
              Find_stmts_addrs(switch_else_stmts_ptr);
            end;

          {********************}
          { looping statements }
          {********************}
          while_loop:
            begin
              Find_decls_addrs(decl_ptr_type(while_decls_ptr));
              Find_stmts_addrs(while_stmts_ptr);
            end;
          for_loop:
            begin
              Find_decl_addrs(decl_ptr_type(counter_decl_ptr));
              Find_decls_addrs(decl_ptr_type(for_decls_ptr));
              Find_stmts_addrs(for_stmts_ptr);
            end;
          for_each:
            begin
              Find_decl_addrs(decl_ptr_type(each_index_decl_ptr));
              Find_decls_addrs(decl_ptr_type(each_decls_ptr));
              Find_stmts_addrs(each_stmts_ptr);
            end;
          for_each_loop:
            Find_stmts_addrs(loop_stmts_ptr);
          for_each_list:
            begin
              Find_decl_addrs(decl_ptr_type(each_struct_decl_ptr));
              Find_decls_addrs(decl_ptr_type(list_decls_ptr));
              Find_stmts_addrs(list_stmts_ptr);
            end;
          loop_label_stmt:
            Find_stmt_addrs(loop_stmt_ptr);

          {********************}
          { scoping statements }
          {********************}
          with_stmt:
            begin
              Find_decls_addrs(decl_ptr_type(with_decls_ptr));
              Find_stmts_addrs(with_stmts_ptr);
            end;

        end; {case}
end; {procedure Find_stmt_addrs}


procedure Find_stmts_addrs(stmt_ptr: stmt_ptr_type);
begin
  while stmt_ptr <> nil do
    begin
      Find_stmt_addrs(stmt_ptr);
      stmt_ptr := stmt_ptr^.next;
    end;
end; {procedure Find_stmts_addrs}


{****************************************}
{ routines for finding declaration addrs }
{****************************************}


procedure Find_code_decl_addrs(code_ptr: code_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if code_ptr^.decl_kind <> forward_decl then
    Find_data_decl_addr(code_ptr^.code_decl_ref);

  decl_attributes_ptr := Get_decl_attributes(code_ptr^.code_decl_ref);
  with code_ptr^ do
    begin
      {*******************}
      { initial paramters }
      {*******************}
      Find_decl_addrs(implicit_param_decls_ptr);
      Find_decls_addrs(initial_param_decls_ptr);

      {*********************}
      { optional parameters }
      {*********************}
      Find_decls_addrs(optional_param_decls_ptr);
      params_size := decl_attributes_ptr^.scope_size;

      {*******************}
      { return parameters }
      {*******************}
      Find_decls_addrs(return_param_decls_ptr);
      Find_decls_addrs(local_decls_ptr);
      Find_stmts_addrs(local_stmts_ptr);

      stack_frame_size := decl_attributes_ptr^.scope_size;
    end;
end; {procedure Find_code_decl_addrs}


procedure Set_type_size(type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  {*******************************}
  { dynamic (run time) allocation }
  {*******************************}
  type_ptr^.size := decl_attributes_ptr^.scope_size;

  {**********************************}
  { static (compile time) allocation }
  {**********************************}
  if type_ptr^.static then
    decl_attributes_ptr^.type_attributes_ptr^.size := type_ptr^.size
  else
    decl_attributes_ptr^.type_attributes_ptr^.size := 1;
end; {procedure Set_type_size}


procedure Find_type_decl_addrs(type_ptr: type_ptr_type);
var
  parent_size: integer;
  decl_attributes_ptr: decl_attributes_ptr_type;
  parent_decl_attributes_ptr: decl_attributes_ptr_type;
begin
  decl_attributes_ptr := Get_decl_attributes(type_ptr^.type_decl_ref);

  if type_ptr^.kind in [struct_type, class_type] then
    with type_ptr^ do
      case kind of

        struct_type:
          begin
            Find_decls_addrs(field_decls_ptr);
            Set_type_size(type_ptr, decl_attributes_ptr);
          end; {struct_type}

        class_type:
          begin
            {**************************************************}
            { if the class has a parent class then its fields  }
            { must come after space has been allocated for the }
            { parent 's fields, otherwise, for the base class, }
            { the first field is a pointer to the class type.  }
            {**************************************************}
            if parent_class_ref <> nil then
              begin
                parent_decl_attributes_ptr :=
                  Get_decl_attributes(parent_class_ref^.type_decl_ref);
                if parent_decl_attributes_ptr <> nil then
                  parent_size := parent_decl_attributes_ptr^.scope_size
                else
                  parent_size := 1;
              end
            else
              parent_size := 1;

            {*******************************}
            { allocate space for base class }
            {*******************************}
            if decl_attributes_ptr^.type_attributes_ptr^.kind <> type_class_alias
              then
              decl_attributes_ptr^.scope_size := parent_size
            else
              decl_attributes_ptr^.scope_size :=
                decl_attributes_ptr^.type_attributes_ptr^.class_alias_type_attributes_ptr^.size;

            {***********************************************************}
            { Since classes may contain static instances of themselves, }
            { we must find the size of the class by allocating all of   }
            { the nonstatic members before allocating the statics.      }
            {***********************************************************}
            Find_nonstatic_decls_addrs(member_decls_ptr);
            Find_nonstatic_decls_addrs(private_member_decls_ptr);
            Set_type_size(type_ptr, decl_attributes_ptr);
            Find_static_decls_addrs(member_decls_ptr);
            Find_static_decls_addrs(private_member_decls_ptr);

            {*************************************************}
            { find addrs for class methods and implementation }
            {*************************************************}
            Find_decls_addrs(method_decls_ptr);
            Find_decls_addrs(class_decls_ptr);
            Find_stmts_addrs(class_init_ptr);
          end; {class_type}

      end; {case}
end; {procedure Find_type_decl_addrs}


procedure Find_decl_addrs(decl_ptr: decl_ptr_type);
begin
  if decl_ptr <> nil then
    case decl_ptr^.kind of

      null_decl:
        ;

      boolean_decl..reference_decl:
        Find_data_decl_addr(decl_ptr);

      type_decl:
        Find_type_decl_addrs(type_ptr_type(decl_ptr^.type_ptr));

      code_decl, code_reference_decl:
        Find_code_decl_addrs(code_ptr_type(decl_ptr^.code_ptr));

    end; {case}
end; {procedure Find_decl_addrs}


procedure Find_static_decl_addrs(decl_ptr: decl_ptr_type);
begin
  if decl_ptr <> nil then
    case decl_ptr^.kind of

      null_decl:
        ;

      boolean_decl..reference_decl:
        if decl_ptr^.data_decl.static then
          Find_data_decl_addr(decl_ptr);

      type_decl:
        Find_type_decl_addrs(type_ptr_type(decl_ptr^.type_ptr));

      code_decl, code_reference_decl:
        if decl_ptr^.code_data_decl.static then
          Find_code_decl_addrs(code_ptr_type(decl_ptr^.code_ptr));

    end; {case}
end; {procedure Find_static_decl_addrs}


procedure Find_nonstatic_decl_addrs(decl_ptr: decl_ptr_type);
begin
  if decl_ptr <> nil then
    case decl_ptr^.kind of

      null_decl:
        ;

      boolean_decl..reference_decl:
        if not decl_ptr^.data_decl.static then
          Find_data_decl_addr(decl_ptr);

      type_decl:
        ;

      code_decl, code_reference_decl:
        if not decl_ptr^.code_data_decl.static then
          Find_code_decl_addrs(code_ptr_type(decl_ptr^.code_ptr));

    end; {case}
end; {procedure Find_nonstatic_decl_addrs}


procedure Find_decls_addrs(decl_ptr: decl_ptr_type);
begin
  while decl_ptr <> nil do
    begin
      Find_decl_addrs(decl_ptr);
      decl_ptr := decl_ptr^.next;
    end;
end; {procedure Find_decls_addrs}


procedure Find_static_decls_addrs(decl_ptr: decl_ptr_type);
begin
  while decl_ptr <> nil do
    begin
      Find_static_decl_addrs(decl_ptr);
      decl_ptr := decl_ptr^.next;
    end;
end; {procedure Find_static_decls_addrs}


procedure Find_nonstatic_decls_addrs(decl_ptr: decl_ptr_type);
begin
  while decl_ptr <> nil do
    begin
      Find_nonstatic_decl_addrs(decl_ptr);
      decl_ptr := decl_ptr^.next;
    end;
end; {procedure Find_nonstatic_decls_addrs}


{****************************************}
{ routines for finding syntax tree addrs }
{****************************************}


procedure Find_syntax_tree_addrs(syntax_tree_ptr: syntax_tree_ptr_type);
begin
  if syntax_tree_ptr <> nil then
    with syntax_tree_ptr^ do
      case kind of

        root_tree:
          begin
            static_size := 0;
            Find_decls_addrs(implicit_decls_ptr);
            Find_syntax_trees_addrs(implicit_includes_ptr);
            Find_syntax_trees_addrs(root_includes_ptr);
            Find_decls_addrs(decls_ptr);
            root_frame_size := static_size;
          end;

        include_tree:
          begin
            Find_syntax_trees_addrs(includes_ptr);
            Find_decls_addrs(include_decls_ptr);
          end;

      end; {case}
end; {procedure Find_syntax_tree_addrs}


procedure Find_syntax_trees_addrs(syntax_tree_ptr: syntax_tree_ptr_type);
begin
  while syntax_tree_ptr <> nil do
    begin
      Find_syntax_tree_addrs(syntax_tree_ptr);
      syntax_tree_ptr := syntax_tree_ptr^.next;
    end;
end; {procedure Find_syntax_trees_addrs}


{***************************************}
{ routines for finding expression addrs }
{***************************************}


procedure Find_expr_addrs;
var
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  expr_attributes_ptr := active_expr_attributes_list;

  while expr_attributes_ptr <> nil do
    begin
      if expr_attributes_ptr^.kind = variable_attributes_kind then
        begin
          expr_ptr := expr_ptr_type(expr_attributes_ptr^.expr_ref);

          if debug then
            begin
              write('finding the addr of expr, ');
              writeln(Quotate_str(Get_expr_attributes_name(expr_attributes_ptr)),
                '.');
            end;

          with expr_ptr^ do
            if kind in identifier_set then
              case kind of

                global_identifier, local_identifier:
                  begin
                    decl_attributes_ptr :=
                      expr_attributes_ptr^.decl_attributes_ptr;
                    expr_ptr^.stack_index := decl_attributes_ptr^.stack_index;
                  end;

                nested_identifier:
                  begin
                    decl_attributes_ptr :=
                      expr_attributes_ptr^.decl_attributes_ptr;
                    expr_ptr^.nested_id_expr_ptr^.stack_index :=
                      decl_attributes_ptr^.stack_index;
                  end;

                field_identifier:
                  begin
                    decl_attributes_ptr :=
                      expr_attributes_ptr^.decl_attributes_ptr;
                    expr_ptr^.field_index := decl_attributes_ptr^.field_index;
                  end;

              end; {case}
        end; {if variable_attributes}

      expr_attributes_ptr := expr_attributes_ptr^.next;
    end; {while}
end; {procedure Find_expr_addrs}


procedure Find_addrs(syntax_tree_ptr: syntax_tree_ptr_type);
begin
  Find_syntax_tree_addrs(syntax_tree_ptr);
  Find_expr_addrs;
end; {procedure Find_addrs}


end.

