unit pack_bytes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             pack_bytes                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to pack bytes into        }
{       different forms using differing byte orderings.         }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


type
  {*********************************************}
  { structures used to pack integers into bytes }
  {*********************************************}
  integer_bytes_ptr_type = ^integer_bytes_type;
  integer_bytes_type = record
    hi, lo: byte;
  end; {integer_bytes_type}

  long_bytes_ptr_type = ^long_bytes_type;
  long_bytes_type = record
    hi, lo: integer_bytes_type;
  end; {long_bytes_type}


{***************************}
{ routines to pack integers }
{***************************}
function Integer_to_bytes(l: longint): integer_bytes_type;
function Integer_to_reverse_bytes(l: longint): integer_bytes_type;
function Long_to_bytes(l: longint): long_bytes_type;
function Long_to_reverse_bytes(l: longint): long_bytes_type;

{**********************************}
{ routines to change byte ordering }
{**********************************}
function Reverse_integer_bytes(bytes: integer_bytes_type): integer_bytes_type;

{*****************************}
{ routines to unpack integers }
{*****************************}
function Bytes_to_integer(bytes: integer_bytes_type): longint;
function Bytes_to_long(bytes: long_bytes_type): longint;

{******************************}
{ routines to write to buffers }
{******************************}
procedure Write_integer_bytes(var buffer_ptr: integer_bytes_ptr_type;
  l: longint);
procedure Write_long_bytes(var buffer_ptr: long_bytes_ptr_type;
  l: longint);


implementation


{***************************}
{ routines to pack integers }
{***************************}


function Integer_to_bytes(l: longint): integer_bytes_type;
var
  bytes: integer_bytes_type;
begin
  bytes.hi := byte(l div 256);
  bytes.lo := byte(l mod 256);
  Integer_to_bytes := bytes;
end; {function Integer_to_bytes}


function Integer_to_reverse_bytes(l: longint): integer_bytes_type;
var
  bytes: integer_bytes_type;
begin
  bytes.lo := byte(l div 256);
  bytes.hi := byte(l mod 256);
  Integer_to_reverse_bytes := bytes;
end; {function Integer_to_reverse_bytes}


function Long_to_bytes(l: longint): long_bytes_type;
var
  hi, lo: longint;
  bytes: long_bytes_type;
begin
  hi := l div 65536;
  lo := l mod 65536;
  bytes.hi := Integer_to_bytes(hi);
  bytes.lo := Integer_to_bytes(lo);
  Long_to_bytes := bytes;
end; {function Long_to_bytes}


function Long_to_reverse_bytes(l: longint): long_bytes_type;
var
  hi, lo: longint;
  bytes: long_bytes_type;
begin
  hi := l div 65536;
  lo := l mod 65536;
  bytes.lo := Integer_to_reverse_bytes(hi);
  bytes.hi := Integer_to_reverse_bytes(lo);
  Long_to_reverse_bytes := bytes;
end; {function Long_to_reverse_bytes}


{**********************************}
{ routines to change byte ordering }
{**********************************}


function Reverse_integer_bytes(bytes: integer_bytes_type): integer_bytes_type;
var
  b: byte;
begin
  b := bytes.hi;
  bytes.hi := bytes.lo;
  bytes.lo := b;
  Reverse_integer_bytes := bytes;
end; {function Reverse_integer_bytes}


function Reverse_long_bytes(bytes: long_bytes_type): long_bytes_type;
var
  integer_bytes: integer_bytes_type;
begin
  integer_bytes := bytes.hi;
  bytes.hi := Reverse_integer_bytes(bytes.lo);
  bytes.lo := Reverse_integer_bytes(integer_bytes);
  Reverse_long_bytes := bytes;
end; {function Reverse_long_bytes}


{*****************************}
{ routines to unpack integers }
{*****************************}


function Bytes_to_integer(bytes: integer_bytes_type): longint;
var
  i: longint;
begin
  if bytes.hi < 0 then
    i := integer(bytes.hi) + 256
  else
    i := bytes.hi;

  Bytes_to_integer := (i * 256) + bytes.lo;
end; {function Bytes_to_integer}


function Bytes_to_long(bytes: long_bytes_type): longint;
var
  hi, lo: longint;
begin
  hi := Bytes_to_integer(bytes.hi);
  lo := Bytes_to_integer(bytes.lo);
  Bytes_to_long := (hi * 65536) + lo;
end; {function Bytes_to_long}


{******************************}
{ routines to write to buffers }
{******************************}


procedure Write_integer_bytes(var buffer_ptr: integer_bytes_ptr_type;
  l: longint);
begin
  buffer_ptr^ := Integer_to_bytes(l);
  buffer_ptr := integer_bytes_ptr_type(longint(buffer_ptr) +
    sizeof(integer_bytes_type));
end; {procedure Write_integer_bytes}


procedure Write_long_bytes(var buffer_ptr: long_bytes_ptr_type;
  l: longint);
begin
  buffer_ptr^ := Long_to_bytes(l);
  buffer_ptr := long_bytes_ptr_type(longint(buffer_ptr) +
    sizeof(long_bytes_type));
end; {procedure Write_long_bytes}


end. {pack_bytes}
