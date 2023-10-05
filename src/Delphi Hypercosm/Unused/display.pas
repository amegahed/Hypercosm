unit display;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              display                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to the graphics      }
{       operations. This module is one level above the actual   }
{       graphics hardware, so most porting changes will be      }
{       confined to the video module and this module should     }
{       remain unchanged.                                       }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  colors, pixels, pixel_colors, images;


type
  {***************}
  { display modes }
  {***************}
  buffer_mode_type = (single_buffer, double_buffer);
  show_mode_type = (show_on, show_off);
  save_mode_type = (save_on, save_off);


var
  window_size, window_center: pixel_type;
  window_min, window_max: pixel_type;


  {********************}
  { initialize display }
  {********************}
procedure Init_display;

{****************************************}
{ routines to create and destroy windows }
{****************************************}
function Open_window(name: string;
  size, center: pixel_type): integer;
procedure Close_window(window_id: integer);

{********************************}
{ routines to manipulate windows }
{********************************}
procedure Set_window(window_id: integer);
function Get_window: integer;

{***************************************}
{ routines to set various display modes }
{***************************************}
procedure Set_buffer_mode(mode: buffer_mode_type);
procedure Set_show_mode(mode: show_mode_type);
procedure Set_raster_save_mode(mode: save_mode_type);
procedure Set_vector_save_mode(mode: save_mode_type);

{***************************************}
{ routines to get various display modes }
{***************************************}
function Get_buffer_mode: buffer_mode_type;
function Get_show_mode: show_mode_type;
function Get_raster_save_mode: save_mode_type;
function Get_vector_save_mode: save_mode_type;

{************************}
{ color related routines }
{************************}
procedure Set_color(color: color_type);
function Get_color: color_type;
function Get_pixel_color(pixel: pixel_type): pixel_color_type;
function Get_display_image: image_ptr_type;

{******************}
{ drawing routines }
{******************}
procedure Draw_frame;
procedure Move_to(pixel: pixel_type);
procedure Line_to(pixel: pixel_type);
procedure Draw_pixel(pixel: pixel_type);
procedure Draw_line(pixel1, pixel2: pixel_type);
procedure Draw_h_line(h1, h2, v: integer);
procedure Draw_span(h1, h2, v: integer;
  color: color_type);
procedure Draw_rect(pixel1, pixel2: pixel_type);

{*************************}
{ window refresh routines }
{*************************}
procedure Clear_window;
procedure Update_window;
procedure Show_window;

{****************************}
{ image composition routines }
{****************************}
procedure Composite_image(filter: color_type);
procedure Clear_composite_buffer;
procedure Show_composite_buffer;


implementation
uses
  errors, new_memory, screen_boxes, math_utils, video, display_lists;


const
  max_windows = 64;
  memory_alert = false;


  {******************************************}
  { color buffer is divided up into sectors  }
  { which mark background and non-background }
  { regions to make clearing and compositing }
  { more efficient.                          }
  {******************************************}
  sector_size = 8;


type
  buffer_color_type = record
    pixel_color: pixel_color_type;
    background: boolean;
  end; {buffer_color_type}


  {*************************************************}
  { dynamic arrays of true colors and sectors which }
  { mark background and non background regions      }
  {*************************************************}
  buffer_type = buffer_color_type;
  buffer_ptr_type = ^buffer_type;

  sector_type = boolean;
  sector_ptr_type = ^sector_type;


  color_buffer_type = record
    {*********************************}
    { color buffer and its screen box }
    {*********************************}
    screen_box: screen_box_type;
    buffer_ptr: buffer_ptr_type;
    sector_ptr: sector_ptr_type;

    {******************}
    { background color }
    {******************}
    background: color_type;
    background_color: buffer_color_type;
  end; {color_buffer_type}


  window_ptr_type = ^window_type;
  window_type = record
    size, center, max, min: pixel_type;
    window_id: integer;
    video_window_ptr: video_window_ptr_type;

    {***********}
    { mode vars }
    {***********}
    buffer_mode: buffer_mode_type;
    show_mode: show_mode_type;
    raster_save_mode: save_mode_type;
    vector_save_mode: save_mode_type;

    {*************}
    { window vars }
    {*************}
    window_changed: boolean;
    previous_pixel: pixel_type;

    {************}
    { color vars }
    {************}
    drawing_color: color_type;
    buffer_color: buffer_color_type;
    background: color_type;

    {*********}
    { buffers }
    {*********}
    color_buffer: color_buffer_type;
    composite_buffer: color_buffer_type;
    sectors: pixel_type;

    {**************}
    { display list }
    {**************}
    display_list_ptr: display_list_ptr_type;

    next: window_ptr_type;
  end; {window_type}


var
  {******************}
  { window variables }
  {******************}
  window_ptr_array: array[1..max_windows] of window_ptr_type;
  current_window_ptr: window_ptr_type;
  window_free_list: window_ptr_type;
  window_number: integer;

  {***********}
  { mode vars }
  {***********}
  buffer_mode: buffer_mode_type;
  show_mode: show_mode_type;
  raster_save_mode: save_mode_type;
  vector_save_mode: save_mode_type;


  {********************}
  { initialize display }
  {********************}


procedure Init_display;
var
  counter: integer;
