/**
 * Blockly Demos: Code
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
 * @fileoverview JavaScript for Blockly's Code demo.
 * @author fraser@google.com (Neil Fraser)
 */
'use strict';

goog.require('Blockly.CustomConfig');

/**
 * Create a namespace for the application.
 */
var Code = {};
var sp_lang;

let pages = {};
let currentPageId = null;
/**
 * Lookup for names of supported languages.  Keys should be in ISO 639 format.
 */
Code.LANGUAGE_NAME = {
  /*
  'ar': 'العربية',
  'be-tarask': 'Taraškievica',
  'br': 'Brezhoneg',
  'ca': 'Català',
  'cs': 'Česky',
  'da': 'Dansk',
  'de': 'Deutsch',
  'el': 'Ελληνικά',
  */
  //'en': 'English',
  /*
  'es': 'Español',
  'et': 'Eesti',
  'fa': 'فارسی',
  'fr': 'Français',
  'he': 'עברית',
  'hrx': 'Hunsrik',
  'hu': 'Magyar',
  'ia': 'Interlingua',
  'is': 'Íslenska',
  'it': 'Italiano',
  'ja': '日本語',
  'ko': '한국어',
  'mk': 'Македонски',
  'ms': 'Bahasa Melayu',
  'nb': 'Norsk Bokmål',
  'nl': 'Nederlands, Vlaams',
  'oc': 'Lenga d\'òc',
  'pl': 'Polski',
  'pms': 'Piemontèis',
  'pt-br': 'Português Brasileiro',
  'ro': 'Română',
  'ru': 'Русский',
  'sc': 'Sardu',
  'sk': 'Slovenčina',
  'sr': 'Српски',
  'sv': 'Svenska',
  'ta': 'தமிழ்',
  'th': 'ภาษาไทย',
  'tlh': 'tlhIngan Hol',
  'tr': 'Türkçe',
  'uk': 'Українська',
  'vi': 'Tiếng Việt',
  */
  'zh-hans': '简体中文',
  // 'zh-hant': '正體中文'
};

/**
 * List of RTL languages.
 */
Code.LANGUAGE_RTL = ['ar', 'fa', 'he', 'lki'];

/**
 * Blockly's main workspace.
 * @type {Blockly.WorkspaceSvg}
 */
Code.workspace = null;

//网页APP转换
var isWeb = true;
// APP/WebView 下让 Blockly 使用 prompt 弹窗输入，避免内联输入框无法聚焦、弹不出键盘
if (typeof Blockly !== 'undefined') Blockly.IS_APP = (typeof bound !== 'undefined');
/**
 * Extracts a parameter from the URL.
 * If the parameter is absent default_value is returned.
 * @param {string} name The name of the parameter.
 * @param {string} defaultValue Value to return if paramater not found.
 * @return {string} The parameter value or the default value if not found.
 */
Code.getStringParamFromUrl = function (name, defaultValue) {
  var val = location.search.match(new RegExp('[?&]' + name + '=([^&]+)'));
  return val ? decodeURIComponent(val[1].replace(/\+/g, '%20')) : defaultValue;
};

/**
 * Get the language of this user from the URL.
 * @return {string} User's language.
 */
Code.getLang = function () {
  //网页APP转换
  isWeb = true;
  var lang = Code.getStringParamFromUrl('lang', '');
  if (!isWeb) {
    //APP版本------------
    sp_lang = bound.getSp_lang();
    if (Code.LANGUAGE_NAME[lang] === undefined) {
      // Default to English.
      if (sp_lang == 'en') {
        lang = 'en';//设置初识默认语言 lang = 'en';
      } else {
        lang = 'zh-hans';//设置初识默认语言 lang = 'en';
      }
    }
    return lang;
    //APP版本------------
  } else {
    // var lang = Code.getStringParamFromUrl('lang', '');
    //网页版本-------------
    if (Code.LANGUAGE_NAME[lang] === undefined) {
      // Default to English.
      lang = 'zh-hans';//设置初识默认语言 lang = 'en';
    }
    return lang;
    //网页版本-------------
  }
};

/**
 * Is the current language (Code.LANG) an RTL language?
 * @return {boolean} True if RTL, false if LTR.
 */
Code.isRtl = function () {
  return Code.LANGUAGE_RTL.indexOf(Code.LANG) != -1;
};

/**
 * Load blocks saved on App Engine Storage or in session/local storage.
 * @param {string} defaultXml Text representation of default blocks.
 */
Code.loadBlocks = function (defaultXml) {
  try {
    var loadOnce = window.sessionStorage.loadOnceBlocks;
  } catch (e) {
    // Firefox sometimes throws a SecurityError when accessing sessionStorage.
    // Restarting Firefox fixes this, so it looks like a bug.
    // Firefox隐私模式安全限制处理
    var loadOnce = null;
  }
  //加载优先级：URL哈希 > 临时存储 > 默认配置 > 持久化存储
  if ('BlocklyStorage' in window && window.location.hash.length > 1) {
    // An href with #key trigers an AJAX call to retrieve saved blocks.
    BlocklyStorage.retrieveXml(window.location.hash.substring(1));//?????????????????????????????
  } else if (loadOnce) {
    // Language switching stores the blocks during the reload.
    delete window.sessionStorage.loadOnceBlocks;
    var xml = Blockly.Xml.textToDom(loadOnce);
    Blockly.Xml.domToWorkspace(xml, Code.workspace);
  } else if (defaultXml) {
    // Load the editor with default starting blocks.
    var xml = Blockly.Xml.textToDom(defaultXml);
    Blockly.Xml.domToWorkspace(xml, Code.workspace);
  } else if ('BlocklyStorage' in window) {
    // Restore saved blocks in a separate thread so that subsequent
    // initialization is not affected from a failed load.
    window.setTimeout(BlocklyStorage.restoreBlocks, 0);
  }
};

/**
 * Save the blocks and reload with a different language.
 */
Code.changeLanguage = function () {
  // Store the blocks for the duration of the reload.
  // This should be skipped for the index page, which has no blocks and does
  // not load Blockly.
  // MSIE 11 does not support sessionStorage on file:// URLs.
  if (typeof Blockly != 'undefined' && window.sessionStorage) {
    var xml = Blockly.Xml.workspaceToDom(Code.workspace);
    var text = Blockly.Xml.domToText(xml);
    window.sessionStorage.loadOnceBlocks = text;
  }

  var languageMenu = document.getElementById('languageMenu');
  var newLang = encodeURIComponent(
    languageMenu.options[languageMenu.selectedIndex].value);
  var search = window.location.search;//??????????????????????????????????????
  if (search.length <= 1) {
    search = '?lang=' + newLang;
  } else if (search.match(/[?&]lang=[^&]*/)) {
    search = search.replace(/([?&]lang=)[^&]*/, '$1' + newLang);
  } else {
    search = search.replace(/\?/, '?lang=' + newLang + '&');
  }

  window.location = window.location.protocol + '//' +
    window.location.host + window.location.pathname + search;
};

/**
 * Bind a function to a button's click event.
 * On touch enabled browsers, ontouchend is treated as equivalent to onclick.
 * @param {!Element|string} el Button element or ID thereof.
 * @param {!Function} func Event handler to bind.
 */
Code.bindClick = function (el, func) {
  if (typeof el == 'string') {
    el = document.getElementById(el);
  }
  el.addEventListener('click', func, true);
  el.addEventListener('touchend', func, true);
};

/**
 * Load the Prettify CSS and JavaScript.
 */
Code.importPrettify = function () {
  var script = document.createElement('script');
  script.setAttribute('src', '../../../code-prettify/loader/run_prettify.js');//修改run_prettify.js路径
  //https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js
  document.head.appendChild(script);
};

/**
 * Compute the absolute coordinates and dimensions of an HTML element.
 * @param {!Element} element Element to match.
 * @return {!Object} Contains height, width, x, and y properties.
 * @private
 */
Code.getBBox_ = function (element) {
  var height = element.offsetHeight;
  var width = element.offsetWidth;
  var x = 0;
  var y = 0;
  do {
    x += element.offsetLeft;
    y += element.offsetTop;
    element = element.offsetParent;
  } while (element);
  return {
    height: height,
    width: width,
    x: x,
    y: y
  };
};

/**
 * User's language (e.g. "en").
 * 获取语言
 * @type {string}
 */
Code.LANG = Code.getLang();

/**
 * List of tab names.
 * @private  修改界面显示Block 数量 新增csharp llrobot
 */
Code.TABS_ = ['blocks', 'csharp', 'llrobot', 'javascript', 'php', 'python', 'dart', 'lua', 'xml'];

/**
 * 会触发 workspaceToCode / workspaceToDom 的预览 Tab（不含 blocks）。
 * @private
 */
Code.PREVIEW_TABS_ = ['csharp', 'llrobot', 'javascript', 'php', 'python', 'dart', 'lua', 'xml'];

/** 工作区自上次预览刷新后是否有改动。 */
Code.previewStale_ = true;

Code.selected = 'blocks';//Initalize the selected tabs

/**
 * 当前选中 Tab 是否需要代码/ XML 预览。
 * @return {boolean}
 * @private
 */
Code.needsPreviewRefresh_ = function () {
  return Code.PREVIEW_TABS_.indexOf(Code.selected) !== -1;
};

/**
 * 轻量 change 监听：仅标记预览过期，不在拖动/编辑时全量 workspaceToCode。
 * @param {!Blockly.Events.Abstract} event Workspace change event.
 * @private
 */
Code.onWorkspaceChange_ = function (event) {
  if (!event || event.type === Blockly.Events.UI) {
    return;
  }
  if (!Blockly.Events.isEnabled()) {
    return;
  }
  if (Code.workspace && Code.workspace.isDragging()) {
    return;
  }
  Code.previewStale_ = true;
};

