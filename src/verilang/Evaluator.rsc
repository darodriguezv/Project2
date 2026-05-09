module verilang::Evaluator

// ─────────────────────────────────────────────────────────────────
//  Evaluator  –  task 2
//  Reads a .vl file, parses it, implodes it to an AST, runs the
//  semantic checks, and prints a structured report to the console.
//
//  Usage from the Rascal REPL / VS Code terminal:
//    import verilang::Evaluator;
//    run(|file:///absolute/path/to/program.vl|);
// ─────────────────────────────────────────────────────────────────

import verilang::Syntax;
import verilang::AST;
import verilang::Implode;
import verilang::Parser;
import verilang::SemanticRules;
import verilang::Typecheck;
import ParseTree;
import IO;
import List;
import String;
import Message;

// ── Main entry point ───────────────────────────────────────────────
void run(loc file) {
  println("=== VeriLang Evaluator ===");
  println("File : <file.path>");
  println("");

  // 1. Parse
  Tree pt;
  try {
    pt = parseFile(file);
    println("[OK] Parsing");
  } catch ParseError(loc l): {
    println("[FAIL] Parse error at line <l.begin.line>, column <l.begin.column>");
    return;
  }

  // 2. Build AST
  Program prog;
  try {
    prog = implodeProgram(readFile(file));
    println("[OK] AST construction");
  } catch e: {
    println("[FAIL] AST construction – <e>");
    return;
  }

  // 3. Print module structure
  println("");
  printProgram(prog);

  // 4. TypePal type check (task 5)
  println("");
  println("--- TypePal type check ---");
  TModel tm = checkFile(file);
  list[Message] msgs = tm.messages;
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
          println("[INFO]  <msg>");
      }
    }
  }

  // 5. Existence / semantic checks (task 6)
  println("");
  println("--- Semantic checks ---");
  list[str] errors = checkProgram(prog);
  if (isEmpty(errors)) {
    println("[OK] All checks passed");
  } else {
    for (e <- errors) {
      println("[ERROR] <e>");
    }
  }

  println("");
  println("=== Done ===");
}

// ── Pretty-print helpers ───────────────────────────────────────────

void printProgram(Program prog) {
  Module m = prog.m;
  println("--- Module: <m.name> ---");

  if (!isEmpty(m.imports)) {
    str impStr = intercalate(", ", [ i.moduleName | i <- m.imports ]);
    println("  Imports : <impStr>");
  }

  for (elem <- m.elements) {
    printElement(elem);
  }
}

void printElement(spaceDecl(space(str n))) {
  println("  defspace <n>");
}

void printElement(spaceDecl(space(str n, subspaceOf(str p)))) {
  // literal < must be escaped in Rascal string templates
  println("  defspace <n> \< <p>");
}

void printElement(spaceDecl(spaceWithType(str n, str t))) {
  println("  defspace <n> : <t>");
}

void printElement(operatorDecl(\operator(str n, TypeChain tc))) {
  println("  defoperator <n> : <ppTypeChain(tc)>");
}

void printElement(operatorDecl(\operator(str n, TypeChain tc, list[Attribute] attrs))) {
  str attrStr = intercalate(", ", [ ppAttr(a) | a <- attrs ]);
  println("  defoperator <n> : <ppTypeChain(tc)>  [<attrStr>]");
}

void printElement(varDecl(varDecl(list[VarBinding] bs))) {
  str bindStr = intercalate(", ", [ b.varName + ":" + b.typeName | b <- bs ]);
  println("  defvar <bindStr>");
}

void printElement(ruleDecl(ruleApp(OperatorApp lhs, OperatorApp rhs))) {
  println("  defrule <ppApp(lhs)> -\> <ppApp(rhs)>");
}

void printElement(expressionDecl(expression(LogicalExpr body))) {
  println("  defexpression <ppLogical(body)>");
}

void printElement(expressionDecl(expression(LogicalExpr body, list[Attribute] attrs))) {
  str attrStr = intercalate(", ", [ ppAttr(a) | a <- attrs ]);
  println("  defexpression <ppLogical(body)>  [<attrStr>]");
}

default void printElement(ModuleElement _) { ; }

// ── Rendering functions ────────────────────────────────────────────

str ppTypeChain(baseType(str t))           = t;
str ppTypeChain(arrow(str d, TypeChain r)) = "<d> -\> <ppTypeChain(r)>";

str ppApp(app(str op, list[OperatorArg] args)) {
  if (isEmpty(args)) return "(<op>)";
  str argStr = intercalate(" ", [ ppArg(a) | a <- args ]);
  return "(<op> <argStr>)";
}

str ppArg(idArg(str n))        = n;
str ppArg(appArg(OperatorApp a)) = ppApp(a);
str ppArg(litArg(Lit lit))     = ppLit(lit);

str ppLit(litInt(str n))              = n;
str ppLit(litFloat(str r))            = r;
str ppLit(litChar(str c))             = c;
str ppLit(litBool(str b))             = b;
str ppLit(litString(str s))           = s;
str ppLit(litTyped(Lit inner, str t)) = ppLit(inner) + ":" + t;

str ppLogical(LogicalExpr e) {
  switch (e) {
    case \forall(str v, str d, LogicalExpr body):
      return "forall <v> in <d> . <ppLogical(body)>";
    case \exists(str v, str d, LogicalExpr body):
      return "exists <v> in <d> . <ppLogical(body)>";
    case equiv(LogicalExpr l, LogicalExpr r):
      return ppLogical(l) + " ≡ " + ppLogical(r);
    case implies(LogicalExpr l, LogicalExpr r):
      return ppLogical(l) + " =\> " + ppLogical(r);
    case \and(LogicalExpr l, LogicalExpr r):
      return ppLogical(l) + " and " + ppLogical(r);
    case \or(LogicalExpr l, LogicalExpr r):
      return ppLogical(l) + " or " + ppLogical(r);
    case \neg(LogicalExpr inner):
      return "neg " + ppLogical(inner);
    case parenExpr(LogicalExpr inner):
      return "(" + ppLogical(inner) + ")";
    case appExpr(OperatorApp a):
      return ppApp(a);
    case memberExpr(str x, str s):
      return x + " in " + s;
    case litExpr(Lit lit):
      return ppLit(lit);
    default:
      return "?";
  }
}

str ppAttr(attr(str n))                    = n;
str ppAttr(attrWithValue(str n, str v))    = n + ":" + v;