begin
  {*******************************}
  { system calls handled by video }
  {*******************************}
  Init_video;

  {**************}
  { init globals }
  {**************}
  window_size := To_pixel(0, 0);
  window_center := To_pixel(0, 0);
  window_min := To_pixel(0, 0);
  window_max := To_pixel(0, 0);

  {************}
  { state vars }
  {************}
  window_number := 0;
  current_window_ptr := nil;

  {************}
  { init modes }
  {************}
  buffer_mode := single_buffer;
  show_mode := show_on;
  raster_save_mode := save_off;
  vector_save_mode := save_off;

  {***********************}
  { init window ptr array }
  {***********************}
  for counter := 1 to max_windows do
    window_ptr_array[counter] := nil;
end; {procedure Init_display}


{***************************************}
{ routines to allocate and free windows }
{***************************************}


function New_window: window_ptr_type;
var
  window_ptr: window_ptr_type;
begin
  {***************************}
  { get window from free list }
  {***************************}
  if (window_free_list <> nil) then
    begin
      window_ptr := window_free_list;
      window_free_list := window_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new window');
      new(window_ptr);

      window_number := window_number + 1;
      if (window_number > max_windows) then
        Quit('Opened too many windows.');

      window_ptr^.window_id := window_number;
      window_ptr_array[window_number] := window_ptr;
    end;

  {*******************}
  { initialize window }
  {*******************}
  with window_ptr^ do
    begin
      video_window_ptr := nil;
      display_list_ptr := nil;
      next := nil;
    end;

  New_window := window_ptr;
end; {function New_window}


procedure Free_window(var window_ptr: window_ptr_type);
begin
  {*************************}
  { add window to free list }
  {*************************}
  window_ptr^.next := window_free_list;
  window_free_list := window_ptr;
  window_ptr := nil;
end; {procedure Free_window}


{****************************************}
{ routines to create and destroy windows }
{****************************************}


function Open_window(name: string;
  size, center: pixel_type): integer;
var
  window_ptr: window_ptr_type;
begin
  {*********************}
  { allocate new window }
  {*********************}
  window_ptr := New_window;

  {***********************}
  { initialize new window }
  {***********************}
  window_ptr^.size := size;
  window_ptr^.center.h := (size.h - 1) div 2;
  window_ptr^.center.v := (size.v - 1) div 2;
  window_ptr^.min.h := center.h - size.h div 2;
  window_ptr^.min.v := center.v - size.v div 2;
  window_ptr^.max.h := center.h + size.h div 2;
  window_ptr^.max.v := center.v + size.v div 2;

  {************************}
  { initialize buffer ptrs }
  {************************}
  window_ptr^.color_buffer.buffer_ptr := nil;
  window_ptr^.composite_buffer.buffer_ptr := nil;
  window_ptr^.display_list_ptr := New_display_list;

  {********************}
  { initialize globals }
  {********************}
  with window_ptr^ do
    begin
      sectors.h := (size.h + (sector_size - 1)) div sector_size;
      sectors.v := (size.v + (sector_size - 1)) div sector_size;
      window_changed := false;
      drawing_color := white_color;
    end;

  {****************}
  { init mode vars }
  {****************}
  window_ptr^.buffer_mode := buffer_mode;
  window_ptr^.show_mode := show_mode;
  window_ptr^.raster_save_mode := raster_save_mode;
  window_ptr^.vector_save_mode := vector_save_mode;

  {*************************}
  { open window system call }
  {*************************}
  if (show_mode = show_on) then
    window_ptr^.video_window_ptr := Open_video_window(name, size, center);

  {********************************}
  { make new window current window }
  {********************************}
  Set_window(window_ptr^.window_id);

  Open_window := window_ptr^.window_id;
end; {procedure Open_window}


procedure Free_window_buffers(window_ptr: window_ptr_type);
begin
  with window_ptr^ do
    begin
      if (color_buffer.buffer_ptr <> nil) then
        Free_ptr(ptr_type(color_buffer.buffer_ptr));
      if (color_buffer.sector_ptr <> nil) then
        Free_ptr(ptr_type(color_buffer.sector_ptr));
      if (composite_buffer.buffer_ptr <> nil) then
        Free_ptr(ptr_type(composite_buffer.buffer_ptr));
      if (composite_buffer.sector_ptr <> nil) then
        Free_ptr(ptr_type(composite_buffer.sector_ptr));
    end;
end; {procedure Free_window_buffers}


procedure Close_window(window_id: integer);
var
  window_ptr: window_ptr_type;
begin
  if (window_id > 0) and (window_id <= window_number) then
    begin
      {********************}
      { free window memory }
      {********************}
      window_ptr := window_ptr_array[window_id];
      Free_window_buffers(window_ptr);
      with window_ptr^ do
        begin
          Free_display_list(display_list_ptr);
          Close_video_window(video_window_ptr);
        end;
      Free_window(window_ptr_array[window_id])
    end
  else
    Error('invalid window id');
end; {procedure Close_window}


procedure Resize_window(window_ptr: window_ptr_type;
  size: pixel_type);
begin
  window_ptr^.size := size;
  Free_window_buffers(window_ptr);
  if window_ptr = current_window_ptr then
    window_size := size;
end; {procedure Resize_window}


{******************************}
{ routines to allocate buffers }
{******************************}


function New_color_buffer(size: pixel_type): buffer_ptr_type;
var
  buffer_ptr: buffer_ptr_type;
  buffer_size: longint;
begin
  buffer_size := longint(size.h + 1) * longint(size.v + 1);
  buffer_size := buffer_size * sizeof(buffer_type);

  if memory_alert then
    writeln('allocating color buffer');
  buffer_ptr := buffer_ptr_type(New_ptr(buffer_size));

  New_color_buffer := buffer_ptr;
