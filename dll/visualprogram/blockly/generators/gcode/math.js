'use strict';

goog.provide('Blockly.GCode.math');

goog.require('Blockly.GCode');
goog.require('Blockly.Blocks');
goog.require('Blockly.Block');
goog.require('Blockly.CustomConfig');

Blockly.GCode['math_number'] = function (block) {
    // Numeric value.
    var raw  = block.getFieldValue('NUM');   // 字符串： "1" / "1.0" / "1.25"
    var code = raw.includes('.') ? raw : parseFloat(raw).toString();
    var order;
    if (code == Infinity) {
        code = 'double.INFINITY';
        order = Blockly.GCode.ORDER_UNARY_POSTFIX;
    } else if (code == -Infinity) {
        code = '-double.INFINITY';
        order = Blockly.GCode.ORDER_UNARY_PREFIX;
    } else {
        // -4.abs() returns -4 in Dart due to strange order of operation choices.
        // -4 is actually an operator and a number.  Reflect this in the order.
        order = code < 0 ?
            Blockly.GCode.ORDER_UNARY_PREFIX : Blockly.GCode.ORDER_ATOMIC;
    }
    // 默认数字按照float double 小数处理
    if (!(String(code).indexOf(".") > -1)) {
        code = String(code);
    }
    if (!block.parentBlock_) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);

    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        //Blockly.GCode.workspaceToCodeError = false;
        block.setWarningText(null);
    }
    return [code, order];
};

Blockly.GCode['math_constant'] = function (block) {
    // Constants: PI, E, the Golden Ratio, sqrt(2), 1/sqrt(2), INFINITY.
    var CONSTANTS = {
        'PI': ['#' + Math.PI, Blockly.GCode.ORDER_UNARY_POSTFIX],//Blockly.GCode.ORDER_MEMBER
        'E': ['#' + Math.E, Blockly.GCode.ORDER_UNARY_POSTFIX],//Blockly.GCode.ORDER_MEMBER
        'GOLDEN_RATIO':
            ['#' + (Math.sqrt(5) - 1) / 2, Blockly.GCode.ORDER_MULTIPLICATIVE],//Blockly.GCode.ORDER_DIVISION
        'SQRT2': ['#' + Math.SQRT2, Blockly.GCode.ORDER_UNARY_POSTFIX],//Blockly.GCode.ORDER_MEMBER
        'SQRT1_2': ['#' + Math.SQRT1_2, Blockly.GCode.ORDER_UNARY_POSTFIX],//Blockly.GCode.ORDER_MEMBER
        //'INFINITY': ['double.PositiveInfinity', Blockly.GCode.ORDER_ATOMIC]
    };
    if (!block.parentBlock_) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);

    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        //Blockly.GCode.workspaceToCodeError = false;
        block.setWarningText(null);
    }
    return CONSTANTS[block.getFieldValue('CONSTANT')];
};

Blockly.GCode['math_arithmetic'] = function (block) {
    // Basic arithmetic operators, and power.
    var OPERATORS = {
        'ADD': [' + ', Blockly.GCode.ORDER_ADDITIVE],//Blockly.GCode.ORDER_ADDITION
        'MINUS': [' - ', Blockly.GCode.ORDER_ADDITIVE],//Blockly.GCode.ORDER_SUBTRACTION
        'MULTIPLY': [' * ', Blockly.GCode.ORDER_MULTIPLICATIVE],//Blockly.GCode.ORDER_MULTIPLICATION
        'DIVIDE': [' / ', Blockly.GCode.ORDER_MULTIPLICATIVE],//Blockly.GCode.ORDER_DIVISION
        'MODULO': [' % ', Blockly.GCode.ORDER_MULTIPLICATIVE],  // Handle power separately.
        'BITAND': [' & ', Blockly.GCode.ORDER_BITWISE_AND],  // Handle power separately.
        'BITXOR': [' ^ ', Blockly.GCode.ORDER_BITWISE_XOR],
        'BITOR': [' | ', Blockly.GCode.ORDER_BITWISE_OR],
        'LeftShift': [' << ', Blockly.GCode.ORDER_BITWISE_SHIFT],
        'RightShift': [' >> ', Blockly.GCode.ORDER_BITWISE_SHIFT],
        'LOOP': [' ∞ ', Blockly.GCode.ORDER_BITWISE_SHIFT]
    };
    var tuple = OPERATORS[block.getFieldValue('OP')];
    var operator = tuple[0];
    var order = tuple[1];
    var argument0 = Blockly.GCode.valueToCode(block, 'A', order) || '0.0';//'0.0' or '0'  ????????????????????
    var argument1 = Blockly.GCode.valueToCode(block, 'B', order) || '0.0';
    var argNum0 = parseInt(argument0);
    if (!isNaN(argNum0)) {
        argument0 = '#' + argument0;
    }
    var argNum1 = parseInt(argument1);
    if (!isNaN(argNum1)) {
        argument1 = '#' + argument1;
    }

    // Power in GCode requires a special case since it has no operator.
    // if (!operator) {
    //   code = 'Math.Pow(' + argument0 + ', ' + argument1 + ')';
    //   return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
    // }
    var code;
    code = ' ( ' + argument0 + operator + argument1 + ' ) ';
    if (!block.parentBlock_) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);

    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        //Blockly.GCode.workspaceToCodeError = false;
        block.setWarningText(null);
    }
    return [code, order];
};

