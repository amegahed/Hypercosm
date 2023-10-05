unit mesh_prims;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             mesh_prims                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The mesh_prims module builds the topology structures    }
{       for the primitive objects.                              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  topology, polygons;


procedure Free_faceted_topologies;

{********************}
{ quadric primitives }
{********************}
function Sphere_topology: topology_ptr_type;
function Cylinder_topology: topology_ptr_type;
function Paraboloid_topology: topology_ptr_type;
function Hyperboloid1_topology: topology_ptr_type;
function Sphere_sweep_topology: topology_ptr_type;
function Cylinder_sweep_topology: topology_ptr_type;
function Paraboloid_sweep_topology: topology_ptr_type;
function Hyperboloid1_sweep_topology: topology_ptr_type;

{*******************}
{ planar primitives }
{*******************}
function Plane_topology: topology_ptr_type;
function Disk_topology: topology_ptr_type;
function Ring_topology: topology_ptr_type;
function Triangle_topology: topology_ptr_type;
function Parallelogram_topology: topology_ptr_type;
function Polygon_topology(polygon_ptr: polygon_ptr_type): topology_ptr_type;
function Shaded_polygon_topology(shaded_polygon_ptr: shaded_polygon_ptr_type):
  topology_ptr_type;
function Disk_sweep_topology: topology_ptr_type;
function Ring_sweep_topology: topology_ptr_type;

{***********************}
{ non-planar primitives }
{***********************}
function Torus_topology: topology_ptr_type;
function Torus_u_sweep_topology: topology_ptr_type;
function Torus_v_sweep_topology: topology_ptr_type;
function Torus_uv_sweep_topology: topology_ptr_type;
function Block_topology: topology_ptr_type;

{************************}
{ non-surface primitives }
{************************}
function Point_topology(vertices: integer): topology_ptr_type;
function Line_topology(vertices: integer): topology_ptr_type;


{*******************************************************}
{                topological equivalence                }
{*******************************************************}
{       hyperboloid2s are topologically equal to        }
{       paraboloids.                                    }
{       cones are topologically equal to cylinders      }
{       in our representation because the apex must     }
{       have multiple points in order to shade          }
{       properly since the normal at the apex cannot    }
{       be represented by a single vector.              }
{*******************************************************}


implementation
uses
  new_memory, grid_prims, make_b_rep;


{*******************************************************}
{                  the mesh structure                   }
{*******************************************************}
{       A mesh data structure is used by many of the    }
{       primitives to form a b-rep data structure.      }
{       The idea is that many of the primitives         }
{       (esp. quadrics) can be represented by a mesh    }
{       but for different primitives, connectivity      }
{       is different. For example, a sphere has the     }
{       mesh connected top to bottom and left to        }
{       right whereas a cylinder is just left to        }
{        right connected. This routine handles this     }
{       because in the case that the top and bottom     }
{       are connected, then the bottom horizontal       }
{       edge pointers will point to the same edges      }
{       as the top edge pointers because the routine    }
{       that creates the edges first searches for       }
{       identical ones. The same holds for vertices.    }
{                                                       }
{       Grid data structure:       N = 7, M = 4         }
{       N x M vertices,                                 }
{       N x (M - 1) horizontal edges,                   }
{       (N - 1) x M vertical edges                      }
{                                                       }
{       *---> *---> *---> *---> *---> *---> *--||       }
{       |     |     |     |     |     |     |           }
{       v     v     v     v     v     v     v           }
{       *---> *---> *---> *---> *---> *---> *--||       }
{       |     |     |     |     |     |     |           }
{       v     v     v     v     v     v     v           }
{       *---> *---> *---> *---> *---> *---> *--||       }
{       |     |     |     |     |     |     |           }
{       v     v     v     v     v     v     v           }
{       *---> *---> *---> *---> *---> *---> *--||       }
{       |     |     |     |     |     |     |           }
{       _     _     _     _     _     _     _           }
{                                                       }
{*******************************************************}
const
  max_mesh_size = max_facets * 2;
  memory_alert = false;


type
  point_ptr_array_ptr_type = ^point_ptr_array_type;
  vertex_ptr_array_ptr_type = ^vertex_ptr_array_type;
  edge_ptr_array_ptr_type = ^edge_ptr_array_type;

  point_ptr_array_type = array[0..max_mesh_size, 0..max_mesh_size] of
    point_ptr_type;
  vertex_ptr_array_type = array[0..max_mesh_size, 0..max_mesh_size] of
    vertex_ptr_type;
  edge_ptr_array_type = array[0..max_mesh_size, 0..max_mesh_size] of
    edge_ptr_type;

  quad_mesh_ptr_type = ^quad_mesh_type;
  quad_mesh_type = record
    width, height: integer;

    point_ptr_array_ptr: point_ptr_array_ptr_type;
    vertex_ptr_array_ptr: vertex_ptr_array_ptr_type;

    h_edge_ptr_array_ptr: edge_ptr_array_ptr_type;
    v_edge_ptr_array_ptr: edge_ptr_array_ptr_type;
  end; {quad_mesh_type}


var
  quad_mesh_ptr: quad_mesh_ptr_type;
  verbose: boolean;

  {************************************}
  { topologies for complete primitives }
  {************************************}
  plane_topology_ptr: topology_ptr_type;
  triangle_topology_ptr: topology_ptr_type;
  parallelogram_topology_ptr: topology_ptr_type;
  block_topology_ptr: topology_ptr_type;
  disk_topology_ptr: topology_ptr_type;
  ring_topology_ptr: topology_ptr_type;
  sphere_topology_ptr: topology_ptr_type;
  cylinder_topology_ptr: topology_ptr_type;
  paraboloid_topology_ptr: topology_ptr_type;
  hyperboloid1_topology_ptr: topology_ptr_type;
  torus_topology_ptr: topology_ptr_type;

  {***********************************}
  { topologies for partial primitives }
  {***********************************}
  sphere_sweep_topology_ptr: topology_ptr_type;
  cylinder_sweep_topology_ptr: topology_ptr_type;
  paraboloid_sweep_topology_ptr: topology_ptr_type;
  hyperboloid1_sweep_topology_ptr: topology_ptr_type;
  disk_sweep_topology_ptr: topology_ptr_type;
  ring_sweep_topology_ptr: topology_ptr_type;
  torus_u_sweep_topology_ptr: topology_ptr_type;
  torus_v_sweep_topology_ptr: topology_ptr_type;
  torus_uv_sweep_topology_ptr: topology_ptr_type;


function New_quad_mesh: quad_mesh_ptr_type;
var
  quad_mesh_ptr: quad_mesh_ptr_type;
begin
  if memory_alert then
    writeln('allocating new quad mesh');
  new(quad_mesh_ptr);

  quad_mesh_ptr^.width := 0;
  quad_mesh_ptr^.height := 0;

  new(quad_mesh_ptr^.point_ptr_array_ptr);
  new(quad_mesh_ptr^.vertex_ptr_array_ptr);
  new(quad_mesh_ptr^.h_edge_ptr_array_ptr);
  new(quad_mesh_ptr^.v_edge_ptr_array_ptr);

  New_quad_mesh := quad_mesh_ptr;
end; {function New_quad_mesh}


procedure Dispose_quad_mesh(quad_mesh_ptr: quad_mesh_ptr_type);
begin
  Free_ptr(ptr_type(quad_mesh_ptr^.vertex_ptr_array_ptr));
  Free_ptr(ptr_type(quad_mesh_ptr^.h_edge_ptr_array_ptr));
  Free_ptr(ptr_type(quad_mesh_ptr^.v_edge_ptr_array_ptr));
  Free_ptr(ptr_type(quad_mesh_ptr));
end; {procedure Dispose_quad_mesh}


procedure Make_faces_from_mesh(quad_mesh_ptr: quad_mesh_ptr_type);
var
  width, height: integer;
begin
  {**************}
  { create faces }
  {**************}
  for height := 0 to quad_mesh_ptr^.height - 1 do
    for width := 0 to quad_mesh_ptr^.width - 1 do
      begin
        Make_face_topology;

        {*************************************}
        { make left, bottom, right, top edges }
        {*************************************}
        Make_directed_edge(quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height],
          true);
        Make_directed_edge(quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height +
          1], true);
        Make_directed_edge(quad_mesh_ptr^.v_edge_ptr_array_ptr^[width + 1,
          height], false);
        Make_directed_edge(quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height],
          false);
      end;
