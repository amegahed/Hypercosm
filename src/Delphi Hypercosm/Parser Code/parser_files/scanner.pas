unit scanner;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              scanner                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This scanner transforms the stream of characters        }
{       from the file into a stream of lines which are          }
{       used by the tokenizer.                                  }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  comments;


var
  {*************************}
  { scanner state variables }
  {*************************}
  blank_line: boolean;
  line_counter: integer;
  char_counter: integer;
  last_good_char: integer;
  single_line_mode: boolean;


procedure Scan_next_char;
function Scan_char: char;

procedure Scan_through_whitespace;
function Scan_block_comments: comment_list_type;

procedure Advance_scanner;
procedure Advance_file_marker;

procedure Push_scanner_state;
procedure Pop_scanner_state;

{******************************************}
{ procedures used to report error messages }
{******************************************}
function Get_line_number: integer;
function Get_char_number: integer;
procedure Write_error_line;


implementation
uses
  new_memory, chars, strings, string_structs, file_stack;


const
  line_buffer_size = 128;
  memory_alert = false;
  verbose = false;


type
  line_buffer_ptr_type = ^line_buffer_type;
  line_buffer_type = packed array[1..line_buffer_size] of char;


  scanner_state_ptr_type = ^scanner_state_type;
  scanner_state_type = record

    blank_line: boolean;
    line_counter: integer;
    char_counter: integer;
    last_good_char: integer;
    single_line_mode: boolean;
    comment_list: comment_list_type;

    line_buffer_ptr: line_buffer_ptr_type;
    current_buffer_ptr: line_buffer_ptr_type;
    previous_buffer_ptr: line_buffer_ptr_type;

    next: scanner_state_ptr_type;
  end; {scanner_state_type}


var
  {**************************}
  { scanner global variables }
  {**************************}
  scanner_state_stack: scanner_state_ptr_type;
  scanner_state_free_list: scanner_state_ptr_type;

  comment_list: comment_list_type;
  line_buffer_ptr: line_buffer_ptr_type;
  current_buffer_ptr: line_buffer_ptr_type;
  previous_buffer_ptr: line_buffer_ptr_type;


  {******************************************}
  { procedures used to report error messages }
  {******************************************}


function Get_line_number: integer;
begin
  Get_line_number := line_counter;
end; {function Get_line_number}


function Get_char_number: integer;
begin
  Get_char_number := last_good_char;
end; {function Get_char_number}


procedure Write_error_line;
var
  counter: integer;
begin
  for counter := 1 to char_counter - 1 do
    write(line_buffer_ptr^[counter mod line_buffer_size]);
  writeln;

  for counter := 1 to last_good_char - 1 do
    if line_buffer_ptr^[counter mod line_buffer_size] <> tab then
      write(' ')
    else
      write(tab);

  writeln('^');
end; {procedure Write_error_line}


{******************************}
{ scanner state stack routines }
{******************************}


function New_scanner_state: scanner_state_ptr_type;
var
  scanner_state_ptr: scanner_state_ptr_type;
begin
  {**********************************}
  { get scanner state from free list }
  {**********************************}
  if (scanner_state_free_list <> nil) then
    begin
      scanner_state_ptr := scanner_state_free_list;
      scanner_state_free_list := scanner_state_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new scanner state');
      new(scanner_state_ptr);

      {********************************}
      { allocate scanner state buffers }
      {********************************}
      with scanner_state_ptr^ do
        begin
          new(line_buffer_ptr);
          new(current_buffer_ptr);
          new(previous_buffer_ptr);
        end;
    end;

  {**************************}
  { initialize scanner state }
  {**************************}
  with scanner_state_ptr^ do
    begin
      blank_line := true;
      line_counter := 1;
      char_counter := 1;
      last_good_char := 1;
      single_line_mode := false;
      Init_comment_list(comment_list);
      next := nil;
    end;

  New_scanner_state := scanner_state_ptr;
end; {function New_scanner_state}


procedure Free_scanner_state(var scanner_state_ptr: scanner_state_ptr_type);
begin
  {*********************************}
  { add scanner state to freee list }
  {*********************************}
  scanner_state_ptr^.next := scanner_state_free_list;
  scanner_state_free_list := scanner_state_ptr;
