unit coords;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               coords                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The coords module is used to keep track of the          }
{       coordinates used by the shading language.               }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, trans, coord_axes, coord_stack, raytrace;


type
  {*************************}
  { coordinate mapping info }
  {*************************}
  coord_kind_type = (display_coords, screen_coords, camera_coords, world_coords,
    object_coords, shader_coords, surface_coords, primitive_coords,
    parametric_coords);


  {*************************************************************************************}
  {                description of coordinate transformation relationships               }
  {*************************************************************************************}
  {                                                                                     }
  {                                              /-------\        linear                }
  {                                              |surface|    transformation            }
  {                                              \-------/         (3D)                 }
  {                                                  ^              |                   }
  {                                                  | <------------/                   }
  {                                                  v                                  }
  {                    perspective       shader   /------\   /----------\   parametric  }
  {                    projection        trans    |shader|   |parametric|   projection  }
  {                    (non-linear)       (3D)    \------/   \----------/  (non-linear) }
  {                        |               |         ^            ^             |       }
  {                        |               \------>  |            =  <----------/       }
  {                        v                         v            v                     }
  {   /-------\   /------\   /------\   /-----\   /------\   /---------\                }
  {   |display|<->|screen|<=>|camera|<->|world|<->|object|<->|primitive|                }
  {   \-------/   \------/   \------/   \-----/   \------/   \---------/                }
  {             ^                     ^         ^          ^                            }
  {             |                     |         |          |                            }
  {             |                     |         \----------/                            }
  {           linear               linear            |                                  }
  {       transformation       transformation    transform                              }
  {            (2D)                 (3D)           stacks                               }
  {                                                                                     }
  {*************************************************************************************}


  {*************************************************************************************}
  {                                                                                     }
  {       display coords:                                                               }
  {       this is the coordinate system of the raster grid with the origin at the       }
  {       upper left usually ranging to some integer number of pixels in each           }
  {       direction.                                                                    }
  {                                                                                     }
  {       screen coords:                                                                }
  {       this is like the display coords in having its axes parallel to the sides      }
  {       of the screen but ranging from -1 to 1 in each direction.                     }
  {                                                                                     }
  {       camera coords:                                                                }
  {       this is the coordinate system in the scene which is oriented such that        }
  {       the x axis points to the viewer's right, the y axis points along the          }
  {       line of sight, and the z axis points up.                                      }
  {                                                                                     }
  {       world coords:                                                                 }
  {       this is the root coordinate frame of the scene. All of the lighting and       }
  {       reflection / refraction effects are computed with respect to this frame.      }
  {                                                                                     }
  {       object coords:                                                                }
  {       this is the coordinate system of the object to which the shader is            }
  {       attached.                                                                     }
  {                                                                                     }
  {       shader coords:                                                                }
  {       this is the coordinate system of the shader which is attached to the          }
  {       object.                                                                       }
  {                                                                                     }
  {       primitive coords:                                                             }
  {       this is the coordinate system of the primitive object.                        }
  {                                                                                     }
  {       surface coords:                                                               }
  {       this is the frame of reference at the surface of the object with its          }
  {       x and y axes lined up with the u and v directions of the parameter space      }
  {       and its z axis lined up with the normal direction.                            }
  {                                                                                     }
  {       parametric coords:                                                            }
  {       this is the space defined by the surface of the object. Each differently      }
  {       shaped primitive has its own kind of mapping distortion.                      }
  {                                                                                     }
  {*************************************************************************************}


  {*************************************************************************************}
  {                            how coordinates are computed                             }
  {*************************************************************************************}
  {       1) Try to find a 'higher' coordinate frame to compute coords from.            }
  {       2) If none can be found, then compute coords from a lower frame.              }
  {                                                                                     }
  {       Reasons for this approach:                                                    }
  {       1) In image space algorithms (z buffer), the reverse transformations          }
  {          (object space to global space to image space) are available but the        }
  {          opposite transformations may not be.                                       }
  {       2) In object space algorithms (ray tracing), although we have the image       }
  {          space information about the location of the shading point, the other       }
  {          data, such as the normal are usually known in the local object's space     }
  {          and must be transformed back to global coordinates for shading.            }
  {       3) Only for primary rays are we going to know the image space information     }
  {          and global coords more easily than computing the local object space.       }
  {          information. For shadow rays, reflection rays, and refraction rays,        }
  {          the image space information will not be known directly.                    }
  {*************************************************************************************}


  {*****************************************************}
  {                       lighting                      }
  {*****************************************************}
  {       Two modes of lighting calculation are         }
  {       supported (like in Silicon Graphics GL).      }
  {                                                     }
  {       'one-sided lighting'                          }
  {       means the normal must point outwards from     }
  {       the surface for correct shading               }
  {                                                     }
  {       'two-sided lighting'                          }
  {       means that the normal may be pointing         }
  {       inwards or outwards. The direction of         }
  {       the normal will automatically be reversed     }
  {       if it is found to be pointing inwards.        }
  {*****************************************************}
  lighting_mode_type = (one_sided, two_sided);


procedure Write_coord_kind(coord_kind: coord_kind_type);

{*************************************************}
{ these routines invalidate previously set coords }
{*************************************************}
procedure Inval_coords;
procedure Inval_location;
procedure Inval_normal;
procedure Inval_up_vector;
procedure Inval_direction;
procedure Inval_distance;

{***********************************************}
{ these routines set new values for coordinates }
{***********************************************}
procedure Set_location(location: vector_type;
  coord_kind: coord_kind_type);
procedure Set_normal(normal: vector_type;
  coord_kind: coord_kind_type);
procedure Set_direction(direction: vector_type;
  coord_kind: coord_kind_type);
procedure Set_distance(d: real);

{*************************************************************}
{ these functions are used to either lookup or compute coords }
{*************************************************************}
function Get_location(coord_kind: coord_kind_type): vector_type;
function Get_normal(coord_kind: coord_kind_type): vector_type;
function Get_direction(coord_kind: coord_kind_type): vector_type;
function Get_distance: real;

