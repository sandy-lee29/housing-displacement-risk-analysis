# Measuring Displacement Risk using U.S. Census and Eviction Lab Data

This project analyzes housing displacement risk in New Mexico using U.S. Census (ACS 5-Year Estimates) and Eviction Lab data at the census tract level. By integrating and modeling key socio-economic indicators, we identify vulnerable populations and geographic areas most at risk of displacement.

## Overview

Rising housing costs and eviction pressures have made housing displacement an increasingly urgent policy issue. This project develops a **Displacement Risk Score (DRS)** that combines rent burden, income disparity, homeownership rates, and eviction rates to estimate risk at a granular level.

The project also analyzes DRS distribution across demographic groups such as renters, homeowners, racial/ethnic communities, seniors, and children, offering insights into social equity and housing stability.

## Data Sources

- **U.S. Census Bureau (ACS 5-Year Estimates)**  
  - Housing Tenure (renters, homeowners)
  - Racial/Ethnic Composition
  - Age Groups (seniors 65+, children under 18)
  - Rent Burden
  - Median Household Income

- **Eviction Lab Data**  
  - Average eviction filings at census tract level

## Methodology

1. **Spatial Record Linkage**
   - ACS and Eviction Lab datasets are merged at the census tract level using `GEOID`.

2. **Displacement Risk Score (DRS) Calculation**
   - Composite score based on:
     - Rent Burden (30%)
     - Income Disparity (30%)
     - Homeownership Rate (20%)
     - Eviction Rate (20%)
   - Lower incomes, higher rent burdens, lower homeownership, and higher eviction rates increase the DRS.

3. **Demographic Group Analysis**
   - Calculated group-specific DRS for:
     - Renters
     - Homeowners
     - Racial/Ethnic groups (White, Black, Asian, Hispanic)
     - Seniors (65+)
     - Children (<18)

4. **Visualization**
   - Choropleth map of DRS across New Mexico census tracts
   - Bar chart of average DRS by demographic group

## Key Findings

- Hispanic residents and renters show notably higher displacement risk.
- Seniors and children also face moderate risk due to limited income and mobility.
- Certain areas like Bernalillo County have particularly high displacement risks due to rapid housing cost increases and socioeconomic vulnerability.

## Policy Implications

- **Affordable Housing Initiatives**  
  Expanding affordable housing and rental assistance programs.

- **Targeted Financial Assistance**  
  Supporting homeowners and renters facing economic pressures.

- **Community Investment**  
  Addressing long-term risk through investments in vulnerable neighborhoods.

## Files

- `newmexico_displacement_risk.R`: Main analysis script (data processing, DRS calculation, visualization)
- `newmexico_monthly_2020_2021.csv`: Eviction data from Eviction Lab
- `Measuring Displacement Risk using U.S. Census and Eviction Lab Data.pdf`: Project report and findings

## Tools

- R (tidycensus, tidyverse, sf, ggplot2)