end; {function New_color_buffer}


function New_sector_buffer(size: pixel_type): sector_ptr_type;
var
  sector_ptr: sector_ptr_type;
  buffer_size: longint;
begin
  buffer_size := longint(size.h + 1) * longint(size.v + 1);
  buffer_size := buffer_size * sizeof(sector_type);

  if memory_alert then
    writeln('allocating new sector buffer');
  sector_ptr := sector_ptr_type(New_ptr(buffer_size));

  New_sector_buffer := sector_ptr;
end; {function New_sector_buffer}


{********************************}
{ routines to manipulate windows }
{********************************}


procedure Set_window(window_id: integer);
begin
  if (window_id > 0) and (window_id <= window_number) then
    begin
      current_window_ptr := window_ptr_array[window_id];
      if not Equal_pixels(current_window_ptr^.size,
        current_window_ptr^.video_window_ptr^.size) then
        Resize_window(current_window_ptr,
          current_window_ptr^.video_window_ptr^.size);

      {***************************************************************}
      { allow raster save mode to change after window has been opened }
      {***************************************************************}
      if raster_save_mode = save_on then
        with current_window_ptr^ do
          begin
            raster_save_mode := save_on;

            {***********************}
            { allocate color buffer }
            {***********************}
            with color_buffer do
              if buffer_ptr = nil then
                begin
                  buffer_ptr := New_color_buffer(size);
                  sector_ptr := New_sector_buffer(sectors);
                end;
          end; {with}

      {******************}
      { update mode vars }
      {******************}
      buffer_mode := current_window_ptr^.buffer_mode;
      show_mode := current_window_ptr^.show_mode;
      raster_save_mode := current_window_ptr^.raster_save_mode;
      vector_save_mode := current_window_ptr^.vector_save_mode;

      {****************}
      { update globals }
      {****************}
      window_size := current_window_ptr^.size;
      window_center := current_window_ptr^.center;
      window_min := current_window_ptr^.min;
      window_max := current_window_ptr^.max;

      if (current_window_ptr^.video_window_ptr <> nil) then
        Set_current_video_window(current_window_ptr^.video_window_ptr);
      Set_display_list(current_window_ptr^.display_list_ptr);
    end
  else
    Error('invalid window id');
end; {procedure Set_window}


function Get_window: integer;
begin
  Get_window := current_window_ptr^.window_id;
end; {function Get_window}


{*********************************}
{ routines to write display modes }
{*********************************}


procedure Write_buffer_mode(mode: buffer_mode_type);
begin
  case mode of
    single_buffer:
      write('single_buffer');
    double_buffer:
      write('double_buffer');
  end;
end; {procedure Write_buffer_mode}


procedure Write_show_mode(mode: show_mode_type);
begin
  case mode of
    show_on:
      write('show_on');
    show_off:
      write('show_off');
  end;
end; {procedure Write_show_mode}


procedure Write_save_mode(mode: save_mode_type);
begin
  case mode of
    save_on:
      write('save_on');
    save_off:
      write('save_off');
  end;
end; {procedure Write_save_mode}


{***************************************}
{ routines to set various display modes }
{***************************************}


procedure Set_buffer_mode(mode: buffer_mode_type);
begin
  buffer_mode := mode;
  case mode of
    single_buffer:
      Set_video_backing_store(false);
    double_buffer:
      Set_video_backing_store(true);
  end;
end; {procedure Set_buffer_mode}


procedure Set_show_mode(mode: show_mode_type);
begin
  show_mode := mode;
end; {procedure Set_show_mode}


procedure Set_raster_save_mode(mode: save_mode_type);
begin
  raster_save_mode := mode;
end; {procedure Set_raster_save_mode}


procedure Set_vector_save_mode(mode: save_mode_type);
begin
  vector_save_mode := mode;
end; {procedure Set_vector_save_mode}


{***************************************}
{ routines to get various display modes }
{***************************************}


function Get_buffer_mode: buffer_mode_type;
begin
  Get_buffer_mode := buffer_mode;
end; {function Get_buffer_mode}


function Get_show_mode: show_mode_type;
begin
  Get_show_mode := show_mode;
end; {function Get_show_mode}


function Get_raster_save_mode: save_mode_type;
begin
  Get_raster_save_mode := raster_save_mode;
end; {function Get_raster_save_mode}


function Get_vector_save_mode: save_mode_type;
begin
  Get_vector_save_mode := vector_save_mode;
end; {function Get_vector_save_mode}


{*****************************}
{ routines to show screen_box }
{*****************************}


procedure Draw_screen_box(screen_box: screen_box_type);
var
  pixel: pixel_type;
begin
  with screen_box do
    begin
      pixel := min;
      Move_to(pixel);
      pixel.h := max.h;
      Line_to(pixel);
      pixel.v := max.v;
      Line_to(pixel);
      pixel.h := min.h;
      Line_to(pixel);
      pixel.v := min.v;
      Line_to(pixel);
    end;
end; {procedure Draw_screen_box}


{*********************************************************}
{ routines to store and retreive colors from color buffer }
{*********************************************************}


function Buffer_color_to_color(buffer_color: buffer_color_type): color_type;
var
  color: color_type;
begin
  if not buffer_color.background then
    color := Pixel_color_to_color(buffer_color.pixel_color)
  else
    color := current_window_ptr^.background;

  Buffer_color_to_color := color;
end; {function Buffer_color_to_color}


function Color_to_buffer_color(color: color_type): buffer_color_type;
var
  buffer_color: buffer_color_type;
