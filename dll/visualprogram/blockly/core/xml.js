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
 * @fileoverview XML reader and writer.
 * @author fraser@google.com (Neil Fraser)
 */
'use strict';

/**
 * @name Blockly.Xml
 * @namespace
 **/
goog.provide('Blockly.Xml');

goog.require('goog.asserts');
goog.require('goog.dom');


/**
 * Encode a block tree as XML.
 * @param {!Blockly.Workspace} workspace The workspace containing blocks.
 * @param {boolean} opt_noId True if the encoder should skip the block ids.
 * @return {!Element} XML document.
 */
Blockly.Xml.workspaceToDom = function (workspace, opt_noId) {
  var xml = goog.dom.createDom('xml');
  xml.appendChild(Blockly.Xml.variablesToDom(workspace.getAllVariables()));
  var blocks = workspace.getTopBlocks(true);
  for (var i = 0, block; block = blocks[i]; i++) {
    xml.appendChild(Blockly.Xml.blockToDomWithXY(block, opt_noId));
  }
  return xml;
};


/**
 * ���ݹؼ�������һ��x��y����������
 * @param {!Blockly.Block} block The root block to encode.
 * @param {boolean} opt_noId True if the encoder should skip the block id.
 * @param {string} key_word .�����ؼ���
 * @return {!Element} Tree of XML elements.
 */
Blockly.Xml.normalizeSearchToken_ = function (raw) {
  var key = String(raw == null ? '' : raw);
  key = key.replace('ADD', '');
  key = key.replace('MINUS', '');
  key = key.replace('MULTIPLY', '');
  key = key.replace('DIVIDE', '');
  key = key.replace('MODULO', '');
  key = key.replace('BITAND', '');
  key = key.replace('BITOR', '');
  key = key.replace('BITXOR', '');
  key = key.replace('LeftShift', '');
  key = key.replace('RightShift', '');
  key = key.replace('LOOP', '');
  key = key.replace('=', '');
  key = key.replace('UP', '');
  key = key.replace('OFF', '');
  key = key.replace('DN', '');
  key = key.replace('AND', '');
  key = key.replace('OR', '');
  key = key.replace('NEQ', '');
  key = key.replace('GTE', '');
  key = key.replace('LTE', '');
  key = key.replace('EQ', '');
  key = key.replace('LT', '');
  key = key.replace('GT', '');
  key = key.replace('DD', 'D');
  key = key.replace('DS', 'S');
  key = key.replace('SD', 'D');
  key = key.replace('SS', 'S');
  key = key.replace(/[\u4e00-\u9fff]/g, '');
  key = key.replace('MD', 'D');
  key = key.replace('VD', 'D');
  key = key.replace('TD', 'D');
  key = key.replace('XD', 'D');
  key = key.replace('YD', 'D');
  key = key.replace('ID', 'D');
  key = key.replace('JD', 'D');
  key = key.replace('KD', 'D');
  key = key.replace('WD', 'D');
  key = key.replace('CD', 'D');
  key = key.replace('MS', 'S');
  key = key.replace('VS', 'S');
  key = key.replace('TS', 'S');
  key = key.replace('XS', 'S');
  key = key.replace('YS', 'S');
  key = key.replace('IS', 'S');
  key = key.replace('JS', 'S');
  key = key.replace('KS', 'S');
  key = key.replace('WS', 'S');
  key = key.replace('CS', 'S');
  return key.toUpperCase();
};

/** @const {!Array.<string>} 寄存器前缀（长前缀在前）。 */
Blockly.Xml.REGISTER_PREFIXES_ = [
  'PX', 'PY', 'PZ', 'PW', 'U1', 'U2', 'U3', 'U4',
  'D', 'V', 'I', 'J', 'K', 'W', 'X', 'Y', 'M', 'S', 'T', 'C'
];

/** @const {!RegExp} 从文本中提取寄存器 token。 */
Blockly.Xml.REGISTER_TOKEN_RE_ =
    /(PX|PY|PZ|PW|U[1-4]|D|V|I|J|K|W|X|Y|M|S|T|C)(\d+)/g;

/** @const {!RegExp} 判断关键字是否为寄存器精确搜索（如 D40、D400）。 */
Blockly.Xml.REGISTER_KEYWORD_RE_ =
    /^(PX|PY|PZ|PW|U[1-4]|D|V|I|J|K|W|X|Y|M|S|T|C)(\d+)$/;

/**
 * 解析寄存器搜索关键字；非寄存器格式返回 null。
 * @param {string} key_word
 * @return {?string} 规范化后的寄存器 token，如 D400
 */
Blockly.Xml.parseRegisterSearchKeyword_ = function (key_word) {
  var compact = String(key_word == null ? '' : key_word).replace(/\s+/g, '');
  if (!compact) {
    return null;
  }
  var normalized = Blockly.Xml.normalizeSearchToken_(compact);
  if (Blockly.Xml.REGISTER_KEYWORD_RE_.test(normalized)) {
    return normalized;
  }
  return null;
};

/**
 * 从块文本中提取全部寄存器 token。
 * @param {string} text
 * @return {!Array.<string>}
 */
Blockly.Xml.extractRegisterTokensFromText_ = function (text) {
  var compact = Blockly.Xml.normalizeSearchToken_(
      String(text == null ? '' : text).replace(/\s+/g, ''));
  var tokens = [];
  var re = new RegExp(Blockly.Xml.REGISTER_TOKEN_RE_.source, 'g');
  var match;
  while ((match = re.exec(compact)) !== null) {
    tokens.push(match[1] + match[2]);
  }
  return tokens;
};

/**
 * 文本中是否包含与关键字完全一致的寄存器 token。
 * @param {string} text
 * @param {string} registerKeyword 已规范化的寄存器关键字
 * @return {boolean}
 */
