unit make_b_rep;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             make_b_rep                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This is a series of routines to aid construction        }
{       of boundary representations.                            }
{                                                               }
{       The routines use the geometry information provided      }
{       to infer the topological information about the          }
{       boundary representation.                                }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, geometry, topology, b_rep;


function Make_surface(kind: surface_kind_type;
  closure: surface_closure_type;
  shading: surface_shading_type): surface_ptr_type;

{*************************************}
{ routines for creating geometry only }
{*************************************}
function Make_geometry: geometry_ptr_type;
procedure Make_point_geometry(point: vector_type);
procedure Make_vertex_geometry(normal, texture: vector_type;
  u_axis, v_axis: vector_type);
procedure Make_face_geometry(normal: vector_type);

{*****************************************}
{ routines for creating the topology only }
{*****************************************}
function Make_topology: topology_ptr_type;
function Make_point_topology: point_ptr_type;
function Make_vertex_topology(point_ptr: point_ptr_type): vertex_ptr_type;
function Make_edge_topology(vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_kind: edge_kind_type;
  duplicate_edge_ptr: edge_ptr_type): edge_ptr_type;
procedure Make_face_topology;
procedure Make_directed_edge(edge_ptr: edge_ptr_type;
  orientation: boolean);
procedure Make_hole;

{*************************************************}
{ routines to copy various components of geometry }
{*************************************************}
procedure Copy_point_geometry(geometry_ptr1, geometry_ptr2: geometry_ptr_type);
procedure Copy_vertex_geometry(geometry_ptr1, geometry_ptr2: geometry_ptr_type);
procedure Copy_face_geometry(geometry_ptr1, geometry_ptr2: geometry_ptr_type);


implementation


var
  surface_ptr: surface_ptr_type;
  geometry_ptr: geometry_ptr_type;
  topology_ptr: topology_ptr_type;

  last_cycle_ptr: cycle_ptr_type;
  last_directed_edge_ptr: directed_edge_ptr_type;


function Make_surface(kind: surface_kind_type;
  closure: surface_closure_type;
  shading: surface_shading_type): surface_ptr_type;
begin
  surface_ptr := New_surface(kind, closure, shading);
  surface_ptr^.geometry_ptr := Make_geometry;
  surface_ptr^.topology_ptr := Make_topology;

  Make_surface := surface_ptr;
end; {function Make_surface}


function Make_geometry: geometry_ptr_type;
begin
  geometry_ptr := New_geometry;
  Make_geometry := geometry_ptr;
end; {function Make_geometry}


function Make_topology: topology_ptr_type;
begin
  topology_ptr := New_topology;
  Make_topology := topology_ptr;
end; {function Make_topology}


procedure Make_point_geometry(point: vector_type);
var
  point_geometry_ptr: point_geometry_ptr_type;
begin
  point_geometry_ptr := New_point_geometry;
  point_geometry_ptr^.point := point;

  {***********************************}
  { add to end of point geometry list }
  {***********************************}
  if (geometry_ptr^.point_geometry_ptr <> nil) then
    begin
      geometry_ptr^.last_point_geometry_ptr^.next := point_geometry_ptr;
      geometry_ptr^.last_point_geometry_ptr := point_geometry_ptr;
    end
  else
    begin
      geometry_ptr^.point_geometry_ptr := point_geometry_ptr;
      geometry_ptr^.last_point_geometry_ptr := point_geometry_ptr;
    end;
end; {procedure Make_point_geometry}


procedure Make_vertex_geometry(normal, texture: vector_type;
  u_axis, v_axis: vector_type);
