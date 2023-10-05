unit eye;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm                eye                    3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines for calculating the       }
{       coord axes of the scene relative to the eye             }
{       according to certain parameters.                        }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, vectors, trans;


type
  eye_coords_kind_type = (left_handed, right_handed);


var
  {******************}
  { viewing geometry }
  {******************}
  eye_point: vector_type;
  lookat_point: vector_type;
  delta_yaw: real;
  delta_pitch: real;
  roll: real;
  eye_coords_kind: eye_coords_kind_type;

  {*****************}
  { stereo geometry }
  {*****************}
  stereo_seperation: real;

  {*********************************}
  { these are the transformations   }
  { from world coords to eye coords }
  {*********************************}
  eye_trans: trans_type;
  left_eye_trans: trans_type;
  right_eye_trans: trans_type;


  {************************************}
  { call this routine to calculate the }
  { world to eye transformations after }
  { the viewing geometry has been set. }
  {************************************}
procedure Set_eye;

{**************************}
{ routines to manage enums }
{**************************}
procedure Write_eye_coords_kind(kind: eye_coords_kind_type);
function Eye_coords_kind_to_str(kind: eye_coords_kind_type): string_type;


{*******************************************************}
{               eye coordinate 'handedness'             }
{*******************************************************}
{       Just to prove their backwardness, and to        }
{       confuse people, computer scientists have        }
{       chosen to use a left handed coordinate          }
{       system for eye coordinates while the entire     }
{       rest of the world uses right handed coords.     }
{       Because the projection to screen coords         }
{       uses eye coords, we must take care to make      }
{       sure that the projection to eye coords and      }
{       the projection routines both use right or       }
{       left handed eye coords consistently.            }
{       To be flexible, both are supported here.        }
{                                                       }
{*******************************************************}
{         right handed             left handed          }
{*******************************************************}
{                                                       }
{     z                           y                     }
{     |                           |                     }
{     |     y (direction)         |     z (direction)   }
{     |    /  (of sight)          |    /  (of sight)    }
{     |   /                       |   /                 }
{     |  /                        |  /                  }
{     | /                         | /                   }
{     |/_____________ x           |/_____________ x     }
{   eye                          eye                    }
{                                                       }
{*******************************************************}


implementation
uses
  rotations;


const
  radians_to_degrees = 57.29577951;


type
  eye_kind_type = (normal, left_eye, right_eye);


function Right_handed_eye_trans: trans_type;
var
  yaw, pitch: real;
  direction: vector_type;
  trans: trans_type;
begin
  direction := Vector_difference(lookat_point, eye_point);
  with direction do
    begin
      if (y <> 0) then
        begin
          yaw := arctan(x / y) * radians_to_degrees;
          if (y < 0) then
            yaw := yaw + 180.0;
        end
      else
        begin
          if (x = 0) then
            yaw := 0
          else if (x > 0) then
            yaw := 90.0
          else
            yaw := -90.0;
        end;

      if (x <> 0) or (y <> 0) then
        pitch := arctan(z / sqrt(y * y + x * x)) * radians_to_degrees
      else
        begin
          if (z > 0) then
            pitch := 90.0
          else if (z < 0) then
            pitch := -90.0
          else
            pitch := 0; {pitch is undefined}
        end;
    end;

  trans := To_Trans(Vector_Reverse(eye_point), x_vector, y_vector, z_vector);
  Z_rotate_trans(trans, yaw);
  X_rotate_trans(trans, -pitch);
  Y_rotate_trans(trans, roll);

  {**************************************}
  { rotate and tilt camera in eye coords }
  {**************************************}
  if delta_yaw <> 0 then
    Z_rotate_trans(trans, delta_yaw);
  if delta_pitch <> 0 then
    X_rotate_trans(trans, -delta_pitch);

  Right_handed_eye_trans := trans;
end; {function Right_handed_eye_trans}


function Left_handed_eye_trans: trans_type;
var
  yaw, pitch: real;
  direction: vector_type;
  trans: trans_type;
