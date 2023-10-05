/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm          common_colors.js              3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file defines a collection of commonly used        |
|        colors.                                                |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

var red = new RGBColor(255, 0, 0);
var green = new RGBColor(0, 255, 0);
var blue = new RGBColor(0, 0, 255);
var cyan = new RGBColor(0, 255, 255);
var magenta = new RGBColor(255, 0, 255);
var yellow = new RGBColor(255, 255, 0);
var orange = new RGBColor(255, 127, 0);
var black = new RGBColor(0, 0, 0);
var white = new RGBColor(255, 255, 255);
var grey = new RGBColor(127, 127, 127);

function colorToNamedColor(color) {
  if (color.matches(red))
    return "red";
  else if (color.matches(green))
    return "green";
  else if (color.matches(blue))
    return "blue";
  else if (color.matches(cyan))
    return "cyan";
  else if (color.matches(magenta))
    return "magenta";
  else if (color.matches(yellow))
    return "yellow";
  else if (color.matches(orange))
    return "orange";
  else if (color.matches(black))
    return "black";
  else if (color.matches(white))
    return "white";
  else if (color.matches(grey))
    return "grey";
  else
    return null;
}	// colorToNamedColor

function namedColorToColor(color) {
  if (color == "red")
    return red;
  else if (color == "green")
    return green;
  else if (color == "blue")
    return blue;
  else if (color == "cyan")
    return cyan;
  else if (color == "magenta")
    return magenta;
  else if (color == "yellow")
    return yellow;
  else if (color == "orange")
    return orange;
  else if (color == "black")
    return black;
  else if (color == "white")
    return white;
  else if (color == "grey")
   return grey;
  else 
    return null;
}	// namedColorToColor
  