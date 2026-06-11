#!/usr/bin/env python3
"""
propagate-lessons-cross-project.py — cross-project lesson propagation suggestions.

Origin:  pkt C3 (2026-05-13).
Adresuje audyt: lessons z project A z category X często mogą dotyczyć project B.
Bez propagation — lessons "umierają" w swoim projekcie, brak cross-pollination.

Workflow:
  1. Read knowledge-base/lessons.jsonl (validate przeciw lessons-schema.json)
  2. Per lesson HIGH/MED: identify source_project + category + tags
  3. Per active project B (not source): grep library tied to B dla keyword matches
  4. Score relevance per (lesson, target_project) pair
  5. Output: knowledge-base/cross-propagation-suggestions-<date>.md z propozycjami

Usage:
  python3 library/scripts/propagate-lessons-cross-project.py [--since=-30d] [--target=<project>]
  python3 library/scripts/propagate-lessons-cross-project.py --dry-run  # console output

Args:
  --since=<date|-Nd>      Filter lessons by date (default: all)
  --target=<project>      Only generate suggestions for this target project
  --min-score=<float>     Threshold (default: 1.5)
  --dry-run               Console output, no file write
"""

import json
import sys
import os
import re
import glob
from datetime import datetime, timezone, timedelta
from pathlib import Path

LESSONS_FILE = "knowledge-base/lessons.jsonl"
LIBRARY_INDEX = "library/library-index.json"
OUTPUT_DIR = "knowledge-base/"

ACTIVE_PROJECTS = [
    "agent-factory", "external-crm", "external-crm",
    "seo-construction", "example-pack", "klienci"
]


def parse_since(arg):
    """Parse --since=-30d or absolute date."""
    if not arg:
        return None
    if arg.startswith('-') and arg.endswith('d'):
        days = int(arg[1:-1])
        return datetime.now(timezone.utc) - timedelta(days=days)
    try:
        return datetime.fromisoformat(arg.replace('Z', '+00:00'))
    except:
        return None


def load_lessons(since):
    """Load lessons.jsonl, filter by since date."""
    lessons = []
    for line in open(LESSONS_FILE):
        line = line.strip
        if not line:
            continue
        try:
            l = json.loads(line)
            if since:
                ts = l.get('ts', '')
                if 'T' in ts:
                    try:
                        dt = datetime.fromisoformat(ts.replace('Z', '+00:00'))
                        if dt < since:
                            continue
                    except:
                        pass
            lessons.append(l)
        except json.JSONDecodeError:
            pass
    return lessons


def compute_relevance(lesson, target_project):
    """
    Score how relevant a lesson is for a target project.
    Heuristics:
      - lesson category match w typowych categories projektu (1.0)
      - lesson tags intersection z project tags (0.5 per match)
      - lesson keywords w target project library files (0.7)
      - lesson explicitly mentions target project (2.0)
    """
    score = 0.0
    signals = []

    src = lesson.get('project', '')
    if src == target_project:
        return 0.0, ["same project — skip"]  # nie propagujemy do siebie

    body = (lesson.get('title', '') + ' ' + lesson.get('lesson', '') +
            ' ' + lesson.get('context', '') + ' ' + lesson.get('action', '')).lower

    # Signal 1: target project explicitly mentioned w body
    if target_project.lower in body:
        score += 2.0
        signals.append(f"tier1: target '{target_project}' explicit mention")

    # Signal 2: category fit per project heuristic
    cat = lesson.get('category', '')
    project_categories = {
        "agent-factory": ["agent-design", "skill-design", "planning",
                          "operationalize", "test-infrastructure", "schema-design"],
        "external-crm": ["agent-design", "scope-management",
                              "tooling", "documentation", "defense-in-depth"],
        "external-crm": ["agent-design", "tooling", "defense-in-depth"],
        "seo-construction": ["content-generation", "skill-design", "scoring-rubric"],
        "example-pack": ["scoring-rubric", "content-generation", "anti-leakage",
                       "agent-design", "skill-design"],
        "klienci": ["scope-management", "agent-design"]
    }
    if cat in project_categories.get(target_project, []):
        score += 1.0
        signals.append(f"tier2: category '{cat}' fits {target_project}")

    # Signal 3: tags intersection (z project-specific keywords)
    project_keywords = {
        "agent-factory": ["meta", "factory", "agent-design"],
        "external-crm": ["crm", "auth", "security"],
        "seo-construction": ["seo", "content", "polish", "rodo"],
        "example-pack": ["rekrutacja", "cv", "scoring", "anti-leakage", "preferences"],
        "klienci": ["client-management", "scope"]
    }
    tags = lesson.get('tags', [])
    target_kws = project_keywords.get(target_project, [])
    matches = set(tags) & set(target_kws)
    if matches:
        score += 0.5 * len(matches)
        signals.append(f"tier3: tags intersection {list(matches)}")

    return score, signals