begin
  direction := Vector_difference(lookat_point, eye_point);
  with direction do
    begin
      if (z <> 0) then
        begin
          yaw := arctan(x / z) * radians_to_degrees;
          if (z < 0) then
            yaw := yaw + 180.0;
        end
      else
        begin
          if (x = 0) then
            yaw := 0
          else if (x > 0) then
            yaw := 90.0
          else
            yaw := -90.0;
        end;

      if (x <> 0) or (z <> 0) then
        pitch := arctan(y / sqrt(z * z + x * x)) * radians_to_degrees
      else
        begin
          if (y > 0) then
            pitch := 90.0
          else if (y < 0) then
            pitch := -90.0
          else
            pitch := 0; {pitch is undefined}
        end;
    end;

  trans := To_trans(Vector_reverse(eye_point), x_vector, y_vector, z_vector);
  Z_rotate_trans(trans, yaw);
  X_rotate_trans(trans, -pitch);
  Y_rotate_trans(trans, roll);

  {**************************************}
  { rotate and tilt camera in eye coords }
  {**************************************}
  if delta_yaw <> 0 then
    Z_rotate_trans(trans, delta_yaw);
  if delta_pitch <> 0 then
    X_rotate_trans(trans, -delta_pitch);

  Left_handed_eye_trans := trans;
end; {function Left_handed_eye_trans}


function Find_eye_trans(eye_kind: eye_kind_type): trans_type;
var
  eye_trans: trans_type;
  eye_distance: real;
  angle: real;
begin
  case eye_coords_kind of
    right_handed:
      eye_trans := Right_handed_eye_trans;
    left_handed:
      eye_trans := Left_handed_eye_trans;
  end; {case}

  {******************************************}
  { if stereo seperation <> 0, then we must  }
  { compute the displacement of the eye from }
  { the line of sight.                       }
  {******************************************}
  if eye_kind <> normal then
    begin
      case eye_kind of
        right_eye:
          angle := (stereo_seperation / 2.0);
        left_eye:
          angle := (-stereo_seperation / 2.0);
        else
          angle := 0;
      end; {case}

      {************************************************}
      { Rotate coord axes around lookat point by angle }
      {************************************************}
      eye_distance := Vector_length(Vector_difference(eye_point, lookat_point));

      case eye_coords_kind of
        right_handed:
          begin
            {****************************}
            { line of sight:      y_axis }
            { vertical direction: z_axis }
            {****************************}
            eye_trans.origin.y := eye_trans.origin.y - eye_distance;
            Z_rotate_trans(eye_trans, angle);
            eye_trans.origin.y := eye_trans.origin.y + eye_distance;
          end;
        left_handed:
          begin
            {****************************}
            { line of sight:      z_axis }
            { vertical direction: y_axis }
            {****************************}
            eye_trans.origin.z := eye_trans.origin.z - eye_distance;
            Y_rotate_trans(eye_trans, angle);
            eye_trans.origin.z := eye_trans.origin.z + eye_distance;
          end;
      end;
    end;
  Find_eye_trans := eye_trans;
end; {function Find_eye_trans}


procedure Set_eye;
begin
  if (stereo_seperation = 0) then
    begin
      eye_trans := Find_eye_trans(normal);
      left_eye_trans := eye_trans;
      right_eye_trans := eye_trans;
    end
  else
    begin
      eye_trans := Find_eye_trans(normal);
      left_eye_trans := Find_eye_trans(left_eye);
      right_eye_trans := Find_eye_trans(right_eye);
    end;
end; {procedure Set_eye}


{**************************}
{ routines to manage enums }
{**************************}


procedure Write_eye_coords_kind(kind: eye_coords_kind_type);
begin
  write(Eye_coords_kind_to_str(kind));
end; {procedure Write_eye_coords_kind}


function Eye_coords_kind_to_str(kind: eye_coords_kind_type): string_type;
var
  str: string_type;
begin
  case kind of
    left_handed:
      str := 'left_handed';
    right_handed:
      str := 'right_handed';
  end;

  Eye_coords_kind_to_str := str;
end; {function Eye_coords_kind_to_str}


end.

