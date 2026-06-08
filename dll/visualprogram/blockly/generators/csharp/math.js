'use strict';

goog.provide('Blockly.CSharp.math');

goog.require('Blockly.CSharp');
goog.require('Blockly.Blocks');
goog.require('Blockly.Block');
goog.require('Blockly.CustomConfig');

Blockly.CSharp['math_number'] = function(block) {
    // Numeric value.
    var code = parseFloat(block.getFieldValue('NUM'));//parseFloat
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
    // 默认数字按照float double 小数处理
    if(!(String(code).indexOf(".")>-1))
    {
      code = String(code) + ".0";
    }
    if(!block.parentBlock_ )
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      Blockly.CSharp.workspaceToCodeError = true;
      block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);

    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
      //Blockly.CSharp.workspaceToCodeError = false;
      block.setWarningText(null);
    }
    return [code, order];
};

Blockly.CSharp['math_arithmetic'] = function(block){
  // Basic arithmetic operators, and power.
    var OPERATORS = {
        'ADD': [' + ', Blockly.CSharp.ORDER_ADDITIVE],//Blockly.CSharp.ORDER_ADDITION
        'MINUS': [' - ', Blockly.CSharp.ORDER_ADDITIVE],//Blockly.CSharp.ORDER_SUBTRACTION
        'MULTIPLY': [' * ', Blockly.CSharp.ORDER_MULTIPLICATIVE],//Blockly.CSharp.ORDER_MULTIPLICATION
        'DIVIDE': [' / ', Blockly.CSharp.ORDER_MULTIPLICATIVE],//Blockly.CSharp.ORDER_DIVISION
        'POWER': [null, Blockly.CSharp.ORDER_NONE]  // Handle power separately.
    };
  var tuple = OPERATORS[block.getFieldValue('OP')];
  var operator = tuple[0];
  var order = tuple[1];
  var argument0 = Blockly.CSharp.valueToCode(block, 'A', order) || '0.0';//'0.0' or '0'  ????????????????????
  var argument1 = Blockly.CSharp.valueToCode(block, 'B', order) || '0.0';
  var code;
  // Power in CSharp requires a special case since it has no operator.
  if (!operator) {
    code = 'Math.Pow(' + argument0 + ', ' + argument1 + ')';
    return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
  }
  code = argument0 + operator + argument1;
  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);

  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //Blockly.CSharp.workspaceToCodeError = false;
    block.setWarningText(null);
  }
  return [code, order];
};



Blockly.CSharp['math_single'] = function(block)  {
  // Math operators with single operand.
  var operator = block.getFieldValue('OP');
  var code;
  var arg;
  if (operator == 'NEG') {
    // Negation is a special case given its different operator precedence.
    arg = Blockly.CSharp.valueToCode(block, 'NUM',
        Blockly.CSharp.ORDER_UNARY_PREFIX) || '0.0';//Blockly.CSharp.ORDER_UNARY_NEGATION
    if (arg[0] == '-') {
      // --3 is not allowed
      arg = ' ' + arg;
    }
    code = '-' + arg;
    return [code, Blockly.CSharp.ORDER_UNARY_PREFIX];//Blockly.CSharp.ORDER_UNARY_NEGATION
  }
  if (operator == 'SIN' || operator == 'COS' || operator == 'TAN') {
    arg = Blockly.CSharp.valueToCode(block, 'NUM',
        Blockly.CSharp.ORDER_MULTIPLICATIVE) || '0';//Blockly.CSharp.ORDER_DIVISION
  } else {
    arg = Blockly.CSharp.valueToCode(block, 'NUM',
        Blockly.CSharp.ORDER_NONE) || '0.0';
  }
  // First, handle cases which generate values that don't need parentheses
  // wrapping the code.
  switch (operator) {
    case 'ABS':
      code = 'Math.Abs(' + arg + ')';
      break;
    case 'ROOT':
      code = 'Math.Sqrt(' + arg + ')';
      break;
    case 'LN':
      code = 'Math.Log(' + arg + ')';
      break;
    case 'EXP':
      code = 'Math.Exp(' + arg + ')';
      break;
    case 'POW10':
      code = 'Math.Pow(' + arg + ', 10)';
      break;
    case 'ROUND':
      code = 'Math.Round(' + arg + ')';
      break;
    case 'ROUNDUP':
      code = 'Math.Ceiling(' + arg + ')';
      break;
    case 'ROUNDDOWN':
      code = 'Math.Floor(' + arg + ')';
      break;
    case 'SIN':
      code = 'Math.Sin(' + arg + ' / 180 * Math.PI)';
      break;
    case 'COS':
      code = 'Math.Cos(' + arg + ' / 180 * Math.PI)';
      break;
    case 'TAN':
      code = 'Math.Tan(' + arg + ' / 180 * Math.PI)';
      break;
  }
  if (code) {
    return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
  }
  // Second, handle cases which generate values that may need parentheses
  // wrapping the code.
  switch (operator) {
    case 'LOG10':
      code = 'Math.Log(' + arg + ') / Math.Log(10)';
      break;
    case 'ASIN':
      code = 'Math.Asin(' + arg + ') / Math.PI * 180';
      break;
    case 'ACOS':
      code = 'Math.Acos(' + arg + ') / Math.PI * 180';
      break;
    case 'ATAN':
      code = 'Math.Atan(' + arg + ') / Math.PI * 180';
      break;
    default:
      throw 'Unknown math operator: ' + operator;
  }
  return [code, Blockly.CSharp.ORDER_MULTIPLICATIVE];//Blockly.CSharp.ORDER_DIVISION
};

