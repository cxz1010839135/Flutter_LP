'use strict';

goog.provide("Blockly.GCode.text");
goog.require("Blockly.GCode");
goog.require("Blockly.CustomConfig");

Blockly.GCode['text'] = function(block) {
  // Text value.
  var code = Blockly.GCode.quote_(block.getFieldValue('TEXT'));
  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.GCode.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);
  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    block.setWarningText(null);
  }
  return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['text_join'] = function(block) {
  // Create a string made up of any number of elements of any type.
  switch (block.itemCount_) {
    case 0:
      if(!block.parentBlock_ )
      {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);
      }
      else
      {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
      }
      return [' ', Blockly.GCode.ORDER_ATOMIC];
    case 1:
      var element = Blockly.GCode.valueToCode(block, 'ADD0',
          Blockly.GCode.ORDER_NONE) || ' ';
      var code = element;
      if(!block.parentBlock_ )
      {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);
      }
      else
      {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
      }
      return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];
    case 2:
      var element0 = Blockly.GCode.valueToCode(block, 'ADD0',
          Blockly.GCode.ORDER_NONE) || ' ';
      var element1 = Blockly.GCode.valueToCode(block, 'ADD1',
          Blockly.GCode.ORDER_NONE) || ' ';
      var code = ' ' + element0 + ' ' + element1;
      if(!block.parentBlock_ )
      {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);
      }
      else
      {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
      }
      return [code, Blockly.GCode.ORDER_ADDITIVE];
    default:
      var elements = new Array(block.itemCount_);
      for (var i = 0; i < block.itemCount_; i++) {
        elements[i] = Blockly.GCode.valueToCode(block, 'ADD' + i,
            Blockly.GCode.ORDER_NONE) || ' ';
      }
      var code = '' + elements.join(' ');
      if(!block.parentBlock_ )
      {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);
      }
      else
      {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
      }
      return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];
  }
};

Blockly.GCode['text_print'] = function(block) {
  // Print statement.
  var argument0 = Blockly.GCode.valueToCode(block, 'TEXT', Blockly.GCode.ORDER_NONE) || ' ';
  var code =  'Print ' + argument0 + '\n';
  return code;
};

