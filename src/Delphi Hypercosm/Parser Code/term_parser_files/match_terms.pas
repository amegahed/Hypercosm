unit match_terms;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            match_terms                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse and create       }
{       new variables and references to previously created      }
{       variables.                                              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, decl_attributes, expr_attributes, exprs, decls;


{****************************************}
{ routines for creating identifier exprs }
{****************************************}
function New_identifier(decl_attributes_ptr: decl_attributes_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type): expr_ptr_type;

{*********************************************}
{ routines to simply parse unique identifiers }
{*********************************************}
procedure Match_unique_id(var name: string_type);
procedure Write_decl_location(decl_info_ptr: decl_info_ptr_type);

{*********************************************************}
{ routines to parse and create newly declared identifiers }
{*********************************************************}
procedure Match_new_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
procedure Match_new_type_id(decl_attributes_ptr: decl_attributes_ptr_type);

{***********************************************************}
{ routines to implicitly parse new ids (no tokens consumed) }
{***********************************************************}
procedure Make_implicit_new_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
procedure Make_implicit_new_type_id(id: string_type;
  decl_attributes_ptr: decl_attributes_ptr_type);

{*********************************************************}
{ routines to parse references to previously declared ids }
{*********************************************************}
procedure Match_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Match_local_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Match_static_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Match_global_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

{***********************************************************}
{ routines to implicitly parse id refs (no tokens consumed) }
{***********************************************************}
procedure Make_implicit_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Make_implicit_local_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Make_implicit_static_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Make_implicit_global_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);


implementation
uses
  stmt_attributes, tokens, tokenizer, parser, scoping, comment_parser,
    implicit_derefs, syntax_trees;


procedure Write_decl_location(decl_info_ptr: decl_info_ptr_type);
begin
  write('line #', decl_info_ptr^.line_number: 1);
  write(' of ', Quotate_str(Get_include(decl_info_ptr^.file_number)));
end; {procedure Write_decl_location}


{****************************************}
{ routines for creating identifier exprs }
{****************************************}


function New_identifier(decl_attributes_ptr: decl_attributes_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type): expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
  expr_info_ptr: expr_info_ptr_type;
begin
  case decl_attributes_ptr^.kind of

    data_decl_attributes:
      begin
        expr_attributes_ptr :=
          New_variable_expr_attributes(decl_attributes_ptr);
        if (decl_attributes_ptr^.static_level = 1) then
          expr_ptr := New_expr(global_identifier)
        else
          expr_ptr := New_expr(local_identifier);
      end;

    field_decl_attributes:
      begin
        expr_attributes_ptr :=
          New_variable_expr_attributes(decl_attributes_ptr);
        expr_ptr := New_expr(field_identifier);
      end;

  else
    expr_ptr := nil;
  end; {case}

  expr_info_ptr := New_expr_info;
  Set_expr_info(expr_ptr, expr_info_ptr);
  Set_expr_attributes(expr_ptr, expr_attributes_ptr);

  New_identifier := expr_ptr;
end; {function New_identifier}


{**********************************************}
{ routines to parse newly declared identifiers }
{**********************************************}

procedure Match_unique_id(var name: string_type);
const
  predict_set = [id_tok];
var
  new_decl_attributes_ptr: decl_attributes_ptr_type;
  new_stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        if Found_local_id(next_token.id, new_decl_attributes_ptr,
          new_stmt_attributes_ptr) then
          begin
            Parse_error;
            writeln(Quotate_str(next_token.id), ' was already declared.');
            Write_decl_location(decl_ptr_type(new_decl_attributes_ptr^.decl_ref)^.decl_info_ptr);
            writeln;
            error_reported := true;
            decl_problems := true;
            parsing_ok := false;
          end
        else
          begin
            name := next_token.id;
            Get_next_token;
          end;
      end
    else
      begin
        Parse_error;
        writeln('Expected an identifier here.');
        error_reported := true;
      end;
end; {procedure Match_unique_id}


procedure Match_new_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
const
  predict_set = [id_tok];
