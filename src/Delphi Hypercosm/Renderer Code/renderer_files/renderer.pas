unit renderer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             renderer                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to 3d drawing        }
{       functionality implemented by the 3d video modules.      }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  vectors, colors, drawable, textures, renderable, reference_counting;


type
  renderer_type = class(interfaced_object_type, clearable_type,
      vertex_renderable_type, point_renderable_type, line_renderable_type,
      polygon_renderable_type)

    {****************************}
    { initializer and finalizers }
    {****************************}
    procedure Open(drawable: drawable_type);
    procedure Close;

    {*******************}
    { clear all buffers }
    {*******************}
    procedure Clear; virtual; abstract;

    {**************************************************************}
    { these function set vertex properties before a vertex is sent }
    {**************************************************************}
    procedure Set_color(color: color_type); virtual; abstract;
    procedure Set_texture(texture: vector_type); virtual; abstract;
    procedure Set_normal(normal: vector_type); virtual; abstract;
    procedure Set_vertex(vertex: vector_type); virtual; abstract;
    procedure Set_vectors(u_axis, v_axis: vector_type); virtual; abstract;

    {************************************************}
    { these functions store vertices in the pipeline }
    {************************************************}
    procedure Add_vertex(point: vector_type); virtual; abstract;

    {************************}
    { point drawable methods }
    {************************}
    procedure Begin_points; virtual; abstract;
    procedure Draw_points; virtual; abstract;

    {***********************}
    { line drawable methods }
    {***********************}
    procedure Begin_line; virtual; abstract;
    procedure Draw_line; virtual; abstract;

    {**************************}
    { polygon drawable methods }
    {**************************}
    procedure Begin_polygon; virtual; abstract;
    procedure Begin_hole; virtual; abstract;
    procedure Draw_polygon; virtual; abstract;

  public
    drawable: drawable_type;
  end; {renderer_type}


  hardware_renderer_type = class(renderer_type)
    procedure Set_range(z_near, z_far: real); virtual; abstract;
  end; {hardware_renderable_type}


implementation


{****************************}
{ initializer and finalizers }
{****************************}


procedure renderer_type.Open(drawable: drawable_type);
begin
  self.drawable := drawable;
end; {procedure renderer_type.Open}


procedure renderer_type.Close;
begin
end; {procedure renderer_type.Close}


end.

