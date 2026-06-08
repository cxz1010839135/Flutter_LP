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

Code.selected = 'blocks';//Initalize the selected tabs



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
  Code.renderContent();
  if (clickedName == 'blocks') {
    Code.workspace.setVisible(true);
  }
  Blockly.svgResize(Code.workspace);
};

/**
 *
使用从块生成的内容填充当前选定的窗格。
 * Populate the currently selected pane with content generated from the blocks.
 */
Code.renderContent = function () {
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
        snap: true
      },
      media: '../../media/',//资源路径
      rtl: rtl,
      toolbox: toolboxXml,
      zoom:
      {
        controls: true,
        wheel: true
      }
    });


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


  //添加鼠标单击事件
  SaveDocDiv.addEventListener('click', Code.SaveDoc, true);
  NewDocDiv.addEventListener('click', Code.NewDoc, true);
  BlueToothDiv.addEventListener('click', Code.BlueTooth, true);
  HelperDiv.addEventListener('click', Code.Helper, true);
  SearchButton.addEventListener('click', Code.SearchData, true);
  SearchUpButton.addEventListener('click', Code.SearchDataUp, true);
  SearchDownButton.addEventListener('click', Code.SearchDataDown, true);
  SearchGrup.addEventListener('click', Code.SearchGrup_none, true);

  //添加到DIV元素中
  // 挂到覆盖层上，确保在 SVG 之上且可交互
  [Searchbg, SearchInput, SaveDocDiv, NewDocDiv, BlueToothDiv, HelperDiv,
    SearchButton, SearchGrup, SearchDownButton, SearchUpButton].forEach(function(el) {
    if (!el) return;
    el.style.pointerEvents = 'auto';
    uiHost.appendChild(el);
  });

  /**
   *  图片比例 动作图标比例1:1 动作文字图片比例2:1 高:宽
   *  整个toolbox 比例按照 高:宽等于 1:1.5设置
   *  屏幕视野内将toolbox分成8个等份
   */
  for (var j = 0; j < Blockly.CustomConfig.BlocklyTreeDivNum; j++) {
    var spanwidth, height;
    var spans = document.getElementById(':' + (j + 1).toString()).firstChild.childNodes[1];//getElementsByClassName('blocklyTreeIcon.blocklyTreeIconNone');
    var treerow = document.getElementById('content_area');

    height = treerow.offsetHeight / Blockly.CustomConfig.BlocklyTreeDivNum;
    //spanwidth = treerow.offsetWidth * 0.1;
    spanwidth = height * 1.0;
    spans.style.boxSizing = 'border-box';
    //spans.style.width = height + 'px';
    spans.style.width = spanwidth + 'px';
    spans.style.lineHeight = height + 'px';
    //spans.style.paddingTop = spanwidth + 'px';
    //spans.style.paddingBottom = spanwidth + 'px';
    var spanlabel = document.getElementById(':' + (j + 1).toString() + '.label');
    //height = spanlabel.offsetHeight;
    //sides[i].style.width = spanwidth + 'px';
    spanlabel.style.boxSizing = 'border-box';
    spanlabel.style.lineHeight = height + 'px';
    var spanlabelwidth = height * 0.5;
    spanlabel.style.width = spanlabelwidth + 'px';//'0px';
    //spanlabel.style.display = 'none';
  }

  var divblocklyToolboxDivs = document.getElementsByClassName('blocklyToolboxDiv');
  var divwidth = treerow.offsetHeight * 0.78 / Blockly.CustomConfig.BlocklyTreeDivNum;//+25 border-radius 圆角半径
  divblocklyToolboxDivs[0].style.width = divwidth + 'px';

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
    Blockly.Xml.search_MD_XY(block, opt_noId, key_word);

    Code.workspace.search_head_index_num++;
  }
  //如果搜索到有数据才会跳转到
  if (Code.workspace.search_.length > 0) {
    UILLRobot.alert("搜索结果", "一共搜索到：" + Code.workspace.search_.length + "个" + key_word);
    var idx = Code.workspace.search_head_index[0];
    blocks[idx].setCollapsed(false); // 展开式折叠或者展开
    blocks[idx].bringToFront();
    Code.workspace.setScale(1);
    var selBlock = Code.workspace.search_blocks_ && Code.workspace.search_blocks_[0] ? Code.workspace.search_blocks_[0] : blocks[idx];
    selBlock.select();
    Code.workspace.scrollCenter_xy(Code.workspace.search_[0][0] - Code.workspace.head_xy[0], Code.workspace.search_[0][1] - Code.workspace.head_xy[1]);
  } else {
    UILLRobot.alert("搜索结果", "没有找到：" + key_word);
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
  //如果搜索到有数据才会跳转到
  if (Code.workspace.search_.length > 0) {
    var len = Code.workspace.search_.length;
    Code.workspace.search_index = (Code.workspace.search_index + 1) % len;

    var idx = Code.workspace.search_head_index[Code.workspace.search_index];
    var blocks = Code.workspace.getTopBlocks(true);
    blocks[idx].setCollapsed(false);
    blocks[idx].bringToFront();
    Code.workspace.setScale(1);
    var selBlock = Code.workspace.search_blocks_ && Code.workspace.search_blocks_[Code.workspace.search_index] ? Code.workspace.search_blocks_[Code.workspace.search_index] : blocks[idx];
    selBlock.select();
    Code.workspace.scrollCenter_xy(Code.workspace.search_[Code.workspace.search_index][0] - Code.workspace.head_xy[0], Code.workspace.search_[Code.workspace.search_index][1] - Code.workspace.head_xy[1]);
  } else {
    UILLRobot.alert("搜索结果", "没有找到：" + key_word);
    //alert("没有找到："+key_word);
  }
};

