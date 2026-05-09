module verilang::Typecheck

// ─────────────────────────────────────────────────────────────────
//  TypePal type checker  –  tasks 3 & 5
//
//  Installs TypePal into VeriLang and verifies that:
//    • Every space referenced in a type chain is declared.
//    • Every variable's declared type is a known space.
//    • Every operator used in a rule / expression is declared.
//    • Every variable used in an expression is in scope.
//    • Every literal's explicit type annotation names a known space.
//    • Subspace parents are declared spaces.
//
//  Built-in primitive type names are pre-defined so the user does
//  not have to declare them:
//    Int  Bool  Char  String  Float
// ─────────────────────────────────────────────────────────────────

import verilang::Syntax;
import ParseTree;
import IO;
import Message;

import analysis::typepal::TypePal;
import analysis::typepal::Collector;

// ── AType ─────────────────────────────────────────────────────────
// The type of a VeriLang name is either a "space type" (the sort it
// belongs to) or a function type (operator with curried arguments).
data AType
  = spaceType(str name)
  | funcType(AType from, AType \to)
  | unknownType()
  ;

// ── IdRole ────────────────────────────────────────────────────────
data IdRole
  = spaceId()
  | operatorId()
  | varId()
  ;

// ── Primitive types (always available without declaration) ────────
private set[str] builtinTypes = {"Int", "Bool", "Char", "String", "Float"};

// ── TypePal configuration ─────────────────────────────────────────
bool vlSubtype(AType sub, AType sup, Solver _s) = (sub == sup);

TypePalConfig vlConfig() = tconfig(isSubType = vlSubtype);

// ── Collect: Module ───────────────────────────────────────────────
void collect(start[Module] sm, Collector c) {
  collect(sm.top, c);
}

void collect((Module)`defmodule <Identifier _name> <Import* _imps> <ModuleElement* elems> end`,
             Collector c) {
  for (ModuleElement e <- elems) collect(e, c);
}

// ── Collect: SpaceDecl ────────────────────────────────────────────
void collect((ModuleElement)`<SpaceDecl sd>`, Collector c) {
  collect(sd, c);
}

void collect((SpaceDecl)`defspace <Identifier name> end`, Collector c) {
  c.define("<name>", spaceId(), name, defType(spaceType("<name>")));
}

void collect((SpaceDecl)`defspace <Identifier name> <SubspaceRelation sr> end`, Collector c) {
  c.define("<name>", spaceId(), name, defType(spaceType("<name>")));
  if ((SubspaceRelation)`\< <Identifier parent>` := sr) {
    useTypeRef(parent, c);
  }
}

// defspace Name : BaseType end  – the base type must be a known space
void collect((SpaceDecl)`defspace <Identifier name> : <Identifier baseType> end`, Collector c) {
  c.define("<name>", spaceId(), name, defType(spaceType("<name>")));
  useTypeRef(baseType, c);
}

// ── Collect: OperatorDecl ─────────────────────────────────────────
void collect((ModuleElement)`<OperatorDecl od>`, Collector c) {
  collect(od, c);
}

void collect((OperatorDecl)`defoperator <Identifier name> : <TypeChain tc> end`, Collector c) {
  AType t = buildFuncType(tc);
  c.define("<name>", operatorId(), name, defType(t));
  collectTypeChain(tc, c);
}

void collect((OperatorDecl)`defoperator <Identifier name> : <TypeChain tc> <AttributeList _al> end`,
             Collector c) {
  AType t = buildFuncType(tc);
  c.define("<name>", operatorId(), name, defType(t));
  collectTypeChain(tc, c);
}

// ── Collect: VarDecl ──────────────────────────────────────────────
void collect((ModuleElement)`<VarDecl vd>`, Collector c) {
  collect(vd, c);
}

void collect((VarDecl)`defvar <{VarBinding ","}+ bindings> end`, Collector c) {
  for (VarBinding b <- bindings) {
    if ((VarBinding)`<Identifier v> : <Identifier t>` := b) {
      c.define("<v>", varId(), v, defType(spaceType("<t>")));
      useTypeRef(t, c);
    }
  }
}

// ── Collect: RuleDecl ─────────────────────────────────────────────
void collect((ModuleElement)`<RuleDecl rd>`, Collector c) {
  collect(rd, c);
}

void collect((RuleDecl)`defrule <OperatorApplication lhs> -\> <OperatorApplication rhs> end`,
             Collector c) {
  collectApp(lhs, c);
  collectApp(rhs, c);
}

// ── Collect: ExpressionDecl ───────────────────────────────────────
void collect((ModuleElement)`<ExpressionDecl ed>`, Collector c) {
  collect(ed, c);
}

void collect((ExpressionDecl)`defexpression <LogicalExpression body> end`, Collector c) {
  collectLogical(body, c);
}

void collect((ExpressionDecl)`defexpression <LogicalExpression body> <AttributeList _al> end`,
             Collector c) {
  collectLogical(body, c);
}