/**
 * 标记预览需要刷新（加载 XML 等批量操作后调用）。
 */
Code.invalidatePreview = function () {
  Code.previewStale_ = true;
};

/**
 * 离开 GCode/预览 Tab 或 WebView 尺寸变化后，重新铺排 workspace 与浮层按钮。
 * @private
 */
Code._layoutResizeHandler_ = null;

Code.scheduleLayoutRefresh_ = function () {
  var run = function () {
    try {
      if (Code._layoutResizeHandler_) {
        Code._layoutResizeHandler_();
      } else {
        window.dispatchEvent(new Event('resize'));
      }
      if (Code.workspace) {
        if (Code.selected === 'blocks') {
          Code.workspace.setVisible(true);
        }
        Blockly.svgResize(Code.workspace);
      }
      if (typeof Code.relayoutToolboxUi_ === 'function') {
        Code.relayoutToolboxUi_();
      }
    } catch (e) {
      console.warn('scheduleLayoutRefresh_', e);
    }
  };
  run();
  window.setTimeout(run, 50);
  window.setTimeout(run, 180);
  window.setTimeout(run, 1000);
};

/**
 * WebView 在隐藏状态下加载工程时，SVG 文字宽度会为 0，导致 M/D/T 编号槽位空白。
 * 显示 WebView 或加载 XML 后调用，清缓存并重绘全部块与行内注释。
 */
Code.refreshWorkspaceAfterLoad_ = function () {
  if (!Code.workspace) {
    return;
  }
  try {
    if (Blockly.Field && Blockly.Field.cacheWidths_) {
      Blockly.Field.cacheWidths_ = null;
    }
    var blocks = Code.workspace.getAllBlocks(false);
    for (var i = 0; i < blocks.length; i++) {
      var block = blocks[i];
      if (block.comment && typeof block.comment.setText === 'function') {
        var commentText = block.comment.text_;
        if (commentText != null && commentText !== '') {
          block.comment.setText(commentText);
        }
      }
      if (block.rendered) {
        block.render(false);
      }
    }
    Blockly.svgResize(Code.workspace);
    if (typeof Code.relayoutToolboxUi_ === 'function') {
      Code.relayoutToolboxUi_();
    }
  } catch (e) {
    console.warn('refreshWorkspaceAfterLoad_', e);
  }
};

/**
 * 对单个块栈折叠再展开，强制重算内部连接与 SVG 布局。
 * @param {!Blockly.BlockSvg} block
 */
Code.stabilizeBlockStack_ = function (block) {
  if (!block || !block.rendered || block.isInFlyout) {
    return;
  }
  if (typeof block.setCollapsed === 'function') {
    var collapsed = block.isCollapsed();
    block.setCollapsed(!collapsed);
    block.setCollapsed(collapsed);
  } else if (typeof block.render === 'function') {
    block.render();
  }
};

/**
 * 模拟顶层块折叠再展开，强制重算连接与拖拽坐标（等同用户手动折叠/展开）。
 * AI 侧栏开合导致 WebView 尺寸变化后调用。
 */
Code.recomputeWorkspaceBlockLayout_ = function () {
  if (!Code.workspace) {
    return;
  }
  try {
    if (typeof Code.scheduleLayoutRefresh_ === 'function') {
      Code.scheduleLayoutRefresh_();
    }
    Blockly.Events.disable();
    var tops = Code.workspace.getTopBlocks(false);
    for (var i = 0; i < tops.length; i++) {
      Code.stabilizeBlockStack_(tops[i]);
    }
    Blockly.svgResize(Code.workspace);
    if (Code.workspace.updateScreenCalculations_) {
      Code.workspace.updateScreenCalculations_();
    }
  } catch (e) {
    console.warn('recomputeWorkspaceBlockLayout_', e);
  } finally {
    Blockly.Events.enable();
  }
};

/**
 * AI 侧栏改变 WebView 宽度后，拖拽松手时块栈可能散架。
 * 在拖拽开始刷新 startXY_，松手后稳定根块栈（等同手动折叠/展开）。
 */
Code._dragRelayoutFixInstalled_ = false;

Code.installDragRelayoutFix_ = function () {
  if (Code._dragRelayoutFixInstalled_ || !Blockly.BlockDragger) {
    return;
  }
  Code._dragRelayoutFixInstalled_ = true;

  var origStart = Blockly.BlockDragger.prototype.startBlockDrag;
  Blockly.BlockDragger.prototype.startBlockDrag = function (currentDragDeltaXY) {
    if (this.workspace_ && this.workspace_.updateScreenCalculations_) {
      this.workspace_.updateScreenCalculations_();
    }
    this.startXY_ = this.draggingBlock_.getRelativeToSurfaceXY();
    origStart.call(this, currentDragDeltaXY);
  };

  var origEnd = Blockly.BlockDragger.prototype.endBlockDrag;
  Blockly.BlockDragger.prototype.endBlockDrag = function (e, currentDragDeltaXY) {
    var root = this.draggingBlock_ ?
        this.draggingBlock_.getRootBlock() : null;
    origEnd.call(this, e, currentDragDeltaXY);
    if (!root || !root.workspace || root.disposed) {
      return;
    }
    try {
      if (root.workspace.updateScreenCalculations_) {
        root.workspace.updateScreenCalculations_();
      }
      Code.stabilizeBlockStack_(root);
      var bumpDelay = (typeof Blockly.BUMP_DELAY === 'number') ?
          Blockly.BUMP_DELAY + 40 : 290;
      window.setTimeout(function () {
        if (root.workspace && !root.disposed) {
          Code.stabilizeBlockStack_(root);
        }
      }, bumpDelay);
    } catch (err) {
      console.warn('drag relayout fix', err);
    }
  };
};

/**
 * 加载 XML 后分阶段刷新布局与块渲染（Windows WebView2 需多次重绘）。
 */
Code.scheduleWorkspaceRerenderAfterLoad_ = function () {
  Code.scheduleLayoutRefresh_();
  window.setTimeout(Code.refreshWorkspaceAfterLoad_, 100);
  window.setTimeout(Code.refreshWorkspaceAfterLoad_, 500);
  window.setTimeout(Code.refreshWorkspaceAfterLoad_, 1200);
};

/**
 * 桌面点击事件 根据点击坐面
 * Switch the visible pane when a tab is clicked.
 * @param {string} clickedName Name of tab  m.
 */
Code.tabClick = function (clickedName) {
  // If the XML tab was open, save and render the content.
  if (document.getElementById('tab_xml').className == 'tabon') {
    var xmlTextarea = document.getElementById('content_xml');
    var xmlText = xmlTextarea.value;
    var xmlDom = null;
    try {
      xmlDom = Blockly.Xml.textToDom(xmlText);
    } catch (e) {
      var q =
        window.confirm(MSG['badXml'].replace('%1', e));
      if (!q) {
        // Leave the user on the XML tab.
        return;
      }
    }
    if (xmlDom) {
      Code.workspace.clear();
      Blockly.Xml.domToWorkspace(xmlDom, Code.workspace);
    }
  }

  if (document.getElementById('tab_blocks').className == 'tabon') {
    Code.workspace.setVisible(false);
  }
  // Deselect all tabs and hide all panes.
  for (var i = 0; i < Code.TABS_.length; i++) {
    var name = Code.TABS_[i];
    document.getElementById('tab_' + name).className = 'taboff';
    document.getElementById('content_' + name).style.visibility = 'hidden';
  }

  // Select the active tab.
  Code.selected = clickedName;
  document.getElementById('tab_' + clickedName).className = 'tabon';
  // Show the selected pane.
  document.getElementById('content_' + clickedName).style.visibility =
    'visible';
  Code.renderContent(true);
  if (clickedName == 'blocks') {
    Code.workspace.setVisible(true);
  }
  Code.scheduleLayoutRefresh_();
};

/**
 *
使用从块生成的内容填充当前选定的窗格。
 * Populate the currently selected pane with content generated from the blocks.
 * @param {boolean=} opt_force 为 true 时强制生成（切换 Tab）；否则仅在预览过期时生成。
 */
