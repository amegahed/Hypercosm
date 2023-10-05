unit assign_native_render;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm        assign_native_render           3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for maintaining              }
{       the primitive state varibles.                           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  eye, project, image_files, state_vars, addr_types, native_render;


type
  shader_coord_kind_type = (display_shader, screen_shader, camera_shader,
    world_shader, local_shader, surface_shader, parametric_shader);


var
  {****************************************************}
  { arrays for converting integers to enumerated types }
  {****************************************************}
  shader_coord_kind_index_array: array[1..7] of shader_coord_kind_type;
  projection_kind_index_array: array[1..4] of projection_kind_type;
  coord_system_index_array: array[1..2] of eye_coords_kind_type;
  render_mode_index_array: array[1..5] of render_mode_type;
  edge_mode_index_array: array[1..3] of edge_mode_type;
  edge_orientation_index_array: array[1..2] of edge_orientation_type;
  outline_kind_index_array: array[1..2] of outline_kind_type;
  shading_index_array: array[1..3] of shading_type;
  scanning_index_array: array[1..3] of scanning_type;
  file_format_index_array: array[1..3] of file_format_type;


  {************************}
  { native viewing indices }
  {************************}
  native_eye_index: stack_index_type;
  native_lookat_index: stack_index_type;
  native_roll_index: stack_index_type;
  native_yaw_index: stack_index_type;
  native_pitch_index: stack_index_type;
  native_coord_system_index: stack_index_type;

  {***********************}
  { native camera indices }
  {***********************}
  native_field_of_view_index: stack_index_type;
  native_projection_index: stack_index_type;

  {*********************************}
  { native rendering window indices }
  {*********************************}
  native_width_index: stack_index_type;
  native_height_index: stack_index_type;
  native_h_center_index: stack_index_type;
  native_v_center_index: stack_index_type;
  native_window_name_index: stack_index_type;

  {************************}
  { native display indices }
  {************************}
  native_aspect_ratio_index: stack_index_type;
  native_logo_index: stack_index_type;
  native_frame_index: stack_index_type;
  native_cursor_index: stack_index_type;
  native_show_pictures_index: stack_index_type;
  native_save_pictures_index: stack_index_type;
  native_file_format_index: stack_index_type;
  native_frame_number_index: stack_index_type;
  native_picture_name_index: stack_index_type;

  {******************************************}
  { native material shape attributes indices }
  {******************************************}
  native_color_index: stack_index_type;
  native_material_index: stack_index_type;

  {*******************************************}
  { native rendering shape attributes indices }
  {*******************************************}
  native_render_mode_index: stack_index_type;
  native_shading_index: stack_index_type;

  {*******************************************}
  { native wireframe shape attributes indices }
  {*******************************************}
  native_edge_mode_index: stack_index_type;
  native_edge_orientation_index: stack_index_type;
  native_outline_kind_index: stack_index_type;

  {*********************************************}
  { native ray tracing shape attributes indices }
  {*********************************************}
  native_shadows_index: stack_index_type;
  native_reflections_index: stack_index_type;
  native_refractions_index: stack_index_type;

  {**************************}
  { native rendering indices }
  {**************************}
  native_facets_index: stack_index_type;
  native_antialiasing_index: stack_index_type;
  native_supersampling_index: stack_index_type;
  native_ambient_color_index: stack_index_type;
  native_background_index: stack_index_type;
  native_fog_factor_index: stack_index_type;
  native_min_feature_size_index: stack_index_type;
  native_stereo_index: stack_index_type;
  native_left_color_index: stack_index_type;
  native_right_color_index: stack_index_type;
  native_double_buffer_index: stack_index_type;

  {***************************}
  { native raytracing indices }
  {***************************}
  native_scanning_index: stack_index_type;
  native_max_reflections_index: stack_index_type;
  native_max_refractions_index: stack_index_type;
  native_min_ray_weight_index: stack_index_type;


  {************************************************************}
  { initialize indices to execute native modelling assignments }
  {************************************************************}
procedure Set_native_render_data_index(kind: native_render_data_kind_type;
  stack_index: stack_index_type);

{***********************************************}
{ routines to get primitive data from the stack }
{***********************************************}
procedure Get_viewing_data;
procedure Get_display_data;
procedure Get_attributes_data;
procedure Get_rendering_data;
procedure Get_raytracing_data;
procedure Get_picture_data;

{***********************************************}
{ routines to put primitive data onto the stack }
{***********************************************}
procedure Put_attributes_data;

{***********************************************}
{ routines to write current value of state vars }
{***********************************************}
procedure Write_viewing_data;
procedure Write_display_data;
procedure Write_attributes_data;
procedure Write_rendering_data;
procedure Write_raytracing_data;
procedure Write_picture_data;


implementation
uses
  vectors, string_io, colors, textures, materials, object_attr,
  attr_stack, objects, data_types, stacks, memrefs, get_stack_data,
  set_stack_data, get_heap_data, query_data, deref_arrays;


const
  {************************}
  { directional components }
  {************************}
  diffuse_offset = 2;
  specular_offset = 5;
  specular_power_offset = 8;

  {****************************}
  { non directional components }
  {****************************}
  ambient_offset = 9;
  emissive_offset = 12;

  {**************************}
  { secondary ray components }
  {**************************}
  reflected_offset = 15;
  transmitted_offset = 18;

  {*****************************}
  { wireframe color and texture }
  {*****************************}
  wireframe_color_offset = 21;
  texture_offset = 24;


procedure Init_native_render_enums;
var
  projection_kind: projection_kind_type;
  coord_system: eye_coords_kind_type;
  render_mode: render_mode_type;
  edge_mode: edge_mode_type;
  edge_orientation: edge_orientation_type;
  outline_kind: outline_kind_type;
  shading: shading_type;
  scanning: scanning_type;
  file_format: file_format_type;
  shader_coord_kind: shader_coord_kind_type;
begin
  {*****************************************************}
  { initialize array to map integers to projection type }
  {*****************************************************}
  for projection_kind := orthographic to panoramic do
    projection_kind_index_array[ord(projection_kind) + 1] := projection_kind;

  {*****************************************************}
  { initialize array to map integers to coord axes type }
  {*****************************************************}
  for coord_system := left_handed to right_handed do
    coord_system_index_array[ord(coord_system) + 1] := coord_system;

  {******************************************************}
  { initialize array to map integers to render_mode type }
  {******************************************************}
  for render_mode := pointplot_mode to shaded_line_mode do
    render_mode_index_array[ord(render_mode) + 1] := render_mode;

  {****************************************************}
  { initialize array to map integers to edge_mode type }
  {****************************************************}
  for edge_mode := silhouette_edges to all_edges do
    edge_mode_index_array[ord(edge_mode) + 1] := edge_mode;

  {***********************************************************}
  { initialize array to map integers to edge_orientation type }
  {***********************************************************}
  for edge_orientation := front_edges to full_edges do
    edge_orientation_index_array[ord(edge_orientation) + 1] := edge_orientation;

  {*******************************************************}
  { initialize array to map integers to outline_kind type }
  {*******************************************************}
  for outline_kind := weak_outline to bold_outline do
    outline_kind_index_array[ord(outline_kind) + 1] := outline_kind;

  {**************************************************}
  { initialize array to map integers to shading type }
  {**************************************************}
  for shading := face_shading to pixel_shading do
    shading_index_array[ord(shading) + 1] := shading;

  {***************************************************}
  { initialize array to map integers to scanning type }
  {***************************************************}
  for scanning := linear_scan to random_scan do
    scanning_index_array[ord(scanning) + 1] := scanning;

  {******************************************************}
  { initialize array to map integers to file format type }
  {******************************************************}
  for file_format := raw_format to pict_format do
    file_format_index_array[ord(file_format) + 1] := file_format;

  {************************************************************}
  { initialize array to map integers to shader coord kind type }
  {************************************************************}
  for shader_coord_kind := display_shader to parametric_shader do
    shader_coord_kind_index_array[ord(shader_coord_kind) + 1] :=
      shader_coord_kind;
end; {procedure Init_native_render_enums}


{*****************************************************}
{ set indices to execute native modelling assignments }
{*****************************************************}


procedure Set_native_render_data_index(kind: native_render_data_kind_type;
  stack_index: stack_index_type);
begin
  case kind of

    {********************}
    { viewing attributes }
    {********************}
    native_eye:
      native_eye_index := stack_index;
    native_lookat:
      native_lookat_index := stack_index;
    native_roll:
      native_roll_index := stack_index;
    native_yaw:
      native_yaw_index := stack_index;
    native_pitch:
      native_pitch_index := stack_index;
    native_coord_system:
      native_coord_system_index := stack_index;

    {*******************}
    { camera attributes }
    {*******************}
    native_field_of_view:
      native_field_of_view_index := stack_index;
    native_projection:
      native_projection_index := stack_index;

    {*****************************}
    { rendering window attributes }
    {*****************************}
    native_width:
      native_width_index := stack_index;
    native_height:
      native_height_index := stack_index;
    native_h_center:
      native_h_center_index := stack_index;
    native_v_center:
      native_v_center_index := stack_index;
    native_window_name:
      native_window_name_index := stack_index;

    {********************}
    { display attributes }
    {********************}
    native_aspect_ratio:
      native_aspect_ratio_index := stack_index;
    native_logo:
      native_logo_index := stack_index;
    native_frame:
      native_frame_index := stack_index;
    native_cursor:
      native_cursor_index := stack_index;
    native_show_pictures:
      native_show_pictures_index := stack_index;
    native_save_pictures:
      native_save_pictures_index := stack_index;
    native_file_format:
      native_file_format_index := stack_index;
    native_frame_number:
      native_frame_number_index := stack_index;
    native_picture_name:
      native_picture_name_index := stack_index;

    {***************************}
    { material shape attributes }
    {***************************}
    native_color:
      native_color_index := stack_index;
    native_material:
      native_material_index := stack_index;

    {****************************}
    { rendering shape attributes }
    {****************************}
    native_render_mode:
      native_render_mode_index := stack_index;
    native_shading:
      native_shading_index := stack_index;

    {****************************}
    { wireframe shape attributes }
    {****************************}
    native_edge_mode:
      native_edge_mode_index := stack_index;
    native_edge_orientation:
      native_edge_orientation_index := stack_index;
    native_outline_kind:
      native_outline_kind_index := stack_index;

    {******************************}
    { ray tracing shape attributes }
    {******************************}
    native_shadows:
      native_shadows_index := stack_index;
    native_reflections:
      native_reflections_index := stack_index;
    native_refractions:
      native_refractions_index := stack_index;

    {**********************}
    { rendering attributes }
    {**********************}
    native_facets:
      native_facets_index := stack_index;
    native_antialiasing:
      native_antialiasing_index := stack_index;
    native_supersampling:
      native_supersampling_index := stack_index;
    native_ambient_color:
      native_ambient_color_index := stack_index;
    native_background:
      native_background_index := stack_index;
    native_fog_factor:
      native_fog_factor_index := stack_index;
    native_min_feature_size:
      native_min_feature_size_index := stack_index;
    native_stereo:
      native_stereo_index := stack_index;
    native_left_color:
      native_left_color_index := stack_index;
    native_right_color:
      native_right_color_index := stack_index;
    native_double_buffer:
      native_double_buffer_index := stack_index;

    {************************}
    { ray tracing attributes }
    {************************}
    native_scanning:
      native_scanning_index := stack_index;
    native_max_reflections:
      native_max_reflections_index := stack_index;
    native_max_refractions:
      native_max_refractions_index := stack_index;
    native_min_ray_weight:
      native_min_ray_weight_index := stack_index;

  end; {case}
end; {procedure Set_native_render_data_index}


{***********************************************}
{ routines to get primitive data from the stack }
{***********************************************}


{********************************}
{ primitive variable assignments }
{********************************}


procedure Get_viewing_data;
begin
  if native_eye_index <> 0 then
    eye_point := Get_global_vector(native_eye_index);
  if native_lookat_index <> 0 then
    lookat_point := Get_global_vector(native_lookat_index);
  if native_roll_index <> 0 then
    roll := Get_global_scalar(native_roll_index);
  if native_yaw_index <> 0 then
    delta_yaw := Get_global_scalar(native_yaw_index);
  if native_pitch_index <> 0 then
    delta_pitch := Get_global_scalar(native_pitch_index);
  if native_coord_system_index <> 0 then
    eye_coords_kind :=
      coord_system_index_array[Get_global_integer(native_coord_system_index)];
end; {procedure Get_viewing_data}


procedure Get_camera_data;
begin
  if native_field_of_view_index <> 0 then
    field_of_view := Get_global_scalar(native_field_of_view_index);
  if native_projection_index <> 0 then
    projection_kind :=
      projection_kind_index_array[Get_global_integer(native_projection_index)];
end; {procedure Get_camera_data}


procedure Get_rendering_window_data;
begin
  if native_width_index <> 0 then
    new_window_size.h := Get_global_integer(native_width_index);
  if native_height_index <> 0 then
    new_window_size.v := Get_global_integer(native_height_index);
  if native_h_center_index <> 0 then
    new_window_placement.h := Get_global_integer(native_h_center_index);
  if native_v_center_index <> 0 then
    new_window_placement.v := Get_global_integer(native_v_center_index);
  if native_window_name_index <> 0 then
    new_window_name :=
      Get_string_from_handle(Get_global_handle(native_window_name_index));
end; {procedure Get_rendering_window_data}


procedure Get_display_data;
begin
  if native_aspect_ratio_index <> 0 then
    screen_physical_aspect_ratio :=
      Get_global_scalar(native_aspect_ratio_index);
  if native_logo_index <> 0 then
    logo_displayed := Get_global_boolean(native_logo_index);
  if native_frame_index <> 0 then
    frame_displayed := Get_global_boolean(native_frame_index);
  if native_cursor_index <> 0 then
    cursor_displayed := Get_global_boolean(native_cursor_index);
  if native_show_pictures_index <> 0 then
    show_pictures := Get_global_boolean(native_show_pictures_index);
  if native_save_pictures_index <> 0 then
    save_pictures := Get_global_boolean(native_save_pictures_index);
  if native_file_format_index <> 0 then
    file_format :=
      file_format_index_array[Get_global_integer(native_file_format_index)];
  if native_frame_number_index <> 0 then
    frame_number := Get_global_integer(native_frame_number_index);
  if native_picture_name_index <> 0 then
    image_file_name :=
      Get_string_from_handle(Get_global_handle(native_picture_name_index));
end; {procedure Get_display_data}


function Found_material(var material_ptr: material_ptr_type;
  var wireframe_color: color_type;
  stack_index: stack_index_type): boolean;
var
  memref: memref_type;
  diffuse, specular: color_type;
  specular_power: real;
  ambient, emissive: color_type;
  reflected, transmitted: color_type;
  texture_memref: memref_type;
  texture_ptr: texture_ptr_type;
  found: boolean;
begin
  memref := Get_global_memref(stack_index);

  if memref <> 0 then
    begin
      {************************}
      { directional components }
      {************************}
      diffuse := Get_memref_color(memref, diffuse_offset);
      specular := Get_memref_color(memref, specular_offset);
      specular_power := Get_memref_scalar(memref, specular_power_offset);

      {****************************}
      { non directional components }
      {****************************}
      ambient := Get_memref_color(memref, ambient_offset);
      emissive := Get_memref_color(memref, emissive_offset);

      {**************************}
      { secondary ray components }
      {**************************}
      reflected := Get_memref_color(memref, reflected_offset);
      transmitted := Get_memref_color(memref, transmitted_offset);

      {*****************************}
      { wireframe color and texture }
      {*****************************}
      wireframe_color := Get_memref_color(memref, wireframe_color_offset);
      texture_memref := Get_memref_memref(memref, texture_offset);

      {*************************************}
      { get native texture ptr from texture }
      {*************************************}
      if texture_memref <> 0 then
        texture_ptr := texture_ptr_type(Get_memref_long(texture_memref, 2))
      else
        texture_ptr := nil;

      {*********************}
      { create new material }
      {*********************}
      material_ptr := New_material(diffuse, specular, specular_power, ambient,
        emissive, reflected, transmitted, texture_ptr);
      found := true;
    end
  else
    begin
      material_ptr := nil;
      found := false;
    end;

  Found_material := found;
end; {function Found_material}


procedure Get_attributes_data;
var
  attributes: object_attributes_type;
  boolean_val: boolean_type;
  integer_val: integer_type;
  color_val: color_type;
  wireframe_color: color_type;
  material_ptr: material_ptr_type;
begin
  {****************************************}
  { get attributes data from current state }
  {****************************************}
  Get_attributes_stack(model_attr_stack_ptr, attributes);

  {**********************************************************}
  { get color and material attributes from interpreter stack }
  {**********************************************************}
  if native_color_index <> 0 then
    if Found_color(color_val, Stack_index_to_addr(native_color_index)) then
      Set_color_attributes(attributes, color_val);

  if native_material_index <> 0 then
    if Found_material(material_ptr, wireframe_color, native_material_index) then
      begin
        Set_material_attributes(attributes, material_ptr);
        Set_color_attributes(attributes, wireframe_color);
      end;

  {*************************************************}
  { get rendering attributes from interpreter stack }
  {*************************************************}
  if native_render_mode_index <> 0 then
    if Found_integer(integer_val, Stack_index_to_addr(native_render_mode_index))
      then
      Set_render_mode_attributes(attributes,
        render_mode_index_array[integer_val]);

  if native_shading_index <> 0 then
    if Found_integer(integer_val, Stack_index_to_addr(native_shading_index))
      then
      Set_shading_attributes(attributes, shading_index_array[integer_val]);

  {*************************************************}
  { get wireframe attributes from interpreter stack }
  {*************************************************}
  if native_edge_mode_index <> 0 then
    if Found_integer(integer_val, Stack_index_to_addr(native_edge_mode_index))
      then
      Set_edge_mode_attributes(attributes, edge_mode_index_array[integer_val]);

  if native_edge_orientation_index <> 0 then
    if Found_integer(integer_val,
      Stack_index_to_addr(native_edge_orientation_index)) then
      Set_edge_orientation_attributes(attributes,
        edge_orientation_index_array[integer_val]);

  if native_outline_kind_index <> 0 then
    if Found_integer(integer_val, Stack_index_to_addr(native_outline_kind_index))
      then
      Set_outline_kind_attributes(attributes,
        outline_kind_index_array[integer_val]);

  {***************************************************}
  { get ray tracing attributes from interpreter stack }
  {***************************************************}
  if native_shadows_index <> 0 then
    if Found_boolean(boolean_val, Stack_index_to_addr(native_shadows_index))
      then
      Set_shadow_attributes(attributes, boolean_val);

  if native_reflections_index <> 0 then
    if Found_boolean(boolean_val, Stack_index_to_addr(native_reflections_index))
      then
      Set_reflection_attributes(attributes, boolean_val);

  if native_refractions_index <> 0 then
    if Found_boolean(boolean_val, Stack_index_to_addr(native_refractions_index))
      then
      Set_refraction_attributes(attributes, boolean_val);

  {********************************}
  { get attributes from stack data }
  {********************************}
  Set_attributes_stack(model_attr_stack_ptr, attributes);
end; {procedure Get_attributes_data}


procedure Get_rendering_data;
begin
  if native_facets_index <> 0 then
    facets := Get_global_integer(native_facets_index);
  if native_antialiasing_index <> 0 then
    antialiasing := Get_global_boolean(native_antialiasing_index);
  if native_supersampling_index <> 0 then
    supersamples := Get_global_integer(native_supersampling_index);
  if native_ambient_color_index <> 0 then
    ambient_color := Get_global_color(native_ambient_color_index);
  if native_background_index <> 0 then
    background_color := Get_global_color(native_background_index);
  if native_fog_factor_index <> 0 then
    fog_factor := Get_global_scalar(native_fog_factor_index);
  if native_min_feature_size_index <> 0 then
    min_feature_size := Get_global_scalar(native_min_feature_size_index);
  if native_stereo_index <> 0 then
    stereo_seperation := Get_global_scalar(native_stereo_index);
  if native_left_color_index <> 0 then
    left_color := Get_global_color(native_left_color_index);
  if native_right_color_index <> 0 then
    right_color := Get_global_color(native_right_color_index);
  if native_double_buffer_index <> 0 then
    double_buffer_mode := Get_global_boolean(native_double_buffer_index);
end; {procedure Get_rendering_data}


procedure Get_raytracing_data;
begin
  if native_scanning_index <> 0 then
    scanning := scanning_index_array[Get_global_integer(native_scanning_index)];
  if native_max_reflections_index <> 0 then
    max_reflections := Get_global_integer(native_max_reflections_index);
  if native_max_refractions_index <> 0 then
    max_refractions := Get_global_integer(native_max_refractions_index);
  if native_min_ray_weight_index <> 0 then
    min_ray_weight := Get_global_scalar(native_min_ray_weight_index);
end; {procedure Get_raytracing_data}


procedure Get_picture_data;
begin
  Get_viewing_data;
  Get_camera_data;
  Get_rendering_window_data;
  Get_display_data;
  Get_rendering_data;
  Get_raytracing_data;
end; {procedure Get_picture_data}


procedure Put_attributes_data;
var
  attributes: object_attributes_type;
  memref: memref_type;
begin
  {********************************}
  { get attributes data from stack }
  {********************************}
  Get_attributes_stack(model_attr_stack_ptr, attributes);

  {********************************************************}
  { set color and material attributes on interpreter stack }
  {********************************************************}
  if native_color_index <> 0 then
    if attributes.valid[color_attributes] then
      Set_global_color(native_color_index, attributes.color)
    else
      begin
        Set_global_error(native_color_index);
        Set_global_error(native_color_index + 1);
        Set_global_error(native_color_index + 2);
      end;

  if native_material_index <> 0 then
    begin
      memref := Get_global_memref(native_material_index);
      if memref <> 0 then
        begin
          Free_memref(memref);
          Set_global_memref(native_material_index, 0);
        end;
    end;

  {***********************************************}
  { set rendering attributes on interpreter stack }
  {***********************************************}
  if native_render_mode_index <> 0 then
    if attributes.valid[render_mode_attributes] then
      Set_global_integer(native_render_mode_index, ord(attributes.render_mode) +
        1)
    else
      Set_global_error(native_render_mode_index);

  if native_shading_index <> 0 then
    if attributes.valid[shading_attributes] then
      Set_global_integer(native_shading_index, ord(attributes.shading) + 1)
    else
      Set_global_error(native_shading_index);

  {***********************************************}
  { set wireframe attributes on interpreter stack }
  {***********************************************}
  if native_edge_mode_index <> 0 then
    if attributes.valid[edge_mode_attributes] then
      Set_global_integer(native_edge_mode_index, ord(attributes.edge_mode) + 1)
    else
      Set_global_error(native_edge_mode_index);

  if native_edge_orientation_index <> 0 then
    if attributes.valid[edge_orientation_attributes] then
      Set_global_integer(native_edge_orientation_index,
        ord(attributes.edge_orientation) + 1)
    else
      Set_global_error(native_edge_orientation_index);

  if native_outline_kind_index <> 0 then
    if attributes.valid[outline_kind_attributes] then
      Set_global_integer(native_outline_kind_index, ord(attributes.outline_kind)
        + 1)
    else
      Set_global_error(native_outline_kind_index);

  {*************************************************}
  { set ray tracing attributes on interpreter stack }
  {*************************************************}
  if native_shadows_index <> 0 then
    if attributes.valid[shadow_attributes] then
      Set_global_boolean(native_shadows_index, attributes.shadows)
    else
      Set_global_error(native_shadows_index);

  if native_reflections_index <> 0 then
    if attributes.valid[reflection_attributes] then
      Set_global_boolean(native_reflections_index, attributes.reflections)
    else
      Set_global_error(native_reflections_index);

  if native_refractions_index <> 0 then
    if attributes.valid[refraction_attributes] then
      Set_global_boolean(native_refractions_index, attributes.refractions)
    else
      Set_global_error(native_refractions_index);
end; {procedure Put_attributes_data}


{***********************************************}
{ routines to write current value of state vars }
{***********************************************}


procedure Write_viewing_data;
const
  decimal_places = 4;
  commas = true;
begin
  writeln('eye_point = ', Vector_to_str(eye_point, decimal_places, false,
    commas));
  writeln('lookat_point = ', Vector_to_str(lookat_point, decimal_places, false,
    commas));
  writeln('roll = ', roll: 1: decimal_places);
  writeln('yaw = ', delta_yaw: 1: decimal_places);
  writeln('pitch = ', delta_pitch: 1: decimal_places);
  writeln('field_of_view = ', field_of_view: 1: decimal_places);
  writeln('projection = ', Projection_kind_to_str(projection_kind));
  writeln('eye_coords = ', Eye_coords_kind_to_str(eye_coords_kind));
end; {procedure Write_viewing_data}


procedure Write_display_data;
const
  decimal_places = 4;
begin
  writeln('window_name = ', new_window_name);
  writeln('width = ', new_window_size.h: 1);
  writeln('height  = ', new_window_size.v: 1);
  writeln('h_center = ', new_window_placement.h: 1);
  writeln('v_center = ', new_window_placement.v: 1);
  writeln('aspect_ratio = ', screen_physical_aspect_ratio: 1: decimal_places);
  writeln('logo = ', logo_displayed);
  writeln('frame = ', frame_displayed);
  writeln('cursor = ', cursor_displayed);
  writeln('show_pictures = ', show_pictures);
  writeln('save_pictures = ', save_pictures);
  writeln('file_format = ', File_format_to_str(file_format));
  writeln('frame_number = ', frame_number: 1);
  writeln('picture_name = ', image_file_name);
end; {procedure Write_display_data}


procedure Write_attributes_data;
const
  decimal_places = 4;
  commas = true;
var
  attributes: object_attributes_type;
begin
  {****************************************}
  { get attributes data from current state }
  {****************************************}
  Get_attributes_stack(model_attr_stack_ptr, attributes);

  writeln('color = ', Vector_to_str(Color_to_vector(attributes.color),
    decimal_places, false, commas));
  writeln('shadows = ', attributes.shadows);
  writeln('reflections = ', attributes.reflections);
  writeln('refractions = ', attributes.refractions);
  writeln('shading = ', Shading_to_str(attributes.shading));
  writeln('render_mode = ', Render_mode_to_str(attributes.render_mode));
  writeln('edge_mode = ', Edge_mode_to_str(attributes.edge_mode));
  writeln('edge_orientation = ',
    Edge_orientation_to_str(attributes.edge_orientation));
  writeln('outline_kind = ', Outline_kind_to_str(attributes.outline_kind));
end; {procedure Write_attributes_data}


procedure Write_rendering_data;
const
  decimal_places = 4;
  commas = true;
begin
  writeln('facets = ', facets: 1);
  writeln('antialiasing = ', antialiasing);
  writeln('supersamples = ', supersamples: 1);
  writeln('ambient_color = ', Vector_to_str(Color_to_vector(ambient_color),
    decimal_places, false, commas));
  writeln('background = ', Vector_to_str(Color_to_vector(background_color),
    decimal_places, false, commas));
  writeln('fog_factor = ', fog_factor: 1: decimal_places);
  writeln('min_feature_size = ', min_feature_size: 1: decimal_places);
  writeln('stereo_seperation = ', stereo_seperation: 1: decimal_places);
  writeln('left_color = ', Vector_to_str(Color_to_vector(left_color),
    decimal_places, false, commas));
  writeln('right_color = ', Vector_to_str(Color_to_vector(right_color),
    decimal_places, false, commas));
  writeln('double_buffer = ', double_buffer_mode);
end; {procedure Write_rendering_data}


procedure Write_raytracing_data;
const
  decimal_places = 4;
begin
  writeln('scanning = ', Scanning_to_str(scanning));
  writeln('max_reflections = ', max_reflections: 1);
  writeln('max_refractions = ', max_refractions: 1);
  writeln('min_ray_weight = ', min_ray_weight: 1: decimal_places);
end; {procedure Write_raytracing_data}


procedure Write_picture_data;
begin
  Write_viewing_data;
  Write_display_data;
  Write_rendering_data;
  Write_raytracing_data;
end; {procedure Write_picture_data}


initialization
  {******************************************************}
  { initialize arrays to map integers to rendering enums }
  {******************************************************}
  Init_native_render_enums;

  {***********************************}
  { initialize native viewing indices }
  {***********************************}
  native_eye_index := 0;
  native_lookat_index := 0;
  native_roll_index := 0;
  native_yaw_index := 0;
  native_pitch_index := 0;
  native_coord_system_index := 0;

  {**********************************}
  { initialize native camera indices }
  {**********************************}
  native_field_of_view_index := 0;
  native_projection_index := 0;

  {********************************************}
  { initialize native rendering window indices }
  {********************************************}
  native_width_index := 0;
  native_height_index := 0;
  native_h_center_index := 0;
  native_v_center_index := 0;
  native_window_name_index := 0;

  {***********************************}
  { initialize native display indices }
  {***********************************}
  native_aspect_ratio_index := 0;
  native_logo_index := 0;
  native_frame_index := 0;
  native_cursor_index := 0;
  native_show_pictures_index := 0;
  native_save_pictures_index := 0;
  native_file_format_index := 0;
  native_frame_number_index := 0;
  native_picture_name_index := 0;

  {*****************************************************}
  { initialize native material shape attributes indices }
  {*****************************************************}
  native_color_index := 0;
  native_material_index := 0;

  {******************************************************}
  { initialize native rendering shape attributes indices }
  {******************************************************}
  native_render_mode_index := 0;
  native_shading_index := 0;

  {******************************************************}
  { initialize native wireframe shape attributes indices }
  {******************************************************}
  native_edge_mode_index := 0;
  native_edge_orientation_index := 0;
  native_outline_kind_index := 0;

  {********************************************************}
  { initialize native ray tracing shape attributes indices }
  {********************************************************}
  native_shadows_index := 0;
  native_reflections_index := 0;
  native_refractions_index := 0;

  {*************************************}
  { initialize native rendering indices }
  {*************************************}
  native_facets_index := 0;
  native_antialiasing_index := 0;
  native_supersampling_index := 0;
  native_ambient_color_index := 0;
  native_background_index := 0;
  native_fog_factor_index := 0;
  native_min_feature_size_index := 0;
  native_stereo_index := 0;
  native_left_color_index := 0;
  native_right_color_index := 0;
  native_double_buffer_index := 0;

  {**************************************}
  { initialize native raytracing indices }
  {**************************************}
  native_scanning_index := 0;
  native_max_reflections_index := 0;
  native_max_refractions_index := 0;
  native_min_ray_weight_index := 0;
end.

