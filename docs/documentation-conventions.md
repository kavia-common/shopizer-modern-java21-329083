# Documentation Conventions (shopizer-modern-java21)

## Purpose and scope
This document defines where modernization documentation and infrastructure templates must live for the Java 21 target repository, `shopizer-modern-java21`. It exists to prevent documentation drift across multiple locations and to make future automation and discovery of docs and templates reliable.

## Source of truth for Java 21
The `shopizer-modern-java21` repository is the Java 21 target codebase for the modernization work. Any architecture or design documentation written during modernization should describe and reference the Java 21 target implementation.

## Required locations
Architecture and design documents must be generated and maintained under the `/docs` directory in this repository. This includes architecture overviews, design documents, ADRs, modernization plans, and other technical design material.

Infrastructure templates must be generated and maintained under the `/infra` directory in this repository. This includes containerization templates, deployment manifests, and other infrastructure-as-code or environment provisioning templates.

## What not to do
Do not place architecture or design documents under other top-level folders or in external documentation trees for the Java 21 target. Do not place infrastructure templates under `/docs` or other documentation locations.

## How to reference these conventions
New architecture and design documents under `/docs` should include a short note that this repository is the Java 21 target and that infrastructure templates are located under `/infra`, so that readers consistently understand where to find the corresponding deployment assets.