end; {procedure Make_faces_from_mesh}


procedure Make_mesh_point(width, height: integer);
begin
  quad_mesh_ptr^.point_ptr_array_ptr^[width, height] := Make_point_topology;
end; {procedure Make_mesh_point}


procedure Link_mesh_point(width1, height1: integer;
  width2, height2: integer);
var
  point_ptr: point_ptr_type;
begin
  point_ptr := quad_mesh_ptr^.point_ptr_array_ptr^[width2, height2];
  quad_mesh_ptr^.point_ptr_array_ptr^[width1, height1] := point_ptr;
end; {procedure Link_mesh_point}


procedure Make_mesh_vertex(width, height: integer);
var
  point_ptr: point_ptr_type;
begin
  point_ptr := quad_mesh_ptr^.point_ptr_array_ptr^[width, height];
  quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height] :=
    Make_vertex_topology(point_ptr);
end; {procedure Make_mesh_point}


procedure Link_mesh_vertex(width1, height1: integer;
  width2, height2: integer);
var
  vertex_ptr: vertex_ptr_type;
begin
  vertex_ptr := quad_mesh_ptr^.vertex_ptr_array_ptr^[width2, height2];
  quad_mesh_ptr^.vertex_ptr_array_ptr^[width1, height1] := vertex_ptr;
end; {procedure Link_mesh_point}


{********************}
{ quadric primitives }
{********************}


function Sphere_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (sphere_topology_ptr = nil) then
    begin
      if verbose then
        write('making sphere topology...');
      sphere_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := Get_facets;

      {*************}
      { make points }
      {*************}
      Make_mesh_point(0, 0);
      for width := 1 to quad_mesh_ptr^.width do
        Link_mesh_point(width, 0, 0, 0);
      for height := 1 to (quad_mesh_ptr^.height - 1) do
        begin
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            Make_mesh_point(width, height);
          Link_mesh_point(quad_mesh_ptr^.width, height, 0, height);
        end;
      Make_mesh_point(0, quad_mesh_ptr^.height);
      for width := 1 to quad_mesh_ptr^.width do
        Link_mesh_point(width, quad_mesh_ptr^.height, 0, quad_mesh_ptr^.height);

      {***************}
      { make vertices }
      {***************}
      for width := 0 to (quad_mesh_ptr^.width - 1) do
        Make_mesh_vertex(width, 0);
      Link_mesh_vertex(quad_mesh_ptr^.width, 0, 0, 0);
      for height := 1 to (quad_mesh_ptr^.height - 1) do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);
      for width := 0 to (quad_mesh_ptr^.width - 1) do
        Make_mesh_vertex(width, quad_mesh_ptr^.height);
      Link_mesh_vertex(quad_mesh_ptr^.width, quad_mesh_ptr^.height, 0,
        quad_mesh_ptr^.height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for width := 0 to quad_mesh_ptr^.width do
        quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, 0] := nil;
      for height := 1 to (quad_mesh_ptr^.height - 1) do
        begin
          if (height = quad_mesh_ptr^.height div 2) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;
      for width := 0 to quad_mesh_ptr^.width do
        quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, quad_mesh_ptr^.height] :=
          nil;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width = quad_mesh_ptr^.width) then
            edge_kind := duplicate_edge
          else if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          for height := 0 to (quad_mesh_ptr^.height - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height
                + 1];

              if (edge_kind = duplicate_edge) then
                edge_ptr := quad_mesh_ptr^.v_edge_ptr_array_ptr^[0, height]
              else
                edge_ptr := nil;

              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, edge_ptr);
              quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Sphere_topology := sphere_topology_ptr;
end; {function Sphere_topology}


function Sphere_sweep_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (sphere_sweep_topology_ptr = nil) then
    begin
      if verbose then
        write('making sphere sweep topology...');
      sphere_sweep_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := Get_facets;

      {*************}
      { make points }
      {*************}
      Make_mesh_point(0, 0);
      for width := 1 to quad_mesh_ptr^.width do
        Link_mesh_point(width, 0, 0, 0);
      for height := 1 to (quad_mesh_ptr^.height - 1) do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_point(width, height);
      Make_mesh_point(0, quad_mesh_ptr^.height);
      for width := 1 to quad_mesh_ptr^.width do
        Link_mesh_point(width, quad_mesh_ptr^.height, 0, quad_mesh_ptr^.height);

      {***************}
      { make vertices }
      {***************}
      for width := 0 to (quad_mesh_ptr^.width - 1) do
        Make_mesh_vertex(width, 0);
      Link_mesh_vertex(quad_mesh_ptr^.width, 0, 0, 0);
      for height := 1 to (quad_mesh_ptr^.height - 1) do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);
      for width := 0 to (quad_mesh_ptr^.width - 1) do
        Make_mesh_vertex(width, quad_mesh_ptr^.height);
      Link_mesh_vertex(quad_mesh_ptr^.width, quad_mesh_ptr^.height, 0,
        quad_mesh_ptr^.height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for width := 0 to quad_mesh_ptr^.width do
        quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, 0] := nil;
      for height := 1 to (quad_mesh_ptr^.height - 1) do
        begin
          if (height = quad_mesh_ptr^.height div 2) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;
      for width := 0 to quad_mesh_ptr^.width do
        quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, quad_mesh_ptr^.height] :=
          nil;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          if (width = 0) or (width = quad_mesh_ptr^.width) then
            edge_kind := real_edge;
          for height := 0 to (quad_mesh_ptr^.height - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height
                + 1];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Sphere_sweep_topology := sphere_sweep_topology_ptr;
