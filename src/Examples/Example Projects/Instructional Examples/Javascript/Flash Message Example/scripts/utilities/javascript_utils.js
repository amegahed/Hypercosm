/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm         javascript_utils.js            3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file contains some generalized javascript         |
|        utilities that add basic features to the language.     |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

function isDefined(variable) {
  return eval('(typeof(' + variable + ') != "undefined");');
}    // isDefined

function isArray(variable) {
  if (typeof(variable) == 'object') 
    return (variable.constructor.toString().match(/array/i) != null);
  else
    return false;
}	// isArray
 
 
function inArray(value, array) {
  for (var counter = 0; counter < array.length; counter++)
    if (array[counter] == value)
      return true;
  return false;
}	// inArray

function copyArray(array) {
  if (!array)
    return;
  var array2 = new Array();
  for (var counter = 0; counter < array.length; counter++)
    array2[counter] = array[counter];
  return array2;
}	// copyArray

function arrayToString(array, seperator, quotateStrings, addBrackets) {
  var string = "";
  
  // set optional parameter defaults
  //
  if (quotateStrings == undefined)
    quotateStrings = false;
  if (seperator == undefined)
    seperator = "";
  if (addBrackets == undefined)
    addBrackets = false;
  
  if (addBrackets)
    string += "[";
  for (var counter = 0; counter < array.length; counter++) {
    if (counter > 0)
	  string += seperator;
	  
    if (isString(array[counter]) && quotateStrings)
      string += getQuotatedString(array[counter]);
    else if (isArray(array[counter]))
	  string += arrayToString(array[counter], seperator, quotateStrings, addBrackets);
    else
      string += array[counter];
  }
  if (addBrackets)
    string += "]";
	
  return string;
}	// arrayToString

// This function binds a method to a particular
// object for executing at a later time
//
function getClosure(objectName, methodName, parameters) {
  function execute() {
    objectName[methodName](parameters);
  }
  return execute;
}    // getClosure

function callFunction() {
  if (callFunction.arguments.length == 0)
    return;
  var string = callFunction.arguments[0] + "(";
  for (var counter = 1; counter < callFunction.arguments.length; counter++) {
    if (counter > 1)
      string += ", ";
    if (isString(callFunction.arguments[counter]))
      string += '"' + callFunction.arguments[counter] + '"';
    else if (isArray(callFunction.arguments[counter]))
	  string += arrayToString(callFunction.arguments[counter], ", ", true, true);
    else
      string += callFunction.arguments[counter];
  }
  string += ")";
  eval(string);
}    // callFunction

