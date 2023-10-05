unit coord_axes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            coord_axes                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The coord_axes module provides data structs and         }
{       routines for transforming between different 3d          }
{       coordinate frames. The coord frames may be stretched    }
{       or skewed and will allow any linear transformation.     }
{                                                               }
{       This module differs from the transform module in two    }
{       ways:                                                   }
{       1) coord_axes contain the reverse transformation        }
{       2) coord_axes recognize axis alignment                  }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  vectors, binormals, rays, trans;


type
  {*****************************}
  { alignment of an axis vector }
  {*****************************}
  axis_alignment_type = (unaligned, x_aligned, y_aligned, z_aligned);


  {********************************************}
  { alignment of all 3 axis vectors in a trans }
  {********************************************}
  trans_alignment_type = record
    x_axis_alignment: axis_alignment_type;
    y_axis_alignment: axis_alignment_type;
    z_axis_alignment: axis_alignment_type;

    { not currently used -                     }
    { this field is used as padding to appease }
    { compilers and run time checking systems  }
    xyz_axis_alignment: axis_alignment_type;
  end;


  coord_axes_type = record
    trans: trans_type;
    inverse_trans: trans_type;

    trans_alignment: trans_alignment_type;
    inverse_trans_alignment: trans_alignment_type;
  end; {coord_axes_type}


var
  unit_axes: coord_axes_type;


{*************}
{ conversions }
{*************}
function Trans_to_axes(trans: trans_type): coord_axes_type;
function Axes_to_trans(coord_axes: coord_axes_type): trans_type;
function Normal_axes(coord_axes: coord_axes_type): coord_axes_type;
function Inverse_axes(coord_axes: coord_axes_type): coord_axes_type;

{*************************}
{ forward transformations }
{*************************}
procedure Transform_vector_from_axes(var vector: vector_type;
  coord_axes: coord_axes_type);
procedure Transform_point_from_axes(var point: vector_type;
  coord_axes: coord_axes_type);
procedure Transform_binormal_from_axes(var binormal: binormal_type;
  coord_axes: coord_axes_type);
procedure Transform_ray_from_axes(var ray: ray_type;
  coord_axes: coord_axes_type);
procedure Transform_trans_from_axes(var trans: trans_type;
  coord_axes: coord_axes_type);
procedure Transform_axes_from_axes(var coord_axes: coord_axes_type;
  source_axes: coord_axes_type);

{*************************}
{ inverse transformations }
{*************************}
procedure Transform_vector_to_axes(var vector: vector_type;
  coord_axes: coord_axes_type);
procedure Transform_point_to_axes(var point: vector_type;
  coord_axes: coord_axes_type);
procedure Transform_binormal_to_axes(var binormal: binormal_type;
  coord_axes: coord_axes_type);
procedure Transform_ray_to_axes(var ray: ray_type;
  coord_axes: coord_axes_type);
procedure Transform_trans_to_axes(var trans: trans_type;
  coord_axes: coord_axes_type);
procedure Transform_axes_to_axes(var coord_axes: coord_axes_type;
  dest_axes: coord_axes_type);
procedure Write_axes(coord_axes: coord_axes_type);


implementation
const
  small = 1E-6;


function Axis_alignment(vector: vector_type): axis_alignment_type;
var
  alignment: axis_alignment_type;
begin
  {**********************}
  { aligned with x axis? }
  {**********************}
  if (vector.y = 0) and (vector.z = 0) then
    alignment := x_aligned

    {**********************}
    { aligned with y axis? }
    {**********************}
  else if (vector.x = 0) and (vector.z = 0) then
    alignment := y_aligned

    {**********************}
    { aligned with z axis? }
    {**********************}
  else if (vector.x = 0) and (vector.y = 0) then
    alignment := z_aligned

    {**********************}
    { aligned with no axes }
    {**********************}
  else
    alignment := unaligned;

  Axis_alignment := alignment;
end; {function Axis_alignment}


