################################################################################
#! Install required packages
################################################################################

options(repos = "https://cloud.r-project.org/")
options(readr.show_progress = FALSE)
options(dplyr.summarise.inform = FALSE)
options(future.globals.maxSize = Inf)
options(warn = -1)

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(tidyverse, parallel, furrr, vroom, tidyfast)

# Setting reticulate
if (!requireNamespace("reticulate", quietly = TRUE)) install.packages("reticulate")
DAJIN_Python <- reticulate:::conda_list()$python %>%
    str_subset("DAJIN/bin/python")
Sys.setenv(RETICULATE_PYTHON = DAJIN_Python)
reticulate::use_condaenv("DAJIN")

joblib <- reticulate::import("joblib")
hdbscan <- reticulate::import("hdbscan")

################################################################################
#! I/O naming
################################################################################

#===========================================================
#? TEST Auguments
#===========================================================

# barcode <- "barcode08"
# allele <- "wt"

# if (allele == "abnormal") control_allele <- "wt"
# if (allele != "abnormal") control_allele <- allele
# file_que_mids <- sprintf(".DAJIN_temp/clustering/temp/query_score_%s_%s", barcode, allele)
# file_que_label <- sprintf(".DAJIN_temp/clustering/temp/query_labels_%s_%s", barcode, allele)
# file_control_score <- sprintf(".DAJIN_temp/clustering/temp/df_control_prop_%s.RDS", control_allele)
# threads <- 12L
# plan(multiprocess, workers = threads)

#===========================================================
#? Auguments
#===========================================================

args <- commandArgs(trailingOnly = TRUE)
file_que_mids <- args[1]
file_que_label <- args[2]
file_control_score <- args[3]
threads <- as.integer(args[4])
plan(multiprocess, workers = threads)

#===========================================================
#? Inputs
#===========================================================

df_que_mids <- vroom(file_que_mids,
    col_names = FALSE,
    col_types = cols(),
    num_threads = threads)
colnames(df_que_mids) <- seq_len(ncol(df_que_mids))

df_que_label <- read_csv(file_que_label,
    col_names = c("id", "strand", "barcode"),
    col_types = cols())

df_control_score <- readRDS(file_control_score)

#===========================================================
#? Outputs
#===========================================================

output_suffix <- str_remove(file_que_label, ".*labels_")

################################################################################
#! MIDS scoring
################################################################################

df_que_score <-
    df_que_mids %>%
    dt_pivot_longer(names_to = "loc", values_to = "MIDS") %>%
    group_by(loc) %>%
    nest(nest = c(MIDS)) %>%
    mutate(que_prop = mclapply(nest,
        function(x)
            x %>% table(dnn = "MIDS") %>% prop.table() %>% as_tibble(n = "prop"),
        mc.cores = threads)) %>%
    mutate(loc = as.double(loc)) %>%
    select(loc, que_prop)

################################################################################
#! MIDS subtraction
################################################################################

list_mids_score <-
    inner_join(df_que_score, df_control_score, by = "loc") %>%
    {future_map2(.$que_prop, .$control_prop, function(x, y) {
        if (y == 1) {
            x %>%
            rename(score = prop) %>%
            mutate(score = replace_na(score, 0))
        } else {
            full_join(x, y, by = "MIDS", suffix = c("_x", "_y")) %>%
            mutate(score = prop_x - prop_y) %>%
            select(-contains("prop")) %>%
            mutate(score = replace_na(score, 0))
        }
    })}

################################################################################
#! Score each reads
################################################################################

df_score <-
    future_map2_dfc(df_que_mids, list_mids_score,
    function(x, y) {
        tmp1 <- x %>% as_tibble() %>% set_names("MIDS")
        tmp2 <- y
        left_join(tmp1, tmp2, by = "MIDS") %>%
            mutate(score = replace_na(score, 0)) %>%
            pull(score)
    })

df_score[, colSums(df_score) == 0] <- 10^-10000

#===========================================================
#? Replace sequence error
#===========================================================

sequence_error <-
    df_control_score %>%
    unnest(control_prop) %>%
    filter(MIDS != "M" & prop > 0.1 & mut == 0) %>%
    pull(loc) %>%
    unique()

df_score[, sequence_error] <- 10^-10000

################################################################################
#! PCA
################################################################################

pca_first <- prcomp(df_score, scale = FALSE)

#* TEST ========================================================

#? HOTELLING
pca_loading <- sweep(pca_first$rotation, 2, pca_first$sdev, FUN = "*")[, 1]
pca_loading_scaled <- scale(pca_loading)
tmp_head <- head(pca_loading_scaled, 100)

pca_hotelling <-
    rnorm(ncol(df_que_mids) * 100,
        mean = mean(tmp_head),
        sd = sd(tmp_head)) %>%
    append(pca_loading_scaled, .) %>%
    as_tibble %>%
    summarize(score = value,
        mean = mean(value),
        var = mean((value - mean(value))^2)) %>%
    summarize(anomaly_score = (score - mean)^2 / var) %>%
    mutate(loc = row_number(), threshold = qchisq(0.99, 1)) %>%
    filter(anomaly_score > threshold & loc <= ncol(df_que_mids)) %>%
    pull(loc)

# Force to add a point mutation location
if (sum(df_control_score$mut) == 1) {
    pca_hotelling <-
        append(pca_hotelling, which(df_control_score$mut == 1)) %>%
        unique
}

#* TEST ========================================================

pca_second <- prcomp(df_score[, pca_hotelling], scale = FALSE)
num_components <- 1:10

