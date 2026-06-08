'use strict';

goog.provide('Blockly.LLRobot.math');

goog.require('Blockly.LLRobot');
goog.require('Blockly.Blocks');
goog.require('Blockly.Block');
goog.require('Blockly.CustomConfig');

Blockly.LLRobot['math_number'] = function(block) {
    // Numeric value.
    var code = parseFloat(block.getFieldValue('NUM'));//parseFloat
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
    // 默认数字按照float double 小数处理
    if(!(String(code).indexOf(".")>-1))
    {
      code = String(code) + ".0";
    }
    // if(!block.parentBlock_ )
    // {
    //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    //   Blockly.LLRobot.workspaceToCodeError = true;
    //   block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);
    //
    // }
    // else
    // {
    //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //   //Blockly.LLRobot.workspaceToCodeError = false;
    //   block.setWarningText(null);
    // }
    return [code, order];
};

Blockly.LLRobot['math_arithmetic'] = function(block){
  // Basic arithmetic operators, and power.
    var OPERATORS = {
        'ADD': [' + ', Blockly.LLRobot.ORDER_ADDITIVE],//Blockly.LLRobot.ORDER_ADDITION
        'MINUS': [' - ', Blockly.LLRobot.ORDER_ADDITIVE],//Blockly.LLRobot.ORDER_SUBTRACTION
        'MULTIPLY': [' * ', Blockly.LLRobot.ORDER_MULTIPLICATIVE],//Blockly.LLRobot.ORDER_MULTIPLICATION
        'DIVIDE': [' / ', Blockly.LLRobot.ORDER_MULTIPLICATIVE],//Blockly.LLRobot.ORDER_DIVISION
        'POWER': [null, Blockly.LLRobot.ORDER_NONE]  // Handle power separately.
    };
  var tuple = OPERATORS[block.getFieldValue('OP')];
  var operator = tuple[0];
  var order = tuple[1];
  var argument0 = Blockly.LLRobot.valueToCode(block, 'A', order) || '0.0';//'0.0' or '0'  ????????????????????
  var argument1 = Blockly.LLRobot.valueToCode(block, 'B', order) || '0.0';
  var code;
  // Power in LLRobot requires a special case since it has no operator.
  if (!operator) {
    code = '((' + argument0 + ')' + Blockly.Msg.MATH_POWER_SYMBOL   + '(' + argument1 + '))';
    return [code, Blockly.LLRobot.ORDER_UNARY_POSTFIX];//Blockly.LLRobot.ORDER_FUNCTION_CALL
  }
  code = argument0 + operator + argument1;
  // if(!block.parentBlock_ )
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);
  //
  // }
  // else
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
  //   //Blockly.LLRobot.workspaceToCodeError = false;
  //   block.setWarningText(null);
  // }
  return [code, order];
};



