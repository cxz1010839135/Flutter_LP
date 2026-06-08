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
 * @fileoverview Generating LLRobot for loop blocks.
 * @author fraser@google.com (Neil Fraser)
 */
'use strict';

goog.provide('Blockly.LLRobot.loops');

goog.require('Blockly.LLRobot');
goog.require('Blockly.CustomConfig');

Blockly.LLRobot['controls_repeat_ext'] = function(block) {
  // Repeat n times
    if (block.getField('TIMES')) {
        // Internal number.
        var repeats = String(Number(block.getFieldValue('TIMES')));
    } else {
        // External number.
        var repeats = Blockly.LLRobot.valueToCode(block, 'TIMES',
            Blockly.LLRobot.ORDER_ASSIGNMENT) || '0';
    }
    var branch = Blockly.LLRobot.statementToCode(block, 'DO');
    branch = Blockly.LLRobot.addLoopTrap(branch, block.id);
    var code = '';
    var loopVar = Blockly.LLRobot.variableDB_.getDistinctName(
        'count', Blockly.Variables.NAME_TYPE);
    var endVar = repeats;
    if (!repeats.match(/^\w+$/) && !Blockly.isNumber(repeats)) {
        // var endVar = Blockly.LLRobot.variableDB_.getDistinctName(
        //     'repeat_end', Blockly.Variables.NAME_TYPE);
        // code += 'var ' + endVar + ' = ' + repeats + ';\n';
      //endVar = '(' + Blockly.CustomConfig.Variable_Prefix  + repeats +')';
    }
     // code += 'for (var ' + loopVar + ' = 0; ' +
     //     loopVar + ' < ' + endVar + '; ' +
     //     loopVar + '++) {\n' +
     //     branch + Blockly.CustomConfig.CSharpCode_ExitMain +  '}\n';
    code += '重复 (' + endVar +') 次{\n' + branch +  '}\n';
    return code;
};

Blockly.LLRobot['controls_repeat'] = Blockly.LLRobot['controls_repeat_ext'];

Blockly.LLRobot['controls_whileUntil'] = function(block) {
  // Do while/until loop.
    var until = block.getFieldValue('MODE') == 'UNTIL';

    var argument0 = Blockly.LLRobot.valueToCode(block, 'BOOL',
        until ? Blockly.LLRobot.ORDER_UNARY_PREFIX ://Blockly.LLRobot.ORDER_LOGICAL_NOT
            Blockly.LLRobot.ORDER_NONE) ;
    // if(!argument0) {
    //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    //   Blockly.LLRobot.workspaceToCodeError = true;
    //   block.setWarningText("判断输入模块不能为空!");
    //   argument0 = 'false';
    // }
    // else
    // {
    //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //   block.setWarningText(null);
    // }


    var branch = Blockly.LLRobot.statementToCode(block, 'DO');
    branch = Blockly.LLRobot.addLoopTrap(branch, block.id);

    var whilename = Blockly.Msg.CONTROLS_WHILEUNTIL_OPERATOR_WHILE;
    if (until) {
        //argument0 = '!' + argument0;
      whilename = Blockly.Msg.CONTROLS_WHILEUNTIL_OPERATOR_UNTIL;
    }
    return whilename + '(' + argument0 + ') {\n' + branch + '}\n';
};

