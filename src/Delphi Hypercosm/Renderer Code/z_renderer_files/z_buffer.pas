unit z_buffer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              z_buffer                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the basic routines for scan        }
{       converting polygons. The interface is designed to       }
{       be semantically similar to Silicon Graphic's GL,        }
{       so if we are running on an Iris, we can easily          }
{       change to hardware supported scan conversion.           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, colors, pixels, screen_boxes;


type
  {********************************}
  { dynamically allocated z buffer }
  {********************************}
  z_ptr_type = ^z_type;
  z_type = real;

  z_buffer_ptr_type = ^z_buffer_type;
  z_buffer_type = record
    size: pixel_type;
    multiplier1, multiplier2: longint;
    z_ptr: z_ptr_type;
    screen_box: screen_box_type;
    next: z_buffer_ptr_type;
  end; {z_buffer_type}


{******************************************}
{ routines to create and destroy z buffers }
{******************************************}
function Open_z_buffer(size: pixel_type): z_buffer_ptr_type;
procedure Free_z_buffer(var z_buffer_ptr: z_buffer_ptr_type);

{******************************}
{ routines to modify z buffers }
{******************************}
procedure Resize_z_buffer(z_buffer_ptr: z_buffer_ptr_type;
  size: pixel_type);

{**********************************}
{ routines to manipulate z buffers }
{**********************************}
procedure Clear_z_buffer(z_buffer_ptr: z_buffer_ptr_type);
procedure Set_z_buffer(z_buffer_ptr: z_buffer_ptr_type;
  pixel: pixel_type;
  z: z_type);
function Get_z_buffer(z_buffer_ptr: z_buffer_ptr_type;
  pixel: pixel_type): z_type;
function Index_z_buffer(z_buffer_ptr: z_buffer_ptr_type;
  pixel: pixel_type): z_ptr_type;


implementation
uses
  errors, new_memory, constants;


const
  memory_alert = false;


var
  {*******************}
  { buffer free lists }
  {*******************}
  z_buffer_free_list: z_buffer_ptr_type;


{*****************************************}
{ routines to allocate and free z buffers }
{*****************************************}


function New_z_buffer: z_buffer_ptr_type;
var
  z_buffer_ptr: z_buffer_ptr_type;
begin
  {*****************************}
  { get z buffer from free list }
  {*****************************}
  if (z_buffer_free_list <> nil) then
    begin
      z_buffer_ptr := z_buffer_free_list;
      z_buffer_free_list := z_buffer_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new z buffer');
      new(z_buffer_ptr);
    end;

  {*********************}
  { initialize z buffer }
  {*********************}
  with z_buffer_ptr^ do
    begin
      size := null_pixel;
      multiplier1 := 0;
      multiplier2 := 0;
      z_ptr := nil;
      screen_box := null_screen_box;
      next := nil;
    end;

  New_z_buffer := z_buffer_ptr;
end; {function New_z_buffer}


procedure Free_z_buffer(var z_buffer_ptr: z_buffer_ptr_type);
begin
  if z_buffer_ptr <> nil then
    begin
      {**********************}
      { free z buffer memory }
      {**********************}
      if z_buffer_ptr^.z_ptr <> nil then
        Free_ptr(ptr_type(z_buffer_ptr^.z_ptr));

      {***************************}
      { add z buffer to free list }
      {***************************}
      z_buffer_ptr^.next := z_buffer_free_list;
      z_buffer_free_list := z_buffer_ptr;
      z_buffer_ptr := nil;
    end;
end; {procedure Free_z_buffer}


{******************************************}
{ routines to create and destroy z buffers }
{******************************************}


procedure Create_z_buffer(z_buffer_ptr: z_buffer_ptr_type;
  size: pixel_type);
var
  z_buffer_size: longint;
begin
  {*********************}
  { initialize z buffer }
  {*********************}
  z_buffer_ptr^.size := size;

  {*********************}
  { compute multipliers }
  {*********************}
  with z_buffer_ptr^ do
    begin
      multiplier1 := sizeof(z_type);
      multiplier2 := longint(size.h) * multiplier1;
    end;

  {*******************}
  { allocate z buffer }
  {*******************}
  z_buffer_size := longint(size.h + 1) * longint(size.v + 1);
  z_buffer_size := z_buffer_size * sizeof(z_type);

  if memory_alert then
    writeln('allocating new z buffer memory');
  z_buffer_ptr^.z_ptr := z_ptr_type(New_ptr(z_buffer_size));

  {********************************}
  { initialize z buffer screen box }
  {********************************}
  with z_buffer_ptr^.screen_box do
    begin
      min.h := 0;
      min.v := 0;
      max := size;
    end;
end; {procedure Create_z_buffer}


function Open_z_buffer(size: pixel_type): z_buffer_ptr_type;
var
  z_buffer_ptr: z_buffer_ptr_type;
begin
  {*******************}
  { allocate z buffer }
  {*******************}
  z_buffer_ptr := New_z_buffer;

  {******************************}
  { allocate new z buffer memory }
  {******************************}
  Create_z_buffer(z_buffer_ptr, size);

  Open_z_buffer := z_buffer_ptr;
end; {function Open_z_buffer}


{******************************}
{ routines to modify z buffers }
{******************************}


procedure Resize_z_buffer(z_buffer_ptr: z_buffer_ptr_type;
  size: pixel_type);
begin
  if z_buffer_ptr <> nil then
    begin
      {**************************}
      { free old z buffer memory }
      {**************************}
      if z_buffer_ptr^.z_ptr <> nil then
        Free_ptr(ptr_type(z_buffer_ptr^.z_ptr));

      {******************************}
      { allocate new z buffer memory }
      {******************************}
      Create_z_buffer(z_buffer_ptr, size);
    end;
end; {procedure Resize_z_buffer}


{**********************************}
{ routines to manipulate z buffers }
{**********************************}


procedure Clear_z_buffer(z_buffer_ptr: z_buffer_ptr_type);
var
  h_counter, v_counter: integer;
  multiplier1, multiplier2: longint;
  z_ptr1, z_ptr2: z_ptr_type;
begin
  {***********************************************}
  { Clear_z_buffer uses the screen box defined by }
  { all z_polygons drawn after the last z buffer  }
  { clear to clear only that portion of the z     }
  { buffer which was modified in the last frame.  }
  {***********************************************}

  {************************************}
  { clip z buffer screen box to window }
  {************************************}
  with z_buffer_ptr^ do
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

  {************************************************}
  { if z buffer screen box set then clear z buffer }
  {************************************************}
  with z_buffer_ptr^.screen_box do
    if (min.h < max.h) then
      if (min.v < max.v) then
        begin
          {****************}
          { clear z buffer }
          {****************}
          z_ptr1 := Index_z_buffer(z_buffer_ptr, min);
          multiplier1 := z_buffer_ptr^.multiplier1;
          multiplier2 := z_buffer_ptr^.multiplier2;
          for v_counter := min.v to max.v do
            begin
              z_ptr2 := z_ptr1;
              for h_counter := min.h to max.h do
                begin
                  z_ptr2^ := infinity;
                  z_ptr2 := z_ptr_type(longint(z_ptr2) + multiplier1);
                end;
              z_ptr1 := z_ptr_type(longint(z_ptr1) + multiplier2);
            end;

          {***************************}
          { reset z buffer screen box }
          {***************************}
          min.h := maxint;
          min.v := maxint;
          max.h := -1;
          max.v := -1;
        end;
end; {procedure Clear_z_buffer}


procedure Set_z_buffer(z_buffer_ptr: z_buffer_ptr_type;
  pixel: pixel_type;
  z: z_type);
begin
  Index_z_buffer(z_buffer_ptr, pixel)^ := z;
end; {procedure Set_z_buffer}


function Get_z_buffer(z_buffer_ptr: z_buffer_ptr_type;
  pixel: pixel_type): z_type;
begin
  Get_z_buffer := Index_z_buffer(z_buffer_ptr, pixel)^;
end; {function Get_z_buffer}


function Index_z_buffer(z_buffer_ptr: z_buffer_ptr_type;
  pixel: pixel_type): z_ptr_type;
var
  offset: longint;
begin
  offset := longint(pixel.h) * z_buffer_ptr^.multiplier1;
  offset := offset + longint(pixel.v) * z_buffer_ptr^.multiplier2;
  Index_z_buffer := z_ptr_type(longint(z_buffer_ptr^.z_ptr) + offset);
end; {function Index_z_buffer}


initialization
  z_buffer_free_list := nil;
end.
