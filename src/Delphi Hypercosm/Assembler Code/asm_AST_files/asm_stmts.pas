unit asm_stmts;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              asm_stmts                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The asm_stmts module defines all of the statements      }
{       used in the mnemonic assembly code, the external        }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  stmts, asms;


{************************************************}
{ routines for making and referencing statements }
{************************************************}
procedure Make_new_asm_stmts(count: asm_index_type);
function New_asm_stmt(kind: stmt_kind_type): stmt_ptr_type;
function Ref_asm_stmt(index: asm_index_type): stmt_ref_type;

{*****************************************************}
{ routines to assemble statements from assembly codes }
{*****************************************************}
function Assemble_stmt: stmt_ptr_type;
function Assemble_stmts: stmt_ptr_type;

{********************************************************}
{ routines to disassemble statements into assembly codes }
{********************************************************}
procedure Disassemble_stmt(var outfile: text;
  stmt_ptr: stmt_ptr_type);
procedure Disassemble_stmts(var outfile: text;
  stmt_ptr: stmt_ptr_type);

{****************************************}
{ functions returning assembler progress }
{****************************************}
function Stmts_assembled: asm_index_type;
function Stmts_disassembled: asm_index_type;


implementation
uses
  new_memory, hashtables, code_types, decl_attributes, exprs, instructs, decls,
  code_decls, type_decls, asm_bounds, asm_subranges, asm_exprs, asm_instructs,
  asm_decls, asm_code_decls, asm_type_decls;


const
  memory_alert = false;


type
  stmt_mnemonic_array_type = array[stmt_kind_type] of mnemonic_type;


var
  stmt_mnemonic_array: stmt_mnemonic_array_type;
  hashtable_ptr: hashtable_ptr_type;
  stmt_asm_count, stmt_disasm_count: asm_index_type;
  stmt_block_ptr: stmt_ptr_type;
  stmt_block_count: asm_index_type;


procedure Make_stmt_mnemonic(kind: stmt_kind_type;
  mnemonic: mnemonic_type);
var
  value: hashtable_value_type;
begin
  value := ord(kind);
  if Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    begin
      writeln('Error - duplicate stmt mnemonic found for ');
      Write_stmt_kind(kind);
      writeln;
    end
  else
    begin
      Enter_hashtable(hashtable_ptr, mnemonic, value);
      stmt_mnemonic_array[kind] := mnemonic;
    end;
end; {procedure Make_stmt_mnemonic}


procedure Make_stmt_mnemonics;
var
  stmt_kind: stmt_kind_type;
