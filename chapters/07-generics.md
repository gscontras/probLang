---
layout: chapter
title: Extending our models of predication
description: "Generic language"
---

### Chapter 7: Generic language

Consider the following sentences:

1. All swans are white.
2. Most swans are white.
3. Some swans are white.
4. *Swans are white.*

Is there some relation between I - III & IV?

~~~~
var literalMeanings = {
  some: function(x){ x > 0 },
  most: function(x){ x > 0.5 },
  all: function(x){ x == 1 },
  generic: function(x, theta){ x > theta }
}
var meaningFn = literalMeanings["generic"]
meaningFn(0.6, 0.5)
~~~~

> *Exercise*: Try out the different meaning functions with different inputs to make sure you understand threshold-semantics. What should `theta` be?

### The logical problem

Generic language (e.g., *Swans are white.*) is a simple and ubiquitous way to communicate generalizations about categories.  Linguists, philosophers, and psychologists have scratched their collective heads for decades, trying to figure out what makes a generic sentence true or false. At first glance, generics feel like universally-quantified statements, as in *All swans are white*.  Unlike universals, however, generics are resilient to counter-examples (e.g., *Swans are white* even though there are black swans).  Our intuitions then fall back to something more vague like *Swans, in general, are white* because indeed most swans are white. But mosquitos, in general, do not carry malaria, yet everyone agrees *Mosquitos carry malaria*.

Indeed, it appears that any truth conditions stated in terms of how common the property is within the kind violates intuitions. Consider the birds: for a bird, being female practically implies you will lay eggs (the properties are present in the same proportion), yet we say things like *Birds lay eggs* and we do not say things like *Birds are female*.

~~~~
var theta = 0.49
var generic = function(x){ x > theta }
var number_of_birds_that_lay_eggs = 0.5;
var number_of_birds_that_are_female = 0.5;
var number_of_mosquitos_that_carry_malaria = 0.02;

display("Birds lay eggs is true ? " + generic(number_of_birds_that_lay_eggs))
display("Birds are female is true ? " + generic(number_of_birds_that_are_female))
display("Mosquitos carry malaria is true ? " + generic(number_of_mosquitos_that_carry_malaria))
''
~~~~

reft:tessler2016manuscript propose that the core meaning of a generic statement is in fact a threshold as in `generic` above, but underspecified (listener has uncertainty about `theta`).
Then we can use the RSA core to resolve a more precise meaning in context.

### A pragmatic model of generic language

The model takes the generic $$[\![\text{K has F}]\!]$$ to mean the prevalence of property F within kind K (i.e., $$P(F \mid K)$$) is above some threshold (cf. Cohen 1999). Quantifiers can be described as conditions on prevalence: $$[\![\text{some}]\!] := P(F \mid K) > 0 $$, $$[\![\text{all}]\!] := P(F \mid K) = 1$$. But for the generic, no fixed value of the threshold would suffice. Instead, we leave the threshold underspecified in the semantics ($$\theta \sim \text{Uniform}(0, 1)$$) and infer it in context.

Context here takes the form of the listener's and speaker's shared beliefs about the property in question. The shape of this distribution affects the listener's interpretation, because the threshold must be calibrated to make utterances truthful and informative. The shape of this distribution varies significantly among different properties (e.g., *lays eggs*, *carries malaria*), and may be the result of a deeper conceptual model of the world.

First, let's try to understand the prior.

### Prior model

Think of your favorite kind of animal.
Got one in mind?
What percentage of that kind of animal *is female*?
Probably roughly 50%, regardless of the kind of animal you thought of.
What percentage of that kind of animal *lays eggs*?
Well, it probably depends on the kind of animal you thought. If you thought of a falcon, then roughly 50% (recall, only the females lay eggs).
But if you thought of a bear, then 0% of them lay eggs.

We can conceive of the prior distribution over the prevalence of a feature with a kind $$P(F\mid K)$$ as a distribution over kinds $$P(K)$$ and then the prevalence of the feature within the kind.

~~~~
var allKinds = [
  {kind: "dog", family: "mammal"},
  {kind: "falcon", family: "bird"},
  {kind: "cat", family: "mammal"},
  {kind: "gorilla", family: "mammal"},
  {kind: "robin", family: "bird"},
  {kind: "alligator", family: "reptile"},
  {kind: "giraffe", family: "mammal"},
]

