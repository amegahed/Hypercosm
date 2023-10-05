unit renderable;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            renderable                 3d       }
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
  vectors, colors, drawable, textures;


type
  {**********************************************}
  { the different parity modes determine how the }
  { parity mask will be used in scan conversion. }
  {**********************************************}
  { no_parity = do not use or set parity mask    }
  { set_parity = set parity during scanning      }
  { not_parity = scan only where parity not set  }
  {**********************************************}
  parity_mode_type = (no_parity, set_parity, not_parity);
  maskable_type = interface
    ['{4ED2938D-7DF3-460B-9031-E7B648060E27}']
    procedure Set_parity_mode(mode: parity_mode_type);
    function Get_parity_mode: parity_mode_type;
  end; {maskable_type}


  texturable_type = interface
    ['{8F9888CB-C452-4ADA-A4CF-9D9B6E87EB48}']
    procedure Set_texture_map(texture_ptr: texture_ptr_type);
    function Get_texture_map: texture_ptr_type;
  end; {texturable_type}


  shading_mode_type = (flat_shading_mode, smooth_shading_mode);
  smooth_shadeable_type = interface
    ['{8A9C845B-70F7-4C29-AFD3-C479A497EF66}']
    procedure Set_shading_mode(mode: shading_mode_type);
    function Get_shading_mode: shading_mode_type;
  end; {smooth_shadeable_type}


  clearable_type = interface
    {*******************}
    { clear all buffers }
    {*******************}
    procedure Clear;
  end;  {clearable_type}


  vertex_renderable_type = interface
    {**************************************************************}
    { these function set vertex properties before a vertex is sent }
    {**************************************************************}
    procedure Set_color(color: color_type);
    procedure Set_texture(texture: vector_type);
    procedure Set_normal(normal: vector_type);
    procedure Set_vertex(vertex: vector_type);
    procedure Set_vectors(u_axis, v_axis: vector_type);

    {************************************************}
    { these functions store vertices in the pipeline }
    {************************************************}
    procedure Add_vertex(point: vector_type);
  end;  {vertex_renderable_type}


  point_renderable_type = interface(vertex_renderable_type)
    procedure Begin_points;
    procedure Draw_points;
  end;  {point_renderable_type}


  line_renderable_type = interface(point_renderable_type)
    procedure Begin_line;
    procedure Draw_line;
  end;  {line_renderable_type}


  polygon_renderable_type = interface(line_renderable_type)
    procedure Begin_polygon;
    procedure Begin_hole;
    procedure Draw_polygon;
  end;  {polygon_renderable_type}


implementation


end.