Code.renderContent = function (opt_force) {
  if (!Code.needsPreviewRefresh_()) {
    return;
  }
  if (!opt_force && !Code.previewStale_) {
    return;
  }
  var content = document.getElementById('content_' + Code.selected);
  // Initialize the pane.
  if (content.id == 'content_xml') {
    var xmlTextarea = document.getElementById('content_xml');
    var xmlDom = Blockly.Xml.workspaceToDom(Code.workspace);
    var xmlText = Blockly.Xml.domToPrettyText(xmlDom);
    xmlTextarea.value = xmlText;
    xmlTextarea.focus();
  } else if (content.id == 'content_javascript') {
    var code = Blockly.JavaScript.workspaceToCode(Code.workspace);
    content.textContent = code;
    if (typeof PR.prettyPrintOne == 'function') {
      code = content.textContent;
      code = PR.prettyPrintOne(code, 'js');
      content.innerHTML = code;
    }
  } else if (content.id == 'content_python') {
    code = Blockly.Python.workspaceToCode(Code.workspace);
    content.textContent = code;
    if (typeof PR.prettyPrintOne == 'function') {
      code = content.textContent;
      code = PR.prettyPrintOne(code, 'py');
      content.innerHTML = code;
    }
  } else if (content.id == 'content_php') {
    code = Blockly.PHP.workspaceToCode(Code.workspace);
    content.textContent = code;
    if (typeof PR.prettyPrintOne == 'function') {
      code = content.textContent;
      code = PR.prettyPrintOne(code, 'php');
      content.innerHTML = code;
    }
  } else if (content.id == 'content_dart') {
    code = Blockly.Dart.workspaceToCode(Code.workspace);
    content.textContent = code;
    if (typeof PR.prettyPrintOne == 'function') {
      code = content.textContent;
      code = PR.prettyPrintOne(code, 'dart');
      content.innerHTML = code;
    }
  } else if (content.id == 'content_lua') {

    code = Blockly.GCode.workspaceToCode(Code.workspace);
    content.textContent = code;
    // code = Blockly.Lua.workspaceToCode(Code.workspace);
    // content.textContent = code;
    // if (typeof PR.prettyPrintOne == 'function') {
    //   code = content.textContent;
    //   code = PR.prettyPrintOne(code, 'lua');
    //   content.innerHTML = code;
    // }
  } else if (content.id == 'content_csharp') {
    /**
     *  添加 CSharp 栏显示 转换图形化程序为CSharp代码
     * @type {string}
     */
    Blockly.CustomConfig.CSharpProgramCurrentLineIndex = 0;//程序行号初始化
    Blockly.CSharp.workspaceToCodeError = false;
    Blockly.CSharp.ComPortList = [];
    code = Blockly.CSharp.workspaceToCode(Code.workspace);
    content.textContent = code;
    if (typeof PR.prettyPrintOne == 'function') {
      code = content.textContent;
      code = PR.prettyPrintOne(code, 'cs');
      content.innerHTML = code;
    }
  } else if (content.id == 'content_llrobot') {
    /**
     * 添加 LLRobot栏显示 转换图形化程序为描述性文字语言
     * @type {string}
     */
    Blockly.CustomConfig.CSharpProgramCurrentLineIndex = 0;//程序行号初始化
    Blockly.CSharp.workspaceToCodeError = false;
    Blockly.CSharp.ComPortList = [];
    code = Blockly.LLRobot.workspaceToCode(Code.workspace);
    content.textContent = code;
    if (typeof PR.prettyPrintOne == 'function') {
      code = content.textContent;
      code = PR.prettyPrintOne(code, 'll');
      content.innerHTML = code;
    }
  }
  Code.previewStale_ = false;
};

/**
 *
 * 初始化函数
 * Initialize Blockly.  Called on page load.
 */
