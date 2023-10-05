unit assign_native_model;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm         assign_native_model           3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for executing native         }
{       modelling assignments.                                  }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types, native_model;


var
  {***********************************}
  { current transformation attributes }
  {***********************************}
  native_trans_index, native_shader_trans_index: stack_index_type;

  {************************************}
  { previous transformation attributes }
  {************************************}
  native_trans_stack_index, native_shader_trans_stack_index: stack_index_type;

  {**************************}
  { default primitive colors }
  {**************************}

  {**********}
  { quadrics }
  {**********}
  native_sphere_color_index: stack_index_type;
  native_cylinder_color_index: stack_index_type;
  native_cone_color_index: stack_index_type;
  native_paraboloid_color_index: stack_index_type;
  native_hyperboloid1_color_index: stack_index_type;
  native_hyperboloid2_color_index: stack_index_type;

  {*******************}
  { planar primitives }
  {*******************}
  native_plane_color_index: stack_index_type;
  native_disk_color_index: stack_index_type;
  native_ring_color_index: stack_index_type;
  native_triangle_color_index: stack_index_type;
  native_parallelogram_color_index: stack_index_type;
  native_polygon_color_index: stack_index_type;

  {***********************}
  { non-planar primitives }
  {***********************}
  native_torus_color_index: stack_index_type;
  native_block_color_index: stack_index_type;
  native_shaded_triangle_color_index: stack_index_type;
  native_shaded_polygon_color_index: stack_index_type;
  native_mesh_color_index: stack_index_type;
  native_blob_color_index: stack_index_type;

  {************************}
  { non-surface primitives }
  {************************}
  native_point_color_index: stack_index_type;
  native_line_color_index: stack_index_type;
  native_volume_color_index: stack_index_type;


{*****************************************************}
{ set indices to execute native modelling assignments }
{*****************************************************}
procedure Set_native_model_data_index(kind: native_model_data_kind_type;
  stack_index: stack_index_type);

{************************************************************}
{ routines to get transformation data from interpreter stack }
{************************************************************}
procedure Get_trans_data;
procedure Get_shader_trans_data;
procedure Get_trans_stack_data;
procedure Get_shader_trans_stack_data;

{************************************************************}
{ routines to put transformation data onto interpreter stack }
{************************************************************}
procedure Put_trans_data;
procedure Put_shader_trans_data;
procedure Put_trans_stack_data;
procedure Put_shader_trans_stack_data;


implementation
uses
  trans, trans_stack, objects, get_stack_data, set_stack_data, get_heap_data,
  set_heap_data, deref_arrays;


const
  x_axis_offset = 1;
  y_axis_offset = 4;
  z_axis_offset = 7;
  origin_offset = 10;
  size_of_trans = 13;


  {************************************************************}
  { routines to get transformation data from interpreter stack }
  {************************************************************}


procedure Get_trans_data;
var
  trans: trans_type;
begin
  if native_trans_index <> 0 then
    begin
      {***************************************}
      { get trans data from interpreter stack }
      {***************************************}
      trans.x_axis := Get_global_vector(native_trans_index + x_axis_offset);
      trans.y_axis := Get_global_vector(native_trans_index + y_axis_offset);
      trans.z_axis := Get_global_vector(native_trans_index + z_axis_offset);
      trans.origin := Get_global_vector(native_trans_index + origin_offset);

      {***************************}
      { set trans from stack data }
      {***************************}
      Set_trans_stack(model_trans_stack_ptr, trans);
    end;
end; {procedure Get_trans_data}


procedure Get_shader_trans_data;
var
  trans: trans_type;
begin
  if native_shader_trans_index <> 0 then
    begin
      {***************************************}
      { get trans data from interpreter stack }
      {***************************************}
      trans.x_axis := Get_global_vector(native_shader_trans_index +
        x_axis_offset);
      trans.y_axis := Get_global_vector(native_shader_trans_index +
        y_axis_offset);
      trans.z_axis := Get_global_vector(native_shader_trans_index +
        z_axis_offset);
      trans.origin := Get_global_vector(native_shader_trans_index +
        origin_offset);

      {***************************}
      { set trans from stack data }
      {***************************}
      Set_trans_stack(shader_trans_stack_ptr, trans);
    end;
end; {procedure Get_shader_trans_data}


procedure Get_trans_stack_data;
var
  trans: trans_type;
  handle: handle_type;
  handle_index: heap_index_type;
