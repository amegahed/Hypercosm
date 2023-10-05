unit xform_b_rep;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            xform_b_rep                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains miscillaneous routines to          }
{       transform the geometry of boundary reps.                }
{                                                               }
{       Because the b reps are very complex, we only            }
{       transform the geometry part and then rebind the         }
{       new geometry with the old topology.                     }
{                                                               }
{       Then, when we are done using the new geometry,          }
{       we free it up and rebind the old geometry back          }
{       to the topology. The old geometry is used as a          }
{       reference and we must remember to rebind it when        }
{       we are done using the new geometry.                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, trans, extents, colors, pixels, b_rep;


type
  {*******************************************************}
  {               auxilliary rendering data               }
  {*******************************************************}
  surface_visibility_type = (back_facing, silhouette_edge, front_facing);


  point_data_ptr_type = ^point_data_type;
  point_data_type = record
    {*********************************}
    { transformed point geometry data }
    {*********************************}
    trans_point: vector_type;
    global_point: vector_type;

    surface_visibility: surface_visibility_type;
    point_projected: boolean;

    pixel: pixel_type; {integer projection}
    vector: vector_type; {scalar projection}
    color: color_type; {edge color}
  end; {point_data_type}


  vertex_data_ptr_type = ^vertex_data_type;
  vertex_data_type = record
    {**********************************}
    { transformed vertex geometry data }
    {**********************************}
    trans_normal: vector_type;
    front_normal, back_normal: vector_type;
    trans_u_axis: vector_type;
    trans_v_axis: vector_type;

    {*******************************}
    { front and back colors of face }
    {*******************************}
    front_color, back_color: color_type;
  end; {vertex_data_type}


  edge_data_ptr_type = ^edge_data_type;
  edge_data_type = record
    {************************************************}
    { used to find the silhouette and the directions }
    { of the u and v vectors (the texture gradient). }
    {************************************************}
    surface_visibility: surface_visibility_type;
  end; {edge_data_type}


  face_data_ptr_type = ^face_data_type;
  face_data_type = record
    {********************************}
    { transformed face geometry data }
    {********************************}
    trans_normal: vector_type;

    {****************}
    { rendering data }
    {****************}
    color: color_type;
    front_facing: boolean;
  end; {face_data_type}


{****************************************}
{ routines to initialize auxilliary data }
{****************************************}
procedure Init_point_data(surface_ptr: surface_ptr_type);
procedure Init_vertex_data(surface_ptr: surface_ptr_type);
procedure Init_edge_data(surface_ptr: surface_ptr_type);
procedure Init_face_data(surface_ptr: surface_ptr_type);

{**************************************}
{ routines to retreive auxilliary data }
{**************************************}
function Get_point_data(point_index: integer): point_data_ptr_type;
function Get_vertex_data(vertex_index: integer): vertex_data_ptr_type;
function Get_edge_data(edge_index: integer): edge_data_ptr_type;
function Get_face_data(face_index: integer): face_data_ptr_type;

{*************************}
{ transformation routines }
{*************************}
procedure Transform_point_geometry(trans: trans_type);
procedure Transform_vertex_geometry(trans: trans_type);
procedure Transform_face_geometry(trans: trans_type);
procedure Transform_uv_axis_geometry(trans: trans_type);

{*********************}
{ projection routines }
{*********************}
procedure Project_points_to_pixels;
procedure Project_points_to_points;

{**********************************************}
{ miscillaneous geometric operations on b reps }
{**********************************************}
procedure Set_front_facing_flags(surface_ptr: surface_ptr_type);
procedure Find_face_visibility(surface_ptr: surface_ptr_type;
  trans: trans_type);
procedure Find_silhouette(surface_ptr: surface_ptr_type);


implementation
uses
  new_memory, coord_axes, bounds, geometry, topology, project;


const
  memory_alert = false;


var
  point_data_block_ptr: point_data_ptr_type;
  vertex_data_block_ptr: vertex_data_ptr_type;
  edge_data_block_ptr: edge_data_ptr_type;
  face_data_block_ptr: face_data_ptr_type;

  point_data_number: integer;
  vertex_data_number: integer;
  edge_data_number: integer;
  face_data_number: integer;

  point_number: integer;
  vertex_number: integer;
  edge_number: integer;
  face_number: integer;


procedure Allocate_point_data(points: integer);
var
  size: longint;
begin
  if (points > point_data_number) then
    begin
      if point_data_block_ptr <> nil then
        begin
          if memory_alert then
            writeln('freeing point data block');
          Free_ptr(ptr_type(point_data_block_ptr));
        end;

      size := sizeof(point_data_type) * points;
      if memory_alert then
        writeln('allocating new point data block');
      point_data_block_ptr := point_data_ptr_type(New_ptr(size));
      point_data_number := points;
    end;
  point_number := points;
end; {procedure Allocate_point_data}


procedure Allocate_vertex_data(vertices: integer);
var
  size: longint;
begin
  if (vertices > vertex_data_number) then
    begin
      if vertex_data_block_ptr <> nil then
        begin
          if memory_alert then
            writeln('freeing vertex data block');
          Free_ptr(ptr_type(vertex_data_block_ptr));
        end;

      size := sizeof(vertex_data_type) * vertices;
      if memory_alert then
        writeln('allocating new vertex data block');
      vertex_data_block_ptr := vertex_data_ptr_type(New_ptr(size));
      vertex_data_number := vertices;
    end;
  vertex_number := vertices;
end; {procedure Allocate_vertex_data}


procedure Allocate_edge_data(edges: integer);
var
  size: longint;
begin
  if (edges > edge_data_number) then
    begin
      if edge_data_block_ptr <> nil then
        begin
          if memory_alert then
            writeln('freeing edge data block');
          Free_ptr(ptr_type(edge_data_block_ptr));
        end;

      size := sizeof(edge_data_type) * edges;
      if memory_alert then
        writeln('allocating new edge data block');
      edge_data_block_ptr := edge_data_ptr_type(New_ptr(size));
      edge_data_number := edges;
    end;
  edge_number := edges;
end; {procedure Allocate_edge_data}


procedure Allocate_face_data(faces: integer);
var
  size: longint;
begin
  if (faces > face_data_number) then
    begin
      if face_data_block_ptr <> nil then
        begin
          if memory_alert then
            writeln('freeing face data block');
          Free_ptr(ptr_type(face_data_block_ptr));
        end;

      size := sizeof(face_data_type) * faces;
      if memory_alert then
        writeln('allocating new face data block');
      face_data_block_ptr := face_data_ptr_type(New_ptr(size));
      face_data_number := faces;
    end;
  face_number := faces;
end; {procedure Allocate_face_data}


{****************************************}
{ routines to initialize auxilliary data }
{****************************************}


procedure Init_point_data(surface_ptr: surface_ptr_type);
var
  topology_ptr: topology_ptr_type;
  geometry_ptr: geometry_ptr_type;
  point_geometry_ptr: point_geometry_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  topology_ptr := surface_ptr^.topology_ptr;
  geometry_ptr := surface_ptr^.geometry_ptr;

  Allocate_point_data(topology_ptr^.point_number);
  point_data_ptr := point_data_block_ptr;
  point_geometry_ptr := geometry_ptr^.point_geometry_ptr;

  while (point_geometry_ptr <> nil) do
    begin
      {***************************}
      { copy point to trans point }
      {***************************}
      point_data_ptr^.trans_point := point_geometry_ptr^.point;
      point_data_ptr^.surface_visibility := front_facing;
      point_data_ptr^.point_projected := false;

      point_geometry_ptr := point_geometry_ptr^.next;
      point_data_ptr := point_data_ptr_type(longint(point_data_ptr) +
        sizeof(point_data_type));
    end;
end; {procedure Init_point_data}


procedure Init_vertex_data(surface_ptr: surface_ptr_type);
var
  topology_ptr: topology_ptr_type;
  geometry_ptr: geometry_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
begin
  topology_ptr := surface_ptr^.topology_ptr;
  geometry_ptr := surface_ptr^.geometry_ptr;

  Allocate_vertex_data(topology_ptr^.vertex_number);
  vertex_data_ptr := vertex_data_block_ptr;
  vertex_geometry_ptr := geometry_ptr^.vertex_geometry_ptr;

  while (vertex_geometry_ptr <> nil) do
    begin
      {*****************************}
      { copy vertex to trans vertex }
      {*****************************}
      vertex_data_ptr^.trans_normal := vertex_geometry_ptr^.normal;

      {*******************************}
      { copy vectors to trans vectors }
      {*******************************}
      vertex_data_ptr^.trans_u_axis := vertex_geometry_ptr^.u_axis;
      vertex_data_ptr^.trans_v_axis := vertex_geometry_ptr^.v_axis;

      vertex_geometry_ptr := vertex_geometry_ptr^.next;
      vertex_data_ptr := vertex_data_ptr_type(longint(vertex_data_ptr) +
        sizeof(vertex_data_type));
    end;
end; {procedure Init_vertex_data}


procedure Init_edge_data(surface_ptr: surface_ptr_type);
var
  topology_ptr: topology_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  topology_ptr := surface_ptr^.topology_ptr;
  Allocate_edge_data(topology_ptr^.edge_number);
  edge_ptr := topology_ptr^.edge_ptr;
  edge_data_ptr := edge_data_block_ptr;

  while (edge_ptr <> nil) do
    begin
      {*************************}
      { copy edge to trans edge }
      {*************************}
      edge_data_ptr^.surface_visibility := front_facing;

      edge_ptr := edge_ptr^.next;
      edge_data_ptr := edge_data_ptr_type(longint(edge_data_ptr) +
        sizeof(edge_data_type));
    end;
end; {procedure Init_edge_data}


procedure Init_face_data(surface_ptr: surface_ptr_type);
var
  topology_ptr: topology_ptr_type;
  geometry_ptr: geometry_ptr_type;
  face_geometry_ptr: face_geometry_ptr_type;
  face_data_ptr: face_data_ptr_type;
begin
  topology_ptr := surface_ptr^.topology_ptr;
  geometry_ptr := surface_ptr^.geometry_ptr;

  Allocate_face_data(topology_ptr^.face_number);
  face_data_ptr := face_data_block_ptr;
  face_geometry_ptr := geometry_ptr^.face_geometry_ptr;

  while (face_geometry_ptr <> nil) do
    begin
      {*************************}
      { copy face to trans face }
      {*************************}
      face_data_ptr^.trans_normal := face_geometry_ptr^.normal;
      face_data_ptr^.front_facing := true;

      face_geometry_ptr := face_geometry_ptr^.next;
      face_data_ptr := face_data_ptr_type(longint(face_data_ptr) +
        sizeof(face_data_type));
    end;
end; {procedure Init_face_data}


{*************************}
{ transformation routines }
{*************************}


procedure Transform_point_geometry(trans: trans_type);
var
  counter: integer;
  point_data_ptr: point_data_ptr_type;
begin
  {******************}
  { transform points }
  {******************}
  point_data_ptr := point_data_block_ptr;
  for counter := 1 to point_number do
    begin
      Transform_point(point_data_ptr^.trans_point, trans);
      point_data_ptr := point_data_ptr_type(longint(point_data_ptr) +
        sizeof(point_data_type));
    end;
end; {procedure Transform_point_geometry}


procedure Transform_vertex_geometry(trans: trans_type);
var
  counter: integer;
  vertex_data_ptr: vertex_data_ptr_type;
begin
  {**************************}
  { transform vertex normals }
  {**************************}
  trans := Normal_trans(trans);
  vertex_data_ptr := vertex_data_block_ptr;
  for counter := 1 to vertex_number do
    begin
      Transform_vector(vertex_data_ptr^.trans_normal, trans);
      vertex_data_ptr^.trans_normal := Normalize(vertex_data_ptr^.trans_normal);
      vertex_data_ptr := vertex_data_ptr_type(longint(vertex_data_ptr) +
        sizeof(vertex_data_type));
    end;
end; {procedure Transform_vertex_geometry}


procedure Transform_face_geometry(trans: trans_type);
var
  counter: integer;
  face_data_ptr: face_data_ptr_type;
begin
  {************************}
  { transform face normals }
  {************************}
  trans := Normal_trans(trans);
  face_data_ptr := face_data_block_ptr;
  for counter := 1 to face_number do
    begin
      Transform_vector(face_data_ptr^.trans_normal, trans);
      face_data_ptr^.trans_normal := Normalize(face_data_ptr^.trans_normal);
      face_data_ptr := face_data_ptr_type(longint(face_data_ptr) +
        sizeof(face_data_type));
    end;
end; {procedure Transform_face_geometry}


procedure Transform_uv_axis_geometry(trans: trans_type);
var
  counter: integer;
  vertex_data_ptr: vertex_data_ptr_type;
begin
  {**********************************}
  { transform vertex texture vectors }
  {**********************************}
  trans := Normal_trans(trans);
  vertex_data_ptr := vertex_data_block_ptr;
  for counter := 1 to vertex_number do
    begin
      Transform_vector(vertex_data_ptr^.trans_u_axis, trans);
      Transform_vector(vertex_data_ptr^.trans_v_axis, trans);
      vertex_data_ptr := vertex_data_ptr_type(longint(vertex_data_ptr) +
        sizeof(vertex_data_type));
    end;
end; {procedure Transform_uv_axis_geometry}


{*********************}
{ projection routines }
{*********************}


procedure Project_points_to_pixels;
var
  counter: integer;
  point_data_ptr: point_data_ptr_type;
begin
  point_data_ptr := point_data_block_ptr;
  for counter := 1 to point_number do
    begin
      with point_data_ptr^ do
        point_data_ptr^.pixel :=
          Project_point_to_pixel(point_data_ptr^.trans_point);
      point_data_ptr := point_data_ptr_type(longint(point_data_ptr) +
        sizeof(point_data_type));
    end;
end; {procedure Project_points_to_pixels}


procedure Project_points_to_points;
var
  counter: integer;
  point_data_ptr: point_data_ptr_type;
begin
  point_data_ptr := point_data_block_ptr;
  for counter := 1 to point_number do
    begin
      with point_data_ptr^ do
        vector := Project_point_to_point(trans_point);
      point_data_ptr := point_data_ptr_type(longint(point_data_ptr) +
        sizeof(point_data_type));
    end;
end; {procedure Project_points_to_points}


{**************************************}
{ routines to retreive auxilliary data }
{**************************************}


function Get_point_data(point_index: integer): point_data_ptr_type;
var
  offset: longint;
begin
  offset := point_index * sizeof(point_data_type);
  Get_point_data := point_data_ptr_type(longint(point_data_block_ptr) + offset);
end; {function Get_point_data}


function Get_vertex_data(vertex_index: integer): vertex_data_ptr_type;
var
  offset: longint;
begin
  offset := vertex_index * sizeof(vertex_data_type);
  Get_vertex_data := vertex_data_ptr_type(longint(vertex_data_block_ptr) +
    offset);
end; {function Get_vertex_data}


function Get_edge_data(edge_index: integer): edge_data_ptr_type;
var
  offset: longint;
begin
  offset := edge_index * sizeof(edge_data_type);
  Get_edge_data := edge_data_ptr_type(longint(edge_data_block_ptr) + offset);
end; {function Get_edge_data}


function Get_face_data(face_index: integer): face_data_ptr_type;
var
  offset: longint;
begin
  offset := face_index * sizeof(face_data_type);
  Get_face_data := face_data_ptr_type(longint(face_data_block_ptr) + offset);
end; {function Get_face_data}


{**********************************************}
{ miscillaneous geometric operations on b reps }
{**********************************************}


procedure Set_front_facing_flags(surface_ptr: surface_ptr_type);
var
  face_ptr: face_ptr_type;
  face_data_ptr: face_data_ptr_type;
begin
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  while (face_ptr <> nil) do
    begin
      face_data_ptr := Get_face_data(face_ptr^.index);
      face_data_ptr^.front_facing := true;
      face_ptr := face_ptr^.next;
    end;
end; {procedure Set_front_facing_flags}


procedure Find_perspective_face_visibility(surface_ptr: surface_ptr_type;
  trans: trans_type);
var
  face_ptr: face_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_ptr: point_ptr_type;
  point, vector, normal: vector_type;
  local_eye: vector_type;
  coord_axes: coord_axes_type;
begin
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;

  {****************************************}
  { transform eye to local coords of b rep }
  {****************************************}
  local_eye := zero_vector;
  coord_axes := Trans_to_axes(trans);
  Transform_point_to_axes(local_eye, coord_axes);

  {**********************************}
  { if eye is inside bounding region }
  { then disable backface culling    }
  {**********************************}
  if not Point_in_extent_box(local_eye, unit_extent_box) then
    while (face_ptr <> nil) do
      begin
        point_ptr :=
          face_ptr^.cycle_ptr^.directed_edge_ptr^.edge_ptr^.point_ptr1;
        point := point_ptr^.point_geometry_ptr^.point;
        normal := face_ptr^.face_geometry_ptr^.normal;
        vector := Vector_difference(point, local_eye);
        face_data_ptr := Get_face_data(face_ptr^.index);
        face_data_ptr^.front_facing := (Dot_product(vector, normal) < 0);
        face_ptr := face_ptr^.next;
      end;
end; {procedure Find_perspective_face_visibility}


procedure Find_ortho_face_visibility(surface_ptr: surface_ptr_type;
  trans: trans_type);
var
  face_ptr: face_ptr_type;
  face_data_ptr: face_data_ptr_type;
  normal: vector_type;
  direction: vector_type;
  coord_axes: coord_axes_type;
begin
  {****************************************}
  { transform eye to local coords of b rep }
  {****************************************}
  direction := y_vector;
  coord_axes := Trans_to_axes(trans);
  Transform_vector_to_axes(direction, coord_axes);

  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  while (face_ptr <> nil) do
    begin
      {normal := Get_face_geometry(face_ptr^.index)^.normal;}
      normal := face_ptr^.face_geometry_ptr^.normal;

      face_data_ptr := Get_face_data(face_ptr^.index);
      face_data_ptr^.front_facing := (Dot_product(direction, normal) < 0);
      face_ptr := face_ptr^.next;
    end;
end; {procedure Find_ortho_face_visibility}


procedure Find_face_visibility(surface_ptr: surface_ptr_type;
  trans: trans_type);
begin
  if current_projection_ptr^.kind <> orthographic then
    Find_perspective_face_visibility(surface_ptr, trans)
  else
    Find_ortho_face_visibility(surface_ptr, trans);
end; {procedure Find_face_visibility}


procedure Find_silhouette(surface_ptr: surface_ptr_type);
var
  face_data_ptr1, face_data_ptr2: face_data_ptr_type;
  front_facing1, front_facing2: boolean;
  face_ref_ptr1, face_ref_ptr2: face_ref_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
begin
  {***********************}
  { find silhouette edges }
  {***********************}
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  edge_data_ptr := edge_data_block_ptr;

  while (edge_ptr <> nil) do
    begin
      face_ref_ptr1 := edge_ptr^.face_list;

      if (face_ref_ptr1 <> nil) then
        begin
          face_ref_ptr2 := face_ref_ptr1^.next;
          if (face_ref_ptr2 <> nil) then
            begin
              face_data_ptr1 := Get_face_data(face_ref_ptr1^.face_ptr^.index);
              face_data_ptr2 := Get_face_data(face_ref_ptr2^.face_ptr^.index);
              front_facing1 := face_data_ptr1^.front_facing;
              front_facing2 := face_data_ptr2^.front_facing;

              if front_facing1 <> front_facing2 then
                edge_data_ptr^.surface_visibility := silhouette_edge
              else if not front_facing1 then
                edge_data_ptr^.surface_visibility := back_facing;
            end;
        end;

      {**************************}
      { find silhouette vertices }
      {**************************}
      case edge_data_ptr^.surface_visibility of
        back_facing:
          begin
            point_data_ptr1 := Get_point_data(edge_ptr^.point_ptr1^.index);
            point_data_ptr2 := Get_point_data(edge_ptr^.point_ptr2^.index);
            if point_data_ptr1^.surface_visibility <> silhouette_edge then
              point_data_ptr1^.surface_visibility := back_facing;
            if point_data_ptr2^.surface_visibility <> silhouette_edge then
              point_data_ptr2^.surface_visibility := back_facing;
          end;
        silhouette_edge:
          begin
            point_data_ptr1 := Get_point_data(edge_ptr^.point_ptr1^.index);
            point_data_ptr2 := Get_point_data(edge_ptr^.point_ptr2^.index);
            point_data_ptr1^.surface_visibility := silhouette_edge;
            point_data_ptr2^.surface_visibility := silhouette_edge;
          end;
        front_facing:
          ; {default}
      end; {case}

      edge_data_ptr := edge_data_ptr_type(longint(edge_data_ptr) +
        sizeof(edge_data_type));
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Find_silhouette}


initialization
  point_data_number := 0;
  vertex_data_number := 0;
  edge_data_number := 0;
  face_data_number := 0;

  point_data_block_ptr := nil;
  vertex_data_block_ptr := nil;
  edge_data_block_ptr := nil;
  face_data_block_ptr := nil;
end.

