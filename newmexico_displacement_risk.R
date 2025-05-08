# Load required libraries
library(tidycensus)
library(tidyverse)

# 1. Retrieve ACS5 Data (Tract Level)
nm_census <- get_acs(
  geography = "tract",  # Set to Tract level
  variables = c(
    "renters" = "B25003_003",  # Renter-occupied units
    "homeowners" = "B25003_002",  # Owner-occupied units
    "white_pop" = "B03002_003",  # White alone
    "black_pop" = "B03002_004",  # Black alone
    "asian_pop" = "B03002_006",  # Asian alone
    "hispanic_pop" = "B03002_012",  # Hispanic or Latino
    "total_pop" = "B01003_001",  # Total population
    "seniors_1" = "B01001_020", "seniors_2" = "B01001_021", "seniors_3" = "B01001_022",
    "seniors_4" = "B01001_023", "seniors_5" = "B01001_024", "seniors_6" = "B01001_025",
    "seniors_7" = "B01001_044", "seniors_8" = "B01001_045", "seniors_9" = "B01001_046",
    "seniors_10" = "B01001_047", "seniors_11" = "B01001_048", "seniors_12" = "B01001_049",  # Seniors (65+)
    "children_1" = "B01001_003", "children_2" = "B01001_004", "children_3" = "B01001_005",
    "children_4" = "B01001_027", "children_5" = "B01001_028", "children_6" = "B01001_029",   # Children (<18)
    "rent_burden_30" = "B25070_007",  # 30-34.9% of income on rent
    "rent_burden_35_39" = "B25070_008",  # 35-39.9% of income on rent
    "rent_burden_40_49" = "B25070_009",  # 40-49.9% of income on rent
    "rent_burden_50plus" = "B25070_010",  # 50%+ of income on rent
    "median_income" = "B19013_001"  # Median Household Income
  ),
  state = "NM"
) %>%
  select(-NAME, -moe) %>%
  pivot_wider(names_from = variable, values_from = estimate)

# 2. Aggregate Seniors & Children Values
nm_census <- nm_census %>%
  mutate(
    seniors = rowSums(select(., starts_with("seniors_")), na.rm = TRUE),
    children = rowSums(select(., starts_with("children_")), na.rm = TRUE)
  ) %>%
  select(-starts_with("seniors_"), -starts_with("children_"))  # Remove temporary variables

# 3. Calculate Group Proportions
nm_census <- nm_census %>%
  mutate(
    renters_pct = renters / total_pop,
    homeowners_pct = homeowners / total_pop,
    white_pct = white_pop / total_pop,
    black_pct = black_pop / total_pop,
    asian_pct = asian_pop / total_pop,
    hispanic_pct = hispanic_pop / total_pop,
    seniors_pct = seniors / total_pop,
    children_pct = children / total_pop,
    rent_burden = (rent_burden_30 + rent_burden_35_39 + rent_burden_40_49 + rent_burden_50plus) / renters,  
    income_disparity = median_income / mean(median_income, na.rm = TRUE)  
  )

# 4. Add Eviction Data (Tract-Level)
evictions <- read_csv("newmexico_monthly_2020_2021.csv") %>%
  group_by(GEOID) %>%
  summarise(
    filings_avg = mean(filings_avg, na.rm = TRUE)  
  ) 

# 5. Calculate Overall Average Filings
overall_avg_filing <- mean(evictions$filings_avg, na.rm = TRUE)

# 6. Calculate Eviction Rate (Comparison with Overall Average)
evictions <- evictions %>%
  mutate(eviction_rate = filings_avg / overall_avg_filing)  

# 7. Merge Eviction Data with ACS Census Tract Data
nm_census <- nm_census %>%
  left_join(evictions, by = "GEOID")

# 8. Calculate Final Displacement Risk Score (DRS)
nm_census <- nm_census %>%
  mutate(
    DRS = (rent_burden * 0.3) + 
      ((1 - income_disparity) * 0.3) +  
      ((1 - (homeowners / (renters + homeowners))) * 0.2) +  
      (eviction_rate * 0.2)  
  )

nm_census

# 9. Save Final Results
write_csv(nm_census, "New_Mexico_Tract_Level_DRS.csv")

# 10. Calculate DRS for Each Group
nm_census <- nm_census %>%
  mutate(
    renters_drs = renters_pct * DRS,
    homeowners_drs = homeowners_pct * DRS,
    white_drs = white_pct * DRS,
    black_drs = black_pct * DRS,
    asian_drs = asian_pct * DRS,
    hispanic_drs = hispanic_pct * DRS,
    seniors_drs = seniors_pct * DRS,
    children_drs = children_pct * DRS
  )

nm_census

# 11. Save Results
write_csv(nm_census, "New_Mexico_Tract_Level_DRS2.csv")

# 12. Output Top 10 Census Tracts with Highest Displacement Risk
top_10_tracts <- nm_census %>%
  select(GEOID, DRS, renters_drs, homeowners_drs, white_drs, black_drs, 
         asian_drs, hispanic_drs, seniors_drs, children_drs) %>%
  arrange(desc(DRS)) %>%
  head(10)  

print(top_10_tracts)
write_csv(top_10_tracts, "New_Mexico_top_10_tract.csv")

# Load Required Libraries for Visualization
library(ggplot2)
library(tigris)
library(sf)
library(dplyr)

# 13. Load New Mexico Census Tract Map Data
tracts_nm <- tracts(state = "NM", cb = TRUE, year = 2022) %>%
  st_as_sf()  

# 14. Merge Census Data with Map
nm_map <- tracts_nm %>%
  left_join(nm_census, by = c("GEOID" = "GEOID"))  

# 15. Visualize DRS Choropleth Map
ggplot(nm_map) +
  geom_sf(aes(fill = DRS), color = "white", size = 0.1) +  
  scale_fill_viridis_c(option = "magma", name = "Displacement Risk Score", 
                       limits = c(0, 1),   
                       breaks = seq(0, 1, by = 0.2)) +  
  theme_minimal() +
  labs(
    title = "Displacement Risk Score (DRS) in New Mexico by Census Tract",
    caption = "Source: ACS 5-Year Data & Eviction Lab"
  )

# 16. Calculate Average DRS by Group
avg_drs <- nm_census %>%
  summarise(
    renters = mean(renters_drs, na.rm = TRUE),
    homeowners = mean(homeowners_drs, na.rm = TRUE),
    white = mean(white_drs, na.rm = TRUE),
    black = mean(black_drs, na.rm = TRUE),
    asian = mean(asian_drs, na.rm = TRUE),
    hispanic = mean(hispanic_drs, na.rm = TRUE),
    seniors = mean(seniors_drs, na.rm = TRUE),
    children = mean(children_drs, na.rm = TRUE)
  ) %>%
  pivot_longer(cols = everything(), names_to = "group", values_to = "DRS")

# 17. Visualize Average DRS by Group
ggplot(avg_drs, aes(x = reorder(group, DRS), y = DRS, fill = group)) +
  geom_bar(stat = "identity", show.legend = FALSE) +  
  geom_text(aes(label = round(DRS, 2)), hjust = -0.2, size = 5) +  
  scale_fill_viridis_d(option = "plasma") +  
  coord_flip() +  
  theme_minimal() +
  labs(
    title = "Average Displacement Risk Score (DRS) by Group in New Mexico",
    x = "Group",
    y = "Average DRS",
    caption = "Source: ACS 5-Year Data & Eviction Lab"
  )