Blockly.GCode['motion_point_join'] = function (block) {
    // Create a string made up of any number of elements of any type.
    var code = '';
    for (var i = 0; i < block.itemCount_; i++) {
        var element = Blockly.GCode.valueToCode(block, 'ADD' + i, Blockly.GCode.ORDER_NONE);
        if (!(element == '')) {
            code += ' P' + element;
        }
    }
    // code += Blockly.GCode.valueToCode(block, 'ADD' + (block.itemCount_-1),Blockly.GCode.ORDER_NONE);
    if (!block.parentBlock_) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.CONTROL_ERROR_LOGICERROR);
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
    }
    // return code;//
    return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];
};

Blockly.GCode['motion_point_idx'] = function (block) {
    var idx_value = Blockly.GCode.valueToCode(block, 'Index', Blockly.GCode.ORDER_ATOMIC);//parseFloat
    var code = '';
    if (idx_value != '') code = idx_value;

    return [code, Blockly.GCode.ORDER_UNARY_PREFIX];
};

Blockly.GCode['math_variable'] = function (block) {
    var argument0 = Blockly.GCode.valueToCode(block, 'Variable_Value',
        Blockly.GCode.ORDER_ASSIGNMENT);
    if (!argument0 || argument0 == "") {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("输入模块不能为空!");
        argument0 = '0';
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
        block.setWarningText(null);
    }

    var argument_index = Blockly.GCode.valueToCode(block, 'Variable_Idx', Blockly.GCode.ORDER_ASSIGNMENT);
    if (!argument_index || argument_index == "") {

        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("输入模块不能为空!");
        argument_index = '0';
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
        block.setWarningText(null);
    }


    if (!(/^[a-zA-Z]/.test(argument_index) || /^[0-9]/.test(argument_index))) {

        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用表达式作为变量！！！");
    }
    if (argument_index.startsWith('X') || argument_index.startsWith('x') ||
        argument_index.startsWith('Y') || argument_index.startsWith('y') ||
        argument_index.startsWith('M') || argument_index.startsWith('m') ||
        argument_index.startsWith('T') || argument_index.startsWith('t')) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用XYMT作为变量！！！");

    }
    var varName = Blockly.GCode.variableDB_.getName(
        block.getFieldValue('Variable_Name'), Blockly.Variables.NAME_TYPE);
    //var varIdx = block.getFieldValue('Variable_Idx') || '0';


    var idxvar = parseInt(argument_index);
    var argNum = parseInt(argument0);
    var varIdx;
    varIdx = argument_index;
    // if (isNaN(idxvar)) {
    //     varIdx = argument_index;
    // } else {
    //     varIdx = idxvar;
    // }
    var code;
    switch (varName) {
        case 'Px':
            code = 'P' + varIdx + '.01'; break;
        case 'Py':
            code = 'P' + varIdx + '.02'; break;
        case 'Pz':
            code = 'P' + varIdx + '.03'; break;
        case 'Pw':
            code = 'P' + varIdx + '.04'; break;
        case 'U1':
            code = 'P' + varIdx + '.11'; break;
        case 'U2':
            code = 'P' + varIdx + '.12'; break;
        case 'U3':
            code = 'P' + varIdx + '.13'; break;
        case 'U4':
            code = 'P' + varIdx + '.14'; break;
        default:
            code = varName + varIdx; break;
    }
    if (isNaN(argNum)) {
        code += ' = ' + argument0 + '\n';
    } else {
        code += ' = #' + argument0 + '\n';
    }
    return code;
};


