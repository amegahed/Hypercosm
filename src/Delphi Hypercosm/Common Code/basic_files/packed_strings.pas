unit packed_strings;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            packed_strings             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{        This module implements the packed string functions.    }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  strings;


type
  {******************************}
  { variable size string structs }
  {******************************}
  packed_array_type = packed array[1..string_size] of char;

  {***********************}
  { packed string structs }
  {***********************}
  packed_string_type = record
    length: integer;
    str: packed_array_type;
  end; {packed_string_type}


{***********************************}
{ fixed size packed string routines }
{***********************************}
function Packed_string_to_string(str: packed_string_type): string_type;
procedure Write_packed_string(str: packed_string_type);
procedure Write_packed_string_to_file(var f: text;
  str: packed_string_type);


implementation


{***********************************}
{ fixed size packed string routines }
{***********************************}


procedure Strmove(length: integer;
  from_str: packed_array_type;
  var dest_str: string);
var
  i: integer;
  c: char;
  s: string;
begin
  dest_str := '';
  for i := 1 to length do
    begin
      c := from_str[i];
      s := c;
      dest_str := concat(dest_str, s);
    end;
end; {procedure Strmove}


function Packed_string_to_string(str: packed_string_type): string_type;
var
  temp_str: string_type;
begin
  temp_str := '';
  // Strmove(str.length - 1, str.str, temp_str);
  Packed_string_to_string := temp_str;
end; {function Packed_string_to_string}


procedure Write_packed_string(str: packed_string_type);
var
  counter: integer;
begin
  for counter := 1 to str.length do
    write(str.str[counter]);
end; {procedure Write_packed_string}


procedure Write_packed_string_to_file(var f: text;
  str: packed_string_type);
var
  counter: integer;
begin
  for counter := 1 to str.length do
    write(f, str.str[counter]);
end; {procedure Write_packed_string_to_file}


end. {module packed_strings}

