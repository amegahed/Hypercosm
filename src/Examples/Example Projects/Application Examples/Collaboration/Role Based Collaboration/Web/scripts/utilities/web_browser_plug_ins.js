/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm       web_browser_plug_ins.js          3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file contains some javascript utilities that      |
|        are used to add web browser plug-ins to a page.        |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

function createIEControl(element, params) {
  // create new object node
  //
  var object = document.createElement("object");
  // set width and height
  //
  object.style.width = element.style.width;
  object.style.height = element.style.height;
  // set attributes
  //
  for (var param in params)
    //object.setAttribute(param, params[param]);
    object[param] = params[param];
  if (document.readyState == "complete") {
    // update DOM
    //
    if (element.parentNode)
      element.parentNode.replaceChild(object, element);
  } else {
    // set callback to update DOM after loading is complete
    //
    var self = element;
    document.attachEvent("onreadystatechange", function() {
      if (document.readyState == "complete")
        if (self.parentNode)
          self.parentNode.replaceChild(object, self);
    });
  }
  return object; 
}	// createIEControl

function createMozillaControl(element, params) {
  if (isSafari)
    return createSafariControl(element, params);
  // create new embed node
  //
  var embed = document.createElement("embed");
  // set width and height
  //
  embed.style.width = element.style.width;
  embed.style.height = element.style.height;
  embed.id = element.id;
  // set attributes
  //
  for (var param in params)
    embed.setAttribute(param, params[param]);
  // wait until element has been loaded to swap in element
  //
  self.interval = window.setInterval(function() {
    if (isElementLoaded(element)) {
      // end checking loop
      //
      window.clearInterval(self.interval);
      // swap node into DOM
      //
      if (element.parentNode)
        element.parentNode.replaceChild(embed, element);
    }
  }, 100);
  return embed;
}	// createMozillaControl

function createSafariControl(element, params) {
  // write embed begin tag
  //
  var HTML = "<embed";
  
  // add parameters
  //
  for (var param in params)
    HTML += " " + param + "=" + '"' + params[param] + '"';
  
  // write close of embed tag
  //
  HTML += ">";
  // add dynamic HTML to document element
  //
  element.innerHTML = HTML;
  
  return document[params["name"]];
}	// createSafariControl