function Trans_alignment(trans: trans_type): trans_alignment_type;
var
  alignment: trans_alignment_type;
begin
  alignment.x_axis_alignment := Axis_alignment(trans.x_axis);
  alignment.y_axis_alignment := Axis_alignment(trans.y_axis);
  alignment.z_axis_alignment := Axis_alignment(trans.z_axis);

  { not currently used but the assignment of the extra    }
  { padding field is needed for clean run time testing    }
  alignment.xyz_axis_alignment := unaligned;

  Trans_alignment := alignment;
end; {function Trans_alignment}


function Trans_to_axes(trans: trans_type): coord_axes_type;
var
  coord_axes: coord_axes_type;
begin
  coord_axes.trans := trans;
  coord_axes.trans_alignment := Trans_alignment(coord_axes.trans);

  coord_axes.inverse_trans := Inverse_trans(trans);
  coord_axes.inverse_trans_alignment :=
    Trans_alignment(coord_axes.inverse_trans);

  Trans_to_axes := coord_axes;
end; {function Trans_to_axes}


function Axes_to_trans(coord_axes: coord_axes_type): trans_type;
begin
  Axes_to_trans := coord_axes.trans;
end; {function Axes_to_trans}


function Normal_axes(coord_axes: coord_axes_type): coord_axes_type;
var
  trans: trans_type;
begin
  trans := Normal_trans(Axes_to_trans(coord_axes));
  Normal_axes := Trans_to_axes(trans);
end; {function Normal_axes}


function Inverse_axes(coord_axes: coord_axes_type): coord_axes_type;
var
  axes: coord_axes_type;
begin
  axes.trans := coord_axes.inverse_trans;
  axes.inverse_trans := coord_axes.trans;
  axes.trans_alignment := coord_axes.inverse_trans_alignment;
  axes.inverse_trans_alignment := coord_axes.trans_alignment;
  Inverse_axes := axes;
end; {function Inverse_axes}


procedure Transform_vector_from_axes(var vector: vector_type;
  coord_axes: coord_axes_type);
var
  temp: vector_type;
begin
  {***********************************************************}
  { vector := Sum(Scale(coord_axes.trans.x_axis, vector.x),   }
  {           Sum(Scale(coord_axes.trans.y_axis, vector.y),   }
  {               Scale(coord_axes.trans.z_axis, vector.z))); }
  {***********************************************************}
  temp := zero_vector;

  with coord_axes.trans do
    begin
      {********}
      { x_axis }
      {********}
      if (vector.x <> 0) then
        case coord_axes.trans_alignment.x_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + x_axis.x * vector.x;
              temp.y := temp.y + x_axis.y * vector.x;
              temp.z := temp.z + x_axis.z * vector.x;
            end;
          x_aligned:
            temp.x := temp.x + x_axis.x * vector.x;
          y_aligned:
            temp.y := temp.y + x_axis.y * vector.x;
          z_aligned:
            temp.z := temp.z + x_axis.z * vector.x;
        end; {x_axis}

      {********}
      { y_axis }
      {********}
      if (vector.y <> 0) then
        case coord_axes.trans_alignment.y_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + y_axis.x * vector.y;
              temp.y := temp.y + y_axis.y * vector.y;
              temp.z := temp.z + y_axis.z * vector.y;
            end;
          x_aligned:
            temp.x := temp.x + y_axis.x * vector.y;
          y_aligned:
            temp.y := temp.y + y_axis.y * vector.y;
          z_aligned:
            temp.z := temp.z + y_axis.z * vector.y;
        end; {y_axis}

      {********}
      { z_axis }
      {********}
      if (vector.z <> 0) then
        case coord_axes.trans_alignment.z_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + z_axis.x * vector.z;
              temp.y := temp.y + z_axis.y * vector.z;
              temp.z := temp.z + z_axis.z * vector.z;
            end;
          x_aligned:
            temp.x := temp.x + z_axis.x * vector.z;
          y_aligned:
            temp.y := temp.y + z_axis.y * vector.z;
          z_aligned:
            temp.z := temp.z + z_axis.z * vector.z;
        end; {z_axis}
    end;

  vector := temp;