Blockly.GCode['thread_get_data'] = function (block) {
    var active_coil = block.getFieldValue('ACTIVE_Data');
    var argument_index = Blockly.GCode.valueToCode(block, 'Idx', Blockly.GCode.ORDER_ASSIGNMENT);

    if (!argument_index || argument_index == "") {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("输入模块不能为空!");
        argument_index = '0';
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
        block.setWarningText(null);
    }

    if (!(/^[a-zA-Z]/.test(argument_index) || /^[0-9]/.test(argument_index))) {

        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用表达式作为变量！！！");
    }

    if (argument_index.startsWith('X') || argument_index.startsWith('x') ||
        argument_index.startsWith('Y') || argument_index.startsWith('y') ||
        argument_index.startsWith('M') || argument_index.startsWith('m') ||
        argument_index.startsWith('T') || argument_index.startsWith('t')) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用XYMT作为变量！！！");
    }

    var idxvar = parseInt(argument_index);
    var value_idx;
    value_idx = argument_index;
    // if (isNaN(idxvar)) {
    //     value_idx = argument_index;
    // } else {
    //     value_idx = idxvar;
    // }




    var code = '';
    switch (active_coil) {
        case 'Px':
            code = 'P' + value_idx + '.01'; break;
        case 'Py':
            code = 'P' + value_idx + '.02'; break;
        case 'Pz':
            code = 'P' + value_idx + '.03'; break;
        case 'Pw':
            code = 'P' + value_idx + '.04'; break;
        case 'U1':
            code = 'P' + value_idx + '.11'; break;
        case 'U2':
            code = 'P' + value_idx + '.12'; break;
        case 'U3':
            code = 'P' + value_idx + '.13'; break;
        case 'U4':
            code = 'P' + value_idx + '.14'; break;
        default:

            code = active_coil + value_idx; break;
    }
    return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['thread_get_bitX'] = function (block) {
    // var active_coil = Blockly.GCode.valueToCode(block,'ACTIVE_Coil',Blockly.GCode.ORDER_ATOMIC) || 'M' ;


    var active_data = block.getFieldValue('ACTIVE_Data');

    var argument_index = Blockly.GCode.valueToCode(block, 'Idx', Blockly.GCode.ORDER_ASSIGNMENT);

    if (!argument_index || argument_index == "") {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("输入模块不能为空!");
        argument_index = '0';
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
        block.setWarningText(null);
    }
    var indexError = null;
    if (argument_index.startsWith('X') || argument_index.startsWith('x') ||
        argument_index.startsWith('Y') || argument_index.startsWith('y') ||
        argument_index.startsWith('M') || argument_index.startsWith('m') ||
        argument_index.startsWith('T') || argument_index.startsWith('t')) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用XYMT作为变量！！！");
        indexError = "变量参数违法，不能用XYMT作为变量！！！";
    }
    if (!(/^[a-zA-Z]/.test(argument_index) || /^[0-9]/.test(argument_index))) {

        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用表达式作为变量！！！");
        indexError = "变量参数违法，不能用表达式作为变量！！！";
    }
    var idxvar = parseInt(argument_index);
    var varIdx;
    varIdx = argument_index;
    // if (isNaN(idxvar)) {
    //     value_idx = argument_index;
    // } else {
    //     value_idx = idxvar;
    // }


    var value_type = '';
    switch (active_data) {
        case 'XUP':
            value_type = '↑X';
            break;
        case 'XDN':
            value_type = '↓X';
            break;
        case 'XOFF':
            value_type = '!X';
            break;
        default:
            value_type = active_data;
            break;
    }
    var IsConnectCheck = false;
    if (!block.parentBlock_) {
        IsConnectCheck = true;
    }
    if (indexError || IsConnectCheck) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        var ErrString = "";
        if (indexError) ErrString = ErrString + indexError;
        if (IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
        block.setWarningText(ErrString);
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
    }
    var code = value_type + varIdx + ' ';
    return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['thread_get_bitY'] = function (block) {
    // var active_coil = Blockly.GCode.valueToCode(block,'ACTIVE_Coil',Blockly.GCode.ORDER_ATOMIC) || 'M' ;

    var active_data = block.getFieldValue('ACTIVE_Data');
    var argument_index = Blockly.GCode.valueToCode(block, 'Idx', Blockly.GCode.ORDER_ASSIGNMENT);

    if (!argument_index || argument_index == "") {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("输入模块不能为空!");
        argument_index = '0';
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
        block.setWarningText(null);
    }
    var indexError = null;
    if (argument_index.startsWith('X') || argument_index.startsWith('x') ||
        argument_index.startsWith('Y') || argument_index.startsWith('y') ||
        argument_index.startsWith('M') || argument_index.startsWith('m') ||
        argument_index.startsWith('T') || argument_index.startsWith('t')) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用XYMT作为变量！！！");
        indexError = "变量参数违法，不能用XYMT作为变量！！！";
    }
    if (!(/^[a-zA-Z]/.test(argument_index) || /^[0-9]/.test(argument_index))) {

        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用表达式作为变量！！！");
        indexError = "变量参数违法，不能用表达式作为变量！！！";
    }
    var idxvar = parseInt(argument_index);
    var varIdx;
    varIdx = argument_index;
    // if (isNaN(idxvar)) {
    //     value_idx = argument_index;
    // } else {
    //     value_idx = idxvar;
    // }

    var value_type = '';
    switch (active_data) {
        case 'YUP':
            value_type = '↑Y';
            break;
        case 'YDN':
            value_type = '↓Y';
            break;
        case 'YOFF':
            value_type = '!Y';
            break;
        default:
            value_type = active_data;
            break;
    }
    var IsConnectCheck = false;
    if (!block.parentBlock_) {
        IsConnectCheck = true;
    }
    if (indexError || IsConnectCheck) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        var ErrString = "";
        if (indexError) ErrString = ErrString + indexError;
        if (IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
        block.setWarningText(ErrString);
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
    }
    var code = value_type + varIdx + ' ';
    return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['thread_get_bitM'] = function (block) {
    // var active_coil = Blockly.GCode.valueToCode(block,'ACTIVE_Coil',Blockly.GCode.ORDER_ATOMIC) || 'M' ;

    var active_data = block.getFieldValue('ACTIVE_Data');

    var argument_index = Blockly.GCode.valueToCode(block, 'Idx', Blockly.GCode.ORDER_ASSIGNMENT);
    var indexError = null;
    if (!argument_index || argument_index == "") {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("输入模块不能为空!");
        argument_index = '0';
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
        block.setWarningText(null);
    }

    if (argument_index.startsWith('X') || argument_index.startsWith('x') ||
        argument_index.startsWith('Y') || argument_index.startsWith('y') ||
        argument_index.startsWith('M') || argument_index.startsWith('m') ||
        argument_index.startsWith('T') || argument_index.startsWith('t')) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用XYMT作为变量！！！");
        indexError = "变量参数违法，不能用XYMT作为变量！！！";
    }
    if (!(/^[a-zA-Z]/.test(argument_index) || /^[0-9]/.test(argument_index))) {

        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用表达式作为变量！！！");
        indexError = "变量参数违法，不能用表达式作为变量！！！";
    }
    var idxvar = parseInt(argument_index);
    var varIdx;
    varIdx = argument_index;
    // if (isNaN(idxvar)) {
    //     value_idx = argument_index;
    // } else {
    //     value_idx = idxvar;
    // }

    var value_type = '';
    switch (active_data) {
        case 'MUP':
            value_type = '↑M';
            break;
        case 'MDN':
            value_type = '↓M';
            break;
        case 'MOFF':
            value_type = '!M';
            break;
        default:
            value_type = active_data;
            break;
    }

    var IsConnectCheck = false;
    if (!block.parentBlock_) {
        IsConnectCheck = true;
    }
    if (indexError || IsConnectCheck) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        var ErrString = "";
        if (indexError) ErrString = ErrString + indexError;
        if (IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
        block.setWarningText(ErrString);
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
    }
    var code = value_type + varIdx + ' ';
    return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['thread_get_bitS'] = function (block) {
    // var active_coil = Blockly.GCode.valueToCode(block,'ACTIVE_Coil',Blockly.GCode.ORDER_ATOMIC) || 'M' ;

    var active_data = block.getFieldValue('ACTIVE_Data');
    var argument_index = Blockly.GCode.valueToCode(block, 'Idx', Blockly.GCode.ORDER_ASSIGNMENT);
    var indexError = null;
    if (!argument_index || argument_index == "") {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("输入模块不能为空!");
        argument_index = '0';
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
        block.setWarningText(null);
    }

    if (argument_index.startsWith('X') || argument_index.startsWith('x') ||
        argument_index.startsWith('Y') || argument_index.startsWith('y') ||
        argument_index.startsWith('M') || argument_index.startsWith('m') ||
        argument_index.startsWith('T') || argument_index.startsWith('t')) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用XYMT作为变量！！！");
        indexError = "变量参数违法，不能用XYMT作为变量！！！";
    }
    if (!(/^[a-zA-Z]/.test(argument_index) || /^[0-9]/.test(argument_index))) {

        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用表达式作为变量！！！");
        indexError = "变量参数违法，不能用表达式作为变量！！！";
    }
    var idxvar = parseInt(argument_index);
    var varIdx;
    varIdx = argument_index;
    // if (isNaN(idxvar)) {
    //     value_idx = argument_index;
    // } else {
    //     value_idx = idxvar;
    // }


    var value_type = '';
    switch (active_data) {
        case 'SUP':
            value_type = '↑S';
            break;
        case 'SDN':
            value_type = '↓S';
            break;
        case 'SOFF':
            value_type = '!S';
            break;
        default:
            value_type = active_data;
            break;
    }
    var IsConnectCheck = false;
    if (!block.parentBlock_) {
        IsConnectCheck = true;
    }
    if (indexError || IsConnectCheck) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        var ErrString = "";
        if (indexError) ErrString = ErrString + indexError;
        if (IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
        block.setWarningText(ErrString);
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
    }
    var code = value_type + varIdx + ' ';
    return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['thread_get_bitT'] = function (block) {
    // var active_coil = Blockly.GCode.valueToCode(block,'ACTIVE_Coil',Blockly.GCode.ORDER_ATOMIC) || 'M' ;

    var active_data = block.getFieldValue('ACTIVE_Data');
    var argument_index = Blockly.GCode.valueToCode(block, 'Idx', Blockly.GCode.ORDER_ASSIGNMENT);
    if (!argument_index || argument_index == "") {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("输入模块不能为空!");
        argument_index = '0';
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_VARIABLES_RGB);
        block.setWarningText(null);
    }

    var indexError = null;

    if (argument_index.startsWith('X') || argument_index.startsWith('x') ||
        argument_index.startsWith('Y') || argument_index.startsWith('y') ||
        argument_index.startsWith('M') || argument_index.startsWith('m') ||
        argument_index.startsWith('T') || argument_index.startsWith('t')) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用XYMT作为变量！！！");
        indexError = "变量参数违法，不能用XYMT作为变量！！！";
    }
    if (!(/^[a-zA-Z]/.test(argument_index) || /^[0-9]/.test(argument_index))) {

        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText("变量参数违法，不能用表达式作为变量！！！");
        indexError = "变量参数违法，不能用表达式作为变量！！！";
    }
    var idxvar = parseInt(argument_index);
    var varIdx;
    varIdx = argument_index;
    // if (isNaN(idxvar)) {
    //     value_idx = argument_index;
    // } else {
    //     value_idx = idxvar;
    // }



    var value_type = '';
    switch (active_data) {
        case 'TUP':
            value_type = '↑T';
            break;
        case 'TDN':
            value_type = '↓T';
            break;
        case 'TOFF':
            value_type = '!T';
            break;
        default:
            value_type = active_data;
            break;
    }

    var IsConnectCheck = false;
    if (!block.parentBlock_) {
        IsConnectCheck = true;
    }
    if (indexError || IsConnectCheck) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        var ErrString = "";
        if (indexError) ErrString = ErrString + indexError;
        if (IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
        block.setWarningText(ErrString);
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
    }

    var code = value_type + varIdx + ' ';
    return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['thread_get_bitC'] = function (block) {
    // var active_coil = Blockly.GCode.valueToCode(block,'ACTIVE_Coil',Blockly.GCode.ORDER_ATOMIC) || 'M' ;

    var active_data = block.getFieldValue('ACTIVE_Data');
    var value_idx = block.getFieldValue('Idx') || '0';

    var value_type = '';
    switch (active_data) {
        case 'CUP':
            value_type = '↑C';
            break;
        case 'CDN':
            value_type = '↓C';
            break;
        case 'COFF':
            value_type = '!C';
            break;
        default:
            value_type = active_data;
            break;
    }
    value_idx = value_idx.replace('(', '');
    value_idx = value_idx.replace(')', '');
    value_idx = parseInt(value_idx);
    var indexError = null;
    if (isNaN(value_idx))//NaN 错误
    {
        //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        value_idx = 100;
        Blockly.GCode.workspaceToCodeError = true;
        Blockly.GCode.workspaceToCodeErrorString = Blockly.GCode.workspaceToCodeErrorString
            + "获取M函数转换出错函数转换出错,请检查M地址是否正确,只能填写0~9999的正整数;\n";
        indexError = "获取M函数转换出错,请检查M地址是否正确,只能填写0~9999的正整数;\n";
    }
    else {
        if (value_idx < 0 || value_idx > 9999)//<=0 错误
        {
            //block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
            value_idx = 0;
            Blockly.GCode.workspaceToCodeError = true;
            Blockly.GCode.workspaceToCodeErrorString = Blockly.GCode.workspaceToCodeErrorString
                + "获取M函数转换出错函数转换出错,请检查M地址是否正确,只能填写0~9999的正整数;\n";
            indexError = "获取M函数转换出错函数转换出错,请检查M地址是否正确,只能填写0~9999的正整数;\n";
        }
    }
    var IsConnectCheck = false;
    if (!block.parentBlock_) {
        IsConnectCheck = true;
    }
    if (indexError || IsConnectCheck) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        var ErrString = "";
        if (indexError) ErrString = ErrString + indexError;
        if (IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
        block.setWarningText(ErrString);
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
    }

    var code = value_type + value_idx + ' ';
    return [code, Blockly.GCode.ORDER_ATOMIC];
};