Blockly.Xml.textHasExactRegister_ = function (text, registerKeyword) {
  var found = Blockly.Xml.extractRegisterTokensFromText_(text);
  for (var i = 0; i < found.length; i++) {
    if (found[i] === registerKeyword) {
      return true;
    }
  }
  return false;
};

Blockly.Xml.fieldSearchText_ = function (field) {
  try {
    if (field.getValue !== undefined && field.getValue !== null &&
        String(field.getValue()) !== '') {
      return String(field.getValue());
    }
    if (field.getText) {
      return String(field.getText());
    }
  } catch (e) {}
  return '';
};

/**
 * Value 输入槽内连接块的可搜索字段（含 shadow），不遍历 statement 链。
 * @param {!Blockly.Block} block
 * @return {!Array.<string>}
 * @private
 */
Blockly.Xml.getValueInputSearchTokens_ = function (block) {
  var tokens = [];
  for (var i = 0, input; input = block.inputList[i]; i++) {
    for (var j = 0, field; field = input.fieldRow[j]; j++) {
      var part = Blockly.Xml.fieldSearchText_(field);
      if (part) {
        tokens.push(part);
      }
    }
    if (input.type === Blockly.INPUT_VALUE && input.connection) {
      var child = input.connection.targetBlock();
      if (child) {
        tokens = tokens.concat(Blockly.Xml.getValueInputSearchTokens_(child));
      }
    }
  }
  return tokens;
};

/**
 * 单块按显示顺序的可搜索 token（含 value 输入子块，如 D + 0 => D0）。
 * 折叠块仅用折叠摘要行，避免与隐藏输入重复。
 * @param {!Blockly.Block} block
 * @return {!Array.<string>}
 * @private
 */
Blockly.Xml.getBlockSearchTokens_ = function (block) {
  var tokens = [];
  if (!block) {
    return tokens;
  }
  if (block.isCollapsed()) {
    var collapsedInput = block.getInput('_TEMP_COLLAPSED_INPUT');
    if (collapsedInput) {
      for (var c = 0, cField; cField = collapsedInput.fieldRow[c]; c++) {
        var collapsedPart = Blockly.Xml.fieldSearchText_(cField);
        if (collapsedPart) {
          tokens.push(collapsedPart);
        }
      }
    }
    if (tokens.length) {
      return tokens;
    }
  }
  for (var i = 0, input; input = block.inputList[i]; i++) {
    if (input.name === '_TEMP_COLLAPSED_INPUT') {
      continue;
    }
    for (var j = 0, field; field = input.fieldRow[j]; j++) {
      var ownPart = Blockly.Xml.fieldSearchText_(field);
      if (ownPart) {
        tokens.push(ownPart);
      }
    }
    if (input.type === Blockly.INPUT_VALUE && input.connection) {
      var connected = input.connection.targetBlock();
      if (connected) {
        tokens = tokens.concat(
            Blockly.Xml.getValueInputSearchTokens_(connected));
      }
    }
  }
  return tokens;
};

Blockly.Xml.search_MD_XY_pushMatch_ = function (block) {
  var tem_data = [block.workspace.temp_xy[0], block.workspace.temp_xy[1]];
  block.workspace.search_.push(tem_data);
  block.workspace.search_head_index.push(block.workspace.search_head_index_num);
  if (block.workspace.search_blocks_) {
    block.workspace.search_blocks_.push(block);
  }
};

/**
 * block 是否为 ancestor 的 value 输入子块或语句槽内嵌套块。
 * 不含 next/previous 语句栈上的前后相邻块（避免误删独立语句）。
 * @param {!Blockly.Block} ancestor
 * @param {!Blockly.Block} block
 * @return {boolean}
 * @private
 */
Blockly.Xml.isSearchBlockAncestor_ = function (ancestor, block) {
  if (!ancestor || !block || ancestor === block) {
    return false;
  }
  var surround = block.getSurroundParent();
  while (surround) {
    if (surround === ancestor) {
      return true;
    }
    surround = surround.getSurroundParent();
  }
  var cur = block;
  var parent = cur.getParent();
  while (parent) {
    if (parent.getInputWithBlock(cur)) {
      if (parent === ancestor) {
        return true;
      }
      cur = parent;
      parent = cur.getParent();
    } else {
      break;
    }
  }
  return false;
};

/**
 * 合并嵌套重复：同一 value/语句嵌套链上父子均命中时，保留最内层块。
 * @param {!Blockly.Workspace} workspace
 */
Blockly.Xml.deduplicateSearchMatches_ = function (workspace) {
  var blocks = workspace.search_blocks_;
  if (!blocks || blocks.length < 2) {
    return;
  }
  var removeSet = {};
  for (var i = 0; i < blocks.length; i++) {
    for (var j = 0; j < blocks.length; j++) {
      if (i !== j &&
          Blockly.Xml.isSearchBlockAncestor_(blocks[i], blocks[j])) {
        removeSet[blocks[i].id] = true;
        break;
      }
    }
  }
  for (var k = blocks.length - 1; k >= 0; k--) {
    if (removeSet[blocks[k].id]) {
      blocks.splice(k, 1);
      workspace.search_.splice(k, 1);
      workspace.search_head_index.splice(k, 1);
    }
  }
};

/**
 * 块是否匹配关键字（含 D400 等变量 token 与中文块名）。
 * @param {!Blockly.Block} block
 * @param {string} key_word
 * @return {boolean}
 * @private
 */
