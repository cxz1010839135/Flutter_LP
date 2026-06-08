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



'use strict';

goog.provide('Blockly.CSharp');

goog.require('Blockly.Generator');


/**
 * CSharp code generator.
 * @type {!Blockly.Generator}
 */
Blockly.CSharp = new Blockly.Generator('CSharp');

/**
 * List of illegal variable names.
 * This is not intended to be a security feature.  Blockly is 100% client-side,
 * so bypassing this list is trivial.  This is intended to prevent users from
 * accidentally clobbering a built-in object or function.
 * @private
 */
Blockly.CSharp.addReservedWords(
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
Blockly.CSharp.ORDER_ATOMIC = 0;         // 0 ""
Blockly.CSharp.ORDER_MEMBER = 1;         // . []
Blockly.CSharp.ORDER_NEW = 1;            // new
Blockly.CSharp.ORDER_TYPEOF = 1;         // typeof
Blockly.CSharp.ORDER_FUNCTION_CALL = 1;  // ()
Blockly.CSharp.ORDER_INCREMENT = 1;      // ++
Blockly.CSharp.ORDER_DECREMENT = 1;      // --
Blockly.CSharp.ORDER_LOGICAL_NOT = 2;    // !
Blockly.CSharp.ORDER_BITWISE_NOT = 2;    // ~
Blockly.CSharp.ORDER_UNARY_PLUS = 2;     // +
Blockly.CSharp.ORDER_UNARY_NEGATION = 2; // -
Blockly.CSharp.ORDER_MULTIPLICATION = 3; // *
Blockly.CSharp.ORDER_DIVISION = 3;       // /
Blockly.CSharp.ORDER_MODULUS = 3;        // %
Blockly.CSharp.ORDER_ADDITION = 4;       // +
Blockly.CSharp.ORDER_SUBTRACTION = 4;    // -
Blockly.CSharp.ORDER_BITWISE_SHIFT = 5;  // << >>
Blockly.CSharp.ORDER_RELATIONAL = 6;     // < <= > >=
Blockly.CSharp.ORDER_EQUALITY = 7;       // == !=
Blockly.CSharp.ORDER_BITWISE_AND = 8;   // &
Blockly.CSharp.ORDER_BITWISE_XOR = 9;   // ^
Blockly.CSharp.ORDER_BITWISE_OR = 10;    // |
Blockly.CSharp.ORDER_LOGICAL_AND = 11;   // &&
Blockly.CSharp.ORDER_LOGICAL_OR = 12;    // ||
Blockly.CSharp.ORDER_CONDITIONAL = 13;   // ?:
Blockly.CSharp.ORDER_ASSIGNMENT = 14;    // = += -= *= /= %= <<= >>= ...
Blockly.CSharp.ORDER_COMMA = 15;         // ,
Blockly.CSharp.ORDER_NONE = 99;          // (...)
*/

Blockly.CSharp.ORDER_ATOMIC = 0;         // 0 "" ...
Blockly.CSharp.ORDER_UNARY_POSTFIX = 1;  // expr++ expr-- () [] . new typeof
Blockly.CSharp.ORDER_UNARY_PREFIX = 2;   // -expr !expr ~expr ++expr --expr
Blockly.CSharp.ORDER_MULTIPLICATIVE = 3; // * / % ~/
Blockly.CSharp.ORDER_ADDITIVE = 4;       // + -
Blockly.CSharp.ORDER_BITWISE_SHIFT = 5;          // << >>
Blockly.CSharp.ORDER_RELATIONAL = 6;     // >= > <= <
Blockly.CSharp.ORDER_EQUALITY = 7;       // == != === !==
Blockly.CSharp.ORDER_BITWISE_AND = 8;    // &
Blockly.CSharp.ORDER_BITWISE_XOR = 9;    // ^
Blockly.CSharp.ORDER_BITWISE_OR = 10;    // |
Blockly.CSharp.ORDER_LOGICAL_AND = 11;   // &&
Blockly.CSharp.ORDER_LOGICAL_OR = 12;    // ||
Blockly.CSharp.ORDER_CONDITIONAL = 13;   // expr ? expr : expr
Blockly.CSharp.ORDER_ASSIGNMENT = 14;    // = *= /= ~/= %= += -= <<= >>= &= ^= |=
Blockly.CSharp.ORDER_NONE = 99;          // (...)

/**
 * Arbitrary code to inject into locations that risk causing infinite loops.
 * Any instances of '%1' will be replaced by the block ID that failed.
 * E.g. '  checkTimeout(%1);\n'
 * @type ?string
 */
Blockly.CSharp.INFINITE_LOOP_TRAP = null;

/**
 * 编译错误标志
 */
Blockly.CSharp.workspaceToCodeError = false;

/**
 *  编译错误代码
 */
Blockly.CSharp.workspaceToCodeErrorString = "";
/**
 * Initialise the database of variable names.
 * @param {!Blockly.Workspace} workspace Workspace to generate code from.
 */
Blockly.CSharp.init = function(workspace) {
    // Create a dictionary of definitions to be printed before the code.
    Blockly.CSharp.definitions_ = Object.create(null);
    // Create a dictionary mapping desired function names in definitions_
    // to actual function names (to avoid collisions with user functions).
    Blockly.CSharp.functionNames_ = Object.create(null);

    if (!Blockly.CSharp.variableDB_) {
        Blockly.CSharp.variableDB_ =
            new Blockly.Names(Blockly.CSharp.RESERVED_WORDS_);
    } else {
        Blockly.CSharp.variableDB_.reset();
    }

    var defvars = [];
    var variables = workspace.getAllVariables();
    if (variables.length) {
        for (var i = 0; i < variables.length; i++) {
            defvars[i] = //Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';' +
                'dynamic ' +
                Blockly.CSharp.variableDB_.getName(variables[i].name,
                    Blockly.Variables.NAME_TYPE) + ' = 0;';//';';
            //Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;//定义的程序行号变量,每增加一行,数字加1
        }
        Blockly.CSharp.definitions_['variables'] = defvars.join('\n');
    }
  if (!Blockly.CSharp.definitions_['funboolline']) {
    // Function copied from Closure's goog.array.repeat.
    var functionName = Blockly.CSharp.variableDB_.getDistinctName(
        'funboolline', Blockly.Generator.NAME_TYPE);
    var func =
    'Func< bool, int, bool , bool > ' + functionName + '= (value, Blockly_n, Blockly_b) => {' +
    'if( Blockly_b){ ' + Blockly.CustomConfig.CSharpCode_ProgramLineSet + 'Convert.ToUInt32( Blockly_n); }else{ ' +
    Blockly.CustomConfig.CSharpCode_ProgramDefinitionsLineSet + 'Convert.ToUInt32( Blockly_n); }' +
    '  return value;' +
    '};';
    Blockly.CSharp.definitions_['funboolline'] = func;
  }
};

/**
 * Prepend the generated code with the variable definitions.
 * @param {string} code Generated code.
 * @return {string} Completed code.
 */
Blockly.CSharp.finish = function(code) {
  var definitions = [];//定义 : 变量variables  不同的函数块
  for (var name in Blockly.CSharp.definitions_) {
    definitions.push(Blockly.CSharp.definitions_[name]);
  }
  var maincode = '';
  if(!Blockly.CSharp.workspaceToCodeError)
  {

    Blockly.CustomConfig.CSharpProgramDefinitionsLineIndex = 0;
    Blockly.CustomConfig.CSharpProgramCurrentLineIndex = 0;
    for (var i = 0; i < definitions.length; i++)
    {
      if(definitions[i].indexOf('Func< bool, int, bool , bool > ' + Blockly.CustomConfig.CSharpBoolLineFunction) == -1) {
        var codelist = definitions[i].split('\n');
        for (var j = 0; j < codelist.length; j++) {
          if (codelist[j].indexOf(Blockly.CustomConfig.CSharpCode_ProgramLineName) != -1) {
            codelist[j] = codelist[j].replace(Blockly.CustomConfig.CSharpCode_ProgramLineName, Blockly.CustomConfig.CSharpProgramDefinitionsLineIndex);
          }
          if (codelist[j].indexOf(Blockly.CustomConfig.CSharpCode_bIsfunOrdefName) != -1) {
            codelist[j] = codelist[j].replace(Blockly.CustomConfig.CSharpCode_bIsfunOrdefName, 'false');
          }
          codelist[j] = Blockly.CustomConfig.CSharpCode_ProgramDefinitionsLineSet + Blockly.CustomConfig.CSharpProgramDefinitionsLineIndex + ';'
              + codelist[j];
          Blockly.CustomConfig.CSharpProgramDefinitionsLineIndex++;
        }
        definitions[i] = codelist.join('\n');
      }
      else {
        var codelist = definitions[i].split('\n');
        for (var j = 0; j < codelist.length; j++) {
          if (codelist[j].indexOf(Blockly.CustomConfig.CSharpCode_ProgramLineName) != -1) {
            codelist[j] = codelist[j].replace(Blockly.CustomConfig.CSharpCode_ProgramLineName, Blockly.CustomConfig.CSharpProgramDefinitionsLineIndex);
          }
          if (codelist[j].indexOf(Blockly.CustomConfig.CSharpCode_bIsfunOrdefName) != -1) {
            codelist[j] = codelist[j].replace(Blockly.CustomConfig.CSharpCode_bIsfunOrdefName, 'false');
          }
          //codelist[j] = Blockly.CustomConfig.CSharpCode_ProgramDefinitionsLineSet + Blockly.CustomConfig.CSharpProgramDefinitionsLineIndex + ';'
          //    + codelist[j];
          //Blockly.CustomConfig.CSharpProgramDefinitionsLineIndex++;
        }
        definitions[i] = codelist.join('\n');
      }
    }
    var program_code = code.replace(/\n/g, '\n  ');
    var reg = /\n(\n)*( )*(\n)*\n/g;
    program_code = program_code.replace(reg,'\n');
    var program_codelist = program_code.split('\n');
    for(var k = 0; k < program_codelist.length;k++)
    {
      if(program_codelist[k].indexOf(Blockly.CustomConfig.CSharpCode_ProgramLineName) != -1)
      {
        program_codelist[k] = program_codelist[k].replace(Blockly.CustomConfig.CSharpCode_ProgramLineName,Blockly.CustomConfig.CSharpProgramCurrentLineIndex);
      }
      if(program_codelist[k].indexOf(Blockly.CustomConfig.CSharpCode_bIsfunOrdefName) != -1)
      {
        program_codelist[k] = program_codelist[k].replace(Blockly.CustomConfig.CSharpCode_bIsfunOrdefName,'true');
      }
      program_codelist[k] = Blockly.CustomConfig.CSharpCode_ProgramLineSet + Blockly.CustomConfig.CSharpProgramCurrentLineIndex + ';'
          + program_codelist[k];
      Blockly.CustomConfig.CSharpProgramCurrentLineIndex++;
    }
    program_code = program_codelist.join('\n');
    maincode = Blockly.CustomConfig.CSharpCode_ProgramLineInitial_Prefix + definitions.join('\n\n') + '\n\n\n' +  program_code.replace(/\n/g, '\n  ');
  }
  var finalcode = 'using System;\nnamespace LLRobot\n{\npublic class GcodeProgram\n{\npublic void main()\n{\n' + maincode + '\n\n}\n}\n}';
  //return definitions.join('\n\n') + '\n\n\n' + code;//.replace(/\n/g, '\n  ')
  return finalcode;
};

/**
 * Naked values are top-level blocks with outputs that aren't plugged into
 * anything.  A trailing semicolon is needed to make this legal.
 * @param {string} line Line of generated code.
 * @return {string} Legal line of code.
 */
Blockly.CSharp.scrubNakedValue = function(line) {
  return line + ';\n';
};

Blockly.CSharp.quote_ = function(string) {
    // TODO: This is a quick hack.  Replace with goog.string.quote
    //return goog.string.quote(string);
    return "\"" + string + "\"";
};

/**
 * Common tasks for generating CSharp from blocks.
 * Handles comments for the specified block and any connected value blocks.
 * Calls any statements following this block.
 * @param {!Blockly.Block} block The current block.
 * @param {string} code The CSharp code created for this block.
 * @return {string} CSharp code with comments and subsequent blocks added.
 * @this {Blockly.CodeGenerator}
 * @private
 */

Blockly.CSharp.scrub_ = function(block, code) {
    if (code === null) {
        // Block has handled code generation itself.
        return '';
    }
    var commentCode = '';
    // Only collect comments for blocks that aren't inline.
    if (!block.outputConnection || !block.outputConnection.targetConnection) {
        // Collect comment for this block.
        var comment = block.getCommentText();
        comment = Blockly.utils.wrap(comment, Blockly.CSharp.COMMENT_WRAP - 3);
        if (comment) {
            if (block.getProcedureDef) {
                // Use a comment block for function comments.
                commentCode += '/**\n' +
                    Blockly.CSharp.prefixLines(comment + '\n', ' * ') +
                    ' */\n';
            } else {
                commentCode += Blockly.CSharp.prefixLines(comment + '\n', '// ');
            }
        }
        // Collect comments for all value arguments.
        // Don't collect comments for nested statements.
        for (var i = 0; i < block.inputList.length; i++) {
            if (block.inputList[i].type == Blockly.INPUT_VALUE) {
                var childBlock = block.inputList[i].connection.targetBlock();
                if (childBlock) {
                    var comment = Blockly.CSharp.allNestedComments(childBlock);
                    if (comment) {
                        commentCode += Blockly.CSharp.prefixLines(comment, '// ');
                    }
                }
            }
        }
    }
    var nextBlock = block.nextConnection && block.nextConnection.targetBlock();
    var nextCode = Blockly.CSharp.blockToCode(nextBlock);
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
Blockly.CSharp.getAdjusted = function(block, atId, opt_delta, opt_negate,
  opt_order) {
  var delta = opt_delta || 0;
  var order = opt_order || Blockly.CSharp.ORDER_NONE;
  if (block.workspace.options.oneBasedIndex) {
    delta--;
  }
  var defaultAtIndex = block.workspace.options.oneBasedIndex ? '1' : '0';
  if (delta) {
    var at = Blockly.CSharp.valueToCode(block, atId,
        Blockly.CSharp.ORDER_ADDITIVE) || defaultAtIndex;
  } else if (opt_negate) {
    var at = Blockly.CSharp.valueToCode(block, atId,
        Blockly.CSharp.ORDER_UNARY_PREFIX) || defaultAtIndex;
  } else {
    var at = Blockly.CSharp.valueToCode(block, atId, order) ||
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
      var innerOrder = Blockly.CSharp.ORDER_ADDITIVE;
    } else if (delta < 0) {
      at = at + ' - ' + -delta;
      var innerOrder = Blockly.CSharp.ORDER_ADDITIVE;
    }
    if (opt_negate) {
      if (delta) {
        at = '-(' + at + ')';
      } else {
        at = '-' + at;
      }
      var innerOrder = Blockly.CSharp.ORDER_UNARY_PREFIX;
    }
    innerOrder = Math.floor(innerOrder);
    order = Math.floor(order);
    if (innerOrder && order >= innerOrder) {
      at = '(' + at + ')';
    }
  }
  return at;
};