begin
  if native_trans_stack_index <> 0 then
    begin
      handle := Get_global_handle(native_trans_stack_index);

      if handle <> 0 then
        begin
          {***************************************}
          { get trans data from interpreter stack }
          {***************************************}
          handle_index := Deref_row_array(handle, model_trans_stack_ptr^.height,
            size_of_trans);

          trans.x_axis := Get_handle_vector(handle, handle_index +
            x_axis_offset);
          trans.y_axis := Get_handle_vector(handle, handle_index +
            y_axis_offset);
          trans.z_axis := Get_handle_vector(handle, handle_index +
            z_axis_offset);
          trans.origin := Get_handle_vector(handle, handle_index +
            origin_offset);

          {***************************}
          { set trans from stack data }
          {***************************}
          Set_trans_stack(model_trans_stack_ptr, trans);
        end;
    end;
end; {procedure Get_trans_stack_data}


procedure Get_shader_trans_stack_data;
var
  trans: trans_type;
  handle: handle_type;
  handle_index: heap_index_type;
begin
  if native_shader_trans_stack_index <> 0 then
    begin
      handle := Get_global_handle(native_shader_trans_stack_index);

      if handle <> 0 then
        begin
          {***************************************}
          { get trans data from interpreter stack }
          {***************************************}
          handle_index := Deref_row_array(handle,
            shader_trans_stack_ptr^.height, size_of_trans);

          trans.x_axis := Get_handle_vector(handle, handle_index +
            x_axis_offset);
          trans.y_axis := Get_handle_vector(handle, handle_index +
            y_axis_offset);
          trans.z_axis := Get_handle_vector(handle, handle_index +
            z_axis_offset);
          trans.origin := Get_handle_vector(handle, handle_index +
            origin_offset);

          {***************************}
          { set trans from stack data }
          {***************************}
          Set_trans_stack(shader_trans_stack_ptr, trans);
        end;
    end;
end; {procedure Get_shader_trans_stack_data}


{************************************************************}
{ routines to put transformation data onto interpreter stack }
{************************************************************}


procedure Put_trans_data;
var
  trans: trans_type;
begin
  if native_trans_index <> 0 then
    begin
      {*************************************}
      { get trans from transformation stack }
      {*************************************}
      Get_trans_stack(model_trans_stack_ptr, trans);

      {***********************************************}
      { echo trans data back out to interpreter stack }
      {***********************************************}
      Set_global_vector(native_trans_index + x_axis_offset, trans.x_axis);
      Set_global_vector(native_trans_index + y_axis_offset, trans.y_axis);
      Set_global_vector(native_trans_index + z_axis_offset, trans.z_axis);
      Set_global_vector(native_trans_index + origin_offset, trans.origin);
    end;
end; {procedure Put_trans_data}


procedure Put_shader_trans_data;
var
  trans: trans_type;
begin
  if native_shader_trans_index <> 0 then
    begin
      {*************************************}
      { get trans from transformation stack }
      {*************************************}
      Get_trans_stack(shader_trans_stack_ptr, trans);

      {***********************************************}
      { echo trans data back out to interpreter stack }
      {***********************************************}
      Set_global_vector(native_shader_trans_index + x_axis_offset,
        trans.x_axis);
      Set_global_vector(native_shader_trans_index + y_axis_offset,
        trans.y_axis);
      Set_global_vector(native_shader_trans_index + z_axis_offset,
        trans.z_axis);
      Set_global_vector(native_shader_trans_index + origin_offset,
        trans.origin);
    end;
end; {procedure Put_shader_trans_data}


procedure Put_trans_stack_data;
var
  trans: trans_type;
  handle: handle_type;
  handle_index: heap_index_type;
begin
  if native_trans_stack_index <> 0 then
    begin
      handle := Get_global_handle(native_trans_stack_index);

      if handle <> 0 then
        begin
          {*************************************}
          { get trans from transformation stack }
          {*************************************}
          Get_trans_stack(model_trans_stack_ptr, trans);

          {***********************************************}
          { echo trans data back out to interpreter stack }
          {***********************************************}
          handle_index := Deref_row_array(handle, model_trans_stack_ptr^.height,
            size_of_trans);

          Set_handle_vector(handle, handle_index + x_axis_offset, trans.x_axis);
          Set_handle_vector(handle, handle_index + y_axis_offset, trans.y_axis);
          Set_handle_vector(handle, handle_index + z_axis_offset, trans.z_axis);
          Set_handle_vector(handle, handle_index + origin_offset, trans.origin);
        end;
    end;
end; {procedure Put_trans_stack_data}


procedure Put_shader_trans_stack_data;
var
  trans: trans_type;
  handle: handle_type;
  handle_index: heap_index_type;