begin
  buffer_color.pixel_color := Color_to_pixel_color(color);
  buffer_color.background := false;

  Color_to_buffer_color := buffer_color;
end; {function Color_to_buffer_color}


{*********************************************}
{ routines to access color and sector buffers }
{*********************************************}


function Index_buffer(buffer_ptr: buffer_ptr_type;
  h, v: integer): buffer_ptr_type;
var
  offset: longint;
begin
  with current_window_ptr^ do
    begin
      offset := (longint(h) + (longint(v) * longint(window_size.h + 1))) *
        sizeof(buffer_type);
      Index_buffer := buffer_ptr_type(longint(buffer_ptr) + offset);
    end;
end; {function Index_buffer}


function Index_sector(sector_ptr: sector_ptr_type;
  h, v: integer): sector_ptr_type;
var
  offset: longint;
begin
  with current_window_ptr^ do
    begin
      offset := (longint(h) + (longint(v) * longint(sectors.h + 1))) *
        sizeof(sector_type);
      Index_sector := sector_ptr_type(longint(sector_ptr) + offset);
    end;
end; {function Index_sector}


{*******************************}
{ miscillaneous sector routines }
{*******************************}


function Sector_screen_box(screen_box: screen_box_type): screen_box_type;
var
  sector_box: screen_box_type;
begin
  sector_box.min.h := screen_box.min.h div sector_size;
  sector_box.min.v := screen_box.min.v div sector_size;
  sector_box.max.h := screen_box.max.h div sector_size;
  sector_box.max.v := screen_box.max.v div sector_size;
  Sector_screen_box := sector_box;
end; {function Sector_screen_box}


procedure Draw_sector(h, v: integer);
var
  sector_min, sector_max: pixel_type;
begin
  {***********************************}
  { find window coordinates of sector }
  {***********************************}
  sector_min.h := h * sector_size;
  sector_min.v := v * sector_size;
  sector_max.h := sector_min.h + (sector_size - 1);
  sector_max.v := sector_min.v + (sector_size - 1);

  {************************}
  { draw outline of sector }
  {************************}
  Move_to_video(To_pixel(sector_min.h, sector_min.v));
  Line_to_video(To_pixel(sector_max.h, sector_min.v));
  Line_to_video(To_pixel(sector_max.h, sector_max.v));
  Line_to_video(To_pixel(sector_min.h, sector_max.v));
  Line_to_video(To_pixel(sector_min.h, sector_min.v));
end; {procedure Draw_sector}


procedure Draw_sectors(var buffer: color_buffer_type);
var
  h_counter, v_counter: integer;
begin
  {**************}
  { draw sectors }
  {**************}
  with buffer do
    for v_counter := 0 to (window_size.v div sector_size) + 1 do
      for h_counter := 0 to (window_size.h div sector_size) + 1 do
        if not Index_sector(sector_ptr, h_counter, v_counter)^ then
          Draw_sector(h_counter, v_counter);
  Update_window;
end; {procedure Draw_sectors}


{****************}
{ clear routines }
{****************}


procedure Clear_sector(var buffer: color_buffer_type;
  h, v: integer);
var
  h_counter, v_counter: integer;
  sector_min, sector_max: pixel_type;
begin
  if not Index_sector(buffer.sector_ptr, h, v)^ then
    begin
      {Set_video_color(1.0, 1.0, 1.0);}
      {Draw_sector(h, v);}
      {Update_video_window;}
      {Set_video_color(drawing_color.x, drawing_color.y, drawing_color.z);}

      {***********************************}
      { find window coordinates of sector }
      {***********************************}
      sector_min.h := h * sector_size;
      sector_min.v := v * sector_size;
      sector_max.h := sector_min.h + (sector_size - 1);
      sector_max.v := sector_min.v + (sector_size - 1);

      with buffer.screen_box do
        begin
          {*********************************}
          { clip sectors at horizontal edge }
          {*********************************}
          if (sector_max.h > max.h) then
            sector_max.h := max.h;

          {*********************************}
          { clip sectors at horizontal edge }
          {*********************************}
          if (sector_max.v > max.v) then
            sector_max.v := max.v;
        end;

      {************************}
      { clear pixels in sector }
      {************************}
      for v_counter := sector_min.v to sector_max.v do
        for h_counter := sector_min.h to sector_max.h do
          Index_buffer(buffer.buffer_ptr, h_counter, v_counter)^.background :=
            true;

      {****************************}
      { clear sector to background }
      {****************************}
      Index_sector(buffer.sector_ptr, h, v)^ := true;
    end;
end; {procedure Clear_sector}


procedure Clear_sector_buffer(var buffer: color_buffer_type);
var
  h_counter, v_counter: integer;
begin
  with current_window_ptr^ do
    begin
      {********************}
      { initialize sectors }
      {********************}
      with buffer do
        for v_counter := 0 to sectors.h do
          for h_counter := 0 to sectors.v do
            Index_sector(sector_ptr, h_counter, v_counter)^ := false;
    end;
end; {procedure Clear_sector_buffer}


procedure Clear_sectors(var buffer: color_buffer_type;
  sector_box: screen_box_type);
var
  h_counter, v_counter: integer;
begin
  with current_window_ptr^ do
    begin
      {***************}
      { clear sectors }
      {***************}
      with buffer do
        for v_counter := sector_box.min.v to sector_box.max.v do
          for h_counter := sector_box.min.h to sector_box.max.h do
            Clear_sector(buffer, h_counter, v_counter);
    end;
