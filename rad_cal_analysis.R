#!/usr/bin/env Rscript
# ==============================================================================
# Analysis of SI-121 Radiometer Calibration Data
# Produces Figure 5: Relationship between water bath temperature variability 
# (Chub SD) and temperature across multiple calibration runs
# ==============================================================================

# Load required libraries
library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(patchwork)  # For combining plots

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# [USER INPUT REQUIRED] Set the root directory containing calibration folders
root_dir <- "/path/to/calibration/data"  # MODIFY THIS PATH

# [ASSUMPTION] Column positions in "results" tab:
# Column G = Chubb Mean (temperature in °C)
# Column H = Chub SD (standard deviation in °C)
# [CLARIFICATION NEEDED] Verify that these column positions are consistent 
# across all calibration files

# [ASSUMPTION] Temperature bin width
bin_width <- 1.0  # 1-K bins as specified in figure caption

# [ASSUMPTION] Sheet name containing results
results_sheet <- "results"

# [CLARIFICATION NEEDED] Which row does data start in the results tab?
# Assuming data starts at row 18 based on the example spreadsheet
data_start_row <- 18

# ==============================================================================
# FUNCTION DEFINITIONS
# ==============================================================================

#' Extract date from folder name
#' @param folder_path Full path to folder
#' @return Date in YYYY-MM-DD format or NA if pattern doesn't match
extract_date_from_folder <- function(folder_path) {
  folder_name <- basename(folder_path)
  # Extract yyyymmdd from folder name (first 8 characters)
  date_string <- substr(folder_name, 1, 8)
  
  # Check if it matches yyyymmdd pattern
  if (grepl("^[0-9]{8}$", date_string)) {
    # Convert to date format
    date <- as.Date(date_string, format = "%Y%m%d")
    return(date)
  } else {
    return(NA)
  }
}

#' Determine calibration type (HRH or HRL) from filename
#' @param filename Name of the calibration file
#' @return "HRH", "HRL", or NA
get_cal_type <- function(filename) {
  if (grepl("HRH", filename, ignore.case = TRUE)) {
    return("HRH")
  } else if (grepl("HRL", filename, ignore.case = TRUE)) {
    return("HRL")
  } else {
    return(NA)
  }
}

#' Read calibration data from Excel file
#' @param file_path Full path to .xlsm file
#' @param folder_path Path to containing folder (for date extraction)
#' @return Data frame with calibration measurements
read_cal_file <- function(file_path, folder_path) {
  tryCatch({
    # Read the results sheet
    # [CLARIFICATION NEEDED] Verify skip parameter matches actual data start row
    cal_data <- read_excel(file_path, 
                           sheet = results_sheet, 
                           skip = data_start_row - 1)
    
    # [ASSUMPTION] Columns G and H contain Chubb Mean and Chub SD
    # Excel columns: A=1, B=2, C=3, D=4, E=5, F=6, G=7, H=8
    # Extract relevant columns (assuming they are 7th and 8th columns)
    
    # Check if we have enough columns
    if (ncol(cal_data) < 8) {
      warning(paste("File", basename(file_path), 
                    "has fewer than 8 columns. Skipping."))
      return(NULL)
    }
    
    # Extract columns by position
    # [CLARIFICATION NEEDED] Verify these column positions
    result_df <- data.frame(
      chubb_mean = as.numeric(cal_data[[7]]),  # Column G
      chub_sd = as.numeric(cal_data[[8]]),     # Column H
      file_name = basename(file_path),
      file_path = file_path,
      stringsAsFactors = FALSE
    )
    
    # Extract date from folder path
    result_df$date <- extract_date_from_folder(folder_path)
    
    # Determine calibration type
    result_df$cal_type <- get_cal_type(basename(file_path))
    
    # Remove rows with NA values in key columns
    result_df <- result_df %>%
      filter(!is.na(chubb_mean) & !is.na(chub_sd) & !is.na(cal_type))
    
    return(result_df)
    
  }, error = function(e) {
    warning(paste("Error reading file", basename(file_path), ":", e$message))
    return(NULL)
  })
}

