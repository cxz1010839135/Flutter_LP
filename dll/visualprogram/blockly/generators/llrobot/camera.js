'use strict';

goog.provide("Blockly.LLRobot.camera");
goog.require("Blockly.LLRobot");
goog.require('Blockly.Blocks');
goog.require('Blockly.Block');
goog.require('Blockly.CustomConfig');


Blockly.LLRobot['camera_grabimage'] = function(block) {
  // Numeric value.
  var value_cameraindex = Blockly.LLRobot.valueToCode(block,'CameraIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_objectnumber = Blockly.LLRobot.valueToCode(block,'ObjectNumber',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = (parseInt(value_cameraindex));//不能为负数
  value_objectnumber = value_objectnumber.replace('(','');value_objectnumber = value_objectnumber.replace(')','');
  value_objectnumber = (parseInt(value_objectnumber));//不能为负数

  var code = '( ' + value_cameraindex + ')'+ Blockly.Msg.CAMERA_GRABIMAGE + '( ' + value_objectnumber + ')'+ Blockly.Msg.CAMERA_OBJECTNUMBER;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.LLRobot['camera_getgrabresult'] = function(block) {
  // Numeric value.
  var value_cameraindex = Blockly.LLRobot.valueToCode(block,'CameraIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.LLRobot.valueToCode(block,'ObjectIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = (parseInt(value_cameraindex));//不能为负数
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = (parseInt(value_objectindex));//不能为负数

  var code = '( ' + value_cameraindex + ')'+ Blockly.Msg.CAMERA_CAMERAINDEX + '( ' + value_objectindex + ')'+ Blockly.Msg.CAMERA_OBJECTINDEX + ' ' + Blockly.Msg.CAMERA_GRABRESULT;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.LLRobot['camera_getimagepos'] = function(block) {
  // Numeric value.
  var value_cameraindex = Blockly.LLRobot.valueToCode(block, 'CameraIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.LLRobot.valueToCode(block, 'ObjectIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var AxisName = {
    'XValue' : 'X',
    'YValue' : 'Y',
    'ZValue' : 'Z',
    'WValue' : 'W'
  };
  var dropdown_axis = AxisName[block.getFieldValue('Axis')];
  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = parseInt(value_cameraindex);
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = parseInt(value_objectindex);
  // var cameraindexError = null;
  // var connectError = null;
  // if(!block.parentBlock_ )
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   connectError = Blockly.Msg.MOTION_ERROR_READERROR;
  // }
  //
  // if(isNaN(value_cameraindex) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_cameraindex = 1;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查相机编号是否正确,只能填写正整数;\r\n";
  //   cameraindexError = "函数转换出错,请检查相机编号是否正确,只能填写正整数;\r\n";
  // }
  // else
  // {
  //   if(value_cameraindex < 0 )//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_cameraindex = 0;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "函数转换出错,请检查相机编号是否正确,只能填写正整数;\r\n";
  //     cameraindexError = "函数转换出错,请检查相机编号是否正确,只能填写正整数;\r\n";
  //   }
  //
  // }
  //
  // if(!cameraindexError && !connectError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrorCode = "";
  //   if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
  //   if(connectError) ErrorCode = ErrorCode + connectError;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(ErrorCode);
  // }
  var code = Blockly.Msg.CAMERA_GET + '( ' + value_cameraindex + ')'+ Blockly.Msg.CAMERA_CAMERAINDEX + '( '+ value_objectindex + ' )' + Blockly.Msg.CAMERA_OBJECTINDEX
      + Blockly.Msg.CAMERA_POS_AXISPOS + ', (' + dropdown_axis + ')';
  return [code, Blockly.LLRobot.ORDER_NONE];
};

Blockly.LLRobot['camera_image_to_image']=function (block) {
  var value_cameraindex1 = Blockly.LLRobot.valueToCode(block, 'CameraIndex1',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_cameraindex2 = Blockly.LLRobot.valueToCode(block, 'CameraIndex2',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_objectindex1 = Blockly.LLRobot.valueToCode(block, 'ObjectIndex1',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_objectindex2 = Blockly.LLRobot.valueToCode(block, 'ObjectIndex2',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.LLRobot.valueToCode(block, 'OffSetIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_heightavoid = Blockly.LLRobot.valueToCode(block, 'HeightAvoid',
      Blockly.LLRobot.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.LLRobot.valueToCode(block, 'MaxSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.LLRobot.valueToCode(block, 'EndSpeed',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';


  value_maxspeed = value_maxspeed.replace('(','');value_maxspeed = value_maxspeed.replace(')','');
  value_endspeed = value_endspeed.replace('(','');value_endspeed = value_endspeed.replace(')','');
  value_maxspeed = parseInt(value_maxspeed);//速度转换成整型
  value_endspeed = parseInt(value_endspeed);
  value_cameraindex1 = value_cameraindex1.replace('(','');value_cameraindex1 = value_cameraindex1.replace(')','');
  value_cameraindex2 = value_cameraindex2.replace('(','');value_cameraindex2 = value_cameraindex2.replace(')','');
  value_cameraindex1 = parseInt(value_cameraindex1);//速度转换成整型
  value_cameraindex2 = parseInt(value_cameraindex2);
  value_objectindex1 = value_objectindex1.replace('(','');value_objectindex1 = value_objectindex1.replace(')','');
  value_objectindex2 = value_objectindex2.replace('(','');value_objectindex2 = value_objectindex2.replace(')','');
  value_objectindex1 = parseInt(value_objectindex1);//速度转换成整型
  value_objectindex2 = parseInt(value_objectindex2);
  value_offsetindex = value_offsetindex.replace('(','');value_offsetindex = value_offsetindex.replace(')','');
  value_offsetindex = parseInt(value_offsetindex);
  //var check = bound.checkPointIsContain(value_pointvalue);


  // var speedError = null;
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
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
  //         + "函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // var cameraindexError = null;
  // if(isNaN(value_cameraindex1) || isNaN(value_cameraindex2))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_cameraindex1 = 1;
  //   value_cameraindex2 = 2;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //   speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  // }
  // else
  // {
  //   if(value_cameraindex1 <= 0 || value_cameraindex2 < 0)//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_cameraindex1 = 1;
  //     value_cameraindex2 = 2;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //     speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // if(!speedError && !cameraindexError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrorCode = "";
  //   if(speedError) ErrorCode = ErrorCode + speedError;
  //   if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(ErrorCode);
  // }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      // 'Camera.ImageMoveToImage( ' + value_cameraindex1 + ', ' + value_cameraindex2 + ', ' +
      // value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      // + ');' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      // Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
      '( ' + value_cameraindex1 + ' )' + Blockly.Msg.CAMERA_CAMERAINDEX + '( '+ value_objectindex1 + ' )' + Blockly.Msg.CAMERA_OBJECTINDEX
      + Blockly.Msg.CAMERA_IMAGE_POS + Blockly.Msg.CAMERA_PLACE +
      '( ' + value_cameraindex2 + ' )' + Blockly.Msg.CAMERA_CAMERAINDEX + '( '+ value_objectindex2 + ' )' + Blockly.Msg.CAMERA_OBJECTINDEX
      + Blockly.Msg.CAMERA_IMAGE_POS + Blockly.Msg.MOTION_HEIGHTAVOID +  '( ' + value_offsetindex + ' )' + Blockly.Msg.CAMERA_OFFSETINDEX +
      'H(' + value_heightavoid + ') ' + Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ') ' + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.LLRobot['camera_image_to_image_calculate']=function (block) {
  var value_cameraindex1 = Blockly.LLRobot.valueToCode(block, 'CameraIndex1',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_cameraindex2 = Blockly.LLRobot.valueToCode(block, 'CameraIndex2',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_objectindex1 = Blockly.LLRobot.valueToCode(block, 'ObjectIndex1',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_objectindex2 = Blockly.LLRobot.valueToCode(block, 'ObjectIndex2',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.LLRobot.valueToCode(block, 'OffSetIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_calculatepointvalue = Blockly.LLRobot.valueToCode(block, 'CalculatePointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '3000';



  value_calculatepointvalue = value_calculatepointvalue.replace('(','');value_calculatepointvalue = value_calculatepointvalue.replace(')','');

  value_calculatepointvalue = parseInt(value_calculatepointvalue);//速度转换成整型

  value_cameraindex1 = value_cameraindex1.replace('(','');value_cameraindex1 = value_cameraindex1.replace(')','');
  value_cameraindex2 = value_cameraindex2.replace('(','');value_cameraindex2 = value_cameraindex2.replace(')','');
  value_cameraindex1 = parseInt(value_cameraindex1);//速度转换成整型
  value_cameraindex2 = parseInt(value_cameraindex2);
  value_objectindex1 = value_objectindex1.replace('(','');value_objectindex1 = value_objectindex1.replace(')','');
  value_objectindex2 = value_objectindex2.replace('(','');value_objectindex2 = value_objectindex2.replace(')','');
  value_objectindex1 = parseInt(value_objectindex1);//速度转换成整型
  value_objectindex2 = parseInt(value_objectindex2);
  value_offsetindex = value_offsetindex.replace('(','');value_offsetindex = value_offsetindex.replace(')','');
  value_offsetindex = parseInt(value_offsetindex);
  //var check = bound.checkPointIsContain(value_pointvalue);


  // var speedError = null;
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
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
  //         + "函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // var cameraindexError = null;
  // if(isNaN(value_cameraindex1) || isNaN(value_cameraindex2))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_cameraindex1 = 1;
  //   value_cameraindex2 = 2;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //   speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  // }
  // else
  // {
  //   if(value_cameraindex1 <= 0 || value_cameraindex2 < 0)//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_cameraindex1 = 1;
  //     value_cameraindex2 = 2;
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //     speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // if(!speedError && !cameraindexError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrorCode = "";
  //   if(speedError) ErrorCode = ErrorCode + speedError;
  //   if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(ErrorCode);
  // }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      // 'Camera.ImageMoveToImage( ' + value_cameraindex1 + ', ' + value_cameraindex2 + ', ' +
      // value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      // + ');' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      // Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
      '( ' + value_cameraindex1 + ' )' + Blockly.Msg.CAMERA_CAMERAINDEX + '( '+ value_objectindex1 + ' )' + Blockly.Msg.CAMERA_OBJECTINDEX
      + Blockly.Msg.CAMERA_IMAGE_POS + Blockly.Msg.CAMERA_PLACE +
      '( ' + value_cameraindex2 + ' )' + Blockly.Msg.CAMERA_CAMERAINDEX + '( '+ value_objectindex2 + ' )' + Blockly.Msg.CAMERA_OBJECTINDEX
      + Blockly.Msg.CAMERA_IMAGE_POS +  ' ( ' + value_offsetindex + ' )' + Blockly.Msg.CAMERA_OFFSETINDEX
       + ' '+ Blockly.Msg.CAMERA_SAVE_TO_POINT + ' P(' + value_calculatepointvalue + ') ' + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.LLRobot['camera_image_to_fixedpos']=function (block) {
  var value_cameraindex = Blockly.LLRobot.valueToCode(block, 'CameraIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.LLRobot.valueToCode(block, 'ObjectIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.LLRobot.valueToCode(block, 'OffSetIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_heightavoid = Blockly.LLRobot.valueToCode(block, 'HeightAvoid',
      Blockly.LLRobot.ORDER_ATOMIC) || '25.0';
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
  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = parseInt(value_cameraindex);//速度转换成整型
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = parseInt(value_objectindex);//速度转换成整型
  value_offsetindex = value_offsetindex.replace('(','');value_offsetindex = value_offsetindex.replace(')','');
  value_offsetindex = parseInt(value_offsetindex);//速度转换成整型
  //var check = bound.checkPointIsContain(value_pointvalue);

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
  // var speedError = null;
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
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
  //         + "函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // var cameraindexError = null;
  // if(isNaN(value_cameraindex) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_cameraindex = 1;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //   speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  // }
  // else
  // {
  //   if(value_cameraindex <= 0)//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_cameraindex = 1;
  //
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //     speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // if(!pointError && !speedError && !cameraindexError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrorCode = "";
  //   if(speedError) ErrorCode = ErrorCode + speedError;
  //   if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(ErrorCode);
  // }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      // 'Camera.ImageMoveToFixedPos( ' + value_cameraindex + ', ' + value_pointvalue + ', ' +
      // value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      // + ');' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      // Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
      '( ' + value_cameraindex + ' )'  + Blockly.Msg.CAMERA_CAMERAINDEX + '( '+ value_objectindex + ' )' + Blockly.Msg.CAMERA_OBJECTINDEX + ' '+ Blockly.Msg.CAMERA_IMAGE_POS + Blockly.Msg.CAMERA_PLACE +
      Blockly.Msg.CAMERA_FIXED_POS +  'P ( ' + value_pointvalue + ' )'+
      Blockly.Msg.MOTION_HEIGHTAVOID +  '( ' + value_offsetindex + ' )' + Blockly.Msg.CAMERA_OFFSETINDEX +
      'H(' + value_heightavoid + ') ' + Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ') ' + '\n';

  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.LLRobot['camera_image_to_fixedpos_calculate']=function (block) {
  var value_cameraindex = Blockly.LLRobot.valueToCode(block, 'CameraIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.LLRobot.valueToCode(block, 'ObjectIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.LLRobot.valueToCode(block, 'OffSetIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_calculatepointvalue = Blockly.LLRobot.valueToCode(block, 'CalculatePointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '3000';

  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);//不能为负数

  value_calculatepointvalue = value_calculatepointvalue.replace('(','');value_calculatepointvalue = value_calculatepointvalue.replace(')','');

  value_calculatepointvalue = parseInt(value_calculatepointvalue);//速度转换成整型

  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = parseInt(value_cameraindex);//速度转换成整型
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = parseInt(value_objectindex);//速度转换成整型
  value_offsetindex = value_offsetindex.replace('(','');value_offsetindex = value_offsetindex.replace(')','');
  value_offsetindex = parseInt(value_offsetindex);//速度转换成整型
  //var check = bound.checkPointIsContain(value_pointvalue);

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
  // var speedError = null;
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
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
  //         + "函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // var cameraindexError = null;
  // if(isNaN(value_cameraindex) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_cameraindex = 1;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //   speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  // }
  // else
  // {
  //   if(value_cameraindex <= 0)//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_cameraindex = 1;
  //
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //     speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // if(!pointError && !speedError && !cameraindexError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrorCode = "";
  //   if(speedError) ErrorCode = ErrorCode + speedError;
  //   if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(ErrorCode);
  // }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      // 'Camera.ImageMoveToFixedPos( ' + value_cameraindex + ', ' + value_pointvalue + ', ' +
      // value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      // + ');' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      // Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
      '( ' + value_cameraindex + ' )'  + Blockly.Msg.CAMERA_CAMERAINDEX + '( '+ value_objectindex + ' )' + Blockly.Msg.CAMERA_OBJECTINDEX + ' '+ Blockly.Msg.CAMERA_IMAGE_POS + Blockly.Msg.CAMERA_PLACE +
      Blockly.Msg.CAMERA_FIXED_POS +  'P ( ' + value_pointvalue + ' )'+
        ' ( ' + value_offsetindex + ' )' + Blockly.Msg.CAMERA_OFFSETINDEX
      + ' ' + Blockly.Msg.CAMERA_SAVE_TO_POINT + ' P(' + value_calculatepointvalue + ') ' + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.LLRobot['camera_fixedpos_to_image']=function (block) {
  var value_cameraindex = Blockly.LLRobot.valueToCode(block, 'CameraIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.LLRobot.valueToCode(block, 'ObjectIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.LLRobot.valueToCode(block, 'OffSetIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_heightavoid = Blockly.LLRobot.valueToCode(block, 'HeightAvoid',
      Blockly.LLRobot.ORDER_ATOMIC) || '25.0';
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
  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = parseInt(value_cameraindex);//
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = parseInt(value_objectindex);//
  value_offsetindex = value_offsetindex.replace('(','');value_offsetindex = value_offsetindex.replace(')','');
  value_offsetindex = parseInt(value_offsetindex);//
  //var check = bound.checkPointIsContain(value_pointvalue);

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
  // var speedError = null;
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
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
  //         + "函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // var cameraindexError = null;
  // if(isNaN(value_cameraindex) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_cameraindex = 1;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //   speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  // }
  // else
  // {
  //   if(value_cameraindex <= 0)//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_cameraindex = 1;
  //
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //     speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // if(!pointError && !speedError && !cameraindexError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrorCode = "";
  //   if(speedError) ErrorCode = ErrorCode + speedError;
  //   if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(ErrorCode);
  // }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      // 'Camera.FixedPosMoveToImage( ' + value_cameraindex + ', ' + value_pointvalue + ', ' +
      // value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      // + ');' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      // Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
      '( ' + value_cameraindex + ' )' + Blockly.Msg.CAMERA_CAMERAINDEX + '( '+ value_objectindex + ' )' + Blockly.Msg.CAMERA_OBJECTINDEX + ' '+ Blockly.Msg.CAMERA_IMAGE_POS + Blockly.Msg.CAMERA_PLACE +
      Blockly.Msg.CAMERA_FIXED_POS +  'P ( ' + value_pointvalue + ' )'+
      Blockly.Msg.MOTION_HEIGHTAVOID +  '( ' + value_offsetindex + ' )' + Blockly.Msg.CAMERA_OFFSETINDEX +
      'H(' + value_heightavoid + ') ' + Blockly.Msg.MOTION_MAXSPEED + 'F('+ value_maxspeed + ') ' + Blockly.Msg.MOTION_ENDSPEED + 'f('+ value_endspeed + ') ' + '\n';

  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
    //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.LLRobot['camera_fixedpos_to_image_calculate']=function (block) {
  var value_cameraindex = Blockly.LLRobot.valueToCode(block, 'CameraIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.LLRobot.valueToCode(block, 'ObjectIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.LLRobot.valueToCode(block, 'OffSetIndex',
      Blockly.LLRobot.ORDER_ATOMIC) || '1';
  var value_pointvalue = Blockly.LLRobot.valueToCode(block, 'PointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '0';
  var value_calculatepointvalue = Blockly.LLRobot.valueToCode(block, 'CalculatePointValue',
      Blockly.LLRobot.ORDER_ATOMIC) || '3000';

  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);//不能为负数

  value_calculatepointvalue = value_calculatepointvalue.replace('(','');value_calculatepointvalue = value_calculatepointvalue.replace(')','');
  value_calculatepointvalue = parseInt(value_calculatepointvalue);//速度转换成整型

  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = parseInt(value_cameraindex);//
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = parseInt(value_objectindex);//
  value_offsetindex = value_offsetindex.replace('(','');value_offsetindex = value_offsetindex.replace(')','');
  value_offsetindex = parseInt(value_offsetindex);//
  //var check = bound.checkPointIsContain(value_pointvalue);

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
  // var speedError = null;
  // if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_maxspeed = 200;
  //   value_endspeed = 0;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
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
  //         + "函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
  //     speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // var cameraindexError = null;
  // if(isNaN(value_cameraindex) )//NaN 错误
  // {
  //   //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   value_cameraindex = 1;
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //       + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //   speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  // }
  // else
  // {
  //   if(value_cameraindex <= 0)//<=0 错误
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //     value_cameraindex = 1;
  //
  //     Blockly.LLRobot.workspaceToCodeError = true;
  //     Blockly.LLRobot.workspaceToCodeErrorString = Blockly.LLRobot.workspaceToCodeErrorString
  //         + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  //     speedError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  //   }
  //   else
  //   {
  //     //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
  //     //block.setWarningText(null);
  //   }
  // }
  //
  // if(!pointError && !speedError && !cameraindexError)
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
  //   block.setWarningText(null);
  // }
  // else
  // {
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   var ErrorCode = "";
  //   if(speedError) ErrorCode = ErrorCode + speedError;
  //   if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   block.setWarningText(ErrorCode);
  // }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      // 'Camera.FixedPosMoveToImage( ' + value_cameraindex + ', ' + value_pointvalue + ', ' +
      // value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
      // + ');' +
      // Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      // Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
      '( ' + value_cameraindex + ' )' + Blockly.Msg.CAMERA_CAMERAINDEX + '( '+ value_objectindex + ' )' + Blockly.Msg.CAMERA_OBJECTINDEX + ' '+ Blockly.Msg.CAMERA_IMAGE_POS + Blockly.Msg.CAMERA_PLACE +
      Blockly.Msg.CAMERA_FIXED_POS +  'P ( ' + value_pointvalue + ' )'+
        ' ( ' + value_offsetindex + ' )' + Blockly.Msg.CAMERA_OFFSETINDEX
      + ' '+ Blockly.Msg.CAMERA_SAVE_TO_POINT + ' P(' + value_calculatepointvalue + ') ' + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};