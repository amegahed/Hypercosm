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
  vectors, colors, drawable, textures, renderable, renderer;


type
  opengl_renderer_type = class(hardware_renderer_type, texturable_type,
    smooth_shadeable_type)

    {****************************}
    { initializer and finalizers }
    {****************************}
    procedure Open(drawable: drawable_type);
    procedure Close;

    {*******************}
    { clear all buffers }
    {*******************}
    procedure Clear; override;
    procedure Set_range(z_near, z_far: real); override;

    {*********************************}
    { routines to set rendering modes }
    {*********************************}
    procedure Set_shading_mode(mode: shading_mode_type);
    procedure Set_texture_map(texture_ptr: texture_ptr_type);

    {***********************************}
    { routines to query rendering modes }
    {***********************************}
    function Get_shading_mode: shading_mode_type;
    function Get_texture_map: texture_ptr_type;

    {********************************************}
    { these functions set the vertex destination }
    {********************************************}
    procedure Begin_polygon; override;
    procedure Begin_hole; override;
    procedure Begin_line; override;
    procedure Begin_points; override;

    {**************************************************************}
    { these function set vertex properties before a vertex is sent }
    {**************************************************************}
    procedure Set_color(color: color_type); override;
    procedure Set_texture(texture: vector_type); override;
    procedure Set_normal(normal: vector_type); override;
    procedure Set_vertex(vertex: vector_type); override;
    procedure Set_vectors(u_axis, v_axis: vector_type); override;

    {************************************************}
    { these functions store vertices in the pipeline }
    {************************************************}
    procedure Add_vertex(point: vector_type); override;

    {******************}
    { drawing routines }
    {******************}
    procedure Draw_polygon; override;
    procedure Draw_line; override;
    procedure Draw_points; override;

  end; {opengl_renderer_type}


implementation
uses
  OpenGL, GL,
  pixels, z_vertices, z_pipeline, z_clip, z_triangles, viewports, project;


function gluBuild2DMipmaps(Target: GLenum; Components, Width, Height: GLint;
  Format, atype: GLenum; Data: Pointer): GLint; stdcall; external glu32;


type
  opengl_texture_ptr_type = ^opengl_texture_type;
  opengl_texture_type = record
    texture_id: GLuint;
  end; {opengl_texture_type}


var
  current_texture_ptr: texture_ptr_type;


