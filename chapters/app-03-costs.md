---
layout: appendix
title: Utterance costs and utterance priors
description: "More on utterance costs and utterance priors"
---

### Appendix chapter 03: More on utterance costs and utterance priors

*Author: Michael Franke*

The main text of [Chapter 1](01-introduction.html) introduced the utility function for the pragmatic speaker as:

$$U_{S_{1}}(u; s) = \log L_{0}(s\mid u) - C(u)\,.$$

[Appendix Chapter 2](app-02-utilities.html) discusses how to derive the first summand. Here we focus on the cost of utterances and how to implement them in WebPPL.

The speaker rule derived from this utility function, written here with explicit reference to its parameters $$\alpha$$ and $$C$$, is:

$$P_{S_1}(u \mid s; \alpha, C) \propto \exp(\alpha (\log L_{0}(s\mid u) - C(u)))\,.$$

In this formulation, utterance costs are used to implement preferences that a speaker might have between one utterance or another, all else equal. Here we look at two equivalent ways to implement such **additive utterance costs** (once straightforwardly and once as an utterance prior). We also look at a conceptually different way of implementing preferences between utterance which are unrelated to their informativity, also in terms of utterance priors.

The following code gives the vanilla RSA model from [Chapter 1](01-introduction.html), but also includes (arbitrarily chosen) costs for messages. These are subtracted in the most straightforward manner, following the above definition of utilities.

~~~~

// Vanilla RSA model up to speaker function
///fold: 
var objects = [{color: "blue", shape: "square", string: "blue square"},
               {color: "blue", shape: "circle", string: "blue circle"},
               {color: "green", shape: "square", string: "green square"}]

// set of utterances
var utterances = ["blue", "green", "square", "circle"]

// prior over world states
var objectPrior = function() {
  var obj = uniformDraw(objects)
  return obj.string 
}

// meaning function to interpret the utterances
var meaning = function(utterance, obj){
  _.includes(obj, utterance)
}

// literal listener
var literalListener = function(utterance){
  Infer({model: function(){
    var obj = objectPrior();
    condition(meaning(utterance, obj))
    return obj
  }})
}

///

// set speaker optimality
var alpha = 1

// cost function
var cost = function(utterance){
  utterance == "blue" ? .1 :
  utterance == "green" ? .2 :
  utterance == "square" ? .3 :
    .4
}

// pragmatic speaker
var speaker = function(obj){
  Infer({model: function(){
    var utterance = uniformDraw(utterances)
    factor(alpha * (literalListener(utterance).score(obj)
	                - cost(utterance)))
    return utterance
  }})
}

speaker("blue square")

~~~~

> **Exercise:**
> 1. Check how different utterance costs affect speaker production likelihoods.
> 2. For fixed costs, check how manipulating $$\alpha$$ affects production likelihoods.

In WebPPL the speaker production probabilities are computed using `Infer` and `factor`. This requires the specification of an utterance prior (so as to minimally tell `Infer` what the domain is from which it could consider different utterances to be compared to whatever we write into the `factor` statement). We can also use utterance priors to implement preferences between utterances. To do so, we first need to map costs onto prior probabilities of utterances. Any function from costs to prior utterance probabilities that is strictly monotonically decreasing would do. One possibility for an utterances prior based on cost function $$C$$ is this:

$$P(u; C) \propto \exp(-C(u))\,.$$

The resulting speaker production probabilities are defined as:

$$P_{S_1}(u \mid s; \alpha, C) \propto P(u; C) \ \exp(\alpha \log P_{LL}(u \mid s))\,.$$

This is implemented in the following code:

~~~~

// Vanilla RSA model up to speaker function
///fold: 
var objects = [{color: "blue", shape: "square", string: "blue square"},
               {color: "blue", shape: "circle", string: "blue circle"},
               {color: "green", shape: "square", string: "green square"}]

// set of utterances
var utterances = ["blue", "green", "square", "circle"]

// prior over world states
var objectPrior = function() {
  var obj = uniformDraw(objects)
  return obj.string 
}

// meaning function to interpret the utterances
var meaning = function(utterance, obj){
  _.includes(obj, utterance)
}

// literal listener
var literalListener = function(utterance){
  Infer({model: function(){
    var obj = objectPrior();
    condition(meaning(utterance, obj))
    return obj
  }})
}

///

// set speaker optimality
var alpha = 1

// cost function
var cost = function(utterance){
  utterance == "blue" ? .1 :
  utterance == "green" ? .2 :
  utterance == "square" ? .3 :
    .4
}