Blockly.GCode['math_variableNotes'] = function (block) {
    var code = "";
    return code;
};

/** ----------------------------------------------以下无用--------------------------------------------- */

Blockly.GCode['math_single'] = function (block) {
    // Math operators with single operand.
    var operator = block.getFieldValue('OP');
    var code;
    var arg;
    if (operator == 'NEG') {
        // Negation is a special case given its different operator precedence.
        arg = Blockly.GCode.valueToCode(block, 'NUM',
            Blockly.GCode.ORDER_UNARY_PREFIX) || '0.0';//Blockly.GCode.ORDER_UNARY_NEGATION
        if (arg[0] == '-') {
            // --3 is not allowed
            arg = ' ' + arg;
        }
        code = '-' + arg;
        return [code, Blockly.GCode.ORDER_UNARY_PREFIX];//Blockly.GCode.ORDER_UNARY_NEGATION
    }
    if (operator == 'SIN' || operator == 'COS' || operator == 'TAN') {
        arg = Blockly.GCode.valueToCode(block, 'NUM',
            Blockly.GCode.ORDER_MULTIPLICATIVE) || '0';//Blockly.GCode.ORDER_DIVISION
    } else {
        arg = Blockly.GCode.valueToCode(block, 'NUM',
            Blockly.GCode.ORDER_NONE) || '0.0';
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
        return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
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
    return [code, Blockly.GCode.ORDER_MULTIPLICATIVE];//Blockly.GCode.ORDER_DIVISION
};

Blockly.GCode['logic_negate'] = function (block) {
    // Negation.
    var order = Blockly.GCode.ORDER_UNARY_PREFIX;//Blockly.GCode.ORDER_LOGICAL_NOT
    var argument0 = Blockly.GCode.valueToCode(block, 'BOOL', order);
    var IsEmptyCheck = false;
    if (!argument0) {
        IsEmptyCheck = true;
        argument0 = 'true';
    }
    var code = '!' + argument0;
    var IsConnectCheck = false;
    if (!block.parentBlock_) {
        IsConnectCheck = true;
    }

    if (IsEmptyCheck || IsConnectCheck) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        var ErrString = "";
        if (IsEmptyCheck) ErrString = ErrString + "输入模块不能为空!\n";
        if (IsConnectCheck) ErrString = ErrString + Blockly.Msg.CONTROL_ERROR_LOGICERROR + "\n";
        block.setWarningText(ErrString);
    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        block.setWarningText(null);
    }
    return [code, order];
};