var
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  vertex_geometry_ptr := New_vertex_geometry;
  vertex_geometry_ptr^.normal := normal;
  vertex_geometry_ptr^.texture := texture;
  vertex_geometry_ptr^.u_axis := u_axis;
  vertex_geometry_ptr^.v_axis := v_axis;

  {************************************}
  { add to end of vertex geometry list }
  {************************************}
  if (geometry_ptr^.vertex_geometry_ptr <> nil) then
    begin
      geometry_ptr^.last_vertex_geometry_ptr^.next := vertex_geometry_ptr;
      geometry_ptr^.last_vertex_geometry_ptr := vertex_geometry_ptr;
    end
  else
    begin
      geometry_ptr^.vertex_geometry_ptr := vertex_geometry_ptr;
      geometry_ptr^.last_vertex_geometry_ptr := vertex_geometry_ptr;
    end;
end; {Make_vertex_geometry}


procedure Make_face_geometry(normal: vector_type);
var
  face_geometry_ptr: face_geometry_ptr_type;
begin
  face_geometry_ptr := New_face_geometry;
  face_geometry_ptr^.normal := normal;

  {**********************************}
  { add to end of face geometry list }
  {**********************************}
  if (geometry_ptr^.face_geometry_ptr <> nil) then
    begin
      geometry_ptr^.last_face_geometry_ptr^.next := face_geometry_ptr;
      geometry_ptr^.last_face_geometry_ptr := face_geometry_ptr;
    end
  else
    begin
      geometry_ptr^.face_geometry_ptr := face_geometry_ptr;
      geometry_ptr^.last_face_geometry_ptr := face_geometry_ptr;
    end;
end; {procedure Make_face_geometry}


function Make_point_topology: point_ptr_type;
var
  point_ptr: point_ptr_type;
begin
  point_ptr := New_point;

  {************}
  { init point }
  {************}
  with point_ptr^ do
    begin
      real_point := false;
      pseudo_point := false;
      index := topology_ptr^.point_number;
    end;
  topology_ptr^.point_number := topology_ptr^.point_number + 1;

  {************************************}
  { add to tail of point topology list }
  {************************************}
  if (topology_ptr^.point_ptr <> nil) then
    begin
      topology_ptr^.last_point_ptr^.next := point_ptr;
      topology_ptr^.last_point_ptr := point_ptr;
    end
  else
    begin
      topology_ptr^.point_ptr := point_ptr;
      topology_ptr^.last_point_ptr := point_ptr;
    end;

  Make_point_topology := point_ptr;
end; {function Make_point_topology}


function Make_vertex_topology(point_ptr: point_ptr_type): vertex_ptr_type;
var
  vertex_ptr: vertex_ptr_type;
begin
  vertex_ptr := New_vertex;

  {*************}
  { init vertex }
  {*************}
  vertex_ptr^.point_ptr := point_ptr;
  vertex_ptr^.index := topology_ptr^.vertex_number;
  topology_ptr^.vertex_number := topology_ptr^.vertex_number + 1;

  {*************************************}
  { add to tail of vertex topology list }
  {*************************************}
  if (topology_ptr^.vertex_ptr <> nil) then
    begin
      topology_ptr^.last_vertex_ptr^.next := vertex_ptr;
      topology_ptr^.last_vertex_ptr := vertex_ptr;
    end
  else
    begin
      topology_ptr^.vertex_ptr := vertex_ptr;
      topology_ptr^.last_vertex_ptr := vertex_ptr;
    end;

  Make_vertex_topology := vertex_ptr;
end; {function Make_vertex_topology}


function Make_edge_topology(vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_kind: edge_kind_type;
  duplicate_edge_ptr: edge_ptr_type): edge_ptr_type;
var
  edge_ptr: edge_ptr_type;
  edge_ref_ptr: edge_ref_ptr_type;
