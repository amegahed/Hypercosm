unit file_stack;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             file_stack                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module provides for all low level file reading     }
{       and keeps a stack of file descriptors so when we        }
{       close a file, it remembers the last file opened.        }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


var
  next_char: char;


{****************************************}
{ routines for opening and closing files }
{****************************************}
function Open_next_file(name: string): boolean;
procedure Close_current_file;
procedure Close_all_files;

{***********************}
{ file reading routines }
{***********************}
procedure Get_next_char;
function Get_char: char;
procedure Unget_char(ch: char);

{**********************}
{ file status routines }
{**********************}
function Get_file_name: string;
function Get_file_char_count: longint;


implementation
uses
  {***************}
  { user includes }
  {***************}
  text_files, new_memory, errors;


const
  {*****************}
  { ascii constants }
  {*****************}
  end_of_file = chr(4); {end of file character}
  null = chr(0); {end of string character}


const
  memory_alert = false;


type
  file_node_ptr_type = ^file_node_type;
  file_node_type = record
    text_file_ptr: text_file_ptr_type;
    next_char: char;
    char_count: integer;
    next: file_node_ptr_type;
  end; {file_node_type}


var
  {******************}
  { input file stack }
  {******************}
  file_list: file_node_ptr_type;


function New_file_node: file_node_ptr_type;
var
  file_node_ptr: file_node_ptr_type;
begin
  if memory_alert then
    writeln('allocating new file node');
  new(file_node_ptr);

  {*****************}
  { initialize file }
  {*****************}
  with file_node_ptr^ do
    begin
      text_file_ptr := nil;
      next_char := end_of_file;
      char_count := 0;
      next := nil;
    end;

  New_file_node := file_node_ptr;
end; {function New_file_node}


function Open_next_file(name: string): boolean;
var
  new_file_node_ptr: file_node_ptr_type;
begin
  {********************}
  { close current file }
  {********************}
  if (file_list <> nil) then
    begin
      // Close_file(file_list^.infile_ptr);
      file_list^.next_char := next_char;
    end;

  {*******************}
  { make new file ptr }
  {*******************}
  new_file_node_ptr := New_file_node;

  {***************}
  { open new file }
  {***************}
  new_file_node_ptr^.text_file_ptr := Open_text_file(name, read_only);

  if new_file_node_ptr^.text_file_ptr <> nil then
    begin
      {***************************}
      { push file on top of stack }
      {***************************}
      new_file_node_ptr^.next := file_list;
      file_list := new_file_node_ptr;

      {*****************************}
      { read first char of new file }
      {*****************************}
      next_char := null;
      Get_next_char;
    end;

  Open_next_file := new_file_node_ptr^.text_file_ptr <> nil;
end; {procedure Open_next_file}


procedure Free_file_node(var file_node_ptr: file_node_ptr_type);
begin
  Close_text_file(file_node_ptr^.text_file_ptr);
  dispose(file_node_ptr);
  file_node_ptr := nil;
end; {procedure Free_file_node}


procedure Close_current_file;
var
  file_node_ptr: file_node_ptr_type;
begin
  if file_list <> nil then
    begin
      {*********************}
      { pop file from stack }
      {*********************}
      file_node_ptr := file_list;
      file_list := file_list^.next;

      {***********}
      { free file }
      {***********}
      Free_file_node(file_node_ptr);

      if file_list <> nil then
        begin
          {*******************}
          { restore next char }
          {*******************}
          next_char := file_list^.next_char;

          {*****************}
          { reopen top file }
          {*****************}
          // Reopen_infile(file_list^.infile_ptr);
        end;
    end
  else
    Error('no file open to close');
end; {procedure Close_current_file}


procedure Close_all_files;
begin
  while (file_list <> nil) do
    Close_current_file;
end; {procedure Close_all_files}


{***********************}
{ file reading routines }
{***********************}


procedure Get_next_char;
begin
  if file_list <> nil then
    begin
      next_char := Get_text_file_char(file_list^.text_file_ptr);
      file_list^.char_count := file_list^.char_count + 1;
    end
  else
    next_char := end_of_file;
end; {procedure Get_next_char}


function Get_char: char;
begin
  Get_char := next_char;
  Get_next_char;
end; {function Get_char}


procedure Unget_char(ch: char);
begin
  if file_list <> nil then
    begin
      Unget_text_file_char(file_list^.text_file_ptr, ch);
      next_char := ch;
      file_list^.char_count := file_list^.char_count - 1;
    end;
end; {procedure Unget_char}


{**********************}
{ file status routines }
{**********************}


function Get_file_name: string;
var
  name: string;
begin
  if file_list <> nil then
    name := file_list^.text_file_ptr^.name
  else
    name := '';

  Get_file_name := name;
end; {function Get_file_name}


function Get_file_char_count: longint;
var
  count: longint;
begin
  if file_list <> nil then
    count := file_list^.char_count
  else
    count := 0;

  Get_file_char_count := count;
end; {function Get_file_char_count}


initialization
  file_list := nil;
  next_char := end_of_file;
end.