Blockly.LLRobot['math_single'] = function(block)  {
  // Math operators with single operand.
  var operator = block.getFieldValue('OP');
  var code;
  var arg;
  if (operator == 'NEG') {
    // Negation is a special case given its different operator precedence.
    arg = Blockly.LLRobot.valueToCode(block, 'NUM',
        Blockly.LLRobot.ORDER_UNARY_PREFIX) || '0.0';//Blockly.LLRobot.ORDER_UNARY_NEGATION
    if (arg[0] == '-') {
      // --3 is not allowed
      arg = ' ' + arg;
    }
    code = '-' + arg;
    return [code, Blockly.LLRobot.ORDER_UNARY_PREFIX];//Blockly.LLRobot.ORDER_UNARY_NEGATION
  }
  if (operator == 'SIN' || operator == 'COS' || operator == 'TAN') {
    arg = Blockly.LLRobot.valueToCode(block, 'NUM',
        Blockly.LLRobot.ORDER_MULTIPLICATIVE) || '0';//Blockly.LLRobot.ORDER_DIVISION
  } else {
    arg = Blockly.LLRobot.valueToCode(block, 'NUM',
        Blockly.LLRobot.ORDER_NONE) || '0.0';
  }
  // First, handle cases which generate values that don't need parentheses
  // wrapping the code.
  switch (operator) {
    case 'ABS':
      code = '绝对值(' + arg + ')';
      break;
    case 'ROOT':
      code = '平方根(' + arg + ')';
      break;
    case 'LN':
      code = 'ln(' + arg + ')';
      break;
    case 'EXP':
      code = 'e^(' + arg + ')';
      break;
    case 'POW10':
      code = '10^(' + arg + ')';
      break;
    case 'ROUND':
      code = Blockly.Msg.MATH_ROUND_OPERATOR_ROUND + '(' + arg + ')';
      break;
    case 'ROUNDUP':
      code = Blockly.Msg.MATH_ROUND_OPERATOR_ROUNDUP + '(' + arg + ')';
      break;
    case 'ROUNDDOWN':
      code = Blockly.Msg.MATH_ROUND_OPERATOR_ROUNDDOWN + '(' + arg + ')';
      break;
    case 'SIN':
      code = 'Sin(' + arg + ')';
      break;
    case 'COS':
      code = 'Cos(' + arg + ')';
      break;
    case 'TAN':
      code = 'Tan(' + arg + ')';
      break;
  }
  if (code) {
    return [code, Blockly.LLRobot.ORDER_UNARY_POSTFIX];//Blockly.LLRobot.ORDER_FUNCTION_CALL
  }
  // Second, handle cases which generate values that may need parentheses
  // wrapping the code.
  switch (operator) {
    case 'LOG10':
      code = 'log10(' + arg + ')';
      break;
    case 'ASIN':
      code = 'Asin(' + arg + ')';
      break;
    case 'ACOS':
      code = 'Acos(' + arg + ')';
      break;
    case 'ATAN':
      code = 'Atan(' + arg + ')';
      break;
    default:
      throw 'Unknown math operator: ' + operator;
  }
  return [code, Blockly.LLRobot.ORDER_MULTIPLICATIVE];//Blockly.LLRobot.ORDER_DIVISION
};

Blockly.LLRobot['math_constant'] = function(block){
    // Constants: PI, E, the Golden Ratio, sqrt(2), 1/sqrt(2), INFINITY.
    var CONSTANTS = {
        'PI': ['\u03c0', Blockly.LLRobot.ORDER_UNARY_POSTFIX],//Blockly.LLRobot.ORDER_MEMBER
        'E': ['e', Blockly.LLRobot.ORDER_UNARY_POSTFIX],//Blockly.LLRobot.ORDER_MEMBER
        'GOLDEN_RATIO':
            ['\u03c6', Blockly.LLRobot.ORDER_MULTIPLICATIVE],//Blockly.LLRobot.ORDER_DIVISION
        'SQRT2': ['sqrt(2)', Blockly.LLRobot.ORDER_UNARY_POSTFIX],//Blockly.LLRobot.ORDER_MEMBER
        'SQRT1_2': ['sqrt(\u00bd)', Blockly.LLRobot.ORDER_UNARY_POSTFIX],//Blockly.LLRobot.ORDER_MEMBER
        'INFINITY': ['\u221e', Blockly.LLRobot.ORDER_ATOMIC]
    };
    // if(!block.parentBlock_ )
    // {
    //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    //   Blockly.LLRobot.workspaceToCodeError = true;
    //   block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);
    //
    // }
    // else
    // {
    //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //   //Blockly.LLRobot.workspaceToCodeError = false;
    //   block.setWarningText(null);
    // }
    return CONSTANTS[block.getFieldValue('CONSTANT')];
};

