unit cubes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               cubes                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The meshes module builds data structures necessary      }
{       for volume rendering. These data structures tell        }
{       the correct tessellation for any voxel in order to      }
{       draw an isosurface through the voxel space.             }
{                                                               }
{       This algorithm is commonly known as the 'marching       }
{       cubes'. (for some reason)                               }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


type
  {****************************************}
  { polarity is used to label the vertices }
  { as below or above the threshold.       }
  {****************************************}
  polarity_type = (below, above);
  polarity_ptr_type = ^polarity_type;

  {*************************************************}
  { polarity of each vertex in voxel which uniquely }
  { identifies the topology of the voxel polygons.  }
  {*************************************************}
  voxel_polarity_type = array[0..8] of polarity_type;


type
  voxel_vertex_ptr_type = ^voxel_vertex_type;
  voxel_vertex_type = record
    edge: integer;
    next: voxel_vertex_ptr_type;
  end; {voxel_vertex_type}


  voxel_polygon_ptr_type = ^voxel_polygon_type;
  voxel_polygon_type = record
    vertex_ptr, last_vertex_ptr: voxel_vertex_ptr_type;
    next: voxel_polygon_ptr_type;
  end; {voxel_polygon_type}


var
  {*******************************************}
  { 256 different types of voxel tessellation }
  {*******************************************}
  voxel_tessellation: array[0..255] of voxel_polygon_ptr_type;


procedure Make_cubes;
function Polarity_to_index(voxel_polarity: voxel_polarity_type): integer;


implementation
uses
  new_memory;

{***************************************************************}
{    algorithm for finding an isosurface through a volume       }
{***************************************************************}
{       The volume is represented by a regular grid with        }
{       density values at each vertex.  Each cube in the        }
{       volume is a volume element, or voxel.                   }
{                                                               }
{       To find an isosurface through the volume, we find       }
{       where the isosurface intersects each edge in the        }
{       regular grid by linear interpolation. When we have      }
{       the edge intersections of each voxel, we connect        }
{       the new vertices that are formed together to create     }
{       partitioning surfaces through each voxel. Together,     }
{       these partitions will form the isosurface.              }
{                                                               }
{       In order to quickly create the isosurface topology,     }
{       we note that there are only 256 possible types of       }
{       voxels (inside or outside at each vertex = 2^8 = 256)   }
{       so there are only 256 different ways to partition       }
{       the voxel.                                              }
{***************************************************************}


{***************************************************************}
{       algorithm for finding how to partition a voxel          }
{***************************************************************}
{       Each vertex of the voxel has a density value and the    }
{       volume has associated with it a threshold value which   }
{       we use to find the isosurface through the voxels.       }
{                                                               }
{       1. Label each vertex as '+' or '-', above or below      }
{          below the threshold point.                           }
{                                                               }
{       2. Find all edges which the isosurface intersects.      }
{          These edges are the edges with a '+' at one vertex   }
{          and a '-' at the other.                              }
{                                                               }
{       3. Pick the first edge out of this list of bisected     }
{          edges. With this edge do the following:              }
{                                                               }
{       4. Determine the orientation of the edge from the       }
{          '+' and '-' of the vertices.  Consider the edge      }
{          to point from the '-' to the '+'.                    }
{                                                               }
{       5. Using the edge orientation, find the neighboring     }
{          face to the right of the edge.                       }
{                                                               }
{       6. Go around this face counterclockwise (right hand     }
{          rule) with respect to the normal of the face to      }
{          find the next bisected edge to connect with.         }
{          Mark this edge as visited.                           }
{                                                               }
{       7. Repeat this process with the new edge until we       }
{          come back to the start.                              }
{                                                               }
{       8. Find the next unvisited edge in the list of          }
{          bisected edges and go back to step 4.                }
{                                                               }
{***************************************************************}
{       Note that since we always go around the bisected        }
{       edges in a counterclockwise manner, the faces that      }
{       are formed will have a consistent orientation, always   }
{       'pointing' from the '-' regions to the '+' regions.     }
{***************************************************************}


const
  {*****************************************}
  { used to allocate small, numerous data   }
  { objects in blocks for faster allocation }
  {*****************************************}
  block_size = 256;
  memory_alert = false;


  {*********************************************}
  { left and right directions are used to find  }
  { the face to the left and right of an edge.  }
  {*********************************************}
  left = false;
  right = true;


type
  direction_type = boolean;


  voxel_vertex_block_type = array[0..block_size] of voxel_vertex_type;
  voxel_polygon_block_type = array[0..block_size] of voxel_polygon_type;
  voxel_vertex_block_ptr_type = ^voxel_vertex_block_type;
  voxel_polygon_block_ptr_type = ^voxel_polygon_block_type;


var
  cubes_done: boolean;

  {****************}
  { voxel topology }
  {****************}
  voxel_vertex: array[0..8, 0..3] of integer;
  voxel_edge: array[0..12, 0..2] of integer;
  voxel_wing: array[0..12, left..right] of integer;
  voxel_face: array[0..6, 0..4] of integer;

  {******************}
  { block allocation }
  {******************}
  voxel_vertex_block_ptr: voxel_vertex_block_ptr_type;
  voxel_polygon_block_ptr: voxel_polygon_block_ptr_type;
  voxel_vertex_counter: integer;
  voxel_polygon_counter: integer;


  {***********************************}
  { routines to create voxel polygons }
  {***********************************}


function New_voxel_polygon: voxel_polygon_ptr_type;
var
  voxel_polygon_ptr: voxel_polygon_ptr_type;
  index: integer;
begin
  {************************}
  { allocate voxel polygon }
  {************************}
  index := voxel_polygon_counter mod block_size;
  if (index = 0) then
    begin
      if memory_alert then
        writeln('allocating new voxel polygon block');
      new(voxel_polygon_block_ptr);
    end;
  voxel_polygon_ptr := @voxel_polygon_block_ptr^[index];
  voxel_polygon_counter := voxel_polygon_counter + 1;

  {**************************}
  { initialize voxel polygon }
  {**************************}
  voxel_polygon_ptr^.vertex_ptr := nil;
  voxel_polygon_ptr^.last_vertex_ptr := nil;
  voxel_polygon_ptr^.next := nil;

  New_voxel_polygon := voxel_polygon_ptr;
end; {function New_voxel_polygon}


function New_voxel_vertex(edge: integer): voxel_vertex_ptr_type;
var
  voxel_vertex_ptr: voxel_vertex_ptr_type;
  index: integer;
begin
  {***********************}
  { allocate voxel vertex }
  {***********************}
  index := voxel_vertex_counter mod block_size;
  if (index = 0) then
    begin
      if memory_alert then
        writeln('allocating new voxel vertex block');
      new(voxel_vertex_block_ptr);
    end;
  voxel_vertex_ptr := @voxel_vertex_block_ptr^[index];
  voxel_vertex_counter := voxel_vertex_counter + 1;

  {*************************}
  { initialize voxel vertex }
  {*************************}
  voxel_vertex_ptr^.edge := edge;
  voxel_vertex_ptr^.next := nil;

  New_voxel_vertex := voxel_vertex_ptr;
end; {function New_voxel_vertex}


procedure Add_voxel_vertex(voxel_polygon_ptr: voxel_polygon_ptr_type;
  voxel_vertex_ptr: voxel_vertex_ptr_type);
begin
  if voxel_polygon_ptr <> nil then
    begin
      if voxel_polygon_ptr^.vertex_ptr <> nil then
        begin
          voxel_polygon_ptr^.last_vertex_ptr^.next := voxel_vertex_ptr;
          voxel_polygon_ptr^.last_vertex_ptr := voxel_vertex_ptr;
        end
      else
        begin
          voxel_polygon_ptr^.vertex_ptr := voxel_vertex_ptr;
          voxel_polygon_ptr^.last_vertex_ptr := voxel_vertex_ptr;
        end;
    end;
end; {procedure Add_voxel_vertex}


{***************************************}
{ routines to initialize voxel topology }
{***************************************}


procedure Init_voxel_vertices;
begin
  {**********************************************}
  {    enumerating voxel vertices 1 through 8    }
  {**********************************************}
  {                                              }
  {                 8---------------7            }
  {                /|              /|            }
  {               / |             / |            }
  {              /  |            /  |            }
  {             5---------------6   |            }
  {             |   |           |   |            }
  {             |   |           |   |            }
  {             |   |           |   |            }
  {             |   |           |   |            }
  {             |   4-----------|---3            }
  {             |  /            |  /             }
  {             | /             | /              }
  {             |/              |/               }
  {             1---------------2                }
  {                                              }
  {**********************************************}

  voxel_vertex[1][1] := 0;
  voxel_vertex[1][2] := 0;
  voxel_vertex[1][3] := 0;

  voxel_vertex[2][1] := 1;
  voxel_vertex[2][2] := 0;
  voxel_vertex[2][3] := 0;

  voxel_vertex[3][1] := 1;
  voxel_vertex[3][2] := 1;
  voxel_vertex[3][3] := 0;

  voxel_vertex[4][1] := 0;
  voxel_vertex[4][2] := 1;
  voxel_vertex[4][3] := 0;

  voxel_vertex[1][1] := 0;
  voxel_vertex[1][2] := 0;
  voxel_vertex[1][3] := 1;

  voxel_vertex[2][1] := 1;
  voxel_vertex[2][2] := 0;
  voxel_vertex[2][3] := 1;

  voxel_vertex[3][1] := 1;
  voxel_vertex[3][2] := 1;
  voxel_vertex[3][3] := 1;

  voxel_vertex[4][1] := 0;
  voxel_vertex[4][2] := 1;
  voxel_vertex[4][3] := 1;
end; {procedure Init_voxel_vertices}



procedure Init_voxel_edges;
begin
  {**********************************************}
  {     enumerating voxel edges 1 through 12     }
  {**********************************************}
  {                                              }
  {                 *------ 7 ------*            }
  {                /|              /|            }
  {               8 |             6 |            }
  {              /  |            /  |            }
  {             *------ 5 ------*   |            }
  {             |  12           |  11            }
  {             |   |           |   |            }
  {             |   |           |   |            }
  {             9   |          10   |            }
  {             |   *------ 3 --|---*            }
  {             |  /            |  /             }
  {             | 4             | 2              }
  {             |/              |/               }
  {             *------ 1 ------*                }
  {                                              }
  {**********************************************}

  voxel_edge[1][1] := 1;
  voxel_edge[1][2] := 2;

  voxel_edge[2][1] := 2;
  voxel_edge[2][2] := 3;

  voxel_edge[3][1] := 3;
  voxel_edge[3][2] := 4;

  voxel_edge[4][1] := 4;
  voxel_edge[4][2] := 1;

  voxel_edge[5][1] := 5;
  voxel_edge[5][2] := 6;

  voxel_edge[6][1] := 6;
  voxel_edge[6][2] := 7;

  voxel_edge[7][1] := 7;
  voxel_edge[7][2] := 8;

  voxel_edge[8][1] := 8;
  voxel_edge[8][2] := 5;

  voxel_edge[9][1] := 1;
  voxel_edge[9][2] := 5;

  voxel_edge[10][1] := 2;
  voxel_edge[10][2] := 6;

  voxel_edge[11][1] := 3;
  voxel_edge[11][2] := 7;

  voxel_edge[12][1] := 4;
  voxel_edge[12][2] := 8;
end; {procedure Init_voxel_edges}


procedure Init_voxel_faces;
begin
  {**********************************************}
  {     enumerating voxel faces 1 through 6      }
  {**********************************************}
  {                                              }
  {                 *---------------*            }
  {                /|              /|            }
  {               / |     6       / |            }
  {              /  |            /  |            }
  {             *---------------*   |            }
  {             |   |       4   |   |            }
  {             |   |           |   |            }
  {             | 1 |           | 2 |            }
  {             |   |   3       |   |            }
  {             |   *-----------|---*            }
  {             |  /            |  /             }
  {             | /       5     | /              }
  {             |/              |/               }
  {             *---------------*                }
  {                                              }
  {**********************************************}

  voxel_face[1][1] := 4;
  voxel_face[1][2] := 9;
  voxel_face[1][3] := 8;
  voxel_face[1][4] := 12;

  voxel_face[2][1] := 2;
  voxel_face[2][2] := 11;
  voxel_face[2][3] := 6;
  voxel_face[2][4] := 10;

  voxel_face[3][1] := 1;
  voxel_face[3][2] := 10;
  voxel_face[3][3] := 5;
  voxel_face[3][4] := 9;

  voxel_face[4][1] := 3;
  voxel_face[4][2] := 12;
  voxel_face[4][3] := 7;
  voxel_face[4][4] := 11;

  voxel_face[5][1] := 1;
  voxel_face[5][2] := 4;
  voxel_face[5][3] := 3;
  voxel_face[5][4] := 2;

  voxel_face[6][1] := 5;
  voxel_face[6][2] := 6;
  voxel_face[6][3] := 7;
  voxel_face[6][4] := 8;
end; {procedure Init_voxel_faces}


procedure Init_voxel_wings;
begin
  {**********************************************}
  {     enumerating voxel wings 1 through 12     }
  {**********************************************}
  {                                              }
  {                 *<----- 7 ------*            }
  {                /^              /^            }
  {               8 |             6 |            }
  {              /  |            /  |            }
  {             *------ 5 ----->*   |            }
  {             ^  12           ^  11            }
  {             |   |           |   |            }
  {             |   |           |   |            }
  {             9   |          10   |            }
  {             |   *<----- 3 --|---*            }
  {             |  /            |  /             }
  {             | 4             | 2              }
  {             |/              |/               }
  {             *------ 1 ----->*                }
  {                                              }
  {**********************************************}

  voxel_wing[1][left] := 3;
  voxel_wing[1][right] := 5;

  voxel_wing[2][left] := 2;
  voxel_wing[2][right] := 5;

  voxel_wing[3][left] := 4;
  voxel_wing[3][right] := 5;

  voxel_wing[4][left] := 1;
  voxel_wing[4][right] := 5;

  voxel_wing[5][left] := 6;
  voxel_wing[5][right] := 3;

  voxel_wing[6][left] := 6;
  voxel_wing[6][right] := 2;

  voxel_wing[7][left] := 6;
  voxel_wing[7][right] := 4;

  voxel_wing[8][left] := 6;
  voxel_wing[8][right] := 1;

  voxel_wing[9][left] := 1;
  voxel_wing[9][right] := 3;

  voxel_wing[10][left] := 3;
  voxel_wing[10][right] := 2;

  voxel_wing[11][left] := 2;
  voxel_wing[11][right] := 4;

  voxel_wing[12][left] := 4;
  voxel_wing[12][right] := 1;
end; {procedure Init_voxel_wings}


procedure Init_voxel_topology;
begin
  Init_voxel_vertices;
  Init_voxel_edges;
  Init_voxel_faces;
  Init_voxel_wings;
end; {procedure Init_voxel_topology}


{**************************************************}
{ routines to tessellate 256 unique kinds of voxel }
{**************************************************}


procedure Write_voxel_polygons(voxel_polygon_ptr: voxel_polygon_ptr_type);
var
  voxel_vertex_ptr: voxel_vertex_ptr_type;
begin
  while (voxel_polygon_ptr <> nil) do
    begin
      voxel_vertex_ptr := voxel_polygon_ptr^.vertex_ptr;
      while voxel_vertex_ptr <> nil do
        begin
          write(voxel_vertex_ptr^.edge: 1);
          voxel_vertex_ptr := voxel_vertex_ptr^.next;
          if (voxel_vertex_ptr <> nil) then
            write(' ');
        end;
      voxel_polygon_ptr := voxel_polygon_ptr^.next;
      if (voxel_polygon_ptr <> nil) then
        write(', ');
    end;
end; {procedure Write_voxel_polygons}


procedure Write_polarity(polarity: polarity_type);
begin
  case polarity of
    below:
      write('below');
    above:
      write('above');
  end;
end; {procedure Write_polarity}


procedure Write_voxel_polarity(voxel_polarity: voxel_polarity_type);
var
  counter: integer;
begin
  for counter := 1 to 8 do
    case voxel_polarity[counter] of
      below:
        write('-');
      above:
        write('+');
    end;
  writeln;
end; {procedure Write_voxel_polarity}


function Tessellate_voxel(voxel_polarity: voxel_polarity_type):
  voxel_polygon_ptr_type;
var
  voxel_polygon_ptr, voxel_polygon_list: voxel_polygon_ptr_type;
  isosurface_edge: array[1..12] of boolean;
  isosurface_edge_list: array[1..12] of integer;
  touched: array[1..12] of boolean;
  isosurface_edges: integer;
  polarity1, polarity2: polarity_type;
  edge, right_face, side, counter: integer;
  done, found, orientation: boolean;
begin
  voxel_polygon_list := nil;

  {****************************************}
  { find edges where isosurface intersects }
  {****************************************}
  isosurface_edges := 0;
  for edge := 1 to 12 do
    begin
      polarity1 := voxel_polarity[voxel_edge[edge][1]];
      polarity2 := voxel_polarity[voxel_edge[edge][2]];
      isosurface_edge[edge] := (polarity1 <> polarity2);

      {**************************************}
      { add edge to list of isosurface edges }
      {**************************************}
      if isosurface_edge[edge] then
        begin
          isosurface_edges := isosurface_edges + 1;
          isosurface_edge_list[isosurface_edges] := edge;
        end;

      touched[edge] := false;
    end;

  if isosurface_edges <> 0 then
    begin
      edge := isosurface_edge_list[1];
      done := false;

      {****************}
      { create polygon }
      {****************}
      voxel_polygon_ptr := New_voxel_polygon;
      voxel_polygon_list := voxel_polygon_ptr;
      Add_voxel_vertex(voxel_polygon_ptr, New_voxel_vertex(edge));
      touched[edge] := true;

      {***************************************}
      { while there are isosurface edges left }
      {***************************************}
      while not done do
        begin
          {********************************}
          { find face to the right of edge }
          {********************************}
          orientation := (voxel_polarity[voxel_edge[edge][1]] = below);

          if orientation then
            right_face := voxel_wing[edge][left]
          else
            right_face := voxel_wing[edge][right];

          {*********************************}
          { go around face counterclockwise }
          {*********************************}

          {***************************}
          { find current edge on face }
          {***************************}
          side := 1;
          found := false;
          while not found do
            begin
              if voxel_face[right_face, side] = edge then
                found := true
              else
                side := side + 1;
            end;

          {************************************}
          { go to next isosurface edge on face }
          {************************************}
          found := false;
          while not found do
            begin
              side := (side mod 4) + 1;
              edge := voxel_face[right_face, side];
              if isosurface_edge[edge] then
                found := true;
            end;

          if (not touched[edge]) then
            begin
              {*********************}
              { add edge to polygon }
              {*********************}
              Add_voxel_vertex(voxel_polygon_ptr, New_voxel_vertex(edge));
              touched[edge] := true;
            end
          else
            begin
              {*************************************}
              { find next untouched isosurface edge }
              {*************************************}
              found := false;
              counter := 1;
              while (counter <= isosurface_edges) and not found do
                begin
                  edge := isosurface_edge_list[counter];
                  if not touched[edge] then
                    begin
                      found := true
                    end
                  else
                    counter := counter + 1;
                end;

              {********************}
              { go to next polygon }
              {********************}
              if found then
                begin
                  voxel_polygon_ptr := New_voxel_polygon;
                  voxel_polygon_ptr^.next := voxel_polygon_list;
                  voxel_polygon_list := voxel_polygon_ptr;
                  Add_voxel_vertex(voxel_polygon_ptr, New_voxel_vertex(edge));
                  touched[edge] := true;
                end
              else
                done := true;
            end;
        end;
    end;

  {write('voxel: ');}
  {Write_voxel_polarity(voxel_polarity);}
  {writeln;}
  {write('polygons:');}
  {Write_voxel_polygons(voxel_polygon_list);}
  {writeln;}
  {writeln;}

  Tessellate_voxel := voxel_polygon_list;
end; {function Tessellate_voxel}


function Polarity_to_index(voxel_polarity: voxel_polarity_type): integer;
var
  index, counter: integer;
  place_value: integer;
begin
  place_value := 1;
  index := 0;
  for counter := 1 to 8 do
    begin
      if voxel_polarity[counter] = above then
        index := index + place_value;
      place_value := place_value * 2;
    end;
  Polarity_to_index := index;
end; {function Polarity_to_index}


procedure Make_cubes;
var
  counter8, counter7, counter6, counter5: polarity_type;
  counter4, counter3, counter2, counter1: polarity_type;
  voxel_polarity: voxel_polarity_type;
  index: integer;
begin
  if not cubes_done then
    begin
      Init_voxel_topology;

      for counter8 := below to above do
        begin
          voxel_polarity[8] := counter8;
          for counter7 := below to above do
            begin
              voxel_polarity[7] := counter7;
              for counter6 := below to above do
                begin
                  voxel_polarity[6] := counter6;
                  for counter5 := below to above do
                    begin
                      voxel_polarity[5] := counter5;
                      for counter4 := below to above do
                        begin
                          voxel_polarity[4] := counter4;
                          for counter3 := below to above do
                            begin
                              voxel_polarity[3] := counter3;
                              for counter2 := below to above do
                                begin
                                  voxel_polarity[2] := counter2;
                                  for counter1 := below to above do
                                    begin
                                      voxel_polarity[1] := counter1;

                                      {*********************************************}
                                      { create tessellation for this voxel topology }
                                      {*********************************************}
                                      index :=
                                        Polarity_to_index(voxel_polarity);
                                      voxel_tessellation[index] :=
                                        Tessellate_voxel(voxel_polarity);

                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;
      cubes_done := true;
    end;
end; {procedure Make_cubes}


initialization
  voxel_vertex_block_ptr := nil;
  voxel_polygon_block_ptr := nil;
  voxel_vertex_counter := 0;
  voxel_polygon_counter := 0;
  cubes_done := false;
end.