var
  new_decl_attributes_ptr: decl_attributes_ptr_type;
  new_stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        if Found_local_id(next_token.id, new_decl_attributes_ptr,
          new_stmt_attributes_ptr) then
          begin
            Parse_error;
            writeln(Quotate_str(next_token.id), ' was already declared.');
            Write_decl_location(decl_ptr_type(new_decl_attributes_ptr^.decl_ref)^.decl_info_ptr);
            writeln;
            error_reported := true;
            decl_problems := true;
            parsing_ok := false;
          end
        else
          begin
            Store_id(next_token.id, decl_attributes_ptr);
            expr_ptr := New_identifier(decl_attributes_ptr,
              expr_attributes_ptr);
            Get_prev_expr_info(expr_ptr^.expr_info_ptr);
            Make_implicit_derefs(expr_ptr, expr_attributes_ptr, nil);
            Get_next_token;
          end;
      end
    else
      begin
        Parse_error;
        writeln('Expected an identifier here.');
        error_reported := true;
      end;
end; {procedure Match_new_id}


procedure Match_new_type_id(decl_attributes_ptr: decl_attributes_ptr_type);
const
  predict_set = [id_tok];
var
  new_decl_attributes_ptr: decl_attributes_ptr_type;
  new_stmt_attributes_ptr: stmt_attributes_ptr_type;
  token: token_type;
  id: string;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        token := next_token;
        token.kind := type_id_tok;
        id := Token_to_id(token);

        if Found_local_id(id, new_decl_attributes_ptr, new_stmt_attributes_ptr)
          then
          begin
            Parse_error;
            writeln(Quotate_str(next_token.id), ' was already declared.');
            Write_decl_location(decl_ptr_type(new_decl_attributes_ptr^.decl_ref)^.decl_info_ptr);
            writeln;
            error_reported := true;
            decl_problems := true;
            parsing_ok := false;
          end
        else
          begin
            Store_id(id, decl_attributes_ptr);
            decl_attributes_ptr^.type_attributes_ptr^.id_ptr :=
              decl_attributes_ptr^.id_ptr;
            Get_next_token;
          end;
      end
    else
      begin
        Parse_error;
        writeln('Expected an identifier here.');
        error_reported := true;
      end;
end; {procedure Match_new_type_id}


{***********************************************************}
{ routines to implicitly parse new ids (no tokens consumed) }
{***********************************************************}


procedure Make_implicit_new_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  new_decl_attributes_ptr: decl_attributes_ptr_type;
  new_stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      if Found_local_id(id, new_decl_attributes_ptr, new_stmt_attributes_ptr)
        then
        begin
          Parse_error;
          writeln(Quotate_str(id), ' was already declared.');
          Write_decl_location(decl_ptr_type(new_decl_attributes_ptr^.decl_ref)^.decl_info_ptr);
          writeln;
          error_reported := true;
          decl_problems := true;
          parsing_ok := false;
        end
      else
        begin
          Store_id(id, decl_attributes_ptr);
          expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);
          Make_implicit_derefs(expr_ptr, expr_attributes_ptr, nil);
        end;
    end;
end; {procedure Make_implicit_new_id}


