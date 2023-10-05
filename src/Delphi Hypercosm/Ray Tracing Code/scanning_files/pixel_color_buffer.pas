unit pixel_color_buffer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm         pixel_color_buffer            3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains code for implementing a 		}
{	pixel color buffer.			       	        }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  pixels, pixel_colors, screen_boxes;


type
  {******************************************}
  { dynamically allocated pixel color buffer }
  {******************************************}
  pixel_color_ptr_type = ^pixel_color_type;


  pixel_color_buffer_ptr_type = ^pixel_color_buffer_type;
  pixel_color_buffer_type = record
    size: pixel_type;
    multiplier1, multiplier2: longint;
    pixel_color_ptr: pixel_color_ptr_type;
    screen_box: screen_box_type;
    next: pixel_color_buffer_ptr_type;
  end; {pixel_color_buffer_type}


  {****************************************************}
  { routines to create and destroy pixel color buffers }
  {****************************************************}
function Open_pixel_color_buffer(size: pixel_type): pixel_color_buffer_ptr_type;
procedure Free_pixel_color_buffer(var pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type);

{****************************************}
{ routines to modify pixel color buffers }
{****************************************}
procedure Resize_pixel_color_buffer(pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type;
  size: pixel_type);

{********************************************}
{ routines to manipulate pixel color buffers }
{********************************************}
procedure Clear_pixel_color_buffer(pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type;
  pixel_color: pixel_color_type);
procedure Set_pixel_color_buffer(pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type;
  pixel: pixel_type;
  pixel_color: pixel_color_type);
function Get_pixel_color_buffer(pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type;
  pixel: pixel_type): pixel_color_type;
function Index_pixel_color_buffer(pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type;
  pixel: pixel_type): pixel_color_ptr_type;


implementation
uses
  errors, new_memory, constants, z_pipeline, drawable;


const
  memory_alert = false;


var
  {*******************}
  { buffer free lists }
  {*******************}
  pixel_color_buffer_free_list: pixel_color_buffer_ptr_type;


  {***************************************************}
  { routines to allocate and free pixel color buffers }
  {***************************************************}


function New_pixel_color_buffer: pixel_color_buffer_ptr_type;
var
  pixel_color_buffer_ptr: pixel_color_buffer_ptr_type;
begin
  {***************************************}
  { get pixel color buffer from free list }
  {***************************************}
  if (pixel_color_buffer_free_list <> nil) then
    begin
      pixel_color_buffer_ptr := pixel_color_buffer_free_list;
      pixel_color_buffer_free_list := pixel_color_buffer_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new pixel_color buffer');
      new(pixel_color_buffer_ptr);
    end;

  {*******************************}
  { initialize pixel color buffer }
  {*******************************}
  with pixel_color_buffer_ptr^ do
    begin
      size := null_pixel;
      multiplier1 := 0;
      multiplier2 := 0;
      pixel_color_ptr := nil;
      screen_box := null_screen_box;
      next := nil;
    end;

  New_pixel_color_buffer := pixel_color_buffer_ptr;
end; {function New_pixel_color_buffer}


procedure Free_pixel_color_buffer(var pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type);
begin
  if pixel_color_buffer_ptr <> nil then
    begin
      {********************************}
      { free pixel color buffer memory }
      {********************************}
      if pixel_color_buffer_ptr^.pixel_color_ptr <> nil then
        Free_ptr(ptr_type(pixel_color_buffer_ptr^.pixel_color_ptr));

      {*************************************}
      { add pixel color buffer to free list }
      {*************************************}
      pixel_color_buffer_ptr^.next := pixel_color_buffer_free_list;
      pixel_color_buffer_free_list := pixel_color_buffer_ptr;
      pixel_color_buffer_ptr := nil;
    end;
end; {procedure Free_pixel_color_buffer}


{****************************************************}
{ routines to create and destroy pixel color buffers }
{****************************************************}


procedure Create_pixel_color_buffer(pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type;
  size: pixel_type);
var
  pixel_color_buffer_size: longint;
begin
  {*******************************}
  { initialize pixel color buffer }
  {*******************************}
  pixel_color_buffer_ptr^.size := size;

  {*********************}
  { compute multipliers }
  {*********************}
  with pixel_color_buffer_ptr^ do
    begin
      multiplier1 := sizeof(pixel_color_type);
      multiplier2 := longint(size.h) * multiplier1;
    end;

  {*****************************}
  { allocate pixel color buffer }
  {*****************************}
  pixel_color_buffer_size := longint(size.h + 1) * longint(size.v + 1);
  pixel_color_buffer_size := pixel_color_buffer_size * sizeof(pixel_color_type);

  if memory_alert then
    writeln('allocating new pixel color buffer memory');
  pixel_color_buffer_ptr^.pixel_color_ptr :=
    pixel_color_ptr_type(New_ptr(pixel_color_buffer_size));

  {******************************************}
  { initialize pixel color buffer screen box }
  {******************************************}
  with pixel_color_buffer_ptr^.screen_box do
    begin
      min.h := 0;
      min.v := 0;
      max := size;
    end;
