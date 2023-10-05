unit msg_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            msg_unparser               3d       }
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
  comments, code_attributes, stmts, code_decls;


procedure Unparse_params(var outfile: text;
  stmt_ptr: stmt_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type);
procedure Unparse_proc_stmt(var outfile: text;
  stmt_ptr: stmt_ptr_type);
procedure Unparse_func_stmt(var outfile: text;
  stmt_ptr: stmt_ptr_type);


implementation
uses
  chars, strings, string_io, code_types, decl_attributes, stmt_attributes,
  expr_attributes, exprs, decls, type_decls, unparser, term_unparser,
  expr_unparser, instruct_unparser, assign_unparser, stmt_unparser,
  type_unparser, decl_unparser;


{*****************************************}
{ auxilliary statement unparsing routines }
{*****************************************}


procedure Unparse_method_data(var outfile: text;
  stmt_ptr: stmt_ptr_type);
var
  code_ptr: code_ptr_type;
  type_ptr: type_ptr_type;
begin
  code_ptr := code_ptr_type(stmt_ptr^.stmt_code_ref);
  type_ptr := type_ptr_type(code_ptr^.class_type_ref);

  if type_ptr <> nil then
    begin
      if (stmt_ptr^.implicit_stmts_ptr <> nil) then
        begin
          {*********************}
          { unparse method data }
          {*********************}
          if not stmt_ptr^.stmt_info_ptr^.implicit_method then
            begin
              Unparse_expr(outfile, stmt_ptr^.implicit_stmts_ptr^.rhs_expr_ptr);
              Unparse_space(outfile);
            end;

          {*************************}
          { static binding override }
          {*************************}
          if code_ptr^.method_kind in dynamic_method_set then
            if stmt_ptr^.kind = static_method_stmt then
              begin
                Unparse_str(outfile, 'static');
                Unparse_space(outfile);
              end;
        end
      else
        begin
          {**************}
          { void methods }
          {**************}
          if not stmt_ptr^.stmt_info_ptr^.implicit_method then
            begin
              Unparse_type_name(outfile, type_ptr);
              Unparse_str(outfile, Char_to_str(single_quote));
              Unparse_str(outfile, 's');
              Unparse_space(outfile);
            end;
        end;
    end;
end; {procedure Unparse_method_data}


procedure Unparse_formatted_params(var outfile: text;
  stmts_ptr: stmt_ptr_type;
  signature_ptr: signature_ptr_type;
  return_params: boolean);
const
  valid_stmt_kinds = [boolean_assign..struct_assign];
var
  param_line_number: integer;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  parameter_ptr: parameter_ptr_type;
  keyword_ptr: keyword_ptr_type;
  comment_ptr: comment_ptr_type;
  follow: signature_ptr_type;
  done, found: boolean;
begin
  done := false;
  while (stmts_ptr <> nil) and (not done) do
    begin
      if (stmts_ptr^.kind in valid_stmt_kinds) then
        begin
          {*************************************}
          { find attributes of first assignment }
          {*************************************}
          if return_params then
            expr_ptr := Get_assign_rhs(stmts_ptr)
          else
            expr_ptr := Get_assign_lhs(stmts_ptr);

          expr_attributes_ptr := Get_expr_attributes(expr_ptr);
          decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
        end
      else
        begin
          signature_ptr := nil;
          decl_attributes_ptr := nil;
        end;

      {******************************}
      { find keywords from signature }
      {******************************}
      follow := signature_ptr;
      found := false;
      while (follow <> nil) and not found do
        begin
          if follow^.parameter_ptr^.id_ptr = decl_attributes_ptr^.id_ptr then
            found := true
          else
            follow := follow^.next;
        end;

      if found then
        begin
          {******************}
          { unparse keywords }
          {******************}
          keyword_ptr := follow^.keyword_ptr;
          while (keyword_ptr <> nil) do
            begin
              Unparse_space(outfile);
              Unparse_str(outfile, keyword_ptr^.keyword);
              keyword_ptr := keyword_ptr^.next;
            end;

          {*********************************}
          { unparse param value expressions }
          {*********************************}
          parameter_ptr := follow^.parameter_ptr;
          while (parameter_ptr <> nil) do
            begin
              if stmts_ptr^.stmt_info_ptr <> nil then
                begin
                  {********************************************}
                  { unparse comments at beginning of statement }
                  {********************************************}
                  comment_ptr := Get_prev_stmt_comments(stmts_ptr);
                  if comment_ptr <> nil then
                    begin
                      Unparseln(outfile, '');
                      Unparse_comments(outfile, comment_ptr);
                      Indent(outfile);
                    end;
                end;

              if return_params then
                expr_ptr := Get_assign_lhs(stmts_ptr)
              else
                expr_ptr := Get_assign_rhs(stmts_ptr);

              {*************************************************************}
              { if param value spans multiple lines then return before next }
              {*************************************************************}
              param_line_number := Unparseln_number;
              Indent(outfile);
              Unparse_space(outfile);
              Unparse_expr(outfile, expr_ptr);

              parameter_ptr := parameter_ptr^.next;
              stmts_ptr := stmts_ptr^.next;

              if stmts_ptr <> nil then
                begin
                  if stmts_ptr^.stmt_info_ptr <> nil then
                    comment_ptr := Get_prev_stmt_comments(stmts_ptr)
                  else
                    comment_ptr := nil;

                  if (Unparseln_number > param_line_number + 1) or (comment_ptr
                    <> nil) then
                    begin
                      Unparseln(outfile, '');
                      if comment_ptr = nil then
                        Unparseln(outfile, '');
                      Indent(outfile);
                    end;
                end; {if}

            end; {while}
        end
      else
        done := true;
    end;
