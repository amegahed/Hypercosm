unit drawable;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             drawable                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to 2d drawing        }
{       functionality implemented by the video modules.         }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  pixels, colors;


type
  ditherable_type = interface
    ['{3F907E82-DBDC-4045-BA9B-B6794C410AC4}']
    procedure Set_dither_mode(mode: boolean);
    function Get_dither_mode: boolean;
  end; {ditherable_type}


  double_bufferable_type = interface
    ['{11625D00-A47B-11D6-B2C3-002078005298}']
    procedure Set_double_buffer_mode(mode: boolean);
    function Get_double_buffer_mode: boolean;
  end; {double_bufferable_type}


  drawable_ptr_type = ^drawable_type;
  drawable_type = interface

    {***********************}
    { color related methods }
    {***********************}
    procedure Set_color(color: color_type);
    function Get_color: color_type;

    {******************}
    { drawing routines }
    {******************}
    procedure Move_to(pixel: pixel_type);
    procedure Line_to(pixel: pixel_type);
    procedure Draw_pixel(pixel: pixel_type);
    procedure Draw_line(pixel1, pixel2: pixel_type);
    procedure Draw_h_line(h1, h2, v: integer);
    procedure Draw_span(h1, h2, v: integer; color: color_type);
    procedure Draw_rect(pixel1, pixel2: pixel_type);
    procedure Fill_rect(pixel1, pixel2: pixel_type);

    {*************************}
    { window refresh routines }
    {*************************}
    procedure Clear;
    procedure Update;
    procedure Show;

    {**************************}
    { window querying routines }
    {**************************}
    function Get_size: pixel_type;

  end; {drawable_type}


implementation


end.