def find_relevant_lessons(lessons, target_project, min_score=1.5):
    """Find lessons relevant for target project, ranked by score."""
    candidates = []
    for l in lessons:
        if l.get('severity') not in ['HIGH', 'MED', 'META']:
            continue
        if l.get('project') == target_project:
            continue  # skip own
        score, signals = compute_relevance(l, target_project)
        if score >= min_score:
            candidates.append({
                'lesson_id': l.get('id'),
                'source_project': l.get('project'),
                'title': l.get('title', '')[:80],
                'severity': l.get('severity'),
                'score': score,
                'signals': signals,
                'category': l.get('category'),
                'lesson_body': l.get('lesson', '')[:200],
                'action': l.get('action', '')[:200]
            })

    candidates.sort(key=lambda c: -c['score'])
    return candidates


def generate_report(by_project, since_str, min_score):
    """Generate markdown report."""
    today = datetime.now(timezone.utc).strftime('%Y-%m-%d')
    md = []
    md.append(f"# Cross-project lesson propagation suggestions — {today}")
    md.append("")
    md.append(f"**Generated:** {today}T{datetime.now(timezone.utc).strftime('%H:%M:%S')}Z")
    md.append(f"**Since:** {since_str or 'all-time'}")
    md.append(f"**Min relevance score:** {min_score}")
    md.append("")
    md.append("## Cel")
    md.append("")
    md.append("Identyfikuj lessons z project A które mogą być cenne dla project B "
              "(cross-pollination). Wzorzec  C3.")
    md.append("")
    md.append("**HITL:** każda propozycja wymaga operator review przed implementation w target project.")
    md.append("")

    total_suggestions = sum(len(v) for v in by_project.values)
    md.append(f"## Summary: {total_suggestions} suggestions across {len(by_project)} projects")
    md.append("")

    for target, candidates in by_project.items:
        if not candidates:
            continue
        md.append(f"### → Target project: `{target}` ({len(candidates)} suggestions)")
        md.append("")
        for c in candidates[:10]:  # top 10 per project
            md.append(f"#### Lesson #{c['lesson_id']} ({c['source_project']} → {target})")
            md.append("")
            md.append(f"- **Title:** {c['title']}")
            md.append(f"- **Severity:** {c['severity']} · **Category:** {c['category']}")
            md.append(f"- **Relevance score:** {c['score']:.1f}")
            md.append(f"- **Signals:**")
            for s in c['signals']:
                md.append(f"  - {s}")
            md.append(f"- **Lesson body:** {c['lesson_body']}")
            if c['action']:
                md.append(f"- **Suggested action (source):** {c['action']}")
            md.append("")
            md.append(f"  **Propagation recommendation:** review czy ta lekcja "
                      f"dotyczy `{target}` — jeśli tak, spawn version-bumper lub patch directly.")
            md.append("")
        md.append("---")
        md.append("")

    md.append("## Decision workflow")
    md.append("")
    md.append("Per suggestion:")
    md.append("1. **Accept** → spawn `version-bumper --proposal=<this-suggestion>` lub patch directly")
    md.append("2. **Reject** → dopisz komentarz (informuje przyszłe propagation)")
    md.append("3. **Defer** → review w next cycle (>14d)")
    md.append("")
    md.append("---")
    md.append(f"**Generated by:** propagate-lessons-cross-project.py v1.0.0")
    md.append(f"**Plan:** knowledge-base/plans/2026-05-13--operationalize-learning-loop.md C3")

    return '\n'.join(md)


def main:
    args = {a.split('=')[0]: a.split('=')[1] if '=' in a else True for a in sys.argv[1:]}
    since_str = args.get('--since', '')
    target = args.get('--target', None)
    min_score = float(args.get('--min-score', '1.5'))
    dry_run = bool(args.get('--dry-run'))

    since = parse_since(since_str) if since_str else None

    lessons = load_lessons(since)
    print(f"Loaded {len(lessons)} lessons (since={since_str or 'all'})", file=sys.stderr)

    targets = [target] if target else ACTIVE_PROJECTS

    by_project = {}
    for t in targets:
        by_project[t] = find_relevant_lessons(lessons, t, min_score)
        print(f"  → {t}: {len(by_project[t])} suggestions (score ≥ {min_score})", file=sys.stderr)

    report = generate_report(by_project, since_str, min_score)

    if dry_run:
        print(report)
    else:
        today = datetime.now(timezone.utc).strftime('%Y-%m-%d')
        outfile = f"{OUTPUT_DIR}cross-propagation-suggestions-{today}.md"
        Path(outfile).write_text(report, encoding='utf-8')
        print(f"\n✅ Report written: {outfile}", file=sys.stderr)

        # Activity-log
        with open("knowledge-base/activity-log.jsonl", "a") as f:
            entry = {
                "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                "actor": "propagate-lessons-cross-project",
                "action": "proposal_created",
                "artifact": outfile,
                "status": "ok",
                "notes": f"{sum(len(v) for v in by_project.values)} suggestions"
            }
            f.write(json.dumps(entry) + "\n")


if __name__ == "__main__":
    main
