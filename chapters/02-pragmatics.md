---
layout: chapter
title: Modeling pragmatic inference
description: "Enriching the literal interpretations"
---

### Day 2: Enriching the literal interpretations

<!--   - Building the literal interpretations
  - Compositional mechanisms and semantic types
    - Functional Application; Predicate Modification 
  - The compositional semantics example from DIPPL -->

#### Application 1: Scalar implicature

Scalar implicature stands as the poster child of pragmatic inference. Utterances are strengthened---via implicature---from a relatively weak literal interpretation to a pragmatic interpretation that goes beyond the literal semantics: "Some of the apples are red," an utterance compatible with all of the apples being red, gets strengthed to "Some but not all of the apples are red."  The mechanisms underlying this process have been discussed at length. reft:goodmanstuhlmuller2013 apply an RSA treatment to the phenomenon and formally articulate the model by which scalar implicatures get calculated.

Assume a world with three apples; zero, one, two, or three of those apples may be red:

~~~~
// possible states of the world
var statePrior = function() {
  return uniformDraw([0, 1, 2, 3])
};
statePrior() // sample a state
~~~~

> **Exercises:**

> 1. Try visualizing `statePrior()` by drawing many samples and plotting the output (hint: you'll need to use the `repeat()` function, which has a strange syntax that is documented [here](http://webppl.readthedocs.io/en/master/functions/arrays.html#repeat)).
> 2. Try visualizing `statePrior()` by wrapping it in an inference model (à la our $$L_0$$ model) and plotting the output.

Next, assume that speakers may describe the current state of the world in one of three ways:

~~~~
// possible utterances
var utterancePrior = function() {
  return uniformDraw(['all', 'some', 'none']);
};

// meaning funtion to interpret the utterances
var literalMeanings = {
  all: function(state) { return state === 3; },
  some: function(state) { return state > 0; },
  none: function(state) { return state === 0; }
};

var utt = utterancePrior(); // sample an utterance
var meaning = literalMeanings[utt]; // get its meaning
[utt, meaning(3)] // apply meaning to state = 3
~~~~

With this knowledge about the communcation scenario---crucially, the availability of the "all" alternative utterance---a pragmatic listener is able to infer from the "some" utterance that the "all" utterance describes an unlikely state. In other words, the pragmatic listener strengthens "some" via scalar implicature.

Technical note: Below, `cache` is used to save the results of the various Bayesian inferences being performed. This is used for computational efficiency when dealing with nested inferences.

~~~~
// Here is the code from the basic scalar implicature model

// possible states of the world
var statePrior = function() {
  return uniformDraw([0, 1, 2, 3])
};

// possible utterances
var utterancePrior = function() {
  return uniformDraw(['all', 'some', 'none']);
};

// meaning funtion to interpret the utterances
var literalMeanings = {
  all: function(state) { return state === 3; },
  some: function(state) { return state > 0; },
  none: function(state) { return state === 0; }
};

// literal listener
var literalListener = cache(function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    var meaning = literalMeanings[utt]
    condition(meaning(state))
    return state
  }})
});

// set speaker optimality
var alpha = 1

// pragmatic speaker
var speaker = cache(function(state) {
  return Infer({model: function(){
    var utt = utterancePrior()
    factor(alpha * literalListener(utt).score(state))
    return utt
  }})
});

// pragmatic listener
var pragmaticListener = cache(function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    observe(speaker(state),utt)
    return state
  }})
});

print("pragmatic listener's interpretation of 'some':")
viz.auto(pragmaticListener('some'));

~~~~

> **Exercises:** 

> 1. Explore what happens if you make the speaker *less* optimal.
> 2. Subtract one of the utterances. What changed?
> 3. Add a new utterance. What changed?
> 4. Check what would happen if 'some' literally meant some-but-not-all (hint: use `!=` to assert that two values are not equal).
> 5. Change the relative probabilities of the various states and see what happens to model predictions.


#### Application 2: Scalar implicature and speaker knowledge

Capturing scalar implicature within the RSA framework might not induce waves of excitement. However, by implementing implicature-calculation within a formal model of communication, we can also capture its interactions with other pragmatic factors. Goodman and Stuhlmüller (2013) explored what happens when the speaker only has partial knowledge about the state of the world (Fig. 1). Below, we explore this model, taking into account the listener's knowledge about the speaker's epistemic state: whether or not the speaker has full or partial knowledge about the state of the world. 

<img src="../images/scalar.png" alt="Fig. 3: Example communication scenario from Goodman and Stuhmüller." style="width: 500px;"/>
<center>Fig. 1: Example communication scenario from Goodman and Stuhmüller: How will the listener interpret the speaker’s utterance? How will this change if she knows that he can see only two of the objects?.</center>

In the extended Scalar Implicature model, the pragmatic listener infers the true state of the world not only on the basis of the observed utterance, but also the speaker's epistemic access $$a$$.