end; {procedure Transform_vector_from_axes}


procedure Transform_point_from_axes(var point: vector_type;
  coord_axes: coord_axes_type);
var
  temp: vector_type;
begin
  {**********************************************************}
  { point := Sum(coord_axes.trans.origin,                    }
  {          Sum(Scale(coord_axes.trans.x_axis, point.x),    }
  {          Sum(Scale(coord_axes.trans.y_axis, point.y),    }
  {              Scale(coord_axes.trans.z_axis, point.z)))); }
  {**********************************************************}

  with coord_axes.trans do
    begin
      temp := origin;

      {********}
      { x_axis }
      {********}
      if (point.x <> 0) then
        case coord_axes.trans_alignment.x_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + x_axis.x * point.x;
              temp.y := temp.y + x_axis.y * point.x;
              temp.z := temp.z + x_axis.z * point.x;
            end;
          x_aligned:
            temp.x := temp.x + x_axis.x * point.x;
          y_aligned:
            temp.y := temp.y + x_axis.y * point.x;
          z_aligned:
            temp.z := temp.z + x_axis.z * point.x;
        end; {x_axis}

      {********}
      { y_axis }
      {********}
      if (point.y <> 0) then
        case coord_axes.trans_alignment.y_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + y_axis.x * point.y;
              temp.y := temp.y + y_axis.y * point.y;
              temp.z := temp.z + y_axis.z * point.y;
            end;
          x_aligned:
            temp.x := temp.x + y_axis.x * point.y;
          y_aligned:
            temp.y := temp.y + y_axis.y * point.y;
          z_aligned:
            temp.z := temp.z + y_axis.z * point.y;
        end; {y_axis}

      {********}
      { z_axis }
      {********}
      if (point.z <> 0) then
        case coord_axes.trans_alignment.z_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + z_axis.x * point.z;
              temp.y := temp.y + z_axis.y * point.z;
              temp.z := temp.z + z_axis.z * point.z;
            end;
          x_aligned:
            temp.x := temp.x + z_axis.x * point.z;
          y_aligned:
            temp.y := temp.y + z_axis.y * point.z;
          z_aligned:
            temp.z := temp.z + z_axis.z * point.z;
        end; {z_axis}
    end;

  point := temp;
end; {procedure Transform_point_from_axes}


procedure Transform_binormal_from_axes(var binormal: binormal_type;
  coord_axes: coord_axes_type);
begin
  Transform_vector_from_axes(binormal.x_axis, coord_axes);
  Transform_vector_from_axes(binormal.y_axis, coord_axes);
end; {procedure Transform_binormal_from_axes}


procedure Transform_ray_from_axes(var ray: ray_type;
  coord_axes: coord_axes_type);
begin
  Transform_point_from_axes(ray.location, coord_axes);
  Transform_vector_from_axes(ray.direction, coord_axes);
end; {procedure Transform_ray_from_axes}


procedure Transform_trans_from_axes(var trans: trans_type;
  coord_axes: coord_axes_type);
begin
  Transform_point_from_axes(trans.origin, coord_axes);
  Transform_vector_from_axes(trans.x_axis, coord_axes);
  Transform_vector_from_axes(trans.y_axis, coord_axes);
  Transform_vector_from_axes(trans.z_axis, coord_axes);
end; {procedure Transform_trans_from_axes}


procedure Transform_axes_from_axes(var coord_axes: coord_axes_type;
  source_axes: coord_axes_type);
begin
  Transform_point_from_axes(coord_axes.trans.origin, source_axes);
  Transform_vector_from_axes(coord_axes.trans.x_axis, source_axes);
  Transform_vector_from_axes(coord_axes.trans.y_axis, source_axes);
  Transform_vector_from_axes(coord_axes.trans.z_axis, source_axes);
  coord_axes := Trans_to_axes(coord_axes.trans);
