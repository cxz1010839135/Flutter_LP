/**
 * Flutter WebView 桥接：
 * - 配置：{installRoot}/config/server/{name}.xml + .rp4
 * - 保存：{installRoot}/files/xml、files/projects、files/funlib 等
 */
(function () {
  'use strict';

  var DEFAULT_NAME = 'main';

  function serverXmlUrl(filename) {
    return (
      '/api/files/server/xml/' + encodeURIComponent(filename || DEFAULT_NAME)
    );
  }

  function serverRp4Url(filename) {
    return (
      '/api/files/server/rp4/' + encodeURIComponent(filename || DEFAULT_NAME)
    );
  }

  function syncGet(url) {
    try {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', url, false);
      xhr.send(null);
      if (xhr.status >= 200 && xhr.status < 300) {
        return xhr.responseText || '';
      }
    } catch (e) {
      console.error('syncGet failed:', url, e);
    }
    return '';
  }

  function syncPost(url, content, contentType) {
    try {
      var xhr = new XMLHttpRequest();
      xhr.open('POST', url, false);
      xhr.setRequestHeader(
        'Content-Type',
        contentType || 'text/plain; charset=utf-8'
      );
      xhr.send(content || '');
      return xhr.status >= 200 && xhr.status < 300;
    } catch (e) {
      console.error('syncPost failed:', url, e);
      return false;
    }
  }

  function getFlutterChannel() {
    try {
      if (typeof FlutterBlockly !== 'undefined') return FlutterBlockly;
      if (window.FlutterBlockly) return window.FlutterBlockly;
    } catch (e) {}
    return null;
  }

  function postToFlutter(payload) {
    try {
      var channel = getFlutterChannel();
      if (channel && channel.postMessage) {
        channel.postMessage(JSON.stringify(payload));
        return true;
      }
    } catch (e) {
      console.error('FlutterBlockly postMessage failed:', e);
    }
    return false;
  }

  function generateGCodeText() {
    try {
      if (window.Code && Code.generateGCode) {
        return Code.generateGCode().replace(/^\s*\n/gm, '');
      }
    } catch (e) {
      console.error('generateGCode failed:', e);
    }
    return '';
  }

  /** 工具栏「保存」：仅写本地 config/server，文件名可自定义 */
  function saveProgramToServer(fileName, xml) {
    var baseName = fileName || DEFAULT_NAME;
    var gcode = generateGCodeText();
    if (
      postToFlutter({
        type: 'saveProgram',
        fileName: baseName,
        xml: xml,
        gcode: gcode,
      })
    ) {
      return;
    }
    saveToServer(fileName, xml);
  }

  /** 同时保存 config/server/{name}.xml 与 .rp4（退出流程内部用） */
  function saveToServer(fileName, xml) {
    var baseName = fileName || DEFAULT_NAME;
    var gcode = generateGCodeText();
    if (
      postToFlutter({
        type: 'saveServerProject',
        fileName: baseName,
        xml: xml,
        gcode: gcode,
      })
    ) {
      return;
    }
    var okXml = syncPost(
      serverXmlUrl(baseName),
      xml,
      'text/xml; charset=utf-8'
    );
    var okRp4 = syncPost(serverRp4Url(baseName), gcode, 'text/plain; charset=utf-8');
    if (okXml && okRp4) {
      alert(
        '已保存到 config/server/' +
          baseName +
          '.xml 和 config/server/' +
          baseName +
          '.rp4'
      );
      return;
    }
    alert('保存失败，请查看 Flutter 控制台日志。');
  }

  function saveRp4ToServer(fileName, gcode) {
    var baseName = fileName || DEFAULT_NAME;
    if (
      postToFlutter({
        type: 'saveServerRp4',
        fileName: baseName,
        gcode: gcode,
      })
    ) {
      return;
    }
    if (syncPost(serverRp4Url(baseName), gcode, 'text/plain; charset=utf-8')) {
      alert('已保存到 config/server/' + baseName + '.rp4');
    }
  }

  function rebindToolbarButton(className, handler) {
    var btn = document.querySelector('.' + className);
    if (!btn || !btn.parentNode) return null;
    var fresh = btn.cloneNode(true);
    btn.parentNode.replaceChild(fresh, btn);
    fresh.addEventListener(
      'click',
      function (e) {
        e.preventDefault();
        e.stopPropagation();
        handler();
      },
      true
    );
    return fresh;
  }

  window.bound = {
    _isFlutter: true,

    getWidth: function () {
      return window.innerHeight || document.documentElement.clientHeight || 800;
    },

    getSp_lang: function () {
      return 'zh-hans';
    },

    loadComplete: function (ok) {
      postToFlutter({ type: 'loadComplete', ok: !!ok });
    },

    loadXML: function (filename) {
      return syncGet(serverXmlUrl(filename || DEFAULT_NAME));
    },

    saveXML: function (filename, xml) {
      saveToServer(filename || DEFAULT_NAME, xml);
    },

    saveFunXML: function (fileName, xml) {
      saveToServer(fileName, xml);
    },

    chooseFunXML: function () {
      postToFlutter({ type: 'pickAndLoadXml' });
    },

    loadFunXML: function () {
      return '';
    },

    saveCSharp: function (filename, code) {
      saveRp4ToServer(filename || DEFAULT_NAME, code);
    },

    saveLLRobotFile: function (filename, code) {
      postToFlutter({ type: 'saveLLRobot', filename: filename, code: code });
    },

    saveCompileResult: function (project, filename, result) {
      window.__lpCompileOk = !!result;
      postToFlutter({
        type: 'saveCompileResult',
        project: project,
        filename: filename,
        result: !!result,
      });
    },

    exit: function () {
      var xml = '';
      var gcode = '';
      try {
        if (window.Code && Code.generateXml) {
          xml = Code.generateXml();
        }
        gcode = generateGCodeText();
      } catch (e) {
        console.error('exit gather content failed:', e);
      }
      postToFlutter({
        type: 'exit',
        fileName: DEFAULT_NAME,
        xml: xml,
        gcode: gcode,
        updateProgram: !!window.__lpUpdateProgram,
        compileOk: !!window.__lpCompileOk,
      });
      window.__lpUpdateProgram = false;
      window.__lpCompileOk = false;
    },

    updateCompileResult: function () {
      window.__lpUpdateProgram = true;
      window.__lpCompileOk = true;
      postToFlutter({ type: 'updateCompileResult' });
    },
  };

  if (typeof isWeb !== 'undefined') {
    isWeb = false;
  }

  function installFlutterSaveButton() {
    rebindToolbarButton('SaveDocDiv', function () {
      var fileName = prompt('请输入保存的工程名：', DEFAULT_NAME);
      if (!fileName) return;
      fileName = fileName.trim();
      if (!fileName) return;
      saveProgramToServer(fileName, Code.generateXml());
    });
  }

  function installFlutterLoadButton() {
    rebindToolbarButton('BlueToothDiv', function () {
      loadFromServerFolder();
    });
  }

  function loadFromServerFolder() {
    if (postToFlutter({ type: 'pickAndLoadXml' })) {
      return;
    }

    try {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', '/api/files/server/xml/_list', false);
      xhr.send(null);
      if (xhr.status < 200 || xhr.status >= 300) {
        throw new Error('HTTP ' + xhr.status);
      }
      var files = JSON.parse(xhr.responseText || '[]');
      if (!files.length) {
        alert('config/server 目录下还没有 xml 文件，请先保存。');
        return;
      }
      var name = prompt(
        '请输入要加载的文件名（位于 config/server 目录）：\n\n' + files.join('\n'),
        DEFAULT_NAME
      );
      if (!name) return;
      name = name.trim();
      if (!name) return;
      var xml = syncGet(serverXmlUrl(name));
      if (!xml) {
        alert('未找到文件：' + name + '.xml');
        return;
      }
      Code.replaceBlocksfromXml(xml);
      alert('已加载 config/server/' + name + '.xml');
    } catch (e) {
      alert('加载失败：' + e);
    }
  }

  window.addEventListener('load', function () {
    if (typeof isWeb !== 'undefined') {
      isWeb = false;
    }
    window.setTimeout(function () {
      installFlutterSaveButton();
      installFlutterLoadButton();
    }, 500);
  });

  document.onreadystatechange = function () {
    if (document.readyState === 'complete') {
      window.setTimeout(function () {
        if (window.Code && typeof Code.ReLoadXML === 'function') {
          Code.ReLoadXML();
        } else if (window.Code && typeof Code.loadComplete === 'function') {
          Code.loadComplete();
        }
      }, 300);
    }
  };
})();