var utterancePrior = function() {
  var uttProbs = map(function(u) {return Math.exp(-cost(u)) }, utterances)
  return categorical(uttProbs, utterances);
}

// pragmatic speaker
var speaker = function(obj){
  Infer({model: function(){
  var utterance = utterancePrior()
    factor(alpha * literalListener(utterance).score(obj))
    return utterance
  }})
}

speaker("blue square")

~~~~

> **Exercise:**
> 1. Check how different utterance costs affect speaker production likelihoods.
> 2. For fixed costs, check how manipulating $$\alpha$$ affects production likelihoods.

Unlike in the previous, in this new implementation choice the effect of utterance costs is not affected by manipulating the speaker optimality parameter $$\alpha$$. This may be a bug or a feature, depending on what we want. There are simply two ways of implementing *ceteris-paribus* preferences among utterance: one where differences are affected by $$\alpha$$ and one where they are not. One possible conceptual interpretation in which both possibility can coexist peacefully and actually complement each other is this (currently speculative) suggestion of a distinction: 

**Economic utterance costs** that relate to the effort of producing an utterance, such as length, phonological difficulty or syntactic complexity should be affected by $$\alpha$$, since a hyperrational agent (where $$\alpha \rightarrow \infty$$) would, all else equal, never actively choose a form that is in an objective sense less economic. **Salience utterance priors**, on the other hand, might implement a speaker inclination to prefer one utterance over another even when every objective criterion of informativity, economy etc. that would count for rational decision, is equal. The former should therefore be affected by $$\alpha$$, the latter should not $$\alpha$$. 

Be all of this as it may, it is nonetheless possible to also implement additive economic utterance costs that *are* affected by $$\alpha$$ in terms of utterance priors in WebPPL. Like so:

~~~~

// Vanilla RSA model up to speaker function
///fold: 
var objects = [{color: "blue", shape: "square", string: "blue square"},
               {color: "blue", shape: "circle", string: "blue circle"},
               {color: "green", shape: "square", string: "green square"}]

// set of utterances
var utterances = ["blue", "green", "square", "circle"]

// prior over world states
var objectPrior = function() {
  var obj = uniformDraw(objects)
  return obj.string 
}

// meaning function to interpret the utterances
var meaning = function(utterance, obj){
  _.includes(obj, utterance)
}

// literal listener
var literalListener = function(utterance){
  Infer({model: function(){
    var obj = objectPrior();
    condition(meaning(utterance, obj))
    return obj
  }})
}

///

// set speaker optimality
var alpha = 1

// cost function
var cost = function(utterance){
  utterance == "blue" ? .1 :
  utterance == "green" ? .2 :
  utterance == "square" ? .3 :
    .4
}

var utterancePrior = function() {
  var uttProbs = map(function(u) {return Math.exp(- alpha * cost(u)) }, utterances)
  return categorical(uttProbs, utterances);
}

// pragmatic speaker
var speaker = function(obj){
  Infer({model: function(){
  var utterance = utterancePrior()
    factor(alpha * literalListener(utterance).score(obj))
    return utterance
  }})
}

speaker("blue square")

~~~~

> **Exercise:**
> 1. Check how different utterance costs affect speaker production likelihoods.
> 2. For fixed costs, check how manipulating $$\alpha$$ affects production likelihoods.

It is easy to see that if we choose this particular function from utterance costs to utterance priors, which also depends on $$\alpha$$:

$$P(u; \alpha, C) \propto \exp(-\alpha C(u))\,,$$

the resulting speaker choice rule is equivalent to what we obtain from additive costs (the starting point of this chapter):

$$P_{S_1}(u \mid s; \alpha, C) \propto P(u; \alpha, C) \ \exp(\alpha \log P_{LL}(u \mid s))\,,$$

wich expands to:

$$P_{S_1}(u \mid s; \alpha, C) \propto \frac{\exp(-\alpha C(u))}{\sum_{u'}\exp(-\alpha C(u'))} \ \exp(\alpha \log P_{LL}(u \mid s))\,,$$

where $$\sum_{u'}\exp(-\alpha C(u'))$$ cancels out because it is independent of $$u$$:

$$P_{S_1}(u \mid s; \alpha, C) \propto \exp(-\alpha C(u)) \ \exp(\alpha \log P_{LL}(u \mid s))\,,$$

so that:

$$P_{S_1}(u \mid s; \alpha, C) \propto \exp(\alpha \log P_{LL}(u \mid s) - \alpha C(u))\,,$$

and finally: 

$$P_{S_1}(u \mid s; \alpha, C) \propto \exp(\alpha (\log P_{LL}(u \mid s) - C(u)))\,.$$

