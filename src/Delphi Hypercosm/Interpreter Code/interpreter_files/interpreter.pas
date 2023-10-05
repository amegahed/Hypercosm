unit interpreter;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            interpreter                3d       }
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
  strings, string_structs, addr_types, syntax_trees;


{*************************************}
{ routines for executing syntax trees }
{*************************************}
procedure Interpret(syntax_tree_ptr: syntax_tree_ptr_type;
  argument_list_ptr: string_list_ptr_type;
  max_stack_size: stack_index_type);
procedure Runtime_error(error_message: string_type);
procedure Internal_error(error_message: string_type);
procedure Shut_down;


implementation
uses
  errors, stmts, code_decls, type_decls, decls, data, stacks, handles, memrefs,
  op_stacks, set_stack_data, deref_arrays, exec_stmts, exec_methods, exec_decls,
  eval_row_arrays, implicit_stmts, file_stack;


const
  debug = false;
  memory_alert = false;


  {**********************}
  { forward declarations }
  {**********************}
procedure Interpret_syntax_trees_decls(syntax_tree_ptr: syntax_tree_ptr_type);
  forward;
procedure Interpret_static_syntax_trees_decls(syntax_tree_ptr:
  syntax_tree_ptr_type);
  forward;


procedure Write_call_stack_frame(stmt_ptr: stmt_ptr_type;
  code_ptr: code_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
  decl_info_ptr: decl_info_ptr_type;
  line_number, file_number: integer;
  file_name, decl_name: string_type;
begin
  if stmt_ptr <> nil then
    if stmt_ptr^.stmt_info_ptr <> nil then
      begin
        writeln;
        write('called');
        stmt_info_ptr := stmt_ptr^.stmt_info_ptr;

        line_number := stmt_info_ptr^.line_number;
        write(' from line #', line_number: 1);

        if code_ptr <> nil then
          begin
            decl_info_ptr := code_ptr^.code_decl_ref^.decl_info_ptr;
            if decl_info_ptr <> nil then
              begin
                file_number := decl_info_ptr^.file_number;
                file_name := Get_include(file_number);
                write(' of ', Quotate_str(file_name));

                if decl_info_ptr^.decl_attributes_ptr <> nil then
                  begin
                    decl_name := Get_method_name(code_ptr);
                    write(' in ', Quotate_str(decl_name));
                  end;
              end;
          end;
      end;
end; {procedure Write_call_stack_frame}


procedure Write_call_stack;
var
  call_stack_frames, counter, index: integer;
  stmt_ptr: stmt_ptr_type;
  code_ptr: code_ptr_type;
begin
  if call_stack_height < call_stack_size then
    call_stack_frames := call_stack_height
  else
    call_stack_frames := call_stack_size;

  for counter := 1 to call_stack_frames - 1 do
    begin
      index := (call_stack_height - counter) mod call_stack_size;
      if index < 0 then
        index := index + call_stack_size;

      stmt_ptr := call_stack[index].stmt_ptr;
      code_ptr := call_stack[index].code_ptr;
      Write_call_stack_frame(stmt_ptr, code_ptr);
    end;
end; {procedure Write_call_stack}


procedure Runtime_error(error_message: string_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
  decl_info_ptr: decl_info_ptr_type;
  line_number, file_number: integer;
  file_name, decl_name: string_type;
begin
  writeln('Stopped!');

  if current_stmt_ptr <> nil then
    if current_stmt_ptr^.stmt_info_ptr <> nil then
      begin
        write('Error');
        stmt_info_ptr := current_stmt_ptr^.stmt_info_ptr;

        line_number := stmt_info_ptr^.line_number;
        write(' at line #', line_number: 1);

        if current_code_ptr <> nil then
          current_decl_ptr := current_code_ptr^.code_decl_ref;

        decl_info_ptr := current_decl_ptr^.decl_info_ptr;
        if decl_info_ptr <> nil then
          begin
            file_number := decl_info_ptr^.file_number;
            file_name := Get_include(file_number);
            write(' of ', Quotate_str(file_name));

            if decl_info_ptr^.decl_attributes_ptr <> nil then
              begin
                decl_name := Get_decl_name(current_decl_ptr);
                write(' in ', Quotate_str(decl_name));
              end;
          end;

        Write_call_stack;
        writeln('.');
      end;

  writeln(error_message);
  Stop;
end; {procedure Runtime_error}


procedure Internal_error(error_message: string_type);
begin
  writeln('Internal Error!');
  Runtime_error(error_message);
end; {procedure Internal_error}


procedure Shut_down;
begin
  Close_all_files;
  Halt;
end; {procedure Shut_down}


{************************************}
{ routines to initialize static vars }
{************************************}


function New_args_handle(argument_list_ptr: string_list_ptr_type): handle_type;
var
  argument_array_handle: handle_type;
  argument_handle: handle_type;
  string_list_ptr: string_list_ptr_type;
  arguments, argument_length: integer;
  counter1, counter2: integer;
  heap_index: heap_index_type;
  ch: char;
begin
  {*****************}
  { count arguments }
  {*****************}
  arguments := 0;
  string_list_ptr := argument_list_ptr;
  while (string_list_ptr <> nil) do
    begin
      arguments := arguments + 1;
      string_list_ptr := string_list_ptr^.next;
    end;

  if arguments <> 0 then
    begin
      Eval_new_array_row_array(1, arguments, nil);
      argument_array_handle := Peek_handle_operand;

      for counter1 := 1 to arguments do
        begin
          argument_length := String_length(argument_list_ptr^.string_ptr);
          Eval_new_char_row_array(1, argument_length);
          argument_handle := Peek_handle_operand;

          for counter2 := 1 to argument_length do
            begin
              ch := Index_string(argument_list_ptr^.string_ptr, counter2);
              heap_index := Deref_row_array(argument_handle, counter2, 1);
              Set_handle_data(argument_handle, heap_index, Char_to_data(ch));
            end;

          heap_index := Deref_row_array(argument_array_handle, counter1, 1);
          Set_handle_data(argument_array_handle, heap_index,
            Handle_to_data(argument_handle));
          argument_list_ptr := argument_list_ptr^.next;

          Pop_handle_operand;
        end;

      argument_array_handle := Pop_handle_operand;
    end
  else
    argument_array_handle := 0;

  New_args_handle := argument_array_handle;
end; {function New_args_handle}


{************************************}
{ routines to interpret syntax trees }
{************************************}


procedure Interpret_static_syntax_tree_decls(syntax_tree_ptr:
  syntax_tree_ptr_type);
begin
  if (syntax_tree_ptr <> nil) then
    with syntax_tree_ptr^ do
      case kind of

        {****************************}
        { root of entire syntax tree }
        {****************************}
        root_tree:
          begin
            {*******************************}
            { interpret static declarations }
            {*******************************}
            Interpret_static_decls(implicit_decls_ptr);
            Interpret_static_syntax_trees_decls(implicit_includes_ptr);
            Interpret_static_syntax_trees_decls(root_includes_ptr);
            Interpret_static_decls(decls_ptr);
          end;

        include_tree:
          begin
            Interpret_static_syntax_trees_decls(includes_ptr);
            Interpret_static_decls(include_decls_ptr);
          end;

      end; {case}
end; {procedure Interpret_static_syntax_tree_decls}


procedure Interpret_static_syntax_trees_decls(syntax_tree_ptr:
  syntax_tree_ptr_type);
begin
  while syntax_tree_ptr <> nil do
    begin
      Interpret_static_syntax_tree_decls(syntax_tree_ptr);
      syntax_tree_ptr := syntax_tree_ptr^.next;
    end; {while}
end; {procedure Interpret_static_syntax_trees_decls}


procedure Interpret_syntax_tree_decls(syntax_tree_ptr: syntax_tree_ptr_type);
begin
  if (syntax_tree_ptr <> nil) then
    with syntax_tree_ptr^ do
      case kind of

        {****************************}
        { root of entire syntax tree }
        {****************************}
        root_tree:
          begin
            {*******************************}
            { interpret static declarations }
            {*******************************}
            Interpret_decls(implicit_decls_ptr);
            Interpret_syntax_trees_decls(implicit_includes_ptr);
            Interpret_syntax_trees_decls(root_includes_ptr);
            Interpret_decls(decls_ptr);
          end;

        include_tree:
          begin
            Interpret_syntax_trees_decls(includes_ptr);
            Interpret_decls(include_decls_ptr);
          end;

      end; {case}
end; {procedure Interpret_syntax_tree_decls}


procedure Interpret_syntax_trees_decls(syntax_tree_ptr: syntax_tree_ptr_type);
begin
  while syntax_tree_ptr <> nil do
    begin
      Interpret_syntax_tree_decls(syntax_tree_ptr);
      syntax_tree_ptr := syntax_tree_ptr^.next;
    end; {while}
end; {procedure Interpret_syntax_trees_decls}


procedure Interpret(syntax_tree_ptr: syntax_tree_ptr_type;
  argument_list_ptr: string_list_ptr_type;
  max_stack_size: stack_index_type);
begin
  if (syntax_tree_ptr <> nil) then
    with syntax_tree_ptr^ do
      case kind of

        {****************************}
        { root of entire syntax tree }
        {****************************}
        root_tree:
          begin
            {******************}
            { set status flags }
            {******************}
            current_code_ptr := nil;

            {*******************************}
            { prepare run time enviornement }
            {*******************************}
            Reset_stacks;
            if max_stack_size <> 0 then
              Set_max_stack_size(max_stack_size);
            Push_stack(root_frame_size);

            {*********************}
            { prepare syntax tree }
            {*********************}
            Make_method_data(decls_ptr);

            {*********************************}
            { create implicit free statements }
            {*********************************}
            Make_implicit_free_stmts(syntax_tree_ptr);

            {******}
            { run! }
            {******}
            Interpret_static_syntax_tree_decls(syntax_tree_ptr);
            Interpret_syntax_tree_decls(syntax_tree_ptr);
            if syntax_tree_ptr^.implicit_decls_ptr <> nil then
              if syntax_tree_ptr^.implicit_decls_ptr^.kind = array_decl then
                Set_global_handle(1, New_args_handle(argument_list_ptr));
            Interpret_stmts(stmts_ptr);
          end;

      end; {case}
end; {procedure Interpret}


end.
