unit pictures;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              pictures                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains miscillaneous routines to set      }
{       up the data structures for rendering.                   }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  video, drawable, renderer, pixel_color_buffer;


{************************************}
{ routines for drawing and rendering }
{************************************}
procedure Draw_picture(drawable: drawable_type;
  var renderer: renderer_type;
  var pixel_color_buffer_ptr: pixel_color_buffer_ptr_type);


implementation
uses
  SysUtils,
  vectors, trans, colors, pixels, screen_boxes, image_files, select_video,
  eye, project, viewports, state_vars, object_attr, attr_stack, objects,
  viewing, raytrace, grid_prims, scan, lighting, luxels, precalc, preview,
  make_voxels, make_boxels, show_b_rep, render, z_renderer, select_renderer;


var
  picture_attributes: object_attributes_type;


procedure Set_window_viewing(drawable: drawable_type);
var
  screen_size: pixel_type;
  window_size: pixel_type;
  double_bufferable: double_bufferable_type;
begin
  {***********************}
  { set display paramters }
  {***********************}
  screen_size := Get_screen_size;
  screen_pixel_aspect_ratio := screen_size.v / screen_size.h;
  pixel_aspect_ratio := screen_physical_aspect_ratio /
    screen_pixel_aspect_ratio;

  {*******************************************}
  { some viewing parameters must be set after }
  { the window has been opened because they   }
  { depend on the dimensions of the window.   }
  {*******************************************}
  if current_projection_ptr <> nil then
    Free_projection(current_projection_ptr);
  if current_viewport_ptr <> nil then
    Free_viewport(current_viewport_ptr);

  {***********************}
  { set window parameters }
  {***********************}
  window_size := drawable.Get_size;
  current_projection_ptr := New_projection(projection_kind, field_of_view,
    To_screen_box(To_pixel(0, 0), window_size), pixel_aspect_ratio);
  current_viewport_ptr := New_viewport(current_projection_ptr);
  Set_eye;

  {*****************}
  { set buffer mode }
  {*****************}
  if Supports(drawable, double_bufferable_type, double_bufferable) then
    double_bufferable.Set_double_buffer_mode(double_buffer_mode);
end; {procedure Set_window_viewing}


procedure Copy_lights(object_list: object_inst_ptr_type;
  trans: trans_type);
var
  temp_trans: trans_type;
  color: color_type;
  brightness: real;
  dimensions: vector_type;
begin
  while (object_list <> nil) do
    begin
      if (object_list^.kind = complex_object) then
        begin
          if (object_list^.object_decl_ptr^.luminous) then
            begin
              temp_trans := object_list^.trans;
              Transform_trans(temp_trans, trans);
              Copy_lights(object_list^.object_decl_ptr^.sub_object_ptr,
                temp_trans);
            end;
        end
      else
        begin
          if (object_list^.kind in light_sources) then
            begin
              temp_trans := object_list^.trans;
              Transform_trans(temp_trans, trans);
              with temp_trans do
                begin
                  dimensions.x := Dot_product(x_axis, x_axis);
                  dimensions.y := Dot_product(y_axis, y_axis);
                  dimensions.z := Dot_product(z_axis, z_axis);
                  brightness := sqrt(dimensions.x + dimensions.y + dimensions.z)
                    / sqrt(3.0);
                end;

              color := object_list^.attributes.color;
              with object_list^ do
                case kind of
                  distant_light:
                    Make_distant_light(temp_trans.z_axis, brightness, color,
                      shadows);
                  point_light:
                    Make_point_light(temp_trans.origin, brightness, color,
                      shadows);
                  spot_light:
                    Make_spot_light(temp_trans.origin, temp_trans.z_axis,
                      brightness, spot_angle, color, shadows);
                end; {case}
            end;
        end;
      object_list := object_list^.next;
    end;
end; {procedure Copy_lights}


procedure Make_lights;
begin
  Copy_lights(geometry_scene_ptr, unit_trans);
  Make_luxel_space;
end; {procedure Make_lights}


procedure Init_renderer(var renderer: renderer_type);
begin
  renderer := z_renderer_type.Create;
end; {procedure Init_renderer}


procedure Init_scene_attributes;
var
  attributes: object_attributes_type;
begin
  Get_attributes_stack(model_attr_stack_ptr, attributes);
  Apply_object_attributes(attributes, picture_attributes);

  {******************************}
  { initialize global attributes }
  {******************************}
  render_mode := attributes.render_mode;
  edge_mode := attributes.edge_mode;
  edge_orientation := attributes.edge_orientation;
  outline_kind := attributes.outline_kind;
  shading := attributes.shading;
  shadows := attributes.shadows;
  reflections := attributes.reflections;
  refractions := attributes.refractions;

  {****************************}
  { initialize state variables }
  {****************************}
  min_ray_weight_squared := min_ray_weight * min_ray_weight;
