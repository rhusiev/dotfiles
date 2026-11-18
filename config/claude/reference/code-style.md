# Changing code

code_style_rules:
  MUST:
    - "Treat the code as requiring diligence and attention to detail - keep the quality
       of the code around your change intact"
    - "No magic numbers"
    - "Avoid duplicating code or comments. Two or three repetitions are sometimes
       justified; systematic repetition almost never is"
    - "Never log secrets (tokens/passwords/keys) or sensitive payloads"
    - "Treat code size as a cost. For substantive changes where line counts are
       meaningful, report the net product, test and doc line deltas, using the
       repository's scope and exclusions, and name the counting method. A refactor
       that grows product code says what the growth buys. Judge quality on more
       than line count, but never treat growth as free"
    - "When I raise code size or verbosity, measure like for like first - product
       against product, the same scope and the same counting method - then deliver
       measured reductions. An audit or a list of candidates is not a reduction.
       Add a non-regression check for the measured problem with the repository's
       tooling, and let only reviewed baseline changes raise it"
    - "Do not introduce a project-wide requirement to document every item, such as
       a missing-docs lint. Document published or stable APIs, and the invariants,
       units, contracts and non-obvious reasons that safe maintenance needs. If an
       existing requirement mainly produces comments that restate names, propose
       narrowing it"
    - "When a measured budget - size, memory or time - is exceeded, try several
       measured reductions over a few hours before asking me to raise it, and never
       raise it yourself. Prefer reductions that remove code or work. A reduction
       that adds a custom subsystem reports its line cost next to its saving"

  SHOULD:
    - "Use trailing commas in multi-line literals to reduce diff noise"
    - "If there is a choice between an okay solution and a solution that is usually used in the industry, choose the latter. If it adds too much complexity, though, notify the user, so that they make the choice"
    - "Keep functions small (~<=30 lines) and single-responsibility"
    - "Constructors must be lightweight (no I/O/network); use explicit lifecycle methods like connect()/load()"
    - "Use modern language features - e.g. list[...] type hints in Python; compile-time
       features, templates and smart pointers in C++"
    - "When part of the code needs a refactor to be of good quality, mention it to me
       and suggest the improvement"
    - "Model state with types whose variants carry their own data. Do not encode one
       state machine as several optional fields or as parallel collections that must
       stay aligned"
    - "Avoid redundant type mirrors across layers. Keep distinct types only where
       they enforce different invariants, trust boundaries, dependencies, ownership
       or versioning, and derive or test the conversions between them"
    - "Split a module or package that owns more than one of orchestration, storage
       mechanics, process supervision and presentation"

  AVOID:
    - "Excessive blank lines inside if/for/try blocks"
    - "Unnecessary/excessive comments in code. Only explain hard-to-understand parts of code"
    - "Logging full payloads by default; log identifiers + key context instead"

  ALLOW:
    - "Slight line-length overflow for URLs/very readable strings when justified"

python_style_rules:
  TOOLING: "If a rule conflicts with repo tooling (formatter/linter/type-checker), tooling wins"

  MUST:
    - "Use snake_case for variables/functions/modules/files/packages"
    - "Use PascalCase for classes and exceptions (prefer *Error suffix for custom errors)"
    - "Use UPPER_SNAKE_CASE for constants"
    - "Use a single leading '_' for internal/private members; avoid dunder unless name-mangling is truly required"
    - "Boolean names must read naturally: is_*, has_*, should_*, enabled"
    - "Test files must be named *_test.py"
    - "PEP8 formatting: 4-space indentation, no trailing whitespace"
    - "Line length target: 88 chars"
    - "Imports grouped: stdlib → third-party → local, with exactly one blank line between groups"
    - "No wildcard imports"
    - "Type annotate all function args + returns (especially public APIs)"
    - "Write docstrings for all public modules/classes/functions; docstrings must match behavior"
    - "Globals only in app/globals.py; globals must be UPPERCASE and not mutable state"
    - "Raise appropriate exception types with actionable context; never silently swallow exceptions"

  SHOULD:
    - "Prefer modern typing: list[int], dict[str,int], tuple[int,...], X | None (use __future__ annotations if needed)"
    - "Prefer absolute imports"
    - "Prefer f-strings for interpolation"
    - "Keep return behavior consistent (don’t mix returning values and returning None unpredictably)"
    - "Use exception chaining when wrapping: raise DomainError(...) from exc"
    - "Use context managers (with ...) for resources; prefer finally only when needed"
    - "Prefer composition over inheritance"
    - "Use @dataclass for simple value objects"
    - "Tests should follow AAA structure and be deterministic; use fixtures for shared setup"

  AVOID:
    - "Dumping grounds like utils.py/helpers.py/misc.py (unless narrowly scoped and clearly named)"
    - "Any typing unless necessary (if used, explain why)"
    - "Side effects in compute_*/build_* functions (no I/O, network, or global mutation)"
    - "except Exception: unless you re-raise or wrap into a meaningful domain error"
    - "print() in library/business logic"
    - "Hard-coded secrets; eval/exec; string-formatted SQL (must be parameterized)"
    - "Time-based flaky tests; sleeps without an explicit reason"

  ALLOW:
    - "print() only for CLI/user-facing scripts output"
    - "Literal time.sleep(x) only"

  NOTES:
    - "Prefer constants with units in names: *_S, *_MS, *_BYTES, *_MB, *_PCT"
    - "If a package exposes a public API, keep it small and optionally define __all__"
    - "If you write Python docstrings, use Google style"
