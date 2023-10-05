unit main_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           main_unparser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module traverses the syntax tree and writes out    }
{       the original program declarations from it.              }
{       This is useful for debugging and to tell if the         }
{       parsers have produced the correct syntax tree.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  syntax_trees;


{**********************************}
{ routines to unparse syntax trees }
{**********************************}
procedure Unparse(var outfile: text;
  syntax_tree_ptr: syntax_tree_ptr_type);


implementation
uses
  strings, exprs, stmts, decls, unparser, term_unparser, expr_unparser,
    stmt_unparser, decl_unparser;


procedure Unparse_tasks(var outfile: text;
  stmt_ptr: stmt_ptr_type);
begin
  while (stmt_ptr <> nil) do
    begin
      Unparse_expr(outfile, stmt_ptr^.stmt_name_ptr);
      if (stmt_ptr^.next <> nil) then
        Unparse_str(outfile, ', ');
      stmt_ptr := stmt_ptr^.next;
    end;
end; {procedure Unparse_tasks}


procedure Unparse_syntax_tree(var outfile: text;
  syntax_tree_ptr: syntax_tree_ptr_type);
var
  file_name: string_type;
begin
  if (syntax_tree_ptr <> nil) then
    with syntax_tree_ptr^ do
      begin
        case kind of

          {****************************}
          { root of entire syntax tree }
          {****************************}
          root_tree:
            begin
              Indent(outfile);
              if stmts_ptr <> nil then
                begin
                  Unparse_str(outfile, 'do');
                  Unparse_space(outfile);

                  Unparse_tasks(outfile, stmts_ptr);
                  Unparseln(outfile, ';');

                  Unparseln(outfile, '');
                  Unparseln(outfile, '');
                end;

              if false then
                if show_implicit then
                  begin
                    Unparse_decls(outfile, implicit_decls_ptr);
                    Unparse(outfile, implicit_includes_ptr);
                  end;

              if root_includes_ptr <> nil then
                begin
                  Unparse(outfile, root_includes_ptr);
                  Unparseln(outfile, '');
                  Unparseln(outfile, '');
                end;
              Unparse_decls(outfile, decls_ptr);
            end;

          {*******************************}
          { declarations from other files }
          {*******************************}
          include_tree:
            begin
              if show_includes then
                begin
                  Unparse(outfile, includes_ptr);
                  Unparse_decls(outfile, include_decls_ptr);
                end
              else
                begin
                  {******************************}
                  { lookup and convert file name }
                  {******************************}
                  file_name := Get_include(include_index);
                  file_name := Change_str_prefix(file_name, 'smpl_', 'sage_');
                  file_name := Change_str_suffix(file_name, '.smpl', '.sage');

                  Unparse_str(outfile, 'include');
                  Unparse_space(outfile);
                  Unparse_str(outfile, Quotate_str(file_name));
                  Unparseln(outfile, ';');
                end;
            end;

        end; {case}
      end; {with}
end; {procedure Unparse_syntax_tree}


procedure Unparse(var outfile: text;
  syntax_tree_ptr: syntax_tree_ptr_type);
begin
  while (syntax_tree_ptr <> nil) do
    begin
      Unparse_syntax_tree(outfile, syntax_tree_ptr);
      syntax_tree_ptr := syntax_tree_ptr^.next;
    end;
end; {procedure Unparse}


end.

