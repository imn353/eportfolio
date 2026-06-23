#   HISTOGRAM FOR EXERCISE SESSION
colour <- c("darkseagreen", "darkseagreen1", "darkseagreen2", "darkseagreen3", "darkseagreen4", "darkslategray")
output_h <- hist(responses$`How many minutes do you typically spend exercising per session`, col = colour, xlab = "Exercise Duration per Session (minutes)", ylim = c(0,25), main = "Frequency of Exercise Duration per Session")
output_h

#   BAR PLOT FOR EXERCISE DAYS PER WEEK
stripchart(responses$`On average, how many days per week do you engage in exercise?`, method = "stack", offset = .5, at = 0, pch = 19,
           col = "steelblue", main = "Dot Plot of Frequency of Exercises per Week", xlab = "Number of Exercises")

#   HISTOGRAM FOR AGE OF REPONDENTS
colour2 <- c("skyblue", "skyblue1", "skyblue2", "skyblue3", "skyblue4", "slateblue")
output_h1 <- hist(responses$`What is your age group ?`, col = colour2, xlab = "Age", ylab = "Frequency", ylim = c(0,50), main = "Histogram of Age of Respondents" )
output_h1

#   BOXPLOT OF SLEEPING DURATION
boxplot(responses$`How many hours of sleep do you typically get per night`, main = "Average Sleep Duration of Respondents", ylab = "Sleep Duration (Hours)", col = "orange", border = "brown")

#   FREQUENCY DISTRIBUTION OF WEIGHT OF RESPONDENTS

#determining data points
weight <- responses$`How many kilograms do you weight?`

#determine break points
break_points <-seq(40, 110, by = 10)

## transforming the data
data_transform = cut(weight, break_points,
                    right=FALSE)
# creating the frequency table
freq_table = table(data_transform)

#Printing frequency table
print("Frequency Table")
print(freq_table)

# calculating cumulative frequency
cumulative_freq = c(0, cumsum(freq_table))
print("Cumulative Frequency")
print(cumulative_freq)

# plotting the data
plot(break_points, cumulative_freq, xlab="Weight", ylab="Cummulative Frequency", main = "Frequency Distribution of Respondent's Weight")

# creating line graph
lines(break_points, cumulative_freq)

#   SCATTERPLOT BETWEEN EXERECISE DURATION PER WEEK (MINUTES) AND RESTING HEART RATE

bpm <- responses$`What is your resting heart rate? (beats per minute)`
exercise <-(responses$`On average, how many days per week do you engage in exercise?`)*(responses$`How many minutes do you typically spend exercising per session`)

plot(bpm, exercise, main = "Scatterplot of Exercise Duration per Week (minutes) vs Resting Heart Rate (BPM)", xlab = "Resting Heart Rate (BPM)", ylab = "Exercise Duration per Week (minutes)", col = "blue")

abline(lm(bpm~exercise,data=responses),col='red') 

#    SCATTERPLOT BETWEEN DURATION OF SEDENTARY BEHAVIOUR (HOURS) AND RESTING HEART RATE

sedentary <- responses$`How many hours of sedentary behavior (inactive) do you engage in per day on average?`

plot(bpm, sedentary, main = "Scatterplot Duration of Sedentary Behavior (hours) vs Resting Heart Rate (BPM)", xlab = "Resting Heart Rate (BPM)", ylab = "Duration of Sedentary Behavior (hours)", col = "red")
