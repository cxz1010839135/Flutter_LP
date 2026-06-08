'use strict';

goog.provide('Blockly.GCode.logic');

goog.require('Blockly.GCode');
goog.require('Blockly.Blocks');
goog.require('Blockly.Block');
goog.require('Blockly.CustomConfig');

Blockly.GCode['controls_if'] = function(block) {
  // If/elseif/else condition.
    var n = 0;
    var code = '',  branchCode, conditionCode;
    var check = false;
    do{
        conditionCode = Blockly.GCode.valueToCode(block,'IF' + n,
            Blockly.GCode.ORDER_NONE) ;
        if(!conditionCode) {
          check = true;
          conditionCode = 'false';
        }
        branchCode = Blockly.GCode.statementToCode(block,'DO' + n);
        code += (n > 0 ? 'else ': '') +
            'if (' + conditionCode + ') {' +
            '\n' + branchCode + '} ';
        ++n;
    }while (block.getInput('IF' + n));
    if(block.getInput('ELSE')){
        branchCode=Blockly.GCode.statementToCode(block,'ELSE');
        code += '\n' + 'else {' + '\n' + branchCode + '}';
    }
    if(check)
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      Blockly.GCode.workspaceToCodeError = true;
      block.setWarningText("判断输入模块不能为空!");
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
      block.setWarningText(null);
    }
    return code +'\n';
};

Blockly.GCode['controls_ifelse'] = Blockly.GCode['controls_if'];

Blockly.GCode['logic_compare'] = function(block) {
    // Comparison operator.
    var OPERATORS = {
        'EQ': '==',
        'NEQ': '<>',
        'LT': '<',
        'LTE': '<=',
        'GT': '>',
        'GTE': '>='
    };
    var operator = OPERATORS[block.getFieldValue('OP')];
    var order = (operator == '==' || operator == '<>') ?
        Blockly.GCode.ORDER_EQUALITY : Blockly.GCode.ORDER_RELATIONAL;
    var argument0 = Blockly.GCode.valueToCode(block, 'A', order);
    var IsEmptyCheck =false;
    if(!argument0) {
      IsEmptyCheck = true;
      argument0 = 'null';
    }

    var argument1 = Blockly.GCode.valueToCode(block, 'B', order) ;
    if(!argument1) {
      IsEmptyCheck = true;
      argument1 = 'null';
    }

    var argNum0 = parseInt(argument0);
    if (!isNaN(argNum0)){
        argument0 = '#'+argument0;
    }
    var argNum1 = parseInt(argument1);
    if (!isNaN(argNum1)){
        argument1 = '#'+argument1;
    }

    var code = argument0 + ' ' + operator + ' ' + argument1;
    var IsConnectCheck = false;
    if(!block.parentBlock_ )
    {
      IsConnectCheck = true;
    }


  if(IsEmptyCheck || IsConnectCheck) {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.GCode.workspaceToCodeError = true;
    var ErrString ="";
    if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\n";
    if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
    block.setWarningText(ErrString);
  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    block.setWarningText(null);
  }
    return [code, order];
};

Blockly.GCode['logic_operation'] = function(block) {
  // Operations 'and', 'or'.
    var operator = (block.getFieldValue('OP') == 'AND') ? '&&' : '||';
    var order = (operator == '&&') ? Blockly.GCode.ORDER_LOGICAL_AND :
        Blockly.GCode.ORDER_LOGICAL_OR;
    var argument0 = Blockly.GCode.valueToCode(block, 'A', order);
    var IsEmptyCheck = false;
    if(!argument0) {
      IsEmptyCheck = true;
    }

    var argument1 = Blockly.GCode.valueToCode(block, 'B', order);
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
    var code = '( ' + argument0 + ' ) ' + operator + ' ( ' + argument1 + ' ) ';
    var IsConnectCheck = false;
    if(!block.parentBlock_ )
    {
      IsConnectCheck = true;
    }

    if(IsEmptyCheck || IsConnectCheck)
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      Blockly.GCode.workspaceToCodeError = true;
      var ErrString ="";
      if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\n";
      if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
      block.setWarningText(ErrString);
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
      block.setWarningText(null);
    }
    return [code, order];
};

