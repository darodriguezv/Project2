# VeriLang

## Overview
This project defines the domain-specific VeriLang using Rascal.
It includes:
- A concrete syntax (grammar)
- An abstract syntax tree (AST)
- An imploder that converts parse trees into AST values
- Valid and invalid example programs for parser testing

The repository is intended for grammar design, parsing experiments, and validation of language constructs such as modules, operators, rules, and logical expressions.

## Project Structure
- META-INF/RASCAL.MF: Rascal project manifest (project name, source folder, libraries).
- src/verilang/Syntax.rsc: Concrete grammar of VeriLang.
- src/verilang/AST.rsc: AST type definitions.
- src/verilang/Implode.rsc: ParseTree to AST conversion.
- examples/valid: Programs that should parse successfully.
- examples/invalid: Programs that should fail parsing.

## Main Modules
### Syntax
File: src/verilang/Syntax.rsc
Defines lexical and context-free rules, plus precedence/associativity for logical expressions.

### AST
File: src/verilang/AST.rsc
Defines all semantic data types for VeriLang, including Program, Module, declarations, expressions, and literals.

### Implode
File: src/verilang/Implode.rsc
Provides:
- implodeProgram(str src): parse source text and produce AST Program
- Helper functions for each nonterminal to map parse tree nodes into AST constructors

## Requirements
- Visual Studio Code with Rascal extension installed
- Rascal terminal opened in this project workspace


## How To Run
### 1. Open Rascal terminal in this project
In VS Code, open the Rascal terminal with the project selected.

### 2. Import parser modules
Run these commands in order:

    import IO;
    import verilang::Syntax;
    import verilang::AST;
    import verilang::Implode;

### 3. Parse valid examples

    implodeProgram(readFile(|project://project2/examples/valid/01-empty.vl|));
    implodeProgram(readFile(|project://project2/examples/valid/02-bool.vl|));
    implodeProgram(readFile(|project://project2/examples/valid/03-nat.vl|));

Expected result: each command returns an AST Program value.

### 4. Check invalid examples

    implodeProgram(readFile(|project://project2/examples/invalid/01-missing-end.vl|));
    implodeProgram(readFile(|project://project2/examples/invalid/02-bad-rule.vl|));
    implodeProgram(readFile(|project://project2/examples/invalid/03-bad-operator.vl|));

Expected result: parse errors for each file.

### 5. Test a new file you create
1. Create a new file in one of these folders:
   - examples/valid for a program that should parse
   - examples/invalid for a program that should fail
2. Example path:

    examples/valid/my-new-program.vl

3. Parse it from the Rascal terminal:

    implodeProgram(readFile(|project://project2/examples/valid/my-new-program.vl|));

If the file is in invalid, use its path instead. A valid file should return an AST Program value; an invalid file should report a parse error.

### 6. Write and test a program directly in Rascal terminal
You can define a source string and parse it without creating a file:

    str src = "defmodule Quick defspace Nat end end";
    implodeProgram(src);

For a longer program, concatenate lines:

    str src2 = "defmodule Quick "
             + "defoperator zero : Nat end "
             + "defexpression forall x in Nat . (zero) end "
             + "end";
    implodeProgram(src2);


