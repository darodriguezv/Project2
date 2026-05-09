module verilang::SemanticRules

// ─────────────────────────────────────────────────────────────────
//  Semantic Rules  –  task 6
//
//  Rule: every name that appears as an element inside a data
//  structure (operator application, type chain, variable binding,
//  subspace relation, or logical expression) must be declared
//  somewhere in the same module.
//
//  Concretely this verifies:
//    1. Operator applications: the operator is declared AND every
//       identifier argument is a declared variable or operator.
//    2. Type chains: every space name is declared (or built-in).
//    3. Variable bindings: the declared type is a known space.
//    4. Subspace relations: the parent space is declared.
//    5. Typed SpaceDecl: the base-type annotation is a known space.
//    6. Quantifiers in expressions: the domain is a declared space;
//       the bound variable is treated as locally declared.
//    7. Member-of expressions: both names must be declared.
//
//  checkProgram/1 returns a list[str] of human-readable error
//  messages (empty means the program is semantically valid).
// ─────────────────────────────────────────────────────────────────

import verilang::AST;
import List;
import Set;

// ── Built-in primitive type names ─────────────────────────────────
private set[str] builtinTypes = {"Int", "Bool", "Char", "String", "Float"};

// ── Helpers to collect declared names ─────────────────────────────

set[str] declaredSpaces(list[ModuleElement] elems)
  = { n | spaceDecl(space(n))              <- elems }
  + { n | spaceDecl(space(n, _))           <- elems }
  + { n | spaceDecl(spaceWithType(n, _))   <- elems }
  ;

set[str] declaredOperators(list[ModuleElement] elems)
  = { n | operatorDecl(\operator(n, _))    <- elems }
  + { n | operatorDecl(\operator(n, _, _)) <- elems }
  ;

set[str] declaredVars(list[ModuleElement] elems)
  = { v | varDecl(varDecl(bs)) <- elems, binding(v, _) <- bs }
  ;

// A type is valid if it is a declared space or a built-in primitive.
bool isKnownType(str t, set[str] spaces)
  = t in spaces || t in builtinTypes;

// ── Top-level check ───────────────────────────────────────────────
list[str] checkProgram(Program prog) {
  Module m = prog.m;
  set[str] spaces = declaredSpaces(m.elements);
  set[str] ops    = declaredOperators(m.elements);
  set[str] vars   = declaredVars(m.elements);

  return [ e | elem <- m.elements, e <- checkElement(elem, spaces, ops, vars) ];
}

// ── Per-element checks ────────────────────────────────────────────

// defspace Name < Parent end  — parent must be declared
list[str] checkElement(spaceDecl(space(n, subspaceOf(parent))),
                       set[str] spaces, set[str] _, set[str] _) {
  if (parent notin spaces)
    return ["Space \"<n>\": parent space \"<parent>\" is not declared"];
  return [];
}

// defspace Name : BaseType end  — base type must be known
list[str] checkElement(spaceDecl(spaceWithType(n, t)),
                       set[str] spaces, set[str] _, set[str] _) {
  if (!isKnownType(t, spaces))
    return ["Space \"<n>\": base type \"<t>\" is not a declared space or built-in"];
  return [];
}

// defspace Name end  — nothing to check
list[str] checkElement(spaceDecl(space(_)),
                       set[str] _, set[str] _, set[str] _) = [];

// defoperator Name : TypeChain  — every type in the chain must be known
list[str] checkElement(operatorDecl(\operator(n, tc)),
                       set[str] spaces, set[str] _, set[str] _)
  = checkTypeChain(n, tc, spaces);

list[str] checkElement(operatorDecl(\operator(n, tc, _)),
                       set[str] spaces, set[str] _, set[str] _)
  = checkTypeChain(n, tc, spaces);

// defvar — every declared type must be a known space
list[str] checkElement(varDecl(varDecl(bs)),
                       set[str] spaces, set[str] _, set[str] _) {
  list[str] errs = [];
  for (binding(v, t) <- bs) {
    if (!isKnownType(t, spaces))
      errs += ["Variable \"<v>\": type \"<t>\" is not a declared space or built-in"];
  }
  return errs;
}

// defrule — check both operator applications
list[str] checkElement(ruleDecl(ruleApp(lhs, rhs)),
                       set[str] spaces, set[str] ops, set[str] vars)
  = checkApp(lhs, spaces, ops, vars, {})
  + checkApp(rhs, spaces, ops, vars, {});

// defexpression
list[str] checkElement(expressionDecl(expression(body)),
                       set[str] spaces, set[str] ops, set[str] vars)
  = checkLogical(body, spaces, ops, vars, {});

