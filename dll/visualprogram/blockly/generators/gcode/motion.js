'use strict';

goog.provide("Blockly.GCode.motion");
goog.require("Blockly.GCode");
goog.require('Blockly.Blocks');
goog.require('Blockly.Block');
goog.require('Blockly.CustomConfig');


Blockly.GCode.ComPortList = [];

Blockly.GCode['math_number_int'] = function (block) {
    // Numeric value.
    var code = (parseInt(block.getFieldValue('NUM')));//parseFloat
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
    return [code, order];
};

Blockly.GCode['math_number_uint'] = function (block) {
    // Numeric value.
    var code = Math.abs(parseInt(block.getFieldValue('NUM')));//parseFloat
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
    return [code, order];
};

/** P点 坐标点编号门型定位 */
Blockly.GCode['motion_moveptp_point'] = function (block) {
    var Position_mode = block.getFieldValue('OP_G90');
    // var G90 = Blockly.GCode.valueToCode(block, 'G90', Blockly.GCode.ORDER_ATOMIC);

    var motion_mode = block.getFieldValue('MotionMode');
    var value_pointValue = '';
    var value_heightavoid = '25.0';
    var value_maxspeed = '1000';
    var value_endspeed = '0';

    ////------------------------------------------------------ 解析'条件'子块信息
    for (var i = 0; i < block.paraCount_; i++) {
        var operator = block.getFieldValue('OP' + i);
        var element = Blockly.GCode.valueToCode(block, 'PARA' + i, Blockly.GCode.ORDER_ATOMIC);
        if (element) {
            switch (operator) {
                case "AvoidPoint":
                    value_pointValue += ' P' + element;
                    break;
                case "HeightAvoid":
                    value_heightavoid = element;
                    break;
                case "MaxSpeed":
                    value_maxspeed = element;
                    break;
                case "EndSpeed":
                    value_endspeed = element;
                    break;
            }
        }
    }
    value_maxspeed = value_maxspeed.replace('(', '');
    value_maxspeed = value_maxspeed.replace(')', '');
    value_endspeed = value_endspeed.replace('(', '');
    value_endspeed = value_endspeed.replace(')', '');
    value_heightavoid = value_heightavoid.replace('(', '');
    value_heightavoid = value_heightavoid.replace(')', '');
    value_heightavoid = parseFloat(value_heightavoid);//避障高度转换成浮点型

    var havoidError = null;
    if (isNaN(value_heightavoid))//NaN 错误
    {
        value_heightavoid = 25.0;
        havoidError = "请检查避障高度参数，只能输入整数！" + "\n";
    }

    ////------------------------------------------------------ 解析'IO'子块信息
    var ioCode = '';
    var ioError = null;
    for (var i = 0; i < block.ioCount_; i++) {
        var value_IoNum = Blockly.GCode.valueToCode(block, 'IO' + i,
            Blockly.GCode.ORDER_ATOMIC) || '0';
        var value_ratio = Blockly.GCode.valueToCode(block, 'DisRatio' + i,
            Blockly.GCode.ORDER_ATOMIC) || '0';

        if (isNaN(value_IoNum) || isNaN(value_ratio)) {
            ioError = "请检查IO号和位移比是否正确,只能填写正数" + "\n";
        }
        else if (value_ratio < 0 || value_ratio > 1) {
            ioError = "请检查位移比是否正确,只能填写0到1之间的数字" + "\n";
        }
        ioCode = ioCode + " Y" + value_IoNum + " r" + value_ratio;
    }

    ////------------------------------------------------------ 解析'偏移'子块信息
    var offsetCode = '';
    var offsetError = null;
    if (block.offsetCount_) {
        var value_xOffset = Blockly.GCode.valueToCode(block, 'OFFSET',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var value_yOffset = Blockly.GCode.valueToCode(block, 'YValue',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var value_zOffset = Blockly.GCode.valueToCode(block, 'ZValue',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var value_wOffset = Blockly.GCode.valueToCode(block, 'WValue',
            Blockly.GCode.ORDER_ATOMIC) || '';

        if (value_xOffset) {
            if (isNaN(value_xOffset)) offsetCode += ' ' + value_xOffset;
            else offsetError = "偏移量请输入I J K，不能输入数字";
        }
        if (value_yOffset) {
            if (isNaN(value_yOffset)) offsetCode += ' ' + value_yOffset;
            else offsetError = "偏移量请输入I J K，不能输入数字";
        }
        if (value_zOffset) {
            if (isNaN(value_zOffset)) offsetCode += ' ' + value_zOffset;
            else offsetError = "偏移量请输入I J K，不能输入数字";
        }
        if (value_wOffset) {
            if (isNaN(value_wOffset)) offsetCode += ' ' + value_wOffset;
            else offsetError = "偏移量请输入I J K，不能输入数字";
        }
    }



    var offsetabcCode = '';
    var offsetabcError = null;
    if (block.offsetabcCount_) {
        var value_aOffset = Blockly.GCode.valueToCode(block, 'OFFSETABC',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var value_bOffset = Blockly.GCode.valueToCode(block, 'OFFSETB',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var value_cOffset = Blockly.GCode.valueToCode(block, 'OFFSETC',
            Blockly.GCode.ORDER_ATOMIC) || '';
        value_aOffset = value_aOffset.replace('(', '');
        value_aOffset = value_aOffset.replace(')', '');
        value_bOffset = value_bOffset.replace('(', '');
        value_bOffset = value_bOffset.replace(')', '');
        value_cOffset = value_cOffset.replace('(', '');
        value_cOffset = value_cOffset.replace(')', '');
        if (value_aOffset) {
            if (value_aOffset) offsetabcCode += ' l' + value_aOffset;
            else offsetabcError = "偏移量A不能为空";
        }
        if (value_bOffset) {
            if (value_bOffset) offsetabcCode += ' m' + value_bOffset;
            else offsetabcError = "偏移量B不能为空";
        }
        if (value_cOffset) {
            if (value_cOffset) offsetabcCode += ' n' + value_cOffset;
            else offsetabcError = "偏移量C不能为空";
        }

    }

    ////------------------------------------------------------ 解析'避障列表'子块信息
    var listCode = '';
    var listError = null;
    if (block.avoidCount_) {
        if (block.ioCount_ || block.offsetCount_) {
            listError = "避障列表不能和'io输出'等其他子块混用，请删除多余添加！";
        }
        else {
            var value_pointList = Blockly.GCode.valueToCode(block, 'AVOID',
                Blockly.GCode.ORDER_ATOMIC) || ' ';
            var s = value_pointList.replace('(', '').replace(')', '').split(',');
            for (var i = 0; i < s.length; i++) {
                listCode += s[i];
            }
        }
    }

    ////------------------------------------------------------ 打印报警信息
    if (!havoidError && !ioError && !listError && !offsetError) {
        block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
        block.setWarningText(null);
    }
    else {
        Blockly.GCode.workspaceToCodeError = true;
        var ErrorCode = "";
        if (havoidError) ErrorCode = ErrorCode + havoidError;
        if (ioError) ErrorCode = ErrorCode + ioError;
        if (listError) ErrorCode = ErrorCode + listError;
        if (offsetError) ErrorCode = ErrorCode + offsetError;
        if (offsetabcError) ErrorCode = ErrorCode + offsetabcError;
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        block.setWarningText(ErrorCode);
    }

    var position_mode_code = '';
    switch (Position_mode) {
        case 'absmode':
            position_mode_code = ' G90';
            break;
        default:
            position_mode_code = '';
            break;
    }

    var motion_mode_code = '';
    switch (motion_mode) {
        case 'DoorLine':
            motion_mode_code = 'G5';
            break;
        case 'MoveLine':
            motion_mode_code = 'G1';
            break;
        case 'DoorDynamic':
            motion_mode_code = 'G16';
            break;
        case 'DoorFree':
            motion_mode_code = 'G51';
            break;
    }

    var code = '';
    if (motion_mode_code == 'G1') {
        code += motion_mode_code + position_mode_code + value_pointValue + offsetCode
            + ' F' + value_maxspeed + ' f' + value_endspeed + '\n';
    }
    else {
        code += motion_mode_code + position_mode_code + value_pointValue + listCode + ioCode + offsetCode
            + ' H' + value_heightavoid + ' F' + value_maxspeed + ' f' + value_endspeed + offsetabcCode + '\n';
    }
    return code;
};

/** 独立关节定位 */
Blockly.GCode['motion_move_go'] = function (block) {
    var Position_mode = block.getFieldValue('absmode');
    if (Position_mode) Position_mode = ' G90';
    else Position_mode = '';

    var axisList = [];
    ////------------------------------------------------------ 解析'关节点动'子块信息
    var axisCode = '';
    var axisError = null;
    for (var i = 0; i < block.axisCount_; i++) {
        var value_axisIdx = Blockly.GCode.valueToCode(block, 'AXIS' + i, Blockly.GCode.ORDER_ATOMIC) || '0';
        axisList.push(value_axisIdx);
        var value_Distance = Blockly.GCode.valueToCode(block, 'Distance' + i, Blockly.GCode.ORDER_ATOMIC) || '0';
        var value_axisSpeed = Blockly.GCode.valueToCode(block, 'axisSpeed' + i, Blockly.GCode.ORDER_ATOMIC) || '0';

        value_axisIdx = value_axisIdx.replace('(', '');
        value_axisIdx = value_axisIdx.replace(')', '');
        value_axisIdx = parseInt(value_axisIdx);

        value_Distance = value_Distance.replace('(', '');
        value_Distance = value_Distance.replace(')', '');
        value_axisSpeed = value_axisSpeed.replace('(', '');
        value_axisSpeed = value_axisSpeed.replace(')', '');

        if (isNaN(value_axisIdx))//NaN 错误
        {
            axisError = "轴号参数错误！请填写整数" + "\n";
        }
        else {
            if (value_axisIdx < 0) {
                axisError = "关节点动参数错误！轴号和点动距离只能填写正整数" + "\n";
            }
            else {
                axisCode += ' U' + value_axisIdx + ' L' + value_Distance + ' F' + value_axisSpeed;
            }
        }
    }

    ////------------------------------------------------------ 解析'jog启动'子块信息
    var sJogCode = '';
    var sJogError = null;
    for (var i = 0; i < block.sJogCount_; i++) {
        var value_axisIdx = Blockly.GCode.valueToCode(block, 'sJOG' + i, Blockly.GCode.ORDER_ATOMIC) || '0';
        axisList.push(value_axisIdx);
        var value_jogSpeed = Blockly.GCode.valueToCode(block, 'jogSpeed' + i, Blockly.GCode.ORDER_ATOMIC) || '0';

        value_axisIdx = value_axisIdx.replace('(', '');
        value_axisIdx = value_axisIdx.replace(')', '');
        value_axisIdx = parseInt(value_axisIdx);

        value_jogSpeed = value_jogSpeed.replace('(', '');
        value_jogSpeed = value_jogSpeed.replace(')', '');

        if (isNaN(value_axisIdx))//NaN 错误
        {
            sJogError = "轴号参数错误！请填写正整数" + "\n";
        }
        else {
            if (value_axisIdx < 0) {
                sJogError = "JOG启动参数错误！轴号只能填写正整数" + "\n";
            }
            else {
                sJogCode += ' U' + value_axisIdx + ' F' + value_jogSpeed;
            }
        }
    }

    ////------------------------------------------------------ 解析'jog停止'子块信息
    var tJogCode = '';
    var tJogError = null;
    for (var i = 0; i < block.tJogCount_; i++) {
        var value_axisIdx = Blockly.GCode.valueToCode(block, 'tJOG' + i, Blockly.GCode.ORDER_ATOMIC) || '0';
        axisList.push(value_axisIdx);

        value_axisIdx = value_axisIdx.replace('(', '');
        value_axisIdx = value_axisIdx.replace(')', '');
        value_axisIdx = parseInt(value_axisIdx);

        if (isNaN(value_axisIdx))//NaN 错误
        {
            tJogError = "JOG停止参数错误！轴号只能填写正整数" + "\n";
        }
        else {
            if (value_axisIdx < 0) {
                tJogError = "JOG停止参数错误！轴号只能填写正整数" + "\n";
            }
            else {
                tJogCode += ' U' + value_axisIdx;
            }
        }
    }

    ////------------------------------------------------------ 解析'回零模式'子块信息
    var zeroMovCode = '';
    var zeroError = null;
    if (block.zeromode_flag_) {
        var value_axisIdx = Blockly.GCode.valueToCode(block, 'zeroAxis', Blockly.GCode.ORDER_ATOMIC) || '0';
        axisList.push(value_axisIdx);
        var value_zeroSpeed = Blockly.GCode.valueToCode(block, 'zeroSpd', Blockly.GCode.ORDER_ATOMIC) || '0';
        var value_zeroOffset = Blockly.GCode.valueToCode(block, 'zeroOfs', Blockly.GCode.ORDER_ATOMIC) || '0';
        var value_zeroMode = Blockly.GCode.valueToCode(block, 'ZEROMODE', Blockly.GCode.ORDER_ATOMIC) || '0';

        value_axisIdx = value_axisIdx.replace('(', '');
        value_axisIdx = value_axisIdx.replace(')', '');
        value_axisIdx = parseInt(value_axisIdx);

        value_zeroOffset = value_zeroOffset.replace('(', '');
        value_zeroOffset = value_zeroOffset.replace(')', '');

        value_zeroSpeed = value_zeroSpeed.replace('(', '');
        value_zeroSpeed = value_zeroSpeed.replace(')', '');

        value_zeroMode = value_zeroMode.replace('(', '');
        value_zeroMode = value_zeroMode.replace(')', '');

        if (isNaN(value_axisIdx))//NaN 错误
        {
            zeroError = "轴号参数错误！请填写正整数" + "\n";
        }
        else {
            if (value_axisIdx < 0) {
                zeroError = "回零轴号参数错误！轴号只能填写正整数" + "\n";
            }
            else {
                zeroMovCode += ' U' + value_axisIdx + ' L' + value_zeroOffset + ' F' + value_zeroSpeed + ' H' + value_zeroMode;
            }
        }
    }


    ////------------------------------------------------------ 轴号查重
    var repeatError = null;
    for (var i = 0; i < axisList.length; i++) {
        var temp = axisList[i];
        for (var j = i + 1; j < axisList.length; j++) {
            if (temp == axisList[j]) {
                repeatError = '关节轴号重复！请勿对同一个轴进行多个操作！' + '\n';
                break;
            }
        }
    }

    ////------------------------------------------------------ 打印报警信息
    if (!axisError && !sJogError && !tJogError && !zeroError && !repeatError) {
        block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
        block.setWarningText(null);
    }
    else {
        Blockly.GCode.workspaceToCodeError = true;
        var ErrorCode = "";
        if (axisError) ErrorCode = ErrorCode + axisError;
        if (sJogError) ErrorCode = ErrorCode + sJogError;
        if (tJogError) ErrorCode = ErrorCode + tJogError;
        if (zeroError) ErrorCode = ErrorCode + zeroError;
        if (repeatError) ErrorCode = ErrorCode + repeatError;
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        block.setWarningText(ErrorCode);
    }

    var code = 'G0' + Position_mode + zeroMovCode + axisCode + sJogCode + tJogCode + '\n';
    return code;
};


Blockly.GCode['motion_move_arc_go'] = function (block) {
    var Position_mode = block.getFieldValue('OP_G90');
    // var G90 = Blockly.GCode.valueToCode(block, 'G90', Blockly.GCode.ORDER_ATOMIC);

    var motion_mode = block.getFieldValue('MotionMode');
    var value_pointValue = '';
    var value_heightavoid = '0';//'25.0';
    var value_maxspeed = '1000';
    var value_endspeed = '0';

    ////------------------------------------------------------ 解析'条件'子块信息
    for (var i = 0; i < block.conditionCount_; i++) {
        var operator = block.getFieldValue('OP' + i);
        var element = Blockly.GCode.valueToCode(block, 'PARA' + i, Blockly.GCode.ORDER_ATOMIC);
        if (element) {
            switch (operator) {
                case "HeightAvoid":
                    value_heightavoid = element;
                    break;
                case "MaxSpeed":
                    value_maxspeed = element;
                    break;
                case "EndSpeed":
                    value_endspeed = element;
                    break;
            }
        }
    }


    value_maxspeed = value_maxspeed.replace('(', '');
    value_maxspeed = value_maxspeed.replace(')', '');
    value_endspeed = value_endspeed.replace('(', '');
    value_endspeed = value_endspeed.replace(')', '');
    value_heightavoid = value_heightavoid.replace('(', '');
    value_heightavoid = value_heightavoid.replace(')', '');
    value_heightavoid = parseFloat(value_heightavoid);//避障高度转换成浮点型

    var havoidError = null;
    if (isNaN(value_heightavoid))//NaN 错误
    {
        value_heightavoid = 25.0;
        havoidError = "请检查避障高度参数，只能输入整数！" + "\n";
    }

    ////------------------------------------------------------ 解析'IO'子块信息
    var ioCode = '';
    var ioError = null;
    for (var i = 0; i < block.ioCount_; i++) {
        var value_IoNum = Blockly.GCode.valueToCode(block, 'IO' + i,
            Blockly.GCode.ORDER_ATOMIC) || '0';
        var value_ratio = Blockly.GCode.valueToCode(block, 'DisRatio' + i,
            Blockly.GCode.ORDER_ATOMIC) || '0';

        if (isNaN(value_IoNum) || isNaN(value_ratio)) {
            ioError = "请检查IO号和位移比是否正确,只能填写正数" + "\n";
        }
        else if (value_ratio < 0 || value_ratio > 1) {
            ioError = "请检查位移比是否正确,只能填写0到1之间的数字" + "\n";
        }
        ioCode = ioCode + " Y" + value_IoNum + " r" + value_ratio;
    }

    ////------------------------------------------------------ 解析'偏移'子块信息
    var offsetCode = '';
    var offsetError = null;
    if (block.offsetCount_) {
        var value_xOffset = Blockly.GCode.valueToCode(block, 'OFFSET',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var value_yOffset = Blockly.GCode.valueToCode(block, 'YValue',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var value_zOffset = Blockly.GCode.valueToCode(block, 'ZValue',
            Blockly.GCode.ORDER_ATOMIC) || '';


        if (value_xOffset) {
            if (isNaN(value_xOffset)) offsetCode += ' ' + value_xOffset;
            else offsetError = "偏移量请输入I J K，不能输入数字";
        }
        if (value_yOffset) {
            if (isNaN(value_yOffset)) offsetCode += ' ' + value_yOffset;
            else offsetError = "偏移量请输入I J K，不能输入数字";
        }
        if (value_zOffset) {
            if (isNaN(value_zOffset)) offsetCode += ' ' + value_zOffset;
            else offsetError = "偏移量请输入I J K，不能输入数字";
        }
    }

    ////------------------------------------------------------ 解析'避障列表'子块信息
    var listCode = '';
    var listError = null;
    if (block.avoidCount_) {
        if (block.ioCount_ || block.offsetCount_) {
            listError = "避障列表不能和'io输出'等其他子块混用，请删除多余添加！";
        }
        else {
            var value_pointList = Blockly.GCode.valueToCode(block, 'AVOID',
                Blockly.GCode.ORDER_ATOMIC) || ' ';
            var s = value_pointList.replace('(', '').replace(')', '').split(',');
            for (var i = 0; i < s.length; i++) {
                listCode += s[i];
            }
        }
    }
    ////------------------------------------------------------ 解析'点位'子块信息
    var pa = -1;
    var pb = -1;
    for (var i = 0; i < block.paraCount_; i++) {
        var value_PA = Blockly.GCode.valueToCode(block, 'PA' + i,
            Blockly.GCode.ORDER_ATOMIC) || '-1';
        var value_PB = Blockly.GCode.valueToCode(block, 'PB' + i,
            Blockly.GCode.ORDER_ATOMIC) || '-1';
        pa = value_PA;
        pb = value_PB;
    }

    var papbCode = " P" + pa + " P" + pb + " ";
    ////------------------------------------------------------ 打印报警信息
    if (!havoidError && !ioError && !listError && !offsetError) {
        block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
        block.setWarningText(null);
    }
    else {
        Blockly.GCode.workspaceToCodeError = true;
        var ErrorCode = "";
        if (havoidError) ErrorCode = ErrorCode + havoidError;
        if (ioError) ErrorCode = ErrorCode + ioError;
        if (listError) ErrorCode = ErrorCode + listError;
        if (offsetError) ErrorCode = ErrorCode + offsetError;
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        block.setWarningText(ErrorCode);
    }

    // var position_mode_code = '';
    // switch(Position_mode){
    //     case 'absmode':
    //         position_mode_code = ' G90';
    //         break;
    //     default:
    //         position_mode_code = '';
    //         break;
    // }

    var motion_mode_code = '';
    switch (motion_mode) {
        case 'ArcMove':
            motion_mode_code = 'G2';
            break;
        case 'AnArcMove':
            motion_mode_code = 'G3';
            break;
    }

    var startIndex_value = Blockly.GCode.valueToCode(block, 'startIndex', Blockly.GCode.ORDER_ATOMIC) || '-1';
    var endIndex_value = Blockly.GCode.valueToCode(block, 'endIndex', Blockly.GCode.ORDER_ATOMIC) || '-1';

    var papbCode_st_en = " P" + startIndex_value + " P" + endIndex_value + " ";

    var code = '';
    code += motion_mode_code + papbCode_st_en + offsetCode
        + ' H' + value_heightavoid + ' F' + value_maxspeed + ' f' + value_endspeed + '\n';



    //    code += motion_mode_code   +papbCode+papbCode_st_en+ offsetCode
    //            + ' H' + value_heightavoid + ' F' + value_maxspeed + ' f' + value_endspeed + '\n';
    return code;
};

Blockly.GCode['bcar'] = function (block) {
    var code = "";
    var modol = "";
    // 先拿到 XML 节点
    var xml = block.mutationToDom();   // 返回 DocumentFragment
    var isDownUp = xml && xml.getAttribute('downup') === '1';
    var isForBack = xml && xml.getAttribute('forback') === '1';
    var isGoPose = xml && xml.getAttribute('gopose') === '1';
    var isStopPlan = xml && xml.getAttribute('stopplan') === '1';
    var isGetStatus = xml && xml.getAttribute('getstatus') === '1';
    var isClearStatus = xml && xml.getAttribute('clearbcarstatus') === '1';
    var isJog = xml && xml.getAttribute('jogstep') === '1';
    var isChangeMap = xml && xml.getAttribute('map') === '1';
    var isChangeLocalization = xml && xml.getAttribute('locatize') === '1';

    var forBackErr = "";
    // 如果是downup类型，解析'起卧'子块信息
    if (isDownUp) {
        var downupBlock = block.getFieldValue('DIR0');
        switch (downupBlock) {
            case "Bcar_DOWN":
                modol = "G810";
                break;
            case "Bcar_UP":
                modol = "G811";
                break;
        }
    }
    // 如果是forback类型，解析'进退'子块信息
    else if (isForBack) {
        var forBackCode = '';
        var DIS = Blockly.GCode.valueToCode(block, 'DIS',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var VMAX = Blockly.GCode.valueToCode(block, 'VMAX',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var ACC = Blockly.GCode.valueToCode(block, 'ACC',
            Blockly.GCode.ORDER_ATOMIC) || '';

        if (DIS) {
            DIS = DIS.replace('(', '').replace(')', '');
            forBackCode += ' f' + DIS;
        } else forBackErr += "请添加距离参数";
        if (VMAX) {
            VMAX = VMAX.replace('(', '').replace(')', '');
            forBackCode += ' F' + VMAX;
        } else forBackErr += "请添加速度参数";
        if (ACC) {
            ACC = ACC.replace('(', '').replace(')', '');
            forBackCode += ' H' + ACC;
        } else forBackErr += "请添加速度参数";
        if (DIS && VMAX && ACC) modol = "G812";
    }

    else if (isGoPose) {
        var goPoseCode = '';
        var DIS = Blockly.GCode.valueToCode(block, 'GOPOS_',
            Blockly.GCode.ORDER_ATOMIC) || '';


        if (DIS) {
            goPoseCode += ' P' + DIS;
        } else forBackErr += "请添加距离参数";

        if (DIS) modol = "G815";
    }
    else if (isStopPlan) {
        modol = "G813";
    }
    else if (isGetStatus) {
        modol = "G814";
    } else if (isJog) {
        var JogCode = '';
        var IDX = Blockly.GCode.valueToCode(block, 'IDX_JOG',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var DIS = Blockly.GCode.valueToCode(block, 'DIS_JOG',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var V = Blockly.GCode.valueToCode(block, 'V_JOG',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var ABS = block.getFieldValue('ABS_');
        switch (ABS) {
            case "UN_ABS":
                modol = "G810";
                break;
            case "ABS_":
                modol = "G811";
                break;
        }
        if (IDX) {
            IDX = IDX.replace('(', '').replace(')', '');
            JogCode += ' H' + IDX;
        } else forBackErr += "请添加距离参数";
        if (DIS) {
            DIS = DIS.replace('(', '').replace(')', '');
            JogCode += ' f' + DIS;
        } else forBackErr += "请添加速度参数";
        if (V) {
            V = V.replace('(', '').replace(')', '');
            JogCode += ' F' + V;
        } else forBackErr += "请添加速度参数";
        if (IDX && DIS && V && ABS) {
            switch (ABS) {
                case "UN_ABS":
                    modol = "G816";
                    break;
                case "ABS_":
                    modol = "G817";
                    break;
            }
        }
    }
    else if (isChangeMap) {
        var ChMapCode = '';
        var MAP_IDX = Blockly.GCode.valueToCode(block, 'MAP_CH_IDX',
            Blockly.GCode.ORDER_ATOMIC) || '';
        if (MAP_IDX) {
            ChMapCode += ' P' + MAP_IDX;
        } else forBackErr += "请添加地图编号";

        if (MAP_IDX) modol = "G818";
    }
    else if (isChangeLocalization) {
        var ChLoCode = '';
        var MAP_IDX = Blockly.GCode.valueToCode(block, 'MAP_LO_IDX',
            Blockly.GCode.ORDER_ATOMIC) || '';
        var LO_IDX = Blockly.GCode.valueToCode(block, 'LO_IDX',
            Blockly.GCode.ORDER_ATOMIC) || '';


        if (MAP_IDX) {
            MAP_IDX = MAP_IDX.replace('(', '').replace(')', '');
            ChLoCode += ' P' + MAP_IDX;
        } else forBackErr += "请添加地图编号";
        if (LO_IDX) {
            LO_IDX = LO_IDX.replace('(', '').replace(')', '');
            ChLoCode += ' F' + LO_IDX;
        } else forBackErr += "请添加定位编号";
        if (MAP_IDX && LO_IDX) modol = "G819";
    }
    else if(isClearStatus){
        modol = "G820";
    }


    ////------------------------------------------------------ 打印报警信息
    if (!forBackErr) {
        block.setColour(Blockly.CustomConfig.BLOCK_MOTION_RGB);
        block.setWarningText(null);
    }
    else {
        Blockly.GCode.workspaceToCodeError = true;
        var ErrorCode = "";
        if (forBackErr) ErrorCode = forBackErr;
        block.setColour(Blockly.CustomConfig.BLOCK_ERROR_RGB);
        block.setWarningText(ErrorCode);
    }
    code = modol + (isForBack ? forBackCode : "") + (isGoPose ? goPoseCode : "") + (isJog ? JogCode : "")+ (isChangeLocalization ? ChLoCode : "") + (isChangeMap ? ChMapCode : "") + ' \n';
    return code;
};



Blockly.GCode['robot'] = function (block) {
    //------------------------------------------------------ 解析'手臂+规划'子块信息
    var motion_mode = block.getFieldValue('MotionMode');
    var motion_mode_val = 0;
    var motion_Group_val = 0;
    switch (motion_mode) {
        case 'FixPlan':
            motion_mode_val = 3;
            break;
        case 'MoveLine':
            motion_mode_val = 2;
            break;
        case 'DoorDynamic':
            motion_mode_val = 1;
            break;
        case 'DoorFree':
            motion_mode_val = 0;
            break;
    }
    var motion_mode = block.getFieldValue('MotionGroup');
    switch (motion_mode) {
        case 'LeftArm':
            motion_Group_val = 710;
            break;
        case 'RightArm':
            motion_Group_val = 720;
            break;
        case 'DoubleArm':
            motion_Group_val = 700;
            break;
    }

    ////------------------------------------------------------ 解析'条件'子块信息
    var value_pointValue;
    var value_heightavoid;
    var value_maxspeed;
    var value_endspeed;

    for (var i = 0; i < block.paraCount_; i++) {
        var operator = block.getFieldValue('OP' + i);
        var element = Blockly.GCode.valueToCode(block, 'PARA' + i, Blockly.GCode.ORDER_ATOMIC);
        if (element) {
            switch (operator) {
                case "AvoidPoint":
                    value_pointValue = element;
                    break;
                case "HeightAvoid":
                    value_heightavoid = element;
                    break;
                case "MaxSpeed":
                    value_maxspeed = element;
                    break;
                case "EndSpeed":
                    value_endspeed = element;
                    break;
            }
        }
    }

    ////------------------------------------------------------ 解析'偏移'子块信息
    var value_LXOffset = Blockly.GCode.valueToCode(block, 'LXValue',
        Blockly.GCode.ORDER_ATOMIC) || '';
    var value_LYOffset = Blockly.GCode.valueToCode(block, 'LYValue',
        Blockly.GCode.ORDER_ATOMIC) || '';
    var value_LZOffset = Blockly.GCode.valueToCode(block, 'LZValue',
        Blockly.GCode.ORDER_ATOMIC) || '';
    var value_LAOffset = Blockly.GCode.valueToCode(block, 'LAValue',
        Blockly.GCode.ORDER_ATOMIC) || '';
    var value_LBOffset = Blockly.GCode.valueToCode(block, 'LBValue',
        Blockly.GCode.ORDER_ATOMIC) || '';
    var value_LCOffset = Blockly.GCode.valueToCode(block, 'LCValue',
        Blockly.GCode.ORDER_ATOMIC) || '';

    var value_RXOffset = Blockly.GCode.valueToCode(block, 'RXValue',
        Blockly.GCode.ORDER_ATOMIC) || '';
    var value_RYOffset = Blockly.GCode.valueToCode(block, 'RYValue',
        Blockly.GCode.ORDER_ATOMIC) || '';
    var value_RZOffset = Blockly.GCode.valueToCode(block, 'RZValue',
        Blockly.GCode.ORDER_ATOMIC) || '';
    var value_RAOffset = Blockly.GCode.valueToCode(block, 'RAValue',
        Blockly.GCode.ORDER_ATOMIC) || '';
    var value_RBOffset = Blockly.GCode.valueToCode(block, 'RBValue',
        Blockly.GCode.ORDER_ATOMIC) || '';
    var value_RCOffset = Blockly.GCode.valueToCode(block, 'RCValue',
        Blockly.GCode.ORDER_ATOMIC) || '';
    //----------------------------------------------------- 解析'绝对路径'子块信息
    var xml = block.mutationToDom();   // 返回 DocumentFragment
    var isObLeft = xml && xml.getAttribute('obleft') === '1';
    var isObRight = xml && xml.getAttribute('obright') === '1';
    ////------------------------------------------------------ 打印报警信息

    var motion_mode_code = motion_mode_val + motion_Group_val;
    var code = 'G' + motion_mode_code +
        (value_pointValue ? " P" + value_pointValue : "") + (value_heightavoid ? " H" + value_heightavoid : "") + (value_maxspeed ? " F" + value_maxspeed : "") + (value_endspeed ? " f" + value_maxspeed : "") +
        (value_LXOffset ? " i" + value_LXOffset : "") + (value_LYOffset ? " j" + value_LYOffset : "") + (value_LZOffset ? " k" + value_LZOffset : "") +
        (value_LAOffset ? " a" + value_LAOffset : "") + (value_LBOffset ? " b" + value_LBOffset : "") + (value_LCOffset ? " c" + value_LCOffset : "") +
        (value_RXOffset ? " x" + value_RXOffset : "") + (value_RYOffset ? " y" + value_RYOffset : "") + (value_RZOffset ? " z" + value_RZOffset : "") +
        (value_RAOffset ? " u" + value_RAOffset : "") + (value_RBOffset ? " v" + value_RBOffset : "") + (value_RCOffset ? " w" + value_RCOffset : "") +
        (isObLeft ? " p90" : "") + (isObRight ? " q90" : "") + ' \n';

    return code;
};

Blockly.GCode['motion_ele_mode'] = function (block) {


    var idxSelect_value = Blockly.GCode.valueToCode(block, 'idxSelect', Blockly.GCode.ORDER_ATOMIC) || '-1';
    var idxFollow_value = Blockly.GCode.valueToCode(block, 'idxFollow', Blockly.GCode.ORDER_ATOMIC) || '-1';
    var molecule_value = Blockly.GCode.valueToCode(block, 'molecule', Blockly.GCode.ORDER_ASSIGNMENT) || '1';
    var denominator_value = Blockly.GCode.valueToCode(block, 'denominator', Blockly.GCode.ORDER_ASSIGNMENT) || '1';


    var code;
    code = 'G800 U' + idxSelect_value + ' L' + idxFollow_value + ' f' + molecule_value + ' F' + denominator_value + ' \n';

    return code;
};

Blockly.GCode['batch'] = function (block) {

    var batch_name = block.getFieldValue('batch_name');
    var batch_name_code = batch_name;
    switch (batch_name) {
        case 'batch_D':
            batch_name_code = 'D';
            break;
        case 'batch_M':
            batch_name_code = 'M';
            break;
        case 'batch_S':
            batch_name_code = 'S';
            break;
    }
    var batch_index = Blockly.GCode.valueToCode(block, 'batch_index', Blockly.GCode.ORDER_ATOMIC) || '-1';
    var batch_num = Blockly.GCode.valueToCode(block, 'batch_num', Blockly.GCode.ORDER_ATOMIC) || '-1';
    var batch_value = Blockly.GCode.valueToCode(block, 'batch_value', Blockly.GCode.ORDER_ASSIGNMENT) || '1';



    var code;
    code = 'G60 '+batch_name_code + batch_index + ' F' + batch_num + ' f' + batch_value + ' \n';

    return code;
};