end; {function Sphere_sweep_topology}


function Cylinder_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (cylinder_topology_ptr = nil) then
    begin
      if verbose then
        write('making cylinder topology...');
      cylinder_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := 1;

      {*************}
      { make points }
      {*************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            Make_mesh_point(width, height);
          Link_mesh_point(quad_mesh_ptr^.width, height, 0, height);
        end;

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                real_edge, nil);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width = quad_mesh_ptr^.width) then
            edge_kind := duplicate_edge
          else if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;

          if (edge_kind = duplicate_edge) then
            edge_ptr := quad_mesh_ptr^.v_edge_ptr_array_ptr^[0, 0]
          else
            edge_ptr := nil;

          vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 0];
          vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 1];
          edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2, edge_kind,
            edge_ptr);
          quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, 0] := edge_ptr;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Cylinder_topology := cylinder_topology_ptr;
end; {function Cylinder_topology}


function Cylinder_sweep_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (cylinder_sweep_topology_ptr = nil) then
    begin
      if verbose then
        write('making cylinder sweep topology...');
      cylinder_sweep_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := 1;

      {*************}
      { make points }
      {*************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_point(width, height);

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                real_edge, nil);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          if (width = 0) or (width = quad_mesh_ptr^.width) then
            edge_kind := real_edge;
          vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 0];
          vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 1];
          edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2, edge_kind,
            nil);
          quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, 0] := edge_ptr;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Cylinder_sweep_topology := cylinder_sweep_topology_ptr;
end; {function Cylinder_sweep_topology}


function Paraboloid_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (paraboloid_topology_ptr = nil) then
    begin
      if verbose then
        write('making paraboloid topology...');
      paraboloid_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := Get_facets;

      {*************}
      { make points }
      {*************}
      Make_mesh_point(0, 0);
      for width := 1 to quad_mesh_ptr^.width do
        Link_mesh_point(width, 0, 0, 0);
      for height := 1 to quad_mesh_ptr^.height do
        begin
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            Make_mesh_point(width, height);
          Link_mesh_point(quad_mesh_ptr^.width, height, 0, height);
        end;

      {***************}
      { make vertices }
      {***************}
      for width := 0 to (quad_mesh_ptr^.width - 1) do
        Make_mesh_vertex(width, 0);
      Link_mesh_vertex(quad_mesh_ptr^.width, 0, 0, 0);
      for height := 1 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for width := 0 to quad_mesh_ptr^.width do
        quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, 0] := nil;
      for height := 1 to quad_mesh_ptr^.height do
        begin
          if (height = quad_mesh_ptr^.height div 2) then
            edge_kind := pseudo_edge
          else if (height = quad_mesh_ptr^.height) then
            edge_kind := real_edge
          else
            edge_kind := fake_edge;
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width = quad_mesh_ptr^.width) then
            edge_kind := duplicate_edge
          else if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          for height := 0 to (quad_mesh_ptr^.height - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height
                + 1];

              if (edge_kind = duplicate_edge) then
                edge_ptr := quad_mesh_ptr^.v_edge_ptr_array_ptr^[0, height]
              else
                edge_ptr := nil;

              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, edge_ptr);
              quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Paraboloid_topology := paraboloid_topology_ptr;
end; {function Paraboloid_topology}


function Paraboloid_sweep_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (paraboloid_sweep_topology_ptr = nil) then
    begin
      if verbose then
        write('making paraboloid sweep topology...');
      paraboloid_sweep_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := Get_facets;

      {*************}
      { make points }
      {*************}
      Make_mesh_point(0, 0);
      for width := 1 to quad_mesh_ptr^.width do
        Link_mesh_point(width, 0, 0, 0);
      for height := 1 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_point(width, height);

      {***************}
      { make vertices }
      {***************}
      for width := 0 to (quad_mesh_ptr^.width - 1) do
        Make_mesh_vertex(width, 0);
      Link_mesh_vertex(quad_mesh_ptr^.width, 0, 0, 0);
      for height := 1 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          if (height = quad_mesh_ptr^.height div 2) then
            edge_kind := pseudo_edge
          else if (height = quad_mesh_ptr^.height) or (height = 0) then
            edge_kind := real_edge
          else
            edge_kind := fake_edge;
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          if (width = 0) or (width = quad_mesh_ptr^.width) then
            edge_kind := real_edge;
          for height := 0 to (quad_mesh_ptr^.height - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height
                + 1];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Paraboloid_sweep_topology := paraboloid_sweep_topology_ptr;
end; {function Paraboloid_sweep_topology}


function Hyperboloid1_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (hyperboloid1_topology_ptr = nil) then
    begin
      if verbose then
        write('making hyperboloid_topology...');
      hyperboloid1_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := Get_facets;

      {*************}
      { make points }
      {*************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            Make_mesh_point(width, height);
          Link_mesh_point(quad_mesh_ptr^.width, height, 0, height);
        end;

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          if (height = quad_mesh_ptr^.height div 2) then
            edge_kind := pseudo_edge
          else if (height mod quad_mesh_ptr^.height = 0) then
            edge_kind := real_edge
          else
            edge_kind := fake_edge;
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width = quad_mesh_ptr^.width) then
            edge_kind := duplicate_edge
          else if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          for height := 0 to (quad_mesh_ptr^.height - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height
                + 1];

              if (edge_kind = duplicate_edge) then
                edge_ptr := quad_mesh_ptr^.v_edge_ptr_array_ptr^[0, height]
              else
                edge_ptr := nil;

              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, edge_ptr);
              quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Hyperboloid1_topology := hyperboloid1_topology_ptr;
end; {function Hyperboloid1_topology}


