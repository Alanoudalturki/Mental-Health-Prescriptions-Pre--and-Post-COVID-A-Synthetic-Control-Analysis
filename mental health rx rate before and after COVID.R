# Uncomment to install
install.packages(c("readr", "dplyr", "tidyr", "stringr", "data.table", "Synth", "ggplot2", 
                   "purrr"))

library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(data.table)
library(Synth)
library(ggplot2)
library(purrr)
library(scales)


# STEP 1: Load and process Medicare Part D datasets (2015–2022)
file_paths <- c(
  "/Users/alanoudalturki/Downloads/Medicare Part D Prescribers - by Geography and Drug/2022/MUP_DPR_RY24_P04_V10_DY22_Geo.csv",
  "/Users/alanoudalturki/Downloads/Medicare Part D Prescribers - by Geography and Drug/2021/MUP_DPR_RY23_P04_V10_DY21_Geo.csv",
  "/Users/alanoudalturki/Downloads/Medicare Part D Prescribers - by Geography and Drug/2020/MUP_DPR_RY22_P04_V10_DY20_Geo.csv",
  "/Users/alanoudalturki/Downloads/Medicare Part D Prescribers - by Geography and Drug/2019/MUP_DPR_RY21_P04_V10_DY19_Geo.csv",
  "/Users/alanoudalturki/Downloads/Medicare Part D Prescribers - by Geography and Drug/2018/MUP_DPR_RY21_P04_V10_DY18_Geo.csv",
  "/Users/alanoudalturki/Downloads/Medicare Part D Prescribers - by Geography and Drug/2017/MUP_DPR_RY21_P04_V10_DY17_Geo.csv",
  "/Users/alanoudalturki/Downloads/Medicare Part D Prescribers - by Geography and Drug/2016/MUP_DPR_RY21_P04_V10_DY16_Geo_0.csv",
  "/Users/alanoudalturki/Downloads/Medicare Part D Prescribers - by Geography and Drug/2015/MUP_DPR_RY21_P04_V10_DY15_Geo_0.csv"
)





mental_drugs <- c(
  "Aripiprazole", "Bupropion Hcl", "Citalopram Hbr", "Duloxetine Hcl",
  "Escitalopram Oxalate", "Fluoxetine Hcl", "Mirtazapine", "Paroxetine Hcl",
  "Sertraline Hcl", "Trazodone Hcl", "Venlafaxine Hcl", "Amitriptyline Hcl"
)

all_years <- list()
for (file in file_paths) {
  year <- str_extract(file, "DY\\d{2}") %>% str_replace("DY", "20") %>% as.numeric()
  df <- fread(file, showProgress = FALSE)
  colnames(df) <- toupper(colnames(df))
  if (!all(c("GNRC_NAME", "PRSCRBR_GEO_DESC", "TOT_CLMS") %in% colnames(df))) next
  
  df_filtered <- df %>%
    filter(GNRC_NAME %in% mental_drugs) %>%
    mutate(TOT_CLMS = as.numeric(TOT_CLMS)) %>%
    group_by(State = PRSCRBR_GEO_DESC) %>%
    summarise(Total_Claims = sum(TOT_CLMS, na.rm = TRUE)) %>%
    mutate(Year = year)
  
  all_years[[as.character(year)]] <- df_filtered
}

combined_df <- bind_rows(all_years)

# STEP 2: Reshape to wide → long
pivot_df <- combined_df %>%
  pivot_wider(names_from = State, values_from = Total_Claims)

df_long <- pivot_df %>%
  pivot_longer(-Year, names_to = "State", values_to = "Claims") %>%
  mutate(
    unit_num = as.numeric(factor(State)),
    time_id = as.numeric(Year)
  ) %>%
  arrange(State, Year) %>%
  as.data.frame()

# STEP 3: Run Synthetic Control
intervention_year <- 2020
treated_state <- "California"
treated_unit <- unique(df_long$unit_num[df_long$State == treated_state])

dataprep.out <- dataprep(
  foo = df_long,
  predictors = "Claims",
  dependent = "Claims",
  unit.variable = "unit_num",
  time.variable = "time_id",
  treatment.identifier = treated_unit,
  controls.identifier = unique(df_long$unit_num[df_long$State != treated_state]),
  time.predictors.prior = unique(df_long$time_id[df_long$Year < intervention_year]),
  time.optimize.ssr = unique(df_long$time_id[df_long$Year < intervention_year]),
  time.plot = unique(df_long$time_id)
)

synth.out <- synth(dataprep.out)
years <- dataprep.out$tag$time.plot
actual <- as.numeric(dataprep.out$Y1plot)
synthetic_series <- as.numeric(dataprep.out$Y0plot %*% synth.out$solution.w)
gap <- actual - synthetic_series