$$P_{L_{1}}(s\mid u, a) \propto P_{S_{1}}(u\mid s, a) \cdot P(s)$$

~~~~
// pragmatic listener
var pragmaticListener = cache(function(access,utt) {
  return Infer({model: function(){
    var state = statePrior()
    observe(speaker(access,state),utt)
    return numTrue(state)
  }})
});
~~~~

We have to enrich the speaker model: first the speaker makes an observation $$o$$ of the true state $$s$$ with access $$a$$. On the basis of the observation and access, the speaker infers the true state.

~~~~
///fold:
// tally up the state
var numTrue = function(state) {
  var fun = function(x) {
    x ? 1 : 0
  }
  return sum(map(fun,state))
}
///

// red apple base rate
var baserate = 0.8

// state builder
var statePrior = function() {
  var s1 = flip(baserate)
  var s2 = flip(baserate)
  var s3 = flip(baserate)
  return [s1,s2,s3]
}

// speaker belief function
var belief = function(actualState, access) {
  var fun = function(access,state) {
    return access ? state : uniformDraw(statePrior())
  }
  return map2(fun, access, actualState);
}

print("1000 runs of the speaker's belief function:")

viz.auto(repeat(1000,function() {
  numTrue(belief([true,true,true],[true,true,false]))
}))

~~~~

> **Exercise:** See what happens when you change the red apple base rate.

The speaker then chooses an utterance $$u$$ to communicate the true state $$s$$ that likely generated the observation $$o$$ that the speaker made with access $$a$$.

$$P_{S_{1}}(u\mid o, a) \propto exp(\alpha\mathbb{E}_{P(s\mid o, a)}[U(u; s)])$$

~~~~
// pragmatic speaker
var speaker = cache(function(access,state) {
  return Infer({model: function(){
    var utterance = utterancePrior()
    var beliefState = belief(state,access)
    factor(alpha * literalListener(utterance).score(beliefState))
    return utterance
  }})
});
~~~~

The speaker's utility function remains unchanged, such that utterances are chosen to minimize cost and maximize informativity.

$$U_{S_{1}}(u; s) = log(L_{0}(s\mid u)) - C(u)$$

The intuition (which Goodman and Stuhlmüller validate experimentally) is that in cases where the speaker has partial knowledge access (say, she knows about only two out of three relevant apples), the listener will be less likely to calculate the implicature (because he knows that the speaker doesn't have the evidence to back up the strengthened meaning).

~~~~
///fold:
// tally up the state
var numTrue = function(state) {
  var fun = function(x) {
    x ? 1 : 0
  }
  return sum(map(fun,state))
}
///

// Here is the code from the Goodman and Stuhlmüller speaker-access SI model

// red apple base rate
var baserate = 0.8

// state prior
var statePrior = function() {
  var s1 = flip(baserate)
  var s2 = flip(baserate)
  var s3 = flip(baserate)
  return [s1,s2,s3]
}

// speaker belief function
var belief = function(actualState, access) {
  var fun = function(access,state) {
    return access ? state : uniformDraw(statePrior())
  }
  return map2(fun, access, actualState);
}

// utterance prior
var utterancePrior = function() {
  uniformDraw(['all','some','none'])
}

// meaning funtion to interpret utterances
var literalMeanings = {
  all: function(state) { return all(function(s){s}, state); },
  some: function(state) { return any(function(s){s}, state); },
  none: function(state) { return all(function(s){s==false}, state); }
};

// literal listener
var literalListener = cache(function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    var meaning = literalMeanings[utt]
    condition(meaning(state))
    return state
  }})
});

// set speaker optimality
var alpha = 1

// pragmatic speaker
var speaker = cache(function(access,state) {
  return Infer({model: function(){
    var utt = utterancePrior()
    var beliefState = belief(state,access)
    factor(alpha * literalListener(utt).score(beliefState))
    return utt
  }})
});

// pragmatic listener
var pragmaticListener = cache(function(access,utt) {
  return Infer({model: function(){
    var state = statePrior()
    observe(speaker(access,state),utt)
    return numTrue(state)
  }})
});

print("pragmatic listener for a full-access speaker:")
viz.auto(pragmaticListener([true,true,true],'some'))
print("pragmatic listener for a partial-access speaker:")
viz.auto(pragmaticListener([true,true,false],'some'))

~~~~

> **Exercise:** 

> 1. Check the predictions for the other possible knowledge states.
> 2. Compare the full-access predictions with the predictions from the simpler scalar implicature model above. Why are the predictions of the two models different? How can you get the model predictions to converge? (Hint: first try to align the predictions of the simpler model with those of the knowledge model, then try aligning the predictions of the knowledge model with those fo the simpler model.)

We have seen how the RSA framework can implement the mechanism whereby utterance interpretations are strengthened. Through an interaction between what was said, what could have been said, and what all of those things literally mean, the model delivers scalar implicature. And by taking into account awareness of the speaker's knowledge, the model successfully *blocks* implicatures in those cases where listeners are unlikely to access them. 
