/**
 * @license
 * Visual Blocks Editor
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
 * @fileoverview Logic blocks for Blockly.
 *
 * This file is scraped to extract a .json file of block definitions. The array
 * passed to defineBlocksWithJsonArray(..) must be strict JSON: double quotes
 * only, no outside references, no functions, no trailing commas, etc. The one
 * exception is end-of-line comments, which the scraper will remove.
 * @author q.neutron@gmail.com (Quynh Neutron)
 */
'use strict';

goog.provide('Blockly.Blocks.logic');  // Deprecated
goog.provide('Blockly.Constants.Logic');

goog.require('Blockly.Blocks');

/**
 * 重新定义block颜色 logic归类到control类型中
 * BKY_LOGIC_HUE  ->  BKY_BLOCK_CONTROL_RGB
 * Msg 中添加 BLOCK_CONTROL_RGB
 */

/**
 * Common HSV hue for all blocks in this category.
 * Should be the same as Blockly.Msg.LOGIC_HUE.
 * @readonly
 */
Blockly.Constants.Logic.HUE = 210;
/** @deprecated Use Blockly.Constants.Logic.HUE */
Blockly.Blocks.logic.HUE = Blockly.Constants.Logic.HUE;

Blockly.defineBlocksWithJsonArray([  // BEGIN JSON EXTRACT
    /** -----------------------------------------------------------Block for Mutators*/
    // Block representing the if statement in the controls_if mutator.
    {
        "type": "controls_if_if",
        "message0": "%{BKY_CONTROLS_IF_IF_TITLE_IF}",
        "nextStatement": null,
        "enableContextMenu": false,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "%{BKY_CONTROLS_IF_IF_TOOLTIP}"
    },
    // Block representing the else-if statement in the controls_if mutator.
    {
        "type": "controls_if_elseif",
        "message0": "%{BKY_CONTROLS_IF_ELSEIF_TITLE_ELSEIF}",
        "previousStatement": null,
        "nextStatement": null,
        "enableContextMenu": false,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "%{BKY_CONTROLS_IF_ELSEIF_TOOLTIP}"
    },
    // Block representing the else statement in the controls_if mutator.
    {
        "type": "controls_if_else",
        "message0": "%{BKY_CONTROLS_IF_ELSE_TITLE_ELSE}",
        "previousStatement": null,
        "enableContextMenu": false,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "%{BKY_CONTROLS_IF_ELSE_TOOLTIP}"
    },

    {
        "type": "logic_create_container",
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
        "type": "logic_op_item",
        "message0": "%{BKY_MOTION_CREATE_ITEM_TITLE_ITEM_COND}",
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "{%BKY_LOGIC_OPERATION_HELPURL}",
        "enableContextMenu": false
    },

    /** -----------------------------------------------------------Block is used*/
    {
        "type": "controls_if",
        "message0": "%{BKY_CONTROLS_IF_MSG_IF} %1",
        "args0": [
            {
                "type": "input_value",
                "name": "IF0",
                "check": "Number"
            }
        ],
        "message1": "%{BKY_CONTROLS_IF_MSG_THEN} %1",
        "args1": [
            {
                "type": "input_statement",
                "name": "DO0"
            }
        ],
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "helpUrl": "%{BKY_CONTROLS_IF_HELPURL}",
         "mutator": "controls_if_mutator",
        "extensions": ["controls_if_tooltip"]
    },
    {
        "type": "logic_operation_m_vertical",
        "message0": "%1 %2",
        "args0": [
            {
                "type": "field_dropdown",
                "name": "OP",
                "options": [
                    ["%{BKY_LOGIC_OPERATION_OR}", "OR"],
                    ["%{BKY_LOGIC_OPERATION_AND}", "AND"]
                ]
            },
            {
                "type": "input_value",
                "name": "A",
                "check": "Number"
            }
        ],
        "output": "Number",
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "helpUrl": "%{BKY_LOGIC_OPERATION_HELPURL}",
        "extensions": ["logic_op_tooltip"],
        //"tooltip": "%{BKY_VARIABLE_GETDATA_TEXT_TOOLTIP}",
        "mutator": "logic_op_mutator"
    },
    {
        "type": "logic_operation_m",
        "message0": "%1 %2",
        "args0": [
            {
                "type": "input_value",
                "name": "A",
                "check": "Number"
            },
            {
                "type": "field_dropdown",
                "name": "OP",
                "options": [
                    ["%{BKY_LOGIC_OPERATION_AND}", "AND"],
                    ["%{BKY_LOGIC_OPERATION_OR}", "OR"]
                ]
            }//,
            // {
            //     "type": "input_value",
            //     "name": "B",
            //     "check": "Boolean"
            // }
        ],
        "inputsInline": true,
        "output": "Number",
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "helpUrl": "%{BKY_LOGIC_OPERATION_HELPURL}",
        "extensions": ["logic_op_tooltip"],
        "mutator": "logic_op_mutator"
    },
    {
        "type": "logic_compare",
        "message0": "%1 %2 %3",
        "args0": [
            {
                "type": "input_value",
                "name": "A",
                "check": "Number"
            },
            {
                "type": "field_dropdown",
                "name": "OP",
                "options": [
                    ["=", "EQ"],
                    ["\u2260", "NEQ"],
                    ["<", "LT"],
                    ["\u2264", "LTE"],
                    [">", "GT"],
                    ["\u2265", "GTE"]
                ]
            },
            {
                "type": "input_value",
                "name": "B",
                "check": "Number"
            }
        ],
        "inputsInline": true,
        "output": "Number",
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "helpUrl": "%{BKY_LOGIC_COMPARE_HELPURL}",
        "extensions": ["logic_compare", "logic_op_tooltip"]
    },
    {
        "type": "logic_boolean",
        "message0": "%1",
        "args0": [
            {
                "type": "field_dropdown",
                "name": "BOOL",
                "options": [
                    ["%{BKY_LOGIC_BOOLEAN_TRUE}", "TRUE"],
                    ["%{BKY_LOGIC_BOOLEAN_FALSE}", "FALSE"]
                ]
            }
        ],
        "output": "Boolean",
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "%{BKY_LOGIC_BOOLEAN_TOOLTIP}",
        "helpUrl": "%{BKY_LOGIC_BOOLEAN_HELPURL}"
    }
]);  // END JSON EXTRACT (Do not delete this comment.)