#' Recursively find all calibration Excel files
#' @param root_path Root directory to search
#' @return Data frame with all calibration data
compile_calibration_data <- function(root_path) {
  # Find all folders matching yyyymmdd_calval pattern
  all_folders <- list.dirs(root_path, recursive = TRUE, full.names = TRUE)
  
  # Filter for folders matching the pattern (yyyymmdd_calval)
  calval_folders <- all_folders[grepl("[0-9]{8}_calval", basename(all_folders))]
  
  cat(paste("Found", length(calval_folders), "calval folders\n"))
  
  # Find all .xlsm files in these folders
  all_data <- list()
  file_count <- 0
  
  for (folder in calval_folders) {
    # Find all .xlsm files that match calibration pattern
    excel_files <- list.files(folder, 
                              pattern = ".*cal.*\\.xlsm$", 
                              full.names = TRUE,
                              recursive = FALSE,
                              ignore.case = TRUE)
    
    if (length(excel_files) > 0) {
      cat(paste("Processing", length(excel_files), 
                "files from", basename(folder), "\n"))
      
      for (file in excel_files) {
        file_count <- file_count + 1
        data <- read_cal_file(file, folder)
        
        if (!is.null(data) && nrow(data) > 0) {
          all_data[[file_count]] <- data
        }
      }
    }
  }
  
  # Combine all data
  if (length(all_data) > 0) {
    combined_data <- bind_rows(all_data)
    cat(paste("\nSuccessfully compiled data from", 
              length(all_data), "files\n"))
    cat(paste("Total measurements:", nrow(combined_data), "\n"))
    cat(paste("Date range:", 
              min(combined_data$date, na.rm = TRUE), "to",
              max(combined_data$date, na.rm = TRUE), "\n"))
    return(combined_data)
  } else {
    stop("No calibration data found")
  }
}

#' Bin data by temperature and calculate statistics
#' @param data Data frame with chubb_mean and chub_sd
#' @param bin_width Width of temperature bins in K
#' @return Data frame with binned statistics
bin_temperature_data <- function(data, bin_width = 1.0) {
  data %>%
    mutate(temp_bin = floor(chubb_mean / bin_width) * bin_width) %>%
    group_by(temp_bin) %>%
    summarise(
      mean_chub_sd = mean(chub_sd, na.rm = TRUE),
      sd_chub_sd = sd(chub_sd, na.rm = TRUE),
      n = n(),
      .groups = 'drop'
    ) %>%
    mutate(temp_bin_center = temp_bin + bin_width / 2)
}

# ==============================================================================
# MAIN ANALYSIS
# ==============================================================================

cat("Starting calibration data compilation...\n")
cat(paste("Root directory:", root_dir, "\n\n"))

# Check if root directory exists
if (!dir.exists(root_dir)) {
  stop(paste("Root directory does not exist:", root_dir))
}

# Compile all calibration data
all_cal_data <- compile_calibration_data(root_dir)

# Separate HRH and HRL data
hrh_data <- all_cal_data %>% filter(cal_type == "HRH")
hrl_data <- all_cal_data %>% filter(cal_type == "HRL")

cat(paste("\nHRH measurements:", nrow(hrh_data), "\n"))
cat(paste("HRL measurements:", nrow(hrl_data), "\n"))

# Temperature range summary
cat(paste("\nHRH temperature range:", 
          round(min(hrh_data$chubb_mean, na.rm = TRUE), 1), "to",
          round(max(hrh_data$chubb_mean, na.rm = TRUE), 1), "°C\n"))
cat(paste("HRL temperature range:", 
          round(min(hrl_data$chubb_mean, na.rm = TRUE), 1), "to",
          round(max(hrl_data$chubb_mean, na.rm = TRUE), 1), "°C\n"))

# Bin the data
hrh_binned <- bin_temperature_data(hrh_data, bin_width)
hrl_binned <- bin_temperature_data(hrl_data, bin_width)

# ==============================================================================
# CREATE FIGURE 5
# ==============================================================================

# Set theme for all plots
theme_set(theme_bw(base_size = 11))

# Figure 5a: HRH calibrations
fig5a <- ggplot() +
  # Individual data points
  geom_point(data = hrh_data, 
             aes(x = chubb_mean, y = chub_sd * 1000),  # Convert to mK
             alpha = 0.3, size = 1, color = "gray50") +
  # Binned means with error bars (horizontal lines showing SD)
  geom_point(data = hrh_binned, 
             aes(x = temp_bin_center, y = mean_chub_sd * 1000),
             size = 2, color = "black") +
  geom_errorbar(data = hrh_binned, 
                aes(x = temp_bin_center, 
                    ymin = mean_chub_sd * 1000 - sd_chub_sd * 1000,
                    ymax = mean_chub_sd * 1000 + sd_chub_sd * 1000),
                width = 0.5, color = "black") +
  # Linear fit to binned data
  geom_smooth(data = hrh_binned, 
              aes(x = temp_bin_center, y = mean_chub_sd * 1000),
              method = "lm", se = FALSE, color = "red", linewidth = 0.8) +
  labs(x = "Water bath temperature (°C)",
       y = "Chub SD (mK)",
       title = "(a) HRH Calibrations") +
  theme(plot.title = element_text(hjust = 0))

