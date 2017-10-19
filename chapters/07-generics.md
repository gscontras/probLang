---
layout: chapter
title: Extending our models of predication
description: "Generic language"
---

### Chapter 7: Generic language 

## The philosophical problem

Generic language (e.g., *Swans are white.*) is a simple and ubiquitous way to communicate generalizations about categories.  Linguists, philosophers, and psychologists have scratched their collective heads for decades, trying to figure out what makes a generic sentence true or false. At first glance, generics feel like universally-quantified statements, as in *All swans are white*.  Unlike universals, however, generics are resilient to counter-examples (e.g., *Swans are white* even though there are black swans).  Our intuitions then fall back to something more vague like *Swans, in general, are white* because indeed most swans are white. But mosquitos, in general, do not carry malaria, yet everyone agrees *Mosquitos carry malaria*.

Indeed, it appears that any truth conditions stated in terms of how common the property is within the kind violates intuitions. Consider the birds: for a bird, being female practically implies you will lay eggs (the properties are present in the same proportion), yet we say things like *Birds lay eggs* and we do not say things like *Birds are female*.

reft:tessler2016manuscript propose that the core meaning of a generic statement is simple, but underspecified, and that general principles of communication may be used to resolve precise meaning in context. In particular, they developed a model that describes pragmatic reasoning about the degree of prevalence required to assert the generic.

#### A pragmatic model of generic language

The model takes the generic $$[\![\text{K has F}]\!]$$ to mean the prevalence of property F within kind K (i.e., $$P(F \mid K)$$) is above some threshold (cf. Cohen 1999). Quantifiers can be described as conditions on prevalence: $$[\![\text{some}]\!] := P(F \mid K) > 0 $$, $$[\![\text{all}]\!] := P(F \mid K) = 1$$. But for the generic, no fixed value of the threshold would suffice. Instead, we leave the threshold underspecified in the semantics (`threshold = uniform(0,1)`) and infer it in context.

Context here takes the form of the listener's and speaker's shared beliefs about the property in question. The shape of this distribution affects the listener's interpretation, because the threshold must be calibrated to make utterances truthful and informative. The shape of this distribution varies significantly among different properties (e.g., *lays eggs*, *carries malaria*), and may be the result of a deeper conceptual model of the world. For instance, if speakers and listeners believe that some kinds have a causal mechanism that *could* give rise to the property, while others do not, then we would expect the prior to be structured as a mixture distribution (cf. Griffiths & Tenenbaum, 2005). 

First, let's try to understand the prior.

#### Prior model

The following model `structuredPriorModel` formalizes the idea that some kinds have a mechanism that *could* give rise to the property, while other do not. `potential` is a mixture parameter that governs the property's potential to be present in a kind (or, the frequency of a property across kinds). For example, "is female" has a high potential to be present in a kind; while "lays eggs" has less potential (owing to the fact that a lot of animals do not have any members who lay eggs). "Carries malaria" has a very low potential to be present. `prevalenceWhenPresent` is the *mean prevalence when the property is present*. Knowing that the property is present in a kind, what % of the kind do you expect to have it? 


These two components of the prior can be probed from human intuitions through two questions:

> We just discovered an animal on a far away island called a fep.

> 1. How likely is it that there is a *fep* that has wings?
> 2. Suppose there is a fep that has wings, what % of feps do you think have wings? 

(Run through your intuitions with other properties like "is female", or "lays eggs".)


Finally, `concentrationWhenPresent` is the concentration (conceptually, the inverse of variance) of that prevalence when present. It is high for properties that present in almost every kind in exactly the same proportion (e.g. "is female"). It is lower when there is more uncertainty about exactly how many within a kind are expected to have the property.

~~~~
///fold:
// discretized range between 0 - 1
var bins = _.range(0.01, 1, 0.025);
///

// function returns a discretized Beta PDF
var discretizeBeta = function(g, d){
  var shape_alpha =  g * d
  var shape_beta = (1-g) * d
  var betaPDF = function(x){
    return Math.pow(x,shape_alpha-1)*Math.pow((1-x),shape_beta-1)
  }
  return map(betaPDF, bins)
}