list[str] checkElement(expressionDecl(expression(body, _)),
                       set[str] spaces, set[str] ops, set[str] vars)
  = checkLogical(body, spaces, ops, vars, {});

// Default: nothing to check
default list[str] checkElement(ModuleElement _,
                               set[str] _, set[str] _, set[str] _) = [];

// ── Rule 1: Operator application ──────────────────────────────────
// The operator must be declared AND every identifier argument must
// resolve to a declared variable (or the bound set) or operator.
list[str] checkApp(app(opName, args),
                   set[str] spaces, set[str] ops, set[str] vars,
                   set[str] bound) {
  list[str] errs = [];

  // Check operator existence
  if (opName notin ops)
    errs += ["Operator application: \"<opName>\" is not a declared operator"];

  // Check each argument
  for (a <- args)
    errs += checkArg(a, spaces, ops, vars, bound);

  return errs;
}

list[str] checkArg(idArg(n), set[str] spaces, set[str] ops, set[str] vars, set[str] bound) {
  if (n notin vars && n notin bound && n notin ops)
    return ["Argument \"<n>\" is neither a declared variable nor a declared operator"];
  return [];
}

list[str] checkArg(appArg(a), set[str] spaces, set[str] ops, set[str] vars, set[str] bound)
  = checkApp(a, spaces, ops, vars, bound);

// Literal arguments are always well-formed
list[str] checkArg(litArg(lit), set[str] spaces, set[str] _, set[str] _, set[str] _)
  = checkLitType(lit, spaces);

// ── Literal type annotation check ─────────────────────────────────
// If a literal carries a type annotation, verify the type is known.
list[str] checkLitType(litTyped(_, t), set[str] spaces) {
  if (!isKnownType(t, spaces))
    return ["Typed literal: annotation type \"<t>\" is not a declared space or built-in"];
  return [];
}
default list[str] checkLitType(Lit _, set[str] _) = [];

// ── Rule: Type chain ──────────────────────────────────────────────
list[str] checkTypeChain(str opName, baseType(t), set[str] spaces) {
  if (!isKnownType(t, spaces))
    return ["Operator \"<opName>\": type \"<t>\" in signature is not a declared space or built-in"];
  return [];
}
list[str] checkTypeChain(str opName, arrow(d, rest), set[str] spaces) {
  list[str] errs = [];
  if (!isKnownType(d, spaces))
    errs += ["Operator \"<opName>\": type \"<d>\" in signature is not a declared space or built-in"];
  return errs + checkTypeChain(opName, rest, spaces);
}

// ── Rule: Logical expressions ─────────────────────────────────────
list[str] checkLogical(LogicalExpr e,
                       set[str] spaces, set[str] ops, set[str] vars,
                       set[str] bound) {
  switch (e) {
    // Quantifiers introduce a new bound variable; domain must be a known space
    case \forall(v, d, body): {
      list[str] errs = [];
      if (!isKnownType(d, spaces))
        errs += ["forall: domain \"<d>\" is not a declared space or built-in"];
      return errs + checkLogical(body, spaces, ops, vars, bound + {v});
    }
    case \exists(v, d, body): {
      list[str] errs = [];
      if (!isKnownType(d, spaces))
        errs += ["exists: domain \"<d>\" is not a declared space or built-in"];
      return errs + checkLogical(body, spaces, ops, vars, bound + {v});
    }

    // Boolean connectives — recurse
    case equiv(l, r):    return checkLogical(l, spaces, ops, vars, bound) + checkLogical(r, spaces, ops, vars, bound);
    case implies(l, r):  return checkLogical(l, spaces, ops, vars, bound) + checkLogical(r, spaces, ops, vars, bound);
    case \and(l, r):     return checkLogical(l, spaces, ops, vars, bound) + checkLogical(r, spaces, ops, vars, bound);
    case \or(l, r):      return checkLogical(l, spaces, ops, vars, bound) + checkLogical(r, spaces, ops, vars, bound);
    case \neg(inner):    return checkLogical(inner, spaces, ops, vars, bound);
    case parenExpr(inner): return checkLogical(inner, spaces, ops, vars, bound);

    // Operator application
    case appExpr(a): return checkApp(a, spaces, ops, vars, bound);

    // Member-of: x in S — x must be declared, S must be a known space
    case memberExpr(x, s): {
      list[str] errs = [];
      if (x notin vars && x notin bound)
        errs += ["Member expression: \"<x>\" is not a declared variable"];
      if (!isKnownType(s, spaces))
        errs += ["Member expression: \"<s>\" is not a declared space or built-in"];
      return errs;
    }

    // Literal with possible type annotation
    case litExpr(lit): return checkLitType(lit, spaces);

    default: return [];
  }
}
