/**
 * @license
 * Visual Blocks Language
 *
 * Copyright 2016 Google Inc.
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
 * LLRobot 将图形化程序翻译成描述性语言程序段落
 */

'use strict';

goog.provide('Blockly.LLRobot');

goog.require('Blockly.Generator');


/**
 * LLRobot code generator.
 * @type {!Blockly.Generator}
 */
Blockly.LLRobot = new Blockly.Generator('LLRobot');

/**
 * List of illegal variable names.
 * This is not intended to be a security feature.  Blockly is 100% client-side,
 * so bypassing this list is trivial.  This is intended to prevent users from
 * accidentally clobbering a built-in object or function.
 * @private
 */
Blockly.LLRobot.addReservedWords(
    //https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/
    //https://docs.microsoft.com/zh-cn/dotnet/csharp/language-reference/keywords/
    'abstract,as,base,bool,break,byte,case,catch,char,checked,class,const,continue,' +
    'decimal,default,delegate,do,double,else,enum,event,explicit,extern,false,finally,fixed,float,for,foreach,' +
    'goto,if,implicit,in,int,interface,internal,is,lock,long,namespace,new,null,' +
    'object,operator,out,override,params,private,protected,public,readonly,ref,return,' +
    'sbyte,sealed,short,sizeof,stackalloc,static,string,struct,switch,this,throw,true,try,typeof,' +
    'uint,ulong,unchecked,unsafe,ushort,using,virtual,void,volatile,while,' +
    //Types
    //Value Types
    'bool,byte,char,decimal,double,enum,float,int,long,sbyte,short,struct,uint,ulong,ushort,' +
    //Reference Types
    'class,delegate,dynamic,interface,object,string,' +
    'void,var' +
    //Modifiers
    'internal,private,protected,public,abstract,async,const,event,extern,in,out,override,readonly,sealed,static,unsafe,virtual,volatile,' +
    //Statement Keywords
    //Selection ,Iteration ,Jump ,Exception handling ,Checked and unchecked ,fixed ,lock
    'if,else,switch,case,' +
    'do,for,foreach,in,while,' +
    'break,continue,default,goto,return,yield,' +
    'throw,try,catch,finally,' +
    'checked,unchecked,' +
    'fixed,' +
    'lock,' +
    //Method Parameters
    'params,ref,out,' +
    //Namespace Keywords
    'namespace,using,static,Operator,extern,' +
    //Operator Keywords
    'as,await,is,new,sizeof,typeof,true,false,stackalloc,nameof,' +
    'explicit,implicit,operator,base,this,null,default,add,get,global,partial,remove,set,when,where,value,yield,' +
    'from,select,group,into'
);

/**
 * Order of operation ENUMs.
 * C# operator precedence 运算符优先级
 * //https://docs.microsoft.com/zh-cn/dotnet/csharp/language-reference/operators/index
 */

/**
 Blockly.LLRobot.ORDER_ATOMIC = 0;         // 0 ""
 Blockly.LLRobot.ORDER_MEMBER = 1;         // . []
 Blockly.LLRobot.ORDER_NEW = 1;            // new
 Blockly.LLRobot.ORDER_TYPEOF = 1;         // typeof
 Blockly.LLRobot.ORDER_FUNCTION_CALL = 1;  // ()
 Blockly.LLRobot.ORDER_INCREMENT = 1;      // ++
 Blockly.LLRobot.ORDER_DECREMENT = 1;      // --
 Blockly.LLRobot.ORDER_LOGICAL_NOT = 2;    // !
 Blockly.LLRobot.ORDER_BITWISE_NOT = 2;    // ~
 Blockly.LLRobot.ORDER_UNARY_PLUS = 2;     // +
 Blockly.LLRobot.ORDER_UNARY_NEGATION = 2; // -
 Blockly.LLRobot.ORDER_MULTIPLICATION = 3; // *
 Blockly.LLRobot.ORDER_DIVISION = 3;       // /
 Blockly.LLRobot.ORDER_MODULUS = 3;        // %
 Blockly.LLRobot.ORDER_ADDITION = 4;       // +
 Blockly.LLRobot.ORDER_SUBTRACTION = 4;    // -
 Blockly.LLRobot.ORDER_BITWISE_SHIFT = 5;  // << >>
 Blockly.LLRobot.ORDER_RELATIONAL = 6;     // < <= > >=
 Blockly.LLRobot.ORDER_EQUALITY = 7;       // == !=
 Blockly.LLRobot.ORDER_BITWISE_AND = 8;   // &
 Blockly.LLRobot.ORDER_BITWISE_XOR = 9;   // ^
 Blockly.LLRobot.ORDER_BITWISE_OR = 10;    // |
 Blockly.LLRobot.ORDER_LOGICAL_AND = 11;   // &&
 Blockly.LLRobot.ORDER_LOGICAL_OR = 12;    // ||
 Blockly.LLRobot.ORDER_CONDITIONAL = 13;   // ?:
 Blockly.LLRobot.ORDER_ASSIGNMENT = 14;    // = += -= *= /= %= <<= >>= ...
 Blockly.LLRobot.ORDER_COMMA = 15;         // ,
 Blockly.LLRobot.ORDER_NONE = 99;          // (...)
 */

