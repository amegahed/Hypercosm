unit screen_boxes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            screen_boxes               3d       }
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
uses
  pixels;


type
  screen_box_type = record
    min, max: pixel_type;
  end; {screen_box_type}


var
  null_screen_box: screen_box_type;


{************************}
{ screen box constructor }
{************************}
function To_screen_box(min, max: pixel_type): screen_box_type;

{*********************}
{ screen box routines }
{*********************}
procedure Init_screen_box(var screen_box: screen_box_type;
  size: pixel_type);
procedure Clip_screen_box(var screen_box: screen_box_type;
  size: pixel_type);
procedure Reset_screen_box(var screen_box: screen_box_type);

{****************************}
{ screen box update routines }
{****************************}
procedure Update_screen_box(var screen_box: screen_box_type;
  pixel: pixel_type);
procedure Extend_screen_box(var screen_box1: screen_box_type;
  screen_box2: screen_box_type);

{******************************}
{ screen box querying routines }
{******************************}
function Pixel_in_screen_box(pixel: pixel_type;
  screen_box: screen_box_type): boolean;

{********************************}
{ screen box diagnostic routines }
{********************************}
procedure Write_screen_box(screen_box: screen_box_type);


implementation


{************************}
{ screen box constructor }
{************************}


function To_screen_box(min, max: pixel_type): screen_box_type;
var
  screen_box: screen_box_type;
begin
  screen_box.min := min;
  screen_box.max := max;
  To_screen_box := screen_box;
end; {function To_screen_box}


{*********************}
{ screen box routines }
{*********************}


procedure Init_screen_box(var screen_box: screen_box_type;
  size: pixel_type);
begin
  with screen_box do
    begin
      min := null_pixel;
      max := size;
    end;
end; {procedure Init_screen_box}


procedure Clip_screen_box(var screen_box: screen_box_type;
  size: pixel_type);
begin
  with screen_box do
    begin
      if (min.h < 0) then
        min.h := 0;
      if (min.v < 0) then
        min.v := 0;
      if (max.h > size.h) then
        max.h := size.h;
      if (max.v > size.v) then
        max.v := size.v;
    end;
end; {procedure Clip_screen_box}


procedure Reset_screen_box(var screen_box: screen_box_type);
begin
  with screen_box do
    begin
      min.h := maxint;
      min.v := maxint;
      max.h := -1;
      max.v := -1;
    end;
end; {procedure Reset_screen_box}


{****************************}
{ screen box update routines }
{****************************}


procedure Update_screen_box(var screen_box: screen_box_type;
  pixel: pixel_type);
begin
  if pixel.h < screen_box.min.h then
    screen_box.min.h := pixel.h;
  if pixel.v < screen_box.min.v then
    screen_box.min.v := pixel.v;
  if pixel.h > screen_box.max.h then
    screen_box.max.h := pixel.h;
  if pixel.v > screen_box.max.v then
    screen_box.max.v := pixel.v;
end; {procedure Update_screen_box}


procedure Extend_screen_box(var screen_box1: screen_box_type;
  screen_box2: screen_box_type);
begin
  with screen_box1 do
    if (min.h < max.h) and (min.v < max.v) then
      begin
        {*************************}
        { screen_box1 initialized }
        {*************************}
        if (screen_box2.min.h < screen_box2.max.h) then
          if (screen_box2.min.v < screen_box2.max.v) then
            begin
              if (screen_box2.min.h < min.h) then
                min.h := screen_box2.min.h;
              if (screen_box2.min.v < min.v) then
                min.v := screen_box2.min.v;
              if (screen_box2.max.h > max.h) then
                max.h := screen_box2.max.h;
              if (screen_box2.max.v > max.v) then
                max.v := screen_box2.max.v;
            end;
      end
    else
      begin
        {*****************************}
        { screen_box1 not initialized }
        {*****************************}
        screen_box1 := screen_box2;
      end;
end; {procedure Extend_screen_box}


{******************************}
{ screen box querying routines }
{******************************}


function Pixel_in_screen_box(pixel: pixel_type;
  screen_box: screen_box_type): boolean;
var
  inside: boolean;
begin
  if pixel.h < screen_box.min.h then
    inside := false
  else if pixel.h > screen_box.max.h then
    inside := false
  else if pixel.v < screen_box.min.v then
    inside := false
  else if pixel.v > screen_box.max.v then
    inside := false
  else
    inside := true;

  Pixel_in_screen_box := inside;
end; {function Pixel_in_screen_box}


{********************************}
{ screen box diagnostic routines }
{********************************}


procedure Write_screen_box(screen_box: screen_box_type);
begin
  with screen_box do
    begin
      writeln('screen box:');
      writeln('h min = ', min.h);
      writeln('h max = ', max.h);
      writeln('v min = ', min.v);
      writeln('v max = ', max.v);
    end;
end; {procedure Write_screen_box}


initialization
  null_screen_box.min := null_pixel;
  null_screen_box.max := null_pixel;
end.
