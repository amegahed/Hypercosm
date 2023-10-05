/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm            hc_applet.js                3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file defines a Javascript function to add a       |
|        Hypercosm applet to a web page.                        |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

//
// "class" constructor
//

function HCApplet(element, appletSrc, resources, commandLine, parent) {
  if (!element)
    return this;
	
  // set defaults
  //
  if (commandLine == undefined)
    commandLine = "";
  if (parent == undefined)
    parent = null;
	
  // call superclass constructor
  //
  component.call(this, element, parent);
  
  // set applet attributes
  //
  this.appletSrc = appletSrc;
  this.resources = resources;
  this.commandLine = commandLine;
  this.plugIn = null;
  this.index = HCApplet.applets.length;
  this.id = "HCApplet" + this.index;
  
  // first, send id of applet element
  //
  this.commandLine = "-id " + this.id + "; " + commandLine;
	
  // store reference to applet
  //
  HCApplet.appletIndices[this.id] = HCApplet.applets.length;
  HCApplet.applets[HCApplet.applets.length] = this;
  // make this the current applet
  //
  HCApplet.setCurrentApplet(this);
  // activate ActiveX control
  //
  this.activate();
	
  return this;
}	// HCApplet

// inherit prototype from "superclass"
//
HCApplet.prototype = new component();

//
// "object" or "instance" methods
//
  
  
HCApplet.prototype.activate = function() {
	
  function getResourcesString(resources) {
    var string = "";
    if (resources)
      for (var i = 0; i < resources.length; i++) {
        string += "'" + resources[i] + "'";
        if (i < resources.length)
          string += "; ";
      }
    return string;
  }
  
  // create Internet Explorer Control
  //
  if (navigator.appName == "Microsoft Internet Explorer") {
    var params = new Array();
    params["id"] = this.id;
    params["classid"] = "clsid:34B8892A-9303-4893-9E12-1CEE6C3BF95D";
    params["AppletSrc"] = this.appletSrc;
    params["CommandLine"] = this.commandLine;
    params["Resources"] = getResourcesString(this.resources);
    this.plugIn = createIEControl(this.element, params);
  // create Mozilla Firefox / Safari Control
  //
  } else {
    var params = new Array();
    params["name"] = this.id;
    params["type"] = "application/x-hypercosm";
    params["width"] = this.element.style.width;
    params["height"] = this.element.style.height;
    params["appletsrc"] = this.appletSrc;
    params["commandline"] = this.commandLine;
    params["resources"] = getResourcesString(this.resources);
    params["browser"] = navigator.userAgent;
    this.plugIn = createMozillaControl(this.element, params);
  }
}	// activate

//
// this method is called by the applet when the applet starts up
//

HCApplet.prototype.onActivate = function() {
  // call user defined callback
  //
  if (this.onload)
    this.onload();
}	// onActivate

HCApplet.prototype.isActivated = function() {
  return (this.plugIn != null);
}	// isActivated

//
// method for invoking scripts on applet
//

HCApplet.prototype.call = function(script) {
  if (script)
    eval(script);
}	// call

//
// "class" or "static" methods
//

HCApplet.getAppletById = function(id) {
  return this.getAppletByIndex(HCApplet.appletIndices[id]);
}	// getAppletById

HCApplet.getAppletByIndex = function(index) {
  return HCApplet.applets[index];
}	// getAppletByIndex

HCApplet.setCurrentApplet = function(applet) {
  HCApplet.currentApplet = applet;
}	// setCurrentApplet

HCApplet.getCurrentApplet = function() {
  return HCApplet.currentApplet;
}	// getCurrentApplet

//
// "class" or "static" member variables
//

HCApplet.applets = new Array();
HCApplet.appletIndices = new Array();