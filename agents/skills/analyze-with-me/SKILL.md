---
name: analyze-with-me
description: My personal analysis methodology — trunk first, simple to deep, diagrams, examples and data visuals; manual invocation only via /analyze-with-me, never auto-trigger.
argument-hint: "<target> [question]"
disable-model-invocation: true
---

# Analyze with me

Manual analysis mode. `/analyze-with-me <target> [question]` — target required, question optional; infer a missing question and say what you inferred. Directions, not a pipeline: the target decides the shape.

## Trunk first

Find the trunk before anything else: for a running system, the main path from entry or trigger to result — its main call or communication chain; for a non-running target — code, a design, a bug — the main structure or causal chain. Don't open with a module list or incidental detail; open with the trunk for this question.

Explain its flow: direction, layers, boundaries, and where it crosses them. Modules are nodes; the trunk is the relations between them. Confirm it against the real thing — entry points, calls, config, design artifacts — not names.

## Simple to deep

Explain the whole trunk plainly first — preferably with an overview diagram — then unfold the trunk's details and draw them, as deep as the question needs. Diagram depth follows explanation depth; no preset number of levels or diagrams.

Diagrams are part of the explanation, not decoration. Let them carry structure and flow; use prose for what a diagram cannot show — why the flow goes this way, what the boundaries mean. Don't re-list a diagram's boxes in prose.

## Concrete example

Walk a real request, call, event or input along the trunk (usually one; don't pile up cases). The example serves the trunk.

## Make data visible

When data is central to the question, use a chart, table or other visual to answer it. The question the data must answer decides the form; not every analysis needs one.

## Work before alignment

Do the work before aligning: challenge your first conclusion before presenting it. When information is missing, state the inference and continue — don't replace analysis with confirmation questions. If the target cannot be located at all, say what you tried and what is missing.

## Example — method demo, not a fixed scenario

Skynet or microservices: the trunk is client → server → inter-service communication → inside a service, where its internal components communicate. Explain the whole path plainly with an overview diagram, then go deeper — here, inter-service first, then inside a service. That order is one instance of coarse-to-fine, not a fixed sequence. Walk one player login through it; if the question is why login is slow, show where the time goes. The shape generalizes: find the main path, explain it simply, then deepen it.
