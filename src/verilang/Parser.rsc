module verilang::Parser

// ─────────────────────────────────────────────────────────────────
//  Parser  –  task 1
//  Provides entry points for parsing VeriLang (.vl) source text.
//  The parse tree can be further processed by Implode (→ AST) or
//  by the Typecheck module (→ TypePal TModel).
// ─────────────────────────────────────────────────────────────────

import verilang::Syntax;
import ParseTree;
import IO;

// Parse a .vl file given as a location and return the concrete parse tree.
Tree parseFile(loc file) {
  str src = readFile(file);
  return parse(#start[Module], src, file);
}

// Parse a raw source string (useful for tests / REPL usage).
Tree parseString(str src) {
  return parse(#start[Module], src);
}

// Parse and return only the Module node (unwrap the start production).
Module parseModule(loc file) {
  return parseFile(file).top;
}

// Attempt to parse; print a user-friendly message and re-throw on failure.
Tree tryParseFile(loc file) {
  try {
    return parseFile(file);
  } catch ParseError(loc l): {
    println("Parse error in <file> at <l>.");
    throw ParseError(l);
  }
}
