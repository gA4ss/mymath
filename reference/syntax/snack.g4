grammar snack;

//// Lexer规则

// 匹配所有换行符
NL : ('\r' '\n' | '\r' | '\n');

// 匹配所有注释, 发送到'HIDDEN'通道
BLOCKCOMMENT	: '%{' .*?  '%}' -> channel(HIDDEN);
COMMENT			: '%' .*? NL  -> channel(HIDDEN);

// 忽略空格或制表符
WS : [ \t] -> skip;

// 忽略省略号
ELLIPSIS: '...' -> skip;

// 关键字
ARGUMENTS   : 'arguments';
BREAK		: 'break';
CASE		: 'case';
CATCH		: 'catch';
CLASSDEF	: 'classdef';
CLEANUP     : 'unwind_protect_cleanup';
CONTINUE	: 'continue';
ELSE		: 'else';
ELSEIF		: 'elseif';
END			: 'end';
FOR			: 'for';
FUNCTION	: 'function';
GET			: 'get';
GLOBAL		: 'global';
IF			: 'if';
OTHERWISE	: 'otherwise';
PARFOR      : 'parfor';
PERSISTENT	: 'persistent';
PROPERTIES	: 'properties';
RETURN		: 'return';
SET			: 'set';
SPMD        : 'spmd';
SWITCH		: 'switch';
TRY			: 'try';
UNWIND      : 'unwind_protect';
WHILE		: 'while';

// 特殊关键字

STATIC	    : 'Static';

ASSIGN			        : '=';

EXPR_AND                : '&';
EXPR_OR                 : '|';
EXPR_PLUS			    : '+';
EXPR_MINUS              : '-';
EXPR_LT                 : '<';
EXPR_GT                 : '>';
EXPR_MUL                : '*';
EXPR_DIV                : '/';
EXPR_NOT                : '!';
EXPR_POW                : '^';

EXPR_LE                 : '<=';
EXPR_EQ                 : '==';
EXPR_NE                 : '!=';
EXPR_GE                 : '>=';

EXPR_EPOW               : '.^';
EXPR_EPLUS              : '.+';
EXPR_EMINUS             : '.-';
EXPR_EMUL               : '.*';
EXPR_EDIV               : './';
EXPR_LEFTDIV            : '\\';
EXPR_ELEFTDIV           : '.\\';

AND_AND                 : '&&';
OR_OR                   : '||';
PLUS_PLUS               : '++';
MINUS_MINUS             : '--';

ADD_EQ                  : '+=';
SUB_EQ                  : '-=';
MUL_EQ                  : '*=';
DIV_EQ                  : '/=';
LEFTDIV_EQ              : '\\=';
POW_EQ                  : '^=';
EMUL_EQ                 : '.*=';
EDIV_EQ                 : './=';
ELEFTDIV_EQ             : '.\\=';
EPOW_EQ                 : '.^=';
AND_EQ                  : '&=';
OR_EQ                   : '|=';

// 特殊字符
AT						: '@';
COLON                   : ':';
COMMA					: ',';
DOT						: '.';
SEMI_COLON				: ';';
LEFT_BRACE				: '{';
LEFT_PARENTHESIS		: '(';
LEFT_SQUARE_BRACKET		: '[';
QUESTION				: '?';
RIGHT_BRACE				: '}';
RIGHT_PARENTHESIS		: ')';
RIGHT_SQUARE_BRACKET	: ']';

ID: [a-zA-Z] [a-zA-Z0-9_]*;

// 虚数
IMAGINARY :	INT 'i'
          |	FLOAT 'i'
          ;

NUMBER    : INT
          | FLOAT
          ;

FLOAT     :	DIGIT+ '.' DIGIT* EXPONENT?
          |	DIGIT+			  EXPONENT
          |	'.' DIGIT+ EXPONENT?
          ;

INT: DIGIT+;

// 指数
fragment
EXPONENT  : ('e'|'E') ('+'|'-')? DIGIT+;

fragment
DIGIT     : [0-9];

// TODO: 双引号字符串，单引号字符串
STRING    : '\'' ( ~('\'' | '\r' | '\n') | '\'\'')* '\'';


//// 解释器规则


// =======================
// 脚本 或 方法文件
// =======================

program         : (statement opt_sep)* EOF
                ;

// 语句
statement       : expression
                | command
                ;

// ===========
// 表达式
// ===========

identifier      : ID
                ;

string          : STRING
                ;

// 常量
constant        : NUMBER
                | string
                ;

// 矩阵
matrix          : '[' matrix_rows ']'
                ;

// 矩阵_行集
matrix_rows     : cell_or_matrix_row (';' cell_or_matrix_row)*
                ;

// 元胞
cell            : '{' cell_rows '}'
                ;
// 元胞_行集
cell_rows       : cell_or_matrix_row (';' cell_or_matrix_row)*
                ;

// 元胞_或_矩阵_行

cell_or_matrix_row
                : arg_list (',' arg_list)*
                ;

// 匿名_函数_句柄
anon_fcn_handle : '@' param_list expression
                ;