end; {procedure Transform_axes_from_axes}


procedure Transform_vector_to_axes(var vector: vector_type;
  coord_axes: coord_axes_type);
var
  temp: vector_type;
begin
  {*******************************************************************}
  { vector := Sum(Scale(coord_axes.inverse_trans.x_axis, vector.x),   }
  {           Sum(Scale(coord_axes.inverse_trans.y_axis, vector.y),   }
  {               Scale(coord_axes.inverse_trans.z_axis, vector.z))); }
  {*******************************************************************}
  temp := zero_vector;

  with coord_axes.inverse_trans do
    begin
      {********}
      { x_axis }
      {********}
      if (vector.x <> 0) then
        case coord_axes.inverse_trans_alignment.x_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + x_axis.x * vector.x;
              temp.y := temp.y + x_axis.y * vector.x;
              temp.z := temp.z + x_axis.z * vector.x;
            end;
          x_aligned:
            temp.x := temp.x + x_axis.x * vector.x;
          y_aligned:
            temp.y := temp.y + x_axis.y * vector.x;
          z_aligned:
            temp.z := temp.z + x_axis.z * vector.x;
        end; {x_axis}

      {********}
      { y_axis }
      {********}
      if (vector.y <> 0) then
        case coord_axes.inverse_trans_alignment.y_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + y_axis.x * vector.y;
              temp.y := temp.y + y_axis.y * vector.y;
              temp.z := temp.z + y_axis.z * vector.y;
            end;
          x_aligned:
            temp.x := temp.x + y_axis.x * vector.y;
          y_aligned:
            temp.y := temp.y + y_axis.y * vector.y;
          z_aligned:
            temp.z := temp.z + y_axis.z * vector.y;
        end; {y_axis}

      {********}
      { z_axis }
      {********}
      if (vector.z <> 0) then
        case coord_axes.inverse_trans_alignment.z_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + z_axis.x * vector.z;
              temp.y := temp.y + z_axis.y * vector.z;
              temp.z := temp.z + z_axis.z * vector.z;
            end;
          x_aligned:
            temp.x := temp.x + z_axis.x * vector.z;
          y_aligned:
            temp.y := temp.y + z_axis.y * vector.z;
          z_aligned:
            temp.z := temp.z + z_axis.z * vector.z;
        end; {z_axis}
    end;

  vector := temp;
end; {procedure Transform_vector_to_axes}


procedure Transform_point_to_axes(var point: vector_type;
  coord_axes: coord_axes_type);
var
  temp: vector_type;
begin
  {******************************************************************}
  { point := Sum(coord_axes.inverse_trans.origin,                    }
  {          Sum(Scale(coord_axes.inverse_trans.x_axis, point.x),    }
  {          Sum(Scale(coord_axes.inverse_trans.y_axis, point.y),    }
  {              Scale(coord_axes.inverse_trans.z_axis, point.z)))); }
  {******************************************************************}

  with coord_axes.inverse_trans do
    begin
      temp := origin;

      {********}
      { x_axis }
      {********}
      if (point.x <> 0) then
        case coord_axes.inverse_trans_alignment.x_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + x_axis.x * point.x;
              temp.y := temp.y + x_axis.y * point.x;
              temp.z := temp.z + x_axis.z * point.x;
            end;
          x_aligned:
            temp.x := temp.x + x_axis.x * point.x;
          y_aligned:
            temp.y := temp.y + x_axis.y * point.x;
          z_aligned:
            temp.z := temp.z + x_axis.z * point.x;
        end; {x_axis}

      {********}
      { y_axis }
      {********}
      if (point.y <> 0) then
        case coord_axes.inverse_trans_alignment.y_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + y_axis.x * point.y;
              temp.y := temp.y + y_axis.y * point.y;
              temp.z := temp.z + y_axis.z * point.y;
            end;
          x_aligned:
            temp.x := temp.x + y_axis.x * point.y;
          y_aligned:
            temp.y := temp.y + y_axis.y * point.y;
          z_aligned:
            temp.z := temp.z + y_axis.z * point.y;
        end; {y_axis}

      {********}
      { z_axis }
      {********}
      if (point.z <> 0) then
        case coord_axes.inverse_trans_alignment.z_axis_alignment of
          unaligned:
            begin
              temp.x := temp.x + z_axis.x * point.z;
              temp.y := temp.y + z_axis.y * point.z;
              temp.z := temp.z + z_axis.z * point.z;
            end;
          x_aligned:
            temp.x := temp.x + z_axis.x * point.z;
          y_aligned:
            temp.y := temp.y + z_axis.y * point.z;
          z_aligned:
            temp.z := temp.z + z_axis.z * point.z;
        end; {z_axis}
    end;

  point := temp;