Blockly.Xml.blockMatchesKeyword_ = function (block, key_word) {
  if (!key_word || block.isShadow()) {
    return false;
  }
  var registerKeyword = Blockly.Xml.parseRegisterSearchKeyword_(key_word);
  if (registerKeyword) {
    var tokenText = Blockly.Xml.getBlockSearchTokens_(block).join(' ');
    if (Blockly.Xml.textHasExactRegister_(tokenText, registerKeyword)) {
      return true;
    }
    if (block.toString &&
        Blockly.Xml.textHasExactRegister_(block.toString(80), registerKeyword)) {
      return true;
    }
    return false;
  }

  var compactKeyword = key_word.replace(/\s+/g, '');
  var tokens = Blockly.Xml.getBlockSearchTokens_(block);
  var blockOwnText = tokens.join(' ');
  var compactOwnText = blockOwnText.replace(/\s+/g, '');
  if (blockOwnText.indexOf(key_word) !== -1 ||
      (compactKeyword && compactOwnText.indexOf(compactKeyword) !== -1)) {
    return true;
  }

  if (block.toString) {
    var fullText = block.toString(80);
    var compactFull = fullText.replace(/\s+/g, '');
    if (fullText.indexOf(key_word) !== -1 ||
        (compactKeyword && compactFull.indexOf(compactKeyword) !== -1)) {
      return true;
    }
  }
  return false;
};

Blockly.Xml.search_MD_XY_matchBlock_ = function (block, opt_noId, key_word) {
  var matched = false;
  var pushMatch = function () {
    if (matched) {
      return;
    }
    matched = true;
    Blockly.Xml.search_MD_XY_pushMatch_(block);
  };
  //�����block��ͷ��  �Һ��涼Ҫ��������
  var x = 0, y = 0;
  var key_word_first = '';
  //�ж��Ƿ����key_word�ǿ�  ���Ϊ���򲻴���
  if (typeof key_word == 'string' && key_word.length > 0) {
    //alert(key_word.length+"=======");
  }


  if (!block.isShadow()) {
    var xy = block.getRelativeToSurfaceXY();
    x = Math.round(block.workspace.RTL ? width - xy.x : xy.x);
    y = Math.round(xy.y);
  }
  if (!block.workspace.block_bool_xy) {
    block.workspace.block_bool_xy = true;
    block.workspace.head_xy = [x, y];
  }

  if (x < block.workspace.head_xy[0]) block.workspace.head_xy[0] = x;


  if (x < block.workspace.head_xy[0]) block.workspace.head_xy[0] = x;
  if (x + y != 0) {
    block.workspace.temp_xy[0] = x;
    block.workspace.temp_xy[1] = y;
  }
  //alert("x:"+x+" ;y:"+y);

  if (typeof key_word === 'string' && key_word.length > 0 &&
      Blockly.Xml.blockMatchesKeyword_(block, key_word)) {
    pushMatch();
  }

  var last_key = '';
  var tem_key = '';
  function fieldToDom(field) {
    if (field.name && field.EDITABLE) {
      var container = goog.dom.createDom('field', null, field.getValue());
    }
  }
  var registerKeyword = Blockly.Xml.parseRegisterSearchKeyword_(key_word);
  var keywordUpper = typeof key_word === 'string' ?
      Blockly.Xml.normalizeSearchToken_(key_word.replace(/\s+/g, '')) : '';
  if (true) {
    if (block.type != "math_variableNotes") {//把注释排除
      var searchTokens = Blockly.Xml.getBlockSearchTokens_(block);
      for (var j = 0; j < searchTokens.length; j++) {
          // fieldToDom(field);
          tem_key = last_key + searchTokens[j];

          //alert("last_key:"+last_key+" ;field.getValue():"+field.getValue());
          tem_key = tem_key.replace("ADD", "");
          tem_key = tem_key.replace("MINUS", "");
          tem_key = tem_key.replace("MULTIPLY", "");
          tem_key = tem_key.replace("DIVIDE", "");
          tem_key = tem_key.replace("MODULO", "");
          tem_key = tem_key.replace("BITAND", "");

          tem_key = tem_key.replace("BITOR", "");
          tem_key = tem_key.replace("BITXOR", "");
          tem_key = tem_key.replace("LeftShift", "");
          tem_key = tem_key.replace("RightShift", "");
          tem_key = tem_key.replace("LOOP", "");

          tem_key = tem_key.replace("=", "");
          tem_key = tem_key.replace("UP", "");
          tem_key = tem_key.replace("OFF", "");
          tem_key = tem_key.replace("DN", "");


          tem_key = tem_key.replace("AND", "");
          tem_key = tem_key.replace("OR", "");

          tem_key = tem_key.replace("NEQ", "");
          tem_key = tem_key.replace("GTE", "");
          tem_key = tem_key.replace("LTE", "");
          tem_key = tem_key.replace("EQ", "");
          tem_key = tem_key.replace("LT", "");
          tem_key = tem_key.replace("GT", "");


          tem_key = tem_key.replace("DD", "D");
          tem_key = tem_key.replace("DS", "S");
          tem_key = tem_key.replace("SD", "D");
          tem_key = tem_key.replace("SS", "S");


          tem_key = tem_key.replace(/[\u4e00-\u9fff]/g, ""); // 关键修改：去除所有中文字符

          last_key = searchTokens[j];
          last_key = last_key ? last_key.charAt(0) : '';

          var pureNumber = /^\d+$/.test(tem_key);
          if (pureNumber) {
            block.workspace.code_serch += tem_key;
          } else {
            block.workspace.code_serch = "";
          }

          block.workspace.code_serch = block.workspace.code_serch.replace("DD", "D");
          block.workspace.code_serch = block.workspace.code_serch.replace("MD", "D");
          block.workspace.code_serch = block.workspace.code_serch.replace("VD", "D");
          block.workspace.code_serch = block.workspace.code_serch.replace("TD", "D");
          block.workspace.code_serch = block.workspace.code_serch.replace("XD", "D");
          block.workspace.code_serch = block.workspace.code_serch.replace("YD", "D");
          block.workspace.code_serch = block.workspace.code_serch.replace("SD", "D");
          block.workspace.code_serch = block.workspace.code_serch.replace("ID", "D");
          block.workspace.code_serch = block.workspace.code_serch.replace("JD", "D");
          block.workspace.code_serch = block.workspace.code_serch.replace("KD", "D");
          block.workspace.code_serch = block.workspace.code_serch.replace("WD", "D");
          block.workspace.code_serch = block.workspace.code_serch.replace("CD", "D");

          block.workspace.code_serch = block.workspace.code_serch.replace("DS", "S");
          block.workspace.code_serch = block.workspace.code_serch.replace("MS", "S");
          block.workspace.code_serch = block.workspace.code_serch.replace("VS", "S");
          block.workspace.code_serch = block.workspace.code_serch.replace("TS", "S");
          block.workspace.code_serch = block.workspace.code_serch.replace("XS", "S");
          block.workspace.code_serch = block.workspace.code_serch.replace("YS", "S");
          block.workspace.code_serch = block.workspace.code_serch.replace("SS", "S");
          block.workspace.code_serch = block.workspace.code_serch.replace("IS", "S");
          block.workspace.code_serch = block.workspace.code_serch.replace("JS", "S");
          block.workspace.code_serch = block.workspace.code_serch.replace("KS", "S");
          block.workspace.code_serch = block.workspace.code_serch.replace("WS", "S");
          block.workspace.code_serch = block.workspace.code_serch.replace("CS", "S");

          if (registerKeyword) {
            if (Blockly.Xml.normalizeSearchToken_(tem_key) === registerKeyword) {
              pushMatch();
            }
            if (Blockly.Xml.normalizeSearchToken_(block.workspace.code_serch) ===
                registerKeyword) {
              pushMatch();
            }
          } else if (keywordUpper &&
              Blockly.Xml.normalizeSearchToken_(tem_key) === keywordUpper) {
            pushMatch();
          } else if (keywordUpper &&
              Blockly.Xml.normalizeSearchToken_(block.workspace.code_serch) ===
              keywordUpper) {
            pushMatch();
          }
      }

    }

  }
  var pureNumber = /^\d+$/.test(tem_key);
  if (!pureNumber) {
    block.workspace.code_serch += tem_key;
  } else {
    block.workspace.code_serch = "";
  }
  if (!matched && registerKeyword) {
    if (Blockly.Xml.normalizeSearchToken_(tem_key) === registerKeyword ||
        Blockly.Xml.normalizeSearchToken_(block.workspace.code_serch) ===
        registerKeyword) {
      pushMatch();
    }
  } else if (!matched && keywordUpper) {
    if (Blockly.Xml.normalizeSearchToken_(tem_key) === keywordUpper ||
        Blockly.Xml.normalizeSearchToken_(block.workspace.code_serch) ===
        keywordUpper) {
      pushMatch();
    }
  }
};

