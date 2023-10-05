unit textures;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               textures                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines for defining the          }
{       basic texture data structures.                          }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  images, new_memory;


type
  texture_ptr_type = ^texture_type;
  texture_type = record
    image_ptr: image_ptr_type;
    interpolation, mipmapping, wraparound: boolean;
    ptr: ptr_type;
    next: texture_ptr_type;
  end; {texture_type}


{************************************************}
{ routines for allocating and freeing z textures }
{************************************************}
function New_texture(image_ptr: image_ptr_type;
  interpolation, mipmapping, wraparound: boolean): texture_ptr_type;
procedure Free_texture(var texture_ptr: texture_ptr_type);


implementation


const
  memory_alert = false;


var
  texture_free_list: texture_ptr_type;


{************************************************}
{ routines for allocating and freeing z textures }
{************************************************}


function New_texture(image_ptr: image_ptr_type;
  interpolation, mipmapping, wraparound: boolean): texture_ptr_type;
var
  texture_ptr: texture_ptr_type;
begin
  {********************************}
  { get new texture from free list }
  {********************************}
  if texture_free_list <> nil then
    begin
      texture_ptr := texture_free_list;
      texture_free_list := texture_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new z texture');
      new(texture_ptr);
    end;

  {**********************}
  { initialize z texture }
  {**********************}
  texture_ptr^.image_ptr := image_ptr;
  texture_ptr^.interpolation := interpolation;
  texture_ptr^.mipmapping := mipmapping;
  texture_ptr^.wraparound := wraparound;
  texture_ptr^.ptr := nil;
  texture_ptr^.next := nil;

  New_texture := texture_ptr;
end; {function New_texture}


procedure Free_texture(var texture_ptr: texture_ptr_type);
begin
  {**************************}
  { add texture to free list }
  {**************************}
  texture_ptr^.next := texture_free_list;
  texture_free_list := texture_ptr;
  texture_ptr := nil;
end; {procedure Free_texture}


initialization
  texture_free_list := nil;
end.