var kindPrior = function(){
  uniformDraw(allKinds)
}

var prevalencePrior = Infer({model:
  function(){
    var k = kindPrior()
    var prevalence =
        k.family == "bird" ? 0.5 :  // half of birds lay eggs
        k.family == "reptile" ? 0.2 : // i'm not really sure if reptiles lay eggs
        0 // no other thing lays eggs;

    return prevalence
  }
})

prevalencePrior
~~~~

> *Exercise*: What if you didn't know that exactly 50% of birds lay eggs? Generalize the above code to sample the prevalence of laying eggs for birds, reptiles, etc.. from a distribution. (Hint: The [Beta distribution](http://docs.webppl.org/en/master/distributions.html#Beta) is a distribution over numbers between 0 and 1.)

#### A generalization of the prior model

In the above model, we encoded the fact that people have knowledge about different types of categories (e.g., reptiles, mammals) and that this knowledge should give rise to different beliefs about the prevalence of the feature for a given kind.
More generally, if speakers and listeners believe that some kinds have a causal mechanism that *stably* gives rise to the property, while others do not, then we would expect the prior to be structured as a mixture distribution (cf., Griffiths & Tenenbaum, 2005).

For convenience, let us denote the relevant probability $$P(F \mid K)$$ as $$x$$.
The categories that have a stable causal mechanism produce the feature with some probability $$x_{stable}$$.
The categories that do not have a stable causal mechanism produce the feature with some probability $$x_{transient}$$ (perhaps this unstable mechanism is an external, environmental cause).
We would expect $$x_{transient}$$ to be small (even zero), as certain features are completely absent in many categories (e.g., the number of lions that lay eggs).
$$x_{stable}$$, on the other hand, could be large, giving rise to features that are often common in a kind (e.g., *has four legs*), but might also be substantially less than 1 for features that are non-universal in a category (e.g., *has brown fur*).

We formalize this idea by drawing $$x_{stable}$$ and $$x_{transient}$$ from Beta distributions (which has support between 0 - 1; thus samples from a Beta are numbers between 0 - 1 i.e., probabilities) with different parameters.
We fix the distribution for the transient cause: $$ x_{transient} \sim Beta(0.01, 100)$$.
(Here we use the mean--concentration parameterization of the Beta distribution rather than the canonical pseudocount parameterization. The first parameter is the mean of the distribution while the second is the concentration --- or inverse-variance --- of the distribution.)

What we plausibly can vary between contexts is the distribution for $$x_{stable} \sim Beta(\gamma, \delta)$$.
We also can vary how prevalent each component or sub-distribution is, by a parameter $$\phi$$.

Thus, the prior over $$x$$ is a mixture distribution:

$$
x \sim \phi \cdot \text{Beta}(\gamma, \delta) + (1 - \phi) \cdot \text{Beta}(0.01, 100)
$$

where $$\gamma$$ is the mean of the stable cause distribution and $$\delta$$ is the "concentration" (or, inverse-variance) of this distribution. $$\delta$$ is high for properties that present in almost every kind in exactly the same proportion (e.g. "is female"). It is lower when there is more uncertainty about exactly how many within a kind are expected to have the property.


<!-- $$\phi$$ is a parameter that governs mixture between these two components.
 For example, "is female" has a high `phi` to be present in a kind; while "lays eggs" has less potential (owing to the fact that a lot of animals do not have any members who lay eggs). "Carries malaria" has a very low potential to be present. `prevalenceWhenPresent` is the *mean prevalence when the property is present*. Knowing that the property is present in a kind, what % of the kind do you expect to have it? -->

These two components of the prior can be probed from human intuitions through two questions:

> We just discovered an animal on a far away island called a fep.

> 1. How likely is it that there is a *fep* that has wings? ($$\rightarrow \phi$$)
> 2. Suppose there is a fep that has wings, what % of feps do you think have wings? ($$\rightarrow \gamma; \rightarrow \delta$$)

(Run through your intuitions with other properties like "is female", or "lays eggs".)

The following model `priorModel` formalizes the above ideas computationally:

~~~~
///fold:
// discretized range between 0 - 1
var bins = _.range(0.01, 1, 0.025);