var structuredPriorModel = function(params){
  Infer({method: "enumerate"}, function(){

    // unpack parameters
    var potential = params["potential"]
    var g = params["prevalenceWhenPresent"]
    var d = params["concentrationWhenPresent"]
    
    var propertyIsPresent = flip(potential)
    var prevalence = propertyIsPresent ? 
          categorical(discretizeBeta(g,d), bins) : 
          0

    return {prevalence: prevalence}
  })
}

// e.g. "Has Wings"
viz.auto(structuredPriorModel({
  potential: 0.3, 
  prevalenceWhenPresent: 0.99, 
  concentrationWhenPresent: 10
}))
~~~~

> **Exercises:**

> 1. What does this picture represent? If you drew a sample from this distribution, what (in the world) would that correspond to?
> 2. Try to construct priors for other properties. Some possibilities include: lays eggs, are female, carry malaria, attack swimmers, are full-grown. Or choose your favorite property.

#### Generics model

The model assumes a simple (the simplest?) meaning for a generic statement: a threshold on prevalence. 

~~~~
///fold:
// discretized range between 0 - 1
var bins = _.range(0.01, 1, 0.025);
var thresholdBins = _.range(0, 1, 0.025);

// function returns a discretized Beta PDF
var discretizeBeta = function(g, d){
  var shape_alpha =  g * d
  var shape_beta = (1-g) * d
  var betaPDF = function(x){
    return Math.pow(x,shape_alpha-1)*Math.pow((1-x),shape_beta-1)
  }
  return map(betaPDF, bins)
}

var structuredPriorModel = function(params){
  Infer({method: "enumerate"}, function(){

    // unpack parameters
    var potential = params["potential"]
    var g = params["prevalenceWhenPresent"]
    var d = params["concentrationWhenPresent"]
    
    var propertyIsPresent = flip(potential)
    var prevalence = propertyIsPresent ? 
          categorical(discretizeBeta(g,d), bins) : 
          0

    return prevalence
  })
}
///

var utterances = ["generic", "silence"];

var thresholdPrior = function() { return uniformDraw(thresholdBins) };
var utterancePrior = function() { return uniformDraw(utterances) };

var meaning = function(utterance, state, threshold) {
  return (utterance == 'generic') ? state > threshold : true
}

var threshold = thresholdPrior()

print(threshold)
meaning("generic", 0.5, threshold)
~~~~

Since we have a prior and a meaning function, we are ready to implement RSA. For the speaker utterances, we use only the alternative of staying silent. Staying silent is a null utterance that has no information content. The inclusion of the null utterance turns the generic into a speech-act, and is useful for evaluating the meaning of an utterance without competition of alternatives.

~~~~
///fold:
// discretized range between 0 - 1
var bins = _.range(0.01, 1, 0.025);
var thresholdBins = _.range(0, 1, 0.025);

// function returns a discretized Beta PDF
var discretizeBeta = function(g, d){
  var shape_alpha =  g * d
  var shape_beta = (1-g) * d
  var betaPDF = function(x){
    return Math.pow(x,shape_alpha-1)*Math.pow((1-x),shape_beta-1)
  }
  return map(betaPDF, bins)
}

var structuredPriorModel = function(params){
  Infer({method: "enumerate"}, function(){

    // unpack parameters
    var potential = params["potential"]
    var g = params["prevalenceWhenPresent"]
    var d = params["concentrationWhenPresent"]
    
    var propertyIsPresent = flip(potential)
    var prevalence = propertyIsPresent ? 
          categorical(discretizeBeta(g,d), bins) : 
          0

    return prevalence
  })
}
///

var alpha_1 = 5;

var utterances = ["generic", "silence"];

var thresholdPrior = function() { return uniformDraw(thresholdBins) };
var utterancePrior = function() { return uniformDraw(utterances) }

var meaning = function(utterance, state, threshold) {
  return (utterance == 'generic') ? state > threshold : true
}

