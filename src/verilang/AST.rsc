module verilang::AST

// ─────────────────────────────────────────────
//  ABSTRACT SYNTAX TREE  for VeriLang
// ─────────────────────────────────────────────

data Program = program(Module m);

data Module = \module(str name, list[Import] imports, list[ModuleElement] elements);

data Import = \import(str moduleName);

// FIX: field names shortened to avoid Rascal generating a
// conflicting implicit accessor named "decl" for both
// SpaceDecl and OperatorDecl (both types end in "Decl").
data ModuleElement
  = spaceDecl(SpaceDecl sd)
  | operatorDecl(OperatorDecl od)
  | varDecl(VarDecl vd)
  | ruleDecl(RuleDecl rd)
  | expressionDecl(ExpressionDecl ed)
  ;

// Space declaration
data SpaceDecl
  = space(str name, SubspaceRel subspace)
  | space(str name)
  ;

data SubspaceRel = subspaceOf(str parentSpace);

// Operator declaration
data OperatorDecl
  = \operator(str name, TypeChain typeChain, list[Attribute] attributes)
  | \operator(str name, TypeChain typeChain)
  ;

// Type chain (curried: A -> B -> C)
data TypeChain
  = arrow(str domain, TypeChain codomain)
  | baseType(str typeName)
  ;

// Variable declaration
data VarDecl = varDecl(list[VarBinding] bindings);

data VarBinding = binding(str varName, str typeName);

// Rule declaration
data RuleDecl = ruleApp(OperatorApp lhs, OperatorApp rhs);

// Operator application — args can be identifiers or nested applications
data OperatorArg = idArg(str name) | appArg(OperatorApp nested);
data OperatorApp = app(str opName, list[OperatorArg] args);

// Expression declaration
data ExpressionDecl
  = expression(LogicalExpr body, list[Attribute] attributes)
  | expression(LogicalExpr body)
  ;

// Logical expressions
data LogicalExpr
  = \forall(str varName, str domain, LogicalExpr body)
  | \exists(str varName, str domain, LogicalExpr body)
  | equiv(LogicalExpr lhs, LogicalExpr rhs)
  | implies(LogicalExpr lhs, LogicalExpr rhs)
  | \and(LogicalExpr lhs, LogicalExpr rhs)
  | \or(LogicalExpr lhs, LogicalExpr rhs)
  | \neg(LogicalExpr expr)
  | appExpr(OperatorApp ap)
  | memberExpr(str element, str collection)
  | parenExpr(LogicalExpr inner)
  | litExpr(Lit literal)
  ;

// Literals
data Lit = litInt(str n) | litFloat(str r) | litChar(str c);

// Attributes
data Attribute = attrWithValue(str n, str v) | attr(str n);