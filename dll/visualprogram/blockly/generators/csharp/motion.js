'use strict';

goog.provide("Blockly.CSharp.motion");
goog.require("Blockly.CSharp");
goog.require('Blockly.Blocks');
goog.require('Blockly.Block');
goog.require('Blockly.CustomConfig');




Blockly.CSharp.ComPortList = [];

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.CSharp['math_number_int'] = function(block) {
  // Numeric value.
  var code = (parseInt(block.getFieldValue('NUM')));//parseFloat
  var order;
  if (code == Infinity) {
    code = 'double.INFINITY';
    order = Blockly.CSharp.ORDER_UNARY_POSTFIX;
  } else if (code == -Infinity) {
    code = '-double.INFINITY';
    order = Blockly.CSharp.ORDER_UNARY_PREFIX;
  } else {
    // -4.abs() returns -4 in Dart due to strange order of operation choices.
    // -4 is actually an operator and a number.  Reflect this in the order.
    order = code < 0 ?
        Blockly.CSharp.ORDER_UNARY_PREFIX : Blockly.CSharp.ORDER_ATOMIC;
  }
  return [code, order];
};

Blockly.CSharp['math_number_uint'] = function(block) {
  // Numeric value.
  var code = Math.abs(parseInt(block.getFieldValue('NUM')));//parseFloat
  var order;
  if (code == Infinity) {
    code = 'double.INFINITY';
    order = Blockly.CSharp.ORDER_UNARY_POSTFIX;
  } else if (code == -Infinity) {
    code = '-double.INFINITY';
    order = Blockly.CSharp.ORDER_UNARY_PREFIX;
  } else {
    // -4.abs() returns -4 in Dart due to strange order of operation choices.
    // -4 is actually an operator and a number.  Reflect this in the order.
    order = code < 0 ?
        Blockly.CSharp.ORDER_UNARY_PREFIX : Blockly.CSharp.ORDER_ATOMIC;
  }
  return [code, order];
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_movel_point'] = function(block) {
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';

  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);//不能为负数
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  var pointError = null;
  if(isNaN(value_pointvalue) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "P点直线定位方式函数转换出错,请检查坐标点编号是否正确;\r\n";
    pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR +"\r\n";
  }
  else
  {
    if(value_pointvalue < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "P点直线定位方式函数转换出错,请检查坐标点编号是否正确;\r\n";
      pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR +"\r\n";
    }
    else
    {
      if(Blockly.CustomConfig.DebugMode) {
        var check = bound.checkPointIsContain(value_pointvalue);
        if (check) {
          //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
          //block.setWarningText(null);
        }
        else {
          Blockly.CSharp.workspaceToCodeError = true;
          pointError = Blockly.Msg.MOTION_ERROR_POINT_NOT_EXIST + value_pointvalue + "\r\n";
        }
      }
    }
  }

  var speedError = null;
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "P点直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    speedError = Blockly.Msg.MOTION_ENDSPEED + "\r\n";
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "P点直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      speedError = Blockly.Msg.MOTION_ENDSPEED + "\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }
  if(!pointError && !speedError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  else
  {
    var ErrorCode = "";
    if(pointError) ErrorCode = ErrorCode + pointError;
    if(speedError) ErrorCode = ErrorCode + speedError;
    Blockly.CSharp.workspaceToCodeError = true;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MoveL_Point( ' + value_pointvalue + ', ' +
      value_maxspeed + ', ' + value_endspeed + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_movel_xyz'] = function(block) {
  var value_xvalue = Blockly.CSharp.valueToCode(block, 'XValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_yvalue = Blockly.CSharp.valueToCode(block, 'YValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_zvalue = Blockly.CSharp.valueToCode(block, 'ZValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "XYZ直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "XYZ直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      block.setWarningText(null);
    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MoveL_XYZ( ' + value_xvalue + ', ' + value_yvalue + ', ' + value_zvalue + ', ' +
      value_maxspeed + ', ' + value_endspeed + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_movel_joint'] = function(block) {
  var value_jvalue1 = Blockly.CSharp.valueToCode(block, 'JValue1',
      Blockly.CSharp.ORDER_ATOMIC) || '-90.0';
  var value_jvalue2 = Blockly.CSharp.valueToCode(block, 'JValue2',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_jvalue3 = Blockly.CSharp.valueToCode(block, 'JValue3',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_jvalue4 = Blockly.CSharp.valueToCode(block, 'JValue4',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "关节角度直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "关节角度直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      block.setWarningText(null);
    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MoveL_Joint( ' + value_jvalue1 + ', ' + value_jvalue2 + ', ' + value_jvalue3 + ', ' + value_jvalue4 + ', ' +
      value_maxspeed + ', ' + value_endspeed + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_movel_point_offset'] = function(block) {
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.CSharp.valueToCode(block,'OffSetX',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.CSharp.valueToCode(block,'OffSetY',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.CSharp.valueToCode(block,'OffSetZ',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  //var value_offsetw = Blockly.CSharp.valueToCode(block,'OffSetW',
  //    Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  var pointError = null;
  if(isNaN(value_pointvalue) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "P点 加偏移量直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR +"\r\n";
  }
  else
  {
    if(value_pointvalue < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "P点 加偏移量直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR +"\r\n";
    }
    else
    {
      if(Blockly.CustomConfig.DebugMode) {
        var check = bound.checkPointIsContain(value_pointvalue);
        if (check) {
          //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
          //block.setWarningText(null);
        }
        else {
          Blockly.CSharp.workspaceToCodeError = true;
          pointError = Blockly.Msg.MOTION_ERROR_POINT_NOT_EXIST + value_pointvalue + "\r\n";
        }
      }
    }
  }

  var speedError = null;
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "P点 加偏移量直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "P点 加偏移量直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }
  if(!pointError && !speedError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(pointError) ErrorCode = ErrorCode + pointError;
    if(speedError) ErrorCode = ErrorCode + speedError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MoveL_PointOffset( ' + value_pointvalue + ', ' +
      value_offsetx + ', ' + value_offsety + ', ' + value_offsetz + ', '  +
      value_maxspeed + ', ' + value_endspeed + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_movel_xyz_offset'] = function(block) {
  var value_xvalue = Blockly.CSharp.valueToCode(block, 'XValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_yvalue = Blockly.CSharp.valueToCode(block, 'YValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_zvalue = Blockly.CSharp.valueToCode(block, 'ZValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.CSharp.valueToCode(block,'OffSetX',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.CSharp.valueToCode(block,'OffSetY',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.CSharp.valueToCode(block,'OffSetZ',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  //var value_offsetw = Blockly.CSharp.valueToCode(block,'OffSetW',
  //    Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "XYZ 加偏移量直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "XYZ 加偏移量直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      block.setWarningText(null);
    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MoveL_XYZOffset( ' + value_xvalue + ', ' + value_yvalue + ', ' + value_zvalue + ', ' +
      value_offsetx + ', ' + value_offsety + ', ' + value_offsetz + ', ' +
      value_maxspeed + ', ' + value_endspeed + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_movel_joint_offset'] = function(block) {
  var value_jvalue1 = Blockly.CSharp.valueToCode(block, 'JValue1',
      Blockly.CSharp.ORDER_ATOMIC) || '-90.0';
  var value_jvalue2 = Blockly.CSharp.valueToCode(block, 'JValue2',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_jvalue3 = Blockly.CSharp.valueToCode(block, 'JValue3',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_jvalue4 = Blockly.CSharp.valueToCode(block, 'JValue4',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.CSharp.valueToCode(block,'OffSetX',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.CSharp.valueToCode(block,'OffSetY',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.CSharp.valueToCode(block,'OffSetZ',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  //var value_offsetw = Blockly.CSharp.valueToCode(block,'OffSetW',
  //    Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "关节角度 加偏移量直线定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "关节角度 加偏移量直线定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      block.setWarningText(Blockly.Msg.MOTION_ERROR_SPEEDERROR);
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      block.setWarningText(null);
    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MoveL_JointOffset( ' + value_jvalue1 + ', ' + value_jvalue2 + ', ' + value_jvalue3 + ', ' + value_jvalue4 + ', ' +
      value_offsetx + ', ' + value_offsety + ', ' + value_offsetz + ', '  +
      value_maxspeed + ', ' + value_endspeed + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 * P点 坐标点编号门型定位
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_moveptp_point'] = function(block) {
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_heightavoid = Blockly.CSharp.valueToCode(block, 'HeightAvoid',
      Blockly.CSharp.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var PosAdjustValue = {
    'true' : 'true',
    'false' : 'false'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = (parseInt(value_pointvalue));//不能为负数
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  //var check = bound.checkPointIsContain(value_pointvalue);
  var pointError = null;
  if(isNaN(value_pointvalue) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString;
    pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR + "\r\n";
  }
  else
  {
    if(value_pointvalue < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "XYZW门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      pointError = Blockly.Msg.MOTION_ERROR_POINTINDEXERROR + "\r\n";
    }
    else
    {
      if(Blockly.CustomConfig.DebugMode) {
        var check = bound.checkPointIsContain(value_pointvalue);
        if (check) {
          //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
          //block.setWarningText(null);
        }
        else {
          Blockly.CSharp.workspaceToCodeError = true;
          pointError = Blockly.Msg.MOTION_ERROR_POINT_NOT_EXIST + value_pointvalue + "\r\n";
        }
      }
    }
  }

  var speedError = null;
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "P点门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "P点门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }
  if(!pointError && !speedError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(pointError) ErrorCode = ErrorCode + pointError;
    if(speedError) ErrorCode = ErrorCode + speedError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MovePTP_Point( ' + value_pointvalue + ', ' +
      value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      ', ' + dropdown_posadjustvalue + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *  XYZW 门型定位
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_moveptp_xyz'] = function(block) {
  var value_xvalue = Blockly.CSharp.valueToCode(block, 'XValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_yvalue = Blockly.CSharp.valueToCode(block, 'YValue',
      Blockly.CSharp.ORDER_ATOMIC) || '-300.0';
  var value_zvalue = Blockly.CSharp.valueToCode(block, 'ZValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_wvalue = Blockly.CSharp.valueToCode(block, 'WValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_heightavoid = Blockly.CSharp.valueToCode(block, 'HeightAvoid',
      Blockly.CSharp.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var PosAdjustValue = {
    'true' : 'true',
    'false' : 'false'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "XYZW门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    block.setWarningText("XYZW门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n");
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "XYZW门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      block.setWarningText("XYZW门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n");
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      block.setWarningText(null);
    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MovePTP_XYZW( ' + value_xvalue + ', ' + value_yvalue + ', ' + value_zvalue + ', ' + value_wvalue + ', ' +
      value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      ', ' + dropdown_posadjustvalue + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 * J1 J2 J3 J4 门型定位
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_moveptp_joint'] = function(block) {
  var value_jvalue1 = Blockly.CSharp.valueToCode(block, 'JValue1',
      Blockly.CSharp.ORDER_ATOMIC) || '-90.0';
  var value_jvalue2 = Blockly.CSharp.valueToCode(block, 'JValue2',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_jvalue3 = Blockly.CSharp.valueToCode(block, 'JValue3',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_jvalue4 = Blockly.CSharp.valueToCode(block, 'JValue4',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_heightavoid = Blockly.CSharp.valueToCode(block, 'HeightAvoid',
      Blockly.CSharp.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var PosAdjustValue = {
    'true' : 'true',
    'false' : 'false'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "关节坐标门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    block.setWarningText("XYZW门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n");
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "关节坐标门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      block.setWarningText("关节坐标门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n");
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      block.setWarningText(null);
    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MovePTP_Joint( ' + value_jvalue1 + ', ' + value_jvalue2 + ', ' + value_jvalue3 + ', ' + value_jvalue4 + ', ' +
      value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      ', ' + dropdown_posadjustvalue + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_moveptp_point_offset'] = function(block) {
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_heightavoid = Blockly.CSharp.valueToCode(block, 'HeightAvoid',
      Blockly.CSharp.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.CSharp.valueToCode(block,'OffSetX',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.CSharp.valueToCode(block,'OffSetY',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.CSharp.valueToCode(block,'OffSetZ',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  //var value_offsetw = Blockly.CSharp.valueToCode(block,'OffSetW',
  //    Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var PosAdjustValue = {
    'true' : 'true',
    'false' : 'false'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  var value_offsetw = '0.0';
  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);//不能为负数
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  var pointError = null;
  if(isNaN(value_pointvalue))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "P点 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    pointError = "P点 加偏移量门型定位方式函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_pointvalue < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "P点 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      pointError = "P点 加偏移量门型定位方式函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
    }
    else
    {
      if(Blockly.CustomConfig.DebugMode) {
        var check = bound.checkPointIsContain(value_pointvalue);
        if (check) {
          //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
          //block.setWarningText(null);
        }
        else {
          Blockly.CSharp.workspaceToCodeError = true;
          pointError = "P" + value_pointvalue + "点不存在";
        }
      }
    }
  }

  var speedError = null;
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "P点 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    speedError = "P点 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "P点 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      speedError = "P点 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }
  if(!pointError && !speedError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(pointError) ErrorCode = ErrorCode + pointError;
    if(speedError) ErrorCode = ErrorCode + speedError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MovePTP_PointOffset( ' + value_pointvalue + ', ' +
      value_offsetx + ', ' + value_offsety + ', ' + value_offsetz + ', ' + value_offsetw + ', ' +
      value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      ', ' + dropdown_posadjustvalue + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_moveptp_xyz_offset'] = function(block) {
  var value_xvalue = Blockly.CSharp.valueToCode(block, 'XValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_yvalue = Blockly.CSharp.valueToCode(block, 'YValue',
      Blockly.CSharp.ORDER_ATOMIC) || '-300.0';
  var value_zvalue = Blockly.CSharp.valueToCode(block, 'ZValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_wvalue = Blockly.CSharp.valueToCode(block, 'WValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_heightavoid = Blockly.CSharp.valueToCode(block, 'HeightAvoid',
      Blockly.CSharp.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.CSharp.valueToCode(block,'OffSetX',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.CSharp.valueToCode(block,'OffSetY',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.CSharp.valueToCode(block,'OffSetZ',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  //var value_offsetw = Blockly.CSharp.valueToCode(block,'OffSetW',
  //    Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var PosAdjustValue = {
    'true' : 'true',
    'false' : 'false'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  var value_offsetw = '0.0';
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "XYZW 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    block.setWarningText("XYZW 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n");
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "XYZW 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      block.setWarningText("XYZW 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n");
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      block.setWarningText(null);
    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MovePTP_XYZWOffset( ' + value_xvalue + ', ' + value_yvalue + ', ' + value_zvalue + ', ' + value_wvalue + ', ' +
      value_offsetx + ', ' + value_offsety + ', ' + value_offsetz + ', ' + value_offsetw + ', ' +
      value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      ', ' + dropdown_posadjustvalue + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_moveptp_joint_offset'] = function(block) {
  var value_jvalue1 = Blockly.CSharp.valueToCode(block, 'JValue1',
      Blockly.CSharp.ORDER_ATOMIC) || '-90.0';
  var value_jvalue2 = Blockly.CSharp.valueToCode(block, 'JValue2',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_jvalue3 = Blockly.CSharp.valueToCode(block, 'JValue3',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_jvalue4 = Blockly.CSharp.valueToCode(block, 'JValue4',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_heightavoid = Blockly.CSharp.valueToCode(block, 'HeightAvoid',
      Blockly.CSharp.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_offsetx = Blockly.CSharp.valueToCode(block,'OffSetX',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsety = Blockly.CSharp.valueToCode(block,'OffSetY',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_offsetz = Blockly.CSharp.valueToCode(block,'OffSetZ',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  //var value_offsetw = Blockly.CSharp.valueToCode(block,'OffSetW',
  //    Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var PosAdjustValue = {
    'true' : 'true',
    'false' : 'false'
  };
  var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];
  var value_offsetw = '0.0';
  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "关节角度 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    block.setWarningText("关节角度 加偏移量门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n");
  }
  else
  {
    if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_maxspeed = 200;
      value_endspeed = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "关节角度 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      block.setWarningText("关节角度 加偏移量门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n");
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      block.setWarningText(null);
    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'RobotMove.MovePTP_JointOffset( ' + value_jvalue1 + ', ' + value_jvalue2 + ', ' + value_jvalue3 + ', ' + value_jvalue4 + ', ' +
      value_offsetx + ', ' + value_offsety + ', ' + value_offsetz + ', ' + value_offsetw + ', ' +
      value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      ', ' + dropdown_posadjustvalue + ');' +
      Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_moveptp_dir_offset'] = function(block) {
    var value_startpoint = Blockly.CSharp.valueToCode(block, 'StartPoint',
        Blockly.CSharp.ORDER_ATOMIC) || '0';
    var value_dirpoint = Blockly.CSharp.valueToCode(block, 'DirPoint',
        Blockly.CSharp.ORDER_ATOMIC) || '0';
    var value_heightavoid = Blockly.CSharp.valueToCode(block, 'HeightAvoid',
        Blockly.CSharp.ORDER_ATOMIC) || '25.0';
    var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
        Blockly.CSharp.ORDER_ATOMIC) || '1000';
    var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
        Blockly.CSharp.ORDER_ATOMIC) || '0';
    var value_offset = Blockly.CSharp.valueToCode(block,'OffSet',
        Blockly.CSharp.ORDER_ATOMIC) || '0.0';

    var PosAdjustValue = {
        'true' : 'true',
        'false' : 'false'
    };
    var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];

    value_startpoint = value_startpoint.replace('(','');
    value_startpoint = value_startpoint.replace(')','');
    //value_startpoint = parseInt(value_startpoint);//不能为负数
    value_dirpoint = value_dirpoint.replace('(','');
    value_dirpoint = value_dirpoint.replace(')','');
    // value_dirpoint = parseInt(value_dirpoint);//不能为负数
    value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
    value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
    value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
    value_endspeed = parseInt(value_endspeed);
    var pointError = null;
    // if(isNaN(value_startpoint) || isNaN(value_dirpoint))//NaN 错误
    // {
    //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    //     value_startpoint = 0;
    //     value_dirpoint =0;
    //     Blockly.CSharp.workspaceToCodeError = true;
    //     Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
    //         + "任一方向偏移门型定位方式函数转换出错,请检查坐标点编号是否正确,只能填写大于或等于0整数;\r\n";
    //     pointError = "任一方向偏移门型定位方式函数转换出错,请检查坐标点编号是否正确,只能填写大于或等于0整数;\r\n";
    // }
    // else
    // {
    // if(value_startpoint< 0 || value_dirpoint< 0 )//<=0 错误
    // {
    //     value_startpoint = 0;
    //     value_dirpoint =0;
    //     Blockly.CSharp.workspaceToCodeError = true;
    //     Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
    //         + "任一方向偏移门型定位方式函数转换出错,坐标点编号需要设置为大于或等于0的整数;\r\n";
    //     pointError = "任一方向偏移门型定位方式函数转换出错,请检查坐标点编号是否正确,只能填写大于或等于0整数;\r\n";
    // }
    // else
    // {
    //     if(Blockly.CustomConfig.DebugMode) {
    //         var check = bound.checkPointIsContain(value_startpoint) ;
    //         if (check) {
    //             //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    //             //block.setWarningText(null);
    //         }
    //         else {
    //             Blockly.CSharp.workspaceToCodeError = true;
    //             pointError = value_startpoint + "点不存在";
    //         }
    //         var check1=bound.checkPointIsContain(value_dirpoint);
    //         if (!check1){
    //             Blockly.CSharp.workspaceToCodeError = true;
    //             pointError = value_dirpoint + "点不存在";
    //         }
    //     }
    // }
    // }

    var speedError = null;
    if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
    {
        //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        value_maxspeed = 200;
        value_endspeed = 0;
        Blockly.CSharp.workspaceToCodeError = true;
        Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
            + "任一方向偏移门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
        speedError = "任一方向偏移门型定位方式函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
        if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
        {
            //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
            value_maxspeed = 200;
            value_endspeed = 0;
            Blockly.CSharp.workspaceToCodeError = true;
            Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
                + "任一方向偏移门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
            speedError = "任一方向偏移门型定位方式函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
        }
        else
        {
            //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
            //block.setWarningText(null);
        }
    }
    if(!pointError && !speedError)
    {
        block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
        block.setWarningText(null);
    }
    else
    {
        Blockly.CSharp.workspaceToCodeError = true;
        var ErrorCode = "";
        if(pointError) ErrorCode = ErrorCode + pointError;
        if(speedError) ErrorCode = ErrorCode + speedError;
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        block.setWarningText(ErrorCode);
    }
    var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
        Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
        'RobotMove.MovePTP_Dir_Offset( ' + value_startpoint + ', ' +
        value_dirpoint + ', ' + value_offset + ', ' +value_maxspeed + ', ' +
        value_endspeed +  ', ' + value_heightavoid + ', ' + dropdown_posadjustvalue + ');' +
        Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
        Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
    //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
    return code;
};


/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_move_coordinate_offset'] = function(block) {
    var value_startpoint = Blockly.CSharp.valueToCode(block, 'StartPoint',
        Blockly.CSharp.ORDER_ATOMIC) || '0';
    var value_xpoint = Blockly.CSharp.valueToCode(block, 'XPoint',
        Blockly.CSharp.ORDER_ATOMIC) || '0';
    var value_ypoint = Blockly.CSharp.valueToCode(block, 'YPoint',
        Blockly.CSharp.ORDER_ATOMIC) || '0';
    var value_xstep = Blockly.CSharp.valueToCode(block,'XStep',
        Blockly.CSharp.ORDER_ATOMIC) || '0.0';
    var value_ystep = Blockly.CSharp.valueToCode(block,'YStep',
        Blockly.CSharp.ORDER_ATOMIC) || '0.0';
    var value_xindex = Blockly.CSharp.valueToCode(block,'XIndex',
        Blockly.CSharp.ORDER_ATOMIC) || '0.0';
    var value_yindex = Blockly.CSharp.valueToCode(block,'YIndex',
        Blockly.CSharp.ORDER_ATOMIC) || '0.0';
    var value_heightavoid = Blockly.CSharp.valueToCode(block, 'HeightAvoid',
        Blockly.CSharp.ORDER_ATOMIC) || '25.0';
    var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
        Blockly.CSharp.ORDER_ATOMIC) || '1000';
    var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
        Blockly.CSharp.ORDER_ATOMIC) || '0';

    var PosAdjustValue = {
        'true' : 'true',
        'false' : 'false'
    };
    var dropdown_posadjustvalue = PosAdjustValue[block.getFieldValue('TrueOrFalse')];

    value_startpoint = value_startpoint.replace('(',''); value_startpoint = value_startpoint.replace(')','');
    //value_startpoint = parseInt(value_startpoint);//不能为负数
    value_xpoint = value_xpoint.replace('(',''); value_xpoint = value_xpoint.replace(')','');
    value_ypoint = value_ypoint.replace('(',''); value_ypoint = value_ypoint.replace(')','');
    value_xindex = value_xindex.replace('(',''); value_xindex = value_xindex.replace(')','');
    value_yindex = value_yindex.replace('(',''); value_yindex = value_yindex.replace(')','');
    value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
    value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
    // value_xindex = parseInt(value_xindex);
    // value_yindex = parseInt(value_yindex);
    value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
    value_endspeed = parseInt(value_endspeed);
    var indexError = null;
    // if(isNaN(value_xindex) || isNaN(value_yindex))//NaN 错误
    // {
    //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    //     value_xindex = 0;
    //     value_yindex =0;
    //     Blockly.CSharp.workspaceToCodeError = true;
    //     Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
    //         + "摆盘函数转换出错,请检查行编号和列编号设置是否正确,只能填写大于或等于0的整数;\r\n";
    //     indexError = "摆盘函数转换出错,请检查行编号和列编号是否正确,只能填写大于或等于0的整数;\r\n";
    // }
    // else
    // {
    //   if(value_xindex< 0 || value_xindex< 0 )//<0 错误
    //   {
    //     value_xindex = 0;
    //     value_xindex =0;
    //     Blockly.CSharp.workspaceToCodeError = true;
    //     Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
    //         + "摆盘函数转换出错,行编号和列编号应该为大于或等于0的整数;\r\n";
    //     indexError = "摆盘函数转换出错,请检查坐标点编号是否正确,只能填写大于或等于0的整数;\r\n";
    //   }
    //   // else
    //   // {
    //   //   if(Blockly.CustomConfig.DebugMode) {
    //   //     var check = bound.checkPointIsContain(value_startpoint) ;
    //   //     if (check) {
    //   //         //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    //   //         //block.setWarningText(null);
    //   //     }
    //   //     else {
    //   //         Blockly.CSharp.workspaceToCodeError = true;
    //   //         indexError = value_startpoint + "点不存在";
    //   //     }
    //   //     var check1=bound.checkPointIsContain(value_dirpoint);
    //   //     if (!check1){
    //   //         Blockly.CSharp.workspaceToCodeError = true;
    //   //         indexError = value_dirpoint + "点不存在";
    //   //     }
    //   //   }
    //   // }
    // }

    var speedError = null;
    if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
    {
        //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        value_maxspeed = 200;
        value_endspeed = 0;
        Blockly.CSharp.workspaceToCodeError = true;
        Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
            + "摆盘函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
        speedError = "摆盘函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
        if(value_maxspeed <= 0 || value_endspeed < 0)//<=0 错误
        {
            //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
            value_maxspeed = 200;
            value_endspeed = 0;
            Blockly.CSharp.workspaceToCodeError = true;
            Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
                + "摆盘函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
            speedError = "摆盘函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
        }
        else
        {
            //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
            //block.setWarningText(null);
        }
    }
    if(!indexError && !speedError)
    {
        block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
        block.setWarningText(null);
    }
    else
    {
        Blockly.CSharp.workspaceToCodeError = true;
        var ErrorCode = "";
        if(indexError) ErrorCode = ErrorCode + indexError;
        if(speedError) ErrorCode = ErrorCode + speedError;
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        block.setWarningText(ErrorCode);
    }
    var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
        Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
        'RobotMove.MovePTP_Coordinate( ' + value_startpoint + ', ' + value_xpoint + ', ' + value_ypoint + ', ' +
        value_xstep + ', ' + value_ystep + ', ' + value_xindex + ', ' + value_yindex + ', ' +value_maxspeed + ', ' +
        value_endspeed +  ', ' + value_heightavoid + ', ' + dropdown_posadjustvalue + ');' +
        Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
        Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
    //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
    return code;
};


/**
 *
 */
Blockly.CSharp['motion_waitrobot'] = function (block) {
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      'RobotMove.WaitRobot();'+
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.CSharp['motion_getcurrent_axispos'] = function(block) {
  var AxisName = {
    'XValue' : '0',
    'YValue' : '1',
    'ZValue' : '2',
    'WValue' : '3'
  };
  var dropdown_axis = AxisName[block.getFieldValue('Axis')];
  var code = 'RobotMove.GetAxisPos( ' + dropdown_axis + ')';
  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.MOTION_ERROR_READERROR);
  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  return [code, Blockly.CSharp.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.CSharp['motion_getcurrent_jointangle'] = function(block) {
  var JointName = {
    'JointValue1' : '0',
    'JointValue2' : '1',
    'JointValue3' : '2',
    'JointValue4' : '3'
  };
  var dropdown_jointangle = JointName[block.getFieldValue('JointAngle')];
  var code = 'RobotMove.GetJointAngle( ' + dropdown_jointangle + ')';
  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.MOTION_ERROR_READERROR);
  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  return [code, Blockly.CSharp.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.CSharp['motion_getaxispos_frompoint'] = function(block) {
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var AxisName = {
    'XValue' : '0',
    'YValue' : '1',
    'ZValue' : '2',
    'WValue' : '3'
  };
  var dropdown_axis = AxisName[block.getFieldValue('Axis')];
  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);
  var pointError = null;
  var connectError = null;
  if(!block.parentBlock_ )
  {
    Blockly.CSharp.workspaceToCodeError = true;
    connectError = Blockly.Msg.MOTION_ERROR_READERROR;
  }

  if(isNaN(value_pointvalue) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "获取坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
    pointError = "获取坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_pointvalue < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "获取坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
      pointError = "获取坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
    }
    else
    {
      var check = true;
      //var check = bound.checkPointIsContain(value_pointvalue);
      if(check) {
        //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
        //block.setWarningText(null);
      }
      else
      {
        Blockly.CSharp.workspaceToCodeError = true;
        pointError = "P" + value_pointvalue + "点不存在";
      }
    }
  }

  if(!pointError && !connectError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(pointError) ErrorCode = ErrorCode + pointError;
    if(connectError) ErrorCode = ErrorCode + connectError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }
  var code = 'RobotMove.GetPointPos( ' + value_pointvalue + ', ' + dropdown_axis + ')';
  return [code, Blockly.CSharp.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.CSharp['motion_getjointangle_frompoint'] = function(block) {
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var JointName = {
    'JointValue1' : '0',
    'JointValue2' : '1',
    'JointValue3' : '2',
    'JointValue4' : '3'
  };
  var dropdown_jointangle = JointName[block.getFieldValue('JointAngle')];
  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);
  var pointError = null;
  var connectError = null;
  if(!block.parentBlock_ )
  {
    Blockly.CSharp.workspaceToCodeError = true;
    connectError = Blockly.Msg.MOTION_ERROR_READERROR;
  }

  if(isNaN(value_pointvalue))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "获取坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
    pointError = "获取坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_pointvalue < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "获取坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
      pointError = "获取坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
    }
    else
    {
      if(Blockly.CustomConfig.DebugMode) {
        var check = bound.checkPointIsContain(value_pointvalue);
        if (check) {
          //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
          //block.setWarningText(null);
        }
        else {
          Blockly.CSharp.workspaceToCodeError = true;
          pointError = "P" + value_pointvalue + "点不存在";
        }
      }
    }
  }
  // if(!pointError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.CSharp.workspaceToCodeError = true;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(pointError);
  // }
  if(!pointError && !connectError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(pointError) ErrorCode = ErrorCode + pointError;
    if(connectError) ErrorCode = ErrorCode + connectError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }
  var code = 'RobotMove.GetPointAngle( ' + value_pointvalue + ', ' + dropdown_jointangle + ')';
  return [code, Blockly.CSharp.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_setaxispos_topoint'] = function(block) {
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_xvalue = Blockly.CSharp.valueToCode(block, 'XValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_yvalue = Blockly.CSharp.valueToCode(block, 'YValue',
      Blockly.CSharp.ORDER_ATOMIC) || '-300.0';
  var value_zvalue = Blockly.CSharp.valueToCode(block, 'ZValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_wvalue = Blockly.CSharp.valueToCode(block, 'WValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';

  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);
  var pointError = null;
  if(isNaN(value_pointvalue) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "设置坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
    pointError = "设置坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_pointvalue < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "设置坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
      pointError = "设置坐标点XYZW位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
    }
    else
    {
      if(Blockly.CustomConfig.DebugMode) {
        var check = bound.checkPointIsContain(value_pointvalue);
        if (check) {
          //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
          //block.setWarningText(null);
        }
        else {
          Blockly.CSharp.workspaceToCodeError = true;
          pointError = "P" + value_pointvalue + "点不存在";
        }
      }
    }
  }
  if(!pointError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(pointError);
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      'RobotMove.SetPointPos( ' + value_pointvalue + ', ' +
      value_xvalue + ', ' + value_yvalue + ', ' + value_zvalue + ', ' + value_wvalue +');' +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_setjointangle_topoint'] = function(block) {
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_jvalue1 = Blockly.CSharp.valueToCode(block, 'JValue1',
      Blockly.CSharp.ORDER_ATOMIC) || '-90.0';
  var value_jvalue2 = Blockly.CSharp.valueToCode(block, 'JValue2',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_jvalue3 = Blockly.CSharp.valueToCode(block, 'JValue3',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';
  var value_jvalue4 = Blockly.CSharp.valueToCode(block, 'JValue4',
      Blockly.CSharp.ORDER_ATOMIC) || '0.0';

  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);
  var pointError = null;
  if(isNaN(value_pointvalue) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "设置坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
    pointError = "设置坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_pointvalue < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "设置坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
      pointError = "设置坐标点关节角度位置函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
    }
    else
    {
      if(Blockly.CustomConfig.DebugMode) {
        var check = bound.checkPointIsContain(value_pointvalue);
        if (check) {
          //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
          //block.setWarningText(null);
        }
        else {
          Blockly.CSharp.workspaceToCodeError = true;
          pointError = "P" + value_pointvalue + "点不存在";
        }
      }
    }
  }
  if(!pointError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(pointError);
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      'RobotMove.SetPointAngle( ' + value_pointvalue + ', ' +
      value_jvalue1 + ', ' + value_jvalue2 + ', ' + value_jvalue3 + ', ' + value_jvalue4 +');' +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.CSharp['motion_getinputvalue'] = function(block) {
  var Index = {
    'Input1' : '0',
    'Input2' : '1',
    'Input3' : '2',
    'Input4' : '3',
    'Input5' : '4',
    'Input6' : '5',
    'Input7' : '6',
    'Input8' : '7',
    'Input9' : '8',
    'Input10' : '9',
    'Input11' : '10',
    'Input12' : '11',
    'Input13' : '12',
    'Input14' : '13',
    'Input15' : '14',
    'Input16' : '15'
  };
  var dropdown_inputnum = Index[block.getFieldValue('InputNum')];
  var code = 'RobotMove.GetInputValue( ' + dropdown_inputnum + ')';
  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.MOTION_ERROR_READERROR);
  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  return [code, Blockly.CSharp.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.CSharp['motion_getoutputvalue'] = function(block) {
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
  var code = 'RobotMove.GetOutputValue( ' + dropdown_outputnum + ')';
  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.MOTION_ERROR_READERROR);
  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  return [code, Blockly.CSharp.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_setoutputvalue_dropdown'] = function(block) {
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
  var OutputValue = {
    'true' : 'true',
    'false' : 'false'
  };
  var dropdown_outputnum = Index[block.getFieldValue('OutputNum')];
  var dropdown_outputvalue = OutputValue[block.getFieldValue('OutputValue')];
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      'RobotMove.SetOutputValue( ' + dropdown_outputnum + ', ' +dropdown_outputvalue + ');' +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
/**
Blockly.CSharp['motion_setoutputvalue_externalinput'] = function(block) {
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
  var value_outputvalue = Blockly.CSharp.valueToCode(block, 'OutputValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
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
Blockly.CSharp['motion_setcomport_parameter'] = function(block) {
  var dropdown_tpye = block.getFieldValue("Type");
  var value_comportnum = Blockly.CSharp.valueToCode(block, 'ComPortNum',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var dropdown_baudrate = block.getFieldValue('BaudRate');
  var dropdown_databit = block.getFieldValue('DataBit');
  var dropdown_stopbit = block.getFieldValue('StopBit');
  var dropdown_paritybit = block.getFieldValue('ParityBit');
  value_comportnum = value_comportnum.replace('(','');value_comportnum = value_comportnum.replace(')','');
  value_comportnum = parseInt(value_comportnum);
  if(isNaN(value_comportnum) )//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_comportnum = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "设置串口参数函数转换出错,请检查串口编号设置是否正确,只能填写正整数;\r\n";
    block.setWarningText("设置串口参数函数转换出错,请检查串口编号设置是否正确,只能填写正整数;\r\n");
  }
  else
  {
    if(value_comportnum < 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_comportnum = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "设置串口参数函数转换出错,请检查串口编号设置是否正确,只能填写正整数;\r\n";
      block.setWarningText("设置串口参数函数转换出错,请检查串口编号设置是否正确,只能填写正整数;\r\n");
    }
    else
    {
      //查找电脑中可用的串口号，并判断是否存在
      if(Blockly.CSharp.ComPortList.length == 0)
      {
        Blockly.CSharp.ComPortList.push(value_comportnum);
        block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
        block.setWarningText(null);
      }
      else
      {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        value_comportnum = 0;
        Blockly.CSharp.workspaceToCodeError = true;

        block.setWarningText("目前串口通讯功能只支持单个串口!请勿重复使用!\r\n");
        /*
        if(Blockly.CSharp.ComPortList.indexOf(value_comportnum) != -1)
        {
          block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
          value_comportnum = 0;
          Blockly.CSharp.workspaceToCodeError = true;

          block.setWarningText("串口号设置重复,请注意检查!同一个串口号只能初始化一次!;\r\n");
        }
        else
        {
          Blockly.CSharp.ComPortList.push(value_comportnum);
          block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
          block.setWarningText(null);
        }
        */
      }

    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      'ComPort.SetComPortParam( ' + value_comportnum + ', ' + dropdown_tpye + ', ' + dropdown_baudrate + ', '
      + dropdown_databit + ', '+ dropdown_stopbit + ', "'+ dropdown_paritybit + '");' +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.CSharp['motion_getplc_coilstatus'] = function(block) {
  var value_coilnum = Blockly.CSharp.valueToCode(block, 'CoilNum',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  value_coilnum = value_coilnum.replace('(','');value_coilnum = value_coilnum.replace(')','');
  value_coilnum = parseInt(value_coilnum);
  var coilnumError = null;
  var InitialError = null;
  var connectError = null;
  if(!block.parentBlock_ )
  {
    Blockly.CSharp.workspaceToCodeError = true;
    connectError = Blockly.Msg.MOTION_ERROR_READERROR;
  }
  if(isNaN(value_coilnum) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_coilnum = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    // Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
    //     + "读取PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n";
    //block.setWarningText("读取PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\n");
    coilnumError = "读取PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;";
  }
  else
  {
    if(value_coilnum < 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_coilnum = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      // Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
      //     + "读取PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n";
      // block.setWarningText("读取PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\n");
      coilnumError = "读取PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;";
    }
    else
    {
      if(Blockly.CSharp.ComPortList.length == 0)
      {
        //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        value_coilnum = 0;
        Blockly.CSharp.workspaceToCodeError = true;
        //block.setWarningText("串口参数还未初始化,请先调用串口参数初始化模块!\n");
        InitialError = "串口参数还未初始化,请先调用串口参数初始化模块!";
      }
      // else {
      //   block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //   block.setWarningText(null);
      // }
    }
  }

  var code = 'ComPort.GetCoilStatus( ' + value_coilnum + ')';
  if(!coilnumError && !InitialError && !connectError)
  {
       block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
       block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(coilnumError) ErrorCode = ErrorCode + coilnumError;
    if(InitialError) ErrorCode = ErrorCode + InitialError;
    if(connectError) ErrorCode = ErrorCode + connectError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }
  return [code, Blockly.CSharp.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {[null,null]}
 */
Blockly.CSharp['motion_getplc_registerdata'] = function(block) {
  var value_registernum = Blockly.CSharp.valueToCode(block, 'RegisterNum',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  value_registernum = value_registernum.replace('(','');value_registernum = value_registernum.replace(')','');
  value_registernum = parseInt(value_registernum);
  var registernumError = null;
  var InitialError = null;
  var connectError = null;
  if(!block.parentBlock_ )
  {
    Blockly.CSharp.workspaceToCodeError = true;
    connectError = Blockly.Msg.MOTION_ERROR_READERROR;
  }
  if(isNaN(value_registernum) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_registernum = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    // Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
    //     + "读取PLC寄存器数值函数转换出错,请检查寄存器编号设置是否正确,只能填写正整数;\r\n";
    // block.setWarningText("读取PLC寄存器数值函数转换出错,请检查寄存器编号设置是否正确,只能填写正整数;\n");
    registernumError = "读取PLC寄存器数值函数转换出错,请检查寄存器编号设置是否正确,只能填写正整数;";
  }
  else
  {
    if(value_registernum < 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_registernum = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      // Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
      //     + "读取PLC寄存器数值函数转换出错,请检查寄存器编号设置是否正确,只能填写正整数;\r\n";
      // block.setWarningText("读取PLC寄存器数值函数转换出错,请检查寄存器编号设置是否正确,只能填写正整数;\n");
      registernumError = "读取PLC寄存器数值函数转换出错,请检查寄存器编号设置是否正确,只能填写正整数;";
    }
    else
    {
      if(Blockly.CSharp.ComPortList.length == 0)
      {
        //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        value_registernum = 0;
        Blockly.CSharp.workspaceToCodeError = true;
        //block.setWarningText("串口参数还未初始化,请先调用串口参数初始化模块!\n");
        InitialError = "串口参数还未初始化,请先调用串口参数初始化模块!";
      }
      // else {
      //   block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //   block.setWarningText(null);
      // }
    }
  }
  var code = 'ComPort.GetRegisterData( ' + value_registernum +')';
  if(!registernumError && !InitialError && !connectError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(registernumError) ErrorCode = ErrorCode + registernumError;
    if(InitialError) ErrorCode = ErrorCode + InitialError;
    if(connectError) ErrorCode = ErrorCode + connectError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }
  return [code, Blockly.CSharp.ORDER_NONE];
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_setplc_registerdata'] = function(block) {
  var value_registernum = Blockly.CSharp.valueToCode(block, 'RegisterNum',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_registerdata = Blockly.CSharp.valueToCode(block, 'RegisterData',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  value_registernum = value_registernum.replace('(','');value_registernum = value_registernum.replace(')','');
  value_registerdata = value_registerdata.replace('(','');value_registerdata = value_registerdata.replace(')','');
  value_registernum = parseInt(value_registernum);
  //value_registerdata = parseInt(value_registerdata);//PLC寄存器数值 整型
  if(isNaN(value_registernum))// || isNaN(value_registerdata))//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_registernum = 0;
    //value_registerdata = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "设置PLC寄存器数值函数转换出错,请检查寄存器编号和寄存器数值设置是否正确,只能填写正整数;\r\n";
    block.setWarningText("设置PLC寄存器数值函数转换出错,请检查寄存器编号和寄存器数值设置是否正确,只能填写正整数;\r\n");
  }
  else
  {
    if(value_registernum < 0)// || value_registerdata < 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_registernum = 0;
      //value_registerdata = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "设置PLC寄存器数值函数转换出错,请检查寄存器编号和寄存器数值设置是否正确,只能填写正整数;\r\n";
      block.setWarningText("设置PLC寄存器数值函数转换出错,请检查寄存器编号和寄存器数值设置是否正确,只能填写正整数;\r\n");
    }
    else
    {
      if(Blockly.CSharp.ComPortList.length == 0)
      {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        value_registernum = 0;
        Blockly.CSharp.workspaceToCodeError = true;
        block.setWarningText("串口参数还未初始化,请先调用串口参数初始化模块!\n");
      }
      else {
        block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
        block.setWarningText(null);
      }
    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      'ComPort.SetRegisterData( ' + value_registernum + ', ' + value_registerdata + ');' +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_setplc_coilstatus'] = function(block) {
  var value_coilnum = Blockly.CSharp.valueToCode(block, 'CoilNum',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  //var value_coilstatus = Blockly.CSharp.valueToCode(block, 'CoilStatus',
  //    Blockly.CSharp.ORDER_ATOMIC) || 'false';
  var value_coilstatus = block.getFieldValue('SET_RST_CoilStatus');
  value_coilnum = value_coilnum.replace('(','');value_coilnum = value_coilnum.replace(')','');
  value_coilnum = parseInt(value_coilnum);
  if(isNaN(value_coilnum))//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_coilnum = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "设置PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n";
    block.setWarningText("设置PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n");
  }
  else
  {
    if(value_coilnum <= 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_coilnum = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "设置PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n";
      block.setWarningText("设置PLC线圈状态函数转换出错,请检查线圈编号设置是否正确,只能填写正整数;\r\n");
    }
    else
    {
      if(Blockly.CSharp.ComPortList.length == 0)
      {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        value_coilnum = 0;
        Blockly.CSharp.workspaceToCodeError = true;
        block.setWarningText("串口参数还未初始化,请先调用串口参数初始化模块!\n");
      }
      else {
        block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
        block.setWarningText(null);
      }
    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      'ComPort.SetCoilStatus( ' + value_coilnum + ', ' +value_coilstatus + ');' +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

/**
 *
 * @param block
 * @returns {string}
 */
Blockly.CSharp['motion_delaytime'] = function(block) {
  var uint = {
    'millisecond' : '1',
    'second' : '1000'
  };
  var value_delaytime = Blockly.CSharp.valueToCode(block, 'DelayTime',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var dropdown_unit = uint[block.getFieldValue('UNIT')];
  value_delaytime = value_delaytime.replace('(','');value_delaytime = value_delaytime.replace(')','');
  value_delaytime = parseFloat(value_delaytime) * parseFloat(dropdown_unit);
  value_delaytime = parseInt(value_delaytime);
  if(isNaN(value_delaytime))//NaN 错误
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_delaytime = 10;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "延时函数转换出错,请检查延时时间设置是否正确,只能填写正整数;\r\n";
    block.setWarningText("延时函数转换出错,请检查延时时间设置是否正确,只能填写正整数;\r\n");
  }
  else
  {
    if(value_delaytime <= 0)//<=0 错误
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_delaytime = 10;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "延时函数转换出错,请检查延时时间设置是否正确,只能填写正整数;\r\n";
      block.setWarningText("延时函数转换出错,请检查延时时间设置是否正确,只能填写正整数;\r\n");
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      block.setWarningText(null);
    }
  }
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      'UtilityClass.Delay_ms( ' + value_delaytime + ');' +
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};