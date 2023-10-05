unit make_voxels;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            make_voxels                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The make_voxels module is used to build the spatial     }
{       database used for raytracing.                           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans, raytrace, drawable;


procedure Make_voxel_space(drawable: drawable_type;
  object_decl_ptr: ray_object_decl_ptr_type;
  scene_trans: trans_type);


implementation
uses
  colors, vectors, coord_axes, extents, bounds, project, visibility,
  state_vars, geometry, b_rep, objects, object_attr, viewing, preview,
  b_rep_prims, meshes, triangles, show_lines, show_b_rep, tri_voxels,
  mesh_voxels;


const
  min_voxel_subdivision = 1;
  max_voxel_subdivision = 5; {maximum depth of voxel octree structure}
  max_objects_per_voxel = 7; {maximum # of object references per voxel}
  min_objects_per_voxel = 4; {below this amount, a sequential search is used}


var
  voxel_trans: trans_type;


procedure Draw_voxel(drawable: drawable_type;
  voxel_ptr: voxel_ptr_type);
var
  box: bounding_box_type;
  counter1, counter2, counter3: extent_type;
  color_num: integer;
begin
  {*******************************************}
  { set color based on nesting level of voxel }
  {*******************************************}
  color_num := voxel_ptr^.subdivision_level mod 3;
  if (color_num = 0) then
    Set_line_color(drawable, red_color)
  else if (color_num = 1) then
    Set_line_color(drawable, green_color)
  else if (color_num = 2) then
    Set_line_color(drawable, blue_color);

  {*********************}
  { draw edges of voxel }
  {*********************}
  Make_bounding_box_from_extent_box(box, voxel_ptr^.extent_box);
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        Transform_point(box[counter1, counter2, counter3], voxel_trans);
  Show_bounding_box(drawable, box);
end; {procedure Draw_voxel}


function Count_objects(voxel_ptr: voxel_ptr_type): integer;
var
  follow: object_ref_ptr_type;
  object_count: integer;
begin
  follow := voxel_ptr^.object_ref_ptr;
  object_count := 0;
  while (follow <> nil) do
    begin
      object_count := object_count + 1;
      follow := follow^.next;
    end;
  Count_objects := object_count;
end; {function Count_objects}


function Too_many_objects(voxel_ptr: voxel_ptr_type): boolean;
var
  follow: object_ref_ptr_type;
  object_count: integer;
begin
  follow := voxel_ptr^.object_ref_ptr;
  object_count := 0;
  while (follow <> nil) and (object_count <= max_objects_per_voxel) do
    begin
      if not Bounds_surround_extent_box(follow^.object_ptr^.bounds,
        voxel_ptr^.extent_box) then
        {if Bounds_contained_by_extent_box(follow^.object_ptr^.bounds, voxel_ptr^.extent_box) then}
        object_count := object_count + 1;
      follow := follow^.next;
    end;
  if (object_count > max_objects_per_voxel) then
    Too_many_objects := true
  else
    Too_many_objects := false;
end; {function Too_many_objects}


procedure Copy_object_refs(object_ref_ptr: object_ref_ptr_type;
  subvoxel_ptr: voxel_ptr_type);
var
  temp_object_ref_ptr: object_ref_ptr_type;
begin
  while (object_ref_ptr <> nil) do
    begin
      if Bounds_in_extent_box(object_ref_ptr^.object_ptr^.bounds,
        object_ref_ptr^.object_ptr^.coord_axes, subvoxel_ptr^.extent_box) then
        begin
          {************************************}
          { make new object reference node and }
          { initialize the new object_ref node }
          {************************************}
          temp_object_ref_ptr := New_object_ref;
          temp_object_ref_ptr^.object_ptr := object_ref_ptr^.object_ptr;

          {************************}
          { insert at head of list }
          {************************}
          temp_object_ref_ptr^.next := subvoxel_ptr^.object_ref_ptr;
          subvoxel_ptr^.object_ref_ptr := temp_object_ref_ptr;
        end;
      object_ref_ptr := object_ref_ptr^.next;
    end; {while loop}
end; {procedure Copy_object_refs}


procedure Subdivide_voxel(drawable: drawable_type;
  voxel_ptr: voxel_ptr_type);
var
  temp_neighbor_voxel_ptr: array[extent_type] of voxel_ptr_type;
  temp_object_ref_ptr: object_ref_ptr_type;
  counter1, counter2, counter3: extent_type;
  center: vector_type;
begin
  {******************************}
  { change voxel from leaf voxel }
  { to an internal tree node -   }
  { make into a subdivided voxel }
  {******************************}
  center := Extent_box_center(voxel_ptr^.extent_box);
  for counter1 := left to top do
    temp_neighbor_voxel_ptr[counter1] :=
      voxel_ptr^.neighbor_voxel_ptr[counter1];
  voxel_ptr^.subdivided := true;
  temp_object_ref_ptr := voxel_ptr^.object_ref_ptr;

  {**************************}
  { allocate 8 new subvoxels }
  {**************************}
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        voxel_ptr^.subvoxel_ptr[counter1, counter2, counter3] := New_voxel;

  {**************************}
  { initialize new subvoxels }
  {**************************}
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        with voxel_ptr^.subvoxel_ptr[counter1, counter2, counter3]^ do
          begin
            subdivision_level := voxel_ptr^.subdivision_level + 1;
            subdivided := false;
            object_ref_ptr := nil;

            extent_box[counter1] := voxel_ptr^.extent_box[counter1];
            extent_box[counter2] := voxel_ptr^.extent_box[counter2];
            extent_box[counter3] := voxel_ptr^.extent_box[counter3];
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
              voxel_ptr^.subvoxel_ptr[Opposite_extent(counter1), counter2,
              counter3];
            neighbor_voxel_ptr[Opposite_extent(counter2)] :=
              voxel_ptr^.subvoxel_ptr[counter1, Opposite_extent(counter2),
              counter3];
            neighbor_voxel_ptr[Opposite_extent(counter3)] :=
              voxel_ptr^.subvoxel_ptr[counter1, counter2,
              Opposite_extent(counter3)];

            if draw_voxels then
              Draw_voxel(drawable, voxel_ptr^.subvoxel_ptr[counter1, counter2, counter3]);
            Copy_object_refs(temp_object_ref_ptr,
              voxel_ptr^.subvoxel_ptr[counter1, counter2, counter3]);
          end;
  Free_object_refs(temp_object_ref_ptr);

  if draw_voxels then
    drawable.Update;
end; {procedure Subdivide_voxel}


procedure Subdivide_octree_level(drawable: drawable_type;
  voxel_ptr: voxel_ptr_type;
  subdivision_level: integer;
  var done: boolean);
var
  counter1, counter2, counter3: extent_type;
  subvoxel_done: boolean;
begin
  if (voxel_ptr^.subdivision_level < subdivision_level) then
    begin
      {*********************************}
      { traverse octree until we are at }
      { the subdivision level (fringe)  }
      {*********************************}
      done := true;
      if (voxel_ptr^.subdivided) then
        for counter1 := left to right do
          for counter2 := front to back do
            for counter3 := bottom to top do
              begin
                Subdivide_octree_level(drawable, voxel_ptr^.subvoxel_ptr[counter1,
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
      if (Too_many_objects(voxel_ptr)) or (subdivision_level <=
        min_voxel_subdivision) then
        begin
          Subdivide_voxel(drawable, voxel_ptr);
          done := false;
        end
      else
        done := true;
    end;
end; {procedure Subdivide_octree_level}


procedure Link_octree_fringe(voxel_ptr: voxel_ptr_type;
  subdivision_level: integer);
var
  counter1, counter2, counter3, counter4: extent_type;
  neighbor_voxel_ptr, subvoxel_ptr: voxel_ptr_type;
begin
  if (voxel_ptr^.subdivision_level < subdivision_level) then
    begin
      {****************************************}
      { traverse octree until we are one level }
      { above the subdivision level  (fringe)  }
      {****************************************}
      if (voxel_ptr^.subdivided) then
        for counter1 := left to right do
          for counter2 := front to back do
            for counter3 := bottom to top do
              Link_octree_fringe(voxel_ptr^.subvoxel_ptr[counter1, counter2,
                counter3], subdivision_level);
    end

      {******************************************}
      { at one level above the subdivision level }
      { link faces of neighboring subvoxels      }
      {******************************************}
  else if (voxel_ptr^.subdivided) then
    {****************}
    { link each face }
    {****************}
    for counter4 := left to top do
      for counter1 := left to right do
        for counter2 := front to back do
          for counter3 := bottom to top do
            begin
              subvoxel_ptr := voxel_ptr^.subvoxel_ptr[counter1, counter2,
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


procedure Draw_voxel_bounds(drawable: drawable_type;
  object_ptr: ray_object_inst_ptr_type;
  coord_axes: coord_axes_type);
var
  bounds: bounding_type;
begin
  Set_line_color(drawable, black_color);
  while object_ptr <> nil do
    begin
      bounds := object_ptr^.bounds;
      Transform_bounds_from_axes(bounds, coord_axes);
      Show_bounds(drawable, bounds);
      object_ptr := object_ptr^.next;
    end;
end; {procedure Draw_voxel_bounds}


procedure Draw_voxel_objects(drawable: drawable_type;
  object_decl_ptr: view_object_decl_ptr_type;
  trans: trans_type);
var
  object_ptr: view_object_inst_ptr_type;
begin
  Set_line_color(drawable, black_color);
  drawable.Clear;
  object_ptr := New_view_object_inst;

  object_ptr^.kind := view_object_decl;
  object_ptr^.object_decl_ptr := object_decl_ptr;
  object_ptr^.trans :=
    Inverse_trans(Extent_box_trans(object_decl_ptr^.extent_box));
  object_ptr^.bounding_kind := non_planar_bounds;

  object_ptr^.attributes := null_attributes;
  Set_render_mode_attributes(object_ptr^.attributes, wireframe_mode);
  Set_edge_mode_attributes(object_ptr^.attributes, outline_edges);

  Show_scene(drawable, object_ptr, trans, 1);
  Free_view_object_inst(object_ptr);
end; {procedure Draw_voxel_objects}


procedure Build_voxels(drawable: drawable_type;
  complex_object_ptr: ray_object_decl_ptr_type);
var
  ray_object_ptr: ray_object_inst_ptr_type;
  object_ref_ptr: object_ref_ptr_type;
  voxel_space_ptr: voxel_ptr_type;
  subdivision_level: integer;
  counter: extent_type;
  done, ok: boolean;
begin
  {*****************}
  { make root voxel }
  {*****************}
  complex_object_ptr^.voxel_space_ptr := New_voxel;
  voxel_space_ptr := complex_object_ptr^.voxel_space_ptr;
  with voxel_space_ptr^ do
    begin
      subdivided := false;
      object_ref_ptr := nil;
      subdivision_level := 1;
      extent_box := unit_extent_box;
      for counter := left to top do
        neighbor_voxel_ptr[counter] := nil;
    end;

  {************************}
  { make object references }
  {************************}
  ray_object_ptr := complex_object_ptr^.sub_object_ptr;
  while (ray_object_ptr <> nil) do
    begin
      object_ref_ptr := New_object_ref;
      object_ref_ptr^.object_ptr := ray_object_ptr;
      ray_object_ptr := ray_object_ptr^.next;

      {************************}
      { insert at head of list }
      {************************}
      object_ref_ptr^.next := voxel_space_ptr^.object_ref_ptr;
      voxel_space_ptr^.object_ref_ptr := object_ref_ptr;
    end;

  {**************}
  { build voxels }
  {**************}
  subdivision_level := 1;
  done := false;

  ok := ((subdivision_level < max_voxel_subdivision) and not done) or
    (subdivision_level <= min_voxel_subdivision);
  while ok do
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
      ok := ((subdivision_level < max_voxel_subdivision) and not done) or
        (subdivision_level <= min_voxel_subdivision);
    end; {while loop}
end; {procedure Build_voxels}


procedure Voxelize_ray_mesh(drawable: drawable_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  view_object_ptr: view_object_inst_ptr_type;
  scene_trans: trans_type);
var
  surface_ptr: surface_ptr_type;
  temp_axes: coord_axes_type;
begin
  {******************************}
  { borrow mesh from view object }
  {******************************}
  ray_object_ptr^.ray_mesh_data_ptr := New_ray_mesh_data;
  surface_ptr := Copy_surface(view_object_ptr^.surface_ptr);
  ray_object_ptr^.ray_mesh_data_ptr^.surface_ptr := surface_ptr;

  {*****************************}
  { create mesh voxels for prim }
  {*****************************}
  temp_axes := ray_object_ptr^.coord_axes;
  ray_object_ptr^.coord_axes := unit_axes;

  Voxelize_mesh(drawable, ray_object_ptr, unit_trans, scene_trans);
  ray_object_ptr^.coord_axes := temp_axes;
end; {procedure Voxelize_ray_mesh}


procedure Voxelize_prim(drawable: drawable_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  view_object_ptr: view_object_inst_ptr_type;
  scene_trans: trans_type);
begin
  with ray_object_ptr^ do
    if ray_mesh_data_ptr = nil then
      begin
        {********************}
        { self similar prims }
        {********************}
        if Self_similar_surface(ray_object_ptr) then
          begin
            if (prim_mesh_ptr_array[kind] = nil) then
              begin
                Voxelize_ray_mesh(drawable, ray_object_ptr, view_object_ptr, scene_trans);

                {***************************************}
                { save mesh data for self similar prims }
                {***************************************}
                prim_mesh_ptr_array[kind] := ray_mesh_data_ptr;
              end
            else
              begin
                {************************}
                { duplicate copy of mesh }
                {************************}
                ray_object_ptr^.ray_mesh_data_ptr := prim_mesh_ptr_array[kind];
              end;
          end

            {************************}
            { non self similar prims }
            {************************}
        else
          Voxelize_ray_mesh(drawable, ray_object_ptr, view_object_ptr, scene_trans);
      end;
end; {procedure Voxelize_prim}


procedure Voxelize_prim_objects(drawable: drawable_type;
  complex_object_ptr: ray_object_decl_ptr_type;
  scene_trans: trans_type);
var
  ray_object_ptr: ray_object_inst_ptr_type;
  object_decl_ptr: view_object_decl_ptr_type;
  view_object_ptr: view_object_inst_ptr_type;
begin
  {***************************************************}
  { find corresponding object in viewing data structs }
  {***************************************************}
  object_decl_ptr := Find_view_object(complex_object_ptr^.object_id);
  view_object_ptr := object_decl_ptr^.sub_object_ptr;
  ray_object_ptr := complex_object_ptr^.sub_object_ptr;

  while (ray_object_ptr <> nil) do
    begin
      {*******************************************}
      { if curved, then we must tessellate object }
      {*******************************************}
      with ray_object_ptr^ do
        if (kind in curved_prims) then
          if original_object_ptr = ray_object_ptr then
            begin
              {*********************************}
              { original object - create voxels }
              {*********************************}
              Voxelize_prim(drawable, ray_object_ptr, view_object_ptr, scene_trans);
            end
          else
            begin
              {********************************}
              { duplicate object - copy voxels }
              {********************************}
              with ray_object_ptr^ do
                ray_mesh_data_ptr := original_object_ptr^.ray_mesh_data_ptr;
            end;

      ray_object_ptr := ray_object_ptr^.next;
      view_object_ptr := view_object_ptr^.next;
    end;
end; {procedure Voxelize_prim_objects}


procedure Voxelize_mesh_object(drawable: drawable_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  view_object_ptr: view_object_inst_ptr_type;
  complex_object_ptr: ray_object_decl_ptr_type;
  scene_trans: trans_type);
var
  mesh_trans: trans_type;
  mesh_axes: coord_axes_type;
  surface_ptr: surface_ptr_type;
begin
  {*************}
  { create mesh }
  {*************}
  if (view_object_ptr <> nil) then
    begin
      {******************************}
      { borrow mesh from view object }
      {******************************}
      surface_ptr := Copy_surface(view_object_ptr^.surface_ptr);
      ray_object_ptr^.ray_mesh_data_ptr^.surface_ptr := surface_ptr;
    end
  else
    begin
      {*******************************}
      { create new mesh from geometry }
      {*******************************}
      surface_ptr := nil;
      case ray_object_ptr^.kind of
        mesh:
          begin
            with ray_object_ptr^ do
              surface_ptr := Mesh_b_rep(mesh_ptr, smoothing, mending, closed,
                true);
            ray_object_ptr^.ray_mesh_data_ptr^.surface_ptr := surface_ptr;
          end;
        volume:
          begin
            surface_ptr := Volume_b_rep(ray_object_ptr^.volume_ptr);
            Unitize_mesh(surface_ptr, mesh_trans);
            mesh_axes := Trans_to_axes(mesh_trans);
            Transform_axes_from_axes(ray_object_ptr^.coord_axes, mesh_axes);
            ray_object_ptr^.ray_mesh_data_ptr^.surface_ptr := surface_ptr;
          end;
      end;
    end;

  {***************************}
  { bind topology to geometry }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_vertex_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_face_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {***********************}
  { compute mesh geometry }
  {***********************}
  if not surface_ptr^.geometry_ptr^.geometry_info.face_normals_avail then
    Find_mesh_face_normals(surface_ptr);
  if not surface_ptr^.geometry_ptr^.geometry_info.vertex_normals_avail then
    Find_mesh_vertex_normals(surface_ptr);
  if not surface_ptr^.geometry_ptr^.geometry_info.vertex_vectors_avail then
    Find_mesh_uv_vectors(surface_ptr);

  {*******************}
  { triangulate b rep }
  {*******************}
  with ray_object_ptr^.ray_mesh_data_ptr^ do
    triangle_ptr := Triangulated_mesh(surface_ptr);

  {********************}
  { voxelize triangles }
  {********************}
  mesh_trans := Axes_to_trans(complex_object_ptr^.coord_axes);
  Voxelize_triangles(drawable, ray_object_ptr, mesh_trans, scene_trans);
end; {procedure Voxelize_mesh_object}


procedure Triangulate_polygon_object(ray_object_ptr: ray_object_inst_ptr_type;
  view_object_ptr: view_object_inst_ptr_type);
var
  surface_ptr: surface_ptr_type;
begin
  {****************}
  { create polygon }
  {****************}
  if (view_object_ptr <> nil) then
    begin
      {*********************************}
      { borrow polygon from view object }
      {*********************************}
      surface_ptr := Copy_surface(view_object_ptr^.surface_ptr);
      ray_object_ptr^.ray_mesh_data_ptr^.surface_ptr := surface_ptr;
    end
  else
    begin
      {**********************************}
      { create new polygon from geometry }
      {**********************************}
      surface_ptr := nil;
      case ray_object_ptr^.kind of
        flat_polygon:
          begin
            surface_ptr := Polygon_b_rep(ray_object_ptr^.polygon_ptr);
            ray_object_ptr^.ray_mesh_data_ptr^.surface_ptr := surface_ptr;
          end;
        shaded_polygon:
          begin
            surface_ptr :=
              Shaded_polygon_b_rep(ray_object_ptr^.shaded_polygon_ptr);
            ray_object_ptr^.ray_mesh_data_ptr^.surface_ptr := surface_ptr;
          end;
      end;
    end;

  {***************************}
  { bind topology to geometry }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_vertex_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_face_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {***********************}
  { compute mesh geometry }
  {***********************}
  if not surface_ptr^.geometry_ptr^.geometry_info.face_normals_avail then
    Find_mesh_face_normals(surface_ptr);
  if not surface_ptr^.geometry_ptr^.geometry_info.vertex_normals_avail then
    Find_mesh_vertex_normals(surface_ptr);
  if not surface_ptr^.geometry_ptr^.geometry_info.vertex_vectors_avail then
    Find_mesh_uv_vectors(surface_ptr);

  {*******************}
  { triangulate b rep }
  {*******************}
  with ray_object_ptr^.ray_mesh_data_ptr^ do
    triangle_ptr := Triangulated_mesh(surface_ptr);
end; {procedure Triangulate_polygon_object}


procedure Voxelize_sub_objects(drawable: drawable_type;
  complex_object_ptr: ray_object_decl_ptr_type;
  scene_trans: trans_type);
var
  object_decl_ptr: view_object_decl_ptr_type;
  view_object_ptr: view_object_inst_ptr_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  original_object_ptr: ray_object_inst_ptr_type;
  done: boolean;
begin
  {*********************}
  { voxelize primitives }
  {*********************}
  if (facets <> 0) then
    begin
      Voxelize_prim_objects(drawable, complex_object_ptr, scene_trans);
    end;

  {***************************************************}
  { find corresponding object in viewing data structs }
  {***************************************************}
  if (facets <> 0) or (draw_voxels) then
    begin
      object_decl_ptr := Find_view_object(complex_object_ptr^.object_id);
      view_object_ptr := object_decl_ptr^.sub_object_ptr;
    end
  else
    view_object_ptr := nil;

  {******************************************}
  { search subobjects for any meshes to be   }
  { voxelized or polygons to be triangulated }
  {******************************************}
  ray_object_ptr := complex_object_ptr^.sub_object_ptr;
  while (ray_object_ptr <> nil) do
    begin
      done := false;
      if ray_object_ptr^.ray_mesh_data_ptr <> nil then
        with ray_object_ptr^.ray_mesh_data_ptr^ do
          if (mesh_voxel_ptr <> nil) or (triangle_voxel_ptr <> nil) then
            done := true;

      if not done then
        begin
          {************************}
          { meshes to be voxelized }
          {************************}
          if (ray_object_ptr^.kind in [mesh, volume]) then
            begin
              if (ray_object_ptr^.original_object_ptr = ray_object_ptr) then
                begin
                  {********************************}
                  { voxelize original copy of mesh }
                  {********************************}
                  Voxelize_mesh_object(drawable, ray_object_ptr, view_object_ptr,
                    complex_object_ptr, scene_trans);
                end
              else
                begin
                  {************************}
                  { duplicate copy of mesh }
                  {************************}
                  original_object_ptr := ray_object_ptr^.original_object_ptr;
                  ray_object_ptr^.ray_mesh_data_ptr :=
                    original_object_ptr^.ray_mesh_data_ptr;
                end;
            end {meshes}

              {*****************************}
              { polygons to be triangulated }
              {*****************************}
          else if (ray_object_ptr^.kind in [flat_polygon, shaded_polygon]) then
            begin
              if (ray_object_ptr^.original_object_ptr = ray_object_ptr) then
                begin
                  {***********************************}
                  { voxelize original copy of polygon }
                  {***********************************}
                  Triangulate_polygon_object(ray_object_ptr, view_object_ptr);
                end
              else
                begin
                  {*****************************}
                  { duplicate copy of triangles }
                  {*****************************}
                  original_object_ptr := ray_object_ptr^.original_object_ptr;
                  ray_object_ptr^.ray_mesh_data_ptr :=
                    original_object_ptr^.ray_mesh_data_ptr;
                end;
            end;

          if (ray_object_ptr^.kind = volume) and (view_object_ptr <> nil) then
            begin
              {******************************************}
              { borrow trans from view object since for  }
              { volumes and blobs, the viewing bounds    }
              { and the geometry bounds are not the same }
              {******************************************}
              ray_object_ptr^.coord_axes :=
                Trans_to_axes(view_object_ptr^.trans);
              ray_object_ptr^.shader_axes :=
                Trans_to_axes(view_object_ptr^.shader_trans);
              ray_object_ptr^.normal_coord_axes :=
                Trans_to_axes(Normal_trans(view_object_ptr^.trans));
              ray_object_ptr^.normal_shader_axes :=
                Trans_to_axes(Normal_trans(view_object_ptr^.shader_trans));
              Make_bounds(ray_object_ptr^.bounds, non_planar_bounds,
                view_object_ptr^.trans);
            end;
        end;

      {********************************}
      { go to next ray and view object }
      {********************************}
      ray_object_ptr := ray_object_ptr^.next;
      if view_object_ptr <> nil then
        view_object_ptr := view_object_ptr^.next;
    end;
end; {procedure Voxelize_sub_objects}


procedure Voxelize_complex_object(drawable: drawable_type;
  complex_object_ptr: ray_object_decl_ptr_type;
  scene_trans: trans_type);
var
  ray_object_ptr: ray_object_inst_ptr_type;
  object_decl_ptr: view_object_decl_ptr_type;
  trans: trans_type;
begin
  {***********************************}
  { compute bounds on all sub objects }
  {***********************************}
  ray_object_ptr := complex_object_ptr^.sub_object_ptr;
  while (ray_object_ptr <> nil) do
    begin
      with ray_object_ptr^ do
        Make_bounds(bounds, bounds.bounding_kind, Axes_to_trans(coord_axes));
      ray_object_ptr := ray_object_ptr^.next;
    end;

  {******************************}
  { draw objects to be voxelized }
  {******************************}
  if draw_voxels then
    begin
      trans := Axes_to_trans(complex_object_ptr^.coord_axes);
      voxel_trans := Center_object(trans, scene_trans, current_projection_ptr);
      object_decl_ptr := Find_view_object(complex_object_ptr^.object_id);
      Draw_voxel_objects(drawable, object_decl_ptr, voxel_trans);
    end;

  {**************************}
  { recursively build voxels }
  {**************************}
  Build_voxels(drawable, complex_object_ptr);

  if draw_voxels then
    drawable.Update;
end; {procedure Voxelize_complex_object}


procedure Make_voxel_space(drawable: drawable_type;
  object_decl_ptr: ray_object_decl_ptr_type;
  scene_trans: trans_type);
var
  voxelize_scene: boolean;
  temp: boolean;
begin
  {******************************************}
  { don't use antialiasing for voxel preview }
  {******************************************}
  temp := antialiasing;
  antialiasing := false;

  {****************************************}
  { only draw voxels in single buffer mode }
  {****************************************}
  draw_voxels := rendering and (min_feature_size = 0);
  // draw_voxels := rendering and (Get_buffer_mode = single_buffer) and
  //  (min_feature_size = 0);

  while (object_decl_ptr <> nil) do
    begin
      {*******************************}
      { create voxels for sub objects }
      {*******************************}
      if object_decl_ptr^.voxel_space_ptr = nil then
        Voxelize_sub_objects(drawable, object_decl_ptr, scene_trans);

      with object_decl_ptr^ do
        begin
          if (next = nil) and (sub_object_number > min_objects_per_voxel) then
            voxelize_scene := true
          else
            voxelize_scene := false;

          if (voxel_space_ptr = nil) then
            if (sub_object_number > min_object_complexity) or voxelize_scene
              then
              begin
                {*****************}
                { voxelize object }
                {*****************}
                Voxelize_complex_object(drawable, object_decl_ptr, scene_trans);
              end;
        end;
      object_decl_ptr := object_decl_ptr^.next;
    end;

  antialiasing := temp;
end; {procedure Make_voxel_space}


end.