begin
  hashtable_ptr := New_hashtable;

  {*************************************}
  { initialize statement mnemonic array }
  {*************************************}
  for stmt_kind := null_stmt to proto_method_stmt do
    stmt_mnemonic_array[stmt_kind] := '';

  {***********************}
  { null or nop statement }
  {***********************}
  Make_stmt_mnemonic(null_stmt, 'nop');

  {***************************************************************}
  {                     assignment statements                     }
  {***************************************************************}

  {**********************************}
  { enumerated assignment statements }
  {**********************************}
  Make_stmt_mnemonic(boolean_assign, 'bla');
  Make_stmt_mnemonic(char_assign, 'cha');

  {*******************************}
  { integer assignment statements }
  {*******************************}
  Make_stmt_mnemonic(byte_assign, 'bya');
  Make_stmt_mnemonic(short_assign, 'sha');
  Make_stmt_mnemonic(integer_assign, 'ina');
  Make_stmt_mnemonic(long_assign, 'lga');

  {******************************}
  { scalar assignment statements }
  {******************************}
  Make_stmt_mnemonic(scalar_assign, 'sca');
  Make_stmt_mnemonic(double_assign, 'dba');
  Make_stmt_mnemonic(complex_assign, 'cma');
  Make_stmt_mnemonic(vector_assign, 'vca');

  {*********************************}
  { reference assignment statements }
  {*********************************}
  Make_stmt_mnemonic(array_ptr_assign, 'apa');
  Make_stmt_mnemonic(struct_ptr_assign, 'spa');
  Make_stmt_mnemonic(proto_assign, 'pra');
  Make_stmt_mnemonic(reference_assign, 'rfa');

  {***************************************************************}
  {                  array assignment statements                  }
  {***************************************************************}

  {**********************************}
  { enumerated assignment statements }
  {**********************************}
  Make_stmt_mnemonic(boolean_array_assign, 'baa');
  Make_stmt_mnemonic(char_array_assign, 'caa');

  {*******************************}
  { integer assignment statements }
  {*******************************}
  Make_stmt_mnemonic(byte_array_assign, 'yaa');
  Make_stmt_mnemonic(short_array_assign, 'haa');
  Make_stmt_mnemonic(integer_array_assign, 'iaa');
  Make_stmt_mnemonic(long_array_assign, 'laa');

  {******************************}
  { scalar assignment statements }
  {******************************}
  Make_stmt_mnemonic(scalar_array_assign, 'faa');
  Make_stmt_mnemonic(double_array_assign, 'daa');
  Make_stmt_mnemonic(complex_array_assign, 'xaa');
  Make_stmt_mnemonic(vector_array_assign, 'vaa');

  {*********************************}
  { reference assignment statements }
  {*********************************}
  Make_stmt_mnemonic(array_array_assign, 'aaa');
  Make_stmt_mnemonic(struct_array_assign, 'saa');
  Make_stmt_mnemonic(static_struct_array_assign, 'taa');
  Make_stmt_mnemonic(proto_array_assign, 'paa');
  Make_stmt_mnemonic(reference_array_assign, 'raa');

  {********************************}
  { subarray assignment statements }
  {********************************}
  Make_stmt_mnemonic(subarray_assign, 'sba');

  {***************************************************************}
  {             array expression assignment statements            }
  {***************************************************************}

  {****************************************}
  { enumerated array assignment statements }
  {****************************************}
  Make_stmt_mnemonic(boolean_array_expr_assign, 'bxa');
  Make_stmt_mnemonic(char_array_expr_assign, 'cxa');

  {*************************************}
  { integer array assignment statements }
  {*************************************}
  Make_stmt_mnemonic(byte_array_expr_assign, 'yxa');
  Make_stmt_mnemonic(short_array_expr_assign, 'hxa');
  Make_stmt_mnemonic(integer_array_expr_assign, 'ixa');
  Make_stmt_mnemonic(long_array_expr_assign, 'lxa');

  {************************************}
  { scalar array assignment statements }
  {************************************}
  Make_stmt_mnemonic(scalar_array_expr_assign, 'fxa');
  Make_stmt_mnemonic(double_array_expr_assign, 'dxa');
  Make_stmt_mnemonic(complex_array_expr_assign, 'xxa');
  Make_stmt_mnemonic(vector_array_expr_assign, 'vxa');

  {***************************************}
  { reference array assignment statements }
  {***************************************}
  Make_stmt_mnemonic(array_array_expr_assign, 'axa');
  Make_stmt_mnemonic(struct_array_expr_assign, 'sxa');
  Make_stmt_mnemonic(static_struct_array_expr_assign, 'txa');
  Make_stmt_mnemonic(proto_array_expr_assign, 'pxa');
  Make_stmt_mnemonic(reference_array_expr_assign, 'rxa');

  {********************************}
  { subarray assignment statements }
  {********************************}
  Make_stmt_mnemonic(subarray_expr_assign, 'sbx');

  {***************************************************************}
  {                structure assignment statements                }
  {***************************************************************}

  {******************************}
  { struct assignment statements }
  {******************************}
  Make_stmt_mnemonic(struct_assign, 'ras');
  Make_stmt_mnemonic(struct_base_assign, 'sbs');
  Make_stmt_mnemonic(struct_expr_assign, 'sea');
  Make_stmt_mnemonic(struct_expr_ptr_assign, 'sxp');

  {***************************************************************}
  {                        logical statements                     }
  {***************************************************************}

  {************************}
  { conditional statements }
  {************************}
  Make_stmt_mnemonic(if_then_else, 'ift');
  Make_stmt_mnemonic(case_char_stmt, 'ccs');
  Make_stmt_mnemonic(case_enum_stmt, 'ces');

  {********************}
  { looping statements }
  {********************}
  Make_stmt_mnemonic(while_loop, 'wle');
  Make_stmt_mnemonic(for_loop, 'for');
  Make_stmt_mnemonic(for_each, 'foe');
  Make_stmt_mnemonic(for_each_loop, 'flp');
  Make_stmt_mnemonic(for_each_list, 'fel');

  {***************************************************************}
  {                        control statements                     }
  {***************************************************************}

  {**************************}
  { loop breaking statements }
  {**************************}
  Make_stmt_mnemonic(break_stmt, 'brk');
  Make_stmt_mnemonic(continue_stmt, 'ctu');
  Make_stmt_mnemonic(loop_label_stmt, 'lbl');
  Make_stmt_mnemonic(return_stmt, 'rtn');
  Make_stmt_mnemonic(exit_stmt, 'xit');

  {***************************************}
  { enumerated function return statements }
  {***************************************}
  Make_stmt_mnemonic(boolean_answer, 'rtb');
  Make_stmt_mnemonic(char_answer, 'rtc');

  {************************************}
  { integer function return statements }
  {************************************}
  Make_stmt_mnemonic(byte_answer, 'rty');
  Make_stmt_mnemonic(short_answer, 'rth');
  Make_stmt_mnemonic(integer_answer, 'rti');
  Make_stmt_mnemonic(long_answer, 'rtl');

  {***********************************}
  { scalar function return statements }
  {***********************************}
  Make_stmt_mnemonic(scalar_answer, 'rts');
  Make_stmt_mnemonic(double_answer, 'rtd');
  Make_stmt_mnemonic(complex_answer, 'rtx');
  Make_stmt_mnemonic(vector_answer, 'rtv');

  {**************************************}
  { reference function return statements }
  {**************************************}
  Make_stmt_mnemonic(array_ptr_answer, 'rta');
  Make_stmt_mnemonic(struct_ptr_answer, 'rtt');
  Make_stmt_mnemonic(proto_answer, 'rtp');
  Make_stmt_mnemonic(reference_answer, 'rtr');

  {********************}
  { scoping statements }
  {********************}
  Make_stmt_mnemonic(with_stmt, 'wth');

  {***************************************************************}
  {                    memory allocation statements               }
  {***************************************************************}

  {***************************************}
  { memory explicit allocation statements }
  {***************************************}
  Make_stmt_mnemonic(dim_stmt, 'dst');
  Make_stmt_mnemonic(new_struct_stmt, 'nss');

  {********************************}
  { memory reallocation statements }
  {********************************}
  Make_stmt_mnemonic(redim_stmt, 'rdm');
  Make_stmt_mnemonic(renew_struct_stmt, 'rnw');

  {********************************}
  { memory deallocation statements }
  {********************************}
  Make_stmt_mnemonic(implicit_free_array_stmt, 'ifa');
  Make_stmt_mnemonic(implicit_free_struct_stmt, 'ifs');
  Make_stmt_mnemonic(implicit_free_reference_stmt, 'ifr');
  Make_stmt_mnemonic(implicit_free_params_stmt, 'ifp');

  {***************************************************************}
  {                      subprogram call statements               }
  {***************************************************************}

  {*********************}
  { built in statements }
  {*********************}
  Make_stmt_mnemonic(built_in_stmt, 'bis');

  {********************}
  { complex statements }
  {********************}
  Make_stmt_mnemonic(static_method_stmt, 'sms');
  Make_stmt_mnemonic(dynamic_method_stmt, 'dms');
  Make_stmt_mnemonic(interface_method_stmt, 'ims');
  Make_stmt_mnemonic(proto_method_stmt, 'pms');
