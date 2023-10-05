unit code_types;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             code_types                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the attributes and descriptors     }
{       of primitive code types which are used by the           }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


type
  code_kind_type = (

    {******************}
    { basic code kinds }
    {******************}
    procedure_code, function_code,

    {********************}
    { special code kinds }
    {********************}
    constructor_code, destructor_code,

    {**********************}
    { modelling code kinds }
    {**********************}
    shader_code, object_code,

    {**********************}
    { rendering code kinds }
    {**********************}
    picture_code, anim_code);


type
  code_kind_set_type = set of code_kind_type;


var
  {********************}
  { sets of code kinds }
  {********************}
  special_code_kinds, procedural_code_kinds, functional_code_kinds:
  code_kind_set_type;


{************************************}
{ routines to write enumerated types }
{************************************}
procedure Write_code_kind(kind: code_kind_type);


implementation
uses
  errors;


{************************************}
{ routines to write enumerated types }
{************************************}


procedure Write_code_kind(kind: code_kind_type);
begin
  case kind of

    {******************}
    { basic code kinds }
    {******************}
    procedure_code:
      write('verb');
    function_code:
      write('question');

    {********************}
    { special code kinds }
    {********************}
    constructor_code:
      write('constructor');
    destructor_code:
      write('destructor');

    {**********************}
    { modelling code kinds }
    {**********************}
    shader_code:
      write('shader');
    object_code:
      write('shape');

    {**********************}
    { rendering code kinds }
    {**********************}
    picture_code:
      write('picture');
    anim_code:
      write('anim');

  end;
end; {procedure Write_code_kind}


initialization
  special_code_kinds := [constructor_code, destructor_code];
  procedural_code_kinds := [procedure_code, object_code, picture_code,
    anim_code];
  functional_code_kinds := [function_code, shader_code];
end.
