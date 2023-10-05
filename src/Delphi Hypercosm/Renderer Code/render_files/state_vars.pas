unit state_vars;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             state_vars                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains various variables which are        }
{       shared by the various rendering modules.                }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, vectors, colors, pixels, project;


type
  render_mode_type = (pointplot_mode, wireframe_mode, hidden_line_mode,
    shaded_mode, shaded_line_mode);
  edge_mode_type = (silhouette_edges, outline_edges, all_edges);
  edge_orientation_type = (front_edges, full_edges);
  outline_kind_type = (weak_outline, bold_outline);
  shading_type = (face_shading, vertex_shading, pixel_shading);
  scanning_type = (linear_scan, ordered_scan, random_scan);
  file_format_type = (raw_format, targa_format, pict_format);


var
  {*******************}
  { window parameters }
  {*******************}
  new_window_name: string_type; {name of window to be created}
  new_window_size: pixel_type; {size of window to be created}
  new_window_placement: pixel_type; {location of center of window on screen}
  double_buffer_mode: boolean; {state of backing store}

  {*******************}
  { display paramters }
  {*******************}
  screen_physical_aspect_ratio: real; {physical aspect ratio of screen}
  screen_pixel_aspect_ratio: real; {pixel aspect ratio of screen}
  pixel_aspect_ratio: real; {physical aspect ratio of a pixel}
  logo_displayed: boolean; {switch to toggle logo}
  frame_displayed: boolean; {switch to toggle window frame}
  cursor_displayed: boolean; {switch to toggle cursor}
  show_pictures: boolean; {switch to toggle display}

  {********************}
  { viewing parameters }
  {********************}
  projection_kind: projection_kind_type;
  field_of_view: real;

  {*******************}
  { rendering options }
  {*******************}
  render_mode: render_mode_type; {rendering algorithm}
  edge_mode: edge_mode_type; {which edges to display}
  edge_orientation: edge_orientation_type; {which edges to display}
  outline_kind: outline_kind_type; {how bright pseudo edges are}
  shading: shading_type; {sampling of shading computations}
  scanning: scanning_type; {mode of raster scanning display}
  facets: integer; {number of facets used in preview}
  shadows: boolean; {switch to toggle shadows}
  reflections: boolean; {switch to toggle reflections}
  refractions: boolean; {switch to toggle refractions}
  antialiasing: boolean; {switch to toggle antialiasing}
  supersamples: integer; {number of samples per pixel}
  max_reflections: integer; {maximum number of reflections permitted}
  max_refractions: integer; {maximum number of refractions permitted}
  ambient_color: color_type; {ambient (non-directional) light}
  background_color: color_type; {background color}
  fog_factor: real; {half distance for fog}
  min_feature_size: real; {size of smallest features detailed}
  min_ray_weight: real; {feeble light rays are ignored}
  min_ray_weight_squared: real; {square of above factor}
  left_color: color_type; {stereo filter color for left eye}
  right_color: color_type; {stereo filter color for right eye}
  frame_number: integer; {number of frame of animation}
  starting_frame_number: integer; {number of first frame of animation}
  rendering, animating: boolean; {state of renderer}
  save_pictures: boolean; {switch to toggle picture saving}
  image_file_name: string_type; {name of image file to be saved}
  file_format: file_format_type; {format of file to be saved}

  {*******************}
  { colors of objects }
  {*******************}
  sphere_color, cylinder_color, cone_color: color_type;
  paraboloid_color, hyperboloid1_color, hyperboloid2_color: color_type;
  plane_color, disk_color, ring_color: color_type;
  triangle_color, parallelogram_color, polygon_color: color_type;
  torus_color, block_color, shaded_triangle_color: color_type;
  shaded_polygon_color, mesh_color, blob_color: color_type;
  point_color, line_color, volume_color: color_type;


{*************************}
{ routines to write enums }
{*************************}
procedure Write_render_mode(render_mode: render_mode_type);
procedure Write_edge_mode(edge_mode: edge_mode_type);
procedure Write_edge_orientation(edge_orientation: edge_orientation_type);
procedure Write_outline_kind(outline_kind: outline_kind_type);
procedure Write_shading(shading: shading_type);
procedure Write_scanning(scanning: scanning_type);
procedure Write_file_format(file_format: file_format_type);

{***************************}
{ routines to convert enums }
{***************************}
function Render_mode_to_str(render_mode: render_mode_type): string_type;
function Edge_mode_to_str(edge_mode: edge_mode_type): string_type;
function Edge_orientation_to_str(edge_orientation: edge_orientation_type):
  string_type;
function Outline_kind_to_str(outline_kind: outline_kind_type): string_type;
function Shading_to_str(shading: shading_type): string_type;
function Scanning_to_str(scanning: scanning_type): string_type;
function File_format_to_str(file_format: file_format_type): string_type;


implementation


{*************************}
{ routines to write enums }
{*************************}


procedure Write_render_mode(render_mode: render_mode_type);
begin
  write(Render_mode_to_str(render_mode));
end; {procedure Write_render_mode}


procedure Write_edge_mode(edge_mode: edge_mode_type);
begin
  write(Edge_mode_to_str(edge_mode));
end; {procedure Write_edge_mode}


procedure Write_edge_orientation(edge_orientation: edge_orientation_type);
begin
  write(Edge_orientation_to_str(edge_orientation));
end; {procedure Write_edge_orientation}


