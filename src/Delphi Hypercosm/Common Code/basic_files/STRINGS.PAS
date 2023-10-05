unit strings;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              strings                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{        This module implements the string functions.           }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


const
  {**************}
  { string sizes }
  {**************}
  string_size = 255;


type
  {***************************}
  { fixed size string structs }
  {***************************}
  string_type = string[string_size];


  {******************************}
  { variable size string structs }
  {******************************}
  string_node_ptr_type = ^string_node_type;
  string_node_type = record
    str: string_type;
    next: string_node_ptr_type;
  end; {string_node_type}

  string_ptr_type = ^string_node_list_type;
  string_node_list_type = record
    length: integer;
    first, last: string_node_ptr_type;
    next: string_ptr_type;
  end; {string_node_list_type}


  {****************************}
  { fixed size string routines }
  {****************************}
function Char_to_str(ch: char): string_type;
function Str_length(str: string_type): integer;
function Reverse_str(str: string_type): string_type;

function Left_str(str: string_type;
  chars: integer): string_type;
function Right_str(str: string_type;
  chars: integer): string_type;

procedure Prepend_char_to_str(ch: char;
  var str: string_type);
procedure Append_char_to_str(ch: char;
  var str: string_type);
procedure Append_str_to_str(str1: string_type;
  var str2: string_type);
procedure Append_string_to_str(string_ptr: string_ptr_type;
  var str: string_type);

{*******************************}
{ variable size string routines }
{*******************************}
function New_string: string_ptr_type;
procedure Free_string(var string_ptr: string_ptr_type);

function String_length(string_ptr: string_ptr_type): integer;
function Equal_string(string_ptr1, string_ptr2: string_ptr_type): boolean;
function Index_string(string_ptr: string_ptr_type;
  index: integer): char;

function Left_string(string_ptr: string_ptr_type;
  chars: integer): string_ptr_type;
function Right_string(string_ptr: string_ptr_type;
  chars: integer): string_ptr_type;

procedure Append_char_to_string(ch: char;
  var string_ptr: string_ptr_type);
procedure Append_str_to_string(str: string_type;
  var string_ptr: string_ptr_type);
procedure Append_string_to_string(string_ptr1: string_ptr_type;
  var string_ptr2: string_ptr_type);

{***********************************************}
{ fixed to variable string conversion utilities }
{***********************************************}
function Str_to_string(str: string_type): string_ptr_type;
function String_to_str(string_ptr: string_ptr_type): string_type;

{***************}
{ string output }
{***************}
procedure Write_string(string_ptr: string_ptr_type);
procedure Write_string_to_file(var f: text;
  string_ptr: string_ptr_type);

{******************************}
{ string modification routines }
{******************************}
function Change_str_prefix(str: string_type;
  prefix1: string_type;
  prefix2: string_type): string_type;
function Change_str_suffix(str: string_type;
  suffix1: string_type;
  suffix2: string_type): string_type;

{*********************************}
{ string case conversion routines }
{*********************************}
function Lower_case_str(str: string_type): string_type;
function Upper_case_str(str: string_type): string_type;

{********************************}
{ miscillaneous string utilities }
{********************************}
function Quotate_str(str: string_type): string_type;
function Bracket_str(str: string_type): string_type;
function Parenthesize_str(str: string_type): string_type;
function Surround_str(str: string_type;
  first, last: char): string_type;


implementation
uses
  errors, chars;


const
  memory_alert = false;


var
  string_node_free_list: string_node_ptr_type;
  string_free_list: string_ptr_type;


  {****************************}
  { fixed size string routines }
  {****************************}


function Char_to_str(ch: char): string_type;
var
  str: string_type;
begin
  str := ' ';
  str[1] := ch;
  Char_to_str := str;
end; {function Char_to_str}


function Str_length(str: string_type): integer;
begin
  Str_length := length(str);
end; {function Str_length}


function Reverse_str(str: string_type): string_type;
var
  str2: string_type;
  str_length, counter: integer;
  s: string_type;
  c: char;
begin
  str2 := '';
  str_length := length(str);
  for counter := 1 to str_length do
    begin
      c := str[str_length - counter + 1];
      s := c;
      str2 := concat(str2, s);
    end;
  Reverse_str := str2;
end; {function Reverse_str}


function Left_str(str: string_type;
  chars: integer): string_type;
var
  new_str: string_type;
  counter, limit: integer;
  ch: char;
begin
  new_str := '';

  if length(str) > chars then
    limit := chars
  else
    limit := length(str);

  for counter := 1 to limit do
    begin
      ch := str[counter];
      Append_char_to_str(ch, new_str);
    end;

  Left_str := new_str;
end; {function Left_str}


function Right_str(str: string_type;
  chars: integer): string_type;
var
  new_str: string_type;
  counter, limit: integer;
  ch: char;