Blockly.defineBlocksWithJsonArray([  // BEGIN JSON EXTRACT
    /** -----------------------------------------------------------Block is unused*/
    // If/else block that does not use a mutator.
    {
        "type": "controls_ifelse",
        "message0": "%{BKY_CONTROLS_IF_MSG_IF} %1",
        "args0": [
            {
                "type": "input_value",
                "name": "IF0",
                "check": "Boolean"
            }
        ],
        "message1": "%{BKY_CONTROLS_IF_MSG_THEN} %1",
        "args1": [
            {
                "type": "input_statement",
                "name": "DO0"
            }
        ],
        "message2": "%{BKY_CONTROLS_IF_MSG_ELSE} %1",
        "args2": [
            {
                "type": "input_statement",
                "name": "ELSE"
            }
        ],
        "previousStatement": null,
        "nextStatement": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "%{BKYCONTROLS_IF_TOOLTIP_2}",
        "helpUrl": "%{BKY_CONTROLS_IF_HELPURL}",
        "extensions": ["controls_if_tooltip"]
    },
    // Block for null data type.
    {
        "type": "logic_null",
        "message0": "%{BKY_LOGIC_NULL}",
        "output": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "%{BKY_LOGIC_NULL_TOOLTIP}",
        "helpUrl": "%{BKY_LOGIC_NULL_HELPURL}"
    },
    // Block for ternary operator.
    {
        "type": "logic_ternary",
        "message0": "%{BKY_LOGIC_TERNARY_CONDITION} %1",
        "args0": [
            {
                "type": "input_value",
                "name": "IF",
                "check": "Boolean"
            }
        ],
        "message1": "%{BKY_LOGIC_TERNARY_IF_TRUE} %1",
        "args1": [
            {
                "type": "input_value",
                "name": "THEN"
            }
        ],
        "message2": "%{BKY_LOGIC_TERNARY_IF_FALSE} %1",
        "args2": [
            {
                "type": "input_value",
                "name": "ELSE"
            }
        ],
        "output": null,
        "colour": "%{BKY_BLOCK_CONTROL_RGB}",
        "tooltip": "%{BKY_LOGIC_TERNARY_TOOLTIP}",
        "helpUrl": "%{BKY_LOGIC_TERNARY_HELPURL}",
        "extensions": ["logic_ternary"]
    }
]);  // END JSON EXTRACT (Do not delete this comment.)

