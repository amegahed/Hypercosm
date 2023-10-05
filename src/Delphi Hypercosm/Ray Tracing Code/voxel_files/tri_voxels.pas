unit tri_voxels;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             tri_voxels                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module creates the spatial database needed         }
{       to raytrace the triangulaed mesh.                       }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans, raytrace, drawable;


procedure Voxelize_triangles(drawable: drawable_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  mesh_trans, scene_trans: trans_type);


implementation
uses
  constants, colors, vectors, coord_axes, extents, bounds, project, visibility,
  triangles, state_vars, object_attr, viewing, show_lines, show_b_rep;


const
  min_voxel_subdivision = 1;
  max_voxel_subdivision = 5; {maximum depth of voxel octree structure}
  max_triangles_per_voxel = 12; {maximum # of triangle references per voxel}


var
  {**********************************}
  { variables used for voxel preview }
  {**********************************}
  voxel_trans: trans_type;


function Triangle_disjoint_from_extent_box(point1, point2, point3: vector_type;
  extent_box: extent_box_type): boolean;
var
  counter: extent_type;
  counter1: integer;
  disjoint, side_disjoint: boolean;
  triangle: array[1..3] of vector_type;
  point: vector_type;
begin
  disjoint := false;
  triangle[1] := point1;
  triangle[2] := point2;
  triangle[3] := point3;

  {*******************************}
  { check each side of extent_box }
  {*******************************}
  for counter := left to top do
    if not disjoint then
      begin
        {*****************************}
        { check all corners of square }
        { against side of extent_box  }
        {*****************************}
        side_disjoint := true;

        for counter1 := 1 to 3 do
          if side_disjoint then
            begin
              point := triangle[counter1];

              case (counter) of
                left:
                  if point.x >= extent_box[left] then
                    side_disjoint := false;
                right:
                  if point.x <= extent_box[right] then
                    side_disjoint := false;
                front:
                  if point.y >= extent_box[front] then
                    side_disjoint := false;
                back:
                  if point.y <= extent_box[back] then
                    side_disjoint := false;
                bottom:
                  if point.z >= extent_box[bottom] then
                    side_disjoint := false;
                top:
                  if point.z <= extent_box[top] then
                    side_disjoint := false;
              end; {case statement}
            end;
        {************************}
        { were all points tested }
        {************************}
        if side_disjoint then
          disjoint := true;
      end;
  Triangle_disjoint_from_extent_box := disjoint;
end; {function Triangle_disjoint_from_extent_box}


function Triangle_edges_in_extent_box(point1, point2, point3: vector_type;
  extent_box: extent_box_type): boolean;
var
  inside: boolean;
begin
  {*********************************************}
  { if all edges fail to intersect extent_box   }
  { then inside = false otherwise inside = true }
  {*********************************************}
  inside := true;
  if not Line_in_extent_box(point1, point2, extent_box) then
    if not Line_in_extent_box(point2, point3, extent_box) then
      if not Line_in_extent_box(point3, point1, extent_box) then
        inside := false;

  Triangle_edges_in_extent_box := inside;
end; {function Triangle_edges_in_extent_box}


function Line_in_unit_triangle(point1, point2: vector_type): boolean;
var
  z_direction: real;
  x, y: real;
  in_triangle: boolean;
  t: real;
begin
  in_triangle := false;
  z_direction := point2.z - point1.z;
  if (z_direction <> 0) then
    begin
      t := (-point1.z) / z_direction;
      if (t > -tiny) and (t < (1 + tiny)) then
        begin {check to see if in unit triangle}
          x := point1.x + (t * (point2.x - point1.x));
          y := point1.y + (t * (point2.y - point1.y));
          if (x > 0) and (y > 0) and (x + y < 1) then
            in_triangle := true;
        end;
    end;
  Line_in_unit_triangle := in_triangle;
end; {function Line_in_unit_triangle}


function Box_edges_in_unit_triangle(box: bounding_box_type): boolean;
var
  inside: boolean;
begin
  {**********************************************}
  { if all edges fail to intersect triangle then }
  { inside = false otherwise inside = true       }
  {**********************************************}
  inside := true;

  {***********}
  { top edges }
  {***********}
  if not Line_in_unit_triangle(box[right, front, top], box[right, back, top])
    then
    if not Line_in_unit_triangle(box[right, back, top], box[left, back, top])
      then
      if not Line_in_unit_triangle(box[left, back, top], box[left, front, top])
        then
        if not Line_in_unit_triangle(box[left, front, top], box[right, front,
          top]) then
          {**************}
          { bottom edges }
          {**************}
          if not Line_in_unit_triangle(box[right, front, bottom], box[right,
            back, bottom]) then
            if not Line_in_unit_triangle(box[right, back, bottom], box[left,
              back, bottom]) then
              if not Line_in_unit_triangle(box[left, back, bottom], box[left,
                front, bottom]) then
                if not Line_in_unit_triangle(box[left, front, bottom],
                  box[right, front, bottom]) then
                  {************}
                  { side edges }
                  {************}
                  if not Line_in_unit_triangle(box[right, front, bottom],
                    box[right, front, top]) then
                    if not Line_in_unit_triangle(box[right, back, bottom],
                      box[right, back, top]) then
                      if not Line_in_unit_triangle(box[left, back, bottom],
                        box[left, back, top]) then
                        if not Line_in_unit_triangle(box[left, front, bottom],
                          box[left, front, top]) then
                          inside := false;

  Box_edges_in_unit_triangle := inside;
end; {function Box_edges_in_unit_triangle}


function Triangle_in_extent_box(triangle_ptr: triangle_ptr_type;
  extent_box: extent_box_type): boolean;
var
  point1, point2, point3: vector_type;
  inside, done: boolean;
  counter1, counter2, counter3: extent_type;
  extent_box_bounding_box: bounding_box_type;
  trans: trans_type;
begin
  done := false;
  inside := false;

  point1 := triangle_ptr^.vertex_ptr1^.point_ptr^.point_geometry_ptr^.point;
  point2 := triangle_ptr^.vertex_ptr2^.point_ptr^.point_geometry_ptr^.point;
  point3 := triangle_ptr^.vertex_ptr3^.point_ptr^.point_geometry_ptr^.point;
  trans := triangle_ptr^.trans;

  {*********************************************************}
  { test #1 - are any corners of triangle inside extent_box }
  {*********************************************************}
  if Point_in_extent_box(point1, extent_box) then
    begin
      inside := true;
      done := true;
    end
  else if Point_in_extent_box(point2, extent_box) then
    begin
      inside := true;
      done := true;
    end
  else if Point_in_extent_box(point3, extent_box) then
    begin
      inside := true;
      done := true;
    end;

  {************************************************}
  { test #2 - are triangle and extent_box disjoint }
  {************************************************}
  if not done then {continue testing}
    if Triangle_disjoint_from_extent_box(point1, point2, point3, extent_box)
      then
      begin
        inside := false;
        done := true;
      end;

  {*******************************************************}
  { test #3 - do any edges of square intersect extent_box }
  {*******************************************************}
  if not done then {continue testing}
    if Triangle_edges_in_extent_box(point1, point2, point3, extent_box) then
      begin
        inside := true;
        done := true;
      end;

  {*********************************************************}
  { test #4 - do any edges of extent_box intersect triangle }
  {*********************************************************}
  if not done then {continue testing}
    begin
      Make_bounding_box_from_extent_box(extent_box_bounding_box, extent_box);
      for counter1 := left to right do
        for counter2 := front to back do
          for counter3 := bottom to top do
            Transform_point(extent_box_bounding_box[counter1, counter2,
              counter3], trans);
      if Box_edges_in_unit_triangle(extent_box_bounding_box) then
        begin
          inside := true;
        end;
    end;

  Triangle_in_extent_box := inside;
end; {function Triangle_in_extent_box}


procedure Draw_triangle_voxel(drawable: drawable_type;
  triangle_voxel_ptr: triangle_voxel_ptr_type);
var
  box: bounding_box_type;
  counter1, counter2, counter3: extent_type;
  color_num: integer;
begin
  {*******************************************}
  { set color based on nesting level of voxel }
  {*******************************************}
  color_num := triangle_voxel_ptr^.subdivision_level mod 3;
  if (color_num = 0) then
    Set_line_color(drawable, red_color)
  else if (color_num = 1) then
    Set_line_color(drawable, green_color)
  else if (color_num = 2) then
    Set_line_color(drawable, blue_color);

  {*********************}
  { draw edges of voxel }
  {*********************}
  Make_bounding_box_from_extent_box(box, triangle_voxel_ptr^.extent_box);
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        Transform_point(box[counter1, counter2, counter3], voxel_trans);
  Show_bounding_box(drawable, box);
end; {procedure Draw_triangle_voxel}


function Too_many_triangles(triangle_voxel_ptr: triangle_voxel_ptr_type):
  boolean;
var
  follow: triangle_node_ref_ptr_type;
  triangle_count: integer;
  triangle_ptr: triangle_ptr_type;
begin
  follow := triangle_voxel_ptr^.triangle_node_ref_ptr;
  triangle_count := 0;
  while (follow <> nil) and (triangle_count <= max_triangles_per_voxel) do
    begin
      triangle_ptr := follow^.triangle_node_ptr^.triangle_ptr;
      if Triangle_in_extent_box(triangle_ptr, triangle_voxel_ptr^.extent_box)
        then
        triangle_count := triangle_count + 1;
      follow := follow^.next;
    end;
  if (triangle_count > max_triangles_per_voxel) then
    Too_many_triangles := true
  else
    Too_many_triangles := false;
end; {function Too_many_triangles}


procedure Copy_triangle_node_refs(triangle_node_ref_ptr:
  triangle_node_ref_ptr_type;
  subvoxel_ptr: triangle_voxel_ptr_type);
var
  triangle_ptr: triangle_ptr_type;
  temp_triangle_node_ref_ptr: triangle_node_ref_ptr_type;
begin
  while (triangle_node_ref_ptr <> nil) do
    begin
      triangle_ptr := triangle_node_ref_ptr^.triangle_node_ptr^.triangle_ptr;
      if Triangle_in_extent_box(triangle_ptr, subvoxel_ptr^.extent_box) then
        begin
          {************************************}
          { make new object reference node and }
          { initialize the new object_ref node }
          {************************************}
          temp_triangle_node_ref_ptr := New_triangle_node_ref;
          temp_triangle_node_ref_ptr^.triangle_node_ptr :=
            triangle_node_ref_ptr^.triangle_node_ptr;

          {************************}
          { insert at head of list }
          {************************}
          temp_triangle_node_ref_ptr^.next :=
            subvoxel_ptr^.triangle_node_ref_ptr;
          subvoxel_ptr^.triangle_node_ref_ptr := temp_triangle_node_ref_ptr;
        end;
      triangle_node_ref_ptr := triangle_node_ref_ptr^.next;
    end; {while loop}
end; {procedure Copy_triangle_node_refs}


procedure Subdivide_triangle_voxel(drawable: drawable_type;
  triangle_voxel_ptr: triangle_voxel_ptr_type);
var
  temp_neighbor_voxel_ptr: array[extent_type] of triangle_voxel_ptr_type;
  temp_triangle_node_ref_ptr: triangle_node_ref_ptr_type;
  counter1, counter2, counter3: extent_type;
  center: vector_type;
begin
  {******************************}
  { change voxel from leaf voxel }
  { to an internal tree node -   }
  { make into a subdivided voxel }
  {******************************}
  center := Extent_box_center(triangle_voxel_ptr^.extent_box);
  for counter1 := left to top do
    temp_neighbor_voxel_ptr[counter1] :=
      triangle_voxel_ptr^.neighbor_voxel_ptr[counter1];
  triangle_voxel_ptr^.subdivided := true;
  temp_triangle_node_ref_ptr := triangle_voxel_ptr^.triangle_node_ref_ptr;

  {**************************}
  { allocate 8 new subvoxels }
  {**************************}
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        triangle_voxel_ptr^.subvoxel_ptr[counter1, counter2, counter3] :=
          New_triangle_voxel;

  {**************************}
  { initialize new subvoxels }
  {**************************}
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        with triangle_voxel_ptr^.subvoxel_ptr[counter1, counter2, counter3]^ do
          begin
            subdivision_level := triangle_voxel_ptr^.subdivision_level + 1;
            subdivided := false;
            triangle_node_ref_ptr := nil;

            extent_box[counter1] := triangle_voxel_ptr^.extent_box[counter1];
            extent_box[counter2] := triangle_voxel_ptr^.extent_box[counter2];
            extent_box[counter3] := triangle_voxel_ptr^.extent_box[counter3];
            extent_box[Opposite_extent(counter1)] := center.x;
            extent_box[Opposite_extent(counter2)] := center.y;
            extent_box[Opposite_extent(counter3)] := center.z;

            {*************************************}
            { sides of subvoxel pointing outwards }
            {*************************************}
            neighbor_voxel_ptr[counter1] := temp_neighbor_voxel_ptr[counter1];
            neighbor_voxel_ptr[counter2] := temp_neighbor_voxel_ptr[counter2];
            neighbor_voxel_ptr[counter3] := temp_neighbor_voxel_ptr[counter3];

            {************************************}
            { sides of subvoxel pointing inwards }
            {************************************}
            neighbor_voxel_ptr[Opposite_extent(counter1)] :=
              triangle_voxel_ptr^.subvoxel_ptr[Opposite_extent(counter1),
              counter2, counter3];
            neighbor_voxel_ptr[Opposite_extent(counter2)] :=
              triangle_voxel_ptr^.subvoxel_ptr[counter1,
              Opposite_extent(counter2), counter3];
            neighbor_voxel_ptr[Opposite_extent(counter3)] :=
              triangle_voxel_ptr^.subvoxel_ptr[counter1, counter2,
              Opposite_extent(counter3)];

            if draw_voxels then
              Draw_triangle_voxel(drawable,
                triangle_voxel_ptr^.subvoxel_ptr[counter1,
                counter2, counter3]);
            Copy_triangle_node_refs(temp_triangle_node_ref_ptr,
              triangle_voxel_ptr^.subvoxel_ptr[counter1, counter2, counter3]);
          end;
  Free_triangle_node_refs(temp_triangle_node_ref_ptr);

  if draw_voxels then
    drawable.Update;
end; {procedure Subdivide_triangle_voxel}


procedure Subdivide_octree_level(drawable: drawable_type;
  triangle_voxel_ptr: triangle_voxel_ptr_type;
  subdivision_level: integer;
  var done: boolean);
var
  counter1, counter2, counter3: extent_type;
  subvoxel_done: boolean;
begin
  if (triangle_voxel_ptr^.subdivision_level < subdivision_level) then
    begin
      {*********************************}
      { traverse octree until we are at }
      { the subdivision level (fringe)  }
      {*********************************}
      done := true;
      if (triangle_voxel_ptr^.subdivided) then
        for counter1 := left to right do
          for counter2 := front to back do
            for counter3 := bottom to top do
              begin
                Subdivide_octree_level(drawable,
                  triangle_voxel_ptr^.subvoxel_ptr[counter1, counter2, counter3],
                  subdivision_level, subvoxel_done);

                {**********************************************}
                { if all subvoxels are done then this voxel is }
                { done, otherwise, this voxel is not done yet. }
                {**********************************************}
                if (not subvoxel_done) then
                  done := false;
              end;
    end
  else
    {******************************************}
    { we are at the subdivision level (fringe) }
    {******************************************}
    begin
      {**********************************}
      { if neccessary, subdivide further }
      {**********************************}
      if (Too_many_triangles(triangle_voxel_ptr)) or (subdivision_level <=
        min_voxel_subdivision) then
        begin
          Subdivide_triangle_voxel(drawable, triangle_voxel_ptr);
          done := false;
        end
      else
        done := true;
    end;
end; {procedure Subdivide_octree_level}


procedure Link_octree_fringe(triangle_voxel_ptr: triangle_voxel_ptr_type;
  subdivision_level: integer);
var
  counter1, counter2, counter3, counter4: extent_type;
  neighbor_voxel_ptr, subvoxel_ptr: triangle_voxel_ptr_type;
begin
  if (triangle_voxel_ptr^.subdivision_level < subdivision_level) then
    begin
      {****************************************}
      { traverse octree until we are one level }
      { above the subdivision level  (fringe)  }
      {****************************************}
      if (triangle_voxel_ptr^.subdivided) then
        for counter1 := left to right do
          for counter2 := front to back do
            for counter3 := bottom to top do
              Link_octree_fringe(triangle_voxel_ptr^.subvoxel_ptr[counter1,
                counter2, counter3], subdivision_level);
    end

      {******************************************}
      { at one level above the subdivision level }
      { link triangles of neighboring subvoxels  }
      {******************************************}
  else if (triangle_voxel_ptr^.subdivided) then
    {********************}
    { link each triangle }
    {********************}
    for counter4 := left to top do
      for counter1 := left to right do
        for counter2 := front to back do
          for counter3 := bottom to top do
            begin
              subvoxel_ptr := triangle_voxel_ptr^.subvoxel_ptr[counter1,
                counter2, counter3];
              neighbor_voxel_ptr := subvoxel_ptr^.neighbor_voxel_ptr[counter4];
              if (neighbor_voxel_ptr <> nil) then
                if (neighbor_voxel_ptr^.subdivision_level = subdivision_level)
                  then
                  if (neighbor_voxel_ptr^.subdivided) then
                    begin
                      if (counter4 = counter1) then
                        subvoxel_ptr^.neighbor_voxel_ptr[counter4] :=
                          neighbor_voxel_ptr^.subvoxel_ptr[Opposite_extent(counter1),
                            counter2, counter3]
                      else if (counter4 = counter2) then
                        subvoxel_ptr^.neighbor_voxel_ptr[counter4] :=
                          neighbor_voxel_ptr^.subvoxel_ptr[counter1,
                          Opposite_extent(counter2), counter3]
                      else if (counter4 = counter3) then
                        subvoxel_ptr^.neighbor_voxel_ptr[counter4] :=
                          neighbor_voxel_ptr^.subvoxel_ptr[counter1, counter2,
                          Opposite_extent(counter3)];
                    end;
            end;
end; {procedure Link_octree_fringe}


procedure Draw_mesh(drawable: drawable_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  trans: trans_type);
var
  object_ptr: view_object_inst_ptr_type;
begin
  Set_line_color(drawable, black_color);
  drawable.Clear;
  object_ptr := New_view_object_inst;

  object_ptr^.kind := view_object_prim;
  object_ptr^.surface_ptr := ray_object_ptr^.ray_mesh_data_ptr^.surface_ptr;
  object_ptr^.trans := unit_trans;
  object_ptr^.bounding_kind := non_planar_bounds;

  object_ptr^.attributes := ray_object_ptr^.attributes;
  Set_render_mode_attributes(object_ptr^.attributes, wireframe_mode);
  Set_edge_mode_attributes(object_ptr^.attributes, outline_edges);

  Show_scene(drawable, object_ptr, trans, 1);
  Free_view_object_inst(object_ptr);
end; {procedure Draw_mesh}


procedure Build_triangle_voxels(drawable: drawable_type;
  ray_mesh_data_ptr: ray_mesh_data_ptr_type);
var
  voxel_space_ptr: triangle_voxel_ptr_type;
  triangle_node_ref_ptr: triangle_node_ref_ptr_type;
  triangle_node_ptr: triangle_node_ptr_type;
  triangle_ptr: triangle_ptr_type;
  subdivision_level: integer;
  counter: extent_type;
  done: boolean;
begin
  {**************************}
  { make root triangle voxel }
  {**************************}
  ray_mesh_data_ptr^.triangle_voxel_ptr := New_triangle_voxel;
  voxel_space_ptr := ray_mesh_data_ptr^.triangle_voxel_ptr;
  with voxel_space_ptr^ do
    begin
      subdivided := false;
      triangle_node_ref_ptr := nil;
      subdivision_level := 1;
      extent_box := unit_extent_box;
      for counter := left to top do
        neighbor_voxel_ptr[counter] := nil;
    end;

  {*********************}
  { make triangle nodes }
  {*********************}
  triangle_ptr := ray_mesh_data_ptr^.triangle_ptr;
  ray_mesh_data_ptr^.triangle_node_ptr := nil;
  while (triangle_ptr <> nil) do
    begin
      triangle_node_ptr := New_triangle_node;
      triangle_node_ptr^.triangle_ptr := triangle_ptr;
      triangle_ptr := triangle_ptr^.next;

      {************************}
      { insert at head of list }
      {************************}
      triangle_node_ptr^.next := ray_mesh_data_ptr^.triangle_node_ptr;
      ray_mesh_data_ptr^.triangle_node_ptr := triangle_node_ptr;
    end;

  {*******************************}
  { make triangle node references }
  {*******************************}
  triangle_node_ptr := ray_mesh_data_ptr^.triangle_node_ptr;
  while (triangle_node_ptr <> nil) do
    begin
      triangle_node_ref_ptr := New_triangle_node_ref;
      triangle_node_ref_ptr^.triangle_node_ptr := triangle_node_ptr;
      triangle_node_ptr := triangle_node_ptr^.next;

      {************************}
      { insert at head of list }
      {************************}
      triangle_node_ref_ptr^.next := voxel_space_ptr^.triangle_node_ref_ptr;
      voxel_space_ptr^.triangle_node_ref_ptr := triangle_node_ref_ptr;
    end;

  {***********************}
  { build triangle voxels }
  {***********************}
  subdivision_level := 1;
  done := false;

  while ((subdivision_level < max_voxel_subdivision) and not done) or
    (subdivision_level <= min_voxel_subdivision) do
    begin
      {***********************************************}
      { Subdivide all voxels at the subdivision level }
      {***********************************************}
      Subdivide_octree_level(drawable, voxel_space_ptr, subdivision_level, done);

      {******************************************}
      { Link newly created neighboring subvoxels }
      {******************************************}
      Link_octree_fringe(voxel_space_ptr, subdivision_level);

      subdivision_level := subdivision_level + 1;
    end; {while loop}
end; {procedure Build_triangle_voxels}


procedure Voxelize_triangles(drawable: drawable_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  mesh_trans, scene_trans: trans_type);
var
  trans: trans_type;
begin
  if (ray_object_ptr^.ray_mesh_data_ptr^.triangle_node_ptr = nil) then
    begin
      {******************************}
      { draw objects to be voxelized }
      {******************************}
      if draw_voxels then
        begin
          trans := Axes_to_trans(ray_object_ptr^.coord_axes);
          Transform_trans(trans, mesh_trans);
          voxel_trans := Center_object(trans, scene_trans,
            current_projection_ptr);
          Draw_mesh(drawable, ray_object_ptr, voxel_trans);
        end;

      {***********************************}
      { recursively build triangle voxels }
      {***********************************}
      Build_triangle_voxels(drawable, ray_object_ptr^.ray_mesh_data_ptr);

      if draw_voxels then
        drawable.Update;
    end;
end; {procedure Voxelize_triangles}


end.