/**
 * 按关键字搜索块树；始终遍历 getDescendants，折叠块内子块也计入个数。
 */
Blockly.Xml.search_MD_XY = function (block, opt_noId, key_word) {
  var descendants = block.getDescendants();
  for (var i = 0; i < descendants.length; i++) {
    block.workspace.code_serch = '';
    Blockly.Xml.search_MD_XY_matchBlock_(descendants[i], opt_noId, key_word);
  }
};

/**
 * Encode a list of variables as XML.
 * @param {!Array.<!Blockly.VariableModel>} variableList List of all variable
 *     models.
 * @return {!Element} List of XML elements.
 */
Blockly.Xml.variablesToDom = function (variableList) {
  var variables = goog.dom.createDom('variables');
  if (currentPageId != null) {
    variables.setAttribute('id', currentPageId);
    variables.setAttribute('name', pages[currentPageId].name);
  }

  for (var i = 0, variable; variable = variableList[i]; i++) {
    var element = goog.dom.createDom('variable', null, variable.name);
    element.setAttribute('type', variable.type);
    element.setAttribute('id', variable.getId());
    variables.appendChild(element);
  }
  return variables;
};

/**
 * Encode a block subtree as XML with XY coordinates.
 * @param {!Blockly.Block} block The root block to encode.
 * @param {boolean} opt_noId True if the encoder should skip the block id.
 * @return {!Element} Tree of XML elements.
 */
Blockly.Xml.blockToDomWithXY = function (block, opt_noId) {
  var width;  // Not used in LTR.
  if (block.workspace.RTL) {
    width = block.workspace.getWidth();
  }
  var element = Blockly.Xml.blockToDom(block, opt_noId);
  var xy = block.getRelativeToSurfaceXY();
  element.setAttribute('x',
    Math.round(block.workspace.RTL ? width - xy.x : xy.x));
  element.setAttribute('y', Math.round(xy.y));
  return element;
};

/**
 * Encode a block subtree as XML.
 * @param {!Blockly.Block} block The root block to encode.
 * @param {boolean} opt_noId True if the encoder should skip the block id.
 * @return {!Element} Tree of XML elements.
 */
