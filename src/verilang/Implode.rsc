module verilang::Implode

import verilang::Syntax;
import verilang::AST;
import ParseTree;

Program implodeProgram(str src) {
  Tree t = parse(#start[Module], src).top;
  return implodeModule(t);
}

Program implodeModule((Module)`defmodule <Identifier name> <Import* imps> <ModuleElement* elems> end`)
  = program(\module("<name>",
            [ implodeImport(i) | i <- imps ],
            [ implodeElement(e) | e <- elems ]));

Import implodeImport((Import)`using <Identifier name>`) = \import("<name>");

ModuleElement implodeElement((ModuleElement)`<SpaceDecl s>`)      = spaceDecl(implodeSpace(s));
ModuleElement implodeElement((ModuleElement)`<OperatorDecl od>`)  = operatorDecl(implodeOperator(od));
ModuleElement implodeElement((ModuleElement)`<VarDecl v>`)        = varDecl(implodeVar(v));
ModuleElement implodeElement((ModuleElement)`<RuleDecl r>`)       = ruleDecl(implodeRule(r));
ModuleElement implodeElement((ModuleElement)`<ExpressionDecl e>`) = expressionDecl(implodeExpr(e));

SpaceDecl implodeSpace((SpaceDecl)`defspace <Identifier n> <SubspaceRelation s> end`)
  = space("<n>", implodeSubspaceRel(s));
SpaceDecl implodeSpace((SpaceDecl)`defspace <Identifier n> end`)
  = space("<n>");

SubspaceRel implodeSubspaceRel((SubspaceRelation)`\< <Identifier parent>`)
  = subspaceOf("<parent>");

OperatorDecl implodeOperator((OperatorDecl)`defoperator <Identifier n> : <TypeChain tc> <AttributeList al> end`)
  = \operator("<n>", implodeTypeChain(tc), implodeAttrList(al));
OperatorDecl implodeOperator((OperatorDecl)`defoperator <Identifier n> : <TypeChain tc> end`)
  = \operator("<n>", implodeTypeChain(tc));

TypeChain implodeTypeChain((TypeChain)`<Identifier t> -\> <TypeChain rest>`)
  = arrow("<t>", implodeTypeChain(rest));
TypeChain implodeTypeChain((TypeChain)`<Identifier t>`)
  = baseType("<t>");

VarDecl implodeVar((VarDecl)`defvar <{VarBinding ","}+ bs> end`)
  = varDecl([ implodeVarBinding(b) | b <- bs ]);

VarBinding implodeVarBinding((VarBinding)`<Identifier name> : <Identifier t>`)
  = binding("<name>", "<t>");

RuleDecl implodeRule((RuleDecl)`defrule <OperatorApplication lhs> -\> <OperatorApplication rhs> end`)
  = ruleApp(implodeApp(lhs), implodeApp(rhs));

OperatorApp implodeApp((OperatorApplication)`( <Identifier op> <OperatorArg* args> )`)
  = app("<op>", [ implodeArg(a) | a <- args ]);

OperatorArg implodeArg((OperatorArg)`<Identifier id>`)         = idArg("<id>");
OperatorArg implodeArg((OperatorArg)`<OperatorApplication a>`) = appArg(implodeApp(a));

ExpressionDecl implodeExpr((ExpressionDecl)`defexpression <LogicalExpression body> <AttributeList al> end`)
  = expression(implodeLogical(body), implodeAttrList(al));
ExpressionDecl implodeExpr((ExpressionDecl)`defexpression <LogicalExpression body> end`)
  = expression(implodeLogical(body));

LogicalExpr implodeLogical((LogicalExpression)`forall <Identifier v> in <Identifier d> . <LogicalExpression body>`) = \forall("<v>", "<d>", implodeLogical(body));
LogicalExpr implodeLogical((LogicalExpression)`exists <Identifier v> in <Identifier d> . <LogicalExpression body>`) = \exists("<v>", "<d>", implodeLogical(body));
LogicalExpr implodeLogical((LogicalExpression)`<LogicalExpression l> ≡ <LogicalExpression r>`)     = equiv(implodeLogical(l), implodeLogical(r));
LogicalExpr implodeLogical((LogicalExpression)`<LogicalExpression l> =\> <LogicalExpression r>`)   = implies(implodeLogical(l), implodeLogical(r));
LogicalExpr implodeLogical((LogicalExpression)`<LogicalExpression l> and <LogicalExpression r>`)   = \and(implodeLogical(l), implodeLogical(r));
LogicalExpr implodeLogical((LogicalExpression)`<LogicalExpression l> or <LogicalExpression r>`)    = \or(implodeLogical(l), implodeLogical(r));
LogicalExpr implodeLogical((LogicalExpression)`neg <LogicalExpression e>`)                         = \neg(implodeLogical(e));
LogicalExpr implodeLogical((LogicalExpression)`( <LogicalExpression e> )`)                         = parenExpr(implodeLogical(e));
LogicalExpr implodeLogical((LogicalExpression)`<AtomicExpression a>`)                              = implodeAtomic(a);

LogicalExpr implodeQuantified((QuantifiedExpression)`forall <Identifier v> in <Identifier d> . <LogicalExpression body>`)
  = \forall("<v>", "<d>", implodeLogical(body));
LogicalExpr implodeQuantified((QuantifiedExpression)`exists <Identifier v> in <Identifier d> . <LogicalExpression body>`)
  = \exists("<v>", "<d>", implodeLogical(body));

LogicalExpr implodeAtomic((AtomicExpression)`<OperatorApplication a>`)                        = appExpr(implodeApp(a));
LogicalExpr implodeAtomic((AtomicExpression)`<Identifier x> in <Identifier s>`)               = memberExpr("<x>", "<s>");
LogicalExpr implodeAtomic((AtomicExpression)`<Literal lit>`)                                  = litExpr(implodeLiteral(lit));

Lit implodeLiteral((Literal)`<IntLiteral n>`)   = litInt("<n>");
Lit implodeLiteral((Literal)`<FloatLiteral r>`) = litFloat("<r>");
Lit implodeLiteral((Literal)`<CharLiteral c>`)  = litChar("<c>");

list[verilang::AST::Attribute] implodeAttrList((AttributeList)`[ <Attribute+ attrs> ]`)
  = [ implodeAttr(a) | a <- attrs ];

verilang::AST::Attribute implodeAttr((Attribute)`<Identifier n> : <Identifier v>`) = attrWithValue("<n>", "<v>");
verilang::AST::Attribute implodeAttr((Attribute)`<Identifier n>`)                   = attr("<n>");