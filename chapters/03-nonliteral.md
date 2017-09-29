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


The models we have so far considered strengthen the literal interpretations of our utterances: from "blue" to "blue circle" and from "some" to "some-but-not-all." Now, we consider what happens when we use utterances that are *literally* false. As we'll see, the strategy of strengthening interpretations by narrowing the set of worlds that our utterances describe will no longer serve to capture our meanings. Our secret ingredient will be the uncertainty conversational participants experience about the topic of conversation: the literal semantics will have different impacts depending on what the conversation is about.

#### Application 1: Hyperbole and the Question Under Discussion

If you hear that someone waited "a million years" for a table at a popular restaurant or paid "a thousand dollars" for a coffee at a hipster hangout, you are unlikely to conclude that the improbable literal meanings are true. Instead, you conclude that the diner waited a long time, or paid an exorbitant amount of money, *and that she is frustrated with the experience*. Whereas blue circles are compatible with the literal meaning of "blue," five-dollar coffees are not compatible with the literal meaning of "a thousand dollars." How, then, do we arrive at sensible interpretations when our words are literally false?

reft:kaoetal2014 propose that we model hyperbole understanding as pragmatic inference. Crucially, they propose that we recognize uncertainty about **communicative goals**: what Question Under Discussion (QUD) a speaker is likely addressing with their utterance. QUDs are modeled as summaries of the full world states, or *projections* of full world states onto the aspect(s) that are relevant for the Question Under Discussion. In the case study of hyperbolic language understanding, reft:kaoetal2014 propose that two aspects of the world are critical: the true state of the world and speakers' attitude toward the true state of the world (e.g., the valence of their *affect*), which is modeled simply as a binary positive/negative variable (representing whether or not the speaker is upset). In addition, the authors investigate the *pragmatic halo* effect, by considering a QUD that addresses *approximately* the exact price (`approxPrice`):

~~~~
///fold:
// Round x to nearest multiple of b (used for approximate interpretation):
var approx = function(x) {
  var b = 10
  return b * Math.round(x / b)
};
var stringify = function(x){return JSON.stringify(x)}
///

var qudFns = {
  price : function(state) {return { price: state.price } },
  valence : function(state) {return { valence: state.valence } },
  priceValence : function(state) {
    return { price: state.price, valence: state.valence }
  },
  approxPrice : function(state) {return { price: approx(state.price) } },
};

var fullState = { price: 51, valence: true }
display("full state = " + stringify(fullState))

var valenceQudFn = qudFns["valence"]
var valenceQudVal = valenceQudFn(fullState)
display("valence QUD value = " + stringify(valenceQudVal))

var priceQudFn = qudFns["price"]
var priceQudVal = priceQudFn(fullState)
display("price QUD value = " + stringify(priceQudVal))

var priceValenceQudFn = qudFns["priceValence"]
var priceValenceQudVal = priceValenceQudFn(fullState)
display("priceValence QUD value = " + stringify(priceValenceQudVal))

var approxPriceQudFn = qudFns["approxPrice"]
var approxPriceQudVal = approxPriceQudFn(fullState)
display("approxPrice QUD value = " + stringify(approxPriceQudVal))
~~~~

Accurately modeling world knowledge is key to getting appropriate inferences from the world. Kao et al. achieve this using **prior elicitation**, an empirical methodology for gathering precise quantitative information about interlocutors' relevant world knowledge. They do this to estimate the prior knowledge people carry about the price of an object (in this case, an *electric kettle*), as well as the probability of getting upset (i.e., experiencing a negatively-valenced affect) in response to a given price.

~~~~
// Prior probability of kettle prices (taken from human experiments)
var pricePrior = function() {
  return categorical({
    vs: [
      50, 51,
      500, 501,
      1000, 1001,
      5000, 5001,
      10000, 10001
    ],
    ps: [
      0.4205, 0.3865,
      0.0533, 0.0538,
      0.0223, 0.0211,
      0.0112, 0.0111,
      0.0083, 0.0120
    ]
  })
};

