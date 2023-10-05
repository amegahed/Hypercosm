/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm            hc_vector3.js               3d      |
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

function HCVector3(x, y, z) {
	
  // check for valid values
  //
  if (isNaN(x)) x = 0;
  if (isNaN(y)) y = 0;
  if (isNaN(z)) z = 0;
  // set attributes
  //
  this.x = x;
  this.y = y;
  this.z = z;
  
  return this;
}    // HCVector3

//
// "object" or "instance" methods
//

HCVector3.prototype.equals = function(vector) {
  if (vector)
    return ((this.x == vector.x) && (this.y == vector.y) && (this.z == vector.z))
  else
    return false;
}    // equals

HCVector3.prototype.duplicate = function() {
  return new HCVector3(this.x, this.y, this.z);
}    // duplicate

HCVector3.prototype.toPrecision = function(precision) {
  return this.x.toPrecision(precision) + "," + this.y.toPrecision(precision) + "," + this.z.toPrecision(precision);
}    // toPrecision

//
// vector arithmetic methods
//

HCVector3.prototype.add = function(vector) {
  this.x = this.x + vector.x;
  this.y = this.y + vector.y;
  this.z = this.z + vector.z;
}    // add

HCVector3.prototype.subtract = function(vector) {
  this.x = this.x - vector.x;
  this.y = this.y - vector.y;
  this.z = this.z - vector.z;
}    // subtract

HCVector3.prototype.multiplyBy = function(vector) {
  this.x = this.x * vector.x;
  this.y = this.y * vector.y;
  this.z = this.z * vector.z;
}    // multiplyBy

HCVector3.prototype.divideBy = function(vector) {
  this.x = this.x / vector.x;
  this.y = this.y / vector.y;
  this.z = this.z / vector.z;
}    // divideBy

HCVector3.prototype.scaleBy = function(scalar) {
  this.x = this.x * scalar;
  this.y = this.y * scalar;
  this.z = this.z * scalar;
}    // scaleBy

//
// vector arithmetic functions
//

HCVector3.prototype.plus = function(vector) {
  var x = this.x + vector.x;
  var y = this.y + vector.y;
  var z = this.z + vector.z;
  return new HCVector3(x, y, z);
}    // plus

HCVector3.prototype.minus = function(vector) {
  var x = this.x - vector.x;
  var y = this.y - vector.y;
  var z = this.z - vector.z;
  return new HCVector3(x, y, z);
}    // minus

HCVector3.prototype.times = function(vector) {
  var x = this.x * vector.x;
  var y = this.y * vector.y;
  var z = this.z * vector.z;
  return new HCVector3(x, y, z);
}    // times

HCVector3.prototype.dividedBy = function(vector) {
  var x = this.x / vector.x;
  var y = this.y / vector.y;
  var z = this.z / vector.z;
  return new HCVector3(x, y, z);
}    // dividedBy

HCVector3.prototype.scaledBy = function(scalar) {
  var x = this.x * scalar;
  var y = this.y * scalar;
  var z = this.z * scalar;
  return new HCVector3(x, y, z);
}    // scaledBy

//
// vector operators
// 

HCVector3.prototype.dotProduct = function(vector) {
  return (this.x * vector.x) + (this.y * vector.y) + (this.z * vector.z);
}    // dotProduct

HCVector3.prototype.crossProduct = function(vector) {
  var x = (this.y * vector.z) - (this.z * vector.y);
  var y = (this.z * vector.x) - (this.x * vector.z);
  var z = (this.x * vector.y) - (this.y * vector.x);
  return new HCVector3(x, y, z);
}    // crossProduct

HCVector3.prototype.parallel = function(vector) {
  var denominator = vector.dotProduct(vector);
  if (denominator != 0)
    return vector.scaledBy(this.dotProduct(vector) / denominator);
  else
    return this;
}	// parallel

HCVector3.prototype.perpendicular = function(vector) {
  return this.minus(this.parallel(vector));
}	// perpendicular

HCVector3.prototype.length = function() {
  return Math.sqrt(this.dotProduct(this));
}	// length

//
// rotation methods
//
HCVector3.prototype.rotateBy = function(angle, axis) {
  var length = axis.length();
    
  if (length != 0) {
    var xAxis = this.perpendicular(axis);
    var yAxis = (axis.crossProduct(xAxis)).scaledBy(1 / length);
    var zAxis = this.parallel(axis);
    var x = Math.cos(angle * Math.PI/180);
    var y = Math.sin(angle * Math.PI/180);
	var xAxis2 = xAxis.scaledBy(x);
	var yAxis2 = yAxis.scaledBy(y);
    var vector = (xAxis2.plus(yAxis2)).plus(zAxis);
	this.x = vector.x;
	this.y = vector.y;
	this.z = vector.z;
  };
}	// rotateBy

HCVector3.prototype.rotatedBy = function(angle, axis) {
  var length = axis.length();
    
  if (length != 0) {
    var xAxis = this.perpendicular(axis);
    var yAxis = (axis.crossProduct(xAxis)).scaledBy(1 / length);
    var zAxis = this.parallel(axis);
    var x = Math.cos(angle * Math.PI/180);
    var y = Math.sin(angle * Math.PI/180);
	var xAxis2 = xAxis.scaledBy(x);
	var yAxis2 = yAxis.scaledBy(y);	
    return (xAxis2.plus(yAxis2)).plus(zAxis);
  } else
    return this;
}	// rotatedBy