{************************************************}
{ these routines are used to set transformations }
{************************************************}
procedure Set_coord_stack_data(coords_ptr, normals_ptr: coord_stack_ptr_type;
  shader_height: integer);
procedure Set_shader_to_object(coord_axes, normal_axes: coord_axes_type);
procedure Set_surface_to_prim(u_axis, v_axis: vector_type);
procedure Set_surface_to_shader(u_axis, v_axis: vector_type);
procedure Set_ray_object(object_ptr: ray_object_inst_ptr_type);
procedure Set_camera_to_world(coord_axes: coord_axes_type);

{**************************************}
{ routines to change the lighting mode }
{**************************************}
procedure Set_lighting_mode(mode: lighting_mode_type);
function Get_lighting_mode: lighting_mode_type;


implementation
uses
  project, normals, uv_mapping;


{*************************************************************************************}
{                           data needed for transformations                           }
{*************************************************************************************}
{                                                                                     }
{       display to screen coords:                                                     }
{       We need the dimensions of the screen in pixels.                               }
{                                                                                     }
{       screen to eye coords:                                                         }
{       We need the projection information.                                           }
{                                                                                     }
{       eye to global coords:                                                         }
{       We need the transformation from the eye coords to the root frame              }
{                                                                                     }
{       global coords to local coords:                                                }
{       We need the transformation stack from global coords to the object to which    }
{       the shader is attached. Also, we need the transformation from the object      }
{       to the shader.                                                                }
{                                                                                     }
{       local coords to parametric coords:                                            }
{       We need the inverse transformation from the shader to the object to which     }
{       it is attached and also the transformation stack from the object to the       }
{       primitive and the non-linear projection from the primitive to the parameter   }
{       space.                                                                        }
{                                                                                     }
{       primitive coords to surface coords:                                           }
{       We need the transformation from the primitive to the surface and back. This   }
{       is well defined for each primitive and is computed as it is needed because    }
{       it is only really useful for bump mapping.                                    }
{*************************************************************************************}


const
  debug = false;


type
  {*****************************}
  { arrays of coordinate values }
  {*****************************}
  coord_array_type = array[display_coords..parametric_coords] of vector_type;

  {********************************************************************}
  { arrays of flags telling whether coords are available for each mode }
  {********************************************************************}
  coord_avail_type = array[display_coords..parametric_coords] of boolean;


var
  location_array: coord_array_type;
  normal_array: coord_array_type;
  up_vector_array: coord_array_type;
  direction_array: coord_array_type;
  distance: real;

  location_avail: coord_avail_type;
  normal_avail: coord_avail_type;
  up_vector_avail: coord_avail_type;
  direction_avail: coord_avail_type;
  distance_avail: boolean;

  coord_stack_ptr: coord_stack_ptr_type;
  normal_stack_ptr: coord_stack_ptr_type;

  object_height: integer;
  world_height: integer;
  prim_height: integer;

  {*****************************************************}
  { transformations for going to and from surface space }
  { (from world space)                                  }
  {*****************************************************}
  camera_axes: coord_axes_type;

  {*****************************************************}
  { transformations for going to and from surface space }
  { (from object space)                                 }
  {*****************************************************}
  shader_axes: coord_axes_type;
  shader_normal_axes: coord_axes_type;

  {*****************************************************}
  { transformations for going to and from surface space }
  { (from primitive space or from shader space)         }
  {*****************************************************}
  prim_u_axis, prim_v_axis: vector_type;
  shader_u_axis, shader_v_axis: vector_type;
  prim_uv_axes_avail: boolean;
  shader_uv_axes_avail: boolean;

  shader_to_surface: trans_type;
  surface_to_shader: trans_type;
  shader_to_surface_avail: boolean;
  surface_to_shader_avail: boolean;
  surface_disabled: boolean;

  {*****************************************}
  { this is used to compute the parametric  }
  { coords for ray traced objects on demand }
  {*****************************************}
  primitive_ptr: ray_object_inst_ptr_type;

  {******************************************************}
  { the current lighting mode affects normal orientation }
  {******************************************************}
  lighting_mode: lighting_mode_type;

  normal_changed: boolean;
  normal_oriented: boolean;
  normal_set: boolean;


procedure Set_lighting_mode(mode: lighting_mode_type);
begin
  lighting_mode := mode;
end; {procedure Set_lighting_mode}


function Get_lighting_mode: lighting_mode_type;
begin
  Get_lighting_mode := lighting_mode;
end; {function Get_lighting_mode}


{************************************************}
{ these routines are used to set transformations }
{************************************************}


procedure Set_coord_stack_data(coords_ptr, normals_ptr: coord_stack_ptr_type;
  shader_height: integer);
begin
  coord_stack_ptr := coords_ptr;
  normal_stack_ptr := normals_ptr;

  object_height := shader_height;
  world_height := 1;
  prim_height := Coord_stack_height(coords_ptr);

  if debug then
    begin
      Write_coord_stack(coords_ptr);
      writeln('object height = ', object_height);
      writeln('world height = ', world_height);
      writeln('prim height = ', prim_height);
    end;
end; {procedure Set_coord_stack_data}


procedure Set_shader_to_object(coord_axes, normal_axes: coord_axes_type);
begin
  shader_axes := coord_axes;
  shader_normal_axes := normal_axes;
end; {procedure Set_shader_to_object}


procedure Set_surface_to_prim(u_axis, v_axis: vector_type);
begin
  prim_u_axis := u_axis;
  prim_v_axis := v_axis;
  prim_uv_axes_avail := true;
end; {procedure Set_surface_to_prim}


procedure Set_surface_to_shader(u_axis, v_axis: vector_type);
begin
  shader_u_axis := u_axis;
  shader_v_axis := v_axis;
  shader_uv_axes_avail := true;
end; {procedure Set_surface_to_prim}


procedure Set_camera_to_world(coord_axes: coord_axes_type);
begin
  camera_axes := coord_axes;
end; {procedure Set_camera_to_world}


procedure Set_ray_object(object_ptr: ray_object_inst_ptr_type);
begin
  primitive_ptr := object_ptr;
end; {procedure Set_ray_object}