Blockly.Xml.blockToDom = function (block, opt_noId) {
  var element = goog.dom.createDom(block.isShadow() ? 'shadow' : 'block');
  element.setAttribute('type', block.type);
  if (!opt_noId) {
    element.setAttribute('id', block.id);
  }
  //如果没有隐藏
  if (!block.isShadow()) {
    var xy = block.getRelativeToSurfaceXY();
    element.setAttribute('x',
      Math.round(block.workspace.RTL ? width - xy.x : xy.x));
    element.setAttribute('y', Math.round(xy.y));
  }


  if (block.mutationToDom) {
    // Custom data for an advanced block.
    var mutation = block.mutationToDom();
    if (mutation && (mutation.hasChildNodes() || mutation.hasAttributes())) {
      element.appendChild(mutation);
    }
  }
  function fieldToDom(field) {
    if (field.name && field.EDITABLE) {
      var container = goog.dom.createDom('field', null, field.getValue());
      container.setAttribute('name', field.name);
      if (field instanceof Blockly.FieldVariable) {
        var variable = block.workspace.getVariable(field.getValue());
        if (variable) {
          container.setAttribute('id', variable.getId());
          container.setAttribute('variableType', variable.type);
        }
      }
      element.appendChild(container);
    }
  }
  for (var i = 0, input; input = block.inputList[i]; i++) {
    for (var j = 0, field; field = input.fieldRow[j]; j++) {
      fieldToDom(field);
    }
  }

  var commentText = block.getCommentText();
  if (commentText) {
    var commentElement = goog.dom.createDom('comment', null, commentText);
    if (typeof block.comment == 'object') {
      commentElement.setAttribute('pinned', block.comment.isVisible());
      var hw = block.comment.getBubbleSize();
      commentElement.setAttribute('h', hw.height);
      commentElement.setAttribute('w', hw.width);
    }
    element.appendChild(commentElement);
  }

  if (block.data) {
    var dataElement = goog.dom.createDom('data', null, block.data);
    element.appendChild(dataElement);
  }

  for (var i = 0, input; input = block.inputList[i]; i++) {
    var container;
    var empty = true;
    if (input.type == Blockly.DUMMY_INPUT) {
      continue;
    } else {
      var childBlock = input.connection.targetBlock();
      if (input.type == Blockly.INPUT_VALUE) {
        container = goog.dom.createDom('value');
      } else if (input.type == Blockly.NEXT_STATEMENT) {
        container = goog.dom.createDom('statement');
      }
      var shadow = input.connection.getShadowDom();
      if (shadow && (!childBlock || !childBlock.isShadow())) {
        container.appendChild(Blockly.Xml.cloneShadow_(shadow));
      }
      if (childBlock) {
        container.appendChild(Blockly.Xml.blockToDom(childBlock, opt_noId));
        empty = false;
      }
    }
    container.setAttribute('name', input.name);
    if (!empty) {
      element.appendChild(container);
    }
  }
  if (block.inputsInlineDefault != block.inputsInline) {
    element.setAttribute('inline', block.inputsInline);
  }
  if (block.isCollapsed()) {
    element.setAttribute('collapsed', true);
  }
  if (block.disabled) {
    element.setAttribute('disabled', true);
  }
  if (!block.isDeletable() && !block.isShadow()) {
    element.setAttribute('deletable', false);
  }
  if (!block.isMovable() && !block.isShadow()) {
    element.setAttribute('movable', false);
  }
  if (!block.isEditable()) {
    element.setAttribute('editable', false);
  }

  var nextBlock = block.getNextBlock();
  if (nextBlock) {
    var container = goog.dom.createDom('next', null,
      Blockly.Xml.blockToDom(nextBlock, opt_noId));
    element.appendChild(container);
  }
  var shadow = block.nextConnection && block.nextConnection.getShadowDom();
  if (shadow && (!nextBlock || !nextBlock.isShadow())) {
    container.appendChild(Blockly.Xml.cloneShadow_(shadow));
  }

  return element;
};

/**
 * Deeply clone the shadow's DOM so that changes don't back-wash to the block.
 * @param {!Element} shadow A tree of XML elements.
 * @return {!Element} A tree of XML elements.
 * @private
 */
Blockly.Xml.cloneShadow_ = function (shadow) {
  shadow = shadow.cloneNode(true);
  // Walk the tree looking for whitespace.  Don't prune whitespace in a tag.
  var node = shadow;
  var textNode;
  while (node) {
    if (node.firstChild) {
      node = node.firstChild;
    } else {
      while (node && !node.nextSibling) {
        textNode = node;
        node = node.parentNode;
        if (textNode.nodeType == 3 && textNode.data.trim() == '' &&
          node.firstChild != textNode) {
          // Prune whitespace after a tag.
          goog.dom.removeNode(textNode);
        }
      }
      if (node) {
        textNode = node;
        node = node.nextSibling;
        if (textNode.nodeType == 3 && textNode.data.trim() == '') {
          // Prune whitespace before a tag.
          goog.dom.removeNode(textNode);
        }
      }
    }
  }
  return shadow;
};

/**
 * Converts a DOM structure into plain text.
 * Currently the text format is fairly ugly: all one line with no whitespace.
 * @param {!Element} dom A tree of XML elements.
 * @return {string} Text representation.
 */
Blockly.Xml.domToText = function (dom) {
  var oSerializer = new XMLSerializer();
  return oSerializer.serializeToString(dom);
};

/**
 * Converts a DOM structure into properly indented text.
 * @param {!Element} dom A tree of XML elements.
 * @return {string} Text representation.
 */
Blockly.Xml.domToPrettyText = function (dom) {
  // This function is not guaranteed to be correct for all XML.
  // But it handles the XML that Blockly generates.
  var blob = Blockly.Xml.domToText(dom);
  // Place every open and close tag on its own line.
  var lines = blob.split('<');
  // Indent every line.
  var indent = '';
  for (var i = 1; i < lines.length; i++) {
    var line = lines[i];
    if (line[0] == '/') {
      indent = indent.substring(2);
    }
    lines[i] = indent + '<' + line;
    if (line[0] != '/' && line.slice(-2) != '/>') {
      indent += '  ';
    }
  }
  // Pull simple tags back together.
  // E.g. <foo></foo>
  var text = lines.join('\n');
  text = text.replace(/(<(\w+)\b[^>]*>[^\n]*)\n *<\/\2>/g, '$1</$2>');
  // Trim leading blank line.
  return text.replace(/^\n/, '');
};

/**
 * Converts plain text into a DOM structure.
 * Throws an error if XML doesn't parse.
 * @param {string} text Text representation.
 * @return {!Element} A tree of XML elements.
 */