begin
  new_str := '';

  if length(str) > chars then
    limit := (length(str) - chars) + 1
  else
    limit := 1;

  for counter := limit to length(str) do
    begin
      ch := str[counter];
      Append_char_to_str(ch, new_str);
    end;

  Right_str := new_str;
end; {function Right_str}


procedure Prepend_char_to_str(ch: char;
  var str: string_type);
var
  index: integer;
begin
  index := length(str) + 1;

  if index < string_size then
    begin
      str := concat(Char_to_str(ch), str);
    end
  else
    Error('string overflow');
end; {procedure Prepend_char_to_str}


procedure Append_char_to_str(ch: char;
  var str: string_type);
var
  index: integer;
begin
  index := length(str) + 1;

  if index < string_size then
    begin
      if false then
        begin
          str[0] := chr(index);
          str[index] := ch;
          str[index + 1] := null;
        end
      else
        begin
          str := concat(str, Char_to_str(ch));
        end;
    end
  else
    Error('string overflow');
end; {procedure Append_char_to_str}


procedure Append_str_to_str(str1: string_type;
  var str2: string_type);
begin
  if length(str1) + length(str2) < string_size then
    begin
      str2 := concat(str2, str1);
    end
  else
    Error('string overflow');
end; {procedure Append_str_to_str}


procedure Append_str_to_str2(str1: string_type;
  var str2: string_type);
var
  counter, offset: integer;
begin
  if length(str1) + length(str2) < string_size then
    begin
      offset := length(str1);
      for counter := 1 to length(str2) - 1 do
        str2[offset + counter] := str1[counter];
      str2[offset + length(str2)] := null;
    end
  else
    Error('string overflow');
end; {procedure Append_str_to_str2}


procedure Append_string_to_str(string_ptr: string_ptr_type;
  var str: string_type);
var
  string_node_ptr: string_node_ptr_type;
  offset, counter, index: integer;
begin
  if string_ptr <> nil then
    begin
      if length(str) + string_ptr^.length < (string_size - 1) then
        begin
          string_node_ptr := string_ptr^.first;
          offset := length(str);

          for counter := 1 to string_ptr^.length do
            begin
              index := (counter - 1) mod (string_size - 1) + 1;
              if index = string_size then
                begin
                  string_node_ptr := string_node_ptr^.next;
                  index := 1;
                end;

              str[offset + counter] := string_node_ptr^.str[index];
            end;

          str[offset + string_ptr^.length] := null;
        end
      else
        Error('string overflow');
    end;
end; {procedure Append_string_to_str}


{*******************************}
{ variable size string routines }
{*******************************}


function New_string_node: string_node_ptr_type;
var
  string_node_ptr: string_node_ptr_type;
begin
  {********************************}
  { get string node from free list }
  {********************************}
  if (string_node_free_list <> nil) then
    begin
      string_node_ptr := string_node_free_list;
      string_node_free_list := string_node_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new string node');
      new(string_node_ptr);
    end;

  {************************}
  { initialize string node }
  {************************}
  string_node_ptr^.str := '';
  string_node_ptr^.next := nil;

  New_string_node := string_node_ptr;
end; {function New_string_node}


function New_string: string_ptr_type;
var
  string_ptr: string_ptr_type;
begin
  {***************************}
  { get string from free list }
  {***************************}
  if (string_free_list <> nil) then
    begin
      string_ptr := string_free_list;
      string_free_list := string_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new string');
      new(string_ptr);
    end;

  {*******************}
  { initialize string }
  {*******************}
  string_ptr^.length := 0;
  string_ptr^.first := nil;
  string_ptr^.last := nil;

  New_string := string_ptr;
end; {function New_string}


procedure Free_string(var string_ptr: string_ptr_type);
begin
  if string_ptr <> nil then
    begin
      {*******************************}
      { add string nodes to free list }
      {*******************************}
      if string_ptr^.last <> nil then
        begin
          string_ptr^.last^.next := string_node_free_list;
          string_node_free_list := string_ptr^.last;
        end;

      {*************************}
      { add string to free list }
      {*************************}
      string_ptr^.next := string_free_list;
      string_free_list := string_ptr;

      string_ptr := nil;
    end;
end; {procedure Free_string}


function String_length(string_ptr: string_ptr_type): integer;
begin
  if string_ptr <> nil then
    String_length := string_ptr^.length
  else
    String_length := 0;
end; {function String_length}


function Equal_string(string_ptr1, string_ptr2: string_ptr_type): boolean;
var
  equal: boolean;
  counter, index: integer;
  string_node_ptr1, string_node_ptr2: string_node_ptr_type;
