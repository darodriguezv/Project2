module verilang::TypeChecker

// ─────────────────────────────────────────────────────────────────
//  Custom type checker  –  tasks 3 & 5
//
//  This module replicates what TypePal would do but is implemented
//  in plain Rascal so it works even when the TypePal library is not
//  installed.  See Typecheck.rsc for the TypePal-based version.
//
//  Checks performed:
//    1. Every type name in an operator signature is a declared space
//       or a built-in primitive (Int Bool Char String Float).
//    2. Every variable's declared type is a known space.
//    3. Every subspace parent is a declared space.
//    4. Every typed-space base-type annotation is a known type.
//    5. Every operator used in a rule / expression is declared.
//    6. Every identifier argument resolves to a declared var or op.
//    7. Every quantifier domain is a known space.
//    8. Typed literals carry a known type annotation.
// ─────────────────────────────────────────────────────────────────

import verilang::AST;
import verilang::Implode;
import IO;
import List;
import Set;
import Map;

// ── VLType  (mirrors what TypePal's AType would be) ───────────────
data VLType
  = spaceType(str name)
  | funcType(VLType from, VLType \to)
  | unknownType()
  ;

// ── Environment: name → type ───────────────────────────────────────
alias Env = map[str, VLType];

// ── Built-in primitive type names ─────────────────────────────────
private set[str] builtins = {"Int", "Bool", "Char", "String", "Float"};

// ── Build the module-level environment from all declarations ───────
Env buildEnv(list[ModuleElement] elems) {
  Env env = ();

  // Spaces
  for (spaceDecl(space(str n))              <- elems) env[n] = spaceType(n);
  for (spaceDecl(space(str n, _))           <- elems) env[n] = spaceType(n);
  for (spaceDecl(spaceWithType(str n, _))   <- elems) env[n] = spaceType(n);

  // Operators
  for (operatorDecl(\operator(str n, TypeChain tc))    <- elems) env[n] = buildFuncType(tc);
  for (operatorDecl(\operator(str n, TypeChain tc, _)) <- elems) env[n] = buildFuncType(tc);

  // Variables
  for (varDecl(varDecl(list[VarBinding] bs)) <- elems,
       binding(str v, str t)                 <- bs)   env[v] = spaceType(t);

  return env;
}

VLType buildFuncType(baseType(str t))           = spaceType(t);
VLType buildFuncType(arrow(str d, TypeChain r)) = funcType(spaceType(d), buildFuncType(r));

// ── Helper: is this type name valid? ──────────────────────────────
bool knownType(str t, Env env) = t in builtins || (t in env && spaceType(_) := env[t]);

list[str] requireType(str t, str ctx, Env env) {
  if (!knownType(t, env))
    return ["<ctx>: type \"<t>\" is not a declared space or built-in"];
  return [];
}

// ── Top-level check ────────────────────────────────────────────────
list[str] typeCheck(Program prog) {
  Env env = buildEnv(prog.m.elements);
  return [ err | elem <- prog.m.elements, err <- checkElem(elem, env) ];
}

// ── Element-level checks ───────────────────────────────────────────
list[str] checkElem(spaceDecl(space(str n, subspaceOf(str p))), Env env)
  = requireType(p, "Space \"<n>\": parent", env);

list[str] checkElem(spaceDecl(spaceWithType(str n, str t)), Env env)
  = requireType(t, "Space \"<n>\": base type", env);

list[str] checkElem(spaceDecl(space(str _)), Env _) = [];

list[str] checkElem(operatorDecl(\operator(str n, TypeChain tc)), Env env)
  = checkChain(n, tc, env);

list[str] checkElem(operatorDecl(\operator(str n, TypeChain tc, _)), Env env)
  = checkChain(n, tc, env);

list[str] checkElem(varDecl(varDecl(list[VarBinding] bs)), Env env) {
  list[str] errs = [];
  for (binding(str v, str t) <- bs)
    errs += requireType(t, "Variable \"<v>\"", env);
  return errs;
}

