# CLI

ClipShield ships with a CLI for scanning and redacting text.

## Commands

```bash
clipshield scan --text "..." | --file path | --stdin [--json]
clipshield redact --text "..." [--strategy mask|tokenize|remove] [--copy]
clipshield tokenize --text "..." [--copy]
clipshield config path|init|print
clipshield rules [--json]
clipshield watch [--interval 1.0]
```

## Examples

Scan from stdin:

```bash
echo "SSN 123-45-6789" | clipshield scan --stdin
```

Redact a file:

```bash
clipshield redact --file ./notes.txt --strategy mask
```

Tokenize and copy:

```bash
clipshield tokenize --text "4111 1111 1111 1111" --copy
```