/**
 * 整数 质数判断暂时未使用
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['math_number_property'] = function(block){
  // Check if a number is even, odd, prime, whole, positive, or negative
  // or if it is divisible by certain number. Returns true or false.
  var number_to_check = Blockly.LLRobot.valueToCode(block, 'NUMBER_TO_CHECK',
      Blockly.LLRobot.ORDER_MULTIPLICATIVE) || 'double.NaN';//Blockly.LLRobot.ORDER_MODULUS
  var dropdown_property = block.getFieldValue('PROPERTY');
  var code;
  if (dropdown_property == 'PRIME') {
    // Prime is a special case as it is not a one-liner test.
    if (!Blockly.LLRobot.definitions_['MathisPrime']) {
      var functionName = Blockly.LLRobot.variableDB_.getDistinctName(
          'MathisPrime', Blockly.Generator.NAME_TYPE);
      Blockly.LLRobot.logic_prime= functionName;
      var func = [];
      func.push('var ' + functionName + ' = new Func<double, bool>((n) => {');
      func.push('  // http://en.wikipedia.org/wiki/Primality_test#Naive_methods');
      func.push('  if (n == 2.0 || n == 3.0)');
      func.push('    return true;');
      func.push('  // False if n is NaN, negative, is 1, or not whole. And false if n is divisible by 2 or 3.');
      func.push('  if (double.IsNaN(n) || n <= 1 || n % 1 != 0.0 || n % 2 == 0.0 || n % 3 == 0.0)');
      func.push('    return false;');
      func.push('  // Check all the numbers of form 6k +/- 1, up to sqrt(n).');
      func.push('  for (var x = 6; x <= Math.Sqrt(n) + 1; x += 6) {');
      func.push('    if (n % (x - 1) == 0.0 || n % (x + 1) == 0.0)');
      func.push('      return false;');
      func.push('  }');
      func.push('  return true;');
      func.push('});');
      Blockly.LLRobot.definitions_['MathisPrime'] = func.join('\n');
    }
    code = Blockly.LLRobot.logic_prime + '(' + number_to_check + ')';
    return [code, Blockly.LLRobot.ORDER_UNARY_POSTFIX];//Blockly.LLRobot.ORDER_FUNCTION_CALL
  }
  switch (dropdown_property) {
    case 'EVEN':
      code = number_to_check + ' % 2 == 0';
      break;
    case 'ODD':
      code = number_to_check + ' % 2 == 1';
      break;
    case 'WHOLE':
      code = number_to_check + ' % 1 == 0';
      break;
    case 'POSITIVE':
      code = number_to_check + ' > 0';
      break;
    case 'NEGATIVE':
      code = number_to_check + ' < 0';
      break;
    case 'DIVISIBLE_BY':
      var divisor = Blockly.LLRobot.valueToCode(block, 'DIVISOR',
          Blockly.LLRobot.ORDER_MULTIPLICATIVE) || 'double.NaN';// '0';//Blockly.LLRobot.ORDER_MODULUS
      code = number_to_check + ' % ' + divisor + ' == 0';
      break;
  }
  // if(!block.parentBlock_ )
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);
  //
  // }
  // else
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
  //   //Blockly.LLRobot.workspaceToCodeError = false;
  //   block.setWarningText(null);
  // }
  return [code, Blockly.LLRobot.ORDER_EQUALITY];
};

/**
 * 类型变换 暂时未使用
 * @param block
 * @returns {string}
 */
