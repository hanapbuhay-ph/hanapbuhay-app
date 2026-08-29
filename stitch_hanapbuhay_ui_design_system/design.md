# Tarsi

## Mission
Create implementation-ready, token-driven UI guidance for Tarsi that is optimized for consistency, accessibility, and fast delivery across content site.

## Brand
- Product/brand: Tarsi
- URL: https://www.tarsi.cloud/
- Audience: readers and knowledge seekers
- Product surface: content site

## Style Foundations
- Visual style: clean, functional, implementation-oriented
- Main font style: `font.family.primary=Plus Jakarta Sans`, `font.family.stack=Plus Jakarta Sans, Plus Jakarta Sans Fallback`, `font.size.base=16px`, `font.weight.base=400`, `font.lineHeight.base=24px`
- Typography scale: `font.size.xs=10px`, `font.size.sm=12.48px`, `font.size.md=14px`, `font.size.lg=15.68px`, `font.size.xl=16px`, `font.size.2xl=16.13px`, `font.size.3xl=16.9px`, `font.size.4xl=18px`
- Color palette: `color.surface.base=#000000`, `color.text.secondary=#111827`, `color.text.tertiary=lab(65.9269 -0.832707 -8.17473)`, `color.text.inverse=#4b5563`, `color.surface.muted=#f2f2f2`, `color.surface.raised=#ffffff`, `color.surface.strong=lab(85.1236 -0.612259 -3.7138)`
- Spacing scale: `space.1=4px`, `space.2=8px`, `space.3=10px`, `space.4=12px`, `space.5=14px`, `space.6=16px`, `space.7=20px`, `space.8=24px`
- Radius/shadow/motion tokens: `radius.xs=12px`, `radius.sm=24px`, `radius.md=999px`, `radius.lg=26843500px` | `shadow.1=rgba(15, 23, 42, 0.12) 0px 10px 24px 0px` | `motion.duration.instant=150ms`, `motion.duration.fast=180ms`, `motion.duration.normal=300ms`, `motion.duration.slow=500ms`

## Accessibility
- Target: WCAG 2.2 AA
- Keyboard-first interactions required.
- Focus-visible rules required.
- Contrast constraints required.

## Writing Tone
Concise, confident, implementation-focused.

## Rules: Do
- Use semantic tokens, not raw hex values, in component guidance.
- Every component must define states for default, hover, focus-visible, active, disabled, loading, and error.
- Component behavior should specify responsive and edge-case handling.
- Interactive components must document keyboard, pointer, and touch behavior.
- Accessibility acceptance criteria must be testable in implementation.

## Rules: Don't
- Do not allow low-contrast text or hidden focus indicators.
- Do not introduce one-off spacing or typography exceptions.
- Do not use ambiguous labels or non-descriptive actions.
- Do not ship component guidance without explicit state rules.

## Guideline Authoring Workflow
1. Restate design intent in one sentence.
2. Define foundations and semantic tokens.
3. Define component anatomy, variants, interactions, and state behavior.
4. Add accessibility acceptance criteria with pass/fail checks.
5. Add anti-patterns, migration notes, and edge-case handling.
6. End with a QA checklist.

## Required Output Structure
- Context and goals.
- Design tokens and foundations.
- Component-level rules (anatomy, variants, states, responsive behavior).
- Accessibility requirements and testable acceptance criteria.
- Content and tone standards with examples.
- Anti-patterns and prohibited implementations.
- QA checklist.

## Component Rule Expectations
- Include keyboard, pointer, and touch behavior.
- Include spacing and typography token requirements.
- Include long-content, overflow, and empty-state handling.
- Include known page component density: links (15), cards (8), buttons (7).

- Extraction diagnostics: Audience and product surface inference confidence is low; verify generated brand context.

## Quality Gates
- Every non-negotiable rule must use "must".
- Every recommendation should use "should".
- Every accessibility rule must be testable in implementation.
- Teams should prefer system consistency over local visual exceptions.