begin
  if native_shader_trans_stack_index <> 0 then
    begin
      handle := Get_global_handle(native_shader_trans_stack_index);

      if handle <> 0 then
        begin
          {*************************************}
          { get trans from transformation stack }
          {*************************************}
          Get_trans_stack(shader_trans_stack_ptr, trans);

          {***********************************************}
          { echo trans data back out to interpreter stack }
          {***********************************************}
          handle_index := Deref_row_array(handle,
            shader_trans_stack_ptr^.height, size_of_trans);

          Set_handle_vector(handle, handle_index + x_axis_offset, trans.x_axis);
          Set_handle_vector(handle, handle_index + y_axis_offset, trans.y_axis);
          Set_handle_vector(handle, handle_index + z_axis_offset, trans.z_axis);
          Set_handle_vector(handle, handle_index + origin_offset, trans.origin);
        end;
    end;
end; {procedure Put_shader_trans_stack_data}


{*****************************************************}
{ set indices to execute native modelling assignments }
{*****************************************************}


procedure Set_native_model_data_index(kind: native_model_data_kind_type;
  stack_index: stack_index_type);
begin
  case kind of

    {***********************************}
    { current transformation attributes }
    {***********************************}
    native_trans:
      native_trans_index := stack_index;
    native_shader_trans:
      native_shader_trans_index := stack_index;

    {************************************}
    { previous transformation attributes }
    {************************************}
    native_trans_stack:
      native_trans_stack_index := stack_index;
    native_shader_trans_stack:
      native_shader_trans_stack_index := stack_index;

    {**************************}
    { default primitive colors }
    {**************************}

    {**********}
    { quadrics }
    {**********}
    native_sphere_color:
      native_sphere_color_index := stack_index;
    native_cylinder_color:
      native_cylinder_color_index := stack_index;
    native_cone_color:
      native_cone_color_index := stack_index;
    native_paraboloid_color:
      native_paraboloid_color_index := stack_index;
    native_hyperboloid1_color:
      native_hyperboloid1_color_index := stack_index;
    native_hyperboloid2_color:
      native_hyperboloid2_color_index := stack_index;

    {*******************}
    { planar primitives }
    {*******************}
    native_plane_color:
      native_plane_color_index := stack_index;
    native_disk_color:
      native_disk_color_index := stack_index;
    native_ring_color:
      native_ring_color_index := stack_index;
    native_triangle_color:
      native_triangle_color_index := stack_index;
    native_parallelogram_color:
      native_parallelogram_color_index := stack_index;
    native_polygon_color:
      native_polygon_color_index := stack_index;

    {***********************}
    { non-planar primitives }
    {***********************}
    native_torus_color:
      native_torus_color_index := stack_index;
    native_block_color:
      native_block_color_index := stack_index;
    native_shaded_triangle_color:
      native_shaded_triangle_color_index := stack_index;
    native_shaded_polygon_color:
      native_shaded_polygon_color_index := stack_index;
    native_mesh_color:
      native_mesh_color_index := stack_index;
    native_blob_color:
      native_blob_color_index := stack_index;

    {************************}
    { non-surface primitives }
    {************************}
    native_point_color:
      native_point_color_index := stack_index;
    native_line_color:
      native_line_color_index := stack_index;
    native_volume_color:
      native_volume_color_index := stack_index;

  end; {case}
end; {procedure Set_native_model_data_index}


initialization
  {**********************************}
  { current transformation variables }
  {**********************************}
  native_trans_index := 0;
  native_shader_trans_index := 0;

  {***********************************}
  { previous transformation variables }
  {***********************************}
  native_trans_stack_index := 0;
  native_shader_trans_stack_index := 0;

  {**************************}
  { default primitive colors }
  {**************************}

  {**********}
  { quadrics }
  {**********}
  native_sphere_color_index := 0;
  native_cylinder_color_index := 0;
  native_cone_color_index := 0;
  native_paraboloid_color_index := 0;
  native_hyperboloid1_color_index := 0;
  native_hyperboloid2_color_index := 0;

  {*******************}
  { planar primitives }
  {*******************}
  native_plane_color_index := 0;
  native_disk_color_index := 0;
  native_ring_color_index := 0;
  native_triangle_color_index := 0;
  native_parallelogram_color_index := 0;
  native_polygon_color_index := 0;

  {***********************}
  { non-planar primitives }
  {***********************}
  native_torus_color_index := 0;
  native_block_color_index := 0;
  native_shaded_triangle_color_index := 0;
  native_shaded_polygon_color_index := 0;
  native_mesh_color_index := 0;
  native_blob_color_index := 0;

  {************************}
  { non-surface primitives }
  {************************}
  native_point_color_index := 0;
  native_line_color_index := 0;
  native_volume_color_index := 0;
end.
