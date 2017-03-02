---
layout: chapter
title: Inferring the Question-Under-Discussion
description: "Non-literal language"
---

### Chapter 3: Non-literal language

<!--   - Building the literal interpretations
  - Compositional mechanisms and semantic types
    - Functional Application; Predicate Modification 
  - The compositional semantics example from DIPPL -->


#### Application 1: Hyperbole and the Question Under Discussion

If you hear that someone waited "a million years" for a table at a popular restaurant or paid "a thousand dollars" for a coffee at a hipster hangout, you are unlikely to conclude that the improbable literal meanings are true. Instead, you conclude that the diner waited a long time, or paid an exorbitant amount of money, *and that she is frustrated with the experience*. Whereas blue circles are compatible with the literal meaning of "blue," five-dollar coffees are not compatible with the literal meaning of "a thousand dollars." How, then, do we arrive at sensible interpretations when our words are literally false?

reft:kaoetal2014 propose that we model hyperbole understanding as pragmatic inference. Crucially, they propose that we recognize uncertainty about **communicative goals**: what Question Under Discussion (QUD) a speaker is likely addressing with their utterance. To capture cases of hyperbole, Kao et al. observe that speakers are likely communicating---at least in part---about their attitude toward a state of the world (i.e., the valence of their *affect*). QUDs are modeled as summaries of the full world states, which take into account both state and valence (a binary positive/negative variable) information:

~~~~
///fold:
// Round x to nearest multiple of b (used for approximate interpretation):
var approx = function(x,b) {
  return b * Math.round(x / b)
};
///

var qudFns = {
  state : function(state, valence) {return {state: state} },
  valence : function(state, valence) {return {valence: valence} },
  stateValence : function(state, valence) {return {state: state, valence: valence} },
  approxState : function(state, valence) {return {state: approx(state, 10) } },
};

print("QUD values for state (i.e., price)=51, valence (i.e., is annoyed?) = true")

print("valence QUD")
var fun = qudFns["valence"]
print(fun(51, true))

print("state QUD")
var fun = qudFns["state"]
print(fun(51, true))

print("stateValence QUD")
var fun = qudFns["stateValence"]
print(fun(51, true))

print("approxState QUD")
var fun = qudFns["approxState"]
print(fun(51, true))
~~~~


The literal listener infers the answer to the QUD, assuming that the utterance he hears is true of the state. In the full version, Kao et al. model liteners' reactions to statements about the price of electric kettles. They empirically estimate the prior knowledge people carry about kettle prices, as well as the probility of getting upset (i.e., experiencing a negatively-valenced affect) in response to a given price.

~~~~
///fold:
// Round x to nearest multiple of b (used for approximate interpretation):
var approx = function(x,b) {
  return b * Math.round(x / b)
};
///

// Define list of kettle prices under consideration (possible price states)
var states = [50, 51, 500, 501, 1000, 1001, 5000, 5001, 10000, 10001];

// Prior probability of kettle prices (taken from human experiments)
var statePrior = function() {
  return categorical([0.4205, 0.3865, 0.0533, 0.0538, 0.0223, 0.0211, 0.0112, 0.0111, 0.0083, 0.0120],
                     states)
};

// Probability that given a price state, the speaker thinks it's too
// expensive (taken from human experiments)
var valencePrior = function(state) {
  var probs = {
    50 : 0.3173,
    51 : 0.3173, 
    500 : 0.7920,
    501 : 0.7920, 
    1000 : 0.8933,
    1001 : 0.8933,
    5000 : 0.9524,
    5001 : 0.9524,
    10000 : 0.9864,
    10001 : 0.9864
  }
  var tf = flip(probs[state]);
  return tf
};

var qudFns = {
  state : function(state, valence) {return {state: state} },
  valence : function(state, valence) {return {valence: valence} },
  stateValence : function(state, valence) {return {state: state, valence: valence} },
  approxState : function(state, valence) {return {state: approx(state, 10) } },
};

// Literal interpretation "meaning" function; 
// checks if uttered number reflects price state
var meaning = function(utterance, state) {
  return utterance == state;
};


var literalListener = cache(function(utterance, qud) {
  return Infer({method : "enumerate"},
               function() {

    var state = statePrior() // uncertainty about the state
    var valence = valencePrior(state) // uncertainty about the valence
    var qudFn = qudFns[qud]

    condition(meaning(utterance,state))

    return qudFn(state,valence)
  })
});
~~~~

> **Exercises:** 

> 1. Suppose the literal listener hears the kettle costs `10000` dollars with the `"stateValence"` QUD. What does it infer?
> 2. Test out other QUDs. What aspects of interpretation does the literal listener capture? What aspects does it not capture?
> 3. Create a new QUD function and try it out with "the kettle costs `10000` dollars".

This enriched literal listener does a joint inference about the state and the valence but assumes a particular QUD by which to interpret the utterance. Similarly, the speaker chooses an utterance to convey a particular value of the QUD to the literal listener:

~~~~
var speaker = cache(function(qValue, qud) {
  return Infer({method : "enumerate"},
               function() {
    var utterance = utterancePrior()
    factor(alpha * literalListener(utterance,qud).score(qValue))
    return utterance
  })
});
~~~~

