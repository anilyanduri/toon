# 🎋 Toon Token-Oriented Object Notation for Ruby

`toon` is a Ruby implementation of **TOON (Token-Oriented Object Notation)**
a compact, readable, indentation-based data format designed for humans *and* machines.

This gem provides:

- A **TOON encoder** (Ruby → TOON)
- A **TOON decoder** (TOON → Ruby)
- A **CLI** (`bin/toon`) for converting TOON ↔ JSON
- Optional **ActiveSupport integration** (`Object#to_toon`)
- Built-in `Hash#to_toon` / `Array#to_toon` plus lightweight `#to_json` helpers
- Full RSpec test suite

---

## ✨ Features

### ✔ Encode Ruby objects → TOON
```ruby
Toon.generate({ "name" => "Alice", "age" => 30 })
````

Produces:

```
name:Alice
age:30
```

### ✔ Decode TOON → Ruby

```ruby
Toon.parse("name:Alice\nage:30")
```

Returns:

```ruby
{ "name" => "Alice", "age" => 30 }
```

---

## 🧩 Arrays

### Nested arrays (encoder output)

```
colors:
  [3]:
    red
    green
    blue
```

### Flat arrays (user input)

```
colors[3]:
  red
  green
  blue
```

Both decode correctly.

---

## 📊 Tabular Arrays

### Nested tabular (encoder output)

```
users:
  [2]{id,name}:
    1,A
    2,B
```

→ numeric fields parsed (`id` becomes integer)

### Flat tabular (user input)

```
users[2]{id,name}:
  1,Alice
  2,Bob
```

→ fields remain **strings**

---

## ⚙️ ActiveSupport Integration

If ActiveSupport (and by extension Rails/Active Record) is installed—regardless of whether it loads before or after `toon`—every object gains `#to_toon`.

```ruby
require "toon"
require "active_support"

class Session < ApplicationRecord; end

Session.first.to_toon
# => "id:1\nuser_id:42\n..."
```

- Automatically hooks in as soon as ActiveSupport finishes loading (thanks to a TracePoint watcher)
- Falls back to `#as_json` when present, so Active Record / ActiveModel instances serialize their attributes instead of opaque object IDs

## 🧩 Core Extensions

`toon` now provides handy helpers even without ActiveSupport:

```ruby
require "toon"

{foo: "bar"}.to_toon
# => "foo:bar"

[1, 2, 3].to_toon
# => "[3]:\n  1\n  2\n  3\n"

{foo: "bar"}.to_json
# => "{\"foo\":\"bar\"}"
```

Both `Hash` and `Array` gain `#to_toon` and `#to_json` implementations so you can round-trip data between TOON and JSON with a single method call.

---

## 🚀 Installation

Gem coming soon. For now:

```bash
git clone <your-repo-url>
cd toon
bundle install
```

Use locally:

```ruby
require_relative "lib/toon"
```

---

## 🧰 CLI Usage

### Encode JSON → TOON

```bash
echo '{"name":"Alice","age":30}' | bin/toon --encode
```

### Decode TOON → JSON

```bash
echo "name:Alice\nage:30" | bin/toon --decode
```

### Read from STDIN automatically

```bash
bin/toon --encode < input.json
```

---

## 🧪 Running Tests

Ensure CLI is executable:

```bash
chmod +x bin/toon
```

Run all tests:

```bash
bundle exec rspec
```

Tests include:

* Encoder specs
* Decoder specs
* CLI specs
* ActiveSupport specs

---

## 📚 Supported TOON Grammar (Current)

### Key-value

```
key:value
```

### Nested objects

```
user:
  name:Alice
  age:30
```

### Primitive arrays

```
colors:
  [3]:
    red
    green
    blue
```

Flat form:

```
colors[3]:
  red
  green
  blue
```

### Tabular arrays

```
users:
  [2]{id,name}:
    1,A
    2,B
```

Flat form:

```
users[2]{id,name}:
  1,A
  2,B
```

---

## ⚠️ Error Handling

Malformed input (e.g., missing indentation):

```
Malformed TOON: array header '[3]:' must be under a key (e.g., 'colors:')
```

Decoder stops with a friendly `Toon::Error`.

---

## 🗺️ Roadmap

* Multiline values
* Quoted strings
* Mixed-type arrays
* Strict vs non-strict modes
* Streaming decoder
* Schema validation
* Ruby gem release

---

## ❤️ Contributing

PRs and issues welcome!

---

## 📝 License

MIT