/**
 * Tooltip text, keyed by block OP value. Used by logic_compare and
 * logic_operation blocks.
 * @see {Blockly.Extensions#buildTooltipForDropdown}
 * @package
 * @readonly
 */
Blockly.Constants.Logic.TOOLTIPS_BY_OP = {
  // logic_compare
  'EQ': '%{BKY_LOGIC_COMPARE_TOOLTIP_EQ}',
  'NEQ': '%{BKY_LOGIC_COMPARE_TOOLTIP_NEQ}',
  'LT': '%{BKY_LOGIC_COMPARE_TOOLTIP_LT}',
  'LTE': '%{BKY_LOGIC_COMPARE_TOOLTIP_LTE}',
  'GT': '%{BKY_LOGIC_COMPARE_TOOLTIP_GT}',
  'GTE': '%{BKY_LOGIC_COMPARE_TOOLTIP_GTE}',

  // logic_operation
  'AND': '%{BKY_LOGIC_OPERATION_TOOLTIP_AND}',
  'OR': '%{BKY_LOGIC_OPERATION_TOOLTIP_OR}'
};

Blockly.Extensions.register('logic_op_tooltip',
  Blockly.Extensions.buildTooltipForDropdown(
    'OP', Blockly.Constants.Logic.TOOLTIPS_BY_OP));

/**
 * Mutator methods added to controls_if blocks.
 * @mixin
 * @augments Blockly.Block
 * @package
 * @readonly
 */
