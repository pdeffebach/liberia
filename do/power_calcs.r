# power calculations

################################################################################
# Add relevant packages ########################################################
################################################################################
# todo: figure out how to use packrat and projects to automate this
library(tidyverse)
library(haven)
library(ICC)
library(knitr)
library(kableExtra)
library(clusterPower)

################################################################################
# Import the data set ##########################################################
################################################################################
# This dataset is just a small subset of variables we need, and just the 
# 4,000 individual level observations for the second round.
df <- haven::read_dta("data/power_calcs.dta")
vars_to_power <- c(
    "anylndconf_u_ec2",
    "unrslv_lnd_conf_u_ec2",
    "conf_any_u_ec2",
    "lmg_conf_u_ec2",
    "lmg_unrslv_conf_u_ec2",
    "lmg_conf_any_u_ec2") 

################################################################################
# Control means, treatments effects, and treatment SEs for each variable #######
################################################################################
# hard coded for now, so dont change the list of variables above!
# todo: figure out why I was dumb and did this. Fix. 
control_means <- c(
    0.087,
    0.024,
    0.041,
    0.306,
    0.064,
    0.101
    )

treatment_effects <- c(
    0.008,
    0.002,
    -0.012,
    .012,
    -0.004,
    -0.015
    ) 

treatment_ses <- c(
    0.011,
    0.005,
    0.006,
    0.017,
    0.009,
    0.010) 

################################################################################
# Define a function for getting the labels as a list ###########################
################################################################################
# Remember that the `haven` package saves the labels of stata variables in 
# an attribute called "label". This function just gets those out and puts
# them in a nice tibble. 
makeVlist <- function(dta) { 
     labels <- sapply(dta, function(x) attr(x, "label"))
      tibble(variable = names(labels),
             label = labels)
}
labels = makeVlist(df[,vars_to_power])

################################################################################
# Find the size of each effect as a t-stat #####################################
################################################################################
# Initiate a vector of all effect sizes, which we will append to
effect_sizes = vector()

for(var in vars_to_power) {
    # get the intra-class correlation
    icc = ICCbare(df$commcode, df[[var]])

    # get the within-group variance
    # todo: document where I got this. I think it was from googling how to 
    # get the within-group variance
    model = anova(lm(df[[var]] ~ factor(df[["commcode"]])))
    varw = model[["Mean Sq"]][1]

    # Look up the documentation for clusterPower to understand what's going
    # on here. 
    effect_size = crtpwr.2mean(
        alpha = .05, 
        power = .8, 
        m = 102, 
        n = 20, 
        cv = 0, 
        d = NA, 
        icc = icc, 
        varw = varw)
    effect_sizes <- c(effect_sizes, effect_size)
}

# Put everything into a tibble that is combined with the control mean etc.
powers = tibble(
    variable = vars_to_power, 
    mde = effect_sizes, 
    treatment_effect = treatment_effects, 
    control_mean = control_means,
    treatment_se = treatment_ses)

# Add in the labels that we got from the makeVlist function above
powers <- powers %>%     
    inner_join(labels, by = "variable") %>% 
    mutate(standardized_treatment_effect = treatment_effect / treatment_se) %>%
    mutate(effect_as_pct_mde = abs(standardized_treatment_effect) / mde) 

# Combine everything together, for real this time.
out <- powers %>% select(label, standardized_treatment_effect, mde, effect_as_pct_mde)

# Use kable, a nice way to format latex tables, for output.
table = kable(
    out, 
    format = "html",
    col.names = c("", "(1)", "(2)", "(3)"),
    escape = FALSE,
     digits = 3,
     align = c("l", "c", "c", "c"), 
     booktabs = T) %>%
add_header_above(c("Dependent variable", "at Endline 2", "able effect", "as % of MDE")) %>%
add_header_above(c("", "Treatment effect", "Minimum detect-", "Treatment effect")) %>% 
cat(., file = "out/tables/power_calcs.html")

###

