'use strict';

goog.provide("Blockly.CSharp.text");
goog.require("Blockly.CSharp");
goog.require("Blockly.CustomConfig");

Blockly.CSharp['text'] = function(block) {
  // Text value.
  var code = Blockly.CSharp.quote_(block.getFieldValue('TEXT'));
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
  return [code, Blockly.CSharp.ORDER_ATOMIC];
};

Blockly.CSharp['text_join'] = function(block) {
  // Create a string made up of any number of elements of any type.
  switch (block.itemCount_) {
    case 0:
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
      return ['""', Blockly.CSharp.ORDER_ATOMIC];
    case 1:
      var element = Blockly.CSharp.valueToCode(block, 'ADD0',
          Blockly.CSharp.ORDER_NONE) || '""';
      var code = element + '.ToString()';
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
      return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];
    case 2:
      var element0 = Blockly.CSharp.valueToCode(block, 'ADD0',
          Blockly.CSharp.ORDER_NONE) || '""';
      var element1 = Blockly.CSharp.valueToCode(block, 'ADD1',
          Blockly.CSharp.ORDER_NONE) || '""';
      var code = 'String.Concat(' + element0 + ', ' + element1 + ')';
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
      return [code, Blockly.CSharp.ORDER_ADDITIVE];
    default:
      var elements = new Array(block.itemCount_);
      for (var i = 0; i < block.itemCount_; i++) {
        elements[i] = Blockly.CSharp.valueToCode(block, 'ADD' + i,
            Blockly.CSharp.ORDER_NONE) || '""';
      }
      var code = 'String.Concat(' + elements.join(', ') + ')';
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
      return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];
  }
};

Blockly.CSharp['text_print'] = function(block) {
  // Print statement.
  var argument0 = Blockly.CSharp.valueToCode(block, 'TEXT', Blockly.CSharp.ORDER_NONE) || '""';
  var code = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
      //Blockly.CustomConfig.CSharpCode_RobotMove_False_Prefix +
      'UtilityClass.Print(' + argument0 + ');'+
      Blockly.CustomConfig.CSharpCode_ExitMain + '\n';
  //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
  return code;
};