if (ncol(pca_second$x) > length(num_components)) {
    df_coord <- pca_second$x[, num_components] %>% as_tibble
    num_prop_variance <- summary(pca_second)$importance[2, num_components]
    output_pca <- map2_dfc(df_coord, num_prop_variance, ~ .x * .y)
} else {
    df_coord <- pca_second$x %>% as_tibble
    num_prop_variance <- summary(pca_second)$importance[2, ]
    output_pca <- map2_dfc(df_coord, num_prop_variance, ~ .x * .y)
}

output_pca <- map2_dfc(df_coord, num_prop_variance, ~ .x * .y)

################################################################################
#! Clustering
################################################################################

input_hdbscan <- output_pca

min_cluster_sizes <-
    seq(nrow(input_hdbscan) * 0.1, nrow(input_hdbscan) * 0.3, length = 30) %>%
    as.integer %>%
    `+`(2L) %>%
    unique

hd <- function(x) {
    cl <- hdbscan$HDBSCAN(min_samples = 1L, min_cluster_size = as.integer(x),
        memory = joblib$Memory(cachedir = ".DAJIN_temp/clustering/temp", verbose = 0))
    cl$fit_predict(input_hdbscan) %>% table %>% length
}

#===========================================================
#? Clustering with multile cluster sizes
#? to find the most frequent cluster numbers
#===========================================================

int_cluster_nums <-
    mclapply(min_cluster_sizes, hd,
    mc.cores = as.integer(threads)) %>%
    unlist

#===========================================================
#? Extract cluster size with the smallest cluster size
#? and the most frequent cluster numbers
#===========================================================

int_cluster_nums_opt <-
    int_cluster_nums %>%
    as_tibble %>%
    mutate(id = row_number()) %>%
    add_count(value, name = "count") %>%
    slice_max(count) %>%
    slice_min(id) %>%
    pull(id)

if (length(int_cluster_nums_opt) == 0)
    int_cluster_nums_opt <- which.max(min_cluster_sizes)

#===========================================================
#? Clustering with optimized cluster sizes
#===========================================================

clustering_hdbscan <- hdbscan$HDBSCAN(min_samples = 1L,
    min_cluster_size = min_cluster_sizes[int_cluster_nums_opt],
    memory = joblib$Memory(cachedir = ".DAJIN_temp/clustering/temp", verbose = 0))

int_hdbscan_clusters <- clustering_hdbscan$fit_predict(input_hdbscan) + 1

#* TEST ========================================================

# #? REPEAT CLUSTERING

# hdbscan_clusters <- int_hdbscan_clusters
# stop_cl_number <- NA

# while (!identical(unique(hdbscan_clusters), stop_cl_number)) {
#     for (cluster in unique(hdbscan_clusters) %>%  sort) {
#         stop_cl_number <- unique(hdbscan_clusters)
#         if(df_score[hdbscan_clusters == cluster, pca_hotelling] %>% n_distinct == 1) next

#         pca_cluster <- prcomp(df_score[hdbscan_clusters == cluster, pca_hotelling], scale = FALSE)

#         if (ncol(pca_cluster$x) > length(num_components)) {
#             df_coord <- pca_cluster$x[, num_components] %>% as_tibble
#             num_prop_variance <- summary(pca_cluster)$importance[2, num_components]
#             output_pca <- map2_dfc(df_coord, num_prop_variance, ~ .x * .y)
#         } else {
#             df_coord <- pca_cluster$x %>% as_tibble
#             num_prop_variance <- summary(pca_cluster)$importance[2, ]
#             output_pca <- map2_dfc(df_coord, num_prop_variance, ~ .x * .y)
#         }

#         input_hdbscan <- output_pca

#         min_cluster_sizes <-
#         seq(nrow(input_hdbscan) * 0.1, nrow(input_hdbscan) * 0.3, length = 30) %>%
#             as.integer %>%
#             `+`(2L) %>%
#             unique

#         int_cluster_nums <-
#             mclapply(min_cluster_sizes, hd,
#             mc.cores = as.integer(threads)) %>%
#             unlist

#         getmode <- function(v) {
#             uniqv <- unique(v)
#             uniqv[which.max(tabulate(match(v, uniqv)))]
#         }

#         if (getmode(int_cluster_nums) == 1) next

#         int_cluster_nums_opt <-
#             int_cluster_nums %>%
#             as_tibble %>%
#             mutate(id = row_number()) %>%
#             add_count(value, name = "count") %>%
#             slice_max(count) %>%
#             slice_min(id) %>%
#             pull(id)

#         if (length(int_cluster_nums_opt) == 0)
#             int_cluster_nums_opt <- which.max(min_cluster_sizes)

#         tmp_cl <- clustering_hdbscan$fit_predict(input_hdbscan) + 1
#         if (any(tmp_cl == 0)) tmp_cl <- tmp_cl + 1
#         hdbscan_clusters[hdbscan_clusters == cluster] <- tmp_cl + max(hdbscan_clusters)
#     }
# }
# # table(int_hdbscan_clusters)
# # table(hdbscan_clusters)
# int_hdbscan_clusters <- hdbscan_clusters
#* ========================================================

################################################################################
#! Output results
################################################################################

write_csv(tibble(cl = int_hdbscan_clusters),
    sprintf(".DAJIN_temp/clustering/temp/int_hdbscan_clusters_%s", output_suffix),
    col_names = F
)

saveRDS(df_score,
    sprintf(".DAJIN_temp/clustering/temp/df_score_%s.RDS", output_suffix)
)
