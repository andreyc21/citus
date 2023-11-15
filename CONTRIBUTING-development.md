# Coding style

* We almost always use **CamelCase**, when naming functions, variables etc., **not snake_case**.

* We **start functions with a comment**:

  ```c
  /*
   * MyNiceFunction <something in present simple tense, e.g., processes / returns / checks / takes X as input / does Y> ..
   * <some more nice words> ..
   * <some more nice words> ..
   */
  <static?> <return type>
  MyNiceFunction(..)
  {
    ..
    ..
  }
  ```

* `#includes` needs to be sorted based on below ordering and then alphabetically  and we should not include what we don't need in a file:

  * System includes (eg. #include<...>)
  * Postgres.h (eg. #include "postgres.h")
  * Toplevel imports from postgres, not contained in a directory (eg. #include "miscadmin.h")
  * General postgres includes (eg . #include "nodes/...")
  * Toplevel citus includes, not contained in a directory (eg. #include "citus_verion.h")
  * Columnar includes (eg. #include "columnar/...")
  * Distributed includes (eg. #include "distributed/...")

* Comments:
  ```c
  /* single line comments start with a lower-case */

  /*
   * We start multi-line comments with a capital letter
   * and keep adding a star to the beginning of each line
   * until we close the comment with a star and a slash.
   */
  ```

* Order of function implementations and their declarations in a file:

  We define static functions after the functions that call them. For example:

  ```c
  #include<..>
  #include<..>
  ..
  ..
  typedef struct
  {
    ..
    ..
  } MyNiceStruct;
  ..
  ..
  PG_FUNCTION_INFO_V1(my_nice_udf1);
  PG_FUNCTION_INFO_V1(my_nice_udf2);
  ..
  ..
  // ..  somewhere on top of the file …
  static void MyNiceStaticlyDeclaredFunction1(…);
  static void MyNiceStaticlyDeclaredFunction2(…);
  ..
  ..


  void
  MyNiceFunctionExternedViaHeaderFile(..)
  {
    ..
    ..
    MyNiceStaticlyDeclaredFunction1(..);
    ..
    ..
    MyNiceStaticlyDeclaredFunction2(..);
    ..
  }

  ..
  ..

  // we define this first because it's called by MyNiceFunctionExternedViaHeaderFile()
  // before MyNiceStaticlyDeclaredFunction2()
  static void
  MyNiceStaticlyDeclaredFunction1(…)
  {
  }
  ..
  ..

  // then we define this
  static void
  MyNiceStaticlyDeclaredFunction2(…)
  {
  }
  ```

# Making a pull request ready for reviews

Asking for help and asking for reviews are two different things. When you're asking for help, you're asking for someone to help you with something that you're not expected to know.

But when you're asking for a review, you're asking for someone to review your work and provide feedback. So, when you're asking for a review, you're expected to make sure that:

* Your changes don't perform **unnecessary line addition / deletions / style changes on unrelated files / lines**.

* All CI jobs are **passing**, including **style checks** and **flaky test detection jobs**.

* Your PR has necessary amount of **tests** and that they're passing.

* You separated as much as possible work into **separate PRs**, e.g., a prerequisite bugfix, a refactoring etc..

* Your PR doesn't introduce a typo or something that you can easily fix yourself.

* After all CI jobs pass, code-coverage measurement job (CodeCov as of today) then kicks in. That's why it's important to make the **tests passing** first. At that point, you're expected to check **CodeCov annotations** that can be seen in the **Files Changed** tab and expected to make sure that it doesn't complain about any lines that are not covered. For example, it's ok if CodeCov complains about an `ereport()` call that you put for an "unexpected-but-better-than-crashing" case, but it's not ok if it complains about an uncovered `if` branch that you added.

* And finally, perform a **self-review** to make sure that:
  * Code and code-comments reflects the idea **without requiring an extra explanation** via a chat message / email / PR comment.
    This is important because we don't expect developers to reach out to author / read about the whole discussion in the PR to understand the idea behind a commit merged into `main` branch.
  * PR description is clear enough.
  * If-and-only-if you're **introducing a user facing change / bugfix**, your PR has a line that starts with `DESCRIPTION: <Present simple tense word that starts with a capital letter, e.g., Adds support for / Fixes / Disallows>`.
  * **Commit messages** are clear enough if the commits are doing logically different things.

# Regression test best practices

* Instead of connecting to different nodes to check catalog tables, should use `run_command_on_all_nodes()` because it's faster than keep disconnecting / connecting to different nodes.

* Tests should **define functions** for repetitive actions, e.g., by wrapping usual queries used to check catalog tables.
  If the function is presumed to be used by other tests in future, then the function needs to defined in `multi_test_helpers.sql`.

* If you're adding a new file, consider using `src/test/regress/bin/create_test.py` to create the file. Or if you want to manually create it, make sure that your test file creates a schema and that it drops the schema at the end of the test to make sure that it doesn't leak any objects behind. See which lines `src/test/regress/bin/create_test.py` adds to the test file to understand what you need to do.

  For the object that are not bound to a schema, make sure to drop them at the end of the test too, such as databases and roles.