function Hyperboloid1_sweep_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (hyperboloid1_sweep_topology_ptr = nil) then
    begin
      if verbose then
        write('making hyperboloid sweep topology...');
      hyperboloid1_sweep_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := Get_facets;

      {*************}
      { make points }
      {*************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_point(width, height);

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          if (height = quad_mesh_ptr^.height div 2) then
            edge_kind := pseudo_edge
          else if (height mod quad_mesh_ptr^.height = 0) then
            edge_kind := real_edge
          else
            edge_kind := fake_edge;
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          if (width = 0) or (width = quad_mesh_ptr^.width) then
            edge_kind := real_edge;
          for height := 0 to (quad_mesh_ptr^.height - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height
                + 1];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Hyperboloid1_sweep_topology := hyperboloid1_sweep_topology_ptr;
end; {function Hyperboloid1_sweep_topology}


{*******************}
{ planar primitives }
{*******************}


function Plane_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (plane_topology_ptr = nil) then
    begin
      if verbose then
        write('making plane topology...');
      plane_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := Get_facets * 2;

      {*************}
      { make points }
      {*************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_point(width, height);

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          if (height = 0) or (height = quad_mesh_ptr^.height) then
            edge_kind := real_edge
          else
            edge_kind := pseudo_edge;
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width = 0) or (width = quad_mesh_ptr^.width) then
            edge_kind := real_edge
          else
            edge_kind := pseudo_edge;
          for height := 0 to (quad_mesh_ptr^.height - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height
                + 1];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Plane_topology := plane_topology_ptr;
end; {function Plane_topology}


function Disk_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (disk_topology_ptr = nil) then
    begin
      if verbose then
        write('making disk topology...');
      disk_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := 1;

      {*************}
      { make points }
      {*************}
      Make_mesh_point(0, 0);
      for width := 1 to quad_mesh_ptr^.width do
        Link_mesh_point(width, 0, 0, 0);
      for width := 0 to (quad_mesh_ptr^.width - 1) do
        Make_mesh_point(width, 1);
      Link_mesh_point(quad_mesh_ptr^.width, 1, 0, 1);

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for width := 0 to (quad_mesh_ptr^.width - 1) do
        quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, 0] := nil;
      for width := 0 to (quad_mesh_ptr^.width - 1) do
        begin
          vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 1];
          vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1, 1];
          edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2, real_edge,
            nil);
          quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, 1] := edge_ptr;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width = quad_mesh_ptr^.width) then
            edge_kind := duplicate_edge
          else if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 0];
          vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 1];

          if (edge_kind = duplicate_edge) then
            edge_ptr := quad_mesh_ptr^.v_edge_ptr_array_ptr^[0, 0]
          else
            edge_ptr := nil;

          edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2, edge_kind,
            edge_ptr);
          quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, 0] := edge_ptr;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Disk_topology := disk_topology_ptr;
end; {function Disk_topology}


function Disk_sweep_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (disk_sweep_topology_ptr = nil) then
    begin
      if verbose then
        write('making disk sweep topology...');
      disk_sweep_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := 1;

      {*************}
      { make points }
      {*************}
      Make_mesh_point(0, 0);
      for width := 1 to quad_mesh_ptr^.width do
        Link_mesh_point(width, 0, 0, 0);
      for width := 0 to quad_mesh_ptr^.width do
        Make_mesh_point(width, 1);

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      edge_ptr := nil;
      for width := 0 to (quad_mesh_ptr^.width - 1) do
        quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, 0] := nil;
      for width := 0 to (quad_mesh_ptr^.width - 1) do
        begin
          vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 1];
          vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1, 1];
          edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2, real_edge,
            nil);
          quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, 1] := edge_ptr;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width = 0) or (width = quad_mesh_ptr^.width) then
            edge_kind := real_edge
          else if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 0];
          vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 1];
          edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2, edge_kind,
            edge_ptr);
          quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, 0] := edge_ptr;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Disk_sweep_topology := disk_sweep_topology_ptr;
end; {function Disk_sweep_topology}


function Ring_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (ring_topology_ptr = nil) then
    begin
      if verbose then
        write('making ring topology...');
      ring_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := 1;

      {*************}
      { make points }
      {*************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            Make_mesh_point(width, height);
          Link_mesh_point(quad_mesh_ptr^.width, height, 0, height);
        end;

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to (quad_mesh_ptr^.width - 1) do
          begin
            vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height];
            vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
              height];
            edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2, real_edge,
              nil);
            quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
          end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width = quad_mesh_ptr^.width) then
            edge_kind := duplicate_edge
          else if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;

          if (edge_kind = duplicate_edge) then
            edge_ptr := quad_mesh_ptr^.v_edge_ptr_array_ptr^[0, 0]
          else
            edge_ptr := nil;

          vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 0];
          vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 1];
          edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2, edge_kind,
            edge_ptr);
          quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, 0] := edge_ptr;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Ring_topology := ring_topology_ptr;
end; {function Ring_topology}


function Ring_sweep_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (ring_sweep_topology_ptr = nil) then
    begin
      if verbose then
        write('making ring sweep topology...');
      ring_sweep_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := 1;

      {*************}
      { make points }
      {*************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          for width := 0 to quad_mesh_ptr^.width do
            Make_mesh_point(width, height);
        end;

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to (quad_mesh_ptr^.width - 1) do
          begin
            vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height];
            vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
              height];
            edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2, real_edge,
              nil);
            quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
          end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width = 0) or (width = quad_mesh_ptr^.width) then
            edge_kind := real_edge
          else if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 0];
          vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, 1];
          edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2, edge_kind,
            nil);
          quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, 0] := edge_ptr;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Ring_sweep_topology := ring_sweep_topology_ptr;
end; {function Ring_sweep_topology}


function Triangle_topology: topology_ptr_type;
var
  counter: integer;
  point_ptr: array[1..3] of point_ptr_type;
  vertex_ptr: array[1..3] of vertex_ptr_type;
  edge_ptr: array[1..3] of edge_ptr_type;