end; {procedure Transform_point_to_axes}


procedure Transform_binormal_to_axes(var binormal: binormal_type;
  coord_axes: coord_axes_type);
begin
  Transform_vector_to_axes(binormal.x_axis, coord_axes);
  Transform_vector_to_axes(binormal.y_axis, coord_axes);
end; {procedure Transform_binormal_to_axes}


procedure Transform_ray_to_axes(var ray: ray_type;
  coord_axes: coord_axes_type);
begin
  Transform_point_to_axes(ray.location, coord_axes);
  Transform_vector_to_axes(ray.direction, coord_axes);
end; {procedure Transform_ray_to_axes}


procedure Transform_trans_to_axes(var trans: trans_type;
  coord_axes: coord_axes_type);
begin
  Transform_point_to_axes(trans.origin, coord_axes);
  Transform_vector_to_axes(trans.x_axis, coord_axes);
  Transform_vector_to_axes(trans.y_axis, coord_axes);
  Transform_vector_to_axes(trans.z_axis, coord_axes);
end; {procedure Transform_trans_to_axes}


procedure Transform_axes_to_axes(var coord_axes: coord_axes_type;
  dest_axes: coord_axes_type);
begin
  Transform_point_to_axes(coord_axes.trans.origin, dest_axes);
  Transform_vector_to_axes(coord_axes.trans.x_axis, dest_axes);
  Transform_vector_to_axes(coord_axes.trans.y_axis, dest_axes);
  Transform_vector_to_axes(coord_axes.trans.z_axis, dest_axes);
  coord_axes := Trans_to_axes(coord_axes.trans);
end; {procedure Transform_axes_to_axes}


procedure Write_axis_alignment(axis_alignment: axis_alignment_type);
begin
  case axis_alignment of
    x_aligned:
      write('x_aligned');
    y_aligned:
      write('y_aligned');
    z_aligned:
      write('z_aligned');
    unaligned:
      write('unaligned');
  end; {case}
end; {procedure Write_axis_alignment}


procedure Write_trans_alignment(trans_alignment: trans_alignment_type);
begin
  with trans_alignment do
    begin
      write('x_axis: ');
      Write_axis_alignment(trans_alignment.x_axis_alignment);
      writeln;

      write('y_axis: ');
      Write_axis_alignment(trans_alignment.y_axis_alignment);
      writeln;

      write('z_axis: ');
      Write_axis_alignment(trans_alignment.z_axis_alignment);
      writeln;
    end;
end; {procedure Write_trans_alignment}


procedure Write_axes(coord_axes: coord_axes_type);
begin
  with coord_axes do
    begin
      writeln('coord_axes with');
      writeln('trans:');
      Write_trans(trans);

      {writeln('inverse_trans:');}
      {Write_trans(inverse_trans);}

      {writeln('trans alignment:');}
      {Write_trans_alignment(trans_alignment);}

      {writeln('inverse trans alignment:');}
      {Write_trans_alignment(inverse_trans_alignment);}
    end;
end; {procedure Write_axes}


initialization
  unit_axes := Trans_to_axes(unit_trans);
end.
