unit comment_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           comment_parser              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse expressions      }
{       into an abstract syntax tree representation.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  exprs, stmts, decls;


{***************************************}
{ routines to parse expression comments }
{***************************************}
procedure Get_prev_expr_info(var expr_info_ptr: expr_info_ptr_type);
procedure Get_post_expr_info(var expr_info_ptr: expr_info_ptr_type);

{**************************************}
{ routines to parse statement comments }
{**************************************}
procedure Get_prev_stmt_info(var stmt_info_ptr: stmt_info_ptr_type);
procedure Get_post_stmt_info(var stmt_info_ptr: stmt_info_ptr_type);

{****************************************}
{ routines to parse declaration comments }
{****************************************}
procedure Get_prev_decl_info(var decl_info_ptr: decl_info_ptr_type);
procedure Get_post_decl_info(var decl_info_ptr: decl_info_ptr_type);


implementation
uses
  comments, parser, scanner, tokenizer;


{***********************************}
{ routines to parse expression info }
{***********************************}


procedure Get_prev_expr_info(var expr_info_ptr: expr_info_ptr_type);
var
  comments_ptr: comments_ptr_type;
begin
  {*************************************************}
  { create new expr info only if there are comments }
  {*************************************************}
  if parsing_ok then
    begin
      if expr_info_ptr <> nil then
        begin
          Get_prev_token_comments(expr_info_ptr^.comments_ptr);
        end
      else
        begin
          comments_ptr := nil;
          Get_prev_token_comments(comments_ptr);

          if comments_ptr <> nil then
            begin
              expr_info_ptr := New_expr_info;
              expr_info_ptr^.comments_ptr := comments_ptr;
            end;
        end;
    end;
end; {procedure Get_prev_expr_info}


procedure Get_post_expr_info(var expr_info_ptr: expr_info_ptr_type);
var
  comments_ptr: comments_ptr_type;
begin
  {*************************************************}
  { create new expr info only if there are comments }
  {*************************************************}
  if parsing_ok then
    begin
      if expr_info_ptr <> nil then
        begin
          Get_post_token_comments(expr_info_ptr^.comments_ptr);
        end
      else
        begin
          comments_ptr := nil;
          Get_post_token_comments(comments_ptr);

          if comments_ptr <> nil then
            begin
              expr_info_ptr := New_expr_info;
              expr_info_ptr^.comments_ptr := comments_ptr;
            end;
        end;
    end;
end; {procedure Get_post_expr_info}


{**********************************}
{ routines to parse statement info }
{**********************************}


procedure Get_prev_stmt_info(var stmt_info_ptr: stmt_info_ptr_type);
begin
  {************************************************************}
  { always create stmt info to store comments and line numbers }
  {************************************************************}
  if parsing_ok then
    begin
      stmt_info_ptr := New_stmt_info;
      Get_prev_token_comments(stmt_info_ptr^.comments_ptr);
      stmt_info_ptr^.line_number := Get_line_number;
    end;
end; {procedure Get_prev_stmt_info}


procedure Get_post_stmt_info(var stmt_info_ptr: stmt_info_ptr_type);
begin
  if parsing_ok then
    Get_post_token_comments(stmt_info_ptr^.comments_ptr);
end; {procedure Get_post_stmt_info}


{****************************************}
{ routines to parse declaration comments }
{****************************************}


procedure Get_prev_decl_info(var decl_info_ptr: decl_info_ptr_type);
begin
  {******************************************************************}
  { always create decl info to store comments, line and file numbers }
  {******************************************************************}
  if parsing_ok then
    begin
      decl_info_ptr := New_decl_info;
      Get_prev_token_comments(decl_info_ptr^.comments_ptr);
      decl_info_ptr^.line_number := Get_line_number;
      decl_info_ptr^.file_number := current_file_index;
    end;
end; {procedure Get_prev_decl_info}


procedure Get_post_decl_info(var decl_info_ptr: decl_info_ptr_type);
begin
  if parsing_ok then
    Get_post_token_comments(decl_info_ptr^.comments_ptr);
end; {procedure Get_post_decl_info}


end.
