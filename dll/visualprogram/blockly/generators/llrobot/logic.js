'use strict';

goog.provide('Blockly.LLRobot.logic');

goog.require('Blockly.LLRobot');
goog.require('Blockly.Blocks');
goog.require('Blockly.Block');
goog.require('Blockly.CustomConfig');

Blockly.LLRobot['controls_if'] = function(block) {
  // If/elseif/else condition.
    var n = 0;
    var code = '',  branchCode, conditionCode;
    //var check = false;
    do{
        conditionCode = Blockly.LLRobot.valueToCode(block,'IF' + n,
            Blockly.LLRobot.ORDER_NONE) ;
        if(!conditionCode) {
          //check = true;
          //conditionCode = 'false';
          conditionCode = Blockly.Msg.LOGIC_BOOLEAN_FALSE;
        }
        branchCode = Blockly.LLRobot.statementToCode(block,'DO' + n);
        code += (n > 0 ? Blockly.Msg.CONTROLS_IF_MSG_ELSE : '')+
            Blockly.Msg.CONTROLS_IF_MSG_IF +  '(' + conditionCode +') {\n'+branchCode+'}';
        ++n;
    }while (block.getInput('IF' + n));
    if(block.getInput('ELSE')){
        branchCode=Blockly.LLRobot.statementToCode(block,'ELSE');
        code += Blockly.Msg.CONTROLS_IF_MSG_ELSE + '{\n'+branchCode +'}';
    }
    // if(check)
    // {
    //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    //   Blockly.LLRobot.workspaceToCodeError = true;
    //   block.setWarningText("判断输入模块不能为空!");
    // }
    // else
    // {
    //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //   block.setWarningText(null);
    // }
    return code +'\n';
};

Blockly.LLRobot['controls_ifelse'] = Blockly.LLRobot['controls_if'];

Blockly.LLRobot['logic_compare'] = function(block) {
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
        Blockly.LLRobot.ORDER_EQUALITY : Blockly.LLRobot.ORDER_RELATIONAL;
    var argument0 = Blockly.LLRobot.valueToCode(block, 'A', order);
    //var IsEmptyCheck =false;
    // if(!argument0) {
    //   IsEmptyCheck = true;
    //   argument0 = 'null';
    // }

    var argument1 = Blockly.LLRobot.valueToCode(block, 'B', order) ;
    // if(!argument1) {
    //   IsEmptyCheck = true;
    //   argument1 = 'null';
    // }

    var code = argument0 + ' ' + operator + ' ' + argument1;
    // var IsConnectCheck = false;
    // if(!block.parentBlock_ )
    // {
    //   IsConnectCheck = true;
    // }


  // if(IsEmptyCheck || IsConnectCheck) {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrString ="";
  //   if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\r\n";
  //   if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\r\n";
  //   block.setWarningText(ErrString);
  // }
  // else
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
  //   block.setWarningText(null);
  // }
    return [code, order];
};

Blockly.LLRobot['logic_operation'] = function(block) {
  // Operations 'and', 'or'.
    var operator = (block.getFieldValue('OP') == 'AND') ? '&&' : '||';
    var codeoperator = (block.getFieldValue('OP') == 'AND') ? Blockly.Msg.LOGIC_OPERATION_AND : Blockly.Msg.LOGIC_OPERATION_OR;
    var order = (operator == '&&') ? Blockly.LLRobot.ORDER_LOGICAL_AND :
        Blockly.LLRobot.ORDER_LOGICAL_OR;
    var argument0 = Blockly.LLRobot.valueToCode(block, 'A', order);
    // var IsEmptyCheck = false;
    // if(!argument0) {
    //   IsEmptyCheck = true;
    // }

    var argument1 = Blockly.LLRobot.valueToCode(block, 'B', order);
    // if(!argument1) {
    //   IsEmptyCheck = true;
    // }
    if (!argument0 && !argument1) {
        // If there are no arguments, then the return value is false.
        // argument0 = 'false';
        // argument1 = 'false';
      argument0 = Blockly.Msg.LOGIC_BOOLEAN_FALSE ;
      argument1 = Blockly.Msg.LOGIC_BOOLEAN_FALSE ;
    } else {
        // Single missing arguments have no effect on the return value.
        var defaultArgument = (operator == '&&') ? Blockly.Msg.LOGIC_BOOLEAN_TRUE : Blockly.Msg.LOGIC_BOOLEAN_FALSE;
        if (!argument0) {
            argument0 = defaultArgument;
        }
        if (!argument1) {
            argument1 = defaultArgument;
        }
    }
    var code = argument0 + ' ' + operator + ' ' + argument1;
    // var IsConnectCheck = false;
    // if(!block.parentBlock_ )
    // {
    //   IsConnectCheck = true;
    // }
    //
    // if(IsEmptyCheck || IsConnectCheck)
    // {
    //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    //   Blockly.LLRobot.workspaceToCodeError = true;
    //   var ErrString ="";
    //   if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\r\n";
    //   if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\r\n";
    //   block.setWarningText(ErrString);
    // }
    // else
    // {
    //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //   block.setWarningText(null);
    // }
    return [code, order];
};

