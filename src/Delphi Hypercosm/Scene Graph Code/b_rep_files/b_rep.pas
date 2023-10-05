unit b_rep;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               b_rep                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{      The b-rep (boundary representation) data structs         }
{      are used to the topological and  geometrical             }
{      descriptions of surfaces & solids.                       }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


{***************************************************************}
{                     geometry and topology                     }
{***************************************************************}
{      In many algorithms, the topology of the surface          }
{      is required (For example, what faces are adjacent        }
{      to this edge etc .) .                                    }
{                                                               }
{      To topological part of the data structure consumes       }
{      a large amount of memory , so to conserve memory, we     }
{      have seperated the geometry and the topology parts.      }
{                                                               }
{      This means that if you have, say, many torii with        }
{      differing thicknesses, then you can use the same         }
{      topology for all of them and prior to running your       }
{      algorithm, simply link in the new geometry.              }
{                                                               }
{      Since surfaces can share topology and geometry, we       }
{      must note this so when freeing a surface, we can         }
{      avoid accidentally freeing topology or geometry used     }
{      by other surfaces.                                       }
{                                                               }
{      There are three types of surfaces recognized:            }
{      1) self_similar                                          }
{             These are surfaces for which all instances        }
{             share the same topology and geometry.             }
{             examples: sphere, paraboloid, cylinder            }
{                                                               }
{      2) topo_similar                                          }
{             These are surfaces for which all instances        }
{             share the same topology but have different        }
{             geometries.                                       }
{             examples: ring, hyperboloid, cone, torus          }
{                                                               }
{      3) dissimilar                                            }
{             These are surfaces for which each particular      }
{             instance has its own topology and geometry.       }
{             examples: polygon, polyhedra                      }
{***************************************************************}


interface
uses
  geometry, topology;


{*******************************************************}
{                 surfaces and solids                   }
{*******************************************************}


type
  surface_kind_type = (self_similar, topo_similar, dissimilar);
  surface_closure_type = (open_surface, closed_surface);
  surface_shading_type = (flat_shading, smooth_shading);


  surface_ptr_type = ^surface_type;
  surface_type = record
    kind: surface_kind_type;
    closure: surface_closure_type;
    shading: surface_shading_type;

    topology_ptr: topology_ptr_type;
    geometry_ptr: geometry_ptr_type;

    reference_count: integer;
    next: surface_ptr_type;
  end; {surface_type}


  solid_ptr_type = ^solid_type;
  solid_type = record
    shell_ptr: surface_ptr_type;
    next: solid_ptr_type;
  end; {solid_type}


  {*********************************************}
  { These routines are used to allocate and     }
  { free surfaces and their geometry. Free      }
  { lists are maintained to make this more      }
  { efficient since new geometry may be created }
  { and destroyed during an animation. This is  }
  { not always done for the topology because    }
  { for most shapes, once the topology of a     }
  { particular shape is created, it can be kept }
  { and reused for new instances of the shape   }
  { with different geometry.                    }
  {*********************************************}
function New_surface(kind: surface_kind_type;
  closure: surface_closure_type;
  shading: surface_shading_type): surface_ptr_type;

function Copy_surface(surface_ptr: surface_ptr_type): surface_ptr_type;
procedure Free_surface(var surface_ptr: surface_ptr_type);
procedure Inspect_surface(surface_ptr: surface_ptr_type);
procedure Mend_surface(surface_ptr: surface_ptr_type);

{****************************************}
{ routines to bind geometry and topology }
{****************************************}
procedure Bind_point_geometry(surface_ptr: surface_ptr_type;
  geometry_ptr: geometry_ptr_type);
procedure Bind_vertex_geometry(surface_ptr: surface_ptr_type;
  geometry_ptr: geometry_ptr_type);
procedure Bind_face_geometry(surface_ptr: surface_ptr_type;
  geometry_ptr: geometry_ptr_type);

procedure Write_surface_kind(surface_kind: surface_kind_type);
procedure Write_surface_closure(surface_closure: surface_closure_type);
procedure Write_surface_shading(surface_shading: surface_shading_type);


implementation
uses
  new_memory, vectors, meshes;


const
  block_size = 512;
  memory_alert = false;


var
  surface_free_list: surface_ptr_type;


function New_surface(kind: surface_kind_type;
  closure: surface_closure_type;
  shading: surface_shading_type): surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
begin
  {****************************}
  { get surface from free list }
  {****************************}
  if (surface_free_list <> nil) then
    begin
      surface_ptr := surface_free_list;
      surface_free_list := surface_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new surface');
      new(surface_ptr);
    end;

  {********************}
  { initialize surface }
  {********************}
  surface_ptr^.kind := kind;
  surface_ptr^.closure := closure;
  surface_ptr^.shading := shading;

  with surface_ptr^ do
    begin
      geometry_ptr := nil;
      topology_ptr := nil;
      reference_count := 1;
      next := nil;
    end;

  New_surface := surface_ptr;
end; {function New_surface}