end; {procedure Clear_sectors}


procedure Clear_color_buffer(var buffer: color_buffer_type);
begin
  with current_window_ptr^ do
    begin
      background := drawing_color;
      with buffer do
        begin
          {*********************************************}
          { Clear_color_buffer uses the screen box to   }
          { clear only that portion of the color buffer }
          { which was modified in the last frame.       }
          {*********************************************}
          background := drawing_color;
          background_color := Color_to_buffer_color(background);
          background_color.background := true;

          {***********************}
          { allocate color buffer }
          {***********************}
          if buffer_ptr = nil then
            begin
              buffer_ptr := New_color_buffer(size);
              sector_ptr := New_sector_buffer(sectors);
            end;

          {***********************}
          { initialize screen box }
          {***********************}
          Init_screen_box(screen_box, window_size);

          {***************************}
          { clip screen box to window }
          {***************************}
          Clip_screen_box(screen_box, window_size);

          {Set_color(unit_vector);}
          {Write_screen_box(buffer.screen_box);}
          {Draw_screen_box(buffer.screen_box);}
          {Show_window;}

          {*******************************************}
          { if screen box set then clear color buffer }
          {*******************************************}
          if (screen_box.min.h < screen_box.max.h) then
            if (screen_box.min.v < screen_box.max.v) then
              begin
                {********************}
                { clear color buffer }
                {********************}
                Clear_sectors(buffer, Sector_screen_box(screen_box));

                {*******************************}
                { reset color buffer screen box }
                {*******************************}
                Reset_screen_box(screen_box);
              end;
        end;
    end;
end; {procedure Clear_color_buffer}


procedure Set_color(color: color_type);
begin
  with current_window_ptr^ do
    if not Equal_color(color, drawing_color) then
      begin
        color := Clip_color(color);
        drawing_color := color;

        if (show_mode = show_on) then
          Set_video_color(color);
        if (vector_save_mode = save_on) then
          Add_display_list_set_foreground_color(color);

        buffer_color := Color_to_buffer_color(drawing_color);
      end;
end; {procedure Set_color}


function Get_color: color_type;
begin
  Get_color := current_window_ptr^.drawing_color;
end; {function Get_color}


{*************************}
{ buffer drawing routines }
{*************************}


procedure Draw_buffer_line(pixel1, pixel2: pixel_type);
var
  x1, y1: integer;
  x2, y2: integer;
  x, y: integer;
  dx, dy, sx, sy, temp: integer;
  interchange: boolean;
  error: integer;
  i: integer;
begin
  Update_screen_box(current_window_ptr^.color_buffer.screen_box, pixel1);
  Update_screen_box(current_window_ptr^.color_buffer.screen_box, pixel2);

  x1 := pixel1.h;
  y1 := pixel1.v;

  x2 := pixel2.h;
  y2 := pixel2.v;

  x := x1;
  y := y1;

  dx := abs(x2 - x1);
  dy := abs(y2 - y1);
  sx := Sign(x2 - x1);
  sy := Sign(y2 - y1);

  {*********************************}
  { interchange dx and dy depending }
  { on the slope of the line        }
  {*********************************}
  if (dy > dx) then
    begin
      temp := dx;
      dx := dy;
      dy := temp;
      interchange := true;
    end
  else
    interchange := false;

  {************************************}
  { initialize error term to           }
  { compensate for a nonzero intercept }
  {************************************}
  error := (2 * dy) - dx;

  {***********}
  { main loop }
  {***********}
  with current_window_ptr^.color_buffer do
    for i := 0 to dx do
      begin
        Index_buffer(buffer_ptr, x, y)^ := current_window_ptr^.buffer_color;

        {***************}
        { update sector }
        {***************}
        Index_sector(sector_ptr, x div sector_size, y div sector_size)^ :=
          false;

        while (error > 0) do
          begin
            if interchange then
              begin
                x := x + sx;
              end
            else
              begin
                y := y + sy;
              end;
            error := error - (2 * dx);
          end;

        if interchange then
          begin
            y := y + sy;
          end
        else
          begin
            x := x + sx;
          end;
        error := error + (2 * dy);
      end;
end; {procedure Draw_buffer_line}


procedure Draw_buffer_h_line(h1, h2, v: integer);
var
  current_buffer_ptr: buffer_ptr_type;
  current_sector_ptr: sector_ptr_type;
  counter: integer;
begin
  Update_screen_box(current_window_ptr^.color_buffer.screen_box, To_pixel(h1,
    v));
  Update_screen_box(current_window_ptr^.color_buffer.screen_box, To_pixel(h2,
    v));

  with current_window_ptr^.color_buffer do
    begin
      {***********************}
      { draw line into buffer }
      {***********************}
      current_buffer_ptr := Index_buffer(buffer_ptr, h1, v);
      for counter := h1 to h2 do
        begin
          current_buffer_ptr^ := current_window_ptr^.buffer_color;
          current_buffer_ptr := buffer_ptr_type(longint(current_buffer_ptr) +
            sizeof(buffer_type));
        end;

      {************************}
      { draw line into sectors }
      {************************}
      h1 := h1 div sector_size;
      h2 := h2 div sector_size;
      v := v div sector_size;
      current_sector_ptr := Index_sector(sector_ptr, h1, v);
      for counter := h1 to h2 do
        begin
          current_sector_ptr^ := false;
          current_sector_ptr := sector_ptr_type(longint(current_sector_ptr) +
            sizeof(sector_type));
        end;
    end;
