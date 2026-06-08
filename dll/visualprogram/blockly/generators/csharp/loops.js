/**
 * @license
 * Visual Blocks Language
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
 * @fileoverview Generating CSharp for loop blocks.
 * @author fraser@google.com (Neil Fraser)
 */
'use strict';

goog.provide('Blockly.CSharp.loops');

goog.require('Blockly.CSharp');
goog.require('Blockly.CustomConfig');

Blockly.CSharp['controls_repeat_ext'] = function(block) {
  // Repeat n times
    if (block.getField('TIMES')) {
        // Internal number.
        var repeats = String(Number(block.getFieldValue('TIMES')));
    } else {
        // External number.
        var repeats = Blockly.CSharp.valueToCode(block, 'TIMES',
            Blockly.CSharp.ORDER_ASSIGNMENT) || '0';
    }
    var branch = Blockly.CSharp.statementToCode(block, 'DO');
    branch = Blockly.CSharp.addLoopTrap(branch, block.id);
    var code = '';
    var loopVar = Blockly.CSharp.variableDB_.getDistinctName(
        'count', Blockly.Variables.NAME_TYPE);
    var endVar = repeats;
    if (!repeats.match(/^\w+$/) && !Blockly.isNumber(repeats)) {
        var endVar = Blockly.CSharp.variableDB_.getDistinctName(
            'repeat_end', Blockly.Variables.NAME_TYPE);
        code += 'var ' + endVar + ' = ' + repeats + ';';
    }
    var conditioncode = Blockly.CustomConfig.CSharpBoolLineFunction + '(' +
        loopVar + ' < ' + endVar  + ',' +
        Blockly.CustomConfig.CSharpCode_ProgramLineName + ',' +
        Blockly.CustomConfig.CSharpCode_bIsfunOrdefName + ')';
    code += //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
        //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
        'for (var ' + loopVar + ' = 0; ' +
        conditioncode + '; ' +
        loopVar + '++) {' +
        '\n' +
        branch + Blockly.CustomConfig.CSharpCode_ExitMain +  '}\n';
    //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
    return code;
};

Blockly.CSharp['controls_repeat'] = Blockly.CSharp['controls_repeat_ext'];

Blockly.CSharp['controls_whileUntil'] = function(block) {
  // Do while/until loop.
    var until = block.getFieldValue('MODE') == 'UNTIL';

    var argument0 = Blockly.CSharp.valueToCode(block, 'BOOL',
        until ? Blockly.CSharp.ORDER_UNARY_PREFIX ://Blockly.CSharp.ORDER_LOGICAL_NOT
            Blockly.CSharp.ORDER_NONE) ;
    if(!argument0) {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      Blockly.CSharp.workspaceToCodeError = true;
      block.setWarningText("判断输入模块不能为空!");
      argument0 = 'false';
    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
      block.setWarningText(null);
    }


    var branch = Blockly.CSharp.statementToCode(block, 'DO');
    branch = Blockly.CSharp.addLoopTrap(branch, block.id);
    if (until) {
        argument0 = '!' + argument0;
    }
    var conditioncode = Blockly.CustomConfig.CSharpBoolLineFunction + '(' +
        argument0 + ',' +
        Blockly.CustomConfig.CSharpCode_ProgramLineName + ',' +
        Blockly.CustomConfig.CSharpCode_bIsfunOrdefName + ')';
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
        //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
        'while (' +
        conditioncode +
        ') {' +
        '\n' + branch + Blockly.CustomConfig.CSharpCode_ExitMain +  '}\n';
    //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
    return code;
};

