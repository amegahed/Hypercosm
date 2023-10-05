unit render;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               render                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module an image of the scene using the various     }
{       rendering modes.                                        }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans, viewing, renderer;


procedure Render_scene(renderer: renderer_type;
  object_ptr: view_object_inst_ptr_type;
  trans: trans_type);


implementation
uses
  SysUtils,
  math_utils, colors, vectors, coord_axes, extents, bounds, clip_planes, eye,
  project, viewports, visibility, proximity, state_vars, object_attr, b_rep,
  trans_stack, coord_stack, attr_stack, raytrace, shade_b_rep, z_buffer,
  textures, z_pointplot, z_silhouette, z_outline, z_wireframe, coords,
  flat_shader, gouraud_shader, phong_shader, parity_buffer, b_rep_prims,
  renderable, z_renderer, view_sorting
  {, flat_hider, gouraud_hider, phong_hider};


var
  trans_stack_ptr: trans_stack_ptr_type;
  shader_stack_ptr: trans_stack_ptr_type;
  attributes_stack_ptr: attributes_stack_ptr_type;


procedure Render_surface(renderable: polygon_renderable_type;
  surface_ptr: surface_ptr_type;
  clipping: boolean);
var
  color: color_type;
  trans: trans_type;
  edge_orientation: edge_orientation_type;
  outline_kind: outline_kind_type;
  attributes: object_attributes_type;
  texturable: texturable_type;
  texturing: boolean;
begin
  Get_trans_stack(trans_stack_ptr, trans);
  Get_attributes_stack(attributes_stack_ptr, attributes);
  color := attributes.color;
  edge_orientation := attributes.edge_orientation;
  outline_kind := attributes.outline_kind;

  {*****************************************************}
  { object attributes are limited by picture attributes }
  {*****************************************************}
  if attributes.render_mode > render_mode then
    attributes.render_mode := render_mode;
  if attributes.shading > shading then
    attributes.shading := shading;
  if surface_ptr^.shading = flat_shading then
    attributes.shading := face_shading;

  case attributes.render_mode of

    {***************************}
    { the pointplot render mode }
    {***************************}
    pointplot_mode:
      Pointplot_z_surface(renderable, surface_ptr, trans_stack_ptr, clipping);

    {****************************}
    { the wireframe render modes }
    {****************************}
    wireframe_mode:
      case attributes.edge_mode of
        silhouette_edges:
          Silhouette_z_surface(renderable, surface_ptr, edge_orientation,
            trans_stack_ptr, clipping);

        outline_edges:
          Outline_z_surface(renderable, surface_ptr, edge_orientation,
            outline_kind,
            trans_stack_ptr, clipping);

        all_edges:
          Wireframe_z_surface(renderable, surface_ptr, edge_orientation,
            trans_stack_ptr, clipping);
      end; // case

    {************************}
    { the shaded render mode }
    {************************}
    shaded_mode:
      begin
        texturing := false;
        if attributes.valid[material_attributes] then
          if attributes.material_ptr^.texture_ptr <> nil then
            if Supports(renderable, texturable_type, texturable) then
              begin
                texturable.Set_texture_map(attributes.material_ptr^.texture_ptr);
                texturing := (attributes.material_ptr^.texture_ptr <> nil);
              end;

        case attributes.shading of
          face_shading:
            Flat_shade_surface(renderable, surface_ptr, outline_kind,
              trans_stack_ptr, clipping, texturing);

          vertex_shading:
            Gouraud_shade_surface(renderable, surface_ptr, outline_kind,
              trans_stack_ptr, clipping, texturing);

          pixel_shading:
            Phong_shade_surface(z_renderer_type(renderable), surface_ptr,
              outline_kind,
              trans_stack_ptr, clipping);
        end; {case}

        if texturing then
          texturable.Set_texture_map(nil);
      end;

    {*****************************}
    { the hidden line render mode }
    {*****************************}
    hidden_line_mode:
      // Flat_hide_surface(surface_ptr, outline_kind, trans_stack_ptr, clipping);
      ;

    {*****************************}
    { the shaded line render mode }
    {*****************************}
    shaded_line_mode:
      begin
        {
        if attributes.valid[material_attributes] then
          if attributes.material_ptr^.z_texture_ptr <> nil then
            Set_current_z_texture(attributes.material_ptr^.z_texture_ptr);

        case attributes.shading of
          face_shading:
            Flat_hide_surface(surface_ptr, outline_kind, trans_stack_ptr,
              clipping);

          vertex_shading:
            Gouraud_hide_surface(surface_ptr, outline_kind, trans_stack_ptr,
              clipping);

          pixel_shading:
            Phong_hide_surface(surface_ptr, outline_kind, trans_stack_ptr,
              clipping);
        end;

        Set_current_z_texture(nil);
        }
      end;

  end; {case}