Blockly.Constants.Logic.CONTROLS_IF_MUTATOR_MIXIN = {
  elseifCount_: 0,
  elseCount_: 0,

  /**
   * Create XML to represent the number of else-if and else inputs.
   * @return {Element} XML storage element.
   * @this Blockly.Block
   */
  mutationToDom: function() {
    if (!this.elseifCount_ && !this.elseCount_) {
      return null;
    }
    var container = document.createElement('mutation');
    if (this.elseifCount_) {
      container.setAttribute('elseif', this.elseifCount_);
    }
    if (this.elseCount_) {
      container.setAttribute('else', 1);
    }
    return container;
  },
  /**
   * Parse XML to restore the else-if and else inputs.
   * @param {!Element} xmlElement XML storage element.
   * @this Blockly.Block
   */
  domToMutation: function(xmlElement) {
    this.elseifCount_ = parseInt(xmlElement.getAttribute('elseif'), 10) || 0;
    this.elseCount_ = parseInt(xmlElement.getAttribute('else'), 10) || 0;
    this.updateShape_();
  },
  /**
   * Populate the mutator's dialog with this block's components.
   * @param {!Blockly.Workspace} workspace Mutator's workspace.
   * @return {!Blockly.Block} Root block in mutator.
   * @this Blockly.Block
   */
  decompose: function(workspace) {
    var containerBlock = workspace.newBlock('controls_if_if');
    containerBlock.initSvg();
    var connection = containerBlock.nextConnection;
    for (var i = 1; i <= this.elseifCount_; i++) {
      var elseifBlock = workspace.newBlock('controls_if_elseif');
      elseifBlock.initSvg();
      connection.connect(elseifBlock.previousConnection);
      connection = elseifBlock.nextConnection;
    }
    if (this.elseCount_) {
      var elseBlock = workspace.newBlock('controls_if_else');
      elseBlock.initSvg();
      connection.connect(elseBlock.previousConnection);
    }
    return containerBlock;
  },
  /**
   * Reconfigure this block based on the mutator dialog's components.
   * @param {!Blockly.Block} containerBlock Root block in mutator.
   * @this Blockly.Block
   */
  compose: function(containerBlock) {
    var clauseBlock = containerBlock.nextConnection.targetBlock();
    // Count number of inputs.
    this.elseifCount_ = 0;
    this.elseCount_ = 0;
    var valueConnections = [null];
    var statementConnections = [null];
    var elseStatementConnection = null;
    while (clauseBlock) {
      switch (clauseBlock.type) {
        case 'controls_if_elseif':
          this.elseifCount_++;
          valueConnections.push(clauseBlock.valueConnection_);
          statementConnections.push(clauseBlock.statementConnection_);
          break;
        case 'controls_if_else':
          this.elseCount_++;
          elseStatementConnection = clauseBlock.statementConnection_;
          break;
        default:
          throw 'Unknown block type.';
      }
      clauseBlock = clauseBlock.nextConnection &&
          clauseBlock.nextConnection.targetBlock();
    }
    this.updateShape_();
    // Reconnect any child blocks.
    for (var i = 1; i <= this.elseifCount_; i++) {
      Blockly.Mutator.reconnect(valueConnections[i], this, 'IF' + i);
      Blockly.Mutator.reconnect(statementConnections[i], this, 'DO' + i);
    }
    Blockly.Mutator.reconnect(elseStatementConnection, this, 'ELSE');
  },
  /**
   * Store pointers to any connected child blocks.
   * @param {!Blockly.Block} containerBlock Root block in mutator.
   * @this Blockly.Block
   */
  saveConnections: function(containerBlock) {
    var clauseBlock = containerBlock.nextConnection.targetBlock();
    var i = 1;
    while (clauseBlock) {
      switch (clauseBlock.type) {
        case 'controls_if_elseif':
          var inputIf = this.getInput('IF' + i);
          var inputDo = this.getInput('DO' + i);
          clauseBlock.valueConnection_ =
              inputIf && inputIf.connection.targetConnection;
          clauseBlock.statementConnection_ =
              inputDo && inputDo.connection.targetConnection;
          i++;
          break;
        case 'controls_if_else':
          var inputDo = this.getInput('ELSE');
          clauseBlock.statementConnection_ =
              inputDo && inputDo.connection.targetConnection;
          break;
        default:
          throw 'Unknown block type.';
      }
      clauseBlock = clauseBlock.nextConnection &&
          clauseBlock.nextConnection.targetBlock();
    }
  },
  /**
   * Modify this block to have the correct number of inputs.
   * @this Blockly.Block
   * @private
   */
  updateShape_: function() {
    // Delete everything.
    if (this.getInput('ELSE')) {
      this.removeInput('ELSE');
    }
    var i = 1;
    while (this.getInput('IF' + i)) {
      this.removeInput('IF' + i);
      this.removeInput('DO' + i);
      i++;
    }
    // Rebuild block.
    for (var i = 1; i <= this.elseifCount_; i++) {
      this.appendValueInput('IF' + i)
          .setCheck('Boolean')
          .appendField(Blockly.Msg.CONTROLS_IF_MSG_ELSEIF);
      this.appendStatementInput('DO' + i)
          .appendField(Blockly.Msg.CONTROLS_IF_MSG_THEN);
    }
    if (this.elseCount_) {
      this.appendStatementInput('ELSE')
          .appendField(Blockly.Msg.CONTROLS_IF_MSG_ELSE);
    }
  }
};

Blockly.Extensions.registerMutator('controls_if_mutator',
    Blockly.Constants.Logic.CONTROLS_IF_MUTATOR_MIXIN, null,
    // ['controls_if_elseif', 'controls_if_else']);
    ['controls_if_else']);
/**
 * "controls_if" extension function. Adds mutator, shape updating methods, and
 * dynamic tooltip to "controls_if" blocks.
 * @this Blockly.Block
 * @package
 */