begin
  if (triangle_topology_ptr = nil) then
    begin
      if verbose then
        write('making triangle topology...');
      triangle_topology_ptr := Make_topology;

      {*************}
      { make points }
      {*************}
      for counter := 1 to 3 do
        point_ptr[counter] := Make_point_topology;

      {***************}
      { make vertices }
      {***************}
      for counter := 1 to 3 do
        vertex_ptr[counter] := Make_vertex_topology(point_ptr[counter]);

      {************}
      { make edges }
      {************}
      edge_ptr[1] := Make_edge_topology(vertex_ptr[1], vertex_ptr[2], real_edge,
        nil);
      edge_ptr[2] := Make_edge_topology(vertex_ptr[2], vertex_ptr[3], real_edge,
        nil);
      edge_ptr[3] := Make_edge_topology(vertex_ptr[3], vertex_ptr[1], real_edge,
        nil);

      {***********}
      { make face }
      {***********}
      Make_face_topology;
      Make_directed_edge(edge_ptr[1], true);
      Make_directed_edge(edge_ptr[2], true);
      Make_directed_edge(edge_ptr[3], true);
      if verbose then
        writeln('done.');
    end;

  Triangle_topology := triangle_topology_ptr;
end; {function Triangle_topology}


function Parallelogram_topology: topology_ptr_type;
var
  counter: integer;
  point_ptr: array[1..4] of point_ptr_type;
  vertex_ptr: array[1..4] of vertex_ptr_type;
  edge_ptr: array[1..4] of edge_ptr_type;
begin
  if (parallelogram_topology_ptr = nil) then
    begin
      if verbose then
        write('making parallelogram topology...');
      parallelogram_topology_ptr := Make_topology;

      {*************}
      { make points }
      {*************}
      for counter := 1 to 4 do
        point_ptr[counter] := Make_point_topology;

      {***************}
      { make vertices }
      {***************}
      for counter := 1 to 4 do
        vertex_ptr[counter] := Make_vertex_topology(point_ptr[counter]);

      {************}
      { make edges }
      {************}
      edge_ptr[1] := Make_edge_topology(vertex_ptr[1], vertex_ptr[2], real_edge,
        nil);
      edge_ptr[2] := Make_edge_topology(vertex_ptr[2], vertex_ptr[3], real_edge,
        nil);
      edge_ptr[3] := Make_edge_topology(vertex_ptr[3], vertex_ptr[4], real_edge,
        nil);
      edge_ptr[4] := Make_edge_topology(vertex_ptr[4], vertex_ptr[1], real_edge,
        nil);

      {************}
      { make faces }
      {************}
      Make_face_topology;
      Make_directed_edge(edge_ptr[1], true);
      Make_directed_edge(edge_ptr[2], true);
      Make_directed_edge(edge_ptr[3], true);
      Make_directed_edge(edge_ptr[4], true);
      if verbose then
        writeln('done.');
    end;

  Parallelogram_topology := parallelogram_topology_ptr;
end; {function Parallelogram_topology}


function Polygon_topology(polygon_ptr: polygon_ptr_type): topology_ptr_type;
var
  topology_ptr: topology_ptr_type;
  point_ptr: point_ptr_type;
  vertex_ptr, first_vertex_ptr: vertex_ptr_type;
  edge_ptr, first_edge_ptr: edge_ptr_type;
  counter: integer;
begin
  if verbose then
    write('making polygon topology...');
  topology_ptr := Make_topology;

  while (polygon_ptr <> nil) do
    begin
      {**************************}
      { make points and vertices }
      {**************************}
      first_vertex_ptr := nil;
      for counter := 1 to polygon_ptr^.vertices do
        begin
          point_ptr := Make_point_topology;
          vertex_ptr := Make_vertex_topology(point_ptr);
          if counter = 1 then
            first_vertex_ptr := vertex_ptr;
        end;

      {************}
      { make edges }
      {************}
      vertex_ptr := first_vertex_ptr;
      first_edge_ptr := nil;
      while (vertex_ptr^.next <> nil) do
        begin
          edge_ptr := Make_edge_topology(vertex_ptr, vertex_ptr^.next,
            real_edge, nil);
          vertex_ptr := vertex_ptr^.next;
          if (first_edge_ptr = nil) then
            first_edge_ptr := edge_ptr;
        end;
      Make_edge_topology(vertex_ptr, first_vertex_ptr, real_edge, nil);

      {************}
      { make faces }
      {************}
      if (topology_ptr^.face_ptr = nil) then
        Make_face_topology;

      edge_ptr := first_edge_ptr;
      while (edge_ptr <> nil) do
        begin
          Make_directed_edge(edge_ptr, true);
          edge_ptr := edge_ptr^.next;
        end;

      if (polygon_ptr^.next <> nil) then
        Make_hole;
      polygon_ptr := polygon_ptr^.next;
    end;

  if verbose then
    writeln('done.');
  Polygon_topology := topology_ptr;
end; {function Polygon_topology}


function Shaded_polygon_topology(shaded_polygon_ptr: shaded_polygon_ptr_type):
  topology_ptr_type;
var
  topology_ptr: topology_ptr_type;
  point_ptr: point_ptr_type;
  vertex_ptr, first_vertex_ptr: vertex_ptr_type;
  edge_ptr, first_edge_ptr: edge_ptr_type;
  counter: integer;
begin
  if verbose then
    write('making shaded polygon topology...');
  topology_ptr := Make_topology;

  while (shaded_polygon_ptr <> nil) do
    begin
      {**************************}
      { make points and vertices }
      {**************************}
      first_vertex_ptr := nil;
      for counter := 1 to shaded_polygon_ptr^.vertices do
        begin
          point_ptr := Make_point_topology;
          vertex_ptr := Make_vertex_topology(point_ptr);
          if counter = 1 then
            first_vertex_ptr := vertex_ptr;
        end;

      {************}
      { make edges }
      {************}
      vertex_ptr := first_vertex_ptr;
      first_edge_ptr := nil;
      while (vertex_ptr^.next <> nil) do
        begin
          edge_ptr := Make_edge_topology(vertex_ptr, vertex_ptr^.next,
            real_edge, nil);
          vertex_ptr := vertex_ptr^.next;
          if (first_edge_ptr = nil) then
            first_edge_ptr := edge_ptr;
        end;
      Make_edge_topology(vertex_ptr, first_vertex_ptr, real_edge, nil);

      {************}
      { make faces }
      {************}
      if (topology_ptr^.face_ptr = nil) then
        Make_face_topology;

      edge_ptr := first_edge_ptr;
      while (edge_ptr <> nil) do
        begin
          Make_directed_edge(edge_ptr, true);
          edge_ptr := edge_ptr^.next;
        end;

      if (shaded_polygon_ptr^.next <> nil) then
        Make_hole;
      shaded_polygon_ptr := shaded_polygon_ptr^.next;
    end;

  if verbose then
    writeln('done.');
  Shaded_polygon_topology := topology_ptr;
end; {function Shaded_polygon_topology}


