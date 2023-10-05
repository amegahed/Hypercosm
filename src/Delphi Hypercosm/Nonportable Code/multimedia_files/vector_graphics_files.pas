unit vector_graphics_files;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm         vector_graphics_file          3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to save pictures          }
{       to a file in a vector format.                           }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  strings, display_lists;


{**************************************}
{ routines to save vector based images }
{**************************************}
procedure Save_pict_image(name: string_type;
  display_list_ptr: display_list_ptr_type);

{**************************************}
{ routines to load vector based images }
{**************************************}
function Load_pict_image(name: string_type): display_list_ptr_type;


implementation


const
  memory_alert = false;


  {**************************************}
  { routines to save vector based images }
  {**************************************}


procedure Save_pict_image(name: string_type;
  display_list_ptr: display_list_ptr_type);
begin
end; {procedure Save_pict_image}


{**************************************}
{ routines to load vector based images }
{**************************************}


function Load_pict_image(name: string_type): display_list_ptr_type;
begin
  Load_pict_image := nil;
end; {function Load_pict_image}


end.