end; {procedure Render_surface}


procedure Render_surface_bounds(renderable: polygon_renderable_type;
  bounding_kind: bounding_kind_type;
  clipping: boolean);
begin
  case bounding_kind of

    planar_bounds:
      Render_surface(renderable, Parallelogram_b_rep, clipping);

    non_planar_bounds:
      Render_surface(renderable, Block_b_rep, clipping);

    infinite_planar_bounds, infinite_non_planar_bounds:
      ; {do nothing}

  end; {case}
end; {procedure Render_surface_bounds}


procedure Push_shading_trans(object_ptr: view_object_inst_ptr_type;
  parent_trans: trans_type;
  var object_trans: trans_type);
var
  bounds_trans: trans_type;
begin
  case object_ptr^.kind of
    view_object_prim, view_object_clip:
      object_trans := object_ptr^.trans;

    view_object_decl:
      begin
        object_trans :=
          Extent_box_trans(object_ptr^.object_decl_ptr^.extent_box);
        Transform_trans(object_trans, object_ptr^.trans);
      end;
  end; {case}

  {******************************************}
  { compute object to shader transformations }
  {******************************************}
  bounds_trans := object_trans;
  Transform_trans(bounds_trans, parent_trans);
  Push_coord_stack(coord_stack_ptr);
  Set_coord_stack(coord_stack_ptr, Trans_to_axes(bounds_trans));
  Push_coord_stack(normal_stack_ptr);
  Set_coord_stack(normal_stack_ptr, Trans_to_axes(Normal_trans(bounds_trans)));
end; {procedure Push_shading_trans}


procedure Push_shader_trans(object_ptr: view_object_inst_ptr_type;
  object_trans: trans_type);
var
  shader_trans: trans_type;
begin
  {****************************}
  { transform shader to object }
  {****************************}
  shader_trans := object_ptr^.shader_trans;
  Transform_trans(shader_trans, Inverse_trans(object_trans));

  {******************}
  { set shader trans }
  {******************}
  Push_trans_stack(shader_stack_ptr);
  Set_trans_stack(shader_stack_ptr, shader_trans);
  shader_stack_height := Coord_stack_height(coord_stack_ptr);

  {*****************}
  { set shader axes }
  {*****************}
  Get_trans_stack(shader_stack_ptr, shader_trans);
  shader_axes := Trans_to_axes(shader_trans);
  normal_shader_axes := Trans_to_axes(Normal_trans(shader_trans));
end; {procedure Push_shader_trans}


function Simplifyable_object(object_ptr: view_object_inst_ptr_type): boolean;
var
  simplifyable: boolean;
begin
  simplifyable := true;

  case object_ptr^.kind of

    view_object_prim:
      case object_ptr^.bounding_kind of
        planar_bounds:
          simplifyable := object_ptr^.surface_ptr^.topology_ptr^.point_number > 4;

        non_planar_bounds:
          simplifyable := object_ptr^.surface_ptr^.topology_ptr^.face_number > 6;

        infinite_planar_bounds, infinite_non_planar_bounds:
          simplifyable := false;
      end; {case}

    view_object_clip:
      simplifyable := true;

    view_object_decl:
      simplifyable := object_ptr^.object_decl_ptr^.sub_object_number > 2;

  end; {case}

  Simplifyable_object := simplifyable;
