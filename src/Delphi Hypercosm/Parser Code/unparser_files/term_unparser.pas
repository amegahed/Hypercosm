unit term_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            term_unparser              3d       }
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
  comments;


{*********************}
{ formatting routines }
{*********************}
procedure Unparse_str(var outfile: text;
  str: string);
procedure Unparseln(var outfile: text;
  str: string);
procedure Unparse_char(var outfile: text;
  ch: char);

procedure Push_margin;
procedure Pop_margin;
function Unparseln_number: integer;

procedure Indent(var outfile: text);
procedure Check_line_break(var outfile: text);
procedure Check_wraparound(var outfile: text);

procedure Unparse_tab(var outfile: text);
procedure Unparse_space(var outfile: text);
procedure Unparse_comments(var outfile: text;
  comment_ptr: comment_ptr_type);


implementation
uses
  chars, strings, string_structs, unparser;


var
  digit_to_char: array[0..9] of char;

  {**************}
  { status flags }
  {**************}
  indented, no_break: boolean;
  line_length, line_number: integer;
  indent_level, max_indent_level: integer;
  comment_nesting_level: integer;
  unparsed_wraparound: boolean;
  unparsed_blank_line: boolean;
  unparsed_space: boolean;


procedure Break_line(var outfile: text);
begin
  writeln(outfile);
  line_number := line_number + 1;
  line_length := 0;
  indented := false;
  unparsed_blank_line := true;
  unparsed_space := false;
  unparsed_wraparound := true;

  if indented_wraparound then
    begin
      Push_margin;
      Indent(outfile);
      Pop_margin;
    end
  else
    begin
      Indent(outfile);
    end;
end; {procedure Break_line}


procedure Check_line_break(var outfile: text);
begin
  if line_length > max_line_length then
    Break_line(outfile);
end; {procedure Check_line_break}


procedure Check_wraparound(var outfile: text);
begin
  Check_line_break(outfile);
  if unparsed_wraparound and not (unparsed_blank_line) then
    begin
      Unparseln(outfile, '');
      Indent(outfile);
    end;
end; {procedure Check_wraparound}


procedure Breakln(var outfile: text;
  str: string);
begin
  if not no_break then
    if (line_length + length(str)) > (line_break_length) then
      Break_line(outfile);
end; {procedure Breakln}


procedure Unparse_tab(var outfile: text);
var
  next_tab: integer;
  counter, tabs: integer;
begin
  next_tab := ((line_length + tabsize) div tabsize) * tabsize;
  tabs := next_tab - line_length;

  if do_tabs then
    write(outfile, tab)
  else
    for counter := 1 to tabs do
      write(outfile, ' ');

  line_length := line_length + tabs;
end; {procedure Unparse_tab}


procedure Unparse_space(var outfile: text);
begin
  if not unparsed_blank_line then
    if not unparsed_space then
      begin
        write(outfile, ' ');
        line_length := line_length + 1;
      end;
  unparsed_space := true;
end; {procedure Unparse_space}


procedure Indent(var outfile: text);
var
  counter: integer;
begin
  if not indented then
    begin
      if indent_level < max_indent_level then
        begin
          for counter := 1 to indent_level do
            Unparse_tab(outfile);
        end
      else
        begin
          for counter := 1 to max_indent_level do
            Unparse_tab(outfile);
        end;
    end;
  indented := true;
end; {procedure Indent}


procedure Unparse_str(var outfile: text;
  str: string);
begin
  Breakln(outfile, str);
  write(outfile, str);
  line_length := line_length + length(str);
  unparsed_blank_line := false;
  unparsed_space := false;
end; {procedure Unparse_str}


procedure Unparse_char(var outfile: text;
  ch: char);
begin
  {**************************************}
  { note: Unparse_char does not autowrap }
  {**************************************}
  write(outfile, ch);
  line_length := line_length + 1;
  unparsed_blank_line := false;
  unparsed_space := false;
end; {procedure Unparse_char}


procedure Unparseln(var outfile: text;
  str: string);
begin
  if (length(str) > 1) then
    Breakln(outfile, str);
  writeln(outfile, str);
  line_number := line_number + 1;
  line_length := 0;
  indented := false;
  unparsed_blank_line := true;
  unparsed_space := false;
  unparsed_wraparound := false;
end; {procedure Unparseln}


procedure Unparse_text(var outfile: text;
  str: string);
var
  str_length: integer;
  counter: integer;
  ch, last_ch: char;
  done, temp: boolean;