Blockly.GCode['math_number_property'] = function (block) {
    // Check if a number is even, odd, prime, whole, positive, or negative
    // or if it is divisible by certain number. Returns true or false.
    var number_to_check = Blockly.GCode.valueToCode(block, 'NUMBER_TO_CHECK',
        Blockly.GCode.ORDER_MULTIPLICATIVE) || 'double.NaN';//Blockly.GCode.ORDER_MODULUS
    var dropdown_property = block.getFieldValue('PROPERTY');
    var code;
    if (dropdown_property == 'PRIME') {
        // Prime is a special case as it is not a one-liner test.
        if (!Blockly.GCode.definitions_['MathisPrime']) {
            var functionName = Blockly.GCode.variableDB_.getDistinctName(
                'MathisPrime', Blockly.Generator.NAME_TYPE);
            Blockly.GCode.logic_prime = functionName;
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
            Blockly.GCode.definitions_['MathisPrime'] = func.join('\n');
        }
        code = Blockly.GCode.logic_prime + '(' + number_to_check + ')';
        return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
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
            var divisor = Blockly.GCode.valueToCode(block, 'DIVISOR',
                Blockly.GCode.ORDER_MULTIPLICATIVE) || 'double.NaN';// '0';//Blockly.GCode.ORDER_MODULUS
            code = number_to_check + ' % ' + divisor + ' == 0';
            break;
    }
    if (!block.parentBlock_) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);

    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        //Blockly.GCode.workspaceToCodeError = false;
        block.setWarningText(null);
    }
    return [code, Blockly.GCode.ORDER_EQUALITY];
};