//
// Blockly.GCode['text_append'] = function(block) {
//   // Append to a variable in place.
//   var varName = Blockly.GCode.variableDB_.getName(
//       block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
//   var value = Blockly.GCode.valueToCode(block, 'TEXT',
//       Blockly.JavaScript.ORDER_NONE) || '""';
//   return varName + ' = String.Concat(' + varName + ', ' + value + ');\n';
// };
//
// Blockly.GCode['text_length'] = function(block) {
//   // String or array length.
//   var text = Blockly.GCode.valueToCode(block, 'VALUE',
//       Blockly.GCode.ORDER_UNARY_POSTFIX) || '""';
//   return [text + '.Length', Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_MEMBER
// };
//
// Blockly.GCode['text_isEmpty'] = function(block) {
//   // Is the string null or array empty?
//   var text = Blockly.GCode.valueToCode(block, 'VALUE',
//       Blockly.GCode.ORDER_EQUALITY) || '""';
//   return [text + '.Length == 0', Blockly.GCode.ORDER_EQUALITY];
// };
//
// Blockly.GCode['text_indexOf'] = function(block) {
//   // Search the text for a substring.
//   var operator = block.getFieldValue('END') == 'FIRST' ?
//       'IndexOf' : 'LastIndexOf';
//   var substring = Blockly.GCode.valueToCode(block, 'FIND',
//       Blockly.GCode.ORDER_NONE) || '""';
//   var text = Blockly.GCode.valueToCode(block, 'VALUE',
//       Blockly.GCode.ORDER_UNARY_POSTFIX) || '""';
//   var code = text + '.' + operator + '(' + substring + ')';
//   // Adjust index if using one-based indices.
//   if (block.workspace.options.oneBasedIndex) {
//     return [code + ' + 1', Blockly.GCode.ORDER_ADDITIVE];
//   }
//   return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_MEMBER
// };
//
// Blockly.GCode['text_charAt'] = function(block) {
//   // Get letter at index.
//   // Note: Until January 2013 this block did not have the WHERE input.
//
//   //var at = Blockly.GCode.valueToCode(block, 'AT', Blockly.GCode.ORDER_UNARY_PREFIX) || '1';//Blockly.GCode.ORDER_UNARY_NEGATION
//   var where = block.getFieldValue('WHERE') || 'FROM_START';
//   var text = Blockly.GCode.valueToCode(block, 'VALUE',
//       Blockly.GCode.ORDER_UNARY_POSTFIX) || '""';
//
//   switch (where) {
//     case 'FIRST':
//       var code = text + '.First()';
//       return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];
//     case 'LAST':
//       var code = text + '.Last()';
//       return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
//     case 'FROM_START':
//       var at = Blockly.GCode.getAdjusted(block, 'AT');
//       var code = text + '[' + at + ' - 1]';
//       return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];
//     case 'FROM_END':
//       var at = Blockly.GCode.getAdjusted(block, 'AT');
//       var code = text + '[text.Length - ' + at + ']';
//       return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
//     case 'RANDOM':
//       if (!Blockly.GCode.definitions_['text_random_letter']) {
//         var functionName = Blockly.GCode.variableDB_.getDistinctName(
//             'text_random_letter', Blockly.Generator.NAME_TYPE);
//         Blockly.GCode.text_charAt.text_random_letter = functionName;
//         var func = [];
//         func.push('var ' + functionName + ' = new Func<string, char>((text) => {');
//         func.push('  var x = (new Random()).Next(text.length);');
//         func.push('  return text[x];');
//         func.push('});');
//         Blockly.GCode.definitions_['text_random_letter'] = func.join('\n');
//       }
//       code = Blockly.GCode.text_charAt.text_random_letter +
//           '(' + text + ')';
//       return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
//   }
//   throw 'Unhandled option (text_charAt).';
// };
//
// Blockly.GCode['text_getSubstring'] = function(block) {
//   // Get substring.
//   var text = Blockly.GCode.valueToCode(block, 'STRING', Blockly.GCode.ORDER_UNARY_POSTFIX) || 'null';//Blockly.GCode.ORDER_MEMBER
//   var where1 = block.getFieldValue('WHERE1');
//   var where2 = block.getFieldValue('WHERE2');
//   var at1 = Blockly.GCode.valueToCode(block, 'AT1', Blockly.GCode.ORDER_NONE) || '1';
//   var at2 = Blockly.GCode.valueToCode(block, 'AT2', Blockly.GCode.ORDER_NONE) || '1';
//   if (where1 == 'FIRST' && where2 == 'LAST') {
//     var code = text;
//   } else {
//     if (!Blockly.GCode.definitions_['text_get_substring']) {
//       var functionName = Blockly.GCode.variableDB_.getDistinctName(
//           'text_get_substring', Blockly.Generator.NAME_TYPE);
//       Blockly.GCode.text_getSubstring.func = functionName;
//       var func = [];
//       func.push('var ' + functionName + ' = new Func<string, dynamic, int, dynamic, int, string>((text, where1, at1, where2, at2) => {');
//       func.push('  var getAt =new Func<dynamic, int, int>((where, at) => {');
//       func.push('    if (where == "FROM_START") {');
//       func.push('      at--;');
//       func.push('    } else if (where == "FROM_END") {');
//       func.push('      at = text.Length - at;');
//       func.push('    } else if (where == "FIRST") {');
//       func.push('      at = 0;');
//       func.push('    } else if (where == "LAST") {');
//       func.push('      at = text.Length - 1;');
//       func.push('    } else {');
//       func.push('      throw new ApplicationException("Unhandled option (text_getSubstring).");');
//       func.push('    }');
//       func.push('    return at;');
//       func.push('  });');
//       func.push('  at1 = getAt(where1, at1);');
//       func.push('  at2 = getAt(where2, at2) + 1;');
//       func.push('  return text.Substring(at1, at2 - at1);');
//       func.push('});');
//       Blockly.GCode.definitions_['text_get_substring'] =
//           func.join('\n');
//     }
//     var code = Blockly.GCode.text_getSubstring.func + '(' + text + ', "' + where1 + '", ' + at1 + ', "' + where2 + '", ' + at2 + ')';
//   }
//   return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
// };
//
// Blockly.GCode['text_changeCase'] = function(block) {
//   // Change capitalization.
//   var mode = block.getFieldValue('CASE');
//   var operator = Blockly.GCode.text_changeCase.OPERATORS[mode];
//   var code;
//   if (operator) {
//     // Upper and lower case are functions built into GCode.
//     var argument0 = Blockly.GCode.valueToCode(block, 'TEXT', Blockly.GCode.ORDER_UNARY_POSTFIX) || '""';//Blockly.GCode.ORDER_MEMBER
//     code = argument0 + operator;
//   } else {
//     if (!Blockly.GCode.definitions_['text_toTitleCase']) {
//       // Title case is not a native GCode function.  Define one.
//       var functionName = Blockly.GCode.variableDB_.getDistinctName('text_toTitleCase', Blockly.Generator.NAME_TYPE);
//       Blockly.GCode.text_changeCase.toTitleCase = functionName;
//       var func = [];
//       func.push('var ' + functionName + ' = new Func<string, string>((str) => {');
//       func.push('  var buf = new StringBuilder(str.Length);');
//       func.push('  var toUpper = true;');
//       func.push('  foreach (var ch in str) {');
//       func.push('    buf.Append(toUpper ? Char.ToUpper(ch) : ch);');
//       func.push('    toUpper = Char.IsWhiteSpace(ch);');
//       func.push('  }');
//       func.push('  return buf.ToString();');
//       func.push('});');
//       Blockly.GCode.definitions_['text_toTitleCase'] = func.join('\n');
//     }
//     var argument0 = Blockly.GCode.valueToCode(block, 'TEXT',
//         Blockly.GCode.ORDER_NONE) || '""';
//     code = Blockly.GCode.text_changeCase.toTitleCase + '(' + argument0 + ')';
//   }
//   return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
// };
//
// Blockly.GCode.text_changeCase.OPERATORS = {
//   UPPERCASE: '.ToUpper()',
//   LOWERCASE: '.ToLower()',
//   TITLECASE: null
// };
//
// Blockly.GCode['text_trim'] = function(block) {
//   // Trim spaces.
//   var mode = block.getFieldValue('MODE');
//   var operator = Blockly.GCode.text_trim.OPERATORS[mode];
//   var argument0 = Blockly.GCode.valueToCode(block, 'TEXT', Blockly.GCode.ORDER_UNARY_POSTFIX) || '""';//Blockly.GCode.ORDER_MEMBER
//   return [argument0 + operator, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
// };
//
// Blockly.GCode.text_trim.OPERATORS = {
//   LEFT: '.TrimStart()',
//   RIGHT: '.TrimEnd()',
//   BOTH: '.Trim()'
// };
//
//
//
// Blockly.GCode['text_prompt_ext'] = function (block) {
//   // Prompt function.
//   if (block.getField('TEXT')) {
//     // Internal message.
//     var msg = Blockly.GCode.quote_(block.getFieldValue('TEXT'));
//   } else {
//     // External message.
//     var msg = Blockly.GCode.valueToCode(block, 'TEXT',
//         Blockly.GCode.ORDER_NONE) || '""';
//   }
//     var toNumber = block.getFieldValue('TYPE') == 'NUMBER';
//
//     var functionName = Blockly.GCode.variableDB_.getDistinctName('text_promptInput', Blockly.Generator.NAME_TYPE);
//     Blockly.GCode.text_prompt.promptInput = functionName;
//     var func = [];
//     func.push('var ' + functionName + ' = new Func<string, bool, dynamic>((msg, toNumber) => {');
//     func.push('  Console.WriteLine(msg);');
//     func.push('  var res = Console.ReadLine();');
//     func.push('  if (toNumber)');
//     func.push('    return Double.Parse(res);');
//     func.push('  return res;');
//     func.push('});');
//     Blockly.GCode.definitions_['text_promptInput'] = func.join('\n');
//
//     var code = Blockly.GCode.text_prompt.promptInput + '(' + msg + ', ' + toNumber + ')';
//     return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
// };
//
// Blockly.GCode['text_prompt'] = Blockly.GCode['text_prompt_ext'];
//
// Blockly.GCode['text_count'] = function(block) {
//   var text = Blockly.GCode.valueToCode(block, 'TEXT',
//       Blockly.GCode.ORDER_UNARY_POSTFIX) || '\'\'';
//   var sub = Blockly.GCode.valueToCode(block, 'SUB',
//       Blockly.GCode.ORDER_NONE) || '\'\'';
//   // Substring count is not a native Dart function.  Define one.
//   var functionName = Blockly.GCode.provideFunction_(
//       'text_count',
//       ['int ' + Blockly.GCode.FUNCTION_NAME_PLACEHOLDER_ +
//       '(String haystack, String needle) {',
//         '  if (needle.length == 0) {',
//         '    return haystack.length + 1;',
//         '  }',
//         '  int index = 0;',
//         '  int count = 0;',
//         '  while (index != -1) {',
//         '    index = haystack.indexOf(needle, index);',
//         '    if (index != -1) {',
//         '      count++;',
//         '     index += needle.length;',
//         '    }',
//         '  }',
//         '  return count;',
//         '}']);
//   var code = functionName + '(' + text + ', ' + sub + ')';
//   return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];
// };
//
// Blockly.GCode['text_replace'] = function(block) {
//   var text = Blockly.GCode.valueToCode(block, 'TEXT',
//       Blockly.GCode.ORDER_UNARY_POSTFIX) || '""';
//   var from = Blockly.GCode.valueToCode(block, 'FROM',
//       Blockly.GCode.ORDER_NONE) || '""';
//   var to = Blockly.GCode.valueToCode(block, 'TO',
//       Blockly.GCode.ORDER_NONE) || '""';
//   var code = text + '.Replace(' + from + ', ' + to + ')';
//   return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];
// };
//
// Blockly.GCode['text_reverse'] = function(block) {
//   // Implementing something is possibly better than not implementing anything?
//   var text = Blockly.GCode.valueToCode(block, 'TEXT',
//       Blockly.GCode.ORDER_UNARY_POSTFIX) || '""';
//   var code = text + '.Reverse()';
//   return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];
// };