// 主_表达式
primary_expr    : identifier
                | constant
                | matrix
                | cell
                | '(' expression ')'
                ;

// 逻辑_冒号
magic_colon     : COLON
                ;

// 逻辑_波浪号
magic_tilde     : EXPR_NOT
                ;

// 参数_列表
arg_list        : (arg_list_ele (COMMA arg_list_ele)*)?
                ;

// 参数_列表_元素
arg_list_ele    : expression
                | magic_colon
                | magic_tilde    // '!' 是否可用索引表达式
                ;

// 间接_引用_操作符
indirect_ref_op : DOT
                ;

// 操作符_表达式

oper_expr       : primary_expr                          # oper_expr_primary_expr
                | oper_expr PLUS_PLUS                   # oper_expr_unary_postfix_PLUS_PLUS
                | oper_expr MINUS_MINUS                 # oper_expr_unary_postfix_MINUS_MINUS
                | oper_expr '(' ')'                     # oper_expr_parens_noargs
                | oper_expr '(' arg_list ')'            # oper_expr_parens
                | oper_expr '{' '}'                     # oper_expr_braces_noargs
                | oper_expr '{' arg_list '}'            # oper_expr_braces
//                | oper_expr HERMITIAN
//                | oper_expr TRANSPOSE
//                | oper_expr indirect_ref_op STRUCT_ELT
                | oper_expr indirect_ref_op '(' expression ')' # oper_expr_indirect_ref_op
                | PLUS_PLUS oper_expr                   # oper_expr_unary_prefix_PLUS_PLUS
                | MINUS_MINUS oper_expr                 # oper_expr_unary_prefix_MINUS_MINUS
                | EXPR_NOT oper_expr                    # oper_expr_unary_prefix_EXPR_NOT
                | EXPR_PLUS oper_expr                   # oper_expr_unary_prefix_EXPR_PLUS
                | EXPR_MINUS oper_expr                  # oper_expr_unary_prefix_EXPR_MINUS
                | lhs=oper_expr EXPR_POW rhs=power_expr         # oper_expr_EXPR_POW
                | lhs=oper_expr EXPR_EPOW rhs=power_expr        # oper_expr_EXPR_EPOW
                | lhs=oper_expr EXPR_PLUS rhs=oper_expr         # oper_expr_EXPR_PLUS
                | lhs=oper_expr EXPR_MINUS rhs=oper_expr        # oper_expr_EXPR_MINUS
                | lhs=oper_expr EXPR_MUL rhs=oper_expr          # oper_expr_EXPR_MUL
                | lhs=oper_expr EXPR_DIV rhs=oper_expr          # oper_expr_EXPR_DIV
                | lhs=oper_expr EXPR_EPLUS rhs=oper_expr        # oper_expr_EXPR_EPLUS
                | lhs=oper_expr EXPR_EMINUS rhs=oper_expr       # oper_expr_EXPR_EMINUS
                | lhs=oper_expr EXPR_EMUL rhs=oper_expr         # oper_expr_EXPR_EMUL
                | lhs=oper_expr EXPR_EDIV rhs=oper_expr         # oper_expr_EXPR_EDIV
                | lhs=oper_expr EXPR_LEFTDIV rhs=oper_expr      # oper_expr_EXPR_LEFTDIV
                | lhs=oper_expr EXPR_ELEFTDIV rhs=oper_expr     # oper_expr_EXPR_ELEFTDIV
                ;

// 幂_表达式
power_expr      : primary_expr                          # power_expr_primary_expr
                | power_expr PLUS_PLUS                  # power_expr_unary_postfix_PLUS_PLUS
                | power_expr MINUS_MINUS                # power_expr_unary_postfix_MINUS_MINUS
                | power_expr '(' ')'                    # power_expr_parens_noargs
                | power_expr '(' arg_list ')'           # power_expr_parens
                | power_expr '{' '}'                    # power_expr_braces_noargs
                | power_expr '{' arg_list '}'           # power_expr_braces
//                | power_expr indirect_ref_op STRUCT_ELT
                | power_expr indirect_ref_op '(' expression ')' # power_expr_indirect_ref_op
                | PLUS_PLUS power_expr                  # power_expr_unary_prefix_PLUS_PLUS
                | MINUS_MINUS power_expr                # power_expr_unary_prefix_MINUS_MINUS
                | EXPR_NOT power_expr                   # power_expr_unary_prefix_EXPR_NOT
                | EXPR_PLUS power_expr                  # power_expr_unary_prefix_EXPR_PLUS
                | EXPR_MINUS power_expr                 # power_expr_unary_prefix_EXPR_MINUS
                ;

// 冒号_表达式
colon_expr      : base=oper_expr ':' limit=oper_expr
                | base=oper_expr ':' limit=oper_expr ':' incr=oper_expr
                ;

