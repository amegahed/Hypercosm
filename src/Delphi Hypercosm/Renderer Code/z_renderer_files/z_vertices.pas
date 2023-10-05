unit z_vertices;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             z_vertices                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines for feeding polygonal     }
{       vertex data into the 3d 'pipeline'.                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, vectors2, colors, drawable;


type
  {*******************************************}
  { the internal types used in storing vertex }
  { and polygon data are exported so that the }
  { z clipping module has access to them.     }
  {*******************************************}
  z_vertex_ptr_type = ^z_vertex_type;
  z_vertex_type = record
    point: vector_type;

    {*****************************}
    { for Gouraud shaded polygons }
    {*****************************}
    color: color_type;

    {***********************}
    { for textured polygons }
    {***********************}
    texture: vector_type;

    {***************************}
    { for Phong shaded polygons }
    {***************************}
    normal: vector_type;
    vertex: vector_type;
    u_axis: vector_type;
    v_axis: vector_type;

    {*******************************}
    { fields used for triangulation }
    {*******************************}
    convex: boolean;
    direction: vector2_type;

    next: z_vertex_ptr_type;
  end;


  {***************************************************************}
  { polygon kind is used so that colors are not interpolated when }
  { scan converting flat polygons and textures and global coords  }
  { are not interpolated when scan converting gouraud polygons    }
  {***************************************************************}
  z_vertex_list_kind_type = (flat_z_kind, Gouraud_z_kind, Phong_z_kind);


  z_vertex_list_ptr_type = ^z_vertex_list_type;
  z_vertex_list_type = record
    kind: z_vertex_list_kind_type;
    textured: boolean;
    vertices: integer;
    color: color_type;
    first, last: z_vertex_ptr_type;
    orientation: boolean;
    next: z_vertex_list_ptr_type;
  end; {z_vertex_list_type}


  {********************************************}
  { a z vertex list can represent a polygon,   }
  { a line, a collection of points, or a hole. }
  {********************************************}
  z_polygon_ptr_type = z_vertex_list_ptr_type;
  z_line_ptr_type = z_vertex_list_ptr_type;
  z_point_ptr_type = z_vertex_list_ptr_type;
  z_hole_ptr_type = z_vertex_list_ptr_type;


{*****************************}
{ routines uses by z clipping }
{*****************************}
procedure Interpolate_z_vertex(var z_vertex: z_vertex_type;
  z_vertex_list_ptr: z_vertex_list_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  edge_vector: vector_type;
  t: real);

{*************************************}
{ routines to allocate z vertex lists }
{*************************************}
function New_z_vertex_list(kind: z_vertex_list_kind_type;
  color: color_type;
  textured: boolean): z_vertex_list_ptr_type;
function New_z_vertex: z_vertex_ptr_type;

{************************************}
{ routines to construct vertex lists }
{************************************}
procedure Add_new_z_vertex(z_vertex_list_ptr: z_vertex_list_ptr_type;
  z_vertex: z_vertex_type);
procedure Swap_z_vertex_lists(z_vertex_list_ptr1, z_vertex_list_ptr2:
  z_vertex_list_ptr_type);

{*******************************}
{ routines to copy vertex lists }
{*******************************}
function Copy_z_vertex_list(z_vertex_list_ptr: z_vertex_list_ptr_type):
  z_vertex_list_ptr_type;
function Copy_z_vertex(z_vertex_ptr: z_vertex_ptr_type): z_vertex_ptr_type;

{*******************************}
{ routines to free vertex lists }
{*******************************}
procedure Free_z_vertex_list(var z_vertex_list_ptr: z_vertex_list_ptr_type);
procedure Free_z_vertex_lists(var z_vertex_list_ptr: z_vertex_list_ptr_type);
procedure Free_z_vertex(var z_vertex_ptr: z_vertex_ptr_type);
procedure Free_z_vertices(var z_vertex_ptr: z_vertex_ptr_type);

{*********************}
{ diagnostic routines }
{*********************}
procedure Preview_z_vertex_list(drawable: drawable_type;
  z_vertex_list_ptr: z_vertex_list_ptr_type);
procedure Preview_z_vertex_lists(drawable: drawable_type;
  z_vertex_list_ptr: z_vertex_list_ptr_type);
procedure Write_z_vertex_list(z_vertex_list_ptr: z_vertex_list_ptr_type);
procedure Write_z_vertex_lists(z_vertex_list_ptr: z_vertex_list_ptr_type);


implementation
uses
  new_memory, constants, pixels;


const
  memory_alert = false;


var
  {***********************************}
  { variables for maintaining polygon }
  { and vertex free lists             }
  {***********************************}
  z_vertex_list_free_list: z_vertex_list_ptr_type;
  z_vertex_free_list: z_vertex_ptr_type;


{*****************************}
{ routines uses by z clipping }
{*****************************}


procedure Interpolate_z_vertex(var z_vertex: z_vertex_type;
  z_vertex_list_ptr: z_vertex_list_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  edge_vector: vector_type;
  t: real);
var
  edge_color: color_type;
  edge_normal, edge_texture, edge_vertex: vector_type;
  edge_u_axis, edge_v_axis: vector_type;
begin
  with z_vertex do
    begin
      {*****************************}
      { interpolate projected point }
      {*****************************}
      point := Vector_sum(z_vertex_ptr1^.point, Vector_scale(edge_vector, t));

      {****************************}
      { interpolate texture coords }
      {****************************}
      if (z_vertex_list_ptr^.textured) then
        begin
          edge_texture := Vector_difference(z_vertex_ptr2^.texture,
            z_vertex_ptr1^.texture);
          texture := Vector_sum(z_vertex_ptr1^.texture,
            Vector_scale(edge_texture, t));
        end;

      {*******************}
      { interpolate color }
      {*******************}
      case z_vertex_list_ptr^.kind of
        flat_z_kind:
          begin
            color := z_vertex_ptr1^.color;
          end;

        Gouraud_z_kind:
          begin
            edge_color := Contrast_color(z_vertex_ptr2^.color,
              z_vertex_ptr1^.color);
            color := Mix_color(z_vertex_ptr1^.color, Intensify_color(edge_color,
              t));
          end;

        Phong_z_kind:
          begin
            edge_normal := Vector_difference(z_vertex_ptr2^.normal,
              z_vertex_ptr1^.normal);
            normal := Vector_sum(z_vertex_ptr1^.normal,
              Vector_scale(edge_normal, t));
            edge_vertex := Vector_difference(z_vertex_ptr2^.vertex,
              z_vertex_ptr1^.vertex);
            vertex := Vector_sum(z_vertex_ptr1^.vertex,
              Vector_scale(edge_vertex, t));
            edge_u_axis := Vector_difference(z_vertex_ptr2^.u_axis,
              z_vertex_ptr1^.u_axis);
            u_axis := Vector_sum(z_vertex_ptr1^.u_axis,
              Vector_scale(edge_u_axis, t));
            edge_v_axis := Vector_difference(z_vertex_ptr2^.v_axis,
              z_vertex_ptr1^.v_axis);
            v_axis := Vector_sum(z_vertex_ptr1^.v_axis,
              Vector_scale(edge_v_axis, t));
          end;
      end; {case}

    end; {with}
end; {procedure Interpolate_z_vertex}


{*************************************}
{ routines to allocate z vertex lists }
{*************************************}


function New_z_vertex_list(kind: z_vertex_list_kind_type;
  color: color_type;
  textured: boolean): z_vertex_list_ptr_type;
var
  z_vertex_list_ptr: z_vertex_list_ptr_type;
begin
  {********************************}
  { get new polygon from free list }
  {********************************}
  if z_vertex_list_free_list <> nil then
    begin
      z_vertex_list_ptr := z_vertex_list_free_list;
      z_vertex_list_free_list := z_vertex_list_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new z vertex list');
      new(z_vertex_list_ptr);
    end;

  {**********************}
  { initialize z polygon }
  {**********************}
  z_vertex_list_ptr^.kind := kind;
  z_vertex_list_ptr^.color := color;
  z_vertex_list_ptr^.textured := textured;

  with z_vertex_list_ptr^ do
    begin
      orientation := false;
      vertices := 0;
      first := nil;
      last := nil;
      next := nil;
    end;

  New_z_vertex_list := z_vertex_list_ptr;
end; {function New_z_vertex_list}


function New_z_vertex: z_vertex_ptr_type;
var
  z_vertex_ptr: z_vertex_ptr_type;
begin
  {*******************************}
  { get new vertex from free list }
  {*******************************}
  if z_vertex_free_list <> nil then
    begin
      z_vertex_ptr := z_vertex_free_list;
      z_vertex_free_list := z_vertex_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new z vertex');
      new(z_vertex_ptr);
    end;

  New_z_vertex := z_vertex_ptr;
end; {function New_z_vertex}


{************************************}
{ routines to construct vertex lists }
{************************************}


procedure Add_new_z_vertex(z_vertex_list_ptr: z_vertex_list_ptr_type;
  z_vertex: z_vertex_type);
var
  z_vertex_ptr: z_vertex_ptr_type;
begin
  z_vertex_ptr := New_z_vertex;
  z_vertex_ptr^ := z_vertex;
  z_vertex_ptr^.next := nil;
  z_vertex_list_ptr^.vertices := z_vertex_list_ptr^.vertices + 1;

  if z_vertex_list_ptr^.last <> nil then
    begin
      z_vertex_list_ptr^.last^.next := z_vertex_ptr;
      z_vertex_list_ptr^.last := z_vertex_ptr;
    end
  else
    begin
      z_vertex_list_ptr^.first := z_vertex_ptr;
      z_vertex_list_ptr^.last := z_vertex_ptr;
    end;
end; {procedure Add_new_z_vertex}


procedure Swap_z_vertex_lists(z_vertex_list_ptr1, z_vertex_list_ptr2:
  z_vertex_list_ptr_type);
var
  next1, next2: z_vertex_list_ptr_type;
  z_vertex_list: z_vertex_list_type;
begin
  next1 := z_vertex_list_ptr1^.next;
  next2 := z_vertex_list_ptr2^.next;

  z_vertex_list := z_vertex_list_ptr1^;
  z_vertex_list_ptr1^ := z_vertex_list_ptr2^;
  z_vertex_list_ptr2^ := z_vertex_list;

  z_vertex_list_ptr1^.next := next1;
  z_vertex_list_ptr2^.next := next2;
end; {procedure Swap_z_vertex_lists}


{*******************************}
{ routines to copy vertex lists }
{*******************************}


function Copy_z_vertex_list(z_vertex_list_ptr: z_vertex_list_ptr_type):
  z_vertex_list_ptr_type;
var
  new_z_vertex_list_ptr: z_vertex_list_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
  follow: z_vertex_ptr_type;
begin
  new_z_vertex_list_ptr := New_z_vertex_list(z_vertex_list_ptr^.kind,
    z_vertex_list_ptr^.color, z_vertex_list_ptr^.textured);
  follow := z_vertex_list_ptr^.first;

  while (follow <> nil) do
    begin
      z_vertex_ptr := New_z_vertex;
      z_vertex_ptr^ := follow^;
      z_vertex_ptr^.next := nil;
      follow := follow^.next;

      {****************************}
      { add vertex to tail of list }
      {****************************}
      with new_z_vertex_list_ptr^ do
        if (first = nil) then
          begin
            first := z_vertex_ptr;
            last := z_vertex_ptr;
          end
        else
          begin
            last^.next := z_vertex_ptr;
            last := z_vertex_ptr;
          end;
    end;

  Copy_z_vertex_list := new_z_vertex_list_ptr;
end; {function Copy_z_vertex_list}


function Copy_z_vertex(z_vertex_ptr: z_vertex_ptr_type): z_vertex_ptr_type;
var
  new_vertex_ptr: z_vertex_ptr_type;
begin
  new_vertex_ptr := New_z_vertex;
  new_vertex_ptr^ := z_vertex_ptr^;
  new_vertex_ptr^.next := nil;
  Copy_z_vertex := new_vertex_ptr;
end; {function Copy_z_vertex}


{*******************************}
{ routines to free vertex lists }
{*******************************}


procedure Free_z_vertex_list(var z_vertex_list_ptr: z_vertex_list_ptr_type);
begin
  {***************************}
  { add vertices to free list }
  {***************************}
  if (z_vertex_list_ptr^.last <> nil) then
    begin
      z_vertex_list_ptr^.last^.next := z_vertex_free_list;
      z_vertex_free_list := z_vertex_list_ptr^.first;
    end;

  {********************************}
  { add z vertex list to free list }
  {********************************}
  z_vertex_list_ptr^.next := z_vertex_list_free_list;
  z_vertex_list_free_list := z_vertex_list_ptr;
  z_vertex_list_ptr := nil;
end; {procedure Free_z_vertex_list}


procedure Free_z_vertex_lists(var z_vertex_list_ptr: z_vertex_list_ptr_type);
var
  follow: z_vertex_list_ptr_type;
begin
  follow := z_vertex_list_ptr;
  while (follow <> nil) do
    begin
      z_vertex_list_ptr := follow;
      follow := follow^.next;
      Free_z_vertex_list(z_vertex_list_ptr);
    end;
end; {procedure  Free_z_vertex_lists}


procedure Free_z_vertex(var z_vertex_ptr: z_vertex_ptr_type);
begin
  {*************************}
  { add vertex to free list }
  {*************************}
  z_vertex_ptr^.next := z_vertex_free_list;
  z_vertex_free_list := z_vertex_ptr;
  z_vertex_ptr := nil;
end; {procedure Free_z_vertex}


procedure Free_z_vertices(var z_vertex_ptr: z_vertex_ptr_type);
var
  follow: z_vertex_ptr_type;
begin
  follow := z_vertex_ptr;
  while (follow <> nil) do
    begin
      z_vertex_ptr := follow;
      follow := follow^.next;
      Free_z_vertex(z_vertex_ptr);
    end;
end; {procedure Free_z_vertices}


{*********************}
{ diagnostic routines }
{*********************}


procedure Preview_z_vertex_list(drawable: drawable_type;
  z_vertex_list_ptr: z_vertex_list_ptr_type);
var
  z_vertex_ptr: z_vertex_ptr_type;
  pixel: pixel_type;
begin
  if (z_vertex_list_ptr <> nil) then
    if (z_vertex_list_ptr^.first <> nil) then
      begin
        {*************************}
        { draw outline of polygon }
        {*************************}
        z_vertex_ptr := z_vertex_list_ptr^.first;
        pixel.h := Trunc(z_vertex_ptr^.point.x);
        pixel.v := Trunc(z_vertex_ptr^.point.y);
        drawable.Move_to(pixel);

        z_vertex_ptr := z_vertex_ptr^.next;
        while (z_vertex_ptr <> nil) do
          begin
            pixel.h := Trunc(z_vertex_ptr^.point.x);
            pixel.v := Trunc(z_vertex_ptr^.point.y);
            drawable.Line_to(pixel);
            z_vertex_ptr := z_vertex_ptr^.next;
          end;

        z_vertex_ptr := z_vertex_list_ptr^.first;
        pixel.h := Trunc(z_vertex_ptr^.point.x);
        pixel.v := Trunc(z_vertex_ptr^.point.y);
        drawable.Line_to(pixel);
      end;
end; {procedure Preview_z_vertex_list}


procedure Preview_z_vertex_lists(drawable: drawable_type;
  z_vertex_list_ptr: z_vertex_list_ptr_type);
begin
  while (z_vertex_list_ptr <> nil) do
    begin
      Preview_z_vertex_list(drawable, z_vertex_list_ptr);
      z_vertex_list_ptr := z_vertex_list_ptr^.next;
    end;
end; {procedure Preview_z_vertex_lists}


procedure Write_z_vertex_list(z_vertex_list_ptr: z_vertex_list_ptr_type);
var
  z_vertex_ptr: z_vertex_ptr_type;
  counter: integer;
begin
  writeln('z_vertex_list = ');

  if (z_vertex_list_ptr <> nil) then
    begin
      z_vertex_ptr := z_vertex_list_ptr^.first;
      counter := 1;
      while (z_vertex_ptr <> nil) do
        begin
          write(counter: 1, ') ');
          with z_vertex_ptr^.color do
            writeln('color = ', r, g, b);

          if false then
            begin
              with z_vertex_ptr^.point do
                writeln('z_vertex = ', x, y);
              with z_vertex_ptr^.normal do
                writeln('normal = ', x, y, z);
              with z_vertex_ptr^.texture do
                writeln('texture = ', x, y, z);
              with z_vertex_ptr^.u_axis do
                writeln('u_axis = ', x, y, z);
              with z_vertex_ptr^.v_axis do
                writeln('v_axis = ', x, y, z);
            end;

          z_vertex_ptr := z_vertex_ptr^.next;
          counter := counter + 1;
        end;
    end;
end; {procedure Write_z_vertex_list}


procedure Write_z_vertex_lists(z_vertex_list_ptr: z_vertex_list_ptr_type);
begin
  while (z_vertex_list_ptr <> nil) do
    begin
      Write_z_vertex_list(z_vertex_list_ptr);
      z_vertex_list_ptr := z_vertex_list_ptr^.next;
    end;
end; {procedure Write_z_vertex_lists}


initialization
  z_vertex_list_free_list := nil;
  z_vertex_free_list := nil;
end.

