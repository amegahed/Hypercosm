unit z_clip;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               z_clip                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module clips polygons used by the z buffer.        }
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
  z_vertices, project, viewports;


var
  z_clipping_enabled: boolean;


{********************************************}
{ routines to enable / disable z_clipping    }
{ (in some circumstances, we may know before }
{ hand that clipping is unneccessary.        }
{********************************************}
procedure Enable_z_clipping;
procedure Disable_z_clipping;


procedure Clip_and_project_z_polygon(z_polygon_ptr: z_polygon_ptr_type;
  viewport_ptr: viewport_ptr_type;
  projection_ptr: projection_ptr_type);
procedure Clip_and_project_z_line(z_line_ptr: z_line_ptr_type;
  viewport_ptr: viewport_ptr_type;
  projection_ptr: projection_ptr_type);
procedure Clip_and_project_z_point(z_point_ptr: z_point_ptr_type;
  viewport_ptr: viewport_ptr_type;
  projection_ptr: projection_ptr_type);


implementation
uses
  vectors, pixels, rays, clip_planes, clip_regions, clip_lines, z_screen_clip;


{**************************************}
{       clipping to the viewport       }
{**************************************}
{       Orthographic projection        }
{       1) clip to window              }
{                                      }
{       Perspective projection:        }
{       1) clip against view pyramid   }
{       2) project                     }
{                                      }
{       Fisheye, Panoramic projection: }
{       1) clip against view region    }
{       2) project                     }
{       3) clip against window         }
{**************************************}


type
  window_edge_type = (left_edge, right_edge, bottom_edge, top_edge);
  edge_visibility_type = (entirely_visible, entirely_invisible, leaving_visible,
    entering_visible);


var
  {*****************************}
  { extents of the clip pyramid }
  {*****************************}
  z_clip_pyramid: pyramid_type;