var literalListener = cache(function(utterance, threshold, statePrior) {
  Infer({method: "enumerate"}, function(){
    var state = sample(statePrior)
    var m = meaning(utterance, state, threshold)
    condition(m)
    return state
  })
})

var speaker1 = cache(function(state, threshold, statePrior) {
  Infer({method: "enumerate"}, function(){
    var utterance = utterancePrior()
    var L0 = literalListener(utterance, threshold, statePrior)
    factor( alpha_1*L0.score(state) )
    return utterance
  })
})

var pragmaticListener = function(utterance, statePrior) {
  Infer({method: "enumerate"}, function(){
    var state = sample(statePrior)
    var threshold = thresholdPrior()
    var S1 = speaker1(state, threshold, statePrior)
    observe(S1, utterance)
    return {prevalence: state}
  })
}

// "Feps have wings."
var hasWingsPrior = structuredPriorModel({
  potential: 0.3, 
  prevalenceWhenPresent: 0.99, 
  concentrationWhenPresent: 10
})
                    
var fepsHaveWings = pragmaticListener("generic", hasWingsPrior);
print("Listener interpretation of 'feps have wings'")
viz.auto(fepsHaveWings)

// "Wugs carry malaria."
var carriesMalariaPrior = structuredPriorModel({
  potential: 0.01, 
  prevalenceWhenPresent: 0.1, 
  concentrationWhenPresent: 5
})

var fepsCarryMalaria = pragmaticListener("generic", carriesMalariaPrior);
print('Listener interpretation of "wugs carry malaria"')
viz.auto(fepsCarryMalaria)

~~~~

> **Exercise:** Test the pragmatic listener's interpretations of generics about different properties (hence, different priors).