procedure Write_outline_kind(outline_kind: outline_kind_type);
begin
  write(Outline_kind_to_str(outline_kind));
end; {procedure Write_outline_kind}


procedure Write_shading(shading: shading_type);
begin
  write(Shading_to_str(shading));
end; {procedure Write_shading}


procedure Write_scanning(scanning: scanning_type);
begin
  write(Scanning_to_str(scanning));
end; {procedure Write_scanning}


procedure Write_file_format(file_format: file_format_type);
begin
  write(File_format_to_str(file_format));
end; {procedure Write_file_format}


{***************************}
{ routines to convert enums }
{***************************}


function Render_mode_to_str(render_mode: render_mode_type): string_type;
var
  str: string_type;
begin
  case render_mode of
    pointplot_mode:
      str := 'pointplot';
    wireframe_mode:
      str := 'wireframe';
    hidden_line_mode:
      str := 'hidden_line';
    shaded_mode:
      str := 'shaded';
    shaded_line_mode:
      str := 'shaded_line';
  end; {case}

  Render_mode_to_str := str;
end; {function Render_mode_to_str}


function Edge_mode_to_str(edge_mode: edge_mode_type): string_type;
var
  str: string_type;
begin
  case edge_mode of
    silhouette_edges:
      str := 'silhouette_edges';
    outline_edges:
      str := 'outline_edges';
    all_edges:
      str := 'all_edges';
  end; {case}

  Edge_mode_to_str := str;
end; {function Edge_mode_to_str}


function Edge_orientation_to_str(edge_orientation: edge_orientation_type):
  string_type;
var
  str: string_type;
begin
  case edge_orientation of
    front_edges:
      str := 'front_edges';
    full_edges:
      str := 'full_edges';
  end; {case}

  Edge_orientation_to_str := str;
end; {function Edge_orientation_to_str}


function Outline_kind_to_str(outline_kind: outline_kind_type): string_type;
var
  str: string_type;
begin
  case outline_kind of
    weak_outline:
      str := 'weak_outline';
    bold_outline:
      str := 'bold_outline';
  end; {case}

  Outline_kind_to_str := str;
end; {function Outline_kind_to_str}


function Shading_to_str(shading: shading_type): string_type;
var
  str: string_type;
begin
  case shading of
    face_shading:
      str := 'face_shading';
    vertex_shading:
      str := 'vertex_shading';
    pixel_shading:
      str := 'pixel_shading';
  end; {case}

  Shading_to_str := str;
end; {function Shading_to_str}


function Scanning_to_str(scanning: scanning_type): string_type;
var
  str: string_type;
begin
  case scanning of
    linear_scan:
      str := 'linear_scan';
    ordered_scan:
      str := 'ordered_scan';
    random_scan:
      str := 'random_scan';
  end; {case}

  Scanning_to_str := str;
end; {function Scanning_to_str}


function File_format_to_str(file_format: file_format_type): string_type;
var
  str: string_type;
begin
  case file_format of
    raw_format:
      str := 'raw_format';
    targa_format:
      str := 'targa_format';
    pict_format:
      str := 'pict_format';
  end;

  File_format_to_str := str;
end; {function File_format_to_str}


initialization
  {******************************}
  { initialize window parameters }
  {******************************}
  new_window_name := '';
  new_window_size := null_pixel;
  new_window_placement := null_pixel;
  double_buffer_mode := false;

  {******************************}
  { initialize display paramters }
  {******************************}
  screen_physical_aspect_ratio := 0.75;
  screen_pixel_aspect_ratio := 0.75;
  pixel_aspect_ratio := 1.0;
  logo_displayed := true;
  frame_displayed := true;
  cursor_displayed := true;
  show_pictures := true;

  {******************************}
  { initialize viewing paramters }
  {******************************}
  projection_kind := perspective;
  field_of_view := 0;

  {******************************}
  { initialize rendering options }
  {******************************}
  render_mode := wireframe_mode;
  edge_mode := outline_edges;
  edge_orientation := front_edges;
  outline_kind := bold_outline;
  shading := face_shading;
  scanning := ordered_scan;
  facets := 8;
  shadows := false;
  reflections := false;
  refractions := false;
  antialiasing := false;
  supersamples := 1;
  max_reflections := 5;
  max_refractions := 5;
  ambient_color := black_color;
  background_color := black_color;
  fog_factor := 0;
  min_feature_size := 0;
  min_ray_weight := 0;
  min_ray_weight_squared := 0;
  left_color := black_color;
  right_color := black_color;
  starting_frame_number := 1;
  frame_number := starting_frame_number;
  rendering := false;
  animating := false;
  save_pictures := false;
  image_file_name := '';

  {******************************}
  { initialize colors of objects }
  {******************************}
  sphere_color := black_color;
  cylinder_color := black_color;
  cone_color := black_color;
  paraboloid_color := black_color;
  hyperboloid1_color := black_color;
  hyperboloid2_color := black_color;
  plane_color := black_color;
  disk_color := black_color;
  ring_color := black_color;
  triangle_color := black_color;
  parallelogram_color := black_color;
  polygon_color := black_color;
  torus_color := black_color;
  block_color := black_color;
  shaded_triangle_color := black_color;
  shaded_polygon_color := black_color;
  mesh_color := black_color;
  blob_color := black_color;
  point_color := black_color;
  line_color := black_color;
  volume_color := black_color;
end.