# Figure 5b: HRL calibrations with gray shaded region
fig5b <- ggplot() +
  # Individual data points
  geom_point(data = hrl_data, 
             aes(x = chubb_mean, y = chub_sd * 1000),  # Convert to mK
             alpha = 0.3, size = 1, color = "gray50") +
  # Shaded region showing ±1 SD from binned means
  geom_ribbon(data = hrl_binned, 
              aes(x = temp_bin_center, 
                  ymin = mean_chub_sd * 1000 - sd_chub_sd * 1000,
                  ymax = mean_chub_sd * 1000 + sd_chub_sd * 1000),
              fill = "gray70", alpha = 0.5) +
  # Binned means
  geom_point(data = hrl_binned, 
             aes(x = temp_bin_center, y = mean_chub_sd * 1000),
             size = 2, color = "black") +
  # Linear fit to binned data
  geom_smooth(data = hrl_binned, 
              aes(x = temp_bin_center, y = mean_chub_sd * 1000),
              method = "lm", se = FALSE, color = "red", linewidth = 0.8) +
  labs(x = "Water bath temperature (°C)",
       y = "Chub SD (mK)",
       title = "(b) HRL Calibrations") +
  theme(plot.title = element_text(hjust = 0))

# Figure 5c: Number of data points per bin
# Combine HRH and HRL binned data
binned_combined <- bind_rows(
  hrh_binned %>% mutate(cal_type = "HRH"),
  hrl_binned %>% mutate(cal_type = "HRL")
)

fig5c <- ggplot(binned_combined, 
                aes(x = temp_bin_center, y = n, fill = cal_type)) +
  geom_col(position = "dodge", width = bin_width * 0.8) +
  scale_fill_manual(values = c("HRH" = "#E69F00", "HRL" = "#56B4E9"),
                    name = "Calibration Type") +
  labs(x = "Water bath temperature (°C)",
       y = "Number of measurements",
       title = "(c) Data Points per Temperature Bin") +
  theme(plot.title = element_text(hjust = 0),
        legend.position = "bottom")

# Combine all three panels
fig5_combined <- (fig5a / fig5b / fig5c) + 
  plot_layout(heights = c(1, 1, 1))

# Save figure
ggsave("Figure_5_calibration_analysis.pdf", 
       fig5_combined, 
       width = 7, height = 10, units = "in")

ggsave("Figure_5_calibration_analysis.png", 
       fig5_combined, 
       width = 7, height = 10, units = "in", dpi = 300)

cat("\nFigure 5 saved as:\n")
cat("  - Figure_5_calibration_analysis.pdf\n")
cat("  - Figure_5_calibration_analysis.png\n")

# ==============================================================================
# SAVE COMPILED DATA
# ==============================================================================

# Save the compiled dataset for future use
write.csv(all_cal_data, 
          "compiled_calibration_data.csv", 
          row.names = FALSE)

cat("\nCompiled data saved as: compiled_calibration_data.csv\n")

# Print summary statistics
cat("\n===== SUMMARY STATISTICS =====\n")
cat("\nHRH Calibrations:\n")
cat(paste("  Temperature range:", 
          round(min(hrh_data$chubb_mean, na.rm = TRUE), 1), "to",
          round(max(hrh_data$chubb_mean, na.rm = TRUE), 1), "°C\n"))
cat(paste("  Mean Chub SD:", 
          round(mean(hrh_data$chub_sd, na.rm = TRUE) * 1000, 3), "mK\n"))
cat(paste("  SD of Chub SD:", 
          round(sd(hrh_data$chub_sd, na.rm = TRUE) * 1000, 3), "mK\n"))

cat("\nHRL Calibrations:\n")
cat(paste("  Temperature range:", 
          round(min(hrl_data$chubb_mean, na.rm = TRUE), 1), "to",
          round(max(hrl_data$chubb_mean, na.rm = TRUE), 1), "°C\n"))
cat(paste("  Mean Chub SD:", 
          round(mean(hrl_data$chub_sd, na.rm = TRUE) * 1000, 3), "mK\n"))
cat(paste("  SD of Chub SD:", 
          round(sd(hrl_data$chub_sd, na.rm = TRUE) * 1000, 3), "mK\n"))

# Linear regression statistics for binned data
cat("\n===== LINEAR REGRESSION STATISTICS =====\n")
cat("\nHRH (binned data):\n")
hrh_lm <- lm(mean_chub_sd ~ temp_bin_center, data = hrh_binned)
print(summary(hrh_lm))

cat("\nHRL (binned data):\n")
hrl_lm <- lm(mean_chub_sd ~ temp_bin_center, data = hrl_binned)
print(summary(hrl_lm))

cat("\nAnalysis complete!\n")