Blockly.GCode['math_change'] = function (block) {
    // Add to a variable in place.
    var argument0 = Blockly.GCode.valueToCode(block, 'DELTA',
        Blockly.GCode.ORDER_ADDITIVE) || '0.0';//Blockly.GCode.ORDER_ADDITION
    var varName = Blockly.GCode.variableDB_.getName(
        block.getFieldValue('VAR'), Blockly.Variables.NAME_TYPE);
    return varName + ' = (' + varName + '.GetType().Name == "Double" ? '
        + varName + ' : 0.0) + ' + argument0 + ';\n';
};

// Rounding functions have a single operand.
Blockly.GCode['math_round'] = Blockly.GCode['math_single'];
// Trigonometry functions have a single operand.
Blockly.GCode['math_trig'] = Blockly.GCode['math_single'];

/**
 * list 相关函数暂时未使用
 * @param block
 * @returns {[null,null]}
 */
Blockly.GCode['math_on_list'] = function (block) {
    // Math functions for lists.
    var func = block.getFieldValue('OP');
    var list, code;
    switch (func) {
        case 'SUM':
            list = Blockly.GCode.valueToCode(block, 'LIST',
                Blockly.GCode.ORDER_UNARY_POSTFIX) || 'new List<dynamic>()';//Blockly.GCode.ORDER_MEMBER
            code = list + '.Aggregate((x, y) => x + y)';
            break;
        case 'MIN':
            list = Blockly.GCode.valueToCode(block, 'LIST',
                Blockly.GCode.ORDER_NONE) || 'new List<dynamic>()';//Blockly.GCode.ORDER_COMMA
            code = list + '.Min()';
            break;
        case 'MAX':
            list = Blockly.GCode.valueToCode(block, 'LIST',
                Blockly.GCode.ORDER_NONE) || 'new List<dynamic>()';//Blockly.GCode.ORDER_COMMA
            code = list + '.Max()';
            break;
        case 'AVERAGE'://动态dynamic List求和 ????????????????????????????????
            // ListAverage([null,null,1,3]) == 2.0.
            var functionName = Blockly.GCode.provideFunction_(
                'ListAverage',
                ['function ' + Blockly.GCode.FUNCTION_NAME_PLACEHOLDER_ +
                    '(myList) {',
                '  return myList.reduce(function(x, y) {return x + y;}) / ' +
                'myList.length;',
                    '}']);
            list = Blockly.GCode.valueToCode(block, 'LIST',
                Blockly.GCode.ORDER_NONE) || 'new List<dynamic>()';//Blockly.GCode.ORDER_COMMA
            code = functionName + '(' + list + ')';//code = list + '.Average()';
            break;
        case 'MEDIAN':
            // math_median([null,null,1,3]) == 2.0.
            if (!Blockly.GCode.definitions_['mathMedian']) {
                var functionName = Blockly.GCode.variableDB_.getDistinctName(
                    'mathMedian', Blockly.Generator.NAME_TYPE);
                Blockly.GCode.math_on_list.math_median = functionName;
                var func = [];
                func.push('var ' + functionName + ' = new Func<List<dynamic>,dynamic>((vals) => {');
                func.push('  vals.Sort();');
                func.push('  if (vals.Count % 2 == 0)');
                func.push('    return (vals[vals.Count / 2 - 1] + vals[vals.Count / 2]) / 2;');
                func.push('  else');
                func.push('    return vals[(vals.Count - 1) / 2];');
                func.push('});');
                Blockly.GCode.definitions_['math_median'] = func.join('\n');
            }
            list = Blockly.GCode.valueToCode(block, 'LIST',
                Blockly.GCode.ORDER_NONE) || 'new List<dynamic>()';
            code = Blockly.GCode.math_on_list.math_median + '(' + list + ')';
            break;
        case 'MODE':
            if (!Blockly.GCode.definitions_['math_modes']) {
                var functionName = Blockly.GCode.variableDB_.getDistinctName(
                    'math_modes', Blockly.Generator.NAME_TYPE);
                Blockly.GCode.math_on_list.math_modes = functionName;
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
                Blockly.GCode.definitions_['math_modes'] = func.join('\n');
            }
            list = Blockly.GCode.valueToCode(block, 'LIST',
                Blockly.GCode.ORDER_NONE) || 'new List<dynamic>()';
            code = Blockly.GCode.math_on_list.math_modes + '(' + list + ')';
            break;
        case 'STD_DEV':
            if (!Blockly.GCode.definitions_['math_standard_deviation']) {
                var functionName = Blockly.GCode.variableDB_.getDistinctName(
                    'math_standard_deviation', Blockly.Generator.NAME_TYPE);
                Blockly.GCode.math_on_list.math_standard_deviation = functionName;
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
                Blockly.GCode.definitions_['math_standard_deviation'] =
                    func.join('\n');
            }
            list = Blockly.GCode.valueToCode(this, 'LIST',
                Blockly.GCode.ORDER_NONE) || 'new List<dynamic>()';
            code = Blockly.GCode.math_on_list.math_standard_deviation +
                '(' + list + ')';
            break;
        case 'RANDOM':
            if (!Blockly.GCode.definitions_['math_random_item']) {
                var functionName = Blockly.GCode.variableDB_.getDistinctName(
                    'math_random_item', Blockly.Generator.NAME_TYPE);
                Blockly.GCode.math_on_list.math_random_item = functionName;
                var func = [];
                func.push('var ' + functionName + ' = new Func<List<dynamic>,dynamic>((list) => {');
                func.push('  var x = (new Random()).Next(list.Count);');
                func.push('  return list[x];');
                func.push('});');
                Blockly.GCode.definitions_['math_random_item'] = func.join('\n');
            }
            list = Blockly.GCode.valueToCode(block, 'LIST',
                Blockly.GCode.ORDER_NONE) || 'new List<dynamic>()';
            code = Blockly.GCode.math_on_list.math_random_item +
                '(' + list + ')';
            break;
        default:
            throw 'Unknown operator: ' + func;
    }
    return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
};

