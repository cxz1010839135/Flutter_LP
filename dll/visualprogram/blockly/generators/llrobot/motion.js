'use strict';

goog.provide("Blockly.LLRobot.motion");
goog.require("Blockly.LLRobot");
goog.require('Blockly.Blocks');
goog.require('Blockly.Block');
goog.require('Blockly.CustomConfig');




Blockly.LLRobot.ComPortList = [];

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['math_number_int'] = function(block) {
  // Numeric value.
  var code = (parseInt(block.getFieldValue('NUM')));//parseFloat
  var order;
  if (code == Infinity) {
    code = 'double.INFINITY';
    order = Blockly.LLRobot.ORDER_UNARY_POSTFIX;
  } else if (code == -Infinity) {
    code = '-double.INFINITY';
    order = Blockly.LLRobot.ORDER_UNARY_PREFIX;
  } else {
    // -4.abs() returns -4 in Dart due to strange order of operation choices.
    // -4 is actually an operator and a number.  Reflect this in the order.
    order = code < 0 ?
        Blockly.LLRobot.ORDER_UNARY_PREFIX : Blockly.LLRobot.ORDER_ATOMIC;
  }
  return [code, order];
};

Blockly.LLRobot['math_number_uint'] = function(block) {
  // Numeric value.
  var code = Math.abs(parseInt(block.getFieldValue('NUM')));//parseFloat
  var order;
  if (code == Infinity) {
    code = 'double.INFINITY';
    order = Blockly.LLRobot.ORDER_UNARY_POSTFIX;
  } else if (code == -Infinity) {
    code = '-double.INFINITY';
    order = Blockly.LLRobot.ORDER_UNARY_PREFIX;
  } else {
    // -4.abs() returns -4 in Dart due to strange order of operation choices.
    // -4 is actually an operator and a number.  Reflect this in the order.
    order = code < 0 ?
        Blockly.LLRobot.ORDER_UNARY_PREFIX : Blockly.LLRobot.ORDER_ATOMIC;
  }
  return [code, order];
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_movel_point'] = function(block) {
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';

  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);//不能为负数
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  // var pointError = null;
  // if(isNaN(value_pointvalue) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_pointvalue = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "P点直线定位方式函数转换出错,请检查坐标点编号是否正确;\r\n";
  //   pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR +"\r\n";
  // }
  // else
  // {
  //   if(value_pointvalue < 0 )//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_pointvalue = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "P点直线定位方式函数转换出错,请检查坐标点编号是否正确;\r\n";
  //     pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR +"\r\n";
  //   }
  //   else
  //   {
  //     if(Blockly.CustomConfig.DebugMode) {
  //       var check = bound.checkPointIsContain(value_pointvalue);
  //       if (check) {
  //         //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //         //block.setWarningText(null);
  //       }
  //       else {
  //         Blockly.LLRobot.workspaceToCodeError = true;
  //         pointError = Blockly.Msg.MOTION_ERROR_POINT_NOT_EXIST + value_pointvalue + "\r\n";
  //       }
  //     }
  //   }
  // }
  // var speedError = null;
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "P点直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   speedError = Blockly.Msg.MOTION_ENDSPEED + "\r\n";
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "P点直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     speedError = Blockly.Msg.MOTION_ENDSPEED + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  // if(!pointError && !speedError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   var ErrorCode = "";
  //   if(pointError) ErrorCode = ErrorCode + pointError;
  //   if(speedError) ErrorCode = ErrorCode + speedError;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(ErrorCode);
  // }
  var code = Blockly.Msg.MOTION_MOVEL + ' P( ' + value_pointvalue + ') ' +
      Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ');'+ '\n';//RobotType 预留机器人型号
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_movel_xyz'] = function(block) {
  var value_xvalue = Blockly.LLRobot.valueToCode(block, 'XValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_yvalue = Blockly.LLRobot.valueToCode(block, 'YValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_zvalue = Blockly.LLRobot.valueToCode(block, 'ZValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "XYZ直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "XYZ直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  //   }
  //   else
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     block.setWarningText(null);
  //   }
  // }
  var code = Blockly.Msg.MOTION_MOVEL + ' X( ' + value_xvalue + ') Y(' + value_yvalue + ') Z(' + value_zvalue + ') ' +
      Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ');'+ '\n';//RobotType 预留机器人型号
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_movel_joint'] = function(block) {
  var value_jvalue1 = Blockly.LLRobot.valueToCode(block, 'JValue1',
      Blockly.LLRobot.ORDER_ATOMIC) || '-90.0';
  var value_jvalue2 = Blockly.LLRobot.valueToCode(block, 'JValue2',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_jvalue3 = Blockly.LLRobot.valueToCode(block, 'JValue3',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_jvalue4 = Blockly.LLRobot.valueToCode(block, 'JValue4',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "关节角度直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "关节角度直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  //   }
  //   else
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     block.setWarningText(null);
  //   }
  // }
  var code = Blockly.Msg.MOTION_MOVEL+ ' J1( ' + value_jvalue1 + ') J2(' + value_jvalue2 + ') J3(' + value_jvalue3 + ') J4(' + value_jvalue4 + ') ' +
      Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ');'+ '\n';//RobotType 预留机器人型号
  return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_movel_point_offset'] = function(block) {
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.LLRobot.valueToCode(block,'OffSetX',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.LLRobot.valueToCode(block,'OffSetY',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.LLRobot.valueToCode(block,'OffSetZ',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  //var value_offsetw = Blockly.LLRobot.valueToCode(block,'OffSetW',
  //    Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  // var pointError = null;
  // if(isNaN(value_pointvalue) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_pointvalue = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "P点 加偏移量直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR +"\r\n";
  // }
  // else
  // {
  //   if(value_pointvalue < 0 )//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_pointvalue = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "P点 加偏移量直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR +"\r\n";
  //   }
  //   else
  //   {
  //     if(Blockly.CustomConfig.DebugMode) {
  //       var check = bound.checkPointIsContain(value_pointvalue);
  //       if (check) {
  //         //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //         //block.setWarningText(null);
  //       }
  //       else {
  //         Blockly.LLRobot.workspaceToCodeError = true;
  //         pointError = Blockly.Msg.MOTION_ERROR_POINT_NOT_EXIST + value_pointvalue + "\r\n";
  //       }
  //     }
  //   }
  // }
  //
  // var speedError = null;
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "P点 加偏移量直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "P点 加偏移量直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  // if(!pointError && !speedError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrorCode = "";
  //   if(pointError) ErrorCode = ErrorCode + pointError;
  //   if(speedError) ErrorCode = ErrorCode + speedError;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(ErrorCode);
  // }
  var code = Blockly.Msg.MOTION_MOVEL + ' P( ' + value_pointvalue + ') ' +
      Blockly.Msg.MOTION_MOVE_OFFSET_X + 'I(' + value_offsetx + ') ' + Blockly.Msg.MOTION_MOVE_OFFSET_Y + 'J(' + value_offsety + ') ' +
      Blockly.Msg.MOTION_MOVE_OFFSET_Z + 'K(' + value_offsetz + ') ' +
      Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ');'+ '\n';//RobotType 预留机器人型号
  return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_movel_xyz_offset'] = function(block) {
  var value_xvalue = Blockly.LLRobot.valueToCode(block, 'XValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_yvalue = Blockly.LLRobot.valueToCode(block, 'YValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_zvalue = Blockly.LLRobot.valueToCode(block, 'ZValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.LLRobot.valueToCode(block,'OffSetX',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.LLRobot.valueToCode(block,'OffSetY',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.LLRobot.valueToCode(block,'OffSetZ',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  //var value_offsetw = Blockly.LLRobot.valueToCode(block,'OffSetW',
  //    Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "XYZ 加偏移量直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "XYZ 加偏移量直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  //   }
  //   else
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     block.setWarningText(null);
  //   }
  // }
  var code = Blockly.Msg.MOTION_MOVEL + ' X( ' + value_xvalue + ') Y(' + value_yvalue + ') Z(' + value_zvalue + ')' +
      Blockly.Msg.MOTION_MOVE_OFFSET_X + 'I(' + value_offsetx + ') ' + Blockly.Msg.MOTION_MOVE_OFFSET_Y + 'J(' + value_offsety + ') ' +
      Blockly.Msg.MOTION_MOVE_OFFSET_Z + 'K(' + value_offsetz + ') ' +
      Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ');'+ '\n';//RobotType 预留机器人型号
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_movel_joint_offset'] = function(block) {
  var value_jvalue1 = Blockly.LLRobot.valueToCode(block, 'JValue1',
      Blockly.LLRobot.ORDER_ATOMIC) || '-90.0';
  var value_jvalue2 = Blockly.LLRobot.valueToCode(block, 'JValue2',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_jvalue3 = Blockly.LLRobot.valueToCode(block, 'JValue3',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_jvalue4 = Blockly.LLRobot.valueToCode(block, 'JValue4',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.LLRobot.valueToCode(block,'OffSetX',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.LLRobot.valueToCode(block,'OffSetY',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.LLRobot.valueToCode(block,'OffSetZ',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  //var value_offsetw = Blockly.LLRobot.valueToCode(block,'OffSetW',
  //    Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "关节角度 加偏移量直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "关节角度 加偏移量直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  //   }
  //   else
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     block.setWarningText(null);
  //   }
  // }
  var code =Blockly.Msg.MOTION_MOVEL+ ' J1( ' + value_jvalue1 + ') J2(' + value_jvalue2 + ') J3(' + value_jvalue3 + ') J4(' + value_jvalue4 + ') ' +
      Blockly.Msg.MOTION_MOVE_OFFSET_X + 'I(' + value_offsetx + ') ' + Blockly.Msg.MOTION_MOVE_OFFSET_Y + 'J(' + value_offsety + ') ' +
      Blockly.Msg.MOTION_MOVE_OFFSET_Z + 'K(' + value_offsetz + ') ' +
      Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ');'+ '\n';//RobotType 预留机器人型号
  return code;
};

/**
 * P点 坐标点编号门型定位
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_moveptp_point'] = function(block) {
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_heightavoid = Blockly.LLRobot.valueToCode(block, 'HeightAvoid',
      Blockly.LLRobot.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var PosAdjustValue = {
    'true' : '是',
    'false' : '否'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = (parseInt(value_pointvalue));//不能为负数
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  //var check = bound.checkPointIsContain(value_pointvalue);
  // var pointError = null;
  // if(isNaN(value_pointvalue) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_pointvalue = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString;
  //   pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR + "\r\n";
  // }
  // else
  // {
  //   if(value_pointvalue < 0 )//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_pointvalue = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "XYZW门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR + "\r\n";
  //   }
  //   else
  //   {
  //     if(Blockly.CustomConfig.DebugMode) {
  //       var check = bound.checkPointIsContain(value_pointvalue);
  //       if (check) {
  //         //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //         //block.setWarningText(null);
  //       }
  //       else {
  //         Blockly.LLRobot.workspaceToCodeError = true;
  //         pointError = Blockly.Msg.MOTION_ERROR_POINT_NOT_EXIST + value_pointvalue + "\r\n";
  //       }
  //     }
  //   }
  // }
  //
  // var speedError = null;
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "P点门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "P点门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  // if(!pointError && !speedError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrorCode = "";
  //   if(pointError) ErrorCode = ErrorCode + pointError;
  //   if(speedError) ErrorCode = ErrorCode + speedError;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(ErrorCode);
  // }
  var code = Blockly.Msg.MOTION_MOVEPTP + ' P( ' + value_pointvalue + ') ' +
      Blockly.Msg.MOTION_HEIGHTAVOID + 'H(' + value_heightavoid + ') ' + Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ') ' +
      Blockly.Msg.MOTION_POS_ADJUST + '(' + dropdown_posadjustvalue + ')' + ';'+ '\n';//RobotType 预留机器人型号
  return code;
};

/**
 *  XYZW 门型定位
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_moveptp_xyz'] = function(block) {
  var value_xvalue = Blockly.LLRobot.valueToCode(block, 'XValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_yvalue = Blockly.LLRobot.valueToCode(block, 'YValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '-300.0';
  var value_zvalue = Blockly.LLRobot.valueToCode(block, 'ZValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_wvalue = Blockly.LLRobot.valueToCode(block, 'WValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_heightavoid = Blockly.LLRobot.valueToCode(block, 'HeightAvoid',
      Blockly.LLRobot.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var PosAdjustValue = {
    'true' : '是',
    'false' : '否'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "XYZW门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText("XYZW门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n");
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "XYZW门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     block.setWarningText("XYZW门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n");
  //   }
  //   else
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     block.setWarningText(null);
  //   }
  // }
  var code = Blockly.Msg.MOTION_MOVEPTP + ' X( ' + value_xvalue + ') Y(' + value_yvalue + ') Z(' + value_zvalue + ') W(' + value_wvalue + ') ' +
      Blockly.Msg.MOTION_HEIGHTAVOID + 'H(' + value_heightavoid + ') ' + Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ') ' +
      Blockly.Msg.MOTION_POS_ADJUST + '(' + dropdown_posadjustvalue + ')' + ';'+ '\n';//RobotType 预留机器人型号
  return code;
};

/**
 * J1 J2 J3 J4 门型定位
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_moveptp_joint'] = function(block) {
  var value_jvalue1 = Blockly.LLRobot.valueToCode(block, 'JValue1',
      Blockly.LLRobot.ORDER_ATOMIC) || '-90.0';
  var value_jvalue2 = Blockly.LLRobot.valueToCode(block, 'JValue2',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_jvalue3 = Blockly.LLRobot.valueToCode(block, 'JValue3',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_jvalue4 = Blockly.LLRobot.valueToCode(block, 'JValue4',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_heightavoid = Blockly.LLRobot.valueToCode(block, 'HeightAvoid',
      Blockly.LLRobot.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var PosAdjustValue = {
    'true' : '是',
    'false' : '否'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "关节坐标门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText("XYZW门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n");
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "关节坐标门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     block.setWarningText("关节坐标门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n");
  //   }
  //   else
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     block.setWarningText(null);
  //   }
  // }
  var code = Blockly.Msg.MOTION_MOVEPTP + ' J1( ' + value_jvalue1 + ') J2(' + value_jvalue2 + ') J3(' + value_jvalue3 + ') J4(' + value_jvalue4 + ') ' +
      Blockly.Msg.MOTION_HEIGHTAVOID + 'H(' + value_heightavoid + ') ' + Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ') ' +
      Blockly.Msg.MOTION_POS_ADJUST + '(' + dropdown_posadjustvalue + ')' + ';'+ '\n';//RobotType 预留机器人型号
  return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_moveptp_point_offset'] = function(block) {
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_heightavoid = Blockly.LLRobot.valueToCode(block, 'HeightAvoid',
      Blockly.LLRobot.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.LLRobot.valueToCode(block,'OffSetX',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.LLRobot.valueToCode(block,'OffSetY',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.LLRobot.valueToCode(block,'OffSetZ',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';

  //var value_offsetw = Blockly.LLRobot.valueToCode(block,'OffSetW',
  //    Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsetw = '0.0';
  var PosAdjustValue = {
    'true' : '是',
    'false' : '否'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);//不能为负数
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  // var pointError = null;
  // if(isNaN(value_pointvalue))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_pointvalue = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "P点 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   pointError = "P点 加偏移量门型定位方式函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  // }
  // else
  // {
  //   if(value_pointvalue < 0 )//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_pointvalue = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "P点 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     pointError = "P点 加偏移量门型定位方式函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //   }
  //   else
  //   {
  //     if(Blockly.CustomConfig.DebugMode) {
  //       var check = bound.checkPointIsContain(value_pointvalue);
  //       if (check) {
  //         //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //         //block.setWarningText(null);
  //       }
  //       else {
  //         Blockly.LLRobot.workspaceToCodeError = true;
  //         pointError = "P" + value_pointvalue + "点不存在";
  //       }
  //     }
  //   }
  // }
  //
  // var speedError = null;
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "P点 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   speedError = "P点 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "P点 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     speedError = "P点 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  // if(!pointError && !speedError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrorCode = "";
  //   if(pointError) ErrorCode = ErrorCode + pointError;
  //   if(speedError) ErrorCode = ErrorCode + speedError;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(ErrorCode);
  // }
  var code = Blockly.Msg.MOTION_MOVEPTP + ' P( ' + value_pointvalue + ') ' +
      Blockly.Msg.MOTION_MOVE_OFFSET_X + 'I(' + value_offsetx + ') ' + Blockly.Msg.MOTION_MOVE_OFFSET_Y + 'J(' + value_offsety + ') ' +
      Blockly.Msg.MOTION_MOVE_OFFSET_Z + 'K(' + value_offsetz + ') ' +
      Blockly.Msg.MOTION_HEIGHTAVOID + 'H(' + value_heightavoid + ') ' + Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ') ' +
      Blockly.Msg.MOTION_POS_ADJUST + '(' + dropdown_posadjustvalue + ')' + ';'+ '\n';
  return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_moveptp_xyz_offset'] = function(block) {
  var value_xvalue = Blockly.LLRobot.valueToCode(block, 'XValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_yvalue = Blockly.LLRobot.valueToCode(block, 'YValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '-300.0';
  var value_zvalue = Blockly.LLRobot.valueToCode(block, 'ZValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_wvalue = Blockly.LLRobot.valueToCode(block, 'WValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_heightavoid = Blockly.LLRobot.valueToCode(block, 'HeightAvoid',
      Blockly.LLRobot.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.LLRobot.valueToCode(block,'OffSetX',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.LLRobot.valueToCode(block,'OffSetY',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.LLRobot.valueToCode(block,'OffSetZ',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  //var value_offsetw = Blockly.LLRobot.valueToCode(block,'OffSetW',
  //    Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var PosAdjustValue = {
    'true' : '是',
    'false' : '否'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  var value_offsetw = '0.0';
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "XYZW 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText("XYZW 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n");
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "XYZW 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     block.setWarningText("XYZW 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n");
  //   }
  //   else
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     block.setWarningText(null);
  //   }
  // }
  var code = Blockly.Msg.MOTION_MOVEPTP + ' X( ' + value_xvalue + ') Y(' + value_yvalue + ') Z(' + value_zvalue + ') W(' + value_wvalue + ') ' +
      Blockly.Msg.MOTION_MOVE_OFFSET_X + 'I(' + value_offsetx + ') ' + Blockly.Msg.MOTION_MOVE_OFFSET_Y + 'J(' + value_offsety + ') ' +
      Blockly.Msg.MOTION_MOVE_OFFSET_Z + 'K(' + value_offsetz + ') ' +
      Blockly.Msg.MOTION_HEIGHTAVOID + 'H(' + value_heightavoid + ') ' + Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ') ' +
      Blockly.Msg.MOTION_POS_ADJUST + '(' + dropdown_posadjustvalue + ')' + ';'+ '\n';
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_moveptp_joint_offset'] = function(block) {
  var value_jvalue1 = Blockly.LLRobot.valueToCode(block, 'JValue1',
      Blockly.LLRobot.ORDER_ATOMIC) || '-90.0';
  var value_jvalue2 = Blockly.LLRobot.valueToCode(block, 'JValue2',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_jvalue3 = Blockly.LLRobot.valueToCode(block, 'JValue3',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_jvalue4 = Blockly.LLRobot.valueToCode(block, 'JValue4',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_heightavoid = Blockly.LLRobot.valueToCode(block, 'HeightAvoid',
      Blockly.LLRobot.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.LLRobot.valueToCode(block,'OffSetX',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.LLRobot.valueToCode(block,'OffSetY',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.LLRobot.valueToCode(block,'OffSetZ',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  //var value_offsetw = Blockly.LLRobot.valueToCode(block,'OffSetW',
  //    Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var PosAdjustValue = {
    'true' : '是',
    'false' : '否'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  var value_offsetw = '0.0';//暂时省略姿态角度偏移
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "关节角度 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText("关节角度 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n");
  // }
  // else
  // {
  //   if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_maxspeed = 200;
  //     value_endspeed = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "关节角度 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     block.setWarningText("关节角度 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n");
  //   }
  //   else
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     block.setWarningText(null);
  //   }
  // }
  var code = Blockly.Msg.MOTION_MOVEPTP + ' J1( ' + value_jvalue1 + ') J2(' + value_jvalue2 + ') J3(' + value_jvalue3 + ') J4(' + value_jvalue4 + ') ' +
      Blockly.Msg.MOTION_MOVE_OFFSET_X + 'I(' + value_offsetx + ') ' + Blockly.Msg.MOTION_MOVE_OFFSET_Y + 'J(' + value_offsety + ') ' +
      Blockly.Msg.MOTION_MOVE_OFFSET_Z + 'K(' + value_offsetz + ') ' +
      Blockly.Msg.MOTION_HEIGHTAVOID + 'H(' + value_heightavoid + ') ' + Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ') ' +
      Blockly.Msg.MOTION_POS_ADJUST + '(' + dropdown_posadjustvalue + ')' + ';'+ '\n';//RobotType 预留机器人型号
  return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_moveptp_dir_offset'] = function(block) {

    var value_startpoint = Blockly.LLRobot.valueToCode(block, 'StartPoint',
        Blockly.LLRobot.ORDER_ATOMIC) || '0';
    var value_dirpoint = Blockly.LLRobot.valueToCode(block, 'DirPoint',
        Blockly.LLRobot.ORDER_ATOMIC) || '0';
    var value_offset = Blockly.LLRobot.valueToCode(block,'OffSet',
        Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
    var value_heightavoid = Blockly.LLRobot.valueToCode(block, 'HeightAvoid',
        Blockly.LLRobot.ORDER_ATOMIC) || '25.0';
    var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
        Blockly.LLRobot.ORDER_ATOMIC) || '1000';
    var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
        Blockly.LLRobot.ORDER_ATOMIC) || '0';

    var PosAdjustValue = {
        'true' : '是',
        'false' : '否'
    };
    var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
    value_startpoint = value_startpoint.replace('(','');value_startpoint = value_startpoint.replace(')','');
    // value_startpoint = parseInt(value_startpoint);//不能为负数
    value_dirpoint = value_dirpoint.replace('(','');value_dirpoint = value_dirpoint.replace(')','');
    // value_dirpoint = parseInt(value_dirpoint);//不能为负数
    value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
    value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
    value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
    value_endspeed = parseInt(value_endspeed);

    var code = Blockly.Msg.MOTION_MOVEPTP_DIR + ' ' + Blockly.Msg.MOTION_MOVEPTP_DIR_START+ '( ' + value_startpoint + ') ' +Blockly.Msg.MOTION_MOVEPTP_DIR_DIR+ '( ' + value_dirpoint + ') '+
        Blockly.Msg.MOTION_MOVEPTP_DIR_OFFSET+ '(' + value_offset + ') ' + Blockly.Msg.MOTION_HEIGHTAVOID + 'H(' + value_heightavoid + ') '+
        Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ') ' +
        Blockly.Msg.MOTION_POS_ADJUST + '(' + dropdown_posadjustvalue + ')' + ';'+ '\n';
    return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_move_coordinate_offset'] = function(block) {

    var value_startpoint = Blockly.LLRobot.valueToCode(block, 'StartPoint',
        Blockly.LLRobot.ORDER_ATOMIC) || '0';
    var value_xpoint = Blockly.LLRobot.valueToCode(block, 'XPoint',
        Blockly.LLRobot.ORDER_ATOMIC) || '0';
    var value_ypoint = Blockly.LLRobot.valueToCode(block, 'YPoint',
        Blockly.LLRobot.ORDER_ATOMIC) || '0';
    var value_xstep = Blockly.LLRobot.valueToCode(block,'XStep',
        Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
    var value_ystep = Blockly.LLRobot.valueToCode(block,'YStep',
        Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
    var value_xindex = Blockly.LLRobot.valueToCode(block,'XIndex',
        Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
    var value_yindex = Blockly.LLRobot.valueToCode(block,'YIndex',
        Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
    var value_heightavoid = Blockly.LLRobot.valueToCode(block, 'HeightAvoid',
        Blockly.LLRobot.ORDER_ATOMIC) || '25.0';
    var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
        Blockly.LLRobot.ORDER_ATOMIC) || '1000';
    var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
        Blockly.LLRobot.ORDER_ATOMIC) || '0';

    var PosAdjustValue = {
        'true' : '是',
        'false' : '否'
    };
    var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
    value_xindex = value_xindex.replace('(','');value_xindex = value_xindex.replace(')','');
    value_yindex = value_yindex.replace('(','');value_yindex = value_yindex.replace(')','');
    value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
    value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
    // value_xindex = parseInt(value_xindex);
    // value_yindex = parseInt(value_yindex);
    value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
    value_endspeed = parseInt(value_endspeed);

    var code = Blockly.Msg.MOTION_MOVE_COORDINATE + ' ' + Blockly.Msg.MOTION_MOVE_COORDINATE_START+ '( ' + value_startpoint + ') ' +
        Blockly.Msg.MOTION_MOVE_COORDINATE_XDIR+ '( ' + value_xpoint + ') '+ Blockly.Msg.MOTION_MOVE_COORDINATE_YDIR+ '( ' + value_ypoint + ') '+
        Blockly.Msg.MOTION_MOVE_COORDINATE_XSTEP+ '(' + value_xstep + ') ' +  Blockly.Msg.MOTION_MOVE_COORDINATE_YSTEP+ '(' + value_ystep + ') ' +
        Blockly.Msg.MOTION_MOVE_COORDINATE_XINDEX+ '(' + value_xindex + ') ' +  Blockly.Msg.MOTION_MOVE_COORDINATE_YINDEX+ '(' + value_yindex + ') ' +
        Blockly.Msg.MOTION_HEIGHTAVOID + 'H(' + value_heightavoid + ') '+
        Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ') ' +
        Blockly.Msg.MOTION_POS_ADJUST + '(' + dropdown_posadjustvalue + ')' + ';'+ '\n';
    return code;
};

/**
 *
 */
Blockly.LLRobot['motion_waitrobot'] = function (block) {
  var code = Blockly.Msg.MOTION_WAITROBOT + ';\n';
  return code;
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['motion_getcurrent_axispos'] = function(block) {
  var AxisName = {
    'XValue' : 'X',
    'YValue' : 'Y',
    'ZValue' : 'Z',
    'WValue' : 'W'
  };
  var dropdown_axis = AxisName[block.getFieldValue('Axis')];
  var code = Blockly.Msg.MOTION_GET_CURRENT_AXISPOS + '( ' + dropdown_axis + ')';
  return [code, Blockly.LLRobot.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['motion_getcurrent_jointangle'] = function(block) {
  var JointName = {
    'JointValue1' : 'J1',
    'JointValue2' : 'J2',
    'JointValue3' : 'J3',
    'JointValue4' : 'J4'
  };
  var dropdown_jointangle = JointName[block.getFieldValue('JointAngle')];
  var code = Blockly.Msg.MOTION_GET_CURRENT_JOINTANGLE + '( ' + dropdown_jointangle + ')';
  return [code, Blockly.LLRobot.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['motion_getaxispos_frompoint'] = function(block) {
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var AxisName = {
    'XValue' : 'X',
    'YValue' : 'Y',
    'ZValue' : 'Z',
    'WValue' : 'W'
  };
  var dropdown_axis = AxisName[block.getFieldValue('Axis')];
  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);
  // var pointError = null;
  // if(isNaN(value_pointvalue) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_pointvalue = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "获取坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //   pointError = "获取坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  // }
  // else
  // {
  //   if(value_pointvalue < 0 )//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_pointvalue = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "获取坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //     pointError = "获取坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //   }
  //   else
  //   {
  //     var check = true;
  //     //var check = bound.checkPointIsContain(value_pointvalue);
  //     if(check) {
  //       //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //       //block.setWarningText(null);
  //     }
  //     else
  //     {
  //       Blockly.LLRobot.workspaceToCodeError = true;
  //       pointError = "P" + value_pointvalue + "点不存在";
  //     }
  //   }
  // }
  // if(!pointError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(pointError);
  // }
  var code = Blockly.Msg.MOTION_GET_POINT + ' P( ' + value_pointvalue + ') ' + Blockly.Msg.MOTION_POS_AXISPOS + '(' + dropdown_axis + ')';
  return [code, Blockly.LLRobot.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['motion_getjointangle_frompoint'] = function(block) {
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var JointName = {
    'JointValue1' : 'J1',
    'JointValue2' : 'J2',
    'JointValue3' : 'J3',
    'JointValue4' : 'J4'
  };
  var dropdown_jointangle = JointName[block.getFieldValue('JointAngle')];
  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);
  // var pointError = null;
  // if(isNaN(value_pointvalue) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_pointvalue = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "获取坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //   pointError = "获取坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  // }
  // else
  // {
  //   if(value_pointvalue < 0 )//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_pointvalue = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "获取坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //     pointError = "获取坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //   }
  //   else
  //   {
  //     if(Blockly.CustomConfig.DebugMode) {
  //       var check = bound.checkPointIsContain(value_pointvalue);
  //       if (check) {
  //         //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //         //block.setWarningText(null);
  //       }
  //       else {
  //         Blockly.LLRobot.workspaceToCodeError = true;
  //         pointError = "P" + value_pointvalue + "点不存在";
  //       }
  //     }
  //   }
  // }
  // if(!pointError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(pointError);
  // }
  var code = Blockly.Msg.MOTION_GET_POINT + ' P( ' + value_pointvalue + ') ' + Blockly.Msg.MOTION_POS_JOINTANGLE + '(' + dropdown_jointangle + ')';
  return [code, Blockly.LLRobot.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_setaxispos_topoint'] = function(block) {
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_xvalue = Blockly.LLRobot.valueToCode(block, 'XValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_yvalue = Blockly.LLRobot.valueToCode(block, 'YValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '-300.0';
  var value_zvalue = Blockly.LLRobot.valueToCode(block, 'ZValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_wvalue = Blockly.LLRobot.valueToCode(block, 'WValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';

  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);
  // var pointError = null;
  // if(isNaN(value_pointvalue) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_pointvalue = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "设置坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //   pointError = "设置坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  // }
  // else
  // {
  //   if(value_pointvalue < 0 )//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_pointvalue = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "设置坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //     pointError = "设置坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //   }
  //   else
  //   {
  //     if(Blockly.CustomConfig.DebugMode) {
  //       var check = bound.checkPointIsContain(value_pointvalue);
  //       if (check) {
  //         //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //         //block.setWarningText(null);
  //       }
  //       else {
  //         Blockly.LLRobot.workspaceToCodeError = true;
  //         pointError = "P" + value_pointvalue + "点不存在";
  //       }
  //     }
  //   }
  // }
  // if(!pointError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(pointError);
  // }
  var code = Blockly.Msg.MOTION_SET_POINT + ' P( ' + value_pointvalue + ') ' + Blockly.Msg.MOTION_POS_AXISPOS + '(' +
      value_xvalue + ', ' + value_yvalue + ', ' + value_zvalue + ', ' + value_wvalue +');' + '\n';
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_setjointangle_topoint'] = function(block) {
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_jvalue1 = Blockly.LLRobot.valueToCode(block, 'JValue1',
      Blockly.LLRobot.ORDER_ATOMIC) || '-90.0';
  var value_jvalue2 = Blockly.LLRobot.valueToCode(block, 'JValue2',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_jvalue3 = Blockly.LLRobot.valueToCode(block, 'JValue3',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';
  var value_jvalue4 = Blockly.LLRobot.valueToCode(block, 'JValue4',
      Blockly.LLRobot.ORDER_ATOMIC) || '0.0';

  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);
  // var pointError = null;
  // if(isNaN(value_pointvalue) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_pointvalue = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "设置坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //   pointError = "设置坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  // }
  // else
  // {
  //   if(value_pointvalue < 0 )//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_pointvalue = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "设置坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //     pointError = "设置坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  //   }
  //   else
  //   {
  //     if(Blockly.CustomConfig.DebugMode) {
  //       var check = bound.checkPointIsContain(value_pointvalue);
  //       if (check) {
  //         //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //         //block.setWarningText(null);
  //       }
  //       else {
  //         Blockly.LLRobot.workspaceToCodeError = true;
  //         pointError = "P" + value_pointvalue + "点不存在";
  //       }
  //     }
  //   }
  // }
  // if(!pointError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(pointError);
  // }
  var code = Blockly.Msg.MOTION_SET_POINT + ' ( ' + value_pointvalue + ') ' + Blockly.Msg.MOTION_POS_JOINTANGLE + '(' +
      value_jvalue1 + ', ' + value_jvalue2 + ', ' + value_jvalue3 + ', ' + value_jvalue4 +');' + '\n';
  return code;
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['motion_getinputvalue'] = function(block) {
  var Index = {
    'Input1' : 'Input1',
    'Input2' : 'Input2',
    'Input3' : 'Input3',
    'Input4' : 'Input4',
    'Input5' : 'Input5',
    'Input6' : 'Input6',
    'Input7' : 'Input7',
    'Input8' : 'Input8',
    'Input9' : 'Input9',
    'Input10' : 'Input10',
    'Input11' : 'Input11',
    'Input12' : 'Input12',
    'Input13' : 'Input13',
    'Input14' : 'Input14',
    'Input15' : 'Input15',
    'Input16' : 'Input16'
  };
  var dropdown_inputnum = Index[block.getFieldValue('InputNum')];
  var code = Blockly.Msg.MOTION_GET_IO_INPUT_STATUS + ' ( ' + dropdown_inputnum + ')';
  return [code, Blockly.LLRobot.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['motion_getoutputvalue'] = function(block) {
  var Index = {
    'Output1' : 'Output1',
    'Output2' : 'Output2',
    'Output3' : 'Output3',
    'Output4' : 'Output4',
    'Output5' : 'Output5',
    'Output6' : 'Output6',
    'Output7' : 'Output7',
    'Output8' : 'Output8',
    'Output9' : 'Output9',
    'Output10' : 'Output10',
    'Output11' : 'Output11',
    'Output12' : 'Output12',
    'Output13' : 'Output13',
    'Output14' : 'Output14',
    'Output15' : 'Output15',
    'Output16' : 'Output16'
  };
  var dropdown_outputnum = Index[block.getFieldValue('OutputNum')];
  var code = Blockly.Msg.MOTION_GET_IO_OUTPUT_STATUS + ' ( ' + dropdown_outputnum + ')';
  return [code, Blockly.LLRobot.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_setoutputvalue_dropdown'] = function(block) {
  var Index = {
    'Output1' : 'Output1',
    'Output2' : 'Output2',
    'Output3' : 'Output3',
    'Output4' : 'Output4',
    'Output5' : 'Output5',
    'Output6' : 'Output6',
    'Output7' : 'Output7',
    'Output8' : 'Output8',
    'Output9' : 'Output9',
    'Output10' : 'Output10',
    'Output11' : 'Output11',
    'Output12' : 'Output12',
    'Output13' : 'Output13',
    'Output14' : 'Output14',
    'Output15' : 'Output15',
    'Output16' : 'Output16'
  };
  var OutputValue = {
    'true' : Blockly.Msg.MOTION_IO_OUTPUT_STATUS_SET,
    'false' : Blockly.Msg.MOTION_IO_OUTPUT_STATUS_RST
  };
  var dropdown_outputnum = Index[block.getFieldValue('OutputNum')];
  var dropdown_outputvalue = OutputValue[block.getFieldValue('OutputValue')];
  var code = Blockly.Msg.MOTION_SET_IO_OUTPUT + '( ' + dropdown_outputnum + ') ' + Blockly.Msg.MOTION_IO_OUTPUT_STATUS + ': (' +dropdown_outputvalue + ');' + '\n';
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
/**
Blockly.LLRobot['motion_setoutputvalue_externalinput'] = function(block) {
  var Index = {
    'Output1' : '0',
    'Output2' : '1',
    'Output3' : '2',
    'Output4' : '3',
    'Output5' : '4',
    'Output6' : '5',
    'Output7' : '6',
    'Output8' : '7',
    'Output9' : '8',
    'Output10' : '9',
    'Output11' : '10',
    'Output12' : '11',
    'Output13' : '12',
    'Output14' : '13',
    'Output15' : '14',
    'Output16' : '15'
  };
  var dropdown_outputnum = Index[block.getFieldValue('OutputNum')];
  var value_outputvalue = Blockly.LLRobot.valueToCode(block, 'OutputValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  value_outputvalue = parseInt(value_outputvalue);
  var code = 'RobotMove.SetOutputValue( ' + dropdown_outputnum + ', ' +value_outputvalue + ');\n';
  return code;
};
*/

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_setcomport_parameter'] = function(block) {
  var dropdown_tpye = block.getFieldValue("Type");
  var value_comportnum = Blockly.LLRobot.valueToCode(block, 'ComPortNum',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var dropdown_baudrate = block.getFieldValue('BaudRate');
  var dropdown_databit = block.getFieldValue('DataBit');
  var dropdown_stopbit = block.getFieldValue('StopBit');
  var dropdown_paritybit = block.getFieldValue('ParityBit');
  value_comportnum = value_comportnum.replace('(','');value_comportnum = value_comportnum.replace(')','');
  value_comportnum = parseInt(value_comportnum);
  // if(isNaN(value_comportnum) )//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_comportnum = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "设置串口参数函数转换出错,请检查串口编号设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText("设置串口参数函数转换出错,请检查串口编号设置是否正确,只能填写正整数;\r\n");
  // }
  // else
  // {
  //   if(value_comportnum < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_comportnum = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "设置串口参数函数转换出错,请检查串口编号设置是否正确,只能填写正整数;\r\n";
  //     block.setWarningText("设置串口参数函数转换出错,请检查串口编号设置是否正确,只能填写正整数;\r\n");
  //   }
  //   else
  //   {
  //     //查找电脑中可用的串口号，并判断是否存在
  //     if(Blockly.LLRobot.ComPortList.length == 0)
  //     {
  //       Blockly.LLRobot.ComPortList.push(value_comportnum);
  //       block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //       block.setWarningText(null);
  //     }
  //     else
  //     {
  //       block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //       value_comportnum = 0;
  //       Blockly.LLRobot.workspaceToCodeError = true;
  //
  //       block.setWarningText("目前串口通讯功能只支持单个串口!请勿重复使用!\r\n");
  //       /*
  //       if(Blockly.LLRobot.ComPortList.indexOf(value_comportnum) != -1)
  //       {
  //         block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //         value_comportnum = 0;
  //         Blockly.LLRobot.workspaceToCodeError = true;
  //
  //         block.setWarningText("串口号设置重复,请注意检查!同一个串口号只能初始化一次!;\r\n");
  //       }
  //       else
  //       {
  //         Blockly.LLRobot.ComPortList.push(value_comportnum);
  //         block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //         block.setWarningText(null);
  //       }
  //       */
  //     }
  //
  //   }
  // }
  var plc_type_name =Blockly.Msg.MOTION_PLC_TYPE_DEFAULT;
  if (dropdown_tpye==1){
    plc_type_name = Blockly.Msg.MOTION_PLC_TYPE_FX;
  }else if(dropdown_tpye==2){
    plc_type_name =Blockly.Msg.MOTION_PLC_TYPE_XJ;
  }
  var code = Blockly.Msg.MOTION_SET_COMPORT +' ( ' + value_comportnum + ') '+Blockly.Msg.MOTION_PLC_TYPE+  ' ( ' + plc_type_name+ ') '+ Blockly.Msg.MOTION_BAUDRATE + ': (' + dropdown_baudrate + ') ' + Blockly.Msg.MOTION_DATABIT + ': ('
      + dropdown_databit + ') ' + Blockly.Msg.MOTION_STOPBIT + ': ('+ dropdown_stopbit + ') ' + Blockly.Msg.MOTION_PARITYBIT + ': ('+ dropdown_paritybit + ');' + '\n';
  return code;
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['motion_getplc_coilstatus'] = function(block) {
  var value_coilnum = Blockly.LLRobot.valueToCode(block, 'CoilNum',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  value_coilnum = value_coilnum.replace('(','');value_coilnum = value_coilnum.replace(')','');
  value_coilnum = parseInt(value_coilnum);
  // if(isNaN(value_coilnum) )//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_coilnum = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "读取PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText("读取PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\n");
  // }
  // else
  // {
  //   if(value_coilnum < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_coilnum = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "读取PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n";
  //     block.setWarningText("读取PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\n");
  //   }
  //   else
  //   {
  //     if(Blockly.LLRobot.ComPortList.length == 0)
  //     {
  //       block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //       value_coilnum = 0;
  //       Blockly.LLRobot.workspaceToCodeError = true;
  //       block.setWarningText("串口参数还未初始化,请先调用串口参数初始化模块!\n");
  //     }
  //     else {
  //       block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //       block.setWarningText(null);
  //     }
  //   }
  // }
  var code = Blockly.Msg.MOTION_GET_COILSTATUS + ' M( ' + value_coilnum + ')';
  return [code, Blockly.LLRobot.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['motion_getplc_registerdata'] = function(block) {
  var value_registernum = Blockly.LLRobot.valueToCode(block, 'RegisterNum',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  value_registernum = value_registernum.replace('(','');value_registernum = value_registernum.replace(')','');
  value_registernum = parseInt(value_registernum);
  // if(isNaN(value_registernum) )//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_registernum = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "读取PLC寄存器数值函数转换出错,请检查寄存器编号设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText("读取PLC寄存器数值函数转换出错,请检查寄存器编号设置是否正确,只能填写正整数;\n");
  // }
  // else
  // {
  //   if(value_registernum < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_registernum = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "读取PLC寄存器数值函数转换出错,请检查寄存器编号设置是否正确,只能填写正整数;\r\n";
  //     block.setWarningText("读取PLC寄存器数值函数转换出错,请检查寄存器编号设置是否正确,只能填写正整数;\n");
  //   }
  //   else
  //   {
  //     if(Blockly.LLRobot.ComPortList.length == 0)
  //     {
  //       block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //       value_registernum = 0;
  //       Blockly.LLRobot.workspaceToCodeError = true;
  //       block.setWarningText("串口参数还未初始化,请先调用串口参数初始化模块!\n");
  //     }
  //     else {
  //       block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //       block.setWarningText(null);
  //     }
  //   }
  // }
  var code = Blockly.Msg.MOTION_GET_REGISTERDATA + ' D( ' + value_registernum +')';
  return [code, Blockly.LLRobot.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_setplc_registerdata'] = function(block) {
  var value_registernum = Blockly.LLRobot.valueToCode(block, 'RegisterNum',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_registerdata = Blockly.LLRobot.valueToCode(block, 'RegisterData',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  value_registernum = value_registernum.replace('(','');value_registernum = value_registernum.replace(')','');
  value_registerdata = value_registerdata.replace('(','');value_registerdata = value_registerdata.replace(')','');
  value_registernum = parseInt(value_registernum);
  //value_registerdata = parseInt(value_registerdata);//PLC寄存器数值 整型
  // if(isNaN(value_registernum))// || isNaN(value_registerdata))//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_registernum = 0;
  //   //value_registerdata = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "设置PLC寄存器数值函数转换出错,请检查寄存器编号和寄存器数值设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText("设置PLC寄存器数值函数转换出错,请检查寄存器编号和寄存器数值设置是否正确,只能填写正整数;\r\n");
  // }
  // else
  // {
  //   if(value_registernum < 0)// || value_registerdata < 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_registernum = 0;
  //     //value_registerdata = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "设置PLC寄存器数值函数转换出错,请检查寄存器编号和寄存器数值设置是否正确,只能填写正整数;\r\n";
  //     block.setWarningText("设置PLC寄存器数值函数转换出错,请检查寄存器编号和寄存器数值设置是否正确,只能填写正整数;\r\n");
  //   }
  //   else
  //   {
  //     if(Blockly.LLRobot.ComPortList.length == 0)
  //     {
  //       block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //       value_registernum = 0;
  //       Blockly.LLRobot.workspaceToCodeError = true;
  //       block.setWarningText("串口参数还未初始化,请先调用串口参数初始化模块!\n");
  //     }
  //     else {
  //       block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //       block.setWarningText(null);
  //     }
  //   }
  // }
  var code = Blockly.Msg.MOTION_SET_REGISTERDATA + ' D( ' + value_registernum + ') ' + Blockly.Msg.MOTION_REGISTERVALUE + ': (' + value_registerdata + ');' + '\n';
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_setplc_coilstatus'] = function(block) {
  var value_coilnum = Blockly.LLRobot.valueToCode(block, 'CoilNum',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  //var value_coilstatus = Blockly.LLRobot.valueToCode(block, 'CoilStatus',
  //    Blockly.LLRobot.ORDER_ATOMIC) || 'false';
  var value_coilstatus = block.getFieldValue('SET_RST_CoilStatus');
  value_coilnum = value_coilnum.replace('(','');value_coilnum = value_coilnum.replace(')','');
  value_coilnum = parseInt(value_coilnum);
  // if(isNaN(value_coilnum))//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_coilnum = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "设置PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText("设置PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n");
  // }
  // else
  // {
  //   if(value_coilnum <= 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_coilnum = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "设置PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n";
  //     block.setWarningText("设置PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n");
  //   }
  //   else
  //   {
  //     if(Blockly.LLRobot.ComPortList.length == 0)
  //     {
  //       block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //       value_coilnum = 0;
  //       Blockly.LLRobot.workspaceToCodeError = true;
  //       block.setWarningText("串口参数还未初始化,请先调用串口参数初始化模块!\n");
  //     }
  //     else {
  //       block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //       block.setWarningText(null);
  //     }
  //   }
  // }
  var value_coilstatusName = value_coilstatus ? Blockly.Msg.MOTION_COILSTATUS_SET : Blockly.Msg.MOTION_COILSTATUS_RST;
  var code = Blockly.Msg.MOTION_SET_COIL + ' M( ' + value_coilnum + ') ' + Blockly.Msg.MOTION_COILSTATUS + ': (' + value_coilstatusName + ');' + '\n';
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['motion_delaytime'] = function(block) {
  var uint = {
    'millisecond' : '1',
    'second' : '1000'
  };
  var value_delaytime = Blockly.LLRobot.valueToCode(block, 'DelayTime',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var dropdown_unit = uint[block.getFieldValue('UNIT')];
  value_delaytime = value_delaytime.replace('(','');value_delaytime = value_delaytime.replace(')','');
  value_delaytime = parseFloat(value_delaytime) * parseFloat(dropdown_unit);
  value_delaytime = parseInt(value_delaytime);
  // if(isNaN(value_delaytime))//NaN 错误
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_delaytime = 10;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "延时函数转换出错,请检查延时时间设置是否正确,只能填写正整数;\r\n";
  //   block.setWarningText("延时函数转换出错,请检查延时时间设置是否正确,只能填写正整数;\r\n");
  // }
  // else
  // {
  //   if(value_delaytime <= 0)//<=0 错误
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_delaytime = 10;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "延时函数转换出错,请检查延时时间设置是否正确,只能填写正整数;\r\n";
  //     block.setWarningText("延时函数转换出错,请检查延时时间设置是否正确,只能填写正整数;\r\n");
  //   }
  //   else
  //   {
  //     block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     block.setWarningText(null);
  //   }
  // }
  //var code = 'UtilityClass.Delay_ms( ' + value_delaytime + ');' + Blockly.CustomConfig.CSharpCode_ExitMain + '\n';
  var code = Blockly.Msg.MOTION_DELAY + '( ' + value_delaytime + ')' + Blockly.Msg.MOTION_MILLISECOND_UNIT  + ';\n';
  return code;
};