# MVP Description

- The MVP of `hafb-range-control` is a central control repo that can deploy, validate, and score one training module in an air-gapped environment.
- The first proof-of-concept target is `SBOM-Training-Module` Module 1 running on the Linux analysis VM.
- Ansible is used in its simplest form to stage the offline bundle and run the existing installer and validator.
- A lightweight readiness-scoring script evaluates whether the module is installed and ready for students.
- The broader scoring dashboard objective is intentionally deferred until the Ansible deployment path is proven on one target.
- This proves the technical pattern for future capstone expansion without requiring the full multi-service range to be finished now.

