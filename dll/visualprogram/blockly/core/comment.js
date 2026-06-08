/**
 * @license
 * Visual Blocks Editor
 *
 * Copyright 2011 Google Inc.
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
 * @fileoverview Object representing a code comment.
 * @author fraser@google.com (Neil Fraser)
 */
'use strict';

goog.provide('Blockly.Comment');

goog.require('Blockly.Bubble');
goog.require('Blockly.Icon');
goog.require('Blockly.BlockSvg');
goog.require('goog.userAgent');


/**
 * Class for a comment.
 * @param {!Blockly.Block} block The block associated with this comment.
 * @extends {Blockly.Icon}
 * @constructor
 */
Blockly.Comment = function(block) {
  Blockly.Comment.superClass_.constructor.call(this, block);
  this.createIcon();
  this.createInlineLabel_();
};
goog.inherits(Blockly.Comment, Blockly.Icon);

/**
 * PLC-style: inline comment label group (below block), no bubble.
 * @private
 */
Blockly.Comment.prototype.commentLabelGroup_ = null;
/**
 * @private
 */
Blockly.Comment.prototype.inlineTextarea_ = null;
/**
 * PLC-style: 自适应高度（px），无上下翻页。
 * @private
 */
Blockly.Comment.prototype.commentLabelHeight_ = 0;

/**
 * Comment text (if bubble is not visible).
 * @private
 */
Blockly.Comment.prototype.text_ = '';

/**
 * Width of bubble.
 * @private
 */
Blockly.Comment.prototype.width_ = 160;

/**
 * Height of bubble.
 * @private
 */
Blockly.Comment.prototype.height_ = 80;

/**
 * Draw the comment icon.
 * @param {!Element} group The icon group.
 * @private
 */
Blockly.Comment.prototype.drawIcon_ = function(group) {
  // Circle.
  Blockly.utils.createSvgElement('circle',
      {'class': 'blocklyIconShape', 'r': '8', 'cx': '8', 'cy': '8'},
       group);
  // Can't use a real '?' text character since different browsers and operating
  // systems render it differently.
  // Body of question mark.
  Blockly.utils.createSvgElement('path',
      {'class': 'blocklyIconSymbol',
       'd': 'm6.8,10h2c0.003,-0.617 0.271,-0.962 0.633,-1.266 2.875,-2.405 0.607,-5.534 -3.765,-3.874v1.7c3.12,-1.657 3.698,0.118 2.336,1.25 -1.201,0.998 -1.201,1.528 -1.204,2.19z'},
       group);
  // Dot of question mark.
  Blockly.utils.createSvgElement('rect',
      {'class': 'blocklyIconSymbol',
       'x': '6.8', 'y': '10.78', 'height': '2', 'width': '2'},
       group);
};

/**
 * PLC-style: create inline comment label below block (no bubble).
 * @private
 */
Blockly.Comment.prototype.createInlineLabel_ = function() {
  if (this.commentLabelGroup_) return;
  this.commentLabelHeight_ = Blockly.BlockSvg.COMMENT_LABEL_HEIGHT;
  var labelHeight = Blockly.BlockSvg.COMMENT_LABEL_HEIGHT - 4;
  this.commentLabelGroup_ = Blockly.utils.createSvgElement('g',
      {'class': 'blocklyCommentInlineLabel'}, null);
  var fo = Blockly.utils.createSvgElement('foreignObject',
      {'x': Blockly.BlockSvg.SEP_SPACE_X, 'y': 2, 'width': 100, 'height': labelHeight},
      this.commentLabelGroup_);
  var body = document.createElementNS(Blockly.HTML_NS, 'body');
  body.setAttribute('xmlns', Blockly.HTML_NS);
  body.className = 'blocklyMinimalBody';
  var textarea = document.createElementNS(Blockly.HTML_NS, 'textarea');
  textarea.className = 'blocklyCommentInlineTextarea';
  textarea.setAttribute('dir', this.block_.RTL ? 'RTL' : 'LTR');
  textarea.setAttribute('rows', '1');
  body.appendChild(textarea);
  fo.appendChild(body);
  this.inlineTextarea_ = textarea;
  Blockly.bindEventWithChecks_(textarea, 'wheel', this, function(e) {
    e.stopPropagation();
  });
  Blockly.bindEventWithChecks_(textarea, 'change', this, function() {
    if (this.text_ != textarea.value) {
      Blockly.Events.fire(new Blockly.Events.BlockChange(
          this.block_, 'comment', null, this.text_, textarea.value));
      this.text_ = textarea.value;
      this.resizeCommentLabelAndMaybeRender_();
    }
  });
  Blockly.bindEventWithChecks_(textarea, 'input', this, function() {
    if (this.text_ != textarea.value) {
      Blockly.Events.fire(new Blockly.Events.BlockChange(
          this.block_, 'comment', null, this.text_, textarea.value));
      this.text_ = textarea.value;
      this.resizeCommentLabelAndMaybeRender_();
    }
  });
  // 加载 XML/G 代码时块可能尚未渲染，getSvgRoot() 不存在则延后挂载，由 render 时补挂
  var root = this.block_.getSvgRoot && this.block_.getSvgRoot();
  if (root) root.appendChild(this.commentLabelGroup_);
};

