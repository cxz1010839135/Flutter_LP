/**
 * @license
 * Visual Blocks Editor
 *
 * Copyright 2012 Google Inc.
 * https://developers.google.com/blockly/
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @fileoverview 自定义配置
 *
 */
'use strict';

goog.provide('Blockly.CustomConfig');  // Deprecated

goog.require('Blockly.Blocks');

Blockly.CustomConfig.VERSION = "V1.0.1";
Blockly.CustomConfig.DocIcon_Height = 0.015;//保存 新建 蓝牙连接 帮助 图标Icon大小比例 相对于整个浏览器显示高度的比例
Blockly.CustomConfig.DocIcon_Top = 0.005;
Blockly.CustomConfig.DocIcon_Left = 100;
Blockly.CustomConfig.BlocklyTreeDivNum = 4;

Blockly.CustomConfig.FOCUS_MOTION_RGB="#eac889";//"#00ace7";//动作 鼠标点击时颜色
Blockly.CustomConfig.FOCUS_CONTROL_RGB="#bdd69f";//"#f7a300";//"#b5549c";//控制 鼠标点击时颜色
Blockly.CustomConfig.FOCUS_MATH_RGB="#d4c0cb";//"#f7a300";//"#0263ae";//数学 鼠标点击时颜色
Blockly.CustomConfig.FOCUS_PROCEDURES_RGB="#9bd3f1";//"#7fbf4c";//"#944238";//函数 鼠标点击时颜色
Blockly.CustomConfig.FOCUS_MATH_NUM_RGB="#b6a2ad";//"#A28E99";//"#C0B6B7";//数学 鼠标点击时颜色

Blockly.CustomConfig.BLOCK_MOTION_RGB="#eac889";//"#00ace7";//动作block颜色
Blockly.CustomConfig.BLOCK_CONTROL_RGB="#bdd69f";//"#f7a300";//"#b5549c";//控制block颜色
Blockly.CustomConfig.BLOCK_MATH_RGB="#d4c0cb";//"#f7a300";//"#0263ae";//数学block颜色
Blockly.CustomConfig.BLOCK_MATH_NOTE_RGB="#d43c5e";//"#f7a300";//"#0263ae";//数学block颜色
Blockly.CustomConfig.BLOCK_PROCEDURES_RGB="#9bd3f1";//"#7fbf4c";//"#944238";//函数block颜色
Blockly.CustomConfig.BLOCK_MATH_NUM_RGB="#b6a2ad";//"#A28E99";//"#C0B6B7";//数学 鼠标点击时颜色

// Blockly.CustomConfig.FOCUS_MOTION_RGB="#5e90c1";//"#00ace7";//动作 鼠标点击时颜色
// Blockly.CustomConfig.FOCUS_CONTROL_RGB="#5c987f";//"#f7a300";//"#b5549c";//控制 鼠标点击时颜色
// Blockly.CustomConfig.FOCUS_MATH_RGB="#ae85a0";//"#f7a300";//"#0263ae";//数学 鼠标点击时颜色
// Blockly.CustomConfig.FOCUS_PROCEDURES_RGB="#daab81";//"#7fbf4c";//"#944238";//函数 鼠标点击时颜色
//
// Blockly.CustomConfig.BLOCK_MOTION_RGB="#5e90c1";//"#00ace7";//动作block颜色
// Blockly.CustomConfig.BLOCK_CONTROL_RGB="#5c987f";//"#f7a300";//"#b5549c";//控制block颜色
// Blockly.CustomConfig.BLOCK_MATH_RGB="#ae85a0";//"#f7a300";//"#0263ae";//数学block颜色
// Blockly.CustomConfig.BLOCK_PROCEDURES_RGB="#daab81";//"#7fbf4c";//"#944238";//函数block颜色

