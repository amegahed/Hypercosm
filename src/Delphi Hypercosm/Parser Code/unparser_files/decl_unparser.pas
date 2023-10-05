unit decl_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           decl_unparser               3d       }
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
  strings, decls;


{**********************************}
{ routines to unparse declarations }
{**********************************}
procedure Unparse_decls(var outfile: text;
  decl_ptr: decl_ptr_type);

{********************************************}
{ routines to unparse declaration components }
{********************************************}
function Decl_kind_to_str(decl_ptr: decl_ptr_type): string_type;


implementation
uses
  decl_attributes, expr_attributes, comments, exprs, stmts,
    code_decls, type_decls, unparser, term_unparser, expr_unparser, data_unparser,
    stmt_unparser, code_unparser, type_unparser;


var
  first_decl: boolean;


function Decl_kind_to_str(decl_ptr: decl_ptr_type): string_type;
var
  code_ptr: code_ptr_type;
  type_ptr: type_ptr_type;
  str: string_type;
begin
  case decl_ptr^.kind of

    boolean_decl..reference_decl:
      str := 'variable';

    type_decl:
      begin
        type_ptr := type_ptr_type(decl_ptr^.type_ptr);
        str := Type_decl_kind_to_str(type_ptr^.kind);
      end;

    code_decl, code_reference_decl:
      begin
        code_ptr := code_ptr_type(decl_ptr^.code_ptr);
        str := Code_kind_to_str(code_ptr^.kind);
      end;

  end; {case}

  Decl_kind_to_str := str;
end; {procedure Decl_kind_to_str}


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


{***************************************}
{ routines to unparse data declarations }
{***************************************}


function Found_first_decl(decl_ptr: decl_ptr_type): boolean;
var
  first: boolean;
begin
  first := true;

  if decl_ptr^.decl_info_ptr <> nil then
    if decl_ptr^.decl_info_ptr^.decl_number > 1 then
      first := false;

  Found_first_decl := first;
end; {function Found_first_decl}


function Found_last_decl(decl_ptr: decl_ptr_type): boolean;
var
  last: boolean;
begin
  {*******************************************}
  { find if this is the last decl on the line }
  {*******************************************}
  if decl_ptr^.next = nil then
    last := true
  else if decl_ptr^.decl_info_ptr = nil then
    last := true
  else if decl_ptr^.next^.decl_info_ptr = nil then
    last := true
  else if decl_ptr^.next^.decl_info_ptr^.decl_number <=
    decl_ptr^.decl_info_ptr^.decl_number then
    last := true
  else
    last := false;

  Found_last_decl := last;
end; {function Found_last_decl}


