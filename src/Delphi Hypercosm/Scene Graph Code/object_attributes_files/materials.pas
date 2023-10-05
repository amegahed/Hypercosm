unit materials;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             materials                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The materials module provides data structures and       }
{       routines for describing basic surface materials         }
{       for lighting and shading purposes.                      }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  colors, textures;


type
  material_ptr_type = ^material_type;
  material_type = record

    {************************}
    { directional components }
    {************************}
    diffuse, specular: color_type;
    specular_power: real;

    {****************************}
    { non directional components }
    {****************************}
    ambient, emissive: color_type;

    {**************************}
    { secondary ray components }
    {**************************}
    reflected, transmitted: color_type;

    {*************}
    { texture map }
    {*************}
    texture_ptr: texture_ptr_type;

    next: material_ptr_type;
  end; {material_type}


function New_material(diffuse, specular: color_type;
  specular_power: real;
  ambient, emissive: color_type;
  reflected, transmitted: color_type;
  texture_ptr: texture_ptr_type): material_ptr_type;
procedure Free_material(var material_ptr: material_ptr_type);


implementation
uses
  new_memory;


const
  memory_alert = false;


var
  material_free_list: material_ptr_type;


function New_material(diffuse, specular: color_type;
  specular_power: real;
  ambient, emissive: color_type;
  reflected, transmitted: color_type;
  texture_ptr: texture_ptr_type): material_ptr_type;
var
  material_ptr: material_ptr_type;
begin
  {*******************************}
  { get new vertex from free list }
  {*******************************}
  if material_free_list <> nil then
    begin
      material_ptr := material_free_list;
      material_free_list := material_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new material');
      new(material_ptr);
    end;

  {*********************}
  { initialize material }
  {*********************}
  material_ptr^.diffuse := diffuse;
  material_ptr^.specular := specular;
  material_ptr^.specular_power := specular_power;
  material_ptr^.ambient := ambient;
  material_ptr^.emissive := emissive;
  material_ptr^.reflected := reflected;
  material_ptr^.transmitted := transmitted;
  material_ptr^.texture_ptr := texture_ptr;
  material_ptr^.next := nil;

  New_material := material_ptr;
end; {function New_material}


procedure Free_material(var material_ptr: material_ptr_type);
begin
  material_ptr^.next := material_free_list;
  material_free_list := material_ptr;
  material_ptr := nil;
end; {procedure Free_material}


initialization
  material_free_list := nil;
end.
