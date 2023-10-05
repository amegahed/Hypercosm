unit data_types;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             data_types                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the definitions of primitive       }
{       data types which are used by the interpreter.           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


type
  {********************************************}
  { definition of non standard primitive types }
  {********************************************}
  boolean_type = boolean;
  char_type = char;

  byte_type = 0..255;
  short_type = integer;

  integer_type = integer;
  long_type = longint;

  scalar_type = real;
  double_type = extended;


implementation


end.