Blockly.LLRobot['logic_negate'] = function(block) {
  // Negation.
  var order = Blockly.LLRobot.ORDER_UNARY_PREFIX;//Blockly.LLRobot.ORDER_LOGICAL_NOT
  var argument0 = Blockly.LLRobot.valueToCode(block, 'BOOL', order) ;
  //var IsEmptyCheck = false;
  // if(!argument0) {
  //   IsEmptyCheck = true;
  //   argument0 =  'true';
  // }
  //var code = '!' + argument0;
  var code = '!' + argument0;
  // var IsConnectCheck = false;
  // if(!block.parentBlock_ )
  // {
  //   IsConnectCheck = true;
  // }

  // if(IsEmptyCheck || IsConnectCheck)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrString ="";
  //   if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\r\n";
  //   if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\r\n";
  //   block.setWarningText(ErrString);
  // }
  // else
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
  //   block.setWarningText(null);
  // }
  return [code, order];
};

Blockly.LLRobot['logic_boolean'] = function(block) {
  // Boolean values true and false.
  var code = (block.getFieldValue('BOOL') == 'TRUE') ? Blockly.Msg.LOGIC_BOOLEAN_TRUE : Blockly.Msg.LOGIC_BOOLEAN_FALSE;

  // if(!block.parentBlock_ )
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);
  //
  // }
  // else
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
  //   //Blockly.LLRobot.workspaceToCodeError = false;
  //   block.setWarningText(null);
  // }

  return [code, Blockly.LLRobot.ORDER_ATOMIC];
};

Blockly.LLRobot['logic_null'] = function(block) {
  // Null data type.
  // if(!block.parentBlock_ )
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);
  //
  // }
  // else
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
  //   //Blockly.LLRobot.workspaceToCodeError = false;
  //   block.setWarningText(null);
  // }
  return [Blockly.Msg.LOGIC_NULL, Blockly.LLRobot.ORDER_ATOMIC];
};

Blockly.LLRobot['logic_ternary'] = function(block) {
  // Ternary operator.  a>b ? a : b 三元算子
  var value_if = Blockly.LLRobot.valueToCode(block, 'IF',
      Blockly.LLRobot.ORDER_CONDITIONAL) ;
  // var IsEmptyCheck = false;
  //   if(!value_if) {
  //     IsEmptyCheck = true;
  //     value_if =  'false';
  //   }

  var value_then = Blockly.LLRobot.valueToCode(block, 'THEN',
      Blockly.LLRobot.ORDER_CONDITIONAL) || Blockly.Msg.LOGIC_NULL;
  var value_else = Blockly.LLRobot.valueToCode(block, 'ELSE',
      Blockly.LLRobot.ORDER_CONDITIONAL) || Blockly.Msg.LOGIC_NULL;
  var code = value_if + ' ? ' + value_then + ' : ' + value_else;

  // var IsConnectCheck = false;
  // if(!block.parentBlock_ )
  // {
  //   IsConnectCheck = true;
  //
  // }

  // if(IsEmptyCheck || IsConnectCheck)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrString ="";
  //   if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\r\n";
  //   if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\r\n";
  //   block.setWarningText(ErrString);
  // }
  // else
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
  //   block.setWarningText(null);
  // }
  return [code, Blockly.LLRobot.ORDER_CONDITIONAL];
};