Blockly.CSharp['math_constant'] = function(block){
    // Constants: PI, E, the Golden Ratio, sqrt(2), 1/sqrt(2), INFINITY.
    var CONSTANTS = {
        'PI': ['Math.PI', Blockly.CSharp.ORDER_UNARY_POSTFIX],//Blockly.CSharp.ORDER_MEMBER
        'E': ['Math.E', Blockly.CSharp.ORDER_UNARY_POSTFIX],//Blockly.CSharp.ORDER_MEMBER
        'GOLDEN_RATIO':
            ['(1 + Math.Sqrt(5)) / 2', Blockly.CSharp.ORDER_MULTIPLICATIVE],//Blockly.CSharp.ORDER_DIVISION
        'SQRT2': ['Math.Sqrt(2)', Blockly.CSharp.ORDER_UNARY_POSTFIX],//Blockly.CSharp.ORDER_MEMBER
        'SQRT1_2': ['Math.Sqrt(1.0/2)', Blockly.CSharp.ORDER_UNARY_POSTFIX],//Blockly.CSharp.ORDER_MEMBER
        'INFINITY': ['double.PositiveInfinity', Blockly.CSharp.ORDER_ATOMIC]
    };
    if(!block.parentBlock_ )
    {
      block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
      Blockly.CSharp.workspaceToCodeError = true;
      block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);

    }
    else
    {
      block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
      //Blockly.CSharp.workspaceToCodeError = false;
      block.setWarningText(null);
    }
    return CONSTANTS[block.getFieldValue('CONSTANT')];
};

Blockly.CSharp['math_number_property'] = function(block){
  // Check if a number is even, odd, prime, whole, positive, or negative
  // or if it is divisible by certain number. Returns true or false.
  var number_to_check = Blockly.CSharp.valueToCode(block, 'NUMBER_TO_CHECK',
      Blockly.CSharp.ORDER_MULTIPLICATIVE) || 'double.NaN';//Blockly.CSharp.ORDER_MODULUS
  var dropdown_property = block.getFieldValue('PROPERTY');
  var code;
  if (dropdown_property == 'PRIME') {
    // Prime is a special case as it is not a one-liner test.
    if (!Blockly.CSharp.definitions_['MathisPrime']) {
      var functionName = Blockly.CSharp.variableDB_.getDistinctName(
          'MathisPrime', Blockly.Generator.NAME_TYPE);
      Blockly.CSharp.logic_prime= functionName;
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
      Blockly.CSharp.definitions_['MathisPrime'] = func.join('\n');
    }
    code = Blockly.CSharp.logic_prime + '(' + number_to_check + ')';
    return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
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
      var divisor = Blockly.CSharp.valueToCode(block, 'DIVISOR',
          Blockly.CSharp.ORDER_MULTIPLICATIVE) || 'double.NaN';// '0';//Blockly.CSharp.ORDER_MODULUS
      code = number_to_check + ' % ' + divisor + ' == 0';
      break;
  }
  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);

  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //Blockly.CSharp.workspaceToCodeError = false;
    block.setWarningText(null);
  }
  return [code, Blockly.CSharp.ORDER_EQUALITY];
};