{****************************************************}
{ these routines are used to compute transformations }
{****************************************************}


procedure Find_location_from_lower(coord_kind: coord_kind_type);
  forward;
procedure Find_normal_from_lower(coord_kind: coord_kind_type);
  forward;


procedure Find_surface_to_shader;
var
  location: vector_type;
  normal: vector_type;
  counter: integer;
begin
  if not surface_to_shader_avail and not surface_disabled then
    begin
      {***************************************}
      { compute uv axes from primitive coords }
      {***************************************}
      if not shader_uv_axes_avail then
        begin
          if not prim_uv_axes_avail then
            begin
              {*****************************************}
              { find uv vectors from ray tracing object }
              {*****************************************}
              location := location_array[primitive_coords];
              normal := normal_array[primitive_coords];
              Find_surface_vectors(primitive_ptr, location, normal, prim_u_axis,
                prim_v_axis);
              prim_uv_axes_avail := true;
            end;

          {********************************************}
          { transform uv axes from primitive to shader }
          {********************************************}

          shader_u_axis := prim_u_axis;
          shader_v_axis := prim_v_axis;

          {*********************}
          { primitive to object }
          {*********************}
          for counter := prim_height downto (object_height + 1) do
            begin
              Transform_vector_from_axes(shader_u_axis,
                coord_stack_ptr^.stack[counter]);
              Transform_vector_from_axes(shader_v_axis,
                coord_stack_ptr^.stack[counter]);
            end;

          {******************}
          { object to shader }
          {******************}
          Transform_vector_to_axes(shader_u_axis, shader_axes);
          Transform_vector_to_axes(shader_v_axis, shader_axes);
          shader_uv_axes_avail := true;
        end;

      {********************************}
      { create surface to shader trans }
      {********************************}
      surface_disabled := true;
      with surface_to_shader do
        begin
          origin := Get_location(shader_coords);
          x_axis := Normalize(shader_u_axis);
          y_axis := Normalize(shader_v_axis);
          z_axis := Cross_product(x_axis, y_axis);
        end;

      surface_disabled := false;
      surface_to_shader_avail := true;
    end;
end; {procedure Find_surface_to_shader}


procedure Find_shader_to_surface;
begin
  if not shader_to_surface_avail then
    begin
      Find_surface_to_shader;
      if surface_to_shader_avail then
        begin
          shader_to_surface := Inverse_trans(surface_to_shader);
          shader_to_surface_avail := true;
        end;
    end;
end; {procedure Find_shader_to_surface}


{**************************}
{ location transformations }
{**************************}
procedure Find_location_from_higher(coord_kind: coord_kind_type);
  forward;


procedure Find_location_from_lower(coord_kind: coord_kind_type);
var
  location: vector_type;
  counter: integer;
begin
  if not location_avail[coord_kind] then
    case coord_kind of

      display_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

      screen_coords:
        begin
          if location_avail[display_coords] then
            begin
              {*******************}
              { display to screen }
              {*******************}
              location := location_array[display_coords];
              location := Display_to_screen(location);
              location_array[screen_coords] := location;
              location_avail[screen_coords] := true;
            end;
        end;

      camera_coords:
        begin
          Find_location_from_lower(screen_coords);
          if location_avail[screen_coords] then
            begin
              {******************}
              { screen to camera }
              {******************}
              location := location_array[screen_coords];
              location := Screen_to_display(location);
              location := Project_point_to_point(location);
              location_array[camera_coords] := location;
              location_avail[camera_coords] := true;
            end;
        end;

      world_coords:
        begin
          Find_location_from_lower(camera_coords);
          if location_avail[camera_coords] then
            begin
              {*****************}
              { camera to world }
              {*****************}
              location := location_array[camera_coords];
              Transform_point_to_axes(location, camera_axes);
              location_array[world_coords] := location;
              location_avail[world_coords] := true;
            end;
        end;

      object_coords:
        begin
          Find_location_from_lower(world_coords);
          if location_avail[world_coords] then
            begin
              {*****************}
              { world to object }
              {*****************}
              location := location_array[world_coords];
              for counter := world_height to object_height do
                Transform_point_to_axes(location,
                  coord_stack_ptr^.stack[counter]);
              location_array[object_coords] := location;
              location_avail[object_coords] := true;
            end;
        end;

      shader_coords:
        begin
          Find_location_from_lower(object_coords);
          Find_location_from_higher(object_coords);
          if location_avail[object_coords] then
            begin
              {******************}
              { object to shader }
              {******************}
              location := location_array[object_coords];
              Transform_point_to_axes(location, shader_axes);
              location_array[shader_coords] := location;
              location_avail[shader_coords] := true;
            end;
        end;

      surface_coords:
        begin
          Find_location_from_lower(shader_coords);
          if location_avail[shader_coords] then
            begin
              {*******************}
              { shader to surface }
              {*******************}
              Find_shader_to_surface;
              if shader_to_surface_avail then
                begin
                  location := location_array[shader_coords];
                  Transform_point(location, shader_to_surface);
                  location_array[surface_coords] := location;
                  location_avail[surface_coords] := true;
                end;
            end;
        end;

      primitive_coords:
        begin
          Find_location_from_lower(object_coords);
          if location_avail[object_coords] then
            begin
              {*********************}
              { object to primitive }
              {*********************}
              location := location_array[object_coords];
              for counter := (object_height + 1) to prim_height do
                Transform_point_to_axes(location,
                  coord_stack_ptr^.stack[counter]);
              location_array[primitive_coords] := location;
              location_avail[primitive_coords] := true;
            end;
        end;

      parametric_coords:
        begin
          Find_location_from_lower(primitive_coords);
          if location_avail[primitive_coords] then
            begin
              {*************************}
              { primitive to parametric }
              {*************************}
              if (primitive_ptr <> nil) then
                begin
                  location := location_array[primitive_coords];
                  location := Find_uv_mapping(primitive_ptr, location);
                  location_array[parametric_coords] := location;
                  location_avail[parametric_coords] := true;
                end;
            end;
        end;

    end; {case}
end; {procedure Find_location_from_lower}


