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
 * @fileoverview Generating JavaScript for procedure blocks.
 * @author fraser@google.com (Neil Fraser)
 */

'use strict';

goog.provide("Blockly.GCode.procedures");

goog.require("Blockly.GCode");


/**
 * Code generator to create a function with a return value (X).
 * GCode code: void functionname { return X }
 * @param {!Blockly.Block} block Block to generate the code from.
 * @return {null} There is no code added to loop.
 */
Blockly.GCode['procedures_defreturn'] = function(block) {
  // Define a procedure with a return value.
  var funcName = Blockly.GCode.variableDB_.getName(
      block.getFieldValue('NAME'), Blockly.Procedures.NAME_TYPE);
  var branch = Blockly.GCode.statementToCode(block, 'STACK');
  if (Blockly.GCode.STATEMENT_PREFIX) {
    branch = Blockly.GCode.prefixLines(
        Blockly.GCode.STATEMENT_PREFIX.replace(/%1/g,
            '\'' + block.id + '\''), Blockly.GCode.INDENT) + branch;
  }
  if (Blockly.GCode.INFINITE_LOOP_TRAP) {
    branch = Blockly.GCode.INFINITE_LOOP_TRAP.replace(/%1/g,
        '\'' + block.id + '\'') + branch;
  }

  var returnValue = Blockly.GCode.valueToCode(block, 'RETURN',
      Blockly.GCode.ORDER_NONE) || '';
  if (returnValue) {
    returnValue = '  return ' + returnValue + ';\n';
  }
  var args = [];
  for (var i = 0; i < block.arguments_.length; i++) {
    args[i] = Blockly.GCode.variableDB_.getName(block.arguments_[i],
        Blockly.Variables.NAME_TYPE);
  }


   var argTypes = '';
  var append_to_list = function (res, val) {
      if (res.length == 0)
          argTypes = val;
      else
          argTypes += ', ' + val;
  };


  for (var x = 0; x < args.length; x++) {
      append_to_list(argTypes, 'dynamic');
  }

  if (returnValue.length != 0) {
      append_to_list(argTypes, 'dynamic');
  }

  var delegateType = (returnValue.length == 0) ? 'Action' : ('Func< ' + argTypes + ' >');

  //var code = 'var ' + funcName + ' = new ' + delegateType + '((' + args.join(', ') + ') => {\n' + branch + returnValue + '});';

  var code = '@' + funcName + /*'(' + args.join(', ') + ')*/'\n' + branch + returnValue + '\n@END\n';

  //var code = 'dynamic ' + funcName + '(' + args.join(', ') + ') {\n' +
   //   branch + returnValue + '}';
  code = Blockly.GCode.scrub_(block, code);
  // Add % so as not to collide with helper functions in definitions list.
  Blockly.GCode.definitions_['%' + funcName] = code;
  return null;
};

// Defining a procedure without a return value uses the same generator as
// a procedure with a return value.
Blockly.GCode['procedures_defnoreturn'] =
    Blockly.GCode['procedures_defreturn'];

// Blockly.GCode['procedures_callreturn'] = function(block) {
//   // Call a procedure with a return value.
//   var funcName = Blockly.GCode.variableDB_.getName(
//       block.getFieldValue('NAME'), Blockly.Procedures.NAME_TYPE);
//   var args = [];
//   for (var x = 0; x < block.arguments_.length; x++) {
//     args[x] = Blockly.GCode.valueToCode(block, 'ARG' + x,
//         Blockly.GCode.ORDER_NONE) || 'null';//Blockly.GCode.ORDER_COMMA
//   }
//   var code = funcName + '(' + args.join(', ') + ')';
//   return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
// };

Blockly.GCode['procedures_callnoreturn'] = function(block) {
  // Call a procedure with no return value.
  var funcName = Blockly.GCode.variableDB_.getName(
      block.getFieldValue('NAME'), Blockly.Procedures.NAME_TYPE);
  var args = [];
  for (var x = 0; x < block.arguments_.length; x++) {
    args[x] = Blockly.GCode.valueToCode(block, 'ARG' + x,
        Blockly.GCode.ORDER_NONE) || 'null';//Blockly.GCode.ORDER_COMMA
  }
  var code = funcName + '(' + args.join(', ') + ')' + '\n';
  return code;
};

// Blockly.GCode['procedures_ifreturn'] = function(block) {
//   // Conditionally return value from a procedure.
//   var condition = Blockly.GCode.valueToCode(block, 'CONDITION',
//       Blockly.GCode.ORDER_NONE) || 'false';
//   var code = 'if (' + condition + ') {\n';
//   if (block.hasReturnValue_) {
//     var value = Blockly.GCode.valueToCode(block, 'VALUE',
//         Blockly.GCode.ORDER_NONE) || 'null';
//     code += '  return ' + value + ';\n';
//   } else {
//     code += '  return;\n';
//   }
//   code += '}\n';
//   return code;
// };