Blockly.CSharp['math_change'] = function(block) {
  // Add to a variable in place.
  var argument0 = Blockly.CSharp.valueToCode(block, 'DELTA',
      Blockly.CSharp.ORDER_ADDITIVE) || '0.0';//Blockly.CSharp.ORDER_ADDITION
  var varName = Blockly.CSharp.variableDB_.getName(
      block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
  return varName + ' = (' + varName + '.GetType().Name == "Double" ? '
      + varName + ' : 0.0) + ' + argument0 + ';\n';
};

// Rounding functions have a single operand.
Blockly.CSharp['math_round'] = Blockly.CSharp['math_single'];
// Trigonometry functions have a single operand.
Blockly.CSharp['math_trig'] = Blockly.CSharp['math_single'];

/**
 * list 相关函数暂时未使用
 * @param block
 * @returns {[null,null]}
 */
Blockly.CSharp['math_on_list'] = function(block){
  // Math functions for lists.
  var func = block.getFieldValue('OP');
  var list, code;
  switch (func) {
    case 'SUM':
      list = Blockly.CSharp.valueToCode(block, 'LIST',
          Blockly.CSharp.ORDER_UNARY_POSTFIX) || 'new List<dynamic>()';//Blockly.CSharp.ORDER_MEMBER
      code = list + '.Aggregate((x, y) => x + y)';
      break;
    case 'MIN':
      list = Blockly.CSharp.valueToCode(block, 'LIST',
          Blockly.CSharp.ORDER_NONE) || 'new List<dynamic>()';//Blockly.CSharp.ORDER_COMMA
      code = list + '.Min()';
      break;
    case 'MAX':
      list = Blockly.CSharp.valueToCode(block, 'LIST',
          Blockly.CSharp.ORDER_NONE) || 'new List<dynamic>()';//Blockly.CSharp.ORDER_COMMA
      code = list + '.Max()';
      break;
    case 'AVERAGE'://动态dynamic List求和 ????????????????????????????????
        // ListAverage([null,null,1,3]) == 2.0.
        var functionName = Blockly.CSharp.provideFunction_(
            'ListAverage',
            ['function ' + Blockly.CSharp.FUNCTION_NAME_PLACEHOLDER_ +
            '(myList) {',
                '  return myList.reduce(function(x, y) {return x + y;}) / ' +
                'myList.length;',
                '}']);
      list = Blockly.CSharp.valueToCode(block, 'LIST',
          Blockly.CSharp.ORDER_NONE) || 'new List<dynamic>()';//Blockly.CSharp.ORDER_COMMA
        code = functionName + '(' + list + ')';//code = list + '.Average()';
      break;
    case 'MEDIAN':
      // math_median([null,null,1,3]) == 2.0.
      if (!Blockly.CSharp.definitions_['mathMedian']) {
        var functionName = Blockly.CSharp.variableDB_.getDistinctName(
            'mathMedian', Blockly.Generator.NAME_TYPE);
        Blockly.CSharp.math_on_list.math_median = functionName;
        var func = [];
        func.push('var ' + functionName + ' = new Func<List<dynamic>,dynamic>((vals) => {');
        func.push('  vals.Sort();');
        func.push('  if (vals.Count % 2 == 0)');
        func.push('    return (vals[vals.Count / 2 - 1] + vals[vals.Count / 2]) / 2;');
        func.push('  else');
        func.push('    return vals[(vals.Count - 1) / 2];');
        func.push('});');
        Blockly.CSharp.definitions_['math_median'] = func.join('\n');
      }
      list = Blockly.CSharp.valueToCode(block, 'LIST',
          Blockly.CSharp.ORDER_NONE) || 'new List<dynamic>()';
      code = Blockly.CSharp.math_on_list.math_median + '(' + list + ')';
      break;
    case 'MODE':
      if (!Blockly.CSharp.definitions_['math_modes']) {
        var functionName = Blockly.CSharp.variableDB_.getDistinctName(
            'math_modes', Blockly.Generator.NAME_TYPE);
        Blockly.CSharp.math_on_list.math_modes = functionName;
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
        Blockly.CSharp.definitions_['math_modes'] = func.join('\n');
      }
      list = Blockly.CSharp.valueToCode(block, 'LIST',
          Blockly.CSharp.ORDER_NONE) || 'new List<dynamic>()';
      code = Blockly.CSharp.math_on_list.math_modes + '(' + list + ')';
      break;
    case 'STD_DEV':
      if (!Blockly.CSharp.definitions_['math_standard_deviation']) {
        var functionName = Blockly.CSharp.variableDB_.getDistinctName(
            'math_standard_deviation', Blockly.Generator.NAME_TYPE);
        Blockly.CSharp.math_on_list.math_standard_deviation = functionName;
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
        Blockly.CSharp.definitions_['math_standard_deviation'] =
            func.join('\n');
      }
      list = Blockly.CSharp.valueToCode(this, 'LIST',
          Blockly.CSharp.ORDER_NONE) || 'new List<dynamic>()';
      code = Blockly.CSharp.math_on_list.math_standard_deviation +
          '(' + list + ')';
      break;
    case 'RANDOM':
      if (!Blockly.CSharp.definitions_['math_random_item']) {
        var functionName = Blockly.CSharp.variableDB_.getDistinctName(
            'math_random_item', Blockly.Generator.NAME_TYPE);
        Blockly.CSharp.math_on_list.math_random_item = functionName;
        var func = [];
        func.push('var ' + functionName + ' = new Func<List<dynamic>,dynamic>((list) => {');
        func.push('  var x = (new Random()).Next(list.Count);');
        func.push('  return list[x];');
        func.push('});');
        Blockly.CSharp.definitions_['math_random_item'] = func.join('\n');
      }
      list = Blockly.CSharp.valueToCode(block, 'LIST',
          Blockly.CSharp.ORDER_NONE) || 'new List<dynamic>()';
      code = Blockly.CSharp.math_on_list.math_random_item +
          '(' + list + ')';
      break;
    default:
      throw 'Unknown operator: ' + func;
  }
  return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
};

/**
 * 取余数
 * @param block
 * @returns {[null,null]}
 */
Blockly.CSharp['math_modulo'] = function(block) {
  // Remainder computation.
  var argument0 = Blockly.CSharp.valueToCode(block, 'DIVIDEND',
      Blockly.CSharp.ORDER_MULTIPLICATIVE) || '0.0';//Blockly.CSharp.ORDER_MODULUS
  var argument1 = Blockly.CSharp.valueToCode(block, 'DIVISOR',
      Blockly.CSharp.ORDER_MULTIPLICATIVE) || '0.0';//Blockly.CSharp.ORDER_MODULUS
  var code = argument0 + ' % ' + argument1;
  if(!block.parentBlock_ )
  {
    block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
    Blockly.CSharp.workspaceToCodeError = true;
    block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);

  }
  else
  {
    block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
    //Blockly.CSharp.workspaceToCodeError = false;
    block.setWarningText(null);
  }
  return [code, Blockly.CSharp.ORDER_MULTIPLICATIVE];//Blockly.CSharp.ORDER_MODULUS
};