# STEP 4: Plot Synthetic Control vs Actual
df_plot <- data.frame(
  Year = years,
  Actual = as.numeric(actual),
  Synthetic = as.numeric(synthetic_series),
  Gap = as.numeric(gap)
)

ggplot(df_plot, aes(x = Year)) +
  geom_line(aes(y = Actual, color = "Actual"), linewidth = 1.4) +
  geom_line(aes(y = Synthetic, color = "Synthetic"), linewidth = 1.4, linetype = "dashed") +
  geom_vline(xintercept = intervention_year, linetype = "dotted", color = "gray40", linewidth = 1) +
  scale_color_manual(values = c("Actual" = "firebrick", "Synthetic" = "steelblue")) +
  scale_y_continuous(labels = comma) +
  labs(
    title = paste("Mental Health Drug Claims: Synthetic Control for", treated_state),
    subtitle = paste("Intervention Year:", intervention_year),
    x = "Year", y = "Claims",
    color = "Series"
  ) +
  theme_minimal(base_family = "Helvetica", base_size = 15) +
  theme(legend.position = "top", plot.title = element_text(face = "bold"))

# STEP 5: Placebo States
placebo_results <- list()
for (state in unique(df_long$State[df_long$State != treated_state])) {
  unit <- unique(df_long$unit_num[df_long$State == state])
  tryCatch({
    dp <- dataprep(
      foo = df_long,
      predictors = "Claims",
      dependent = "Claims",
      unit.variable = "unit_num",
      time.variable = "time_id",
      treatment.identifier = unit,
      controls.identifier = unique(df_long$unit_num[df_long$State != state]),
      time.predictors.prior = unique(df_long$time_id[df_long$Year < intervention_year]),
      time.optimize.ssr = unique(df_long$time_id[df_long$Year < intervention_year]),
      time.plot = unique(df_long$time_id)
    )
    synth_res <- synth(dp)
    synthetic_placebo <- dp$Y0plot %*% synth_res$solution.w
    gap <- as.numeric(dp$Y1plot - synthetic_placebo)
    placebo_results[[state]] <- gap
  }, error = function(e) NULL)
}


# STEP 6: Plot Gaps for California vs Placebo States
plot_data <- data.frame(Year = years)

# Add California
plot_data$California <- df_plot$Gap

# Add other placebo states
for (state in names(placebo_results)) {
  plot_data[[state]] <- placebo_results[[state]]
}

# Reshape to long
plot_data_long <- pivot_longer(plot_data, -Year, names_to = "State", values_to = "Gap")

# Plot with all state gaps
ggplot(plot_data_long, aes(x = Year, y = Gap, group = State)) +
  geom_line(alpha = 0.3, color = "gray60") +  # Placebo states
  geom_line(data = filter(plot_data_long, State == treated_state),
            aes(y = Gap), color = "firebrick", linewidth = 1.5) +  # California
  geom_vline(xintercept = intervention_year, linetype = "dotted", color = "black") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", linewidth = 0.8) +
  annotate("text", x = intervention_year + 0.3, 
           y = max(df_plot$Gap, na.rm = TRUE), hjust = 0,
           label = paste("Intervention:", intervention_year), size = 3.5) +
  labs(
    title = "Placebo Test: Gap Between Actual and Synthetic",
    subtitle = paste(treated_state, "vs Control States – Intervention Year:", intervention_year),
    x = "Year",
    y = "Gap in Claims (Actual - Synthetic)"
  ) +
  theme_minimal(base_family = "Helvetica", base_size = 14) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "none")





# STEP 6: Plot Gaps for California vs Placebo States (Cleaned Up)
library(ggplot2)
library(dplyr)
library(tidyr)

plot_data <- data.frame(Year = years, California = df_plot$Gap)

# Add placebo gaps
for (state in names(placebo_results)) {
  plot_data[[state]] <- placebo_results[[state]]
}

plot_data_long <- pivot_longer(plot_data, -Year, names_to = "State", values_to = "Gap")

# Reorder so California is plotted last and on top
plot_data_long$State <- factor(plot_data_long$State, levels = c(setdiff(names(placebo_results), "California"), "California"))

# Plot
ggplot(plot_data_long, aes(x = Year, y = Gap, group = State)) +
  geom_line(data = filter(plot_data_long, State != "California"),
            color = "gray80", size = 0.6, alpha = 0.6) +
  geom_line(data = filter(plot_data_long, State == "California"),
            color = "firebrick", size = 1.4) +
  geom_vline(xintercept = intervention_year, linetype = "dotted", color = "black") +
  labs(
    title = "Policy Impact on Mental Health Drug Claims",
    subtitle = paste("California vs Synthetic Control – Intervention Year:", intervention_year),
    y = "Gap in Claims (Actual - Synthetic)",
    x = "Year"
  ) +
  theme_minimal(base_family = "Helvetica", base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "none"
  )




