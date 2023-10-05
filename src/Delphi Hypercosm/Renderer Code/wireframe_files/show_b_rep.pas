unit show_b_rep;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             show_b_rep                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws a wireframe rendering of objects      }
{       from the viewing data structs.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans, viewing, drawable;


procedure Show_scene(drawable: drawable_type;
  object_ptr: view_object_inst_ptr_type;
  trans: trans_type;
  level_of_detail: integer);


implementation
uses
  colors, vectors, extents, bounds, clip_planes, project, viewports,
  visibility, trans_stack, attr_stack, topology, b_rep, xform_b_rep, meshes,
  clip_lines, show_lines, state_vars, object_attr, pointplot, silhouette,
  outline, wireframe, b_rep_prims, view_sorting;


var
  trans_stack_ptr: trans_stack_ptr_type;
  attributes_stack_ptr: attributes_stack_ptr_type;


procedure Show_face_normals(drawable: drawable_type;
  face_ptr: face_ptr_type;
  length: real);
var
  vertex_ptr: vertex_ptr_type;
  point_data_ptr: point_data_ptr_type;
  face_data_ptr: face_data_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  vector, point, center_point: vector_type;
  counter: integer;
  line: line_type;
begin
  while (face_ptr <> nil) do
    begin
      center_point := zero_vector;
      directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;
      counter := 0;

      while (directed_edge_ptr <> nil) do
        begin
          if directed_edge_ptr^.orientation then
            vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr1
          else
            vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr2;
          directed_edge_ptr := directed_edge_ptr^.next;

          point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
          point := point_data_ptr^.trans_point;
          center_point := Vector_sum(center_point, point);
          counter := counter + 1;
        end;

      if (counter <> 0) then
        center_point := Vector_scale(center_point, 1 / counter);

      face_data_ptr := Get_face_data(face_ptr^.index);
      vector := face_data_ptr^.trans_normal;

      line.point1 := center_point;
      line.point2 := Vector_sum(center_point, Vector_scale(vector, length));
      Show_line(drawable, line);
      face_ptr := face_ptr^.next;
    end;
end; {procedure Show_surface_face_normals}


procedure Show_vertex_normals(drawable: drawable_type;
  face_ptr: face_ptr_type;
  length: real);
var
  vertex_ptr: vertex_ptr_type;
  point_data_ptr: point_data_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  line: line_type;
begin
  while (face_ptr <> nil) do
    begin
      directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;

      while (directed_edge_ptr <> nil) do
        begin
          if directed_edge_ptr^.orientation then
            vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr1
          else
            vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr2;

          point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
          vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
          line.point1 := point_data_ptr^.trans_point;
          line.point2 := Vector_sum(line.point1,
            Vector_scale(vertex_data_ptr^.trans_normal,
            length));
          Show_line(drawable, line);
          directed_edge_ptr := directed_edge_ptr^.next;
        end;

      face_ptr := face_ptr^.next;
    end;
end; {procedure Show_vertex_normals}


procedure Show_u_axis_vectors(drawable: drawable_type;
  face_ptr: face_ptr_type;
  trans: trans_type;
  length: real);
var
  vertex_ptr: vertex_ptr_type;
  point_data_ptr: point_data_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  vector: vector_type;
  line: line_type;
begin
  while (face_ptr <> nil) do
    begin
      directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;

      while (directed_edge_ptr <> nil) do
        begin
          if directed_edge_ptr^.orientation then
            vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr1
          else
            vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr2;

          point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
          line.point1 := point_data_ptr^.trans_point;
          vector := vertex_ptr^.vertex_geometry_ptr^.u_axis;
          Transform_vector(vector, trans);
          line.point2 := Vector_sum(line.point1, Vector_scale(vector, length));
          Show_line(drawable, line);
          directed_edge_ptr := directed_edge_ptr^.next;
        end;

      face_ptr := face_ptr^.next;
    end;
end; {procedure Show_u_axis_vectors}


procedure Show_v_axis_vectors(drawable: drawable_type;
  face_ptr: face_ptr_type;
  trans: trans_type;
  length: real);
var
  vertex_ptr: vertex_ptr_type;
  point_data_ptr: point_data_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  vector: vector_type;
  line: line_type;
begin
  while (face_ptr <> nil) do
    begin
      directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;

      while (directed_edge_ptr <> nil) do
        begin
          if directed_edge_ptr^.orientation then
            vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr1
          else
            vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr2;

          point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
          line.point1 := point_data_ptr^.trans_point;
          vector := vertex_ptr^.vertex_geometry_ptr^.v_axis;
          Transform_vector(vector, trans);
          line.point2 := Vector_sum(line.point1, Vector_scale(vector, length));
          Show_line(drawable, line);
          directed_edge_ptr := directed_edge_ptr^.next;
        end;

      face_ptr := face_ptr^.next;
    end;
end; {procedure Show_v_axis_vectors}


procedure Show_surface_vectors(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  trans: trans_type);
const
  normal_length = 0.1;
  uv_length = 0.1;
  draw_face_normals = false;
  draw_vertex_normals = true;
  draw_u_vectors = false;
  draw_v_vectors = false;
begin
  {***************************}
  { bind geometry to topology }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_vertex_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_face_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {******************************}
  { compute vectors if necessary }
  {******************************}
  if not surface_ptr^.geometry_ptr^.geometry_info.face_normals_avail then
    Find_mesh_face_normals(surface_ptr);
  if not surface_ptr^.geometry_ptr^.geometry_info.vertex_normals_avail then
    Find_mesh_vertex_normals(surface_ptr);

  {********************************}
  { init auxilliary rendering data }
  {********************************}
  Init_point_data(surface_ptr);
  Init_vertex_data(surface_ptr);
  Init_face_data(surface_ptr);

  {**************************************}
  { transform local coords to eye coords }
  {**************************************}
  Transform_point_geometry(trans);
  Transform_vertex_geometry(trans);
  Transform_face_geometry(trans);

  {*******************}
  { draw face normals }
  {*******************}
  if draw_face_normals then
    begin
      Set_line_color(drawable, white_color);
      Show_face_normals(drawable, surface_ptr^.topology_ptr^.face_ptr,
        normal_length);
    end;

  {*********************}
  { draw vertex normals }
  {*********************}
  if draw_vertex_normals then
    begin
      Set_line_color(drawable, blue_color);
      Show_vertex_normals(drawable, surface_ptr^.topology_ptr^.face_ptr,
        normal_length);
    end;

  {**************************}
  { draw u direction vectors }
  {**************************}
  if draw_u_vectors then
    begin
      Set_line_color(drawable, red_color);
      Show_u_axis_vectors(drawable, surface_ptr^.topology_ptr^.face_ptr, trans,
        uv_length);
    end;

  {**************************}
  { draw v direction vectors }
  {**************************}
  if draw_v_vectors then
    begin
      Set_line_color(drawable, green_color);
      Show_v_axis_vectors(drawable, surface_ptr^.topology_ptr^.face_ptr, trans,
        uv_length);
    end;
end; {procedure Show_surface_vectors}


procedure Show_surface(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  clipping: boolean);
var
  trans: trans_type;
  attributes: object_attributes_type;
  edge_orientation: edge_orientation_type;
  outline_kind: outline_kind_type;
  color: color_type;
begin
  Get_trans_stack(trans_stack_ptr, trans);
  Get_attributes_stack(attributes_stack_ptr, attributes);

  edge_orientation := attributes.edge_orientation;
  outline_kind := attributes.outline_kind;
  color := attributes.color;

  {*****************************************************}
  { object attributes are limited by picture attributes }
  {*****************************************************}
  if attributes.render_mode > render_mode then
    attributes.render_mode := render_mode;

  case attributes.render_mode of
    pointplot_mode:
      Pointplot_surface(drawable, surface_ptr, trans, color, clipping);

    wireframe_mode:
      case attributes.edge_mode of
        silhouette_edges:
          Silhouette_surface(drawable, surface_ptr, edge_orientation, trans,
            color,
            clipping);

        outline_edges:
          Outline_surface(drawable, surface_ptr, edge_orientation, outline_kind,
            trans,
            color, clipping);

        all_edges:
          Wireframe_surface(drawable, surface_ptr, edge_orientation, trans, color,
            clipping);
      end;
  end;

  {Show_surface_vectors(surface_ptr, trans);}
end; {procedure Show_surface}


procedure Show_surface_bounds(drawable: drawable_type;
  bounding_kind: bounding_kind_type;
  clipping: boolean);
begin
  case bounding_kind of
    planar_bounds:
      begin
        Show_surface(drawable, Parallelogram_b_rep, clipping);
      end;

    non_planar_bounds:
      begin
        Show_surface(drawable, Block_b_rep, clipping);
      end;

    infinite_planar_bounds, infinite_non_planar_bounds:
      ; {do nothing}
  end; {case}
end; {procedure Show_surface_bounds}


procedure Show_sub_objects(drawable: drawable_type;
  object_ptr: view_object_inst_ptr_type;
  visibility: visibility_type;
  level_of_detail: integer);
var
  trans, bounds_trans: trans_type;
  sub_object_ptr: view_object_inst_ptr_type;
  bounds: bounding_type;
  detail_visible, clipping: boolean;
  surface_ptr: surface_ptr_type;
begin
  {********************************}
  { transform object to eye coords }
  {********************************}
  Push_trans_stack(trans_stack_ptr);
  Transform_trans_stack(trans_stack_ptr, object_ptr^.trans);
  Get_trans_stack(trans_stack_ptr, trans);

  {******************************************}
  { find bounds transformation in eye coords }
  {******************************************}
  case object_ptr^.kind of
    view_object_prim, view_object_clip:
      bounds_trans := trans;

    view_object_decl:
      begin
        bounds_trans :=
          Extent_box_trans(object_ptr^.object_decl_ptr^.extent_box);
        Transform_trans(bounds_trans, trans);
      end;
  end; {case}

  {********************************************}
  { calculate visibility of object from bounds }
  {********************************************}
  if object_ptr^.bounding_kind in infinite_bounding_kinds then
    visibility := partially_visible
  else if (visibility <> completely_visible) then
    begin
      Make_bounds(bounds, object_ptr^.bounding_kind, bounds_trans);
      visibility := Bounds_visibility(bounds, bounds_trans,
        current_viewport_ptr);
    end;

  if (visibility <> completely_invisible) then
    begin
      {*******************************************}
      { propagate object attributes to subobjects }
      {*******************************************}
      Push_attributes_stack(attributes_stack_ptr);
      Apply_attributes_stack(attributes_stack_ptr, object_ptr^.attributes);

      {*********************************}
      { calculate visibility of details }
      {*********************************}
      detail_visible := true;
      if (min_feature_size <> 0) then
        if Visual_size(object_ptr^.bounding_kind, bounds_trans,
          current_projection_ptr) < min_feature_size then
          detail_visible := false;
      clipping := (visibility <> completely_visible) or (clipping_planes_ptr <>
        nil);

      if (level_of_detail = 0) and (object_ptr^.kind = view_object_decl) or not
        detail_visible then
        begin
          {*******************}
          { draw bounding box }
          {*******************}
          Set_trans_stack(trans_stack_ptr, bounds_trans);
          Show_surface_bounds(drawable, object_ptr^.bounding_kind, clipping);
          drawable.Update;
        end
      else
        case object_ptr^.kind of
          {******************}
          { primitive object }
          {******************}
          view_object_prim:
            begin
              surface_ptr := object_ptr^.surface_ptr;
              while (surface_ptr <> nil) do
                begin
                  Show_surface(drawable, surface_ptr, clipping);
                  surface_ptr := surface_ptr^.next;
                end;
              drawable.Update;
            end;

          {****************}
          { clipping plane }
          {****************}
          view_object_clip:
            begin
              Get_trans_stack(trans_stack_ptr, trans);
              Push_clipping_plane(clipping_planes_ptr, trans.origin,
                Cross_product(trans.x_axis, trans.y_axis));
            end;

          {****************}
          { complex object }
          {****************}
          view_object_decl:
            begin
              {************************}
              { set up clipping planes }
              {************************}
              sub_object_ptr := object_ptr^.object_decl_ptr^.clipping_plane_ptr;
              while sub_object_ptr <> nil do
                begin
                  Show_sub_objects(drawable, sub_object_ptr, visibility,
                    level_of_detail -
                    1);
                  sub_object_ptr := sub_object_ptr^.next;
                end;

              {******************}
              { draw sub objects }
              {******************}
              sub_object_ptr := object_ptr^.object_decl_ptr^.sub_object_ptr;
              Decreasing_center_depth_sort(sub_object_ptr, trans);
              while sub_object_ptr <> nil do
                begin
                  Show_sub_objects(drawable, sub_object_ptr, visibility,
                    level_of_detail -
                    1);
                  sub_object_ptr := sub_object_ptr^.spatial_next;
                end; {while}

              {**********************}
              { nuke clipping planes }
              {**********************}
              sub_object_ptr := object_ptr^.object_decl_ptr^.clipping_plane_ptr;
              while sub_object_ptr <> nil do
                begin
                  Pop_clipping_plane(clipping_planes_ptr);
                  sub_object_ptr := sub_object_ptr^.next;
                end;
            end;
        end; {case}

      Pop_attributes_stack(attributes_stack_ptr);
    end;

  Pop_trans_stack(trans_stack_ptr);
end; {procedure Show_sub_objects}


procedure Show_scene(drawable: drawable_type;
  object_ptr: view_object_inst_ptr_type;
  trans: trans_type;
  level_of_detail: integer);
var
  attributes: object_attributes_type;
begin
  {***************************}
  { set attributes of picture }
  {***************************}
  attributes := null_attributes;
  Set_render_mode_attributes(attributes, render_mode);
  Set_edge_mode_attributes(attributes, edge_mode);
  Set_edge_orientation_attributes(attributes, edge_orientation);
  Set_outline_kind_attributes(attributes, outline_kind);
  Set_shading_attributes(attributes, shading);

  {************************}
  { initialize trans stack }
  {************************}
  trans_stack_ptr := New_trans_stack;
  Set_trans_mode(postmultiply_trans);
  Push_trans_stack(trans_stack_ptr);
  Set_trans_stack(trans_stack_ptr, trans);

  {*****************************}
  { initialize attributes stack }
  {*****************************}
  attributes_stack_ptr := New_attributes_stack;
  Set_attributes_mode(postapply_attributes);
  Push_attributes_stack(attributes_stack_ptr);
  Set_attributes_stack(attributes_stack_ptr, attributes);

  Show_sub_objects(drawable, object_ptr, partially_visible, level_of_detail);

  {******************}
  { free trans stack }
  {******************}
  Pop_trans_stack(trans_stack_ptr);
  Set_trans_mode(premultiply_trans);
  Free_trans_stack(trans_stack_ptr);

  {***********************}
  { free attributes stack }
  {***********************}
  Pop_attributes_stack(attributes_stack_ptr);
  Set_attributes_mode(preapply_attributes);
  Free_attributes_stack(attributes_stack_ptr);
end; {procedure Show_scene}


end.

