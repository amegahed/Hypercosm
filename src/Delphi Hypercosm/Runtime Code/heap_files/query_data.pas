unit query_data;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             query_data                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       Using a tagged data format allows data to be            }
{       queried for its type information.                       }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  complex_numbers, vectors, colors, addr_types, data_types, data;


{***************************************}
{ routines to query for primitive types }
{***************************************}
function Found_boolean(var boolean_val: boolean_type;
  addr: addr_type): boolean;
function Found_char(var char_val: char_type;
  addr: addr_type): boolean;

function Found_byte(var byte_val: byte_type;
  addr: addr_type): boolean;
function Found_short(var short_val: short_type;
  addr: addr_type): boolean;

function Found_integer(var integer_val: integer_type;
  addr: addr_type): boolean;
function Found_long(var long_val: long_type;
  addr: addr_type): boolean;

function Found_scalar(var scalar_val: scalar_type;
  addr: addr_type): boolean;
function Found_double(var double_val: double_type;
  addr: addr_type): boolean;

{**************************************}
{ routines to query for compound types }
{**************************************}
function Found_complex(var complex_val: complex_type;
  addr: addr_type): boolean;
function Found_vector(var vector_val: vector_type;
  addr: addr_type): boolean;
function Found_color(var color_val: color_type;
  addr: addr_type): boolean;


implementation
uses
  get_data;


{*********************************************}
{ routines to query stack for primitive types }
{*********************************************}


function Found_boolean(var boolean_val: boolean_type;
  addr: addr_type): boolean;
var
  found: boolean;
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind = boolean_data then
    begin
      boolean_val := Data_to_boolean(data);
      found := true;
    end
  else
    found := false;

  Found_boolean := found;
end; {function Found_boolean}


function Found_char(var char_val: char_type;
  addr: addr_type): boolean;
var
  found: boolean;
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind = char_data then
    begin
      char_val := Data_to_char(data);
      found := true;
    end
  else
    found := false;

  Found_char := found;
end; {function Found_char}


function Found_byte(var byte_val: byte_type;
  addr: addr_type): boolean;
var
  found: boolean;
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind = byte_data then
    begin
      byte_val := Data_to_byte(data);
      found := true;
    end
  else
    found := false;

  Found_byte := found;
end; {function Found_byte}


function Found_short(var short_val: short_type;
  addr: addr_type): boolean;
var
  found: boolean;
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind = short_data then
    begin
      short_val := Data_to_short(data);
      found := true;
    end
  else
    found := false;

  Found_short := found;
end; {function Found_short}


function Found_integer(var integer_val: integer_type;
  addr: addr_type): boolean;
var
  found: boolean;
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind = integer_data then
    begin
      integer_val := Data_to_integer(data);
      found := true;
    end
  else
    found := false;

  Found_integer := found;
end; {function Found_integer}


function Found_long(var long_val: long_type;
  addr: addr_type): boolean;
var
  found: boolean;
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind = long_data then
    begin
      long_val := Data_to_long(data);
      found := true;
    end
  else
    found := false;

  Found_long := found;
end; {function Found_long}


function Found_scalar(var scalar_val: scalar_type;
  addr: addr_type): boolean;
var
  found: boolean;
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind = scalar_data then
    begin
      scalar_val := Data_to_scalar(data);
      found := true;
    end
  else
    found := false;

  Found_scalar := found;
end; {function Found_scalar}


function Found_double(var double_val: double_type;
  addr: addr_type): boolean;
var
  found: boolean;
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind = double_data then
    begin
      double_val := Data_to_double(data);
      found := true;
    end
  else
    found := false;

  Found_double := found;
end; {function Found_double}


{**************************************}
{ routines to query for compound types }
{**************************************}


function Found_complex(var complex_val: complex_type;
  addr: addr_type): boolean;
var
  found: boolean;
begin
  if not Found_scalar(complex_val.a, addr) then
    found := false
  else if not Found_scalar(complex_val.b, Get_offset_addr(addr, 1)) then
    found := false
  else
    found := true;

  Found_complex := found;
end; {function Found_complex}


function Found_vector(var vector_val: vector_type;
  addr: addr_type): boolean;
var
  found: boolean;
begin
  if not Found_scalar(vector_val.x, addr) then
    found := false
  else if not Found_scalar(vector_val.y, Get_offset_addr(addr, 1)) then
    found := false
  else if not Found_scalar(vector_val.z, Get_offset_addr(addr, 2)) then
    found := false
  else
    found := true;

  Found_vector := found;
end; {function Found_vector}


function Found_color(var color_val: color_type;
  addr: addr_type): boolean;
var
  found: boolean;
begin
  if not Found_scalar(color_val.r, addr) then
    found := false
  else if not Found_scalar(color_val.g, Get_offset_addr(addr, 1)) then
    found := false
  else if not Found_scalar(color_val.b, Get_offset_addr(addr, 2)) then
    found := false
  else
    found := true;

  Found_color := found;
end; {function Found_color}


end.
