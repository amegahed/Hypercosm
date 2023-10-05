unit z_screen_clip;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           z_screen_clip               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module clips polygons used by the z buffer         }
{       To properly clip the edges of the polygons, we must     }
{       also interpolate the associated z values and vectors    }
{       (colors for Gouraud, and normals for Phong) along       }
{       clipped edges.                                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  z_vertices, screen_boxes;


{********************************}
{ routines to clip to screen box }
{********************************}
procedure Clip_z_polygon_to_screen_box(z_polygon_ptr: z_polygon_ptr_type;
  screen_box: screen_box_type);
procedure Clip_z_line_to_screen_box(z_line_ptr: z_line_ptr_type;
  screen_box: screen_box_type);
procedure Clip_z_point_to_screen_box(z_point_ptr: z_point_ptr_type;
  screen_box: screen_box_type);
procedure Clip_z_polygons_to_screen_box(z_polygon_ptr: z_polygon_ptr_type;
  screen_box: screen_box_type);


implementation
uses
  vectors, pixels;


type
  screen_box_edge_type = (left_edge, right_edge, bottom_edge, top_edge);
  edge_visibility_type = (entirely_visible, entirely_invisible, leaving_visible,
    entering_visible);


var
  {***********************************}
  { extents of the current screen box }
  {***********************************}
  min, max: pixel_type;


procedure Write_screen_box_edge(screen_box_edge: screen_box_edge_type);
begin
  case screen_box_edge of
    left_edge:
      write('left_edge');
    right_edge:
      write('right_edge');
    bottom_edge:
      write('bottom_edge');
    top_edge:
      write('top_edge');
  end;
end; {procedure Write_screen_box_edge}


procedure Write_edge_visibility(edge_visibility: edge_visibility_type);
begin
  case edge_visibility of
    entirely_visible:
      write('entirely_visible');
    entirely_invisible:
      write('entirely_invisible');
    leaving_visible:
      write('leaving_visible');
    entering_visible:
      write('entering_visible');
  end;
end; {procedure Write_edge_visibility}


{***************************************}
{ routines for clipping to a screen box }
{***************************************}


procedure Clip_screen_box_edge(screen_box_edge: screen_box_edge_type;
  z_polygon_ptr: z_polygon_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  var intersection_vertex: z_vertex_type;
  var visibility: edge_visibility_type);
var
  edge_vector: vector_type;
  t: real;
begin
  case screen_box_edge of
    left_edge:
      if (z_vertex_ptr1^.point.x < min.h) then
        begin
          if (z_vertex_ptr2^.point.x < min.h) then
            visibility := entirely_invisible
          else
            visibility := entering_visible;
        end
      else
        begin
          if (z_vertex_ptr2^.point.x < min.h) then
            visibility := leaving_visible
          else
            visibility := entirely_visible;
        end;

    right_edge:
      if (z_vertex_ptr1^.point.x > max.h) then
        begin
          if (z_vertex_ptr2^.point.x > max.h) then
            visibility := entirely_invisible
          else
            visibility := entering_visible;
        end
      else
        begin
          if (z_vertex_ptr2^.point.x > max.h) then
            visibility := leaving_visible
          else
            visibility := entirely_visible;
        end;

    bottom_edge:
      if (z_vertex_ptr1^.point.y > max.v) then
        begin
          if (z_vertex_ptr2^.point.y > max.v) then
            visibility := entirely_invisible
          else
            visibility := entering_visible;
        end
      else
        begin
          if (z_vertex_ptr2^.point.y > max.v) then
            visibility := leaving_visible
          else
            visibility := entirely_visible;
        end;

    top_edge:
      if (z_vertex_ptr1^.point.y < min.v) then
        begin
          if (z_vertex_ptr2^.point.y < min.v) then
            visibility := entirely_invisible
          else
            visibility := entering_visible;
        end
      else
        begin
          if (z_vertex_ptr2^.point.y < min.v) then
            visibility := leaving_visible
          else
            visibility := entirely_visible;
        end;
  end; {case}

  if (visibility = entering_visible) or (visibility = leaving_visible) then
    begin
      edge_vector := Vector_difference(z_vertex_ptr2^.point,
        z_vertex_ptr1^.point);

      case screen_box_edge of
        left_edge:
          t := (min.h - z_vertex_ptr1^.point.x) / edge_vector.x;
        right_edge:
          t := (max.h - z_vertex_ptr1^.point.x) / edge_vector.x;
        top_edge:
          t := (min.v - z_vertex_ptr1^.point.y) / edge_vector.y;
        bottom_edge:
          t := (max.v - z_vertex_ptr1^.point.y) / edge_vector.y;
      else
        t := 0;
      end; {case}

      Interpolate_z_vertex(intersection_vertex, z_polygon_ptr, z_vertex_ptr1,
        z_vertex_ptr2, edge_vector, t);
    end;
end; {procedure Clip_screen_box_edge}


procedure Clip_z_polygon_to_screen_box(z_polygon_ptr: z_polygon_ptr_type;
  screen_box: screen_box_type);
var
  screen_box_edge: screen_box_edge_type;
  clipped_polygon_ptr: z_polygon_ptr_type;
  edge_visibility: edge_visibility_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  intersection_vertex: z_vertex_type;
begin
  min := screen_box.min;
  max := screen_box.max;

  for screen_box_edge := left_edge to top_edge do
    begin
      clipped_polygon_ptr := New_z_vertex_list(z_polygon_ptr^.kind,
        z_polygon_ptr^.color, z_polygon_ptr^.textured);
      z_vertex_ptr1 := z_polygon_ptr^.first;

      while (z_vertex_ptr1 <> nil) do
        begin
          if (z_vertex_ptr1^.next <> nil) then
            z_vertex_ptr2 := z_vertex_ptr1^.next
          else
            z_vertex_ptr2 := z_polygon_ptr^.first;

          {**********************************************}
          { clip edge of polygon with edge of screen box }
          {**********************************************}
          Clip_screen_box_edge(screen_box_edge, z_polygon_ptr, z_vertex_ptr1,
            z_vertex_ptr2, intersection_vertex, edge_visibility);

          case edge_visibility of
            entirely_visible:
              begin
                Add_new_z_vertex(clipped_polygon_ptr, z_vertex_ptr1^);
              end;
            entirely_invisible:
              ;
            leaving_visible:
              begin
                Add_new_z_vertex(clipped_polygon_ptr, z_vertex_ptr1^);
                Add_new_z_vertex(clipped_polygon_ptr, intersection_vertex);
              end;
            entering_visible:
              begin
                Add_new_z_vertex(clipped_polygon_ptr, intersection_vertex);
              end;
          end; {case}

          z_vertex_ptr1 := z_vertex_ptr1^.next;
        end; {while}

      Swap_z_vertex_lists(clipped_polygon_ptr, z_polygon_ptr);
      Free_z_vertex_list(clipped_polygon_ptr);
    end; {for}
end; {procedure Clip_polygon_to_screen_box}


procedure Clip_z_line_to_screen_box(z_line_ptr: z_line_ptr_type;
  screen_box: screen_box_type);
var
  screen_box_edge: screen_box_edge_type;
  follow, current: z_line_ptr_type;
  clipped_line_ptr: z_line_ptr_type;
  current_line_ptr: z_line_ptr_type;
  new_line_ptr: z_line_ptr_type;
  edge_visibility: edge_visibility_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  intersection_vertex: z_vertex_type;
begin
  min := screen_box.min;
  max.h := screen_box.max.h - 1;
  max.v := screen_box.max.v - 1;

  for screen_box_edge := left_edge to top_edge do
    begin
      {****************************}
      { clip each polyline in list }
      {****************************}
      follow := z_line_ptr;
      while (follow <> nil) do
        begin
          current := follow;
          follow := follow^.next;

          {*******************************}
          { clip polyline with screen box }
          {*******************************}
          if current^.first <> nil then
            if current^.first^.next <> nil then
              begin
                clipped_line_ptr := New_z_vertex_list(z_line_ptr^.kind,
                  z_line_ptr^.color, z_line_ptr^.textured);
                current_line_ptr := clipped_line_ptr;
                z_vertex_ptr1 := current^.first;
                z_vertex_ptr2 := z_vertex_ptr1^.next;

                while (z_vertex_ptr2 <> nil) do
                  begin
                    {*******************************************}
                    { clip edge of line with edge of screen box }
                    {*******************************************}
                    Clip_screen_box_edge(screen_box_edge, z_line_ptr,
                      z_vertex_ptr1, z_vertex_ptr2, intersection_vertex,
                      edge_visibility);

                    case edge_visibility of
                      entirely_visible:
                        begin
                          Add_new_z_vertex(current_line_ptr, z_vertex_ptr1^);
                          if z_vertex_ptr2^.next = nil then
                            Add_new_z_vertex(current_line_ptr, z_vertex_ptr2^);
                        end;
                      entirely_invisible:
                        ;
                      leaving_visible:
                        begin
                          Add_new_z_vertex(current_line_ptr, z_vertex_ptr1^);
                          Add_new_z_vertex(current_line_ptr,
                            intersection_vertex);
                        end;
                      entering_visible:
                        begin
                          {**************************************}
                          { create new line and insert into list }
                          {**************************************}
                          if current_line_ptr^.first <> nil then
                            begin
                              new_line_ptr :=
                                New_z_vertex_list(z_line_ptr^.kind,
                                z_line_ptr^.color, z_line_ptr^.textured);
                              current_line_ptr^.next := new_line_ptr;
                              current_line_ptr := new_line_ptr;
                            end;

                          Add_new_z_vertex(current_line_ptr,
                            intersection_vertex);
                          if z_vertex_ptr2^.next = nil then
                            Add_new_z_vertex(current_line_ptr, z_vertex_ptr2^);
                        end;
                    end; {case}

                    z_vertex_ptr1 := z_vertex_ptr2;
                    z_vertex_ptr2 := z_vertex_ptr2^.next;
                  end; {while}

                current_line_ptr^.next := follow;
                Swap_z_vertex_lists(clipped_line_ptr, current);
                Free_z_vertex_list(clipped_line_ptr);
              end; {if}
        end; {for}
    end; {while}
end; {procedure Clip_z_line_to_screen_box}


procedure Clip_z_point_to_screen_box(z_point_ptr: z_point_ptr_type;
  screen_box: screen_box_type);
var
  clipped_point_ptr: z_point_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  min := screen_box.min;
  max.h := screen_box.max.h - 1;
  max.v := screen_box.max.v - 1;

  if z_point_ptr <> nil then
    begin
      clipped_point_ptr := New_z_vertex_list(z_point_ptr^.kind,
        z_point_ptr^.color, z_point_ptr^.textured);
      z_vertex_ptr := z_point_ptr^.first;

      while (z_vertex_ptr <> nil) do
        begin
          if (z_vertex_ptr^.point.x > min.h) then
            if (z_vertex_ptr^.point.x < max.h) then
              if (z_vertex_ptr^.point.y > min.v) then
                if (z_vertex_ptr^.point.y < max.v) then
                  Add_new_z_vertex(clipped_point_ptr, z_vertex_ptr^);

          z_vertex_ptr := z_vertex_ptr^.next;
        end; {while}

      Swap_z_vertex_lists(clipped_point_ptr, z_point_ptr);
      Free_z_vertex_list(clipped_point_ptr);
    end; {for}
end; {procedure Clip_z_point_to_screen_box}


procedure Clip_z_polygons_to_screen_box(z_polygon_ptr: z_polygon_ptr_type;
  screen_box: screen_box_type);
var
  follow: z_polygon_ptr_type;
begin
  follow := z_polygon_ptr;
  while (follow <> nil) do
    begin
      Clip_z_polygon_to_screen_box(follow, screen_box);
      follow := follow^.next;
    end;
end; {procedure Clip_z_polygons_to_screen_box}


end.