begin
  if string_ptr1^.length = string_ptr2^.length then
    begin
      counter := 1;
      equal := true;
      string_node_ptr1 := string_ptr1^.first;
      string_node_ptr2 := string_ptr2^.first;
      while (counter <= string_ptr1^.length) and equal do
        begin
          index := (counter - 1) mod (string_size - 1) + 1;
          if index = string_size then
            begin
              string_node_ptr1 := string_node_ptr1^.next;
              string_node_ptr2 := string_node_ptr2^.next;
              counter := 1;
            end;
          if (string_node_ptr1^.str[index] <> string_node_ptr2^.str[index]) then
            equal := false
          else
            counter := counter + 1;
        end;
    end
  else
    equal := false;

  Equal_string := equal;
end; {function Equal_string}


function Left_string(string_ptr: string_ptr_type;
  chars: integer): string_ptr_type;
var
  new_string_ptr: string_ptr_type;
  counter, limit, length: integer;
  ch: char;
begin
  new_string_ptr := New_string;

  length := String_length(string_ptr);
  if length > chars then
    limit := chars
  else
    limit := length;

  for counter := 1 to limit do
    begin
      ch := Index_string(string_ptr, counter);
      Append_char_to_string(ch, new_string_ptr);
    end;

  Left_string := new_string_ptr;
end; {function Left_string}


function Right_string(string_ptr: string_ptr_type;
  chars: integer): string_ptr_type;
var
  new_string_ptr: string_ptr_type;
  counter, limit, length: integer;
  ch: char;
begin
  new_string_ptr := New_string;

  length := String_length(string_ptr);
  if length > chars then
    limit := (length - chars) + 1
  else
    limit := 1;

  for counter := limit to length do
    begin
      ch := Index_string(string_ptr, counter);
      Append_char_to_string(ch, new_string_ptr);
    end;

  Right_string := new_string_ptr;
end; {function Right_string}


function Index_string(string_ptr: string_ptr_type;
  index: integer): char;
var
  derefs, counter: integer;
  string_node_ptr: string_node_ptr_type;
  ch: char;
begin
  ch := null;

  if string_ptr <> nil then
    begin
      if index <= string_ptr^.length then
        begin
          derefs := (index - 1) div (string_size - 1);
          index := (index - 1) mod (string_size - 1) + 1;

          string_node_ptr := string_ptr^.first;
          for counter := 1 to derefs do
            string_node_ptr := string_node_ptr^.next;

          ch := string_node_ptr^.str[index];
        end
      else
        Error('string index error');
    end
  else
    Error('tried to index a nil string');

  Index_string := ch;
end; {function Index_string}


procedure Append_char_to_string(ch: char;
  var string_ptr: string_ptr_type);
var
  index: integer;
  string_node_ptr: string_node_ptr_type;
begin
  if string_ptr = nil then
    string_ptr := New_string;

  {**************************}
  { create first string node }
  {**************************}
  if (string_ptr^.length = 0) then
    begin
      string_node_ptr := New_string_node;
      string_ptr^.first := string_node_ptr;
      string_ptr^.last := string_node_ptr;
    end;

  {*****************************}
  { create new last string node }
  {*****************************}
  index := string_ptr^.length mod (string_size - 1) + 1;
  if index = (string_size - 1) then
    begin
      string_node_ptr := New_string_node;
      string_ptr^.last^.next := string_node_ptr;
      string_ptr^.last := string_node_ptr;
    end
  else
    string_node_ptr := string_ptr^.last;

  {*******************************}
  { assign to last char of string }
  {*******************************}
  Append_char_to_str(ch, string_node_ptr^.str);
  string_ptr^.length := string_ptr^.length + 1;
end; {procedure Append_char_to_string}


procedure Append_str_to_string(str: string_type;
  var string_ptr: string_ptr_type);
var
  counter: integer;
begin
  if string_ptr = nil then
    string_ptr := New_string;

  for counter := 1 to length(str) do
    Append_char_to_string(str[counter], string_ptr);
end; {procedure Append_str_to_string}


procedure Append_string_to_string(string_ptr1: string_ptr_type;
  var string_ptr2: string_ptr_type);
var
  counter, index: integer;
  string_node_ptr: string_node_ptr_type;
  ch: char;
begin
  if string_ptr1 <> nil then
    begin
      if string_ptr2 = nil then
        string_ptr2 := New_string;

      string_node_ptr := string_ptr1^.first;
      for counter := 1 to string_ptr1^.length do
        begin
          index := (counter - 1) mod (string_size - 1) + 1;
          if index = string_size then
            begin
              string_node_ptr := string_node_ptr^.next;
              index := 1;
            end;

          ch := string_node_ptr^.str[index];
          Append_char_to_string(ch, string_ptr2);
        end;
    end;
end; {procedure Append_string_to_string}


{***********************************************}
{ fixed to variable string conversion utilities }
{***********************************************}


function Str_to_string(str: string_type): string_ptr_type;
var
  string_ptr: string_ptr_type;