procedure Unparse_data_modifiers(var outfile: text;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  with decl_attributes_ptr^ do
    begin
      {**********************}
      { unparse access level }
      {**********************}
      if Found_public_member(decl_attributes_ptr) then
        begin
          Unparse_str(outfile, 'public');
          Unparse_space(outfile);
        end;

      Unparse_storage_class(outfile, decl_attributes_ptr);

      if native then
        begin
          Unparse_str(outfile, 'native');
          Unparse_space(outfile);
        end;
    end; {with}
end; {procedure Unparse_data_modifiers}


procedure Unparse_data_decl(var outfile: text;
  decl_ptr: decl_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  comment_ptr: comment_ptr_type;
begin
  with decl_ptr^ do
    begin
      Indent(outfile);
      decl_attributes_ptr := Get_decl_attributes(decl_ptr);

      if Found_first_decl(decl_ptr) then
        begin
          {****************************************}
          { unparse storage class and access level }
          {****************************************}
          Unparse_data_modifiers(outfile, decl_attributes_ptr);

          {***************************}
          { unparse base type of data }
          {***************************}
          Unparse_type_attributes(outfile,
            decl_attributes_ptr^.base_type_attributes_ref);
          Unparse_space(outfile);
        end;

      {****************************}
      { unparse name of identifier }
      {****************************}
      Unparse_data_name(outfile, data_decl, decl_attributes_ptr);

      {**********************************}
      { unparse semicolon at end of line }
      {**********************************}
      if Found_last_decl(decl_ptr) then
        Unparse_char(outfile, ';')
      else
        Unparse_char(outfile, ',');

      {***************************************}
      { unparse comment at end of declaration }
      {***************************************}
      if decl_info_ptr <> nil then
        with decl_info_ptr^ do
          begin
            comment_ptr := Get_post_comments(comments_ptr);
            if comment_ptr <> nil then
              begin
                Unparse_tab(outfile);
                Unparse_comments(outfile, comment_ptr);
              end
            else
              begin
                if Found_last_decl(decl_ptr) then
                  Unparseln(outfile, '')
                else
                  Unparse_space(outfile);
              end;
          end
      else
        Unparseln(outfile, '');
    end;
end; {procedure Unparse_data_decl}


procedure Unparse_decl_spacing(var outfile: text;
  decl_ptr: decl_ptr_type;
  multiline: boolean);
var
  unparsing_field_decl: boolean;
begin
  with decl_ptr^ do
    case kind of

      boolean_decl..reference_decl:
        begin
          {************************************************************}
          { unparse two spaces between data decls and subprogram decls }
          {************************************************************}
          if (next <> nil) then
            if (next^.kind <> null_decl) then
              begin
                if (next^.kind in [type_decl, code_decl]) then
                  begin
                    unparsing_field_decl := (data_decl.data_expr_ptr^.kind in
                      [field_deref, field_offset]);
                    if not unparsing_field_decl then
                      begin
                        Unparseln(outfile, '');
                        Unparseln(outfile, '');
                      end;
                  end
                else if next^.decl_info_ptr <> nil then
                  if Get_prev_comments(next^.decl_info_ptr^.comments_ptr) <> nil
                    then
                    Unparseln(outfile, '');
              end;
        end;

      type_decl:
        begin
          if next <> nil then
            if next^.kind <> null_decl then
              begin
                if not (type_ptr_type(type_ptr)^.kind = enum_type) then
                  begin
                    Unparseln(outfile, '');
                    Unparseln(outfile, '');
                  end
                else if next^.decl_info_ptr <> nil then
                  if Get_prev_comments(next^.decl_info_ptr^.comments_ptr) <> nil
                    then
                    begin
                      Unparseln(outfile, '');
                      Unparseln(outfile, '');
                    end;
              end;
        end;

      code_decl, code_reference_decl:
        begin
          if next <> nil then
            if next^.kind <> null_decl then
              begin
                {**************}
                { actual decls }
                {**************}
                if code_ptr_type(code_ptr)^.decl_kind = actual_decl then
                  begin
                    Unparseln(outfile, '');
                    Unparseln(outfile, '');
                  end

                    {***************************}
                    { prototype / forward decls }
                    {***************************}
                else
                  begin
                    if multiline then
                      if next^.decl_info_ptr <> nil then
                        if Get_prev_comments(next^.decl_info_ptr^.comments_ptr)
                          <> nil then
                          begin
                            Unparseln(outfile, '');
                            Unparseln(outfile, '');
                          end;
                  end;
              end;
        end;

    end; {case}
end; {procedure Unparse_decl_spacing}


procedure Unparse_decl(var outfile: text;
  decl_ptr: decl_ptr_type);
var
  starting_line_number: integer;
  ending_line_number: integer;
  comment_ptr: comment_ptr_type;
  multiline: boolean;
begin
  if (decl_ptr <> nil) then
    with decl_ptr^ do
      begin
        if decl_info_ptr <> nil then
          begin
            {********************************************}
            { unparse comments at beginning of statement }
            {********************************************}
            comment_ptr := Get_prev_comments(decl_info_ptr^.comments_ptr);
            if comment_ptr <> nil then
              begin
                Unparse_comments(outfile,
                  Get_prev_comments(decl_info_ptr^.comments_ptr));
                Indent(outfile);
              end;
          end;

        starting_line_number := Unparseln_number;

        case kind of

          {*************************}
          { null or nop declaration }
          {*************************}
          null_decl:
            ;

          {***************************}
          { unparse data declarations }
          {***************************}
          boolean_decl..reference_decl:
            Unparse_data_decl(outfile, decl_ptr);

          {***************************}
          { unparse type declarations }
          {***************************}
          type_decl:
            Unparse_type_decl(outfile, decl_ptr);

          {*********************************}
          { unparse subprogram declarations }
          {*********************************}
          code_decl, code_reference_decl:
            Unparse_code_decl(outfile, decl_ptr);

        end; {case}


        if kind <> null_decl then
          begin
            ending_line_number := Unparseln_number;
            multiline := ending_line_number > starting_line_number + 1;
            Unparse_decl_spacing(outfile, decl_ptr, multiline);
          end;
      end; {with}
end; {procedure Unparse_decl}


procedure Unparse_decls(var outfile: text;
  decl_ptr: decl_ptr_type);
begin
  first_decl := true;
  while (decl_ptr <> nil) do
    begin
      Unparse_decl(outfile, decl_ptr);
      decl_ptr := decl_ptr^.next;
      first_decl := false;
    end;
end; {procedure Unparse_decls}


end.