// function returns a discretized Beta distribution
var DiscreteBeta = cache(function(g, d){
  var a =  g * d, b = (1-g) * d;
  var betaPDF = function(x){
    return Math.pow(x, a-1)*Math.pow((1-x), b-1)
  }
  var probs = map(betaPDF, bins);
  return Categorical({vs: bins, ps: probs})
})
///
var priorModel = function(params){
  Infer({model: function(){

    var StableDistribution = DiscreteBeta(params.g, params.d)
    var UnstableDistribution = DiscreteBeta(0.01, 100)

    var x = flip(params.phi) ?
      sample(StableDistribution) :
      sample(UnstableDistribution)

    return {x}

  }})
}

// e.g. "Has Wings"
viz(priorModel({
  phi: 0.3,
  g: 0.99, // how prevalent under the stable cause
  d: 10    // the inverse-variance of the stable cause
}))
~~~~

> **Exercises:**

> 1. What does this picture represent? If you drew a sample from this distribution, what would that correspond to?
> 2. Try to think up a property for which the three parameters above are not able to give even a remotely plausible distribution. (If you succeed, let us know; the idea is that this parameterization is sufficient to capture---in approximation---any case of relevance.)

### Generics model

The model assumes a simple (the simplest?) meaning for a generic statement: a threshold on the probability.

~~~~
///fold:
// discretized range between 0 - 1
var bins = map(function(x){
  _.round(x, 2);
},  _.range(0.01, 1, 0.02));

var thresholdBins = map2(function(x,y){
  var d = (y - x)/ 2;
  return x + d
}, bins.slice(0, bins.length - 1), bins.slice(1, bins.length))

// function returns a discretized Beta distribution
var DiscreteBeta = cache(function(g, d){
  var a =  g * d, b = (1-g) * d;
  var betaPDF = function(x){
    return Math.pow(x, a-1)*Math.pow((1-x), b-1)
  }
  var probs = map(betaPDF, bins);
  return Categorical({vs: bins, ps: probs})
})
///
var priorModel = function(params){
  Infer({model: function(){

    var StableDistribution = DiscreteBeta(params.g, params.d)
    var UnstableDistribution = DiscreteBeta(0.01, 100)

    var x = flip(params.phi) ?
      sample(StableDistribution) :
      sample(UnstableDistribution)

    return {x}

  }})
}
///

var utterances = ["generic", "silence"];

var thresholdPrior = function() { return uniformDraw(thresholdBins) };
var utterancePrior = function() { return uniformDraw(utterances) };

var meaning = function(utterance, x, threshold) {
  return (utterance == 'generic') ? x > threshold : true
}

var threshold = thresholdPrior()

print(threshold)
meaning("generic", 0.5, threshold)
~~~~

Since we have a prior and a meaning function, we are ready to implement RSA. For the speaker utterances, we use only the alternative of staying silent. Staying silent is a null utterance that has no information content. The inclusion of the null utterance turns the generic into a speech-act, and is useful for evaluating the meaning of an utterance without competition of alternatives.

~~~~
///fold:
// discretized range between 0 - 1
var bins = map(function(x){
  _.round(x, 2);
},  _.range(0.01, 1, 0.02));

var thresholdBins = map2(function(x,y){
  var d = (y - x)/ 2;
  return x + d
}, bins.slice(0, bins.length - 1), bins.slice(1, bins.length))

// function returns a discretized Beta distribution
var DiscreteBeta = cache(function(g, d){
  var a =  g * d, b = (1-g) * d;
  var betaPDF = function(x){
    return Math.pow(x, a-1)*Math.pow((1-x), b-1)
  }
  var probs = map(betaPDF, bins);
  return Categorical({vs: bins, ps: probs})
})

var priorModel = function(params){
  Infer({model: function(){

    var StableDistribution = DiscreteBeta(params.g, params.d)
    var UnstableDistribution = DiscreteBeta(0.01, 100)
    var x = flip(params.phi) ?
      sample(StableDistribution) :
      sample(UnstableDistribution)

    return x
  }})
}
///

var alpha_1 = 5;

var utterances = ["generic", "silence"];

var thresholdPrior = function() { return uniformDraw(thresholdBins) };
var utterancePrior = function() { return uniformDraw(utterances) }

var meaning = function(utterance, x, threshold) {
  return (utterance == 'generic') ? x > threshold : true
}