procedure Find_location_from_higher(coord_kind: coord_kind_type);
var
  location: vector_type;
  counter: integer;
begin
  if not location_avail[coord_kind] then
    case coord_kind of

      display_coords:
        begin
          Find_location_from_higher(screen_coords);
          if location_avail[screen_coords] then
            begin
              {*******************}
              { screen to display }
              {*******************}
              location := location_array[screen_coords];
              location := Screen_to_display(location);
              location_array[display_coords] := location;
              location_avail[display_coords] := true;
            end;
        end;

      screen_coords:
        begin
          Find_location_from_higher(camera_coords);
          if location_avail[camera_coords] then
            begin
              {******************}
              { camera to screen }
              {******************}
              location := location_array[camera_coords];
              location := Project_point_to_point(location);
              location := Display_to_screen(location);
              location_array[screen_coords] := location;
              location_avail[screen_coords] := true;
            end;
        end;

      camera_coords:
        begin
          Find_location_from_higher(world_coords);
          if location_avail[world_coords] then
            begin
              {*****************}
              { world to camera }
              {*****************}
              location := location_array[world_coords];
              Transform_point_from_axes(location, camera_axes);
              location_array[camera_coords] := location;
              location_avail[camera_coords] := true;
            end;
        end;

      world_coords:
        begin
          Find_location_from_higher(object_coords);
          if location_avail[object_coords] then
            begin
              {*****************}
              { object to world }
              {*****************}
              location := location_array[object_coords];
              for counter := object_height downto world_height do
                Transform_point_from_axes(location,
                  coord_stack_ptr^.stack[counter]);
              location_array[world_coords] := location;
              location_avail[world_coords] := true;
            end;
        end;

      object_coords:
        begin
          Find_location_from_higher(primitive_coords);
          if location_avail[primitive_coords] then
            begin
              {*********************}
              { primitive to object }
              {*********************}
              location := location_array[primitive_coords];
              for counter := prim_height downto (object_height + 1) do
                Transform_point_from_axes(location,
                  coord_stack_ptr^.stack[counter]);
              location_array[object_coords] := location;
              location_avail[object_coords] := true;
            end
          else
            begin
              Find_location_from_higher(shader_coords);
              if location_avail[shader_coords] then
                begin
                  {******************}
                  { shader to object }
                  {******************}
                  location := location_array[shader_coords];
                  Transform_point_from_axes(location, shader_axes);
                  location_array[object_coords] := location;
                  location_avail[object_coords] := true;
                end;
            end;
        end;

      shader_coords:
        if location_avail[surface_coords] then
          begin
            {*******************}
            { surface to shader }
            {*******************}
            Find_surface_to_shader;
            if surface_to_shader_avail then
              begin
                location := location_array[surface_coords];
                Transform_point(location, surface_to_shader);
                location_array[primitive_coords] := location;
                location_avail[primitive_coords] := true;
              end;
          end;

      surface_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

      primitive_coords:
        begin
          if location_avail[parametric_coords] then
            begin
              {*************************}
              { parametric to primitive }
              {*************************}
            end
        end;

      parametric_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

    end; {case}
end; {procedure Find_location_from_higher}


{************************}
{ normal transformations }
{************************}
procedure Find_normal_from_higher(coord_kind: coord_kind_type);
  forward;


procedure Find_normal_from_lower(coord_kind: coord_kind_type);
var
  normal: vector_type;
  counter: integer;
begin
  if not normal_avail[coord_kind] then
    case coord_kind of

      display_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

      screen_coords:
        begin
          if normal_avail[display_coords] then
            begin
              {*******************}
              { display to screen }
              {*******************}
            end;
        end;

      camera_coords:
        begin
          Find_normal_from_lower(screen_coords);
          if normal_avail[screen_coords] then
            begin
              {******************}
              { screen to camera }
              {******************}
            end;
        end;

      world_coords:
        begin
          Find_normal_from_lower(camera_coords);
          if normal_avail[camera_coords] then
            begin
              {*****************}
              { camera to world }
              {*****************}
              normal := normal_array[camera_coords];
              Transform_vector_to_axes(normal, camera_axes);
              normal_array[world_coords] := normal;
              normal_avail[world_coords] := true;
            end;
        end;

      object_coords:
        begin
          Find_normal_from_lower(world_coords);
          if normal_avail[world_coords] then
            begin
              {*****************}
              { world to object }
              {*****************}
              normal := normal_array[world_coords];
              for counter := world_height to object_height do
                Transform_vector_to_axes(normal,
                  normal_stack_ptr^.stack[counter]);
              normal := Normalize(normal);
              normal_array[object_coords] := normal;
              normal_avail[object_coords] := true;
            end;
        end;

      shader_coords:
        begin
          Find_normal_from_lower(object_coords);
          Find_normal_from_higher(object_coords);
          if normal_avail[object_coords] then
            begin
              {******************}
              { object to shader }
              {******************}
              normal := normal_array[object_coords];
              Transform_vector_to_axes(normal, shader_normal_axes);
              normal := Normalize(normal);
              normal_array[shader_coords] := normal;
              normal_avail[shader_coords] := true;
            end;
        end;

      surface_coords:
        begin
          Find_normal_from_lower(shader_coords);
          if normal_avail[shader_coords] then
            begin
              {*******************}
              { shader to surface }
              {*******************}
              Find_shader_to_surface;
              if shader_to_surface_avail then
                begin
                  normal := normal_array[shader_coords];
                  Transform_vector(normal, shader_to_surface);
                  normal_array[surface_coords] := normal;
                  normal_avail[surface_coords] := true;
                end;
            end;
        end;

      primitive_coords:
        begin
          Find_normal_from_lower(object_coords);
          if normal_avail[object_coords] then
            begin
              {*********************}
              { object to primitive }
              {*********************}
              normal := normal_array[object_coords];
              for counter := (object_height + 1) to prim_height do
                Transform_vector_to_axes(normal,
                  normal_stack_ptr^.stack[counter]);
              normal_array[primitive_coords] := normal;
              normal_avail[primitive_coords] := true;
            end;
        end;

      parametric_coords:
        begin
          Find_normal_from_lower(primitive_coords);
          if normal_avail[primitive_coords] then
            begin
              {*************************}
              { primitive to parametric }
              {*************************}
            end;
        end;

    end; {case}

  {**************************}
  { echo normal to up vector }
  {**************************}
  if normal_avail[coord_kind] and not normal_changed then
    begin
      up_vector_array[coord_kind] := normal_array[coord_kind];
      up_vector_avail[coord_kind] := true;
    end;
