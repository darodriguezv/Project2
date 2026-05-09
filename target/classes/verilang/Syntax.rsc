module verilang::Syntax

layout Layout = WhitespaceOrComment* !>> [\ \t\n\r];

lexical WhitespaceOrComment
  = [\ \t\n\r]
  | "//" ![\n]* "\n"
  ;

keyword Keywords
  = "defmodule" | "using"     | "defspace"
  | "defoperator" | "defexpression" | "defrule"
  | "defvar"   | "end"        | "forall"
  | "exists"   | "in"
  | "and"      | "or"         | "neg"
  | "true"     | "false"
  ;

lexical Identifier
  = [a-zA-Z] [a-zA-Z0-9\-]* !>> [a-zA-Z0-9\-] \ Keywords
  ;

lexical IntLiteral    = [0-9]+ !>> [0-9];
lexical FloatLiteral  = [0-9]+ "." [0-9]+ !>> [0-9];
lexical CharLiteral   = "\'" ![\'\\] "\'";
lexical BoolLiteral   = "true" | "false";
lexical StringLiteral = "\"" ![\"\n]* "\"";

start syntax Module
  = "defmodule" Identifier Import* ModuleElement* "end"
  ;

syntax Import
  = "using" Identifier
  ;

syntax ModuleElement
  = SpaceDecl
  | OperatorDecl
  | VarDecl
  | RuleDecl
  | ExpressionDecl
  ;

syntax SpaceDecl
  = "defspace" Identifier SubspaceRelation "end"
  | "defspace" Identifier "end"
  | "defspace" Identifier ":" Identifier "end"
  ;

syntax SubspaceRelation
  = "\<" Identifier
  ;

syntax OperatorDecl
  = "defoperator" Identifier ":" TypeChain AttributeList "end"
  | "defoperator" Identifier ":" TypeChain "end"
  ;

syntax TypeChain
  = Identifier "-\>" TypeChain
  | Identifier
  ;

syntax VarDecl
  = "defvar" {VarBinding ","}+ "end"
  ;

syntax VarBinding
  = Identifier ":" Identifier
  ;

syntax RuleDecl
  = "defrule" OperatorApplication "-\>" OperatorApplication "end"
  ;

syntax OperatorApplication
  = "(" Identifier OperatorArg* ")"
  ;

syntax OperatorArg
  = Identifier
  | OperatorApplication
  | @prefer TypedLiteral
  | Literal
  ;

syntax ExpressionDecl
  = "defexpression" LogicalExpression AttributeList "end"
  | "defexpression" LogicalExpression "end"
  ;

// Quantifiers are inlined at the TOP of the priority chain so they
// extend as far right as possible (standard logic convention).
syntax LogicalExpression
  = "forall" Identifier "in" Identifier "." LogicalExpression
  | "exists" Identifier "in" Identifier "." LogicalExpression
  > left ( LogicalExpression "≡"   LogicalExpression
         | LogicalExpression "=\>" LogicalExpression
         )
  > left ( LogicalExpression "and" LogicalExpression
         | LogicalExpression "or"  LogicalExpression
         )
  > "neg" LogicalExpression
  | @avoid "(" LogicalExpression ")"
  | AtomicExpression
  ;

// TypedLiteral preferred over plain Literal to resolve the subset ambiguity
syntax AtomicExpression
  = OperatorApplication
  | Identifier "in" Identifier
  > @prefer TypedLiteral
  | Literal
  ;

// A literal with an explicit type annotation: e.g.  42:Int  true:Bool
syntax TypedLiteral
  = Literal ":" Identifier
  ;

syntax Literal
  = IntLiteral
  | FloatLiteral
  | CharLiteral
  | BoolLiteral
  | StringLiteral
  ;

syntax AttributeList
  = "[" Attribute+ "]"
  ;

syntax Attribute
  = Identifier ":" Identifier
  | Identifier
  ;