end; {procedure Draw_buffer_h_line}


procedure Draw_buffer_span(h1, h2, v: integer;
  color: color_type);
var
  color_increment: color_type;
  current_buffer_ptr: buffer_ptr_type;
  current_sector_ptr: sector_ptr_type;
  counter, span_length: integer;
begin
  Update_screen_box(current_window_ptr^.color_buffer.screen_box, To_pixel(h1,
    v));
  Update_screen_box(current_window_ptr^.color_buffer.screen_box, To_pixel(h2,
    v));

  span_length := h2 - h1;
  if span_length = 0 then
    span_length := 1;
  color_increment := Intensify_color(Contrast_color(color,
    current_window_ptr^.drawing_color), 1 / span_length);

  with current_window_ptr^.color_buffer do
    begin
      {***********************}
      { draw line into buffer }
      {***********************}
      current_buffer_ptr := Index_buffer(buffer_ptr, h1, v);
      for counter := h1 to h2 do
        begin
          current_buffer_ptr^ := current_window_ptr^.buffer_color;
          current_buffer_ptr := buffer_ptr_type(longint(current_buffer_ptr) +
            sizeof(buffer_type));
          Set_color(Mix_color(current_window_ptr^.drawing_color,
            color_increment));
        end;

      {************************}
      { draw line into sectors }
      {************************}
      h1 := h1 div sector_size;
      h2 := h2 div sector_size;
      v := v div sector_size;
      current_sector_ptr := Index_sector(sector_ptr, h1, v);
      for counter := h1 to h2 do
        begin
          current_sector_ptr^ := false;
          current_sector_ptr := sector_ptr_type(longint(current_sector_ptr) +
            sizeof(sector_type));
        end;
    end;
end; {procedure Draw_buffer_span}


procedure Draw_buffer_rect(pixel1, pixel2: pixel_type);
var
  rect_box: screen_box_type;
  sector_box: screen_box_type;
  h, v: integer;
begin
  Update_screen_box(current_window_ptr^.color_buffer.screen_box, pixel1);
  Update_screen_box(current_window_ptr^.color_buffer.screen_box, pixel2);

  {**************************}
  { find min and max of rect }
  {**************************}
  with rect_box do
    begin
      if (pixel1.h < pixel2.h) then
        begin
          min.h := pixel1.h;
          max.h := pixel2.h;
        end
      else
        begin
          min.h := pixel2.h;
          max.h := pixel1.h;
        end;

      if (pixel1.v < pixel2.v) then
        begin
          min.v := pixel1.v;
          max.v := pixel2.v;
        end
      else
        begin
          min.v := pixel2.v;
          max.v := pixel1.v;
        end;
    end;

  {*******************}
  { scan convert rect }
  {*******************}
  with current_window_ptr^.color_buffer do
    for v := rect_box.min.v to rect_box.max.v do
      for h := rect_box.min.h to rect_box.max.h do
        Index_buffer(buffer_ptr, h, v)^ := current_window_ptr^.buffer_color;

  {*************}
  { set sectors }
  {*************}
  sector_box := Sector_screen_box(rect_box);
  with current_window_ptr^.color_buffer do
    for v := sector_box.min.v to sector_box.max.v do
      for h := sector_box.min.h to sector_box.max.h do
        Index_sector(sector_ptr, h, v)^ := false;
end; {procedure Draw_buffer_rect}


{******************}
{ drawing routines }
{******************}


procedure Draw_frame;
var
  color: color_type;
  pixel: pixel_type;
begin
  with current_window_ptr^ do
    begin
      color := drawing_color;
      Set_color(white_color);

      {if (show_mode = show_on) then}
      {Draw_video_frame;}

      pixel.h := 0;
      pixel.v := 0;
      Move_to(pixel);
      pixel.h := size.h - 1;
      Line_to(pixel);
      pixel.v := size.v - 1;
      Line_to(pixel);
      pixel.h := 0;
      Line_to(pixel);
      pixel.v := 0;
      Line_to(pixel);

      Set_color(color);
      window_changed := true;
    end;
end; {procedure Draw_frame}


procedure Clear_window;
begin
  with current_window_ptr^ do
    begin
      if (show_mode = show_on) then
        Clear_video_window;

      if (raster_save_mode = save_on) then
        Clear_color_buffer(color_buffer);

      if (vector_save_mode = save_on) then
        begin
          Clear_display_list(display_list_ptr);
          Add_display_list_set_background_color(background);
        end;

      window_changed := true;
    end;
end; {procedure Clear_window}


procedure Move_to(pixel: pixel_type);
begin
  with current_window_ptr^ do
    begin
      if (show_mode = show_on) then
        with pixel do
          Move_to_video(pixel);
      previous_pixel := pixel;
    end;
end; {procedure Move_to}


procedure Line_to(pixel: pixel_type);
begin
  with current_window_ptr^ do
    begin
      if (show_mode = show_on) then
        with pixel do
          Line_to_video(pixel);

      if (raster_save_mode = save_on) then
        Draw_buffer_line(previous_pixel, pixel);

      if (vector_save_mode = save_on) then
        Add_display_list_line(previous_pixel, pixel);

      previous_pixel := pixel;
      window_changed := true;
    end;
end; {procedure Line_to}


