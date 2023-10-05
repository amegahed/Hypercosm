unit lighting;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              lighting                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The lighting module is used to query the lighting       }
{       database used for shading.                              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  colors, vectors, extents;


type
  light_kind_type = (distant_kind, point_kind, spot_kind);


  light_cache_type = record
    direction: vector_type;
    distance: real;
    intensity: color_type;
    shadow_intensity: color_type;

    direction_found: boolean;
    distance_found: boolean;
    intensity_found: boolean;
    shadow_intensity_found: boolean;
  end; {light_cache}


  light_ptr_type = ^light_type;
  light_type = record
    kind: light_kind_type;
    location: vector_type;
    direction: vector_type;
    color: color_type;
    brightness: real;
    spot_angle: real;
    intensity: color_type;
    shadows: boolean;

    max_distance: real;
    max_distance_squared: real;
    extent_box: extent_box_type;
    light_cache: light_cache_type;

    next: light_ptr_type;
  end; {light_type}


var
  light_list: light_ptr_type;

  number_of_lights: integer;
  number_of_distant_lights: integer;
  number_of_point_lights: integer;
  number_of_spot_lights: integer;


  {******************************}
  { routines for creating lights }
  {******************************}
procedure Make_distant_light(direction: vector_type;
  brightness: real;
  color: color_type;
  shadows: boolean);
procedure Make_point_light(location: vector_type;
  brightness: real;
  color: color_type;
  shadows: boolean);
procedure Make_spot_light(location: vector_type;
  direction: vector_type;
  brightness: real;
  angle: real;
  color: color_type;
  shadows: boolean);
procedure Free_lights;

{**************************}
{ routines to query lights }
{**************************}
procedure Reset_light_info(light_ptr: light_ptr_type);
function Get_light_direction(light_ptr: light_ptr_type;
  point: vector_type): vector_type;
function Get_light_distance(light_ptr: light_ptr_type;
  point: vector_type): real;
function Get_light_intensity(light_ptr: light_ptr_type;
  point: vector_type): color_type;
function Get_light_shadows(light_ptr: light_ptr_type): boolean;


implementation
uses
  new_memory, constants, trigonometry, state_vars;


const
  light_block_size = 16;
  memory_alert = false;
  verbose = false;


type
  light_block_ptr_type = ^light_block_type;
  light_block_type = record
    ptr_array: array[1..light_block_size] of light_ptr_type;
    next: light_block_ptr_type;
  end; {light_block_type}


var
  light_free_list: light_ptr_type;


{*********************************************}
{ routines for creating the lighting database }
{*********************************************}


function New_light: light_ptr_type;
var
  light_ptr: light_ptr_type;
begin
  {**************************}
  { get light from free list }
  {**************************}
  if light_free_list <> nil then
    begin
      light_ptr := light_free_list;
      light_free_list := light_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new light');
      new(light_ptr);
    end;

  {**********************}
  { initialize new light }
  {**********************}
  light_ptr^.next := nil;

  New_light := light_ptr;
end; {function New_light}


procedure Normalize_color(var color: color_type;
  var brightness: real);
var
  brightness2: real;
begin
  brightness2 := Color_brightness(color);
  color := Intensify_color(color, 1 / brightness2);
  brightness := brightness * brightness2;
end; {procedure Normalize_color}


procedure Make_distant_light(direction: vector_type;
  brightness: real;
  color: color_type;
  shadows: boolean);
var
  light_ptr: light_ptr_type;
begin
  if verbose then
    writeln('Making distant light');

  Normalize_color(color, brightness);

  light_ptr := New_light;
  light_ptr^.kind := distant_kind;
  light_ptr^.brightness := brightness;
  light_ptr^.color := color;
  light_ptr^.direction := Normalize(direction);
  light_ptr^.intensity := Intensify_color(color, brightness);
  light_ptr^.shadows := shadows;
  light_ptr^.max_distance_squared := infinity;
  light_ptr^.max_distance := infinity;

  {************************}
  { insert into light list }
  {************************}
  light_ptr^.next := light_list;
  light_list := light_ptr;
  number_of_lights := number_of_lights + 1;
  number_of_distant_lights := number_of_distant_lights + 1;
end; {procedure Make_distant_light}


procedure Find_light_bounding_sphere(light_ptr: light_ptr_type);
begin
  light_ptr^.max_distance_squared := sqrt(light_ptr^.brightness *
    light_ptr^.brightness / min_ray_weight_squared);
  light_ptr^.max_distance := sqrt(light_ptr^.max_distance_squared);
end; {procedure Find_light_bounding_sphere}


procedure Make_point_light(location: vector_type;
  brightness: real;
  color: color_type;
  shadows: boolean);
var
  light_ptr: light_ptr_type;
begin
  if verbose then
    writeln('Making point light');

  {*****************************}
  { adjust color and brightness }
  {*****************************}
  Normalize_color(color, brightness);

  {************************}
  { initialize point light }
  {************************}
  light_ptr := New_light;
  light_ptr^.kind := point_kind;
  light_ptr^.location := location;
  light_ptr^.brightness := brightness;
  light_ptr^.color := color;
  light_ptr^.intensity := Intensify_color(color, brightness * brightness);
  light_ptr^.shadows := shadows;

  {*******************************}
  { compute light bounding sphere }
  {*******************************}
  Find_light_bounding_sphere(light_ptr);

  {************************}
  { insert into light list }
  {************************}
  light_ptr^.next := light_list;
  light_list := light_ptr;
  number_of_lights := number_of_lights + 1;
  number_of_point_lights := number_of_point_lights + 1;
end; {procedure Make_point_light}


procedure Make_spot_light(location: vector_type;
  direction: vector_type;
  brightness: real;
  angle: real;
  color: color_type;
  shadows: boolean);
var
  light_ptr: light_ptr_type;
begin
  if verbose then
    writeln('Making spot light');

  {*****************************}
  { adjust color and brightness }
  {*****************************}
  Normalize_color(color, brightness);

  {***********************}
  { initialize spot light }
  {***********************}
  light_ptr := New_light;
  light_ptr^.kind := spot_kind;
  light_ptr^.location := location;
  light_ptr^.direction := Normalize(direction);
  light_ptr^.brightness := brightness;
  light_ptr^.spot_angle := cos(angle * degrees_to_radians / 2.0);
  light_ptr^.color := color;
  light_ptr^.intensity := Intensify_color(color, brightness * brightness);
  light_ptr^.shadows := shadows;

  {*******************************}
  { compute light bounding sphere }
  {*******************************}
  Find_light_bounding_sphere(light_ptr);

  {************************}
  { insert into light list }
  {************************}
  light_ptr^.next := light_list;
  light_list := light_ptr;
  number_of_lights := number_of_lights + 1;
  number_of_spot_lights := number_of_spot_lights + 1;
end; {procedure Make_spot_light}


procedure Free_lights;
var
  light_ptr: light_ptr_type;
begin
  {*************************}
  { add lights to free list }
  {*************************}
  while (light_list <> nil) do
    begin
      if verbose then
        case light_list^.kind of
          distant_kind:
            writeln('Freeing distant light');
          point_kind:
            writeln('Freeing point light');
          spot_kind:
            writeln('Freeing spot light');
        end;

      light_ptr := light_list;
      light_list := light_list^.next;
      light_ptr^.next := light_free_list;
      light_free_list := light_ptr;
    end;

  number_of_lights := 0;
  number_of_distant_lights := 0;
  number_of_point_lights := 0;
  number_of_spot_lights := 0;
end; {procedure Free_lights}


{**************************}
{ routines to query lights }
{**************************}


procedure Reset_light_info(light_ptr: light_ptr_type);
begin
  with light_ptr^.light_cache do
    begin
      direction_found := false;
      distance_found := false;
      intensity_found := false;
      shadow_intensity_found := false;
    end;
end; {procedure Reset_light_info}


function Get_light_direction(light_ptr: light_ptr_type;
  point: vector_type): vector_type;
var
  direction: vector_type;
  distance: real;
begin
  if (light_ptr <> nil) then
    begin
      if light_ptr^.light_cache.direction_found then
        begin
          {*************************}
          { lookup cached direction }
          {*************************}
          direction := light_ptr^.light_cache.direction;
        end
      else
        begin
          {****************************************}
          { compute light direction (and distance) }
          {****************************************}
          distance := 0;
          case light_ptr^.kind of

            distant_kind:
              begin
                direction := light_ptr^.direction;
                distance := infinity;
              end;

            point_kind:
              begin
                direction := Vector_difference(light_ptr^.location, point);
                distance := Vector_length(direction);
                if distance <> 0 then
                  direction := Vector_scale(direction, 1 / distance);
              end;

            spot_kind:
              begin
                direction := Vector_difference(light_ptr^.location, point);
                distance := Vector_length(direction);
                if distance <> 0 then
                  direction := Vector_scale(direction, 1 / distance);
              end;
          end; {case}

          {********************************}
          { cache direction (and distance) }
          {********************************}
          light_ptr^.light_cache.direction_found := true;
          light_ptr^.light_cache.direction := direction;

          light_ptr^.light_cache.distance_found := true;
          light_ptr^.light_cache.distance := distance;
        end;
    end
  else
    direction := zero_vector;

  Get_light_direction := direction;
end; {function Get_light_direction}


function Get_light_distance(light_ptr: light_ptr_type;
  point: vector_type): real;
var
  distance: real;
  direction: vector_type;
begin
  if (light_ptr <> nil) then
    begin
      if light_ptr^.light_cache.distance_found then
        begin
          {************************}
          { lookup cached distance }
          {************************}
          distance := light_ptr^.light_cache.distance;
        end
      else
        begin
          {**********************************}
          { compute distance (and direction) }
          {**********************************}
          distance := 0;
          case light_ptr^.kind of

            distant_kind:
              begin
                direction := light_ptr^.direction;
                distance := infinity;
              end;

            point_kind:
              begin
                direction := Vector_difference(light_ptr^.location, point);
                distance := Vector_length(direction);
                if distance <> 0 then
                  direction := Vector_scale(direction, 1 / distance);
              end;

            spot_kind:
              begin
                direction := Vector_difference(light_ptr^.location, point);
                distance := Vector_length(direction);
                if distance <> 0 then
                  direction := Vector_scale(direction, 1 / distance);
              end;
          end; {case}

          {********************************}
          { cache distance (and direction) }
          {********************************}
          light_ptr^.light_cache.direction_found := true;
          light_ptr^.light_cache.direction := direction;

          light_ptr^.light_cache.distance_found := true;
          light_ptr^.light_cache.distance := distance;
        end;
    end
  else
    begin
      direction := zero_vector;
      distance := 0;
    end;

  Get_light_distance := distance;
end; {function Get_light_distance}


function Get_light_intensity(light_ptr: light_ptr_type;
  point: vector_type): color_type;
var
  intensity: color_type;
  direction: vector_type;
  distance, spot_angle, brightness: real;
begin
  if (light_ptr <> nil) then
    begin
      if light_ptr^.light_cache.intensity_found then
        begin
          {*************************}
          { lookup cached intensity }
          {*************************}
          intensity := light_ptr^.light_cache.intensity;
        end
      else
        begin
          {*******************}
          { compute intensity }
          {*******************}
          case light_ptr^.kind of

            distant_kind:
              begin
                intensity := light_ptr^.intensity;
              end;

            point_kind:
              begin
                distance := Get_light_distance(light_ptr, point);

                if distance <> 0 then
                  begin
                    brightness := 1 / (distance * distance);
                    intensity := Intensify_color(light_ptr^.intensity,
                      brightness);
                  end
                else
                  intensity := white_color;
              end;

            spot_kind:
              begin
                direction := Get_light_direction(light_ptr, point);
                spot_angle := -Dot_product(light_ptr^.direction, direction);

                if (spot_angle > light_ptr^.spot_angle) then
                  begin
                    brightness := (spot_angle - light_ptr^.spot_angle) / (1 -
                      light_ptr^.spot_angle);
                    distance := Get_light_distance(light_ptr, point);

                    if distance <> 0 then
                      begin
                        brightness := brightness / (distance * distance);
                        intensity := Intensify_color(light_ptr^.intensity,
                          brightness);
                      end
                    else
                      intensity := white_color;
                  end
                else
                  intensity := black_color;
              end;

          end; {case}

          {*****************}
          { cache intensity }
          {*****************}
          light_ptr^.light_cache.intensity_found := true;
          light_ptr^.light_cache.intensity := intensity;
        end;
    end
  else
    intensity := black_color;

  Get_light_intensity := intensity;
end; {function Get_light_intensity}


function Get_light_shadows(light_ptr: light_ptr_type): boolean;
var
  shadows: boolean;
begin
  if (light_ptr <> nil) then
    shadows := light_ptr^.shadows
  else
    shadows := false;

  Get_light_shadows := shadows;
end; {function Get_light_shadows}


initialization
  light_list := nil;
  light_free_list := nil;

  number_of_lights := 0;
  number_of_distant_lights := 0;
  number_of_point_lights := 0;
  number_of_spot_lights := 0;
end.