procedure Make_implicit_new_type_id(id: string_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  new_decl_attributes_ptr: decl_attributes_ptr_type;
  new_stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      if Found_local_id(id, new_decl_attributes_ptr, new_stmt_attributes_ptr)
        then
        begin
          Parse_error;
          writeln(Quotate_str(id), ' was already declared.');
          Write_decl_location(decl_ptr_type(new_decl_attributes_ptr^.decl_ref)^.decl_info_ptr);
          writeln;
          error_reported := true;
          decl_problems := true;
          parsing_ok := false;
        end
      else
        begin
          Store_id(id, decl_attributes_ptr);
          decl_attributes_ptr^.type_attributes_ptr^.id_ptr :=
            decl_attributes_ptr^.id_ptr;
        end;
    end;
end; {procedure Make_implicit_new_id}


{*********************************************************}
{ routines to parse references to previously declared ids }
{*********************************************************}


procedure Check_id_attributes(decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      if global_mode then
        if (decl_attributes_ptr^.static_level <> 1) then
          if not (decl_attributes_ptr^.scope_decl_attributes_ptr^.static) then
            if (stmt_attributes_ptr = nil) then
              begin
                Parse_error;
                writeln('Expected a static or global expression here.');
                decl_problems := true;
                error_reported := true;
                parsing_ok := false;
              end;

      if static_mode then
        if (decl_attributes_ptr^.static_level <> 1) then
          begin
            Parse_error;
            writeln('Expected a static or literal expression here.');
            decl_problems := true;
            error_reported := true;
            parsing_ok := false;
          end;
    end;
end; {procedure Check_id_attributes}


procedure Match_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [id_tok];
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        if Found_id(next_token.id, decl_attributes_ptr, stmt_attributes_ptr)
          then
          Check_id_attributes(decl_attributes_ptr, stmt_attributes_ptr)
        else
          begin
            Parse_error;
            writeln(Quotate_str(next_token.id), ' was not declared.');
            decl_problems := true;
            error_reported := true;
            parsing_ok := false;
          end;

        if parsing_ok then
          begin
            expr_ptr := New_identifier(decl_attributes_ptr,
              expr_attributes_ptr);
            Get_prev_expr_info(expr_ptr^.expr_info_ptr);
            Make_implicit_derefs(expr_ptr, expr_attributes_ptr,
              stmt_attributes_ptr);
            Get_next_token;
          end
        else
          begin
            expr_ptr := nil;
            expr_attributes_ptr := nil;
          end;
      end
    else
      begin
        Parse_error;
        writeln('Expected an identifier here.');
        error_reported := true;
      end;
end; {procedure Match_id}


procedure Match_local_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [id_tok, static_id_tok];
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        if Found_local_id(next_token.id, decl_attributes_ptr,
          stmt_attributes_ptr) then
          Check_id_attributes(decl_attributes_ptr, stmt_attributes_ptr)
        else
          begin
            Parse_error;
            scope_decl_attributes_ptr := Get_scope_decl_attributes;
            write(Quotate_str(next_token.id), ' is not a valid member of ');
            writeln(Quotate_str(Get_decl_attributes_name(scope_decl_attributes_ptr)), '.');
            decl_problems := true;
            error_reported := true;
            parsing_ok := false;
          end;

        if parsing_ok then
          begin
            expr_ptr := New_identifier(decl_attributes_ptr,
              expr_attributes_ptr);
            Get_prev_expr_info(expr_ptr^.expr_info_ptr);
            Make_implicit_derefs(expr_ptr, expr_attributes_ptr,
              stmt_attributes_ptr);
            Get_next_token;
          end
        else
          begin
            expr_ptr := nil;
            expr_attributes_ptr := nil;
          end;
      end
    else
      begin
        Parse_error;
        writeln('Expected an identifier here.');
        error_reported := true;
      end;
end; {procedure Match_local_id}


procedure Match_static_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [static_id_tok];
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        if Found_static_id(next_token.id, decl_attributes_ptr,
          stmt_attributes_ptr) then
          Check_id_attributes(decl_attributes_ptr, stmt_attributes_ptr)
        else
          begin
            Parse_error;
            writeln(Quotate_str(next_token.id), ' was not declared.');
            decl_problems := true;
            error_reported := true;
            parsing_ok := false;
          end;

        if parsing_ok then
          begin
            expr_ptr := New_identifier(decl_attributes_ptr,
              expr_attributes_ptr);
            Get_prev_expr_info(expr_ptr^.expr_info_ptr);
            Make_implicit_derefs(expr_ptr, expr_attributes_ptr,
              stmt_attributes_ptr);
            Get_next_token;
          end
        else
          begin
            expr_ptr := nil;
            expr_attributes_ptr := nil;
          end;
      end
    else
      begin
        Parse_error;
        writeln('Expected an identifier here.');
        error_reported := true;
      end;
end; {procedure Match_static_id}


procedure Match_global_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [id_tok];
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        if Found_global_id(next_token.id, decl_attributes_ptr,
          stmt_attributes_ptr) then
          Check_id_attributes(decl_attributes_ptr, stmt_attributes_ptr)
        else
          begin
            Parse_error;
            writeln(Quotate_str(next_token.id), ' was not declared.');
            decl_problems := true;
            error_reported := true;
            parsing_ok := false;
          end;

        if parsing_ok then
          begin
            expr_ptr := New_identifier(decl_attributes_ptr,
              expr_attributes_ptr);
            Get_prev_expr_info(expr_ptr^.expr_info_ptr);
            Make_implicit_derefs(expr_ptr, expr_attributes_ptr,
              stmt_attributes_ptr);
            Get_next_token;
          end
        else
          begin
            expr_ptr := nil;
            expr_attributes_ptr := nil;
          end;
      end
    else
      begin
        Parse_error;
        writeln('Expected an identifier here.');
        error_reported := true;
      end;
end; {procedure Match_global_id}


{***********************************************************}
{ routines to implicitly parse id refs (no tokens consumed) }
{***********************************************************}


procedure Make_implicit_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      if Found_id(id, decl_attributes_ptr, stmt_attributes_ptr) then
        Check_id_attributes(decl_attributes_ptr, stmt_attributes_ptr)
      else
        begin
          Parse_error;
          writeln(Quotate_str(id), ' was not declared.');
          decl_problems := true;
          error_reported := true;
          parsing_ok := false;
        end;

      if parsing_ok then
        begin
          expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);
          Make_implicit_derefs(expr_ptr, expr_attributes_ptr,
            stmt_attributes_ptr);
        end
      else
        begin
          expr_ptr := nil;
          expr_attributes_ptr := nil;
        end;
    end;
end; {procedure Make_implicit_id}


procedure Make_implicit_local_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      if Found_local_id(id, decl_attributes_ptr, stmt_attributes_ptr) then
        Check_id_attributes(decl_attributes_ptr, stmt_attributes_ptr)
      else
        begin
          Parse_error;
          scope_decl_attributes_ptr := Get_scope_decl_attributes;
          write(Quotate_str(id), ' is not a valid member of ');
          writeln(Quotate_str(Get_decl_attributes_name(scope_decl_attributes_ptr)), '.');
          decl_problems := true;
          error_reported := true;
          parsing_ok := false;
        end;

      if parsing_ok then
        begin
          expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);
          Make_implicit_derefs(expr_ptr, expr_attributes_ptr,
            stmt_attributes_ptr);
        end
      else
        begin
          expr_ptr := nil;
          expr_attributes_ptr := nil;
        end;
    end;
