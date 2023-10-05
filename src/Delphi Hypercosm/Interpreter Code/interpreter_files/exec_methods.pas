unit exec_methods;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            exec_methods               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for the execution of         }
{       methods described by the abstract syntax tree.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types, stmts, decls, code_decls;


const
  call_stack_size = 16;


type
  call_stack_frame_type = record
    stmt_ptr: stmt_ptr_type;
    code_ptr: code_ptr_type;
  end;


  call_stack_type = array[0..call_stack_size] of call_stack_frame_type;


var
  returning_from: boolean;
  current_code_ptr: code_ptr_type;
  call_stack: call_stack_type;
  call_stack_height: integer;


{*********************************}
{ auxilliary interpreter routines }
{*********************************}
procedure Push_param_frame(stmt_ptr: stmt_ptr_type;
  var code_ptr: code_ptr_type);
procedure Assign_params(stmt_ptr: stmt_ptr_type);

{**********************************}
{ routines to execute a subprogram }
{**********************************}
procedure Interpret_method_stmt(stmt_ptr: stmt_ptr_type);
procedure Interpret_destructor_stmt(code_ptr: code_ptr_type;
  memref: memref_type);
procedure Interpret_abstract_destructor_stmt(code_ptr: forward_code_ptr_type;
  memref: memref_type);

{*************************************}
{ routines to deal with method params }
{*************************************}
procedure Pre_eval_method(stmt_ptr: stmt_ptr_type);
procedure Make_method_data(decl_ptr: decl_ptr_type);
procedure Free_method_params(decl_ptr: decl_ptr_type);


implementation
uses
  errors, strings, exprs, code_types, type_decls, params, data, stacks,
  set_stack_data, heaps, op_stacks, get_data, get_heap_data, set_data,
  eval_booleans, eval_chars, eval_integers, eval_scalars, eval_references,
  eval_structs, make_exprs, native_glue, exec_native, exec_graphics,
  exec_objects, exec_stmts, exec_decls, interpreter;


{**********************}
{ forward declarations }
{**********************}
function Find_method_offset(parent_class_ptr: type_ptr_type;
  interface_ptr: type_ptr_type;
  var found: boolean): integer;
  forward;


const
  debug = false;


function Find_method_interface_offset(type_ref_ptr: type_reference_ptr_type;
  interface_ptr: type_ptr_type;
  var found: boolean): integer;
var
  offset: integer;
begin
  found := false;
  offset := 0;

  {***************************************}
  { search list of interfaces for a match }
  {***************************************}
  while (type_ref_ptr <> nil) and (not found) do
    begin
      offset := Find_method_offset(type_ref_ptr^.type_ref, interface_ptr,
        found);

      if found then
        offset := offset + type_ref_ptr^.index
      else
        type_ref_ptr := type_ref_ptr^.next;
    end;

  Find_method_interface_offset := offset;
end; {function Find_method_interface_offset}


function Find_method_offset(parent_class_ptr: type_ptr_type;
  interface_ptr: type_ptr_type;
  var found: boolean): integer;
var
  offset: integer;
begin
  found := false;
  offset := 0;

  if (parent_class_ptr <> interface_ptr) then
    begin
      {**************************************}
      { search class hierarchy of interfaces }
      {**************************************}
      while (parent_class_ptr <> nil) and (not found) do
        begin
          {*********************************************************}
          { calling an interface extending a class - the interface  }
          { methods are at an offset from the start of the dispatch }
          { table after the superclass's methods.                   }
          {*********************************************************}
          offset :=
            Find_method_interface_offset(parent_class_ptr^.interface_class_ptr,
            interface_ptr, found);

          if not found then
            parent_class_ptr := parent_class_ptr^.parent_class_ref;
        end;
    end
  else
    begin
      {**************************************************}
      { calling an interface method directly - no offset }
      {**************************************************}
      found := true;
    end;

  Find_method_offset := offset;
end; {function Find_method_offset}


procedure Push_static_frame(stmt_ptr: stmt_ptr_type;
  var code_ptr: code_ptr_type);
begin
  code_ptr := code_ptr_type(stmt_ptr^.stmt_code_ref);
  Push_stack_frame(code_ptr^.decl_static_link);
  Push_stack(code_ptr^.stack_frame_size);
end; {procedure Push_static_frame}


procedure Push_dynamic_frame(stmt_ptr: stmt_ptr_type;
  var code_ptr: code_ptr_type);
var
  memref: memref_type;
  class_type_ptr: type_ptr_type;
  dispatch_table_ptr: dispatch_table_ptr_type;
begin
  code_ptr := code_ptr_type(stmt_ptr^.stmt_code_ref);
  Push_stack_frame(code_ptr^.decl_static_link);
  class_type_ptr := type_ptr_type(code_ptr^.class_type_ref);

  {***********************}
  { find type from object }
  {***********************}
  if not class_type_ptr^.static then
    begin
      {***********************************************}
      { class decl ptr is first field of class object }
      {***********************************************}
      if code_ptr^.reference_method then
        begin
          Eval_reference(stmt_ptr^.implicit_stmts_ptr^.rhs_expr_ptr);
          memref := Get_addr_memref(Pop_addr_operand)
        end
      else
        begin
          Eval_struct(stmt_ptr^.implicit_stmts_ptr^.rhs_expr_ptr);
          memref := Pop_memref_operand;
        end;

      if memref <> 0 then
        class_type_ptr := type_ptr_type(Get_memref_type(memref, 1))
      else
        Runtime_error('Can not call a method with a nil object.');
    end;

  {*********************************************}
  { find actual code from type's dispatch table }
  {*********************************************}
  dispatch_table_ptr := class_type_ptr^.dispatch_table_ptr;
  code_ptr := dispatch_table_ptr^.dispatch_table[code_ptr^.method_id];

  Set_static_link(code_ptr^.decl_static_link);
  Push_stack(code_ptr^.stack_frame_size);
end; {procedure Push_dynamic_frame}


procedure Push_interface_frame(stmt_ptr: stmt_ptr_type;
  var code_ptr: code_ptr_type);
var
  memref: memref_type;
  class_type_ptr: type_ptr_type;
  dispatch_table_ptr: dispatch_table_ptr_type;
  offset: integer;
  found: boolean;
begin
  code_ptr := code_ptr_type(stmt_ptr^.stmt_code_ref);
  Push_stack_frame(code_ptr^.decl_static_link);

  {***********************************************}
  { class decl ptr is first field of class object }
  {***********************************************}
  if code_ptr^.reference_method then
    begin
      Eval_reference(stmt_ptr^.implicit_stmts_ptr^.rhs_expr_ptr);
      memref := Get_addr_memref(Pop_addr_operand)
    end
  else
    begin
      Eval_struct(stmt_ptr^.implicit_stmts_ptr^.rhs_expr_ptr);
      memref := Pop_memref_operand;
    end;

  if memref <> 0 then
    begin
      class_type_ptr := type_ptr_type(Get_memref_type(memref, 1));
      dispatch_table_ptr := class_type_ptr^.dispatch_table_ptr;
      code_ptr := dispatch_table_ptr^.dispatch_table[code_ptr^.method_id];
    end
  else
    begin
      Runtime_error('Can not call a method with a nil object.');
      class_type_ptr := nil;
      dispatch_table_ptr := nil;
      code_ptr := nil;
    end;

  {******************************************************************}
  { interface methods must add an offset to the dispatch table index }
  {******************************************************************}
  code_ptr := code_ptr_type(stmt_ptr^.stmt_code_ref);
  offset := Find_method_offset(class_type_ptr,
    type_ptr_type(code_ptr^.class_type_ref), found);

  if found then
    code_ptr := dispatch_table_ptr^.dispatch_table[code_ptr^.method_id + offset]
  else
    Error('interface method binding error');

  Set_static_link(code_ptr^.decl_static_link);
  Push_stack(code_ptr^.stack_frame_size);
end; {procedure Push_interface_frame}


procedure Push_proto_frame(stmt_ptr: stmt_ptr_type;
  var code_ptr: code_ptr_type);
var
  static_link: stack_index_type;
begin
  {********************************}
  { use implementation from memory }
  {********************************}
  Eval_proto(stmt_ptr^.stmt_name_ptr);
  static_link := Pop_stack_index_operand;
  code_ptr := code_ptr_type(Pop_code_operand);
  Push_stack_frame(static_link);

  if (code_ptr = nil) then
    Runtime_error('Can not execute nil subprogram.')
  else
    Push_stack(code_ptr^.stack_frame_size);
end; {procedure Push_proto_frame}


procedure Push_param_frame(stmt_ptr: stmt_ptr_type;
  var code_ptr: code_ptr_type);
begin
  {**********************}
  { push new stack frame }
  {**********************}
  case stmt_ptr^.kind of

    static_method_stmt:
      Push_static_frame(stmt_ptr, code_ptr);

    dynamic_method_stmt:
      Push_dynamic_frame(stmt_ptr, code_ptr);

    interface_method_stmt:
      Push_interface_frame(stmt_ptr, code_ptr);

    proto_method_stmt:
      Push_proto_frame(stmt_ptr, code_ptr);

  end; {case}
end; {procedure Push_param_frame}


procedure Assign_params(stmt_ptr: stmt_ptr_type);
var
  code_ptr: code_ptr_type;
begin
  returning_from := false;
  code_ptr := code_ptr_type(stmt_ptr^.stmt_code_ref);

  {*************************************************}
  { implicit parameter declarations and assignments }
  {*************************************************}
  if code_ptr^.implicit_param_decls_ptr <> nil then
    begin
      Interpret_decl(code_ptr^.implicit_param_decls_ptr);
      Interpret_stmts(stmt_ptr^.implicit_stmts_ptr);
    end;

  {************************************************}
  { initial parameter declarations and assignments }
  {************************************************}
  Interpret_decls(code_ptr^.initial_param_decls_ptr);
  Interpret_stmts(stmt_ptr^.param_assign_stmts_ptr);

  {*************************************************}
  { optional parameter declarations and assignments }
  {*************************************************}
  Interpret_decls(code_ptr^.optional_param_decls_ptr);
  Interpret_stmts(code_ptr^.optional_param_stmts_ptr);
  Interpret_stmts(stmt_ptr^.param_stmts_ptr);

  {*******************************}
  { return parameter declarations }
  {*******************************}
  Interpret_decls(code_ptr^.return_param_decls_ptr);
end; {procedure Assign_params}


procedure Interpret_procedure_stmt(stmt_ptr: stmt_ptr_type);
var
  code_ptr, last_code_ptr: code_ptr_type;
begin
  {*********************}
  { prepare stack frame }
  {*********************}
  Push_param_frame(stmt_ptr, code_ptr);
  Assign_params(stmt_ptr);

  {**********************}
  { begin new subprogram }
  {**********************}
  last_code_ptr := current_code_ptr;
  current_code_ptr := code_ptr;

  {********************}
  { execute statements }
  {********************}
  if code_ptr^.decl_kind = native_decl then
    Exec_native_method(code_ptr^.code_decl_ref^.code_data_decl.native_index)
  else
    begin
      Interpret_decls(code_ptr^.local_decls_ptr);
      Interpret_stmts(code_ptr^.local_stmts_ptr);
    end;

  {*****************************}
  { interpret return statements }
  {*****************************}
  returning_from := false;
  Interpret_stmts(stmt_ptr^.return_assign_stmts_ptr);
  Interpret_stmts(stmt_ptr^.return_stmts_ptr);

  {*******************}
  { ending subprogram }
  {*******************}
  current_code_ptr := last_code_ptr;
  returning_from := false;
  Interpret_stmts(code_ptr^.param_free_stmts_ptr);
  Pop_stack_frame;
end; {procedure Interpret_procedure_stmt}


procedure Interpret_destructor_stmt(code_ptr: code_ptr_type;
  memref: memref_type);
var
  last_code_ptr: code_ptr_type;
begin
  {*********************}
  { prepare stack frame }
  {*********************}
  Push_stack_frame(code_ptr^.decl_static_link);
  Push_stack(code_ptr^.stack_frame_size);
  Set_local_memref(1, memref);

  {**********************}
  { begin new subprogram }
  {**********************}
  last_code_ptr := current_code_ptr;
  current_code_ptr := code_ptr;

  {********************}
  { execute statements }
  {********************}
  Interpret_decls(code_ptr^.local_decls_ptr);
  Interpret_stmts(code_ptr^.local_stmts_ptr);

  {*****************************}
  { interpret return statements }
  {*****************************}
  returning_from := false;

  {*******************}
  { ending subprogram }
  {*******************}
  current_code_ptr := last_code_ptr;
  returning_from := false;
  Interpret_stmts(code_ptr^.param_free_stmts_ptr);
  Pop_stack_frame;
end; {procedure Interpret_destructor_stmt}


procedure Interpret_abstract_destructor_stmt(code_ptr: forward_code_ptr_type;
  memref: memref_type);
begin
  Interpret_destructor_stmt(code_ptr_type(code_ptr), memref);
end; {procedure Interpret_abstract_destructor_stmt}


procedure Interpret_object_stmt(stmt_ptr: stmt_ptr_type);
var
  code_ptr, last_code_ptr: code_ptr_type;
begin
  {**************************}
  { open new reference frame }
  {**************************}
  Save_model_context;

  {**********************}
  { save shader instance }
  {**********************}
  Save_shader_inst(stmt_ptr^.stmt_data_ptr);

  {*********************}
  { prepare stack frame }
  {*********************}
  Push_param_frame(stmt_ptr, code_ptr);
  Assign_params(stmt_ptr);

  {**********************}
  { begin new subprogram }
  {**********************}
  last_code_ptr := current_code_ptr;
  current_code_ptr := code_ptr;

  {***************}
  { create object }
  {***************}
  if code_ptr^.decl_kind = native_decl then
    Interpret_native_object(stmt_ptr, code_ptr)
  else
    Interpret_object(stmt_ptr, code_ptr);

  {*******************}
  { ending subprogram }
  {*******************}
  current_code_ptr := last_code_ptr;
  returning_from := false;
  Interpret_stmts(code_ptr^.param_free_stmts_ptr);
  Pop_stack_frame;

  {*****************************}
  { restore old reference frame }
  {*****************************}
  Restore_model_context;
end; {procedure Interpret_object_stmt}


procedure Interpret_picture_stmt(stmt_ptr: stmt_ptr_type);
var
  code_ptr, last_code_ptr: code_ptr_type;
begin
  {**************************}
  { open new reference frame }
  {**************************}
  Save_model_context;

  {*********************}
  { prepare stack frame }
  {*********************}
  Push_param_frame(stmt_ptr, code_ptr);
  Assign_params(stmt_ptr);

  {**********************}
  { begin new subprogram }
  {**********************}
  last_code_ptr := current_code_ptr;
  current_code_ptr := code_ptr;

  {************************}
  { open or switch windows }
  {************************}
  Open_picture_window(code_data_ptr_type(code_ptr^.code_data_ptr));

  {*********************}
  { create scene object }
  {*********************}
  Interpret_picture(stmt_ptr, code_ptr);

  {*******************}
  { ending subprogram }
  {*******************}
  current_code_ptr := last_code_ptr;
  returning_from := false;
  Interpret_stmts(code_ptr^.param_free_stmts_ptr);
  Pop_stack_frame;

  {******************}
  { finally, render! }
  {******************}
  Render_picture_window(code_data_ptr_type(code_ptr^.code_data_ptr));

  {*****************************}
  { restore old reference frame }
  {*****************************}
  Restore_model_context;
end; {procedure Interpret_picture_stmt}


procedure Interpret_anim_stmt(stmt_ptr: stmt_ptr_type);
var
  code_ptr, last_code_ptr: code_ptr_type;
begin
  Begin_anim_context;

  {*********************}
  { prepare stack frame }
  {*********************}
  Push_param_frame(stmt_ptr, code_ptr);
  Assign_params(stmt_ptr);

  {**********************}
  { begin new subprogram }
  {**********************}
  last_code_ptr := current_code_ptr;
  current_code_ptr := code_ptr;

  {****************************}
  { push local vars onto stack }
  {****************************}
  Interpret_decls(code_ptr^.local_decls_ptr);

  {********************}
  { execute statements }
  {********************}
  Interpret_stmts(code_ptr^.local_stmts_ptr);

  {*****************************}
  { interpret return statements }
  {*****************************}
  returning_from := false;
  Interpret_stmts(stmt_ptr^.return_assign_stmts_ptr);
  Interpret_stmts(stmt_ptr^.return_stmts_ptr);

  {*******************}
  { ending subprogram }
  {*******************}
  current_code_ptr := last_code_ptr;
  returning_from := false;
  Interpret_stmts(code_ptr^.param_free_stmts_ptr);
  Pop_stack_frame;

  End_anim_context;
end; {procedure Interpret_anim_stmt}


procedure Interpret_function_stmt(stmt_ptr: stmt_ptr_type);
var
  code_ptr, last_code_ptr: code_ptr_type;
begin
  {*********************}
  { prepare stack frame }
  {*********************}
  Push_param_frame(stmt_ptr, code_ptr);
  Assign_params(stmt_ptr);

  {**********************}
  { begin new subprogram }
  {**********************}
  last_code_ptr := current_code_ptr;
  current_code_ptr := code_ptr;

  {********************}
  { execute statements }
  {********************}
  if code_ptr^.decl_kind = native_decl then
    Exec_native_method(code_ptr^.code_decl_ref^.code_data_decl.native_index)
  else
    begin
      Interpret_decls(code_ptr^.local_decls_ptr);
      Interpret_stmts(code_ptr^.local_stmts_ptr);
    end;

  {*****************************}
  { interpret return statements }
  {*****************************}
  returning_from := false;
  Interpret_stmts(stmt_ptr^.return_assign_stmts_ptr);
  Interpret_stmts(stmt_ptr^.return_stmts_ptr);

  {*******************}
  { ending subprogram }
  {*******************}
  current_code_ptr := last_code_ptr;
  returning_from := false;
  Interpret_stmts(code_ptr^.param_free_stmts_ptr);
  Pop_stack_frame;
end; {procedure Interpret_function_stmt}


procedure Interpret_shader_stmt(stmt_ptr: stmt_ptr_type);
var
  code_ptr, last_code_ptr: code_ptr_type;
begin
  if Shaders_ok then
    begin
      {*********************}
      { prepare stack frame }
      {*********************}
      Push_param_frame(stmt_ptr, code_ptr);
      Assign_params(stmt_ptr);

      {**********************}
      { begin new subprogram }
      {**********************}
      last_code_ptr := current_code_ptr;
      current_code_ptr := code_ptr;

      {****************************}
      { push local vars onto stack }
      {****************************}
      Interpret_decls(code_ptr^.local_decls_ptr);

      {********************}
      { execute statements }
      {********************}
      Interpret_stmts(code_ptr^.local_stmts_ptr);

      {*******************}
      { ending subprogram }
      {*******************}
      current_code_ptr := last_code_ptr;
      returning_from := false;
      Interpret_stmts(code_ptr^.param_free_stmts_ptr);
      Pop_stack_frame;
    end
  else
    begin
      {**************************************}
      { return global color on operand stack }
      {**************************************}
      Push_vector_operand(Get_current_color);
    end;
end; {procedure Interpret_shader_stmt}


procedure Interpret_method_stmt(stmt_ptr: stmt_ptr_type);
var
  index: integer;
begin
  {*****************}
  { push call stack }
  {*****************}
  index := call_stack_height mod call_stack_size;
  call_stack[index].stmt_ptr := stmt_ptr;
  call_stack[index].code_ptr := current_code_ptr;
  call_stack_height := call_stack_height + 1;

  if debug then
    writeln('interpreting method ',
      Quotate_str(Get_method_name(code_ptr_type(stmt_ptr^.stmt_code_ref))));

  case code_ptr_type(stmt_ptr^.stmt_code_ref)^.kind of

    {****************************************}
    { interpret procedural method statements }
    {****************************************}
    procedure_code, constructor_code, destructor_code:
      Interpret_procedure_stmt(stmt_ptr);

    object_code:
      Interpret_object_stmt(stmt_ptr);

    picture_code:
      Interpret_picture_stmt(stmt_ptr);

    anim_code:
      Interpret_anim_stmt(stmt_ptr);

    {****************************************}
    { interpret functional method statements }
    {****************************************}
    function_code:
      Interpret_function_stmt(stmt_ptr);

    shader_code:
      Interpret_shader_stmt(stmt_ptr);

  end; {case}

  {****************}
  { pop call stack }
  {****************}
  call_stack_height := call_stack_height - 1;
  current_code_ptr := call_stack[index].code_ptr;
end; {procedure Interpret_method_stmt}


{**************************************************}
{ routines for preevaluating a shader's parameters }
{**************************************************}


procedure Pre_eval_boolean(var expr_ptr: expr_ptr_type);
begin
  if expr_ptr^.kind <> user_fn then
    begin
      Eval_boolean(expr_ptr);
      Destroy_expr(expr_ptr, true);

      if Pop_boolean_operand then
        expr_ptr := New_expr(true_val)
      else
        expr_ptr := New_expr(false_val);
    end
  else
    Pre_eval_method(stmt_ptr_type(expr_ptr^.fn_stmt_ptr));
end; {procedure Pre_eval_boolean}


procedure Pre_eval_char(var expr_ptr: expr_ptr_type);
begin
  if expr_ptr^.kind <> user_fn then
    begin
      Eval_char(expr_ptr);
      Destroy_expr(expr_ptr, true);
      expr_ptr := New_expr(char_lit);
      expr_ptr^.char_val := Pop_char_operand;
    end
  else
    Pre_eval_method(stmt_ptr_type(expr_ptr^.fn_stmt_ptr));
end; {procedure Pre_eval_char}


procedure Pre_eval_byte(var expr_ptr: expr_ptr_type);
begin
  if expr_ptr^.kind <> user_fn then
    begin
      Eval_byte(expr_ptr);
      Destroy_expr(expr_ptr, true);
      expr_ptr := New_expr(byte_lit);
      expr_ptr^.byte_val := Pop_byte_operand;
    end
  else
    Pre_eval_method(stmt_ptr_type(expr_ptr^.fn_stmt_ptr));
end; {procedure Pre_eval_byte}


procedure Pre_eval_short(var expr_ptr: expr_ptr_type);
begin
  if expr_ptr^.kind <> user_fn then
    begin
      Eval_short(expr_ptr);
      Destroy_expr(expr_ptr, true);
      expr_ptr := New_expr(short_lit);
      expr_ptr^.short_val := Pop_short_operand;
    end
  else
    Pre_eval_method(stmt_ptr_type(expr_ptr^.fn_stmt_ptr));
end; {procedure Pre_eval_short}


procedure Pre_eval_integer(var expr_ptr: expr_ptr_type);
begin
  if expr_ptr^.kind <> user_fn then
    begin
      Eval_integer(expr_ptr);
      Destroy_expr(expr_ptr, true);
      expr_ptr := New_expr(integer_lit);
      expr_ptr^.integer_val := Pop_integer_operand;
    end
  else
    Pre_eval_method(stmt_ptr_type(expr_ptr^.fn_stmt_ptr));
end; {procedure Pre_eval_integer}


procedure Pre_eval_long(var expr_ptr: expr_ptr_type);
begin
  if expr_ptr^.kind <> user_fn then
    begin
      Eval_long(expr_ptr);
      Destroy_expr(expr_ptr, true);
      expr_ptr := New_expr(long_lit);
      expr_ptr^.long_val := Pop_long_operand;
    end
  else
    Pre_eval_method(stmt_ptr_type(expr_ptr^.fn_stmt_ptr));
end; {procedure Pre_eval_long}


procedure Pre_eval_scalar(var expr_ptr: expr_ptr_type);
begin
  if expr_ptr^.kind <> user_fn then
    begin
      Eval_scalar(expr_ptr);
      Destroy_expr(expr_ptr, true);
      expr_ptr := New_expr(scalar_lit);
      expr_ptr^.scalar_val := Pop_scalar_operand;
    end
  else
    Pre_eval_method(stmt_ptr_type(expr_ptr^.fn_stmt_ptr));
end; {procedure Pre_eval_scalar}


procedure Pre_eval_double(var expr_ptr: expr_ptr_type);
begin
  if expr_ptr^.kind <> user_fn then
    begin
      Eval_double(expr_ptr);
      Destroy_expr(expr_ptr, true);
      expr_ptr := New_expr(double_lit);
      expr_ptr^.double_val := Pop_double_operand;
    end
  else
    Pre_eval_method(stmt_ptr_type(expr_ptr^.fn_stmt_ptr));
end; {procedure Pre_eval_double}


procedure Pre_eval_complex(var expr_ptr: expr_ptr_type);
begin
  if expr_ptr^.kind <> user_fn then
    begin
      Eval_complex(expr_ptr);
      Destroy_expr(expr_ptr, true);
      expr_ptr := New_expr(complex_lit);
      expr_ptr^.complex_val := Pop_complex_operand;
    end
  else
    Pre_eval_method(stmt_ptr_type(expr_ptr^.fn_stmt_ptr));
end; {procedure Pre_eval_complex}


procedure Pre_eval_vector(var expr_ptr: expr_ptr_type);
begin
  if expr_ptr^.kind <> user_fn then
    begin
      Eval_vector(expr_ptr);
      Destroy_expr(expr_ptr, true);
      expr_ptr := New_expr(vector_lit);
      expr_ptr^.vector_val := Pop_vector_operand;
    end
  else
    Pre_eval_method(stmt_ptr_type(expr_ptr^.fn_stmt_ptr));
end; {procedure Pre_eval_vector}


procedure Pre_eval_assign(stmt_ptr: stmt_ptr_type);
begin
  case stmt_ptr^.kind of

    {******************}
    { enumerated types }
    {******************}
    boolean_assign:
      Pre_eval_boolean(stmt_ptr^.rhs_expr_ptr);
    char_assign:
      Pre_eval_char(stmt_ptr^.rhs_expr_ptr);

    {***************}
    { integer types }
    {***************}
    byte_assign:
      Pre_eval_byte(stmt_ptr^.rhs_expr_ptr);
    short_assign:
      Pre_eval_short(stmt_ptr^.rhs_expr_ptr);
    integer_assign:
      Pre_eval_integer(stmt_ptr^.rhs_expr_ptr);
    long_assign:
      Pre_eval_long(stmt_ptr^.rhs_expr_ptr);

    {**************}
    { scalar types }
    {**************}
    scalar_assign:
      Pre_eval_scalar(stmt_ptr^.rhs_expr_ptr);
    double_assign:
      Pre_eval_double(stmt_ptr^.rhs_expr_ptr);
    complex_assign:
      Pre_eval_complex(stmt_ptr^.rhs_expr_ptr);
    vector_assign:
      Pre_eval_vector(stmt_ptr^.rhs_expr_ptr);

  end; {case}
end; {procedure Pre_eval_assign}


procedure Pre_eval_assigns(stmts_ptr: stmt_ptr_type);
begin
  while stmts_ptr <> nil do
    begin
      Pre_eval_assign(stmts_ptr);
      stmts_ptr := stmts_ptr^.next;
    end;
end; {procedure Pre_eval_assigns}


procedure Pre_eval_method(stmt_ptr: stmt_ptr_type);
var
  code_ptr, last_code_ptr: code_ptr_type;
begin
  {*********************}
  { prepare stack frame }
  {*********************}
  Push_param_frame(stmt_ptr, code_ptr);

  {**********************}
  { begin new subprogram }
  {**********************}
  last_code_ptr := current_code_ptr;
  current_code_ptr := code_ptr;

  {*******************************************}
  { Push parameters onto stack and initialize }
  {*******************************************}
  Interpret_decls(code_ptr^.initial_param_decls_ptr);

  {*********************************}
  { pre eval method's param assigns }
  {*********************************}
  Pre_eval_assigns(stmt_ptr^.param_assign_stmts_ptr);
  Interpret_stmts(stmt_ptr^.param_assign_stmts_ptr);

  {*********************************************}
  { interpret method decl's optional parameters }
  {*********************************************}
  Interpret_decls(code_ptr^.optional_param_decls_ptr);
  Interpret_stmts(code_ptr^.optional_param_stmts_ptr);

  {***********************************}
  { interpret method call's statments }
  {***********************************}
  Pre_eval_assigns(stmt_ptr^.param_stmts_ptr);
  Interpret_stmts(stmt_ptr^.param_stmts_ptr);

  {*******************}
  { ending subprogram }
  {*******************}
  current_code_ptr := last_code_ptr;
  returning_from := false;
  Interpret_stmts(code_ptr^.param_free_stmts_ptr);
  Pop_stack_frame;
end; {procedure Pre_eval_method}


procedure Make_method_data(decl_ptr: decl_ptr_type);
begin
  while (decl_ptr <> nil) do
    begin
      with decl_ptr^ do
        if kind in [type_decl, code_decl] then
          case kind of

            {*******************}
            { type declarations }
            {*******************}
            type_decl:
              begin
                with type_ptr_type(type_ptr)^ do
                  if kind = class_type then
                    begin
                      {***************************}
                      { init static vars of class }
                      {***************************}
                      Make_method_data(method_decls_ptr);
                      Make_method_data(member_decls_ptr);
                      Make_method_data(private_member_decls_ptr);
                      Make_method_data(class_decls_ptr);
                    end;
              end;

            {*************************}
            { subprogram declarations }
            {*************************}
            code_decl:
              begin
                with code_ptr_type(code_ptr)^ do
                  begin
                    if decl_kind <> native_decl then
                      if kind in [object_code, picture_code] then
                        begin
                          object_decl_count := object_decl_count + 1;
                          if kind = picture_code then
                            picture_decl_count := picture_decl_count + 1;
                          code_data_ptr :=
                            forward_code_data_ptr_type(New_code_data);
                        end;

                    Make_method_data(implicit_param_decls_ptr);
                    Make_method_data(initial_param_decls_ptr);
                    Make_method_data(optional_param_decls_ptr);
                    Make_method_data(local_decls_ptr);
                    Make_method_data(return_param_decls_ptr);
                  end;
              end;
          end; {case}

      decl_ptr := decl_ptr^.next;
    end;
end; {procedure Make_method_data}


procedure Free_method_params(decl_ptr: decl_ptr_type);
var
  code_ptr: code_ptr_type;
  code_data_ptr: code_data_ptr_type;
begin
  code_ptr := code_ptr_type(decl_ptr^.code_ptr);
  code_data_ptr := code_data_ptr_type(code_ptr^.code_data_ptr);
  Free_method_decl_data(code_data_ptr^.object_decl_id);
end; {procedure Free_method_params}


initialization
  {*******************}
  { init status flags }
  {*******************}
  returning_from := false;
  current_code_ptr := nil;
  call_stack_height := 0;
end.