begin
  edge_ptr := nil;

  if (vertex_ptr1 <> vertex_ptr2) then
    if (vertex_ptr1 <> nil) then
      if (vertex_ptr2 <> nil) then
        if (vertex_ptr1^.point_ptr <> vertex_ptr2^.point_ptr) then
          if (vertex_ptr1^.point_ptr <> nil) then
            if (vertex_ptr2^.point_ptr <> nil) then
              begin
                edge_ptr := New_edge;

                {***********}
                { init edge }
                {***********}
                edge_ptr^.point_ptr1 := vertex_ptr1^.point_ptr;
                edge_ptr^.point_ptr2 := vertex_ptr2^.point_ptr;
                edge_ptr^.vertex_ptr1 := vertex_ptr1;
                edge_ptr^.vertex_ptr2 := vertex_ptr2;
                edge_ptr^.edge_kind := edge_kind;
                edge_ptr^.duplicate_edge_ptr := duplicate_edge_ptr;
                edge_ptr^.index := topology_ptr^.edge_number;
                topology_ptr^.edge_number := topology_ptr^.edge_number + 1;

                if (edge_kind = real_edge) then
                  begin
                    vertex_ptr1^.point_ptr^.real_point := true;
                    vertex_ptr2^.point_ptr^.real_point := true;
                  end
                else if (edge_kind = pseudo_edge) then
                  begin
                    vertex_ptr1^.point_ptr^.pseudo_point := true;
                    vertex_ptr2^.point_ptr^.pseudo_point := true;
                  end;

                {***********************************}
                { add to tail of edge topology list }
                {***********************************}
                if (topology_ptr^.edge_ptr <> nil) then
                  begin
                    topology_ptr^.last_edge_ptr^.next := edge_ptr;
                    topology_ptr^.last_edge_ptr := edge_ptr;
                  end
                else
                  begin
                    topology_ptr^.edge_ptr := edge_ptr;
                    topology_ptr^.last_edge_ptr := edge_ptr;
                  end;

                {**************************************}
                { add edge list backpointers to points }
                {**************************************}
                if (edge_ptr^.edge_kind <> duplicate_edge) then
                  duplicate_edge_ptr := edge_ptr;

                edge_ref_ptr := New_edge_ref;
                edge_ref_ptr^.edge_ptr := duplicate_edge_ptr;
                edge_ref_ptr^.next := vertex_ptr1^.point_ptr^.edge_list;
                vertex_ptr1^.point_ptr^.edge_list := edge_ref_ptr;

                edge_ref_ptr := New_edge_ref;
                edge_ref_ptr^.edge_ptr := duplicate_edge_ptr;
                edge_ref_ptr^.next := vertex_ptr2^.point_ptr^.edge_list;
                vertex_ptr2^.point_ptr^.edge_list := edge_ref_ptr;

                topology_ptr^.edge_ref_number := topology_ptr^.edge_ref_number +
                  2;
              end;

  Make_edge_topology := edge_ptr;
end; {function Make_edge_topology}


procedure Check_vertex_edge_topology;
var
  vertex_ptr: vertex_ptr_type;
begin
  {**********************************************************}
  { Find out if all the vertices of the surface are on the   }
  { perimeter. If we can find any vertex which is neither a  }
  { real or a pseudo edge vertex, then the boundary contains }
  { contains vertices which may not be drawn. Otherwise, all }
  { the vertices of the boundary are always drawn. (default) }
  {**********************************************************}
  topology_ptr^.perimeter_vertices := true;
  vertex_ptr := topology_ptr^.vertex_ptr;
  while (vertex_ptr <> nil) do
    begin
      if (not vertex_ptr^.point_ptr^.real_point) and (not
        vertex_ptr^.point_ptr^.pseudo_point) then
        begin
          topology_ptr^.perimeter_vertices := false;
          vertex_ptr := nil;
        end
      else
        vertex_ptr := vertex_ptr^.next;
    end;
end; {procedure Check_vertex_edge_topology}


procedure Make_face_topology;
var
  face_ptr: face_ptr_type;
  cycle_ptr: cycle_ptr_type;