// Probability that given a price state, the speaker thinks it's too
// expensive (taken from human experiments)
var valencePrior = function(price) {
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
  var tf = flip(probs[price]);
  return tf
};

display("marginal distribution on prices")
viz.table(Infer({model: pricePrior}))

~~~~

> **Exercise:** Use `Infer()` to visualize the joint distribution on price and valence. (Hint: You'll want to run inference over a function that returns an object like the following: `{price: aPrice, valence: aValence}`.)

Putting it all together, the Literal Listener updates these prior belief distributions by conditioning on the literal meaning of the utterance. The Question Under Discussion determines which kind of distribution (e.g., price or affect or both) will be returned.

~~~~
///fold:
// Round x to nearest multiple of b (used for approximate interpretation):
var approx = function(x,b) {
  var b = 10;
  return b * Math.round(x / b)
};

// Prior probability of kettle prices (taken from human experiments)
var pricePrior = function() {
  return categorical({
    vs: [
      50, 51,
      500, 501,
      1000, 1001,
      5000, 5001,
      10000, 10001
    ],
    ps: [
      0.4205, 0.3865,
      0.0533, 0.0538,
      0.0223, 0.0211,
      0.0112, 0.0111,
      0.0083, 0.0120
    ]
  })
};

// Probability that given a price state, the speaker thinks it's too
// expensive (taken from human experiments)
var valencePrior = function(price) {
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
  var tf = flip(probs[price]);
  return tf
};
///
var qudFns = {
  price : function(state) {return { price: state.price } },
  valence : function(state) {return { valence: state.valence } },
  priceValence : function(state) {
    return { price: state.price, valence: state.valence }
  },
  approxPrice : function(state) {return { price: approx(state.price) } },
};

// Literal interpretation "meaning" function;
// checks if uttered number reflects price state
var meaning = function(utterance, price) {
  return utterance == price;
};

var literalListener = cache(function(utterance, qud) {
  return Infer({model: function(){

    var price = pricePrior() // uncertainty about the price
    var valence = valencePrior(price) // uncertainty about the valence
    var qudFn = qudFns[qud]

    condition( meaning(utterance, price) )

    return qudFn({price, valence})
  }
})});
~~~~

> **Exercises:**

> 1. Suppose the literal listener hears the kettle costs `10000` dollars with the `"priceValence"` QUD. What does it infer?
> 2. Test out other QUDs. What aspects of interpretation does the literal listener capture? What aspects does it not capture?
> 3. Create a new QUD function and try it out with "the kettle costs `10000` dollars".

This enriched literal listener does a joint inference about the price and the valence but assumes a particular QUD by which to interpret the utterance. Similarly, the speaker chooses an utterance to convey a particular value of the QUD to the literal listener:

~~~~
var speaker = function(qudValue, qud) {
  return Infer({model: function(){
    var utterance = utterancePrior()
    factor(alpha * literalListener(utterance, qud).score(qudValue))
    return utterance
  }
})};
~~~~

To model hyperbole, Kao et al. posited that the pragmatic listener actually has uncertainty about what the QUD is, and jointly infers the price (and speaker valence) and the intended QUD from the utterance he receives. That is, the pragmatic listener simulates how the speaker would behave with various QUDs.

~~~~
var pragmaticListener = function(utterance) {
  return Infer({model: function(){
    var price = pricePrior()
    var valence = valencePrior(price)
    var fullState = {price, valence}
    var qud = qudPrior()
    var qudFn = qudFns[qud]
    var qudValue = qudFn(price, valence)
    observe( speaker(qudValue, qud), utterance)
    return fullState
  }
})};
~~~~

Here is the full model:

~~~~
///fold:
// Round x to nearest multiple of b (used for approximate interpretation):
var approx = function(x,b) {
  var b = 10;
  return b * Math.round(x / b)
};

// Here is the code from the Kao et al. hyperbole model
// Prior probability of kettle prices (taken from human experiments)
var pricePrior = function() {
  return categorical({
    vs: [
      50, 51,
      500, 501,
      1000, 1001,
      5000, 5001,
      10000, 10001
    ],
    ps: [
      0.4205, 0.3865,
      0.0533, 0.0538,
      0.0223, 0.0211,
      0.0112, 0.0111,
      0.0083, 0.0120
    ]
  })
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

// Literal interpretation "meaning" function;
// checks if uttered number reflects price state
var meaning = function(utterance, price) {
  return utterance == price;
};

var qudFns = {
  price : function(state) {return { price: state.price } },
  valence : function(state) {return { valence: state.valence } },
  priceValence : function(state) {
    return { price: state.price, valence: state.valence }
  },
  approxPrice : function(state) {return { price: approx(state.price) } },
  approxPriceValence: function(state) {
    return { price: approx(state.price), valence: state.valence  }
  }
};
///

// Prior over QUDs
var qudPrior = function() {
 categorical({
    vs: ["price", "valence", "priceValence", "approxPrice", "approxPriceValence"],
    ps: [1, 1, 1, 1, 1]
  })
};

// Define list of possible utterances (same as price states)
var utterances = [
  50, 51,
  500, 501,
  1000, 1001,
  5000, 5001,
  10000, 10001
];

// precise numbers can be assumed to be costlier than round numbers
var preciseNumberCost = 1
var utteranceCost = function(numberUtt){
  return numberUtt == approx(numberUtt) ? // if it's a round number utterance
        0 : // no cost
        preciseNumberCost // cost of precise numbers (>= 0)
}

var utteranceProbs = map(function(numberUtt){
  return Math.exp(-utteranceCost(numberUtt)) // prob ~ e^(-cost)
}, utterances)

var utterancePrior = function() {
  categorical({ vs: utterances, ps: utteranceProbs })
};

// Literal listener, infers the qud value assuming the utterance is
// true of the state
var literalListener = cache(function(utterance, qud) {
  return Infer({model: function(){

    var price = pricePrior() // uncertainty about the price
    var valence = valencePrior(price) // uncertainty about the valence
    var fullState = {price, valence}

    condition( meaning(utterance, price) )

    var qudFn = qudFns[qud]

    return qudFn(fullState)
  }
})});

// set speaker optimality
var alpha = 1

// Speaker, chooses an utterance to convey a particular value of the qud
var speaker = cache(function(qudValue, qud) {
  return Infer({model: function(){
    var utterance = utterancePrior()
    factor(alpha*literalListener(utterance,qud).score(qudValue))
    return utterance
  }
})});

// Pragmatic listener, jointly infers the price state, speaker valence, and QUD
var pragmaticListener = cache(function(utterance) {
  return Infer({model: function(){
    //////// priors ////////
    var price = pricePrior()
    var valence = valencePrior(price)
    var qud = qudPrior()
    ////////////////////////

    var fullState = {price, valence}
    var qudFn = qudFns[qud]
    var qudValue = qudFn(fullState)

    observe(speaker(qudValue, qud), utterance)

    return fullState
  }
})});

var listenerPosterior = pragmaticListener(10000);

print("pragmatic listener's joint interpretation of 'The kettle cost $10,000':")
viz(listenerPosterior)

// print("marginal distributions:")
// viz.table(marginalize(listenerPosterior, "price"))
// viz.hist(marginalize(listenerPosterior, "valence"))
~~~~

> **Exercises:**

> 1. In the second code box, we looked at the joint *prior* distribution over price and valence. Compare the results of that with the listener interpretation of "10000". What is similar? What is different?
> 2. Try the `pragmaticListener` with the other possible utterances.
> 3. Check the predictions of the `speaker` for the `approxPriceValence` QUD.

By capturing the extreme (im)probability of kettle prices, together with the flexibility introduced by shifting communicative goals, the model is able to derive the inference that a speaker who comments on a "$10,000 kettle" likely intends to communicate that the kettle price was upsetting. The model thus captures some of the most flexible uses of language: what we mean when our utterances are literally false.

#### Application 2: Irony

The same machinery---actively reasoning about the QUD---has been used to capture other cases of non-literal language. [Kao and Goodman (2015)](http://cocolab.stanford.edu/papers/KaoEtAl2015-Cogsci.pdf) use this process to model ironic language, utterances whose intended meanings are opposite in polarity to the literal meaning. For example, if we are standing outside on a beautiful day and I tell you the weather is "terrible," you're unlikely to conclude that I intend to be taken literally. Instead, you will probably interpret the utterance ironically and conclude that I intended the opposite of what I uttered, namely that the weather is good and I'm happy about it. The following model implements this reasoning process by formalizing three possible conversational goals: communicating about the true state, communicating about the speaker's valence (i.e., whether they feel positively or negatively toward the state), and communicating about the speaker's arousal (i.e., how strongly they feel about the state).

~~~~
// There are three possible states the weather could be in: terrible, okay, or amazing
var states = ['terrible', 'ok', 'amazing']

// Since the authors are in California, the prior over these states privileges okay and amazing weather.
var statePrior = function() {
  categorical([0.01, 0.5, 0.5], states)
}

// Valence prior defined in terms of negative valence. If the current state
// is terrible, it's extremely likely that the valence associted is negative.
// If it's ok, then the valence could be negative or positive with equal probability.
var valencePrior = function(state) {
  state === "terrible" ? flip(0.99) ? -1 : 1 :
  state === "ok" ? flip(0.5) ? -1 : 1 :
  state === "amazing" ? flip(0.01) ? -1 : 1 :
  true
}

// Define binary arousals (could model as continuous).
var arousals = ["low", "high"]

// Define goals and goal priors. Could want to communicate state of the world,    
// valence about it, or arousal (intensity of feeling) about it.
var goals = ["goalState", "goalValence", "goalArousal"]

var goalPrior = function() {
  categorical([0.1, 0.1, 0.1], goals)
}

// Assume possible utterances are identical to possible states
var utterances = states

// Assume cost of utterances is uniform.
var utterancePrior = function() {
  uniformDraw(utterances)
}

// Sample arousal given a state.
var arousalPrior = function(state) {
  state === "terrible" ? categorical([0.1, 0.9], arousals) :
  state === "ok" ? categorical([0.9, 0.1], arousals) :
  state === "amazing" ? categorical([0.1, 0.9], arousals) :
  true
}

// Literal interpretation is just whether utterance equals state
var literalInterpretation = function(utterance, state) {
  utterance === state ? true : false
}

// A speaker's goal is satisfied if the listener infers the correct and relevant information.
var goalState = function(goal, state, valence, arousal) {
  goal === "goalState" ? state :
  goal === "goalValence" ? valence :
  goal === "goalArousal" ? arousal :
  true
}

// Define a literal listener
var literalListener = function(utterance, goal) {
  Infer({model: function(){
    var state = statePrior()
    var valence = valencePrior(state)
    var arousal = arousalPrior(state)
    condition(literalInterpretation(utterance,state))
    return goalState(goal, state, valence, arousal)
  }})
}

// Define a speaker
var speaker = function(state, valence, arousal, goal) {
  Infer({model: function(){
    var utterance = utterancePrior()
    factor(1 * literalListener(utterance, goal).score(goalState(goal, state, valence, arousal)))
    return utterance
  }})
}

// Define a pragmatic listener
var pragmaticListener = function(utterance) {
  Infer({model: function(){
    var state = statePrior()
    var valence = valencePrior(state)
    var arousal = arousalPrior(state)
    var goal = goalPrior()
    observe(speaker(state, valence, arousal, goal),utterance)
    return {state, valence, arousal}
  }})
}

viz.table(pragmaticListener("terrible"))

~~~~

#### Application 3: Metaphor

In yet another application, reft:kaoetal2014metaphor use a QUD manipulation to model metaphor, perhaps the most flagrant case of non-literal language use. If I call John a whale, you're unlikely to infer that he's an aquatic mammal. However, you probably will infer that John has qualities characteristic of whales (e.g., size, grace, majesty, etc.). The following model implements this reasoning process by aligning utterances (e.g., "whale", "person") with stereotypical features, then introducing uncertainty about which feature is currently the topic of conversation.


~~~~
// John could either be a whale or a person.
var categories = ["whale", "person"]

// It is extremely unlikely that John is actually a whale.
var categoriesPrior = function() {
  categorical([0.01, 0.99], categories)
}

// The speaker could either say "John is a whale" or "John is a person."
var utterances = ["whale", "person"]

// The utterances are equally costly.
var utterancePrior = function() {
  categorical([0.1, 0.1], utterances)
}

// The features of John being considered are "large", "graceful",
// "majestic." Features are binary.
var featureSets = [
  {large : 1, graceful : 1, majestic : 1},
  {large : 1, graceful : 1, majestic : 0},
  {large : 1, graceful : 0, majestic : 1},
  {large : 1, graceful : 0, majestic : 0},
  {large : 0, graceful : 1, majestic : 1},
  {large : 0, graceful : 1, majestic : 0},
  {large : 0, graceful : 0, majestic : 1},
  {large : 0, graceful : 0, majestic : 0}
]

var featureSetPrior = function(category) {
  category === "whale" ? categorical([0.30592786494628, 0.138078454222818,
                                      0.179114768847673, 0.13098781834847,
                                      0.0947267162507846, 0.0531420411185539,
                                      0.0601520520596695, 0.0378702842057509],
                                     featureSets) :
  category === "person" ? categorical([0.11687632453038, 0.105787535267869,
                                       0.11568145784997, 0.130847056136141,
                                       0.15288225956497, 0.128098151176801,
                                       0.114694702836614, 0.135132512637255],
                                      featureSets) :
  true
}

// Speaker's possible goals are to communicate feature 1, 2, or 3
var goals = ["large", "graceful", "majestic"]

// Prior probability of speaker's goal is set to uniform but can
// change with context/QUD.
var goalPrior = function() {
  categorical([0.33, 0.33, 0.33], goals)
}

// Speaker optimality parameter
var alpha = 3

// Check if interpreted category is identical to utterance
var literalInterpretation = function(utterance, category) {
  utterance === category ? true : false
}

// Check if goal is satisfied
var goalState = function(goal, featureSet) {
  goal === "large" ? featureSet.large :
  goal === "graceful" ? featureSet.graceful :
  goal === "majestic" ? featureSet.majestic :
  true
}

//  Define a literal listener
var literalListener = function(utterance, goal) {
  Infer({model: function() {
    var category = categoriesPrior()
    var featureSet = featureSetPrior(category)
    condition(literalInterpretation(utterance, category))
    return goalState(goal, featureSet)
  }})
}         

// Speaker model
var speaker = function(large, graceful, majestic, goal) {
  Infer({model: function() {
    var utterance = utterancePrior()
    factor(alpha *
           literalListener(utterance,goal).score(goalState(goal, {large : large, graceful : graceful, majestic : majestic})))
    return utterance
  }})
}

// Define a pragmatic listener
var pragmaticListener = function(utterance) {
  Infer({model: function() {
    var category = categoriesPrior()
    var featureSet = featureSetPrior(category)
    var large = featureSet.large
    var graceful = featureSet.graceful
    var majestic = featureSet.majestic
    var goal = goalPrior()
    observe(speaker(large, graceful, majestic, goal), utterance)
    return {category, large, graceful, majestic}
  }})
}

viz.table(pragmaticListener("whale"))

~~~~

All of the models we have considered so far operate at the level of full utterances, with conversational participants reasoning about propositions. In the [next chapter](04-ambiguity.html), we begin to look at what it would take to model reasoning about sub-propositional meaning-bearing elements within the RSA framework.