begin
  counter := 1;
  str_length := length(str);
  done := false;
  last_ch := null;

  {*********************************}
  { always translate tabs to spaces }
  {*********************************}
  temp := do_tabs;
  do_tabs := false;

  while (counter <= str_length) and (not done) do
    begin
      ch := str[counter];
      counter := counter + 1;

      if (ch = tab) then
        begin
          Unparse_tab(outfile);
        end
      else if (ch = CR) then
        begin
          if (last_ch <> NL) then
            begin
              Unparseln(outfile, '');
            end;
        end
      else if (ch = NL) then
        begin
          if (last_ch <> CR) then
            begin
              Unparseln(outfile, '');
            end;
        end
      else if (ch = null) then
        begin
          done := true;
        end
      else
        begin
          Unparse_char(outfile, ch);
        end;

      last_ch := ch;
    end; {while}

  {******************************}
  { go back to previous tab mode }
  {******************************}
  do_tabs := temp;
end; {procedure Unparse_text}


procedure Unparse_string(var outfile: text;
  string_ptr: string_ptr_type);
var
  string_node_ptr: string_node_ptr_type;
begin
  if string_ptr <> nil then
    begin
      string_node_ptr := string_ptr^.first;
      while string_node_ptr <> nil do
        begin
          Unparse_text(outfile, string_node_ptr^.str);
          string_node_ptr := string_node_ptr^.next;
        end;
    end;
end; {procedure Unparse_string}


function Unparseln_number: integer;
begin
  Unparseln_number := line_number;
end; {function Unparseln_number}


procedure Push_margin;
begin
  indent_level := indent_level + 1;
end; {procedure Push_margin}


procedure Pop_margin;
begin
  indent_level := indent_level - 1;
end; {procedure Pop_margin}


procedure Unparse_line_comment(var outfile: text;
  string_ptr: string_ptr_type);
begin
  Indent(outfile);
  Unparse_str(outfile, '//');
  Unparse_string(outfile, string_ptr);
  Unparseln(outfile, '');
end; {procedure Unparse_comment}


procedure Unparse_eoln_comment(var outfile: text;
  string_ptr: string_ptr_type);
begin
  Unparse_tab(outfile);
  Unparse_str(outfile, '//');
  Unparse_string(outfile, string_ptr);
  Unparseln(outfile, '');
end; {procedure Unparse_eoln_comment}


procedure Unparse_block_comment(var outfile: text;
  comment_ptr: string_tree_ptr_type);
var
  string_tree_node_ptr: string_tree_node_ptr_type;
begin
  while comment_ptr <> nil do
    begin
      if comment_nesting_level = 0 then
        Indent(outfile);
      Unparse_str(outfile, '{');

      string_tree_node_ptr := comment_ptr^.first;
      while string_tree_node_ptr <> nil do
        begin

          if string_tree_node_ptr^.hierarchical then
            begin
              comment_nesting_level := comment_nesting_level + 1;
              Unparse_block_comment(outfile,
                string_tree_node_ptr^.string_tree_ptr);
              comment_nesting_level := comment_nesting_level - 1;
            end
          else
            Unparse_string(outfile, string_tree_node_ptr^.string_ptr);

          string_tree_node_ptr := string_tree_node_ptr^.next;
        end;

      Unparse_str(outfile, '}');
      if comment_nesting_level = 0 then
        Unparse_space(outfile);
      comment_ptr := comment_ptr^.next;
    end;
end; {procedure Unparse_block_comment}


procedure Unparse_blank_lines(var outfile: text;
  number: integer);
var
  counter: integer;
begin
  for counter := 1 to number do
    Unparseln(outfile, '');
end; {procedure Unparse_blank_lines}


procedure Unparse_comments(var outfile: text;
  comment_ptr: comment_ptr_type);
begin
  if comment_ptr <> nil then
    begin
      Indent(outfile);
      while comment_ptr <> nil do
        begin
          case comment_ptr^.kind of

            line_comment:
              Unparse_line_comment(outfile, comment_ptr^.string_ptr);

            block_comment:
              begin
                Unparse_block_comment(outfile, comment_ptr^.string_tree_ptr);
                Unparse_blank_lines(outfile, comment_ptr^.trailing_spaces);
              end;

          end; {case}
          comment_ptr := comment_ptr^.next;
        end;
    end;
end; {procedure Unparse_comments}


initialization
  {****************************}
  { initialize unparser status }
  {****************************}
  indented := false;
  no_break := false;

  line_length := 0;
  line_number := 0;

  indent_level := 0;
  max_indent_level := max_indent_length div tabsize;
  comment_nesting_level := 0;

  unparsed_blank_line := true;
  unparsed_space := false;
  unparsed_wraparound := false;

  digit_to_char[0] := '0';
  digit_to_char[1] := '1';
  digit_to_char[2] := '2';
  digit_to_char[3] := '3';
  digit_to_char[4] := '4';
  digit_to_char[5] := '5';
  digit_to_char[6] := '6';
  digit_to_char[7] := '7';
  digit_to_char[8] := '8';
  digit_to_char[9] := '9';
end.