Blockly.LLRobot['math_change'] = function(block) {
  // Add to a variable in place.
  var argument0 = Blockly.LLRobot.valueToCode(block, 'DELTA',
      Blockly.LLRobot.ORDER_ADDITIVE) || '0.0';//Blockly.LLRobot.ORDER_ADDITION
  var varName = Blockly.LLRobot.variableDB_.getName(
      block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
  return varName + ' = (' + varName + '.GetType().Name == "Double" ? '
      + varName + ' : 0.0) + ' + argument0 + ';\n';
};

// Rounding functions have a single operand.
Blockly.LLRobot['math_round'] = Blockly.LLRobot['math_single'];
// Trigonometry functions have a single operand.
Blockly.LLRobot['math_trig'] = Blockly.LLRobot['math_single'];

/**
 * list 相关函数暂时未使用
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['math_on_list'] = function(block){
  // Math functions for lists.
  var func = block.getFieldValue('OP');
  var list, code;
  switch (func) {
    case 'SUM':
      list = Blockly.LLRobot.valueToCode(block, 'LIST',
          Blockly.LLRobot.ORDER_UNARY_POSTFIX) || 'new List<dynamic>()';//Blockly.LLRobot.ORDER_MEMBER
      code = list + '.Aggregate((x, y) => x + y)';
      break;
    case 'MIN':
      list = Blockly.LLRobot.valueToCode(block, 'LIST',
          Blockly.LLRobot.ORDER_NONE) || 'new List<dynamic>()';//Blockly.LLRobot.ORDER_COMMA
      code = list + '.Min()';
      break;
    case 'MAX':
      list = Blockly.LLRobot.valueToCode(block, 'LIST',
          Blockly.LLRobot.ORDER_NONE) || 'new List<dynamic>()';//Blockly.LLRobot.ORDER_COMMA
      code = list + '.Max()';
      break;
    case 'AVERAGE'://动态dynamic List求和 ????????????????????????????????
        // ListAverage([null,null,1,3]) == 2.0.
        var functionName = Blockly.LLRobot.provideFunction_(
            'ListAverage',
            ['function ' + Blockly.LLRobot.FUNCTION_NAME_PLACEHOLDER_ +
            '(myList) {',
                '  return myList.reduce(function(x, y) {return x + y;}) / ' +
                'myList.length;',
                '}']);
      list = Blockly.LLRobot.valueToCode(block, 'LIST',
          Blockly.LLRobot.ORDER_NONE) || 'new List<dynamic>()';//Blockly.LLRobot.ORDER_COMMA
        code = functionName + '(' + list + ')';//code = list + '.Average()';
      break;
    case 'MEDIAN':
      // math_median([null,null,1,3]) == 2.0.
      if (!Blockly.LLRobot.definitions_['mathMedian']) {
        var functionName = Blockly.LLRobot.variableDB_.getDistinctName(
            'mathMedian', Blockly.Generator.NAME_TYPE);
        Blockly.LLRobot.math_on_list.math_median = functionName;
        var func = [];
        func.push('var ' + functionName + ' = new Func<List<dynamic>,dynamic>((vals) => {');
        func.push('  vals.Sort();');
        func.push('  if (vals.Count % 2 == 0)');
        func.push('    return (vals[vals.Count / 2 - 1] + vals[vals.Count / 2]) / 2;');
        func.push('  else');
        func.push('    return vals[(vals.Count - 1) / 2];');
        func.push('});');
        Blockly.LLRobot.definitions_['math_median'] = func.join('\n');
      }
      list = Blockly.LLRobot.valueToCode(block, 'LIST',
          Blockly.LLRobot.ORDER_NONE) || 'new List<dynamic>()';
      code = Blockly.LLRobot.math_on_list.math_median + '(' + list + ')';
      break;
    case 'MODE':
      if (!Blockly.LLRobot.definitions_['math_modes']) {
        var functionName = Blockly.LLRobot.variableDB_.getDistinctName(
            'math_modes', Blockly.Generator.NAME_TYPE);
        Blockly.LLRobot.math_on_list.math_modes = functionName;
        // As a list of numbers can contain more than one mode,
        // the returned result is provided as an array.
        // Mode of [3, 'x', 'x', 1, 1, 2, '3'] -> ['x', 1].
        var func = [];
        func.push('var ' + functionName + ' = new Func<List<dynamic>,List<dynamic>>((values) => {');
        func.push('  var modes = new List<dynamic>();');
        func.push('  var counts = new Dictionary<double, int>();');
        func.push('  var maxCount = 0;');
        func.push('  foreach (var value in values) {');
        func.push('    int storedCount;');
        func.push('    if (counts.TryGetValue(value, out storedCount)) {');
        func.push('      maxCount = Math.Max(maxCount, ++counts[value]);');
        func.push('    }');
        func.push('    else {');
        func.push('      counts.Add(value, 1);');
        func.push('      maxCount = 1;');
        func.push('    }');
        func.push('  }');
        func.push('  foreach (var pair in counts) {');
        func.push('    if (pair.Value == maxCount)');
        func.push('      modes.Add(pair.Key);');
        func.push('  }');
        func.push('  return modes;');
        func.push('});');
        Blockly.LLRobot.definitions_['math_modes'] = func.join('\n');
      }
      list = Blockly.LLRobot.valueToCode(block, 'LIST',
          Blockly.LLRobot.ORDER_NONE) || 'new List<dynamic>()';
      code = Blockly.LLRobot.math_on_list.math_modes + '(' + list + ')';
      break;
    case 'STD_DEV':
      if (!Blockly.LLRobot.definitions_['math_standard_deviation']) {
        var functionName = Blockly.LLRobot.variableDB_.getDistinctName(
            'math_standard_deviation', Blockly.Generator.NAME_TYPE);
        Blockly.LLRobot.math_on_list.math_standard_deviation = functionName;
        var func = [];
        func.push('var ' + functionName + ' = new Func<List<dynamic>,double>((numbers) => {');
        func.push('  var n = numbers.Count;');
        func.push('  var mean = numbers.Average(val => val);');
        func.push('  var variance = 0.0;');
        func.push('  for (var j = 0; j < n; j++) {');
        func.push('    variance += Math.Pow(numbers[j] - mean, 2);');
        func.push('  }');
        func.push('  variance = variance / n;');
        func.push('  return Math.Sqrt(variance);');
        func.push('});');
        Blockly.LLRobot.definitions_['math_standard_deviation'] =
            func.join('\n');
      }
      list = Blockly.LLRobot.valueToCode(this, 'LIST',
          Blockly.LLRobot.ORDER_NONE) || 'new List<dynamic>()';
      code = Blockly.LLRobot.math_on_list.math_standard_deviation +
          '(' + list + ')';
      break;
    case 'RANDOM':
      if (!Blockly.LLRobot.definitions_['math_random_item']) {
        var functionName = Blockly.LLRobot.variableDB_.getDistinctName(
            'math_random_item', Blockly.Generator.NAME_TYPE);
        Blockly.LLRobot.math_on_list.math_random_item = functionName;
        var func = [];
        func.push('var ' + functionName + ' = new Func<List<dynamic>,dynamic>((list) => {');
        func.push('  var x = (new Random()).Next(list.Count);');
        func.push('  return list[x];');
        func.push('});');
        Blockly.LLRobot.definitions_['math_random_item'] = func.join('\n');
      }
      list = Blockly.LLRobot.valueToCode(block, 'LIST',
          Blockly.LLRobot.ORDER_NONE) || 'new List<dynamic>()';
      code = Blockly.LLRobot.math_on_list.math_random_item +
          '(' + list + ')';
      break;
    default:
      throw 'Unknown operator: ' + func;
  }
  return [code, Blockly.LLRobot.ORDER_UNARY_POSTFIX];//Blockly.LLRobot.ORDER_FUNCTION_CALL
};

/**
 * 取余数
 * @param block
 * @returns {[null,null]}
 */
Blockly.LLRobot['math_modulo'] = function(block) {
  // Remainder computation.
  var argument0 = Blockly.LLRobot.valueToCode(block, 'DIVIDEND',
      Blockly.LLRobot.ORDER_MULTIPLICATIVE) || '0.0';//Blockly.LLRobot.ORDER_MODULUS
  var argument1 = Blockly.LLRobot.valueToCode(block, 'DIVISOR',
      Blockly.LLRobot.ORDER_MULTIPLICATIVE) || '0.0';//Blockly.LLRobot.ORDER_MODULUS
  var code = '取余数自 ((' + argument0 + ') / (' + argument1 + '))';
  // if(!block.parentBlock_ )
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
  //   Blockly.LLRobot.workspaceToCodeError = true;
  //   block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);
  //
  // }
  // else
  // {
  //   block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
  //   //Blockly.LLRobot.workspaceToCodeError = false;
  //   block.setWarningText(null);
  // }
  return [code, Blockly.LLRobot.ORDER_MULTIPLICATIVE];//Blockly.LLRobot.ORDER_MODULUS
};

Blockly.LLRobot['math_constrain'] = function(block) {
  // Constrain a number between two limits.
  var argument0 = Blockly.LLRobot.valueToCode(block, 'VALUE',
      Blockly.LLRobot.ORDER_NONE) || '0.0';//Blockly.LLRobot.ORDER_COMMA
  var argument1 = Blockly.LLRobot.valueToCode(block, 'LOW',
      Blockly.LLRobot.ORDER_NONE) || '0.0';//Blockly.LLRobot.ORDER_COMMA
  var argument2 = Blockly.LLRobot.valueToCode(block, 'HIGH',
      Blockly.LLRobot.ORDER_NONE) || '+';//Blockly.LLRobot.ORDER_COMMA
  var code = '限制数字(' + argument0 + ')介于(低) (' + argument1 + ')到(高)( ' + argument2 + ')';
  return [code, Blockly.LLRobot.ORDER_UNARY_POSTFIX];//Blockly.LLRobot.ORDER_FUNCTION_CALL
};

Blockly.LLRobot['math_random_int'] = function(block) {
  // Random integer between [X] and [Y].
  var argument0 = Blockly.LLRobot.valueToCode(block, 'FROM',
      Blockly.LLRobot.ORDER_NONE) || '0.0';//Blockly.LLRobot.ORDER_COMMA
  var argument1 = Blockly.LLRobot.valueToCode(block, 'TO',
      Blockly.LLRobot.ORDER_NONE) || '0.0';//Blockly.LLRobot.ORDER_COMMA
  /*
  if (!Blockly.LLRobot.definitions_['math_random_int']) {
    var functionName = Blockly.LLRobot.variableDB_.getDistinctName(
        'math_random_int', Blockly.Generator.NAME_TYPE);
    Blockly.LLRobot.math_random_int.random_function = functionName;
    var func = [];
    func.push('var ' + functionName + ' new Func<int,int,int>((a, b) => {');
    func.push('  if (a > b) {');
    func.push('    // Swap a and b to ensure a is smaller.');
    func.push('    var c = a;');
    func.push('    a = b;');
    func.push('    b = c;');
    func.push('  }');
    func.push('  return (int)Math.Floor(a + (new Random()).Next(b - a));');
    func.push('});');
    Blockly.LLRobot.definitions_['math_random_int'] = func.join('\n');
  }

  var code = Blockly.LLRobot.math_random_int.random_function +
      '(' + argument0 + ', ' + argument1 + ')';
  return [code, Blockly.LLRobot.ORDER_UNARY_POSTFIX];//Blockly.LLRobot.ORDER_FUNCTION_CALL
  */
  var code = '(从 (' + argument0 + ') 到 (' + argument1 + ') 之间的随机整数)';
  return [code, Blockly.LLRobot.ORDER_UNARY_POSTFIX];
};

Blockly.LLRobot['math_random_float'] = function(block){
  // Random fraction between 0 and 1. double
  return ['(0到1之间的随机小数)', Blockly.LLRobot.ORDER_UNARY_POSTFIX];//Blockly.LLRobot.ORDER_FUNCTION_CALL
};