end; {procedure Find_normal_from_lower}


procedure Find_normal_from_higher(coord_kind: coord_kind_type);
var
  normal: vector_type;
  counter: integer;
begin
  if not normal_avail[coord_kind] then
    case coord_kind of

      display_coords:
        begin
          Find_normal_from_higher(screen_coords);
          if normal_avail[screen_coords] then
            begin
              {*******************}
              { screen to display }
              {*******************}
            end;
        end;

      screen_coords:
        begin
          Find_normal_from_higher(camera_coords);
          if normal_avail[camera_coords] then
            begin
              {******************}
              { camera to screen }
              {******************}
            end;
        end;

      camera_coords:
        begin
          Find_normal_from_higher(world_coords);
          if normal_avail[world_coords] then
            begin
              {*****************}
              { world to camera }
              {*****************}
              normal := normal_array[world_coords];
              Transform_vector_from_axes(normal, camera_axes);
              normal_array[camera_coords] := normal;
              normal_avail[camera_coords] := true;
            end;
        end;

      world_coords:
        begin
          Find_normal_from_higher(object_coords);
          if normal_avail[object_coords] then
            begin
              {*****************}
              { object to world }
              {*****************}
              normal := normal_array[object_coords];
              for counter := object_height downto world_height do
                Transform_vector_from_axes(normal,
                  normal_stack_ptr^.stack[counter]);
              normal := Normalize(normal);
              normal_array[world_coords] := normal;
              normal_avail[world_coords] := true;
            end;
        end;

      object_coords:
        begin
          Find_normal_from_higher(primitive_coords);
          if normal_avail[primitive_coords] then
            begin
              {*********************}
              { primitive to object }
              {*********************}
              normal := normal_array[primitive_coords];
              for counter := prim_height downto (object_height + 1) do
                Transform_vector_from_axes(normal,
                  normal_stack_ptr^.stack[counter]);
              normal := Normalize(normal);
              normal_array[object_coords] := normal;
              normal_avail[object_coords] := true;
            end
          else
            begin
              Find_normal_from_higher(shader_coords);
              if normal_avail[shader_coords] then
                begin
                  {******************}
                  { shader to object }
                  {******************}
                  normal := normal_array[shader_coords];
                  Transform_vector_from_axes(normal, shader_normal_axes);
                  normal := Normalize(normal);
                  normal_array[object_coords] := normal;
                  normal_avail[object_coords] := true;
                end;
            end;
        end;

      shader_coords:
        begin
          Find_normal_from_higher(surface_coords);
          if normal_avail[surface_coords] then
            begin
              {*******************}
              { surface to shader }
              {*******************}
              Find_surface_to_shader;
              if surface_to_shader_avail then
                begin
                  normal := normal_array[surface_coords];
                  Transform_vector(normal, surface_to_shader);
                  normal := Normalize(normal);
                  normal_array[shader_coords] := normal;
                  normal_avail[shader_coords] := true;
                end;
            end;
        end;

      surface_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

      primitive_coords:
        begin
          if normal_avail[parametric_coords] then
            begin
              {*************************}
              { parametric to primitive }
              {*************************}
            end;
        end;

      parametric_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

    end; {case}

  {**************************}
  { echo normal to up vector }
  {**************************}
  if normal_avail[coord_kind] and not normal_changed then
    begin
      up_vector_array[coord_kind] := normal_array[coord_kind];
      up_vector_avail[coord_kind] := true;
    end;
end; {procedure Find_normal_from_higher}


{***************************}
{ up_vector transformations }
{***************************}
procedure Find_up_vector_from_higher(coord_kind: coord_kind_type);
  forward;


procedure Find_up_vector_from_lower(coord_kind: coord_kind_type);
var
  up_vector: vector_type;
  counter: integer;
begin
  if not up_vector_avail[coord_kind] then
    case coord_kind of

      display_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

      screen_coords:
        begin
          if up_vector_avail[display_coords] then
            begin
              {*******************}
              { display to screen }
              {*******************}
            end;
        end;

      camera_coords:
        begin
          Find_up_vector_from_lower(screen_coords);
          if up_vector_avail[screen_coords] then
            begin
              {******************}
              { screen to camera }
              {******************}
            end;
        end;

      world_coords:
        begin
          Find_up_vector_from_lower(camera_coords);
          if up_vector_avail[camera_coords] then
            begin
              {*****************}
              { camera to world }
              {*****************}
              up_vector := up_vector_array[camera_coords];
              Transform_vector_to_axes(up_vector, camera_axes);
              up_vector_array[world_coords] := up_vector;
              up_vector_avail[world_coords] := true;
            end;
        end;

      object_coords:
        begin
          Find_up_vector_from_lower(world_coords);
          if up_vector_avail[world_coords] then
            begin
              {*****************}
              { world to object }
              {*****************}
              up_vector := up_vector_array[world_coords];
              for counter := world_height to object_height do
                Transform_vector_to_axes(up_vector,
                  normal_stack_ptr^.stack[counter]);
              up_vector_array[object_coords] := up_vector;
              up_vector_avail[object_coords] := true;
            end;
        end;

      shader_coords:
        begin
          Find_up_vector_from_lower(object_coords);
          Find_up_vector_from_higher(object_coords);
          if up_vector_avail[object_coords] then
            begin
              {******************}
              { object to shader }
              {******************}
              up_vector := up_vector_array[object_coords];
              Transform_vector_to_axes(up_vector, shader_normal_axes);
              up_vector_array[shader_coords] := up_vector;
              up_vector_avail[shader_coords] := true;
            end;
        end;

      surface_coords:
        begin
          Find_up_vector_from_lower(shader_coords);
          if up_vector_avail[shader_coords] then
            begin
              {*******************}
              { shader to surface }
              {*******************}
              Find_shader_to_surface;
              if shader_to_surface_avail then
                begin
                  up_vector := up_vector_array[shader_coords];
                  Transform_vector(up_vector, shader_to_surface);
                  up_vector_array[surface_coords] := up_vector;
                  up_vector_avail[surface_coords] := true;
                end;
            end;
        end;

      primitive_coords:
        begin
          Find_up_vector_from_lower(object_coords);
          if up_vector_avail[object_coords] then
            begin
              {*********************}
              { object to primitive }
              {*********************}
              up_vector := up_vector_array[object_coords];
              for counter := (object_height + 1) to prim_height do
                Transform_vector_to_axes(up_vector,
                  normal_stack_ptr^.stack[counter]);
              up_vector_array[primitive_coords] := up_vector;
              up_vector_avail[primitive_coords] := true;
            end;
        end;

      parametric_coords:
        begin
          Find_up_vector_from_lower(primitive_coords);
          if up_vector_avail[primitive_coords] then
            begin
              {*************************}
              { primitive to parametric }
              {*************************}
            end;
        end;

    end; {case}

  {**************************}
  { echo up vector to normal }
  {**************************}
  if up_vector_avail[coord_kind] and not normal_changed then
    begin
      normal_array[coord_kind] := up_vector_array[coord_kind];
      normal_avail[coord_kind] := true;
    end;
