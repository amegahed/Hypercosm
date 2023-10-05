/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm           rgb_color.js                 3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file defines a simple RGB (red, green, blue)      |
|        color type and a few basic operations.                 |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

//
// "class" constructor
//

function RGBColor(red, green, blue) {
  // check for valid values
  //
  if (isNaN(red)) red = 0;
  if (isNaN(green)) green = 0;
  if (isNaN(blue)) blue = 0;
  
  // set attributes
  //
  this.red = red;
  this.green = green;
  this.blue = blue;
  
  return this;
}    // RGBColor

//
// "object" or "instance" methods
//

RGBColor.prototype.matches = function(color) {
  if (color)
    return ((this.red == color.red) && (this.green == color.green) && (this.blue == color.blue))
  else
    return false;
}    // matches

RGBColor.prototype.toString = function() {
  return this.red.toString() + "," + this.green.toString() + "," + this.blue.toString();
}    // toString

//
// color conversion methods
//

RGBColor.prototype.toHex = function() {
  var red = Math.floor(this.red);
  var green = Math.floor(this.green);
  var blue = Math.floor(this.blue);
  
  // clamp values to range
  //
  if (red < 0 || isNaN(red)) red = 0;
  if (red > 255) red = 255;
  if (green < 0 || isNaN(green)) green = 0;
  if (green > 255) green = 255;
  if (blue < 0 || isNaN(blue)) blue = 0;
  if (blue > 255) blue = 255;
	 
  // convert to hex
  //
  red = red.toString(16);
  green = green.toString(16);
  blue = blue.toString(16);
  
  // make sure each component is two digits
  //
  if (red.length < 2) red = "0" + red;
  if (green.length < 2) green = "0" + green;
  if (blue.length < 2) blue = "0" + blue;
  
  return red + green + blue;
}	// toHex