list[str] checkElem(ruleDecl(ruleApp(OperatorApp l, OperatorApp r)), Env env)
  = checkApp(l, env, {}) + checkApp(r, env, {});

list[str] checkElem(expressionDecl(expression(LogicalExpr body)), Env env)
  = checkLogical(body, env, {});

list[str] checkElem(expressionDecl(expression(LogicalExpr body, _)), Env env)
  = checkLogical(body, env, {});

default list[str] checkElem(ModuleElement _, Env _) = [];

// ── Type-chain check ───────────────────────────────────────────────
list[str] checkChain(str op, baseType(str t), Env env)
  = requireType(t, "Operator \"<op>\" codomain", env);

list[str] checkChain(str op, arrow(str d, TypeChain rest), Env env)
  = requireType(d, "Operator \"<op>\" domain", env) + checkChain(op, rest, env);

// ── Operator-application check ─────────────────────────────────────
list[str] checkApp(app(str opName, list[OperatorArg] args), Env env, set[str] bound) {
  list[str] errs = [];
  if (opName notin env)
    errs += ["Operator \"<opName>\" is not declared"];
  for (a <- args) errs += checkArg(a, env, bound);
  return errs;
}

list[str] checkArg(idArg(str n), Env env, set[str] bound) {
  if (n notin bound && n notin env)
    return ["Name \"<n>\" is not declared (not a variable or operator)"];
  return [];
}
list[str] checkArg(appArg(OperatorApp a), Env env, set[str] bound) = checkApp(a, env, bound);
list[str] checkArg(litArg(litTyped(Lit _, str t)), Env env, set[str] _)
  = requireType(t, "Typed literal", env);
default list[str] checkArg(OperatorArg _, Env _, set[str] _) = [];

// ── Logical-expression check ───────────────────────────────────────
list[str] checkLogical(LogicalExpr e, Env env, set[str] bound) {
  switch (e) {
    case \forall(str v, str d, LogicalExpr body): {
      return requireType(d, "forall domain", env)
           + checkLogical(body, env, bound + {v});
    }
    case \exists(str v, str d, LogicalExpr body): {
      return requireType(d, "exists domain", env)
           + checkLogical(body, env, bound + {v});
    }
    case equiv(LogicalExpr l, LogicalExpr r):
      return checkLogical(l, env, bound) + checkLogical(r, env, bound);
    case implies(LogicalExpr l, LogicalExpr r):
      return checkLogical(l, env, bound) + checkLogical(r, env, bound);
    case \and(LogicalExpr l, LogicalExpr r):
      return checkLogical(l, env, bound) + checkLogical(r, env, bound);
    case \or(LogicalExpr l, LogicalExpr r):
      return checkLogical(l, env, bound) + checkLogical(r, env, bound);
    case \neg(LogicalExpr inner):     return checkLogical(inner, env, bound);
    case parenExpr(LogicalExpr inner):return checkLogical(inner, env, bound);
    case appExpr(OperatorApp a):      return checkApp(a, env, bound);
    case memberExpr(str x, str s): {
      list[str] errs = [];
      if (x notin bound && x notin env)
        errs += ["Name \"<x>\" is not declared"];
      errs += requireType(s, "Member-of collection", env);
      return errs;
    }
    case litExpr(litTyped(Lit _, str t)):
      return requireType(t, "Typed literal", env);
    default: return [];
  }
}

// ── Entry points ───────────────────────────────────────────────────
list[str] checkFile(loc file) {
  Program prog = implodeProgram(readFile(file));
  return typeCheck(prog);
}

void checkAndReport(loc file) {
  println("--- Type check: <file.file> ---");
  list[str] errs = checkFile(file);
  if (isEmpty(errs)) {
    println("[OK] No type errors");
  } else {
    for (e <- errs) println("[TYPE ERROR] <e>");
  }
}