Code.init = function () {

  Code.initLanguage();
  var rtl = Code.isRtl(); //布局
  var container = document.getElementById('content_area');//获取content_area的空间
  //跟随浏览器自适应调整大小  begin
  var onresize = function (e) {
    var bBox = Code.getBBox_(container);//获取浏览器的长宽高
    for (var i = 0; i < Code.TABS_.length; i++) {
      //设置div content_block 位置以及宽度和高度
      var el = document.getElementById('content_' + Code.TABS_[i]);
      el.style.top = bBox.y + 'px';//
      el.style.left = bBox.x + 'px';
      // Height and width need to be set, read back, then set again to
      // compensate for scrollbars.
      el.style.height = bBox.height + 'px';
      el.style.height = (2 * bBox.height - el.offsetHeight) + 'px';
      el.style.width = bBox.width + 'px';
      el.style.width = (2 * bBox.width - el.offsetWidth) + 'px';
    }
    // Make the 'Blocks' tab line up with the toolbox.
    if (Code.workspace && Code.workspace.toolbox_.width) {
      document.getElementById('tab_blocks').style.minWidth =
        (Code.workspace.toolbox_.width - 38) + 'px';
      // Account for the 19 pixel margin and on each side.
    }
  };
  window.addEventListener('resize', onresize, false);
  Code._layoutResizeHandler_ = onresize;
  //跟随浏览器自适应调整大小   end

  // The toolbox XML specifies each category name using Blockly's messaging
  // format (eg. `<category name="%{BKY_CATLOGIC}">`).
  // These message keys need to be defined in `Blockly.Msg` in order to
  // be decoded by the library. Therefore, we'll use the `MSG` dictionary that's
  // been defined for each language to import each category name message
  // into `Blockly.Msg`.
  // TODO: Clean up the message files so this is done explicitly instead of
  // through this for-loop.
  for (var messageKey in MSG) {
    if (goog.string.startsWith(messageKey, 'cat')) {
      Blockly.Msg[messageKey.toUpperCase()] = MSG[messageKey];
    }
  }

  // Construct the toolbox XML.
  var toolboxText = document.getElementById('toolbox').outerHTML;
  var toolboxXml = Blockly.Xml.textToDom(toolboxText);

  /**
   * 注入函数
   *将workspace注入到toolbox中
   *通过toolboxXml创建div class=blocklyToolboxDiv Blockly.init_ = function(mainWorkspace)
   */
  Code.workspace = Blockly.inject('content_blocks',
    {
      grid:
      {
        spacing: 0,///////////////////////// 0 no grid
        length: 1,
        colour: '#ccc',
        snap: false
      },
      media: '../../media/',//资源路径
      rtl: rtl,
      toolbox: toolboxXml,
      trashcan: false,
      sounds: false,
      scrollbars: true,
      zoom:
      {
        controls: true,
        wheel: true,
        startScale: 0.85
      }
    });

  Code.workspace.addChangeListener(Code.onWorkspaceChange_);
  Code.installDragRelayoutFix_();

  // Add to reserved word list: Local variables in execution environment (runJS)
  // and the infinite loop detection function.
  Blockly.JavaScript.addReservedWords('code,timeouts,checkTimeout');

  /**
   * 自定义创建 保存 新建 蓝牙 帮助 4个按钮
   **/
  var divInjectionDiv = document.getElementById('content_blocks');
  // 自定义 UI 覆盖层：避免在模拟器/WebView 里把 HTML 塞进 SVG（会导致 input 不能输入/按钮点不到）
  var uiHost = divInjectionDiv && divInjectionDiv.querySelector('.custom-ui-host');
  if (!uiHost && divInjectionDiv) {
    uiHost = document.createElement('div');
    uiHost.className = 'custom-ui-host';
    uiHost.style.position = 'absolute';
    uiHost.style.left = '0';
    uiHost.style.top = '0';
    uiHost.style.width = '100%';
    uiHost.style.height = '100%';
    uiHost.style.zIndex = '9999';
    uiHost.style.pointerEvents = 'none';
    divInjectionDiv.appendChild(uiHost);
  }
  var SaveDocDiv = document.createElement("div");
  var divcontainer = document.getElementById('content_area');

  // 网页/APP 尺寸兼容（模拟器里 bound.getWidth() 可能返回 0/非数字，导致输入框不可用、上下按钮消失）
  // web: divcontainer.offsetHeight；app: bound.getWidth()（历史命名：返回高度）
  var ParentHeight = divcontainer.offsetHeight;
  if (!isWeb) {
    var appHeight = null;
    try {
      if (typeof bound !== 'undefined' && bound && typeof bound.getWidth === 'function') {
        appHeight = Number(bound.getWidth());
      }
    } catch (e) {
      appHeight = null;
    }
    if (appHeight && isFinite(appHeight) && appHeight > 0) {
      ParentHeight = appHeight;
    }
  }
  if (!ParentHeight || ParentHeight < 100) {
    ParentHeight = (divcontainer && divcontainer.offsetHeight) || window.innerHeight || 600;
  }

  var ParentWidth = divcontainer.offsetWidth || window.innerWidth || 800;

  // 给按钮/输入框一个最小可用尺寸，避免高度过小导致“无法输入/按钮不见”
  var IconHeight = Math.max(24, ParentHeight * Blockly.CustomConfig.DocIcon_Height);
  var IconTop = Math.max(4, ParentHeight * Blockly.CustomConfig.DocIcon_Top);
  var rightpos = 6.7 * IconHeight;
  SaveDocDiv.setAttribute('class', 'SaveDocDiv');
  SaveDocDiv.style.height = IconHeight * 1.3 + 'px';
  SaveDocDiv.style.width = IconHeight * 1.3 + 'px';
  SaveDocDiv.style.top = IconTop + 'px';
  SaveDocDiv.style.right = rightpos + 'px';
  //SaveDocDiv.style.backgroundColor = Blockly.CustomConfig.SaveDoc_BackGroundColor_RGB;
  SaveDocDiv.title = "保存";

  var NewDocDiv = document.createElement("div");
  NewDocDiv.setAttribute('class', 'NewDocDiv');
  NewDocDiv.style.height = IconHeight * 1.3 + 'px';
  NewDocDiv.style.width = IconHeight * 1.3 + 'px';
  NewDocDiv.style.top = IconTop + 'px';
  rightpos = 1.5*IconHeight;
  NewDocDiv.style.right = rightpos + 'px';
  //NewDocDiv.style.backgroundColor = Blockly.CustomConfig.NewDoc_BackGroundColor_RGB;
  NewDocDiv.title = "返回";

  var HelperDiv = document.createElement("div");
  HelperDiv.setAttribute('class', 'HelperDiv');
  HelperDiv.style.height = IconHeight * 1.3 + 'px';
  HelperDiv.style.width = IconHeight * 1.3 + 'px';
  HelperDiv.style.top = IconTop + 'px';
  rightpos = IconHeight * 3.3;
  HelperDiv.style.right = rightpos + 'px';
  //HelperDiv.style.backgroundColor = Blockly.CustomConfig.Helper_BackGroundColor_RGB;
  HelperDiv.title = "帮助";

  var BlueToothDiv = document.createElement("div");
  BlueToothDiv.setAttribute('class', 'BlueToothDiv');
  BlueToothDiv.style.height = IconHeight * 1.3 + 'px';
  BlueToothDiv.style.width = IconHeight * 1.3 + 'px';
  BlueToothDiv.style.top = IconTop + 'px';
  rightpos = 5.1 * IconHeight;
  BlueToothDiv.style.right = rightpos + 'px';
  //BlueToothDiv.style.backgroundColor = Blockly.CustomConfig.BlueTooth_BackGroundColor_RGB;
  BlueToothDiv.title = "函数";



  //搜索框
  var Searchbg = document.createElement("div");
  Searchbg.className = "Searchbg"
  Searchbg.style.height = IconHeight * 1.6 + 'px';
  Searchbg.style.width = IconHeight * 9.5 + 'px';
  Searchbg.style.top = IconTop * 0.6 + 'px';
  rightpos = 8.3 * IconHeight;
  Searchbg.style.right = rightpos + 'px';
  Searchbg.id = "Searchbg";



  var SearchInput = document.createElement("input");
  SearchInput.className = "SearchInput"
  SearchInput.style.height = IconHeight + 'px';
  SearchInput.style.width = IconHeight * 3.5 + 'px';
  SearchInput.style.top = IconTop * 1.35 + 'px';
  rightpos = 13.8 * IconHeight;
  SearchInput.style.right = rightpos + 'px';
  SearchInput.id = "searchInput";


  var SearchButton = document.createElement("div");
  SearchButton.setAttribute('class', 'SearchButton');
  SearchButton.style.height = IconHeight * 1 + 'px';
  SearchButton.style.width = IconHeight * 1 + 'px';
  SearchButton.style.top = IconTop * 1.5 + 'px';
  rightpos = 12.4 * IconHeight;
  SearchButton.style.right = rightpos + 'px';
  //HelperDiv.style.backgroundColor = Blockly.CustomConfig.Helper_BackGroundColor_RGB;
  SearchButton.title = "搜索";



  var SearchGrup = document.createElement("div");
  SearchGrup.setAttribute('class', 'SearchGrup');
  SearchGrup.style.height = IconHeight * 1 + 'px';
  SearchGrup.style.width = IconHeight * 1 + 'px';
  SearchGrup.style.top = IconTop * 1.5 + 'px';
  rightpos = 8.3 * IconHeight;
  SearchGrup.style.right = rightpos + 'px';
  //HelperDiv.style.backgroundColor = Blockly.CustomConfig.Helper_BackGroundColor_RGB;
  SearchGrup.title = "关闭";

  var SearchGrup_open = document.createElement("div");
  SearchGrup_open.setAttribute('class', 'SearchGrup_open');
  SearchGrup_open.style.height = IconHeight * 1 + 'px';
  SearchGrup_open.style.width = IconHeight * 1 + 'px';
  SearchGrup_open.style.top = IconTop * 1.5 + 'px';
  rightpos = 8.3 * IconHeight;
  SearchGrup_open.style.right = rightpos + 'px';
  //HelperDiv.style.backgroundColor = Blockly.CustomConfig.Helper_BackGroundColor_RGB;
  SearchGrup_open.title = "打开";



  var SearchUpButton = document.createElement("div");
  SearchUpButton.setAttribute('class', 'SearchUpButton');
  SearchUpButton.style.height = IconHeight * 1 + 'px';
  SearchUpButton.style.width = IconHeight * 1 + 'px';
  SearchUpButton.style.top = IconTop * 1.5 + 'px';
  rightpos = 9.6 * IconHeight;
  SearchUpButton.style.right = rightpos + 'px';
  //HelperDiv.style.backgroundColor = Blockly.CustomConfig.Helper_BackGroundColor_RGB;
  SearchUpButton.title = "下一个";


  var SearchDownButton = document.createElement("div");
  SearchDownButton.setAttribute('class', 'SearchDownButton');
  SearchDownButton.style.height = IconHeight * 1 + 'px';
  SearchDownButton.style.width = IconHeight * 1 + 'px';
  SearchDownButton.style.top = IconTop * 1.5 + 'px';
  rightpos = 10.9 * IconHeight;
  SearchDownButton.style.right = rightpos + 'px';
  //HelperDiv.style.backgroundColor = Blockly.CustomConfig.Helper_BackGroundColor_RGB;
  SearchDownButton.title = "上一个";

  var SearchResultsPanel = document.createElement('div');
  SearchResultsPanel.className = 'SearchResultsPanel';
  SearchResultsPanel.id = 'searchResultsPanel';
  SearchResultsPanel.style.top = (IconTop * 0.6 + IconHeight * 1.9 + 4) + 'px';
  SearchResultsPanel.style.right = (8.3 * IconHeight) + 'px';
  SearchResultsPanel.style.width = (IconHeight * 14) + 'px';
  var SearchResultsHeader = document.createElement('div');
  SearchResultsHeader.className = 'SearchResultsHeader';
  SearchResultsHeader.id = 'searchResultsHeader';
  var SearchResultsTitle = document.createElement('span');
  SearchResultsTitle.className = 'SearchResultsTitle';
  SearchResultsTitle.id = 'searchResultsTitle';
  var SearchResultsCollapseBtn = document.createElement('button');
  SearchResultsCollapseBtn.className = 'SearchResultsCollapseBtn';
  SearchResultsCollapseBtn.type = 'button';
  SearchResultsCollapseBtn.title = '收起';
  SearchResultsCollapseBtn.textContent = '▲';
  SearchResultsCollapseBtn.addEventListener('click', function (e) {
    e.stopPropagation();
    Code.hideSearchResultsPanel();
  }, true);
  SearchResultsHeader.appendChild(SearchResultsTitle);
  SearchResultsHeader.appendChild(SearchResultsCollapseBtn);
  var SearchResultsList = document.createElement('div');
  SearchResultsList.className = 'SearchResultsList';
  SearchResultsList.id = 'searchResultsList';
  SearchResultsPanel.appendChild(SearchResultsHeader);
  SearchResultsPanel.appendChild(SearchResultsList);
  Code.searchResultsPanel = SearchResultsPanel;

  //添加鼠标单击事件
  SaveDocDiv.addEventListener('click', Code.SaveDoc, true);
  NewDocDiv.addEventListener('click', Code.NewDoc, true);
  BlueToothDiv.addEventListener('click', Code.BlueTooth, true);
  HelperDiv.addEventListener('click', Code.Helper, true);
  SearchButton.addEventListener('click', Code.SearchData, true);
  SearchUpButton.addEventListener('click', Code.SearchDataUp, true);
  SearchDownButton.addEventListener('click', Code.SearchDataDown, true);
  SearchGrup.addEventListener('click', Code.SearchGrup_none, true);
  SearchGrup_open.addEventListener('click', Code.SearchGrup_block, true);
  SearchInput.addEventListener('keydown', function (e) {
    if (e.key === 'Enter') {
      Code.SearchData();
    }
  }, true);

  //添加到DIV元素中
  // 挂到覆盖层上，确保在 SVG 之上且可交互
  [Searchbg, SearchInput, SaveDocDiv, NewDocDiv, BlueToothDiv, HelperDiv,
    SearchButton, SearchGrup, SearchGrup_open, SearchDownButton, SearchUpButton,
    SearchResultsPanel].forEach(function(el) {
    if (!el) return;
    el.style.pointerEvents = 'auto';
    uiHost.appendChild(el);
  });

  /**
   *  图片比例 动作图标比例1:1 动作文字图片比例2:1 高:宽
   *  整个toolbox 比例按照 高:宽等于 1:1.5设置
   *  屏幕视野内将toolbox分成8个等份
   */
  Code.relayoutToolboxUi_ = function () {
    var treerow = document.getElementById('content_area');
    if (!treerow || !Blockly.CustomConfig) {
      return;
    }
    for (var j = 0; j < Blockly.CustomConfig.BlocklyTreeDivNum; j++) {
      var row = document.getElementById(':' + (j + 1).toString());
      if (!row || !row.firstChild || !row.firstChild.childNodes[1]) {
        continue;
      }
      var spans = row.firstChild.childNodes[1];
      var height = treerow.offsetHeight / Blockly.CustomConfig.BlocklyTreeDivNum;
      var spanwidth = height * 1.0;
      spans.style.boxSizing = 'border-box';
      spans.style.width = spanwidth + 'px';
      spans.style.lineHeight = height + 'px';
      var spanlabel = document.getElementById(':' + (j + 1).toString() + '.label');
      if (spanlabel) {
        spanlabel.style.boxSizing = 'border-box';
        spanlabel.style.lineHeight = height + 'px';
        spanlabel.style.width = (height * 0.5) + 'px';
      }
    }
    var divblocklyToolboxDivs = document.getElementsByClassName('blocklyToolboxDiv');
    if (divblocklyToolboxDivs.length > 0) {
      var divwidth = treerow.offsetHeight * 0.78 / Blockly.CustomConfig.BlocklyTreeDivNum;
      divblocklyToolboxDivs[0].style.width = divwidth + 'px';
    }
  };

  Code.relayoutToolboxUi_();

  var element1 = document.createElement("p");
  element1.textContent = Blockly.Msg.MAIN_TOOL_LOGIC;
  element1.id = "mainToolName_Logic";
  document.body.appendChild(element1);
  var element2 = document.createElement("p");
  element2.textContent = Blockly.Msg.MAIN_TOOL_VARIABLE;
  element2.id = "mainToolName_Variable";
  document.body.appendChild(element2);
  var element3 = document.createElement("p");
  element3.textContent = Blockly.Msg.MAIN_TOOL_MOVE;
  element3.id = "mainToolName_Move";
  document.body.appendChild(element3);
  var element4 = document.createElement("p");
  element4.textContent = Blockly.Msg.MAIN_TOOL_CUSTOM;
  element4.id = "mainToolName_Custom";
  document.body.appendChild(element4);
  // 获取所有p标签
  var paragraphs = document.querySelectorAll('p');

  // 遍历所有p标签并设置pointer-events属性为none
  paragraphs.forEach(function (paragraph) {
    paragraph.style.pointerEvents = 'none';
  });
  Code.loadBlocks('');

  if ('BlocklyStorage' in window) {
    // Hook a save function onto unload.
    BlocklyStorage.backupOnUnload(Code.workspace);
  }

  Code.tabClick(Code.selected);

  //Code.bindClick('trashButton',//*********************************************
  //    function() {Code.discard(); Code.renderContent();});//*****************************
  //Code.bindClick('runButton', Code.runJS);//***************************************
  // Disable the link button if page isn't backed by App Engine storage.
  //var linkButton = document.getElementById('linkButton');//**************************************
  if ('BlocklyStorage' in window) {
    BlocklyStorage['HTTPREQUEST_ERROR'] = MSG['httpRequestError'];
    BlocklyStorage['LINK_ALERT'] = MSG['linkAlert'];
    BlocklyStorage['HASH_ERROR'] = MSG['hashError'];
    BlocklyStorage['XML_ERROR'] = MSG['xmlError'];
    //Code.bindClick(linkButton,//*************************************
    //    function() {BlocklyStorage.link(Code.workspace);});//*************************
  } //else if (linkButton) {//**********************
  //linkButton.className = 'disabled';//**********************
  //}//**********************

  for (var i = 0; i < Code.TABS_.length; i++) {
    var name = Code.TABS_[i];
    Code.bindClick('tab_' + name,
      function (name_) { return function () { Code.tabClick(name_); }; }(name));
  }
  onresize();
  Blockly.svgResize(Code.workspace);//??????????????????????????????????
  Code.workspace.clear();
  //Code.loadXML("main");
  // Lazy-load the syntax-highlighting.
  window.setTimeout(Code.importPrettify, 1);
  //Code.loadComplete();
};

