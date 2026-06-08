/**
 * @fileoverview Loop blocks for Blockly.
 *
 * This file is scraped to extract a .json file of block definitions. The array
 * passed to defineBlocksWithJsonArray(..) must be strict JSON: double quotes
 * only, no outside references, no functions, no trailing commas, etc. The one
 * exception is end-of-line comments, which the scraper will remove.
 * @author fraser@google.com (Neil Fraser)
 */
'use strict';

goog.provide('Blockly.Blocks.event');  // Deprecated
goog.provide('Blockly.Constants.Event');

goog.require('Blockly.Blocks');

/**
 * Common HSV hue for all blocks in this category.
 * Should be the same as Blockly.Msg.LOOPS_HUE
 * @readonly
 */
Blockly.Constants.Event.HUE = 120;