end; {procedure Simplifyable_object}


procedure Render_sub_objects(renderable: polygon_renderable_type;
  object_ptr: view_object_inst_ptr_type;
  visibility: visibility_type;
  parent_trans: trans_type);
var
  trans, bounds_trans, object_trans: trans_type;
  sub_object_ptr: view_object_inst_ptr_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  bounds: bounding_type;
  simplify, clipping: boolean;
  surface_ptr: surface_ptr_type;
  prev_shader_height: integer;
begin
  {********************************}
  { transform object to eye coords }
  {********************************}
  Push_trans_stack(trans_stack_ptr);
  Transform_trans_stack(trans_stack_ptr, object_ptr^.trans);
  Get_trans_stack(trans_stack_ptr, trans);

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

  {********************************}
  { calculate visibility of object }
  {********************************}
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
      Get_attributes_stack(attributes_stack_ptr, attributes);

      {*******************************************}
      { propagate shader attributes to subobjects }
      {*******************************************}
      Push_shading_trans(object_ptr, parent_trans, object_trans);
      if object_ptr^.attributes.valid[shader_attributes] then
        begin
          prev_shader_height := shader_stack_height;
          Push_shader_trans(object_ptr, object_trans);
        end
      else
        prev_shader_height := 0;

      {*********************************}
      { calculate visibility of details }
      {*********************************}
      if (min_feature_size <> 0) then
        begin
          if Simplifyable_object(object_ptr) then
            simplify := Visual_size(object_ptr^.bounding_kind, bounds_trans,
              current_projection_ptr) < min_feature_size
          else
            simplify := false;
        end
      else
        simplify := false;

      {********************************}
      { activate / deactivate clipping }
      {********************************}
      clipping := (visibility <> completely_visible) or
       (clipping_planes_ptr <> nil);

      {*************}
      { draw object }
      {*************}
      if simplify then
        begin
          {*******************}
          { draw bounding box }
          {*******************}
          Set_trans_stack(trans_stack_ptr, bounds_trans);
          hierarchical_obj.object_ptr := object_ptr^.ray_object_ptr;
          Render_surface_bounds(renderable, object_ptr^.bounding_kind, clipping);
        end
      else
        case object_ptr^.kind of

          {******************}
          { primitive object }
          {******************}
          view_object_prim:
            begin
              hierarchical_obj.object_ptr := object_ptr^.ray_object_ptr;
              surface_ptr := object_ptr^.surface_ptr;
              while (surface_ptr <> nil) do
                begin
                  Render_surface(renderable, surface_ptr, clipping);
                  surface_ptr := surface_ptr^.next;
                end;
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
              with hierarchical_obj do
                transform_stack.depth := transform_stack.depth + 1;
              ray_object_ptr := object_ptr^.ray_object_ptr;
              with hierarchical_obj do
                transform_stack.stack[transform_stack.depth] := ray_object_ptr;

              {************************}
              { set up clipping planes }
              {************************}
              sub_object_ptr := object_ptr^.object_decl_ptr^.clipping_plane_ptr;
              while sub_object_ptr <> nil do
                begin
                  Render_sub_objects(renderable, sub_object_ptr, visibility,
                    parent_trans);
                  sub_object_ptr := sub_object_ptr^.next;
                end;

              {******************}
              { draw sub objects }
              {******************}
              sub_object_ptr := object_ptr^.object_decl_ptr^.sub_object_ptr;
              parent_trans :=
                Inverse_trans(Extent_box_trans(object_ptr^.object_decl_ptr^.extent_box));
              Increasing_closest_depth_sort(sub_object_ptr, trans);
              while sub_object_ptr <> nil do
                begin
                  Render_sub_objects(renderable, sub_object_ptr, visibility,
                    parent_trans);
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

              with hierarchical_obj do
                transform_stack.depth := transform_stack.depth - 1;
            end;
        end; {case}

      {***********************}
      { pop object attributes }
      {***********************}
      Pop_attributes_stack(attributes_stack_ptr);
      Pop_coord_stack(coord_stack_ptr);
      Pop_coord_stack(normal_stack_ptr);
      if object_ptr^.attributes.valid[shader_attributes] then
        begin
          {***********************}
          { pop shader attributes }
          {***********************}
          Pop_trans_stack(shader_stack_ptr);
          shader_stack_height := prev_shader_height;
        end;
    end;

  Pop_trans_stack(trans_stack_ptr);
