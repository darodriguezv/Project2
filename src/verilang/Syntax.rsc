module verilang::Syntax

layout Layout
  = [\ \t\n\r]+
  | "//" ![\n]* "\n"
  ;

keyword Keywords
  = "defmodule" | "using" | "defspace" | "defoperator" | "defexpression"
  | "defrule" | "defvar" | "end" | "forall" | "exists" | "in"
  | "and" | "or" | "neg"
  ;

lexical Identifier
  = @category="identifier" [a-zA-Z] [a-zA-Z0-9\-]* !>> [a-zA-Z0-9\-] \ Keywords
  ;

lexical IntLiteral
  = @category="literal" [0-9]+ !>> [0-9]
  ;

lexical FloatLiteral
  = @category="literal" [0-9]+ "." [0-9]+ !>> [0-9]
  ;

lexical CharLiteral
  = @category="literal" "\'" ![\'\\] "\'"
  ;

start syntax Module
  = "defmodule" Identifier ImportList ModuleElement* "end"
  ;

syntax ImportList
  = Import*
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
  = "(" IdentifierList ")"
  ;

syntax IdentifierList
  = {Identifier ""}+
  ;

syntax ExpressionDecl
  = "defexpression" LogicalExpression AttributeList "end"
  | "defexpression" LogicalExpression "end"
  ;

syntax LogicalExpression
  = QuantifiedExpression
  | AtomicExpression
  | LogicalExpression "≡" LogicalExpression
  | LogicalExpression "and" LogicalExpression
  | LogicalExpression "or" LogicalExpression
  | "neg" LogicalExpression
  ;

syntax QuantifiedExpression
  = "forall" Identifier "in" Identifier "." LogicalExpression
  | "exists" Identifier "in" Identifier "." LogicalExpression
  ;

syntax AtomicExpression
  = OperatorApplication
  | Identifier "in" Identifier
  | Identifier Identifier Identifier
  | "(" LogicalExpression ")"
  ;

syntax AttributeList
  = "[" Attribute+ "]"
  ;

syntax Attribute
  = Identifier
  | Identifier ":" Identifier
  ;