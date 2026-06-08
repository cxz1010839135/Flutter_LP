'use strict';

goog.provide('Blockly.CSharp.variables');

goog.require('Blockly.CSharp');

/**
Blockly.CSharp.variables = {};

Blockly.CSharp.variables_get = function() {
  // Variable getter.
  var code = Blockly.CSharp.variableDB_.getName(this.getTitleValue('VAR'),
      Blockly.Variables.NAME_TYPE);
  return [code, Blockly.CSharp.ORDER_ATOMIC];
};

Blockly.CSharp.variables_set = function() {
  // Variable setter.
  var argument0 = Blockly.CSharp.valueToCode(this, 'VALUE',
      Blockly.CSharp.ORDER_ASSIGNMENT) || 'null';
  var varName = Blockly.CSharp.variableDB_.getName(
      this.getTitleValue('VAR'), Blockly.Variables.NAME_TYPE);
  return varName + ' = ' + argument0 + ';\n';
};
 */

Blockly.CSharp['variables_get'] = function(block) {
    // Variable getter.
    var code = Blockly.CSharp.variableDB_.getName(block.getFieldValue('VAR'),
        Blockly.Variables.NAME_TYPE);
      if(!block.parentBlock_ )
      {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.CSharp.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);

      }
      else
      {
        block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
        block.setWarningText(null);
      }
    return [code, Blockly.CSharp.ORDER_ATOMIC];
};

Blockly.CSharp['variables_set'] = function(block) {
    // Variable setter.
    var argument0 = Blockly.CSharp.valueToCode(block, 'VALUE',
        Blockly.CSharp.ORDER_ASSIGNMENT);
    if(!argument0 || argument0 == "")
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      Blockly.CSharp.workspaceToCodeError = true;
      block.setWarningText("输入模块不能为空!");
      argument0 = '0';
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
      block.setWarningText(null);
    }
    var varName = Blockly.CSharp.variableDB_.getName(
        block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
    var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
        //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
        varName + ' = ' + argument0 + ';\n';
    //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
    return code;
};