unit rotations;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              rotations                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The rotations module provides routines for rotating     }
{       3 dimensional coordinates.                              }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  vectors, trans;


{******************}
{ vector rotations }
{******************}
procedure X_rotate_vector(var vector: vector_type;
  angle: real);
procedure Y_rotate_vector(var vector: vector_type;
  angle: real);
procedure Z_rotate_vector(var vector: vector_type;
  angle: real);
procedure Rotate_vector(var vector: vector_type;
  rotation: vector_type);

{*************************}
{ tranformation rotations }
{*************************}
procedure X_rotate_trans(var trans: trans_type;
  angle: real);
procedure Y_rotate_trans(var trans: trans_type;
  angle: real);
procedure Z_rotate_trans(var trans: trans_type;
  angle: real);
procedure Rotate_trans(var trans: trans_type;
  rotation: vector_type);


implementation
const
  pi = 3.14159265358;


  {*****************************************************}
  { procedure X_rotate_vector rotates a vector by angle }
  { radians around the x_axis in the positive or        }
  { counter-clockwise direction by the right hand rule. }
  {*****************************************************}

procedure X_rotate_vector(var vector: vector_type;
  angle: real);
var
  cosine, sine: real;
  new_Y, new_Z: real;
begin
  cosine := cos(angle * pi / 180);
  sine := sin(angle * pi / 180);
  with vector do
    begin
      new_Y := (cosine * y) - (sine * z);
      new_Z := (cosine * z) + (sine * y);
      y := new_Y;
      z := new_Z;
    end;
end; {procedure X_rotate_vector}


{*****************************************************}
{ procedure Y_rotate_vector rotates a vector by angle }
{ radians around the y_axis in the positive or        }
{ counter-clockwise direction by the right hand rule. }
{*****************************************************}

procedure Y_rotate_vector(var vector: vector_type;
  angle: real);
var
  cosine, sine: real;
  new_X, new_Z: real;
begin
  cosine := cos(angle * pi / 180);
  sine := sin(angle * pi / 180);
  with vector do
    begin
      new_X := (cosine * x) + (sine * z);
      new_Z := (cosine * z) - (sine * x);
      x := new_X;
      z := new_Z;
    end;
end; {procedure Y_rotate_vector}


{*****************************************************}
{ procedure Y_rotate_vector rotates a vector by angle }
{ radians around the y_axis in the positive or        }
{ counter-clockwise direction by the right hand rule. }
{*****************************************************}

procedure Z_rotate_vector(var vector: vector_type;
  angle: real);
var
  cosine, sine: real;
  new_X, new_Y: real;
begin
  cosine := cos(angle * pi / 180);
  sine := sin(angle * pi / 180);
  with vector do
    begin
      new_X := (cosine * x) - (sine * y);
      new_Y := (cosine * y) + (sine * x);
      x := new_X;
      y := new_Y;
    end;
end; {procedure Z_rotate_vector}


{*****************************************************}
{ procedure Rotate_vector rotates a vector around the }
{ coordinate axes in the specific order, x, y, z.     }
{*****************************************************}


procedure Rotate_vector(var vector: vector_type;
  rotation: vector_type);
begin
  X_rotate_vector(vector, rotation.x);
  Y_rotate_vector(vector, rotation.y);
  Z_rotate_vector(vector, rotation.z);
end; {procedure Rotate_vector}


{*************************}
{ tranformation rotations }
{*************************}


procedure X_rotate_trans(var trans: trans_type;
  angle: real);
begin
  X_rotate_vector(trans.origin, angle);
  X_rotate_vector(trans.x_axis, angle);
  X_rotate_vector(trans.y_axis, angle);
  X_rotate_vector(trans.z_axis, angle);
end; {procedure X_rotate_trans}


procedure Y_rotate_trans(var trans: trans_type;
  angle: real);
begin
  Y_rotate_vector(trans.origin, angle);
  Y_rotate_vector(trans.x_axis, angle);
  Y_rotate_vector(trans.y_axis, angle);
  Y_rotate_vector(trans.z_axis, angle);
end; {procedure Y_rotate_trans}


procedure Z_rotate_trans(var trans: trans_type;
  angle: real);
begin
  Z_rotate_vector(trans.origin, angle);
  Z_rotate_vector(trans.x_axis, angle);
  Z_rotate_vector(trans.y_axis, angle);
  Z_rotate_vector(trans.z_axis, angle);
end; {procedure Z_rotate_trans}


procedure Rotate_trans(var trans: trans_type;
  rotation: vector_type);
begin
  X_rotate_trans(trans, rotation.x);
  Y_rotate_trans(trans, rotation.y);
  Z_rotate_trans(trans, rotation.z);
end; {procedure Rotate_trans}


end.
