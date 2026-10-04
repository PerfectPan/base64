# Project status

- Version 0.3.0 is the final release. Preserve the discontinued notice and
  official-library migration guidance in `README.md`. Further maintenance or
  releases require an explicit owner request.

# Repository workflow

- Develop directly on `main`; commit and push completed, verified changes there.
  A pull request is not required. Fetch first and preserve collaborators' work;
  use a normal push, never overwrite remote history.
- Use the configured Git commit signing. Verify each new commit locally, then
  confirm GitHub reports `Verified` after pushing. Stop the affected delivery
  step if signature verification fails.
- Append this trailer only to Codex-authored commit messages:

  ```text
  Generated with Codex

  Co-Authored-By: Codex <noreply@openai.com>
  ```

# Implementation and verification

- Keep the root package and existing public string API compatible. The API and
  decoding rules are documented in `README.md`; consult them when changing
  encoding, validation, or error handling.
- Use the current stable MoonBit syntax and `moon.mod` / `moon.pkg`. Keep the
  Base64 algorithm implemented in this repository; use the standard UTF-8 module
  for text conversion. Keep internal helpers private and add only externally
  needed exports.
- Put public behavior tests in `*_test.mbt` and call the package through
  `@base64`. Cover independent RFC/Unicode vectors, binary data, malformed input,
  and any changed edge cases.
- Run the full `README.md` development command sequence before committing codec,
  manifest, or test changes. All declared backends must pass without warnings;
  review and commit the `moon info` interface diff. Changes to documentation
  examples must be checked as runnable MoonBit tests.

# Releases

- Follow `README.md`'s local publishing procedure when preparing or publishing a
  release. Inspect `moon package --list` and the generated archive before upload.
  Keep local secrets, machine configuration, and generated outputs out of both
  Git and the release archive.
- Prepare and verify a release locally before uploading. Run `moon publish`
  when the user requests publication; report the registry result separately
  from the Git push. CI verifies changes and does not publish.
