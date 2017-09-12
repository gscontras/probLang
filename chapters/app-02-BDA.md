---
layout: appendix
title: Bayesian data analysis
description: "BDA for the RSA reference game model"
---

### Appendix chapter 2: Bayesian data analysis for the RSA reference game model

*Author: Michael Franke*

WebPPL allows us to conveniently specify even complex probabilistic cognitive models and to explore the predictions these models make. Usually these predictions are probabilistic, e.g., the probability that a pragmatic listener assigns to interpretation $$s$$ after hearing utterance $$u$$ is $$.7$$. Sometimes it suffices for our explanatory purposes to just obtain such (probabilistic) predictions. For example, we might want to explain that the listener's assumptions about the speaker's knowledge impact conclusions about scalar implicatures in a particular qualitative but systematic way (see [Chapter 2](02-pragmatics.html)). Sometimes, however, our explanatory amibitions are more adventurous. Sometimes we like to explain quantitative data, e.g., from observational experiments or corpora. In this case, WebPPL makes it easy to analyse our experimental data through the lens of our probabilistic cognitive models; or, put the other way around, reason about unknown parameters (such as: which model to believe in) based on the data observed. 

##### Motivating example

Consider the vanilla RSA model from [Chapter 1](01-introduction.html) once more. The model is intended to explain data from reference games, such as pictured in Fig. 1.

<img src="../images/rsa_scene.png" alt="Fig. 1: Example referential communication scenario from Frank & Goodman (2012). Speakers choose a single word, $$u$$, to signal an object, $$s$$." style="width: 400px;"/>
<center>Fig. 1: Example referential communication scenario from Frank and Goodman. Speakers choose a single word, <i>u</i>, to signal an object, <i>s</i>.</center>


The vanilla RSA model defines a literal and a pragmatic listener rule, both of which maps utterances $$u \in U$$ to probability distributions over states/objects $$s \in S$$: $$P_{L_{0,1}} \colon U \rightarrow \Delta(S)$$. (The predictions for the pragmatic listener depend on the optimization parameter $$\alpha$$, which is here set to $$1$$. - We will come back to this below.) Let us look at how literal and pragmatic listeners would interpret the utterance "blue" for the example from [Chapter 1](01-introduction.html).

~~~~
// Frank and Goodman (2012) RSA model

// set of states (here: objects of reference)
var states = [{shape: "square", color: "blue"},
              {shape: "circle", color: "blue"},
              {shape: "square", color: "green"}]

// set of utterances
var utterances = ["blue","green","square","circle"]

// prior over world states
var objectPrior = function() {
  uniformDraw(states)
}

// meaning function to interpret the utterances
var meaning = function(utterance, obj){
  (utterance === "blue" || utterance === "green") ? utterance === obj.color :
  (utterance === "circle" || utterance === "square") ? utterance === obj.shape :
  true
}

// literal listener
var literalListener = function(utterance){
  Infer({model: function(){
    var obj = objectPrior();
    condition(meaning(utterance, obj))
    return obj
  }})
}

// set speaker optimality
var alpha = 1

// pragmatic speaker
var speaker = function(obj){
  Infer({model: function(){
    var utterance = uniformDraw(utterances)
    factor(alpha * literalListener(utterance).score(obj))
    return utterance
  }})
}

// pragmatic listener
var pragmaticListener = function(utterance){
  Infer({model: function(){
    var obj = objectPrior()
    observe(speaker(obj),utterance)
    return obj
  }})
}

display("Literal listener's interpretation of 'blue':")
viz.table(literalListener("blue"))
display("Pragmatic listener's interpretation of 'blue':")
viz.table(pragmaticListener("blue"))
~~~~

Suppose we conduct a simple experiment in which we provide the referential context in Fig. 1 above and ask our participants to choose the object which they believe that a speaker who chose utterance "blue" might have meant. The experiment of refp:frankgoodman2012 was slightly different (a betting paradigm in which participants had to distribute 100 points over the potential referents), but refp:QingFranke2013:Variations-on-a executed exactly such a forced choice experiment, in which each participant must choose exactly one referent. They observed that in all conditions equivalent to an observation of "blue", 115 participants chose the blue square and 65 chose the blue circle, while nobody (phew!) chose the green square.

~~~~
var comp_data = {
  blue:   {blue_circle: 65, green_square:   0, blue_square: 115},
}
~~~~

What can we do with this data and our model? - A lot! Much depends on what we want. We could summon **classical statistics**, for example, to test whether an observation of 115 successes in 115+65 = 180 trials is surprising under a null hypothesis that assumes, like our literal listener does, that successes and failures are equally likely. Indeed, a binomial test gives a highly significant result ($$p \le 0.001$$), which is standardly interpreted as an indication that the null hypothesis is to be rejected. In our case this means that it is highly unlikely that the data observed was generated by a literal listener model.

**Bayesian data analysis** is different from classical hypothesis testing. From a Bayesian point of view, we might rather ask: how likely is it that the literal listener model or the pragmatic listener model has generated the observed results? Suppose that we are initially completely undecided about which model is likely correct, but (for the sake of a simple example) consider only those two listener models. Then our **prior belief** in each model is equal $$P(M_{LL}) = P(M_{PL}) = 0.5$$, where $$M_{LL}$$ and $$M_{PL}$$ are the literal and pragmatic listener model, respectively. Our **posterior belief** after observing data $$D$$ concerning the probability of $$M_{LL}$$ can be calculated by Bayes rule:

$$ P(M_{LL} \mid D) = \frac{P(D \mid M_{LL}) \cdot P(M_{LL})}{P(D \mid M_{LL}) \cdot P(M_{LL}) + P(D \mid M_{PL}) \cdot P(M_{PL})}$$

Since prior beliefs are equal, they cancel out entirely, leaving us with:

$$ P(M_{LL} \mid D) = \frac{P(D \mid M_{LL}) }{P(D \mid M_{LL}) + P(D \mid M_{PL}) }$$

The remaining terms refer to the **likelihood** of the data $$D$$ under each model, i.e., how likely the actually observed data was from each model's point of view. We can easily calculate that in WebPPL:


~~~~

var LH_literalLister = Math.exp(Binomial({n: 180, p: 0.5}).score(115))
var LH_pragmatLister = Math.exp(Binomial({n: 180, p: 0.6}).score(115))
var posterior_literalListener = LH_literalLister / 
    (LH_literalLister + LH_pragmatLister)
print(posterior_literalListener)

~~~~

#### Parameter estimation

The above approach generalizes beyond the simplest case of two models to that where we have an infinity of models. First some conceptual contortionism: the literal listener's predictions are equivalent to those of a pragmatic listener with optimality parameter $$\alpha \rightarrow 0$$. The following code treats $$\alpha$$ as an argument of function calls to `speaker` and `pragmaticListener` but is otherwise the exact same as above. 

~~~~
// Frank and Goodman (2012) RSA model

// set of states (here: objects of reference)
var states = [{shape: "square", color: "blue"},
              {shape: "circle", color: "blue"},
              {shape: "square", color: "green"}]

// set of utterances
var utterances = ["blue","green","square","circle"]

// prior over world states
var objectPrior = function() {
  uniformDraw(states)
}

// meaning function to interpret the utterances
var meaning = function(utterance, obj){
  (utterance === "blue" || utterance === "green") ? utterance === obj.color :
  (utterance === "circle" || utterance === "square") ? utterance === obj.shape :
  true
}

// literal listener
var literalListener = function(utterance){
  Infer({model: function(){
    var obj = objectPrior();
    condition(meaning(utterance, obj))
    return obj
  }})
}

// pragmatic speaker
var speaker = function(obj, alpha){ //alpha is now an argument
  Infer({model: function(){
    var utterance = uniformDraw(utterances)
    factor(alpha * literalListener(utterance).score(obj))
    return utterance
  }})
}

// pragmatic listener
var pragmaticListener = function(utterance, alpha){ //alpha is now an argument
  Infer({model: function(){
    var obj = objectPrior()
    observe(speaker(obj, alpha),utterance) // pass alpha to the speaker function
    return obj
  }})
}

display("Literal listener's interpretation of 'blue':")
viz.table(literalListener("blue"))
display("Pragmatic listener's interpretation of 'blue':")
viz.table(pragmaticListener("blue"), 1)
~~~~

> **Exercises:**

> 1. Check that $$\alpha \rightarrow 0$$ gives predictions identical to the literal listener's rule.

In a sense, we now have infinitely many models, one for each value of $$\alpha$$. Another equivalent way of looking at this is to say that we have one model $$M_{PL}$$ whose probabilistic predictions depend on the value of the parameter $$\alpha$$. In other words, we have defined a parameterized likelihood function for observational data $$P(D \mid M_{PL}, \alpha)$$. Whenever it is clear what the model is, we can drop the reference to the model. For the general case of possibly high-dimensional continuous parameter vector $$\theta$$, we can use Bayes rule for **parameter inference** like so:

$$ P(\theta \mid D) = \frac{P(D \mid \theta) \cdot P(\theta)}{ \int P(D \mid \theta') \cdot P(\theta') \text{d} \theta'}$$

~~~~
// Frank and Goodman (2012) RSA model (as before)

///fold:

// set of states (here: objects of reference)
var states = [{shape: "square", color: "blue"},
              {shape: "circle", color: "blue"},
              {shape: "square", color: "green"}]

// set of utterances
var utterances = ["blue","green","square","circle"]

// prior over world states
var objectPrior = function() {
  uniformDraw(states)
}

// meaning function to interpret the utterances
var meaning = function(utterance, obj){
  (utterance === "blue" || utterance === "green") ? utterance === obj.color :
  (utterance === "circle" || utterance === "square") ? utterance === obj.shape :
  true
}

// literal listener
var literalListener = function(utterance){
  Infer({model: function(){
    var obj = objectPrior();
    condition(meaning(utterance, obj))
    return obj
  }})
}

// pragmatic speaker
var speaker = function(obj, alpha){ //alpha is now an argument
  Infer({model: function(){
    var utterance = uniformDraw(utterances)
    factor(alpha * literalListener(utterance).score(obj))
    return utterance
  }})
}

// pragmatic listener
var pragmaticListener = function(utterance, alpha){ //alpha is now an argument
  Infer({model: function(){
    var obj = objectPrior()
    observe(speaker(obj, alpha),utterance) // pass alpha to the speaker function
    return obj
  }})
}

///

// Data analysis

var non_normalized_posterior = function(){
  // prior over model parameter
  var alpha = uniform({a:0, b:10})
  var predicted_probability = 
      Math.exp(
        pragmaticListener("blue", alpha).score({shape: "square", color: "blue"})
      )
  var likelihood = Binomial({n: 180, p: predicted_probability}).score(115)    
  factor(likelihood)
}

var posterior_samples = Infer({
  method: "MCMC",
  samples: 20000,
  burn: 2500,
//   verbose: true,
  model: non_normalized_posterior})
  
viz(posterior_samples)  
~~~~