end; {procedure Make_stmt_mnemonics}


{************************************************}
{ routines for making and referencing statements }
{************************************************}


procedure Make_new_asm_stmts(count: asm_index_type);
var
  stmt_block_size: longint;
begin
  if count > 0 then
    begin
      {*************************}
      { compute stmt block size }
      {*************************}
      stmt_block_size := longint(count + 1) * sizeof(stmt_type);

      {*********************}
      { allocate stmt block }
      {*********************}
      if memory_alert then
        writeln('allocating new stmt block');
      stmt_block_ptr := stmt_ptr_type(New_ptr(stmt_block_size));
      stmt_block_count := count;
    end;
end; {procedure Make_new_asm_stmts}


function New_asm_stmt(kind: stmt_kind_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  stmt_asm_count := stmt_asm_count + 1;
  stmt_ptr := Ref_asm_stmt(stmt_asm_count);
  Init_stmt(stmt_ptr, kind);
  stmt_ptr^.stmt_index := stmt_asm_count;
  New_asm_stmt := stmt_ptr;
end; {function New_asm_stmt}


function Ref_asm_stmt(index: asm_index_type): stmt_ptr_type;
begin
  if index > stmt_block_count then
    Asm_error;
  Ref_asm_stmt := stmt_ptr_type(longint(stmt_block_ptr) + sizeof(stmt_type) *
    (index - 1));
end; {function Ref_asm_stmt}


{**********************************************************}
{ routines to covert between assembly codes and statements }
{**********************************************************}


function Stmt_kind_to_mnemonic(kind: stmt_kind_type): mnemonic_type;
begin
  Stmt_kind_to_mnemonic := stmt_mnemonic_array[kind];
end; {function Stmt_kind_to_mnemonic}


function Mnemonic_to_stmt_kind(mnemonic: mnemonic_type): stmt_kind_type;
var
  value: hashtable_value_type;
begin
  if not Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    Asm_error;
  Mnemonic_to_stmt_kind := stmt_kind_type(value);
end; {function Mnemonic_to_stmt_kind}


{*****************************************************}
{ routines to assemble statements from assembly codes }
{*****************************************************}


function Assemble_case_constant(switch_array_ptr: switch_array_ptr_type):
  case_constant_ptr_type;
var
  case_constant_ptr: case_constant_ptr_type;
  switch_case_ptr: switch_case_ptr_type;
  mnemonic: mnemonic_type;
begin
  mnemonic := Assemble_mnemonic;
  if mnemonic <> 'nil' then
    begin
      {***************************}
      { disassemble case mnemonic }
      {***************************}
      if mnemonic = 'cse' then
        begin
          case_constant_ptr := New_case_constant;

          {***************************}
          { disassemble case operands }
          {***************************}
          case_constant_ptr^.value := Assemble_integer;
          switch_case_ptr := New_switch_case;
          switch_array_ptr^.switch_case_array[case_constant_ptr^.value] :=
            switch_case_ptr;
          with switch_case_ptr^ do
            begin
              case_decls_ptr := forward_decl_ptr_type(Assemble_decls);
              case_stmts_ptr := Assemble_stmts;
            end;
        end
      else
        begin
          Asm_error;
          case_constant_ptr := nil;
        end;
    end
  else
    case_constant_ptr := nil;

  Assemble_case_constant := case_constant_ptr;
end; {function Assemble_case_constant}


function Assemble_case_constants(switch_array_ptr: switch_array_ptr_type):
  case_constant_ptr_type;
var
  case_constant_ptr, last_case_constant_ptr: case_constant_ptr_type;
begin
  case_constant_ptr := Assemble_case_constant(switch_array_ptr);
  last_case_constant_ptr := case_constant_ptr;

  while (last_case_constant_ptr <> nil) do
    begin
      last_case_constant_ptr^.next := Assemble_case_constant(switch_array_ptr);
      last_case_constant_ptr := last_case_constant_ptr^.next;
    end;

  Assemble_case_constants := case_constant_ptr;
end; {function Assemble_case_constants}


procedure Set_copyable_class(type_ptr: type_ptr_type);
begin
  if type_ptr <> nil then
    if not type_ptr^.copyable then
      begin
        if type_ptr^.member_decls_ptr <> nil then
          type_ptr^.copyable := true;
        Set_copyable_class(type_ptr^.parent_class_ref);
      end;
end; {procedure Set_copyable_class}


procedure Assemble_stmt_fields(stmt_ptr: stmt_ptr_type);
var
  shader_stmt_ptr: stmt_ptr_type;
begin
  with stmt_ptr^ do
    case stmt_ptr^.kind of

      {***********************}
      { null or nop statement }
      {***********************}
      null_stmt:
        ;

      {******************************}
      { simple assignment statements }
      {******************************}
      boolean_assign..reference_assign:
        begin
          if stmt_ptr^.kind in [reference_assign, proto_assign] then
            static_level := Assemble_integer;
          lhs_data_ptr := Assemble_expr;
          rhs_expr_ptr := Assemble_expr;
        end;

      {*****************************}
      { array assignment statements }
      {*****************************}
      boolean_array_assign..reference_array_assign:
        begin
          lhs_array_subrange_ptr := Assemble_array_subrange;
          rhs_array_subrange_ptr := Assemble_array_subrange;
          array_assign_bounds_list_ref := Assemble_array_bounds_list;
          array_assign_stmt_ptr := Assemble_stmt;

          {******************************************************}
          { structure array implicit allocation / initialization }
          {******************************************************}
          if kind = struct_array_assign then
            array_struct_new_ptr := Assemble_expr

            {************************************************}
            { static structure array implicit initialization }
            {************************************************}
          else if kind = static_struct_array_assign then
            array_static_struct_type_ref :=
              forward_type_ref_type(Assemble_type);
        end;
      subarray_assign:
        begin
          lhs_subarray_subrange_ptr := Assemble_array_subrange;
          rhs_subarray_subrange_ptr := Assemble_array_subrange;
          subarray_assign_stmt_ptr := Assemble_stmt;
        end;

      {****************************************}
      { array expression assignment statements }
      {****************************************}
      boolean_array_expr_assign..reference_array_expr_assign:
        begin
          array_expr_subrange_ptr := Assemble_array_subrange;
          array_expr_element_ref := Assemble_expr;
          array_expr_bounds_list_ref := Assemble_array_bounds_list;
          array_expr_assign_stmt_ptr := Assemble_stmt;

          {******************************************************}
          { structure array implicit allocation / initialization }
          {******************************************************}
          if kind = struct_array_expr_assign then
            array_expr_struct_new_ptr := Assemble_expr

            {************************************************}
            { static structure array implicit initialization }
            {************************************************}
          else if kind = static_struct_array_expr_assign then
            array_expr_static_struct_type_ref :=
              forward_type_ref_type(Assemble_type);
        end;
      subarray_expr_assign:
        begin
          subarray_expr_subrange_ptr := Assemble_array_subrange;
          subarray_expr_element_ref := Assemble_expr;
          subarray_expr_assign_stmt_ptr := Assemble_stmt;
        end;

      {******************************}
      { struct assignment statements }
      {******************************}
      struct_assign:
        begin
          lhs_struct_expr_ptr := Assemble_expr;
          rhs_struct_expr_ptr := Assemble_expr;
          assign_struct_type_ref := forward_type_ref_type(Assemble_type);
          if type_ptr_type(assign_struct_type_ref)^.kind = class_type then
            Set_copyable_class(type_ptr_type(assign_struct_type_ref));
        end;
      struct_base_assign:
        begin
          lhs_struct_base_ptr := Assemble_expr;
          rhs_struct_base_ptr := Assemble_expr;
          parent_base_assign_ref := Assemble_stmt;
          field_assign_stmts_ptr := Assemble_stmts;
        end;
      struct_expr_assign, struct_expr_ptr_assign:
        ;

      {************************}
      { conditional statements }
      {************************}
      if_then_else:
        begin
          if_expr_ptr := Assemble_expr;
          then_decls_ptr := forward_decl_ptr_type(Assemble_decls);
          then_stmts_ptr := Assemble_stmts;
          else_decls_ptr := forward_decl_ptr_type(Assemble_decls);
          else_stmts_ptr := Assemble_stmts;
        end;
      case_char_stmt, case_enum_stmt:
        begin
          switch_expr_ptr := Assemble_expr;
          switch_array_ptr := New_switch_array;
          switch_case_constant_ptr := Assemble_case_constants(switch_array_ptr);
          switch_else_decls_ptr := forward_decl_ptr_type(Assemble_decls);
          switch_else_stmts_ptr := Assemble_stmts;
        end;

      {********************}
      { looping statements }
      {********************}
      while_loop:
        begin
          while_expr_ptr := Assemble_expr;
          while_decls_ptr := forward_decl_ptr_type(Assemble_decls);
          while_stmts_ptr := Assemble_stmts;
        end;
      for_loop:
        begin
          counter_decl_ptr := forward_decl_ptr_type(Assemble_decl);
          start_expr_ptr := Assemble_expr;
          end_expr_ptr := Assemble_expr;
          for_decls_ptr := forward_decl_ptr_type(Assemble_decls);
          for_stmts_ptr := Assemble_stmts;
        end;
      for_each:
        begin
          each_stmts_ptr := Assemble_stmts;
          each_index_decl_ptr := forward_decl_ptr_type(Assemble_decl);
          each_array_ptr := Assemble_expr;
          each_decls_ptr := forward_decl_ptr_type(Assemble_decls);
        end;
      for_each_loop:
        begin
          loop_stmts_ptr := Assemble_stmts;
          for_each_array_subrange_ptr := Assemble_array_subrange;
        end;
      for_each_list:
        begin
          each_struct_decl_ptr := forward_decl_ptr_type(Assemble_decl);
          each_next_expr_ptr := Assemble_expr;
          each_list_expr_ptr := Assemble_expr;
          list_decls_ptr := forward_decl_ptr_type(Assemble_decls);
          list_stmts_ptr := Assemble_stmts;
        end;

      {**************************}
      { loop breaking statements }
      {**************************}
      break_stmt, continue_stmt:
        enclosing_loop_ref := Assemble_stmt;
      loop_label_stmt:
        loop_stmt_ptr := Assemble_stmt;
      return_stmt, exit_stmt:
        ;
      boolean_answer..reference_answer:
        answer_expr_ptr := Assemble_expr;

      {********************}
      { scoping statements }
      {********************}
      with_stmt:
        begin
          with_expr_ptr := Assemble_expr;
          with_decls_ptr := forward_decl_ptr_type(Assemble_decls);
          with_stmts_ptr := Assemble_stmts;
        end;

      {******************************}
      { memory allocation statements }
      {******************************}
      dim_stmt, redim_stmt:
        begin
          dim_data_ptr := Assemble_expr;
          dim_expr_ptr := Assemble_expr;
        end;
      new_struct_stmt, renew_struct_stmt:
        begin
          new_data_ptr := Assemble_expr;
          new_expr_ptr := Assemble_expr;
        end;

      {***************************}
      { memory deallocation stmts }
      {***************************}
      implicit_free_array_stmt:
        free_array_expr_ref := Assemble_expr;
      implicit_free_struct_stmt:
        free_struct_expr_ref := Assemble_expr;
      implicit_free_reference_stmt:
        free_reference_expr_ref := Assemble_expr;
      implicit_free_params_stmt:
        free_decl_ref := forward_decl_ref_type(Assemble_decl);

      {*********************}
      { built in statements }
      {*********************}
      built_in_stmt:
        instruct_ptr := Assemble_instruct;

      {********************************}
      { user defined method statements }
      {********************************}
      static_method_stmt, dynamic_method_stmt, interface_method_stmt,
        proto_method_stmt:
        begin
          stmt_code_ref := forward_code_ref_type(Assemble_code);
          stmt_name_ptr := Assemble_expr;

          implicit_stmts_ptr := Assemble_stmts;
          param_assign_stmts_ptr := Assemble_stmts;
          param_stmts_ptr := Assemble_stmts;

          return_assign_stmts_ptr := Assemble_stmts;
          return_stmts_ptr := Assemble_stmts;

          {**************************}
          { optional shader statment }
          {**************************}
          if code_ref_type(stmt_code_ref)^.kind = object_code then
            begin
              shader_stmt_ptr := Assemble_stmt;
              if shader_stmt_ptr <> nil then
                begin
                  stmt_data_ptr := New_stmt_data;
                  stmt_data_ptr^.shader_stmt_ptr := shader_stmt_ptr;
                end;
            end;
        end;

    end; {case}
end; {procedure Assemble_stmt_fields}


function Assemble_stmt: stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
  mnemonic: mnemonic_type;
begin
  {*****************************}
  { assemble statement mnemonic }
  {*****************************}
  mnemonic := Assemble_mnemonic;

  if mnemonic <> 'nil' then
    begin
      {******************************}
      { assemble statement reference }
      {******************************}
      if mnemonic = 'srf' then
        stmt_ptr := Ref_asm_stmt(Assemble_index)

        {********************}
        { assemble statement }
        {********************}
      else
        begin
          stmt_ptr := New_asm_stmt(Mnemonic_to_stmt_kind(mnemonic));
          Assemble_stmt_fields(stmt_ptr);
        end;
    end
  else
    stmt_ptr := nil;

  Assemble_stmt := stmt_ptr;
end; {function Assemble_stmt}


function Assemble_stmts: stmt_ptr_type;
var
  stmt_ptr, last_stmt_ptr: stmt_ptr_type;
begin
  stmt_ptr := Assemble_stmt;
  last_stmt_ptr := stmt_ptr;

  while (last_stmt_ptr <> nil) do
    begin
      last_stmt_ptr^.next := Assemble_stmt;
      last_stmt_ptr := last_stmt_ptr^.next;
    end;

  Assemble_stmts := stmt_ptr;
end; {function Assemble_stmts}


{********************************************************}
{ routines to disassemble statements into assembly codes }
{********************************************************}


procedure Disassemble_case_constant(var outfile: text;
  case_constant_ptr: case_constant_ptr_type;
  switch_array_ptr: switch_array_ptr_type);
begin
  if case_constant_ptr <> nil then
    begin
      {***************************}
      { disassemble case mnemonic }
      {***************************}
      Disassemble_mnemonic(outfile, 'cse');

      {***************************}
      { disassemble case operands }
      {***************************}
      Disassemble_integer(outfile, case_constant_ptr^.value);
      with switch_array_ptr^.switch_case_array[case_constant_ptr^.value]^ do
        begin
          Disassemble_decls(outfile, decl_ptr_type(case_decls_ptr));
          Disassemble_stmts(outfile, case_stmts_ptr);
        end;
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_case_constant}