{********************************************}
{ routines to enable / disable z_clipping    }
{ (in some circumstances, we may know before }
{ hand that clipping is unneccessary.        }
{********************************************}


procedure Enable_z_clipping;
begin
  z_clipping_enabled := true;
end; {procedure Enable_z_clipping}


procedure Disable_z_clipping;
begin
  z_clipping_enabled := false;
end; {procedure Disable_z_clipping}


{**********************************}
{ routines for clipping to a plane }
{**********************************}


procedure Clip_edge_to_plane(plane: plane_type;
  z_polygon_ptr: z_polygon_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  var intersection_vertex: z_vertex_type;
  var visibility: edge_visibility_type);
var
  edge_vector: vector_type;
  clipped1, clipped2: boolean;
  line: line_type;
  t: real;
begin
  line.point1 := z_vertex_ptr1^.point;
  line.point2 := z_vertex_ptr2^.point;

  Clip_line_to_plane(line, clipped1, clipped2, t, plane);
  if clipped1 then
    begin
      if clipped2 then
        visibility := entirely_invisible
      else
        visibility := entering_visible;
    end
  else
    begin
      if clipped2 then
        visibility := leaving_visible
      else
        visibility := entirely_visible;
    end;

  if (visibility = entering_visible) or (visibility = leaving_visible) then
    begin
      edge_vector := Vector_difference(z_vertex_ptr2^.point,
        z_vertex_ptr1^.point);
      Interpolate_z_vertex(intersection_vertex, z_polygon_ptr, z_vertex_ptr1,
        z_vertex_ptr2, edge_vector, t);
    end;
end; {procedure Clip_edge_to_plane}


procedure Clip_edge_to_origin_plane(normal: vector_type;
  z_polygon_ptr: z_polygon_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  var intersection_vertex: z_vertex_type;
  var visibility: edge_visibility_type);
var
  edge_vector: vector_type;
  clipped1, clipped2: boolean;
  line: line_type;
  t: real;
begin
  line.point1 := z_vertex_ptr1^.point;
  line.point2 := z_vertex_ptr2^.point;

  Clip_line_to_origin_plane(line, clipped1, clipped2, t, normal);
  if clipped1 then
    begin
      if clipped2 then
        visibility := entirely_invisible
      else
        visibility := entering_visible;
    end
  else
    begin
      if clipped2 then
        visibility := leaving_visible
      else
        visibility := entirely_visible;
    end;

  if (visibility = entering_visible) or (visibility = leaving_visible) then
    begin
      edge_vector := Vector_difference(z_vertex_ptr2^.point,
        z_vertex_ptr1^.point);
      Interpolate_z_vertex(intersection_vertex, z_polygon_ptr, z_vertex_ptr1,
        z_vertex_ptr2, edge_vector, t);
    end;
end; {procedure Clip_edge_to_origin_plane}


{**********************************}
{ routines for clipping z polygons }
{**********************************}


procedure Clip_z_polygon_to_plane(z_polygon_ptr: z_polygon_ptr_type;
  plane: plane_type);
var
  edge_visibility: edge_visibility_type;
  clipped_polygon_ptr: z_polygon_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  intersection_vertex: z_vertex_type;
begin
  if z_polygon_ptr <> nil then
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

          {*********************************}
          { clip edge of polygon with plane }
          {*********************************}
          Clip_edge_to_plane(plane, z_polygon_ptr, z_vertex_ptr1, z_vertex_ptr2,
            intersection_vertex, edge_visibility);

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
end; {procedure Clip_z_polygon_to_plane}


procedure Clip_z_polygon_to_origin_plane(z_polygon_ptr: z_polygon_ptr_type;
  normal: vector_type);
var
  edge_visibility: edge_visibility_type;
  clipped_polygon_ptr: z_polygon_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  intersection_vertex: z_vertex_type;
begin
  if z_polygon_ptr <> nil then
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

          {*********************************}
          { clip edge of polygon with plane }
          {*********************************}
          Clip_edge_to_origin_plane(normal, z_polygon_ptr, z_vertex_ptr1,
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
end; {procedure Clip_z_polygon_to_origin_plane}


procedure Clip_z_polygon_to_region(z_polygon_ptr: z_polygon_ptr_type;
  clipping_plane_ptr: clipping_plane_ptr_type);
begin
  while (clipping_plane_ptr <> nil) do
    begin
      with clipping_plane_ptr^ do
        Clip_z_polygon_to_plane(z_polygon_ptr, plane);
      clipping_plane_ptr := clipping_plane_ptr^.next;
    end;
end; {procedure Clip_z_polygon_to_region}


{*******************************}
{ routines for clipping z lines }
{*******************************}


procedure Clip_z_line_to_plane(z_line_ptr: z_polygon_ptr_type;
  plane: plane_type);
var
  follow, current: z_polygon_ptr_type;
  clipped_line_ptr: z_polygon_ptr_type;
  current_line_ptr: z_polygon_ptr_type;
  new_line_ptr: z_polygon_ptr_type;
  edge_visibility: edge_visibility_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  intersection_vertex: z_vertex_type;
begin
  {****************************}
  { clip each polyline in list }
  {****************************}
  follow := z_line_ptr;
  while follow <> nil do
    begin
      current := follow;
      follow := follow^.next;

      {*****************************}
      { clip polyline against plane }
      {*****************************}
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
                {******************************}
                { clip edge of line with plane }
                {******************************}
                Clip_edge_to_plane(plane, z_line_ptr, z_vertex_ptr1,
                  z_vertex_ptr2, intersection_vertex, edge_visibility);

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
                      Add_new_z_vertex(current_line_ptr, intersection_vertex);
                    end;
                  entering_visible:
                    begin
                      {**************************************}
                      { create new line and insert into list }
                      {**************************************}
                      if current_line_ptr^.first <> nil then
                        begin
                          new_line_ptr := New_z_vertex_list(z_line_ptr^.kind,
                            z_line_ptr^.color, z_line_ptr^.textured);
                          current_line_ptr^.next := new_line_ptr;
                          current_line_ptr := new_line_ptr;
                        end;

                      Add_new_z_vertex(current_line_ptr, intersection_vertex);
                      if z_vertex_ptr2^.next = nil then
                        Add_new_z_vertex(current_line_ptr, z_vertex_ptr2^);
                    end;
                end; {case}

                z_vertex_ptr1 := z_vertex_ptr2;
                z_vertex_ptr2 := z_vertex_ptr2^.next;
              end; {while}

            current_line_ptr^.next := current^.next;
            Swap_z_vertex_lists(clipped_line_ptr, current);
            Free_z_vertex_list(clipped_line_ptr);
          end; {for}
    end; {while}
end; {procedure Clip_z_line_to_plane}


procedure Clip_z_line_to_origin_plane(z_line_ptr: z_polygon_ptr_type;
  normal: vector_type);
var
  follow, current: z_polygon_ptr_type;
  clipped_line_ptr: z_polygon_ptr_type;
  current_line_ptr: z_polygon_ptr_type;
  new_line_ptr: z_polygon_ptr_type;
  edge_visibility: edge_visibility_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  intersection_vertex: z_vertex_type;
begin
  {****************************}
  { clip each polyline in list }
  {****************************}
  follow := z_line_ptr;
  while follow <> nil do
    begin
      current := follow;
      follow := follow^.next;

      {*****************************}
      { clip polyline against plane }
      {*****************************}
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
                {******************************}
                { clip edge of line with plane }
                {******************************}
                Clip_edge_to_origin_plane(normal, z_line_ptr, z_vertex_ptr1,
                  z_vertex_ptr2, intersection_vertex, edge_visibility);

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
                      Add_new_z_vertex(current_line_ptr, intersection_vertex);
                    end;
                  entering_visible:
                    begin
                      {**************************************}
                      { create new line and insert into list }
                      {**************************************}
                      if current_line_ptr^.first <> nil then
                        begin
                          new_line_ptr := New_z_vertex_list(z_line_ptr^.kind,
                            z_line_ptr^.color, z_line_ptr^.textured);
                          current_line_ptr^.next := new_line_ptr;
                          current_line_ptr := new_line_ptr;
                        end;

                      Add_new_z_vertex(current_line_ptr, intersection_vertex);
                      if z_vertex_ptr2^.next = nil then
                        Add_new_z_vertex(current_line_ptr, z_vertex_ptr2^);
                    end;
                end; {case}

                z_vertex_ptr1 := z_vertex_ptr2;
                z_vertex_ptr2 := z_vertex_ptr2^.next;
              end; {while}

            current_line_ptr^.next := current^.next;
            Swap_z_vertex_lists(clipped_line_ptr, current);
            Free_z_vertex_list(clipped_line_ptr);
          end; {for}
    end; {while}
end; {procedure Clip_z_line_to_origin_plane}


procedure Clip_z_line_to_region(z_line_ptr: z_polygon_ptr_type;
  clipping_plane_ptr: clipping_plane_ptr_type);
begin
  while (clipping_plane_ptr <> nil) do
    begin
      with clipping_plane_ptr^ do
        Clip_z_line_to_plane(z_line_ptr, plane);
      clipping_plane_ptr := clipping_plane_ptr^.next;
    end;
end; {procedure Clip_z_line_to_region}


{********************************}
{ routines for clipping z points }
{********************************}


procedure Clip_z_point_to_plane(z_point_ptr: z_polygon_ptr_type;
  plane: plane_type);
var
  clipped_point_ptr: z_polygon_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  if z_point_ptr <> nil then
    begin
      clipped_point_ptr := New_z_vertex_list(z_point_ptr^.kind,
        z_point_ptr^.color, z_point_ptr^.textured);
      z_vertex_ptr := z_point_ptr^.first;

      while (z_vertex_ptr <> nil) do
        begin
          {*********************************}
          { clip edge of polygon with plane }
          {*********************************}
          if (Dot_product(Vector_difference(z_vertex_ptr^.point, plane.origin),
            plane.normal) > 0) then
            Add_new_z_vertex(clipped_point_ptr, z_vertex_ptr^);

          z_vertex_ptr := z_vertex_ptr^.next;
        end; {while}

      Swap_z_vertex_lists(clipped_point_ptr, z_point_ptr);
      Free_z_vertex_list(clipped_point_ptr);
    end; {for}
end; {procedure Clip_z_point_to_plane}


procedure Clip_z_point_to_origin_plane(z_point_ptr: z_polygon_ptr_type;
  normal: vector_type);
var
  clipped_point_ptr: z_polygon_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  if z_point_ptr <> nil then
    begin
      clipped_point_ptr := New_z_vertex_list(z_point_ptr^.kind,
        z_point_ptr^.color, z_point_ptr^.textured);
      z_vertex_ptr := z_point_ptr^.first;

      while (z_vertex_ptr <> nil) do
        begin
          {*********************************}
          { clip edge of polygon with plane }
          {*********************************}
          if (Dot_product(z_vertex_ptr^.point, normal) > 0) then
            Add_new_z_vertex(clipped_point_ptr, z_vertex_ptr^);

          z_vertex_ptr := z_vertex_ptr^.next;
        end; {while}

      Swap_z_vertex_lists(clipped_point_ptr, z_point_ptr);
      Free_z_vertex_list(clipped_point_ptr);
    end; {for}
end; {procedure Clip_z_point_to_origin_plane}


procedure Clip_z_point_to_region(z_point_ptr: z_polygon_ptr_type;
  clipping_plane_ptr: clipping_plane_ptr_type);
begin
  while (clipping_plane_ptr <> nil) do
    begin
      with clipping_plane_ptr^ do
        Clip_z_point_to_plane(z_point_ptr, plane);
      clipping_plane_ptr := clipping_plane_ptr^.next;
    end;
end; {procedure Clip_z_point_to_region}


{************************************}
{ routines for clipping to a pyramid }
{************************************}


procedure Clip_edge_to_pyramid(window_edge: window_edge_type;
  z_polygon_ptr: z_polygon_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  var intersection_vertex: z_vertex_type;
  var visibility: edge_visibility_type);
var
  normal: vector_type;
  edge_vector: vector_type;
  clipped1, clipped2: boolean;
  line: line_type;
  t: real;
begin
  line.point1 := z_vertex_ptr1^.point;
  line.point2 := z_vertex_ptr2^.point;

  with z_clip_pyramid.frustrum do
    case window_edge of
      left_edge:
        normal := left_normal;
      right_edge:
        normal := right_normal;
      bottom_edge:
        normal := bottom_normal;
      top_edge:
        normal := top_normal;
    end; {case}

  Clip_line_to_origin_plane(line, clipped1, clipped2, t, normal);
  if clipped1 then
    begin
      if clipped2 then
        visibility := entirely_invisible
      else
        visibility := entering_visible;
    end
  else
    begin
      if clipped2 then
        visibility := leaving_visible
      else
        visibility := entirely_visible;
    end;

  if (visibility = entering_visible) or (visibility = leaving_visible) then
    begin
      edge_vector := Vector_difference(z_vertex_ptr2^.point,
        z_vertex_ptr1^.point);
      Interpolate_z_vertex(intersection_vertex, z_polygon_ptr, z_vertex_ptr1,
        z_vertex_ptr2, edge_vector, t);
    end;
end; {procedure Clip_edge_to_pyramid}


procedure Clip_z_polygon_to_pyramid(z_polygon_ptr: z_polygon_ptr_type;
  pyramid: pyramid_type);
var
  window_edge: window_edge_type;
  clipped_polygon_ptr: z_polygon_ptr_type;
  edge_visibility: edge_visibility_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  intersection_vertex: z_vertex_type;
begin
  z_clip_pyramid := pyramid;

  if z_polygon_ptr <> nil then
    for window_edge := left_edge to top_edge do
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

            {*******************************************}
            { clip edge of polygon with edge of pyramid }
            {*******************************************}
            Clip_edge_to_pyramid(window_edge, z_polygon_ptr, z_vertex_ptr1,
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
end; {procedure Clip_z_polygon_to_pyramid}


procedure Clip_z_line_to_pyramid(z_line_ptr: z_polygon_ptr_type;
  pyramid: pyramid_type);
var
  window_edge: window_edge_type;
  follow, current: z_polygon_ptr_type;
  clipped_line_ptr: z_polygon_ptr_type;
  current_line_ptr: z_polygon_ptr_type;
  new_line_ptr: z_polygon_ptr_type;
  edge_visibility: edge_visibility_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  intersection_vertex: z_vertex_type;
begin
  z_clip_pyramid := pyramid;

  for window_edge := left_edge to top_edge do
    begin
      {****************************}
      { clip each polyline in list }
      {****************************}
      follow := z_line_ptr;
      while (follow <> nil) do
        begin
          current := follow;
          follow := follow^.next;

          {****************************}
          { clip polyline with pyramid }
          {****************************}
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
                    {****************************************}
                    { clip edge of line with edge of pyramid }
                    {****************************************}
                    Clip_edge_to_pyramid(window_edge, z_line_ptr, z_vertex_ptr1,
                      z_vertex_ptr2, intersection_vertex, edge_visibility);

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

                current_line_ptr^.next := current^.next;
                Swap_z_vertex_lists(clipped_line_ptr, current);
                Free_z_vertex_list(clipped_line_ptr);
              end; {if}
        end; {while}
    end; {for}
end; {procedure Clip_z_line_to_pyramid}


procedure Clip_z_point_to_pyramid(z_point_ptr: z_polygon_ptr_type;
  pyramid: pyramid_type);
var
  clipped_point_ptr: z_polygon_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  if z_point_ptr <> nil then
    begin
      clipped_point_ptr := New_z_vertex_list(z_point_ptr^.kind,
        z_point_ptr^.color, z_point_ptr^.textured);
      z_vertex_ptr := z_point_ptr^.first;

      while (z_vertex_ptr <> nil) do
        begin
          {*********************************}
          { clip edge of polygon with plane }
          {*********************************}
          with pyramid.frustrum do
            if (Dot_product(z_vertex_ptr^.point, left_normal) > 0) then
              if (Dot_product(z_vertex_ptr^.point, right_normal) > 0) then
                if (Dot_product(z_vertex_ptr^.point, bottom_normal) > 0) then
                  if (Dot_product(z_vertex_ptr^.point, top_normal) > 0) then
                    Add_new_z_vertex(clipped_point_ptr, z_vertex_ptr^);

          z_vertex_ptr := z_vertex_ptr^.next;
        end; {while}

      Swap_z_vertex_lists(clipped_point_ptr, z_point_ptr);
      Free_z_vertex_list(clipped_point_ptr);
    end; {for}
end; {procedure Clip_z_point_to_pyramid}


{******************************************}
{ routines for clipping to an anti pyramid }
{******************************************}


procedure Clip_z_polygon_to_quadrant(z_polygon_ptr: z_polygon_ptr_type;
  quadrant: quadrant_type);
begin
  Clip_z_polygon_to_origin_plane(z_polygon_ptr, quadrant.normal1);
  Clip_z_polygon_to_origin_plane(z_polygon_ptr, quadrant.normal2);
end; {procedure Clip_z_polygon_to_quadrant}


procedure Clip_z_line_to_quadrant(z_line_ptr: z_polygon_ptr_type;
  quadrant: quadrant_type);
begin
  Clip_z_line_to_origin_plane(z_line_ptr, quadrant.normal1);
  Clip_z_line_to_origin_plane(z_line_ptr, quadrant.normal2);
end; {procedure Clip_z_line_to_quadrant}


procedure Clip_z_polygon_to_anti_pyramid(z_polygon_ptr: z_polygon_ptr_type;
  pyramid: pyramid_type;
  quadrants: quadrants_type);
var
  back_polygon_ptr: z_polygon_ptr_type;

  front_left_polygon_ptr: z_polygon_ptr_type;
  front_right_polygon_ptr: z_polygon_ptr_type;
  front_bottom_polygon_ptr: z_polygon_ptr_type;
  front_top_polygon_ptr: z_polygon_ptr_type;

  back_left_polygon_ptr: z_polygon_ptr_type;
  back_right_polygon_ptr: z_polygon_ptr_type;
  back_bottom_polygon_ptr: z_polygon_ptr_type;
  back_top_polygon_ptr: z_polygon_ptr_type;
begin
  {************************}
  { clip to back hemispace }
  {************************}
  back_polygon_ptr := Copy_z_vertex_list(z_polygon_ptr);
  Clip_z_polygon_to_origin_plane(back_polygon_ptr, neg_y_vector);

  {*************************}
  { clip to front hemispace }
  {*************************}
  Clip_z_polygon_to_origin_plane(z_polygon_ptr, y_vector);

  with pyramid.frustrum do
    begin
      left_normal.y := -left_normal.y;
      right_normal.y := -right_normal.y;
      bottom_normal.y := -bottom_normal.y;
      top_normal.y := -top_normal.y;
    end;

  with quadrants do
    begin
      {**********************}
      { clip front quadrants }
      {**********************}

      {*****************************}
      { clip to front left quadrant }
      {*****************************}
      front_left_polygon_ptr := Copy_z_vertex_list(z_polygon_ptr);
      Clip_z_polygon_to_quadrant(front_left_polygon_ptr, left_quadrant);

      {******************************}
      { clip to front right quadrant }
      {******************************}
      front_right_polygon_ptr := Copy_z_vertex_list(z_polygon_ptr);
      Clip_z_polygon_to_quadrant(front_right_polygon_ptr, right_quadrant);

      {*******************************}
      { clip to front bottom quadrant }
      {*******************************}
      front_bottom_polygon_ptr := Copy_z_vertex_list(z_polygon_ptr);
      Clip_z_polygon_to_quadrant(front_bottom_polygon_ptr, bottom_quadrant);

      {***************************}
      { clip to back top quadrant }
      {***************************}
      front_top_polygon_ptr := z_polygon_ptr;
      Clip_z_polygon_to_quadrant(front_top_polygon_ptr, top_quadrant);

      {*********************************}
      { splice together front quadrants }
      {*********************************}
      z_polygon_ptr^.next := front_left_polygon_ptr;
      front_left_polygon_ptr^.next := front_right_polygon_ptr;
      front_right_polygon_ptr^.next := front_bottom_polygon_ptr;

      {*********************}
      { clip back quadrants }
      {*********************}

      {****************************}
      { clip to back left quadrant }
      {****************************}
      back_left_polygon_ptr := Copy_z_vertex_list(back_polygon_ptr);
      Clip_z_polygon_to_quadrant(back_left_polygon_ptr, left_quadrant);
      Clip_z_polygon_to_origin_plane(back_left_polygon_ptr,
        pyramid.frustrum.left_normal);

      {*****************************}
      { clip to back right quadrant }
      {*****************************}
      back_right_polygon_ptr := Copy_z_vertex_list(back_polygon_ptr);
      Clip_z_polygon_to_quadrant(back_right_polygon_ptr, right_quadrant);
      Clip_z_polygon_to_origin_plane(back_right_polygon_ptr,
        pyramid.frustrum.right_normal);

      {******************************}
      { clip to back bottom quadrant }
      {******************************}
      back_bottom_polygon_ptr := Copy_z_vertex_list(back_polygon_ptr);
      Clip_z_polygon_to_quadrant(back_bottom_polygon_ptr, bottom_quadrant);
      Clip_z_polygon_to_origin_plane(back_bottom_polygon_ptr,
        pyramid.frustrum.bottom_normal);

      {***************************}
      { clip to back top quadrant }
      {***************************}
      back_top_polygon_ptr := back_polygon_ptr;
      Clip_z_polygon_to_quadrant(back_top_polygon_ptr, top_quadrant);
      Clip_z_polygon_to_origin_plane(back_top_polygon_ptr,
        pyramid.frustrum.top_normal);

      {**********************************}
      { string polygon segments together }
      {**********************************}
      front_bottom_polygon_ptr^.next := back_left_polygon_ptr;
      back_left_polygon_ptr^.next := back_right_polygon_ptr;
      back_right_polygon_ptr^.next := back_bottom_polygon_ptr;
      back_bottom_polygon_ptr^.next := back_top_polygon_ptr;
    end;
end; {procedure Clip_z_polygon_to_anti_pyramid}


procedure Append_z_lines(z_line_ptr1, z_line_ptr2: z_polygon_ptr_type);
var
  follow: z_polygon_ptr_type;
begin
  {**********************************}
  { append line2 to the end of line1 }
  {**********************************}
  follow := z_line_ptr1;
  while (follow^.next <> nil) do
    follow := follow^.next;
  follow^.next := z_line_ptr2;
end; {procedure Append_z_line}


procedure Clip_z_line_to_anti_pyramid(z_line_ptr: z_polygon_ptr_type;
  pyramid: pyramid_type;
  quadrants: quadrants_type);
var
  back_line_ptr: z_polygon_ptr_type;

  front_left_line_ptr: z_polygon_ptr_type;
  front_right_line_ptr: z_polygon_ptr_type;
  front_bottom_line_ptr: z_polygon_ptr_type;
  front_top_line_ptr: z_polygon_ptr_type;

  back_left_line_ptr: z_polygon_ptr_type;
  back_right_line_ptr: z_polygon_ptr_type;
  back_bottom_line_ptr: z_polygon_ptr_type;
  back_top_line_ptr: z_polygon_ptr_type;
begin
  {************************}
  { clip to back hemispace }
  {************************}
  back_line_ptr := Copy_z_vertex_list(z_line_ptr);
  Clip_z_line_to_origin_plane(back_line_ptr, neg_y_vector);

  {*************************}
  { clip to front hemispace }
  {*************************}
  Clip_z_line_to_origin_plane(z_line_ptr, y_vector);

  with pyramid.frustrum do
    begin
      left_normal.y := -left_normal.y;
      right_normal.y := -right_normal.y;
      bottom_normal.y := -bottom_normal.y;
      top_normal.y := -top_normal.y;
    end;

  with quadrants do
    begin
      {**********************}
      { clip front quadrants }
      {**********************}

      {*****************************}
      { clip to front left quadrant }
      {*****************************}
      front_left_line_ptr := Copy_z_vertex_list(z_line_ptr);
      Clip_z_line_to_quadrant(front_left_line_ptr, left_quadrant);

      {******************************}
      { clip to front right quadrant }
      {******************************}
      front_right_line_ptr := Copy_z_vertex_list(z_line_ptr);
      Clip_z_line_to_quadrant(front_right_line_ptr, right_quadrant);

      {*******************************}
      { clip to front bottom quadrant }
      {*******************************}
      front_bottom_line_ptr := Copy_z_vertex_list(z_line_ptr);
      Clip_z_line_to_quadrant(front_bottom_line_ptr, bottom_quadrant);

      {***************************}
      { clip to back top quadrant }
      {***************************}
      front_top_line_ptr := z_line_ptr;
      Clip_z_line_to_quadrant(front_top_line_ptr, top_quadrant);

      {*********************************}
      { splice together front quadrants }
      {*********************************}
      Append_z_lines(z_line_ptr, front_left_line_ptr);
      Append_z_lines(front_left_line_ptr, front_right_line_ptr);
      Append_z_lines(front_right_line_ptr, front_bottom_line_ptr);

      {*********************}
      { clip back quadrants }
      {*********************}

      {****************************}
      { clip to back left quadrant }
      {****************************}
      back_left_line_ptr := Copy_z_vertex_list(back_line_ptr);
      Clip_z_line_to_quadrant(back_left_line_ptr, left_quadrant);
      Clip_z_line_to_origin_plane(back_left_line_ptr,
        pyramid.frustrum.left_normal);

      {*****************************}
      { clip to back right quadrant }
      {*****************************}
      back_right_line_ptr := Copy_z_vertex_list(back_line_ptr);
      Clip_z_line_to_quadrant(back_right_line_ptr, right_quadrant);
      Clip_z_line_to_origin_plane(back_right_line_ptr,
        pyramid.frustrum.right_normal);

      {******************************}
      { clip to back bottom quadrant }
      {******************************}
      back_bottom_line_ptr := Copy_z_vertex_list(back_line_ptr);
      Clip_z_line_to_quadrant(back_bottom_line_ptr, bottom_quadrant);
      Clip_z_line_to_origin_plane(back_bottom_line_ptr,
        pyramid.frustrum.bottom_normal);

      {***************************}
      { clip to back top quadrant }
      {***************************}
      back_top_line_ptr := back_line_ptr;
      Clip_z_line_to_quadrant(back_top_line_ptr, top_quadrant);
      Clip_z_line_to_origin_plane(back_top_line_ptr,
        pyramid.frustrum.top_normal);

      {*******************************}
      { string line segments together }
      {*******************************}
      Append_z_lines(front_bottom_line_ptr, back_left_line_ptr);
      Append_z_lines(back_left_line_ptr, back_right_line_ptr);
      Append_z_lines(back_right_line_ptr, back_bottom_line_ptr);
      Append_z_lines(back_bottom_line_ptr, back_top_line_ptr);
    end;
end; {procedure Clip_z_line_to_anti_pyramid}


{***************************}
{ general clipping routines }
{***************************}


procedure Check_z_polygon(message: string;
  z_polygon_ptr: z_polygon_ptr_type);
var
  z_vertex_ptr: z_vertex_ptr_type;
  error: boolean;
begin
  error := false;
  z_vertex_ptr := z_polygon_ptr^.first;
  while (z_vertex_ptr <> nil) do
    begin
      if not Vector_ok(z_vertex_ptr^.point) then
        begin
          if not error then
            writeln(message);

          error := true;
          with z_vertex_ptr^.point do
            writeln('Error - point = ', x, y, z);
        end;
      z_vertex_ptr := z_vertex_ptr^.next;
    end;
  if error then
    writeln;
end; {procedure Check_z_polygon}


procedure Project_z_polygon(z_polygon_ptr: z_polygon_ptr_type);
var
  z_vertex_ptr: z_vertex_ptr_type;
begin
  {******************************}
  { project all polygons in list }
  {******************************}
  while (z_polygon_ptr <> nil) do
    begin
      {*********************************}
      { project all vertices in polygon }
      {*********************************}
      z_vertex_ptr := z_polygon_ptr^.first;
      while (z_vertex_ptr <> nil) do
        begin
          z_vertex_ptr^.point := Project_point_to_point(z_vertex_ptr^.point);
          z_vertex_ptr := z_vertex_ptr^.next;
        end;
      z_polygon_ptr := z_polygon_ptr^.next;
    end;
end; {procedure Project_z_polygon}


procedure Reverse_project_z_polygon(z_polygon_ptr: z_polygon_ptr_type);
var
  z_vertex_ptr: z_vertex_ptr_type;
  ray: ray_type;
begin
  {******************************}
  { project all polygons in list }
  {******************************}
  while (z_polygon_ptr <> nil) do
    begin
      {*********************************}
      { project all vertices in polygon }
      {*********************************}
      z_vertex_ptr := z_polygon_ptr^.first;
      while (z_vertex_ptr <> nil) do
        begin
          ray := Project_point_to_ray(z_vertex_ptr^.point);
          z_vertex_ptr^.vertex := Vector_sum(ray.location, ray.direction);
          z_vertex_ptr := z_vertex_ptr^.next;
        end;
      z_polygon_ptr := z_polygon_ptr^.next;
    end;
end; {procedure Reverse_project_z_polygon}


procedure Write_z_polygons(z_polygon_ptr: z_polygon_ptr_type);
begin
  writeln('z_polygons:');
  while (z_polygon_ptr <> nil) do
    begin
      Write_z_vertex_list(z_polygon_ptr);
      z_polygon_ptr := z_polygon_ptr^.next;
    end;
  writeln;
end; {procedure Write_z_polygons}


procedure Clip_and_project_z_polygon(z_polygon_ptr: z_polygon_ptr_type;
  viewport_ptr: viewport_ptr_type;
  projection_ptr: projection_ptr_type);
begin
  {*******************************************}
  { clip against user defined clipping planes }
  {*******************************************}
  Clip_z_polygon_to_region(z_polygon_ptr, clipping_planes_ptr);

  {************************}
  { clip to viewing region }
  {************************}
  with viewport_ptr^ do
    case kind of

      orthographic:
        begin
          Clip_z_polygon_to_origin_plane(z_polygon_ptr, y_vector);
          Project_z_polygon(z_polygon_ptr);
          Clip_z_polygon_to_screen_box(z_polygon_ptr,
            projection_ptr^.screen_box);
        end;

      perspective:
        begin
          Clip_z_polygon_to_pyramid(z_polygon_ptr, clip_pyramid);
          Project_z_polygon(z_polygon_ptr);
        end;

      fisheye, panoramic:
        begin
          if convex then
            begin
              Clip_z_polygon_to_pyramid(z_polygon_ptr, outer_pyramid);
              Project_z_polygon(z_polygon_ptr);
              Clip_z_polygon_to_screen_box(z_polygon_ptr,
                projection_ptr^.screen_box);
            end
          else if not concave then
            begin
              Clip_z_polygon_to_origin_plane(z_polygon_ptr, y_vector);
              Project_z_polygon(z_polygon_ptr);
              Clip_z_polygon_to_screen_box(z_polygon_ptr,
                projection_ptr^.screen_box);
            end
          else
            begin
              Clip_z_polygon_to_anti_pyramid(z_polygon_ptr, outer_pyramid,
                quadrants);
              Project_z_polygon(z_polygon_ptr);
              Clip_z_polygons_to_screen_box(z_polygon_ptr,
                projection_ptr^.screen_box);
            end;
        end;
    end;
end; {procedure Clip_and_project_z_polygon}


procedure Clip_and_project_z_line(z_line_ptr: z_line_ptr_type;
  viewport_ptr: viewport_ptr_type;
  projection_ptr: projection_ptr_type);
begin
  {*******************************************}
  { clip against user defined clipping planes }
  {*******************************************}
  Clip_z_line_to_region(z_line_ptr, clipping_planes_ptr);

  {************************}
  { clip to viewing region }
  {************************}
  with viewport_ptr^ do
    case kind of

      orthographic:
        begin
          Clip_z_line_to_origin_plane(z_line_ptr, y_vector);
          Project_z_polygon(z_line_ptr);
          Clip_z_line_to_screen_box(z_line_ptr, projection_ptr^.screen_box);
        end;

      perspective:
        begin
          Clip_z_line_to_pyramid(z_line_ptr, clip_pyramid);
          Project_z_polygon(z_line_ptr);
        end;

      fisheye, panoramic:
        begin
          if convex then
            begin
              Clip_z_line_to_pyramid(z_line_ptr, outer_pyramid);
              Project_z_polygon(z_line_ptr);
              Clip_z_line_to_screen_box(z_line_ptr, projection_ptr^.screen_box);
            end
          else if not concave then
            begin
              Clip_z_line_to_origin_plane(z_line_ptr, y_vector);
              Project_z_polygon(z_line_ptr);
              Clip_z_line_to_screen_box(z_line_ptr, projection_ptr^.screen_box);
            end
          else
            begin
              Clip_z_line_to_anti_pyramid(z_line_ptr, outer_pyramid, quadrants);
              Project_z_polygon(z_line_ptr);
              Clip_z_line_to_screen_box(z_line_ptr, projection_ptr^.screen_box);
            end;
        end;
    end;
end; {procedure Clip_and_project_z_line}


procedure Clip_and_project_z_point(z_point_ptr: z_point_ptr_type;
  viewport_ptr: viewport_ptr_type;
  projection_ptr: projection_ptr_type);
begin
  {*******************************************}
  { clip against user defined clipping planes }
  {*******************************************}
  Clip_z_point_to_region(z_point_ptr, clipping_planes_ptr);

  {************************}
  { clip to viewing region }
  {************************}
  with viewport_ptr^ do
    case kind of

      orthographic:
        begin
          Clip_z_point_to_origin_plane(z_point_ptr, y_vector);
          Project_z_polygon(z_point_ptr);
          Clip_z_point_to_screen_box(z_point_ptr, projection_ptr^.screen_box);
        end;

      perspective:
        begin
          Clip_z_point_to_pyramid(z_point_ptr, clip_pyramid);
          Project_z_polygon(z_point_ptr);
        end;

      fisheye, panoramic:
        begin
          if convex then
            begin
              Project_z_polygon(z_point_ptr);
              Clip_z_point_to_screen_box(z_point_ptr,
                projection_ptr^.screen_box);
            end
          else if not concave then
            begin
              Project_z_polygon(z_point_ptr);
              Clip_z_point_to_screen_box(z_point_ptr,
                projection_ptr^.screen_box);
            end
          else
            begin
              Project_z_polygon(z_point_ptr);
              Clip_z_point_to_screen_box(z_point_ptr,
                projection_ptr^.screen_box);
            end;
        end;
    end;
end; {procedure Clip_and_project_z_point}


end.
