unit video;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               video                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to the display       }
{       hardware. Most porting changes will be here.            }
{                                                               }
{       This is intended to be a one way interface because      }
{       we can't always rely on being able to get data back     }
{       from the videoframe buffer. If we wish to query the     }
{       display, then these types of functions must be          }
{       provided in the display module, where we can keep       }
{       our own copy of the frame buffer so that any type       }
{       of operation is possible.                               }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  strings, pixels, screen_boxes, colors, mouse_input, keyboard_input,
  drawable, reference_counting;


type
  video_window_type = class(interfaced_object_type, drawable_type)

  public
    {******************************}
    { auxilliary state information }
    {******************************}
    mouse_state: mouse_state_type;
    keyboard_state: keyboard_state_type;

    {*****************************}
    { opening and closing methods }
    {*****************************}
    procedure Open(title: string_type; size, center: pixel_type); virtual;
    procedure Close; virtual;

    {*****************************}
    { window manipulation methods }
    {*****************************}
    procedure Activate;
    procedure Resize(size: pixel_type);

    {***********************}
    { color related methods }
    {***********************}
    procedure Set_color(color: color_type); virtual; abstract;
    function Get_color: color_type; virtual; abstract;

    {****************************}
    { primitive drawing routines }
    {****************************}
    procedure Move_to(pixel: pixel_type); virtual; abstract;
    procedure Line_to(pixel: pixel_type); virtual; abstract;

    {**************************}
    { derived drawing routines }
    {**************************}
    procedure Draw_pixel(pixel: pixel_type); virtual;
    procedure Draw_line(pixel1, pixel2: pixel_type); virtual;
    procedure Draw_h_line(h1, h2, v: integer); virtual;
    procedure Draw_span(h1, h2, v: integer; color: color_type); virtual;
    procedure Draw_rect(pixel1, pixel2: pixel_type); virtual;
    procedure Fill_rect(pixel1, pixel2: pixel_type); virtual;

    {*************************}
    { window refresh routines }
    {*************************}
    procedure Clear; virtual; abstract;
    procedure Update; virtual; abstract;
    procedure Show; virtual; abstract;

    {***********************}
    { window query function }
    {***********************}
    function Get_title: string_type;
    function Get_size: pixel_type;

  protected
    {****************************************}
    { platform independent window attributes }
    {****************************************}
    title: string_type;
    size, center: pixel_type;
    screen_box: screen_box_type;
    fullscreen: boolean;
  end; {video_window}


var
  current_window: video_window_type;


procedure Close_all_video_windows;

{***********************}
{ screen query routines }
{***********************}
function Get_screen_size: pixel_type;
function Get_screen_center: pixel_type;


implementation


const
  debug = false;


type
  window_ref_ptr_type = ^window_ref_type;
  window_ref_type = record
    video_window: video_window_type;
    next: window_ref_ptr_type;
  end; {window_ref_type}


var
  window_ref_list: window_ref_ptr_type;


{***********************************************}
{ routines for window reference list management }
{***********************************************}


procedure Add_window_reference(video_window: video_window_type);
var
  window_ref_ptr: window_ref_ptr_type;
begin
  new(window_ref_ptr);
  window_ref_ptr^.video_window := video_window;

  {*******************************}
  { add reference to head of list }
  {*******************************}
  window_ref_ptr^.next := window_ref_list;
  window_ref_list := window_ref_ptr;
end; {procedure Add_window_reference}


procedure Remove_window_reference(video_window: video_window_type);
var
  prev, next: window_ref_ptr_type;
  found: boolean;
begin
  {*******************************}
  { find window in reference list }
  {*******************************}
  found := false;
  prev := nil;
  next := window_ref_list;
  while not found and (next <> nil) do
    begin
      if next^.video_window = video_window then
        found := true
      else
        begin
          prev := next;
          next := next^.next;
        end;
    end;

  {****************************************}
  { unlink and dispose of window reference }
  {****************************************}
  if found then
    begin
      if prev <> nil then
        prev^.next := next^.next
      else
        window_ref_list := next^.next;
      dispose(next);
    end;
end; {procedure Remove_window_reference}


procedure Close_all_video_windows;
var
  video_window: video_window_type;
begin
  while (window_ref_list <> nil) do
    begin
      video_window := window_ref_list^.video_window;
      Remove_window_reference(window_ref_list^.video_window);
      video_window.Close;
    end;
end; {procedure Close_all_video_windows}


{*****************************}
{ opening and closing methods }
{*****************************}


procedure video_window_type.Open(title: string_type; size, center: pixel_type);
begin
  self.title := title;
  self.size := size;
  self.center := center;
  self.fullscreen := Equal_pixels(size, Get_screen_size);
  self.screen_box.min := Pixel_difference(center, Pixel_scale(size, 0.5));
  self.screen_box.max := Pixel_sum(screen_box.min, size);
  Add_window_reference(self);
  Activate;
end; {procedure video_window_type.Open}


procedure video_window_type.Close;
begin
  Remove_window_reference(self);
end; {procedure video_window_type.Close}


{*****************************}
{ window manipulation methods }
{*****************************}


procedure video_window_type.Activate;
begin
  current_window := self;
end; {procedure video_window_type.Activate}


procedure video_window_type.Resize(size: pixel_type);
begin
  self.size := size;
  self.screen_box.min := Pixel_difference(center, Pixel_scale(size, 0.5));
  self.screen_box.max := Pixel_sum(screen_box.min, size);
end; {procedure video_window_type.Resize}


{**************************}
{ derived drawing routines }
{**************************}


procedure video_window_type.Draw_pixel(pixel: pixel_type);
begin
  Move_to(pixel);
  Line_to(pixel);
end; {procedure video_window_type.Draw_pixel}


procedure video_window_type.Draw_line(pixel1, pixel2: pixel_type);
begin
  Move_to(pixel1);
  Line_to(pixel2);
end; {procedure video_window_type.Draw_line}


procedure video_window_type.Draw_h_line(h1, h2, v: integer);
begin
  Move_to(To_pixel(h1, v));
  Line_to(To_pixel(h2, v));
end; {procedure video_window_type.Draw_h_line}


procedure video_window_type.Draw_span(h1, h2, v: integer; color: color_type);
begin
  Move_to(To_pixel(h1, v));
  Set_color(color);
  Line_to(To_pixel(h2, v));
end; {procedure video_window_type.Draw_span}


procedure video_window_type.Draw_rect(pixel1, pixel2: pixel_type);
begin
  Move_to(pixel1);
  Line_to(To_pixel(pixel2.h, pixel1.v));
  Line_to(pixel2);
  Line_to(To_pixel(pixel1.h, pixel2.v));
  Line_to(pixel1);
end; {procedure video_window_type.Draw_rect}


procedure video_window_type.Fill_rect(pixel1, pixel2: pixel_type);
var
  v: integer;
begin
  for v := pixel1.v to pixel2.v do
    Draw_h_line(pixel1.h, pixel2.h, v);
end; {procedure video_window_type.Fill_rect}


{***********************}
{ window query function }
{***********************}


function video_window_type.Get_title: string_type;
begin
  Get_title := title;
end; {function video_window_type.Get_title}


function video_window_type.Get_size: pixel_type;
begin
  Get_size := size;
end; {function video_window_type.Get_size}


{***********************}
{ screen query routines }
{***********************}


function Get_screen_size: pixel_type;
begin
  Get_screen_size := To_pixel(1024, 768);
end; {function Get_screen_size}


function Get_screen_center: pixel_type;
begin
  Get_screen_center := To_pixel(512, 384);
end; {function Get_screen_center}


initialization
  if debug then
    writeln('Initializing video.');

  {****************************}
  { initialize window pointers }
  {****************************}
  window_ref_list := nil;
  current_window := nil;
end.

