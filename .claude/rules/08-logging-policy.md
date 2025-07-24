---
description: Control use of print and logging across all code
---

PRINT_USAGE:
  - **Python**: Temporary print() statements are allowed during development or when running.
  - **Octave**: Temporary disp() or fprintf() statements are allowed during development.
  - **ALL OUTPUT MUST BE IN ENGLISH** - No Spanish print statements or error messages allowed.
  - All print/disp calls must be removed before final commits unless:
    • They are part of CLI tools (e.g., click-based interfaces or Octave scripts with user interaction).
    • They appear in notebooks used for demos or traceability.
    • They serve a user-facing or critical runtime function (e.g., MRST simulation progress indicators).

LOGGING_USAGE:
  - **Python**: Use logging.info, logging.warning, and logging.error for structured output in production.
  - **Octave**: Use warning() and error() for structured output; disp() for informational messages.
  - **Python**: Avoid logging.debug unless:
    • The logger is properly configured.
    • The output can be filtered by log level.
  - **Python**: Always use logger = logging.getLogger(__name__) for module-scoped loggers.
  - **Octave**: Use consistent prefixes like '[INFO]', '[WARN]', '[ERROR]' for structured output.
  - **ALL LOG MESSAGES MUST BE IN ENGLISH** - No Spanish log messages allowed.

CLEANUP_AND_ISOLATION:
  - Extensive debug output must be isolated into scripts inside debug/.
  - Debug code and verbose logs must be excluded from main modules.
  - Final production versions must not include leftover print/disp or logging unless justified by scope.
  - Treat print/disp/log statements as disposable scaffolding unless approved by the project owner.

NOTEBOOKS_AND_EXCEPTIONS:
  - In notebooks, print/logging is allowed for readability, validation, or user interaction.
  - CLI scripts may retain structured logging or print if it improves UX or runtime feedback.
  - Octave simulation scripts may retain progress indicators (e.g., fprintf for MRST simulation progress).