end; {procedure Free_scanner_state}


{*****************************************************}
{ routines to move data from scanner state to globals }
{*****************************************************}


procedure Swap_state_buffers(scanner_state_ptr: scanner_state_ptr_type);
var
  temp_line_buffer_ptr: line_buffer_ptr_type;
  temp_current_buffer_ptr: line_buffer_ptr_type;
  temp_previous_buffer_ptr: line_buffer_ptr_type;
begin
  temp_line_buffer_ptr := scanner_state_ptr^.line_buffer_ptr;
  temp_current_buffer_ptr := scanner_state_ptr^.current_buffer_ptr;
  temp_previous_buffer_ptr := scanner_state_ptr^.previous_buffer_ptr;

  scanner_state_ptr^.line_buffer_ptr := line_buffer_ptr;
  scanner_state_ptr^.current_buffer_ptr := current_buffer_ptr;
  scanner_state_ptr^.previous_buffer_ptr := previous_buffer_ptr;

  line_buffer_ptr := temp_line_buffer_ptr;
  current_buffer_ptr := temp_current_buffer_ptr;
  previous_buffer_ptr := temp_previous_buffer_ptr;
end; {procedure Swap_state_buffers}


procedure Set_scanner_state(scanner_state_ptr: scanner_state_ptr_type);
begin
  {***********************************}
  { set current scanner state globals }
  {***********************************}
  blank_line := scanner_state_ptr^.blank_line;
  line_counter := scanner_state_ptr^.line_counter;
  char_counter := scanner_state_ptr^.char_counter;
  last_good_char := scanner_state_ptr^.last_good_char;
  single_line_mode := scanner_state_ptr^.single_line_mode;
  comment_list := scanner_state_ptr^.comment_list;

  {************************************************}
  { swap scanner state buffers with global buffers }
  {************************************************}
  Swap_state_buffers(scanner_state_ptr);
end; {procedure Set_scanner_state}


procedure Get_scanner_state(scanner_state_ptr: scanner_state_ptr_type);
begin
  {***********************************}
  { get current scanner state globals }
  {***********************************}
  scanner_state_ptr^.blank_line := blank_line;
  scanner_state_ptr^.line_counter := line_counter;
  scanner_state_ptr^.char_counter := char_counter;
  scanner_state_ptr^.last_good_char := last_good_char;
  scanner_state_ptr^.single_line_mode := single_line_mode;
  scanner_state_ptr^.comment_list := comment_list;

  {************************************************}
  { swap scanner state buffers with global buffers }
  {************************************************}
  Swap_state_buffers(scanner_state_ptr);
end; {procedure Get_scanner_state}


procedure Init_scanner_state;
begin
  {******************************}
  { initialize new current state }
  {******************************}
  blank_line := true;
  line_counter := 1;
  char_counter := 1;
  last_good_char := 1;
  single_line_mode := false;
  Init_comment_list(comment_list);
end; {procedure Init_scanner_state}


procedure Push_scanner_state;
var
  scanner_state_ptr: scanner_state_ptr_type;
begin
  {****************************}
  { push state to top of stack }
  {****************************}
  scanner_state_ptr := New_scanner_state;
  scanner_state_ptr^.next := scanner_state_stack;
  scanner_state_stack := scanner_state_ptr;

  {****************************}
  { save current scanner state }
  {****************************}
  Get_scanner_state(scanner_state_ptr);

  {*******************************}
  { initialize scanner state vars }
  {*******************************}
  Init_scanner_state;
end; {procedure Push_scanner_state}


procedure Pop_scanner_state;
var
  scanner_state_ptr: scanner_state_ptr_type;
begin
  {*****************************}
  { pop state from top of stack }
  {*****************************}
  if scanner_state_stack <> nil then
    begin
      scanner_state_ptr := scanner_state_stack;
      scanner_state_stack := scanner_state_stack^.next;

      {********************************}
      { restore previous scanner state }
      {********************************}
      Set_scanner_state(scanner_state_ptr);

      Free_scanner_state(scanner_state_ptr);
    end;
end; {procedure Pop_scanner_state}


{******************}
{ scanner routines }
{******************}


procedure Swap_buffers;
var
  temp_buffer_ptr: line_buffer_ptr_type;