begin
  if length(str) > 0 then
    begin
      string_ptr := New_string;
      Append_str_to_string(str, string_ptr);
    end
  else
    string_ptr := nil;

  Str_to_string := string_ptr;
end; {function Str_to_string}


function String_to_str(string_ptr: string_ptr_type): string_type;
var
  str: string_type;
  counter, index: integer;
  string_node_ptr: string_node_ptr_type;
  ch: char;
begin
  str := '';
  if string_ptr <> nil then
    begin
      if string_ptr^.length < string_size then
        begin
          string_node_ptr := string_ptr^.first;
          for counter := 1 to string_ptr^.length do
            begin
              index := (counter - 1) mod (string_size - 1) + 1;
              if index = string_size then
                begin
                  string_node_ptr := string_node_ptr^.next;
                  index := 1;
                end;

              ch := string_node_ptr^.str[index];
              Append_char_to_str(ch, str);
            end;
        end
      else
        begin
          writeln('Error - string too large for conversion');
        end;
    end;

  String_to_str := str;
end; {function String_to_str}


{***************}
{ string output }
{***************}


procedure Write_string(string_ptr: string_ptr_type);
var
  counter, length: integer;
  string_node_ptr: string_node_ptr_type;
begin
  if string_ptr <> nil then
    begin
      string_node_ptr := string_ptr^.first;
      while string_node_ptr <> nil do
        begin
          if string_node_ptr^.next <> nil then
            length := string_size - 1
          else
            length := string_ptr^.length mod string_size;

          for counter := 1 to length do
            write(string_node_ptr^.str[counter]);

          string_node_ptr := string_node_ptr^.next;
        end;
    end;
end; {procedure Write_string}


procedure Write_string_to_file(var f: text;
  string_ptr: string_ptr_type);
var
  counter, length: integer;
  string_node_ptr: string_node_ptr_type;
begin
  if string_ptr <> nil then
    begin
      string_node_ptr := string_ptr^.first;
      while string_node_ptr <> nil do
        begin
          if string_node_ptr^.next <> nil then
            length := string_size - 1
          else
            length := string_ptr^.length mod string_size;

          for counter := 1 to length do
            write(f, string_node_ptr^.str[counter]);

          string_node_ptr := string_node_ptr^.next;
        end;
    end;
end; {procedure Write_string_to_file}


{******************************}
{ string modification routines }
{******************************}


function Change_str_prefix(str: string_type;
  prefix1: string_type;
  prefix2: string_type): string_type;
var
  length, prefix_length: integer;
begin
  length := Str_length(str);
  prefix_length := Str_length(prefix1);

  if Left_str(str, prefix_length) = prefix1 then
    begin
      str := Right_str(str, length - prefix_length);
      Append_str_to_str(str, prefix2);
    end;

  Change_str_prefix := str;
end; {function Change_str_prefix}


function Change_str_suffix(str: string_type;
  suffix1: string_type;
  suffix2: string_type): string_type;
var
  length, suffix_length: integer;
begin
  length := Str_length(str);
  suffix_length := Str_length(suffix1);

  if Right_str(str, suffix_length) = suffix1 then
    begin
      str := Left_str(str, length - suffix_length);
      Append_str_to_str(suffix2, str);
    end;

  Change_str_suffix := str;
end; {function Change_str_suffix}


{*********************************}
{ string case conversion routines }
{*********************************}


function Lower_case_str(str: string_type): string_type;
var
  counter: integer;
begin
  for counter := 1 to length(str) do
    str[counter] := Lower_case_char(str[counter]);
  Lower_case_str := str;
end; {function Lower_case_str}


function Upper_case_str(str: string_type): string_type;
var
  counter: integer;
begin
  for counter := 1 to length(str) do
    str[counter] := Upper_case_char(str[counter]);
  Upper_case_str := str;
end; {function Upper_case_str}


{********************************}
{ miscillaneous string utilities }
{********************************}


function Quotate_str(str: string_type): string_type;
begin
  Prepend_char_to_str('"', str);
  Append_char_to_str('"', str);
  Quotate_str := str;
end; {function Quotate_str}


function Bracket_str(str: string_type): string_type;
begin
  Prepend_char_to_str('[', str);
  Append_char_to_str(']', str);
  Bracket_str := str;
end; {function Bracket_str}


function Parenthesize_str(str: string_type): string_type;
begin
  Prepend_char_to_str('(', str);
  Append_char_to_str(')', str);
  Parenthesize_str := str;
end; {function Parenthesize_str}


function Surround_str(str: string_type;
  first, last: char): string_type;
begin
  Prepend_char_to_str(first, str);
  Append_char_to_str(last, str);
  Surround_str := str;
end; {function Surround_str}


initialization
  string_node_free_list := nil;
  string_free_list := nil;
end.

