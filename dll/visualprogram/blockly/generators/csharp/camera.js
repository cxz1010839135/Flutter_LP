'use strict';

goog.provide("Blockly.CSharp.camera");
goog.require("Blockly.CSharp");
goog.require('Blockly.Blocks');
goog.require('Blockly.Block');
goog.require('Blockly.CustomConfig');

Blockly.CSharp['camera_grabimage'] = function(block) {
  // Numeric value.
  var value_cameraindex = Blockly.CSharp.valueToCode(block,'CameraIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_objectnumber = Blockly.CSharp.valueToCode(block,'ObjectNumber',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = (parseInt(value_cameraindex));//不能为负数
  value_objectnumber = value_objectnumber.replace('(','');value_objectnumber = value_objectnumber.replace(')','');
  value_objectnumber = (parseInt(value_objectnumber));//不能为负数
  var objectnumberError=null;
  var indexError = null;
  var connectError = null;
  if(!block.parentBlock_ )
  {
    Blockly.CSharp.workspaceToCodeError = true;
    connectError = Blockly.Msg.MOTION_ERROR_READERROR;
  }
  if(isNaN(value_cameraindex) )//NaN 错误
  {
    value_cameraindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString;
    indexError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  }
  else
  {
    if(value_cameraindex < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_cameraindex = 1;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,相机编号设置是否正确,只能填写正整数;\r\n";
      indexError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
    }
  }
  if(isNaN(value_objectnumber) )//NaN 错误
  {
    value_objectnumber = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString;
    objectnumberError = Blockly.Msg.CAMERA_ERROR_OBJECTNUMBERERROR + "\r\n";
  }
  else
  {
    if(value_objectnumber < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_objectnumber = 1;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,产品个数设置是否正确,只能填写正整数;\r\n";
      objectnumberError = Blockly.Msg.CAMERA_ERROR_OBJECTNUMBERERROR + "\r\n";
    }
  }
  if(!indexError&&!connectError&&!objectnumberError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(indexError) ErrorCode = ErrorCode + indexError;
    if(connectError) ErrorCode = ErrorCode + connectError;
    if(objectnumberError) ErrorCode = ErrorCode + objectnumberError;
    block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
    block.setWarningText(ErrorCode);
  }
  var code = 'Camera.GrabImage( ' + value_cameraindex + ' ,' + value_objectnumber +  ')';
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.CSharp['camera_getgrabresult'] = function(block){
  var value_cameraindex = Blockly.CSharp.valueToCode(block,'CameraIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.CSharp.valueToCode(block,'ObjectIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = (parseInt(value_cameraindex));//不能为负数
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = (parseInt(value_objectindex));//不能为负数
  var objectindexError=null;
  var indexError = null;
  var connectError = null;
  if(!block.parentBlock_ )
  {
    Blockly.CSharp.workspaceToCodeError = true;
    connectError = Blockly.Msg.MOTION_ERROR_READERROR;
  }
  if(isNaN(value_cameraindex) )//NaN 错误
  {
    value_cameraindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString;
    indexError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
  }
  else
  {
    if(value_cameraindex < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_cameraindex = 1;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,相机编号设置是否正确,只能填写正整数;\r\n";
      indexError = Blockly.Msg.CAMERA_ERROR_CAMERAINDEXERROR + "\r\n";
    }
  }
  if(isNaN(value_objectindex) )//NaN 错误
  {
    value_objectindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString;
    objectindexError = Blockly.Msg.CAMERA_ERROR_OBJECTNUMBERERROR + "\r\n";
  }
  else
  {
    if(value_objectindex < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_objectindex = 1;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,产品个数设置是否正确,只能填写正整数;\r\n";
      objectindexError = Blockly.Msg.CAMERA_ERROR_OBJECTNUMBERERROR + "\r\n";
    }
  }
  if(!indexError&&!connectError&&!objectindexError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(indexError) ErrorCode = ErrorCode + indexError;
    if(connectError) ErrorCode = ErrorCode + connectError;
    if(objectindexError) ErrorCode = ErrorCode + objectindexError;
    block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
    block.setWarningText(ErrorCode);
  }
  var code = 'Camera.GetGrabResult( ' + value_cameraindex + ' ,' + value_objectindex +  ')';
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.CSharp['camera_getimagepos'] = function(block) {
  // Numeric value.
  var value_cameraindex = Blockly.CSharp.valueToCode(block, 'CameraIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.CSharp.valueToCode(block,'ObjectIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var AxisName = {
    'XValue' : '0',
    'YValue' : '1',
    'ZValue' : '2',
    'WValue' : '3'
  };
  var dropdown_axis = AxisName[block.getFieldValue('Axis')];
  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = parseInt(value_cameraindex);
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = (parseInt(value_objectindex));//不能为负数
  var cameraindexError = null;
  var connectError = null;
  var objectindexError=null;
  if(!block.parentBlock_ )
  {
    Blockly.CSharp.workspaceToCodeError = true;
    connectError = Blockly.Msg.MOTION_ERROR_READERROR;
  }

  if(isNaN(value_cameraindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_cameraindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查相机编号是否正确,只能填写正整数;\r\n";
    cameraindexError = "函数转换出错,请检查相机编号是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_cameraindex < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_cameraindex = 1;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查相机编号是否正确,只能填写正整数;\r\n";
      cameraindexError = "函数转换出错,请检查相机编号是否正确,只能填写正整数;\r\n";
    }

  }
  if(isNaN(value_objectindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_objectindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查产品编号是否正确,只能填写正整数;\r\n";
    objectindexError = "函数转换出错,请检查产品编号是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_objectindex < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_objectindex = 1;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查产品编号是否正确,只能填写正整数;\r\n";
      objectindexError = "函数转换出错,请检查产品编号是否正确,只能填写正整数;\r\n";
    }

  }
  if(!cameraindexError && !connectError && !objectindexError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
    if(connectError) ErrorCode = ErrorCode + connectError;
    if(objectindexError) ErrorCode = ErrorCode + objectindexError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }
  var code = 'Camera.GetImagePos( ' + value_cameraindex + ', '+ value_objectindex + ', ' + dropdown_axis + ')';
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.CSharp['camera_image_to_image']=function (block) {
  var value_cameraindex1 = Blockly.CSharp.valueToCode(block, 'CameraIndex1',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_cameraindex2 = Blockly.CSharp.valueToCode(block, 'CameraIndex2',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_objectindex1 = Blockly.CSharp.valueToCode(block, 'ObjectIndex1',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_objectindex2 = Blockly.CSharp.valueToCode(block, 'ObjectIndex2',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.CSharp.valueToCode(block, 'OffSetIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_heightavoid = Blockly.CSharp.valueToCode(block, 'HeightAvoid',
      Blockly.CSharp.ORDER_ATOMIC) || '25.0';
  var value_maxspeed = Blockly.CSharp.valueToCode(block, 'MaxSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '1000';
  var value_endspeed = Blockly.CSharp.valueToCode(block, 'EndSpeed',
      Blockly.CSharp.ORDER_ATOMIC) || '0';


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
  //var check = bound.checkPointIsContain(value_pointvalue);


  var speedError = null;
  if(isNaN(value_maxspeed) || isNaN(value_endspeed))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_maxspeed = 200;
    value_endspeed = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
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
          + "函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var cameraindexError = null;
  if(isNaN(value_cameraindex1) || isNaN(value_cameraindex2))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_cameraindex1 = 1;
    value_cameraindex2 = 2;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_cameraindex1 <= 0 || value_cameraindex2 < 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_cameraindex1 = 1;
      value_cameraindex2 = 2;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
      cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var objectindexError = null;
  if(isNaN(value_objectindex1) || isNaN(value_objectindex2))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_objectindex1 = 1;
    value_objectindex2 = 2;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_objectindex1 <= 0 || value_objectindex2 < 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_objectindex1 = 1;
      value_objectindex2 = 2;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
      objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var offsetindexError = null;
  if(isNaN(value_offsetindex))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_offsetindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_offsetindex <= 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_offsetindex = 1;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
      offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  if(!speedError && !cameraindexError && !objectindexError && !offsetindexError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(speedError) ErrorCode = ErrorCode + speedError;
    if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
    if(objectindexError) ErrorCode = ErrorCode + objectindexError;
    if(offsetindexError) ErrorCode = ErrorCode + offsetindexError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'Camera.ImageMoveToImage( ' + value_cameraindex1 + ', ' + value_objectindex1 + ', ' + value_cameraindex2 + ', ' + value_objectindex2 + ', ' + value_offsetindex + ', ' +
      value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed +
       ')';// +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      //Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.CSharp['camera_image_to_image_calculate']=function (block) {
  var value_cameraindex1 = Blockly.CSharp.valueToCode(block, 'CameraIndex1',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_cameraindex2 = Blockly.CSharp.valueToCode(block, 'CameraIndex2',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_objectindex1 = Blockly.CSharp.valueToCode(block, 'ObjectIndex1',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_objectindex2 = Blockly.CSharp.valueToCode(block, 'ObjectIndex2',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.CSharp.valueToCode(block, 'OffSetIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_calculatepointvalue = Blockly.CSharp.valueToCode(block, 'CalculatePointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '3000';



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
  //var check = bound.checkPointIsContain(value_pointvalue);


  var pointError = null;
  if(isNaN(value_calculatepointvalue))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_calculatepointvalue=0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
    pointError = "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if( value_calculatepointvalue<0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_calculatepointvalue=0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
      pointError = "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      if(Blockly.CustomConfig.DebugMode) {

      }
    }
  }

  var cameraindexError = null;
  if(isNaN(value_cameraindex1) || isNaN(value_cameraindex2))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_cameraindex1 = 1;
    value_cameraindex2 = 2;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_cameraindex1 <= 0 || value_cameraindex2 < 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_cameraindex1 = 1;
      value_cameraindex2 = 2;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
      cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var objectindexError = null;
  if(isNaN(value_objectindex1) || isNaN(value_objectindex2))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_objectindex1 = 1;
    value_objectindex2 = 2;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_objectindex1 <= 0 || value_objectindex2 < 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_objectindex1 = 1;
      value_objectindex2 = 2;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
      objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var offsetindexError = null;
  if(isNaN(value_offsetindex))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_offsetindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_offsetindex <= 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_offsetindex = 1;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
      offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  if(!cameraindexError && !objectindexError && !offsetindexError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(pointError) ErrorCode = ErrorCode + pointError;
    if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
    if(objectindexError) ErrorCode = ErrorCode + objectindexError;
    if(offsetindexError) ErrorCode = ErrorCode + offsetindexError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'Camera.ImageMoveToImageCalculate( ' + value_cameraindex1 + ', ' + value_objectindex1 + ', ' + value_cameraindex2 + ', ' + value_objectindex2 + ', ' + value_offsetindex + ', ' +
      value_calculatepointvalue +
      ')';// +
     //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      //Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
    //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.CSharp['camera_image_to_fixedpos']=function (block) {
  var value_cameraindex = Blockly.CSharp.valueToCode(block, 'CameraIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.CSharp.valueToCode(block, 'ObjectIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.CSharp.valueToCode(block, 'OffSetIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_heightavoid = Blockly.CSharp.valueToCode(block, 'HeightAvoid',
      Blockly.CSharp.ORDER_ATOMIC) || '25.0';
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
  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = parseInt(value_cameraindex);//
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = parseInt(value_objectindex);//
  value_offsetindex = value_offsetindex.replace('(','');value_offsetindex = value_offsetindex.replace(')','');
  value_offsetindex = parseInt(value_offsetindex);//
  //var check = bound.checkPointIsContain(value_pointvalue);

  var pointError = null;
  if(isNaN(value_pointvalue))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
    pointError = "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_pointvalue < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
      pointError = "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
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
        + "函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
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
          + "函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var cameraindexError = null;
  if(isNaN(value_cameraindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_cameraindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_cameraindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_cameraindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
      cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var objectindexError = null;
  if(isNaN(value_objectindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_objectindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_objectindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_objectindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
      objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var offsetindexError = null;
  if(isNaN(value_offsetindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_offsetindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_offsetindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_offsetindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
      offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  if(!pointError && !speedError && !cameraindexError && !objectindexError && !offsetindexError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(pointError) ErrorCode = ErrorCode + pointError;
    if(speedError) ErrorCode = ErrorCode + speedError;
    if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
    if(objectindexError) ErrorCode = ErrorCode + objectindexError;
    if(offsetindexError) ErrorCode = ErrorCode + offsetindexError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'Camera.ImageMoveToFixedPos( ' + value_cameraindex + ', ' + value_objectindex + ', ' + value_pointvalue + ', ' + value_offsetindex + ', ' +
      value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed
      + ')';// +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
     // Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.CSharp['camera_image_to_fixedpos_calculate']=function (block) {
  var value_cameraindex = Blockly.CSharp.valueToCode(block, 'CameraIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.CSharp.valueToCode(block, 'ObjectIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.CSharp.valueToCode(block, 'OffSetIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_calculatepointvalue = Blockly.CSharp.valueToCode(block, 'CalculatePointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '3000';

  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);//不能为负数

  value_calculatepointvalue = value_calculatepointvalue.replace('(','');value_calculatepointvalue = value_calculatepointvalue.replace(')','');
  value_calculatepointvalue = parseInt(value_calculatepointvalue);//不能为负数

  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = parseInt(value_cameraindex);//
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = parseInt(value_objectindex);//
  value_offsetindex = value_offsetindex.replace('(','');value_offsetindex = value_offsetindex.replace(')','');
  value_offsetindex = parseInt(value_offsetindex);//
  //var check = bound.checkPointIsContain(value_pointvalue);

  var pointError = null;
  if(isNaN(value_pointvalue)|| isNaN(value_calculatepointvalue))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    value_calculatepointvalue=0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
    pointError = "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_pointvalue < 0 || value_calculatepointvalue<0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      value_calculatepointvalue=0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
      pointError = "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
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


  var cameraindexError = null;
  if(isNaN(value_cameraindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_cameraindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_cameraindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_cameraindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
      cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var objectindexError = null;
  if(isNaN(value_objectindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_objectindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_objectindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_objectindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
      objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var offsetindexError = null;
  if(isNaN(value_offsetindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_offsetindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_offsetindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_offsetindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
      offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  if(!pointError  && !cameraindexError && !objectindexError && !offsetindexError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(pointError) ErrorCode = ErrorCode + pointError;
    if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
    if(objectindexError) ErrorCode = ErrorCode + objectindexError;
    if(offsetindexError) ErrorCode = ErrorCode + offsetindexError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'Camera.ImageMoveToFixedPosCalculate( ' + value_cameraindex + ', ' + value_objectindex + ', ' + value_pointvalue + ', ' + value_offsetindex + ', ' +
      value_calculatepointvalue
      + ')';// +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      //Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
    //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.CSharp['camera_fixedpos_to_image']=function (block) {
  var value_cameraindex = Blockly.CSharp.valueToCode(block, 'CameraIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.CSharp.valueToCode(block, 'ObjectIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.CSharp.valueToCode(block, 'OffSetIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_heightavoid = Blockly.CSharp.valueToCode(block, 'HeightAvoid',
      Blockly.CSharp.ORDER_ATOMIC) || '25.0';
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
  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = parseInt(value_cameraindex);//
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = parseInt(value_objectindex);//
  value_offsetindex = value_offsetindex.replace('(','');value_offsetindex = value_offsetindex.replace(')','');
  value_offsetindex = parseInt(value_offsetindex);//
  //var check = bound.checkPointIsContain(value_pointvalue);

  var pointError = null;
  if(isNaN(value_pointvalue))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
    pointError = "函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_pointvalue < 0 )//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
      pointError = "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
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
        + "函数转换出错,请检查最大速度和最小速度设置是否正确,只能填写正整数;\r\n";
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
          + "函数转换出错,最大速度需要设置为大于0的整数,最小速度设置为大于等于0的整数;\r\n";
      speedError = Blockly.Msg.MOTION_ERROR_SPEEDERROR + "\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var cameraindexError = null;
  if(isNaN(value_cameraindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_cameraindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_cameraindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_cameraindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
      cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var objectindexError = null;
  if(isNaN(value_objectindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_objectindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_objectindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_objectindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
      objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var offsetindexError = null;
  if(isNaN(value_offsetindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_offsetindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_offsetindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_offsetindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
      offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  if(!pointError && !speedError && !cameraindexError && !objectindexError && !offsetindexError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(pointError) ErrorCode = ErrorCode + pointError;
    if(speedError) ErrorCode = ErrorCode + speedError;
    if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
    if(objectindexError) ErrorCode = ErrorCode + objectindexError;
    if(offsetindexError) ErrorCode = ErrorCode + offsetindexError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'Camera.FixedPosMoveToImage( ' + value_cameraindex + ', ' + value_objectindex + ', ' + value_pointvalue + ', ' +
      value_offsetindex + ', '+ value_heightavoid + ', ' + value_maxspeed + ', ' + value_endspeed
      + ')';// +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      //Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};

Blockly.CSharp['camera_fixedpos_to_image_calculate']=function (block) {
  var value_cameraindex = Blockly.CSharp.valueToCode(block, 'CameraIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_objectindex = Blockly.CSharp.valueToCode(block, 'ObjectIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_offsetindex = Blockly.CSharp.valueToCode(block, 'OffSetIndex',
      Blockly.CSharp.ORDER_ATOMIC) || '1';
  var value_pointvalue = Blockly.CSharp.valueToCode(block, 'PointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '0';
  var value_calculatepointvalue = Blockly.CSharp.valueToCode(block, 'CalculatePointValue',
      Blockly.CSharp.ORDER_ATOMIC) || '3000';
  value_pointvalue = value_pointvalue.replace('(','');value_pointvalue = value_pointvalue.replace(')','');
  value_pointvalue = parseInt(value_pointvalue);//不能为负数

  value_calculatepointvalue = value_calculatepointvalue.replace('(','');value_calculatepointvalue = value_calculatepointvalue.replace(')','');
  value_calculatepointvalue = parseInt(value_calculatepointvalue);//不能为负数

  value_cameraindex = value_cameraindex.replace('(','');value_cameraindex = value_cameraindex.replace(')','');
  value_cameraindex = parseInt(value_cameraindex);//
  value_objectindex = value_objectindex.replace('(','');value_objectindex = value_objectindex.replace(')','');
  value_objectindex = parseInt(value_objectindex);//
  value_offsetindex = value_offsetindex.replace('(','');value_offsetindex = value_offsetindex.replace(')','');
  value_offsetindex = parseInt(value_offsetindex);//
  //var check = bound.checkPointIsContain(value_pointvalue);

  var pointError = null;
  if(isNaN(value_pointvalue)|| isNaN(value_calculatepointvalue))//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_pointvalue = 0;
    value_calculatepointvalue=0;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
    pointError = "函数转换出错,请检查坐标点编号是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_pointvalue < 0 || value_calculatepointvalue<0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_pointvalue = 0;
      value_calculatepointvalue=0;
      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
      pointError = "函数转换出错,请检查坐标点编号设置是否正确,只能填写正整数;\r\n";
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


  var cameraindexError = null;
  if(isNaN(value_cameraindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_cameraindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_cameraindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_cameraindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
      cameraindexError = "函数转换出错,请检查相机编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var objectindexError = null;
  if(isNaN(value_objectindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_objectindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_objectindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_objectindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
      objectindexError = "函数转换出错,请检查产品编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  var offsetindexError = null;
  if(isNaN(value_offsetindex) )//NaN 错误
  {
    //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    value_offsetindex = 1;
    Blockly.CSharp.workspaceToCodeError = true;
    Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
        + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
  }
  else
  {
    if(value_offsetindex <= 0)//<=0 错误
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      value_offsetindex = 1;

      Blockly.CSharp.workspaceToCodeError = true;
      Blockly.CSharp.workspaceToCodeErrorString = Blockly.CSharp.workspaceToCodeErrorString
          + "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
      offsetindexError = "函数转换出错,请检查补偿值编号设置是否正确,只能填写正整数;\r\n";
    }
    else
    {
      //block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
      //block.setWarningText(null);
    }
  }

  if(!pointError  && !cameraindexError && !objectindexError && !offsetindexError)
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CAMERA_RGB);
    block.setWarningText(null);
  }
  else
  {
    Blockly.CSharp.workspaceToCodeError = true;
    var ErrorCode = "";
    if(pointError) ErrorCode = ErrorCode + pointError;
    if(cameraindexError) ErrorCode = ErrorCode + cameraindexError;
    if(objectindexError) ErrorCode = ErrorCode + objectindexError;
    if(offsetindexError) ErrorCode = ErrorCode + offsetindexError;
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    block.setWarningText(ErrorCode);
  }

  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix +
      'Camera.FixedPosMoveToImageCalculate( ' + value_cameraindex + ', ' + value_objectindex + ', ' + value_pointvalue + ', ' +
      value_offsetindex + ', '+ value_calculatepointvalue
      + ')';// +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      //Blockly.CustomConfig.CSharpCode_ExitMain + '\n';//RobotType 预留机器人型号
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
    //return code;
  return [code, Blockly.CSharp.ORDER_NONE];
};