/**
 * 取余数
 * @param block
 * @returns {[null,null]}
 */
Blockly.GCode['math_modulo'] = function (block) {
    // Remainder computation.
    var argument0 = Blockly.GCode.valueToCode(block, 'DIVIDEND',
        Blockly.GCode.ORDER_MULTIPLICATIVE) || '0.0';//Blockly.GCode.ORDER_MODULUS
    var argument1 = Blockly.GCode.valueToCode(block, 'DIVISOR',
        Blockly.GCode.ORDER_MULTIPLICATIVE) || '0.0';//Blockly.GCode.ORDER_MODULUS
    var code = argument0 + ' % ' + argument1;
    if (!block.parentBlock_) {
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        Blockly.GCode.workspaceToCodeError = true;
        block.setWarningText(Blockly.Msg.MATH_ERROR_NUMBERERROR);

    }
    else {
        block.setColour(Blockly.CustomConfig.BLOCK_CONTROL_RGB);
        //Blockly.GCode.workspaceToCodeError = false;
        block.setWarningText(null);
    }
    return [code, Blockly.GCode.ORDER_MULTIPLICATIVE];//Blockly.GCode.ORDER_MODULUS
};

Blockly.GCode['math_constrain'] = function (block) {
    // Constrain a number between two limits.
    var argument0 = Blockly.GCode.valueToCode(block, 'VALUE',
        Blockly.GCode.ORDER_NONE) || '0.0';//Blockly.GCode.ORDER_COMMA
    var argument1 = Blockly.GCode.valueToCode(block, 'LOW',
        Blockly.GCode.ORDER_NONE) || '0.0';//Blockly.GCode.ORDER_COMMA
    var argument2 = Blockly.GCode.valueToCode(block, 'HIGH',
        Blockly.GCode.ORDER_NONE) || 'double.PositiveInfinity';//Blockly.GCode.ORDER_COMMA
    var code = 'Math.Min(Math.Max(' + argument0 + ', ' + argument1 + '), ' +
        argument2 + ')';
    return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
};