procedure Init_opengl_environment_mapping;
begin
  glTexGenf(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
  glTexGenf(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
  glEnable(GL_TEXTURE_GEN_S); // Enable spherical
  glEnable(GL_TEXTURE_GEN_T); // Environment Mapping
end; {procedure Init_opengl_environment_mapping}


procedure Init_opengl_texture_mapping;
begin
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  glEnable(GL_TEXTURE_2D);
end; {procedure Init_opengl_texture_mapping}


procedure Init_opengl;
begin
  Init_opengl_texture_mapping;
  // Init_opengl_environment_mapping;
end; {procedure Init_opengl}


function New_opengl_texture: opengl_texture_ptr_type;
var
  opengl_texture_ptr: opengl_texture_ptr_type;
begin
  new(opengl_texture_ptr);
  opengl_texture_ptr^.texture_id := 0;
  New_opengl_texture := opengl_texture_ptr;
end; {function New_opengl_texture}


procedure Init_opengl_texture(texture_ptr: texture_ptr_type);
var
  opengl_texture_ptr: opengl_texture_ptr_type;
begin
  opengl_texture_ptr := New_opengl_texture;
  texture_ptr^.ptr := opengl_texture_ptr;

  glGenTextures(1, opengl_texture_ptr^.texture_id);
  glBindTexture(GL_TEXTURE_2D, opengl_texture_ptr^.texture_id);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

  if texture_ptr^.image_ptr <> nil then
    gluBuild2DMipmaps(GL_TEXTURE_2D, 3, texture_ptr^.image_ptr^.size.h,
      texture_ptr^.image_ptr^.size.v, GL_RGB, GL_UNSIGNED_BYTE,
      texture_ptr^.image_ptr^.pixel_color_ptr);
end; {Init_opengl_texture}


procedure Set_opengl_texture(opengl_texture_ptr: opengl_texture_ptr_type);
begin
  if opengl_texture_ptr <> nil then
    glBindTexture(GL_TEXTURE_2D, opengl_texture_ptr^.texture_id)
  else
    glBindTexture(GL_TEXTURE_2D, 0);
end; {procedure Set_opengl_texture}


{****************************}
{ initializer and finalizers }
{****************************}


procedure opengl_renderer_type.Open(drawable: drawable_type);
begin
  inherited Open(drawable);
  Init_opengl;
end; {procedure opengl_renderer_type.Open}


procedure opengl_renderer_type.Close;
begin
end; {procedure opengl_renderer_type.Close}


{*******************}
{ clear all buffers }
{*******************}


procedure opengl_renderer_type.Clear;
var
  color: color_type;
begin
  color := drawable.Get_color;
  glClearColor(color.r, color.g, color.b, 0.0);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LESS);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
end; {procedure opengl_renderer_type.Clear}


procedure opengl_renderer_type.Set_range(z_near, z_far: real);
var
  size: pixel_type;
begin
  glLoadIdentity;
  size := drawable.Get_size;
  glViewport(0, 0, size.h, size.v);
  glOrtho(0, size.h, size.v, 0, -z_near, -z_far);
end; {procedure opengl_renderer_type.Set_range}


{*********************************}
{ routines to set rendering modes }
{*********************************}


procedure opengl_renderer_type.Set_shading_mode(mode: shading_mode_type);
begin
  case mode of
    flat_shading_mode:
      glShadeModel(GL_FLAT);
    smooth_shading_mode:
      glShadeModel(GL_SMOOTH);
  end; {case}
end; {procedure opengl_renderer_type.Set_shading_mode}


procedure opengl_renderer_type.Set_texture_map(texture_ptr: texture_ptr_type);
begin
  current_texture_ptr := texture_ptr;
  if texture_ptr <> nil then
    begin
      if texture_ptr^.ptr <> nil then
        Set_opengl_texture(opengl_texture_ptr_type(texture_ptr^.ptr))
      else
        Init_opengl_texture(texture_ptr);
    end
  else
    Set_opengl_texture(nil);
end; {procedure opengl_renderer_type.Set_texture_map}


{***********************************}
{ routines to query rendering modes }
{***********************************}


function opengl_renderer_type.Get_shading_mode: shading_mode_type;
begin
  Get_shading_mode := smooth_shading_mode;
end; {function opengl_renderer_type.Get_shading_mode}


function opengl_renderer_type.Get_texture_map: texture_ptr_type;
begin
  Get_texture_map := current_texture_ptr;
end; {function opengl_renderer_type.Get_texture_map}


{********************************************}
{ these functions set the vertex destination }
{********************************************}


procedure opengl_renderer_type.Begin_polygon;
begin
  // glBegin(GL_POLYGON);
  Begin_z_polygon;
end; {procedure opengl_renderer_type.Begin_polygon}


procedure opengl_renderer_type.Begin_hole;
begin
  Begin_z_hole;
end; {procedure opengl_renderer_type.Begin_hole}


procedure opengl_renderer_type.Begin_line;
begin
  // glBegin(GL_LINE);
  Begin_z_line;
end; {procedure opengl_renderer_type.Begin_line}


procedure opengl_renderer_type.Begin_points;
begin
  // glBegin(GL_POINTS);
  Begin_z_points;
end; {procedure opengl_renderer_type.Begin_points}


{**************************************************************}
{ these function set vertex properties before a vertex is sent }
{**************************************************************}


procedure opengl_renderer_type.Set_color(color: color_type);
begin
  // glColor3f(color.r, color.g, color.b);
  Set_z_color(color);
end; {procedure opengl_renderer_type.Set_color}


procedure opengl_renderer_type.Set_texture(texture: vector_type);
begin
  Set_z_texture(texture);
end; {procedure opengl_renderer_type.Set_texture}


procedure opengl_renderer_type.Set_normal(normal: vector_type);
begin
  Set_z_normal(normal);
end; {procedure opengl_renderer_type.Set_normal}


procedure opengl_renderer_type.Set_vertex(vertex: vector_type);
begin
  Set_z_vertex(vertex);
end; {procedure opengl_renderer_type.Set_vertex}


procedure opengl_renderer_type.Set_vectors(u_axis, v_axis: vector_type);
begin
  Set_z_vectors(u_axis, v_axis);
end; {procedure opengl_renderer_type.Set_vectors}


{************************************************}
{ these functions store vertices in the pipeline }
{************************************************}


procedure opengl_renderer_type.Add_vertex(point: vector_type);
begin
  // glVertex3f(point.x, point.y, point.z);
  Add_z_vertex(point);
end; {procedure opengl_renderer_type.Add_vertex}


{******************}
{ drawing routines }
{******************}


procedure opengl_renderer_type.Draw_polygon;
var
  z_polygon_ptr: z_polygon_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
  q: real;
begin
  {************************************}
  { connect polygon holes to perimeter }
  {************************************}
  Remove_z_holes(z_polygon_list, z_hole_list);

  {**************************}
  { clip and project polygon }
  {**************************}
  if z_clipping_enabled then
    Clip_and_project_z_polygon(z_polygon_list, current_viewport_ptr,
      current_projection_ptr);

  {*********************}
  { triangulate polygon }
  {*********************}
  Triangulate_z_polygons(z_polygon_list);

  {***********************}
  { traverse polygon list }
  {***********************}
  z_polygon_ptr := z_polygon_list;
  while z_polygon_ptr <> nil do
    begin
      glBegin(GL_POLYGON);
      z_vertex_ptr := z_polygon_ptr^.first;

      if z_polygon_ptr^.textured then
        begin
          if z_polygon_ptr^.kind <> flat_z_kind then
            begin
              {**************************************}
              { draw smooth shaded, textured polygon }
              {**************************************}
              while (z_vertex_ptr <> nil) do
                begin
                  glColor3f(z_vertex_ptr^.color.r, z_vertex_ptr^.color.g,
                    z_vertex_ptr^.color.b);
                  q := z_vertex_ptr^.point.z;
                  glTexCoord4f(q * z_vertex_ptr^.texture.x, q *
                    z_vertex_ptr^.texture.y,
                    0, q);
                  glVertex3f(z_vertex_ptr^.point.x, z_vertex_ptr^.point.y,
                    z_vertex_ptr^.point.z);
                  z_vertex_ptr := z_vertex_ptr^.next;
                end;
            end
          else
            begin
              {************************************}
              { draw flat shaded, textured polygon }
              {************************************}
              glColor3f(z_polygon_ptr^.color.r, z_polygon_ptr^.color.g,
                z_polygon_ptr^.color.b);
              while (z_vertex_ptr <> nil) do
                begin
                  q := z_vertex_ptr^.point.z;
                  glTexCoord4f(q * z_vertex_ptr^.texture.x, q *
                    z_vertex_ptr^.texture.y,
                    0, q);
                  glVertex3f(z_vertex_ptr^.point.x, z_vertex_ptr^.point.y,
                    z_vertex_ptr^.point.z);
                  z_vertex_ptr := z_vertex_ptr^.next;
                end;
            end;
        end
      else
        begin
          if z_polygon_ptr^.kind <> flat_z_kind then
            begin
              {****************************************}
              { draw smooth shaded, untextured polygon }
              {****************************************}
              while (z_vertex_ptr <> nil) do
                begin
                  glColor3f(z_vertex_ptr^.color.r, z_vertex_ptr^.color.g,
                    z_vertex_ptr^.color.b);
                  glVertex3f(z_vertex_ptr^.point.x, z_vertex_ptr^.point.y,
                    z_vertex_ptr^.point.z);
                  z_vertex_ptr := z_vertex_ptr^.next;
                end;
            end
          else
            begin
              {**************************************}
              { draw flat shaded, untextured polygon }
              {**************************************}
              glColor3f(z_polygon_ptr^.color.r, z_polygon_ptr^.color.g,
                z_polygon_ptr^.color.b);
              while (z_vertex_ptr <> nil) do
                begin
                  glVertex3f(z_vertex_ptr^.point.x, z_vertex_ptr^.point.y,
                    z_vertex_ptr^.point.z);
                  z_vertex_ptr := z_vertex_ptr^.next;
                end;
            end;
        end;

      glEnd;
      z_polygon_ptr := z_polygon_ptr^.next;
    end;

  {*******************}
  { free polygon list }
  {*******************}
  Free_z_vertex_lists(z_polygon_list);
end; {procedure opengl_renderer_type.Draw_polygon}


procedure opengl_renderer_type.Draw_line;
var
  z_line_ptr: z_polygon_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  {***********************}
  { clip and project line }
  {***********************}
  if z_clipping_enabled then
    Clip_and_project_z_line(z_line_list, current_viewport_ptr,
      current_projection_ptr);

  {********************}
  { traverse line list }
  {********************}
  z_line_ptr := z_line_list;
  while z_line_ptr <> nil do
    begin
      glBegin(GL_LINES);
      z_vertex_ptr := z_line_ptr^.first;
      while (z_vertex_ptr <> nil) do
        begin
          glColor3f(z_vertex_ptr^.color.r, z_vertex_ptr^.color.g,
            z_vertex_ptr^.color.b);
          glVertex3f(z_vertex_ptr^.point.x, z_vertex_ptr^.point.y,
            z_vertex_ptr^.point.z);
          z_vertex_ptr := z_vertex_ptr^.next;
        end;
      glEnd;
      z_line_ptr := z_line_ptr^.next;
    end;

  {****************}
  { free line list }
  {****************}
  Free_z_vertex_lists(z_line_list);
end; {procedure opengl_renderer_type.Draw_line}


procedure opengl_renderer_type.Draw_points;
var
  z_point_ptr: z_polygon_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  {*********************}
  { traverse point list }
  {*********************}
  z_point_ptr := z_point_list;
  while z_point_ptr <> nil do
    begin
      z_vertex_ptr := z_point_ptr^.first;
      while (z_vertex_ptr <> nil) do
        begin
          z_vertex_ptr := z_vertex_ptr^.next;
        end;
      z_point_ptr := z_point_ptr^.next;
    end;

  {*****************}
  { free point list }
  {*****************}
  Free_z_vertex_lists(z_point_list);
end; {procedure opengl_renderer_type.Draw_points}


initialization
  current_texture_ptr := nil;
end.