end; {procedure Find_up_vector_from_lower}


procedure Find_up_vector_from_higher(coord_kind: coord_kind_type);
var
  up_vector: vector_type;
  counter: integer;
begin
  if not up_vector_avail[coord_kind] then
    case coord_kind of

      display_coords:
        begin
          Find_up_vector_from_higher(screen_coords);
          if up_vector_avail[screen_coords] then
            begin
              {*******************}
              { screen to display }
              {*******************}
            end;
        end;

      screen_coords:
        begin
          Find_up_vector_from_higher(camera_coords);
          if up_vector_avail[camera_coords] then
            begin
              {******************}
              { camera to screen }
              {******************}
            end;
        end;

      camera_coords:
        begin
          Find_up_vector_from_higher(world_coords);
          if up_vector_avail[world_coords] then
            begin
              {*****************}
              { world to camera }
              {*****************}
              up_vector := up_vector_array[world_coords];
              Transform_vector_from_axes(up_vector, camera_axes);
              up_vector_array[camera_coords] := up_vector;
              up_vector_avail[camera_coords] := true;
            end;
        end;

      world_coords:
        begin
          Find_up_vector_from_higher(object_coords);
          if up_vector_avail[object_coords] then
            begin
              {*****************}
              { object to world }
              {*****************}
              up_vector := up_vector_array[object_coords];
              for counter := object_height downto world_height do
                Transform_vector_from_axes(up_vector,
                  normal_stack_ptr^.stack[counter]);
              up_vector_array[world_coords] := up_vector;
              up_vector_avail[world_coords] := true;
            end;
        end;

      object_coords:
        begin
          Find_up_vector_from_higher(primitive_coords);
          if up_vector_avail[primitive_coords] then
            begin
              {*********************}
              { primitive to object }
              {*********************}
              up_vector := up_vector_array[primitive_coords];
              for counter := prim_height downto (object_height + 1) do
                Transform_vector_from_axes(up_vector,
                  normal_stack_ptr^.stack[counter]);
              up_vector_array[object_coords] := up_vector;
              up_vector_avail[object_coords] := true;
            end
          else
            begin
              Find_up_vector_from_higher(shader_coords);
              if up_vector_avail[shader_coords] then
                begin
                  {******************}
                  { shader to object }
                  {******************}
                  up_vector := up_vector_array[shader_coords];
                  Transform_vector_from_axes(up_vector, shader_normal_axes);
                  up_vector_array[object_coords] := up_vector;
                  up_vector_avail[object_coords] := true;
                end;
            end;
        end;

      shader_coords:
        begin
          Find_up_vector_from_higher(surface_coords);
          if up_vector_avail[surface_coords] then
            begin
              {*******************}
              { surface to shader }
              {*******************}
              Find_surface_to_shader;
              if surface_to_shader_avail then
                begin
                  up_vector := up_vector_array[surface_coords];
                  Transform_vector(up_vector, surface_to_shader);
                  up_vector_array[shader_coords] := up_vector;
                  up_vector_avail[shader_coords] := true;
                end;
            end;
        end;

      surface_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

      primitive_coords:
        begin
          if up_vector_avail[parametric_coords] then
            begin
              {*************************}
              { parametric to primitive }
              {*************************}
            end;
        end;

      parametric_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

    end; {case}

  {**************************}
  { echo up vector to normal }
  {**************************}
  if up_vector_avail[coord_kind] and not normal_changed then
    begin
      normal_array[coord_kind] := up_vector_array[coord_kind];
      normal_avail[coord_kind] := true;
    end;
end; {procedure Find_up_vector_from_higher}


{***************************}
{ direction transformations }
{***************************}
procedure Find_direction_from_higher(coord_kind: coord_kind_type);
  forward;


procedure Find_direction_from_lower(coord_kind: coord_kind_type);
var
  direction: vector_type;
  counter: integer;
