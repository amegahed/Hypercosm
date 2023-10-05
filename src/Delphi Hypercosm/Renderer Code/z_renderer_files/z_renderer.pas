unit z_renderer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            z_renderer                 3d       }
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
  vectors, colors, pixels, drawable, renderable, textures, renderer, z_buffer,
  parity_buffer, scan_conversion;


type
  z_renderer_type = class(renderer_type, smooth_shadeable_type, maskable_type)

    {****************************}
    { initializer and finalizers }
    {****************************}
    procedure Open(drawable: drawable_type);
    procedure Close;
    procedure Resize(size: pixel_type);

    {*******************}
    { clear all buffers }
    {*******************}
    procedure Clear; override;

    {*********************************}
    { routines to set rendering modes }
    {*********************************}
    procedure Set_shading_mode(mode: shading_mode_type);
    procedure Set_parity_mode(mode: parity_mode_type);

    {***********************************}
    { routines to query rendering modes }
    {***********************************}
    function Get_shading_mode: shading_mode_type;
    function Get_parity_mode: parity_mode_type;

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

  public
    {**************************}
    { rendering mode variables }
    {**************************}
    shading_mode: shading_mode_type;
    parity_mode: parity_mode_type;

    {****************************}
    { rendering buffer variables }
    {****************************}
    z_buffer_ptr: z_buffer_ptr_type;
    parity_buffer_ptr: parity_buffer_ptr_type;

    {****************************}
    { scan conversion structures }
    {****************************}
    z_edge_table_height: integer;
    z_edge_table_ptr: z_edge_table_ptr_type;
    y_min, y_max: integer;
    z_active_edge_list: z_edge_ptr_type;
  end; {z_renderer_type}


implementation
uses
  z_pipeline, z_polygons, z_flat_polygons, z_smooth_polygons, z_flat_lines,
  z_smooth_lines, z_points;


{****************************}
{ initializer and finalizers }
{****************************}


procedure z_renderer_type.Open(drawable: drawable_type);
var
  size: pixel_type;
begin
  inherited Open(drawable);
  size := drawable.Get_size;

  {******************************}
  { initialize rendering buffers }
  {******************************}
  z_buffer_ptr := Open_z_buffer(size);

  {***************************************}
  { initialize scan conversion structures }
  {***************************************}
  z_edge_table_height := size.v;
  z_edge_table_ptr := New_z_edge_table(size.v);
  y_min := maxint;
  y_max := -1;
  z_active_edge_list := nil;
end; {procedure z_renderer_type.Open}


procedure z_renderer_type.Close;
begin
  {************************}
  { free rendering buffers }
  {************************}
  Free_z_buffer(z_buffer_ptr);
  Free_parity_buffer(parity_buffer_ptr);

  {******************************}
  { free scan conversion structs }
  {******************************}
  Free_z_edge_table(z_edge_table_ptr);
end; {procedure z_renderer_type.Close}


procedure z_renderer_type.Resize(size: pixel_type);
begin
  {**************************}
  { resize rendering buffers }
  {**************************}
  Resize_z_buffer(z_buffer_ptr, size);
  if parity_buffer_ptr <> nil then
    Resize_parity_buffer(parity_buffer_ptr, size);

  {********************************}
  { resize scan conversion structs }
  {********************************}
  Free_z_edge_table(z_edge_table_ptr);
  Resize_z_edge_table(z_edge_table_ptr, size.v);
end; {procedure z_renderer_type.Resize}


{*******************}
{ clear all buffers }
{*******************}


procedure z_renderer_type.Clear;
begin
  drawable.Clear;

  // make sure that size of drawable still matches z buffer
  //
  if not Equal_pixels(drawable.Get_size, z_buffer_ptr^.size) then
    Resize(drawable.Get_size);

  Clear_z_buffer(z_buffer_ptr);
end; {procedure z_renderer_type.Clear}


{*********************************}
{ routines to set rendering modes }
{*********************************}


procedure z_renderer_type.Set_shading_mode(mode: shading_mode_type);
begin
  self.shading_mode := mode;
end; {procedure z_renderer_type.Set_shading_mode}


procedure z_renderer_type.Set_parity_mode(mode: parity_mode_type);
begin
  self.parity_mode := mode;
end; {procedure z_renderer_type.Set_parity_mode}


{***********************************}
{ routines to query rendering modes }
{***********************************}


function z_renderer_type.Get_shading_mode: shading_mode_type;
begin
  Get_shading_mode := shading_mode;
end; {function z_renderer_type.Get_shading_mode}


function z_renderer_type.Get_parity_mode: parity_mode_type;
begin
  Get_parity_mode := parity_mode;
end; {function z_renderer_type.Get_parity_mode}


{********************************************}
{ these functions set the vertex destination }
{********************************************}


procedure z_renderer_type.Begin_polygon;
begin
  Begin_z_polygon;
end; {procedure z_renderer_type.Begin_polygon}


procedure z_renderer_type.Begin_hole;
begin
  Begin_hole;
end; {procedure z_renderer_type.Begin_hole}


procedure z_renderer_type.Begin_line;
begin
  Begin_z_line;
end; {procedure z_renderer_type.Begin_line}


procedure z_renderer_type.Begin_points;
begin
  Begin_z_points;
end; {procedure z_renderer_type.Begin_points}


{**************************************************************}
{ these function set vertex properties before a vertex is sent }
{**************************************************************}


procedure z_renderer_type.Set_color(color: color_type);
begin
  Set_z_color(color);
end; {procedure z_renderer_type.Set_color}


procedure z_renderer_type.Set_texture(texture: vector_type);
begin
  Set_z_texture(texture);
end; {procedure z_renderer_type.Set_texture}


procedure z_renderer_type.Set_normal(normal: vector_type);
begin
  Set_z_normal(normal);
end; {procedure z_renderer_type.Set_normal}


procedure z_renderer_type.Set_vertex(vertex: vector_type);
begin
  Set_z_vertex(vertex);
end; {procedure z_renderer_type.Set_vertex}


procedure z_renderer_type.Set_vectors(u_axis, v_axis: vector_type);
begin
  Set_z_vectors(u_axis, v_axis);
end; {procedure z_renderer_type.Set_vectors}


{************************************************}
{ these functions store vertices in the pipeline }
{************************************************}


procedure z_renderer_type.Add_vertex(point: vector_type);
begin
  Add_z_vertex(point);
end; {procedure z_renderer_type.Add_vertex}


{******************}
{ drawing routines }
{******************}


procedure z_renderer_type.Draw_polygon;
begin
  case shading_mode of
    flat_shading_mode:
      Flat_shade_z_polygon(self);
    smooth_shading_mode:
      Gouraud_shade_z_polygon(self);
  end;
end; {procedure z_renderer_type.Draw_polygon}


procedure z_renderer_type.Draw_line;
begin
  case shading_mode of
    flat_shading_mode:
      Flat_shade_z_line(self);
    smooth_shading_mode:
      Gouraud_shade_z_line(self);
  end;
end; {procedure z_renderer_type.Draw_line}


procedure z_renderer_type.Draw_points;
begin
  Draw_z_points(self);
end; {procedure z_renderer_type.Draw_points}


end.

