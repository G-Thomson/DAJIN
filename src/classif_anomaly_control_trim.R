################################################################################
#! Install required packages
################################################################################

options(repos = "https://cloud.r-project.org/")
options(readr.show_progress = FALSE)
options(dplyr.summarise.inform = FALSE)
options(future.globals.maxSize = Inf)
options(warn = -1)

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(tidyverse, vroom)

################################################################################
#! I/O naming
################################################################################
#===========================================================
#? TEST Auguments
#===========================================================

# input_control_score <- ".DAJIN_temp/classif/barcode21_wt.csv"

#===========================================================
# ? Auguments
#===========================================================

args <- commandArgs(trailingOnly = TRUE)
input_control_score <- args[1]
threads <- as.integer(args[2])

#===========================================================
#? Input
#===========================================================

df_control_score <- vroom(input_control_score,
    col_names = c("id", "score", "allele"),
    col_types = cols(),
    num_threads = threads)

#===========================================================
#? Output
#===========================================================

output_score <- ".DAJIN_temp/classif/tmp_control_score.csv"

################################################################################
#! Extract mutations by Hotelling's T2 statistics
################################################################################

df_control_score <- df_control_score %>% mutate(score = scale(score))

normal_score <-
    df_control_score %>%
    summarize(score = score,
        mean = mean(score),
        var = mean((score - mean(score))^2)) %>%
    summarize(score = score, anomaly_score = (score - mean)^2 / var) %>%
    mutate(number = row_number(), threshold = qchisq(0.95, 1)) %>%
    filter(anomaly_score < threshold) %>%
    select(score)

write_csv(normal_score, output_score, col_names = FALSE)

# df_control_score[!rownames(df_control_score) %in% normal_numbers, ]

# pacman::p_load(moments)
# df_control_score$score %>% hist()
# df_control_score$score[normal_numbers] %>% hist()
# ks.test(df_control_score$score, y = "pnorm")
# ks.test(df_control_score$score[normal_numbers], y = "pnorm")
# tmp <- agostino.test(df_control_score$score)
# glimpse(tmp)
# tmp %>% flatten_dfc %>% pull(z)
# tmp[[1]][2]

# agostino.test(df_control_score$score[normal_numbers])

# df_control_score %>% ggplot(aes(sample = score)) + stat_qq() + stat_qq_line()
# df_control_score[normal_numbers, ] %>% ggplot(aes(sample = score)) + stat_qq() + stat_qq_line()

# shapiro.test(x=rnorm(1000))
# shapiro.test(x=runif(1000))

# agostino.test(x=rnorm(1000))
# agostino.test(x=runif(1000))
# agostino.test(x=rlnorm(1000))
# hist(rnorm(1000))
# hist(runif(1000))
# hist(rlnorm(1000))
# library(tidyverse)
# df <- read_csv("tmp", col_name = c("id","score","allele"), col_type = c())
# df <- df %>% mutate(score = if_else(score == 0, 0.00001, score))
# df <- df %>% mutate(log = log(score))
# df$score %>% summary

# df_trim <- df %>% filter(log > quantile(df$log, 0.025) & log < quantile(df$log, 0.995))
# ggplot(df_trim, aes(sample = log)) + stat_qq() + stat_qq_line()
# ggplot(df_trim, aes(y = log)) + geom_histogram() + coord_flip()