Blockly.LLRobot.ORDER_ATOMIC = 0;         // 0 "" ...
Blockly.LLRobot.ORDER_UNARY_POSTFIX = 1;  // expr++ expr-- () [] . new typeof
Blockly.LLRobot.ORDER_UNARY_PREFIX = 2;   // -expr !expr ~expr ++expr --expr
Blockly.LLRobot.ORDER_MULTIPLICATIVE = 3; // * / % ~/
Blockly.LLRobot.ORDER_ADDITIVE = 4;       // + -
Blockly.LLRobot.ORDER_BITWISE_SHIFT = 5;          // << >>
Blockly.LLRobot.ORDER_RELATIONAL = 6;     // >= > <= <
Blockly.LLRobot.ORDER_EQUALITY = 7;       // == != === !==
Blockly.LLRobot.ORDER_BITWISE_AND = 8;    // &
Blockly.LLRobot.ORDER_BITWISE_XOR = 9;    // ^
Blockly.LLRobot.ORDER_BITWISE_OR = 10;    // |
Blockly.LLRobot.ORDER_LOGICAL_AND = 11;   // &&
Blockly.LLRobot.ORDER_LOGICAL_OR = 12;    // ||
Blockly.LLRobot.ORDER_CONDITIONAL = 13;   // expr ? expr : expr
Blockly.LLRobot.ORDER_ASSIGNMENT = 14;    // = *= /= ~/= %= += -= <<= >>= &= ^= |=
Blockly.LLRobot.ORDER_NONE = 99;          // (...)

/**
 * Arbitrary code to inject into locations that risk causing infinite loops.
 * Any instances of '%1' will be replaced by the block ID that failed.
 * E.g. '  checkTimeout(%1);\n'
 * @type ?string
 */
Blockly.LLRobot.INFINITE_LOOP_TRAP = null;

/**
 * 编译错误标志
 */
Blockly.LLRobot.workspaceToCodeError = false;

/**
 *  编译错误代码
 */
Blockly.LLRobot.workspaceToCodeErrorString = "";
/**
 * Initialise the database of variable names.
 * @param {!Blockly.Workspace} workspace Workspace to generate code from.
 */
Blockly.LLRobot.init = function(workspace) {
  // Create a dictionary of definitions to be printed before the code.
  Blockly.LLRobot.definitions_ = Object.create(null);
  // Create a dictionary mapping desired function names in definitions_
  // to actual function names (to avoid collisions with user functions).
  Blockly.LLRobot.functionNames_ = Object.create(null);

  if (!Blockly.LLRobot.variableDB_) {
    Blockly.LLRobot.variableDB_ =
        new Blockly.Names(Blockly.LLRobot.RESERVED_WORDS_);
  } else {
    Blockly.LLRobot.variableDB_.reset();
  }

  var defvars = [];
  var variables = workspace.getAllVariables();
  if (variables.length) {
    for (var i = 0; i < variables.length; i++) {
      // defvars[i] = 'dynamic ' +
      //     Blockly.LLRobot.variableDB_.getName(variables[i].name,
      //         Blockly.Variables.NAME_TYPE) + ' = 0;';//';';
      defvars[i] = '变量定义 var-' +
          variables[i].name + ' = 0;';//';';
    }
    Blockly.LLRobot.definitions_['variables'] = defvars.join('\n');
  }
};

/**
 * Prepend the generated code with the variable definitions.
 * @param {string} code Generated code.
 * @return {string} Completed code.
 */
Blockly.LLRobot.finish = function(code) {
  var definitions = [];
  for (var name in Blockly.LLRobot.definitions_) {
    definitions.push(Blockly.LLRobot.definitions_[name]);
  }
  var maincode = '';
  //if(!Blockly.LLRobot.workspaceToCodeError)
  {
    maincode = definitions.join('\n\n') + '\n\n\n' + '@@@\n' +  code.replace(/\n/g, '\n  ');
  }
  var reg = /\n(\n)*( )*(\n)*\n/g;
  var finalcode = maincode.replace(reg,"\n") + '\n';
  //return definitions.join('\n\n') + '\n\n\n' + code;//.replace(/\n/g, '\n  ')
  return finalcode;
};