//
// Blockly.CSharp['text_append'] = function(block) {
//   // Append to a variable in place.
//   var varName = Blockly.CSharp.variableDB_.getName(
//       block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
//   var value = Blockly.CSharp.valueToCode(block, 'TEXT',
//       Blockly.JavaScript.ORDER_NONE) || '""';
//   return varName + ' = String.Concat(' + varName + ', ' + value + ');\n';
// };
//
// Blockly.CSharp['text_length'] = function(block) {
//   // String or array length.
//   var text = Blockly.CSharp.valueToCode(block, 'VALUE',
//       Blockly.CSharp.ORDER_UNARY_POSTFIX) || '""';
//   return [text + '.Length', Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_MEMBER
// };
//
// Blockly.CSharp['text_isEmpty'] = function(block) {
//   // Is the string null or array empty?
//   var text = Blockly.CSharp.valueToCode(block, 'VALUE',
//       Blockly.CSharp.ORDER_EQUALITY) || '""';
//   return [text + '.Length == 0', Blockly.CSharp.ORDER_EQUALITY];
// };
//
// Blockly.CSharp['text_indexOf'] = function(block) {
//   // Search the text for a substring.
//   var operator = block.getFieldValue('END') == 'FIRST' ?
//       'IndexOf' : 'LastIndexOf';
//   var substring = Blockly.CSharp.valueToCode(block, 'FIND',
//       Blockly.CSharp.ORDER_NONE) || '""';
//   var text = Blockly.CSharp.valueToCode(block, 'VALUE',
//       Blockly.CSharp.ORDER_UNARY_POSTFIX) || '""';
//   var code = text + '.' + operator + '(' + substring + ')';
//   // Adjust index if using one-based indices.
//   if (block.workspace.options.oneBasedIndex) {
//     return [code + ' + 1', Blockly.CSharp.ORDER_ADDITIVE];
//   }
//   return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_MEMBER
// };
//
// Blockly.CSharp['text_charAt'] = function(block) {
//   // Get letter at index.
//   // Note: Until January 2013 this block did not have the WHERE input.
//
//   //var at = Blockly.CSharp.valueToCode(block, 'AT', Blockly.CSharp.ORDER_UNARY_PREFIX) || '1';//Blockly.CSharp.ORDER_UNARY_NEGATION
//   var where = block.getFieldValue('WHERE') || 'FROM_START';
//   var text = Blockly.CSharp.valueToCode(block, 'VALUE',
//       Blockly.CSharp.ORDER_UNARY_POSTFIX) || '""';
//
//   switch (where) {
//     case 'FIRST':
//       var code = text + '.First()';
//       return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];
//     case 'LAST':
//       var code = text + '.Last()';
//       return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
//     case 'FROM_START':
//       var at = Blockly.CSharp.getAdjusted(block, 'AT');
//       var code = text + '[' + at + ' - 1]';
//       return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];
//     case 'FROM_END':
//       var at = Blockly.CSharp.getAdjusted(block, 'AT');
//       var code = text + '[text.Length - ' + at + ']';
//       return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
//     case 'RANDOM':
//       if (!Blockly.CSharp.definitions_['text_random_letter']) {
//         var functionName = Blockly.CSharp.variableDB_.getDistinctName(
//             'text_random_letter', Blockly.Generator.NAME_TYPE);
//         Blockly.CSharp.text_charAt.text_random_letter = functionName;
//         var func = [];
//         func.push('var ' + functionName + ' = new Func<string, char>((text) => {');
//         func.push('  var x = (new Random()).Next(text.length);');
//         func.push('  return text[x];');
//         func.push('});');
//         Blockly.CSharp.definitions_['text_random_letter'] = func.join('\n');
//       }
//       code = Blockly.CSharp.text_charAt.text_random_letter +
//           '(' + text + ')';
//       return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
//   }
//   throw 'Unhandled option (text_charAt).';
// };
//
// Blockly.CSharp['text_getSubstring'] = function(block) {
//   // Get substring.
//   var text = Blockly.CSharp.valueToCode(block, 'STRING', Blockly.CSharp.ORDER_UNARY_POSTFIX) || 'null';//Blockly.CSharp.ORDER_MEMBER
//   var where1 = block.getFieldValue('WHERE1');
//   var where2 = block.getFieldValue('WHERE2');
//   var at1 = Blockly.CSharp.valueToCode(block, 'AT1', Blockly.CSharp.ORDER_NONE) || '1';
//   var at2 = Blockly.CSharp.valueToCode(block, 'AT2', Blockly.CSharp.ORDER_NONE) || '1';
//   if (where1 == 'FIRST' && where2 == 'LAST') {
//     var code = text;
//   } else {
//     if (!Blockly.CSharp.definitions_['text_get_substring']) {
//       var functionName = Blockly.CSharp.variableDB_.getDistinctName(
//           'text_get_substring', Blockly.Generator.NAME_TYPE);
//       Blockly.CSharp.text_getSubstring.func = functionName;
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
//       Blockly.CSharp.definitions_['text_get_substring'] =
//           func.join('\n');
//     }
//     var code = Blockly.CSharp.text_getSubstring.func + '(' + text + ', "' + where1 + '", ' + at1 + ', "' + where2 + '", ' + at2 + ')';
//   }
//   return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
// };
//
// Blockly.CSharp['text_changeCase'] = function(block) {
//   // Change capitalization.
//   var mode = block.getFieldValue('CASE');
//   var operator = Blockly.CSharp.text_changeCase.OPERATORS[mode];
//   var code;
//   if (operator) {
//     // Upper and lower case are functions built into CSharp.
//     var argument0 = Blockly.CSharp.valueToCode(block, 'TEXT', Blockly.CSharp.ORDER_UNARY_POSTFIX) || '""';//Blockly.CSharp.ORDER_MEMBER
//     code = argument0 + operator;
//   } else {
//     if (!Blockly.CSharp.definitions_['text_toTitleCase']) {
//       // Title case is not a native CSharp function.  Define one.
//       var functionName = Blockly.CSharp.variableDB_.getDistinctName('text_toTitleCase', Blockly.Generator.NAME_TYPE);
//       Blockly.CSharp.text_changeCase.toTitleCase = functionName;
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
//       Blockly.CSharp.definitions_['text_toTitleCase'] = func.join('\n');
//     }
//     var argument0 = Blockly.CSharp.valueToCode(block, 'TEXT',
//         Blockly.CSharp.ORDER_NONE) || '""';
//     code = Blockly.CSharp.text_changeCase.toTitleCase + '(' + argument0 + ')';
//   }
//   return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
// };
//
// Blockly.CSharp.text_changeCase.OPERATORS = {
//   UPPERCASE: '.ToUpper()',
//   LOWERCASE: '.ToLower()',
//   TITLECASE: null
// };
//
// Blockly.CSharp['text_trim'] = function(block) {
//   // Trim spaces.
//   var mode = block.getFieldValue('MODE');
//   var operator = Blockly.CSharp.text_trim.OPERATORS[mode];
//   var argument0 = Blockly.CSharp.valueToCode(block, 'TEXT', Blockly.CSharp.ORDER_UNARY_POSTFIX) || '""';//Blockly.CSharp.ORDER_MEMBER
//   return [argument0 + operator, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
// };
//
// Blockly.CSharp.text_trim.OPERATORS = {
//   LEFT: '.TrimStart()',
//   RIGHT: '.TrimEnd()',
//   BOTH: '.Trim()'
// };
//
//
//
// Blockly.CSharp['text_prompt_ext'] = function (block) {
//   // Prompt function.
//   if (block.getField('TEXT')) {
//     // Internal message.
//     var msg = Blockly.CSharp.quote_(block.getFieldValue('TEXT'));
//   } else {
//     // External message.
//     var msg = Blockly.CSharp.valueToCode(block, 'TEXT',
//         Blockly.CSharp.ORDER_NONE) || '""';
//   }
//     var toNumber = block.getFieldValue('TYPE') == 'NUMBER';
//
//     var functionName = Blockly.CSharp.variableDB_.getDistinctName('text_promptInput', Blockly.Generator.NAME_TYPE);
//     Blockly.CSharp.text_prompt.promptInput = functionName;
//     var func = [];
//     func.push('var ' + functionName + ' = new Func<string, bool, dynamic>((msg, toNumber) => {');
//     func.push('  Console.WriteLine(msg);');
//     func.push('  var res = Console.ReadLine();');
//     func.push('  if (toNumber)');
//     func.push('    return Double.Parse(res);');
//     func.push('  return res;');
//     func.push('});');
//     Blockly.CSharp.definitions_['text_promptInput'] = func.join('\n');
//
//     var code = Blockly.CSharp.text_prompt.promptInput + '(' + msg + ', ' + toNumber + ')';
//     return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
// };
//
// Blockly.CSharp['text_prompt'] = Blockly.CSharp['text_prompt_ext'];
//
// Blockly.CSharp['text_count'] = function(block) {
//   var text = Blockly.CSharp.valueToCode(block, 'TEXT',
//       Blockly.CSharp.ORDER_UNARY_POSTFIX) || '\'\'';
//   var sub = Blockly.CSharp.valueToCode(block, 'SUB',
//       Blockly.CSharp.ORDER_NONE) || '\'\'';
//   // Substring count is not a native Dart function.  Define one.
//   var functionName = Blockly.CSharp.provideFunction_(
//       'text_count',
//       ['int ' + Blockly.CSharp.FUNCTION_NAME_PLACEHOLDER_ +
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
//   return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];
// };
//
// Blockly.CSharp['text_replace'] = function(block) {
//   var text = Blockly.CSharp.valueToCode(block, 'TEXT',
//       Blockly.CSharp.ORDER_UNARY_POSTFIX) || '""';
//   var from = Blockly.CSharp.valueToCode(block, 'FROM',
//       Blockly.CSharp.ORDER_NONE) || '""';
//   var to = Blockly.CSharp.valueToCode(block, 'TO',
//       Blockly.CSharp.ORDER_NONE) || '""';
//   var code = text + '.Replace(' + from + ', ' + to + ')';
//   return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];
// };
//
// Blockly.CSharp['text_reverse'] = function(block) {
//   // Implementing something is possibly better than not implementing anything?
//   var text = Blockly.CSharp.valueToCode(block, 'TEXT',
//       Blockly.CSharp.ORDER_UNARY_POSTFIX) || '""';
//   var code = text + '.Reverse()';
//   return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];
// };