Blockly.LLRobot['controls_for'] = function(block) {
  // For loop.
  //   var variable0 = Blockly.LLRobot.variableDB_.getName(
  //       block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
    var variable0 = block.getFieldValue('VAR');
    var argument0 = Blockly.LLRobot.valueToCode(block, 'FROM',
        Blockly.LLRobot.ORDER_ASSIGNMENT) || '0';
    var argument1 = Blockly.LLRobot.valueToCode(block, 'TO',
        Blockly.LLRobot.ORDER_ASSIGNMENT) || '0';
    var increment = Blockly.LLRobot.valueToCode(block, 'BY',
        Blockly.LLRobot.ORDER_ASSIGNMENT) || '1';
    var branch = Blockly.LLRobot.statementToCode(block, 'DO');
    branch = Blockly.LLRobot.addLoopTrap(branch, block.id);
    var code;
    //如果都是数值
    if (Blockly.isNumber(argument0) && Blockly.isNumber(argument1) &&
        Blockly.isNumber(increment)) {
        // All arguments are simple numbers.
        var up = parseFloat(argument0) <= parseFloat(argument1);
        code = '使用 (' + Blockly.CustomConfig.Variable_Prefix  + variable0 + ' ) 从范围 (' + argument0 + ') 到 (' + argument1 + ') 每隔( ' + increment + ')';
        // var step = Math.abs(parseFloat(increment));
        // if (step == 1) {
        //     code += up ? '++' : '--';
        // } else {
        //     code += (up ? ' += ' : ' -= ') + step;
        // }
        code += '{\n' + branch + '}\n';
    } else {
        code = '';
        // Cache non-trivial values to variables to prevent repeated look-ups.
        var startVar = argument0;
        if (!argument0.match(/^\w+$/) && !Blockly.isNumber(argument0)) {
            // startVar = Blockly.LLRobot.variableDB_.getDistinctName(
            //     variable0 + '_start', Blockly.Variables.NAME_TYPE);
            // code += 'var ' + startVar + ' = ' + argument0 + ';\n';
          //startVar = '(' +Blockly.CustomConfig.Variable_Prefix  + argument0 +')';
          //startVar = '(' +Blockly.CustomConfig.Variable_Prefix  + argument0 +')';
        }
        var endVar = argument1;
        if (!argument1.match(/^\w+$/) && !Blockly.isNumber(argument1)) {
            // var endVar = Blockly.LLRobot.variableDB_.getDistinctName(
            //     variable0 + '_end', Blockly.Variables.NAME_TYPE);
            // code += 'var ' + endVar + ' = ' + argument1 + ';\n';
          //endVar = '(' + Blockly.CustomConfig.Variable_Prefix  + argument1 +')';
        }
        // Determine loop direction at start, in case one of the bounds
        // changes during loop execution.
        // var incVar = Blockly.LLRobot.variableDB_.getDistinctName(
        //     variable0 + '_inc', Blockly.Variables.NAME_TYPE);
        // code += 'dynamic ' + incVar + ' = ';//code += 'var ' + incVar + ' = ';
        // if (Blockly.isNumber(increment)) {
        //     code += Math.abs(increment) + ';\n';
        // } else {
        //     code += 'Math.Abs(' + increment + ');\n';
        // }
      var inc = increment;
          if (!increment.match(/^\w+$/) && !Blockly.isNumber(increment)) {
            // var endVar = Blockly.LLRobot.variableDB_.getDistinctName(
            //     variable0 + '_end', Blockly.Variables.NAME_TYPE);
            // code += 'var ' + endVar + ' = ' + argument1 + ';\n';
            //inc = '(' + Blockly.CustomConfig.Variable_Prefix  + increment +')';
          }
        // code += 'if (' + startVar + ' > ' + endVar + ') {\n';
        // code += Blockly.LLRobot.INDENT + incVar + ' = -' + incVar + ';\n';
        // code += '}\n';
        // code += 'for (' + variable0 + ' = ' + startVar + '; ' +
        //     incVar + ' >= 0 ? ' +
        //     variable0 + ' <= ' + endVar + ' : ' +
        //     variable0 + ' >= ' + endVar + '; ' +
        //     variable0 + ' += ' + incVar + ') {\n' +
        //     branch + Blockly.CustomConfig.CSharpCode_ExitMain +  '}\n';
        code += '使用 (' + Blockly.CustomConfig.Variable_Prefix  + variable0 +  ') 从范围 (' + startVar + ') 到 (' + endVar + ') 每隔 (' + inc +') ';
        code += '{\n' + branch + '}\n';
    }
    return code;
};

/**
 * List 暂时未添加使用
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['controls_forEach'] = function(block) {
  // For each loop.
    var variable0 = Blockly.LLRobot.variableDB_.getName(
        block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
    var argument0 = Blockly.LLRobot.valueToCode(block, 'LIST',
        Blockly.LLRobot.ORDER_ASSIGNMENT) || '[]';
    var branch = Blockly.LLRobot.statementToCode(block, 'DO');
    branch = Blockly.LLRobot.addLoopTrap(branch, block.id);
    var code = '';
    // Cache non-trivial values to variables to prevent repeated look-ups.
    var listVar = argument0;
    if (!argument0.match(/^\w+$/)) {
        listVar = Blockly.LLRobot.variableDB_.getDistinctName(
            variable0 + '_list', Blockly.Variables.NAME_TYPE);
        code += 'var ' + listVar + ' = ' + argument0 + ';\n';
    }
    var indexVar = Blockly.LLRobot.variableDB_.getDistinctName(
        variable0 + '_index', Blockly.Variables.NAME_TYPE);
    branch = Blockly.LLRobot.INDENT + variable0 + ' = ' +
        listVar + '[' + indexVar + '];\n' + branch;
    code += 'for (var ' + indexVar + ' in ' + listVar + ') {\n' + branch + Blockly.CustomConfig.CSharpCode_ExitMain +  '}\n';
    return code;
};

Blockly.LLRobot['controls_flow_statements'] = function(block) {
  // Flow statements: continue, break.
    switch (block.getFieldValue('FLOW')) {
        case 'BREAK':
            //return 'break;\n';
            return Blockly.Msg.CONTROLS_FLOW_STATEMENTS_OPERATOR_BREAK + ';\n';
        case 'CONTINUE':
            //return 'continue;\n';
            return Blockly.Msg.CONTROLS_FLOW_STATEMENTS_OPERATOR_CONTINUE + ';\n';
    }
    throw 'Unknown flow statement.';
};