/**
 * Naked values are top-level blocks with outputs that aren't plugged into
 * anything.  A trailing semicolon is needed to make this legal.
 * @param {string} line Line of generated code.
 * @return {string} Legal line of code.
 */
Blockly.LLRobot.scrubNakedValue = function(line) {
  return line + ';\n';
};

Blockly.LLRobot.quote_ = function(string) {
  // TODO: This is a quick hack.  Replace with goog.string.quote
  //return goog.string.quote(string);
  return "\"" + string + "\"";
};

/**
 * Common tasks for generating LLRobot from blocks.
 * Handles comments for the specified block and any connected value blocks.
 * Calls any statements following this block.
 * @param {!Blockly.Block} block The current block.
 * @param {string} code The LLRobot code created for this block.
 * @return {string} LLRobot code with comments and subsequent blocks added.
 * @this {Blockly.CodeGenerator}
 * @private
 */

Blockly.LLRobot.scrub_ = function(block, code) {
  if (code === null) {
    // Block has handled code generation itself.
    return '';
  }
  var commentCode = '';
  // Only collect comments for blocks that aren't inline.
  if (!block.outputConnection || !block.outputConnection.targetConnection) {
    // Collect comment for this block.
    var comment = block.getCommentText();
    comment = Blockly.utils.wrap(comment, Blockly.LLRobot.COMMENT_WRAP - 3);
    if (comment) {
      if (block.getProcedureDef) {
        // Use a comment block for function comments.
        commentCode += '/**\n' +
            Blockly.LLRobot.prefixLines(comment + '\n', ' * ') +
            ' */\n';
      } else {
        commentCode += Blockly.LLRobot.prefixLines(comment + '\n', '// ');
      }
    }
    // Collect comments for all value arguments.
    // Don't collect comments for nested statements.
    for (var i = 0; i < block.inputList.length; i++) {
      if (block.inputList[i].type == Blockly.INPUT_VALUE) {
        var childBlock = block.inputList[i].connection.targetBlock();
        if (childBlock) {
          var comment = Blockly.LLRobot.allNestedComments(childBlock);
          if (comment) {
            commentCode += Blockly.LLRobot.prefixLines(comment, '// ');
          }
        }
      }
    }
  }
  var nextBlock = block.nextConnection && block.nextConnection.targetBlock();
  var nextCode = Blockly.LLRobot.blockToCode(nextBlock);
  return commentCode + code + nextCode;
};


/**
 * Gets a property and adjusts the value while taking into account indexing.
 * @param {!Blockly.Block} block The block.
 * @param {string} atId The property ID of the element to get.
 * @param {number=} opt_delta Value to add.
 * @param {boolean=} opt_negate Whether to negate the value.
 * @param {number=} opt_order The highest order acting on this value.
 * @return {string|number}
 */
Blockly.LLRobot.getAdjusted = function(block, atId, opt_delta, opt_negate,
                                      opt_order) {
  var delta = opt_delta || 0;
  var order = opt_order || Blockly.LLRobot.ORDER_NONE;
  if (block.workspace.options.oneBasedIndex) {
    delta--;
  }
  var defaultAtIndex = block.workspace.options.oneBasedIndex ? '1' : '0';
  if (delta) {
    var at = Blockly.LLRobot.valueToCode(block, atId,
        Blockly.LLRobot.ORDER_ADDITIVE) || defaultAtIndex;
  } else if (opt_negate) {
    var at = Blockly.LLRobot.valueToCode(block, atId,
        Blockly.LLRobot.ORDER_UNARY_PREFIX) || defaultAtIndex;
  } else {
    var at = Blockly.LLRobot.valueToCode(block, atId, order) ||
        defaultAtIndex;
  }

  if (Blockly.isNumber(at)) {
    // If the index is a naked number, adjust it right now.
    at = parseInt(at, 10) + delta;
    if (opt_negate) {
      at = -at;
    }
  } else {
    // If the index is dynamic, adjust it in code.
    if (delta > 0) {
      at = at + ' + ' + delta;
      var innerOrder = Blockly.LLRobot.ORDER_ADDITIVE;
    } else if (delta < 0) {
      at = at + ' - ' + -delta;
      var innerOrder = Blockly.LLRobot.ORDER_ADDITIVE;
    }
    if (opt_negate) {
      if (delta) {
        at = '-(' + at + ')';
      } else {
        at = '-' + at;
      }
      var innerOrder = Blockly.LLRobot.ORDER_UNARY_PREFIX;
    }
    innerOrder = Math.floor(innerOrder);
    order = Math.floor(order);
    if (innerOrder && order >= innerOrder) {
      at = '(' + at + ')';
    }
  }
  return at;
};