Blockly.Xml.textToDom = function (text) {
  var oParser = new DOMParser();
  var dom = oParser.parseFromString(text, 'text/xml');
  // The DOM should have one and only one top-level node, an XML tag.
  if (!dom || !dom.firstChild ||
    dom.firstChild.nodeName.toLowerCase() != 'xml' ||
    dom.firstChild !== dom.lastChild) {
    // Whatever we got back from the parser is not XML.
    goog.asserts.fail('Blockly.Xml.textToDom did not obtain a valid XML tree.');
  }
  return dom.firstChild;
};

/**
 * Decode an XML DOM and create blocks on the workspace.
 * @param {!Element} xml XML DOM.
 * @param {!Blockly.Workspace} workspace The workspace.
 * @return {Array.<string>} An array containing new block ids.
 */
Blockly.Xml.domToWorkspace = function (xml, workspace) {
  if (xml instanceof Blockly.Workspace) {
    var swap = xml;
    xml = workspace;
    workspace = swap;
    console.warn('Deprecated call to Blockly.Xml.domToWorkspace, ' +
      'swap the arguments.');
  }
  var width;  // Not used in LTR.
  if (workspace.RTL) {
    width = workspace.getWidth();
  }
  var newBlockIds = []; // A list of block ids added by this call.
  Blockly.Field.startCache();
  // Safari 7.1.3 is known to provide node lists with extra references to
  // children beyond the lists' length.  Trust the length, do not use the
  // looping pattern of checking the index for an object.
  var childCount = xml.childNodes.length;
  var existingGroup = Blockly.Events.getGroup();
  if (!existingGroup) {
    Blockly.Events.setGroup(true);
  }

  // Disable workspace resizes as an optimization.
  if (workspace.setResizesEnabled) {
    workspace.setResizesEnabled(false);
  }
  // Batch mode: defer per-block render/connection timers until all XML is loaded.
  workspace.batchLoadBlocks_ = true;
  workspace.batchLoadTopBlocks_ = [];
  var variablesFirst = true;
  try {
    for (var i = 0; i < childCount; i++) {
      var xmlChild = xml.childNodes[i];
      var name = xmlChild.nodeName.toLowerCase();
      if (name == 'block' ||
        (name == 'shadow' && !Blockly.Events.recordUndo)) {

        // Allow top-level shadow blocks if recordUndo is disabled since
        // that means an undo is in progress.  Such a block is expected
        // to be moved to a nested destination in the next operation.
        var block = Blockly.Xml.domToBlock(xmlChild, workspace);
        newBlockIds.push(block.id);
        var blockX = parseInt(xmlChild.getAttribute('x'), 10);
        var blockY = parseInt(xmlChild.getAttribute('y'), 10);
        if (!isNaN(blockX) && !isNaN(blockY)) {
          block.moveBy(workspace.RTL ? width - blockX : blockX, blockY);
        }
        variablesFirst = false;
      } else if (name == 'shadow') {
        goog.asserts.fail('Shadow block cannot be a top-level block.');
        variablesFirst = false;
      } else if (name == 'variables') {
        if (variablesFirst) {
          Blockly.Xml.domToVariables(xmlChild, workspace);
        }
        else {
          throw Error('\'variables\' tag must exist once before block and ' +
            'shadow tag elements in the workspace XML, but it was found in ' +
            'another location.');
        }
        variablesFirst = false;
      }
    }
  }
  finally {
    if (workspace.batchLoadBlocks_) {
      if (workspace.rendered && workspace.batchLoadTopBlocks_.length) {
        workspace.render();
        var batchTopBlocks = workspace.batchLoadTopBlocks_;
        setTimeout(function() {
          for (var t = 0; t < batchTopBlocks.length; t++) {
            var batchBlock = batchTopBlocks[t];
            if (batchBlock.workspace) {
              batchBlock.setConnectionsHidden(false);
            }
          }
        }, 1);
        for (var t = 0; t < batchTopBlocks.length; t++) {
          batchTopBlocks[t].updateDisabled();
        }
      }
      workspace.batchLoadBlocks_ = false;
      workspace.batchLoadTopBlocks_ = null;
    }
    if (!existingGroup) {
      Blockly.Events.setGroup(false);
    }
    Blockly.Field.stopCache();
  }
  workspace.updateVariableStore(false);
  // Re-enable workspace resizing.
  if (workspace.setResizesEnabled) {
    workspace.setResizesEnabled(true);
  }
  return newBlockIds;
};

/**
 * Decode an XML DOM and create blocks on the workspace. Position the new
 * blocks immediately below prior blocks, aligned by their starting edge.
 * @param {!Element} xml The XML DOM.
 * @param {!Blockly.Workspace} workspace The workspace to add to.
 * @return {Array.<string>} An array containing new block ids.
 */
Blockly.Xml.appendDomToWorkspace = function (xml, workspace) {
  var bbox; //bounding box of the current blocks
  // first check if we have a workspaceSvg otherwise the block have no shape
  // and the position does not matter
  if (workspace.hasOwnProperty('scale')) {
    var savetab = Blockly.BlockSvg.TAB_WIDTH;
    try {
      Blockly.BlockSvg.TAB_WIDTH = 0;
      var bbox = workspace.getBlocksBoundingBox();
    } finally {
      Blockly.BlockSvg.TAB_WIDTH = savetab;
    }
  }
  // load the new blocks into the workspace and get the ids of the new blocks
  var newBlockIds = Blockly.Xml.domToWorkspace(xml, workspace);
  if (bbox && bbox.height) { // check if any previous block
    var offsetY = 0; // offset to add to y of the new block
    var offsetX = 0;
    var farY = bbox.y + bbox.height; //bottom position
    var topX = bbox.x; // x of bounding box
    // check position of the new blocks
    var newX = Infinity; // x of top corner
    var newY = Infinity; // y of top corner
    for (var i = 0; i < newBlockIds.length; i++) {
      var blockXY = workspace.getBlockById(newBlockIds[i]).getRelativeToSurfaceXY();
      if (blockXY.y < newY) {
        newY = blockXY.y;
      }
      if (blockXY.x < newX) { //if we align also on x
        newX = blockXY.x;
      }
    }
    offsetY = farY - newY + Blockly.BlockSvg.SEP_SPACE_Y;
    offsetX = topX - newX;
    // move the new blocks to append them at the bottom
    var width;  // Not used in LTR.
    if (workspace.RTL) {
      width = workspace.getWidth();
    }
    for (var i = 0; i < newBlockIds.length; i++) {
      var block = workspace.getBlockById(newBlockIds[i]);
      block.moveBy(workspace.RTL ? width - offsetX : offsetX, offsetY);
    }
  }
  return newBlockIds;
};