function N_gon_topology(vertices: integer): topology_ptr_type;
var
  topology_ptr: topology_ptr_type;
  point_ptr: point_ptr_type;
  vertex_ptr: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  counter: integer;
begin
  if verbose then
    write('making n gon topology...');
  topology_ptr := Make_topology;

  {**************************}
  { make points and vertices }
  {**************************}
  for counter := 1 to vertices do
    begin
      point_ptr := Make_point_topology;
      Make_vertex_topology(point_ptr);
    end;

  {************}
  { make edges }
  {************}
  vertex_ptr := topology_ptr^.vertex_ptr;
  while (vertex_ptr^.next <> nil) do
    begin
      Make_edge_topology(vertex_ptr, vertex_ptr^.next, real_edge, nil);
      vertex_ptr := vertex_ptr^.next;
    end;
  Make_edge_topology(vertex_ptr, topology_ptr^.vertex_ptr, real_edge, nil);

  {************}
  { make faces }
  {************}
  Make_face_topology;
  edge_ptr := topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      Make_directed_edge(edge_ptr, true);
      edge_ptr := edge_ptr^.next;
    end;

  if verbose then
    writeln('done.');
  N_gon_topology := topology_ptr;
end; {function N_gon_topology}


{***********************}
{ non_planar primitives }
{***********************}


function Torus_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (torus_topology_ptr = nil) then
    begin
      if verbose then
        write('making torus topology...');
      torus_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := Get_facets * 2;

      {*************}
      { make points }
      {*************}
      for height := 0 to (quad_mesh_ptr^.height - 1) do
        begin
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            Make_mesh_point(width, height);
          Link_mesh_point(quad_mesh_ptr^.width, height, 0, height);
        end;
      for width := 0 to quad_mesh_ptr^.width do
        Link_mesh_point(width, quad_mesh_ptr^.height, width, 0);

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          if (height = quad_mesh_ptr^.height) then
            edge_kind := duplicate_edge
          else if (height * 4 mod quad_mesh_ptr^.height = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];

              if (edge_kind = duplicate_edge) then
                edge_ptr := quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, 0]
              else
                edge_ptr := nil;

              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, edge_ptr);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width = quad_mesh_ptr^.width) then
            edge_kind := duplicate_edge
          else if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          for height := 0 to (quad_mesh_ptr^.height - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height
                + 1];

              if (edge_kind = duplicate_edge) then
                edge_ptr := quad_mesh_ptr^.v_edge_ptr_array_ptr^[0, height]
              else
                edge_ptr := nil;

              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, edge_ptr);
              quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Torus_topology := torus_topology_ptr;
end; {function Torus_topology}


function Torus_u_sweep_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (torus_u_sweep_topology_ptr = nil) then
    begin
      if verbose then
        write('making torus u sweep topology...');
      torus_u_sweep_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := Get_facets * 2;

      {*************}
      { make points }
      {*************}
      for height := 0 to (quad_mesh_ptr^.height - 1) do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_point(width, height);
      for width := 0 to quad_mesh_ptr^.width do
        Link_mesh_point(width, quad_mesh_ptr^.height, width, 0);

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          if (height = quad_mesh_ptr^.height) then
            edge_kind := duplicate_edge
          else if (height * 4 mod quad_mesh_ptr^.height = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];

              if (edge_kind = duplicate_edge) then
                edge_ptr := quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, 0]
              else
                edge_ptr := nil;

              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, edge_ptr);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          if (width = 0) or (width = quad_mesh_ptr^.width) then
            edge_kind := real_edge;
          for height := 0 to (quad_mesh_ptr^.height - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height
                + 1];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Torus_u_sweep_topology := torus_u_sweep_topology_ptr;
end; {function Torus_u_sweep_topology}


function Torus_v_sweep_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (torus_v_sweep_topology_ptr = nil) then
    begin
      if verbose then
        write('making torus v sweep topology...');
      torus_v_sweep_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := Get_facets * 2;

      {*************}
      { make points }
      {*************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to (quad_mesh_ptr^.width - 1) do
          begin
            Make_mesh_point(width, height);
            Link_mesh_point(quad_mesh_ptr^.width, height, 0, height);
          end;

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          if (height * 4 mod quad_mesh_ptr^.height = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          if (height = 0) or (height = quad_mesh_ptr^.height) then
            edge_kind := real_edge;
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width = quad_mesh_ptr^.width) then
            edge_kind := duplicate_edge
          else if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          for height := 0 to (quad_mesh_ptr^.height - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height
                + 1];

              if (edge_kind = duplicate_edge) then
                edge_ptr := quad_mesh_ptr^.v_edge_ptr_array_ptr^[0, height]
              else
                edge_ptr := nil;

              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, edge_ptr);
              quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Torus_v_sweep_topology := torus_v_sweep_topology_ptr;
end; {function Torus_v_sweep_topology}


function Torus_uv_sweep_topology: topology_ptr_type;
var
  width, height: integer;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  edge_kind: edge_kind_type;
