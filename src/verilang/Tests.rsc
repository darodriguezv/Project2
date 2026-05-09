module verilang::Tests

import verilang::Evaluator;
import IO;

private loc base = |project://project2/examples|;

private list[loc] validExamples = [
  base + "valid/01-empty.vl",
  base + "valid/02-bool.vl",
  base + "valid/03-nat.vl",
  base + "valid/04-typed.vl"
];

private list[loc] invalidExamples = [
  base + "invalid/01-missing-end.vl",
  base + "invalid/02-bad-rule.vl",
  base + "invalid/03-bad-operator.vl",
  base + "invalid/04-bad-type.vl",
  base + "invalid/05-bad-element.vl"
];

void runAll() {
  println("========================================");
  println(" VeriLang Test Suite");
  println("========================================");

  println("\n--- VALID examples (should pass all checks) ---\n");
  for (f <- validExamples) run(f);

  println("\n--- INVALID examples (should report errors) ---\n");
  for (f <- invalidExamples) run(f);

  println("\n========================================");
  println(" Test suite complete");
  println("========================================");
}