/**
 * Initialize the page language.
 */
Code.initLanguage = function () {
  // Set the HTML's language and direction.
  var rtl = Code.isRtl();
  document.dir = rtl ? 'rtl' : 'ltr';
  document.head.parentElement.setAttribute('lang', Code.LANG);

  // Sort languages alphabetically.
  var languages = [];
  for (var lang in Code.LANGUAGE_NAME) {
    languages.push([Code.LANGUAGE_NAME[lang], lang]);
  }
  var comp = function (a, b) {
    // Sort based on first argument ('English', 'Русский', '简体字', etc).
    if (a[0] > b[0]) return 1;
    if (a[0] < b[0]) return -1;
    return 0;
  };
  languages.sort(comp);
  // Populate the language selection menu.
  var languageMenu = document.getElementById('languageMenu');
  languageMenu.options.length = 0;
  for (var i = 0; i < languages.length; i++) {
    var tuple = languages[i];
    var lang = tuple[tuple.length - 1];
    var option = new Option(tuple[0], lang);
    if (lang == Code.LANG) {
      option.selected = true;
    }
    languageMenu.options.add(option);
  }
  languageMenu.addEventListener('change', Code.changeLanguage, true);

  // Inject language strings.
  //document.title += ' ' + MSG['title'];
  document.getElementById('title').textContent = MSG['title'];
  document.getElementById('tab_blocks').textContent = MSG['blocks'];

  //document.getElementById('linkButton').title = MSG['linkTooltip'];//******************************************
  //document.getElementById('runButton').title = MSG['runTooltip'];//*********************************************
  //document.getElementById('trashButton').title = MSG['trashTooltip'];//*****************************************
};

/**
 * Execute the user's code.
 * Just a quick and dirty eval.  Catch infinite loops.
 */
Code.runJS = function () {
  Blockly.JavaScript.INFINITE_LOOP_TRAP = '  checkTimeout();\n';
  var timeouts = 0;
  var checkTimeout = function () {
    if (timeouts++ > 1000000) {
      throw MSG['timeout'];
    }
  };
  var code = Blockly.JavaScript.workspaceToCode(Code.workspace);
  Blockly.JavaScript.INFINITE_LOOP_TRAP = null;
  try {
    eval(code);
  } catch (e) {
    alert(MSG['badCode'].replace('%1', e));
  }
};

/**
 * Discard all blocks from the workspace.
 */
Code.discard = function () {
  var count = Code.workspace.getAllBlocks().length;
  if (count < 2 ||
    window.confirm(Blockly.Msg.DELETE_ALL_BLOCKS.replace('%1', count))) {
    Code.workspace.clear();
    if (window.location.hash) {
      window.location.hash = '';
    }
  }
};


/**
 * 保存函数事件
 */
Code.SaveDoc = function () {
  var fileName = prompt("请输入保存的函数文件名：");
  if (!fileName) return;
  // web 环境：直接下载；app/模拟器：走 bound.saveFunXML
  if (isWeb) {
    try {
      var blob = new Blob([Code.generateXml()], { type: 'text/plain;charset=utf-8' });
      var url = URL.createObjectURL(blob);
      var a = document.createElement('a');
      a.href = url;
      a.download = fileName;
      a.click();
      URL.revokeObjectURL(url);
    } catch (e) {
      alert('保存失败：' + e);
    }
    return;
  }
  if (typeof bound !== 'undefined' && bound && typeof bound.saveFunXML === 'function') {
    bound.saveFunXML(fileName, Code.generateXml());
  } else {
    alert('当前环境未提供 bound.saveFunXML，无法保存到本地。');
  }
};

/**
 * 返回事件
 */
Code.NewDoc = function () {
  // UILLRobot.alert("提示信息","新建项目功能还在开发中...");
  UILLRobot.confirm("提示信息", "是否保存当前修改!\r\n " +
    "确定:继续编译并保存当前程序!\r\n " +
    "\r\n 取消:不保存修改并退出!\r\n", function (bflag) {
      if (!bflag) {
        // node.getRowElement().style.cursor = 'default';
        Code.saveXMLFileToCSharp("main");
        Code.saveGCodeFileToGCode("main");

        // Code.saveCompileResult("main","config",false);
        bound.exit();//调用exit退出函数 注意函数开头要小写  调用函数不分大小写
        UILLRobot.toast('正在退出,请等待!', 2000);
        return;
      }
      else {
        var CheckCode = Code.checkWorkspaceGCode();
        if (CheckCode) {
          //Code.saveCSharpFileToCSharp("main");
          //保存在本地---G代码和XMl
          Code.saveGCodeFileToGCode("main")
          Code.saveXMLFileToCSharp("main");

          Code.saveCompileResult("main", "config", true);
          bound.updateCompileResult();
          bound.exit();//调用exit退出函数 注意函数开头要小写  调用函数不分大小写
          UILLRobot.toast('保存成功,正在退出,请等待!', 2000);
        }
        else {
          UILLRobot.confirm("提示信息", "当前程序编译失败,请注意红色带感叹号的模块,单击可以显示出错问题!\r\n " + //compileMessage + "\r\n" +
            "确定:继续保存当前程序,无法运行自动程序!\r\n " +
            "\r\n 取消:修改报错模块,重新编译!\r\n", function (flag) {
              if (flag) {
                node.getRowElement().style.cursor = 'default';
                Code.saveXMLFileToCSharp("main");
                Code.saveLLRobotFileToLL("main");
                Code.saveCompileResult("main", "config", false);
                bound.exit();//调用exit退出函数 注意函数开头要小写  调用函数不分大小写
                UILLRobot.toast('正在退出,请等待!', 2000);
              }
              else {
                node.getRowElement().style.cursor = 'default';
                Code.saveCompileResult("main", "config", false);
              }
            });
        }
      }
    });
};

/**
 * 加载函数事件
 */
Code.BlueTooth = function () {
  bound.chooseFunXML();
  var message = "库函数选择完成！";
  alert(message);
  var xml = bound.loadFunXML();
  //console.log("xml:"+xml);
  Code.replaceBlocksfromXml(xml);
  // UILLRobot.alert("提示信息","库函加载完成!");
};


Code.escapeHtml_ = function (text) {
  return String(text == null ? '' : text)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
};

/** 高亮关键字片段（用于结果列表）。 */
Code.highlightKeywordInLabel_ = function (text, keyword) {
  var safe = Code.escapeHtml_(text);
  if (!keyword) {
    return safe;
  }
  var registerKeyword = Blockly.Xml.parseRegisterSearchKeyword_(keyword);
  if (registerKeyword) {
    var parts = registerKeyword.match(Blockly.Xml.REGISTER_KEYWORD_RE_);
    if (parts) {
      var prefix = parts[1].replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      var num = parts[2].replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      var re = new RegExp('(' + prefix + '\\s*' + num + '(?!\\d))', 'gi');
      return safe.replace(re, '<span class="match">$1</span>');
    }
  }
  var compact = keyword.replace(/\s+/g, '');
  if (!compact) {
    return safe;
  }
  var re = new RegExp('(' + compact.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ')', 'gi');
  return safe.replace(re, '<span class="match">$1</span>');
};

/** 列表展示用块：变量读取等子块提升到赋值/比较表达式。 */
Code.getSearchResultDisplayBlock_ = function (block) {
  if (!block) {
    return block;
  }
  var expressionTypes = {
    'math_variable': true,
    'logic_compare': true,
    'logic_operation': true,
    'logic_boolean': true
  };
  if (expressionTypes[block.type]) {
    return block;
  }
  var isVariableLeaf = block.type === 'thread_get_data' ||
      block.type.indexOf('thread_get_') === 0 ||
      block.type === 'math_number';
  if (!isVariableLeaf) {
    return block;
  }
  var cur = block;
  var parent = cur.getParent();
  while (parent) {
    if (parent.getInputWithBlock(cur)) {
      if (expressionTypes[parent.type]) {
        return parent;
      }
      cur = parent;
      parent = cur.getParent();
    } else {
      break;
    }
  }
  return block;
};

