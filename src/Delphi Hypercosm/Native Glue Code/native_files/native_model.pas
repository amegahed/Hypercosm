unit native_model;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            native_model               3d       }
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
  {                     native model data kinds                   }
  {***************************************************************}
  native_model_data_kind_type = (

    {***********************************}
    { current transformation attributes }
    {***********************************}
    native_trans, native_shader_trans,

    {************************************}
    { previous transformation attributes }
    {************************************}
    native_trans_stack, native_shader_trans_stack,

    {**************************}
    { default primitive colors }
    {**************************}

    {**********}
    { quadrics }
    {**********}
    native_sphere_color, native_cylinder_color, native_cone_color,
    native_paraboloid_color, native_hyperboloid1_color,
    native_hyperboloid2_color,

    {*******************}
    { planar primitives }
    {*******************}
    native_plane_color, native_disk_color, native_ring_color,
    native_triangle_color, native_parallelogram_color, native_polygon_color,

    {***********************}
    { non-planar primitives }
    {***********************}
    native_torus_color, native_block_color, native_shaded_triangle_color,
    native_shaded_polygon_color, native_mesh_color, native_blob_color,

    {************************}
    { non-surface primitives }
    {************************}
    native_point_color, native_line_color, native_volume_color);


  {***************************************************************}
  {                    native model method kinds                  }
  {***************************************************************}
  native_model_method_kind_type = (

    {**********}
    { quadrics }
    {**********}
    native_sphere, native_cylinder, native_cone, native_paraboloid,
    native_hyperboloid1, native_hyperboloid2,

    {*******************}
    { planar primitives }
    {*******************}
    native_plane, native_disk, native_ring, native_triangle,
    native_parallelogram, native_polygon,

    {***********************}
    { non-planar primitives }
    {***********************}
    native_torus, native_block, native_shaded_triangle, native_shaded_polygon,
    native_mesh, native_blob,

    {************************}
    { non-surface primitives }
    {************************}
    native_points, native_line, native_volume,

    {*********************}
    { clipping primitives }
    {*********************}
    native_clipping_plane,

    {*********************}
    { lighting primitives }
    {*********************}
    native_distant_light, native_point_light, native_spot_light,

    {*****************************}
    { native model function kinds }
    {*****************************}
    native_trans_level, native_transform_point, native_transform_vector);


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}
function Found_native_model_data_by_name(name: string_type;
  var kind: native_model_data_kind_type): boolean;
function Found_native_model_method_by_name(name: string_type;
  var kind: native_model_method_kind_type): boolean;

{************************************************}
{ routines to query native data and method kinds }
{************************************************}
function Native_model_data_number: integer;
function Native_model_method_number: integer;


implementation
uses
  hashtables;


var
  native_data_table_ptr: hashtable_ptr_type;
  native_method_table_ptr: hashtable_ptr_type;


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}


function Found_native_model_data_by_name(name: string_type;
  var kind: native_model_data_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_data_table_ptr, value, name) then
    begin
      kind := native_model_data_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_model_data_by_name := found;
end; {function Found_native_model_data_by_name}


function Found_native_model_method_by_name(name: string_type;
  var kind: native_model_method_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_method_table_ptr, value, name) then
    begin
      kind := native_model_method_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_model_method_by_name := found;
end; {function Found_native_model_method_by_name}


{***************************************}
{ routines to query native method kinds }
{***************************************}


function Native_model_data_number: integer;
begin
  Native_model_data_number := ord(native_volume_color) + 1;
end; {function Native_model_data_number}


function Native_model_method_number: integer;
begin
  Native_model_method_number := ord(native_transform_vector) + 1;
end; {function Native_model_method_number}


