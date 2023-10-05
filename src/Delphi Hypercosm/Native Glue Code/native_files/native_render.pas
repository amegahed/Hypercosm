unit native_render;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           native_render               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The primitive data needed by the interpreter is found   }
{       by its index on the stack (its order of declaration)    }
{       so that the identifiers which stand for this data       }
{       may be changed without recompiling the code.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings;


type
  {***************************************************************}
  {                    native render data kinds                   }
  {***************************************************************}
  native_render_data_kind_type = (

    {********************}
    { viewing attributes }
    {********************}
    native_eye, native_lookat, native_roll, native_yaw, native_pitch,
    native_coord_system,

    {*******************}
    { camera attributes }
    {*******************}
    native_field_of_view, native_projection,

    {*****************************}
    { rendering window attributes }
    {*****************************}
    native_width, native_height, native_h_center, native_v_center,
    native_window_name,

    {********************}
    { display attributes }
    {********************}
    native_aspect_ratio, native_logo, native_frame, native_cursor,
    native_show_pictures, native_save_pictures, native_file_format,
    native_frame_number, native_picture_name,

    {***************************}
    { material shape attributes }
    {***************************}
    native_color, native_material, native_material_stack,

    {****************************}
    { rendering shape attributes }
    {****************************}
    native_render_mode, native_shading,

    {****************************}
    { wireframe shape attributes }
    {****************************}
    native_edge_mode, native_edge_orientation, native_outline_kind,

    {******************************}
    { ray tracing shape attributes }
    {******************************}
    native_shadows, native_reflections, native_refractions,

    {**********************}
    { rendering attributes }
    {**********************}
    native_facets, native_antialiasing, native_supersampling,
    native_ambient_color, native_background, native_fog_factor,
    native_min_feature_size, native_stereo, native_left_color,
    native_right_color, native_double_buffer,

    {************************}
    { ray tracing attributes }
    {************************}
    native_scanning, native_max_reflections, native_max_refractions,
    native_min_ray_weight);


  {***************************************************************}
  {                   native render method kinds                  }
  {***************************************************************}
  native_render_method_kind_type = (

    {*******************}
    { shader primitives }
    {*******************}
    native_location, native_normal, native_direction, native_distance,

    {******************************************}
    { displacement and bump mapping primitives }
    {******************************************}
    native_set_location, native_set_normal, native_set_direction,
    native_set_distance,

    {*************************}
    { illumination primitives }
    {*************************}
    native_light_number, native_light_direction, native_light_intensity,

    {*********************}
    { lighting primitives }
    {*********************}
    native_diffuse, native_specular,

    {************************}
    { ray tracing primitives }
    {************************}
    native_ray_inside, native_shadow_ray, native_reflection_level,
    native_refraction_level, native_reflect, native_refract,

    {****************************}
    { texture mapping primitives }
    {****************************}
    native_new_texture, native_free_texture);


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}
function Found_native_render_data_by_name(name: string_type;
  var kind: native_render_data_kind_type): boolean;
function Found_native_render_method_by_name(name: string_type;
  var kind: native_render_method_kind_type): boolean;

{************************************************}
{ routines to query native data and method kinds }
{************************************************}
function Native_render_data_number: integer;
function Native_render_method_number: integer;


implementation
uses
  hashtables;


var
  native_data_table_ptr: hashtable_ptr_type;
  native_method_table_ptr: hashtable_ptr_type;


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}


function Found_native_render_data_by_name(name: string_type;
  var kind: native_render_data_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_data_table_ptr, value, name) then
    begin
      kind := native_render_data_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_render_data_by_name := found;
end; {function Found_native_render_data_by_name}


function Found_native_render_method_by_name(name: string_type;
  var kind: native_render_method_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_method_table_ptr, value, name) then
    begin
      kind := native_render_method_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_render_method_by_name := found;
end; {function Found_native_render_method_by_name}


{***************************************}
{ routines to query native method kinds }
{***************************************}


