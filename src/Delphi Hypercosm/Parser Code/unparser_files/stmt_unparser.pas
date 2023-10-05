unit stmt_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            stmt_unparser              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module traverses the syntax tree and writes out    }
{       the original program statements from it.                }
{       This is useful for debugging and to tell if the         }
{       parsers have produced the correct syntax tree.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  comments, type_attributes, code_attributes, exprs, stmts, code_decls;


var
  unparsing_code_ptr: code_ptr_type;
  unparsing_code_attributes_ptr: code_attributes_ptr_type;


  {********************************}
  { routines to unparse statements }
  {********************************}
procedure Unparse_stmt(var outfile: text;
  stmt_ptr: stmt_ptr_type);
procedure Unparse_stmts(var outfile: text;
  stmt_ptr: stmt_ptr_type);

{*******************************************}
{ routines to get comments from a statement }
{*******************************************}
function Get_prev_stmt_comments(stmt_ptr: stmt_ptr_type): comment_ptr_type;
function Get_post_stmt_comments(stmt_ptr: stmt_ptr_type): comment_ptr_type;


implementation
uses
  strings, string_io, code_types, symbol_tables, decl_attributes,
  expr_attributes, decls, type_decls, unparser, term_unparser, array_unparser,
  expr_unparser, instruct_unparser, msg_unparser, data_unparser,
  assign_unparser, decl_unparser;


const
  debug = false;


var
  first_stmt: boolean;


  {*******************************************}
  { routines to get comments from a statement }
  {*******************************************}


function Get_prev_stmt_comments(stmt_ptr: stmt_ptr_type): comment_ptr_type;
var
  comment_ptr: comment_ptr_type;
begin
  comment_ptr := nil;

  if stmt_ptr <> nil then
    with stmt_ptr^ do
      begin
        {*****************************}
        { get comments from stmt node }
        {*****************************}
        if stmt_info_ptr <> nil then
          if stmt_info_ptr^.comments_ptr <> nil then
            comment_ptr :=
              stmt_info_ptr^.comments_ptr^.prev_comment_list.comment_ptr;

        {***********************************************}
        { if no comments and expression is nonterminal, }
        { then get comments from its subexpression.     }
        {***********************************************}
        if comment_ptr = nil then
          begin
            if kind in assign_stmt_set then
              comment_ptr := Get_prev_expr_comments(Get_assign_lhs(stmt_ptr))
            else if kind in method_stmt_set then
              begin
                if stmt_data_ptr <> nil then
                  comment_ptr :=
                    Get_prev_stmt_comments(stmt_data_ptr^.shader_stmt_ptr);

                if implicit_stmts_ptr <> nil then
                  comment_ptr :=
                    Get_prev_expr_comments(implicit_stmts_ptr^.rhs_expr_ptr);

                if comment_ptr = nil then
                  comment_ptr := Get_prev_expr_comments(stmt_name_ptr);
              end;
          end;
      end; {if}

  Get_prev_stmt_comments := comment_ptr;
end; {function Get_prev_stmt_comments}


function Get_post_stmt_comments(stmt_ptr: stmt_ptr_type): comment_ptr_type;
var
  comment_ptr: comment_ptr_type;
begin
  comment_ptr := nil;

  if stmt_ptr <> nil then
    with stmt_ptr^ do
      begin
        {*****************************}
        { get comments from stmt node }
        {*****************************}
        if stmt_info_ptr <> nil then
          if stmt_info_ptr^.comments_ptr <> nil then
            comment_ptr :=
              stmt_info_ptr^.comments_ptr^.post_comment_list.comment_ptr;
      end;

  Get_post_stmt_comments := comment_ptr;
end; {function Get_post_stmt_comments}


{*****************************************}
{ auxilliary statement unparsing routines }
{*****************************************}


function Implicit_stmt(stmt_ptr: stmt_ptr_type): boolean;
var
  code_ptr: code_ptr_type;
  implicit: boolean;
begin
  if not (stmt_ptr^.kind in method_stmt_set) then
    begin
      if stmt_ptr^.kind in implicit_free_stmt_set then
        implicit := not show_implicit
      else
        implicit := (stmt_ptr^.kind in implicit_stmt_set);
    end
  else
    begin
      code_ptr := code_ptr_type(stmt_ptr^.stmt_code_ref);
      implicit := (code_ptr^.kind in [function_code, shader_code]);
    end;

  Implicit_stmt := implicit;
end; {function Implicit_stmt}


procedure Unparse_label(var outfile: text;
  label_index: integer);
var
  symbol_table_ptr: symbol_table_ptr_type;
  id_ptr: id_ptr_type;
begin
  symbol_table_ptr := unparsing_code_attributes_ptr^.label_table_ptr;
  if Found_id_by_value(symbol_table_ptr, id_ptr, label_index) then
    Unparse_str(outfile, Get_id_name(id_ptr))
  else
    Unparse_str(outfile, Integer_to_str(label_index));
end; {procedure Unparse_label}


procedure Unparse_stmt_block(var outfile: text;
  decl_ptr: forward_decl_ptr_type;
  stmt_ptr: stmt_ptr_type);
begin
  Unparse_decls(outfile, decl_ptr_type(decl_ptr));

  {***************************************************}
  { unparse space between declarations and statements }
  {***************************************************}
  if (decl_ptr <> nil) and (stmt_ptr <> nil) then
    begin
      Unparseln(outfile, '');
      Indent(outfile);
    end;

  Unparse_stmts(outfile, stmt_ptr);
end; {procedure Unparse_stmt_block}


function Found_last_stmt(stmt_ptr: stmt_ptr_type): boolean;
var
  last_stmt: boolean;
begin
  if stmt_ptr^.next = nil then
    last_stmt := true
  else if stmt_ptr^.stmt_info_ptr = nil then
    last_stmt := true
  else if stmt_ptr^.next^.stmt_info_ptr = nil then
    last_stmt := true
  else if stmt_ptr^.next^.stmt_info_ptr^.stmt_number <=
    stmt_ptr^.stmt_info_ptr^.stmt_number then
    last_stmt := true
  else
    last_stmt := false;

  Found_last_stmt := last_stmt;
end; {function Found_last_stmt}


{*****************************************************}
{ routines to unparse components of array assignments }
{*****************************************************}


procedure Unparse_subarray_assign(var outfile: text;
  stmt_ptr: stmt_ptr_type);
begin
  if (stmt_ptr <> nil) then
    with stmt_ptr^ do
      begin
        Indent(outfile);
        Unparse_str(outfile, 'subarray');
        Unparse_space(outfile);
        Unparse_str(outfile, 'assign');
        Unparse_space(outfile);
        Unparseln(outfile, 'with');
        Push_margin;

        {********************************}
        { unparse fields of array assign }
        {********************************}
        Indent(outfile);
        Unparse_str(outfile, 'lhs array subrange');
        Unparse_array_subrange(outfile, lhs_subarray_subrange_ptr);

        Indent(outfile);
        Unparse_str(outfile, 'rhs array subrange');
        Unparse_array_subrange(outfile, rhs_subarray_subrange_ptr);

        Indent(outfile);
        if subarray_assign_stmt_ptr^.kind <> subarray_assign then
          Unparse_stmt(outfile, subarray_assign_stmt_ptr)
        else
          Unparse_subarray_assign(outfile, subarray_assign_stmt_ptr);

        Pop_margin;
        Indent(outfile);
        Unparse_str(outfile, 'end');
        Unparseln(outfile, ';');
      end;
end; {procedure Unparse_subarray_assign}


procedure Unparse_array_assign(var outfile: text;
  stmt_ptr: stmt_ptr_type);
begin
  if (stmt_ptr <> nil) then
    with stmt_ptr^ do
      begin
        Indent(outfile);
        Unparse_str(outfile, 'array');
        Unparse_space(outfile);
        Unparse_str(outfile, 'assign');
        Unparse_space(outfile);
        Unparseln(outfile, 'with');
        Push_margin;

        {********************************}
        { unparse fields of array assign }
        {********************************}
        Indent(outfile);
        Unparse_str(outfile, 'lhs array subrange');
        Unparse_array_subrange(outfile, lhs_array_subrange_ptr);

        Indent(outfile);
        Unparse_str(outfile, 'rhs array subrange');
        Unparse_array_subrange(outfile, rhs_array_subrange_ptr);

        Indent(outfile);
        Unparse_str(outfile, 'bounds list = ');
        Unparse_array_bounds_list(outfile, array_assign_bounds_list_ref);
        Unparseln(outfile, ';');

        Indent(outfile);
        if array_assign_stmt_ptr^.kind <> subarray_assign then
          Unparse_stmt(outfile, array_assign_stmt_ptr)
        else
          Unparse_subarray_assign(outfile, array_assign_stmt_ptr);

        Pop_margin;
        Indent(outfile);
        Unparse_str(outfile, 'end');
        Unparseln(outfile, ';');
      end;
end; {procedure Unparse_array_assign}


{****************************************************************}
{ routines to unparse components of array expression assignments }
{****************************************************************}


procedure Unparse_subarray_expr_assign(var outfile: text;
  stmt_ptr: stmt_ptr_type);
begin
  if (stmt_ptr <> nil) then
    with stmt_ptr^ do
      begin
        Indent(outfile);
        Unparse_str(outfile, 'subarray');
        Unparse_space(outfile);
        Unparse_str(outfile, 'expr');
        Unparse_space(outfile);
        Unparse_str(outfile, 'assign');
        Unparse_space(outfile);
        Unparseln(outfile, 'with');
        Push_margin;

        {********************************}
        { unparse fields of array assign }
        {********************************}
        Indent(outfile);
        Unparse_str(outfile, 'array expr subrange');
        Unparse_array_subrange(outfile, subarray_expr_subrange_ptr);

        Indent(outfile);
        if subarray_expr_assign_stmt_ptr^.kind <> subarray_expr_assign then
          Unparse_stmt(outfile, subarray_expr_assign_stmt_ptr)
        else
          Unparse_subarray_expr_assign(outfile, subarray_expr_assign_stmt_ptr);

        Pop_margin;
        Indent(outfile);
        Unparse_str(outfile, 'end');
        Unparseln(outfile, ';');
      end;
end; {procedure Unparse_subarray_expr_assign}


procedure Unparse_array_expr_assign(var outfile: text;
  stmt_ptr: stmt_ptr_type);
begin
  if (stmt_ptr <> nil) then
    with stmt_ptr^ do
      begin
        Indent(outfile);
        Unparse_str(outfile, 'array');
        Unparse_space(outfile);
        Unparse_str(outfile, 'expr');
        Unparse_space(outfile);
        Unparse_str(outfile, 'assign');
        Unparse_space(outfile);
        Unparseln(outfile, 'with');
        Push_margin;

        {********************************}
        { unparse fields of array assign }
        {********************************}
        Indent(outfile);
        Unparse_str(outfile, 'array expr subrange');
        Unparse_array_subrange(outfile, array_expr_subrange_ptr);

        Indent(outfile);
        Unparse_str(outfile, 'bounds list = ');
        Unparse_array_bounds_list(outfile, array_expr_bounds_list_ref);
        Unparseln(outfile, ';');

        Indent(outfile);
        if array_expr_assign_stmt_ptr^.kind <> subarray_expr_assign then
          Unparse_stmt(outfile, array_expr_assign_stmt_ptr)
        else
          Unparse_subarray_expr_assign(outfile, array_expr_assign_stmt_ptr);

        Pop_margin;
        Indent(outfile);
        Unparse_str(outfile, 'end');
        Unparseln(outfile, ';');
      end;
end; {procedure Unparse_array_expr_assign}


{********************************}
{ routines to unparse statements }
{********************************}


procedure Unparse_stmt(var outfile: text;
  stmt_ptr: stmt_ptr_type);
var
  expr_ptr: expr_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  case_constant_ptr: case_constant_ptr_type;
  comment_ptr: comment_ptr_type;
  found_elseif: boolean;
begin
  if (stmt_ptr <> nil) then
    with stmt_ptr^ do
      begin
        {*******************************}
        { indent for each new statement }
        {*******************************}
        if not Implicit_stmt(stmt_ptr) or (stmt_ptr^.kind = loop_label_stmt)
          then
          Indent(outfile);

        if stmt_info_ptr <> nil then
          begin
            {********************************************}
            { unparse comments at beginning of statement }
            {********************************************}
            comment_ptr := Get_prev_comments(stmt_info_ptr^.comments_ptr);
            if comment_ptr <> nil then
              begin
                Unparse_comments(outfile, comment_ptr);
                if stmt_ptr^.kind <> null_stmt then
                  Indent(outfile);
              end;
          end;

        case kind of

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
              Unparse_expr(outfile, lhs_data_ptr);
              Unparse_initializer(outfile, stmt_ptr);
            end;

          {*****************************}
          { array assignment statements }
          {*****************************}
          boolean_array_assign..reference_array_assign:
            if debug then
              Unparse_array_assign(outfile, stmt_ptr)
            else
              Unparse_stmt(outfile, array_assign_stmt_ptr);
          subarray_assign:
            Unparse_stmt(outfile, subarray_assign_stmt_ptr);

          {****************************************}
          { array expression assignment statements }
          {****************************************}
          boolean_array_expr_assign..reference_array_expr_assign:
            if debug then
              Unparse_array_expr_assign(outfile, stmt_ptr)
            else
              begin
                Indent(outfile);
                Unparse_expr(outfile, Get_assign_lhs(stmt_ptr));
                Unparse_initializer(outfile, stmt_ptr);
                Unparseln(outfile, ';');
              end;

          {******************************}
          { struct assignment statements }
          {******************************}
          struct_assign:
            begin
              Unparse_expr(outfile, lhs_struct_expr_ptr);
              Unparse_initializer(outfile, stmt_ptr);
            end;

          {*****************************************}
          { struct expression assignment statements }
          {*****************************************}
          struct_base_assign, struct_expr_assign, struct_expr_ptr_assign:
            ;

          {************************}
          { conditional statements }
          {************************}
          if_then_else:
            begin
              Unparse_str(outfile, 'if');
              Unparse_space(outfile);

              Unparse_expr(outfile, if_expr_ptr);
              Unparse_space(outfile);
              Check_wraparound(outfile);

              Unparseln(outfile, 'then');
              Unparse_space(outfile);

              Push_margin;
              Unparse_stmt_block(outfile, then_decls_ptr, then_stmts_ptr);
              Pop_margin;

              if (else_stmts_ptr <> nil) then
                begin
                  if else_stmts_ptr^.kind <> if_then_else then
                    found_elseif := false
                  else
                    found_elseif := else_stmts_ptr^.elseif_contraction;

                  if found_elseif then
                    begin
                      Indent(outfile);
                      Unparse_str(outfile, 'else');
                      Unparse_stmt_block(outfile, else_decls_ptr,
                        else_stmts_ptr);
                    end
                  else
                    begin
                      Indent(outfile);
                      Unparseln(outfile, 'else');
                      Unparse_space(outfile);

                      Push_margin;
                      Unparse_stmt_block(outfile, else_decls_ptr,
                        else_stmts_ptr);
                      Pop_margin;

                      Indent(outfile);
                      Unparse_str(outfile, 'end');
                    end;
                end
              else
                begin
                  Indent(outfile);
                  Unparse_str(outfile, 'end');
                end;
            end;

          case_char_stmt, case_enum_stmt:
            begin
              Unparse_str(outfile, 'when');
              Unparse_space(outfile);

              Unparse_expr(outfile, switch_expr_ptr);
              Unparse_space(outfile);

              Unparseln(outfile, 'is');
              Unparse_space(outfile);

              case_constant_ptr := switch_case_constant_ptr;
              while (case_constant_ptr <> nil) do
                begin
                  Push_margin;
                  Indent(outfile);
                  Unparse_expr(outfile, case_constant_ptr^.case_expr_ptr);
                  Unparseln(outfile, ':');

                  Push_margin;
                  with
                    switch_array_ptr^.switch_case_array[case_constant_ptr^.value]^
                    do
                    Unparse_stmt_block(outfile, case_decls_ptr, case_stmts_ptr);
                  Pop_margin;

                  Indent(outfile);
                  Unparseln(outfile, 'end;');
                  Pop_margin;

                  case_constant_ptr := case_constant_ptr^.next;
                end;

              if (switch_else_stmts_ptr <> nil) then
                begin
                  Indent(outfile);
                  Unparseln(outfile, 'else');

                  Push_margin;
                  Unparse_stmt_block(outfile, switch_else_decls_ptr,
                    switch_else_stmts_ptr);
                  Pop_margin;
                end;

              Indent(outfile);
              Unparse_str(outfile, 'end');
            end;

          {********************}
          { looping statements }
          {********************}
          while_loop:
            begin
              Unparse_str(outfile, 'while');
              Unparse_space(outfile);

              Unparse_expr(outfile, while_expr_ptr);
              Unparse_space(outfile);
              Check_wraparound(outfile);

              Unparseln(outfile, 'do');

              Push_margin;
              Unparse_stmt_block(outfile, while_decls_ptr, while_stmts_ptr);
              Pop_margin;

              Indent(outfile);
              Unparse_str(outfile, 'end');
            end;

          for_loop:
            begin
              Unparse_str(outfile, 'for');
              Unparse_space(outfile);

              {**********************************}
              { unparse loop counter declaration }
              {**********************************}
              expr_ptr :=
                decl_ptr_type(counter_decl_ptr)^.data_decl.data_expr_ptr;
              expr_attributes_ptr := Get_expr_attributes(expr_ptr);
              Unparse_type_attributes(outfile,
                expr_attributes_ptr^.type_attributes_ptr);
              Unparse_space(outfile);

              Unparse_expr(outfile, expr_ptr);
              Unparse_space(outfile);

              if expr_attributes_ptr^.type_attributes_ptr^.kind in [type_char,
                type_enum] then
                Unparse_str(outfile, 'is')
              else
                Unparse_char(outfile, '=');
              Unparse_space(outfile);

              Unparse_expr(outfile, start_expr_ptr);
              Unparse_str(outfile, '..');
              Unparse_expr(outfile, end_expr_ptr);
              Unparse_space(outfile);
              Check_wraparound(outfile);

              Unparseln(outfile, 'do');

              Push_margin;
              Unparse_stmt_block(outfile, for_decls_ptr, for_stmts_ptr);
              Pop_margin;

              Indent(outfile);
              Unparse_str(outfile, 'end');
            end;

          for_each:
            begin
              Unparse_str(outfile, 'for');
              Unparse_space(outfile);
              Unparse_str(outfile, 'each');
              Unparse_space(outfile);

              {********************************}
              { unparse loop index declaration }
              {********************************}
              expr_ptr :=
                decl_ptr_type(each_index_decl_ptr)^.data_decl.data_expr_ptr;
              expr_attributes_ptr := Get_expr_attributes(expr_ptr);
              Unparse_type_attributes(outfile,
                expr_attributes_ptr^.type_attributes_ptr);
              Unparse_space(outfile);

              Unparse_expr(outfile, expr_ptr);
              Unparse_space(outfile);

              {*********************************}
              { unparse parent array expression }
              {*********************************}
              Unparse_str(outfile, 'in');
              Unparse_space(outfile);

              Unparse_expr(outfile, each_array_ptr);
              Unparse_space(outfile);
              Check_wraparound(outfile);

              Unparseln(outfile, 'do');

              Push_margin;
              Unparse_stmt_block(outfile, each_decls_ptr, each_stmts_ptr);
              Pop_margin;

              Indent(outfile);
              Unparse_str(outfile, 'end');
            end;

          for_each_loop:
            begin
              Unparse_stmts(outfile, loop_stmts_ptr);
            end;

          for_each_list:
            begin
              Unparse_str(outfile, 'for');
              Unparse_space(outfile);
              Unparse_str(outfile, 'each');
              Unparse_space(outfile);

              {********************************}
              { unparse loop index declaration }
              {********************************}
              expr_ptr :=
                decl_ptr_type(each_struct_decl_ptr)^.data_decl.data_expr_ptr;
              expr_attributes_ptr := Get_expr_attributes(expr_ptr);
              Unparse_type_attributes(outfile,
                expr_attributes_ptr^.type_attributes_ptr);
              Unparse_space(outfile);

              Unparse_expr(outfile, expr_ptr);
              Unparse_space(outfile);

              {************************************}
              { unparse 'next' iterator expression }
              {************************************}
              Unparse_str(outfile, 'and');
              Unparse_space(outfile);
              Unparse_expr(outfile, each_next_expr_ptr);
              Unparse_space(outfile);

              {*********************}
              { unparse parent list }
              {*********************}
              Unparse_str(outfile, 'in');
              Unparse_space(outfile);
              Unparse_expr(outfile, each_list_expr_ptr);
              Unparse_space(outfile);
              Check_wraparound(outfile);

              Unparseln(outfile, 'do');

              Push_margin;
              Unparse_stmt_block(outfile, list_decls_ptr, list_stmts_ptr);
              Pop_margin;

              Indent(outfile);
              Unparse_str(outfile, 'end');

            end;

          {*************************}
          { flow control statements }
          {*************************}
          loop_label_stmt:
            begin
              Unparse_str(outfile, 'loop');
              Unparse_space(outfile);
              Unparse_label(outfile, loop_label_index);
              Unparseln(outfile, ':');
              Unparse_stmts(outfile, loop_stmt_ptr);
            end;

          break_stmt:
            begin
              Unparse_str(outfile, 'break');
              if label_index <> 0 then
                begin
                  Unparse_space(outfile);
                  Unparse_label(outfile, label_index);
                end;
            end;

          continue_stmt:
            begin
              Unparse_str(outfile, 'continue');
              if label_index <> 0 then
                begin
                  Unparse_space(outfile);
                  Unparse_label(outfile, label_index);
                end;
            end;

          return_stmt:
            begin
              Unparse_str(outfile, 'return');
            end;

          exit_stmt:
            begin
              Unparse_str(outfile, 'exit');
            end;

          boolean_answer..reference_answer:
            begin
              Unparse_str(outfile, 'answer');
              Unparse_space(outfile);
              Unparse_expr(outfile, answer_expr_ptr);
            end;

          {********************}
          { scoping statements }
          {********************}
          with_stmt:
            begin
              Unparse_str(outfile, 'with');
              Unparse_space(outfile);

              Unparse_expr(outfile, with_expr_ptr);
              Unparse_space(outfile);
              Check_wraparound(outfile);

              Unparseln(outfile, 'do');

              Push_margin;
              Unparse_stmt_block(outfile, with_decls_ptr, with_stmts_ptr);
              Pop_margin;

              Indent(outfile);
              Unparse_str(outfile, 'end');
            end;

          {*****************************}
          { array allocation statements }
          {*****************************}
          dim_stmt, redim_stmt:
            begin
              case kind of
                dim_stmt:
                  Unparse_str(outfile, 'dim');
                redim_stmt:
                  Unparse_str(outfile, 'redim');
              end;
              Unparse_space(outfile);

              {*************************}
              { unparse base identifier }
              {*************************}
              Unparse_expr(outfile, dim_data_ptr);

              {**************************}
              { unparse array dimensions }
              {**************************}
              Unparse_expr(outfile, dim_expr_ptr);
            end;

          {******************************}
          { struct allocation statements }
          {******************************}
          new_struct_stmt:
            begin
              Unparse_str(outfile, 'new');
              Unparse_space(outfile);
              Unparse_expr(outfile, new_data_ptr);
              Unparse_expr(outfile, new_expr_ptr);
            end;

          renew_struct_stmt:
            begin
              Unparse_str(outfile, 'renew');
              if new_data_ptr <> nil then
                begin
                  Unparse_space(outfile);
                  Unparse_expr(outfile, new_data_ptr);
                  Unparse_expr(outfile, new_expr_ptr);
                end;
            end;

          {********************************}
          { memory deallocation statements }
          {********************************}
          implicit_free_array_stmt:
            begin
              if show_implicit then
                begin
                  Unparse_str(outfile, 'free (array)');
                  Unparse_space(outfile);
                  Unparse_expr(outfile, free_array_expr_ref);
                end;
            end;

          implicit_free_struct_stmt:
            begin
              if show_implicit then
                begin
                  Unparse_str(outfile, 'free (struct)');
                  Unparse_space(outfile);
                  Unparse_expr(outfile, free_struct_expr_ref);
                end;
            end;

          implicit_free_reference_stmt:
            begin
              if show_implicit then
                begin
                  Unparse_str(outfile, 'free (reference)');
                  Unparse_space(outfile);
                  Unparse_expr(outfile, free_reference_expr_ref);
                end;
            end;

          implicit_free_params_stmt:
            begin
              if show_implicit then
                begin
                  decl_attributes_ptr :=
                    Get_decl_attributes(decl_ptr_type(free_decl_ref));
                  Unparse_str(outfile, 'free');
                  Unparse_space(outfile);
                  Unparse_str(outfile,
                    Get_decl_attributes_name(decl_attributes_ptr));
                  Unparse_space(outfile);
                  Unparse_str(outfile, 'params');
                end;
            end;

          {*********************}
          { built in statements }
          {*********************}
          built_in_stmt:
            begin
              Unparse_instruct(outfile, stmt_ptr);
            end;

          {********************}
          { complex statements }
          {********************}
          static_method_stmt, dynamic_method_stmt, interface_method_stmt,
            proto_method_stmt:
            begin
              if code_ptr_type(stmt_code_ref)^.kind in procedural_code_kinds
                then
                Unparse_proc_stmt(outfile, stmt_ptr)
              else
                Unparse_func_stmt(outfile, stmt_ptr);
            end;
        end; {case}

        {**********************************}
        { find if stmt is an elseif clause }
        {**********************************}
        if kind <> if_then_else then
          found_elseif := false
        else
          found_elseif := elseif_contraction;

        {******************************}
        { unparse statement terminator }
        {******************************}
        if not Implicit_stmt(stmt_ptr) then
          if not found_elseif then
            begin
              if Found_last_stmt(stmt_ptr) then
                begin
                  Unparse_char(outfile, ';');
                  Unparseln(outfile, '');
                end
              else
                begin
                  Unparse_char(outfile, ',');
                end;
            end;

        if stmt_info_ptr <> nil then
          begin
            {**************************************}
            { unparse comments at end of statement }
            {**************************************}
            comment_ptr := Get_post_comments(stmt_info_ptr^.comments_ptr);
            if comment_ptr <> nil then
              begin
                Unparse_tab(outfile);
                Unparse_comments(outfile, comment_ptr);
              end;
          end;
      end; {with}
end; {procedure Unparse_stmt}


procedure Unparse_stmts(var outfile: text;
  stmt_ptr: stmt_ptr_type);
begin
  first_stmt := true;
  while (stmt_ptr <> nil) do
    begin
      Unparse_stmt(outfile, stmt_ptr);
      stmt_ptr := stmt_ptr^.next;

      {************************************}
      { if next stmt begins with a comment }
      { then seperate it with a blank line }
      {************************************}
      if stmt_ptr <> nil then
        if not Implicit_stmt(stmt_ptr) then
          if Get_prev_stmt_comments(stmt_ptr) <> nil then
            Unparseln(outfile, '');

      first_stmt := false;
    end;
end; {procedure Unparse_stmts}


end.