begin
  if not direction_avail[coord_kind] then
    case coord_kind of

      display_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

      screen_coords:
        begin
          if direction_avail[display_coords] then
            begin
              {*******************}
              { display to screen }
              {*******************}
            end;
        end;

      camera_coords:
        begin
          Find_direction_from_lower(screen_coords);
          if direction_avail[screen_coords] then
            begin
              {******************}
              { screen to camera }
              {******************}
            end;
        end;

      world_coords:
        begin
          Find_direction_from_lower(camera_coords);
          if direction_avail[camera_coords] then
            begin
              {*****************}
              { camera to world }
              {*****************}
              direction := direction_array[camera_coords];
              Transform_vector_to_axes(direction, camera_axes);
              direction_array[world_coords] := direction;
              direction_avail[world_coords] := true;
            end;
        end;

      object_coords:
        begin
          Find_direction_from_lower(world_coords);
          if direction_avail[world_coords] then
            begin
              {*****************}
              { world to object }
              {*****************}
              direction := direction_array[world_coords];
              for counter := world_height to object_height do
                Transform_vector_to_axes(direction,
                  coord_stack_ptr^.stack[counter]);
              direction_array[object_coords] := direction;
              direction_avail[object_coords] := true;
            end;
        end;

      shader_coords:
        begin
          Find_direction_from_lower(object_coords);
          Find_direction_from_higher(object_coords);
          if direction_avail[object_coords] then
            begin
              {******************}
              { object to shader }
              {******************}
              direction := direction_array[object_coords];
              Transform_vector_to_axes(direction, shader_axes);
              direction_array[shader_coords] := direction;
              direction_avail[shader_coords] := true;
            end;
        end;

      surface_coords:
        begin
          Find_direction_from_lower(shader_coords);
          if direction_avail[shader_coords] then
            begin
              {*******************}
              { shader to surface }
              {*******************}
              Find_shader_to_surface;
              if shader_to_surface_avail then
                begin
                  direction := direction_array[shader_coords];
                  Transform_vector(direction, shader_to_surface);
                  direction_array[surface_coords] := direction;
                  direction_avail[surface_coords] := true;
                end;
            end;
        end;

      primitive_coords:
        begin
          Find_direction_from_lower(object_coords);
          if direction_avail[object_coords] then
            begin
              {*********************}
              { object to primitive }
              {*********************}
              direction := direction_array[object_coords];
              for counter := (object_height + 1) to prim_height do
                Transform_vector_to_axes(direction,
                  coord_stack_ptr^.stack[counter]);
              direction_array[primitive_coords] := direction;
              direction_avail[primitive_coords] := true;
            end;
        end;

      parametric_coords:
        begin
          Find_direction_from_lower(primitive_coords);
          if direction_avail[primitive_coords] then
            begin
              {*************************}
              { primitive to parametric }
              {*************************}
            end;
        end;

    end; {case}
end; {procedure Find_direction_from_lower}


procedure Find_direction_from_higher(coord_kind: coord_kind_type);
var
  direction: vector_type;
  counter: integer;
begin
  if not direction_avail[coord_kind] then
    case coord_kind of

      display_coords:
        begin
          Find_direction_from_higher(screen_coords);
          if direction_avail[screen_coords] then
            begin
              {*******************}
              { screen to display }
              {*******************}
            end;
        end;

      screen_coords:
        begin
          Find_direction_from_higher(camera_coords);
          if direction_avail[camera_coords] then
            begin
              {******************}
              { camera to screen }
              {******************}
            end;
        end;

      camera_coords:
        begin
          Find_direction_from_higher(world_coords);
          if direction_avail[world_coords] then
            begin
              {*****************}
              { world to camera }
              {*****************}
              direction := direction_array[world_coords];
              Transform_vector_from_axes(direction, camera_axes);
              direction_array[camera_coords] := direction;
              direction_avail[camera_coords] := true;
            end;
        end;

      world_coords:
        begin
          Find_direction_from_higher(object_coords);
          if direction_avail[object_coords] then
            begin
              {*****************}
              { object to world }
              {*****************}
              direction := direction_array[object_coords];
              for counter := object_height downto world_height do
                Transform_vector_from_axes(direction,
                  coord_stack_ptr^.stack[counter]);
              direction_array[world_coords] := direction;
              direction_avail[world_coords] := true;
            end;
        end;

      object_coords:
        begin
          Find_direction_from_higher(primitive_coords);
          if direction_avail[primitive_coords] then
            begin
              {*********************}
              { primitive to object }
              {*********************}
              direction := direction_array[primitive_coords];
              for counter := prim_height downto (object_height + 1) do
                Transform_vector_from_axes(direction,
                  coord_stack_ptr^.stack[counter]);
              direction_array[object_coords] := direction;
              direction_avail[object_coords] := true;
            end
          else
            begin
              Find_direction_from_higher(shader_coords);
              if direction_avail[shader_coords] then
                begin
                  {******************}
                  { shader to object }
                  {******************}
                  direction := direction_array[shader_coords];
                  Transform_vector_from_axes(direction, shader_axes);
                  direction_array[object_coords] := direction;
                  direction_avail[object_coords] := true;
                end;
            end;
        end;

      shader_coords:
        begin
          Find_direction_from_higher(surface_coords);
          if direction_avail[surface_coords] then
            begin
              {*******************}
              { surface to shader }
              {*******************}
              Find_surface_to_shader;
              if surface_to_shader_avail then
                begin
                  direction := direction_array[surface_coords];
                  Transform_vector(direction, surface_to_shader);
                  direction_array[shader_coords] := direction;
                  direction_avail[shader_coords] := true;
                end;
            end;
        end;

      surface_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

      primitive_coords:
        begin
          if direction_avail[parametric_coords] then
            begin
              {*************************}
              { parametric to primitive }
              {*************************}
            end;
        end;

      parametric_coords:
        begin
          {****************************}
          { do nothing - terminal case }
          {****************************}
        end;

    end; {case}
end; {procedure Find_direction_from_higher}


{*************************************************}
{ these routines invalidate previously set coords }
{*************************************************}


procedure Inval_location;
var
  counter: coord_kind_type;
begin
  for counter := display_coords to parametric_coords do
    location_avail[counter] := false;
end; {procedure Inval_location}


procedure Inval_normal;
var
  counter: coord_kind_type;
begin
  for counter := display_coords to parametric_coords do
    normal_avail[counter] := false;
end; {procedure Inval_normal}


procedure Inval_up_vector;
var
  counter: coord_kind_type;
begin
  for counter := display_coords to parametric_coords do
    up_vector_avail[counter] := false;
end; {procedure Inval_up_vector}


procedure Inval_direction;
var
  counter: coord_kind_type;
begin
  for counter := display_coords to parametric_coords do
    direction_avail[counter] := false;
end; {procedure Inval_location}