function Native_render_data_number: integer;
begin
  Native_render_data_number := ord(native_min_ray_weight) + 1;
end; {function Native_render_data_number}


function Native_render_method_number: integer;
begin
  Native_render_method_number := ord(native_free_texture) + 1;
end; {function Native_render_method_number}


initialization
  native_data_table_ptr := New_hashtable;
  native_method_table_ptr := New_hashtable;

  {********************}
  { viewing attributes }
  {********************}
  Enter_hashtable(native_data_table_ptr, 'eye', ord(native_eye));
  Enter_hashtable(native_data_table_ptr, 'lookat', ord(native_lookat));
  Enter_hashtable(native_data_table_ptr, 'roll', ord(native_roll));
  Enter_hashtable(native_data_table_ptr, 'yaw', ord(native_yaw));
  Enter_hashtable(native_data_table_ptr, 'pitch', ord(native_pitch));
  Enter_hashtable(native_data_table_ptr, 'coord_system',
    ord(native_coord_system));

  {*******************}
  { camera attributes }
  {*******************}
  Enter_hashtable(native_data_table_ptr, 'field_of_view',
    ord(native_field_of_view));
  Enter_hashtable(native_data_table_ptr, 'projection', ord(native_projection));

  {*****************************}
  { rendering window attributes }
  {*****************************}
  Enter_hashtable(native_data_table_ptr, 'width', ord(native_width));
  Enter_hashtable(native_data_table_ptr, 'height', ord(native_height));
  Enter_hashtable(native_data_table_ptr, 'h_center', ord(native_h_center));
  Enter_hashtable(native_data_table_ptr, 'v_center', ord(native_v_center));
  Enter_hashtable(native_data_table_ptr, 'window_name',
    ord(native_window_name));

  {********************}
  { display attributes }
  {********************}
  Enter_hashtable(native_data_table_ptr, 'aspect_ratio',
    ord(native_aspect_ratio));
  Enter_hashtable(native_data_table_ptr, 'logo', ord(native_logo));
  Enter_hashtable(native_data_table_ptr, 'frame', ord(native_frame));
  Enter_hashtable(native_data_table_ptr, 'cursor', ord(native_cursor));
  Enter_hashtable(native_data_table_ptr, 'show_pictures',
    ord(native_show_pictures));
  Enter_hashtable(native_data_table_ptr, 'save_pictures',
    ord(native_save_pictures));
  Enter_hashtable(native_data_table_ptr, 'file_format',
    ord(native_file_format));
  Enter_hashtable(native_data_table_ptr, 'frame_number',
    ord(native_frame_number));
  Enter_hashtable(native_data_table_ptr, 'picture_name',
    ord(native_picture_name));

  {***************************}
  { material shape attributes }
  {***************************}
  Enter_hashtable(native_data_table_ptr, 'color', ord(native_color));
  Enter_hashtable(native_data_table_ptr, 'material', ord(native_material));
  Enter_hashtable(native_data_table_ptr, 'material_stack',
    ord(native_material));

  {****************************}
  { rendering shape attributes }
  {****************************}
  Enter_hashtable(native_data_table_ptr, 'render_mode',
    ord(native_render_mode));
  Enter_hashtable(native_data_table_ptr, 'shading', ord(native_shading));

  {****************************}
  { wireframe shape attributes }
  {****************************}
  Enter_hashtable(native_data_table_ptr, 'edges', ord(native_edge_mode));
  Enter_hashtable(native_data_table_ptr, 'edge_orientation',
    ord(native_edge_orientation));
  Enter_hashtable(native_data_table_ptr, 'outline', ord(native_outline_kind));

  {******************************}
  { ray tracing shape attributes }
  {******************************}
  Enter_hashtable(native_data_table_ptr, 'shadows', ord(native_shadows));
  Enter_hashtable(native_data_table_ptr, 'reflections',
    ord(native_reflections));
  Enter_hashtable(native_data_table_ptr, 'refractions',
    ord(native_refractions));

  {**********************}
  { rendering attributes }
  {**********************}
  Enter_hashtable(native_data_table_ptr, 'facets', ord(native_facets));
  Enter_hashtable(native_data_table_ptr, 'antialiasing',
    ord(native_antialiasing));
  Enter_hashtable(native_data_table_ptr, 'supersampling',
    ord(native_supersampling));
  Enter_hashtable(native_data_table_ptr, 'ambient', ord(native_ambient_color));
  Enter_hashtable(native_data_table_ptr, 'background', ord(native_background));
  Enter_hashtable(native_data_table_ptr, 'fog_factor', ord(native_fog_factor));
  Enter_hashtable(native_data_table_ptr, 'min_feature_size',
    ord(native_min_feature_size));
  Enter_hashtable(native_data_table_ptr, 'stereo', ord(native_stereo));
  Enter_hashtable(native_data_table_ptr, 'left_color', ord(native_left_color));
  Enter_hashtable(native_data_table_ptr, 'right_color',
    ord(native_right_color));
  Enter_hashtable(native_data_table_ptr, 'double_buffer',
    ord(native_double_buffer));

  {************************}
  { ray tracing attributes }
  {************************}
  Enter_hashtable(native_data_table_ptr, 'scanning', ord(native_scanning));
  Enter_hashtable(native_data_table_ptr, 'max_reflections',
    ord(native_max_reflections));
  Enter_hashtable(native_data_table_ptr, 'max_refractions',
    ord(native_max_refractions));
  Enter_hashtable(native_data_table_ptr, 'min_ray_weight',
    ord(native_min_ray_weight));

  {*******************}
  { shader primitives }
  {*******************}
  Enter_hashtable(native_method_table_ptr, 'location', ord(native_location));
  Enter_hashtable(native_method_table_ptr, 'normal', ord(native_normal));
  Enter_hashtable(native_method_table_ptr, 'direction', ord(native_direction));
  Enter_hashtable(native_method_table_ptr, 'distance', ord(native_distance));

  {******************************************}
  { displacement and bump mapping primitives }
  {******************************************}
  Enter_hashtable(native_method_table_ptr, 'set_location',
    ord(native_set_location));
  Enter_hashtable(native_method_table_ptr, 'set_normal',
    ord(native_set_normal));
  Enter_hashtable(native_method_table_ptr, 'set_direction',
    ord(native_set_direction));
  Enter_hashtable(native_method_table_ptr, 'set_distance',
    ord(native_set_distance));

  {*************************}
  { illumination primitives }
  {*************************}
  Enter_hashtable(native_method_table_ptr, 'light_number',
    ord(native_light_number));
  Enter_hashtable(native_method_table_ptr, 'light_direction',
    ord(native_light_direction));
  Enter_hashtable(native_method_table_ptr, 'light_intensity',
    ord(native_light_intensity));

  {*********************}
  { lighting primitives }
  {*********************}
  Enter_hashtable(native_method_table_ptr, 'diffuse', ord(native_diffuse));
  Enter_hashtable(native_method_table_ptr, 'specular', ord(native_specular));

  {************************}
  { ray tracing primitives }
  {************************}
  Enter_hashtable(native_method_table_ptr, 'ray_inside',
    ord(native_ray_inside));
  Enter_hashtable(native_method_table_ptr, 'shadow_ray',
    ord(native_shadow_ray));
  Enter_hashtable(native_method_table_ptr, 'reflection_level',
    ord(native_reflection_level));
  Enter_hashtable(native_method_table_ptr, 'refraction_level',
    ord(native_refraction_level));
  Enter_hashtable(native_method_table_ptr, 'reflect', ord(native_reflect));
  Enter_hashtable(native_method_table_ptr, 'refract', ord(native_refract));

  {****************************}
  { texture mapping primitives }
  {****************************}
  Enter_hashtable(native_method_table_ptr, 'texture new',
    ord(native_new_texture));
  Enter_hashtable(native_method_table_ptr, 'texture free',
    ord(native_free_texture));
end.