end; {procedure Create_pixel_color_buffer}


function Open_pixel_color_buffer(size: pixel_type): pixel_color_buffer_ptr_type;
var
  pixel_color_buffer_ptr: pixel_color_buffer_ptr_type;
begin
  {*********************************}
  { allocate new pixel color buffer }
  {*********************************}
  pixel_color_buffer_ptr := New_pixel_color_buffer;

  {****************************************}
  { allocate new pixel color buffer memory }
  {****************************************}
  Create_pixel_color_buffer(pixel_color_buffer_ptr, size);

  Open_pixel_color_buffer := pixel_color_buffer_ptr;
end; {function Open_pixel_color_buffer}


{****************************************}
{ routines to modify pixel color buffers }
{****************************************}


procedure Resize_pixel_color_buffer(pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type;
  size: pixel_type);
begin
  if pixel_color_buffer_ptr <> nil then
    begin
      {************************************}
      { free old pixel color buffer memory }
      {************************************}
      if pixel_color_buffer_ptr^.pixel_color_ptr <> nil then
        Free_ptr(ptr_type(pixel_color_buffer_ptr^.pixel_color_ptr));

      {****************************************}
      { allocate new pixel color buffer memory }
      {****************************************}
      Create_pixel_color_buffer(pixel_color_buffer_ptr, size);
    end;
end; {procedure Resize_pixel_color_buffer}


{********************************************}
{ routines to manipulate pixel color buffers }
{********************************************}


procedure Clear_pixel_color_buffer(pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type;
  pixel_color: pixel_color_type);
var
  h_counter, v_counter: integer;
  multiplier1, multiplier2: longint;
  pixel_color_ptr1, pixel_color_ptr2: pixel_color_ptr_type;
begin
  if pixel_color_buffer_ptr <> nil then
    begin
      {***************************************}
      { clip pixel color screen box to window }
      {***************************************}
      with pixel_color_buffer_ptr^ do
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

      {*************************************************************}
      { if pixel color screen box set then clear pixel color buffer }
      {*************************************************************}
      with pixel_color_buffer_ptr^.screen_box do
        if (min.h < max.h) then
          if (min.v < max.v) then
            begin
              {**************************}
              { clear pixel color buffer }
              {**************************}
              pixel_color_ptr1 :=
                Index_pixel_color_buffer(pixel_color_buffer_ptr, min);
              multiplier1 := pixel_color_buffer_ptr^.multiplier1;
              multiplier2 := pixel_color_buffer_ptr^.multiplier2;
              for v_counter := min.v to max.v do
                begin
                  pixel_color_ptr2 := pixel_color_ptr1;
                  for h_counter := min.h to max.h do
                    begin
                      pixel_color_ptr2^ := pixel_color;
                      pixel_color_ptr2 :=
                        pixel_color_ptr_type(longint(pixel_color_ptr2) +
                        multiplier1);
                    end;
                  pixel_color_ptr1 :=
                    pixel_color_ptr_type(longint(pixel_color_ptr1) +
                    multiplier2);
                end;

              {******************************}
              { reset pixel color screen box }
              {******************************}
              min.h := maxint;
              min.v := maxint;
              max.h := -1;
              max.v := -1;
            end;
    end;
end; {procedure Clear_pixel_color_buffer}


procedure Set_pixel_color_buffer(pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type;
  pixel: pixel_type;
  pixel_color: pixel_color_type);
begin
  Index_pixel_color_buffer(pixel_color_buffer_ptr, pixel)^ := pixel_color;
end; {procedure Set_pixel_color_buffer}


function Get_pixel_color_buffer(pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type;
  pixel: pixel_type): pixel_color_type;
begin
  Get_pixel_color_buffer := Index_pixel_color_buffer(pixel_color_buffer_ptr, pixel)^;
end; {function Get_pixel_color_buffer}


function Index_pixel_color_buffer(pixel_color_buffer_ptr:
  pixel_color_buffer_ptr_type;
  pixel: pixel_type): pixel_color_ptr_type;
var
  offset: longint;
begin
  offset := longint(pixel.h) * pixel_color_buffer_ptr^.multiplier1;
  offset := offset + longint(pixel.v) * pixel_color_buffer_ptr^.multiplier2;
  Index_pixel_color_buffer :=
    pixel_color_ptr_type(longint(pixel_color_buffer_ptr^.pixel_color_ptr)
    + offset);
end; {function Index_pixel_color_buffer}


initialization
  pixel_color_buffer_free_list := nil;
end.

