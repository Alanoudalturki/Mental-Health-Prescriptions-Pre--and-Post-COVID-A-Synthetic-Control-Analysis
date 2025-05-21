# Mental Health Prescriptions Pre- and Post-COVID: A Synthetic Control Analysis

## Overview

This project examines the impact of the COVID-19 pandemic on mental health prescription rates across U.S. states. Using the Synthetic Control Method (SCM), the analysis evaluates whether states that implemented early telehealth mandates experienced different prescribing trends compared to states without such interventions.

By creating a synthetic version of a treated state from a weighted combination of control states, this project estimates the counterfactual prescribing trends that would have occurred in the absence of the policy or pandemic-driven expansion.

---

## Type of Analysis

**Causal Inference – Synthetic Control Method (SCM)**  
- Constructed synthetic control groups for comparison  
- Analyzed temporal trends in mental health prescriptions  
- Estimated policy-related changes attributable to COVID-19 and telehealth mandates

---

## Research Question

Did the COVID-19 pandemic, combined with early state-level telehealth expansions, lead to significant changes in mental health prescription rates?

---

## Data Description

- **Source**: CMS Medicare Part D Prescriber Public Use File  
- **Period**: 2017–2022  
- **Unit of Analysis**: U.S. states (annual prescription data)  
- **Outcome Variable**: Mental health prescriptions per 1,000 beneficiaries  
- **Treated Unit**: State with early telehealth expansion in 2020  
- **Control Units**: States without similar interventions

---

## Methodology

1. Filtered states with complete time series data  
2. Defined the intervention period (March 2020, COVID onset)  
3. Used `Synth` package in R to construct synthetic control  
4. Compared actual vs. synthetic outcomes  
5. Visualized trends and gaps pre- and post-intervention

---

## Key Findings

- The treated state showed an increase in mental health prescriptions during the pandemic  
- The synthetic control suggested that, in the absence of the intervention, this increase would have been less pronounced  
- Findings suggest telehealth expansion may have contributed to increased access or demand for mental health services

---

## Tools & Technologies

- R (`Synth` package)  
- Data wrangling and visualization  
- Medicare Part D public use data

---

## Skills Demonstrated

- Synthetic control analysis  
- Causal inference using observational data  
- Policy evaluation  
- Health services research and trend analysis

---

## Author

**Alanoud Alturki**  
Health Data Analyst | Health Informatics Specialist | Pharmacist  
MS in Health Informatics · MS in Health Data Analysis · PhD Student  
[LinkedIn](https://www.linkedin.com/in/alanoud-alturki-5601b2b5)

---

## License

This project is for academic and research purposes only. All data used is publicly available and de-identified. Please cite this work appropriately if used in research or publication.