end; {procedure Init_scene_attributes}


procedure Init_scene_data_structs;
begin
  if (render_mode in [hidden_line_mode, shaded_mode, shaded_line_mode]) and
    (shadows or reflections or refractions or (facets < 1)) then
    begin
      if (facets < 1) then
        begin
          {**********************}
          { full raytracing mode }
          {**********************}
          if {(Get_buffer_mode = single_buffer) and}(min_feature_size = 0) then
            begin
              {********************}
              { show voxel preview }
              {********************}
              if (facets < 1) then
                Set_facets(min_facets)
              else
                Set_facets(facets);
              Make_precalc;
              Make_preview;
              Make_voxel_space(current_window, raytracing_decls_ptr, eye_trans);
              if (stereo_seperation = 0) then
                if (current_projection_ptr^.kind = perspective) then
                  if (min_feature_size = 0) then
                    Make_boxel_space(current_window.get_size, current_window,
                      raytracing_scene_ptr, eye_trans);
            end
          else
            begin
              {**************************}
              { don't show voxel preview }
              {**************************}
              Set_facets(facets);
              Make_precalc;
              Make_voxel_space(current_window, raytracing_decls_ptr, eye_trans);
              if (stereo_seperation = 0) then
                if (current_projection_ptr^.kind = perspective) then
                  if (min_feature_size = 0) then
                    Make_boxel_space(current_window.get_size, current_window,
                      raytracing_scene_ptr, eye_trans);
            end;
        end
      else
        begin
          {***********************************}
          { raytracing - z_buffer hybrid mode }
          {***********************************}
          Set_facets(facets);
          Make_precalc;
          Make_preview;
          Make_voxel_space(current_window, raytracing_decls_ptr, eye_trans);
        end;
    end
  else
    begin
      {******************}
      { non-shaded modes }
      {******************}
      if (facets < 1) then
        Set_facets(min_facets)
      else
        Set_facets(facets);
      Make_preview;
    end;
end; {procedure Init_scene_data_structs}


procedure Begin_picture(drawable: drawable_type);
begin
  Set_window_viewing(drawable);
  Init_scene_attributes;
  Init_scene_data_structs;
  rendering := true;
end; {procedure Begin_picture}


procedure Finish_picture(drawable: drawable_type);
begin
  if frame_displayed then
    drawable.Draw_rect(null_pixel, drawable.Get_size);

  // if logo_displayed then
  //  Draw_logo;

  drawable.Show;
  rendering := false;
end; {procedure Finish_picture}


procedure Show_picture(drawable: drawable_type);
begin
  drawable.Set_color(background_color);
  drawable.Clear;
  Show_scene(drawable, viewing_scene_ptr, eye_trans, -1);
end; {procedure Show_picture}


procedure Render_picture(renderer: renderer_type);
begin
  renderer.drawable.Set_color(background_color);
  renderer.Clear;
  Make_lights;
  Render_scene(renderer, viewing_scene_ptr, eye_trans);
  Free_lights;
end; {procedure Render_picture}


procedure Raytrace_picture(drawable: drawable_type;
  pixel_color_buffer_ptr: pixel_color_buffer_ptr_type);
var
  incremental: boolean;
begin
  Make_lights;

  incremental := animating and (frame_number > starting_frame_number) and
    (min_feature_size <> 0);

  case scanning of
    linear_scan:
      Linear_raytrace(drawable, pixel_color_buffer_ptr, raytracing_scene_ptr);
    ordered_scan:
      Ordered_raytrace(drawable, pixel_color_buffer_ptr, raytracing_scene_ptr, incremental);
    random_scan:
      Random_raytrace(drawable, pixel_color_buffer_ptr, raytracing_scene_ptr, incremental);
  end; {case}

  Free_boxel_space;
  Free_lights;
end; {procedure Raytrace_picture}


procedure Draw_picture(drawable: drawable_type;
  var renderer: renderer_type;
  var pixel_color_buffer_ptr: pixel_color_buffer_ptr_type);
begin
  Begin_picture(drawable);

  if not (render_mode in [shaded_mode, shaded_line_mode]) then
    Show_picture(drawable)
  else if (facets <> 0) then
    begin
      if renderer = nil then
        renderer := Select_new_renderer([], drawable);
      Render_picture(renderer);
    end
  else
    begin
      if pixel_color_buffer_ptr = nil then
        pixel_color_buffer_ptr := Open_pixel_color_buffer(drawable.Get_size);
      Raytrace_picture(drawable, pixel_color_buffer_ptr);
    end;

  Finish_picture(drawable);
end; {procedure Draw_picture}


end.

