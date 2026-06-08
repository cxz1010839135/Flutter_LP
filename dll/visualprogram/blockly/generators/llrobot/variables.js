'use strict';

goog.provide('Blockly.LLRobot.variables');

goog.require('Blockly.LLRobot');

/**
Blockly.LLRobot.variables = {};

Blockly.LLRobot.variables_get = function() {
  // Variable getter.
  var code = Blockly.LLRobot.variableDB_.getName(this.getTitleValue('VAR'),
      Blockly.Variables.NAME_TYPE);
  return [code, Blockly.LLRobot.ORDER_ATOMIC];
};

Blockly.LLRobot.variables_set = function() {
  // Variable setter.
  var argument0 = Blockly.LLRobot.valueToCode(this, 'VALUE',
      Blockly.LLRobot.ORDER_ASSIGNMENT) || 'null';
  var varName = Blockly.LLRobot.variableDB_.getName(
      this.getTitleValue('VAR'), Blockly.Variables.NAME_TYPE);
  return varName + ' = ' + argument0 + ';\n';
};
 */

Blockly.LLRobot['variables_get'] = function(block) {
    // Variable getter.
    // var code = Blockly.LLRobot.variableDB_.getName(block.getFieldValue('VAR'),
    //     Blockly.Variables.NAME_TYPE);
    var code = '(' + Blockly.CustomConfig.Variable_Prefix  + block.getFieldValue('VAR') + ')';

      // if(!block.parentBlock_ )
      // {
      //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      //   Blockly.LLRobot.workspaceToCodeError = true;
      //   block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);
      //
      // }
      // else
      // {
      //   block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
      //   block.setWarningText(null);
      // }
    return [code, Blockly.LLRobot.ORDER_ATOMIC];
};

Blockly.LLRobot['variables_set'] = function(block) {
    // Variable setter.
    var argument0 = Blockly.LLRobot.valueToCode(block, 'VALUE',
        Blockly.LLRobot.ORDER_ASSIGNMENT);
    // if(!argument0 || argument0 == "")
    // {
    //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    //   Blockly.LLRobot.workspaceToCodeError = true;
    //   block.setWarningText("输入模块不能为空!");
    //   argument0 = '0';
    // }
    // else
    // {
    //   block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
    //   block.setWarningText(null);
    // }
    // var varName = Blockly.LLRobot.variableDB_.getName(
    //     block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
    var varName = '(' + Blockly.CustomConfig.Variable_Prefix + block.getFieldValue('VAR') + ')';
    //var varName = block.getFieldValue('VAR');
    return varName + ' = ' + argument0 + ';\n';
};