procedure Disassemble_case_constants(var outfile: text;
  case_constant_ptr: case_constant_ptr_type;
  switch_array_ptr: switch_array_ptr_type);
begin
  while (case_constant_ptr <> nil) do
    begin
      Disassemble_case_constant(outfile, case_constant_ptr, switch_array_ptr);
      case_constant_ptr := case_constant_ptr^.next;
    end;
  Disassemble_case_constant(outfile, nil, switch_array_ptr);
end; {procedure Disassemble_case_constants}


procedure Disassemble_stmt_fields(var outfile: text;
  stmt_ptr: stmt_ptr_type);
begin
  with stmt_ptr^ do
    case stmt_ptr^.kind of

      {***********************}
      { null or nop statement }
      {***********************}
      null_stmt:
        ;

      {******************************}
      { simple assignment statements }
      {******************************}
      boolean_assign..reference_assign:
        begin
          if stmt_ptr^.kind in [reference_assign, proto_assign] then
            Disassemble_integer(outfile, static_level);
          Disassemble_expr(outfile, lhs_data_ptr);
          Disassemble_expr(outfile, rhs_expr_ptr);
        end;

      {*****************************}
      { array assignment statements }
      {*****************************}
      boolean_array_assign..reference_array_assign:
        begin
          Disassemble_array_subrange(outfile, lhs_array_subrange_ptr);
          Disassemble_array_subrange(outfile, rhs_array_subrange_ptr);
          Disassemble_array_bounds_list(outfile, array_assign_bounds_list_ref);
          Disassemble_stmt(outfile, array_assign_stmt_ptr);

          {******************************************************}
          { structure array implicit allocation / initialization }
          {******************************************************}
          if kind = struct_array_assign then
            Disassemble_expr(outfile, array_struct_new_ptr)

            {************************************************}
            { static structure array implicit initialization }
            {************************************************}
          else if kind = static_struct_array_assign then
            Disassemble_type(outfile,
              type_ptr_type(array_static_struct_type_ref));
        end;
      subarray_assign:
        begin
          Disassemble_array_subrange(outfile, lhs_subarray_subrange_ptr);
          Disassemble_array_subrange(outfile, rhs_subarray_subrange_ptr);
          Disassemble_stmt(outfile, subarray_assign_stmt_ptr);
        end;

      {****************************************}
      { array expression assignment statements }
      {****************************************}
      boolean_array_expr_assign..reference_array_expr_assign:
        begin
          Disassemble_array_subrange(outfile, array_expr_subrange_ptr);
          Disassemble_expr(outfile, array_expr_element_ref);
          Disassemble_array_bounds_list(outfile, array_expr_bounds_list_ref);
          Disassemble_stmt(outfile, array_expr_assign_stmt_ptr);

          {******************************************************}
          { structure array implicit allocation / initialization }
          {******************************************************}
          if kind = struct_array_expr_assign then
            Disassemble_expr(outfile, array_expr_struct_new_ptr)

            {************************************************}
            { static structure array implicit initialization }
            {************************************************}
          else if kind = static_struct_array_expr_assign then
            Disassemble_type(outfile,
              type_ptr_type(array_expr_static_struct_type_ref));
        end;
      subarray_expr_assign:
        begin
          Disassemble_array_subrange(outfile, subarray_expr_subrange_ptr);
          Disassemble_expr(outfile, subarray_expr_element_ref);
          Disassemble_stmt(outfile, subarray_expr_assign_stmt_ptr);
        end;

      {******************************}
      { struct assignment statements }
      {******************************}
      struct_assign:
        begin
          Disassemble_expr(outfile, lhs_struct_expr_ptr);
          Disassemble_expr(outfile, rhs_struct_expr_ptr);
          Disassemble_type(outfile, type_ptr_type(assign_struct_type_ref));
        end;
      struct_base_assign:
        begin
          Disassemble_expr(outfile, lhs_struct_base_ptr);
          Disassemble_expr(outfile, rhs_struct_base_ptr);
          Disassemble_stmt(outfile, parent_base_assign_ref);
          Disassemble_stmts(outfile, field_assign_stmts_ptr);
        end;
      struct_expr_assign, struct_expr_ptr_assign:
        ;

      {************************}
      { conditional statements }
      {************************}
      if_then_else:
        begin
          Disassemble_expr(outfile, if_expr_ptr);
          Disassemble_decls(outfile, decl_ptr_type(then_decls_ptr));
          Disassemble_stmts(outfile, then_stmts_ptr);
          Disassemble_decls(outfile, decl_ptr_type(else_decls_ptr));
          Disassemble_stmts(outfile, else_stmts_ptr);
        end;
      case_char_stmt, case_enum_stmt:
        begin
          Disassemble_expr(outfile, switch_expr_ptr);
          Disassemble_case_constants(outfile, switch_case_constant_ptr,
            switch_array_ptr);
          Disassemble_decls(outfile, decl_ptr_type(switch_else_decls_ptr));
          Disassemble_stmts(outfile, switch_else_stmts_ptr);
        end;

      {********************}
      { looping statements }
      {********************}
      while_loop:
        begin
          Disassemble_expr(outfile, while_expr_ptr);
          Disassemble_decls(outfile, decl_ptr_type(while_decls_ptr));
          Disassemble_stmts(outfile, while_stmts_ptr);
        end;
      for_loop:
        begin
          Disassemble_decl(outfile, decl_ptr_type(counter_decl_ptr));
          Disassemble_expr(outfile, start_expr_ptr);
          Disassemble_expr(outfile, end_expr_ptr);
          Disassemble_decls(outfile, decl_ptr_type(for_decls_ptr));
          Disassemble_stmts(outfile, for_stmts_ptr);
        end;
      for_each:
        begin
          Disassemble_stmts(outfile, each_stmts_ptr);
          Disassemble_decl(outfile, decl_ptr_type(each_index_decl_ptr));
          Disassemble_expr(outfile, each_array_ptr);
          Disassemble_decls(outfile, decl_ptr_type(each_decls_ptr));
        end;
      for_each_loop:
        begin
          Disassemble_stmts(outfile, loop_stmts_ptr);
          Disassemble_array_subrange(outfile, for_each_array_subrange_ptr);
        end;
      for_each_list:
        begin
          Disassemble_decl(outfile, decl_ptr_type(each_struct_decl_ptr));
          Disassemble_expr(outfile, each_next_expr_ptr);
          Disassemble_expr(outfile, each_list_expr_ptr);
          Disassemble_decls(outfile, decl_ptr_type(list_decls_ptr));
          Disassemble_stmts(outfile, list_stmts_ptr);
        end;

      {**************************}
      { loop breaking statements }
      {**************************}
      break_stmt, continue_stmt:
        Disassemble_stmt(outfile, enclosing_loop_ref);
      loop_label_stmt:
        Disassemble_stmt(outfile, loop_stmt_ptr);
      return_stmt, exit_stmt:
        ;
      boolean_answer..reference_answer:
        Disassemble_expr(outfile, answer_expr_ptr);

      {********************}
      { scoping statements }
      {********************}
      with_stmt:
        begin
          Disassemble_expr(outfile, with_expr_ptr);
          Disassemble_decls(outfile, decl_ptr_type(with_decls_ptr));
          Disassemble_stmts(outfile, with_stmts_ptr);
        end;

      {******************************}
      { memory allocation statements }
      {******************************}
      dim_stmt, redim_stmt:
        begin
          Disassemble_expr(outfile, dim_data_ptr);
          Disassemble_expr(outfile, dim_expr_ptr);
        end;
      new_struct_stmt, renew_struct_stmt:
        begin
          Disassemble_expr(outfile, new_data_ptr);
          Disassemble_expr(outfile, new_expr_ptr);
        end;

      {********************************}
      { memory deallocation statements }
      {********************************}
      implicit_free_array_stmt:
        Disassemble_expr(outfile, free_array_expr_ref);
      implicit_free_struct_stmt:
        Disassemble_expr(outfile, free_struct_expr_ref);
      implicit_free_reference_stmt:
        Disassemble_expr(outfile, free_reference_expr_ref);
      implicit_free_params_stmt:
        Disassemble_decl(outfile, decl_ref_type(free_decl_ref));

      {*********************}
      { built in statements }
      {*********************}
      built_in_stmt:
        Disassemble_instruct(outfile, instruct_ptr_type(instruct_ptr));

      {********************************}
      { user defined method statements }
      {********************************}
      static_method_stmt, dynamic_method_stmt, interface_method_stmt,
        proto_method_stmt:
        begin
          Disassemble_code(outfile, code_ref_type(stmt_code_ref));
          Disassemble_expr(outfile, stmt_name_ptr);

          Disassemble_stmts(outfile, implicit_stmts_ptr);
          Disassemble_stmts(outfile, param_assign_stmts_ptr);
          Disassemble_stmts(outfile, param_stmts_ptr);

          Disassemble_stmts(outfile, return_assign_stmts_ptr);
          Disassemble_stmts(outfile, return_stmts_ptr);

          {**************************}
          { optional shader statment }
          {**************************}
          if code_ref_type(stmt_code_ref)^.kind = object_code then
            if stmt_data_ptr <> nil then
              begin
                Disassemble_stmt(outfile, stmt_data_ptr^.shader_stmt_ptr);
              end
            else
              Disassemble_stmt(outfile, nil);
        end;

    end; {case}