// ── Collect: LogicalExpression ────────────────────────────────────
void collectLogical(
    (LogicalExpression)`forall <Identifier v> in <Identifier d> . <LogicalExpression body>`,
    Collector c) {
  useTypeRef(d, c);
  c.enterScope(body);
  c.define("<v>", varId(), v, defType(spaceType("<d>")));
  collectLogical(body, c);
  c.leaveScope(body);
}

void collectLogical(
    (LogicalExpression)`exists <Identifier v> in <Identifier d> . <LogicalExpression body>`,
    Collector c) {
  useTypeRef(d, c);
  c.enterScope(body);
  c.define("<v>", varId(), v, defType(spaceType("<d>")));
  collectLogical(body, c);
  c.leaveScope(body);
}

void collectLogical((LogicalExpression)`<LogicalExpression l> ≡ <LogicalExpression r>`,   Collector c) { collectLogical(l, c); collectLogical(r, c); }
void collectLogical((LogicalExpression)`<LogicalExpression l> =\> <LogicalExpression r>`, Collector c) { collectLogical(l, c); collectLogical(r, c); }
void collectLogical((LogicalExpression)`<LogicalExpression l> and <LogicalExpression r>`, Collector c) { collectLogical(l, c); collectLogical(r, c); }
void collectLogical((LogicalExpression)`<LogicalExpression l> or <LogicalExpression r>`,  Collector c) { collectLogical(l, c); collectLogical(r, c); }
void collectLogical((LogicalExpression)`neg <LogicalExpression e>`,                       Collector c) { collectLogical(e, c); }
void collectLogical((LogicalExpression)`( <LogicalExpression e> )`,                       Collector c) { collectLogical(e, c); }
void collectLogical((LogicalExpression)`<AtomicExpression ae>`,                           Collector c) { collectAtomic(ae, c); }

// ── Collect: AtomicExpression ─────────────────────────────────────
void collectAtomic((AtomicExpression)`<OperatorApplication app>`, Collector c) {
  collectApp(app, c);
}

void collectAtomic((AtomicExpression)`<Identifier x> in <Identifier s>`, Collector c) {
  c.use(x, {varId()});
  useTypeRef(s, c);
}

// Plain literal — no type references to check
void collectAtomic((AtomicExpression)`<Literal _lit>`, Collector c) { ; }

// Typed literal — the annotation must name a known space
void collectAtomic((AtomicExpression)`<TypedLiteral tl>`, Collector c) {
  if ((TypedLiteral)`<Literal _> : <Identifier t>` := tl) {
    useTypeRef(t, c);
  }
}

// ── Collect: OperatorApplication (used in rules and expressions) ──
void collectApp((OperatorApplication)`( <Identifier op> <OperatorArg* args> )`, Collector c) {
  c.use(op, {operatorId()});
  for (OperatorArg arg <- args) collectArg(arg, c);
}

void collectArg((OperatorArg)`<Identifier id>`,         Collector c) { c.use(id, {varId(), operatorId()}); }
void collectArg((OperatorArg)`<OperatorApplication a>`, Collector c) { collectApp(a, c); }
void collectArg((OperatorArg)`<Literal _>`,             Collector c) { ; }
void collectArg((OperatorArg)`<TypedLiteral tl>`,       Collector c) {
  if ((TypedLiteral)`<Literal _> : <Identifier t>` := tl) {
    useTypeRef(t, c);
  }
}

// ── Helpers ───────────────────────────────────────────────────────

// Register a use of a type-name identifier.
// Built-in primitive types are implicitly available; all others must
// be declared as a space in the current module.
void useTypeRef(Identifier t, Collector c) {
  if ("<t>" notin builtinTypes) {
    c.use(t, {spaceId()});
  }
}

void collectTypeChain((TypeChain)`<Identifier t>`, Collector c) {
  useTypeRef(t, c);
}

void collectTypeChain((TypeChain)`<Identifier t> -\> <TypeChain rest>`, Collector c) {
  useTypeRef(t, c);
  collectTypeChain(rest, c);
}

AType buildFuncType((TypeChain)`<Identifier t>`) = spaceType("<t>");
AType buildFuncType((TypeChain)`<Identifier t> -\> <TypeChain rest>`) =
  funcType(spaceType("<t>"), buildFuncType(rest));

// ── Main entry points ─────────────────────────────────────────────

// Run TypePal on a .vl file and return the raw TModel.
TModel checkFile(loc file) {
  Tree pt = parse(#start[Module], readFile(file), file);
  return typePalCheck(pt, collect, config = vlConfig());
}

// Run TypePal and print a human-readable report to the console.
void checkAndReport(loc file) {
  println("--- TypePal type check: <file.file> ---");
  TModel m = checkFile(file);
  list[Message] msgs = m.messages;
  if (isEmpty(msgs)) {
    println("[OK] No type errors");
  } else {
    for (msg <- msgs) {
      switch (msg) {
        case error(str txt, loc at):
          println("[TYPE ERROR] <at.begin.line>:<at.begin.column>  <txt>");
        case warning(str txt, loc at):
          println("[WARNING]    <at.begin.line>:<at.begin.column>  <txt>");
        default:
          println("[INFO]       <msg>");
      }
    }
  }
}
