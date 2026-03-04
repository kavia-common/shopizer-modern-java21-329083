# shopizer-modern-java21
Shopizer Java e-commerce software modernized to Java 21.

## Repository role in modernization work
This repository (`shopizer-modern-java21`) is the Java 21 target codebase for the modernization effort. When making architecture and design changes, this repository is the source of truth for the Java 21 implementation.

## Documentation and infrastructure location conventions
As the modernization progresses, documentation and infrastructure assets must be maintained in these locations.

Architecture and design documentation must be generated and maintained under `/docs`. This includes architecture overviews, design notes, ADRs, modernization plans, and any other engineering design material.

Infrastructure templates must be generated and maintained under `/infra`. This includes deployment templates, containerization artifacts, and other infrastructure-as-code templates used to run and deploy the modernized system.

If you add new documentation or infrastructure assets, place them in the appropriate directory above rather than creating new top-level documentation folders elsewhere.
