unit chars;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               chars                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{        This module contains utility character definitions.    }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


const
  {*****************}
  { ascii constants }
  {*****************}
  end_of_file = chr(4); {end of file character}
  tab = chr(9); {ascii for tab}
  NL = chr(10); {ascii for newline}
  CR = chr(13); {ascii for carriage return}
  space = chr(32); {ascii for space}
  single_quote = chr(39); {ascii for single quote}
  double_quote = '"'; {ascii for double quote}
  null = chr(0); {end of string character}
  case_difference = ord('A') - ord('a');


  {********************}
  { miscillaneous sets }
  {********************}
  alphabet = ['a'..'z', 'A'..'Z', '_'];
  lowercase = ['a'..'z'];
  uppercase = ['A'..'Z'];
  whitespace = [space, NL, CR, tab, null];
  digits = ['0'..'9'];


  {*******************************}
  { char case conversion routines }
  {*******************************}
function Lower_case_char(ch: char): char;
function Upper_case_char(ch: char): char;


implementation


{*******************************}
{ char case conversion routines }
{*******************************}


function Lower_case_char(ch: char): char;
begin
  if ch in uppercase then
    ch := chr(ord(ch) - case_difference);
  Lower_case_char := ch;
end; {function Lower_case_char}


function Upper_case_char(ch: char): char;
begin
  if ch in lowercase then
    ch := chr(ord(ch) + case_difference);
  Upper_case_char := ch;
end; {function Upper_case_char}


end.
