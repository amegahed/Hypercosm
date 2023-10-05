unit opengl_renderer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           opengl_renderer             3d       }
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
  vectors, colors, renderer;


type
  opengl_renderer_type = class(hardware_renderer_type)

    {*******************}
    { clear all buffers }
    {*******************}
    procedure Clear;
    procedure Set_range(z_near, z_far: real);

    {*********************************}
    { routines to set rendering modes }
    {*********************************}
    procedure Set_shading_mode(mode: shading_mode_type);
    procedure Set_current_texture(texture_ptr: texture_ptr_type);

    {***********************************}
    { routines to query rendering modes }
    {***********************************}
    function Get_shading_mode: shading_mode_type;
    function Get_current_texture: texture_ptr_type;

    {********************************************}
    { these functions set the vertex destination }
    {********************************************}
    procedure Begin_polygon;
    procedure Begin_hole;
    procedure Begin_line;
    procedure Begin_points;

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

    {******************}
    { drawing routines }
    {******************}
    procedure Draw_polygon;
    procedure Draw_line;
    procedure Draw_points;

  end; {opengl_renderer_type}


implementation
uses
  OpenGL;


{*******************}
{ clear all buffers }
{*******************}


procedure opengl_renderer_type.Clear;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
end; {procedure opengl_renderer_type.Clear}


procedure opengl_renderer_type.Set_range(z_near, z_far: real);
begin
end; {procedure opengl_renderer_type.Set_range}


{********************************************}
{ these functions set the vertex destination }
{********************************************}


procedure opengl_renderer_type.Begin_polygon;
begin
  glBegin(GL_POLYGON);
end; {procedure opengl_renderer_type.Begin_polygon}


procedure opengl_renderer_type.Begin_hole;
begin
end; {procedure opengl_renderer_type.Begin_hole}


procedure opengl_renderer_type.Begin_line;
begin
  glBegin(GL_LINE);
end; {procedure opengl_renderer_type.Begin_line}


procedure opengl_renderer_type.Begin_points;
begin
  glBegin(GL_POINTS);
end; {procedure opengl_renderer_type.Begin_points}


{**************************************************************}
{ these function set vertex properties before a vertex is sent }
{**************************************************************}


procedure opengl_renderer_type.Set_color(color: color_type);
begin
  glColor3f(color.r, color.g, color.b);
end; {procedure opengl_renderer_type.Set_color}


procedure opengl_renderer_type.Set_texture(texture: vector_type);
begin
end; {procedure opengl_renderer_type.Set_texture}


procedure opengl_renderer_type.Set_normal(normal: vector_type);
begin
end; {procedure opengl_renderer_type.Set_normal}


procedure opengl_renderer_type.Set_vertex(vertex: vector_type);
begin
end; {procedure opengl_renderer_type.Set_vertex}


procedure opengl_renderer_type.Set_vectors(u_axis, v_axis: vector_type);
begin
end; {procedure opengl_renderer_type.Set_vectors}


{************************************************}
{ these functions store vertices in the pipeline }
{************************************************}


procedure opengl_renderer_type.Add_vertex(point: vector_type);
begin
  glVertex3f(point.x, point.y, point.z);
end; {procedure opengl_renderer_type.Add_vertex}


{******************}
{ drawing routines }
{******************}


procedure opengl_renderer_type.Draw_polygon;
begin
  glEnd;
end; {procedure opengl_renderer_type.Draw_polygon}


procedure opengl_renderer_type.Draw_line;
begin
  glEnd;
end; {procedure opengl_renderer_type.Draw_line}


procedure opengl_renderer_type.Draw_points;
begin
  glEnd;
end; {procedure opengl_renderer_type.Draw_points}


end. {module opengl_renderer}