So we have a model that can interpret generic language (with a very simple semantics). We can now imagine a speaker who thinks about this type of listener, and decides if a generic utterance is a good thing to say. Speaker models are interpreted as models of utterance production, or endorsement (reft:DegenGoodman2014Cogsci). If we specify the alternative utterance to be a *null* utterance (or, *silence*), we model the choice between uttering the generic (i.e., endorsing its truth) or nothing at all (i.e., not endorsing its truth). (Note: You could also think about truth judgments with the alternative of saying the negation, e.g., it's not the case that Ks have F. Model behavior is very similar using that alternative in this case.)

~~~~
///...

var speaker1 = cache(function(state, threshold) {
  Infer({method: "enumerate"}, function(){
    var utterance = utterancePrior()
    
    var L0 = literalListener(utterance, threshold)
    factor( alpha_1*L0.score(state) )
    
    return utterance
  })
})

///...

var speaker2 = function(state){
  Infer({method: "enumerate"}, function(){
    var utterance = utterancePrior()

    var L1 = pragmaticListener(utterance);  
    factor( alpha_2 * L1.score(state) )
  
    return utterance
  })
}
~~~~

Let's add speaker2 into the full model.

~~~~
///fold:
var round = function(x){
  return Math.round(100*x)/100
}

// discretized range between 0 - 1
var bins = map(round,_.range(0.01, 1, 0.025));
var thresholdBins = _.range(0, 1, 0.025);

// function returns a discretized Beta PDF
var discretizeBeta = function(g, d){
  var shape_alpha =  g * d
  var shape_beta = (1-g) * d
  var betaPDF = function(x){
    return Math.pow(x,shape_alpha-1)*Math.pow((1-x),shape_beta-1)
  }
  return map(betaPDF, bins)
}

var structuredPriorModel = function(params){
  Infer({method: "enumerate"}, function(){

    // unpack parameters
    var potential = params["potential"]
    var g = params["prevalenceWhenPresent"]
    var d = params["concentrationWhenPresent"]
    
    var propertyIsPresent = flip(potential)
    var prevalence = propertyIsPresent ? 
          categorical(discretizeBeta(g,d), bins) : 
          0

    return prevalence
  })
}

var alpha_1 = 5;
var alpha_2 = 1;

var thresholdPrior = function() { return uniformDraw(thresholdBins) };

var utterancePrior = function() {
  var utterances = ["generic", "silence"];
  return uniformDraw(utterances);
}

var meaning = function(utt,state, threshold) {
  return utt == 'generic' ? state > threshold :
         true
}

var literalListener = cache(function(utterance, threshold, statePrior) {
  Infer({method: "enumerate"}, function(){
    var state = sample(statePrior)
    var m = meaning(utterance, state, threshold)
    condition(m)
    return state
  })
})

var speaker1 = cache(function(state, threshold, statePrior) {
  Infer({method: "enumerate"}, function(){
    var utterance = utterancePrior()
    var L0 = literalListener(utterance, threshold, statePrior)
    factor( alpha_1*L0.score(state) )
    return utterance
  })
})
///

var pragmaticListener = cache(function(utterance, statePrior) {
  Infer({method: "enumerate"}, function(){
    var state = sample(statePrior);
    var threshold = thresholdPrior();
    var S1 = speaker1( state, threshold, statePrior );
    observe(S1, utterance);
    return state
  })
})

var speaker2 = function(state, statePrior){
  Infer({method: "enumerate"}, function(){
    var utterance = utterancePrior();
    var L1 = pragmaticListener(utterance, statePrior);
    factor( alpha_2 * L1.score(state) )
    return utterance
  })
}

var prevalence = 0.01

var carriesMalariaPrior = structuredPriorModel({
  potential: 0.01, 
  prevalenceWhenPresent: 0.01, 
  concentrationWhenPresent: 5
})

print('Prior on "carries malaria"')
viz.density(carriesMalariaPrior)

print('Truth judgment of "Mosquitos carry malaria"')
print('...assuming (the speaker believes) ' + prevalence * 100 + '% of mosquitos carry malaria.')
viz.auto(speaker2(prevalence, carriesMalariaPrior))

~~~~

> **Exercises:**

> 1. Test *Birds lay eggs* vs. *Birds are female*. (Note: The prevalence levels used as input to the speaker can only take values to the 0.01 decimal place. In addition, not all prevalence levels are available in this discretized prevalence space. If you get an error, try to +/- 0.01).
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

var utterancePrior = function(property) {
  var utterances = property == "height" ? 
      ["tall", "null"] :
  ["generic", "null"]
  return uniformDraw(utterances)
}

var meaning = function(utterance, state, threshold) {
  return utterance == "generic" ? state > threshold :
  utterance == "tall" ? state > threshold :
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

var speaker1 = cache(function(state, threshold, stateProbs, property) {
  Infer({method: "enumerate"}, function(){
    var utterance = utterancePrior(property)
    var L0 = literalListener(utterance, threshold, stateProbs)
    factor(alpha_1 * L0.score(state))
    return utterance

  })
})

var pragmaticListener = cache(function(utterance, property, world) {
  Infer({method: "enumerate"}, function(){
    var stateProbs = property == "height" ? 
        scalePrior(property) : 
    prevalencePrior(property, world)
    var state = statePrior(stateProbs)
    var threshold = thresholdPrior()
    var S1 = speaker1(state, threshold, stateProbs, property)
    observe(S1, utterance)
    return state
  })
})

var worldWithTallness = map(function(individual){
  var tallDistribution = Infer({method: "enumerate"}, function(){
    var utterance = utterancePrior("height")
    factor(pragmaticListener(utterance, "height").score(individual.height))
    return utterance
  })
  return _.extend(individual, 
                  {tall: Math.exp(tallDistribution.score("tall"))})
}, theWorld)

var speaker2 = function(kind, predicate){
  Infer({method: "enumerate"}, function(){
    var property = predicate.split(' ')[1]
    var degree = propertyDegrees[property]
    var world = _.isNumber(theWorld[0][degree]) ? 
        worldWithTallness : theWorld
    var prev = prevalence(world, kind, property)
    var utterance = utterancePrior(property)

    var L1 = pragmaticListener(utterance, property, world)
    factor(2*L1.score(prev))

    return utterance=="generic" ? 
      kind + "s " + predicate :
    "don't think so"
  })
}

viz.auto(speaker2("glippet", "are tall"))

~~~~

References:

- Cite:tessler2016manuscript
- Cite:DegenGoodman2014Cogsci