begin
  if (torus_uv_sweep_topology_ptr = nil) then
    begin
      if verbose then
        write('making torus uv sweep topology...');
      torus_uv_sweep_topology_ptr := Make_topology;

      quad_mesh_ptr^.width := Get_facets * 2;
      quad_mesh_ptr^.height := Get_facets * 2;

      {*************}
      { make points }
      {*************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_point(width, height);

      {***************}
      { make vertices }
      {***************}
      for height := 0 to quad_mesh_ptr^.height do
        for width := 0 to quad_mesh_ptr^.width do
          Make_mesh_vertex(width, height);

      {***********************}
      { make horizontal edges }
      {***********************}
      for height := 0 to quad_mesh_ptr^.height do
        begin
          if (height * 4 mod quad_mesh_ptr^.height = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          if (height = 0) or (height = quad_mesh_ptr^.height) then
            edge_kind := real_edge;
          for width := 0 to (quad_mesh_ptr^.width - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width + 1,
                height];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.h_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {*********************}
      { make vertical edges }
      {*********************}
      for width := 0 to quad_mesh_ptr^.width do
        begin
          if (width * 4 mod quad_mesh_ptr^.width = 0) then
            edge_kind := pseudo_edge
          else
            edge_kind := fake_edge;
          if (width = 0) or (width = quad_mesh_ptr^.width) then
            edge_kind := real_edge;
          for height := 0 to (quad_mesh_ptr^.height - 1) do
            begin
              vertex_ptr1 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width,
                height];
              vertex_ptr2 := quad_mesh_ptr^.vertex_ptr_array_ptr^[width, height
                + 1];
              edge_ptr := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              quad_mesh_ptr^.v_edge_ptr_array_ptr^[width, height] := edge_ptr;
            end;
        end;

      {************}
      { make faces }
      {************}
      Make_faces_from_mesh(quad_mesh_ptr);
      if verbose then
        writeln('done.');
    end;

  Torus_uv_sweep_topology := torus_uv_sweep_topology_ptr;
end; {function Torus_uv_sweep_topology}


function Block_topology: topology_ptr_type;
var
  counter: integer;
  point_ptr: array[1..8] of point_ptr_type;
  vertex_ptr: array[1..24] of vertex_ptr_type;
  edge_ptr: array[1..12] of edge_ptr_type;
  face_edge_ptr: array[1..4] of edge_ptr_type;
begin
  if (block_topology_ptr = nil) then
    begin
      if verbose then
        write('making block topology...');
      block_topology_ptr := Make_topology;

      {*************}
      { make points }
      {*************}
      for counter := 1 to 8 do
        point_ptr[counter] := Make_point_topology;

      {*************************}
      { make left face vertices }
      {*************************}
      vertex_ptr[1] := Make_vertex_topology(point_ptr[1]);
      vertex_ptr[2] := Make_vertex_topology(point_ptr[5]);
      vertex_ptr[3] := Make_vertex_topology(point_ptr[8]);
      vertex_ptr[4] := Make_vertex_topology(point_ptr[4]);

      {**************************}
      { make right face vertices }
      {**************************}
      vertex_ptr[5] := Make_vertex_topology(point_ptr[3]);
      vertex_ptr[6] := Make_vertex_topology(point_ptr[7]);
      vertex_ptr[7] := Make_vertex_topology(point_ptr[6]);
      vertex_ptr[8] := Make_vertex_topology(point_ptr[2]);

      {**************************}
      { make front face vertices }
      {**************************}
      vertex_ptr[9] := Make_vertex_topology(point_ptr[2]);
      vertex_ptr[10] := Make_vertex_topology(point_ptr[6]);
      vertex_ptr[11] := Make_vertex_topology(point_ptr[5]);
      vertex_ptr[12] := Make_vertex_topology(point_ptr[1]);

      {*************************}
      { make back face vertices }
      {*************************}
      vertex_ptr[13] := Make_vertex_topology(point_ptr[4]);
      vertex_ptr[14] := Make_vertex_topology(point_ptr[8]);
      vertex_ptr[15] := Make_vertex_topology(point_ptr[7]);
      vertex_ptr[16] := Make_vertex_topology(point_ptr[3]);

      {***************************}
      { make bottom face vertices }
      {***************************}
      vertex_ptr[17] := Make_vertex_topology(point_ptr[4]);
      vertex_ptr[18] := Make_vertex_topology(point_ptr[3]);
      vertex_ptr[19] := Make_vertex_topology(point_ptr[2]);
      vertex_ptr[20] := Make_vertex_topology(point_ptr[1]);

      {************************}
      { make top face vertices }
      {************************}
      vertex_ptr[21] := Make_vertex_topology(point_ptr[5]);
      vertex_ptr[22] := Make_vertex_topology(point_ptr[6]);
      vertex_ptr[23] := Make_vertex_topology(point_ptr[7]);
      vertex_ptr[24] := Make_vertex_topology(point_ptr[8]);

      {*******************}
      { make bottom edges }
      {*******************}
      edge_ptr[1] := Make_edge_topology(vertex_ptr[17], vertex_ptr[18],
        real_edge, nil);
      edge_ptr[2] := Make_edge_topology(vertex_ptr[18], vertex_ptr[19],
        real_edge, nil);
      edge_ptr[3] := Make_edge_topology(vertex_ptr[19], vertex_ptr[20],
        real_edge, nil);
      edge_ptr[4] := Make_edge_topology(vertex_ptr[20], vertex_ptr[17],
        real_edge, nil);

      {****************}
      { make top edges }
      {****************}
      edge_ptr[5] := Make_edge_topology(vertex_ptr[21], vertex_ptr[22],
        real_edge, nil);
      edge_ptr[6] := Make_edge_topology(vertex_ptr[22], vertex_ptr[23],
        real_edge, nil);
      edge_ptr[7] := Make_edge_topology(vertex_ptr[23], vertex_ptr[24],
        real_edge, nil);
      edge_ptr[8] := Make_edge_topology(vertex_ptr[24], vertex_ptr[21],
        real_edge, nil);

      {*****************}
      { make side edges }
      {*****************}
      edge_ptr[9] := Make_edge_topology(vertex_ptr[1], vertex_ptr[2], real_edge,
        nil);
      edge_ptr[10] := Make_edge_topology(vertex_ptr[5], vertex_ptr[6],
        real_edge, nil);
      edge_ptr[11] := Make_edge_topology(vertex_ptr[9], vertex_ptr[10],
        real_edge, nil);
      edge_ptr[12] := Make_edge_topology(vertex_ptr[13], vertex_ptr[14],
        real_edge, nil);

      {***********}
      { left face }
      {***********}
      face_edge_ptr[1] := edge_ptr[9];
      face_edge_ptr[2] := Make_edge_topology(vertex_ptr[2], vertex_ptr[3],
        duplicate_edge, edge_ptr[8]);
      face_edge_ptr[3] := Make_edge_topology(vertex_ptr[3], vertex_ptr[4],
        duplicate_edge, edge_ptr[12]);
      face_edge_ptr[4] := Make_edge_topology(vertex_ptr[4], vertex_ptr[1],
        duplicate_edge, edge_ptr[4]);

      Make_face_topology;
      Make_directed_edge(face_edge_ptr[1], true);
      Make_directed_edge(face_edge_ptr[2], true);
      Make_directed_edge(face_edge_ptr[3], true);
      Make_directed_edge(face_edge_ptr[4], true);

      {************}
      { right face }
      {************}
      face_edge_ptr[1] := edge_ptr[10];
      face_edge_ptr[2] := Make_edge_topology(vertex_ptr[6], vertex_ptr[7],
        duplicate_edge, edge_ptr[6]);
      face_edge_ptr[3] := Make_edge_topology(vertex_ptr[7], vertex_ptr[8],
        duplicate_edge, edge_ptr[11]);
      face_edge_ptr[4] := Make_edge_topology(vertex_ptr[8], vertex_ptr[5],
        duplicate_edge, edge_ptr[2]);

      Make_face_topology;
      Make_directed_edge(face_edge_ptr[1], true);
      Make_directed_edge(face_edge_ptr[2], true);
      Make_directed_edge(face_edge_ptr[3], true);
      Make_directed_edge(face_edge_ptr[4], true);

      {************}
      { front face }
      {************}
      face_edge_ptr[1] := edge_ptr[11];
      face_edge_ptr[2] := Make_edge_topology(vertex_ptr[10], vertex_ptr[11],
        duplicate_edge, edge_ptr[5]);
      face_edge_ptr[3] := Make_edge_topology(vertex_ptr[11], vertex_ptr[12],
        duplicate_edge, edge_ptr[9]);
      face_edge_ptr[4] := Make_edge_topology(vertex_ptr[12], vertex_ptr[9],
        duplicate_edge, edge_ptr[3]);

      Make_face_topology;
      Make_directed_edge(face_edge_ptr[1], true);
      Make_directed_edge(face_edge_ptr[2], true);
      Make_directed_edge(face_edge_ptr[3], true);
      Make_directed_edge(face_edge_ptr[4], true);

      {***********}
      { back face }
      {***********}
      face_edge_ptr[1] := edge_ptr[12];
      face_edge_ptr[2] := Make_edge_topology(vertex_ptr[14], vertex_ptr[15],
        duplicate_edge, edge_ptr[7]);
      face_edge_ptr[3] := Make_edge_topology(vertex_ptr[15], vertex_ptr[16],
        duplicate_edge, edge_ptr[10]);
      face_edge_ptr[4] := Make_edge_topology(vertex_ptr[16], vertex_ptr[13],
        duplicate_edge, edge_ptr[1]);

      Make_face_topology;
      Make_directed_edge(face_edge_ptr[1], true);
      Make_directed_edge(face_edge_ptr[2], true);
      Make_directed_edge(face_edge_ptr[3], true);
      Make_directed_edge(face_edge_ptr[4], true);

      {*************}
      { bottom face }
      {*************}
      face_edge_ptr[1] := edge_ptr[1];
      face_edge_ptr[2] := edge_ptr[2];
      face_edge_ptr[3] := edge_ptr[3];
      face_edge_ptr[4] := edge_ptr[4];

      Make_face_topology;
      Make_directed_edge(face_edge_ptr[1], true);
      Make_directed_edge(face_edge_ptr[2], true);
      Make_directed_edge(face_edge_ptr[3], true);
      Make_directed_edge(face_edge_ptr[4], true);

      {**********}
      { top face }
      {**********}
      face_edge_ptr[1] := edge_ptr[5];
      face_edge_ptr[2] := edge_ptr[6];
      face_edge_ptr[3] := edge_ptr[7];
      face_edge_ptr[4] := edge_ptr[8];

      Make_face_topology;
      Make_directed_edge(face_edge_ptr[1], true);
      Make_directed_edge(face_edge_ptr[2], true);
      Make_directed_edge(face_edge_ptr[3], true);
      Make_directed_edge(face_edge_ptr[4], true);

      if verbose then
        writeln('done.');
    end;

  Block_topology := block_topology_ptr;
end; {function Block_topology}


{************************}
{ non-surface primitives }
{************************}


function Point_topology(vertices: integer): topology_ptr_type;
var
  topology_ptr: topology_ptr_type;
  vertex_ptr: vertex_ptr_type;
  counter: integer;
begin
  if verbose then
    write('making point topology...');
  topology_ptr := Make_topology;

  {**************************}
  { make points and vertices }
  {**************************}
  for counter := 1 to vertices do
    begin
      vertex_ptr := Make_vertex_topology(Make_point_topology);
      vertex_ptr^.point_ptr^.real_point := true;
    end;

  if verbose then
    writeln('done.');
  Point_topology := topology_ptr;
end; {function Point_topology}


function Line_topology(vertices: integer): topology_ptr_type;
var
  topology_ptr: topology_ptr_type;
  vertex_ptr: vertex_ptr_type;
  counter: integer;
begin
  if verbose then
    write('making line topology...');
  topology_ptr := Make_topology;

  {**************************}
  { make points and vertices }
  {**************************}
  for counter := 1 to vertices do
    begin
      vertex_ptr := Make_vertex_topology(Make_point_topology);
      vertex_ptr^.point_ptr^.real_point := true;
    end;

  {************}
  { make edges }
  {************}
  vertex_ptr := topology_ptr^.vertex_ptr;
  while (vertex_ptr^.next <> nil) do
    begin
      Make_edge_topology(vertex_ptr, vertex_ptr^.next, real_edge, nil);
      vertex_ptr := vertex_ptr^.next;
    end;

  if verbose then
    writeln('done.');
  Line_topology := topology_ptr;
end; {function Line_topology}


procedure Free_faceted_topologies;
begin
  Free_topology(sphere_topology_ptr);
  Free_topology(cylinder_topology_ptr);
  Free_topology(paraboloid_topology_ptr);
  Free_topology(hyperboloid1_topology_ptr);
  Free_topology(sphere_sweep_topology_ptr);
  Free_topology(cylinder_sweep_topology_ptr);
  Free_topology(paraboloid_sweep_topology_ptr);
  Free_topology(hyperboloid1_sweep_topology_ptr);

  Free_topology(plane_topology_ptr);
  Free_topology(disk_topology_ptr);
  Free_topology(ring_topology_ptr);
  Free_topology(disk_sweep_topology_ptr);
  Free_topology(ring_sweep_topology_ptr);

  Free_topology(torus_topology_ptr);
  Free_topology(torus_u_sweep_topology_ptr);
  Free_topology(torus_v_sweep_topology_ptr);
  Free_topology(torus_uv_sweep_topology_ptr);
end; {procedure Free_faceted_topologies}


initialization
  quad_mesh_ptr := New_quad_mesh;

  sphere_topology_ptr := nil;
  cylinder_topology_ptr := nil;
  paraboloid_topology_ptr := nil;
  hyperboloid1_topology_ptr := nil;
  sphere_sweep_topology_ptr := nil;
  cylinder_sweep_topology_ptr := nil;
  paraboloid_sweep_topology_ptr := nil;
  hyperboloid1_sweep_topology_ptr := nil;

  plane_topology_ptr := nil;
  disk_topology_ptr := nil;
  ring_topology_ptr := nil;
  triangle_topology_ptr := nil;
  parallelogram_topology_ptr := nil;
  disk_sweep_topology_ptr := nil;
  ring_sweep_topology_ptr := nil;

  torus_topology_ptr := nil;
  torus_u_sweep_topology_ptr := nil;
  torus_v_sweep_topology_ptr := nil;
  torus_uv_sweep_topology_ptr := nil;
  block_topology_ptr := nil;

  verbose := false;
end.
