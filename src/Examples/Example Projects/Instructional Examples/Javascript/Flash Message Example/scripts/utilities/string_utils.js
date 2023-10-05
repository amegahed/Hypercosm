/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm           string_utils.js              3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file contains some javascript utilities that      |
|        are used to work with strings.                         |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

function isString(variable) {
  if (typeof(variable) == 'string')
    return true;
  else if (typeof arguments[0] == 'object')   
    return (arguments[0].constructor.toString().match(/string/i) != null);
}	// isString

function toLower(string) {
  string = string.replace(/A/g, "a");
  string = string.replace(/B/g, "b");
  string = string.replace(/C/g, "c");
  string = string.replace(/D/g, "d");
  string = string.replace(/E/g, "e");
  string = string.replace(/F/g, "f");
  string = string.replace(/G/g, "g");
  string = string.replace(/H/g, "h");
  string = string.replace(/I/g, "i");
  string = string.replace(/J/g, "j");
  string = string.replace(/K/g, "k");
  string = string.replace(/L/g, "l");
  string = string.replace(/M/g, "m");
  string = string.replace(/N/g, "n");
  string = string.replace(/O/g, "o");
  string = string.replace(/P/g, "p");
  string = string.replace(/Q/g, "q");
  string = string.replace(/R/g, "r");
  string = string.replace(/S/g, "s");
  string = string.replace(/T/g, "t");
  string = string.replace(/U/g, "u");
  string = string.replace(/V/g, "v");
  string = string.replace(/W/g, "w");
  string = string.replace(/X/g, "x");
  string = string.replace(/Y/g, "y");
  string = string.replace(/Z/g, "z");
  return string;
}	// toLower

function toUpper(string) {
  string = string.replace(/a/g, "A");
  string = string.replace(/b/g, "B");
  string = string.replace(/c/g, "C");
  string = string.replace(/d/g, "D");
  string = string.replace(/e/g, "E");
  string = string.replace(/f/g, "F");
  string = string.replace(/g/g, "G");
  string = string.replace(/h/g, "H");
  string = string.replace(/i/g, "I");
  string = string.replace(/j/g, "J");
  string = string.replace(/k/g, "K");
  string = string.replace(/l/g, "L");
  string = string.replace(/m/g, "M");
  string = string.replace(/n/g, "N");
  string = string.replace(/o/g, "O");
  string = string.replace(/p/g, "P");
  string = string.replace(/q/g, "Q");
  string = string.replace(/r/g, "R");
  string = string.replace(/s/g, "S");
  string = string.replace(/t/g, "T");
  string = string.replace(/u/g, "U");
  string = string.replace(/v/g, "V");
  string = string.replace(/w/g, "W");
  string = string.replace(/x/g, "X");
  string = string.replace(/y/g, "Y");
  string = string.replace(/z/g, "Z");
  return string;
}	// toUpper

function getQuotatedString(string) {
  if (string && (string.search('"') == -1))
    return '"' + string + '"';		// use double quotes
  else
    return "'" + string + "'";		// use single quotes
}	// getQuotatedString