initialization
  native_data_table_ptr := New_hashtable;
  native_method_table_ptr := New_hashtable;

  {***********************************}
  { current transformation attributes }
  {***********************************}
  Enter_hashtable(native_data_table_ptr, 'trans', ord(native_trans));
  Enter_hashtable(native_data_table_ptr, 'shader_trans',
    ord(native_shader_trans));

  {************************************}
  { previous transformation attributes }
  {************************************}
  Enter_hashtable(native_data_table_ptr, 'trans_stack',
    ord(native_trans_stack));
  Enter_hashtable(native_data_table_ptr, 'shader_trans_stack',
    ord(native_shader_trans_stack));

  {**************************}
  { default primitive colors }
  {**************************}

  {**********}
  { quadrics }
  {**********}
  Enter_hashtable(native_data_table_ptr, 'sphere_color',
    ord(native_sphere_color));
  Enter_hashtable(native_data_table_ptr, 'cylinder_color',
    ord(native_cylinder_color));
  Enter_hashtable(native_data_table_ptr, 'cone_color', ord(native_cone_color));
  Enter_hashtable(native_data_table_ptr, 'paraboloid_color',
    ord(native_paraboloid_color));
  Enter_hashtable(native_data_table_ptr, 'hyperboloid1_color',
    ord(native_hyperboloid1_color));
  Enter_hashtable(native_data_table_ptr, 'hyperboloid2_color',
    ord(native_hyperboloid2_color));

  {*******************}
  { planar primitives }
  {*******************}
  Enter_hashtable(native_data_table_ptr, 'plane_color',
    ord(native_plane_color));
  Enter_hashtable(native_data_table_ptr, 'disk_color', ord(native_disk_color));
  Enter_hashtable(native_data_table_ptr, 'ring_color', ord(native_ring_color));
  Enter_hashtable(native_data_table_ptr, 'triangle_color',
    ord(native_triangle_color));
  Enter_hashtable(native_data_table_ptr, 'parallelogram_color',
    ord(native_parallelogram_color));
  Enter_hashtable(native_data_table_ptr, 'polygon_color',
    ord(native_polygon_color));

  {***********************}
  { non-planar primitives }
  {***********************}
  Enter_hashtable(native_data_table_ptr, 'torus_color',
    ord(native_torus_color));
  Enter_hashtable(native_data_table_ptr, 'block_color',
    ord(native_block_color));
  Enter_hashtable(native_data_table_ptr, 'shaded_triangle_color',
    ord(native_shaded_triangle_color));
  Enter_hashtable(native_data_table_ptr, 'shaded_polygon_color',
    ord(native_shaded_polygon_color));
  Enter_hashtable(native_data_table_ptr, 'mesh_color', ord(native_mesh_color));
  Enter_hashtable(native_data_table_ptr, 'blob_color', ord(native_blob_color));

  {************************}
  { non-surface primitives }
  {************************}
  Enter_hashtable(native_data_table_ptr, 'point_color',
    ord(native_point_color));
  Enter_hashtable(native_data_table_ptr, 'line_color', ord(native_line_color));
  Enter_hashtable(native_data_table_ptr, 'volume_color',
    ord(native_volume_color));

  {**********}
  { quadrics }
  {**********}
  Enter_hashtable(native_method_table_ptr, 'sphere', ord(native_sphere));
  Enter_hashtable(native_method_table_ptr, 'cylinder', ord(native_cylinder));
  Enter_hashtable(native_method_table_ptr, 'cone', ord(native_cone));
  Enter_hashtable(native_method_table_ptr, 'paraboloid',
    ord(native_paraboloid));
  Enter_hashtable(native_method_table_ptr, 'hyperboloid1',
    ord(native_hyperboloid1));
  Enter_hashtable(native_method_table_ptr, 'hyperboloid2',
    ord(native_hyperboloid2));

  {*******************}
  { planar primitives }
  {*******************}
  Enter_hashtable(native_method_table_ptr, 'plane', ord(native_plane));
  Enter_hashtable(native_method_table_ptr, 'disk', ord(native_disk));
  Enter_hashtable(native_method_table_ptr, 'ring', ord(native_ring));
  Enter_hashtable(native_method_table_ptr, 'triangle', ord(native_triangle));
  Enter_hashtable(native_method_table_ptr, 'parallelogram',
    ord(native_parallelogram));
  Enter_hashtable(native_method_table_ptr, 'polygon', ord(native_polygon));

  {***********************}
  { non-planar primitives }
  {***********************}
  Enter_hashtable(native_method_table_ptr, 'torus', ord(native_torus));
  Enter_hashtable(native_method_table_ptr, 'block', ord(native_block));
  Enter_hashtable(native_method_table_ptr, 'shaded_triangle',
    ord(native_shaded_triangle));
  Enter_hashtable(native_method_table_ptr, 'shaded_polygon',
    ord(native_shaded_polygon));
  Enter_hashtable(native_method_table_ptr, 'mesh', ord(native_mesh));
  Enter_hashtable(native_method_table_ptr, 'blob', ord(native_blob));

  {************************}
  { non-surface primitives }
  {************************}
  Enter_hashtable(native_method_table_ptr, 'points', ord(native_points));
  Enter_hashtable(native_method_table_ptr, 'line', ord(native_line));
  Enter_hashtable(native_method_table_ptr, 'volume', ord(native_volume));

  {*********************}
  { clipping primitives }
  {*********************}
  Enter_hashtable(native_method_table_ptr, 'clipping_plane',
    ord(native_clipping_plane));

  {*********************}
  { lighting primitives }
  {*********************}
  Enter_hashtable(native_method_table_ptr, 'distant_light',
    ord(native_distant_light));
  Enter_hashtable(native_method_table_ptr, 'point_light',
    ord(native_point_light));
  Enter_hashtable(native_method_table_ptr, 'spot_light',
    ord(native_spot_light));

  {**************************}
  { transformation functions }
  {**************************}
  Enter_hashtable(native_method_table_ptr, 'trans_level',
    ord(native_trans_level));
  Enter_hashtable(native_method_table_ptr, 'transform_point',
    ord(native_transform_point));
  Enter_hashtable(native_method_table_ptr, 'transform_vector',
    ord(native_transform_vector));
end.
