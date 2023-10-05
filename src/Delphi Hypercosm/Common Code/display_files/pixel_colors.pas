unit pixel_colors;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            pixel_colors               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module has the basic rgb color declarations        }
{       and operations.                                         }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  colors;


type
  pixel_color_component_ptr_type = ^pixel_color_component_type;
  pixel_color_component_type = byte;


  pixel_color_ptr_type = ^pixel_color_type;
  pixel_color_type = record
    r, g, b: pixel_color_component_type;
  end; {pixel_color_type}


var
  {***************************}
  { monochrome primary colors }
  {***************************}
  black_pixel, white_pixel, grey_pixel: pixel_color_type;

  {*************************}
  { addative primary colors }
  {*************************}
  red_pixel, green_pixel, blue_pixel: pixel_color_type;

  {****************************}
  { subtractive primary colors }
  {****************************}
  cyan_pixel, magenta_pixel, yellow_pixel: pixel_color_type;


{*******************}
{ color constructor }
{*******************}
function To_pixel_color(r, g, b: byte): pixel_color_type;

{****************************}
{ color conversion functions }
{****************************}
function Color_to_pixel_color(color: color_type): pixel_color_type;
function Pixel_color_to_color(pixel_color: pixel_color_type): color_type;

{***************************}
{ color comparison routines }
{***************************}
function Equal_pixel_color(color1, color2: pixel_color_type): boolean;

{******************************}
{ color modification functions }
{******************************}
function Mix_pixel_color(color1, color2: pixel_color_type): pixel_color_type;
function Contrast_pixel_color(color1, color2: pixel_color_type):
  pixel_color_type;

{****************************}
{ color diagnostic functions }
{****************************}
procedure Write_pixel_color(color: pixel_color_type);


implementation


type
  {**************************************************}
  { this array is used to quickly cast integers from }
  { 0 to 255 to floating point numbers from 0 to 1.  }
  {**************************************************}
  pixel_color_to_color_array_type = array[0..255] of real;


var
  pixel_color_to_color_array: pixel_color_to_color_array_type;


procedure Init_pixel_color_to_color_array;
var
  counter: integer;
begin
  for counter := 1 to 255 do
    pixel_color_to_color_array[counter] := counter / 255;
end; {procedure Init_pixel_color_to_color_array}


procedure Init_primary_pixel_colors;
begin
  {**************************************}
  { initialize monochrome primary colors }
  {**************************************}
  black_pixel := Color_to_pixel_color(To_color(0, 0, 0));
  white_pixel := Color_to_pixel_color(To_color(1, 1, 1));
  grey_pixel := Color_to_pixel_color(To_color(0.5, 0.5, 0.5));

  {************************************}
  { initialize addative primary colors }
  {************************************}
  red_pixel := Color_to_pixel_color(To_color(1, 0, 0));
  green_pixel := Color_to_pixel_color(To_color(0, 1, 0));
  blue_pixel := Color_to_pixel_color(To_color(0, 0, 1));

  {***************************************}
  { initialize subtractive primary colors }
  {***************************************}
  cyan_pixel := Color_to_pixel_color(To_color(0, 1, 1));
  magenta_pixel := Color_to_pixel_color(To_color(1, 0, 1));
  yellow_pixel := Color_to_pixel_color(To_color(1, 1, 0));
end; {procedure Init_primary_pixel_colors}


{*******************}
{ color constructor }
{*******************}


function To_pixel_color(r, g, b: byte): pixel_color_type;
var
  color: pixel_color_type;
begin
  color.r := r;
  color.g := g;
  color.b := b;
  To_pixel_color := color;
end; {function To_pixel_color}


{****************************}
{ color conversion functions }
{****************************}


function Color_to_pixel_color(color: color_type): pixel_color_type;
var
  pixel_color: pixel_color_type;
begin
  pixel_color.r := byte(Trunc(color.r * 255));
  pixel_color.g := byte(Trunc(color.g * 255));
  pixel_color.b := byte(Trunc(color.b * 255));
  Color_to_pixel_color := pixel_color;
end; {function Color_to_pixel_color}


function Pixel_color_to_color(pixel_color: pixel_color_type): color_type;
var
  color: color_type;
  r, g, b: integer;
begin
  r := Integer(pixel_color.r);
  g := Integer(pixel_color.g);
  b := Integer(pixel_color.b);

  if (r < 0) then
    r := r + 256;
  if (g < 0) then
    g := g + 256;
  if (b < 0) then
    b := b + 256;

  color.r := pixel_color_to_color_array[r];
  color.g := pixel_color_to_color_array[g];
  color.b := pixel_color_to_color_array[b];

  {color.r := r / 255.0;}
  {color.g := g / 255.0;}
  {color.b := b / 255.0;}

  Pixel_color_to_color := color;
end; {function Pixel_color_to_color}


{***************************}
{ color comparison routines }
{***************************}


function Equal_pixel_color(color1, color2: pixel_color_type): boolean;
var
  equal: boolean;
begin
  if (color1.r <> color2.r) then
    equal := false
  else if (color1.g <> color2.g) then
    equal := false
  else if (color1.b <> color2.b) then
    equal := false
  else
    equal := true;

  Equal_pixel_color := equal;
end; {function Equal_pixel_color}


{******************************}
{ color modification functions }
{******************************}


function Mix_pixel_color(color1, color2: pixel_color_type): pixel_color_type;
begin
  color1.r := integer(color1.r) + integer(color2.r);
  color1.g := integer(color1.g) + integer(color2.g);
  color1.b := integer(color1.b) + integer(color2.b);
  Mix_pixel_color := color1;
end; {function Mix_pixel_color}


function Contrast_pixel_color(color1, color2: pixel_color_type):
  pixel_color_type;
begin
  color1.r := color1.r - color2.r;
  color1.g := color1.g - color2.g;
  color1.b := color1.b - color2.b;
  Contrast_pixel_color := color1;
end; {function Contrast_pixel_color}


{****************************}
{ color diagnostic functions }
{****************************}


procedure Write_pixel_color(color: pixel_color_type);
begin
  write(color.r: 1, ' ');
  write(color.g: 1, ' ');
  write(color.b: 1);
end; {procedure Write_pixel_color}


initialization
  Init_pixel_color_to_color_array;
  Init_primary_pixel_colors;
end.
