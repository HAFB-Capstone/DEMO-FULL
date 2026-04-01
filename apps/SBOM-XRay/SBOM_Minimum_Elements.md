# SBOM minimum elements (lab checklist)

This is a **short, offline** checklist aligned with NTIA / CISA-style “minimum elements” thinking for SBOMs used in security and acquisition workflows. It is **not** a legal substitute for organizational policy.

Use it to score **both** your internally generated CycloneDX SBOM and the vendor SPDX SBOM.

---

## 1. Baseline metadata

| # | Question | Flight Path (internal CDX) | Vendor SPDX |
|---|----------|----------------------------|-------------|
| 1 | Is there a **clear creation time** or build/SBOM timestamp you can point to? | | |
| 2 | Is **who produced the SBOM** identifiable (tool name/version, organization, or author)? | | |
| 3 | Is **supplier or originator** of the *software product* stated (or explicitly marked unknown)? | | |

---

## 2. Components / packages

For **at least three** non-trivial components you care about (e.g., web framework, HTTP client, crypto-related library):

| # | Question | Notes |
|---|----------|--------|
| 4 | **Name** and **version** present? | |
| 5 | **Unique identifier** present (PURL, CPE, or equivalent)? | |
| 6 | **Integrity evidence** where appropriate (e.g., hash on the package or image layer)? | |

---

## 3. Relationships / dependency graph

| # | Question | Flight Path (internal CDX) | Vendor SPDX |
|---|----------|----------------------------|-------------|
| 7 | Can you see **depends-on** (or SPDX equivalent) edges for *some* components? | | |
| 8 | Can you trace **at least one transitive** dependency using those edges? | | |

---

## 4. Known unknowns vs missing data

| # | Question | Your notes |
|---|----------|------------|
| 9 | Find at least one place where the document uses an **explicit unknown marker** (e.g., SPDX `NOASSERTION`). What does that mean for risk? | |
| 10 | Find one field that is **absent with no explanation**. How is that different from `NOASSERTION`? | |

---

## 5. Distribution and usefulness (practical)

| # | Question |
|---|----------|
| 11 | Could an analyst use this SBOM **during an incident** to narrow what is in the deployable unit? Why or why not? |
| 12 | What **one** improvement would you demand from the vendor before you’d call this “operationally adequate”? |

---

### Facilitator note

Students should leave the lab able to separate **(a)** rich internal SBOMs from **(b)** thin vendor claims, and to argue using **evidence** from the JSON—not gut feel.