procedure Draw_pixel(pixel: pixel_type);
begin
  with current_window_ptr^ do
    begin
      if (show_mode = show_on) then
        with pixel do
          Draw_video_pixel(pixel);

      if (raster_save_mode = save_on) then
        begin
          Update_screen_box(current_window_ptr^.color_buffer.screen_box, pixel);
          with color_buffer do
            begin
              Index_buffer(buffer_ptr, pixel.h, pixel.v)^ := buffer_color;
              Index_sector(sector_ptr, pixel.h div sector_size, pixel.v div
                sector_size)^ := false;
            end;
        end;

      if (vector_save_mode = save_on) then
        begin
          Add_display_list_pixel(pixel);
        end;

      window_changed := true;
    end;
end; {procedure Draw_pixel}


procedure Draw_line(pixel1, pixel2: pixel_type);
begin
  with current_window_ptr^ do
    begin
      if (show_mode = show_on) then
        Draw_video_line(pixel1, pixel2);

      if (raster_save_mode = save_on) then
        Draw_buffer_line(pixel1, pixel2);

      if (vector_save_mode = save_on) then
        Add_display_list_line(pixel1, pixel2);

      window_changed := true;
    end;
end; {procedure Draw_line}


procedure Draw_h_line(h1, h2, v: integer);
begin
  with current_window_ptr^ do
    begin
      if (show_mode = show_on) then
        Draw_video_h_line(h1, h2, v);

      if (raster_save_mode = save_on) then
        Draw_buffer_h_line(h1, h2, v);

      window_changed := true;
    end;
end; {procedure Draw_h_line}


procedure Draw_span(h1, h2, v: integer;
  color: color_type);
begin
  with current_window_ptr^ do
    begin
      color := Clip_color(color);

      if (show_mode = show_on) then
        Draw_video_span(h1, h2, v, color);

      if (raster_save_mode = save_on) then
        Draw_buffer_span(h1, h2, v, color);

      window_changed := true;
    end;
end; {procedure Draw_span}


procedure Draw_rect(pixel1, pixel2: pixel_type);
begin
  with current_window_ptr^ do
    begin
      if (show_mode = show_on) then
        Draw_video_rect(pixel1, pixel2);

      if (raster_save_mode = save_on) then
        Draw_buffer_rect(pixel1, pixel2);

      if (vector_save_mode = save_on) then
        Add_display_list_rect(pixel1, pixel2);

      window_changed := true;
    end;
end; {procedure Draw_rect}


function Get_pixel_color(pixel: pixel_type): pixel_color_type;
var
  pixel_color: pixel_color_type;
begin
  with current_window_ptr^.color_buffer do
    if (raster_save_mode = save_on) then
      begin
        with pixel do
          if Index_buffer(buffer_ptr, h, v)^.background then
            pixel_color := background_color.pixel_color
          else
            pixel_color := Index_buffer(buffer_ptr, h, v)^.pixel_color;
      end
    else
      pixel_color := black_pixel;

  Get_pixel_color := pixel_color;
end; {function Get_pixel_color}


function Get_display_image: image_ptr_type;
var
  image_ptr: image_ptr_type;
  pixel: pixel_type;
  h, v: integer;
begin
  with current_window_ptr^ do
    begin
      image_ptr := New_image(size);
      for h := 1 to size.h do
        begin
          pixel.h := h;
          for v := 1 to size.v do
            begin
              pixel.v := v;
              Set_image_color(image_ptr, pixel, Get_pixel_color(pixel));
            end;
        end;
    end;

  Get_display_image := image_ptr;
end; {function Get_display_image}


procedure Update_window;
begin
  if (show_mode = show_on) then
    Update_video_window;
end; {procedure Update_window}


procedure Show_window;
begin
  if (show_mode = show_on) then
    Show_video_window;
end; {procedure Show_window}


{****************************}
{ image composition routines }
{****************************}


procedure Clear_composite_buffer;
begin
  Set_color(black_color);
  Clear_color_buffer(current_window_ptr^.composite_buffer);
end; {procedure Clear_composite_buffer}


procedure Composite_sector(filter: color_type;
  h, v: integer);
var
  h_counter, v_counter: integer;
  sector_min, sector_max: pixel_type;
  background_color_sector: boolean;
  background_composite_sector: boolean;
  background1, background2: boolean;
  color1, color2, sum_color: color_type;
  color_buffer_ptr, composite_buffer_ptr: buffer_ptr_type;
