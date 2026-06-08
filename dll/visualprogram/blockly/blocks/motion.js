/**
* Blockly Demos: Block Factory Blocks
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
 * @fileoverview Blocks for Blockly's Block Factory application.
 * @author fraser@google.com (Neil Fraser)
 */

'use strict';

goog.provide('Blockly.Blocks.motion');
goog.provide('Blockly.Constants.Motion');
goog.require('Blockly.Blocks');


/**
 * 重新定义block颜色
 * BKY_BLOCK_MOTION_RGB "%{BKY_BLOCK_MATH_RGB}"
 * Msg �?添加 BKY_BLOCK_MOTION_RGB
 */

/** 整数 */
Blockly.Blocks['math_number_int'] = {
    init: function () {
        this.appendDummyInput()
            .appendField(new Blockly.FieldNumber(0, -Infinity, Infinity, 1), "NUM");//最小�? Infinity
        this.setInputsInline(true);
        this.setOutput(true, "Number");
        this.setColour("%{BKY_BLOCK_MOTION_RGB}");
        this.setTooltip("");
        this.setHelpUrl("");
    }
};

/** 非负整数 */
Blockly.Blocks['math_number_uint'] = {
    init: function () {
        this.appendDummyInput()
            .appendField(new Blockly.FieldNumber(0, 0, Infinity, 1), "NUM");//最小�? Infinity
        this.setInputsInline(true);
        this.setOutput(true, "Number");
        this.setColour("%{BKY_BLOCK_MOTION_RGB}");
        this.setTooltip("");
        this.setHelpUrl("");
    }
};