Blockly.GCode['math_random_int'] = function (block) {
    // Random integer between [X] and [Y].
    var argument0 = Blockly.GCode.valueToCode(block, 'FROM',
        Blockly.GCode.ORDER_NONE) || '0.0';//Blockly.GCode.ORDER_COMMA
    var argument1 = Blockly.GCode.valueToCode(block, 'TO',
        Blockly.GCode.ORDER_NONE) || '0.0';//Blockly.GCode.ORDER_COMMA
    /*
    if (!Blockly.GCode.definitions_['math_random_int']) {
      var functionName = Blockly.GCode.variableDB_.getDistinctName(
          'math_random_int', Blockly.Generator.NAME_TYPE);
      Blockly.GCode.math_random_int.random_function = functionName;
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
      Blockly.GCode.definitions_['math_random_int'] = func.join('\n');
    }

    var code = Blockly.GCode.math_random_int.random_function +
        '(' + argument0 + ', ' + argument1 + ')';
    return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
    */
    var code = '(new Random()).Next(Convert.ToInt32(' + argument0 + '), Convert.ToInt32(' + argument1 + '))';
    return [code, Blockly.GCode.ORDER_UNARY_POSTFIX];
};

Blockly.GCode['math_random_float'] = function (block) {
    // Random fraction between 0 and 1. double
    return ['(new Random()).NextDouble()', Blockly.GCode.ORDER_UNARY_POSTFIX];//Blockly.GCode.ORDER_FUNCTION_CALL
};

