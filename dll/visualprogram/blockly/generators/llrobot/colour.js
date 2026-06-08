'use strict';
goog.provide('Blockly.LLRobot.colour');

goog.require('Blockly.LLRobot');

Blockly.LLRobot['colour_picker'] = function(block) {
    // Colour picker.
    var code = '\'' + block.getFieldValue('COLOUR') + '\'';
    //var code = 'ColorTranslator.FromHtml("' + block.getTitleValue('COLOUR') + '")';
    return [code, Blockly.LLRobot.ORDER_ATOMIC];
};

Blockly.LLRobot['colour_random'] = function(block){
  // Generate a random colour.
  if (!Blockly.LLRobot.definitions_['colour_random']) {
    var functionName = Blockly.LLRobot.variableDB_.getDistinctName(
        'colour_random', Blockly.Generator.NAME_TYPE);
    Blockly.LLRobot.colour_random.functionName = functionName;
    var func = [];
    func.push('var ' + functionName + ' = new Func<Color>(() => {');
    func.push('  var random = new Random();');
    func.push('  var res = Color.FromArgb(1, random.Next(256), random.Next(256), random.Next(256));');
    func.push('  return res;');
    func.push('});');
    Blockly.LLRobot.definitions_['colour_random'] = func.join('\n');
  }
  var code = Blockly.LLRobot.colour_random.functionName + '()';
  return [code, Blockly.LLRobot.ORDER_UNARY_POSTFIX];//Blockly.LLRobot.ORDER_FUNCTION_CALL
};

Blockly.LLRobot['colour_rgb'] = function(block) {
  // Compose a colour from RGB components expressed as percentages.
  var red = Blockly.LLRobot.valueToCode(block, 'RED',
      Blockly.LLRobot.ORDER_NONE) || 0;//Blockly.LLRobot.ORDER_COMMA
  var green = Blockly.LLRobot.valueToCode(block, 'GREEN',
      Blockly.LLRobot.ORDER_NONE) || 0;//Blockly.LLRobot.ORDER_COMMA
  var blue = Blockly.LLRobot.valueToCode(block, 'BLUE',
      Blockly.LLRobot.ORDER_NONE) || 0;//Blockly.LLRobot.ORDER_COMMA

  if (!Blockly.LLRobot.definitions_['colour_rgb']) {
    var functionName = Blockly.LLRobot.variableDB_.getDistinctName(
        'colour_rgb', Blockly.Generator.NAME_TYPE);
    Blockly.LLRobot.colour_rgb.functionName = functionName;
    var func = [];
    func.push('var ' + functionName + ' = new Func<dynamic, dynamic, dynamic, Color>((r, g, b) => {');
    func.push('  r = (int)Math.Round(Math.Max(Math.Min((int)r, 100), 0) * 2.55);');
    func.push('  g = (int)Math.Round(Math.Max(Math.Min((int)g, 100), 0) * 2.55);');
    func.push('  b = (int)Math.Round(Math.Max(Math.Min((int)b, 100), 0) * 2.55);');
    func.push('  var res = Color.FromArgb(1, r, g, b);');
    func.push('  return res;');
    func.push('});');
    Blockly.LLRobot.definitions_['colour_rgb'] = func.join('\n');
  }
  var code = Blockly.LLRobot.colour_rgb.functionName +
      '(' + red + ', ' + green + ', ' + blue + ')';
  return [code, Blockly.LLRobot.ORDER_UNARY_POSTFIX];//Blockly.LLRobot.ORDER_FUNCTION_CALL
};

Blockly.LLRobot['colour_blend'] = function(block) {
  // Blend two colours together.
  var c1 = Blockly.LLRobot.valueToCode(block, 'COLOUR1',
      Blockly.LLRobot.ORDER_NONE) || 'Color.Black';//Blockly.LLRobot.ORDER_COMMA
  var c2 = Blockly.LLRobot.valueToCode(block, 'COLOUR2',
      Blockly.LLRobot.ORDER_NONE) || 'Color.Black';//Blockly.LLRobot.ORDER_COMMA
  var ratio = Blockly.LLRobot.valueToCode(block, 'RATIO',
      Blockly.LLRobot.ORDER_NONE) || 0.5;//Blockly.LLRobot.ORDER_COMMA

  if (!Blockly.LLRobot.definitions_['colour_blend']) {
    var functionName = Blockly.LLRobot.variableDB_.getDistinctName(
        'colour_blend', Blockly.Generator.NAME_TYPE);
    Blockly.LLRobot.colour_blend.functionName = functionName;
    var func = [];
    func.push('var ' + functionName + ' = new Func<Color, Color, double, Color>((c1, c2, ratio) => {');
    func.push('  ratio = Math.Max(Math.Min((double)ratio, 1), 0);');
    func.push('  var r = (int)Math.Round(c1.R * (1 - ratio) + c2.R * ratio);');
    func.push('  var g = (int)Math.Round(c1.G * (1 - ratio) + c2.G * ratio);');
    func.push('  var b = (int)Math.Round(c1.B * (1 - ratio) + c2.B * ratio);');
    func.push('  var res = Color.FromArgb(1, r, g, b);');
    func.push('  return res;');
    func.push('});');
    Blockly.LLRobot.definitions_['colour_blend'] = func.join('\n');
  }
  var code = Blockly.LLRobot.colour_blend.functionName +
      '(' + c1 + ', ' + c2 + ', ' + ratio + ')';
  return [code, Blockly.LLRobot.ORDER_UNARY_POSTFIX];//Blockly.LLRobot.ORDER_FUNCTION_CALL
};
