# Post-LOE Biosimilar ROI Optimization

## Business Context
Following loss of exclusivity (LOE), originator pharmaceutical brands face rapid revenue erosion as biosimilars enter the market at discounted price points. Broad promotional coverage becomes economically unsustainable, requiring targeted engagement strategies to retain revenue.

## Objective
Design a scenario-based ROI optimization framework to quantify biosimilar-driven revenue at risk post-LOE and support HCP-level targeting decisions under constrained commercial budgets.

## Data Overview
- CMS DE-SynPUF claims data (Carrier, PDE, Beneficiary)
- Colorectal cancer patient cohort identified via diagnosis codes
- Prescription events attributed to HCPs using patient-level temporal proximity due to lack of prescriber identifiers in PDE data

## Analytical Approach
- Attributed prescription events to HCPs using ±30–60 day patient-level temporal joins
- Engineered HCP-level features capturing patient volume, originator exposure, and biosimilar activity
- Developed a rank-based HCP potential score for prioritization
- Segmented HCPs into switch tiers (High / Mid / Low / Non-User)
- Implemented coverage-based targeting logic with minimum originator exposure thresholds

## ROI Scenario Model
**Inputs**
- Coverage %
- Biosimilar share shift %
- Biosimilar discount %

**Outputs**
- Baseline revenue
- Post-LOE revenue
- Revenue at risk
- % revenue retained

## Dashboard
An interactive Power BI dashboard was built on top of this framework to simulate post-LOE scenarios and support executive decision-making and HCP-level explainability.

## Notes
This project prioritizes interpretability and decision support over predictive modeling. Outputs are intended for scenario comparison rather than point estimation.