function Copy_surface(surface_ptr: surface_ptr_type): surface_ptr_type;
begin
  if surface_ptr <> nil then
    if surface_ptr^.kind <> self_similar then
      begin
        surface_ptr^.reference_count := surface_ptr^.reference_count + 1;
        surface_ptr^.topology_ptr := Copy_topology(surface_ptr^.topology_ptr);
      end;
  Copy_surface := surface_ptr;
end; {function Copy_surface}


procedure Free_surface(var surface_ptr: surface_ptr_type);
begin
  if surface_ptr <> nil then
    if surface_ptr^.kind <> self_similar then
      begin
        {***************}
        { free topology }
        {***************}
        if surface_ptr^.kind = dissimilar then
          begin
            if surface_ptr^.topology_ptr^.reference_count = 1 then
              Free_topology_mesh_link(surface_ptr^.topology_ptr);
            Free_topology(surface_ptr^.topology_ptr);
          end;

        {***************}
        { free geometry }
        {***************}
        surface_ptr^.reference_count := surface_ptr^.reference_count - 1;
        if surface_ptr^.reference_count = 0 then
          begin
            Free_geometry(surface_ptr^.geometry_ptr);

            {**************************}
            { add surface to free list }
            {**************************}
            surface_ptr^.next := surface_free_list;
            surface_free_list := surface_ptr;
            surface_ptr := nil;
          end;
      end;
end; {procedure Free_surface}


procedure Inspect_surface(surface_ptr: surface_ptr_type);
begin
  if (surface_ptr <> nil) then
    begin
      Inspect_topology(surface_ptr^.topology_ptr);
      Inspect_geometry(surface_ptr^.geometry_ptr);
    end
  else
    writeln('nil surface');
end; {procedure Inspect_surface}


