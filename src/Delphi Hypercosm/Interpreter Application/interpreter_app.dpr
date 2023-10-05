program interpreter_app;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm       Welcome to Hypercosm!           3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       Yes, now you, the ignorant user, can also have all      }
{       the power and flexibility of the top secret research    }
{       tool used by the virtual reality professionals          }
{       galaxywide and the heavily guarded bastion of           }
{       Western technology and basic foundation of our          }
{       religion and fundamental world view:                    }
{                                                               }
{                        Project XJV52000,                      }
{                        Secret Code Name:                      }
{                   Turbo Squidmaster Pro 9000                  }
{                                                               }
{       Remember: if it doen't have shadows and reflections,    }
{       then it's not virtual reality.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


{$APPTYPE CONSOLE}
{$I-}


uses
  SysUtils,
  exec_array_assigns in '..\Interpreter Code\interpreter_files\exec_array_assigns.pas',
  exec_assigns in '..\Interpreter Code\interpreter_files\exec_assigns.pas',
  exec_data_decls in '..\Interpreter Code\interpreter_files\exec_data_decls.pas',
  exec_decls in '..\Interpreter Code\interpreter_files\exec_decls.pas',
  exec_instructs in '..\Interpreter Code\interpreter_files\exec_instructs.pas',
  exec_methods in '..\Interpreter Code\interpreter_files\exec_methods.pas',
  exec_stmts in '..\Interpreter Code\interpreter_files\exec_stmts.pas',
  exec_structs in '..\Interpreter Code\interpreter_files\exec_structs.pas',
  interpreter in '..\Interpreter Code\interpreter_files\interpreter.pas',
  arrays in '..\Abstract Syntax Tree Code\syntax_tree_files\arrays.pas',
  code_decls in '..\Abstract Syntax Tree Code\syntax_tree_files\code_decls.pas',
  decls in '..\Abstract Syntax Tree Code\syntax_tree_files\decls.pas',
  exprs in '..\Abstract Syntax Tree Code\syntax_tree_files\exprs.pas',
  instructs in '..\Abstract Syntax Tree Code\syntax_tree_files\instructs.pas',
  stmts in '..\Abstract Syntax Tree Code\syntax_tree_files\stmts.pas',
  syntax_trees in '..\Abstract Syntax Tree Code\syntax_tree_files\syntax_trees.pas',
  type_decls in '..\Abstract Syntax Tree Code\syntax_tree_files\type_decls.pas',
  new_memory in '..\Nonportable Code\system_files\new_memory.pas',
  complex_numbers in '..\Common Code\math_files\complex_numbers.pas',
  constants in '..\Common Code\math_files\constants.pas',
  math_utils in '..\Common Code\math_files\math_utils.pas',
  trigonometry in '..\Common Code\math_files\trigonometry.pas',
  vectors in '..\Common Code\vector_files\vectors.pas',
  data_types in '..\Abstract Syntax Tree Code\type_files\data_types.pas',
  addr_types in '..\Abstract Syntax Tree Code\type_files\addr_types.pas',
  errors in '..\Nonportable Code\system_files\errors.pas',
  code_attributes in '..\Abstract Syntax Tree Code\attributes_files\code_attributes.pas',
  comments in '..\Abstract Syntax Tree Code\attributes_files\comments.pas',
  decl_attributes in '..\Abstract Syntax Tree Code\attributes_files\decl_attributes.pas',
  expr_attributes in '..\Abstract Syntax Tree Code\attributes_files\expr_attributes.pas',
  lit_attributes in '..\Abstract Syntax Tree Code\attributes_files\lit_attributes.pas',
  prim_attributes in '..\Abstract Syntax Tree Code\attributes_files\prim_attributes.pas',
  stmt_attributes in '..\Abstract Syntax Tree Code\attributes_files\stmt_attributes.pas',
  symbol_tables in '..\Abstract Syntax Tree Code\attributes_files\symbol_tables.pas',
  type_attributes in '..\Abstract Syntax Tree Code\attributes_files\type_attributes.pas',
  value_attributes in '..\Abstract Syntax Tree Code\attributes_files\value_attributes.pas',
  strings in '..\Common Code\basic_files\strings.pas',
  chars in '..\Common Code\basic_files\chars.pas',
  hashtables in '..\Common Code\basic_files\hashtables.pas',
  code_types in '..\Abstract Syntax Tree Code\type_files\code_types.pas',
  string_structs in '..\Common Code\basic_files\string_structs.pas',
  string_io in '..\Common Code\basic_files\string_io.pas',
  array_limits in '..\Runtime Code\heap_files\array_limits.pas',
  get_data in '..\Runtime Code\heap_files\get_data.pas',
  get_heap_data in '..\Runtime Code\heap_files\get_heap_data.pas',
  handles in '..\Runtime Code\heap_files\handles.pas',
  heaps in '..\Runtime Code\heap_files\heaps.pas',
  memrefs in '..\Runtime Code\heap_files\memrefs.pas',
  query_data in '..\Runtime Code\heap_files\query_data.pas',
  set_data in '..\Runtime Code\heap_files\set_data.pas',
  set_heap_data in '..\Runtime Code\heap_files\set_heap_data.pas',
  load_operands in '..\Runtime Code\operand_stack_files\load_operands.pas',
  op_stacks in '..\Runtime Code\operand_stack_files\op_stacks.pas',
  store_operands in '..\Runtime Code\operand_stack_files\store_operands.pas',
  data in '..\Runtime Code\stack_files\data.pas',
  get_params in '..\Runtime Code\stack_files\get_params.pas',
  get_stack_data in '..\Runtime Code\stack_files\get_stack_data.pas',
  params in '..\Runtime Code\stack_files\params.pas',
  set_stack_data in '..\Runtime Code\stack_files\set_stack_data.pas',
  stacks in '..\Runtime Code\stack_files\stacks.pas',
  colors in '..\Common Code\display_files\colors.pas',
  make_arrays in '..\Abstract Syntax Tree Code\make_AST_files\make_arrays.pas',
  make_code_decls in '..\Abstract Syntax Tree Code\make_AST_files\make_code_decls.pas',
  make_decls in '..\Abstract Syntax Tree Code\make_AST_files\make_decls.pas',
  make_exprs in '..\Abstract Syntax Tree Code\make_AST_files\make_exprs.pas',
  make_instructs in '..\Abstract Syntax Tree Code\make_AST_files\make_instructs.pas',
  make_stmts in '..\Abstract Syntax Tree Code\make_AST_files\make_stmts.pas',
  make_syntax_trees in '..\Abstract Syntax Tree Code\make_AST_files\make_syntax_trees.pas',
  make_type_decls in '..\Abstract Syntax Tree Code\make_AST_files\make_type_decls.pas',
  deref_arrays in '..\Interpreter Code\eval_array_files\deref_arrays.pas',
  eval_expr_arrays in '..\Interpreter Code\eval_array_files\eval_expr_arrays.pas',
  eval_limits in '..\Interpreter Code\eval_array_files\eval_limits.pas',
  eval_new_arrays in '..\Interpreter Code\eval_array_files\eval_new_arrays.pas',
  eval_row_arrays in '..\Interpreter Code\eval_array_files\eval_row_arrays.pas',
  eval_subranges in '..\Interpreter Code\eval_array_files\eval_subranges.pas',
  set_elements in '..\Interpreter Code\eval_array_files\set_elements.pas',
  eval_addrs in '..\Interpreter Code\eval_expr_files\eval_addrs.pas',
  eval_arrays in '..\Interpreter Code\eval_expr_files\eval_arrays.pas',
  eval_booleans in '..\Interpreter Code\eval_expr_files\eval_booleans.pas',
  eval_chars in '..\Interpreter Code\eval_expr_files\eval_chars.pas',
  eval_integers in '..\Interpreter Code\eval_expr_files\eval_integers.pas',
  eval_references in '..\Interpreter Code\eval_expr_files\eval_references.pas',
  eval_scalars in '..\Interpreter Code\eval_expr_files\eval_scalars.pas',
  eval_structs in '..\Interpreter Code\eval_expr_files\eval_structs.pas',
  addressing in '..\Abstract Syntax Tree Code\process_AST_files\addressing.pas',
  array_assigns in '..\Abstract Syntax Tree Code\process_AST_files\array_assigns.pas',
  array_expr_assigns in '..\Abstract Syntax Tree Code\process_AST_files\array_expr_assigns.pas',
  expr_subtrees in '..\Abstract Syntax Tree Code\process_AST_files\expr_subtrees.pas',
  implicit_stmts in '..\Abstract Syntax Tree Code\process_AST_files\implicit_stmts.pas',
  struct_assigns in '..\Abstract Syntax Tree Code\process_AST_files\struct_assigns.pas',
  subranges in '..\Abstract Syntax Tree Code\process_AST_files\subranges.pas',
  type_assigns in '..\Abstract Syntax Tree Code\process_AST_files\type_assigns.pas',
  compare_codes in '..\Abstract Syntax Tree Code\compare_attr_files\compare_codes.pas',
  compare_decls in '..\Abstract Syntax Tree Code\compare_attr_files\compare_decls.pas',
  compare_exprs in '..\Abstract Syntax Tree Code\compare_attr_files\compare_exprs.pas',
  compare_types in '..\Abstract Syntax Tree Code\compare_attr_files\compare_types.pas',
  assembler in '..\Assembler Code\asm_files\assembler.pas',
  debugger in '..\Assembler Code\asm_files\debugger.pas',
  asm_bounds in '..\Assembler Code\asm_AST_files\asm_bounds.pas',
  asm_code_decls in '..\Assembler Code\asm_AST_files\asm_code_decls.pas',
  asm_decls in '..\Assembler Code\asm_AST_files\asm_decls.pas',
  asm_exprs in '..\Assembler Code\asm_AST_files\asm_exprs.pas',
  asm_indices in '..\Assembler Code\asm_AST_files\asm_indices.pas',
  asm_instructs in '..\Assembler Code\asm_AST_files\asm_instructs.pas',
  asm_stmts in '..\Assembler Code\asm_AST_files\asm_stmts.pas',
  asm_subranges in '..\Assembler Code\asm_AST_files\asm_subranges.pas',
  asm_type_decls in '..\Assembler Code\asm_AST_files\asm_type_decls.pas',
  asms in '..\Assembler Code\asm_AST_files\asms.pas',
  file_stack in '..\Common Code\basic_files\file_stack.pas',
  native_collision in '..\Native Glue Code\native_files\native_collision.pas',
  native_glue in '..\Native Glue Code\native_files\native_glue.pas',
  eval_lights in '..\Native Glue Code\exec_graphics_files\eval_lights.pas',
  eval_shaders in '..\Native Glue Code\exec_graphics_files\eval_shaders.pas',
  exec_graphics in '..\Native Glue Code\exec_graphics_files\exec_graphics.pas',
  exec_objects in '..\Native Glue Code\exec_graphics_files\exec_objects.pas',
  exec_native in '..\Native Glue Code\exec_native_files\exec_native.pas',
  anim in '..\Scene Graph Code\anim_files\anim.pas',
  precalc in '..\Scene Graph Code\anim_files\precalc.pas',
  preview in '..\Scene Graph Code\anim_files\preview.pas',
  b_rep in '..\Scene Graph Code\b_rep_files\b_rep.pas',
  geometry in '..\Scene Graph Code\b_rep_files\geometry.pas',
  make_b_rep in '..\Scene Graph Code\b_rep_files\make_b_rep.pas',
  meshes in '..\Scene Graph Code\b_rep_files\meshes.pas',
  polygons in '..\Scene Graph Code\b_rep_files\polygons.pas',
  polymeshes in '..\Scene Graph Code\b_rep_files\polymeshes.pas',
  topology in '..\Scene Graph Code\b_rep_files\topology.pas',
  triangles in '..\Scene Graph Code\b_rep_files\triangles.pas',
  volumes in '..\Scene Graph Code\b_rep_files\volumes.pas',
  bounds in '..\Scene Graph Code\bounding_files\bounds.pas',
  extents in '..\Scene Graph Code\bounding_files\extents.pas',
  proximity in '..\Scene Graph Code\bounding_files\proximity.pas',
  cubes in '..\Scene Graph Code\isosurface_files\cubes.pas',
  isoedges in '..\Scene Graph Code\isosurface_files\isoedges.pas',
  isofaces in '..\Scene Graph Code\isosurface_files\isofaces.pas',
  isomeshes in '..\Scene Graph Code\isosurface_files\isomeshes.pas',
  isosurfaces in '..\Scene Graph Code\isosurface_files\isosurfaces.pas',
  isovertices in '..\Scene Graph Code\isosurface_files\isovertices.pas',
  attr_stack in '..\Scene Graph Code\object_attributes_files\attr_stack.pas',
  materials in '..\Scene Graph Code\object_attributes_files\materials.pas',
  object_attr in '..\Scene Graph Code\object_attributes_files\object_attr.pas',
  init_prims in '..\Scene Graph Code\object_files\init_prims.pas',
  objects in '..\Scene Graph Code\object_files\objects.pas',
  raytrace in '..\Scene Graph Code\object_files\raytrace.pas',
  viewing in '..\Scene Graph Code\object_files\viewing.pas',
  b_rep_prims in '..\Scene Graph Code\primitive_files\b_rep_prims.pas',
  b_rep_quads in '..\Scene Graph Code\primitive_files\b_rep_quads.pas',
  grid_prims in '..\Scene Graph Code\primitive_files\grid_prims.pas',
  grid_quads in '..\Scene Graph Code\primitive_files\grid_quads.pas',
  mesh_prims in '..\Scene Graph Code\primitive_files\mesh_prims.pas',
  coord_axes in '..\Common Code\trans_files\coord_axes.pas',
  coord_stack in '..\Common Code\trans_files\coord_stack.pas',
  trans in '..\Common Code\trans_files\trans.pas',
  trans_stack in '..\Common Code\trans_files\trans_stack.pas',
  trans2 in '..\Common Code\trans_files\trans2.pas',
  binormals in '..\Common Code\vector_files\binormals.pas',
  rays in '..\Common Code\vector_files\rays.pas',
  rays2 in '..\Common Code\vector_files\rays2.pas',
  vectors2 in '..\Common Code\vector_files\vectors2.pas',
  clip_lines in '..\Renderer Code\clipping_files\clip_lines.pas',
  clip_planes in '..\Renderer Code\clipping_files\clip_planes.pas',
  clip_regions in '..\Renderer Code\clipping_files\clip_regions.pas',
  eye in '..\Renderer Code\eye_files\eye.pas',
  project in '..\Renderer Code\eye_files\project.pas',
  viewports in '..\Renderer Code\eye_files\viewports.pas',
  visibility in '..\Renderer Code\eye_files\visibility.pas',
  xform_b_rep in '..\Renderer Code\eye_files\xform_b_rep.pas',
  collision in '..\Renderer Code\physics_files\collision.pas',
  coords in '..\Renderer Code\physics_files\coords.pas',
  lighting in '..\Renderer Code\physics_files\lighting.pas',
  luxels in '..\Renderer Code\physics_files\luxels.pas',
  physics in '..\Renderer Code\physics_files\physics.pas',
  uv_mapping in '..\Renderer Code\physics_files\uv_mapping.pas',
  pictures in '..\Renderer Code\picture_files\pictures.pas',
  flat_shader in '..\Renderer Code\render_files\flat_shader.pas',
  gouraud_shader in '..\Renderer Code\render_files\gouraud_shader.pas',
  hidden_lines in '..\Renderer Code\render_files\hidden_lines.pas',
  phong_shader in '..\Renderer Code\render_files\phong_shader.pas',
  render in '..\Renderer Code\render_files\render.pas',
  state_vars in '..\Renderer Code\render_files\state_vars.pas',
  shade_b_rep in '..\Renderer Code\shading_files\shade_b_rep.pas',
  shading in '..\Renderer Code\shading_files\shading.pas',
  outline in '..\Renderer Code\wireframe_files\outline.pas',
  pointplot in '..\Renderer Code\wireframe_files\pointplot.pas',
  show_b_rep in '..\Renderer Code\wireframe_files\show_b_rep.pas',
  show_lines in '..\Renderer Code\wireframe_files\show_lines.pas',
  silhouette in '..\Renderer Code\wireframe_files\silhouette.pas',
  wireframe in '..\Renderer Code\wireframe_files\wireframe.pas',
  render_lines in '..\Renderer Code\z_wireframe_files\render_lines.pas',
  z_outline in '..\Renderer Code\z_wireframe_files\z_outline.pas',
  z_pointplot in '..\Renderer Code\z_wireframe_files\z_pointplot.pas',
  z_silhouette in '..\Renderer Code\z_wireframe_files\z_silhouette.pas',
  z_wireframe in '..\Renderer Code\z_wireframe_files\z_wireframe.pas',
  screen_clip in '..\Common Code\display_files\screen_clip.pas',
  bitmaps in '..\Common Code\display_files\bitmaps.pas',
  display_lists in '..\Common Code\display_files\display_lists.pas',
  images in '..\Common Code\display_files\images.pas',
  mipmap in '..\Common Code\display_files\mipmap.pas',
  pixel_colors in '..\Common Code\display_files\pixel_colors.pas',
  pixels in '..\Common Code\display_files\pixels.pas',
  screen_boxes in '..\Common Code\display_files\screen_boxes.pas',
  native_math in '..\Native Glue Code\native_files\native_math.pas',
  native_model in '..\Native Glue Code\native_files\native_model.pas',
  native_render in '..\Native Glue Code\native_files\native_render.pas',
  native_system in '..\Native Glue Code\native_files\native_system.pas',
  assign_native_model in '..\Native Glue Code\exec_native_files\assign_native_model.pas',
  assign_native_render in '..\Native Glue Code\exec_native_files\assign_native_render.pas',
  exec_native_collision in '..\Native Glue Code\exec_native_files\exec_native_collision.pas',
  exec_native_math in '..\Native Glue Code\exec_native_files\exec_native_math.pas',
  exec_native_model in '..\Native Glue Code\exec_native_files\exec_native_model.pas',
  exec_native_render in '..\Native Glue Code\exec_native_files\exec_native_render.pas',
  exec_native_system in '..\Native Glue Code\exec_native_files\exec_native_system.pas',
  image_files in '..\Nonportable Code\multimedia_files\image_files.pas',
  noise in '..\Common Code\math_files\noise.pas',
  mouse_input in '..\Nonportable Code\device_files\mouse_input.pas',
  keyboard_input in '..\Nonportable Code\device_files\keyboard_input.pas',
  system_sounds in '..\Nonportable Code\multimedia_files\system_sounds.pas',
  clock_time in '..\Nonportable Code\system_files\clock_time.pas',
  system_interfaces in '..\Nonportable Code\system_files\system_interfaces.pas',
  normals in '..\Ray Tracing Code\intersect_files\normals.pas',
  make_voxels in '..\Ray Tracing Code\voxel_files\make_voxels.pas',
  mesh_tracer in '..\Ray Tracing Code\voxel_files\mesh_tracer.pas',
  mesh_voxels in '..\Ray Tracing Code\voxel_files\mesh_voxels.pas',
  tri_tracer in '..\Ray Tracing Code\voxel_files\tri_tracer.pas',
  tri_voxels in '..\Ray Tracing Code\voxel_files\tri_voxels.pas',
  walk_voxels in '..\Ray Tracing Code\voxel_files\walk_voxels.pas',
  intersect in '..\Ray Tracing Code\intersect_files\intersect.pas',
  nonplanar_tracer in '..\Ray Tracing Code\intersect_files\nonplanar_tracer.pas',
  planar_tracer in '..\Ray Tracing Code\intersect_files\planar_tracer.pas',
  quadric_tracer in '..\Ray Tracing Code\intersect_files\quadric_tracer.pas',
  quartic_tracer in '..\Ray Tracing Code\intersect_files\quartic_tracer.pas',
  roots in '..\Common Code\math_files\roots.pas',
  vector_graphics_files in '..\Nonportable Code\multimedia_files\vector_graphics_files.pas',
  make_boxels in '..\Ray Tracing Code\scanning_files\make_boxels.pas',
  scan in '..\Ray Tracing Code\scanning_files\scan.pas',
  seek_boxels in '..\Ray Tracing Code\scanning_files\seek_boxels.pas',
  text_files in '..\Nonportable Code\system_files\text_files.pas',
  system_events in '..\Nonportable Code\system_files\system_events.pas',
  video in '..\Common Code\display_files\video.pas',
  opengl_video in '..\Nonportable Code\video_files\opengl_video.pas',
  gdi_video in '..\Nonportable Code\video_files\gdi_video.pas',
  drawable in '..\Common Code\display_files\drawable.pas',
  select_video in '..\Nonportable Code\video_files\select_video.pas',
  textures in '..\Renderer Code\renderer_files\textures.pas',
  renderable in '..\Renderer Code\renderer_files\renderable.pas',
  renderer in '..\Renderer Code\renderer_files\renderer.pas',
  select_renderer in '..\Nonportable Code\renderer_files\select_renderer.pas',
  opengl_renderer in '..\Nonportable Code\renderer_files\opengl_renderer.pas',
  find_files in '..\Nonportable Code\system_files\find_files.pas',
  z_renderer in '..\Renderer Code\z_renderer_files\z_renderer.pas',
  z_flat_polygons in '..\Renderer Code\z_renderer_files\z_flat_polygons.pas',
  z_smooth_polygons in '..\Renderer Code\z_renderer_files\z_smooth_polygons.pas',
  z_polygons in '..\Renderer Code\z_renderer_files\z_polygons.pas',
  z_vertices in '..\Renderer Code\z_renderer_files\z_vertices.pas',
  z_pipeline in '..\Renderer Code\z_renderer_files\z_pipeline.pas',
  z_screen_clip in '..\Renderer Code\z_renderer_files\z_screen_clip.pas',
  z_clip in '..\Renderer Code\z_renderer_files\z_clip.pas',
  z_buffer in '..\Renderer Code\z_renderer_files\z_buffer.pas',
  scan_conversion in '..\Renderer Code\z_renderer_files\scan_conversion.pas',
  parity_buffer in '..\Renderer Code\z_renderer_files\parity_buffer.pas',
  z_triangles in '..\Renderer Code\z_renderer_files\z_triangles.pas',
  z_flat_lines in '..\Renderer Code\z_renderer_files\z_flat_lines.pas',
  z_points in '..\Renderer Code\z_renderer_files\z_points.pas',
  z_smooth_lines in '..\Renderer Code\z_renderer_files\z_smooth_lines.pas',
  z_phong_lines in '..\Renderer Code\z_renderer_files\z_phong_lines.pas',
  z_phong_polygons in '..\Renderer Code\z_renderer_files\z_phong_polygons.pas',
  pixel_color_buffer in '..\Ray Tracing Code\scanning_files\pixel_color_buffer.pas',
  view_sorting in '..\Scene Graph Code\object_files\view_sorting.pas',
  GL in '..\System Code\GLUT\GL.pas',
  indexed_geometry in '..\Scene Graph Code\b_rep_files\indexed_geometry.pas',
  rotations in '..\Common Code\trans_files\rotations.pas',
  reference_counting in '..\Nonportable Code\system_files\reference_counting.pas';

var
  program_name: string_type;
  file_name: string_type;


procedure Run;
var
  syntax_tree_ptr: syntax_tree_ptr_type;
  argument_list_ptr: string_list_ptr_type;
begin
  {****************************}
  { set command line arguments }
  {****************************}
  argument_list_ptr := nil;
  Add_string_to_list(Str_to_string('argument3'), argument_list_ptr);
  Add_string_to_list(Str_to_string('argument2'), argument_list_ptr);
  Add_string_to_list(Str_to_string('argument1'), argument_list_ptr);

  {********************************}
  { assemble syntax tree from file }
  {********************************}
  writeln('Assembling ', file_name, '.');
  syntax_tree_ptr := Assemble;

  {********************************************************}
  { assemble auxilliary debugging information if available }
  {********************************************************}
  file_name := Change_str_suffix(file_name, '.hcvm.txt', '.hcdb.txt');
  if Open_next_file(file_name) then
    begin
      Assemble_debug;
      Close_current_file;
    end;

  {*****************}
  { interpret files }
  {*****************}
  writeln('Running...');
  Interpret(syntax_tree_ptr, argument_list_ptr, 8192);
end; {procedure Run}


begin {main}
  program_name := ParamStr(0);
  Add_path_to_search_path(Get_path_of_file(program_name), search_path_ptr);

  if ParamCount <> 0 then
    begin
      file_name := ParamStr(1);
      Open_next_file(file_name);
      Run;
      Close_all_files;
    end
  else
    begin
      writeln('The interpreter requires a file to operate on.');
      writeln('To run, drag and drop the desired file onto the interpreter application.');
      readln;
    end;

  while not finished do
    Check_system_events;
end.

 