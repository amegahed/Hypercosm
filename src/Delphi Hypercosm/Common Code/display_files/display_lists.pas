unit display_lists;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           display_lists               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the routines for building          }
{       and querying display lists of graphical operations.     }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  pixels, colors;


type
  stroke_kind_type = (set_foreground_color, set_background_color, pixel_stroke,
    line_stroke, rect_stroke);


  stroke_ptr_type = ^stroke_type;
  stroke_type = record
    next: stroke_ptr_type;

    case kind: stroke_kind_type of
      set_foreground_color, set_background_color: (
        color: color_type
        );
      pixel_stroke: (
        pixel: pixel_type;
        );
      line_stroke, rect_stroke: (
        pixel1, pixel2: pixel_type;
        );
  end; {stroke_type}


  display_list_ptr_type = ^display_list_type;
  display_list_type = record
    foreground_color_sets, background_color_sets: longint;
    pixel_strokes, line_strokes, rect_strokes: longint;
    first, last: stroke_ptr_type;
    next: display_list_ptr_type;
  end;


{*******************************************}
{ routines to create and free display lists }
{*******************************************}
function New_display_list: display_list_ptr_type;
procedure Free_display_list(var display_list_ptr: display_list_ptr_type);
procedure Clear_display_list(display_list_ptr: display_list_ptr_type);
procedure Write_display_list(display_list_ptr: display_list_ptr_type);

{******************************************}
{ routines to set the current display list }
{******************************************}
procedure Set_display_list(display_list_ptr: display_list_ptr_type);
function Get_display_list: display_list_ptr_type;

{*************************************}
{ routines to construct display lists }
{*************************************}
procedure Add_display_list_set_foreground_color(color: color_type);
procedure Add_display_list_set_background_color(color: color_type);
procedure Add_display_list_pixel(pixel: pixel_type);
procedure Add_display_list_line(pixel1, pixel2: pixel_type);
procedure Add_display_list_rect(pixel1, pixel2: pixel_type);


implementation
uses
  new_memory, errors;


const
  block_size = 512;
  memory_alert = false;


type
  stroke_block_ptr_type = ^stroke_block_type;
  stroke_block_type = array[0..block_size] of stroke_type;


var
  stroke_free_list: stroke_ptr_type;
  stroke_block_ptr: stroke_block_ptr_type;
  stroke_counter: integer;

  display_list_free_list: display_list_ptr_type;
  current_display_list_ptr: display_list_ptr_type;


{*******************************************}
{ routines to create and free display lists }
{*******************************************}


procedure Clear_display_list(display_list_ptr: display_list_ptr_type);
begin
  with display_list_ptr^ do
    begin
      {**********************************}
      { initialize display list counters }
      {**********************************}
      display_list_ptr^.foreground_color_sets := 0;
      display_list_ptr^.background_color_sets := 0;
      display_list_ptr^.pixel_strokes := 0;
      display_list_ptr^.line_strokes := 0;
      display_list_ptr^.rect_strokes := 0;

      if last <> nil then
        begin
          last^.next := stroke_free_list;
          stroke_free_list := first;
        end;
    end;
end; {procedure Clear_display_list}


function New_display_list: display_list_ptr_type;
var
  display_list_ptr: display_list_ptr_type;
begin
  {*********************************}
  { get display list from free list }
  {*********************************}
  if (display_list_free_list <> nil) then
    begin
      display_list_ptr := display_list_free_list;
      display_list_free_list := display_list_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new surface');
      new(display_list_ptr);
    end;

  {*************************}
  { initialize display list }
  {*************************}
  display_list_ptr^.first := nil;
  display_list_ptr^.last := nil;
  display_list_ptr^.next := nil;
  Clear_display_list(display_list_ptr);

  New_display_list := display_list_ptr;
end; {function New_display_list}


