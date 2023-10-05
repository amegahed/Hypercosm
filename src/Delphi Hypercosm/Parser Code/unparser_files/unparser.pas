unit unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              unparser                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module traverses the syntax tree and writes out    }
{       the original program expressions from it.               }
{       This is useful for debugging and to tell if the         }
{       parsers have produced the correct syntax tree.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


var
  {*****************}
  { formatter flags }
  {*****************}
  tabsize: integer;
  max_line_length: integer;
  line_break_length: integer;
  max_indent_length: integer;
  do_tabs: boolean;

  {****************}
  { unparser flags }
  {****************}
  show_types: boolean;
  show_implicit: boolean;
  show_includes: boolean;
  show_shadowed_decls: boolean;
  show_precedence: boolean;
  indented_wraparound: boolean;

  {***************************}
  { unparser diagnostic flags }
  {***************************}
  show_decl_addrs: boolean;
  show_expr_addrs: boolean;
  show_init_addrs: boolean;
  show_static_levels: boolean;
  show_dynamic_levels: boolean;


implementation


initialization
  {*****************}
  { formatter flags }
  {*****************}
  tabsize := 8;
  max_line_length := 64;
  line_break_length := 75;
  max_indent_length := 50;
  do_tabs := true;

  {****************}
  { unparser flags }
  {****************}
  show_types := false;
  show_implicit := false;
  show_includes := false;
  show_shadowed_decls := false;
  show_precedence := false;
  indented_wraparound := true;

  {***************************}
  { unparser diagnostic flags }
  {***************************}
  show_decl_addrs := false;
  show_expr_addrs := false;
  show_init_addrs := false;
  show_static_levels := false;
  show_dynamic_levels := false;
end.
