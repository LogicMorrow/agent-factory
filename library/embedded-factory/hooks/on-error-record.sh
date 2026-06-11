#!/usr/bin/env bash
# library/hooks/on-error-record.sh
#
# UserPromptSubmit hook — detekcja patternów wskazujących na błąd
# w prompcie użytkownika. Soft-reminder dla Claude'a żeby rozważył
# wywołanie agenta `mistake-recorder` (E3  fabryki).
#
# Origin:
#   Nowy artefakt fabryki 2026-05-07 . Hook produkuje delikatny
#   sygnał — Claude widzi w stderr że user mówi o błędzie, może (ale nie
#   musi) wywołać mistake-recorder żeby zapisać do
#   .claude/memory/errors-{agent-name}.md. Wzorzec error-memory-framework.
#
# Mechanizm:
#   Czyta JSON ze stdin (UserPromptSubmit format), wyciąga `prompt`.
#   Jeśli match na regex error-keywords → printf do stderr soft-reminder.
#   Exit 0 zawsze (informational, nie blokuje).
#
# Instalacja:
#   1. Skopiuj plik do `<projekt>/.claude/hooks/on-error-record.sh`
#   2. `chmod +x .claude/hooks/on-error-record.sh`
#   3. W `.claude/settings.json` dopisz:
#        "UserPromptSubmit": [{
#          "matcher": "*",
#          "hooks": [{ "type": "command",
#                      "command": ".claude/hooks/on-error-record.sh" }]
#        }]
#
# Exit codes:
#   0 zawsze (informational)
#
# Towarzyszące artefakty ( fabryki):
#   library/skills/universal/error-memory-framework/SKILL.md
#   library/skills/universal/cross-agent-learning/SKILL.md
#   library/agents/universal/mistake-recorder.md

set -euo pipefail

INPUT="$(cat 2>/dev/null || echo '{}')"
PROMPT="$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")"

# Brak prompt → exit cicho
[ -z "$PROMPT" ] && exit 0

# Regex error-keywords (case-insensitive). Match jeśli prompt zawiera
# jeden z patternów wskazujących na rzeczywisty błąd / problem
# (nie samo słowo "error" w technicznym znaczeniu jak nazwa zmiennej).
ERROR_PATTERNS='(błąd|błędu|błędy|błędem|error|errors|errored|zepsuł|zepsuł[oa]|zepsute|zepsuty|nie działa|niedziała|broken|broke|failed|fail|fails|crash|crashed|crashing|exception|stacktrace|traceback|nie wstaje|nie startuje|przestał|przestało|zwraca błąd|nie odpowiada|timeout|timed out)'

# Negatywne wykluczenia — uniknij false-positive na technicznych terminach
# (np. "stderr message" nie znaczy że user zgłasza error).
NEG_PATTERNS='(error_message|error\.log|error\.json|error_handler|error_class|error code|errno|stderr|stdout)'

# Sprawdź czy prompt matchuje ERROR_PATTERNS i NIE jest false-positive
if echo "$PROMPT" | grep -qiE -- "$ERROR_PATTERNS"; then
  # Sprawdź negatywne — jeśli prompt zawiera neg pattern Z PORÓWNYWALNĄ lub
  # większą liczbą hitów niż error pattern, prawdopodobnie technical context.
  if echo "$PROMPT" | grep -qiE -- "$NEG_PATTERNS"; then
    ERROR_COUNT=$(echo "$PROMPT" | grep -oiE -- "$ERROR_PATTERNS" 2>/dev/null | wc -l)
    NEG_COUNT=$(echo "$PROMPT" | grep -oiE -- "$NEG_PATTERNS" 2>/dev/null | wc -l)
    if [ "$NEG_COUNT" -ge "$ERROR_COUNT" ]; then
      exit 0
    fi
  fi

  cat >&2 <<MSG
ℹ️  Reminder (on-error-record.sh):

Twój prompt wspomina o błędzie / problemie / awarii. Jeśli to coś co może
się powtórzyć lub uderzyć w innego agenta w przyszłości, rozważ:

  1. Po rozwiązaniu problemu wywołaj agenta \`mistake-recorder\` (Task tool, haiku)
     z JSON: {agent_name, error_summary, error_cause, prevention_hint, severity}
     → zapis do \`.claude/memory/errors-{agent_name}.md\`
     → severity=HIGH automatycznie promuje do \`lessons.jsonl\`

  2. Wzorzec error-memory-framework: każdy agent ma swoją pamięć błędów
     (\`library/skills/universal/error-memory-framework/SKILL.md\`).

  3. Cross-agent learning (\`library/skills/universal/cross-agent-learning/\`)
     — następne sesje agentów wczytają ten log przed pracą (krok 0).

Hook source: .claude/hooks/on-error-record.sh
Skill: .claude/skills/error-memory-framework/SKILL.md
MSG
fi

exit 0