begin
  face_ptr := New_face;

  {***********}
  { init face }
  {***********}
  face_ptr^.index := topology_ptr^.face_number;
  topology_ptr^.face_number := topology_ptr^.face_number + 1;

  cycle_ptr := New_cycle;
  cycle_ptr^.face_ptr := face_ptr;
  face_ptr^.cycle_ptr := cycle_ptr;
  topology_ptr^.cycle_number := topology_ptr^.cycle_number + 1;

  last_cycle_ptr := cycle_ptr;
  last_directed_edge_ptr := nil;

  if (topology_ptr^.face_ptr <> nil) then
    begin
      topology_ptr^.last_face_ptr^.next := face_ptr;
      topology_ptr^.last_face_ptr := face_ptr;
    end
  else
    begin
      Check_vertex_edge_topology;
      topology_ptr^.face_ptr := face_ptr;
      topology_ptr^.last_face_ptr := face_ptr;
    end;
end; {procedure Make_face_topology}


procedure Make_face(normal: vector_type);
begin
  Make_face_geometry(normal);
  Make_face_topology;
end; {procedure Make_face}


procedure Make_hole;
var
  cycle_ptr: cycle_ptr_type;
begin
  cycle_ptr := New_cycle;
  cycle_ptr^.face_ptr := last_cycle_ptr^.face_ptr;
  last_directed_edge_ptr := nil;
  topology_ptr^.cycle_number := topology_ptr^.cycle_number + 1;

  {**********************************}
  { insert at tail of list of cycles }
  {**********************************}
  last_cycle_ptr^.next := cycle_ptr;
  last_cycle_ptr := cycle_ptr;
end; {procedure Make_hole}


procedure Make_directed_edge(edge_ptr: edge_ptr_type;
  orientation: boolean);
var
  new_edge_ptr: directed_edge_ptr_type;
  face_ref_ptr: face_ref_ptr_type;