procedure Mend_surface(surface_ptr: surface_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
  point1, point2, vector: vector_type;
  point_ptr: point_ptr_type;
  fore, aft, temp: vertex_ptr_type;
  point_geometry_ptr1, point_geometry_ptr2: point_geometry_ptr_type;
  point_ptr1, point_ptr2: point_ptr_type;
  point_ptr3, point_ptr4: point_ptr_type;
  edge_ptr, follow: edge_ptr_type;
  edge_ref_ptr: edge_ref_ptr_type;
  face_ref_ptr: face_ref_ptr_type;
  equal_points, same_edge, reversed_edge: boolean;
  D, D_squared: real;
begin
  D := 0.00001;
  D_squared := D * D;

  {************************}
  { find coincident points }
  {************************}
  vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
  while (vertex_ptr <> nil) do
    begin
      point_ptr := vertex_ptr^.point_ptr;
      point_geometry_ptr1 := point_ptr^.point_geometry_ptr;
      {point_geometry_ptr1 := Get_point_geometry(point_ptr^.index);}
      point1 := point_geometry_ptr1^.point;

      {***********************************}
      { search forward for any duplicates }
      {***********************************}
      fore := vertex_ptr^.next;
      aft := vertex_ptr;

      while (fore <> nil) do
        begin
          point_geometry_ptr2 := fore^.point_ptr^.point_geometry_ptr;
          {point_geometry_ptr2 := Get_point_geometry(fore^.point_ptr^.index);}
          point2 := point_geometry_ptr2^.point;
          vector := Vector_difference(point2, point1);

          equal_points := Dot_product(vector, vector) < D_squared;

          if equal_points and (point_geometry_ptr1 <> point_geometry_ptr2) then
            begin
              {***********************************************}
              { remove coincident point topology and geometry }
              {***********************************************}
              aft^.next := fore^.next;
              temp := fore;
              fore := aft^.next;

              {*********************************}
              { add point geometry to free list }
              {*********************************}
              {temp^.point_ptr^.point_geometry_ptr^.next := point_geometry_free_list;}
              {point_geometry_free_list := temp^.point_ptr^.point_geometry_ptr;}

              {*********************************}
              { add point topology to free list }
              {*********************************}
              {temp^.point_ptr^.next := point_free_list;}
              {point_free_list := temp^.point_ptr;}

              if temp^.point_ptr^.edge_list <> nil then
                begin
                  {****************************************}
                  { add old point's edge refs to new point }
                  {****************************************}
                  edge_ref_ptr := temp^.point_ptr^.edge_list;
                  while (edge_ref_ptr^.next <> nil) do
                    edge_ref_ptr := edge_ref_ptr^.next;
                  edge_ref_ptr^.next := vertex_ptr^.point_ptr^.edge_list;
                  vertex_ptr^.point_ptr^.edge_list :=
                    temp^.point_ptr^.edge_list;

                  {******************************************}
                  { redirect edges of old point to new point }
                  {******************************************}
                  edge_ref_ptr := temp^.point_ptr^.edge_list;
                  while (edge_ref_ptr <> nil) do
                    begin
                      edge_ptr := edge_ref_ptr^.edge_ptr;
                      if (edge_ptr^.vertex_ptr1 = temp) then
                        edge_ptr^.vertex_ptr1^.point_ptr :=
                          vertex_ptr^.point_ptr;
                      if (edge_ptr^.vertex_ptr2 = temp) then
                        edge_ptr^.vertex_ptr2^.point_ptr :=
                          vertex_ptr^.point_ptr;
                      edge_ref_ptr := edge_ref_ptr^.next;
                    end;

                  temp^.point_ptr^.edge_list := nil;
                end;

              {***********************************}
              { redirect vertex to original point }
              {***********************************}
              temp^.point_ptr := vertex_ptr^.point_ptr;
            end
          else
            begin
              {*****************}
              { advance pointer }
              {*****************}
              aft := fore;
              fore := fore^.next;
            end;
        end;

      vertex_ptr := vertex_ptr^.next;
    end;

  {***********************}
  { find coincident edges }
  {***********************}
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      point_ptr1 := edge_ptr^.vertex_ptr1^.point_ptr;
      point_ptr2 := edge_ptr^.vertex_ptr2^.point_ptr;

      follow := edge_ptr^.next;
      while (follow <> nil) do
        begin
          point_ptr3 := follow^.vertex_ptr1^.point_ptr;
          point_ptr4 := follow^.vertex_ptr2^.point_ptr;

          same_edge := (point_ptr1 = point_ptr3) and (point_ptr2 = point_ptr4);
          reversed_edge := (point_ptr1 = point_ptr4) and (point_ptr2 =
            point_ptr3);

          if same_edge or reversed_edge then
            begin
              follow^.edge_kind := duplicate_edge;
              follow^.duplicate_edge_ptr := edge_ptr;
              edge_ptr^.edge_kind := pseudo_edge;

              {********************************}
              { add face refs to original edge }
              {********************************}
              if (edge_ptr^.face_list <> nil) then
                begin
                  face_ref_ptr := edge_ptr^.face_list;
                  while face_ref_ptr^.next <> nil do
                    face_ref_ptr := face_ref_ptr^.next;
                  face_ref_ptr^.next := follow^.face_list;
                  follow^.face_list := nil;
                end
              else
                begin
                  edge_ptr^.face_list := follow^.face_list;
                  follow^.face_list := nil;
                end;
            end;

          follow := follow^.next;
        end;

      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Mend_surface}


{****************************************}
{ routines to bind geometry and topology }
{****************************************}


procedure Bind_point_geometry(surface_ptr: surface_ptr_type;
  geometry_ptr: geometry_ptr_type);
var
  point_ptr: point_ptr_type;
  point_geometry_ptr: point_geometry_ptr_type;
begin
  surface_ptr^.geometry_ptr := geometry_ptr;

  {*********************************}
  { bind point geometry to topology }
  {*********************************}
  point_ptr := surface_ptr^.topology_ptr^.point_ptr;
  point_geometry_ptr := geometry_ptr^.point_geometry_ptr;
  while (point_ptr <> nil) do
    begin
      point_ptr^.point_geometry_ptr := point_geometry_ptr;
      point_geometry_ptr := point_geometry_ptr^.next;
      point_ptr := point_ptr^.next;
    end;
end; {procedure Bind_point_geometry}


procedure Bind_vertex_geometry(surface_ptr: surface_ptr_type;
  geometry_ptr: geometry_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  surface_ptr^.geometry_ptr := geometry_ptr;

  {**********************************}
  { bind vertex geometry to topology }
  {**********************************}
  vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
  vertex_geometry_ptr := geometry_ptr^.vertex_geometry_ptr;
  while (vertex_ptr <> nil) do
    begin
      vertex_ptr^.vertex_geometry_ptr := vertex_geometry_ptr;
      vertex_geometry_ptr := vertex_geometry_ptr^.next;
      vertex_ptr := vertex_ptr^.next;
    end;
end; {procedure Bind_vertex_geometry}


procedure Bind_face_geometry(surface_ptr: surface_ptr_type;
  geometry_ptr: geometry_ptr_type);
var
  face_ptr: face_ptr_type;
  face_geometry_ptr: face_geometry_ptr_type;
begin
  surface_ptr^.geometry_ptr := geometry_ptr;

  {********************************}
  { bind face geometry to topology }
  {********************************}
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  face_geometry_ptr := geometry_ptr^.face_geometry_ptr;
  while (face_ptr <> nil) do
    begin
      face_ptr^.face_geometry_ptr := face_geometry_ptr;
      face_geometry_ptr := face_geometry_ptr^.next;
      face_ptr := face_ptr^.next;
    end;
end; {procedure Bind_face_geometry}


procedure Write_surface_kind(surface_kind: surface_kind_type);
begin
  case surface_kind of
    self_similar:
      write('self_similar');
    topo_similar:
      write('topo_similar');
    dissimilar:
      write('dissimilar');
  end;
end; {procedure Write_surface_kind}


procedure Write_surface_closure(surface_closure: surface_closure_type);
begin
  case surface_closure of
    open_surface:
      write('open surface');
    closed_surface:
      write('closed surface');
  end;
end; {procedure Write_surface_closure}


procedure Write_surface_shading(surface_shading: surface_shading_type);
begin
  case surface_shading of
    flat_shading:
      write('flat shading');
    smooth_shading:
      write('smooth_shading');
  end;
end; {procedure Write_suface_shading}


initialization
  {***********************}
  { initialize free lists }
  {***********************}
  surface_free_list := nil;
end.

