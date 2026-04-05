module verilang::Implode

import verilang::Syntax;
import verilang::AST;
import ParseTree;

Module parseModule(str src) {
  Tree t = parse(#start[Module], src).top;
  return toModule(t);
}

Module toModule((Module)`defmodule <Identifier name> <ImportList imports> <ModuleElement* elements> end`)
  = module_("<name>", toImportList(imports), [toModuleElement(e) | e <- elements]);

ImportList toImportList((ImportList)`<Import* imports>`)
  = importList([toImport(i) | i <- imports]);

Import toImport((Import)`using <Identifier moduleName>`)
  = import_("<moduleName>");

ModuleElement toModuleElement((ModuleElement)`<SpaceDecl decl>`)
  = moduleSpaceDecl(toSpaceDecl(decl));
ModuleElement toModuleElement((ModuleElement)`<OperatorDecl decl>`)
  = moduleOperatorDecl(toOperatorDecl(decl));
ModuleElement toModuleElement((ModuleElement)`<VarDecl decl>`)
  = moduleVarDecl(toVarDecl(decl));
ModuleElement toModuleElement((ModuleElement)`<RuleDecl decl>`)
  = moduleRuleDecl(toRuleDecl(decl));
ModuleElement toModuleElement((ModuleElement)`<ExpressionDecl decl>`)
  = moduleExpressionDecl(toExpressionDecl(decl));

SpaceDecl toSpaceDecl((SpaceDecl)`defspace <Identifier name> <SubspaceRelation relation> end`)
  = spaceWithParent("<name>", toSubspaceRelation(relation));
SpaceDecl toSpaceDecl((SpaceDecl)`defspace <Identifier name> end`)
  = spaceOnly("<name>");

SubspaceRelation toSubspaceRelation((SubspaceRelation)`\< <Identifier parent>`)
  = subspaceRelation("<parent>");

OperatorDecl toOperatorDecl((OperatorDecl)`defoperator <Identifier name> : <TypeChain chain> <AttributeList attrs> end`)
  = operatorWithAttributes("<name>", toTypeChain(chain), toAttributeList(attrs));
OperatorDecl toOperatorDecl((OperatorDecl)`defoperator <Identifier name> : <TypeChain chain> end`)
  = operatorOnly("<name>", toTypeChain(chain));

TypeChain toTypeChain((TypeChain)`<Identifier domain> -\> <TypeChain codomain>`)
  = typeArrow("<domain>", toTypeChain(codomain));
TypeChain toTypeChain((TypeChain)`<Identifier name>`)
  = typeBase("<name>");

VarDecl toVarDecl((VarDecl)`defvar <{VarBinding ","}+ bindings> end`)
  = varDecl([toVarBinding(b) | b <- bindings]);

VarBinding toVarBinding((VarBinding)`<Identifier name> : <Identifier typeName>`)
  = varBinding("<name>", "<typeName>");

RuleDecl toRuleDecl((RuleDecl)`defrule <OperatorApplication lhs> -\> <OperatorApplication rhs> end`)
  = ruleDecl(toOperatorApplication(lhs), toOperatorApplication(rhs));

OperatorApplication toOperatorApplication((OperatorApplication)`( <IdentifierList ids> )`) {
  list[str] idStrings = toIdentifierList(ids).values;
  str op = idStrings[0];
  if (size(idStrings) == 1) {
    return operatorApplicationNoArgs(op);
  }
  return operatorApplication(op, identifierList(idStrings[1 ..]));
}

IdentifierList toIdentifierList((IdentifierList)`<{Identifier ""}+ values>`)
  = identifierList(["<v>" | v <- values]);

ExpressionDecl toExpressionDecl((ExpressionDecl)`defexpression <LogicalExpression body> <AttributeList attrs> end`)
  = expressionWithAttributes(toLogicalExpression(body), toAttributeList(attrs));
ExpressionDecl toExpressionDecl((ExpressionDecl)`defexpression <LogicalExpression body> end`)
  = expressionOnly(toLogicalExpression(body));

LogicalExpression toLogicalExpression((LogicalExpression)`<QuantifiedExpression quantified>`)
  = logicalQuantified(toQuantifiedExpression(quantified));
LogicalExpression toLogicalExpression((LogicalExpression)`<AtomicExpression atomic>`)
  = logicalAtomic(toAtomicExpression(atomic));
LogicalExpression toLogicalExpression((LogicalExpression)`<LogicalExpression lhs> and <LogicalExpression rhs>`)
  = logicalAnd(toLogicalExpression(lhs), toLogicalExpression(rhs));
LogicalExpression toLogicalExpression((LogicalExpression)`<LogicalExpression lhs> or <LogicalExpression rhs>`)
  = logicalOr(toLogicalExpression(lhs), toLogicalExpression(rhs));
LogicalExpression toLogicalExpression((LogicalExpression)`neg <LogicalExpression expr>`)
  = logicalNeg(toLogicalExpression(expr));
LogicalExpression toLogicalExpression((LogicalExpression)`<LogicalExpression lhs> ≡ <LogicalExpression rhs>`)
  = logicalEquiv(toLogicalExpression(lhs), toLogicalExpression(rhs));

QuantifiedExpression toQuantifiedExpression((QuantifiedExpression)`forall <Identifier varName> in <Identifier domain> . <LogicalExpression body>`)
  = forallExpr("<varName>", "<domain>", toLogicalExpression(body));
QuantifiedExpression toQuantifiedExpression((QuantifiedExpression)`exists <Identifier varName> in <Identifier domain> . <LogicalExpression body>`)
  = existsExpr("<varName>", "<domain>", toLogicalExpression(body));

AtomicExpression toAtomicExpression((AtomicExpression)`<OperatorApplication app>`)
  = atomicOperatorApplication(toOperatorApplication(app));
AtomicExpression toAtomicExpression((AtomicExpression)`<Identifier element> in <Identifier collection>`)
  = atomicMembership("<element>", "<collection>");
AtomicExpression toAtomicExpression((AtomicExpression)`<Identifier lhs> <Identifier op> <Identifier rhs>`)
  = atomicInfix("<lhs>", "<op>", "<rhs>");
AtomicExpression toAtomicExpression((AtomicExpression)`( <LogicalExpression expression> )`)
  = atomicParen(toLogicalExpression(expression));

AttributeList toAttributeList((AttributeList)`[ <Attribute+ attrs> ]`)
  = attributeList([toAttribute(a) | a <- attrs]);

Attribute toAttribute((Attribute)`<Identifier name>`)
  = attributeOnly("<name>");
Attribute toAttribute((Attribute)`<Identifier name> : <Identifier v>`)
  = attributeWithValue("<name>", "<v>");