Code.SearchDataDown = function () {
  //如果搜索到有数据才会跳转到
  if (Code.workspace.search_.length > 0) {
    Code.workspace.search_index = Code.workspace.search_index - 1;
    if (Code.workspace.search_index < 0) Code.workspace.search_index = Code.workspace.search_.length - 1;

    var idx = Code.workspace.search_head_index[Code.workspace.search_index];
    var blocks = Code.workspace.getTopBlocks(true);
    blocks[idx].setCollapsed(false);
    blocks[idx].bringToFront();
    Code.workspace.setScale(1);
    var selBlock = Code.workspace.search_blocks_ && Code.workspace.search_blocks_[Code.workspace.search_index] ? Code.workspace.search_blocks_[Code.workspace.search_index] : blocks[idx];
    selBlock.select();
    Code.workspace.scrollCenter_xy(Code.workspace.search_[Code.workspace.search_index][0] - Code.workspace.head_xy[0], Code.workspace.search_[Code.workspace.search_index][1] - Code.workspace.head_xy[1]);
  } else {
    UILLRobot.alert("搜索结果", "没有找到：" + key_word);
    //alert("没有找到："+key_word);
  }


};

/**
 * 帮助事件
 */
Code.Helper = function () {

 UILLRobot.alert("版本信息","版本号1.2.1 \r\n1.0.4:添加了圆弧指令，优化了UI界面 \r\n1.0.5:添加了电子齿轮指令 \r\n1.0.6:优化了圆弧运动的块表达 \r\n1.0.8:更新了地址偏移，搜索优化\r\n1.1.0修复了多重搜索\r\n1.1.1修复了点子齿轮G代码解析分子分母负数有()\r\n1.1.2改为精确搜索，并且添加了母块高亮\r\n1.1.3添加复制粘贴模块\r\n1.1.4修复和或运算保存异常不提示\r\n1.1.5添加小数点操作\r\n1.1.6优化函数折叠不能搜索功能\r\n1.1.7优化UI、添加批量操作功能块\r\n1.1.8优化中文搜索以及搜索高亮\r\n1.2.0优化注释显示更加明显r\n1.2.1向下兼容普通块也能展开但是不能折叠");

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
  // 查找要修改的标签
  var blocks = xmlDoc.getElementsByTagName('field'); // 获取第一个child元素

  for (var i = 0; i < blocks.length; i++) {
    var block = blocks[i];

    // 查找block中的 <field name="Idx"> 元素
    var idxField = block.querySelector('field[name="Idx"]');
    var field_name = block.getAttribute('name');
    // 如果找到了 <field name="Idx">，进行替换
    //    if (idxField) {
    if (field_name == 'Idx' || field_name == 'Variable_Idx' || field_name == 'Variable_Value') {
      var textNode = block.firstChild;
      var fieldValue = textNode.nodeType === Node.TEXT_NODE ? textNode.textContent : null;
      //alert('1111111111111'+block.getAttribute('name')+"num:"+fieldValue+"====="+idxField);
      // 创建新的 <value> 元素
      var valueElement = document.createElement('value');
      valueElement.setAttribute('name', block.getAttribute('name'));
      // 创建新的 <shadow> 元素
      var shadowElement = document.createElement('shadow');
      shadowElement.setAttribute('type', 'math_number');
      shadowElement.setAttribute('id', ',b^^jksa.BVQjcbm/UJu');
      // 创建新的 <field> 元素，名字为 "NUM"，值为原 <field name="Idx"> 的值
      var newFieldElement = document.createElement('field');
      newFieldElement.setAttribute('name', 'NUM');
      newFieldElement.appendChild(document.createTextNode(fieldValue));
      // 将新的 <field> 元素添加到 <shadow> 中，然后将 <shadow> 添加到 <value> 中
      shadowElement.appendChild(newFieldElement);
      valueElement.appendChild(shadowElement);
      //       // 将新的 <value> 元素插入到 <block> 中，替换掉原来的 <field name="Idx"> 元素
      block.parentNode.replaceChild(valueElement, block);
    }
  }
  // 将修改后的XML转换回字符串
  var serializer = new XMLSerializer();
  var xmlString = serializer.serializeToString(xmlDoc);


  xmlDom = Blockly.Xml.textToDom(xmlString);
  var sucess = false;
  if (xmlDom) {
    sucess = Code.loadBlocksfromXmlDom(xmlDom);
  }
  return sucess;
};

/**
 * Parses the XML from its argument to add the blocks to the workspace.
 * @param {!string} blocksXmlDom String of XML DOM code for the blocks.
 * @return {!boolean} Indicates if the XML into blocks parse was successful.
 */
Code.loadBlocksfromXmlDom = function (blocksXmlDom) {
  try {
    Blockly.Xml.domToWorkspace(blocksXmlDom, Code.workspace);
  } catch (e) {
    return false;
  }
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

/** @return {!string} Generated Arduino code from the Blockly workspace. */
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

//: 判断网页是否加载完成
document.onreadystatechange = function () {
  if (document.readyState == "complete") {//complete
    window.setTimeout(Code.ReLoadXML, 1000);
    //Code.loadXML("main.xml");
    //window.alert("safa");
  }
};
Code.ReLoadXML = function () {
  Code.loadXML("main");
  Code.loadComplete();
};