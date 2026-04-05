module verilang::AST

data Module
  = module_(str name, ImportList imports, list[ModuleElement] elements)
  ;

data ImportList
  = importList(list[Import] imports)
  ;

data Import
  = import_(str moduleName)
  ;

data ModuleElement
  = moduleSpaceDecl(SpaceDecl decl)
  | moduleOperatorDecl(OperatorDecl decl)
  | moduleVarDecl(VarDecl decl)
  | moduleRuleDecl(RuleDecl decl)
  | moduleExpressionDecl(ExpressionDecl decl)
  ;

data SpaceDecl
  = spaceWithParent(str name, SubspaceRelation parent)
  | spaceOnly(str name)
  ;

data SubspaceRelation
  = subspaceRelation(str parent)
  ;

data OperatorDecl
  = operatorWithAttributes(str name, TypeChain typeChain, AttributeList attributes)
  | operatorOnly(str name, TypeChain typeChain)
  ;

data TypeChain
  = typeArrow(str domain, TypeChain codomain)
  | typeBase(str name)
  ;

data VarDecl
  = varDecl(list[VarBinding] bindings)
  ;

data VarBinding
  = varBinding(str name, str typeName)
  ;

data RuleDecl
  = ruleDecl(OperatorApplication lhs, OperatorApplication rhs)
  ;

data OperatorApplication
  = operatorApplication(str operatorName, IdentifierList args)
  | operatorApplicationNoArgs(str operatorName)
  ;

data IdentifierList
  = identifierList(list[str] values)
  ;

data ExpressionDecl
  = expressionWithAttributes(LogicalExpression body, AttributeList attributes)
  | expressionOnly(LogicalExpression body)
  ;

data LogicalExpression
  = logicalQuantified(QuantifiedExpression expr)
  | logicalAtomic(AtomicExpression expr)
  | logicalAnd(LogicalExpression lhs, LogicalExpression rhs)
  | logicalOr(LogicalExpression lhs, LogicalExpression rhs)
  | logicalNeg(LogicalExpression expr)
  | logicalEquiv(LogicalExpression lhs, LogicalExpression rhs)
  ;

data QuantifiedExpression
  = forallExpr(str varName, str domain, LogicalExpression body)
  | existsExpr(str varName, str domain, LogicalExpression body)
  ;

data AtomicExpression
  = atomicOperatorApplication(OperatorApplication app)
  | atomicMembership(str element, str collection)
  | atomicInfix(str lhs, str op, str rhs)
  | atomicParen(LogicalExpression expression)
  ;

data AttributeList
  = attributeList(list[Attribute] attributes)
  ;

data Attribute
  = attributeOnly(str name)
  | attributeWithValue(str name, str val)
  ;

data Identifier
  = identifier(str val)
  ;
