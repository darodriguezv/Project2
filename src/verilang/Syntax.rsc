module verilang::Syntax

//  LAYOUT  (whitespace + single-line comments)
layout Layout = WhitespaceOrComment* !>> [\t\n\r\ ];

lexical WhitespaceOrComment
  = [\ \t\n\r]+
  | "//" ![\n]* "\n"
  ;

//  KEYWORDS
keyword Keywords
  = "defmodule" | "using"     | "defspace"
  | "defoperator" | "defexpression" | "defrule"
  | "defvar"   | "end"        | "forall"
  | "exists"   | "defer"      | "in"
  | "and"      | "or"         | "neg"
  ;

//  LEXICALS  (tokens / terminals)

// Identifier: letter followed by letters, digits, or dashes
// Must NOT be a reserved keyword
lexical Identifier = [a-zA-Z][a-zA-Z0-9\-]* !>> [a-zA-Z0-9\-] \ Keywords;

// Integer literal: sequence of digits
lexical IntLiteral = [0-9]+ !>> [0-9];

// Float literal: digits, dot, digits
lexical FloatLiteral = [0-9]+ "." [0-9]+ !>> [0-9];

// Character literal: single-quoted character
lexical CharLiteral = "\'" ![\'\\] "\'";

//  PROGRAM ENTRY POINT
start syntax Program = Module;

//  MODULE
syntax Module
  = @category="keyword" "defmodule" Identifier Import* ModuleElement* "end"
  ;

syntax Import
  = @category="keyword" "using" Identifier
  ;

//  MODULE ELEMENTS
syntax ModuleElement
  = SpaceDecl
  | OperatorDecl
  | VarDecl
  | RuleDecl
  | ExpressionDecl
  ;

// 
//  SPACE DECLARATION
syntax SpaceDecl
  = @category="keyword" "defspace" Identifier SubspaceRel "end"
  | @category="keyword" "defspace" Identifier "end"
  ;

syntax SubspaceRel
  = "\<" Identifier          // e.g.   Set < SuperSet
  ;

//  OPERATOR DECLARATION
//  Split into two alternatives (with / without attributes).
syntax OperatorDecl
  = @category="keyword" "defoperator" Identifier ":" TypeChain AttributeList "end"
  | @category="keyword" "defoperator" Identifier ":" TypeChain "end"
  ;

// Curried type chain:  A -> B -> C
syntax TypeChain
  = Type "-\>" TypeChain
  | Type
  ;

syntax Type = Identifier;

//  VARIABLE DECLARATION
syntax VarDecl
  = @category="keyword" "defvar" {VarBinding ","}+ "end"
  ;

syntax VarBinding
  = Identifier ":" Type
  ;

//  RULE DECLARATION
syntax RuleDecl
  = @category="keyword" "defrule" OperatorApplication "-\>" OperatorApplication "end"
  ;

syntax OperatorApplication
  = "(" Identifier Identifier* ")"
  ;

//  EXPRESSION DECLARATION
//  Split into two explicit alternatives (with / without attributes).
syntax ExpressionDecl
  = @category="keyword" "defexpression" LogicalExpr AttributeList "end"
  | @category="keyword" "defexpression" LogicalExpr "end"
  ;

// ─────────────────────────────────────────────
//  LOGICAL EXPRESSIONS
//  (left-recursive and operator precedence handled by Rascal priorities)
syntax LogicalExpr
  = QuantifiedExpr
  > left ( LogicalExpr "≡"   LogicalExpr
         | LogicalExpr "=\>" LogicalExpr
         )
  > left ( LogicalExpr "and" LogicalExpr
         | LogicalExpr "or"  LogicalExpr
         )
  > "neg" LogicalExpr
  | AtomicExpr
  ;

syntax QuantifiedExpr
  = @category="keyword" "forall" Identifier "in" Identifier "." LogicalExpr
  | @category="keyword" "exists" Identifier "in" Identifier "." LogicalExpr
  ;

syntax AtomicExpr
  = OperatorApplication
  | Identifier "in" Identifier
  | Identifier Identifier Identifier          // infix operator application
  | "(" LogicalExpr ")"
  | Literal
  ;

syntax Literal
  = IntLiteral
  | FloatLiteral
  | CharLiteral
  ;

//  ATTRIBUTES
syntax AttributeList
  = "[" Attribute+ "]"
  ;

syntax Attribute
  = Identifier ":" Identifier
  | Identifier
  ;