unit constants;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             constants                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{        This module contains miscillaneous ascii and           }
{        numerical constants that may be handy.                 }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


var
  {*****************}
  { range constants }
  {*****************}
  infinity: real;
  tiny: real;

  {****************}
  { math constants }
  {****************}
  root_2, root_3: real;


implementation


initialization
  {**********************}
  { init range constants }
  {**********************}
  infinity := 1E38;
  tiny := 1E-6;

  {*********************}
  { init math constants }
  {*********************}
  root_2 := sqrt(2);
  root_3 := sqrt(3);
end.