//定义toolbox 按下时的颜色
// Blockly.CustomConfig.FOCUS_MOTION_RGB="#50ab53";//"#00ace7";//动作 鼠标点击时颜色
// Blockly.CustomConfig.FOCUS_CONTROL_RGB="#fb5229";//"#f7a300";//"#b5549c";//控制 鼠标点击时颜色
// Blockly.CustomConfig.FOCUS_MATH_RGB="#4096cd";//"#f7a300";//"#0263ae";//数学 鼠标点击时颜色
// Blockly.CustomConfig.FOCUS_PROCEDURES_RGB="#f08924";//"#7fbf4c";//"#944238";//函数 鼠标点击时颜色
Blockly.CustomConfig.FOCUS_EVENT_RGB="#adafb8";//"#319552";//事件 鼠标标点击时颜色
Blockly.CustomConfig.FOCUS_VARIABLES_RGB="#f18595";//"#f7a300";//"#e945eb"//"#a5161c";//变量 鼠标点击时颜色
Blockly.CustomConfig.FOCUS_CAMERA_RGB="#adafb8";//"#f77a00";//"#5d54b5";//相机 鼠标点击时颜色
Blockly.CustomConfig.FOCUS_RETURN_RGB="#FFFFFF";//返回 鼠标点击时颜色

//定义  不同block类型的颜色
// Blockly.CustomConfig.BLOCK_MOTION_RGB="#50ab53";//"#00ace7";//动作block颜色
// Blockly.CustomConfig.BLOCK_CONTROL_RGB="#fb5229";//"#f7a300";//"#b5549c";//控制block颜色
// Blockly.CustomConfig.BLOCK_MATH_RGB="#4096cd";//"#f7a300";//"#0263ae";//数学block颜色
// Blockly.CustomConfig.BLOCK_PROCEDURES_RGB="#f08924";//"#7fbf4c";//"#944238";//函数block颜色
Blockly.CustomConfig.BLOCK_EVENT_RGB="#adafb8";//"#f7a300";//"#319552";//事件block颜色
Blockly.CustomConfig.BLOCK_VARIABLES_RGB="#f18595";//"#f7a300";//"#e945eb"//"#a5161c";//变量block颜色
Blockly.CustomConfig.BLOCK_CAMERA_RGB="#adafb8";//"#f77a00";//"#5d54b5";//相机block颜色

Blockly.CustomConfig.BLOCK_ERROR_RGB = "#FF0000";// 编译出错的Block颜色

Blockly.CustomConfig.DebugMode = true;
Blockly.CustomConfig.CSharpProgramCurrentLineIndex = 0;//主程序段
Blockly.CustomConfig.CSharpProgramDefinitionsLineIndex = 0;//变量定义和程序定义段
Blockly.CustomConfig.CSharpBoolLineFunction = 'funboolline';
Blockly.CustomConfig.CSharpCode_ExitMain = 'if(RobotCommand.bGcode_Stop || RobotCommand.bProgram_Error) return;';
Blockly.CustomConfig.CSharpCode_RobotMove_True_Prefix = 'RobotCommand.bRobotMoveCommandLine = true;';
Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix = 'RobotCommand.bRobotMoveCommandLine = false;';
Blockly.CustomConfig.CSharpCode_Procedures_BeginTrue_Prefix = 'RobotCommand.bCallProceduresLineBegin = true;';
Blockly.CustomConfig.CSharpCode_Procedures_EndFalse_Prefix = 'RobotCommand.bCallProceduresLineBegin = false;';
Blockly.CustomConfig.CSharpCode_ProgramLineInitial_Prefix = 'RobotCommand.uProgramCurrentLineIndex = 0;RobotCommand.uProgramDefinitionsLineIndex = 0;\r\n';
Blockly.CustomConfig.CSharpCode_ProgramLineSet = 'RobotCommand.uProgramCurrentLineIndex = ';
Blockly.CustomConfig.CSharpCode_ProgramLineName = 'Mark_RobotCommand.uProgramCurrentLineIndex';
Blockly.CustomConfig.CSharpCode_bIsfunOrdefName = 'bIsdefOrfun';
Blockly.CustomConfig.CSharpCode_ProgramDefinitionsLineSet = 'RobotCommand.uProgramDefinitionsLineIndex = ';
Blockly.CustomConfig.Variable_Prefix = 'var-';
Blockly.CustomConfig.Procefures_Prefix = 'fun-';

/**
 * 暂时未使用
 * 保存 新建 蓝牙 帮助 图标背景颜色
Blockly.CustomConfig.SaveDoc_BackGroundColor_RGB = "#c5c6ca";//保存项目 图标背景颜色
Blockly.CustomConfig.NewDoc_BackGroundColor_RGB = "#c5c6ca";//新建项目
Blockly.CustomConfig.BlueTooth_BackGroundColor_RGB = "#c5c6ca";//蓝牙连接
Blockly.CustomConfig.Helper_BackGroundColor_RGB = "#c5c6ca";//帮助
 */