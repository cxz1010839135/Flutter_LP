'use strict';
goog.provide('Blockly.GCode.colour');

goog.require('Blockly.GCode');

Blockly.GCode['colour_picker'] = function(block) {
    // Colour picker.
    var code = '\'' + block.getFieldValue('COLOUR') + '\'';
    //var code = 'ColorTranslator.FromHtml("' + block.getTitleValue('COLOUR') + '")';
    return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['colour_random'] = function(block){
  // Generate a random colour.
  if (!Blockly.GCode.definitions_['colour_random']) {
    var functionName = Blockly.GCode.variableDB_.getDistinctName(
        'colour_random', Blockly.Generator.NAME_TYPE);
    Blockly.GCode.colour_random.functionName = functionName;
    var func = [];
    func.push('var ' + functionName + ' = new Func<Color>(() => {');
    func.push('  var random = new Random();');
    func.push('  var res = Color.FromArgb(1, random.Next(256), random.Next(256), random.Next(256));');
    func.push('  return res;');
    func.push('});');
    Blockly.GCode.definitions_['colour_random'] = func.join('\n');
  }
  var code = Blockly.GCode.colour_random.functionName + '()';
  return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
};

Blockly.GCode['colour_rgb'] = function(block) {
  // Compose a colour from RGB components expressed as percentages.
  var red = Blockly.GCode.valueToCode(block, 'RED',
      Blockly.GCode.ORDER_NONE) || 0;//Blockly.GCode.ORDER_COMMA
  var green = Blockly.GCode.valueToCode(block, 'GREEN',
      Blockly.GCode.ORDER_NONE) || 0;//Blockly.GCode.ORDER_COMMA
  var blue = Blockly.GCode.valueToCode(block, 'BLUE',
      Blockly.GCode.ORDER_NONE) || 0;//Blockly.GCode.ORDER_COMMA

  if (!Blockly.GCode.definitions_['colour_rgb']) {
    var functionName = Blockly.GCode.variableDB_.getDistinctName(
        'colour_rgb', Blockly.Generator.NAME_TYPE);
    Blockly.GCode.colour_rgb.functionName = functionName;
    var func = [];
    func.push('var ' + functionName + ' = new Func<dynamic, dynamic, dynamic, Color>((r, g, b) => {');
    func.push('  r = (int)Math.Round(Math.Max(Math.Min((int)r, 100), 0) * 2.55);');
    func.push('  g = (int)Math.Round(Math.Max(Math.Min((int)g, 100), 0) * 2.55);');
    func.push('  b = (int)Math.Round(Math.Max(Math.Min((int)b, 100), 0) * 2.55);');
    func.push('  var res = Color.FromArgb(1, r, g, b);');
    func.push('  return res;');
    func.push('});');
    Blockly.GCode.definitions_['colour_rgb'] = func.join('\n');
  }
  var code = Blockly.GCode.colour_rgb.functionName +
      '(' + red + ', ' + green + ', ' + blue + ')';
  return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
};

Blockly.GCode['colour_blend'] = function(block) {
  // Blend two colours together.
  var c1 = Blockly.GCode.valueToCode(block, 'COLOUR1',
      Blockly.GCode.ORDER_NONE) || 'Color.Black';//Blockly.GCode.ORDER_COMMA
  var c2 = Blockly.GCode.valueToCode(block, 'COLOUR2',
      Blockly.GCode.ORDER_NONE) || 'Color.Black';//Blockly.GCode.ORDER_COMMA
  var ratio = Blockly.GCode.valueToCode(block, 'RATIO',
      Blockly.GCode.ORDER_NONE) || 0.5;//Blockly.GCode.ORDER_COMMA

  if (!Blockly.GCode.definitions_['colour_blend']) {
    var functionName = Blockly.GCode.variableDB_.getDistinctName(
        'colour_blend', Blockly.Generator.NAME_TYPE);
    Blockly.GCode.colour_blend.functionName = functionName;
    var func = [];
    func.push('var ' + functionName + ' = new Func<Color, Color, double, Color>((c1, c2, ratio) => {');
    func.push('  ratio = Math.Max(Math.Min((double)ratio, 1), 0);');
    func.push('  var r = (int)Math.Round(c1.R * (1 - ratio) + c2.R * ratio);');
    func.push('  var g = (int)Math.Round(c1.G * (1 - ratio) + c2.G * ratio);');
    func.push('  var b = (int)Math.Round(c1.B * (1 - ratio) + c2.B * ratio);');
    func.push('  var res = Color.FromArgb(1, r, g, b);');
    func.push('  return res;');
    func.push('});');
    Blockly.GCode.definitions_['colour_blend'] = func.join('\n');
  }
  var code = Blockly.GCode.colour_blend.functionName +
      '(' + c1 + ', ' + c2 + ', ' + ratio + ')';
  return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
};
