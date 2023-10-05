unit pixels;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               pixels                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains some basic pixel related           }
{       routines and data structs.                              }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


type
  pixel_type = record
    h, v: integer;
  end; {pixel_type}


var
  null_pixel, unit_pixel: pixel_type;


{*******************}
{ pixel constructor }
{*******************}
function To_pixel(h, v: integer): pixel_type;

{*****************}
{ pixel operators }
{*****************}
function Pixel_sum(pixel1, pixel2: pixel_type): pixel_type;
function Pixel_difference(pixel1, pixel2: pixel_type): pixel_type;
function Pixel_scale(pixel: pixel_type;
  s: real): pixel_type;
function Equal_pixels(pixel1, pixel2: pixel_type): boolean;

{***************}
{ pixel methods }
{***************}
procedure Clip_pixel(var pixel: pixel_type;
  min, max: pixel_type);
procedure Write_pixel(pixel: pixel_type);


implementation


{*******************}
{ pixel constructor }
{*******************}


function To_pixel(h, v: integer): pixel_type;
var
  pixel: pixel_type;
begin
  pixel.h := h;
  pixel.v := v;
  To_pixel := pixel;
end; {function To_pixel}


{*****************}
{ pixel operators }
{*****************}


function Pixel_sum(pixel1, pixel2: pixel_type): pixel_type;
var
  pixel: pixel_type;
begin
  pixel.h := pixel1.h + pixel2.h;
  pixel.v := pixel1.v + pixel2.v;
  Pixel_sum := pixel;
end; {function Pixel_sum}


function Pixel_difference(pixel1, pixel2: pixel_type): pixel_type;
var
  pixel: pixel_type;
begin
  pixel.h := pixel1.h - pixel2.h;
  pixel.v := pixel1.v - pixel2.v;
  Pixel_difference := pixel;
end; {function Pixel_difference}


function Pixel_scale(pixel: pixel_type;
  s: real): pixel_type;
begin
  pixel.h := trunc(pixel.h * s);
  pixel.v := trunc(pixel.v * s);
  Pixel_scale := pixel;
end; {function Pixel_scale}


function Equal_pixels(pixel1, pixel2: pixel_type): boolean;
begin
  Equal_pixels := (pixel1.h = pixel2.h) and (pixel1.v = pixel2.v);
end; {function Equal_pixels}


{***************}
{ pixel methods }
{***************}


procedure Clip_pixel(var pixel: pixel_type;
  min, max: pixel_type);
begin
  if (pixel.h < min.h) then
    pixel.h := min.h
  else if (pixel.h > max.h) then
    pixel.h := max.h;

  if (pixel.v < min.v) then
    pixel.v := min.v
  else if (pixel.v > max.v) then
    pixel.v := max.v;
end; {procedure Clip_pixel}


procedure Write_pixel(pixel: pixel_type);
begin
  write(pixel.h, ' ', pixel.v);
end; {procedure Write_pixel}


initialization
  null_pixel.h := 0;
  null_pixel.v := 0;
  unit_pixel.h := 1;
  unit_pixel.v := 1;
end.