Blockly.GCode['logic_operation_m'] = function(block) {
    var operator = (block.getFieldValue('OP') == 'AND') ? '&&' : '||';
    var order = (operator == '&&') ? Blockly.GCode.ORDER_LOGICAL_AND :
        Blockly.GCode.ORDER_LOGICAL_OR;
    var precode="";
    var argument0 = Blockly.GCode.valueToCode(block, 'A', order);
    var IsEmptyCheck = false;
    if(!argument0) {
        IsEmptyCheck = true;
    }
    var tmp = argument0.split('\n');
    if (tmp.length>=2){
        precode += tmp[0]+'\n';
        argument0 = tmp[1];
    }
    var argument1="";
    for (var i = 0; i < block.itemCount_; i++) {
        // Operations 'and', 'or'.
        if(i===0){
            var element = Blockly.GCode.valueToCode(block, 'ADD' + i,
                order);// || '0';

            if(!element || element == " " ||element == "") {
                IsEmptyCheck = true;
            }
            var tmp0 = element.split('\n');
            if (tmp0.length>=2){
                precode += tmp0[0]+'\n';
                argument1 += tmp0[1] + ' ';
            }
            else {
                argument1 += element + ' ';
            }
        }
        else {
            var operator1 = (block.getFieldValue('OP'+i) == 'AND') ? '&&' : '||';
            var order1 = (operator1 == '&&') ? Blockly.GCode.ORDER_LOGICAL_AND :
                Blockly.GCode.ORDER_LOGICAL_OR;
            var element1 = Blockly.GCode.valueToCode(block, 'ADD' + i,
                order1);// || '0';

            if(!element1 || element1 == " " ||element1 == "") {
                IsEmptyCheck = true;
            }
            var tmp1 = element1.split('\n');
            if (tmp1.length>=2){
                precode += tmp1[0]+'\n';
                argument1 += operator1 + ' '+ tmp1[1] + ' ';
            }
            else {
                argument1 += operator1 + ' '+ element1 + ' ';
            }
        }
    }
    if(!argument1 || argument1 == " " ) {
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
    var code = precode + argument0 + ' ' + operator + ' ' +argument1;
    var IsConnectCheck = false;
    if(!block.parentBlock_ )
    {
        IsConnectCheck = true;
    }

    if(IsEmptyCheck || IsConnectCheck)
    {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        var ErrString ="";
        if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\n";
        if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
        block.setWarningText(ErrString);
    }
    else
    {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
    }
    return [code, order];
};

Blockly.GCode['logic_operation_m_vertical'] = function(block) {
    var operator = (block.getFieldValue('OP') == 'AND') ? '&&' : '||';
    var order = (operator == '&&') ? Blockly.GCode.ORDER_LOGICAL_AND :
        Blockly.GCode.ORDER_LOGICAL_OR;
    var precode="";
    var argument0 = Blockly.GCode.valueToCode(block, 'A', order);
    var IsEmptyCheck = false;
    if(!argument0) {
        IsEmptyCheck = true;
    }
    var tmp = argument0.split('\n');
    if (tmp.length>=2){
        precode += tmp[0]+'\n';
        argument0 = tmp[1];
    }
    var argument1="";
    for (var i = 0; i < block.itemCount_; i++) {
        // Operations 'and', 'or'.
        if(i===0){
            var element = Blockly.GCode.valueToCode(block, 'ADD' + i,
                order);// || '0';

            if(!element || element == " " ||element == "") {
                IsEmptyCheck = true;
            }
            var tmp0 = element.split('\n');
            if (tmp0.length>=2){
                precode += tmp0[0]+'\n';
                argument1 += tmp0[1] + ' ';
            }
            else {
                argument1 += element + ' ';
            }
        }
        else {
            var operator1 = (block.getFieldValue('OP'+i) == 'AND') ? '&&' : '||';
            var order1 = (operator1 == '&&') ? Blockly.GCode.ORDER_LOGICAL_AND :
                Blockly.GCode.ORDER_LOGICAL_OR;
            var element1 = Blockly.GCode.valueToCode(block, 'ADD' + i,
                order1);//|| '0';
            if(!element1 || element1 == " " ||element1 == "") {
                   IsEmptyCheck = true;
            }
            var tmp1 = element1.split('\n');
            if (tmp1.length>=2){
                precode += tmp1[0]+'\n';
                argument1 += operator1 + ' '+ tmp1[1] + ' ';
            }
            else {
                argument1 += operator1 + ' '+ element1 + ' ';
            }
        }
    }
    if(!argument1 || argument1 == " " ) {
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
    var code = precode + '( ' + argument0 + ' ' + operator + ' ' +argument1 + ')';
    var IsConnectCheck = false;
    if(!block.parentBlock_ )
    {
        IsConnectCheck = true;
    }

    if(IsEmptyCheck || IsConnectCheck)
    {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        var ErrString ="";
        if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\n";
        if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
        block.setWarningText(ErrString);
    }
    else
    {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
    }
    return [code, order];
};



Blockly.GCode['logic_boolean'] = function(block) {
  // Boolean values true and false.
  var code = (block.getFieldValue('BOOL') == 'TRUE') ? 'true' : 'false';

  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.GCode.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);

  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //Blockly.GCode.workspaceToCodeError = false;
    block.setWarningText(null);
  }

  return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['logic_null'] = function(block) {
  // Null data type.
  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.GCode.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);

  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //Blockly.GCode.workspaceToCodeError = false;
    block.setWarningText(null);
  }
  return ['null', Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['logic_ternary'] = function(block) {
  // Ternary operator.  a>b ? a : b 三元算子
  var value_if = Blockly.GCode.valueToCode(block, 'IF',
      Blockly.GCode.ORDER_CONDITIONAL) ;
  var IsEmptyCheck = false;
    if(!value_if) {
      IsEmptyCheck = true;
      value_if =  'false';
    }

  var value_then = Blockly.GCode.valueToCode(block, 'THEN',
      Blockly.GCode.ORDER_CONDITIONAL) || 'null';
  var value_else = Blockly.GCode.valueToCode(block, 'ELSE',
      Blockly.GCode.ORDER_CONDITIONAL) || 'null';
  var code = value_if + ' ? ' + value_then + ' : ' + value_else;

  var IsConnectCheck = false;
  if(!block.parentBlock_ )
  {
    IsConnectCheck = true;

  }

  if(IsEmptyCheck || IsConnectCheck)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.GCode.workspaceToCodeError = true;
    var ErrString ="";
    if(IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\n";
    if(IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
    block.setWarningText(ErrString);
  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    block.setWarningText(null);
  }
  return [code, Blockly.GCode.ORDER_CONDITIONAL];
};
