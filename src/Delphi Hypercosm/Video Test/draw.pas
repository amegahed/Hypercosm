unit draw;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm                draw                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{        This module contains routines for handling error       }
{        messages.                                              }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  drawable, video;


procedure Draw_picture(canvas: drawable_type);


implementation
uses
  Math, colors, pixels;


function Random_color: color_type;
var
  color: color_type;
begin
  color.r := RandomRange(0, 256) / 256;
  color.g := RandomRange(0, 256) / 256;
  color.b := RandomRange(0, 256) / 256;
  Random_color := color;
end; {function Random_color}


procedure Draw_picture(canvas: drawable_type);
const
  border = 10;
var
  lines: integer;
  pixel1, pixel2: pixel_type;
  size: pixel_type;
begin
  canvas.Set_color(To_color(0.5, 0.5, 1.0));
  canvas.Clear;
  size := canvas.Get_size;

  for lines := 1 to 1000 do
    begin
      canvas.Set_color(Random_color);
      pixel1.h := RandomRange(border, size.h - border);
      pixel1.v := RandomRange(border, size.v - border);
      pixel2.h := RandomRange(border, size.h - border);
      pixel2.v := RandomRange(border, size.v - border);
      canvas.Draw_line(pixel1, pixel2);
    end;

  canvas.Update;
end; {procedure Draw_picture}


end.

