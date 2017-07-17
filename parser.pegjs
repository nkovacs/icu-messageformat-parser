{
  var inPlural = false;
}

start = token*

token
  = argument / select / plural / function
  / '#' & { return inPlural; } { return { type: 'octothorpe' }; }
  / str:char+ { return str.join(''); }

argument = '{' _ arg:id _ '}' {
    return {
      type: 'argument',
      arg: arg
    };
  }

select = '{' _ arg:id _ ',' _ (m:'select' { if (options.strictNumberSign) { inPlural = false; } return m; }) _ ',' _ cases:selectCase+ _ '}' {
    return {
      type: 'select',
      arg: arg,
      cases: cases
    };
  }

plural = '{' _ arg:id _ ',' _ type:(m:('plural'/'selectordinal') { inPlural = true; return m; } ) _ ',' _ offset:offset? cases:pluralCase+ _ '}' {
    var ls = ((type === 'selectordinal') ? options.ordinal : options.cardinal)
             || ['zero', 'one', 'two', 'few', 'many', 'other'];
    if (ls && ls.length) cases.forEach(function(c) {
      if (isNaN(c.key) && ls.indexOf(c.key) < 0) throw new Error(
        'Invalid key `' + c.key + '` for argument `' + arg + '`.' +
        ' Valid ' + type + ' keys for this locale are `' + ls.join('`, `') +
        '`, and explicit keys like `=0`.');
    });
    inPlural = false;
    return {
      type: type,
      arg: arg,
      offset: offset || 0,
      cases: cases
    };
  }

function = '{' _ arg:id _ ',' _ key:(m:id { if (options.strictNumberSign) { inPlural = false; } return m; }) _ params:functionParams '}' {
    return {
      type: 'function',
      arg: arg,
      key: key,
      params: params
    };
  }

id = $([0-9a-zA-Z$_][^ \f\n\r\t\v\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff,.+={}]*)

paramDefault = str:paramcharsDefault+ { return str.join(''); }

paramStrict = str:paramcharsStrict+ { return str.join(''); }

selectCase = _ key:id _ tokens:caseTokens { return { key: key, tokens: tokens }; }

pluralCase = _ key:pluralKey _ tokens:caseTokens { return { key: key, tokens: tokens }; }

caseTokens = '{' (_ & '{')? tokens:token* _ '}' { return tokens; }

offset = _ 'offset' _ ':' _ d:digits _ { return d; }

pluralKey
  = id
  / '=' d:digits { return d; }

functionParams
  = p:functionParamsDefault* ! { return options.strictFunctionParams; } { return p; }
  / p:functionParamsStrict* & { return options.strictFunctionParams; } { return p; }

functionParamsStrict = _ ',' p:paramStrict { return p; }

functionParamsDefault = _ ',' _ p:paramDefault _ { return p.trim(); }

doubleapos = "''" { return "'"; }

inapos = doubleapos / str:[^']+ { return str.join(''); }

quotedCurly
  = "'{"str:inapos*"'" { return '\u007B'+str.join(''); }
  / "'}"str:inapos*"'" { return '\u007D'+str.join(''); }

quoted
  = quotedCurly
  / quotedOcto:(("'#"str:inapos*"'" { return "#"+str.join(''); }) & { return inPlural; }) { return quotedOcto[0]; }
  / "'"

quotedFunctionParams
  = quotedCurly
  / "'"

char
  = doubleapos
  / quoted
  / octo:'#' & { return !inPlural; } { return octo; }
  / [^{}#\\\0-\x08\x0e-\x1f\x7f]
  / '\\\\' { return '\\'; }
  / '\\#' { return '#'; }
  / '\\{' { return '\u007B'; }
  / '\\}' { return '\u007D'; }
  / '\\u' h1:hexDigit h2:hexDigit h3:hexDigit h4:hexDigit {
      return String.fromCharCode(parseInt('0x' + h1 + h2 + h3 + h4));
    }

paramcharsCommon
  = doubleapos
  / quotedFunctionParams

paramcharsDefault
  = paramcharsCommon
  / str:[^',}]+ { return str.join(''); }

paramcharsStrict
  = paramcharsCommon
  / str:[^'}]+ { return str.join(''); }

digits = $([0-9]+)

hexDigit = [0-9a-fA-F]

_ = $([ \f\n\r\t\v\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]*)
