unit text_files;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            text_files                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module provides for all low level text file        }
{	input and output.					}
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  strings;


const
  memory_alert = false;
  buffer_size = 256;


type
  buffer_ptr_type = ^buffer_type;
  buffer_type = packed array[1..buffer_size] of char;

  text_file_mode_type = (read_only, write_only, read_write);
  text_file_ptr_type = ^text_file_type;
  text_file_type = record
    {**********************}
    { text_file attributes }
    {**********************}
    name: string_type;
    readable, writeable: boolean;

    {*******************}
    { input char buffer }
    {*******************}
    input_buffer: buffer_type;
    char_index, char_count: integer;

    {***********************}
    {* returned char buffer }
    {***********************}
    returned_char_buffer: buffer_type;
    returned_char_count: integer;

    {********************}
    { output char buffer }
    {********************}
    output_char_buffer: buffer_type;
    output_char_count: integer;

    {**************************************}
    { system specific text file descriptor }
    {**************************************}
    handle: integer;
  end; {text_file_type}


{*********************************************}
{ routines for opening and closing text files }
{*********************************************}
function Open_text_file(name: string_type; mode: text_file_mode_type): text_file_ptr_type;
procedure Close_text_file(var text_file_ptr: text_file_ptr_type);

{****************************************}
{ text file reading and writing routines }
{****************************************}
function Get_text_file_char(text_file_ptr: text_file_ptr_type): char;
procedure Unget_text_file_char(text_file_ptr: text_file_ptr_type; ch: char);
procedure Put_text_file_char(text_file_ptr: text_file_ptr_type; ch: char);


implementation
uses
  SysUtils, chars, errors;


function New_text_file(name: string_type; text_file_mode: text_file_mode_type): text_file_ptr_type;
var
  text_file_ptr: text_file_ptr_type;
begin
  if memory_alert then
    writeln('allocating new text file');
  new(text_file_ptr);

  {**********************}
  { initialize text file }
  {**********************}
  text_file_ptr^.name := name;
  with text_file_ptr^ do
    begin
      readable := (text_file_mode = read_only) or (text_file_mode = read_write);
      writeable := (text_file_mode = write_only) or (text_file_mode = read_write);

      {******************************}
      { initialize buffer attributes }
      {******************************}
      char_index := 1;
      char_count := 0;
      returned_char_count := 0;
      output_char_count := 0;

      {*********************************}
      { initialize text file descriptor }
      {*********************************}
      handle := 0;
    end;

  New_text_file := text_file_ptr;
end; {function New_text_file}


procedure Free_text_file(var text_file_ptr: text_file_ptr_type);
begin
  dispose(text_file_ptr);
  text_file_ptr := nil;
end; {procedure Free_text_file}


{*********************************************}
{ routines for opening and closing text files }
{*********************************************}


function Open_text_file(name: string_type; mode: text_file_mode_type): text_file_ptr_type;
var
  handle: integer;
  mode_code: integer;
  text_file_ptr: text_file_ptr_type;
begin
  case mode of
    read_only:
      mode_code := fmOpenRead;
    write_only:
      mode_code := fmOpenWrite;
    read_write:
      mode_code := fmOpenReadWrite;
  else
    mode_code := fmOpenReadWrite;
  end; {case}

  handle := FileOpen(name, mode_code);
  if handle <> -1 then
    begin
      text_file_ptr := New_text_file(name, mode);
      text_file_ptr^.handle := handle;
    end
  else
    text_file_ptr := nil;

  Open_text_file := text_file_ptr;
end; {function Open_text_file}


procedure Close_text_file(var text_file_ptr: text_file_ptr_type);
begin
  if text_file_ptr <> nil then
    begin
      FileClose(text_file_ptr^.handle);
      Free_text_file(text_file_ptr);
    end;
end; {procedure Close_text_file}


{**************************}
{ buffer handling routines }
{**************************}


procedure Fill_input_buffer(text_file_ptr: text_file_ptr_type);
begin
  with text_file_ptr^ do
    if readable then
      begin
        char_index := 1; // start at the beginning of the buffer
        char_count := FileRead(handle, input_buffer, buffer_size);

        if char_count = -1 then
          Error('Error reading from text file');
      end
    else
      Error('Can not read from text file');
end; {procedure Fill_input_buffer}


procedure Empty_output_buffer(text_file_ptr: text_file_ptr_type);
var
  chars_written: integer;
begin
  with text_file_ptr^ do
    if writeable then
      begin
        chars_written := FileWrite(handle, output_char_buffer,
          output_char_count);
        if chars_written <> output_char_count then
          Error('Error writing to text file')
        else
          output_char_count := 0; // start at the beginning of the buffer
      end
    else
      Error('Can not write to text file');
end; {procedure Empty_output_buffer}


{****************************************}
{ text file reading and writing routines }
{****************************************}


function Get_text_file_char(text_file_ptr: text_file_ptr_type): char;
var
  ch: char;
begin
  with text_file_ptr^ do
    if returned_char_count > 0 then
      begin
        {****************************************************}
        { get returned char from end of returned char buffer }
        {****************************************************}
        ch := returned_char_buffer[returned_char_count];
        returned_char_count := returned_char_count - 1;
      end
    else
      {*******************************}
      { get char from front of buffer }
      {*******************************}
      begin
        if char_index > char_count then
          Fill_input_buffer(text_file_ptr);

        if char_count <> 0 then
          begin
            ch := input_buffer[char_index];
            char_index := char_index + 1;
          end
        else
          ch := end_of_file;
      end;

  Get_text_file_char := ch;
end; {function Get_text_file_char}


procedure Unget_text_file_char(text_file_ptr: text_file_ptr_type; ch: char);
begin
  with text_file_ptr^ do
    begin
      {*****************************************}
      { add char to end of returned char buffer }
      {*****************************************}
      returned_char_count := returned_char_count + 1;
      returned_char_buffer[returned_char_count] := ch;
    end;
end; {procedure Unget_text_file_char}


procedure Put_text_file_char(text_file_ptr: text_file_ptr_type; ch: char);
begin
  with text_file_ptr^ do
    begin
      if output_char_count = buffer_size then
        Empty_output_buffer(text_file_ptr);

      output_char_count := output_char_count + 1;
      output_char_buffer[output_char_count] := ch;
    end;
end; {procedure Put_text_file_char}


end.