To model hyperbole, Kao et al. posited that the pragmatic listener actually has uncertainty about what the QUD is, and jointly infers the world state (and speaker valence) and the intended QUD from the utterance he receives. That is, the pragmatic listener simulates how the speaker would behave with various QUDs.

~~~~
var pragmaticListener = cache(function(utterance) {
  return Infer({method : "enumerate"},
               function() {
    var state = statePrior()
    var valence = valencePrior(state)
    var qud = qudPrior()
    var qudFn = qudFns[qud]
    var qValue = qudFn(state, valence)
    observe(speaker(qValue, qud),utterance)
    return {state : state, valence : valence}
  })
});
~~~~

Here is the full model:

~~~~
///fold:
// Round x to nearest multiple of b (used for approximate interpretation):
var approx = function(x,b) {
  return b * Math.round(x / b)
};
///

// Here is the code from the Kao et al. hyperbole model

// Define list of kettle prices under consideration (possible price states)
var states = [50, 51, 500, 501, 1000, 1001, 5000, 5001, 10000, 10001];

// Prior probability of kettle prices (taken from human experiments)
var statePrior = function() {
  return categorical([0.4205, 0.3865, 0.0533, 0.0538, 0.0223, 0.0211, 0.0112, 0.0111, 0.0083, 0.0120],
                     states)
};

// Probability that given a price state, the speaker thinks it's too
// expensive (taken from human experiments)
var valencePrior = function(state) {
  var probs = {
    50 : 0.3173,
    51 : 0.3173, 
    500 : 0.7920,
    501 : 0.7920, 
    1000 : 0.8933,
    1001 : 0.8933,
    5000 : 0.9524,
    5001 : 0.9524,
    10000 : 0.9864,
    10001 : 0.9864
  }
  var tf = flip(probs[state]);
  return tf
};

// Prior over QUDs 
var qudPrior = function() {
  return categorical([0.17, 0.32, 0.17, 0.17, 0.17],
                     ["state", "valence", "stateValence", "approxState", "approxStateValence"])
};

var qudFns = {
  state : function(state, valence) {return {state: state} },
  valence : function(state, valence) {return {valence: valence} },
  stateValence : function(state, valence) {return {state: state, valence: valence} },
  approxState : function(state, valence) {return {state: approx(state, 10) } },
  approxStateValence: function(state, valence) {return {state: approx(state, 10), valence: valence } }
};


// Define list of possible utterances (same as price states)
var utterances = states;

// Precise numbers are costlier
var utterancePrior = function() {
  categorical([0.18, 0.1, 0.18, 0.1, 0.18, 0.1, 0.18, 0.1, 0.18, 0.1],
              utterances)
};

// Literal interpretation "meaning" function; checks if uttered number
// reflects price state
var meaning = function(utterance, state) {
  return utterance == state;
};

// Literal listener, infers the qud value assuming the utterance is 
// true of the state
var literalListener = cache(function(utterance, qud) {
  return Infer({method : "enumerate"},
               function() {
    var state = statePrior()
    var valence = valencePrior(state)
    var qudFn = qudFns[qud]
    condition(meaning(utterance,state))
    return qudFn(state,valence)
  })
});

// set speaker optimality
var alpha = 1

// Speaker, chooses an utterance to convey a particular value of the qud
var speaker = cache(function(qValue, qud) {
  return Infer({method : "enumerate"},
               function() {
    var utterance = utterancePrior()
    factor(alpha*literalListener(utterance,qud).score(qValue))
    return utterance
  })
});

// Pragmatic listener, jointly infers the price state, speaker valence, and QUD
var pragmaticListener = cache(function(utterance) {
  return Infer({method : "enumerate"},
               function() {
    var state = statePrior()
    var valence = valencePrior(state)
    var qud = qudPrior()

    var qudFn = qudFns[qud]
    var qValue = qudFn(state, valence)

    observe(speaker(qValue, qud), utterance)

    return {state : state, valence : valence}
  })
});

var listenerPosterior = pragmaticListener(10000);

print("marginal distributions:")
viz.marginals(listenerPosterior)

print("pragmatic listener's joint interpretation of 'The kettle cost $10,000':")
viz.auto(listenerPosterior)
~~~~

> **Exercises:** 

> 1. Try the `pragmaticListener` with the other possible utterances.
> 2. Check the predictions of the `speaker` for the `approxStateValence` QUD.

By capturing the extreme (im)probability of kettle prices, together with the flexibility introduced by shifting communicative goals, the model is able to derive the inference that a speaker who comments on a "$10,000 kettle" likely intends to communicate that the kettle price was upsetting. The model thus captures some of the most flexible uses of language: what we mean when our utteranes are literally false.

Both the Scalar Implicature and Hyperbole models operate at the level of full utterances, with conversational participants reasoning about propositions. In the [next chapter](3-semantics.html), we begin to look at what it would take to model reasoning about sub-propositional meaning-bearing elements within the RSA framework.



#### Application 2: Irony


#### Application 3: Methaphor


