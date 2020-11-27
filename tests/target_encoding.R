pacman::p_load(tidyverse, dtplyr, testthat, bench)
setDTthreads(10)

df <- tibble(
    category = c("apple", "apple", "banana", "banana", "banana", "cherry", "cherry", "cherry", "cherry", "durian"),
    label = c(0, 1, 0, 0, 1, 0, 1, 1, 1, 1)
)
df2 <- lazy_dt(df)

bench_result <- bench::mark(
dplyr = df %>%
    group_by(category) %>%
    mutate(te = mean(label)) %>%
    pull(te),
dtplyr = df2 %>%
    group_by(category) %>%
    mutate(te = mean(label)) %>%
    pull(te)
)
bench_result