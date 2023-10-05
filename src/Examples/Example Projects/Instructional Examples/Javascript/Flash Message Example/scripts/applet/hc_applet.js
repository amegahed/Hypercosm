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
  this.index = HCApplet.appletCount;
  this.id = "HCApplet" + this.index;
  
  // first, send id of applet element
  //
  this.commandLine = "-id " + this.id + "; " + commandLine;
	
  // store reference to applet
  //
  HCApplet.appletArray[HCApplet.appletCount] = this;
  HCApplet.appletIndexArray[this.id] = HCApplet.appletCount;
  HCApplet.appletCount++;
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

/***************************************************************\
|                     applet ActiveX activation                 |
|***************************************************************|
|                                                               |
|        This activate method is called automatically by        |
|        the constructor to cause the applet to start up.       |
|                                                               |
|        Although applets can be added to a web page without    |
|        using Javascript, this method is preferred because     |
|        following Microsoft's loss to the Eolas patent,        |
|        inline ActiveX objects now have to be clicked on to    |
|        be activated.                                          |
|                                                               |
|        This javascript avoids that issue and allows the       |
|        applets to become active as soon as the web page is    |
|        is loaded. (when the applet constructor is called).    |
|        Simply call the applet constructor above and the       |
|        applet will automatically start up and run.            |
|                                                               |
|        Applets should call the onActivate() function          |
|        when they start up in order to notify their            |
|        Javascript wrappers that the applet has started        |
|        and is ready to be used.                               |
|                                                               |
\***************************************************************/

//
// activation methods
//
  
  
HCApplet.prototype.activate = function() {
	
  function getResourcesString(resources) {
    var string = "";
    if (resources)
      for (var counter = 0; counter < resources.length; counter++) {
        string += "'" + resources[counter] + "'";
        if (counter < resources.length)
          string += "; ";
      }
    return string;
  }
  
  // create Internet Explorer Control
  //
  if (internetExplorer) {
    var params = new Array();
    params[0] = ["AppletSrc", this.appletSrc];
    params[1] = ["CommandLine", this.commandLine];
    params[2] = ["Resources", getResourcesString(this.resources)];
    this.plugIn = createIEControl(this.element, "CLSID:34B8892A-9303-4893-9E12-1CEE6C3BF95D",
      this.id, this.element.style.width, this.element.style.height, params);
  // create Mozilla Firefox Control
  //
  } else {
    var params = new Array();
    params[0] = ["name", this.id];
    params[1] = ["type", "application/x-hypercosm"];
    params[2] = ["width", this.element.style.width.toString()];
    params[3] = ["height", this.element.style.height.toString()];
    params[4] = ["appletsrc", this.appletSrc];
    params[5] = ["commandline", this.commandLine];
    params[6] = ["resources", getResourcesString(this.resources)];
    this.plugIn = createMozillaControl(this.element, this.id, params);
  }
}	// activate

HCApplet.prototype.onActivate = function() {
  // this method is called by the applet when the applet starts up
  //
}	// onActivate

HCApplet.prototype.isActivated = function() {
  return (this.plugIn != null);
}	// isActivated

//
// method for invoking scripts on applet
//

HCApplet.prototype.call = function(script) {
  if (script)
    eval.call(this, script);
}	// call

//
// "class" or "static" methods
//

HCApplet.getAppletById = function(id) {
  return this.getAppletByIndex(HCApplet.appletIndexArray[id]);
}	// getAppletById

HCApplet.getAppletByIndex = function(index) {
  return HCApplet.appletArray[index];
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

HCApplet.appletCount = 0;
HCApplet.appletArray = new Array();
HCApplet.appletIndexArray = new Array();