/**
 * PLC-style: 返回注释行当前高度（自适应，无翻页）。
 * @return {number} Height in px.
 */
Blockly.Comment.prototype.getCommentLabelHeight = function() {
  var h = this.commentLabelHeight_ || Blockly.BlockSvg.COMMENT_LABEL_HEIGHT;
  return Math.max(Blockly.BlockSvg.COMMENT_LABEL_HEIGHT, h);
};

/**
 * 根据内容重算注释区高度并可能触发块重绘（自适应显示，无上下翻页）。
 * @private
 */
Blockly.Comment.prototype.resizeCommentLabelAndMaybeRender_ = function() {
  if (!this.inlineTextarea_) return;
  var ta = this.inlineTextarea_;
  ta.style.height = '0';
  ta.style.height = Math.max(18, ta.scrollHeight) + 'px';
  var contentH = ta.scrollHeight;
  var newH = contentH + 8;
  newH = Math.max(Blockly.BlockSvg.COMMENT_LABEL_HEIGHT, newH);
  if (newH !== this.commentLabelHeight_) {
    this.commentLabelHeight_ = newH;
    if (this.block_ && this.block_.rendered) {
      this.block_.render(false);
    }
  }
  var fo = this.commentLabelGroup_ && this.commentLabelGroup_.querySelector('foreignObject');
  if (fo) fo.setAttribute('height', contentH + 4);
};

/**
 * PLC-style: position inline comment label below block（自适应高度，全部显示不翻页）.
 * @param {number} y Y offset in block coordinates (top of comment row).
 * @param {number} width Block width in px.
 * @private
 */
Blockly.Comment.prototype.positionInlineLabel_ = function(y, width) {
  if (!this.commentLabelGroup_) return;
  var prevH = this.commentLabelHeight_;
  var pad = Blockly.BlockSvg.SEP_SPACE_X * 2;
  var labelW = Math.max(60, width - pad);
  var minH = Blockly.BlockSvg.COMMENT_LABEL_HEIGHT - 4;
  var labelH = minH;
  if (this.inlineTextarea_) {
    this.inlineTextarea_.value = this.getText();
    this.inlineTextarea_.style.width = (labelW - 4) + 'px';
    this.inlineTextarea_.style.height = '0';
    this.inlineTextarea_.style.height = Math.max(minH - 4, this.inlineTextarea_.scrollHeight) + 'px';
    labelH = Math.max(minH, this.inlineTextarea_.scrollHeight + 4);
  }
  this.commentLabelHeight_ = labelH;
  this.commentLabelGroup_.setAttribute('transform', 'translate(0, ' + y + ')');
  var fo = this.commentLabelGroup_.querySelector('foreignObject');
  if (fo) {
    fo.setAttribute('width', labelW);
    fo.setAttribute('height', labelH);
  }
  // 仅当自适应高度比之前变大时重绘，避免死循环
  if (labelH > prevH && this.block_ && this.block_.rendered) {
    this.block_.render(false);
  }
};

/**
 * Clicking icon focuses inline comment (PLC-style: no bubble).
 * APP/WebView 下 foreignObject 内 textarea 无法聚焦、弹不出键盘，改用 prompt 弹窗编辑。
 * @override
 */
