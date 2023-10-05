unit instruct_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          instruct_unparser            3d       }
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
  stmts;

{********************}
{ unparse statements }
{********************}
procedure Unparse_instruct(var outfile: text;
  stmt_ptr: stmt_ptr_type);
procedure Unparse_instructs(var outfile: text;
  stmt_ptr: stmt_ptr_type);


implementation
uses
  exprs, instructs, term_unparser, expr_unparser;


procedure Unparse_instruct(var outfile: text;
  stmt_ptr: stmt_ptr_type);
var
  instruct_ptr: instruct_ptr_type;
begin
  if (stmt_ptr <> nil) then
    if stmt_ptr^.kind = built_in_stmt then
      begin
        instruct_ptr := instruct_ptr_type(stmt_ptr^.instruct_ptr);
        case instruct_ptr^.kind of

          {******************}
          { input statements }
          {******************}
          boolean_read..read_newline:
            begin
              if stmt_ptr^.stmt_info_ptr^.stmt_number = 1 then
                Unparse_str(outfile, 'read');

              if (instruct_ptr^.argument_ptr <> nil) or
                (stmt_ptr^.stmt_info_ptr^.stmt_number > 1) then
                Unparse_space(outfile);
              Unparse_expr(outfile, instruct_ptr^.argument_ptr);
            end;

          {*******************}
          { output statements }
          {*******************}
          boolean_write..write_newline:
            begin
              if stmt_ptr^.stmt_info_ptr^.stmt_number = 1 then
                Unparse_str(outfile, 'write');

              if (instruct_ptr^.argument_ptr <> nil) or
                (stmt_ptr^.stmt_info_ptr^.stmt_number > 1) then
                Unparse_space(outfile);
              Unparse_expr(outfile, instruct_ptr^.argument_ptr);
            end;

        end;
      end;
end; {procedure Unparse_instruct}


procedure Unparse_instructs(var outfile: text;
  stmt_ptr: stmt_ptr_type);
begin
  while (stmt_ptr <> nil) do
    begin
      Unparse_instruct(outfile, stmt_ptr);
      stmt_ptr := stmt_ptr^.next;
    end;
end; {procedure Unparse_instructs}


end.