end; {procedure Render_sub_objects}


procedure Project_bounds(bounds: bounding_type);
var
  counter1, counter2, counter3: extent_type;
  point: vector_type;
begin
  if bounds.bounding_kind in [planar_bounds, non_planar_bounds] then
    case (bounds.bounding_kind) of

      planar_bounds:
        begin
          for counter1 := left to right do
            for counter2 := front to back do
              begin
                point := bounds.bounding_square[counter1, counter2];
                point := Project_point_to_point(point);
                bounds.bounding_square[counter1, counter2] := point;
              end;
        end; {planar_bounds}

      non_planar_bounds:
        begin
          for counter1 := left to right do
            for counter2 := front to back do
              for counter3 := bottom to top do
                begin
                  point := bounds.bounding_box[counter1, counter2, counter3];
                  point := Project_point_to_point(point);
                  bounds.bounding_box[counter1, counter2, counter3] := point;
                end;
        end; {non_planar_bounds}

    end; {case statement}
end; {procedure Project_bounds}


procedure Get_object_z_range(var z_near, z_far: real;
  object_ptr: view_object_inst_ptr_type;
  trans: trans_type);
var
  scene_trans, bounds_trans: trans_type;
  bounds: bounding_type;
  point: vector_type;
  inside: boolean;
begin
  bounds_trans := Extent_box_trans(object_ptr^.object_decl_ptr^.extent_box);

  {*****************************************************}
  { find bounding transformation of scene in eye coords }
  {*****************************************************}
  scene_trans := bounds_trans;
  Transform_trans(scene_trans, object_ptr^.trans);
  Transform_trans(scene_trans, trans);
  Make_bounds(bounds, non_planar_bounds, scene_trans);

  {************************************}
  { find furthest z extent from bounds }
  {************************************}
  point := Farthest_bounds_vertex_in_direction(bounds, To_vector(0, 1, 0),
    z_far);

  {*******************************************}
  { find if eye is inside or outside of scene }
  {*******************************************}
  point := zero_vector;
  Transform_point(point, Inverse_trans(scene_trans));
  inside := Point_in_extent_box(point, unit_extent_box);

  {***********************************}
  { find nearest z extent from bounds }
  {***********************************}
  if inside then
    z_near := 0
  else
    point := Closest_bounds_point_in_direction(bounds, scene_trans,
      To_vector(0, 1, 0), z_near);
end; {procedure Get_object_z_range}


procedure Snap_near_and_far(var z_near, z_far: real);
var
  near_power, far_power: real;
begin
  near_power := Logarithm(z_near, 2);
  far_power := Logarithm(z_far, 2);

  if near_power < 0 then
    near_power := trunc(near_power - 1)
  else
    near_power := trunc(near_power);

  if far_power < 0 then
    far_power := trunc(far_power)
  else
    far_power := trunc(far_power + 1);

  z_near := Power(2, near_power);
  z_far := Power(2, far_power);
end; {procedure Snap_near_and_far}


procedure Project_near_and_far(var z_near, z_far: real);
var
  point: vector_type;
