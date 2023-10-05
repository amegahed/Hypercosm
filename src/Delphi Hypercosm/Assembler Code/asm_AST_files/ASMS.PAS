unit asms;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm                asms                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The asms module defines basic types and routines        }
{       used in the mnemonic assembly code representation       }
{       of the syntax tree which is used by the interpreter.    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, data_types;


const
  mnemonic_size = 3;


type
  mnemonic_type = string[mnemonic_size];
  asm_index_type = long_type;


  {**************************************************}
  { routines to find and report assembly file errors }
  {**************************************************}
procedure Asm_error;
procedure Disasm_error;
procedure Match_mnemonic(mnemonic: mnemonic_type);
procedure Match_pseudo_mnemonic(mnemonic: mnemonic_type);
procedure Match_string(str: string_type);
procedure Match_char(ch: char);
procedure Match_space;
procedure Match_whitespace;
function Get_asm_line_number: integer;

{************************************************}
{ routines to read primitive assembly code units }
{************************************************}
function Assemble_mnemonic: mnemonic_type;
function Assemble_pseudo_mnemonic: mnemonic_type;
function Assemble_index: asm_index_type;

{************************************************}
{ routines to read primitive assembly data units }
{************************************************}
function Assemble_boolean: boolean_type;
function Assemble_char: char_type;
function Assemble_byte: byte_type;
function Assemble_short: short_type;
function Assemble_integer: integer_type;
function Assemble_long: long_type;
function Assemble_scalar: scalar_type;
function Assemble_double: double_type;
function Assemble_string: string_type;
function Assemble_name: string_type;

{*************************************************}
{ routines to write primitive assembly code units }
{*************************************************}
procedure Disassemble_mnemonic(var outfile: text;
  mnemonic: mnemonic_type);
procedure Disassemble_pseudo_mnemonic(var outfile: text;
  mnemonic: mnemonic_type);
procedure Disassemble_index(var outfile: text;
  asm_index: asm_index_type);

{*************************************************}
{ routines to write primitive assembly data units }
{*************************************************}
procedure Disassemble_boolean(var outfile: text;
  boolean_val: boolean_type);
procedure Disassemble_char(var outfile: text;
  char_val: char_type);
procedure Disassemble_byte(var outfile: text;
  byte_val: byte_type);
procedure Disassemble_short(var outfile: text;
  short_val: short_type);
procedure Disassemble_integer(var outfile: text;
  integer_val: integer_type);
procedure Disassemble_long(var outfile: text;
  long_val: long_type);
procedure Disassemble_scalar(var outfile: text;
  scalar_val: scalar_type;
  decimal_places: integer;
  exponential_notation: boolean);
procedure Disassemble_double(var outfile: text;
  double_val: double_type;
  decimal_places: integer;
  exponential_notation: boolean);
procedure Disassemble_string(var outfile: text;
  str: string_type);
procedure Disassemble_name(var outfile: text;
  name: string_type);
procedure Disassemble_newline(var outfile: text);


implementation
uses
  errors, chars, file_stack, string_io;


const
  ascii_booleans = false;
  ascii_chars = false;


var
  {*************}
  { line counts }
  {*************}
  asm_line_count: longint;
  disasm_line_count: longint;

  {*************}
  { line status }
  {*************}
  asm_newline: boolean;
  disasm_newline: boolean;


  {**************************************************}
  { routines to find and report assembly file errors }
  {**************************************************}


procedure Asm_error;
begin
  writeln('Assembly error on line #', asm_line_count: 1, '.');
  writeln('Bytecode file is invalid or corrupted.');
  Stop;
end; {procedure Asm_error}


procedure Disasm_error;
begin
  Error('Disassembly error on line #' + Integer_to_str(disasm_line_count) +
    '.' + CR + 'Bytecode file is incomplete and invalid.');
  Stop;
end; {procedure Disasm_error}


procedure Match_mnemonic(mnemonic: mnemonic_type);
begin
  if Assemble_mnemonic <> mnemonic then
    Asm_error;
  asm_newline := false;
end; {procedure Match_mnemonic}


procedure Match_pseudo_mnemonic(mnemonic: mnemonic_type);
begin
  if Assemble_pseudo_mnemonic <> mnemonic then
    Asm_error;
end; {procedure Match_pseudo_mnemonic}


procedure Match_string(str: string_type);
var
  str2: string_type;
begin
  str2 := Assemble_string;
  if str <> str2 then
    Asm_error;
end; {procedure Match_string}


procedure Match_char(ch: char);
begin
  if Get_char <> ch then
    Asm_error;
  asm_newline := false;
end; {procedure Match_char}


procedure Match_space;
begin
  if Get_char <> space then
    Asm_error;
  asm_newline := false;
end; {procedure Match_space}


procedure Match_whitespace;
begin
  while next_char in whitespace do
    begin
      if (next_char = CR) or (next_char = NL) then
        begin
          asm_line_count := asm_line_count + 1;
          asm_newline := true;
        end
      else
        asm_newline := false;

      Get_next_char;
    end;
end; {procedure Match_whitespace}


function Get_asm_line_number: integer;
begin
  Get_asm_line_number := asm_line_count;
end; {function Get_asm_line_number}


{************************************************}
{ routines to read primitive assembly code units }
{************************************************}


function Assemble_mnemonic: mnemonic_type;
var
  mnemonic: mnemonic_type;
begin
  Match_whitespace;

  mnemonic := '123';
  mnemonic[1] := Get_char;
  mnemonic[2] := Get_char;
  mnemonic[3] := Get_char;
  asm_newline := false;

  Assemble_mnemonic := mnemonic;
end; {function Assemble_mnemonic}


function Assemble_pseudo_mnemonic: mnemonic_type;
var
  mnemonic: mnemonic_type;
begin
  mnemonic := '123';
  mnemonic[1] := Get_char;
  mnemonic[2] := Get_char;
  mnemonic[3] := Get_char;
  asm_newline := false;

  Assemble_pseudo_mnemonic := mnemonic;
end; {function Assemble_pseudo_mnemonic}


function Assemble_index: asm_index_type;
var
  asm_index: asm_index_type;
begin
  asm_index := Str_to_integer(Assemble_string);
  if (asm_index = 0) then
    Asm_error;

  Assemble_index := asm_index;
end; {function Assemble_index}


{************************************************}
{ routines to read primitive assembly data units }
{************************************************}


function Assemble_boolean: boolean_type;
var
  boolean_val: boolean;
begin
  Match_space;

  if ascii_booleans then
    boolean_val := (Get_char = 'T')
  else
    boolean_val := (Get_char = '1');

  Assemble_boolean := boolean_val;
end; {function Assemble_boolean}


function Assemble_char: char_type;
var
  char_val: char;
begin
  if ascii_chars then
    begin
      Match_space;
      Match_char(double_quote);
      char_val := Get_char;
      Match_char(double_quote);
    end
  else
    char_val := chr(Assemble_integer);

  Assemble_char := char_val;
end; {function Assemble_char}


function Assemble_byte: byte_type;
begin
  Assemble_byte := Str_to_integer(Assemble_string);
end; {function Assemble_byte}


function Assemble_short: short_type;
begin
  Assemble_short := Str_to_integer(Assemble_string);
end; {function Assemble_short}


function Assemble_integer: integer_type;
begin
  Assemble_integer := Str_to_integer(Assemble_string);
end; {function Assemble_integer}


function Assemble_long: long_type;
begin
  Assemble_long := Str_to_integer(Assemble_string);
end; {function Assemble_long}


function Assemble_scalar: scalar_type;
begin
  Assemble_scalar := Str_to_scalar(Assemble_string);
end; {function Assemble_scalar}


function Assemble_double: double_type;
begin
  Assemble_double := Str_to_double(Assemble_string);
end; {function Assemble_double}


function Assemble_string: string_type;
var
  str: string_type;
begin
  if not asm_newline then
    Match_space;

  str := '';

  while not (next_char in whitespace) do
    begin
      str := concat(str, Char_to_str(next_char));
      Get_next_char;
      asm_newline := false;
    end;

  Assemble_string := str;
end; {function Assemble_string}


function Assemble_name: string_type;
var
  str: string_type;
begin
  if not asm_newline then
    Match_space;

  if next_char = '"' then
    begin
      Get_next_char;
      str := '';

      while (next_char <> '"') do
        begin
          str := concat(str, Char_to_str(next_char));
          Get_next_char;
        end;

      Get_next_char;
      asm_newline := false;
    end
  else
    str := '';

  Assemble_name := str;
end; {function Assemble_name}


{*************************************************}
{ routines to write primitive assembly code units }
{*************************************************}


procedure Disassemble_pseudo_mnemonic(var outfile: text;
  mnemonic: mnemonic_type);
begin
  write(outfile, mnemonic);
  disasm_newline := false;
end; {procedure Disassemble_pseudo_mnemonic}


procedure Disassemble_newline(var outfile: text);
begin
  writeln(outfile);
  disasm_newline := true;
end; {procedure Disassemble_newline}


procedure Disassemble_mnemonic(var outfile: text;
  mnemonic: mnemonic_type);
begin
  {***********************************************}
  { mnemonics always begin at the start of a line }
  {***********************************************}
  Disassemble_newline(outfile);
  write(outfile, mnemonic);
  disasm_newline := false;
end; {procedure Disassemble_mnemonic}


procedure Disassemble_index(var outfile: text;
  asm_index: asm_index_type);
begin
  if asm_index <> 0 then
    begin
      if not disasm_newline then
        write(outfile, ' ');
      write(outfile, Integer_to_str(asm_index));
      disasm_newline := false;
    end
  else
    Disasm_error;
end; {procedure Disassemble_index}


{*************************************************}
{ routines to write primitive assembly data units }
{*************************************************}


procedure Disassemble_boolean(var outfile: text;
  boolean_val: boolean_type);
begin
  if not disasm_newline then
    write(outfile, ' ');

  if ascii_booleans then
    begin
      if boolean_val then
        write(outfile, 'T')
      else
        write(outfile, 'F');
    end
  else
    begin
      if boolean_val then
        write(outfile, '1')
      else
        write(outfile, '0');
    end;

  disasm_newline := false;
end; {procedure Disassemble_boolean}


procedure Disassemble_char(var outfile: text;
  char_val: char_type);
begin
  if ascii_chars then
    begin
      if not disasm_newline then
        write(outfile, ' ');

      write(outfile, '"');
      write(outfile, char_val);
      write(outfile, '"');

      disasm_newline := false;
    end
  else
    Disassemble_integer(outfile, ord(char_val));
end; {procedure Disassemble_char}


procedure Disassemble_byte(var outfile: text;
  byte_val: byte_type);
begin
  if not disasm_newline then
    write(outfile, ' ');
  write(outfile, Integer_to_str(byte_val));
  disasm_newline := false;
end; {procedure Disassemble_byte}


procedure Disassemble_short(var outfile: text;
  short_val: short_type);
begin
  if not disasm_newline then
    write(outfile, ' ');
  write(outfile, Integer_to_str(short_val));
  disasm_newline := false;
end; {procedure Disassemble_short}


procedure Disassemble_integer(var outfile: text;
  integer_val: integer_type);
begin
  if not disasm_newline then
    write(outfile, ' ');
  write(outfile, Integer_to_str(integer_val));
  disasm_newline := false;
end; {procedure Disassemble_integer}


procedure Disassemble_long(var outfile: text;
  long_val: long_type);
begin
  if not disasm_newline then
    write(outfile, ' ');
  write(outfile, Integer_to_str(long_val));
  disasm_newline := false;
end; {procedure Disassemble_long}


procedure Disassemble_scalar(var outfile: text;
  scalar_val: scalar_type;
  decimal_places: integer;
  exponential_notation: boolean);
begin
  if not disasm_newline then
    write(outfile, ' ');
  write(outfile, Scalar_to_str(scalar_val, decimal_places,
    exponential_notation));
  disasm_newline := false;
end; {procedure Disassemble_scalar}


procedure Disassemble_double(var outfile: text;
  double_val: double_type;
  decimal_places: integer;
  exponential_notation: boolean);
begin
  if not disasm_newline then
    write(outfile, ' ');
  write(outfile, Double_to_str(double_val, decimal_places,
    exponential_notation));
  disasm_newline := false;
end; {procedure Disassemble_double}


procedure Disassemble_string(var outfile: text;
  str: string_type);
begin
  if not disasm_newline then
    write(outfile, ' ');
  write(outfile, str);
  disasm_newline := false;
end; {procedure Disassemble_string}


procedure Disassemble_name(var outfile: text;
  name: string_type);
begin
  if not disasm_newline then
    write(outfile, ' ');
  write(outfile, Quotate_str(name));
  disasm_newline := false;
end; {procedure Disassemble_name}


initialization
  {************************}
  { initialize line counts }
  {************************}
  asm_line_count := 0;
  disasm_line_count := 0;

  {************************}
  { initialize line status }
  {************************}
  asm_newline := true;
  disasm_newline := true;
end.