// 简单_表达式
simple_expr     : oper_expr
                | colon_expr
                | lhs=simple_expr EXPR_LT rhs=simple_expr
                | lhs=simple_expr EXPR_LE rhs=simple_expr
                | lhs=simple_expr EXPR_EQ rhs=simple_expr
                | lhs=simple_expr EXPR_GE rhs=simple_expr
                | lhs=simple_expr EXPR_GT rhs=simple_expr
                | lhs=simple_expr EXPR_NE rhs=simple_expr
                | lhs=simple_expr EXPR_AND rhs=simple_expr
                | lhs=simple_expr EXPR_OR rhs=simple_expr
                | lhs=simple_expr AND_AND rhs=simple_expr
                | lhs=simple_expr OR_OR rhs=simple_expr
                ;

// 赋值_左部
assign_lhs      : simple_expr
                ;

// 赋值表达式，如：=，+=，-=
assign_expr     : assign_lhs ASSIGN expression
                | assign_lhs ADD_EQ expression
                | assign_lhs SUB_EQ expression
                | assign_lhs MUL_EQ expression
                | assign_lhs DIV_EQ expression
                | assign_lhs LEFTDIV_EQ expression
                | assign_lhs POW_EQ expression
                | assign_lhs EMUL_EQ expression
                | assign_lhs EDIV_EQ expression
                | assign_lhs ELEFTDIV_EQ expression
                | assign_lhs EPOW_EQ expression
                | assign_lhs AND_EQ expression
                | assign_lhs OR_EQ expression
                ;

// 表达式
expression      : simple_expr
                | assign_expr
                | anon_fcn_handle
                ;

// ================================================
// 命令, 声明和方法定义
// ================================================

command         : declaration
                | select_command
                | loop_command
                | jump_command
                | spmd_command
                | except_command
                | function
                ;

// ======================
// 声明语句
// ======================

declaration     : GLOBAL decl_elt*
                | PERSISTENT decl_elt*
                ;

decl_elt        : identifier
                | decl_assign
                ;

decl_assign     : identifier ASSIGN expression
                ;

// ====================
// 选择语句
// ====================

select_command  : if_command
                | switch_command
                ;

// if指令
if_command      : IF if_cause
                  (ELSEIF elseif_cause)*
                  (ELSE else_cause)?
                  END
                ;

// if子句
if_cause        : expression opt_sep (statement opt_sep)*
                ;

// elseif子句
elseif_cause    : opt_sep expression opt_sep (statement opt_sep)*
                ;

// else子句
else_cause      : opt_sep (statement opt_sep)*
                ;

// switch_指令
switch_command  : SWITCH expression opt_sep
                      (switch_case)*
                      (switch_otherwise)?
                  END
                ;

// swtich_case_指令
switch_case     : CASE opt_sep expression opt_sep
                      (statement opt_sep)*
                ;

// switch_otherwise_指令
switch_otherwise
                : OTHERWISE opt_sep
                      (statement opt_sep)*
                ;

// 循环_指令,
loop_command    : for_command
                | parfor_command
                ;

for_command     : FOR assign_lhs ASSIGN expression opt_sep
                      (statement opt_sep)*
                  END
                | FOR '(' assign_lhs ASSIGN expression ')' opt_sep
                      (statement opt_sep)*
                  END
                ;

parfor_command  : PARFOR assign_lhs ASSIGN expression opt_sep
                      (statement opt_sep)*
                  END
                | PARFOR '(' assign_lhs ASSIGN expression ',' expression ')' opt_sep
                      (statement opt_sep)*
                  END
                ;

// =======
// 跳转
// =======

jump_command    : BREAK
                | CONTINUE
                | RETURN
                ;

// =======================
// 并行执行池
// =======================

spmd_command    : SPMD opt_sep
                      (statement opt_sep)*
                  END
                ;

// ==========
// 异常
// ==========

except_command  : UNWIND opt_sep
                      (statement opt_sep)*
                  CLEANUP opt_sep
                      (statement opt_sep)*
                  END
                | TRY opt_sep
                      (statement opt_sep)*
                  CATCH opt_sep
                      (statement opt_sep)*
                  END
                | TRY opt_sep
                      (statement opt_sep)*
                  END
                ;

// ===========================
// 方法参数列表
// ===========================

param_list      : '(' (param_list_elt (COMMA param_list_elt)*)? ')'
                ;

param_list_elt  : decl_elt
                | magic_tilde
                ;

// ===================================
// 方法返回值名称列表
// ===================================

return_list     : '[' identifier (COMMA identifier)* ']'
                ;

// ===================
// 方法定义
// ===================

fcn_name        : identifier
                | GET '.' identifier
                | SET '.' identifier
                ;

function        : FUNCTION (return_list ASSIGN)? fcn_name param_list opt_sep
                      (statement opt_sep)*
                  END
                ;

// 分隔符_无_换行
sep_no_nl       : ','
                | ';'
                | sep_no_nl ','
                | sep_no_nl ';'
                ;

opt_sep_no_nl   : // empty
                | sep_no_nl
                ;

opt_nl          : // empty
                | nl
                ;

// 换号符
nl              : '\n'
                | nl '\n'
                ;

// 分隔符 ',' ';' '\n' ';\n' ',\n' ...
sep             : ','
                | ';'
                | '\n'
                | sep ','
                | sep ';'
                | sep '\n'
                ;

opt_sep         : // empty
                | sep
                ;
