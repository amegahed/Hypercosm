/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm             component.js               3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file defines the Javascript behaviors of a        |
|        generalized user interface component.                  |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

//
// "class" constructor
//

function component(element, parent) {
  if (!element)
    return this;
  
  // the element parameter can refer to a document
  // element object or it can refer to its id
  //
  if (typeof(element) == "string") {
    if (parent) {
      if (parent.element)
        this.element = getElementById(element, parent.element);
	  else
	    this.element = getElementById(element, parent);
	} else
      this.element = document.getElementById(element);
  } else
    this.element = element;
	
  // set attributes
  //
  this.visible = (element != null);
  
  // add component to parent
  //
  if (parent && parent.addComponent)
    parent.addComponent(this);
  
  return this;
}    // componennt

//
// "object" or "instance" methods
//

component.prototype.getWidth = function() {
  if (this.element)
    return this.element.offsetWidth;
  else
    return 0;
}    // getWidth

component.prototype.getHeight = function() {
  if (this.element)
    return this.element.offsetHeight;
  else
    return 0;
}    // getHeight

//
// container visibility methods
//

component.prototype.setVisibility = function(visible) {
	
  // set attributes
  //
  this.visible = visible;
  // modify page element
  //
  if (this.element) {
    if (visible)
      this.element.style.display = 'block'; 
    else
      this.element.style.display = 'none'; 
  }
}	// setVisibility

component.prototype.getVisibility = function(visible) {
  return this.visible;
}	// getVisibility

component.prototype.toggleVisibility = function() {
  this.setVisibility(!this.getVisibility());
}	// toggleVisibility

