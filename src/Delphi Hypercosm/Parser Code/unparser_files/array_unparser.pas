unit array_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           array_unparser              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module traverses the syntax tree and writes out    }
{       the original program expressions from it.               }
{       This is useful for debugging and to tell if the         }
{       parsers have produced the correct syntax tree.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  comments, arrays, exprs;


{**********************************}
{ routines to unparse array bounds }
{**********************************}
procedure Unparse_array_bounds(var outfile: text;
  array_bounds_ptr: array_bounds_ptr_type);
procedure Unparse_array_bounds_list(var outfile: text;
  array_bounds_list_ptr: array_bounds_list_ptr_type);

{***********************************}
{ routines to unparse array indices }
{***********************************}
procedure Unparse_array_index(var outfile: text;
  array_index_ptr: array_index_ptr_type);
procedure Unparse_array_index_list(var outfile: text;
  array_index_list_ptr: array_index_list_ptr_type);

{*************************************}
{ routines to unparse array subranges }
{*************************************}
procedure Unparse_array_subrange(var outfile: text;
  array_subrange_ptr: array_subrange_ptr_type);


implementation
uses
  strings, string_io, stmts, decls, type_decls, unparser, term_unparser,
    expr_unparser;


{**********************************}
{ routines to unparse array bounds }
{**********************************}


procedure Unparse_array_bounds(var outfile: text;
  array_bounds_ptr: array_bounds_ptr_type);
begin
  if array_bounds_ptr <> nil then
    with array_bounds_ptr^ do
      begin
        if (min_expr_ptr <> nil) or (max_expr_ptr <> nil) or (array_index_ref <>
          nil) then
          begin
            if (min_expr_ptr <> nil) then
              Unparse_expr(outfile, expr_ptr_type(min_expr_ptr));

            Unparse_str(outfile, '..');

            if (max_expr_ptr <> nil) then
              Unparse_expr(outfile, expr_ptr_type(max_expr_ptr));
          end;
      end;
end; {procedure Unparse_array_bounds}


procedure Unparse_array_bounds_list(var outfile: text;
  array_bounds_list_ptr: array_bounds_list_ptr_type);
var
  array_bounds_ptr: array_bounds_ptr_type;
  counter: integer;
begin
  if (array_bounds_list_ptr <> nil) then
    begin
      Unparse_str(outfile, '[');
      array_bounds_ptr := array_bounds_list_ptr^.first;

      if array_bounds_ptr <> nil then
        begin
          {*******************************}
          { unparse explicit array bounds }
          {*******************************}
          while (array_bounds_ptr <> nil) do
            begin
              Unparse_array_bounds(outfile, array_bounds_ptr);

              if (array_bounds_ptr^.next <> nil) then
                Unparse_str(outfile, ', ');
              array_bounds_ptr := array_bounds_ptr^.next;
            end;
        end
      else
        begin
          {*******************************}
          { unparse abstract array bounds }
          {*******************************}
          for counter := 1 to array_bounds_list_ptr^.dimensions - 1 do
            write(',');
        end;

      Unparse_char(outfile, ']');
    end;
end; {procedure Unparse_array_bounds_list}


{***********************************}
{ routines to unparse array indices }
{***********************************}


procedure Unparse_array_index(var outfile: text;
  array_index_ptr: array_index_ptr_type);
begin
  if (array_index_ptr^.array_bounds_ref <> nil) then
    Unparse_array_bounds(outfile, array_index_ptr^.array_bounds_ref)
  else
    Unparse_expr(outfile, expr_ptr_type(array_index_ptr^.index_expr_ptr));
end; {procedure Unparse_array_index}


procedure Unparse_array_index_list(var outfile: text;
  array_index_list_ptr: array_index_list_ptr_type);
var
  array_index_ptr: array_index_ptr_type;
begin
  if (array_index_list_ptr <> nil) then
    begin
      Unparse_str(outfile, '[');
      array_index_ptr := array_index_list_ptr^.first;
      while (array_index_ptr <> nil) do
        begin
          Unparse_array_index(outfile, array_index_ptr);

          if (array_index_ptr^.next <> nil) then
            Unparse_str(outfile, ', ');
          array_index_ptr := array_index_ptr^.next;
        end;
      Unparse_char(outfile, ']');
    end;
end; {procedure Unparse_array_index_list}


{*************************************}
{ routines to unparse array subranges }
{*************************************}


procedure Unparse_array_subrange(var outfile: text;
  array_subrange_ptr: array_subrange_ptr_type);
begin
  if (array_subrange_ptr <> nil) then
    with array_subrange_ptr^ do
      begin
        Indent(outfile);
        Unparse_space(outfile);
        Unparseln(outfile, 'with');
        Push_margin;

        {**********************************}
        { unparse fields of array subrange }
        {**********************************}
        Indent(outfile);
        Unparse_str(outfile, 'expr = ');
        Unparse_expr(outfile, expr_ptr_type(array_expr_ptr));
        Unparseln(outfile, ';');

        Indent(outfile);
        Unparse_str(outfile, 'bounds = ');
        Unparse_array_bounds(outfile, array_bounds_ref);
        Unparseln(outfile, ';');

        Indent(outfile);
        Unparse_str(outfile, 'derefs = ');
        Unparse_str(outfile, Integer_to_str(array_derefs));
        Unparseln(outfile, ';');

        Pop_margin;
        Indent(outfile);
        Unparse_str(outfile, 'end');
        Unparseln(outfile, ';');
      end;
end; {procedure Unparse_array_subrange}


end.