Blockly.CSharp['controls_for'] = function(block) {
  // For loop.
    var variable0 = Blockly.CSharp.variableDB_.getName(
        block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
    var argument0 = Blockly.CSharp.valueToCode(block, 'FROM',
        Blockly.CSharp.ORDER_ASSIGNMENT) || '0';
    var argument1 = Blockly.CSharp.valueToCode(block, 'TO',
        Blockly.CSharp.ORDER_ASSIGNMENT) || '0';
    var increment = Blockly.CSharp.valueToCode(block, 'BY',
        Blockly.CSharp.ORDER_ASSIGNMENT) || '1';
    var branch = Blockly.CSharp.statementToCode(block, 'DO');
    branch = Blockly.CSharp.addLoopTrap(branch, block.id);
    var code;
    if (Blockly.isNumber(argument0) && Blockly.isNumber(argument1) &&
        Blockly.isNumber(increment)) {
        // All arguments are simple numbers.
        var up = parseFloat(argument0) <= parseFloat(argument1);
        var conditioncode = Blockly.CustomConfig.CSharpBoolLineFunction + '(' +
            variable0 + (up ? ' <= ' : ' >= ') + argument1 + ',' +
            Blockly.CustomConfig.CSharpCode_ProgramLineName + ',' +
            Blockly.CustomConfig.CSharpCode_bIsfunOrdefName + ')';
        code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
            //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
            'for (' + variable0 + ' = ' + argument0 + '; ' +
            conditioncode + '; ' +
            variable0;
        var step = Math.abs(parseFloat(increment));
        if (step == 1) {
            code += up ? '++' : '--';
        } else {
            code += (up ? ' += ' : ' -= ') + step;
        }
        code += ') {' +
            '\n' + branch + Blockly.CustomConfig.CSharpCode_ExitMain + '}\n';
      //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
    } else {
        code = '';
        // Cache non-trivial values to variables to prevent repeated look-ups.
        var startVar = argument0;
        if (!argument0.match(/^\w+$/) && !Blockly.isNumber(argument0)) {
            startVar = Blockly.CSharp.variableDB_.getDistinctName(
                variable0 + '_start', Blockly.Variables.NAME_TYPE);
            code += 'var ' + startVar + ' = ' + argument0 + ';';
        }
        var endVar = argument1;
        if (!argument1.match(/^\w+$/) && !Blockly.isNumber(argument1)) {
            var endVar = Blockly.CSharp.variableDB_.getDistinctName(
                variable0 + '_end', Blockly.Variables.NAME_TYPE);
            code += 'var ' + endVar + ' = ' + argument1 + ';';
        }
        // Determine loop direction at start, in case one of the bounds
        // changes during loop execution.
        var incVar = Blockly.CSharp.variableDB_.getDistinctName(
            variable0 + '_inc', Blockly.Variables.NAME_TYPE);
        code += 'dynamic ' + incVar + ' = ';//code += 'var ' + incVar + ' = ';
        if (Blockly.isNumber(increment)) {
            //code += Math.abs(increment) + ';\n';
            code += Math.abs(increment) + ';';
        } else {
            //code += 'Math.Abs(' + increment + ');\n';
            code += 'Math.Abs(' + increment + ');';
        }
        code += 'if (' + startVar + ' > ' + endVar + ') {';
        code += Blockly.CSharp.INDENT + incVar + ' = -' + incVar + ';';
        code += '}';
        var conditioncode = Blockly.CustomConfig.CSharpBoolLineFunction + '(' +
            incVar + ' >= 0 ? ' +
            variable0 + ' <= ' + endVar + ' : ' +
            variable0 + ' >= ' + endVar  + ',' +
            Blockly.CustomConfig.CSharpCode_ProgramLineName + ',' +
            Blockly.CustomConfig.CSharpCode_bIsfunOrdefName + ')';
        code += //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
            //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
            'for (' + variable0 + ' = ' + startVar + '; ' +
            conditioncode + '; ' +
            variable0 + ' += ' + incVar + ') {' +
            '\n' +
            branch + Blockly.CustomConfig.CSharpCode_ExitMain +  '}\n';
        //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
    }
    return code;
};

// Blockly.CSharp['controls_forEach'] = function(block) {
//   // For each loop.
//     var variable0 = Blockly.CSharp.variableDB_.getName(
//         block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
//     var argument0 = Blockly.CSharp.valueToCode(block, 'LIST',
//         Blockly.CSharp.ORDER_ASSIGNMENT) || '[]';
//     var branch = Blockly.CSharp.statementToCode(block, 'DO');
//     branch = Blockly.CSharp.addLoopTrap(branch, block.id);
//     var code = '';
//     // Cache non-trivial values to variables to prevent repeated look-ups.
//     var listVar = argument0;
//     if (!argument0.match(/^\w+$/)) {
//         listVar = Blockly.CSharp.variableDB_.getDistinctName(
//             variable0 + '_list', Blockly.Variables.NAME_TYPE);
//         code += 'var ' + listVar + ' = ' + argument0 + ';\n';
//     }
//     var indexVar = Blockly.CSharp.variableDB_.getDistinctName(
//         variable0 + '_index', Blockly.Variables.NAME_TYPE);
//     branch = Blockly.CSharp.INDENT + variable0 + ' = ' +
//         listVar + '[' + indexVar + '];\n' + branch;
//     code += 'for (var ' + indexVar + ' in ' + listVar + ') {\n' + branch + Blockly.CustomConfig.CSharpCode_ExitMain +  '}\n';
//     return code;
// };

Blockly.CSharp['controls_flow_statements'] = function(block) {
  // Flow statements: continue, break.
// || (block.parentBlock_.type != "controls_repeat"
//       && block.parentBlock_.type != "controls_repeat"
//       && block.parentBlock_.type != "controls_repeat_ext"
//       && block.parentBlock_.type != "controls_whileUntil"
//       && block.parentBlock_.type != "controls_forEach"
//       && block.parentBlock_.type != "controls_for"))
   if(!block.parentBlock_ )
   {
     block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
     Blockly.CSharp.workspaceToCodeError = true;
     block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);
   }
   else
   {
     block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
     block.setWarningText(null);
   }
    switch (block.getFieldValue('FLOW')) {
        case 'BREAK':
          var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
              //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
              'break;\n';
              //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
            return code;
        case 'CONTINUE':
          var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
              //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
              'continue;\n';
              //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
            return code;
    }
    throw 'Unknown flow statement.';
};