begin
  with current_window_ptr^ do
    begin
      background_color_sector := Index_sector(color_buffer.sector_ptr, h, v)^;
      background_composite_sector := Index_sector(composite_buffer.sector_ptr,
        h, v)^;

      if not (background_color_sector and background_composite_sector) then
        begin
          {Set_video_color(1.0, 1.0, 1.0);}
          {Draw_sector(h, v);}
          {Update_video_window;}
          {Set_video_color(drawing_color.x, drawing_color.y, drawing_color.z);}

          {******************************************}
          { sector is no longer the background color }
          {******************************************}
          Index_sector(composite_buffer.sector_ptr, h, v)^ := false;

          {***********************************}
          { find window coordinates of sector }
          {***********************************}
          sector_min.h := h * sector_size;
          sector_min.v := v * sector_size;
          sector_max.h := sector_min.h + (sector_size - 1);
          sector_max.v := sector_min.v + (sector_size - 1);

          {*********************************}
          { clip sectors at horizontal edge }
          {*********************************}
          if (h = sectors.h) then
            with composite_buffer.screen_box do
              if (sector_max.h > max.h) then
                sector_max.h := max.h;

          {*********************************}
          { clip sectors at horizontal edge }
          {*********************************}
          if (v = sectors.v) then
            with composite_buffer.screen_box do
              if (sector_max.v > max.v) then
                sector_max.v := max.v;

          {****************************}
          { composite pixels in sector }
          {****************************}
          for v_counter := sector_min.v to sector_max.v do
            for h_counter := sector_min.h to sector_max.h do
              begin
                with composite_buffer do
                  composite_buffer_ptr := Index_buffer(buffer_ptr, h_counter,
                    v_counter);
                with color_buffer do
                  color_buffer_ptr := Index_buffer(buffer_ptr, h_counter,
                    v_counter);

                background1 := composite_buffer_ptr^.background;
                background2 := color_buffer_ptr^.background;

                if not (background1 and background2) then
                  begin
                    {*********************************}
                    { get color from composite buffer }
                    {*********************************}
                    if background1 then
                      color1 := composite_buffer.background
                    else
                      color1 := Buffer_color_to_color(composite_buffer_ptr^);

                    {*****************************}
                    { get color from color buffer }
                    {*****************************}
                    if background2 then
                      color2 := color_buffer.background
                    else
                      color2 := Buffer_color_to_color(color_buffer_ptr^);

                    {************}
                    { sum colors }
                    {************}
                    {sum_color := Sum(color1, Scale(filter, Dot_product(color2, color2) / 3));}
                    {sum_color := Sum(color1, Scale(filter, (color2.x + color2.y + color2.z) / 3));}
                    sum_color := Mix_color(color1, Filter_color(color2,
                      filter));

                    composite_buffer_ptr^ :=
                      Color_to_buffer_color(Clip_color(sum_color));
                  end;
              end;
        end;
    end;
end; {procedure Composite_sector}


procedure Composite_image(filter: color_type);
var
  filtered_background: color_type;
  sector_box: screen_box_type;
  h, v: integer;
begin
  with current_window_ptr^ do
    begin
      {*******************}
      { extend screen box }
      {*******************}
      Extend_screen_box(composite_buffer.screen_box, color_buffer.screen_box);
      sector_box := Sector_screen_box(composite_buffer.screen_box);

      {Set_color(unit_vector);}
      {Draw_screen_box(color_buffer.screen_box);}
      {Update_window;}

      if (color_buffer.buffer_ptr <> nil) and (composite_buffer.buffer_ptr <>
        nil) then
        begin
          {*******************}
          { composite sectors }
          {*******************}
          with sector_box do
            for v := min.v to max.v do
              for h := min.h to max.h do
                Composite_sector(filter, h, v);

          {******************************}
          { compute new background color }
          {******************************}
          with color_buffer do
            begin
              {filtered_background := Scale(filter, Dot_product(background, background) / 3);}
              {filtered_background := Scale(filter, (background.x + background.y + background.z) / 3);}
              filtered_background := Filter_color(background, filter);
            end;

          with composite_buffer do
            begin
              background := Mix_color(background, filtered_background);
              background_color := Color_to_buffer_color(background);
              background_color.background := true;
            end;
        end
      else
        Error('Unable to composite image.');
    end;

  {Draw_sectors(current_window_ptr^.composite_buffer);}
  {Show_window;}
end; {procedure Composite_image}


procedure Show_composite_buffer;
var
  h, v: integer;
  h_counter, v_counter: integer;
  sector_box: screen_box_type;
  sector_min, sector_max: pixel_type;
  color: color_type;
  temp: color_buffer_type;
begin
  if (show_mode = show_on) then
    with current_window_ptr^ do
      begin
        {***************************}
        { clear to background color }
        {***************************}
        Set_video_color(composite_buffer.background);
        Clear_video_window;

        {*****************************}
        { draw non background sectors }
        {*****************************}
        sector_box := Sector_screen_box(composite_buffer.screen_box);
        for v := sector_box.min.v to sector_box.max.v do
          for h := sector_box.min.h to sector_box.max.h do
            if not Index_sector(composite_buffer.sector_ptr, h, v)^ then
              begin
                {***********************************}
                { find window coordinates of sector }
                {***********************************}
                sector_min.h := h * sector_size;
                sector_min.v := v * sector_size;
                sector_max.h := sector_min.h + (sector_size - 1);
                sector_max.v := sector_min.v + (sector_size - 1);

                {*********************************}
                { clip sectors at horizontal edge }
                {*********************************}
                if (h = sectors.h) then
                  with composite_buffer.screen_box do
                    if (sector_max.h > max.h) then
                      sector_max.h := max.h;

                {*********************************}
                { clip sectors at horizontal edge }
                {*********************************}
                if (v = sectors.v) then
                  with composite_buffer.screen_box do
                    if (sector_max.v > max.v) then
                      sector_max.v := max.v;

                {****************************}
                { draw non background pixels }
                {****************************}
                with composite_buffer do
                  for v_counter := sector_min.v to sector_max.v do
                    for h_counter := sector_min.h to sector_max.h do
                      begin
                        buffer_color := Index_buffer(buffer_ptr, h_counter,
                          v_counter)^;
                        if not buffer_color.background then
                          begin
                            color := Buffer_color_to_color(buffer_color);
                            Set_video_color(color);
                            Draw_video_pixel(To_pixel(h_counter, v_counter));
                          end;
                      end;
              end;

        if (raster_save_mode = save_on) then
          begin
            temp := color_buffer;
            color_buffer := composite_buffer;
            composite_buffer := temp;
          end;

        {***********************}
        { restore drawing color }
        {***********************}
        Set_video_color(drawing_color);
      end;
end; {procedure Show_composite_buffer}


end. {module display}

