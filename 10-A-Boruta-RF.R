"""
Script to perform Feature selection using Boruta algorithm and predict COVID-19 new cases with Random Forest
Regression model, using Sample Entropy as a predictor. (Lead time of 2 months).

"""

library(lubridate)
library(dplyr)
library(Boruta)
library(randomForest)

path_sample_entropy <- "data/entropy/monthly/"
path_new_cases <- "data/cases/new_cases.csv"
rf_output_path <- "data/randomforest/"
countries <- c('Brazil', 'England', 'France', 'Germany', 'India', 'Japan', 'USA')

# 1. Set seed
set.seed(123)


# 2. Read all data (Entropy & Cases)

  # Cases
cases <- read.csv()
colnames(cases)[1] <- "Date"
cases$Date <- strptime(cases$Date, "%m/%d/%Y")
cases$Date <-  paste0(month(as.Date(cases$Date), label=TRUE)," ", year(as.Date(cases$Date)))

  # Loop to get Train & Test: Entropy & Cases
train_df <- data.frame()
test_df <- data.frame()

start_month <- 'Mar 2020'
end_month <- 'Jun 2021'
lead_months <- 2

for (country in countries){
  ap_path <- paste0(path_sample_entropy, 'fast_samp_entropy_monthly_', country, '.csv')
  country_df <- read.csv(ap_path)
  country_df$Country <- country
  
  # Filter months (Mar20 - Jun21) in Entropy DF
  start_idx <- which(country_df$Date == start_month) # Mar20
  end_idx <- which(country_df$Date == end_month) # Jun21
  country_df <- country_df[start_idx:end_idx, ]
  
  # Entropy: Train & Test
  country_df <- lag(country_df, lead_months) # Mar20-Apr21
  country_df <- country_df[complete.cases(country_df),]
  entropy_train <- head(country_df, -lead_months) # Mar20-Feb21
  entropy_test <- tail(country_df, lead_months) #  Mar21-Apr21

  # Cases: Filter; Train & Test
  country_cases <- cases[cases$country == country,]
  start_idx <- which(country_cases$Date == start_month)
  end_idx <- which(country_cases$Date == end_month)
  country_cases <- country_cases[start_idx:end_idx, ]

  country_cases <- lead(country_cases, lead_months) # May20-Jun21
  country_cases <- country_cases[complete.cases(country_cases),]
  cases_train <- head(country_cases, -lead_months) # May20-Apr21
  cases_test <- tail(country_cases, lead_months) #  May21-Jun21

  # Bind Entropy with Cases (Lead = 2 months)
  entropy_train <- cbind(entropy_train, cases=cases_train$cases)
  entropy_test <- cbind(entropy_test, cases=cases_test$cases)

  # Append to larger DF
  train_df <- rbind(train_df, entropy_train)
  test_df <- rbind(test_df, entropy_test)
}


# 3. Boruta on Train set
boruta.train <- Boruta(cases~.-Date, data=train_df, maxRuns=1000)
print(boruta.train)
plot(boruta.train, las=3, cex.axis=0.7, xlab= "",
     main = "Boruta: Important Dimensions\n(Sample Entropy)")
selected_features <- getSelectedAttributes(boruta.train, withTentative = F)


# 4. Train Random Forest Regression model with selected features
formula <- reformulate(termlabels = selected_features, response = 'cases')
rf <- randomForest(formula, data = train_df, ntree = 1000)

#     Train performance
train_preds <- predict(rf, train_df[, selected_features])
rsq <- (cor(train_preds, train_df$cases, method = "pearson"))^2


# 5. Test set predictions
test_preds <- predict(rf, test_df[, selected_features])

  # R squared
rsq <- (cor(test_preds, test_df$cases, method = "pearson"))^2
plot(test_preds, test_df$cases, xlab='Predicted Values', ylab='Actual Values',
     main='RF actual & predicted values')
abline(a=0,b=1) # y=x


# 6. Correlations between Actual & Predicted values
  
  # Get all preds from Model
train_preds <- predict(rf, train_df[, selected_features])
test_preds <- predict(rf, test_df[, selected_features])

train_preds_df <- data.frame()
train_preds_df <- train_df[,c('Date', 'Country', 'cases')]
train_preds_df$preds <- train_preds

test_preds_df <- data.frame()
test_preds_df <- test_df[,c('Date', 'Country', 'cases')]
test_preds_df$preds <- test_preds

all_preds <- rbind(train_preds_df, test_preds_df)
write.csv(all_preds, paste0(rf_output_path, 'RF_preds.csv'), row.names = FALSE)


  # Calculate Correlations
    # A. Correlation between preds & actual cases
all_corr_df <- data.frame()

for (country in countries){
  corr_df <- data.frame(Country = country)

  subdf <- all_preds[all_preds$Country==country,]
  pearson_cor <- cor.test(subdf$cases, subdf$preds, method = "pearson")
  spearman_cor <- cor.test(subdf$cases, subdf$preds, method = "spearman")

  corr_df$pearson_cor <- pearson_cor$estimate
  corr_df$pearson_p.value <- pearson_cor$p.value
  corr_df$spearman_cor <- spearman_cor$estimate
  corr_df$spearman_p.value <- spearman_cor$p.value

  all_corr_df <- rbind(all_corr_df, corr_df)  
}
write.csv(all_corr_df, paste0(rf_output_path, 'preds_correlations.csv'), row.names = FALSE)


    # B. Correlation between diff(preds) & diff(actual cases)

all_diff_corr_df <- data.frame()

for (country in countries){
  diff_corr_df <- data.frame(Country = country)
  
  subdf <- all_preds[all_preds$Country==country,]
  
  s1 <- diff(subdf$cases)
  s2 <- diff(subdf$preds)
  pearson_cor <- cor.test(s1, s2, method = "pearson")
  spearman_cor <- cor.test(s1, s2, method = "spearman")
  
  diff_corr_df$pearson_cor <- pearson_cor$estimate
  diff_corr_df$pearson_p.value <- pearson_cor$p.value
  diff_corr_df$spearman_cor <- spearman_cor$estimate
  diff_corr_df$spearman_p.value <- spearman_cor$p.value
  
  all_diff_corr_df <- rbind(all_diff_corr_df, diff_corr_df)
}
write.csv(all_diff_corr_df, paste0(rf_output_path, 'diff_preds_correlations.csv'), row.names = FALSE)



# 7. Case Prediction
  # INFERENCE for months for which case data not available (Jul21-Aug21)
  #   Note: Date col specifies Entropy month; Case month = Current + 2 months

infer_df <- data.frame() # Data for May21-Jun21

for (country in countries){
  ap_path <- paste0(path_sample_entropy, 'fast_samp_entropy_monthly_', country, '.csv')
  country_df <- read.csv(ap_path)
  country_df$Country <- country
  
  # Filter months (May21 - Jun21) in Entropy DF
  start_idx <- which(country_df$Date == 'May 2021')
  end_idx <- which(country_df$Date == 'Jun 2021')
  country_df <- country_df[start_idx:end_idx, ]
  
  # Append to larger DF
  infer_df <- rbind(infer_df, country_df)  
}

infer_df$preds <- predict(rf, infer_df[, selected_features])
infer_df <- infer_df[,c('Date', 'Country', 'preds')]
write.csv(infer_df, paste0(rf_output_path, 'RF_infer_preds.csv'), row.names = FALSE)