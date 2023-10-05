unit system_sounds;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            system_sounds              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to the               }
{       system dependent sound functions.                       }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  strings;


type
  sound_ptr_type = ^sound_type;
  sound_type = record
    name: string_type;
  end; {sound_type}


function Open_sound(name: string_type): sound_ptr_type;
procedure Play_sound(sound_ptr: sound_ptr_type);
procedure Start_sound(sound_ptr: sound_ptr_type);
procedure Stop_sound(sound_ptr: sound_ptr_type);
procedure Free_sound(var sound_ptr: sound_ptr_type);
procedure Sound_beep;


implementation


const
  verbose = true;


function New_sound(name: string_type): sound_ptr_type;
var
  sound_ptr: sound_ptr_type;
begin
  new(sound_ptr);
  sound_ptr^.name := name;

  New_sound := sound_ptr;
end; {function New_sound}


function Open_sound(name: string_type): sound_ptr_type;
var
  sound_ptr: sound_ptr_type;
begin
  sound_ptr := New_sound(name);

  if verbose then
    writeln('opening sound ', sound_ptr^.name);

  Open_sound := sound_ptr;
end; {function Open_sound}


procedure Play_sound(sound_ptr: sound_ptr_type);
begin
  if verbose then
    writeln('playing sound ', sound_ptr^.name);
end; {procedure Play_sound}


procedure Start_sound(sound_ptr: sound_ptr_type);
begin
  if verbose then
    writeln('starting sound ', sound_ptr^.name);
end; {procedure Start_sound}


procedure Stop_sound(sound_ptr: sound_ptr_type);
begin
  if verbose then
    writeln('stopping sound ', sound_ptr^.name);
end; {procedure Stop_sound}


procedure Free_sound(var sound_ptr: sound_ptr_type);
begin
  if verbose then
    writeln('freeing sound ', sound_ptr^.name);

  dispose(sound_ptr);
  sound_ptr := nil;
end; {procedure Free_sound}


procedure Sound_beep;
begin
end; {procedure Sound_beep}


end.
