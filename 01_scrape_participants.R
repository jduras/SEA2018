
# download and scrape SEA conference webpage with a list of all participants
link <- "https://www.southerneconomic.org/program-participant/?conferenceId=4"

readLines("scrape.js") %>%
    # `[`(-3) %>%
    # append(str_c("var url ='", link ,"';"), after = 2) %>%
    str_replace(pattern = "var url ='[[a-zA-Z0-9?=&:/._-]]+';", replacement = str_c("var url ='", link ,"';")) %>%
    writeLines("scrape.js")

system("phantomjs scrape.js")

tbl.sea.2018.participants <-
    read_html("1.html") %>%
    html_table() %>%
    `[[`(1) %>%
    as_tibble() %>%
    rename(participant = Participant,
           affiliation = Affiliation,
           sessions    = `Session(s)`) %>%
    separate(participant, into = c("last.name", "first.name"), sep = ", ")

save(tbl.sea.2018.participants, "sea_2018_participants.Rdata")
