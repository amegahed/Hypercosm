unit bitmaps;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              bitmaps                  3d       }
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
  pixels, pixel_colors, images;


type
  bitmap_ptr_type = ^bitmap_type;
  bitmap_type = record
    size: pixel_type;
    length: longint;
    pixel_color_component_ptr: pixel_color_component_ptr_type;
    next: bitmap_ptr_type;
  end; {bitmap_type}


{****************************}
{ constructor and destructor }
{****************************}
function New_bitmap(size: pixel_type): bitmap_ptr_type;
procedure Free_bitmap(var bitmap_ptr: bitmap_ptr_type);

{************************************************}
{ routines to convert between bitmaps and images }
{************************************************}
function Image_to_bitmap(image_ptr: image_ptr_type): bitmap_ptr_type;
function Bitmap_to_image(bitmap_ptr: bitmap_ptr_type): image_ptr_type;


implementation
uses
  new_memory, colors, screen_boxes;


const
  memory_alert = false;


var
  bitmap_free_list: bitmap_ptr_type;


{*****************************************}
{ routines for dealing with color buffers }
{*****************************************}


function New_bitmap_color_buffer(size: pixel_type):
  pixel_color_component_ptr_type;
var
  buffer_ptr: pixel_color_component_ptr_type;
  buffer_size: longint;
begin
  buffer_size := longint(size.h + 1) * longint(size.v + 1);
  buffer_size := buffer_size * sizeof(pixel_color_component_type) * 3;

  if memory_alert then
    writeln('allocating color buffer');
  buffer_ptr := pixel_color_component_ptr_type(New_ptr(buffer_size));

  New_bitmap_color_buffer := buffer_ptr;
end; {function New_bitmap_color_buffer}


function Index_bitmap(bitmap_ptr: bitmap_ptr_type;
  pixel: pixel_type): pixel_color_component_ptr_type;
var
  offset: longint;
begin
  with bitmap_ptr^ do
    begin
      offset := (longint(pixel.h) + (longint(pixel.v) *
        longint(bitmap_ptr^.size.h))) * sizeof(pixel_color_component_type) * 3;
      Index_bitmap :=
        pixel_color_component_ptr_type(longint(pixel_color_component_ptr) +
        offset);
    end;
end; {function Index_bitmap}


{****************************}
{ constructor and destructor }
{****************************}


procedure Init_bitmap(bitmap_ptr: bitmap_ptr_type);
var
  pixel_color_component_ptr: pixel_color_component_ptr_type;
  counter: longint;
begin
  {*********************************}
  { initialize bitmap buffer memory }
  {*********************************}
  pixel_color_component_ptr := bitmap_ptr^.pixel_color_component_ptr;
  for counter := 1 to bitmap_ptr^.length do
    begin
      pixel_color_component_ptr^ := 0;
      pixel_color_component_ptr :=
        pixel_color_component_ptr_type(longint(pixel_color_component_ptr) +
        sizeof(pixel_color_component_type));
    end;
end; {function Init_bitmap}


function New_bitmap(size: pixel_type): bitmap_ptr_type;
var
  bitmap_ptr: bitmap_ptr_type;
begin
  {***************************}
  { get bitmap from free list }
  {***************************}
  if bitmap_free_list <> nil then
    begin
      bitmap_ptr := bitmap_free_list;
      bitmap_free_list := bitmap_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new bitmap');
      new(bitmap_ptr);
    end;

  {*******************}
  { initialize bitmap }
  {*******************}
  bitmap_ptr^.size := size;
  bitmap_ptr^.length := longint(size.h) * longint(size.v) * 3;
  with bitmap_ptr^ do
    begin
      pixel_color_component_ptr := New_bitmap_color_buffer(size);
      next := nil;
    end;
  Init_bitmap(bitmap_ptr);

  New_bitmap := bitmap_ptr;
end; {function New_bitmap}


procedure Free_bitmap(var bitmap_ptr: bitmap_ptr_type);
begin
  {*************************}
  { dispose of color buffer }
  {*************************}
  dispose(bitmap_ptr^.pixel_color_component_ptr);

  {*************************}
  { add bitmap to free list }
  {*************************}
  bitmap_ptr^.next := bitmap_free_list;
  bitmap_free_list := bitmap_ptr;
  bitmap_ptr := nil;
end; {procedure Free_bitmap}


{************************************************}
{ routines to convert between bitmaps and images }
{************************************************}


function Image_to_bitmap(image_ptr: image_ptr_type): bitmap_ptr_type;
var
  bitmap_ptr: bitmap_ptr_type;
  pixel_color_ptr: pixel_color_ptr_type;
  pixel_color_component_ptr: pixel_color_component_ptr_type;
  h_counter, v_counter: integer;
begin
  bitmap_ptr := New_bitmap(image_ptr^.size);

  pixel_color_ptr := image_ptr^.pixel_color_ptr;
  pixel_color_component_ptr := bitmap_ptr^.pixel_color_component_ptr;

  for h_counter := 1 to bitmap_ptr^.size.h do
    for v_counter := 1 to bitmap_ptr^.size.v do
      begin
        pixel_color_component_ptr^ := pixel_color_ptr^.r;
        pixel_color_component_ptr :=
          pixel_color_component_ptr_type(longint(pixel_color_component_ptr) +
          sizeof(pixel_color_component_type));

        pixel_color_component_ptr^ := pixel_color_ptr^.g;
        pixel_color_component_ptr :=
          pixel_color_component_ptr_type(longint(pixel_color_component_ptr) +
          sizeof(pixel_color_component_type));

        pixel_color_component_ptr^ := pixel_color_ptr^.b;
        pixel_color_component_ptr :=
          pixel_color_component_ptr_type(longint(pixel_color_component_ptr) +
          sizeof(pixel_color_component_type));

        pixel_color_ptr := pixel_color_ptr_type(longint(pixel_color_ptr) +
          sizeof(pixel_color_type));
      end;

  Image_to_bitmap := bitmap_ptr;
end; {function Image_to_bitmap}


function Bitmap_to_image(bitmap_ptr: bitmap_ptr_type): image_ptr_type;
var
  image_ptr: image_ptr_type;
  pixel_color_ptr: pixel_color_ptr_type;
  pixel_color_component_ptr: pixel_color_component_ptr_type;
  h_counter, v_counter: integer;
begin
  image_ptr := New_image(bitmap_ptr^.size);

  pixel_color_ptr := image_ptr^.pixel_color_ptr;
  pixel_color_component_ptr := bitmap_ptr^.pixel_color_component_ptr;

  for h_counter := 1 to bitmap_ptr^.size.h do
    for v_counter := 1 to bitmap_ptr^.size.v do
      begin
        pixel_color_ptr^.r := pixel_color_component_ptr^;
        pixel_color_component_ptr :=
          pixel_color_component_ptr_type(longint(pixel_color_component_ptr) +
          sizeof(pixel_color_component_type));

        pixel_color_ptr^.g := pixel_color_component_ptr^;
        pixel_color_component_ptr :=
          pixel_color_component_ptr_type(longint(pixel_color_component_ptr) +
          sizeof(pixel_color_component_type));

        pixel_color_ptr^.b := pixel_color_component_ptr^;
        pixel_color_component_ptr :=
          pixel_color_component_ptr_type(longint(pixel_color_component_ptr) +
          sizeof(pixel_color_component_type));

        pixel_color_ptr := pixel_color_ptr_type(longint(pixel_color_ptr) +
          sizeof(pixel_color_type));
      end;

  Bitmap_to_image := image_ptr;
end; {function Bitmap_to_image}


initialization
  bitmap_free_list := nil;
end.
