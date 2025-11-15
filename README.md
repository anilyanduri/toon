# toon

**TOON for Ruby** encoder/decoder with JSON-compatible API surface.

Features planned:
- `Toon.generate(obj)` / `Toon.parse(str)`
- `Toon.pretty_generate(obj)`
- `Toon.dump(obj, io)` and `Toon.load(io)`
- Streaming encode / decode
- `to_toon` / `from_toon` hooks for custom objects (like `to_json`)
- Strict and non-strict parsing modes
- CLI (`bin/toon`) for encode/decode
- RSpec test suite and benchmarks
