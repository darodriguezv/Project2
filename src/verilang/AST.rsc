module verilang::AST

// ─────────────────────────────────────────────
//  ABSTRACT SYNTAX TREE  for VeriLang
//  Each constructor mirrors a concrete syntax rule.
//  str is used for identifiers (names).
// ─────────────────────────────────────────────

// Top-level program is a single module
data Program = program(Module \module);

// Module: name, list of imports, list of elements
data Module = \module(str name, list[Import] imports, list[ModuleElement] elements);

// Import
data Import = \import(str moduleName);

// Module elements (union type)
data ModuleElement
  = spaceDecl(SpaceDecl space)
  | operatorDecl(OperatorDecl op)
  | varDecl(VarDecl var)
  | ruleDecl(RuleDecl rule)
  | expressionDecl(ExpressionDecl expr)
  ;

// Space declaration
data SpaceDecl
  = space(str name, SubspaceRel subspace)   // with subspace relation
  | space(str name)                          // plain space
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

// Variable declaration  (one defvar may bind multiple variables)
data VarDecl = varDecl(list[VarBinding] bindings);

data VarBinding = binding(str varName, str typeName);

// Rule declaration
data RuleDecl = rule(OperatorApp lhs, OperatorApp rhs);

data OperatorApp = app(str opName, list[str] args);

// Expression declaration
data ExpressionDecl
  = expression(LogicalExpr body, list[Attribute] attributes)
  | expression(LogicalExpr body)
  ;

// Logical expressions
data LogicalExpr
  = \forall(str varName, str domain, LogicalExpr body)
  | \exists(str varName, str domain, LogicalExpr body)
  | equiv(LogicalExpr lhs, LogicalExpr rhs)        // ≡
  | implies(LogicalExpr lhs, LogicalExpr rhs)      // =>
  | \and(LogicalExpr lhs, LogicalExpr rhs)
  | \or(LogicalExpr lhs, LogicalExpr rhs)
  | \neg(LogicalExpr expr)
  | appExpr(OperatorApp app)                        // (op args)
  | memberExpr(str element, str collection)         // x in S
  | infixExpr(str lhs, str op, str rhs)             // x op y (infix identifier application)
  | parenExpr(LogicalExpr inner)
  | litExpr(Lit literal)
  ;

// Literals
data Lit = litInt(str n) | litFloat(str r) | litChar(str c);

// Attributes
data Attribute = attrWithValue(str n, str v) | attr(str n);
