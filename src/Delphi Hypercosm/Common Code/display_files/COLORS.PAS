unit colors;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              colors                   3d       }
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
  vectors;


type
  color_type = record
    r, g, b: real;
  end; {color_type}


var
  {***************************}
  { monochrome primary colors }
  {***************************}
  black_color, white_color, grey_color: color_type;

  {*************************}
  { addative primary colors }
  {*************************}
  red_color, green_color, blue_color: color_type;

  {****************************}
  { subtractive primary colors }
  {****************************}
  cyan_color, magenta_color, yellow_color: color_type;


{*******************}
{ color constructor }
{*******************}
function To_color(r, g, b: real): color_type;

{****************************}
{ color conversion functions }
{****************************}
function Vector_to_color(vector: vector_type): color_type;
function Color_to_vector(color: color_type): vector_type;

{***************************}
{ color comparison routines }
{***************************}
function Equal_color(color1, color2: color_type): boolean;

{******************************}
{ color modification functions }
{******************************}
function Intensify_color(color: color_type;
  intensity: real): color_type;
function Mix_color(color1, color2: color_type): color_type;
function Contrast_color(color1, color2: color_type): color_type;
function Filter_color(color, filter: color_type): color_type;
function Color_brightness(color: color_type): real;
function Color_brightness_squared(color: color_type): real;
function Clip_color(color: color_type): color_type;

{****************************}
{ color diagnostic functions }
{****************************}
procedure Write_color(color: color_type);


implementation


{*******************}
{ color constructor }
{*******************}


function To_color(r, g, b: real): color_type;
var
  color: color_type;
begin
  color.r := r;
  color.g := g;
  color.b := b;
  To_color := color;
end; {function To_color}


{****************************}
{ color conversion functions }
{****************************}


function Vector_to_color(vector: vector_type): color_type;
var
  color: color_type;
begin
  color.r := vector.x;
  color.g := vector.y;
  color.b := vector.z;
  Vector_to_color := color;
end; {function Vector_to_color}


function Color_to_vector(color: color_type): vector_type;
var
  vector: vector_type;
begin
  vector.x := color.r;
  vector.y := color.g;
  vector.z := color.b;
  Color_to_vector := vector;
end; {function Color_to_vector}


{***************************}
{ color comparison routines }
{***************************}


function Equal_color(color1, color2: color_type): boolean;
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

  Equal_color := equal;
end; {function Equal_color}


{******************************}
{ color modification functions }
{******************************}


function Intensify_color(color: color_type;
  intensity: real): color_type;
begin
  color.r := color.r * intensity;
  color.g := color.g * intensity;
  color.b := color.b * intensity;
  Intensify_color := color;
end; {function Intensify_color}


function Mix_color(color1, color2: color_type): color_type;
begin
  color1.r := color1.r + color2.r;
  color1.g := color1.g + color2.g;
  color1.b := color1.b + color2.b;
  Mix_color := color1;
end; {function Mix_color}


function Contrast_color(color1, color2: color_type): color_type;
begin
  color1.r := color1.r - color2.r;
  color1.g := color1.g - color2.g;
  color1.b := color1.b - color2.b;
  Contrast_color := color1;
end; {function Contrast_color}


function Filter_color(color, filter: color_type): color_type;
begin
  color.r := color.r * filter.r;
  color.g := color.g * filter.g;
  color.b := color.b * filter.b;
  Filter_color := color;
end; {function Filter_color}


function Color_brightness(color: color_type): real;
begin
  with color do
    Color_brightness := sqrt((r * r) + (g * g) + (b * b));
end; {function Color_brightness}


function Color_brightness_squared(color: color_type): real;
begin
  with color do
    Color_brightness_squared := (r * r) + (g * g) + (b * b);
end; {function Color_brightness_squared}


function Clip_color(color: color_type): color_type;
begin
  {**************************}
  { check for color overflow }
  {**************************}
  if (color.r > 1.0) then
    color.r := 1.0;
  if (color.g > 1.0) then
    color.g := 1.0;
  if (color.b > 1.0) then
    color.b := 1.0;

  {***************************}
  { check for color underflow }
  {***************************}
  if (color.r < 0.0) then
    color.r := 0.0;
  if (color.g < 0.0) then
    color.g := 0.0;
  if (color.b < 0.0) then
    color.b := 0.0;

  Clip_color := color;
end; {function Clip_color}


function Burnout_color(color: color_type): color_type;
var
  extra, extra_red, extra_green, extra_blue: real;
begin
  extra_red := 0;
  extra_green := 0;
  extra_blue := 0;

  with color do
    begin
      if (r > 1) then {extra red light spills over into green and blue}
        begin
          extra := (r - 1) / 2;
          extra_green := extra_green + extra;
          extra_blue := extra_blue + extra;
        end;

      if (g > 1) then {extra green light spills over into red and blue}
        begin
          extra := (g - 1) / 2;
          extra_red := extra_red + extra;
          extra_blue := extra_blue + extra;
        end;

      if (b > 1) then {extra blue light spills over into red and green}
        begin
          extra := (b - 1) / 2;
          extra_red := extra_red + extra;
          extra_green := extra_green + extra;
        end;

      r := r + extra_red;
      g := g + extra_green;
      b := b + extra_blue;
    end;

  Burnout_color := Clip_color(color);
end; {function Burnout_color}


{****************************}
{ color diagnostic functions }
{****************************}


procedure Write_color(color: color_type);
begin
  write(color.r: 4: 4, ' ');
  write(color.g: 4: 4, ' ');
  write(color.b: 4: 4);
end; {procedure Write_color}


initialization
  {**************************************}
  { initialize monochrome primary colors }
  {**************************************}
  black_color := To_color(0, 0, 0);
  white_color := To_color(1, 1, 1);
  grey_color := To_color(0.5, 0.5, 0.5);

  {************************************}
  { initialize addative primary colors }
  {************************************}
  red_color := To_color(1, 0, 0);
  green_color := To_color(0, 1, 0);
  blue_color := To_color(0, 0, 1);

  {***************************************}
  { initialize subtractive primary colors }
  {***************************************}
  cyan_color := To_color(0, 1, 1);
  magenta_color := To_color(1, 0, 1);
  yellow_color := To_color(1, 1, 0);
end.
