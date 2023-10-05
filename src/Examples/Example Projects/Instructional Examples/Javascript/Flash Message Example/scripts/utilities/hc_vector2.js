/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm            hc_vector2.js               3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file defines a simple three dimensional vector    |
|        data type and a few basic vector operations.           |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

//
// "class" constructor
//

function HCVector2(x, y) {
	
  // check for valid values
  //
  if (isNaN(x)) x = 0;
  if (isNaN(y)) y = 0;
  // set attributes
  //
  this.x = x;
  this.y = y;
  
  return this;
}    // HCVector2

//
// "object" or "instance" methods
//

HCVector2.prototype.equals = function(vector) {
  if (vector)
    return ((this.x == vector.x) && (this.y == vector.y))
  else
    return false;
}    // equals

HCVector2.prototype.duplicate = function() {
  return new HCVector2(this.x, this.y);
}    // duplicate

HCVector2.prototype.toPrecision = function(precision) {
  return this.x.toPrecision(precision) + "," + this.y.toPrecision(precision);
}    // toPrecision

//
// vector arithmetic methods
//

HCVector2.prototype.add = function(vector) {
  this.x = this.x + vector.x;
  this.y = this.y + vector.y;
}    // add

HCVector2.prototype.subtract = function(vector) {
  this.x = this.x - vector.x;
  this.y = this.y - vector.y;
}    // subtract

HCVector2.prototype.multiplyBy = function(vector) {
  this.x = this.x * vector.x;
  this.y = this.y * vector.y;
}    // multiplyBy

HCVector2.prototype.divideBy = function(vector) {
  this.x = this.x / vector.x;
  this.y = this.y / vector.y;
}    // divideBy

HCVector2.prototype.scaleBy = function(scalar) {
  this.x = this.x * scalar;
  this.y = this.y * scalar;
}    // scaleBy

//
// vector function methods
//

HCVector2.prototype.plus = function(vector) {
  var x = this.x + vector.x;
  var y = this.y + vector.y;
  return new HCVector2(x, y);
}    // plus

HCVector2.prototype.minus = function(vector) {
  var x = this.x - vector.x;
  var y = this.y - vector.y;
  return new HCVector2(x, y);
}    // minus

HCVector2.prototype.times = function(vector) {
  var x = this.x * vector.x;
  var y = this.y * vector.y;
  return new HCVector2(x, y);
}    // times

HCVector2.prototype.dividedBy = function(vector) {
  var x = this.x / vector.x;
  var y = this.y / vector.y;
  return new HCVector2(x, y);
}    // dividedBy

HCVector2.prototype.scaledBy = function(scalar) {
  var x = this.x * scalar;
  var y = this.y * scalar;
  return new HCVector2(x, y);
}    // scaledBy

//
// vector operators
// 

HCVector2.prototype.dotProduct = function(vector) {
  return (this.x * vector.x) + (this.y * vector.y);
}    // dotProduct

