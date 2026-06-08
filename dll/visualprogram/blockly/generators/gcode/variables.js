'use strict';

goog.provide('Blockly.GCode.variables');

goog.require('Blockly.GCode');

/**
Blockly.GCode.variables = {};

Blockly.GCode.variables_get = function() {
  // Variable getter.
  var code = Blockly.GCode.variableDB_.getName(this.getTitleValue('VAR'),
      Blockly.Variables.NAME_TYPE);
  return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode.variables_set = function() {
  // Variable setter.
  var argument0 = Blockly.GCode.valueToCode(this, 'VALUE',
      Blockly.GCode.ORDER_ASSIGNMENT) || 'null';
  var varName = Blockly.GCode.variableDB_.getName(
      this.getTitleValue('VAR'), Blockly.Variables.NAME_TYPE);
  return varName + ' = ' + argument0 + ';\n';
};
 */





Blockly.GCode['variables_get'] = function(block) {
    // Variable getter.
    var code = Blockly.GCode.variableDB_.getName(block.getFieldValue('VAR'),
        Blockly.Variables.NAME_TYPE);
      if(!block.parentBlock_ )
      {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);

      }
      else
      {
        block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
        block.setWarningText(null);
      }
    return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['variables_set'] = function(block) {
    // Variable setter.
    var argument0 = Blockly.GCode.valueToCode(block, 'VALUE',
        Blockly.GCode.ORDER_ASSIGNMENT);
    if(!argument0 || argument0 == "")
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      Blockly.GCode.workspaceToCodeError = true;
      block.setWarningText("输入模块不能为空!");
      argument0 = '0';
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
      block.setWarningText(null);
    }
    var varName = Blockly.GCode.variableDB_.getName(
        block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
    var argNum = parseInt(argument0);
    var code;
    if (isNaN(argNum)){
        code = varName + ' = ' + argument0 + '\n';
    }else {
        code = varName + ' = #' + argument0 + '\n';
    }
    return code;
};