end; {procedure Disassemble_stmt_fields}


procedure Disassemble_stmt(var outfile: text;
  stmt_ptr: stmt_ptr_type);
begin
  if stmt_ptr <> nil then
    begin
      {*********************************}
      { disassemble statement reference }
      {*********************************}
      if stmt_ptr^.stmt_index <> 0 then
        begin
          Disassemble_mnemonic(outfile, 'srf');
          Disassemble_index(outfile, stmt_ptr^.stmt_index);
        end

          {***********************}
          { disassemble statement }
          {***********************}
      else
        begin
          stmt_disasm_count := stmt_disasm_count + 1;
          stmt_ptr^.stmt_index := stmt_disasm_count;

          {********************************}
          { disassemble statement mnemonic }
          {********************************}
          Disassemble_mnemonic(outfile, Stmt_kind_to_mnemonic(stmt_ptr^.kind));
          Disassemble_stmt_fields(outfile, stmt_ptr);
        end;
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_stmt}


procedure Disassemble_stmts(var outfile: text;
  stmt_ptr: stmt_ptr_type);
begin
  while (stmt_ptr <> nil) do
    begin
      Disassemble_stmt(outfile, stmt_ptr);
      stmt_ptr := stmt_ptr^.next;
    end;
  Disassemble_stmt(outfile, nil);
end; {procedure Disassemble_stmts}


{****************************************}
{ functions returning assembler progress }
{****************************************}


function Stmts_assembled: asm_index_type;
begin
  Stmts_assembled := stmt_asm_count;
end; {function Stmts_assembled}


function Stmts_disassembled: asm_index_type;
begin
  Stmts_disassembled := stmt_disasm_count;
end; {function Stmts_disassembled}


initialization
  Make_stmt_mnemonics;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  stmt_asm_count := 0;
  stmt_disasm_count := 0;
  stmt_block_ptr := nil;
  stmt_block_count := 0;
end.

