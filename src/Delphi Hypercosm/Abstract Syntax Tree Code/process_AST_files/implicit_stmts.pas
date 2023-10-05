unit implicit_stmts;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           implicit_stmts              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is used to create implicit free             }
{       statements to free heap references when the             }
{       the scope of their declaration comes to an end.         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  syntax_trees;


procedure Make_implicit_free_stmts(syntax_tree_ptr: syntax_tree_ptr_type);


implementation
uses
  code_types, decl_attributes, exprs, stmts, decls, code_decls, type_decls;


{**********************}
{ forward declarations }
{**********************}
procedure Make_stmts_implicit_free_stmts(stmt_ptr: stmt_ptr_type;
  var last_stmt_ptr: stmt_ptr_type);
  forward;
procedure Make_code_decl_implicit_free_stmts(code_ptr: code_ptr_type);
  forward;
procedure Make_decls_implicit_free_stmts(decl_ptr: decl_ptr_type);
  forward;


function New_implicit_free_array_stmt(data_decl: data_decl_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := New_stmt(implicit_free_array_stmt);
  stmt_ptr^.free_array_expr_ref := data_decl.data_expr_ptr;
  New_implicit_free_array_stmt := stmt_ptr;
end; {function New_implicit_free_array_stmt}


function New_implicit_free_struct_stmt(data_decl: data_decl_type):
  stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := New_stmt(implicit_free_struct_stmt);
  stmt_ptr^.free_struct_expr_ref := data_decl.data_expr_ptr;
  New_implicit_free_struct_stmt := stmt_ptr;
end; {function New_implicit_free_struct_stmt}


function New_implicit_free_reference_stmt(data_decl: data_decl_type):
  stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := New_stmt(implicit_free_reference_stmt);
  stmt_ptr^.free_reference_expr_ref := data_decl.data_expr_ptr;
  New_implicit_free_reference_stmt := stmt_ptr;
end; {function New_implicit_free_reference_stmt}


procedure Add_decl_implicit_free_stmts(decl_ptr: decl_ptr_type;
  var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
var
  new_stmt_ptr: stmt_ptr_type;
begin
  if decl_ptr <> nil then
    begin
      new_stmt_ptr := nil;

      if decl_ptr^.kind in reference_decl_set then
        case decl_ptr^.kind of

          {*******************************************}
          { array, struct, and reference declarations }
          {*******************************************}
          array_decl:
            if not decl_ptr^.data_decl.static then
              new_stmt_ptr := New_implicit_free_array_stmt(decl_ptr^.data_decl);
          struct_decl:
            if not decl_ptr^.data_decl.static then
              new_stmt_ptr :=
                New_implicit_free_struct_stmt(decl_ptr^.data_decl);
          reference_decl:
            if not decl_ptr^.data_decl.static then
              new_stmt_ptr :=
                New_implicit_free_reference_stmt(decl_ptr^.data_decl);

          {**************************************}
          { user defined subprogram declarations }
          {**************************************}
          code_decl:
            begin
              Make_code_decl_implicit_free_stmts(decl_ptr^.code_ptr);
              if not decl_ptr^.code_data_decl.static then
                if code_ptr_type(decl_ptr^.code_ptr)^.kind in [object_code,
                  picture_code] then
                  begin
                    new_stmt_ptr := New_stmt(implicit_free_params_stmt);
                    new_stmt_ptr^.free_decl_ref :=
                      forward_decl_ref_type(decl_ptr);
                  end;
            end;
          code_array_decl:
            if not decl_ptr^.code_data_decl.static then
              new_stmt_ptr :=
                New_implicit_free_array_stmt(decl_ptr^.code_data_decl);
          code_reference_decl:
            if not decl_ptr^.code_data_decl.static then
              new_stmt_ptr :=
                New_implicit_free_reference_stmt(decl_ptr^.code_data_decl)

        end; {case}

      {******************************}
      { add statement to end of list }
      {******************************}
      if new_stmt_ptr <> nil then
        begin
          if last_stmt_ptr <> nil then
            begin
              last_stmt_ptr^.next := new_stmt_ptr;
              last_stmt_ptr := new_stmt_ptr;
            end
          else
            begin
              stmt_ptr := new_stmt_ptr;
              last_stmt_ptr := new_stmt_ptr;
            end;
        end;
    end;
end; {procedure Add_decl_implicit_free_stmts}


procedure Add_decls_implicit_free_stmts(decl_ptr: decl_ptr_type;
  var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
begin
  while decl_ptr <> nil do
    begin
      Add_decl_implicit_free_stmts(decl_ptr, stmt_ptr, last_stmt_ptr);
      decl_ptr := decl_ptr^.next;
    end;
end; {procedure Add_decls_implicit_free_stmts}


procedure Add_decls_stmts_implicit_free_stmts(decl_ptr: decl_ptr_type;
  var stmt_ptr: stmt_ptr_type);
var
  last_stmt_ptr: stmt_ptr_type;
begin
  {************************************************}
  { add implicit free statements to each statement }
  {************************************************}
  Make_stmts_implicit_free_stmts(stmt_ptr, last_stmt_ptr);

  {*********************************************}
  { add implicit free statements to end of list }
  {*********************************************}
  Add_decls_implicit_free_stmts(decl_ptr, stmt_ptr, last_stmt_ptr);
end; {procedure Add_decl_stmt_implicit_free_stmts}


procedure Make_stmt_implicit_free_stmts(stmt_ptr: stmt_ptr_type;
  var last_stmt_ptr: stmt_ptr_type);
var
  case_constant_ptr: case_constant_ptr_type;
  switch_case_ptr: switch_case_ptr_type;
begin
  with stmt_ptr^ do
    if kind in decl_stmt_set then
      case kind of

        {************************}
        { conditional statements }
        {************************}
        if_then_else:
          begin
            Add_decls_stmts_implicit_free_stmts(decl_ptr_type(then_decls_ptr),
              then_stmts_ptr);
            Add_decls_stmts_implicit_free_stmts(decl_ptr_type(else_decls_ptr),
              else_stmts_ptr);
          end;
        case_char_stmt, case_enum_stmt:
          begin
            case_constant_ptr := switch_case_constant_ptr;
            while (case_constant_ptr <> nil) do
              begin
                switch_case_ptr :=
                  switch_array_ptr^.switch_case_array[case_constant_ptr^.value];
                with switch_case_ptr^ do
                  Add_decls_stmts_implicit_free_stmts(decl_ptr_type(case_decls_ptr), case_stmts_ptr);
                case_constant_ptr := case_constant_ptr^.next;
              end;
            Add_decls_stmts_implicit_free_stmts(decl_ptr_type(switch_else_decls_ptr), switch_else_stmts_ptr);
          end;

        {********************}
        { looping statements }
        {********************}
        while_loop:
          Add_decls_stmts_implicit_free_stmts(decl_ptr_type(while_decls_ptr),
            while_stmts_ptr);
        for_loop:
          Add_decls_stmts_implicit_free_stmts(decl_ptr_type(for_decls_ptr),
            for_stmts_ptr);
        for_each:
          Add_decls_stmts_implicit_free_stmts(decl_ptr_type(each_decls_ptr),
            each_stmts_ptr);
        for_each_loop:
          Make_stmts_implicit_free_stmts(loop_stmts_ptr, last_stmt_ptr);
        for_each_list:
          Make_stmts_implicit_free_stmts(list_stmts_ptr, last_stmt_ptr);
        loop_label_stmt:
          Make_stmts_implicit_free_stmts(loop_stmt_ptr, last_stmt_ptr);

        {********************}
        { scoping statements }
        {********************}
        with_stmt:
          Add_decls_stmts_implicit_free_stmts(decl_ptr_type(with_decls_ptr),
            with_stmts_ptr);
      end; {case}
end; {procedure Make_stmt_implicit_free_stmts}


procedure Make_stmts_implicit_free_stmts(stmt_ptr: stmt_ptr_type;
  var last_stmt_ptr: stmt_ptr_type);
begin
  last_stmt_ptr := nil;
  while (stmt_ptr <> nil) do
    begin
      Make_stmt_implicit_free_stmts(stmt_ptr, last_stmt_ptr);
      last_stmt_ptr := stmt_ptr;
      stmt_ptr := stmt_ptr^.next;
    end;
end; {procedure Make_stmts_implicit_free_stmts}


procedure Make_type_decl_implicit_free_stmts(type_ptr: type_ptr_type);
begin
  with type_ptr^ do
    if kind = class_type then
      begin
        {***************************}
        { init static vars of class }
        {***************************}
        Make_decls_implicit_free_stmts(method_decls_ptr);
        Make_decls_implicit_free_stmts(member_decls_ptr);
        Make_decls_implicit_free_stmts(private_member_decls_ptr);
        Make_decls_implicit_free_stmts(class_decls_ptr);
      end;
end; {procedure Make_type_decl_implicit_free_stmts}


procedure Make_code_decl_implicit_free_stmts(code_ptr: code_ptr_type);
var
  last_stmt_ptr: stmt_ptr_type;
begin
  with code_ptr^ do
    if decl_kind in [actual_decl, native_decl] then
      begin
        {*************************************}
        { make implicit free stmts for params }
        {*************************************}
        last_stmt_ptr := nil;
        Add_decl_implicit_free_stmts(implicit_param_decls_ptr,
          param_free_stmts_ptr, last_stmt_ptr);
        Add_decls_implicit_free_stmts(initial_param_decls_ptr,
          param_free_stmts_ptr, last_stmt_ptr);
        Add_decls_implicit_free_stmts(optional_param_decls_ptr,
          param_free_stmts_ptr, last_stmt_ptr);
        Add_decls_implicit_free_stmts(return_param_decls_ptr,
          param_free_stmts_ptr, last_stmt_ptr);

        {*************************************}
        { make implicit free stmts for locals }
        {*************************************}
        Make_stmts_implicit_free_stmts(local_stmts_ptr,
          last_stmt_ptr);
        Add_decls_implicit_free_stmts(local_decls_ptr,
          local_stmts_ptr, last_stmt_ptr);
      end;
end; {procedure Make_code_decl_implicit_free_stmts}


procedure Make_decl_implicit_free_stmts(decl_ptr: decl_ptr_type);
begin
  with decl_ptr^ do
    if kind in [type_decl, code_decl] then
      case kind of

        {********************************}
        { user defined type declarations }
        {********************************}
        type_decl:
          Make_type_decl_implicit_free_stmts(type_ptr_type(type_ptr));

        {*************************}
        { subprogram declarations }
        {*************************}
        code_decl:
          Make_code_decl_implicit_free_stmts(code_ptr_type(code_ptr));

      end; {case}
end; {procedure Make_decl_implicit_free_stmts}


procedure Make_decls_implicit_free_stmts(decl_ptr: decl_ptr_type);
begin
  while (decl_ptr <> nil) do
    begin
      Make_decl_implicit_free_stmts(decl_ptr);
      decl_ptr := decl_ptr^.next;
    end;
end; {procedure Make_decls_implicit_free_stmts}


procedure Make_implicit_free_stmts(syntax_tree_ptr: syntax_tree_ptr_type);
begin
  while (syntax_tree_ptr <> nil) do
    begin
      with syntax_tree_ptr^ do
        case kind of

          {******************}
          { root declaration }
          {******************}
          root_tree:
            begin
              Make_decls_implicit_free_stmts(implicit_decls_ptr);
              Make_implicit_free_stmts(implicit_includes_ptr);
              Make_implicit_free_stmts(root_includes_ptr);
              Make_decls_implicit_free_stmts(decls_ptr);
            end;

          {*******************************}
          { declarations from other files }
          {*******************************}
          include_tree:
            begin
              Make_implicit_free_stmts(includes_ptr);
              Make_decls_implicit_free_stmts(include_decls_ptr);
            end;

        end; {case}

      syntax_tree_ptr := syntax_tree_ptr^.next;
    end;
end; {procedure Make_implicit_free_stmts}


end.