Blockly.Comment.prototype.iconClick_ = function(e) {
  if (this.block_.workspace.isDragging()) return;
  if (!this.block_.isInFlyout && !Blockly.utils.isRightButton(e)) {
    if (Blockly.IS_APP) {
      var comment = this;
      Blockly.prompt(
        Blockly.Msg.CHANGE_VALUE_TITLE || '编辑注释',
        this.getText(),
        function(newText) {
          if (newText != null) {
            comment.setText(newText);
            if (comment.block_ && comment.block_.rendered) {
              comment.block_.render(false);
            }
          }
        }
      );
      return;
    }
    if (this.inlineTextarea_) {
      this.inlineTextarea_.focus();
    }
  }
};

/**
 * Create the editor for the comment's bubble.
 * @return {!Element} The top-level node of the editor.
 * @private
 */
Blockly.Comment.prototype.createEditor_ = function() {
  /* Create the editor.  Here's the markup that will be generated:
    <foreignObject x="8" y="8" width="164" height="164">
      <body xmlns="http://www.w3.org/1999/xhtml" class="blocklyMinimalBody">
        <textarea xmlns="http://www.w3.org/1999/xhtml"
            class="blocklyCommentTextarea"
            style="height: 164px; width: 164px;"></textarea>
      </body>
    </foreignObject>
  */
  this.foreignObject_ = Blockly.utils.createSvgElement('foreignObject',
      {'x': Blockly.Bubble.BORDER_WIDTH, 'y': Blockly.Bubble.BORDER_WIDTH},
      null);
  var body = document.createElementNS(Blockly.HTML_NS, 'body');
  body.setAttribute('xmlns', Blockly.HTML_NS);
  body.className = 'blocklyMinimalBody';
  var textarea = document.createElementNS(Blockly.HTML_NS, 'textarea');
  textarea.className = 'blocklyCommentTextarea';
  textarea.setAttribute('dir', this.block_.RTL ? 'RTL' : 'LTR');
  body.appendChild(textarea);
  this.textarea_ = textarea;
  this.foreignObject_.appendChild(body);
  Blockly.bindEventWithChecks_(textarea, 'mouseup', this, this.textareaFocus_);
  // Don't zoom with mousewheel.
  Blockly.bindEventWithChecks_(textarea, 'wheel', this, function(e) {
    e.stopPropagation();
  });
  Blockly.bindEventWithChecks_(textarea, 'change', this, function(e) {
    if (this.text_ != textarea.value) {
      Blockly.Events.fire(new Blockly.Events.BlockChange(
        this.block_, 'comment', null, this.text_, textarea.value));
      this.text_ = textarea.value;
    }
  });
  setTimeout(function() {
    textarea.focus();
  }, 0);
  return this.foreignObject_;
};

/**
 * Add or remove editability of the comment.
 * @override
 */
Blockly.Comment.prototype.updateEditable = function() {
  if (this.isVisible()) {
    // Toggling visibility will force a rerendering.
    this.setVisible(false);
    this.setVisible(true);
  }
  // Allow the icon to update.
  Blockly.Icon.prototype.updateEditable.call(this);
};

/**
 * Callback function triggered when the bubble has resized.
 * Resize the text area accordingly.
 * @private
 */
Blockly.Comment.prototype.resizeBubble_ = function() {
  if (this.isVisible()) {
    var size = this.bubble_.getBubbleSize();
    var doubleBorderWidth = 2 * Blockly.Bubble.BORDER_WIDTH;
    this.foreignObject_.setAttribute('width', size.width - doubleBorderWidth);
    this.foreignObject_.setAttribute('height', size.height - doubleBorderWidth);
    this.textarea_.style.width = (size.width - doubleBorderWidth - 4) + 'px';
    this.textarea_.style.height = (size.height - doubleBorderWidth - 4) + 'px';
  }
};

/**
 * Show or hide the comment bubble.
 * PLC-style: never open bubble; comment is always shown inline below block.
 * @param {boolean} visible True if the bubble should be visible.
 */
