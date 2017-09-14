library(tidyverse)
library(ggmcmc)
library(coda)
library(rwebppl)
library(jsonlite)

##########################
## observed data
##########################

prod_data = matrix(c(9, 135, 0, 0, 0, 0, 119, 25, 63, 0, 0, 81), nrow = 3, byrow = T)
rownames(prod_data) = c("blue_circle", "green_square", "blue_square")
colnames(prod_data) = c("blue","circle","green","square")

comp_data = matrix(c(65, 0, 115, 0, 117, 62), nrow = 2, byrow = T)
rownames(comp_data) = c("blue","square")
colnames(comp_data) = c("blue_circle", "green_square", "blue_square")


##########################
## WebPPL code
##########################

program_code = '

////////////////
// OBSERVED DATA
////////////////

///fold:

var salience_priors = {
blue_circle:   71,  // object "blue circle" was selected 71 times
green_square: 139,
blue_square:   30,
}

var prod_data = {
blue_circle:  {blue:  9, circle: 135, green:   0, square:  0},
green_square: {blue:  0, circle:   0, green: 119, square: 25},
blue_square:  {blue: 63, circle:   0, green:   0, square: 81}
}

var comp_data = {
blue:   {blue_circle: 65, green_square:   0, blue_square: 115},
square: {blue_circle:  0, green_square: 117, blue_square:  62}
}

///

////////////
// RSA MODEL
////////////

///fold:

// set of states (here: objects of reference)
var states = ["blue_circle", "green_square", "blue_square"]

// set of utterances
var utterances = ["blue","circle","green","square"]

// prior over world states
var objectPrior = function() {
categorical({ps: _.values(salience_priors), // empirical data 
vs: states}) 
}

// meaning function to interpret the utterances
var meaning = function(utterance, obj){
_.includes(obj, utterance)
}

// literal listener
var literalListener = function(utterance){
Infer({model: function(){
var obj = uniformDraw(states);
condition(meaning(utterance, obj))
return obj
}})
}

// function for utterance costs
var cost = function(utterance, c) {
(utterance === "blue" || utterance === "green") ? c : 0
}

// pragmatic speaker
var speaker = function(obj, alpha, c){
Infer({model: function(){
var utterance = uniformDraw(utterances)
factor(alpha * (literalListener(utterance).score(obj) -
cost(utterance,c)))
return utterance
}})
}

// pragmatic listener
var pragmaticListener = function(utterance, alpha, c){
Infer({model: function(){
var obj = objectPrior()
observe(speaker(obj, alpha, c),utterance)
return obj
}})
}

///

////////////////
// Data Analysis
////////////////

var posterior_predictive = function(){

// priors over parameters of interest

var alpha = uniform({a:0, b:10})
var c = uniform({a:-0.4, b:0.4})

// speaker production part

var PP_speaker = map(function(s){

var speaker_predictions = speaker(s, alpha, c)
var speaker_data = prod_data[s]

var utt_probs = map(function(u){
return Math.exp(speaker_predictions.score(u))
}, _.keys(speaker_data))

var utt_count = map(function(u){
return speaker_data[u]
}, _.keys(speaker_data))

observe(Multinomial({n: sum(utt_count), 
ps: utt_probs}), 
utt_count)

return multinomial({n: sum(utt_count), ps: utt_probs})

}, states)

// listener comprehension part

var PP_listener = map(function(u){

var listener_predictions = pragmaticListener(u, alpha, c)
var listener_data = comp_data[u]

var int_probs = map(function(s){
return Math.exp(listener_predictions.score(s))
}, _.keys(listener_data))

var int_count = map(function(s){
return listener_data[s]
}, _.keys(listener_data))

observe(Multinomial({n: sum(int_count), 
ps: int_probs}), 
int_count)

return multinomial({n: sum(int_count), ps: int_probs})

}, _.keys(comp_data))

return {PP_speaker, PP_listener, alpha, c}
}

'

##########################
## receive samples from WebPPL
##########################

posteriorSamples <- webppl(
  program_code = program_code,
  model_var = "posterior_predictive",
  inference_opts = list(method = "MCMC", kernel = list(
    HMC = list(stepSize = 0.0375, steps = 5)
  ), samples = 1000, burn = 1000, lag = 2, verbose = T),
  chains = 2,
  cores = 2
  )

##########################
## process samples & plot
##########################

posteriorSamples %>% 
  filter(Parameter %in% c("alpha",'c')) %>%
  mutate(value = unlist(value)) %>%
  ggplot(., aes(x = value))+
  geom_histogram()+facet_wrap(~Parameter, scales = 'free')

speakerSamples = filter(posteriorSamples, Parameter == "PP_speaker")
listenerSamples = filter(posteriorSamples, Parameter == "PP_listener")

PPC_speaker = map_df(1:nrow(speakerSamples), function(i) {
  data.frame(
    object = rep( c("blue_circle", "green_square", "blue_square"), times = 4),
    utterance = rep(c("color","shape","color","shape"), each = 3),
    value = as.vector(speakerSamples$value[i][[1]]),
    obs = as.vector(prod_data)
  )
}) %>% filter(obs != 0)

PPC_speaker_plot = PPC_speaker %>% ggplot(aes(x = value)) + 
  geom_density() + 
  facet_grid(object ~ utterance) + 
  geom_point(aes(y = 0, x = obs), color = "firebrick")

PPC_speaker_plot

ggsave("../images/PPC_speaker_badModel.jpg", PPC_speaker_plot, width = 5, height = 7)


PPC_listener = map_df(1:nrow(listenerSamples), function(i) {
  data.frame(
    object = rep( c("blue_circle", "green_square", "blue_square"), each = 2),
    utterance = rep(c("color","shape"), times = 3),
    value = as.vector(listenerSamples$value[i][[1]]),
    obs = as.vector(comp_data)
  )
}) %>% filter(obs != 0)

PPC_listener_plot = PPC_listener %>% ggplot(aes(x = value)) + 
  geom_density() + 
  facet_grid(utterance ~ object) + 
  geom_point(aes(y = 0, x = obs), color = "firebrick")

PPC_listener_plot

ggsave("../images/PPC_listener_badModel.jpg", PPC_listener_plot, width = 5, height = 7)