/** 匹配块是否位于「如果/循环」等判断条件输入槽内（非执行体）。 */
Code.isSearchResultInCondition_ = function (block) {
  if (!block) {
    return false;
  }
  var cur = block;
  var parent = cur.getParent();
  while (parent) {
    var input = parent.getInputWithBlock(cur);
    if (input) {
      if (/^IF\d+$/.test(input.name)) {
        return true;
      }
      if ((parent.type === 'controls_whileUntil' ||
          parent.type === 'controls_repeat') &&
          input.name === 'BOOL') {
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

/** 单条搜索结果的显示文案。 */
Code.getSearchResultLabel_ = function (block, index) {
  var displayBlock = Code.getSearchResultDisplayBlock_(block);
  var text = '';
  if (displayBlock && displayBlock.toString) {
    text = goog.string.trim(displayBlock.toString(56));
  }
  if (!text) {
    var tokens = Blockly.Xml.getBlockSearchTokens_(displayBlock || block);
    text = goog.string.trim(tokens.join(' '));
  }
  text = text.replace(/\s+/g, ' ');
  if (Code.isSearchResultInCondition_(displayBlock || block)) {
    text = '【判断】' + text;
  }
  if (text.length > 52) {
    text = text.substring(0, 49) + '...';
  }
  var prefix = '';
  var root = block.getRootBlock();
  if (root && (root.type === 'procedures_defnoreturn' ||
      root.type === 'procedures_defreturn')) {
    var procName = root.getFieldValue('NAME');
    if (procName) {
      prefix = procName + ' · ';
    }
  } else if (root && root.type.indexOf('procedures_call') >= 0) {
    var callName = root.getFieldValue('NAME');
    if (callName) {
      prefix = callName + ' · ';
    }
  }
  return (index + 1) + '. ' + prefix + text;
};

Code.hideSearchResultsPanel = function () {
  var panel = Code.searchResultsPanel ||
      document.getElementById('searchResultsPanel');
  if (panel) {
    panel.style.display = 'none';
  }
};

/** 渲染可点击的搜索结果简表。 */
Code.renderSearchResultsPanel = function (keyword) {
  var panel = Code.searchResultsPanel ||
      document.getElementById('searchResultsPanel');
  var title = document.getElementById('searchResultsTitle');
  var list = document.getElementById('searchResultsList');
  if (!panel || !title || !list) {
    return;
  }
  var count = Code.workspace.search_.length;
  list.innerHTML = '';
  if (count === 0) {
    title.textContent = '未找到「' + keyword + '」';
    var empty = document.createElement('div');
    empty.className = 'SearchResultsEmpty';
    empty.textContent = '请尝试其他关键字';
    list.appendChild(empty);
    panel.style.display = 'flex';
    return;
  }
  title.textContent = '共 ' + count + ' 处「' + keyword + '」，点击定位';
  for (var i = 0; i < count; i++) {
  (function (idx) {
      var block = Code.workspace.search_blocks_ &&
          Code.workspace.search_blocks_[idx];
      var item = document.createElement('div');
      item.className = 'SearchResultsItem' +
          (idx === Code.workspace.search_index ? ' active' : '');
      item.title = Code.getSearchResultLabel_(block, idx);
      item.innerHTML = Code.highlightKeywordInLabel_(
          Code.getSearchResultLabel_(block, idx), keyword);
      item.addEventListener('click', function (e) {
        e.stopPropagation();
        Code.gotoSearchResult(idx);
      }, true);
      list.appendChild(item);
    })(i);
  }
  panel.style.display = 'flex';
  var active = list.querySelector('.SearchResultsItem.active');
  if (active && active.scrollIntoView) {
    active.scrollIntoView({block: 'nearest'});
  }
};

Code.updateSearchResultsActiveItem_ = function () {
  var list = document.getElementById('searchResultsList');
  if (!list) {
    return;
  }
  var items = list.getElementsByClassName('SearchResultsItem');
  for (var i = 0; i < items.length; i++) {
    if (i === Code.workspace.search_index) {
      items[i].className = 'SearchResultsItem active';
      if (items[i].scrollIntoView) {
        items[i].scrollIntoView({block: 'nearest'});
      }
    } else {
      items[i].className = 'SearchResultsItem';
    }
  }
};

/** 跳转到第 index 个搜索结果并高亮对应块。 */
Code.gotoSearchResult = function (index) {
  if (!Code.workspace.search_ || !Code.workspace.search_.length) {
    return;
  }
  var len = Code.workspace.search_.length;
  if (index < 0 || index >= len) {
    return;
  }
  Code.workspace.search_index = index;
  var idx = Code.workspace.search_head_index[index];
  var blocks = Code.workspace.getTopBlocks(true);
  var selBlock = Code.workspace.search_blocks_ &&
      Code.workspace.search_blocks_[index] ?
      Code.workspace.search_blocks_[index] : blocks[idx];
  Code.expandBlocksForSearch(selBlock);
  blocks[idx].bringToFront();
  Code.workspace.setScale(1);
  selBlock.select();
  Code.workspace.scrollCenter_xy(
      Code.workspace.search_[index][0] - Code.workspace.head_xy[0],
      Code.workspace.search_[index][1] - Code.workspace.head_xy[1]);
  Code.updateSearchResultsActiveItem_();
};

/** 跳转到搜索结果前展开目标块及其所有折叠的祖先块。 */
Code.expandBlocksForSearch = function (selBlock) {
  if (!selBlock) {
    return;
  }
  var parent = selBlock.getSurroundParent();
  while (parent) {
    if (parent.isCollapsed()) {
      parent.setCollapsed(false);
    }
    parent = parent.getSurroundParent();
  }
  if (selBlock.isCollapsed()) {
    selBlock.setCollapsed(false);
  }
};

Code.SearchData = function () {
  var opt_noId = false;
  Code.workspace.search_ = [];
  Code.workspace.search_blocks_ = []; // 每个匹配结果对应的块引用，跳转时选中该块而非顶层块
  Code.workspace.block_bool_xy = false;
  Code.workspace.head_xy = [];
  Code.workspace.search_index = 0;

  Code.workspace.search_head_index = [];
  Code.workspace.search_head_index_num = 0;

  var key_word = document.getElementById('searchInput').value;
  var blocks = Code.workspace.getTopBlocks(true);
  for (var i = 0, block; block = blocks[i]; i++) {
    Code.workspace.code_serch = '';
    Blockly.Xml.search_MD_XY(block, opt_noId, key_word);

    Code.workspace.search_head_index_num++;
  }
  Blockly.Xml.deduplicateSearchMatches_(Code.workspace);
  Code.renderSearchResultsPanel(key_word);
  if (Code.workspace.search_.length > 0) {
    Code.gotoSearchResult(0);
  }

};

Code.SearchGrup_none = function () {
  var SearchbgObj = document.getElementsByClassName('Searchbg')[0];
  var SearchInputObj = document.getElementsByClassName('SearchInput')[0];
  var SearchButtonObj = document.getElementsByClassName('SearchButton')[0];
  var SearchDownButtonObj = document.getElementsByClassName('SearchDownButton')[0];
  var SearchUpButtonObj = document.getElementsByClassName('SearchUpButton')[0];
  var SearchGrup_openObj = document.getElementsByClassName('SearchGrup_open')[0];
  var SearchGrupObj = document.getElementsByClassName('SearchGrup')[0];
  //    SearchbgObj.style.display='block';
  //    SearchInputObj.style.display='block';
  //    SearchButtonObj.style.display='block';
  //    SearchDownButtonObj.style.display='block';
  //    SearchUpButtonObj.style.display='block';
  if (Code.workspace.hid_group) {
    SearchbgObj.style.display = 'block';
    SearchInputObj.style.display = 'block';
    SearchButtonObj.style.display = 'block';
    SearchDownButtonObj.style.display = 'block';
    SearchUpButtonObj.style.display = 'block';
    Code.workspace.hid_group = false;
  } else {
    SearchbgObj.style.display = 'none';
    SearchInputObj.style.display = 'none';
    SearchButtonObj.style.display = 'none';
    SearchDownButtonObj.style.display = 'none';
    SearchUpButtonObj.style.display = 'none';
    Code.hideSearchResultsPanel();
    Code.workspace.hid_group = true;
  }


};



Code.SearchGrup_block = function () {
  var SearchbgObj = document.getElementsByClassName('Searchbg')[0];
  var SearchInputObj = document.getElementsByClassName('SearchInput')[0];
  var SearchButtonObj = document.getElementsByClassName('SearchButton')[0];
  var SearchDownButtonObj = document.getElementsByClassName('SearchDownButton')[0];
  var SearchUpButtonObj = document.getElementsByClassName('SearchUpButton')[0];
  var SearchGrup_openObj = document.getElementsByClassName('SearchGrup_open')[0];
  var SearchGrupObj = document.getElementsByClassName('SearchGrup')[0];
  SearchbgObj.style.display = 'block';
  SearchInputObj.style.display = 'block';
  SearchButtonObj.style.display = 'block';
  SearchDownButtonObj.style.display = 'block';
  SearchUpButtonObj.style.display = 'block';

};

Code.SearchDataUp = function () {
  if (Code.workspace.search_.length > 0) {
    var len = Code.workspace.search_.length;
    var next = (Code.workspace.search_index + 1) % len;
    Code.gotoSearchResult(next);
  }
};

Code.SearchDataDown = function () {
  if (Code.workspace.search_.length > 0) {
    var prev = Code.workspace.search_index - 1;
    if (prev < 0) {
      prev = Code.workspace.search_.length - 1;
    }
    Code.gotoSearchResult(prev);
  }
};

/**
 * 帮助事件
 */
Code.Helper = function () {

  UILLRobot.alert(
      '版本信息',
      '版本号1.6.5\r\n' +
      '1.6.5:Android Blockly 资源解压与 WebView 全屏修复；Windows 打包脚本修复\r\n' +
      '1.6.4:预览 Tab 仅在切换或编译时生成代码，拖动不再全量 workspaceToCode\r\n' +
      '1.6.3:优化超大嵌套块（数千块）拖动卡顿\r\n' +
      '1.6.2:修复搜索去重误删相邻语句；增强 D400/中文块名匹配\r\n' +
      '1.6.1:搜索结果显示可点击简表，点击或上下键快速定位\r\n' +
      '1.6.0:修复展开块内变量搜索（D0/S0 等 value 子块字段合并）；折叠与展开均可正确统计个数\r\n' +
      '1.5.4:Flutter版—控制器无程序或拉取失败可进入Blockly，WebView加载修复\r\n' +
      '1.3.1:修复折叠块内无法搜索；跳转时自动展开折叠祖先块\r\n' +
      '1.3.0:普通块支持折叠展开；空白处折叠仅函数块、展开全部嵌套块\r\n' +
      '1.2.2:修复加载工程取消后仍弹出文件列表\r\n' +
      '1.2.1:向下兼容普通块也能展开但是不能折叠\r\n' +
      '1.2.0:优化注释显示更加明显\r\n' +
      '1.1.8:优化中文搜索以及搜索高亮\r\n' +
      '1.1.7:优化UI、添加批量操作功能块\r\n' +
      '1.1.6:优化函数折叠不能搜索功能\r\n' +
      '1.1.5:添加小数点操作\r\n' +
      '1.1.4:修复和或运算保存异常不提示\r\n' +
      '1.1.3:添加复制粘贴模块\r\n' +
      '1.1.2:改为精确搜索，并且添加了母块高亮\r\n' +
      '1.1.1:修复了电子齿轮G代码解析分子分母负数有()\r\n' +
      '1.1.0:修复了多重搜索\r\n' +
      '1.0.8:更新了地址偏移，搜索优化\r\n' +
      '1.0.6:优化了圆弧运动的块表达\r\n' +
      '1.0.5:添加了电子齿轮指令\r\n' +
      '1.0.4:添加了圆弧指令，优化了UI界面');

  // Code.saveXmlFile("motion");
};

Code.loadComplete = function () {
  bound.loadComplete(true);

};

Code.saveXMLFileToCSharp = function (filename) {
  bound.saveXML(filename, Code.generateXml());
};

Code.saveCompileResult = function (projectname, filename, result) {
  bound.saveCompileResult(projectname, filename, result);
};

Code.checkWorkspaceGCode = function () {
  Blockly.GCode.workspaceToCodeError = false;
  //Blockly.CSharp.ComPortList = [];
  var GCode = Code.generateGCode();
  //console.log(GCode);
  return (!Blockly.GCode.workspaceToCodeError);
};

Code.saveGCodeFileToGCode = function (filename) {
  Blockly.GCode.workspaceToCodeError = false;
  //Blockly.CSharp.ComPortList = [];
  var GCode = Code.generateGCode();
  GCode = GCode.replace(/^\s*\n/gm, '');
  //alert(GCode);
  //console.log(GCode);
  if (!Blockly.CSharp.workspaceToCodeError) {
    bound.saveCSharp(filename, GCode);
    return true;
  }
  else {
    return false;
  }
};

Code.checkWorkspaceToCSharp = function () {
  Blockly.CSharp.workspaceToCodeError = false;
  Blockly.CSharp.ComPortList = [];
  var CSharpCode = Code.generateCSharp();
  return (!Blockly.CSharp.workspaceToCodeError);
};

Code.saveCSharpFileToCSharp = function (filename) {
  Blockly.CSharp.workspaceToCodeError = false;
  Blockly.CSharp.ComPortList = [];
  var CSharpCode = Code.generateCSharp();
  if (!Blockly.CSharp.workspaceToCodeError) {
    bound.saveCSharp(filename, CSharpCode);
    return true;
  }
  else {
    return false;
  }
};

Code.saveLLRobotFileToLL = function (filename) {
  var LLRobotCode = Code.generateLLRobot();
  bound.saveLLRobotFile(filename, LLRobotCode);
  return true;
};

Code.loadXML = function (filename) {
  var xml = bound.loadXML(filename);
  //console.log("xml:"+xml);
  //alert("xml:"+xml);
  //  UILLRobot.alert("xml:"+xml);
  Code.replaceBlocksfromXml(xml);
};

/**
 * Creates an text file with the input content and files name, and prompts the
 * users to save it into their local file system.
 * @param {!string} fileName Name for the file to be saved.
 * @param {!string} content Text datd to be saved in to the file.
 */
Code.saveTextFileAs = function (fileName, content) {
  var blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
  saveAs(blob, fileName);
};


/**
 * Creates an XML file containing the blocks from the Blockly workspace and
 * prompts the users to save it into their local file system.
 */
Code.saveXmlFile = function (filename) {
  Code.saveTextFileAs(
    //document.getElementById('sketch_name').value + '.xml',
    filename + '.xml',
    Code.generateXml());
};

/** @return {!string} Generated XML code from the Blockly workspace. */
Code.generateXml = function () {
  var xmlDom = Blockly.Xml.workspaceToDom(Code.workspace);
  return Blockly.Xml.domToPrettyText(xmlDom);
};

/**
 * Loads an XML file from the users file system and adds the blocks into the
 * Blockly workspace.
 */
Code.loadUserXmlFile = function () {
  // Create File Reader event listener function
  var parseInputXMLfile = function (e) {
    var xmlFile = e.target.files[0];
    var filename = xmlFile.name;
    var extensionPosition = filename.lastIndexOf('.');
    if (extensionPosition !== -1) {
      filename = filename.substr(0, extensionPosition);
    }

    var reader = new FileReader();
    reader.onload = function () {
      var success = Code.replaceBlocksfromXml(reader.result);
      if (success) {
        //Code.renderContent();
        //Code.sketchNameSet(filename);
      } else {
        //Code.alertMessage(Code.getLocalStr('invalidXmlTitle'), Code.getLocalStr('invalidXmlBody'), false);
      }
    };
    reader.readAsText(xmlFile);
  };

  // Create once invisible browse button with event listener, and click it

  var selectFile = document.getElementById('select_file');
  if (selectFile === null) {
    var selectFileDom = document.createElement('INPUT');
    selectFileDom.type = 'file';
    selectFileDom.id = 'select_file';

    var selectFileWrapperDom = document.createElement('DIV');
    selectFileWrapperDom.id = 'select_file_wrapper';
    selectFileWrapperDom.style.display = 'none';
    selectFileWrapperDom.appendChild(selectFileDom);

    document.body.appendChild(selectFileWrapperDom);
    selectFile = document.getElementById('select_file');
    selectFile.addEventListener('change', parseInputXMLfile, false);
  }
  selectFile.click();

};


/**
 * 旧版 XML 将 Idx / Variable_Idx 存为 <field>，新版块定义为 input_value + math_number。
 * 必须先收集再替换，避免遍历 live NodeList 时 replaceChild 导致跳过半数字段。
 * @param {!Document} xmlDoc
 */
Code.migrateLegacyFieldXml_ = function (xmlDoc) {
  var allFields = xmlDoc.getElementsByTagName('field');
  var toMigrate = [];
  for (var i = 0; i < allFields.length; i++) {
    var field = allFields[i];
    var fieldName = field.getAttribute('name');
    if (fieldName === 'Idx' || fieldName === 'Variable_Idx' ||
        fieldName === 'Variable_Value') {
      toMigrate.push(field);
    }
  }
  for (var j = 0; j < toMigrate.length; j++) {
    var legacyField = toMigrate[j];
    var legacyName = legacyField.getAttribute('name');
    var fieldValue = legacyField.textContent;
    if (fieldValue == null || String(fieldValue).trim() === '') {
      fieldValue = '0';
    } else {
      fieldValue = String(fieldValue).trim();
    }
    var valueElement = xmlDoc.createElement('value');
    valueElement.setAttribute('name', legacyName);
    var shadowElement = xmlDoc.createElement('shadow');
    shadowElement.setAttribute('type', 'math_number');
    var numField = xmlDoc.createElement('field');
    numField.setAttribute('name', 'NUM');
    numField.appendChild(xmlDoc.createTextNode(fieldValue));
    shadowElement.appendChild(numField);
    valueElement.appendChild(shadowElement);
    legacyField.parentNode.replaceChild(valueElement, legacyField);
  }
};

/**
 * @param {!string} blocksXml
 * @return {boolean}
 */
Code.needsLegacyFieldMigration_ = function (blocksXml) {
  return /<field name="(Idx|Variable_Idx|Variable_Value)">/.test(blocksXml);
};

/**
 * 加载前修补 XML：空 NUM/Idx 默认 0，避免 M/D 等寄存器槽位显示空白。
 * @param {!Document} xmlDoc
 */
Code.normalizeBlocksXml_ = function (xmlDoc) {
  var fields = xmlDoc.getElementsByTagName('field');
  for (var i = 0; i < fields.length; i++) {
    var name = fields[i].getAttribute('name');
    if (name === 'NUM' || name === 'Idx' ||
        name === 'Variable_Idx' || name === 'Variable_Value') {
      var text = fields[i].textContent;
      if (text == null || String(text).trim() === '') {
        fields[i].textContent = '0';
      }
    }
  }
  var values = xmlDoc.getElementsByTagName('value');
  for (var j = 0; j < values.length; j++) {
    var val = values[j];
    var vname = val.getAttribute('name');
    if (vname !== 'Idx' && vname !== 'Variable_Idx' &&
        vname !== 'Variable_Value' && vname !== 'A' && vname !== 'B') {
      continue;
    }
    if (val.getElementsByTagName('block').length > 0) continue;
    if (val.getElementsByTagName('shadow').length > 0) continue;
    var shadow = xmlDoc.createElement('shadow');
    shadow.setAttribute('type', 'math_number');
    var numField = xmlDoc.createElement('field');
    numField.setAttribute('name', 'NUM');
    numField.textContent = '0';
    shadow.appendChild(numField);
    val.appendChild(shadow);
  }
};

/**
 * Parses the XML from its argument input to generate and replace the blocks
 * in the Blockly workspace.
 * @param {!string} blocksXml String of XML code for the blocks.
 * @return {!boolean} Indicates if the XML into blocks parse was successful.
 */
Code.replaceBlocksfromXml = function (blocksXml) {
  var xmlDom = null;
  try {
    xmlDom = Blockly.Xml.textToDom(blocksXml);
  } catch (e) {
    return false;
  }

  var parser = new DOMParser();
  var xmlDoc = parser.parseFromString(blocksXml, 'text/xml');

  // 旧版 XML（Idx 等为 field 而非 value/shadow）需迁移后再加载。
  if (Code.needsLegacyFieldMigration_(blocksXml)) {
    Code.migrateLegacyFieldXml_(xmlDoc);
  }

  Code.normalizeBlocksXml_(xmlDoc);
  var serializer = new XMLSerializer();
  xmlDom = Blockly.Xml.textToDom(serializer.serializeToString(xmlDoc));

  var sucess = false;
  if (xmlDom) {
    sucess = Code.loadBlocksfromXmlDom(xmlDom, true);
  }
  return sucess;
};

/**
 * Append blocks from XML without clearing the workspace (AI 追加模式等).
 * @param {!string} blocksXml
 * @return {!boolean}
 */
Code.appendBlocksfromXml = function (blocksXml) {
  var xmlDom = null;
  try {
    var parser = new DOMParser();
    var xmlDoc = parser.parseFromString(blocksXml, 'text/xml');
    if (Code.needsLegacyFieldMigration_(blocksXml)) {
      Code.migrateLegacyFieldXml_(xmlDoc);
    }
    Code.normalizeBlocksXml_(xmlDoc);
    var serializer = new XMLSerializer();
    xmlDom = Blockly.Xml.textToDom(serializer.serializeToString(xmlDoc));
  } catch (e) {
    return false;
  }
  return Code.loadBlocksfromXmlDom(xmlDom, false);
};

/**
 * Parses the XML from its argument to add the blocks to the workspace.
 * @param {!string} blocksXmlDom String of XML DOM code for the blocks.
 * @return {!boolean} Indicates if the XML into blocks parse was successful.
 */
Code.loadBlocksfromXmlDom = function (blocksXmlDom, opt_clear) {
  try {
    if (opt_clear && Code.workspace) {
      Code.workspace.clear();
    }
    Blockly.Events.disable();
    try {
      Blockly.Xml.domToWorkspace(blocksXmlDom, Code.workspace);
    } finally {
      Blockly.Events.enable();
      Blockly.svgResize(Code.workspace);
    }
  } catch (e) {
    return false;
  }
  Code.invalidatePreview();
  Code.scheduleWorkspaceRerenderAfterLoad_();
  return true;
};

/**
 * Private variable to save the previous version of the Arduino Code.
 * @type {!String}
 * @private
 */
Code.PREV_ARDUINO_CODE_ = 'void setup() {\n\n}\n\n\nvoid loop() {\n\n}';

/**
 * Populate the Arduino Code and Blocks XML panels with content generated from
 * the blocks.
 */

/**
 * AI Agent：工作区概览（顶层块 id/type/文本摘要）。
 * @return {string} JSON 字符串
 */
Code.getWorkspaceOverviewForAi = function () {
  try {
    var ws = Code.workspace;
    if (!ws) {
      return JSON.stringify({ ok: false, message: 'workspace 未就绪' });
    }
    var all = ws.getAllBlocks(false);
    var topBlocks = ws.getTopBlocks(false);
    var tops = [];
    for (var i = 0; i < topBlocks.length; i++) {
      var b = topBlocks[i];
      var label = '';
      try {
        label = goog.string.trim(String(b.toString(64)));
      } catch (e) {
        label = b.type || '';
      }
      tops.push({
        id: b.id,
        type: b.type,
        x: b.getRelativeToSurfaceXY ? b.getRelativeToSurfaceXY().x : 0,
        y: b.getRelativeToSurfaceXY ? b.getRelativeToSurfaceXY().y : 0,
        text: label
      });
    }
    return JSON.stringify({
      ok: true,
      blockCount: all.length,
      topBlockCount: topBlocks.length,
      topBlocks: tops
    });
  } catch (e) {
    return JSON.stringify({ ok: false, message: String(e) });
  }
};

/**
 * AI Agent：扫描 toolbox 中可用块类型。
 * @return {string} JSON
 */
Code.aiGetToolboxBlockTypes = function () {
  try {
    var toolbox = document.getElementById('toolbox');
    if (!toolbox) {
      return JSON.stringify({ ok: false, message: 'toolbox 未找到' });
    }
    var entries = [];
    var seen = {};
    var blockNodes = toolbox.getElementsByTagName('block');
    for (var i = 0; i < blockNodes.length; i++) {
      var node = blockNodes[i];
      var type = node.getAttribute('type');
      if (!type || seen[type]) continue;
      seen[type] = true;
      var category = '其他';
      var parent = node.parentElement;
      while (parent) {
        if (parent.tagName && parent.tagName.toLowerCase() === 'category') {
          category = parent.getAttribute('name') || category;
          break;
        }
        parent = parent.parentElement;
      }
      entries.push({ type: type, category: category });
    }
    return JSON.stringify({ ok: true, types: entries, count: entries.length });
  } catch (e) {
    return JSON.stringify({ ok: false, message: String(e) });
  }
};

/**
 * AI Agent：清空工作区（replace 模式前置步骤）。
 * @return {string} JSON
 */
Code.aiClearWorkspace = function () {
  try {
    if (!Code.workspace) {
      return JSON.stringify({ ok: false, message: 'workspace 未就绪' });
    }
    Code.workspace.clear();
    Code.invalidatePreview();
    return JSON.stringify({ ok: true });
  } catch (e) {
    return JSON.stringify({ ok: false, message: String(e) });
  }
};

/**
 * AI Agent：按 block id 移除块（仅替换上一轮 AI 写入的块）。
 * @param {!Array<string>} ids
 * @return {string} JSON
 */
Code.aiRemoveBlocksByIds = function (ids) {
  try {
    if (!Code.workspace) {
      return JSON.stringify({ ok: false, message: 'workspace 未就绪' });
    }
    var removed = 0;
    if (ids && ids.length) {
      for (var i = 0; i < ids.length; i++) {
        var block = Code.workspace.getBlockById(ids[i]);
        // 旧版 Blockly Block 无 isDisposed()，用 workspace 是否存在判断。
        if (block && block.workspace) {
          block.dispose(false);
          removed++;
        }
      }
    }
    if (removed > 0) {
      Code.invalidatePreview();
    }
    return JSON.stringify({ ok: true, removed: removed });
  } catch (e) {
    return JSON.stringify({ ok: false, message: String(e) });
  }
};

/**
 * AI Agent：移除所有顶层 id 以 ai_ 开头的块（修正模式兜底）。
 * @return {string} JSON
 */
Code.aiRemoveTopAiBlocks = function () {
  try {
    if (!Code.workspace) {
      return JSON.stringify({ ok: false, message: 'workspace 未就绪' });
    }
    var topBlocks = Code.workspace.getTopBlocks(false);
    var removed = 0;
    for (var i = topBlocks.length - 1; i >= 0; i--) {
      var block = topBlocks[i];
      if (block && block.workspace && block.id && block.id.indexOf('ai_') === 0) {
        block.dispose(false);
        removed++;
      }
    }
    if (removed > 0) {
      Code.invalidatePreview();
    }
    return JSON.stringify({ ok: true, removed: removed });
  } catch (e) {
    return JSON.stringify({ ok: false, message: String(e) });
  }
};

/** @return {!string} Generated GCode from the Blockly workspace. */
Code.generateGCode = function () {
  Blockly.CustomConfig.CSharpProgramCurrentLineIndex = 0;//程序行号初始化
  Blockly.CustomConfig.CSharpProgramDefinitionsLineIndex = 0;
  return Blockly.GCode.workspaceToCode(Code.workspace);
};

/** @return {!string} Generated Arduino code from the Blockly workspace. */
Code.generateCSharp = function () {
  Blockly.CustomConfig.CSharpProgramCurrentLineIndex = 0;//程序行号初始化
  Blockly.CustomConfig.CSharpProgramDefinitionsLineIndex = 0;
  return Blockly.CSharp.workspaceToCode(Code.workspace);
};

Code.generateLLRobot = function () {
  return Blockly.LLRobot.workspaceToCode(Code.workspace);
};


//这里实现的选择语言document.write
// Load the Code demo's language strings.
document.write('<script src="msg/' + Code.LANG + '.js"></script>\n');
// Load Blockly's language strings.
document.write('<script src="../../msg/js/' + Code.LANG + '.js"></script>\n');

window.addEventListener('load', Code.init);

//: 判断网页是否加载完成（非 Flutter 宿主时由本处触发加载工程）
document.onreadystatechange = function () {
  if (document.readyState == "complete" && typeof bound === 'undefined') {
    window.setTimeout(Code.ReLoadXML, 1000);
  }
};
Code.ReLoadXML = function () {
  if (!Code.workspace) {
    window.setTimeout(Code.ReLoadXML, 80);
    return;
  }
  Code.loadXML("main");
  Code.loadComplete();
  Code.scheduleWorkspaceRerenderAfterLoad_();
};