Blockly.CSharp['math_constrain'] = function(block) {
  // Constrain a number between two limits.
  var argument0 = Blockly.CSharp.valueToCode(block, 'VALUE',
      Blockly.CSharp.ORDER_NONE) || '0.0';//Blockly.CSharp.ORDER_COMMA
  var argument1 = Blockly.CSharp.valueToCode(block, 'LOW',
      Blockly.CSharp.ORDER_NONE) || '0.0';//Blockly.CSharp.ORDER_COMMA
  var argument2 = Blockly.CSharp.valueToCode(block, 'HIGH',
      Blockly.CSharp.ORDER_NONE) || 'double.PositiveInfinity';//Blockly.CSharp.ORDER_COMMA
  var code = 'Math.Min(Math.Max(' + argument0 + ', ' + argument1 + '), ' +
      argument2 + ')';
  return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
};

Blockly.CSharp['math_random_int'] = function(block) {
  // Random integer between [X] and [Y].
  var argument0 = Blockly.CSharp.valueToCode(block, 'FROM',
      Blockly.CSharp.ORDER_NONE) || '0.0';//Blockly.CSharp.ORDER_COMMA
  var argument1 = Blockly.CSharp.valueToCode(block, 'TO',
      Blockly.CSharp.ORDER_NONE) || '0.0';//Blockly.CSharp.ORDER_COMMA
  /*
  if (!Blockly.CSharp.definitions_['math_random_int']) {
    var functionName = Blockly.CSharp.variableDB_.getDistinctName(
        'math_random_int', Blockly.Generator.NAME_TYPE);
    Blockly.CSharp.math_random_int.random_function = functionName;
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
    Blockly.CSharp.definitions_['math_random_int'] = func.join('\n');
  }

  var code = Blockly.CSharp.math_random_int.random_function +
      '(' + argument0 + ', ' + argument1 + ')';
  return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
  */
  var code = '(new Random()).Next(Convert.ToInt32(' + argument0 + '), Convert.ToInt32(' + argument1 +'))';
  return [code, Blockly.CSharp.ORDER_UNARY_POSTFIX];
};

Blockly.CSharp['math_random_float'] = function(block){
  // Random fraction between 0 and 1. double
  return ['(new Random()).NextDouble()', Blockly.CSharp.ORDER_UNARY_POSTFIX];//Blockly.CSharp.ORDER_FUNCTION_CALL
};
