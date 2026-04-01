module verilang::Implode

import verilang::Syntax;
import verilang::AST;
import ParseTree;

// ─────────────────────────────────────────────
//  Entry: parse a VeriLang source string → AST
// ─────────────────────────────────────────────
Program implodeProgram(str src) {
  Tree t = parse(#start[Program], src).top;
  return implodeProgram(t);
}

// ─────────────────────────────────────────────
//  Program & Module
// ─────────────────────────────────────────────
Program implodeProgram((Program)`<Module m>`) = program(implodeModule(m));

Module implodeModule((Module)`defmodule <Identifier name> <Import* imps> <ModuleElement* elems> end`)
  = \module("<name>",
            [ implodeImport(i) | i <- imps ],
            [ implodeElement(e) | e <- elems ]);

Import implodeImport((Import)`using <Identifier name>`) = \import("<name>");

// ─────────────────────────────────────────────
//  Module elements dispatch
// ─────────────────────────────────────────────
ModuleElement implodeElement((ModuleElement)`<SpaceDecl s>`)      = spaceDecl(implodeSpace(s));
ModuleElement implodeElement((ModuleElement)`defoperator <Identifier n> : <TypeChain tc> <AttributeList al> end`)
  = operatorDecl(\operator("<n>", implodeTypeChain(tc), implodeAttrList(al)));
ModuleElement implodeElement((ModuleElement)`defoperator <Identifier n> : <TypeChain tc> end`)
  = operatorDecl(\operator("<n>", implodeTypeChain(tc)));
ModuleElement implodeElement((ModuleElement)`<VarDecl v>`)        = varDecl(implodeVar(v));
ModuleElement implodeElement((ModuleElement)`<RuleDecl r>`)       = ruleDecl(implodeRule(r));
ModuleElement implodeElement((ModuleElement)`<ExpressionDecl e>`) = expressionDecl(implodeExpr(e));

// ─────────────────────────────────────────────
//  Space
// ─────────────────────────────────────────────
SpaceDecl implodeSpace((SpaceDecl)`defspace <Identifier n> <SubspaceRel s> end`)
  = space("<n>", implodeSubspaceRel(s));
SpaceDecl implodeSpace((SpaceDecl)`defspace <Identifier n> end`)
  = space("<n>");

SubspaceRel implodeSubspaceRel((SubspaceRel)`\< <Identifier parent>`)
  = subspaceOf("<parent>");

// ─────────────────────────────────────────────
//  Operator
// ─────────────────────────────────────────────
OperatorDecl implodeOperator((OperatorDecl)`defoperator <Identifier n> : <TypeChain tc> <AttributeList al> end`)
  = \operator("<n>", implodeTypeChain(tc), implodeAttrList(al));
OperatorDecl implodeOperator((OperatorDecl)`defoperator <Identifier n> : <TypeChain tc> end`)
  = \operator("<n>", implodeTypeChain(tc));

TypeChain implodeTypeChain((TypeChain)`<Type t> -\> <TypeChain rest>`)
  = arrow(implodeTypeName(t), implodeTypeChain(rest));
TypeChain implodeTypeChain((TypeChain)`<Type t>`)
  = baseType(implodeTypeName(t));

str implodeTypeName((Type)`<Identifier t>`) = "<t>";

// ─────────────────────────────────────────────
//  Variables
// ─────────────────────────────────────────────
VarDecl implodeVar((VarDecl)`defvar <VarBinding+ bs> end`)
  = varDecl([ implodeVarBinding(b) | b <- bs ]);

VarBinding implodeVarBinding((VarBinding)`<Identifier name> : <Type t>`)
  = binding("<name>", implodeTypeName(t));

// ─────────────────────────────────────────────
//  Rules
// ─────────────────────────────────────────────
RuleDecl implodeRule((RuleDecl)`defrule <OperatorApplication lhs> -\> <OperatorApplication rhs> end`)
  = rule(implodeApp(lhs), implodeApp(rhs));

OperatorApp implodeApp((OperatorApplication)`( <Identifier op> <Identifier* args> )`)
  = app("<op>", [ "<a>" | a <- args ]);

// ─────────────────────────────────────────────
//  Expressions
// ─────────────────────────────────────────────
ExpressionDecl implodeExpr((ExpressionDecl)`defexpression <LogicalExpr body> <AttributeList al> end`)
  = expression(implodeLogical(body), implodeAttrList(al));
ExpressionDecl implodeExpr((ExpressionDecl)`defexpression <LogicalExpr body> end`)
  = expression(implodeLogical(body));

LogicalExpr implodeLogical((LogicalExpr)`<QuantifiedExpr q>`) = implodeQuantified(q);
LogicalExpr implodeLogical((LogicalExpr)`<LogicalExpr l> ≡ <LogicalExpr r>`)  = equiv(implodeLogical(l), implodeLogical(r));
LogicalExpr implodeLogical((LogicalExpr)`<LogicalExpr l> =\> <LogicalExpr r>`) = implies(implodeLogical(l), implodeLogical(r));
LogicalExpr implodeLogical((LogicalExpr)`<LogicalExpr l> and <LogicalExpr r>`) = \and(implodeLogical(l), implodeLogical(r));
LogicalExpr implodeLogical((LogicalExpr)`<LogicalExpr l> or <LogicalExpr r>`)  = \or(implodeLogical(l), implodeLogical(r));
LogicalExpr implodeLogical((LogicalExpr)`neg <LogicalExpr e>`)                 = \neg(implodeLogical(e));
LogicalExpr implodeLogical((LogicalExpr)`<AtomicExpr a>`)                      = implodeAtomic(a);

LogicalExpr implodeQuantified((QuantifiedExpr)`forall <Identifier v> in <Identifier d> . <LogicalExpr body>`)
  = \forall("<v>", "<d>", implodeLogical(body));
LogicalExpr implodeQuantified((QuantifiedExpr)`exists <Identifier v> in <Identifier d> . <LogicalExpr body>`)
  = \exists("<v>", "<d>", implodeLogical(body));

LogicalExpr implodeAtomic((AtomicExpr)`<OperatorApplication a>`) = appExpr(implodeApp(a));
LogicalExpr implodeAtomic((AtomicExpr)`<Identifier x> in <Identifier s>`) = memberExpr("<x>", "<s>");
LogicalExpr implodeAtomic((AtomicExpr)`<Identifier l> <Identifier op> <Identifier r>`) = infixExpr("<l>", "<op>", "<r>");
LogicalExpr implodeAtomic((AtomicExpr)`( <LogicalExpr e> )`) = parenExpr(implodeLogical(e));
LogicalExpr implodeAtomic((AtomicExpr)`<Literal l>`) = litExpr(implodeLiteral(l));

Lit implodeLiteral((Literal)`<IntLiteral n>`) = litInt("<n>");
Lit implodeLiteral((Literal)`<FloatLiteral r>`) = litFloat("<r>");
Lit implodeLiteral((Literal)`<CharLiteral c>`) = litChar("<c>");

list[Attribute] implodeAttrList((AttributeList)`[ <Attribute+ attrs> ]`)
  = [ implodeAttr(a) | a <- attrs ];

// ─────────────────────────────────────────────
//  Attributes
// ─────────────────────────────────────────────
Attribute implodeAttr((Attribute)`<Identifier n> : <Identifier v>`) = attrWithValue("<n>", "<v>");
Attribute implodeAttr((Attribute)`<Identifier n>`)                   = attr("<n>");