var literalListener = cache(function(utterance, threshold, statePrior) {
  Infer({model: function(){
    var x = sample(statePrior)
    var m = meaning(utterance, x, threshold)
    condition(m)
    return x
  }})
})

var speaker1 = cache(function(x, threshold, statePrior) {
  Infer({model: function(){
    var utterance = utterancePrior()
    var L0 = literalListener(utterance, threshold, statePrior)
    factor( alpha_1 * L0.score(x) )
    return utterance
  }})
})

var pragmaticListener = function(utterance, statePrior) {
  Infer({model: function(){
    var x = sample(statePrior)
    var threshold = thresholdPrior()
    var S1 = speaker1(x, threshold, statePrior)
    observe(S1, utterance)
    return {x}
  }})
}

var prior = priorModel({
  phi: 0.3,
  g: 0.99,
  d: 10
})

var listenerPosterior = pragmaticListener("generic", prior)

viz(listenerPosterior)
~~~~

> **Exercises:**
>
> 1. Test the pragmatic listener's interpretations of *Wugs carry malaria*.
> 2. Test the pragmatic listener's interpretations of *Wugs lay eggs*.
> 3. Test the pragmatic listener's interpretations of *Wugs are female*.

So we have a model that can interpret generic language (with a very simple semantics). We can now imagine a speaker who thinks about this type of listener, and decides if a generic utterance is a good thing to say. Speaker models are interpreted as models of utterance production, or endorsement (reft:DegenGoodman2014Cogsci; reft:Franke2014). If we specify the alternative utterance to be a *null* utterance (or, *silence*), we model the choice between uttering the generic (i.e., endorsing its truth) or nothing at all (i.e., not endorsing its truth). (Note: You could also think about truth judgments with the alternative of saying the negation, e.g., it's not the case that Ks have F. Model behavior is very similar using that alternative in this case.)

~~~~
///...

var speaker1 = function(state, threshold) {
  Infer({model: function(){
    var utterance = utterancePrior()

    var L0 = literalListener(utterance, threshold)
    factor( alpha_1 * L0.score(state) )

    return utterance
  }})
}

///...

var speaker2 = function(state){
  Infer({model: function(){
    var utterance = utterancePrior()

    var L1 = pragmaticListener(utterance);  
    factor( alpha_2 * L1.score(state) )

    return utterance
  }})
}
~~~~

Let's add speaker2 into the full model.

~~~~
///fold:
// discretized range between 0 - 1
var bins = map(function(x){
  _.round(x, 2);
},  _.range(0.01, 1, 0.02));

var thresholdBins = map2(function(x,y){
  var d = (y - x)/ 2;
  return x + d
}, bins.slice(0, bins.length - 1), bins.slice(1, bins.length))

// function returns a discretized Beta distribution
var DiscreteBeta = cache(function(g, d){
  var a =  g * d, b = (1-g) * d;
  var betaPDF = function(x){
    return Math.pow(x, a-1)*Math.pow((1-x), b-1)
  }
  var probs = map(betaPDF, bins);
  return Categorical({vs: bins, ps: probs})
})

var priorModel = function(params){
  Infer({model: function(){

    var StableDistribution = DiscreteBeta(params.g, params.d)
    var UnstableDistribution = DiscreteBeta(0.01, 100)
    var x = flip(params.phi) ?
        sample(StableDistribution) :
    sample(UnstableDistribution)

    return x
  }})
}
///

var alpha_1 = 5;
var alpha_2 = 1;
var utterances = ["generic", "silence"];

var thresholdPrior = function() { return uniformDraw(thresholdBins) };
var utterancePrior = function() { return uniformDraw(utterances) }

var meaning = function(utterance, x, threshold) {
  return (utterance == 'generic') ? x > threshold : true
}

var literalListener = cache(function(utterance, threshold, statePrior) {
  Infer({model: function(){
    var x = sample(statePrior)
    var m = meaning(utterance, x, threshold)
    condition(m)
    return x
  }})
})

var speaker1 = cache(function(x, threshold, statePrior) {
  Infer({model: function(){
    var utterance = utterancePrior()
    var L0 = literalListener(utterance, threshold, statePrior)
    factor( alpha_1 * L0.score(x) )
    return utterance
  }})
})

var pragmaticListener = function(utterance, statePrior) {
  Infer({model: function(){
    var x = sample(statePrior)
    var threshold = thresholdPrior()
    var S1 = speaker1(x, threshold, statePrior)
    observe(S1, utterance)
    return x
  }})
}

var speaker2 = function(x, statePrior){
  Infer({model: function(){
    var utterance = utterancePrior();
    var L1 = pragmaticListener(utterance, statePrior);
    factor( alpha_2 * L1.score(x) )
    return utterance
  }})
}

var target_x = 0.03

var prior = priorModel({
  phi: 0.01,
  g: 0.01,
  d: 5
})

viz.density(prior)

viz(speaker2(target_x, prior))
~~~~

> **Exercises:**

> 1. Test *Birds lay eggs* vs. *Birds are female*. (Technical note: Due to the discretization of the state space, `target_x` must take odd-numbered values such as 0.03, 0.05, 0.09, ... )
> 2. Come up with other generic sentences. Hypothesize what the prior might be, and what the prevalence might be, and test the model on it.


#### Extension: Generics with gradable adjectives


First, a world with entities.

~~~~
var altBeta = function(g, d){
  var a =  g * d;
  var b = (1-g) * d;
  return beta(a, b)
}

var fep = function() {
  return {
    kind: "fep",
    wings: flip(0.5),
    legs: flip(0.01),
    claws: flip(0.01),
    height: altBeta(0.5, 10)
  }
}

var wug = function() {
  return {
    kind: "wug",
    wings: flip(0.5),
    legs: flip(0.99),
    claws: flip(0.3),
    height: altBeta(0.2, 10)
  }
}

var glippet = function() {
  return {
    kind: "glippet",
    wings: flip(0.5),
    legs: flip(0.99),
    claws: flip(0.2),
    height: altBeta(0.8, 10)
  }
}

var theWorld = _.flatten([repeat(10, fep), repeat(10, wug), repeat(10, glippet)])

var kinds = _.uniq(_.map(theWorld, "kind"));

print('height distribution over all creatures')
viz.density(_.map(theWorld, "height"))

var rs = map(function(k){
  print('height distribution for ' + k)
  viz.density(_.map(_.filter(theWorld,{kind: k}), "height"), {bounds:[0,1]})
}, kinds)

print('')
~~~~

Now, let's calculate prevalence distributions. These will be somewhat boring because there are only 3 kinds of creatures in this world.


~~~~
/// fold:
var round = function(x){
  var rounded = Math.round(10*x)/10
  return rounded == 0 ? 0.01 : rounded
}

var makeHistogram = function(prevalences){
  return map(function(s){
    return reduce(function(x, i){
      var k = x == s ? 1 : 0
      return i + k
    }, 0.001, prevalences)
  }, stateBins)
}

var altBeta = function(g, d){
  var a =  g * d;
  var b = (1-g) * d;
  return beta(a, b)
}

var fep = function() {
  return {
    kind: "fep",
    wings: flip(0.5),
    legs: flip(0.01),
    claws: flip(0.01),
    height: altBeta(0.5, 10)
  }
}

var wug = function() {
  return {
    kind: "wug",
    wings: flip(0.5),
    legs: flip(0.99),
    claws: flip(0.3),
    height: altBeta(0.2, 10)
  }
}

var glippet = function() {
  return {
    kind: "glippet",
    wings: flip(0.5),
    legs: flip(0.99),
    claws: flip(0.2),
    height: altBeta(0.8, 10)
  }
}
///
var stateBins = [0.01,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1]

var theWorld = _.flatten([repeat(10, fep), repeat(10, wug), repeat(10, glippet)])

var allKinds = _.uniq(_.map(theWorld, "kind"))

var prevalence = function(world, kind, property){
  var members = _.filter(world, {kind: kind})
  return round(listMean(_.map(members, property)))
}

var prevalencePrior = function(property, world){
  var p =  map(function(k){return prevalence(world, k, property)}, allKinds)
  return makeHistogram(p)
}

viz.bar(stateBins, prevalencePrior("legs", theWorld))
~~~~

With individuals in the world, the extended model evaluates generics with gradable adjectives (e.g., *giraffes are tall*) by first checking to see how many of a relevent subset of the kind could truthfully be described to hold the property *at the individual level*, and then using this information to infer the prevalence of the property in the kind. With prevalence in hand, the model proceeds as before.

~~~~
///fold:
// discretized range between 0 - 1
var stateBins = [0.01,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1]
var thresholdBins = [0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9]
var alpha_1 = 5

var round = function(x){
  var rounded = Math.round(10*x)/10
  return rounded == 0 ? 0.01 : rounded
}

var makeHistogram = function(prevalences){
  return map(function(s){
    return reduce(function(x, i){
      var k = x == s ? 1 : 0
      return i + k
    }, 0.001, prevalences)
  }, stateBins)
}

var altBeta = function(g, d){
  var a =  g * d;
  var b = (1-g) * d;
  return beta(a, b)
}

var fep = function() {
  return {
    kind: "fep",
    wings: flip(0.5),
    legs: flip(0.01),
    claws: flip(0.01),
    height: round(altBeta(0.5, 10))
  }
}

var wug = function() {
  return {
    kind: "wug",
    wings: flip(0.5),
    legs: flip(0.99),
    claws: flip(0.3),
    height: round(altBeta(0.2, 10))
  }
}

var glippet = function() {
  return {
    kind: "glippet",
    wings: flip(0.5),
    legs: flip(0.99),
    claws: flip(0.2),
    height: round(altBeta(0.8, 10))
  }
}
///

var theWorld = _.flatten([repeat(10, fep), repeat(10, wug), repeat(10, glippet)])
var allKinds = _.uniq(_.map(theWorld, "kind"))

var propertyDegrees = {
  wings: "wings",
  legs: "legs",
  claws: "claws",
  tall:" height"
}


var prevalence = function(world, kind, property){
  var members = _.filter(world, {kind: kind})
  return round(listMean(_.map(members, property)))
}

var prevalencePrior = function(property, world){
  var p =  map(function(k){return prevalence(world, k, property)}, allKinds)
  return makeHistogram(p)
}

var scalePrior = function(property){
  var p = _.map(theWorld, property)
  return makeHistogram(p)
}

var statePrior = function(probs){ return categorical(probs, stateBins) }
var thresholdPrior = function() { return uniformDraw(thresholdBins) }

var utterancePrior = function(scale) {
  var utterances = scale == "height" ?
      ["tall", "null"] :
      ["generic", "null"]
  return uniformDraw(utterances)
}

var meaning = function(utt, state, threshold) {
  return utt == "generic" ? state > threshold :
  utt == "tall" ? state > threshold :
  true
}

var literalListener = cache(function(utterance, threshold, stateProbs) {
  Infer({method: "enumerate"}, function(){
    var state = statePrior(stateProbs)
    var m = meaning(utterance, state, threshold)
    condition(m)
    return state
  })
})

var speaker1 = cache(function(state, threshold, stateProbs, predicate) {
  Infer({method: "enumerate"}, function(){
    var utterance = utterancePrior(predicate)
    var L0 = literalListener(utterance, threshold, stateProbs)
    factor(alpha_1 * L0.score(state))
    return utterance

  })
})

var pragmaticListener = cache(function(utterance, scale, world) {
  Infer({method: "enumerate"}, function(){
    var stateProbs = scale == "height" ?
        scalePrior(scale) :
    prevalencePrior(scale, world)
    var state = statePrior(stateProbs)
    var threshold = thresholdPrior()
    var S1 = speaker1(state, threshold, stateProbs, scale)
    observe(S1, utterance)
    return state
  })
})

var worldWithTallness = map(function(thing){
  var tallDistribution = Infer({method: "enumerate"}, function(){
    var utterance = utterancePrior("height")
    factor(pragmaticListener(utterance, "height").score(thing.height))
    return utterance
  })
  return _.extend(thing,
                  {tall: Math.exp(tallDistribution.score("tall"))})
}, theWorld)

var speaker2 = function(k, f){
  Infer({method: "enumerate"}, function(){
    var property = f.split(' ')[1]
    var degree = propertyDegrees[property]
    var world = _.isNumber(theWorld[0][degree]) ?
        worldWithTallness :
    theWorld
    var prev = prevalence(world, k, property)
    var utterance = utterancePrior(property)

    var L1 = pragmaticListener(utterance, property, world)
    factor(2*L1.score(prev))

    return utterance=="generic" ?
      k + "s " + f :
    "don't think so"
  })
}

viz.auto(speaker2("glippet", "are tall"))
~~~~

References:

- Cite:tessler2016manuscript
- Cite:Franke2014
- Cite:DegenGoodman2014Cogsci