end; {procedure Unparse_formatted_params}


procedure Unparse_unformatted_proc_params(var outfile: text;
  implicit_stmts_ptr: stmt_ptr_type;
  param_stmts_ptr: stmt_ptr_type;
  return_stmts_ptr: stmt_ptr_type);
begin
  if (implicit_stmts_ptr <> nil) or (param_stmts_ptr <> nil) or (return_stmts_ptr
    <> nil) then
    begin
      Unparse_str(outfile, 'with');
      Unparse_space(outfile);
      if (implicit_stmts_ptr <> nil) or (param_stmts_ptr <> nil) then
        begin
          Unparseln(outfile, '');
          Push_margin;
          Unparse_stmts(outfile, implicit_stmts_ptr);
          Unparse_stmts(outfile, param_stmts_ptr);
          Pop_margin;
        end;

      if (return_stmts_ptr <> nil) then
        begin
          Indent(outfile);
          Unparse_str(outfile, 'return');
          Unparse_space(outfile);
          if return_stmts_ptr <> nil then
            begin
              Unparseln(outfile, '');
              Push_margin;
              Unparse_stmts(outfile, return_stmts_ptr);
              Pop_margin;
            end;
        end;

      Indent(outfile);
      Unparse_str(outfile, 'end');
    end;
end; {procedure Unparse_unformatted_proc_params}


procedure Unparse_unformatted_func_params(var outfile: text;
  implicit_stmts_ptr: stmt_ptr_type;
  param_stmts_ptr: stmt_ptr_type;
  return_stmts_ptr: stmt_ptr_type);
begin
  if (implicit_stmts_ptr <> nil) or (param_stmts_ptr <> nil) or (return_stmts_ptr
    <> nil) then
    begin
      Unparse_str(outfile, 'with');
      Unparse_space(outfile);
      if (implicit_stmts_ptr <> nil) or (param_stmts_ptr <> nil) then
        begin
          Unparseln(outfile, ' ');
          Push_margin;
          Unparse_stmts(outfile, implicit_stmts_ptr);
          Unparse_stmts(outfile, param_stmts_ptr);
          Pop_margin;
        end;

      if (return_stmts_ptr <> nil) then
        begin
          Indent(outfile);
          Unparse_str(outfile, 'return');
          Unparse_space(outfile);
          if return_stmts_ptr <> nil then
            begin
              Unparseln(outfile, '');
              Push_margin;
              Unparse_stmts(outfile, return_stmts_ptr);
              Pop_margin;
            end;
        end;

      Indent(outfile);
    end;
end; {procedure Unparse_unformatted_func_params}


procedure Unparse_params(var outfile: text;
  stmt_ptr: stmt_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type);
var
  implicit_stmts_ptr, param_stmts_ptr, return_stmts_ptr: stmt_ptr_type;
  param_line_number: integer;
  prev_indented: boolean;
