/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm         web_browser_utils.js           3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file contains some javascript utilities that      |
|        are used to work with the web browser.                 |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

//
// event handling 
//

function addEvent(object, eventType, eventHandler) { 
  if (object.addEventListener) {
    object.addEventListener(eventType, eventHandler, false); 
    return true; 
  } else if (object.attachEvent) 
    return object.attachEvent("on" + eventType, eventHandler); 
  else
    return false;
}    // addEvent

//
// DOM searching method
//

function getElementById(id, parent) {
	
  // if no parent is specified, then use document
  //
  if (!parent)
    return document.getElementById(id);
  // get parent node
  //
  if (typeof(parent) == "string")
    var root = document.getElementById(parent);
  else
    var root = parent;
  // check parent node
  //
  if (root.id == id)
    return root;
  
  // recursively search children for id
  //
  var child = root.firstChild;
  while (child) {
    if (child.id == id)
      return child;
    else {
      var element = getElementById(id, child);
      if (element)
        return element;
    }
    child = child.nextSibling;
  }
  
  return undefined;
}	// getElementById

function getElementAttribute(element, name) {
  var HTML = element.outerHTML.substring(1, element.outerHTML.length - 1);
  var vars = HTML.split(" ");
  for (var i = 0; i < vars.length; i++) {
    var pair = vars[i].split("=");
    if (pair[0] == name) {
      return pair[1];
    }
  }  
}	// getElementAttribute

function isElementLoaded(element) {
  if (element.offsetWidth > 0 && element.offsetHeight > 0)
    return true;
  else if (element.width > 0 && element.height > 0)
    return true;
  else
    return false;
}	// isElementLoaded
  
  
//
// image manipulation methods
//

function swapImage(image, src) {
  var suffix = src.substring(src.length - 3, src.length);
  if (((suffix == "png") || (suffix == "PNG")) && (typeof(swapPNG) != "undefined"))
    swapPNG(image, src);
  else
    image.src = src;
}    // swapImage

function getImageSrc(element) {
  if (element.src)
    return element.src;
  else
    return element.filters(0).src;
}	// getImageSrc

//
// window methods
//

function getWindowWidth() {
  if (document.body.offsetWidth)
    return document.body.offsetWidth;	// IE
  else
    return window.innerWidth;		// Mozilla
}	// getWindowWidth

function getWindowHeight() {
  if (document.body.offsetHeight)
    return document.body.offsetHeight;	// IE
  else
    return window.innerHeight;		// Mozilla
}	// getWindowHeight

function setStatus(status) {
  window.status = status;
}    // setStatus

function clearStatus() {
  window.status = "";
}    // clearStatus

//
// window URL location address methods
//

function setWindowLocation(text) {
  window.top.location.href = text;
}    // setWindowLocation

function getWindowLocation() {
  return window.top.location.href;
}    // getWindowLocation

function getBaseLocation(location) {
  var strings = location.split("?");
  return strings[0];
}    // getBaseLocation

//
// popup window display methods
//

function openDialogBox(windowSrc, width, height) {
  var left = (screen.width - width) / 2;
  var top = (screen.height - height) / 2;
  var features = "resizeable=no, status=no, toolbar=no, menubar=no, location=no, scrollbars=no, directories=no, dialog=yes";
  var popup = window.open(windowSrc, "_blank", 
    "width=" + width + ", height=" + height + ", top=" + top + ", left=" + left + ", " + features);
  if (window.focus)
    popup.focus();
  return popup;
}	// openDialogBox

//
// cascading style sheet (CSS) querying methods
//

function getCSSStyle(rule) {
  for (i = 0; i < document.styleSheets.length; i++)
    if (document.styleSheets[i].rules) {
      for (j = 0; j < document.styleSheets[i].rules.length; j++) 
        if (document.styleSheets[i].rules[j].selectorText == rule)
          return document.styleSheets[i].rules[j].style;
    } else {
      for (j = 0; j < document.styleSheets[i].cssRules.length; j++) 
        if (document.styleSheets[i].cssRules[j].selectorText == rule)
          return document.styleSheets[i].cssRules[j].style;
    }
}	// getCSSStyle