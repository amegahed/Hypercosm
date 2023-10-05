unit mesh_voxels;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            mesh_voxels                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module creates the spatial database needed         }
{       to raytrace the mesh primitive.                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans, raytrace, drawable;


procedure Voxelize_mesh(drawable: drawable_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  mesh_trans, scene_trans: trans_type);


implementation
uses
  colors, vectors, coord_axes, extents, bounds, project, visibility,
  state_vars, geometry, topology, b_rep, object_attr, viewing,
  show_lines, show_b_rep;


const
  min_voxel_subdivision = 1;
  max_voxel_subdivision = 5; {maximum depth of voxel octree structure}
  max_faces_per_voxel = 12; {maximum # of face references per voxel}


var
  {**********************************}
  { variables used for voxel preview }
  {**********************************}
  voxel_trans: trans_type;


procedure Draw_mesh_voxel(drawable: drawable_type;
  mesh_voxel_ptr: mesh_voxel_ptr_type);
var
  box: bounding_box_type;
  counter1, counter2, counter3: extent_type;
  color_num: integer;
begin
  {*******************************************}
  { set color based on nesting level of voxel }
  {*******************************************}
  color_num := mesh_voxel_ptr^.subdivision_level mod 3;
  if (color_num = 0) then
    Set_line_color(drawable, red_color)
  else if (color_num = 1) then
    Set_line_color(drawable, green_color)
  else if (color_num = 2) then
    Set_line_color(drawable, blue_color);

  {*********************}
  { draw edges of voxel }
  {*********************}
  Make_bounding_box_from_extent_box(box, mesh_voxel_ptr^.extent_box);
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        Transform_point(box[counter1, counter2, counter3], voxel_trans);
  Show_bounding_box(drawable, box);
end; {procedure Draw_mesh_voxel}


function Too_many_faces(mesh_voxel_ptr: mesh_voxel_ptr_type): boolean;
var
  follow: face_node_ref_ptr_type;
  face_count: integer;
begin
  follow := mesh_voxel_ptr^.face_node_ref_ptr;
  face_count := 0;
  while (follow <> nil) and (face_count <= max_faces_per_voxel) do
    begin
      if not Disjoint_extent_boxes(follow^.face_node_ptr^.extent_box,
        mesh_voxel_ptr^.extent_box) then
        face_count := face_count + 1;
      follow := follow^.next;
    end;
  if (face_count > max_faces_per_voxel) then
    Too_many_faces := true
  else
    Too_many_faces := false;
end; {function Too_many_faces}


procedure Copy_face_node_refs(face_node_ref_ptr: face_node_ref_ptr_type;
  subvoxel_ptr: mesh_voxel_ptr_type);
var
  temp_face_node_ref_ptr: face_node_ref_ptr_type;
begin
  while (face_node_ref_ptr <> nil) do
    begin
      if not Disjoint_extent_boxes(face_node_ref_ptr^.face_node_ptr^.extent_box,
        subvoxel_ptr^.extent_box) then
        begin
          {************************************}
          { make new object reference node and }
          { initialize the new object_ref node }
          {************************************}
          temp_face_node_ref_ptr := New_face_node_ref;
          temp_face_node_ref_ptr^.face_node_ptr :=
            face_node_ref_ptr^.face_node_ptr;

          {************************}
          { insert at head of list }
          {************************}
          temp_face_node_ref_ptr^.next := subvoxel_ptr^.face_node_ref_ptr;
          subvoxel_ptr^.face_node_ref_ptr := temp_face_node_ref_ptr;
        end;
      face_node_ref_ptr := face_node_ref_ptr^.next;
    end; {while loop}
end; {procedure Copy_face_node_refs}


procedure Subdivide_mesh_voxel(drawable: drawable_type;
  mesh_voxel_ptr: mesh_voxel_ptr_type);
var
  temp_neighbor_voxel_ptr: array[extent_type] of mesh_voxel_ptr_type;
  temp_face_node_ref_ptr: face_node_ref_ptr_type;
  counter1, counter2, counter3: extent_type;
  center: vector_type;
begin
  {******************************}
  { change voxel from leaf voxel }
  { to an internal tree node -   }
  { make into a subdivided voxel }
  {******************************}
  center := Extent_box_center(mesh_voxel_ptr^.extent_box);
  for counter1 := left to top do
    temp_neighbor_voxel_ptr[counter1] :=
      mesh_voxel_ptr^.neighbor_voxel_ptr[counter1];
  mesh_voxel_ptr^.subdivided := true;
  temp_face_node_ref_ptr := mesh_voxel_ptr^.face_node_ref_ptr;

  {**************************}
  { allocate 8 new subvoxels }
  {**************************}
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        mesh_voxel_ptr^.subvoxel_ptr[counter1, counter2, counter3] :=
          New_mesh_voxel;

  {**************************}
  { initialize new subvoxels }
  {**************************}
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        with mesh_voxel_ptr^.subvoxel_ptr[counter1, counter2, counter3]^ do
          begin
            subdivision_level := mesh_voxel_ptr^.subdivision_level + 1;
            subdivided := false;
            face_node_ref_ptr := nil;

            extent_box[counter1] := mesh_voxel_ptr^.extent_box[counter1];
            extent_box[counter2] := mesh_voxel_ptr^.extent_box[counter2];
            extent_box[counter3] := mesh_voxel_ptr^.extent_box[counter3];
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
              mesh_voxel_ptr^.subvoxel_ptr[Opposite_extent(counter1), counter2,
              counter3];
            neighbor_voxel_ptr[Opposite_extent(counter2)] :=
              mesh_voxel_ptr^.subvoxel_ptr[counter1, Opposite_extent(counter2),
              counter3];
            neighbor_voxel_ptr[Opposite_extent(counter3)] :=
              mesh_voxel_ptr^.subvoxel_ptr[counter1, counter2,
              Opposite_extent(counter3)];

            if draw_voxels then
              Draw_mesh_voxel(drawable, mesh_voxel_ptr^.subvoxel_ptr[counter1, counter2,
                counter3]);
            Copy_face_node_refs(temp_face_node_ref_ptr,
              mesh_voxel_ptr^.subvoxel_ptr[counter1, counter2, counter3]);
          end;
  Free_face_node_refs(temp_face_node_ref_ptr);

  if draw_voxels then
    drawable.Update;
end; {procedure Subdivide_mesh_voxel}


procedure Subdivide_octree_level(drawable: drawable_type;
  mesh_voxel_ptr: mesh_voxel_ptr_type;
  subdivision_level: integer;
  var done: boolean);
var
  counter1, counter2, counter3: extent_type;
  subvoxel_done: boolean;
begin
  if (mesh_voxel_ptr^.subdivision_level < subdivision_level) then
    begin
      {*********************************}
      { traverse octree until we are at }
      { the subdivision level (fringe)  }
      {*********************************}
      done := true;
      if (mesh_voxel_ptr^.subdivided) then
        for counter1 := left to right do
          for counter2 := front to back do
            for counter3 := bottom to top do
              begin
                Subdivide_octree_level(drawable, mesh_voxel_ptr^.subvoxel_ptr[counter1,
                  counter2, counter3], subdivision_level, subvoxel_done);

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
      if (Too_many_faces(mesh_voxel_ptr)) or (subdivision_level <=
        min_voxel_subdivision) then
        begin
          Subdivide_mesh_voxel(drawable, mesh_voxel_ptr);
          done := false;
        end
      else
        done := true;
    end;
end; {procedure Subdivide_octree_level}


procedure Link_octree_fringe(mesh_voxel_ptr: mesh_voxel_ptr_type;
  subdivision_level: integer);
var
  counter1, counter2, counter3, counter4: extent_type;
  neighbor_voxel_ptr, subvoxel_ptr: mesh_voxel_ptr_type;
begin
  if (mesh_voxel_ptr^.subdivision_level < subdivision_level) then
    begin
      {****************************************}
      { traverse octree until we are one level }
      { above the subdivision level  (fringe)  }
      {****************************************}
      if (mesh_voxel_ptr^.subdivided) then
        for counter1 := left to right do
          for counter2 := front to back do
            for counter3 := bottom to top do
              Link_octree_fringe(mesh_voxel_ptr^.subvoxel_ptr[counter1,
                counter2, counter3], subdivision_level);
    end

      {******************************************}
      { at one level above the subdivision level }
      { link faces of neighboring subvoxels      }
      {******************************************}
  else if (mesh_voxel_ptr^.subdivided) then
    {****************}
    { link each face }
    {****************}
    for counter4 := left to top do
      for counter1 := left to right do
        for counter2 := front to back do
          for counter3 := bottom to top do
            begin
              subvoxel_ptr := mesh_voxel_ptr^.subvoxel_ptr[counter1, counter2,
                counter3];
              neighbor_voxel_ptr := subvoxel_ptr^.neighbor_voxel_ptr[counter4];
              if (neighbor_voxel_ptr <> nil) then
                if (neighbor_voxel_ptr^.subdivision_level = subdivision_level)
                  then
                  if (neighbor_voxel_ptr^.subdivided) then
                    begin
                      if (counter4 = counter1) then
                        subvoxel_ptr^.neighbor_voxel_ptr[counter4] :=
                          neighbor_voxel_ptr^.subvoxel_ptr[Opposite_extent(counter1), counter2, counter3]
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


procedure Find_face_extents(face_ptr: face_ptr_type;
  var extent_box: extent_box_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  point_ptr: point_ptr_type;
begin
  Init_extent_box(extent_box);
  cycle_ptr := face_ptr^.cycle_ptr;
  while (cycle_ptr <> nil) do
    begin
      directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
      while (directed_edge_ptr <> nil) do
        begin
          with directed_edge_ptr^ do
            if orientation then
              point_ptr := edge_ptr^.point_ptr1
            else
              point_ptr := edge_ptr^.point_ptr2;

          Extend_extent_box_to_point(extent_box,
            point_ptr^.point_geometry_ptr^.point);
          directed_edge_ptr := directed_edge_ptr^.next;
        end;
      cycle_ptr := cycle_ptr^.next;
    end;
end; {procedure Find_face_extents}


procedure Build_mesh_voxels(drawable: drawable_type;
  ray_mesh_data_ptr: ray_mesh_data_ptr_type);
var
  voxel_space_ptr: mesh_voxel_ptr_type;
  surface_ptr: surface_ptr_type;
  face_node_ref_ptr: face_node_ref_ptr_type;
  face_node_ptr: face_node_ptr_type;
  face_ptr: face_ptr_type;
  subdivision_level: integer;
  counter: extent_type;
  done: boolean;
begin
  {**********************}
  { make root mesh voxel }
  {**********************}
  ray_mesh_data_ptr^.mesh_voxel_ptr := New_mesh_voxel;
  voxel_space_ptr := ray_mesh_data_ptr^.mesh_voxel_ptr;
  with voxel_space_ptr^ do
    begin
      subdivided := false;
      face_node_ref_ptr := nil;
      subdivision_level := 1;
      extent_box := unit_extent_box;
      for counter := left to top do
        neighbor_voxel_ptr[counter] := nil;
    end;

  {*****************}
  { make face nodes }
  {*****************}
  surface_ptr := ray_mesh_data_ptr^.surface_ptr;
  ray_mesh_data_ptr^.face_node_ptr := nil;
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  while (face_ptr <> nil) do
    begin
      face_node_ptr := New_face_node;
      face_node_ptr^.face_ptr := face_ptr;
      Find_face_extents(face_ptr, face_node_ptr^.extent_box);
      face_ptr := face_ptr^.next;

      {************************}
      { insert at head of list }
      {************************}
      face_node_ptr^.next := ray_mesh_data_ptr^.face_node_ptr;
      ray_mesh_data_ptr^.face_node_ptr := face_node_ptr;
    end;

  {***************************}
  { make face node references }
  {***************************}
  face_node_ptr := ray_mesh_data_ptr^.face_node_ptr;
  while (face_node_ptr <> nil) do
    begin
      face_node_ref_ptr := New_face_node_ref;
      face_node_ref_ptr^.face_node_ptr := face_node_ptr;
      face_node_ptr := face_node_ptr^.next;

      {************************}
      { insert at head of list }
      {************************}
      face_node_ref_ptr^.next := voxel_space_ptr^.face_node_ref_ptr;
      voxel_space_ptr^.face_node_ref_ptr := face_node_ref_ptr;
    end;

  {*******************}
  { build mesh voxels }
  {*******************}
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
end; {procedure Build_mesh_voxels}


procedure Voxelize_mesh(drawable: drawable_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  mesh_trans, scene_trans: trans_type);
var
  surface_ptr: surface_ptr_type;
  trans: trans_type;
begin
  if (ray_object_ptr^.ray_mesh_data_ptr^.face_node_ptr = nil) then
    begin
      surface_ptr := ray_object_ptr^.ray_mesh_data_ptr^.surface_ptr;

      {***************************}
      { bind geometry to topology }
      {***************************}
      Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
      Bind_face_geometry(surface_ptr, surface_ptr^.geometry_ptr);

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

      {*******************************}
      { recursively build mesh voxels }
      {*******************************}
      Build_mesh_voxels(drawable, ray_object_ptr^.ray_mesh_data_ptr);

      if draw_voxels then
        drawable.Update;
    end;
end; {procedure Voxelize_mesh}


end.