Blockly.Constants.Logic.CONTROLS_IF_TOOLTIP_EXTENSION = function() {

  this.setTooltip(function() {
    if (!this.elseifCount_ && !this.elseCount_) {
      return Blockly.Msg.CONTROLS_IF_TOOLTIP_1;
    } else if (!this.elseifCount_ && this.elseCount_) {
      return Blockly.Msg.CONTROLS_IF_TOOLTIP_2;
    } else if (this.elseifCount_ && !this.elseCount_) {
      return Blockly.Msg.CONTROLS_IF_TOOLTIP_3;
    } else if (this.elseifCount_ && this.elseCount_) {
      return Blockly.Msg.CONTROLS_IF_TOOLTIP_4;
    }
    return '';
  }.bind(this));
};

Blockly.Extensions.register('controls_if_tooltip',
  Blockly.Constants.Logic.CONTROLS_IF_TOOLTIP_EXTENSION);

/**
 * Corrects the logic_compare dropdown label with respect to language direction.
 * @this Blockly.Block
 * @package
 */
Blockly.Constants.Logic.fixLogicCompareRtlOpLabels =
  function() {
    var rtlOpLabels = {
      'LT': '\u200F<\u200F',
      'LTE': '\u200F\u2264\u200F',
      'GT': '\u200F>\u200F',
      'GTE': '\u200F\u2265\u200F'
    };
    var opDropdown = this.getField('OP');
    if (opDropdown) {
      var options = opDropdown.getOptions();
      for (var i = 0; i < options.length; ++i) {
        var tuple = options[i];
        var op = tuple[1];
        var rtlLabel = rtlOpLabels[op];
        if (goog.isString(tuple[0]) && rtlLabel) {
          // Replace LTR text label
          tuple[0] = rtlLabel;
        }
      }
    }
  };

/**
 * Adds dynamic type validation for the left and right sides of a logic_compare block.
 * @mixin
 * @augments Blockly.Block
 * @package
 * @readonly
 */
Blockly.Constants.Logic.LOGIC_COMPARE_ONCHANGE_MIXIN = {
  prevBlocks_: [null, null],

  /**
   * Called whenever anything on the workspace changes.
   * Prevent mismatched types from being compared.
   * @param {!Blockly.Events.Abstract} e Change event.
   * @this Blockly.Block
   */
  onchange: function(e) {
    var blockA = this.getInputTargetBlock('A');
    var blockB = this.getInputTargetBlock('B');
    // Disconnect blocks that existed prior to this change if they don't match.
    if (blockA && blockB &&
        !blockA.outputConnection.checkType_(blockB.outputConnection)) {
      // Mismatch between two inputs.  Disconnect previous and bump it away.
      // Ensure that any disconnections are grouped with the causing event.
      Blockly.Events.setGroup(e.group);
      for (var i = 0; i < this.prevBlocks_.length; i++) {
        var block = this.prevBlocks_[i];
        if (block === blockA || block === blockB) {
          block.unplug();
          block.bumpNeighbours_();
        }
      }
      Blockly.Events.setGroup(false);
    }
    this.prevBlocks_[0] = blockA;
    this.prevBlocks_[1] = blockB;
  }
};

/**
 * "logic_compare" extension function. Corrects direction of operators in the
 * dropdown labels, and adds type left and right side type checking to
 * "logic_compare" blocks.
 * @this Blockly.Block
 * @package
 * @readonly
 */
Blockly.Constants.Logic.LOGIC_COMPARE_EXTENSION = function() {
  // Fix operator labels in RTL
  if (this.RTL) {
    Blockly.Constants.Logic.fixLogicCompareRtlOpLabels.apply(this);
  }

  // Add onchange handler to ensure types are compatable.
  this.mixin(Blockly.Constants.Logic.LOGIC_COMPARE_ONCHANGE_MIXIN);
};

Blockly.Extensions.register('logic_compare',
  Blockly.Constants.Logic.LOGIC_COMPARE_EXTENSION);

/**
 * Adds type coordination between inputs and output.
 * @mixin
 * @augments Blockly.Block
 * @package
 * @readonly
 */