/**
 * Decode an XML block tag and create a block (and possibly sub blocks) on the
 * workspace.
 * @param {!Element} xmlBlock XML block element.
 * @param {!Blockly.Workspace} workspace The workspace.
 * @return {!Blockly.Block} The root block created.
 */
Blockly.Xml.domToBlock = function (xmlBlock, workspace) {
  if (xmlBlock instanceof Blockly.Workspace) {
    var swap = xmlBlock;
    xmlBlock = workspace;
    workspace = swap;
    console.warn('Deprecated call to Blockly.Xml.domToBlock, ' +
      'swap the arguments.');
  }
  // Create top-level block.
  Blockly.Events.disable();
  try {
    var topBlock = Blockly.Xml.domToBlockHeadless_(xmlBlock, workspace);
    if (workspace.rendered) {
      // Hide connections to speed up assembly.
      topBlock.setConnectionsHidden(true);
      // Generate list of all blocks.
      var blocks = topBlock.getDescendants();
      for (var i = blocks.length - 1; i >= 0; i--) {
        blocks[i].initSvg();
      }
      if (workspace.batchLoadBlocks_) {
        workspace.batchLoadTopBlocks_.push(topBlock);
      } else {
        // Render each block.
        for (var i = blocks.length - 1; i >= 0; i--) {
          blocks[i].render(false);
        }
        // Populating the connection database may be deferred until after the
        // blocks have rendered.
        setTimeout(function () {
          if (topBlock.workspace) {  // Check that the block hasn't been deleted.
            topBlock.setConnectionsHidden(false);
          }
        }, 1);
        topBlock.updateDisabled();
        // Allow the scrollbars to resize and move based on the new contents.
        // TODO(@picklesrus): #387. Remove when domToBlock avoids resizing.
        workspace.resizeContents();
      }
    }
  } finally {
    Blockly.Events.enable();
  }
  if (Blockly.Events.isEnabled()) {
    Blockly.Events.fire(new Blockly.Events.BlockCreate(topBlock));
  }
  return topBlock;
};

/**
 * Decode an XML list of variables and add the variables to the workspace.
 * @param {!Element} xmlVariables List of XML variable elements.
 * @param {!Blockly.Workspace} workspace The workspace to which the variable
 *     should be added.
 */
Blockly.Xml.domToVariables = function (xmlVariables, workspace) {
  for (var i = 0, xmlChild; xmlChild = xmlVariables.children[i]; i++) {
    var type = xmlChild.getAttribute('type');
    var id = xmlChild.getAttribute('id');
    var name = xmlChild.textContent;

    if (typeof (type) === undefined || type === null) {
      throw Error('Variable with id, ' + id + ' is without a type');
    }
    workspace.createVariable(name, type, id);
  }
};

/**
 * Decode an XML block tag and create a block (and possibly sub blocks) on the
 * workspace.
 * @param {!Element} xmlBlock XML block element.
 * @param {!Blockly.Workspace} workspace The workspace.
 * @return {!Blockly.Block} The root block created.
 * @private
 */