begin
  param_line_number := Unparseln_number;
  prev_indented := indented_wraparound;

  if prev_indented then
    begin
      indented_wraparound := false;
      Push_margin;
    end;

  {******************************}
  { unparse formatted parameters }
  {******************************}
  Unparse_formatted_params(outfile, stmt_ptr^.param_assign_stmts_ptr,
    code_attributes_ptr^.signature_ptr, false);

  if code_attributes_ptr^.return_signature_ptr <> nil then
    begin
      Unparse_space(outfile);
      Unparse_str(outfile, 'return');
      Unparse_formatted_params(outfile, stmt_ptr^.return_assign_stmts_ptr,
        code_attributes_ptr^.return_signature_ptr, true);
    end;

  if prev_indented then
    begin
      Pop_margin;
      indented_wraparound := true;
    end;

  implicit_stmts_ptr := stmt_ptr^.implicit_stmts_ptr;
  param_stmts_ptr := stmt_ptr^.param_stmts_ptr;
  return_stmts_ptr := stmt_ptr^.return_stmts_ptr;

  if not show_implicit then
    implicit_stmts_ptr := nil;

  if (implicit_stmts_ptr <> nil) or (param_stmts_ptr <> nil) or (return_stmts_ptr
    <> nil) then
    begin
      {**************************************}
      { begin unformatted params on new line }
      {**************************************}
      if Unparseln_number <> param_line_number then
        begin
          Unparseln(outfile, '');
          Indent(outfile);
        end
      else
        Unparse_space(outfile);

      {************************}
      { unformatted parameters }
      {************************}
      if code_attributes_ptr^.kind in procedural_code_kinds then
        Unparse_unformatted_proc_params(outfile, implicit_stmts_ptr,
          param_stmts_ptr, return_stmts_ptr)
      else
        Unparse_unformatted_func_params(outfile, implicit_stmts_ptr,
          param_stmts_ptr, return_stmts_ptr);
    end;
end; {procedure Unparse_params}


function Found_first_stmt(stmt_ptr: stmt_ptr_type): boolean;
var
  first_stmt: boolean;
begin
  first_stmt := true;

  if stmt_ptr^.stmt_info_ptr <> nil then
    if stmt_ptr^.stmt_info_ptr^.stmt_number > 1 then
      first_stmt := false;

  Found_first_stmt := first_stmt;
end; {function Found_first_stmt}


procedure Unparse_proc_stmt(var outfile: text;
  stmt_ptr: stmt_ptr_type);
var
  code_ptr: code_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
begin
  with stmt_ptr^ do
    begin
      code_ptr := code_ptr_type(stmt_code_ref);

      {**********************}
      { unparse shader stmts }
      {**********************}
      if (code_ptr^.kind = object_code) then
        if stmt_data_ptr <> nil then
          with stmt_data_ptr^ do
            begin
              if shader_stmt_ptr <> nil then
                begin
                  Unparse_stmt(outfile, shader_stmt_ptr);
                  Unparse_space(outfile);
                end;

              if edge_shader_stmt_ptr <> nil then
                begin
                  Unparse_stmt(outfile, edge_shader_stmt_ptr);
                  Unparse_space(outfile);
                end;
            end;

      expr_ptr := stmt_ptr^.stmt_name_ptr;
      if (expr_ptr^.kind = struct_deref) then
        expr_ptr := expr_ptr^.field_expr_ptr;

      {*************************************}
      { unparse method name and designators }
      {*************************************}
      if Found_first_stmt(stmt_ptr) then
        begin
          Unparse_method_data(outfile, stmt_ptr);
          Unparse_expr(outfile, stmt_ptr^.stmt_name_ptr);
          stmt_attributes_ptr := Get_stmt_attributes(stmt_ptr);
          Unparse_dynamic_level(outfile, stmt_attributes_ptr);
        end;

      {******************************}
      { unparse procedural paramters }
      {******************************}
      expr_attributes_ptr := Get_expr_attributes(expr_ptr);
      code_attributes_ptr :=
        expr_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr;
      Unparse_params(outfile, stmt_ptr, code_attributes_ptr);
    end; {with}
end; {procedure Unparse_proc_stmt}


procedure Unparse_func_stmt(var outfile: text;
  stmt_ptr: stmt_ptr_type);
var
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
begin
  with stmt_ptr^ do
    begin
      expr_ptr := stmt_ptr^.stmt_name_ptr;
      if (expr_ptr^.kind = struct_deref) then
        expr_ptr := expr_ptr^.field_expr_ptr;

      {*************************************}
      { unparse method name and designators }
      {*************************************}
      if Found_first_stmt(stmt_ptr) then
        begin
          Unparse_method_data(outfile, stmt_ptr);
          Unparse_expr(outfile, expr_ptr);
          stmt_attributes_ptr := Get_stmt_attributes(stmt_ptr);
          Unparse_dynamic_level(outfile, stmt_attributes_ptr);
        end;

      {*******************************}
      { unparse functional parameters }
      {*******************************}
      expr_attributes_ptr := Get_expr_attributes(expr_ptr);
      code_attributes_ptr :=
        expr_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr;
      Unparse_params(outfile, stmt_ptr, code_attributes_ptr);
    end; {with}
end; {procedure Unparse_func_stmt}


end.