Blockly.Constants.Logic.LOGIC_TERNARY_ONCHANGE_MIXIN = {
  prevParentConnection_: null,

  /**
   * Called whenever anything on the workspace changes.
   * Prevent mismatched types.
   * @param {!Blockly.Events.Abstract} e Change event.
   * @this Blockly.Block
   */
  onchange: function(e) {
    var blockA = this.getInputTargetBlock('THEN');
    var blockB = this.getInputTargetBlock('ELSE');
    var parentConnection = this.outputConnection.targetConnection;
    // Disconnect blocks that existed prior to this change if they don't match.
    if ((blockA || blockB) && parentConnection) {
      for (var i = 0; i < 2; i++) {
        var block = (i == 1) ? blockA : blockB;
        if (block && !block.outputConnection.checkType_(parentConnection)) {
          // Ensure that any disconnections are grouped with the causing event.
          Blockly.Events.setGroup(e.group);
          if (parentConnection === this.prevParentConnection_) {
            this.unplug();
            parentConnection.getSourceBlock().bumpNeighbours_();
          } else {
            block.unplug();
            block.bumpNeighbours_();
          }
          Blockly.Events.setGroup(false);
        }
      }
    }
    this.prevParentConnection_ = parentConnection;
  }
};

Blockly.Extensions.registerMixin('logic_ternary',
  Blockly.Constants.Logic.LOGIC_TERNARY_ONCHANGE_MIXIN);

/**
 *
 * @mixin
 * @package
 * @readonly
 */
Blockly.Constants.Logic.QUOTE_IMAGE_MIXIN = {
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
    quoteField_: function(fieldName) {
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
     * @param {boolean} open If the image should be open quote (“ in LTR).
     *                       Otherwise, a closing quote is used (” in LTR).
     * @returns {!Blockly.FieldImage} The new field.
     */
    newQuote_: function(open) {
        var isLeft = this.RTL? !open : open;
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

// Performs final setup of a text_join block.
Blockly.Constants.Logic.LOGIC_OP_EXTENSION = function() {
    // Add the quote mixin for the itemCount_ = 0 case.
    this.mixin(Blockly.Constants.Logic.QUOTE_IMAGE_MIXIN);
    // initialize the mutator values
    this.itemCount_ = 1;
    this.updateShape_();
    // Configure the mutator ui
    this.setMutator(new Blockly.Mutator(['logic_op_item']));
};

/**
 * Mixin for mutator functions in the 'logic_op_mutator' extension.
 * @mixin
 * @augments Blockly.Block
 * @package
 */
Blockly.Constants.Logic.LOGIC_OP_MUTATOR_MIXIN = {
    /**
     * Create XML to represent number of text inputs.
     * @return {!Element} XML storage element.
     * @this Blockly.Block
     */
    mutationToDom: function() {
        var container = document.createElement('mutation');
        container.setAttribute('items', this.itemCount_);
        return container;
    },
    /**
     * Parse XML to restore the text inputs.
     * @param {!Element} xmlElement XML storage element.
     * @this Blockly.Block
     */
    domToMutation: function(xmlElement) {
        this.itemCount_ = parseInt(xmlElement.getAttribute('items'), 10);
        this.updateShape_();
    },
    /**
     * Populate the mutator's dialog with this block's components.
     * @param {!Blockly.Workspace} workspace Mutator's workspace.
     * @return {!Blockly.Block} Root block in mutator.
     * @this Blockly.Block
     */
    decompose: function(workspace) {
        var containerBlock = workspace.newBlock('logic_create_container');
        containerBlock.initSvg();
        var connection = containerBlock.getInput('STACK').connection;
        for (var i = 0; i < this.itemCount_; i++) {
            var itemBlock = workspace.newBlock('logic_op_item');1
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
    compose: function(containerBlock) {
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
    saveConnections: function(containerBlock) {
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
    updateShape_: function() {
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
                if (i !==0) {
                    // input.appendField(Blockly.Msg.MOTION_TITLE_CREATEWITH);
                    input.appendField(new Blockly.FieldDropdown([[Blockly.Msg.LOGIC_OPERATION_AND, 'AND'],
                        [Blockly.Msg.LOGIC_OPERATION_OR, 'OR']]),'OP'+i);
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


Blockly.Extensions.registerMutator('logic_op_mutator',
    Blockly.Constants.Logic.LOGIC_OP_MUTATOR_MIXIN,
    Blockly.Constants.Logic.LOGIC_OP_EXTENSION);