Blockly.Xml.domToBlockHeadless_ = function (xmlBlock, workspace) {
  var block = null;
  var prototypeName = xmlBlock.getAttribute('type');
  goog.asserts.assert(prototypeName, 'Block type unspecified: %s',
    xmlBlock.outerHTML);
  var id = xmlBlock.getAttribute('id');
  block = workspace.newBlock(prototypeName, id);

  var blockChild = null;
  for (var i = 0, xmlChild; xmlChild = xmlBlock.childNodes[i]; i++) {
    if (xmlChild.nodeType == 3) {
      // Ignore any text at the <block> level.  It's all whitespace anyway.
      continue;
    }
    var input;

    // Find any enclosed blocks or shadows in this tag.
    var childBlockNode = null;
    var childShadowNode = null;
    for (var j = 0, grandchildNode; grandchildNode = xmlChild.childNodes[j];
      j++) {
      if (grandchildNode.nodeType == 1) {
        if (grandchildNode.nodeName.toLowerCase() == 'block') {
          childBlockNode = grandchildNode;
        } else if (grandchildNode.nodeName.toLowerCase() == 'shadow') {
          childShadowNode = grandchildNode;
        }
      }
    }
    // Use the shadow block if there is no child block.
    if (!childBlockNode && childShadowNode) {
      childBlockNode = childShadowNode;
    }

    var name = xmlChild.getAttribute('name');
    switch (xmlChild.nodeName.toLowerCase()) {
      case 'mutation':
        // Custom data for an advanced block.
        if (block.domToMutation) {
          block.domToMutation(xmlChild);
          if (block.initSvg) {
            // Mutation may have added some elements that need initializing.
            block.initSvg();
          }
        }
        break;
      case 'comment':
        block.setCommentText(xmlChild.textContent);
        var visible = xmlChild.getAttribute('pinned');
        if (visible && !block.isInFlyout) {
          // Give the renderer a millisecond to render and position the block
          // before positioning the comment bubble.
          setTimeout(function () {
            if (block.comment && block.comment.setVisible) {
              block.comment.setVisible(visible == 'true');
            }
          }, 1);
        }
        var bubbleW = parseInt(xmlChild.getAttribute('w'), 10);
        var bubbleH = parseInt(xmlChild.getAttribute('h'), 10);
        if (!isNaN(bubbleW) && !isNaN(bubbleH) &&
          block.comment && block.comment.setVisible) {
          block.comment.setBubbleSize(bubbleW, bubbleH);
        }
        break;
      case 'data':
        block.data = xmlChild.textContent;
        break;
      case 'title':
      // Titles were renamed to field in December 2013.
      // Fall through.
      case 'field':
        var field = block.getField(name);
        var text = xmlChild.textContent;
        if (field instanceof Blockly.FieldVariable) {
          // TODO (marisaleung): When we change setValue and getValue to
          // interact with id's instead of names, update this so that we get
          // the variable based on id instead of textContent.
          var type = xmlChild.getAttribute('variabletype') || '';
          var variable = workspace.getVariable(text);
          if (!variable) {
            variable = workspace.createVariable(text, type,
              xmlChild.getAttribute(id));
          }
          if (typeof (type) !== undefined && type !== null) {
            if (type !== variable.type) {
              throw Error('Serialized variable type with id \'' +
                variable.getId() + '\' had type ' + variable.type + ', and ' +
                'does not match variable field that references it: ' +
                Blockly.Xml.domToText(xmlChild) + '.');
            }
          }
        }
        if (!field) {
          console.warn('Ignoring non-existent field ' + name + ' in block ' +
            prototypeName);
          break;
        }
        field.setValue(text);
        break;
      case 'value':
      case 'statement':
        input = block.getInput(name);
        if (!input) {
          console.warn('Ignoring non-existent input ' + name + ' in block ' +
            prototypeName);
          break;
        }
        if (childShadowNode) {
          input.connection.setShadowDom(childShadowNode);
        }
        if (childBlockNode) {
          blockChild = Blockly.Xml.domToBlockHeadless_(childBlockNode,
            workspace);
          if (blockChild.outputConnection) {
            input.connection.connect(blockChild.outputConnection);
          } else if (blockChild.previousConnection) {
            input.connection.connect(blockChild.previousConnection);
          } else {
            goog.asserts.fail(
              'Child block does not have output or previous statement.');
          }
        }
        break;
      case 'next':
        if (childShadowNode && block.nextConnection) {
          block.nextConnection.setShadowDom(childShadowNode);
        }
        if (childBlockNode) {
          goog.asserts.assert(block.nextConnection,
            'Next statement does not exist.');
          // If there is more than one XML 'next' tag.
          goog.asserts.assert(!block.nextConnection.isConnected(),
            'Next statement is already connected.');
          blockChild = Blockly.Xml.domToBlockHeadless_(childBlockNode,
            workspace);
          goog.asserts.assert(blockChild.previousConnection,
            'Next block does not have previous statement.');
          block.nextConnection.connect(blockChild.previousConnection);
        }
        break;
      default:
        // Unknown tag; ignore.  Same principle as HTML parsers.
        console.warn('Ignoring unknown tag: ' + xmlChild.nodeName);
    }
  }

  var inline = xmlBlock.getAttribute('inline');
  if (inline) {
    block.setInputsInline(inline == 'true');
  }
  var disabled = xmlBlock.getAttribute('disabled');
  if (disabled) {
    block.setDisabled(disabled == 'true');
  }
  var deletable = xmlBlock.getAttribute('deletable');
  if (deletable) {
    block.setDeletable(deletable == 'true');
  }
  var movable = xmlBlock.getAttribute('movable');
  if (movable) {
    block.setMovable(movable == 'true');
  }
  var editable = xmlBlock.getAttribute('editable');
  if (editable) {
    block.setEditable(editable == 'true');
  }
  var collapsed = xmlBlock.getAttribute('collapsed');
  if (collapsed) {
    block.setCollapsed(collapsed == 'true');
  }
  if (xmlBlock.nodeName.toLowerCase() == 'shadow') {
    // Ensure all children are also shadows.
    var children = block.getChildren();
    for (var i = 0, child; child = children[i]; i++) {
      goog.asserts.assert(child.isShadow(),
        'Shadow block not allowed non-shadow child.');
    }
    // Ensure this block doesn't have any variable inputs.
    goog.asserts.assert(block.getVars().length == 0,
      'Shadow blocks cannot have variable fields.');
    block.setShadow(true);
  }
  return block;
};

/**
 * Remove any 'next' block (statements in a stack).
 * @param {!Element} xmlBlock XML block element.
 */
Blockly.Xml.deleteNext = function (xmlBlock) {
  for (var i = 0, child; child = xmlBlock.childNodes[i]; i++) {
    if (child.nodeName.toLowerCase() == 'next') {
      xmlBlock.removeChild(child);
      break;
    }
  }
};

// Export symbols that would otherwise be renamed by Closure compiler.导出将被 Closure 编译器重命名的符号。
if (!goog.global['Blockly']) {
  goog.global['Blockly'] = {};
}
if (!goog.global['Blockly']['Xml']) {
  goog.global['Blockly']['Xml'] = {};
}

//全局定义
goog.global['Blockly']['Xml']['domToText'] = Blockly.Xml.domToText;
goog.global['Blockly']['Xml']['domToWorkspace'] = Blockly.Xml.domToWorkspace;
goog.global['Blockly']['Xml']['textToDom'] = Blockly.Xml.textToDom;
goog.global['Blockly']['Xml']['workspaceToDom'] = Blockly.Xml.workspaceToDom;