procedure Free_display_list(var display_list_ptr: display_list_ptr_type);
begin
  {*****************************************}
  { add display list's strokes to free list }
  {*****************************************}
  Clear_display_list(display_list_ptr);

  {***********************************}
  { add display list to its free list }
  {***********************************}
  display_list_ptr^.next := display_list_free_list;
  display_list_free_list := display_list_ptr;
end; {procedure Free_display_list}


{******************************************}
{ routines to set the current display list }
{******************************************}


procedure Set_display_list(display_list_ptr: display_list_ptr_type);
begin
  current_display_list_ptr := display_list_ptr;
end; {procedure Set_display_list}


function Get_display_list: display_list_ptr_type;
begin
  Get_display_list := current_display_list_ptr;
end; {function Get_display_list}


{*************************************}
{ routines to construct display lists }
{*************************************}


function New_stroke(kind: stroke_kind_type): stroke_ptr_type;
var
  stroke_ptr: stroke_ptr_type;
  index: integer;
begin
  {***************************}
  { get stroke from free list }
  {***************************}
  if (stroke_free_list <> nil) then
    begin
      stroke_ptr := stroke_free_list;
      stroke_free_list := stroke_ptr^.next;
    end
  else
    begin
      index := stroke_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new stroke block');
          new(stroke_block_ptr);
        end;
      stroke_ptr := @stroke_block_ptr^[index];
      stroke_counter := stroke_counter + 1;
    end;

  {*******************}
  { initialize stroke }
  {*******************}
  stroke_ptr^.kind := kind;
  stroke_ptr^.next := nil;

  New_stroke := stroke_ptr;
end; {function New_stroke}


procedure Add_display_list_set_foreground_color(color: color_type);
var
  stroke_ptr: stroke_ptr_type;
begin
  stroke_ptr := New_stroke(set_foreground_color);
  stroke_ptr^.color := color;

  {************************************}
  { add stroke to current display list }
  {************************************}
  with current_display_list_ptr^ do
    begin
      foreground_color_sets := foreground_color_sets + 1;

      if last <> nil then
        begin
          last^.next := stroke_ptr;
          last := stroke_ptr;
        end
      else
        begin
          first := stroke_ptr;
          last := stroke_ptr;
        end;
    end;
end; {procedure Add_display_list_set_foreground_color}


procedure Add_display_list_set_background_color(color: color_type);
var
  stroke_ptr: stroke_ptr_type;
begin
  stroke_ptr := New_stroke(set_background_color);
  stroke_ptr^.color := color;

  {************************************}
  { add stroke to current display list }
  {************************************}
  with current_display_list_ptr^ do
    begin
      background_color_sets := background_color_sets + 1;

      if last <> nil then
        begin
          last^.next := stroke_ptr;
          last := stroke_ptr;
        end
      else
        begin
          first := stroke_ptr;
          last := stroke_ptr;
        end;
    end;
end; {procedure Add_display_list_set_background_color}


procedure Add_display_list_pixel(pixel: pixel_type);
var
  stroke_ptr: stroke_ptr_type;
begin
  stroke_ptr := New_stroke(pixel_stroke);
  stroke_ptr^.pixel := pixel;

  {************************************}
  { add stroke to current display list }
  {************************************}
  with current_display_list_ptr^ do
    begin
      pixel_strokes := pixel_strokes + 1;

      if last <> nil then
        begin
          last^.next := stroke_ptr;
          last := stroke_ptr;
        end
      else
        begin
          first := stroke_ptr;
          last := stroke_ptr;
        end;
    end;
end; {procedure Add_display_list_pixel}


procedure Add_display_list_line(pixel1, pixel2: pixel_type);
var
  stroke_ptr: stroke_ptr_type;
begin
  stroke_ptr := New_stroke(line_stroke);
  stroke_ptr^.pixel1 := pixel1;
  stroke_ptr^.pixel2 := pixel2;

  {************************************}
  { add stroke to current display list }
  {************************************}
  with current_display_list_ptr^ do
    begin
      line_strokes := line_strokes + 1;

      if last <> nil then
        begin
          last^.next := stroke_ptr;
          last := stroke_ptr;
        end
      else
        begin
          first := stroke_ptr;
          last := stroke_ptr;
        end;
    end;
end; {procedure Add_display_list_line}


procedure Add_display_list_rect(pixel1, pixel2: pixel_type);
var
  stroke_ptr: stroke_ptr_type;
begin
  stroke_ptr := New_stroke(rect_stroke);
  stroke_ptr^.pixel1 := pixel1;
  stroke_ptr^.pixel2 := pixel2;

  {************************************}
  { add stroke to current display list }
  {************************************}
  with current_display_list_ptr^ do
    begin
      rect_strokes := rect_strokes + 1;

      if last <> nil then
        begin
          last^.next := stroke_ptr;
          last := stroke_ptr;
        end
      else
        begin
          first := stroke_ptr;
          last := stroke_ptr;
        end;
    end;
end; {procedure Add_display_list_rect}


procedure Write_display_list(display_list_ptr: display_list_ptr_type);
var
  stroke_ptr: stroke_ptr_type;
begin
  stroke_ptr := display_list_ptr^.first;
  while (stroke_ptr <> nil) do
    begin
      case stroke_ptr^.kind of

        set_foreground_color:
          begin
            with stroke_ptr^.color do
              writeln('set foreground color to ', r, ', ', g, ', ', b);
          end;

        set_background_color:
          begin
            with stroke_ptr^.color do
              writeln('set background color to ', r, ', ', g, ', ', b);
          end;

        pixel_stroke:
          begin
            with stroke_ptr^.pixel do
              writeln('pixel at ', h, ' ', v);
          end;

        line_stroke:
          begin
            writeln('line from ');
            with stroke_ptr^.pixel1 do
              write(h, ' ', v, ' to ');
            with stroke_ptr^.pixel2 do
              writeln(h, ' ', v);
          end;

        rect_stroke:
          begin
            writeln('rect from ');
            with stroke_ptr^.pixel1 do
              write(h, ' ', v, ' to ');
            with stroke_ptr^.pixel2 do
              writeln(h, ' ', v);
          end;
      end; {case}

      stroke_ptr := stroke_ptr^.next;
    end;
end; {procedure Write_display_list}


initialization
  stroke_free_list := nil;
  stroke_block_ptr := nil;
  stroke_counter := 0;

  display_list_free_list := nil;
  current_display_list_ptr := nil;
end.
