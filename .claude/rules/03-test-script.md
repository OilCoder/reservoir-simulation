---
description: Defines test writing rules, naming conventions, and structure enforcement for all test files.
---

TEST_ROOT_FOLDER:
  - All automated tests live inside the top-level directory tests/.
  - Test discovery supports both Python (Pytest) and Octave files.
  - Temporary or debugging scripts belong in debug/ or must be named dbg_*.m so they are ignored.
  - Test scripts are committed to maintain project quality and enable CI/CD workflows.

FILENAME_CONVENTION:
  - See 05-file-naming.md for naming files guidance.

TEST_WRITING_RULES:
  - Each test file must target a single function, class, or module.
  - **Python tests**: Test functions follow the format: def test_<method>_<case>().
  - **Octave tests**: Test functions follow the format: function test_<method>_<case>().
  - Use assert statements (Python) or assert() calls (Octave) tied to expected behavior.
  - Prefer isolated logic; avoid shared state unless using fixtures.
  - **Python**: Use @pytest.mark.<tag> to group tests (e.g. integration, gpu, slow).
  - **Octave**: Use comments like % TEST_GROUP: integration, gpu, slow.
  - Keep tests simple, readable, and focused on one thing per test.
  - **ALL TEST CODE AND COMMENTS MUST BE IN ENGLISH** - No Spanish allowed in test files.

INDEPENDENCE_AND_ORDERING:
  - Tests must be self-contained; execution order should not matter.
  - The numeric prefix serves only for natural sorting and must never create dependencies.
