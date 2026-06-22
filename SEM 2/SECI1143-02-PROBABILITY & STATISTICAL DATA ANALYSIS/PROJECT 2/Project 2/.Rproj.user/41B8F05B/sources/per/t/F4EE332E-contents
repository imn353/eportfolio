library(readxl)
library(tidyverse)
library(psych)

# Compare with boxplot
boxplot(data2$Cholesterol ~ data2$Obesity, main = "Cholesterol Level vs Obesity", xlab = "Obesity", ylab = "Cholesterol Level")

# Check the values, 1 = obese, 0 = not obese
describeBy(data2$Cholesterol, group = data2$Obesity)



var(data2$Cholesterol[data2$Obesity == "0"])
var(data2$Cholesterol[data2$Obesity == "1"])
#From this code, the variance is calculated and the values are not equal to each other

# u1 : mean cholesterol levels of patient with obesity
# u2 : mean cholesterol levels of patient without obesity
# Ho : u1 = u2
# H1 : u1 != u2

# Two sided test
# assume unequal variances
t.test(data2$Cholesterol ~ data2$Obesity, var.equal = FALSE)


