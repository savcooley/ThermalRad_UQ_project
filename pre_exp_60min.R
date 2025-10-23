##########       Variable key & notes       ##########     
'''
Pre-Experiment 1 for temperature stabilization test. Test Q: When does the chamber temperature kick in to influence rad readings? 
Goal: assess how much time it takes for the chamber temperature to soak into the radiometer casing.

Input file (bath temperature, chamber temperature, x, measurment time in min) : 
0,-10,x,60
0,-5,x,60
0,0,x,60
0,5,x,60
0,10,x,60
0,15,x,60
0,20,x,60
0,25,x,60
0,30,x,60
0,35,x,60
0,40,x,60
0,45,x,60
0,50,x,60
20,-10,x,60
20,-5,x,60
20,0,x,60
20,5,x,60
20,10,x,60
20,15,x,60
20,20,x,60
20,25,x,60
20,30,x,60
20,35,x,60
20,40,x,60
20,45,x,60
20,50,x,60
40,-10,x,60
40,-5,x,60
40,0,x,60
40,5,x,60
40,10,x,60
40,15,x,60
40,20,x,60
40,25,x,60
40,30,x,60
40,35,x,60
40,40,x,60
40,45,x,60
40,50,x,60
15,20,x,5

Output file "_rad518_val_run3_60min.csv"
 [v0] The counts read by the IR sensor pointed at the "scene"
 [v1] The counts read by the IR sensor pointed at the internal blackbody
 [v2] The counts read by the internal blackbody platinum resistance thermometer
 [v3] The output of blackbody temperature of the scene in deg C multiplied by 100 (5th order poly conversion)
 [v4] The air temperature inside the housing of the radiometer [?? units of C?] (output from sensor between air and circuit board, not calibrated)
 [v5] The counts read by the thermistor inside the IR sensor (counts that come from detector - good representation of die temperature inside thermopile. Theoretically could use that for a good reading. Could back out scene temp from thermistor ) 
 [v6] The fault code (error state - want this to be at 0. If not 0 then something is stuck / mechanical problems eg. a drum fell out) 
 [v7] The current power level for the thermoelectric heater cooler chip in 0.1% of full power (if chamber is 4C, scene is -10C, then 1024 is full throttle cooling very high power. Housing temp warms as it cools. All latent heat )
Negative numbers mean that the internal blackbody is being cooled
 [v8] The radiometer ID number"
'''
##########       Install packages & plot full data       ##########     
library(ggplot2)
library(dplyr)

# Line 13 is the header. Skip first 12 lines. 
df <- read.csv("/Users/sscooley/Documents/TIR_UQ/Data/Experiment_1/pre_experiment_runs/_rad518_val_run3_60min.csv", skip = 12)
df$scene_tempC <- df$X_v3/100
df$delta_rad_chub <- df$scene_tempC - df$Chub

# Create time variable in minutes from start
df$time_min <- (df$Floating.Time - min(df$Floating.Time, na.rm = TRUE)) / 60

# Create single plot with all three temperature variables
ggplot(df[!is.na(df$Chub) & !is.na(df$scene_tempC) & !is.na(df$Chamber_T), ], 
       aes(x = time_min)) +
  geom_point(aes(y = Chub, color = "Chub Temperature"), size = 0.5, alpha = 0.5) +
  geom_point(aes(y = scene_tempC, color = "Scene Temperature"), size = 0.5, alpha = 0.5) +
  geom_line(aes(y = Chamber_T, color = "Chamber Temperature"), linewidth = 0.6, alpha = 0.8) +
  scale_color_manual(values = c("Chub Temperature" = "purple", 
                                "Scene Temperature" = "red",
                                "Chamber Temperature" = "blue")) +
  labs(title = "Temperature Comparison Over Time",
       subtitle = "Radiometer Temperature Stabilization Test - Chamber cycles through -10 to 50°C",
       x = "Time (minutes from start)",
       y = "Temperature (°C)",
       color = "") +
  theme_minimal() +
  theme(legend.position = "bottom",
        plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 10))
##########       Plot SOAK data       ##########     
# Line 13 is the header. Skip first 12 lines. 
df_soak <- read.csv("/Users/sscooley/Documents/TIR_UQ/Data/Experiment_1/pre_experiment_runs/_rad518_val_run3_60min_SOAK.csv", skip = 12)
df_soak$scene_tempC <- df_soak$X_v3/100
df_soak$delta_rad_chub <- df_soak$scene_tempC - df_soak$Chub

# Create time variable in minutes from start
df_soak$time_min <- (df_soak$Floating.Time - min(df_soak$Floating.Time, na.rm = TRUE)) / 60

# Create single plot with all three temperature variables
ggplot(df_soak[!is.na(df_soak$Chub) & !is.na(df_soak$scene_tempC) & !is.na(df_soak$Chamber_T), ], 
       aes(x = time_min)) +
  geom_point(aes(y = Chub, color = "Chub Temperature"), size = 0.5, alpha = 0.5) +
  geom_point(aes(y = scene_tempC, color = "Scene Temperature"), size = 0.5, alpha = 0.5) +
  geom_line(aes(y = Chamber_T, color = "Chamber Temperature"), linewidth = 0.6, alpha = 0.8) +
  scale_color_manual(values = c("Chub Temperature" = "purple", 
                                "Scene Temperature" = "red",
                                "Chamber Temperature" = "blue")) +
  labs(title = "Temperature Comparison Over Time - SOAK Data",
       subtitle = "Data recorded only when target temperatures reached",
       x = "Time (minutes from start)",
       y = "Temperature (°C)",
       color = "") +
  theme_minimal() +
  theme(legend.position = "bottom",
        plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 10))