unit images;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               images                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to define and             }
{       manipulate 2d images.                                   }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  pixels, pixel_colors, vectors2;


type
  image_ptr_type = ^image_type;
  image_type = record
    size: pixel_type;
    pixel_color_ptr: pixel_color_ptr_type;
    next: image_ptr_type;
  end; {image_type}


{****************************}
{ constructor and destructor }
{****************************}
function New_image(size: pixel_type): image_ptr_type;
procedure Free_image(var image_ptr: image_ptr_type);

{**************************}
{ routines to query images }
{**************************}
procedure Get_image_info(image_ptr: image_ptr_type;
  var size: pixel_type);
function Get_image_color(image_ptr: image_ptr_type;
  pixel: pixel_type): pixel_color_type;
function Interpolate_image_color(image_ptr: image_ptr_type;
  point: vector2_type): pixel_color_type;

{***************************}
{ routines to modify images }
{***************************}
procedure Set_image_color(image_ptr: image_ptr_type;
  pixel: pixel_type;
  pixel_color: pixel_color_type);


implementation
uses
  new_memory, colors, screen_boxes;


const
  memory_alert = false;


var
  image_free_list: image_ptr_type;


{*****************************************}
{ routines for dealing with color buffers }
{*****************************************}


function New_image_color_buffer(size: pixel_type): pixel_color_ptr_type;
var
  buffer_ptr: pixel_color_ptr_type;
  buffer_size: longint;
begin
  buffer_size := longint(size.h + 1) * longint(size.v + 1);
  buffer_size := buffer_size * sizeof(pixel_color_type);

  if memory_alert then
    writeln('allocating color buffer');
  buffer_ptr := pixel_color_ptr_type(New_ptr(buffer_size));

  New_image_color_buffer := buffer_ptr;
end; {function New_image_color_buffer}


function Index_image(image_ptr: image_ptr_type;
  pixel: pixel_type): pixel_color_ptr_type;
var
  offset: longint;
begin
  with image_ptr^ do
    begin
      offset := (longint(pixel.h) + (longint(pixel.v) *
        longint(image_ptr^.size.h))) * sizeof(pixel_color_type);
      Index_image := pixel_color_ptr_type(longint(pixel_color_ptr) + offset);
    end;
end; {function Index_image}


{****************************}
{ constructor and destructor }
{****************************}


procedure Init_image(image_ptr: image_ptr_type);
var
  pixel_color_ptr: pixel_color_ptr_type;
  h_counter, v_counter: integer;
begin
  {********************************}
  { initialize image buffer memory }
  {********************************}
  pixel_color_ptr := image_ptr^.pixel_color_ptr;
  for v_counter := 0 to image_ptr^.size.v do
    begin
      for h_counter := 0 to image_ptr^.size.h do
        begin
          pixel_color_ptr^ := black_pixel;
          pixel_color_ptr := pixel_color_ptr_type(longint(pixel_color_ptr) +
            sizeof(pixel_color_type));
        end;
    end;
end; {function Init_image}


function New_image(size: pixel_type): image_ptr_type;
var
  image_ptr: image_ptr_type;
begin
  {**************************}
  { get image from free list }
  {**************************}
  if image_free_list <> nil then
    begin
      image_ptr := image_free_list;
      image_free_list := image_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new image');
      new(image_ptr);
    end;

  {******************}
  { initialize image }
  {******************}
  image_ptr^.size := size;
  with image_ptr^ do
    begin
      pixel_color_ptr := New_image_color_buffer(size);
      next := nil;
    end;
  Init_image(image_ptr);

  New_image := image_ptr;
end; {function New_image}


procedure Free_image(var image_ptr: image_ptr_type);
begin
  {*************************}
  { dispose of color buffer }
  {*************************}
  dispose(image_ptr^.pixel_color_ptr);

  {************************}
  { add image to free list }
  {************************}
  image_ptr^.next := image_free_list;
  image_free_list := image_ptr;
  image_ptr := nil;
end; {procedure Free_image}


{**************************}
{ routines to query images }
{**************************}


procedure Get_image_info(image_ptr: image_ptr_type;
  var size: pixel_type);
begin
  if image_ptr <> nil then
    size := image_ptr^.size;
end; {procedure Get_image_info}


function Get_image_color(image_ptr: image_ptr_type;
  pixel: pixel_type): pixel_color_type;
var
  pixel_color: pixel_color_type;
begin
  if Pixel_in_screen_box(pixel, To_screen_box(null_pixel, image_ptr^.size)) then
    pixel_color := Index_image(image_ptr, pixel)^
  else
    pixel_color := black_pixel;

  Get_image_color := pixel_color;
end; {function Get_image_color}


function Interpolate_image_color(image_ptr: image_ptr_type;
  point: vector2_type): pixel_color_type;
var
  x1, x2, y1, y2: integer;
  pixel_color1, pixel_color2, pixel_color3, pixel_color4: pixel_color_type;
  color, color1, color2, color3, color4: color_type;
begin
  {************************}
  { snap to nearest pixels }
  {************************}
  x1 := Trunc(point.x);
  y1 := Trunc(point.y);
  x2 := Trunc(point.x + 1);
  y2 := Trunc(point.y + 1);

  {************************}
  { interpolate horizontal }
  {************************}
  pixel_color1 := Get_image_color(image_ptr, To_pixel(x1, y1));
  pixel_color2 := Get_image_color(image_ptr, To_pixel(x2, y1));
  pixel_color3 := Get_image_color(image_ptr, To_pixel(x1, y2));
  pixel_color4 := Get_image_color(image_ptr, To_pixel(x2, y2));

  color1 := Pixel_color_to_color(pixel_color1);
  color2 := Pixel_color_to_color(pixel_color2);
  color3 := Pixel_color_to_color(pixel_color3);
  color4 := Pixel_color_to_color(pixel_color4);

  color1 := Intensify_color(color1, (x2 - point.x));
  color2 := Intensify_color(color2, (point.x - x1));
  color3 := Intensify_color(color3, (x2 - point.x));
  color4 := Intensify_color(color4, (point.x - x1));

  color1 := Intensify_color(Mix_color(color1, color2), (y2 - point.y));
  color2 := Intensify_color(Mix_color(color3, color4), (point.y - y1));
  color := Mix_color(color1, color2);

  Interpolate_image_color := Color_to_pixel_color(color);
end; {function Interpolate_image_color}


{***************************}
{ routines to modify images }
{***************************}


procedure Set_image_color(image_ptr: image_ptr_type;
  pixel: pixel_type;
  pixel_color: pixel_color_type);
begin
  if Pixel_in_screen_box(pixel, To_screen_box(null_pixel, image_ptr^.size)) then
    Index_image(image_ptr, pixel)^ := pixel_color;
end; {procedure Set_image_color}


initialization
  image_free_list := nil;
end.