Blockly.Comment.prototype.setVisible = function(visible) {
  if (visible) {
    // PLC-style: do not open bubble; comment is inline below block.
    return;
  }
  if (visible == this.isVisible()) {
    return;
  }
  Blockly.Events.fire(
      new Blockly.Events.Ui(this.block_, 'commentOpen', !visible, visible));
  if ((!this.block_.isEditable() && !this.textarea_) || goog.userAgent.IE) {
    // Steal the code from warnings to make an uneditable text bubble.
    // MSIE does not support foreignobject; textareas are impossible.
    // http://msdn.microsoft.com/en-us/library/hh834675%28v=vs.85%29.aspx
    // Always treat comments in IE as uneditable.
    Blockly.Warning.prototype.setVisible.call(this, visible);
    return;
  }
  // Save the bubble stats before the visibility switch.
  var text = this.getText();
  var size = this.getBubbleSize();
  if (visible) {
    // Create the bubble.
    this.bubble_ = new Blockly.Bubble(
        /** @type {!Blockly.WorkspaceSvg} */ (this.block_.workspace),
        this.createEditor_(), this.block_.svgPath_,
        this.iconXY_, this.width_, this.height_);
    this.bubble_.registerResizeEvent(this.resizeBubble_.bind(this));
    this.updateColour();
  } else {
    // Dispose of the bubble.
    this.bubble_.dispose();
    this.bubble_ = null;
    this.textarea_ = null;
    this.foreignObject_ = null;
  }
  // Restore the bubble stats after the visibility switch.
  this.setText(text);
  this.setBubbleSize(size.width, size.height);
};

/**
 * Bring the comment to the top of the stack when clicked on.
 * @param {!Event} e Mouse up event.
 * @private
 */
Blockly.Comment.prototype.textareaFocus_ = function(e) {
  // Ideally this would be hooked to the focus event for the comment.
  // However doing so in Firefox swallows the cursor for unknown reasons.
  // So this is hooked to mouseup instead.  No big deal.
  this.bubble_.promote_();
  // Since the act of moving this node within the DOM causes a loss of focus,
  // we need to reapply the focus.
  this.textarea_.focus();
};

/**
 * Get the dimensions of this comment's bubble.
 * @return {!Object} Object with width and height properties.
 */
Blockly.Comment.prototype.getBubbleSize = function() {
  if (this.isVisible() && this.bubble_) {
    return this.bubble_.getBubbleSize();
  }
  // PLC 风格无气泡，或保存/加载 XML 时用 width_/height_（或注释行高）
  var h = this.commentLabelHeight_ || this.height_ || Blockly.BlockSvg.COMMENT_LABEL_HEIGHT;
  return {width: this.width_ || 160, height: h};
};

/**
 * Size this comment's bubble.
 * @param {number} width Width of the bubble.
 * @param {number} height Height of the bubble.
 */
Blockly.Comment.prototype.setBubbleSize = function(width, height) {
  if (this.textarea_) {
    this.bubble_.setBubbleSize(width, height);
  } else {
    this.width_ = width;
    this.height_ = height;
    // PLC 风格：从 XML 加载时用保存的 h 作为注释行高，保证重载后布局正确
    if (height && height >= Blockly.BlockSvg.COMMENT_LABEL_HEIGHT) {
      this.commentLabelHeight_ = height;
    }
  }
};

/**
 * Returns this comment's text.
 * @return {string} Comment text.
 */
Blockly.Comment.prototype.getText = function() {
  if (this.inlineTextarea_) return this.inlineTextarea_.value;
  return this.textarea_ ? this.textarea_.value : this.text_;
};

/**
 * Set this comment's text.
 * @param {string} text Comment text.
 */
Blockly.Comment.prototype.setText = function(text) {
  if (this.text_ != text) {
    Blockly.Events.fire(new Blockly.Events.BlockChange(
      this.block_, 'comment', null, this.text_, text));
    this.text_ = text;
  }
  if (this.inlineTextarea_) {
    this.inlineTextarea_.value = text;
  }
  if (this.textarea_) {
    this.textarea_.value = text;
  }
};

/**
 * Dispose of this comment.
 */
Blockly.Comment.prototype.dispose = function() {
  if (Blockly.Events.isEnabled()) {
    this.setText('');  // Fire event to delete comment.
  }
  if (this.commentLabelGroup_ && this.commentLabelGroup_.parentNode) {
    this.commentLabelGroup_.parentNode.removeChild(this.commentLabelGroup_);
  }
  this.commentLabelGroup_ = null;
  this.inlineTextarea_ = null;
  this.block_.comment = null;
  Blockly.Icon.prototype.dispose.call(this);
};