begin
  point := Project_point_to_point(To_vector(0, z_near, 0));
  z_near := point.z;
  point := Project_point_to_point(To_vector(0, z_far, 0));
  z_far := point.z;
end; {procedure Project_near_and_far}


procedure Render_scene(renderer: renderer_type;
  object_ptr: view_object_inst_ptr_type;
  trans: trans_type);
const
  test_z_range = false;
  integer_z_buffer = true;
var
  use_z_hardware: boolean;
  z_near, z_far: real;
  z_min: real;
begin
  {*******************************************}
  { if using an integer z buffer (z hardware) }
  { set closest and farthest clipping planes. }
  {*******************************************}
  use_z_hardware := renderer is hardware_renderer_type;

  if use_z_hardware or test_z_range then
    begin
      Get_object_z_range(z_near, z_far, object_ptr, trans);

      if test_z_range then
        begin
          writeln('z_near, z_far = ', z_near, ', ', z_far);
          Push_clipping_plane(clipping_planes_ptr, To_vector(0, z_far, 0),
            y_vector);
        end;

      if use_z_hardware then
        begin
          {********************************************************}
          { if near is too close, then let it be a fraction of far }
          {********************************************************}
          z_min := z_far / 100;
          if z_near < z_min then
            z_near := z_min;

          {***********************************************}
          { snap z near and far to nearest power of 2 to  }
          { eliminate pixel jitter from integer z buffers }
          {***********************************************}
          if integer_z_buffer then
            Snap_near_and_far(z_near, z_far);

          {**********************************************}
          { find z near and far in projected coordinates }
          {**********************************************}
          Project_near_and_far(z_near, z_far);

          {**************************************************}
          { set range of integer z buffer to encompass scene }
          {**************************************************}
          hardware_renderer_type(renderer).Set_range(z_near, z_far);
        end;
    end;

  {**************************************************}
  { save the transformation from eye to world coords }
  { because visibility (which is computed first) is  }
  { determined in eye coords but lighting (which is  }
  { computed later) is determined in world coords so }
  { we must be able to go back from eye to world.    }
  {**************************************************}
  world_to_eye := trans;
  eye_to_world := Inverse_trans(trans);

  hierarchical_obj.object_ptr := nil;
  hierarchical_obj.transform_stack.depth := 0;

  // renderer.Set_shading_mode(flat_shading_mode);
  // renderer.Set_parity_mode(no_parity);

  Set_lighting_mode(two_sided);
  Set_camera_to_world(Trans_to_axes(eye_trans));

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
  shader_stack_ptr := New_trans_stack;
  coord_stack_ptr := New_coord_stack;
  normal_stack_ptr := New_coord_stack;

  Set_trans_mode(postmultiply_trans);
  Push_trans_stack(trans_stack_ptr);
  Set_trans_stack(trans_stack_ptr, trans);
  Push_trans_stack(shader_stack_ptr);
  Set_trans_stack(shader_stack_ptr, unit_trans);

  {*****************************}
  { initialize attributes stack }
  {*****************************}
  attributes_stack_ptr := New_attributes_stack;
  Set_attributes_mode(postapply_attributes);
  Push_attributes_stack(attributes_stack_ptr);
  Set_attributes_stack(attributes_stack_ptr, attributes);

  Render_sub_objects(renderer, object_ptr, partially_visible, unit_trans);

  {******************}
  { free trans stack }
  {******************}
  Set_trans_mode(premultiply_trans);
  Free_trans_stack(trans_stack_ptr);
  Free_trans_stack(shader_stack_ptr);
  Free_coord_stack(coord_stack_ptr);
  Free_coord_stack(normal_stack_ptr);

  {***********************}
  { free attributes stack }
  {***********************}
  Set_attributes_mode(preapply_attributes);
  Free_attributes_stack(attributes_stack_ptr);

  if test_z_range then
    Pop_clipping_plane(clipping_planes_ptr);
end; {procedure Render_scene}


end.