begin
  temp_buffer_ptr := previous_buffer_ptr;
  previous_buffer_ptr := current_buffer_ptr;
  current_buffer_ptr := temp_buffer_ptr;
end; {procedure Swap_buffers}


procedure Scan_next_char;
begin
  {********************}
  { check for new line }
  {********************}
  if (next_char = CR) {or (next_char = NL)} then
    begin
      blank_line := true;
      if not single_line_mode then
        begin
          char_counter := 1;
          last_good_char := 1;
          line_counter := line_counter + 1;
        end;
    end
  else
    begin
      if not (next_char in whitespace) and (next_char <> '/') then
        if blank_line then
          blank_line := false;
      current_buffer_ptr^[char_counter] := next_char;
      char_counter := (char_counter mod line_buffer_size) + 1;
    end;

  Get_next_char;
end; {procedure Scan_next_char}


function Scan_char: char;
begin
  Scan_char := next_char;
  Scan_next_char;
end; {function Scan_char}


procedure Scan_through_whitespace;
begin
  while next_char in whitespace do
    Scan_next_char;
end; {Scan_through_whitespace}


procedure Scan_through_comments(var block_comment_ptr: string_tree_ptr_type;
  var trailing_spaces: integer;
  skip_whitespace: boolean);
const
  comment_start = '{';
  comment_end = '}';
var
  string_ptr: string_ptr_type;
  nested_block_comment_ptr: string_tree_ptr_type;
  starting_line: integer;
begin
  if next_char = comment_start then
    begin
      block_comment_ptr := New_string_tree;

      {*****************************************}
      { scan through start of comment delimeter }
      {*****************************************}
      Scan_next_char;
      string_ptr := nil;

      {************************}
      { scan to end of comment }
      {************************}
      while (next_char <> comment_end) and (next_char <> end_of_file) do
        if next_char = comment_start then
          begin
            {***************************}
            { end previous comment text }
            {***************************}
            if string_ptr <> nil then
              begin
                Add_string_to_tail(string_ptr, block_comment_ptr);
                string_ptr := nil;
              end;

            {*********************}
            { scan nested comment }
            {*********************}
            Scan_through_comments(nested_block_comment_ptr, trailing_spaces,
              false);
            Add_string_tree_to_tail(nested_block_comment_ptr,
              block_comment_ptr);
          end
        else
          begin
            {***************************************}
            { append to end of current comment text }
            {***************************************}
            Append_char_to_string(next_char, string_ptr);
            Scan_next_char;
          end;

      Add_string_to_tail(string_ptr, block_comment_ptr);
      string_ptr := nil;

      {***************************************}
      { scan through end of comment delimeter }
      {***************************************}
      starting_line := line_counter;
      Scan_next_char;
      if skip_whitespace then
        Scan_through_whitespace;
      trailing_spaces := line_counter - starting_line;
    end
  else
    begin
      block_comment_ptr := nil;
      trailing_spaces := 0;
    end;
end; {procedure Scan_through_comments}


function Scan_block_comments: comment_list_type;
var
  temp: comment_list_type;
begin
  temp := comment_list;
  Init_comment_list(comment_list);
  Scan_block_comments := temp;
end; {function Scan_block_comments}


procedure Advance_scanner;
var
  comment_ptr: comment_ptr_type;
begin
  while (next_char = '{') or (next_char in whitespace) do
    begin
      if next_char = '{' then
        begin
          comment_ptr := New_comment(block_comment);
          Scan_through_comments(comment_ptr^.string_tree_ptr,
            comment_ptr^.trailing_spaces, true);
          Append_comment(comment_list, comment_ptr);
        end
      else
        Scan_through_whitespace;
    end;
end; {procedure Advance_scanner}


procedure Advance_file_marker;
begin
  last_good_char := char_counter;
  line_buffer_ptr := current_buffer_ptr;
end; {procedure Advance_file_marker}


initialization
  {************************************}
  { initialize scanner state variables }
  {************************************}
  Init_scanner_state;

  if memory_alert then
    writeln('allocating new line buffer');
  new(line_buffer_ptr);
  new(current_buffer_ptr);
  new(previous_buffer_ptr);
end.
