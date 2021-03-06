library(text2vec)
library(Matrix)

article_dat = read.csv("data/jasa.csv", stringsAsFactors = FALSE)

## Articles with large number of downloads
article_dat[article_dat$views >= 2000, ]
## One outlier
article_dat = article_dat[article_dat$views < 10000, ]


## Document-term matrix
tokens = article_dat$title %>% tolower() %>% word_tokenizer()
sw = c("of", "for", "and", "in", "with", "a", "the", "to", "on", "an", "by", "its")
## 3-gram, mininum term count = 2
it = itoken(tokens)
title_voc = create_vocabulary(it, ngram = c(1, 3), stopwords = sw) %>%
    prune_vocabulary(term_count_min = 2)
dict = title_voc$vocab$terms
vectorizer = vocab_vectorizer(title_voc)
it = itoken(tokens)
title_mat  = create_dtm(it, vectorizer)


## Article-author matrix
authors = ifelse(article_dat$authors == "", "#", article_dat$authors)
authors = strsplit(authors, "#")
author_tab = table(unlist(authors))
## At least two papers to be included
author_dict = names(author_tab)[author_tab > 1]
## Matt Taddy has one article and one rejoinder
author_dict = author_dict[-grep("Matt Taddy", author_dict)]
author_match = lapply(authors, function(x) na.omit(match(x, author_dict)))
author_i = rep(seq_along(author_match), sapply(author_match, length))
author_j = unlist(author_match)
author_mat = sparseMatrix(i = author_i, j = author_j, x = 1)


## Category of articles (application section, method section, etc.)
sects = as.character(article_dat$sect)
## Combine similar categories
sects = gsub(".*Presidential Address.*", "ASA Presidential Address", sects)
sects = gsub(".*Case Studies.*", "Application and Case Studies", sects)
sects = gsub(".*Original Articles.*", "Primary Article", sects)
sects = gsub(".*Fisher Lecture.*", "Fisher Lecture", sects)
sects = gsub(".*Review.*", "Review", sects)
sects = gsub(".*Correction.*|.*Errata.*|.*Corrigendum.*", "Correction", sects)
sects = gsub(".*Index.*", "Index", sects)
sects = gsub(".*Letters to the Editor.*", "Letters to the Editors", sects)
sects = gsub(".*Editorial.*", "Editorial", sects)
sects = reorder(sects, rep(1, length(sects)), sum)
sect_mat = model.matrix(~ sects + 0)[, -1]
sect_dict = gsub("^sects", "", colnames(sect_mat))
