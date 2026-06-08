'use strict';

goog.provide('Blockly.CSharp.logic');

goog.require('Blockly.CSharp');
goog.require('Blockly.Blocks');
goog.require('Blockly.Block');
goog.require('Blockly.CustomConfig');

Blockly.CSharp['controls_if'] = function(block) {
  // If/elseif/else condition.
    var n = 0;
    var code = '',  branchCode, conditionCode;
    var check = false;
    do{
        conditionCode = Blockly.CSharp.valueToCode(block,'IF' + n,
            Blockly.CSharp.ORDER_NONE) ;
        if(!conditionCode) {
          check = true;
          conditionCode = 'false';
        }
        branchCode = Blockly.CSharp.statementToCode(block,'DO' + n);
        code += (n > 0 ? 'else ': '')+
            'if (' +
            Blockly.CustomConfig.CSharpBoolLineFunction + '(' +
            conditionCode + ',' +
            Blockly.CustomConfig.CSharpCode_ProgramLineName + ',' +
            Blockly.CustomConfig.CSharpCode_bIsfunOrdefName + ')' +
            ') {' +
            //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
            '\n' + branchCode + '}';
        ++n;
    }while (block.getInput('IF' + n));
    if(block.getInput('ELSE')){
        branchCode=Blockly.CSharp.statementToCode(block,'ELSE');
        code += 'else {' +
            //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
            '\n' + branchCode + '}';
    }
    if(check)
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      Blockly.CSharp.workspaceToCodeError = true;
      block.setWarningText("判断输入模块不能为空!");
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
      block.setWarningText(null);
    }
    return code +'\n';
};

Blockly.CSharp['controls_ifelse'] = Blockly.CSharp['controls_if'];

Blockly.CSharp['logic_compare'] = function(block) {
    // Comparison operator.
    var OPERATORS = {
        'EQ': '==',
        'NEQ': '!=',
        'LT': '<',
        'LTE': '<=',
        'GT': '>',
        'GTE': '>='
    };
    var operator = OPERATORS[block.getFieldValue('OP')];
    var order = (operator == '==' || operator == '!=') ?
        Blockly.CSharp.ORDER_EQUALITY : Blockly.CSharp.ORDER_RELATIONAL;
    var argument0 = Blockly.CSharp.valueToCode(block, 'A', order);
    var IsEmptyCheck =false;
    if(!argument0) {
      IsEmptyCheck = true;
      argument0 = 'null';
    }

    var argument1 = Blockly.CSharp.valueToCode(block, 'B', order) ;
    if(!argument1) {
      IsEmptyCheck = true;
      argument1 = 'null';
    }

    var code = argument0 + ' ' + operator + ' ' + argument1;
    var IsConnectCheck = false;
    if(!block.parentBlock_ )
    {
      IsConnectCheck = true;
    }


  if(IsEmptyCheck || IsConnectCheck) {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrString ="";
    if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\r\n";
    if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\r\n";
    block.setWarningText(ErrString);
  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    block.setWarningText(null);
  }
    return [code, order];
};

Blockly.CSharp['logic_operation'] = function(block) {
  // Operations 'and', 'or'.
    var operator = (block.getFieldValue('OP') == 'AND') ? '&&' : '||';
    var order = (operator == '&&') ? Blockly.CSharp.ORDER_LOGICAL_AND :
        Blockly.CSharp.ORDER_LOGICAL_OR;
    var argument0 = Blockly.CSharp.valueToCode(block, 'A', order);
    var IsEmptyCheck = false;
    if(!argument0) {
      IsEmptyCheck = true;
    }

    var argument1 = Blockly.CSharp.valueToCode(block, 'B', order);
    if(!argument1) {
      IsEmptyCheck = true;
    }
    if (!argument0 && !argument1) {
        // If there are no arguments, then the return value is false.
        argument0 = 'false';
        argument1 = 'false';
    } else {
        // Single missing arguments have no effect on the return value.
        var defaultArgument = (operator == '&&') ? 'true' : 'false';
        if (!argument0) {
            argument0 = defaultArgument;
        }
        if (!argument1) {
            argument1 = defaultArgument;
        }
    }
    var code = argument0 + ' ' + operator + ' ' + argument1;
    var IsConnectCheck = false;
    if(!block.parentBlock_ )
    {
      IsConnectCheck = true;
    }

    if(IsEmptyCheck || IsConnectCheck)
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      Blockly.CSharp.workspaceToCodeError = true;
      var ErrString ="";
      if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\r\n";
      if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\r\n";
      block.setWarningText(ErrString);
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
      block.setWarningText(null);
    }
    return [code, order];
};

Blockly.CSharp['logic_negate'] = function(block) {
  // Negation.
  var order = Blockly.CSharp.ORDER_UNARY_PREFIX;//Blockly.CSharp.ORDER_LOGICAL_NOT
  var argument0 = Blockly.CSharp.valueToCode(block, 'BOOL', order) ;
  var IsEmptyCheck = false;
  if(!argument0) {
    IsEmptyCheck = true;
    argument0 =  'true';
  }
  var code = '!' + argument0;
  var IsConnectCheck = false;
  if(!block.parentBlock_ )
  {
    IsConnectCheck = true;
  }

  if(IsEmptyCheck || IsConnectCheck)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrString ="";
    if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\r\n";
    if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\r\n";
    block.setWarningText(ErrString);
  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    block.setWarningText(null);
  }
  return [code, order];
};

Blockly.CSharp['logic_boolean'] = function(block) {
  // Boolean values true and false.
  var code = (block.getFieldValue('BOOL') == 'TRUE') ? 'true' : 'false';

  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);

  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //Blockly.CSharp.workspaceToCodeError = false;
    block.setWarningText(null);
  }

  return [code, Blockly.CSharp.ORDER_ATOMIC];
};

Blockly.CSharp['logic_null'] = function(block) {
  // Null data type.
  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);

  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //Blockly.CSharp.workspaceToCodeError = false;
    block.setWarningText(null);
  }
  return ['null', Blockly.CSharp.ORDER_ATOMIC];
};

Blockly.CSharp['logic_ternary'] = function(block) {
  // Ternary operator.  a>b ? a : b 三元算子
  var value_if = Blockly.CSharp.valueToCode(block, 'IF',
      Blockly.CSharp.ORDER_CONDITIONAL) ;
  var IsEmptyCheck = false;
    if(!value_if) {
      IsEmptyCheck = true;
      value_if =  'false';
    }

  var value_then = Blockly.CSharp.valueToCode(block, 'THEN',
      Blockly.CSharp.ORDER_CONDITIONAL) || 'null';
  var value_else = Blockly.CSharp.valueToCode(block, 'ELSE',
      Blockly.CSharp.ORDER_CONDITIONAL) || 'null';
  var code = value_if + ' ? ' + value_then + ' : ' + value_else;

  var IsConnectCheck = false;
  if(!block.parentBlock_ )
  {
    IsConnectCheck = true;

  }

  if(IsEmptyCheck || IsConnectCheck)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrString ="";
    if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\r\n";
    if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\r\n";
    block.setWarningText(ErrString);
  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    block.setWarningText(null);
  }
  return [code, Blockly.CSharp.ORDER_CONDITIONAL];
};
