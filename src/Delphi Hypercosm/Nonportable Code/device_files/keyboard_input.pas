unit keyboard_input;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           keyboard_input              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to keyboard          }
{       hardware. Most porting changes will be here and         }
{       in the video and files modules.                         }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


type
  keyboard_state_ptr_type = ^keyboard_state_type;
  keyboard_state_type = record
    last_key: integer;
    key_state: array[0..255] of boolean;
  end; {keyboard_state_type}


{****************************}
{ keyboard polling functions }
{****************************}
function Get_key: integer;
function Key_down(key: integer): boolean;

{******************************}
{ keycode conversion functions }
{******************************}
function Key_to_char(key: integer): char;
function Char_to_key(c: char): integer;


implementation
uses
  chars, video;


type
  key_char_set_type = set of char;


const
  key_char_set = ['a'..'z', 'A'..'Z', '1'..'0', space, tab, CR];


var
  key_to_char_array: array[0..255] of char;
  char_to_key_array: array[0..255] of integer;


procedure Init_key_array;
var
  counter: integer;
begin
  {****************************************}
  { initialize array mapping keys to chars }
  {****************************************}
  for counter := 0 to 255 do
  begin
    if (chr(counter) in key_char_set) then
      key_to_char_array[counter] := chr(counter)
    else
      key_to_char_array[counter] := chr(0);
  end;
end; {procedure Init_key_array}


procedure Init_char_array;
var
  counter: integer;
begin
  {****************************************}
  { initialize array mapping chars to keys }
  {****************************************}
  for counter := 0 to 255 do
  begin
    if (chr(counter) in key_char_set) then
      char_to_key_array[counter] := counter
    else
      char_to_key_array[counter] := 0;
  end;
end; {procedure Init_char_array}


{****************************}
{ keyboard polling functions }
{****************************}


function Get_key: integer;
var
  key: integer;
begin
  if current_window <> nil then
    key := current_window.keyboard_state.last_key
  else
    key := 0;

  Get_key := key;
end; {function Get_key}


function Key_down(key: integer): boolean;
var
  state: boolean;
begin
  if current_window <> nil then
    state := current_window.keyboard_state.key_state[key]
  else
    state := false;

  Key_down := state;
end; {function Key_down}


{******************************}
{ keycode conversion functions }
{******************************}


function Key_to_char(key: integer): char;
begin
  Key_to_char := key_to_char_array[key];
end; {function Key_to_char}


function Char_to_key(c: char): integer;
begin
  Char_to_key := char_to_key_array[ord(c)];
end; {function Char_to_key}


initialization
  Init_key_array;
  Init_char_array;
end.
