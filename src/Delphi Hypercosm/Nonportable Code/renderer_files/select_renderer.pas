unit select_renderer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           select_renderer             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module allows us to select a renderer based        }
{	upon the capabilities required.				}
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  drawable, renderer;


type
  renderer_capabilities_kind_type = (
    does_software_rendering, does_pixel_rendering);


  renderer_capabilities_type = set of renderer_capabilities_kind_type;


function Select_new_renderer(capabilities: renderer_capabilities_type;
  drawable: drawable_type):
  renderer_type;


implementation
uses
  z_renderer, opengl_renderer;


function Select_new_renderer(capabilities: renderer_capabilities_type;
  drawable: drawable_type): renderer_type;
var
  renderer: renderer_type;
  z_renderer: z_renderer_type;
  opengl_z_renderer: opengl_renderer_type;
begin
  if does_software_rendering in capabilities then
    begin
      z_renderer := z_renderer_type.Create;
      z_renderer.Open(drawable);
      renderer := z_renderer;
    end
  else
    begin
      opengl_z_renderer := opengl_renderer_type.Create;
      opengl_z_renderer.Open(drawable);
      renderer := opengl_z_renderer;
    end;

  Select_new_renderer := renderer;
end; {function Select_new_renderer}


end.