begin
  if (edge_ptr <> nil) then
    begin
      new_edge_ptr := New_directed_edge;
      new_edge_ptr^.orientation := orientation;
      new_edge_ptr^.edge_ptr := edge_ptr;
      new_edge_ptr^.cycle_ptr := last_cycle_ptr;
      topology_ptr^.directed_edge_number := topology_ptr^.directed_edge_number +
        1;

      {******************************************}
      { insert at tail of list of directed edges }
      {******************************************}
      if (last_directed_edge_ptr <> nil) then
        begin
          last_directed_edge_ptr^.next := new_edge_ptr;
          last_directed_edge_ptr := new_edge_ptr;
        end
      else
        begin
          last_cycle_ptr^.directed_edge_ptr := new_edge_ptr;
          last_directed_edge_ptr := new_edge_ptr;
        end;

      {*******************************************}
      { add face reference to vertex1's face list }
      {*******************************************}
      if orientation then
        begin
          face_ref_ptr := New_face_ref;
          face_ref_ptr^.face_ptr := last_cycle_ptr^.face_ptr;
          face_ref_ptr^.next := edge_ptr^.vertex_ptr1^.face_list;
          edge_ptr^.vertex_ptr1^.face_list := face_ref_ptr;
        end
      else
        begin
          face_ref_ptr := New_face_ref;
          face_ref_ptr^.face_ptr := last_cycle_ptr^.face_ptr;
          face_ref_ptr^.next := edge_ptr^.vertex_ptr2^.face_list;
          edge_ptr^.vertex_ptr2^.face_list := face_ref_ptr;
        end;
      topology_ptr^.face_ref_number := topology_ptr^.face_ref_number + 1;

      {***************************************}
      { find edge referenced by directed edge }
      {***************************************}
      if (edge_ptr^.edge_kind = duplicate_edge) then
        edge_ptr := edge_ptr^.duplicate_edge_ptr;

      {****************************************}
      { add face reference to edge's face list }
      {****************************************}
      face_ref_ptr := New_face_ref;
      face_ref_ptr^.face_ptr := last_cycle_ptr^.face_ptr;
      face_ref_ptr^.next := edge_ptr^.face_list;
      edge_ptr^.face_list := face_ref_ptr;
      topology_ptr^.face_ref_number := topology_ptr^.face_ref_number + 1;
    end;
end; {procedure Make_directed_edge}


{*************************************************}
{ routines to copy various components of geometry }
{*************************************************}


procedure Copy_point_geometry(geometry_ptr1, geometry_ptr2: geometry_ptr_type);
var
  point_geometry_ptr: point_geometry_ptr_type;
  new_point_geometry_ptr: point_geometry_ptr_type;
begin
  point_geometry_ptr := geometry_ptr1^.point_geometry_ptr;
  while (point_geometry_ptr <> nil) do
    begin
      new_point_geometry_ptr := New_point_geometry;
      new_point_geometry_ptr^ := point_geometry_ptr^;
      new_point_geometry_ptr^.next := nil;

      {****************************************}
      { add point geometry to tail of new list }
      {****************************************}
      if geometry_ptr2^.point_geometry_ptr <> nil then
        begin
          geometry_ptr2^.last_point_geometry_ptr^.next :=
            new_point_geometry_ptr;
          geometry_ptr2^.last_point_geometry_ptr := new_point_geometry_ptr;
        end
      else
        begin
          geometry_ptr2^.point_geometry_ptr := new_point_geometry_ptr;
          geometry_ptr2^.last_point_geometry_ptr := new_point_geometry_ptr;
        end;
      point_geometry_ptr := point_geometry_ptr^.next;
    end; {while}
end; {procedure Copy_point_geometry}


procedure Copy_vertex_geometry(geometry_ptr1, geometry_ptr2: geometry_ptr_type);
var
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  new_vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  vertex_geometry_ptr := geometry_ptr1^.vertex_geometry_ptr;
  while (vertex_geometry_ptr <> nil) do
    begin
      new_vertex_geometry_ptr := New_vertex_geometry;
      new_vertex_geometry_ptr^ := vertex_geometry_ptr^;
      new_vertex_geometry_ptr^.next := nil;

      {*****************************************}
      { add vertex geometry to tail of new list }
      {*****************************************}
      if geometry_ptr2^.vertex_geometry_ptr <> nil then
        begin
          geometry_ptr2^.last_vertex_geometry_ptr^.next :=
            new_vertex_geometry_ptr;
          geometry_ptr2^.last_vertex_geometry_ptr := new_vertex_geometry_ptr;
        end
      else
        begin
          geometry_ptr2^.vertex_geometry_ptr := new_vertex_geometry_ptr;
          geometry_ptr2^.last_vertex_geometry_ptr := new_vertex_geometry_ptr;
        end;
      vertex_geometry_ptr := vertex_geometry_ptr^.next;
    end; {while}
end; {procedure Copy_vertex_geometry}


procedure Copy_face_geometry(geometry_ptr1, geometry_ptr2: geometry_ptr_type);
var
  face_geometry_ptr: face_geometry_ptr_type;
  new_face_geometry_ptr: face_geometry_ptr_type;
begin
  face_geometry_ptr := geometry_ptr1^.face_geometry_ptr;
  while (face_geometry_ptr <> nil) do
    begin
      new_face_geometry_ptr := New_face_geometry;
      new_face_geometry_ptr^ := face_geometry_ptr^;
      new_face_geometry_ptr^.next := nil;

      {***************************************}
      { add face geometry to tail of new list }
      {***************************************}
      if geometry_ptr2^.face_geometry_ptr <> nil then
        begin
          geometry_ptr2^.last_face_geometry_ptr^.next := new_face_geometry_ptr;
          geometry_ptr2^.last_face_geometry_ptr := new_face_geometry_ptr;
        end
      else
        begin
          geometry_ptr2^.face_geometry_ptr := new_face_geometry_ptr;
          geometry_ptr2^.last_face_geometry_ptr := new_face_geometry_ptr;
        end;
      face_geometry_ptr := face_geometry_ptr^.next;
    end; {while}
end; {procedure Copy_face_geometry}


initialization
  surface_ptr := nil;
  geometry_ptr := nil;
  topology_ptr := nil;

  last_cycle_ptr := nil;
  last_directed_edge_ptr := nil;
end.