Blockly.defineBlocksWithJsonArray([  // BEGIN JSON EXTRACT
    /** -----------------------------------------------------------Block for Mutator*/
    //Mutator '容器'�?
    {
        "type": "motion_door_op_create_container",
        "message0": "%{BKY_MOTION_CREATE_TITLE_JOIN} %1 %2",
        "args0": [{
            "type": "input_dummy"
        },
        {
            "type": "input_statement",
            "name": "STACK"
        }],
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "%{BKY_LOGIC_OPERATION_HELPURL}",
        "enableContextMenu": false
    },
    //Mutator '条件'�?
    {
        "type": "motion_door_op_item",
        "message0": "%{BKY_MOTION_CREATE_ITEM_TITLE_ITEM_COND}",

        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    //Mutator 'IO输出'�?
    {
        "type": "motion_io_op_item",
        "message0": "%{BKY_MOTION_CREATE_ITEM_IO_ITEM_COND}",
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    //Mutator offset mini
    {
        "type": "motion_offset_abc",
        "message0": "%{BKY_ROBOT_MUTATOR_OFFABC}",
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    {
        "type": "motion_offset_op_item",
        "message0": "%{BKY_MOTION_CREATE_ITEM_OFFSET_ITEM_COND}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    //Mutator '避障列表'�?
    {
        "type": "motion_avoid_op_item",
        "message0": "%{BKY_MOTION_MOVEL_AVOID_LIST}",
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    //Mutator '绝�?�模�?'�?
    {
        "type": "motion_absmode_op_item",
        "message0": "%{BKY_MOTION_MODEL_ABSOLUTE}",
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    //Mutator '回零模式'�?
    {
        "type": "motion_zeromode_op_item",
        "message0": "%{BKY_MOTION_MODE_RETURN_ZERO}",
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    //Mutator '阵列'�?
    {
        "type": "motion_array_op_item",
        "message0": "%{BKY_MOTION_CREATE_ITEM_ARRAY_ITEM_COND}",
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    //Mutator '关节点动'�?
    {
        "type": "motion_axismove_item",
        "message0": "%{BKY_MOTION_JOINT_MOVEMENT}",
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    //Mutator 'jog�?�?'�?
    {
        "type": "motion_jog_start_item",
        "message0": "%{BKY_MOTION_JOG_BEGIN}",
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    //Mutator 'jog停�??'�?
    {
        "type": "motion_jog_stop_item",
        "message0": "%{BKY_MOTION_JOG_STOP}",
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },

    {
        "type": "motion_MoveCircle_op_create_container",
        "message0": "%{BKY_MOTION_CREATE_TITLE_JOIN} %1 %2",
        "args0": [{
            "type": "input_dummy"
        },
        {
            "type": "input_statement",
            "name": "STACK"
        }],
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "%{BKY_LOGIC_OPERATION_HELPURL}",
        "enableContextMenu": false
    },
    {
        "type": "motion_MoveCircle_op_item",
        "message0": "%{BKY_MOTION_CREATE_ITEM_TITLE_ITEM_COND}",

        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "{%BKY_LOGIC_OPERATION_HELPURL}",
        "enableContextMenu": false
    },

    /** -----------------------------------------------------------Block is used*/
    {
        "type": "motion_moveptp_point",
        "message0": "%1",
        "args0": [
            {
                "type": "field_dropdown",
                "name": "MotionMode",
                "options": [
                    ["%{BKY_MOTION_MOVE_G51}", "DoorFree"],
                    ["%{BKY_MOTION_MOVE_G5}", "DoorLine"],
                    ["%{BKY_MOTION_MOVE_G16}", "DoorDynamic"],
                    ["%{BKY_MOTION_MOVE_G1}", "MoveLine"]
                ]
            }
        ],
        "inputsInline": true,
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_MOTION_RGB}",
        "tooltip": "",
        "mutator": "motion_door_mutator"
    },
    {
        "type": "motion_move_go",
        "message0": "%{BKY_MOTION_MOVE_G0}",
        "inputsInline": true,
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_MOTION_RGB}",
        "tooltip": "",
        "mutator": "motion_movego_mutator"
    },


    /*
    *添加
    */

    //Mutator 点位�?
    {
        "type": "motion_arc_pos_item",
        "message0": "%{BKY_MOTION_CREATE_ITEM_TITLE_ITEM_POS}",

        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    {
        "type": "motion_move_arc_go",
        "message0": "%1 %{BKY_MOTION_MOVE_ARC_END_POINT}%2 %{BKY_MOTION_MOVE_ARC_MID_POINT}%3",
        "args0": [
            {
                "type": "field_dropdown",
                "name": "MotionMode",
                "options": [
                    ["%{BKY_MOTION_MOVE_ARC_CLOCKWISE_G2}", "ArcMove"],
                    ["%{BKY_MOTION_MOVE_ARC_ANTICCLOCKWISE_G3}", "AnArcMove"]
                ]
            },
            {
                "type": "input_value",
                "name": "startIndex",
                "check": "Number"
            },
            {
                "type": "input_value",
                "name": "endIndex",
                "check": "Number"
            },

        ],
        "inputsInline": true,
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_MOTION_RGB}",
        "tooltip": "",
        "mutator": "motion_move_arc_go_mutator"
    },

    //------------------------------bcar----------------------------------------motion_offset_op_item
    {
        "type": "bcar_offset_downup",
        "message0": "%{BKY_BCAR_MUTATOR_DP}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    {
        "type": "bcar_offset_changemap",
        "message0": "%{BKY_BCAR_MUTATOR_MAP}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    {
        "type": "bcar_offset_changelocalization",
        "message0": "%{BKY_BCAR_MUTATOR_LOCALIZE}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    {
        "type": "bcar_offset_forbackward",
        "message0": "%{BKY_BCAR_MUTATOR_STEP}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    {
        "type": "bcar_offset_pose",
        "message0": "%{BKY_BCAR_MUTATOR_POSE}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    {
        "type": "bcar_offset_jog",
        "message0": "%{BKY_BCAR_MUTATOR_JOG}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    {
        "type": "bcar_offset_get_status",
        "message0": "%{BKY_BCAR_MUTATOR_GET_STATUS}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    {
        "type": "bcar_offset_clear_status",
        "message0": "%{BKY_BCAR_MUTATOR_CLEAR_STATUS}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },
    {
        "type": "bcar_offset_stopplan",
        "message0": "%{BKY_BCAR_MUTATOR_STOP_PLAN}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "enableContextMenu": false
    },

    {
        "type": "bcar",
        "message0": " %{BKY_BCAR}",
        "inputsInline": true,
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_MOTION_RGB}",
        "tooltip": "",
        "mutator": "bcar_mutator"

    },
    {
        "type": "bcar_move_jog_step",
        "message0": " %{BKY_BCAR}%1 %{BKY_BCAR_DIS}%2 %{BKY_BCAR_VMAX}%3 %{BKY_BCAR_ACC}%4 ",
        "args0": [
            {
                "type": "field_dropdown",
                "name": "Bcar_forBackWard",
                "options": [
                    ["%{BKY_BCAR_FORWARD}", "BcarForWard"],
                    ["%{BKY_BCAR_BACKWARD}", "BcarBackWard"]
                ]
            },
            {
                "type": "input_value",
                "name": "Bcar_Dis",
                "check": "Number"
            },
            {
                "type": "input_value",
                "name": "Bcar_Vmax",
                "check": "Number"
            },
            {
                "type": "input_value",
                "name": "Bcar_Acc",
                "check": "Number"
            },
        ],
        "inputsInline": true,
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_MOTION_RGB}",
        "tooltip": "",
    },

    //------------------------------bcar----------------------------------------
    //------------------------------robot----------------------------------------
    {
        "type": "robot",
        "message0": " %{BKY_ROBOT} %1 %2",
        "args0": [
            {
                "type": "field_dropdown",
                "name": "MotionMode",
                "options": [
                    ["%{BKY_MOTION_MOVE_G51}", "DoorFree"],
                    ["%{BKY_ROBOT_FIX_PLAN}", "FixPlan"],
                    ["%{BKY_MOTION_MOVE_G16}", "DoorDynamic"],
                    ["%{BKY_MOTION_MOVE_G1}", "MoveLine"]
                ]
            },
            {
                "type": "field_dropdown",
                "name": "MotionGroup",
                "options": [
                    ["%{BKY_ROBOT_MUTATOR_LEFTARM}", "LeftArm"],
                    ["%{BKY_ROBOT_MUTATOR_RIGHTARM}", "RightArm"],
                    ["%{BKY_ROBOT_MUTATOR_RIGHTLEFT}", "DoubleArm"],
                ]
            },
        ],
        "inputsInline": true,
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_MOTION_RGB}",
        "tooltip": "",
        "mutator": "robot_mutator"
    },
    {
        "type": "robot_mutator_PlanType",
        "message0": "%{BKY_ROBOT_MUTATOR_PLANTYPE}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "nextStatement": null,
        "enableContextMenu": false

    },
    {
        "type": "robot_mutator_PlanGroup",
        "message0": "%{BKY_ROBOT_MUTATOR_PLANGROUP}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "nextStatement": null,
        "enableContextMenu": false

    },
    {
        "type": "robot_mutator_LeftOff",
        "message0": "%{BKY_ROBOT_MUTATOR_LEFTOFF}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "nextStatement": null,
        "enableContextMenu": false

    },
    {
        "type": "robot_mutator_RightOff",
        "message0": "%{BKY_ROBOT_MUTATOR_RIGHTOFF}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "nextStatement": null,
        "enableContextMenu": false

    },
    {
        "type": "robot_mutator_LeftOb",
        "message0": "%{BKY_MOTION_ROBOT_OB_L}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "nextStatement": null,
        "enableContextMenu": false

    },
    {
        "type": "robot_mutator_RightOb",
        "message0": "%{BKY_MOTION_ROBOT_OB_R}",
        "previousStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "",
        "nextStatement": null,
        "enableContextMenu": false

    },
    //------------------------------robot----------------------------------------

    //------------------------------batch 批量赋值----------------------------------------
     {
        "type": "batch",
        // "message0": "%{BKY_MOTION_TCP_COMM}",

        "message0": "%{BKY_BATCH_ASSIGNMENT} %1 %2 %{BKY_BATCH_NUM}%3 %{BKY_BATCH_VALUE}%4",
        "args0": [
             {
                "type": "field_dropdown",
                "name": "batch_name",
                "options": [
                    ["D", "batch_D"],
                    ["M", "batch_M"],
                    ["S", "batch_S"],
                ]
            },
            {
                "type": "input_value",
                "name": "batch_index",
                "check": "Number"
            },
            {
                "type": "input_value",
                "name": "batch_num",
                "check": "Number"
            },
            {
                "type": "input_value",
                "name": "batch_value",
                "check": "Number"
            },
        ],
        "inputsInline": true,
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_MOTION_RGB}",

    },

    //------------------------------batch 批量赋值----------------------------------------

    //7.12添加电子齿轮
    {
        "type": "motion_ele_mode",
        // "message0": "%{BKY_MOTION_TCP_COMM}",
        "message0": "%{BKY_MOTION_MOVE_ELE_GEAR} %{BKY_MOTION_MOVE_ELE_GEAR_FOLLOWER}%1 %{BKY_MOTION_MOVE_ELE_GEAR_DRIVING}%2 %{BKY_MOTION_MOVE_ELE_GEAR_NUMERATOR}%3 %{BKY_MOTION_MOVE_ELE_GEAR_DENOMINATOR}%4",
        "args0": [
            {
                "type": "input_value",
                "name": "idxSelect",
                "check": "Number"
            },
            {
                "type": "input_value",
                "name": "idxFollow",
                "check": "Number"
            },
            {
                "type": "input_value",
                "name": "molecule",
                "check": "Number"
            },
            {
                "type": "input_value",
                "name": "denominator",
                "check": "Number"
            },
        ],
        "inputsInline": true,
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_MOTION_RGB}",

    },
]);  // END JSON EXTRACT (Do not delete this comment.)


Blockly.Constants.Motion.MOTION_BCAR_MUTATOR_MIXIN = {
    forbackCount_: 0,
    downupCount_: 0,
    gotopose_: 0,
    stopplan_: 0,
    getbcarstatus_: 0,
    jogstep_: 0,
    map_: 0,
    locatize_: 0,
    clearbcarstatus_: 0,

    /** Create XML to represent the number of io and offset inputs.**/
    mutationToDom: function () {
        var container = document.createElement('mutation');
        if (this.forbackCount_) {
            container.setAttribute('forback', 1);
        }
        if (this.downupCount_) {
            container.setAttribute('downup', 1);
        }
        if (this.gotopose_) {
            container.setAttribute('gopose', 1);
        }
        if (this.stopplan_) {
            container.setAttribute('stopplan', 1);
        }
        if (this.getbcarstatus_) {
            container.setAttribute('getstatus', 1);
        }
        if (this.jogstep_) {
            container.setAttribute('jogstep', 1);
        }
        if (this.map_) {
            container.setAttribute('map', 1);
        }
        if (this.locatize_) {
            container.setAttribute('locatize', 1);
        }
        if (this.clearbcarstatus_) {
            container.setAttribute('clearbcarstatus', 1);
        }
        return container;
    },

    /** Parse XML to restore the io and offset inputs.**/
    domToMutation: function (xmlElement) {
        this.forbackCount_ = parseInt(xmlElement.getAttribute('forback'), 10) || 0;
        this.downupCount_ = parseInt(xmlElement.getAttribute('downup'), 10) || 0;
        this.gotopose_ = parseInt(xmlElement.getAttribute('gopose'), 10) || 0;
        this.stopplan_ = parseInt(xmlElement.getAttribute('stopplan'), 10) || 0;
        this.getbcarstatus_ = parseInt(xmlElement.getAttribute('getstatus'), 10) || 0;
        this.jogstep_ = parseInt(xmlElement.getAttribute('jogstep'), 10) || 0;
        this.map_ = parseInt(xmlElement.getAttribute('map'), 10) || 0;
        this.locatize_ = parseInt(xmlElement.getAttribute('locatize'), 10) || 0;
        this.clearbcarstatus_ = parseInt(xmlElement.getAttribute('clearbcarstatus'), 10) || 0;
        this.updateShape_();
    },

    /**Populate the mutator's dialog with this block's components.**/
    decompose: function (workspace) {
        var containerBlock = workspace.newBlock('motion_door_op_create_container');
        containerBlock.initSvg();
        var connection = containerBlock.getInput('STACK').connection;
        for (var i = 0; i < this.downupCount_; i++) {
            var downupBlock = workspace.newBlock('bcar_offset_downup');
            downupBlock.initSvg();
            connection.connect(downupBlock.previousConnection);
            connection = downupBlock.nextConnection;
        }
        if (this.forbackCount_) {
            var forbackBlock = workspace.newBlock('bcar_offset_forbackward');
            forbackBlock.initSvg();
            connection.connect(forbackBlock.previousConnection);
        }
        if (this.gotopose_) {
            var forbackBlock = workspace.newBlock('bcar_offset_pose');
            forbackBlock.initSvg();
            connection.connect(forbackBlock.previousConnection);
        }
        if (this.stopplan_) {
            var forbackBlock = workspace.newBlock('bcar_offset_stopplan');
            forbackBlock.initSvg();
            connection.connect(forbackBlock.previousConnection);
        }
        if (this.getbcarstatus_) {
            var forbackBlock = workspace.newBlock('bcar_offset_get_status');
            forbackBlock.initSvg();
            connection.connect(forbackBlock.previousConnection);
        }
        if (this.jogstep_) {
            var forbackBlock = workspace.newBlock('bcar_offset_jog');
            forbackBlock.initSvg();
            connection.connect(forbackBlock.previousConnection);
        }
        if (this.map_) {
            var forbackBlock = workspace.newBlock('bcar_offset_changemap');
            forbackBlock.initSvg();
            connection.connect(forbackBlock.previousConnection);
        }
        if (this.locatize_) {
            var forbackBlock = workspace.newBlock('bcar_offset_changelocalization');
            forbackBlock.initSvg();
            connection.connect(forbackBlock.previousConnection);
        }
        if (this.clearbcarstatus_) {
            var forbackBlock = workspace.newBlock('bcar_offset_clear_status');
            forbackBlock.initSvg();
            connection.connect(forbackBlock.previousConnection);
        }
        return containerBlock;
    },

    /** Reconfigure this block based on the mutator dialog's components.**/
    compose: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        this.forbackCount_ = 0;
        this.downupCount_ = 0;
        this.gotopose_ = 0;
        this.stopplan_ = 0;
        this.getbcarstatus_ = 0;
        this.jogstep_ = 0;
        this.map_ = 0;
        this.locatize_ = 0;
        this.clearbcarstatus_ = 0;
        var downupConnections = [null];
        var forbackConnection = null;
        var gotoposeConnection = null;
        var stopplanConnection = null;
        var getbcarstatusConnection = null;
        var jogstepConnection = null;
        var mapConnection = null;
        var localizeConnection = null;
        var clearbcarstatusConnection = null;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'bcar_offset_downup':
                    this.downupCount_++;
                    downupConnections.push(itemBlock.valueConnection_);
                    break;
                case 'bcar_offset_forbackward':
                    this.forbackCount_ = 1;
                    forbackConnection = itemBlock.valueConnection_;
                    break;
                case 'bcar_offset_pose':
                    this.gotopose_ = 1;
                    gotoposeConnection = itemBlock.valueConnection_;
                    break;
                case 'bcar_offset_stopplan':
                    this.stopplan_ = 1;
                    stopplanConnection = itemBlock.valueConnection_;
                    break;
                case 'bcar_offset_get_status':
                    this.getbcarstatus_ = 1;
                    getbcarstatusConnection = itemBlock.valueConnection_;
                    break;
                case 'bcar_offset_jog':
                    this.jogstep_ = 1;
                    jogstepConnection = itemBlock.valueConnection_;
                    break;
                case 'bcar_offset_changemap':
                    this.map_ = 1;
                    mapConnection = itemBlock.valueConnection_;
                    break;
                case 'bcar_offset_changelocalization':
                    this.locatize_ = 1;
                    localizeConnection = itemBlock.valueConnection_;
                    break;
                case 'bcar_offset_clear_status':
                    this.clearbcarstatus_ = 1;
                    clearbcarstatusConnection = itemBlock.valueConnection_;
                    break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
        this.updateShape_();
        // Reconnect any child blocks.
        for (var i = 0; i < this.downupCount_; i++) {
            Blockly.Mutator.reconnect(downupConnections[i], this, 'DOWNUP' + i);
        }
        Blockly.Mutator.reconnect(forbackConnection, this, 'OFFSET');
        Blockly.Mutator.reconnect(gotoposeConnection, this, 'GOPOSE');
        Blockly.Mutator.reconnect(stopplanConnection, this, 'STOPPLAN');
        Blockly.Mutator.reconnect(getbcarstatusConnection, this, 'GETSTATUS');
        Blockly.Mutator.reconnect(jogstepConnection, this, 'JOGSTEP');
        Blockly.Mutator.reconnect(mapConnection, this, 'MAP');
        Blockly.Mutator.reconnect(localizeConnection, this, 'LOCATIZE');
        Blockly.Mutator.reconnect(localizeConnection, this, 'CLEARSTATUS');

    },

    /** Store pointers to any connected child blocks.**/
    saveConnections: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        var i = 0;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'bcar_offset_downup':
                    var input = this.getInput('DOWNUP' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                case 'bcar_offset_forbackward':
                    var inputOffset = this.getInput('OFFSET');
                    itemBlock.valueConnection_ = inputOffset && inputOffset.connection.targetConnection;
                    break;
                case 'bcar_offset_pose':
                    var inputGoPose = this.getInput('GOPOSE');
                    itemBlock.valueConnection_ = inputGoPose && inputGoPose.connection.targetConnection;
                    break;
                case 'bcar_offset_stopplan':
                    var inputStopPlan = this.getInput('STOPPLAN');
                    itemBlock.valueConnection_ = inputStopPlan && inputStopPlan.connection.targetConnection;
                    break;
                case 'bcar_offset_get_status':
                    var inputGetStatus = this.getInput('GETSTATUS');
                    itemBlock.valueConnection_ = inputGetStatus && inputGetStatus.connection.targetConnection;
                    break;
                case 'bcar_offset_jog':
                    var inputGetStatus = this.getInput('JOGSTEP');
                    itemBlock.valueConnection_ = inputGetStatus && inputGetStatus.connection.targetConnection;
                    break;
                case 'bcar_offset_changemap':
                    var inputGetStatus = this.getInput('MAP');
                    itemBlock.valueConnection_ = inputGetStatus && inputGetStatus.connection.targetConnection;
                    break;
                case 'bcar_offset_changelocalization':
                    var inputGetStatus = this.getInput('LOCATIZE');
                    itemBlock.valueConnection_ = inputGetStatus && inputGetStatus.connection.targetConnection;
                    break;
                case 'bcar_offset_clear_status':
                    var inputGetStatus = this.getInput('CLEARSTATUS');
                    itemBlock.valueConnection_ = inputGetStatus && inputGetStatus.connection.targetConnection;
                    break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
    },

    /** Modify this block to have the correct number of inputs.**/
    updateShape_: function () {
        // update 条件 Block
        // ����/ɾ����������Ķ�̬����
        for (var i = 0; i < this.downupCount_; i++) {
            if (!this.getInput('DIRECTION' + i)) {
                this.appendDummyInput('DIRECTION' + i)
                    .appendField(new Blockly.FieldDropdown([
                        [Blockly.Msg.MOTION_BCAR_DOWN, 'Bcar_DOWN'],
                        [Blockly.Msg.MOTION_BCAR_UP, 'Bcar_UP']
                    ]), 'DIR' + i);
            }
        }
        // �����ɾ��
        var j = this.downupCount_;
        while (this.getInput('DIRECTION' + j)) {
            this.removeInput('DIRECTION' + j);
            j++;
        }
        // update Offset Block
        if (this.forbackCount_ && !this.getInput('DIS')) {
            this.appendValueInput('DIS')
                .setCheck('Number')
                .appendField(Blockly.Msg.BCAR_DIS);

            this.appendValueInput('VMAX')
                .setCheck('Number')
                .appendField(Blockly.Msg.BCAR_VMAX);
            this.appendValueInput('ACC')
                .setCheck('Number')
                .appendField(Blockly.Msg.BCAR_ACC);
        }
        if (!this.forbackCount_ && this.getInput('DIS')) {
            this.removeInput('DIS');
            this.removeInput('VMAX');
            this.removeInput('ACC');
        }

        // update gotopose_ Block
        if (this.gotopose_ && !this.getInput('GOPOS_')) {
            this.appendValueInput('GOPOS_')
                .setCheck('Number')
                .appendField(Blockly.Msg.BCAR_POS_IDX);
        }
        if (!this.gotopose_ && this.getInput('GOPOS_')) {
            this.removeInput('GOPOS_');
        }

        // update stopplan_ Block
        if (this.stopplan_ && !this.getInput('STOPPLAN_')) {
            this.appendDummyInput('STOPPLAN_')
                .appendField(Blockly.Msg.BCAR_MUTATOR_STOP_PLAN);
        }
        if (!this.stopplan_ && this.getInput('STOPPLAN_')) {
            this.removeInput('STOPPLAN_');
        }

        // update getbcarstatus_ Block
        if (this.getbcarstatus_ && !this.getInput('GETSTATUS_')) {
            this.appendDummyInput('GETSTATUS_')
                .appendField(Blockly.Msg.BCAR_MUTATOR_GET_STATUS);
        }
        if (!this.getbcarstatus_ && this.getInput('GETSTATUS_')) {
            this.removeInput('GETSTATUS_');
        }

        if (this.jogstep_ && !this.getInput('IDX_JOG')) {
            this.appendValueInput('IDX_JOG')
                .setCheck('Number')
                .appendField(Blockly.Msg.BCAR_IDX);

            this.appendValueInput('DIS_JOG')
                .setCheck('Number')
                .appendField(Blockly.Msg.BCAR_DIS);
            this.appendValueInput('V_JOG')
                .setCheck('Number')
                .appendField(Blockly.Msg.BCAR_VMAX);
            this.appendDummyInput('ABS_JOG')
                .appendField(new Blockly.FieldDropdown([

                    [Blockly.Msg.MOTION_BCAR_UNABS, 'UN_ABS'],
                    [Blockly.Msg.MOTION_BCAR_ABS, 'ABS_'],
                ]), 'ABS_');
        }
        if (!this.jogstep_ && this.getInput('IDX_JOG')) {
            this.removeInput('IDX_JOG');
            this.removeInput('DIS_JOG');
            this.removeInput('V_JOG');
            this.removeInput('ABS_JOG');
        }


        //changemap
        if (this.map_ && !this.getInput('MAP_CH_IDX')) {
            this.appendValueInput('MAP_CH_IDX')
                .setCheck('Number')
                .appendField(Blockly.Msg.BCAR_CH_MAP_IDX);
        }
        if (!this.map_ && this.getInput('MAP_CH_IDX')) {
            this.removeInput('MAP_CH_IDX');
        }
        //changelocalize
        if (this.locatize_ && !this.getInput('MAP_LO_IDX')) {
            this.appendValueInput('MAP_LO_IDX')
                .setCheck('Number')
                .appendField(Blockly.Msg.BCAR_MAP_IDX);
            this.appendValueInput('LO_IDX')
                .setCheck('Number')
                .appendField(Blockly.Msg.BCAR_LOCALIZE_IDX);
        }
        if (!this.locatize_ && this.getInput('MAP_LO_IDX')) {
            this.removeInput('MAP_LO_IDX');
            this.removeInput('LO_IDX');
        }

        if (this.clearbcarstatus_ && !this.getInput('CLEARSTATUS_')) {
            this.appendDummyInput('CLEARSTATUS_')
                .appendField(Blockly.Msg.BCAR_MUTATOR_CLEAR_STATUS);
        }
        if (!this.clearbcarstatus_ && this.getInput('CLEARSTATUS_')) {
            this.removeInput('CLEARSTATUS_');
        }


    }
};






Blockly.Constants.Motion.MOTION_ARC_MUTATOR_MIXIN = {
    paraCount_: 0,
    offsetCount_: 0,
    conditionCount_: 0,
    /** Create XML to represent the number of io and offset inputs.**/
    mutationToDom: function () {
        var container = document.createElement('mutation');
        if (this.paraCount_) {
            container.setAttribute('para', this.paraCount_);
        }
        if (this.offsetCount_) {
            container.setAttribute('offset', 1);
        }
        if (this.conditionCount_) {
            container.setAttribute('condition', 1);
        }
        return container;
    },

    /** Parse XML to restore the io and offset inputs.**/
    domToMutation: function (xmlElement) {
        this.paraCount_ = parseInt(xmlElement.getAttribute('para'), 10) || 0;
        this.offsetCount_ = parseInt(xmlElement.getAttribute('offset'), 10) || 0;
        this.conditionCount_ = parseInt(xmlElement.getAttribute('condition'), 10) || 0;
        this.updateShape_();
    },

    /**Populate the mutator's dialog with this block's components.**/
    decompose: function (workspace) {
        var containerBlock = workspace.newBlock('motion_door_op_create_container');
        containerBlock.initSvg();
        var connection = containerBlock.getInput('STACK').connection;
        for (var i = 0; i < this.paraCount_; i++) {
            var paraBlock = workspace.newBlock('motion_arc_pos_item');
            paraBlock.initSvg();
            connection.connect(paraBlock.previousConnection);
            connection = paraBlock.nextConnection;
        }
        for (var i = 0; i < this.conditionCount_; i++) {
            var paraBlock = workspace.newBlock('motion_door_op_item');
            paraBlock.initSvg();
            connection.connect(paraBlock.previousConnection);
            connection = paraBlock.nextConnection;
        }
        if (this.offsetCount_) {
            var offsetBlock = workspace.newBlock('motion_offset_op_item');
            offsetBlock.initSvg();
            connection.connect(offsetBlock.previousConnection);
        }

        return containerBlock;
    },

    /** Reconfigure this block based on the mutator dialog's components.**/
    compose: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        this.paraCount_ = 0;
        this.offsetCount_ = 0;
        this.conditionCount_ = 0;
        var paraConnections = [null];
        var conditionConnections = [null];
        var offsetConnection = null;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'motion_arc_pos_item':
                    this.paraCount_++;
                    paraConnections.push(itemBlock.valueConnection_);
                    break;
                case 'motion_door_op_item':
                    this.conditionCount_++;
                    paraConnections.push(itemBlock.valueConnection_);
                    break;
                case 'motion_offset_op_item':
                    this.offsetCount_ = 1;
                    offsetConnection = itemBlock.valueConnection_;
                    break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
        this.updateShape_();
        // Reconnect any child blocks.
        for (var i = 0; i < this.paraCount_; i++) {
            Blockly.Mutator.reconnect(paraConnections[i], this, 'PA' + i);
        }
        for (var i = 0; i < this.conditionCount_; i++) {
            Blockly.Mutator.reconnect(conditionConnections[i], this, 'PARA' + i);
        }
        Blockly.Mutator.reconnect(offsetConnection, this, 'OFFSET');

    },

    /** Store pointers to any connected child blocks.**/
    saveConnections: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        var i = 0;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'motion_arc_pos_item':
                    var input = this.getInput('PA' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                case 'motion_door_op_item':
                    var input = this.getInput('PARA' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                case 'motion_offset_op_item':
                    var inputOffset = this.getInput('OFFSET');
                    itemBlock.valueConnection_ = inputOffset && inputOffset.connection.targetConnection;
                    break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
    },

    /** Modify this block to have the correct number of inputs.**/
    updateShape_: function () {
        // update 条件 Block
        for (var i = 0; i < this.conditionCount_; i++) {
            if (!this.getInput('PARA' + i)) {
                this.appendValueInput('PARA' + i)
                    .setCheck('Number')
                    .appendField(new Blockly.FieldDropdown([[Blockly.Msg.MOTION_MAXSPEED, 'MaxSpeed'], [Blockly.Msg.MOTION_HEIGHTAVOID, 'HeightAvoid'],
                    [Blockly.Msg.MOTION_ENDSPEED, 'EndSpeed']]), 'OP' + i);
            }
        }
        while (this.getInput('PARA' + i)) {
            this.removeInput('PARA' + i);
            i++;
        }



        // update 条件 Block
        for (var i = 0; i < this.paraCount_; i++) {
            if (!this.getInput('PA' + i)) {
                this.appendValueInput('PA' + i)
                    .setCheck('Number')
                    .appendField('PA' + i);
                this.appendValueInput('PB' + i)
                    .setCheck('Number')
                    .appendField('PB' + i);
            }
        }
        while (this.getInput('PA' + i)) {
            this.removeInput('PA' + i);
            this.removeInput('PB' + i);
            i++;
        }

        // update Offset Block
        if (this.offsetCount_ && !this.getInput('OFFSET')) {
            this.appendValueInput('OFFSET')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_MOVE_OFFSET_I);

            this.appendValueInput('YValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_MOVE_OFFSET_J);
            this.appendValueInput('ZValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_MOVE_OFFSET_A);

        }
        if (!this.offsetCount_ && this.getInput('OFFSET')) {
            this.removeInput('OFFSET');
            this.removeInput('YValue');
            this.removeInput('ZValue');

        }
    }
};


//混淆的左边添加再这里添加
Blockly.Extensions.registerMutator('motion_move_arc_go_mutator',
    Blockly.Constants.Motion.MOTION_ARC_MUTATOR_MIXIN,
    null, ['motion_door_op_item', 'motion_offset_op_item']);
//null,['motion_door_op_item','motion_arc_pos_item','motion_offset_op_item']);


Blockly.Extensions.registerMutator('bcar_mutator',
    Blockly.Constants.Motion.MOTION_BCAR_MUTATOR_MIXIN,
    null, ['bcar_offset_downup', 'bcar_offset_forbackward', 'bcar_offset_pose', 'bcar_offset_jog', 'bcar_offset_changelocalization', 'bcar_offset_changemap', 'bcar_offset_stopplan', 'bcar_offset_clear_status','bcar_offset_get_status']);

Blockly.Constants.Motion.MOTION_ROBOT_MUTATOR_MIXIN = {
    paraCount_: 0,
    ioCount_: 0,
    offsetLeftCount_: 0,
    offsetRightCount_: 0,
    obLeftCount_: 0,
    obRightCount_: 0,
    avoidCount_: 0,
    absmode_flag_: 0,
    /** Create XML to represent the number of io and offset inputs.**/
    mutationToDom: function () {
        var container = document.createElement('mutation');
        if (this.paraCount_) {
            container.setAttribute('para', this.paraCount_);
        }
        // if (this.ioCount_) {
        //     container.setAttribute('io', this.ioCount_);
        // }
        if (this.offsetLeftCount_) {
            container.setAttribute('offsetleft', 1);
        }
        if (this.offsetRightCount_) {
            container.setAttribute('offsetright', 1);
        }
        if (this.obLeftCount_) {
            container.setAttribute('obleft', 1);
        }
        if (this.obRightCount_) {
            container.setAttribute('obright', 1);
        }
        // if (this.avoidCount_) {
        //     container.setAttribute('avoid', 1);
        // }
        // if (this.absmode_flag_) {
        //     container.setAttribute('absmode', 1);
        // }

        return container;
    },

    /** Parse XML to restore the io and offset inputs.**/
    domToMutation: function (xmlElement) {
        this.paraCount_ = parseInt(xmlElement.getAttribute('para'), 10) || 0;
        // this.ioCount_ = parseInt(xmlElement.getAttribute('io'), 10) || 0;
        this.offsetLeftCount_ = parseInt(xmlElement.getAttribute('offsetleft'), 10) || 0;
        this.offsetRightCount_ = parseInt(xmlElement.getAttribute('offsetright'), 10) || 0;
        this.obLeftCount_ = parseInt(xmlElement.getAttribute('obleft'), 10) || 0;
        this.obRightCount_ = parseInt(xmlElement.getAttribute('obright'), 10) || 0;
        // this.avoidCount_ = parseInt(xmlElement.getAttribute('avoid'), 10) || 0;
        // this.absmode_flag_ = parseInt(xmlElement.getAttribute('absmode'), 10) || 0;
        this.updateShape_();
    },

    /**Populate the mutator's dialog with this block's components.**/
    decompose: function (workspace) {
        var containerBlock = workspace.newBlock('motion_door_op_create_container');
        containerBlock.initSvg();
        var connection = containerBlock.getInput('STACK').connection;
        for (var i = 0; i < this.paraCount_; i++) {
            var paraBlock = workspace.newBlock('motion_door_op_item');
            paraBlock.initSvg();
            connection.connect(paraBlock.previousConnection);
            connection = paraBlock.nextConnection;
        }
        // for (var i = 0; i < this.ioCount_; i++) {
        //     var ioBlock = workspace.newBlock('motion_io_op_item');
        //     ioBlock.initSvg();
        //     connection.connect(ioBlock.previousConnection);
        //     connection = ioBlock.nextConnection;
        // }
        if (this.offsetLeftCount_) {
            var offsetLeftBlock = workspace.newBlock('robot_mutator_LeftOff');
            offsetLeftBlock.initSvg();
            connection.connect(offsetLeftBlock.previousConnection);
        }
        if (this.offsetRightCount_) {
            var offsetRightBlock = workspace.newBlock('robot_mutator_RightOff');
            offsetRightBlock.initSvg();
            connection.connect(offsetRightBlock.previousConnection);
        }
        if (this.obLeftCount_) {
            var obLeftBlock = workspace.newBlock('robot_mutator_LeftOb');
            obLeftBlock.initSvg();
            connection.connect(obLeftBlock.previousConnection);
        }
        if (this.obRightCount_) {
            var obRightBlock = workspace.newBlock('robot_mutator_RightOb');
            obRightBlock.initSvg();
            connection.connect(obRightBlock.previousConnection);
        }
        // if (this.avoidCount_) {
        //     var avoidBlock = workspace.newBlock('motion_avoid_op_item');
        //     avoidBlock.initSvg();
        //     connection.connect(avoidBlock.previousConnection);
        // }
        // if (this.absmode_flag_) {
        //     var absmodeBlock = workspace.newBlock('motion_absmode_op_item');
        //     absmodeBlock.initSvg();
        //     connection.connect(absmodeBlock.previousConnection);
        // }
        return containerBlock;
    },

    /** Reconfigure this block based on the mutator dialog's components.**/
    compose: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        this.paraCount_ = 0;
        this.ioCount_ = 0;
        this.offsetLeftCount_ = 0;
        this.offsetRightCount_ = 0;
        this.obLeftCount_ = 0;
        this.obRightCount_ = 0;
        this.avoidCount_ = 0;
        this.absmode_flag_ = 0;
        var paraConnections = [null];
        var ioConnections = [null];
        var offsetLeftConnection = null;
        var offsetRightConnection = null;
        var obLeftConnection = null;
        var obRightConnection = null;
        var avoidConnection = null;
        var absmodeConnection = null;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'motion_door_op_item':
                    this.paraCount_++;
                    paraConnections.push(itemBlock.valueConnection_);
                    break;
                // case 'motion_io_op_item':
                //     this.ioCount_++;
                //     ioConnections.push(itemBlock.valueConnection_);
                //     break;
                case 'robot_mutator_LeftOff':
                    this.offsetLeftCount_ = 1;
                    offsetLeftConnection = itemBlock.valueConnection_;
                    break;
                case 'robot_mutator_RightOff':
                    this.offsetRightCount_ = 1;
                    offsetRightConnection = itemBlock.valueConnection_;
                    break;
                case 'robot_mutator_LeftOb':
                    this.obLeftCount_ = 1;
                    obLeftConnection = itemBlock.valueConnection_;
                    break;
                case 'robot_mutator_RightOb':
                    this.obRightCount_ = 1;
                    obRightConnection = itemBlock.valueConnection_;
                    break;
                // case 'motion_avoid_op_item':
                //     this.avoidCount_ = 1;
                //     avoidConnection = itemBlock.valueConnection_;
                //     break;
                // case 'motion_absmode_op_item':
                //     this.absmode_flag_ = 1;
                //     absmodeConnection = itemBlock.valueConnection_;
                //     break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
        this.updateShape_();
        // Reconnect any child blocks.
        for (var i = 0; i < this.paraCount_; i++) {
            Blockly.Mutator.reconnect(paraConnections[i], this, 'PARA' + i);
        }
        // for (var i = 0; i < this.ioCount_; i++) {
        //     Blockly.Mutator.reconnect(ioConnections[i], this, 'IO' + i);
        // }
        Blockly.Mutator.reconnect(offsetLeftConnection, this, 'OFFSETLEFT');
        Blockly.Mutator.reconnect(offsetRightConnection, this, 'OFFSETRIGHT');
        Blockly.Mutator.reconnect(obLeftConnection, this, 'OBLEFT');
        Blockly.Mutator.reconnect(obRightConnection, this, 'OBRIGHT');
        // Blockly.Mutator.reconnect(avoidConnection, this, 'AVOID');
        // Blockly.Mutator.reconnect(absmodeConnection, this, 'ABSMODE');
    },

    /** Store pointers to any connected child blocks.**/
    saveConnections: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        var i = 0;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'motion_door_op_item':
                    var input = this.getInput('PARA' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                // case 'motion_io_op_item':
                //     var input = this.getInput('IO' + i);
                //     itemBlock.valueConnection_ = input && input.connection.targetConnection;
                //     i++;
                //     break;
                case 'robot_mutator_LeftOff':
                    var inputOffset = this.getInput('OFFSETLEFT');
                    itemBlock.valueConnection_ = inputOffset && inputOffset.connection.targetConnection;
                    break;
                case 'robot_mutator_RightOff':
                    var inputOffset = this.getInput('OFFSETRIGHT');
                    itemBlock.valueConnection_ = inputOffset && inputOffset.connection.targetConnection;
                    break;
                case 'robot_mutator_LeftOb':
                    var inputOffset = this.getInput('OBLEFT');
                    itemBlock.valueConnection_ = inputOffset && inputOffset.connection.targetConnection;
                    break;
                case 'robot_mutator_RightOb':
                    var inputOffset = this.getInput('OBRIGHT');
                    itemBlock.valueConnection_ = inputOffset && inputOffset.connection.targetConnection;
                    break;
                // case 'motion_avoid_op_item':
                //     var inputAvoid = this.getInput('AVOID');
                //     itemBlock.valueConnection_ = inputAvoid && inputAvoid.connection.targetConnection;
                //     break;
                // case 'motion_absmode_op_item':
                //     var inputABSMODE = this.getInput('ABSMODE');
                //     itemBlock.valueConnection_ = inputABSMODE && inputABSMODE.connection;
                //     break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
    },

    /** Modify this block to have the correct number of inputs.**/
    updateShape_: function () {
        // update 条件 Block
        for (var i = 0; i < this.paraCount_; i++) {
            if (!this.getInput('PARA' + i)) {
                this.appendValueInput('PARA' + i)
                    .setCheck('Number')
                    .appendField(new Blockly.FieldDropdown([[Blockly.Msg.MOTION_AVOIDPOINT, 'AvoidPoint'],
                    [Blockly.Msg.MOTION_HEIGHTAVOID, 'HeightAvoid'], [Blockly.Msg.MOTION_MAXSPEED, 'MaxSpeed'],
                    [Blockly.Msg.MOTION_ENDSPEED, 'EndSpeed']]), 'OP' + i);
            }
        }
        while (this.getInput('PARA' + i)) {
            this.removeInput('PARA' + i);
            i++;
        }

        // // update IO Block
        // for (var i = 0; i < this.ioCount_; i++) {
        //     if (!this.getInput('IO' + i)) {
        //         this.appendValueInput('IO' + i)
        //             .setCheck('Number')
        //             .appendField(Blockly.Msg.MOTION_SET_OUTPUT);
        //         this.appendValueInput('DisRatio' + i)
        //             .setCheck('Number')
        //             .appendField(Blockly.Msg.MOTION_MOVEL_IO + i);
        //     }
        // }
        // while (this.getInput('IO' + i)) {
        //     this.removeInput('IO' + i);
        //     this.removeInput('DisRatio' + i);
        //     i++;
        // }


        // update Offset Block
        if (this.offsetLeftCount_ && !this.getInput('LXValue')) {
            this.appendValueInput('LXValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFX_L);
            this.appendValueInput('LYValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFY_L);
            this.appendValueInput('LZValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFZ_L);
            this.appendValueInput('LAValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFA_L);
            this.appendValueInput('LBValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFB_L);
            this.appendValueInput('LCValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFC_L);
        }
        if (!this.offsetLeftCount_ && this.getInput('LXValue')) {
            this.removeInput('LXValue');
            this.removeInput('LYValue');
            this.removeInput('LZValue');
            this.removeInput('LAValue');
            this.removeInput('LBValue');
            this.removeInput('LCValue');
        }

        if (this.offsetRightCount_ && !this.getInput('RXValue')) {
            this.appendValueInput('RXValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFX_R);
            this.appendValueInput('RYValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFY_R);
            this.appendValueInput('RZValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFZ_R);
            this.appendValueInput('RAValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFA_R);
            this.appendValueInput('RBValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFB_R);
            this.appendValueInput('RCValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFC_R);
        }
        if (!this.offsetRightCount_ && this.getInput('RXValue')) {
            this.removeInput('RXValue');
            this.removeInput('RYValue');
            this.removeInput('RZValue');
            this.removeInput('RAValue');
            this.removeInput('RBValue');
            this.removeInput('RCValue');
        }




        if (this.obLeftCount_ && !this.getInput('OBLEFT_')) {
            this.appendDummyInput('OBLEFT_')
                .appendField(Blockly.Msg.MOTION_ROBOT_OB_L);
        }
        if (!this.obLeftCount_ && this.getInput('OBLEFT_')) {
            this.removeInput('OBLEFT_');

        }
        if (this.obRightCount_ && !this.getInput('OBRIGHT_')) {
            this.appendDummyInput('OBRIGHT_')
                .appendField(Blockly.Msg.MOTION_ROBOT_OB_R);

        }
        if (!this.obRightCount_ && this.getInput('OBRIGHT_')) {
            this.removeInput('OBRIGHT_');

        }
        // // update Avoid Block
        // if (this.avoidCount_ && !this.getInput('AVOID')) {
        //     this.appendValueInput('AVOID')
        //         .appendField(Blockly.Msg.MOTION_MOVEL_AVOID_LIST);
        // }
        // if (!this.avoidCount_ && this.getInput('AVOID')) {
        //     this.removeInput('AVOID');
        // }
    }
};

Blockly.Extensions.registerMutator('robot_mutator',
    Blockly.Constants.Motion.MOTION_ROBOT_MUTATOR_MIXIN,
    null, ['motion_door_op_item', 'robot_mutator_LeftOff', 'robot_mutator_RightOff', 'robot_mutator_LeftOb', 'robot_mutator_RightOb']);





/**--------------------------------- Extension and Mutator ----------------------------------------*/
/** mutator of 'Door' */
Blockly.Constants.Motion.MOTION_DOOR_MUTATOR_MIXIN = {
    paraCount_: 0,
    ioCount_: 0,
    offsetCount_: 0,
    avoidCount_: 0,
    absmode_flag_: 0,
    offsetabcCount_: 0,
    /** Create XML to represent the number of io and offset inputs.**/
    mutationToDom: function () {
        var container = document.createElement('mutation');
        if (this.paraCount_) {
            container.setAttribute('para', this.paraCount_);
        }
        if (this.ioCount_) {
            container.setAttribute('io', this.ioCount_);
        }
        if (this.offsetCount_) {
            container.setAttribute('offset', 1);
        }
        if (this.offsetabcCount_) {
            container.setAttribute('offsetabc', 1);
        }
        if (this.avoidCount_) {
            container.setAttribute('avoid', 1);
        }
        if (this.absmode_flag_) {
            container.setAttribute('absmode', 1);
        }

        return container;
    },

    /** Parse XML to restore the io and offset inputs.**/
    domToMutation: function (xmlElement) {
        this.paraCount_ = parseInt(xmlElement.getAttribute('para'), 10) || 0;
        this.ioCount_ = parseInt(xmlElement.getAttribute('io'), 10) || 0;
        this.offsetCount_ = parseInt(xmlElement.getAttribute('offset'), 10) || 0;
        this.offsetabcCount_ = parseInt(xmlElement.getAttribute('offsetabc'), 10) || 0;
        this.avoidCount_ = parseInt(xmlElement.getAttribute('avoid'), 10) || 0;
        this.absmode_flag_ = parseInt(xmlElement.getAttribute('absmode'), 10) || 0;
        this.updateShape_();
    },

    /**Populate the mutator's dialog with this block's components.**/
    decompose: function (workspace) {
        var containerBlock = workspace.newBlock('motion_door_op_create_container');
        containerBlock.initSvg();
        var connection = containerBlock.getInput('STACK').connection;
        for (var i = 0; i < this.paraCount_; i++) {
            var paraBlock = workspace.newBlock('motion_door_op_item');
            paraBlock.initSvg();
            connection.connect(paraBlock.previousConnection);
            connection = paraBlock.nextConnection;
        }
        for (var i = 0; i < this.ioCount_; i++) {
            var ioBlock = workspace.newBlock('motion_io_op_item');
            ioBlock.initSvg();
            connection.connect(ioBlock.previousConnection);
            connection = ioBlock.nextConnection;
        }
        if (this.offsetCount_) {
            var offsetBlock = workspace.newBlock('motion_offset_op_item');
            offsetBlock.initSvg();
            connection.connect(offsetBlock.previousConnection);
        }
        if (this.offsetabcCount_) {
            var offsetabcBlock = workspace.newBlock('motion_offset_abc');
            offsetabcBlock.initSvg();
            connection.connect(offsetabcBlock.previousConnection);
        }
        if (this.avoidCount_) {
            var avoidBlock = workspace.newBlock('motion_avoid_op_item');
            avoidBlock.initSvg();
            connection.connect(avoidBlock.previousConnection);
        }
        if (this.absmode_flag_) {
            var absmodeBlock = workspace.newBlock('motion_absmode_op_item');
            absmodeBlock.initSvg();
            connection.connect(absmodeBlock.previousConnection);
        }
        return containerBlock;
    },

    /** Reconfigure this block based on the mutator dialog's components.**/
    compose: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        this.paraCount_ = 0;
        this.ioCount_ = 0;
        this.offsetCount_ = 0;
        this.offsetabcCount_ = 0;
        this.avoidCount_ = 0;
        this.absmode_flag_ = 0;
        var paraConnections = [null];
        var ioConnections = [null];
        var offsetConnection = null;
        var offsetabcConnection = null;
        var avoidConnection = null;
        var absmodeConnection = null;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'motion_door_op_item':
                    this.paraCount_++;
                    paraConnections.push(itemBlock.valueConnection_);
                    break;
                case 'motion_io_op_item':
                    this.ioCount_++;
                    ioConnections.push(itemBlock.valueConnection_);
                    break;
                case 'motion_offset_op_item':
                    this.offsetCount_ = 1;
                    offsetConnection = itemBlock.valueConnection_;
                    break;
                case 'motion_offset_abc':
                    this.offsetabcCount_ = 1;
                    offsetabcConnection = itemBlock.valueConnection_;
                    break;
                case 'motion_avoid_op_item':
                    this.avoidCount_ = 1;
                    avoidConnection = itemBlock.valueConnection_;
                    break;
                case 'motion_absmode_op_item':
                    this.absmode_flag_ = 1;
                    absmodeConnection = itemBlock.valueConnection_;
                    break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
        this.updateShape_();
        // Reconnect any child blocks.
        for (var i = 0; i < this.paraCount_; i++) {
            Blockly.Mutator.reconnect(paraConnections[i], this, 'PARA' + i);
        }
        for (var i = 0; i < this.ioCount_; i++) {
            Blockly.Mutator.reconnect(ioConnections[i], this, 'IO' + i);
        }
        Blockly.Mutator.reconnect(offsetConnection, this, 'OFFSET');
        Blockly.Mutator.reconnect(offsetabcConnection, this, 'OFFSETABC');
        Blockly.Mutator.reconnect(avoidConnection, this, 'AVOID');
        Blockly.Mutator.reconnect(absmodeConnection, this, 'ABSMODE');
    },

    /** Store pointers to any connected child blocks.**/
    saveConnections: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        var i = 0;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'motion_door_op_item':
                    var input = this.getInput('PARA' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                case 'motion_io_op_item':
                    var input = this.getInput('IO' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                case 'motion_offset_op_item':
                    var inputOffset = this.getInput('OFFSET');
                    itemBlock.valueConnection_ = inputOffset && inputOffset.connection.targetConnection;
                    break;
                case 'motion_offset_abc':
                    var inputOffsetABC = this.getInput('OFFSETABC');
                    itemBlock.valueConnection_ = inputOffsetABC && inputOffsetABC.connection.targetConnection;
                    break;
                case 'motion_avoid_op_item':
                    var inputAvoid = this.getInput('AVOID');
                    itemBlock.valueConnection_ = inputAvoid && inputAvoid.connection.targetConnection;
                    break;
                case 'motion_absmode_op_item':
                    var inputABSMODE = this.getInput('ABSMODE');
                    itemBlock.valueConnection_ = inputABSMODE && inputABSMODE.connection;
                    break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
    },

    /** Modify this block to have the correct number of inputs.**/
    updateShape_: function () {
        // update 条件 Block
        for (var i = 0; i < this.paraCount_; i++) {
            if (!this.getInput('PARA' + i)) {
                this.appendValueInput('PARA' + i)
                    .setCheck('Number')
                    .appendField(new Blockly.FieldDropdown([[Blockly.Msg.MOTION_AVOIDPOINT, 'AvoidPoint'],
                    [Blockly.Msg.MOTION_HEIGHTAVOID, 'HeightAvoid'], [Blockly.Msg.MOTION_MAXSPEED, 'MaxSpeed'],
                    [Blockly.Msg.MOTION_ENDSPEED, 'EndSpeed']]), 'OP' + i);
            }
        }
        while (this.getInput('PARA' + i)) {
            this.removeInput('PARA' + i);
            i++;
        }

        // update IO Block
        for (var i = 0; i < this.ioCount_; i++) {
            if (!this.getInput('IO' + i)) {
                this.appendValueInput('IO' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_SET_OUTPUT);
                this.appendValueInput('DisRatio' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_MOVEL_IO + i);
            }
        }
        while (this.getInput('IO' + i)) {
            this.removeInput('IO' + i);
            this.removeInput('DisRatio' + i);
            i++;
        }


        if (this.absmode_flag_ && !this.getInput('ABSMODE')) {
            this.appendDummyInput("ABSMODE")
                .appendField(new Blockly.FieldDropdown([["G90", 'absmode']]), 'OP_G90');
        }
        if (!this.absmode_flag_ && this.getInput('ABSMODE')) {
            this.removeInput('ABSMODE');
        }




        // update Offset Block
        if (this.offsetCount_ && !this.getInput('OFFSET')) {
            this.appendValueInput('OFFSET')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_MOVE_OFFSET_X);
            this.appendValueInput('YValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_MOVE_OFFSET_Y);
            this.appendValueInput('ZValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_MOVE_OFFSET_Z);
            this.appendValueInput('WValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_MOVE_OFFSET_W);
        }
        if (!this.offsetCount_ && this.getInput('OFFSET')) {
            this.removeInput('OFFSET');
            this.removeInput('YValue');
            this.removeInput('ZValue');
            this.removeInput('WValue');
        }

        if (this.offsetabcCount_ && !this.getInput('OFFSETABC')) {
            this.appendValueInput('OFFSETABC')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFA);
            this.appendValueInput('OFFSETB')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFB);
            this.appendValueInput('OFFSETC')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_ROBOT_OFFC);

        }
        if (!this.offsetabcCount_ && this.getInput('OFFSETABC')) {
            this.removeInput('OFFSETABC');
            this.removeInput('OFFSETB');
            this.removeInput('OFFSETC');

        }

        // update Avoid Block
        if (this.avoidCount_ && !this.getInput('AVOID')) {
            this.appendValueInput('AVOID')
                .appendField(Blockly.Msg.MOTION_MOVEL_AVOID_LIST);
        }
        if (!this.avoidCount_ && this.getInput('AVOID')) {
            this.removeInput('AVOID');
        }
    }
};

Blockly.Extensions.registerMutator('motion_door_mutator',
    Blockly.Constants.Motion.MOTION_DOOR_MUTATOR_MIXIN,
    null, ['motion_door_op_item', 'motion_io_op_item', 'motion_offset_op_item', 'motion_offset_abc', 'motion_avoid_op_item', 'motion_absmode_op_item']);

/** mutator of 'Move Go' */
Blockly.Constants.Motion.MOTION_MOVEGO_MUTATOR_MIXIN = {
    axisCount_: 0,
    sJogCount_: 0,
    tJogCount_: 0,
    absmode_flag_: 0,
    zeromode_flag_: 0,

    /** Create XML to represent the number of io and offset inputs.**/
    mutationToDom: function () {
        var container = document.createElement('mutation');
        if (this.axisCount_) {
            container.setAttribute('axis', this.axisCount_);
        }
        if (this.sJogCount_) {
            container.setAttribute('s_jog', this.sJogCount_);
        }
        if (this.tJogCount_) {
            container.setAttribute('t_jog', this.tJogCount_);
        }
        if (this.absmode_flag_) {
            container.setAttribute('absmode', this.absmode_flag_);
        }
        if (this.zeromode_flag_) {
            container.setAttribute('zeromode', this.zeromode_flag_);
        }
        return container;
    },

    /** Parse XML to restore the io and offset inputs.**/
    domToMutation: function (xmlElement) {
        this.axisCount_ = parseInt(xmlElement.getAttribute('axis'), 10) || 0;
        this.sJogCount_ = parseInt(xmlElement.getAttribute('s_jog'), 10) || 0;
        this.tJogCount_ = parseInt(xmlElement.getAttribute('t_jog'), 10) || 0;
        this.absmode_flag_ = parseInt(xmlElement.getAttribute('absmode'), 10) || 0;
        this.zeromode_flag_ = parseInt(xmlElement.getAttribute('zeromode'), 10) || 0;
        this.updateShape_();
    },

    /**Populate the mutator's dialog with this block's components.**/
    decompose: function (workspace) {
        var containerBlock = workspace.newBlock('motion_door_op_create_container');
        containerBlock.initSvg();
        var connection = containerBlock.getInput('STACK').connection;
        for (var i = 0; i < this.axisCount_; i++) {
            var axisBlock = workspace.newBlock('motion_axismove_item');
            axisBlock.initSvg();
            connection.connect(axisBlock.previousConnection);
            connection = axisBlock.nextConnection;
        }
        for (var i = 0; i < this.sJogCount_; i++) {
            var sJogBlock = workspace.newBlock('motion_jog_start_item');
            sJogBlock.initSvg();
            connection.connect(sJogBlock.previousConnection);
            connection = sJogBlock.nextConnection;
        }
        for (var i = 0; i < this.tJogCount_; i++) {
            var tJogBlock = workspace.newBlock('motion_jog_stop_item');
            tJogBlock.initSvg();
            connection.connect(tJogBlock.previousConnection);
            connection = tJogBlock.nextConnection;
        }
        if (this.absmode_flag_) {
            var absmodeBlock = workspace.newBlock('motion_absmode_op_item');
            absmodeBlock.initSvg();
            connection.connect(absmodeBlock.previousConnection);
        }
        if (this.zeromode_flag_) {
            var zeromodeBlock = workspace.newBlock('motion_zeromode_op_item');
            zeromodeBlock.initSvg();
            connection.connect(zeromodeBlock.previousConnection);
        }
        return containerBlock;
    },

    /** Reconfigure this block based on the mutator dialog's components.**/
    compose: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        this.axisCount_ = 0;
        this.sJogCount_ = 0;
        this.tJogCount_ = 0;
        this.absmode_flag_ = 0;
        this.zeromode_flag_ = 0;
        var axisConnections = [null];
        var sJogConnections = [null];
        var tJogConnections = [null];
        var absmodeConnection = null;
        var zeromodeConnection = null;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'motion_axismove_item':
                    this.axisCount_++;
                    axisConnections.push(itemBlock.valueConnection_);
                    break;
                case 'motion_jog_start_item':
                    this.sJogCount_++;
                    sJogConnections.push(itemBlock.valueConnection_);
                    break;
                case 'motion_jog_stop_item':
                    this.tJogCount_++;
                    tJogConnections.push(itemBlock.valueConnection_);
                    break;
                case 'motion_absmode_op_item':
                    this.absmode_flag_ = 1;
                    absmodeConnection = itemBlock.valueConnection_;
                    break;
                case 'motion_zeromode_op_item':
                    this.zeromode_flag_ = 1;
                    zeromodeConnection = itemBlock.valueConnection_;
                    break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
        this.updateShape_();
        // Reconnect any child blocks.
        for (var i = 0; i < this.axisCount_; i++) {
            Blockly.Mutator.reconnect(axisConnections[i], this, 'AXIS' + i);
        }
        for (var i = 0; i < this.sJogCount_; i++) {
            Blockly.Mutator.reconnect(sJogConnections[i], this, 'sJOG' + i);
        }
        for (var i = 0; i < this.tJogCount_; i++) {
            Blockly.Mutator.reconnect(tJogConnections[i], this, 'tJOG' + i);
        }
        Blockly.Mutator.reconnect(absmodeConnection, this, 'ABSMODE');
        Blockly.Mutator.reconnect(zeromodeConnection, this, 'ZEROMODE');
    },

    /** Store pointers to any connected child blocks.**/
    saveConnections: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        var i = 0;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'motion_axismove_item':
                    var input = this.getInput('AXIS' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                case 'motion_jog_start_item':
                    var input = this.getInput('sJOG' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                case 'motion_jog_stop_item':
                    var input = this.getInput('tJOG' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                case 'motion_absmode_op_item':
                    var input = this.getInput('ABSMODE');
                    itemBlock.valueConnection_ = input && input.connection;
                    break;
                case 'motion_zeromode_op_item':
                    var input = this.getInput('ZEROMODE');
                    itemBlock.valueConnection_ = input && input.connection;
                    break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
    },

    /** Modify this block to have the correct number of inputs.**/
    updateShape_: function () {
        // update 关节点动 Block
        for (var i = 0; i < this.axisCount_; i++) {
            if (!this.getInput('AXIS' + i)) {
                this.appendValueInput('AXIS' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_AXIS_NUM);
                this.appendValueInput('Distance' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_DISTANCE);
                this.appendValueInput('axisSpeed' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_SPEED);
            }
        }
        while (this.getInput('AXIS' + i)) {
            this.removeInput('AXIS' + i);
            this.removeInput('Distance' + i);
            this.removeInput('axisSpeed' + i);
            i++;
        }

        // update JOG�?�? Block
        for (var i = 0; i < this.sJogCount_; i++) {
            if (!this.getInput('sJOG' + i)) {
                this.appendValueInput('sJOG' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_AXIS_NUM);
                this.appendValueInput('jogSpeed' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_SPEED);
            }
        }
        while (this.getInput('sJOG' + i)) {
            this.removeInput('sJOG' + i);
            this.removeInput('jogSpeed' + i);
            i++;
        }

        // update JOG停�?? Block
        for (var i = 0; i < this.tJogCount_; i++) {
            if (!this.getInput('tJOG' + i)) {
                this.appendValueInput('tJOG' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_AXIS_NUM);
            }
        }
        while (this.getInput('tJOG' + i)) {
            this.removeInput('tJOG' + i);
            i++;
        }

        // update '绝�?�模�?' Block
        if (this.absmode_flag_ && !this.getInput('ABSMODE')) {
            this.appendDummyInput("ABSMODE")
                .appendField(new Blockly.FieldTextInput("G90"), 'absmode');
        }
        if (!this.absmode_flag_ && this.getInput('ABSMODE')) {
            this.removeInput('ABSMODE');
        }

        // update '回零模式' Block
        if (this.zeromode_flag_ && !this.getInput('ZEROMODE')) {
            this.appendValueInput('zeroAxis')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_AXIS_NUM);
            this.appendValueInput('zeroOfs')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_OFFSET_ORIGIN);
            this.appendValueInput('zeroSpd')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_SPEED);
            this.appendValueInput('ZEROMODE')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_MODE_RETURN_ZERO);
        }
        if (!this.zeromode_flag_ && this.getInput('ZEROMODE')) {
            this.removeInput('ZEROMODE');
            this.removeInput('zeroAxis');
            this.removeInput('zeroOfs');
            this.removeInput('zeroSpd');
        }
    }
};

Blockly.Extensions.registerMutator('motion_movego_mutator',
    Blockly.Constants.Motion.MOTION_MOVEGO_MUTATOR_MIXIN,
    null, ['motion_axismove_item', 'motion_jog_start_item', 'motion_jog_stop_item', 'motion_absmode_op_item', 'motion_zeromode_op_item']);

/** mutator of 'exec place' */
Blockly.Constants.Motion.MOTION_EXEC_PLACE_MUTATOR_MIXIN = {
    paraCount_: 0,
    ioCount_: 0,
    arrayCount_: 0,
    offsetCount_: 0,

    /** Create XML to represent the number of io and offset inputs.**/
    mutationToDom: function () {
        var container = document.createElement('mutation');
        if (this.paraCount_) {
            container.setAttribute('para', this.paraCount_);
        }
        if (this.ioCount_) {
            container.setAttribute('io', this.ioCount_);
        }
        if (this.arrayCount_) {
            container.setAttribute('array', this.arrayCount_);
        }
        if (this.offsetCount_) {
            container.setAttribute('offset', 1);
        }
        return container;
    },

    /** Parse XML to restore the io and offset inputs.**/
    domToMutation: function (xmlElement) {
        this.paraCount_ = parseInt(xmlElement.getAttribute('para'), 10) || 0;
        this.ioCount_ = parseInt(xmlElement.getAttribute('io'), 10) || 0;
        this.arrayCount_ = parseInt(xmlElement.getAttribute('array'), 10) || 0;
        this.offsetCount_ = parseInt(xmlElement.getAttribute('offset'), 10) || 0;
        this.updateShape_();
    },

    /**Populate the mutator's dialog with this block's components.**/
    decompose: function (workspace) {
        var containerBlock = workspace.newBlock('motion_door_op_create_container');
        containerBlock.initSvg();
        var connection = containerBlock.getInput('STACK').connection;
        for (var i = 0; i < this.paraCount_; i++) {
            var paraBlock = workspace.newBlock('motion_door_op_item');
            paraBlock.initSvg();
            connection.connect(paraBlock.previousConnection);
            connection = paraBlock.nextConnection;
        }
        for (var i = 0; i < this.ioCount_; i++) {
            var ioBlock = workspace.newBlock('motion_io_op_item');
            ioBlock.initSvg();
            connection.connect(ioBlock.previousConnection);
            connection = ioBlock.nextConnection;
        }
        for (var i = 0; i < this.arrayCount_; i++) {
            var arrayBlock = workspace.newBlock('motion_array_op_item');
            arrayBlock.initSvg();
            connection.connect(arrayBlock.previousConnection);
            connection = arrayBlock.nextConnection;
        }
        if (this.offsetCount_) {
            var offsetBlock = workspace.newBlock('motion_offset_op_item');
            offsetBlock.initSvg();
            connection.connect(offsetBlock.previousConnection);
        }
        return containerBlock;
    },

    /** Reconfigure this block based on the mutator dialog's components.**/
    compose: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        this.paraCount_ = 0;
        this.ioCount_ = 0;
        this.arrayCount_ = 0;
        this.offsetCount_ = 0;
        var paraConnections = [null];
        var ioConnections = [null];
        var arrayConnections = [null];
        var offsetConnection = null;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'motion_door_op_item':
                    this.paraCount_++;
                    paraConnections.push(itemBlock.valueConnection_);
                    break;
                case 'motion_io_op_item':
                    this.ioCount_++;
                    ioConnections.push(itemBlock.valueConnection_);
                    break;
                case 'motion_array_op_item':
                    this.arrayCount_++;
                    ioConnections.push(itemBlock.valueConnection_);
                    break;
                case 'motion_offset_op_item':
                    this.offsetCount_ = 1;
                    offsetConnection = itemBlock.valueConnection_;
                    break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
        this.updateShape_();
        // Reconnect any child blocks.
        for (var i = 0; i < this.paraCount_; i++) {
            Blockly.Mutator.reconnect(paraConnections[i], this, 'PARA' + i);
        }
        for (var i = 0; i < this.ioCount_; i++) {
            Blockly.Mutator.reconnect(ioConnections[i], this, 'IO' + i);
        }
        for (var i = 0; i < this.arrayCount_; i++) {
            Blockly.Mutator.reconnect(arrayConnections[i], this, 'ARRAY' + i);
        }
        Blockly.Mutator.reconnect(offsetConnection, this, 'OFFSET');
    },

    /** Store pointers to any connected child blocks.**/
    saveConnections: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        var i = 0;
        while (itemBlock) {
            switch (itemBlock.type) {
                case 'motion_door_op_item':
                    var input = this.getInput('PARA' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                case 'motion_io_op_item':
                    var input = this.getInput('IO' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                case 'motion_array_op_item':
                    var input = this.getInput('ARRAY' + i);
                    itemBlock.valueConnection_ = input && input.connection.targetConnection;
                    i++;
                    break;
                case 'motion_offset_op_item':
                    var inputOffset = this.getInput('OFFSET');
                    itemBlock.valueConnection_ = inputOffset && inputOffset.connection.targetConnection;
                    break;
                default:
                    break;
            }
            itemBlock = itemBlock.nextConnection && itemBlock.nextConnection.targetBlock();
        }
    },

    /** Modify this block to have the correct number of inputs.**/
    updateShape_: function () {
        // update 条件 Block
        for (var i = 0; i < this.paraCount_; i++) {
            if (!this.getInput('PARA' + i)) {
                this.appendValueInput('PARA' + i)
                    .setCheck('Number')
                    .appendField(new Blockly.FieldDropdown([[Blockly.Msg.MOTION_HEIGHTAVOID, 'HeightAvoid'],
                    [Blockly.Msg.MOTION_MAXSPEED, 'MaxSpeed'], [Blockly.Msg.MOTION_ENDSPEED, 'EndSpeed']]), 'OP' + i);
            }
        }
        while (this.getInput('PARA' + i)) {
            this.removeInput('PARA' + i);
            i++;
        }

        // update IO Block
        for (var i = 0; i < this.ioCount_; i++) {
            if (!this.getInput('IO' + i)) {
                this.appendValueInput('IO' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_SET_OUTPUT);
                this.appendValueInput('DisRatio' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_DISPLACEMENT_RATIO + i);
            }
        }
        while (this.getInput('IO' + i)) {
            this.removeInput('IO' + i);
            this.removeInput('DisRatio' + i);
            i++;
        }

        // update Array Block
        for (var i = 0; i < this.arrayCount_; i++) {
            if (!this.getInput('ARRAY' + i)) {
                this.appendValueInput('ARRAY' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_MOVE_COORDINATE_XSTEP);
                this.appendValueInput('YStep' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_MOVE_COORDINATE_YSTEP);
                this.appendValueInput('XIndex' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_MOVE_COORDINATE_XINDEX);
                this.appendValueInput('YIndex' + i)
                    .setCheck('Number')
                    .appendField(Blockly.Msg.MOTION_MOVE_COORDINATE_YINDEX);
            }
        }
        while (this.getInput('ARRAY' + i)) {
            this.removeInput('ARRAY' + i);
            this.removeInput('YStep' + i);
            this.removeInput('XIndex' + i);
            this.removeInput('YIndex' + i);
            i++;
        }

        // update Offset Block
        if (this.offsetCount_ && !this.getInput('OFFSET')) {
            this.appendValueInput('OFFSET')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_MOVE_OFFSET_X + ' I');
            this.appendValueInput('YValue')
                .setCheck('Number')
                .appendField(Blockly.Msg.MOTION_MOVE_OFFSET_Y + ' J');
        }
        if (!this.offsetCount_ && this.getInput('OFFSET')) {
            this.removeInput('OFFSET');
            this.removeInput('YValue');
        }
    }
};


/** mutator of 'Circle' */
Blockly.Constants.Motion.QUOTE_IMAGE_MIXIN = {
    /**
     * Image data URI of an LTR opening double quote (same as RTL closing couble quote).
     * @readonly
     */
    QUOTE_IMAGE_LEFT_DATAURI:
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAKCAQAAAAqJXdxAAAAn0lEQVQI1z3OMa5BURSF4f/cQhAKjUQhuQmFNwGJEUi0RKN5rU7FHKhpjEH3TEMtkdBSCY1EIv8r7nFX9e29V7EBAOvu7RPjwmWGH/VuF8CyN9/OAdvqIXYLvtRaNjx9mMTDyo+NjAN1HNcl9ZQ5oQMM3dgDUqDo1l8DzvwmtZN7mnD+PkmLa+4mhrxVA9fRowBWmVBhFy5gYEjKMfz9AylsaRRgGzvZAAAAAElFTkSuQmCC',
    /**
     * Image data URI of an LTR closing double quote (same as RTL opening couble quote).
     * @readonly
     */
    QUOTE_IMAGE_RIGHT_DATAURI:
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAKCAQAAAAqJXdxAAAAqUlEQVQI1z3KvUpCcRiA8ef9E4JNHhI0aFEacm1o0BsI0Slx8wa8gLauoDnoBhq7DcfWhggONDmJJgqCPA7neJ7p934EOOKOnM8Q7PDElo/4x4lFb2DmuUjcUzS3URnGib9qaPNbuXvBO3sGPHJDRG6fGVdMSeWDP2q99FQdFrz26Gu5Tq7dFMzUvbXy8KXeAj57cOklgA+u1B5AoslLtGIHQMaCVnwDnADZIFIrXsoXrgAAAABJRU5ErkJggg==',
    /**
     * Pixel width of QUOTE_IMAGE_LEFT_DATAURI and QUOTE_IMAGE_RIGHT_DATAURI.
     * @readonly
     */
    QUOTE_IMAGE_WIDTH: 12,
    /**
     * Pixel height of QUOTE_IMAGE_LEFT_DATAURI and QUOTE_IMAGE_RIGHT_DATAURI.
     * @readonly
     */
    QUOTE_IMAGE_HEIGHT: 12,

    /**
     * Inserts appropriate quote images before and after the named field.
     * @param {string} fieldName The name of the field to wrap with quotes.
     */
    quoteField_: function (fieldName) {
        for (var i = 0, input; input = this.inputList[i]; i++) {
            for (var j = 0, field; field = input.fieldRow[j]; j++) {
                if (fieldName == field.name) {
                    input.insertFieldAt(j, this.newQuote_(true));
                    input.insertFieldAt(j + 2, this.newQuote_(false));
                    return;
                }
            }
        }
        console.warn('field named "' + fieldName + '" not found in ' + this.toDevString());
    },

    /**
     * A helper function that generates a FieldImage of an opening or
     * closing double quote. The selected quote will be adapted for RTL blocks.
     * @param {boolean} open If the image should be open quote (�? in LTR).
     *                       Otherwise, a closing quote is used (�? in LTR).
     * @returns {!Blockly.FieldImage} The new field.
     */
    newQuote_: function (open) {
        var isLeft = this.RTL ? !open : open;
        var dataUri = isLeft ?
            this.QUOTE_IMAGE_LEFT_DATAURI :
            this.QUOTE_IMAGE_RIGHT_DATAURI;
        return new Blockly.FieldImage(
            dataUri,
            this.QUOTE_IMAGE_WIDTH,
            this.QUOTE_IMAGE_HEIGHT,
            isLeft ? '\u201C' : '\u201D');
    }
};

Blockly.Constants.Motion.MOTION_MOVECIRCLE_OP_MUTATOR_MIXIN = {
    /**
     * Create XML to represent number of text inputs.
     * @return {!Element} XML storage element.
     * @this Blockly.Block
     */
    mutationToDom: function () {
        var container = document.createElement('mutation');
        container.setAttribute('items', this.itemCount_);
        return container;
    },
    /**
     * Parse XML to restore the text inputs.
     * @param {!Element} xmlElement XML storage element.
     * @this Blockly.Block
     */
    domToMutation: function (xmlElement) {
        this.itemCount_ = parseInt(xmlElement.getAttribute('items'), 10);
        this.updateShape_();
    },
    /**
     * Populate the mutator's dialog with this block's components.
     * @param {!Blockly.Workspace} workspace Mutator's workspace.
     * @return {!Blockly.Block} Root block in mutator.
     * @this Blockly.Block
     */
    decompose: function (workspace) {
        var containerBlock = workspace.newBlock('motion_MoveCircle_op_create_container');
        containerBlock.initSvg();
        var connection = containerBlock.getInput('STACK').connection;
        for (var i = 0; i < this.itemCount_; i++) {
            var itemBlock = workspace.newBlock('motion_MoveCircle_op_item'); 1
            itemBlock.initSvg();
            connection.connect(itemBlock.previousConnection);
            connection = itemBlock.nextConnection;
        }
        return containerBlock;
    },
    /**
     * Reconfigure this block based on the mutator dialog's components.
     * @param {!Blockly.Block} containerBlock Root block in mutator.
     * @this Blockly.Block
     */
    compose: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        // Count number of inputs.
        var connections = [];
        while (itemBlock) {
            connections.push(itemBlock.valueConnection_);
            itemBlock = itemBlock.nextConnection &&
                itemBlock.nextConnection.targetBlock();
        }
        // Disconnect any children that don't belong.
        for (var i = 0; i < this.itemCount_; i++) {
            var connection = this.getInput('ADD' + i).connection.targetConnection;
            if (connection && connections.indexOf(connection) == -1) {
                connection.disconnect();
            }
        }
        this.itemCount_ = connections.length;
        this.updateShape_();
        // Reconnect any child blocks.
        for (var i = 0; i < this.itemCount_; i++) {
            Blockly.Mutator.reconnect(connections[i], this, 'ADD' + i);
        }
    },
    /**
     * Store pointers to any connected child blocks.
     * @param {!Blockly.Block} containerBlock Root block in mutator.
     * @this Blockly.Block
     */
    saveConnections: function (containerBlock) {
        var itemBlock = containerBlock.getInputTargetBlock('STACK');
        var i = 0;
        while (itemBlock) {
            var input = this.getInput('ADD' + i);
            itemBlock.valueConnection_ = input && input.connection.targetConnection;
            i++;
            itemBlock = itemBlock.nextConnection &&
                itemBlock.nextConnection.targetBlock();
        }
    },
    /**
     * Modify this block to have the correct number of inputs.
     * @private
     * @this Blockly.Block
     */
    updateShape_: function () {
        if (this.itemCount_ && this.getInput('EMPTY')) {
            this.removeInput('EMPTY');
        } else if (!this.itemCount_ && !this.getInput('EMPTY')) {
            this.appendDummyInput('EMPTY');
            // .appendField(this.newQuote_(true))
            // .appendField(this.newQuote_(false));
        }
        // Add new inputs.
        for (var i = 0; i < this.itemCount_; i++) {
            if (!this.getInput('ADD' + i)) {
                var input = this.appendValueInput('ADD' + i);
                // if (i !==0)
                {
                    // input.appendField(Blockly.Msg.MOTION_TITLE_CREATEWITH);
                    input.appendField(new Blockly.FieldDropdown([
                        [Blockly.Msg.MOTION_MOVECIRCLE_TARGET_POINT, 'TargetP'],
                        [Blockly.Msg.MOTION_MOVECIRCLE_TEMPLE_POINT, 'TempleP'],
                        [Blockly.Msg.MOTION_MOVECIRCLE_RADIUS, 'Radius'],
                        [Blockly.Msg.MOTION_MOVECIRCLE_ANGLERANGE, 'AngleRange'],

                        [Blockly.Msg.MOTION_HEIGHTAVOID, 'HeightAvoid'],
                        [Blockly.Msg.MOTION_MOVE_OFFSET_X, 'I'],
                        [Blockly.Msg.MOTION_MOVE_OFFSET_Y, 'J'],
                        [Blockly.Msg.MOTION_MAXSPEED, 'MaxSpeed'],
                        [Blockly.Msg.MOTION_ENDSPEED, 'EndSpeed'],
                        [Blockly.Msg.MOTION_BUFFER_IO_SET1, 'Buffer_IO_Set1'],//No.Value
                        [Blockly.Msg.MOTION_BUFFER_RATIO1, 'Buffer_IO_Ratio1'],
                        [Blockly.Msg.MOTION_BUFFER_IO_SET2, 'Buffer_IO_Set2'],//No.Value
                        [Blockly.Msg.MOTION_BUFFER_RATIO2, 'Buffer_IO_Ratio2']
                    ]), 'OP' + i);


                }
            }
        }
        // Remove deleted inputs.
        while (this.getInput('ADD' + i)) {
            this.removeInput('ADD' + i);
            i++;
        }
    }
};

Blockly.Constants.Motion.MOTION_MOVECIRCLE_OP_EXTENSION = function () {
    // Add the quote mixin for the itemCount_ = 0 case.
    this.mixin(Blockly.Constants.Motion.QUOTE_IMAGE_MIXIN);
    // initialize the mutator values
    this.itemCount_ = 0;
    this.updateShape_();
    // Configure the mutator ui
    this.setMutator(new Blockly.Mutator(['motion_MoveCircle_op_item']));
};

Blockly.Extensions.registerMutator('motion_MoveCircle_op_mutator',
    Blockly.Constants.Motion.MOTION_MOVECIRCLE_OP_MUTATOR_MIXIN,
    Blockly.Constants.Motion.MOTION_MOVECIRCLE_OP_EXTENSION);






