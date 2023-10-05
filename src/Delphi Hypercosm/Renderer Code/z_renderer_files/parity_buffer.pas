unit parity_buffer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            parity_buffer              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains code for implementing a 		}
{	parity or stencil buffer.			       	}
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  pixels, screen_boxes;


type
  {*************************************}
  { dynamically allocated parity buffer }
  {*************************************}
  parity_ptr_type = ^parity_type;
  parity_type = boolean;

  parity_buffer_ptr_type = ^parity_buffer_type;
  parity_buffer_type = record
    size: pixel_type;
    multiplier1, multiplier2: longint;
    parity_ptr: parity_ptr_type;
    screen_box: screen_box_type;
    next: parity_buffer_ptr_type;
  end; {parity_buffer_type}


{***********************************************}
{ routines to create and destroy parity buffers }
{***********************************************}
function Open_parity_buffer(size: pixel_type): parity_buffer_ptr_type;
procedure Free_parity_buffer(var parity_buffer_ptr: parity_buffer_ptr_type);

{***********************************}
{ routines to modify parity buffers }
{***********************************}
procedure Resize_parity_buffer(parity_buffer_ptr: parity_buffer_ptr_type;
  size: pixel_type);

{***************************************}
{ routines to manipulate parity buffers }
{***************************************}
procedure Clear_parity_buffer(parity_buffer_ptr: parity_buffer_ptr_type);
procedure Set_parity_buffer(parity_buffer_ptr: parity_buffer_ptr_type;
  pixel: pixel_type;
  parity: parity_type);
function Get_parity_buffer(parity_buffer_ptr: parity_buffer_ptr_type;
  pixel: pixel_type): parity_type;
function Index_parity_buffer(parity_buffer_ptr: parity_buffer_ptr_type;
  pixel: pixel_type): parity_ptr_type;


implementation
uses
  errors, new_memory;


const
  memory_alert = false;


var
  {*******************}
  { buffer free lists }
  {*******************}
  parity_buffer_free_list: parity_buffer_ptr_type;


{**********************************************}
{ routines to allocate and free parity buffers }
{**********************************************}


function New_parity_buffer: parity_buffer_ptr_type;
var
  parity_buffer_ptr: parity_buffer_ptr_type;
begin
  {**********************************}
  { get parity buffer from free list }
  {**********************************}
  if (parity_buffer_free_list <> nil) then
    begin
      parity_buffer_ptr := parity_buffer_free_list;
      parity_buffer_free_list := parity_buffer_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new parity buffer');
      new(parity_buffer_ptr);
    end;

  {**************************}
  { initialize parity buffer }
  {**************************}
  with parity_buffer_ptr^ do
    begin
      size := null_pixel;
      multiplier1 := 0;
      multiplier2 := 0;
      parity_ptr := nil;
      screen_box := null_screen_box;
      next := nil;
    end;

  New_parity_buffer := parity_buffer_ptr;
end; {function New_parity_buffer}


procedure Free_parity_buffer(var parity_buffer_ptr: parity_buffer_ptr_type);
begin
  if parity_buffer_ptr <> nil then
    begin
      {***************************}
      { free parity buffer memory }
      {***************************}
      if parity_buffer_ptr^.parity_ptr <> nil then
        Free_ptr(ptr_type(parity_buffer_ptr^.parity_ptr));

      {********************************}
      { add parity buffer to free list }
      {********************************}
      parity_buffer_ptr^.next := parity_buffer_free_list;
      parity_buffer_free_list := parity_buffer_ptr;
      parity_buffer_ptr := nil;
    end;
end; {procedure Free_parity_buffer}


{***********************************************}
{ routines to create and destroy parity buffers }
{***********************************************}


procedure Create_parity_buffer(parity_buffer_ptr: parity_buffer_ptr_type;
  size: pixel_type);
var
  parity_buffer_size: longint;
begin
  {**************************}
  { initialize parity buffer }
  {**************************}
  parity_buffer_ptr^.size := size;

  {*********************}
  { compute multipliers }
  {*********************}
  with parity_buffer_ptr^ do
    begin
      multiplier1 := sizeof(parity_type);
      multiplier2 := longint(size.h) * multiplier1;
    end;

  {************************}
  { allocate parity buffer }
  {************************}
  parity_buffer_size := longint(size.h + 1) * longint(size.v + 1);
  parity_buffer_size := parity_buffer_size * sizeof(parity_type);

  if memory_alert then
    writeln('allocating new parity buffer memory');
  parity_buffer_ptr^.parity_ptr := parity_ptr_type(New_ptr(parity_buffer_size));

  {*************************************}
  { initialize parity buffer screen box }
  {*************************************}
  with parity_buffer_ptr^.screen_box do
    begin
      min.h := 0;
      min.v := 0;
      max := size;
    end;