procedure Inval_distance;
begin
  distance_avail := false;
end; {procedure Inval_distance}


procedure Inval_coords;
var
  counter: coord_kind_type;
begin
  for counter := display_coords to parametric_coords do
    begin
      location_avail[counter] := false;
      normal_avail[counter] := false;
      up_vector_avail[counter] := false;
      direction_avail[counter] := false;
    end;
  distance_avail := false;

  prim_uv_axes_avail := false;
  shader_uv_axes_avail := false;
  shader_to_surface_avail := false;
  surface_to_shader_avail := false;

  normal_changed := false;
  normal_oriented := false;
  normal_set := false;
end; {procedure Inval_coords}


procedure Init_shader_coords;
var
  counter: coord_kind_type;
begin
  for counter := display_coords to parametric_coords do
    begin
      location_array[counter] := zero_vector;
      normal_array[counter] := zero_vector;
      direction_array[counter] := zero_vector;
    end;
end; {procedure Init_shader_coords}


procedure Write_coord_kind(coord_kind: coord_kind_type);
begin
  case coord_kind of
    display_coords:
      write('display_coords');
    screen_coords:
      write('screen_coords');
    camera_coords:
      write('camera_coords');
    world_coords:
      write('world_coords');
    object_coords:
      write('object_coords');
    shader_coords:
      write('shader_coords');
    primitive_coords:
      write('primitive_coords');
    parametric_coords:
      write('parametric_coords');
    surface_coords:
      write('surface_coords');
  end;
end; {procedure Write_coord_kind}


{***********************************************}
{ these routines set new values for coordinates }
{***********************************************}


procedure Set_location(location: vector_type;
  coord_kind: coord_kind_type);
begin
  location_array[coord_kind] := location;
  location_avail[coord_kind] := true;
end; {procedure Set_location}


procedure Set_up_vector(up_vector: vector_type;
  coord_kind: coord_kind_type);
begin
  up_vector_array[coord_kind] := up_vector;
  up_vector_avail[coord_kind] := true;
end; {procedure Set_up_vector}


procedure Set_normal(normal: vector_type;
  coord_kind: coord_kind_type);
begin
  normal := Normalize(normal);

  if not normal_set then
    begin
      {****************************************************}
      { first time we set the normal, we set the up vector }
      {****************************************************}
      Set_up_vector(normal, coord_kind);
    end
  else
    begin
      {************************************}
      { when normal is changed, normal and }
      { up vector are no longer identical  }
      {************************************}
      normal_changed := true;
    end;

  normal_set := true;
  normal_array[coord_kind] := normal;
  normal_avail[coord_kind] := true;
end; {procedure Set_normal}


procedure Set_direction(direction: vector_type;
  coord_kind: coord_kind_type);
begin
  direction_array[coord_kind] := direction;
  direction_avail[coord_kind] := true;
end; {procedure Set_direction}


procedure Set_distance(d: real);
begin
  distance := d;
  distance_avail := true;
end; {procedure Set_distance}


{*************************************************************}
{ these functions are used to either lookup or compute coords }
{*************************************************************}


function Get_location(coord_kind: coord_kind_type): vector_type;
begin
  Find_location_from_lower(coord_kind);
  if not location_avail[coord_kind] then
    Find_location_from_higher(coord_kind);
  Get_location := location_array[coord_kind];
end; {function Get_location}


function Get_up_vector(coord_kind: coord_kind_type): vector_type;
begin
  Find_up_vector_from_lower(coord_kind);
  if not up_vector_avail[coord_kind] then
    Find_up_vector_from_higher(coord_kind);
  Get_up_vector := up_vector_array[coord_kind];
end; {function Get_up_vector}


function Get_normal(coord_kind: coord_kind_type): vector_type;
var
  normal: vector_type;
  direction: vector_type;
  up_vector: vector_type;
begin
  Find_normal_from_lower(coord_kind);
  if not normal_avail[coord_kind] then
    Find_normal_from_higher(coord_kind);

  {*************************************************}
  { make normal front facing for two sided lighting }
  {*************************************************}
  if (coord_kind = world_coords) then
    begin
      if (lighting_mode = two_sided) or (normal_changed) then
        begin
          {*****************************}
          { make up vector front facing }
          {*****************************}
          if (not normal_oriented) then
            begin
              direction := Get_direction(world_coords);
              up_vector := Get_up_vector(world_coords);

              if Dot_product(up_vector, direction) > 0 then
                up_vector := Vector_reverse(up_vector);

              normal_oriented := true;
              up_vector_array[world_coords] := up_vector;
            end;

          {************************************}
          { make normal point toward up vector }
          {************************************}
          if normal_changed then
            begin
              normal := normal_array[world_coords];
              up_vector := up_vector_array[world_coords];
              normal_array[world_coords] := Vector_towards(normal, up_vector);
            end
          else
            begin
              normal_array[world_coords] := up_vector_array[world_coords];
            end;
        end;
    end;

  Get_normal := normal_array[coord_kind];
end; {function Get_normal}


function Get_direction(coord_kind: coord_kind_type): vector_type;
begin
  Find_direction_from_lower(coord_kind);
  if not direction_avail[coord_kind] then
    Find_direction_from_higher(coord_kind);
  Get_direction := direction_array[coord_kind];
end; {function Get_direction}


function Get_distance: real;
begin
  if distance_avail then
    begin
      {***************************}
      { distance already computed }
      {***************************}
      Get_distance := distance;
    end
  else
    begin
      {***********************}
      { must compute distance }
      {***********************}
      Get_distance := 0;
    end;
end; {function Get_distance}


initialization
  Inval_coords;
  Init_shader_coords;
  distance := 0;

  coord_stack_ptr := nil;
  normal_stack_ptr := nil;

  object_height := 0;
  world_height := 0;
  prim_height := 0;

  shader_axes := unit_axes;
  shader_normal_axes := unit_axes;

  shader_to_surface := unit_trans;
  surface_to_shader := unit_trans;
  shader_to_surface_avail := false;
  surface_to_shader_avail := false;
  surface_disabled := false;
end.