end; {procedure Make_implicit_local_id}


procedure Make_implicit_static_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      if Found_static_id(id, decl_attributes_ptr, stmt_attributes_ptr) then
        Check_id_attributes(decl_attributes_ptr, stmt_attributes_ptr)
      else
        begin
          Parse_error;
          writeln(Quotate_str(id), ' was not declared.');
          decl_problems := true;
          error_reported := true;
          parsing_ok := false;
        end;

      if parsing_ok then
        begin
          expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);
          Make_implicit_derefs(expr_ptr, expr_attributes_ptr,
            stmt_attributes_ptr);
        end
      else
        begin
          expr_ptr := nil;
          expr_attributes_ptr := nil;
        end;
    end;
end; {procedure Make_implicit_static_id}


procedure Make_implicit_global_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      if Found_global_id(id, decl_attributes_ptr, stmt_attributes_ptr) then
        Check_id_attributes(decl_attributes_ptr, stmt_attributes_ptr)
      else
        begin
          Parse_error;
          writeln(Quotate_str(id), ' was not declared.');
          decl_problems := true;
          error_reported := true;
          parsing_ok := false;
        end;

      if parsing_ok then
        begin
          expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);
          Make_implicit_derefs(expr_ptr, expr_attributes_ptr,
            stmt_attributes_ptr);
        end
      else
        begin
          expr_ptr := nil;
          expr_attributes_ptr := nil;
        end;
    end;
end; {procedure Make_implicit_global_id}


end.