end; {procedure Create_parity_buffer}


function Open_parity_buffer(size: pixel_type): parity_buffer_ptr_type;
var
  parity_buffer_ptr: parity_buffer_ptr_type;
begin
  {****************************}
  { allocate new parity buffer }
  {****************************}
  parity_buffer_ptr := New_parity_buffer;

  {***********************************}
  { allocate new parity buffer memory }
  {***********************************}
  Create_parity_buffer(parity_buffer_ptr, size);

  Open_parity_buffer := parity_buffer_ptr;
end; {function Open_parity_buffer}


{***********************************}
{ routines to modify parity buffers }
{***********************************}


procedure Resize_parity_buffer(parity_buffer_ptr: parity_buffer_ptr_type;
  size: pixel_type);
begin
  if parity_buffer_ptr <> nil then
    begin
      {*******************************}
      { free old parity buffer memory }
      {*******************************}
      if parity_buffer_ptr^.parity_ptr <> nil then
        Free_ptr(ptr_type(parity_buffer_ptr^.parity_ptr));

      {***********************************}
      { allocate new parity buffer memory }
      {***********************************}
      Create_parity_buffer(parity_buffer_ptr, size);
    end;
end; {procedure Resize_parity_buffer}


{***************************************}
{ routines to manipulate parity buffers }
{***************************************}


procedure Clear_parity_buffer(parity_buffer_ptr: parity_buffer_ptr_type);
var
  h_counter, v_counter: integer;
  multiplier1, multiplier2: longint;
  parity_ptr1, parity_ptr2: parity_ptr_type;
begin
  if parity_buffer_ptr <> nil then
    begin
      {**********************************}
      { clip parity screen box to window }
      {**********************************}
      with parity_buffer_ptr^ do
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

      {***************************************************}
      { if parity screen box set then clear parity buffer }
      {***************************************************}
      with parity_buffer_ptr^.screen_box do
        if (min.h < max.h) then
          if (min.v < max.v) then
            begin
              {*********************}
              { clear parity buffer }
              {*********************}
              parity_ptr1 := Index_parity_buffer(parity_buffer_ptr, min);
              multiplier1 := parity_buffer_ptr^.multiplier1;
              multiplier2 := parity_buffer_ptr^.multiplier2;
              for v_counter := min.v to max.v do
                begin
                  parity_ptr2 := parity_ptr1;
                  for h_counter := min.h to max.h do
                    begin
                      parity_ptr2^ := false;
                      parity_ptr2 := parity_ptr_type(longint(parity_ptr2) +
                        multiplier1);
                    end;
                  parity_ptr1 := parity_ptr_type(longint(parity_ptr1) +
                    multiplier2);
                end;

              {*************************}
              { reset parity screen box }
              {*************************}
              min.h := maxint;
              min.v := maxint;
              max.h := -1;
              max.v := -1;
            end;
    end;
end; {procedure Clear_parity_buffer}


procedure Set_parity_buffer(parity_buffer_ptr: parity_buffer_ptr_type;
  pixel: pixel_type;
  parity: parity_type);
begin
  Index_parity_buffer(parity_buffer_ptr, pixel)^ := parity;
end; {procedure Set_parity_buffer}


function Get_parity_buffer(parity_buffer_ptr: parity_buffer_ptr_type;
  pixel: pixel_type): parity_type;
begin
  Get_parity_buffer := Index_parity_buffer(parity_buffer_ptr, pixel)^;
end; {procedure Get_parity_buffer}


function Index_parity_buffer(parity_buffer_ptr: parity_buffer_ptr_type;
  pixel: pixel_type): parity_ptr_type;
var
  offset: longint;
begin
  offset := longint(pixel.h) * parity_buffer_ptr^.multiplier1;
  offset := offset + longint(pixel.v) * parity_buffer_ptr^.multiplier2;
  Index_parity_buffer := parity_ptr_type(longint(parity_buffer_ptr^.parity_ptr)
    + offset);
end; {function Index_parity_buffer}


initialization
  parity_buffer_free_list := nil;
end.
