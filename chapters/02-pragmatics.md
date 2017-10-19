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

Scalar implicature stands as the poster child of pragmatic inference. Utterances are strengthened---via implicature---from a relatively weak literal interpretation to a pragmatic interpretation that goes beyond the literal semantics: "Some of the apples are red," an utterance compatible with all of the apples being red, gets strengthened to "Some but not all of the apples are red."  The mechanisms underlying this process have been discussed at length. reft:goodmanstuhlmuller2013 apply an RSA treatment to the phenomenon and formally articulate the model by which scalar implicatures get calculated.

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
> 2. Try visualizing `statePrior()` by wrapping it in `Infer` (à la our $$L_0$$ model) and using `{method: "forward", samples: 1000}`.

Next, assume that speakers may describe the current state of the world in one of three ways:

~~~~
// possible utterances
var utterancePrior = function() {
  return uniformDraw(['all', 'some', 'none']);
};

// meaning function to interpret the utterances
var literalMeanings = {
  all: function(state) { return state === 3; },
  some: function(state) { return state > 0; },
  none: function(state) { return state === 0; }
};

var utt = utterancePrior(); // sample an utterance
var meaning = literalMeanings[utt]; // get its meaning
[utt, meaning(3)] // apply meaning to state = 3
~~~~

> **Exercise:** Interpret the output of the above code box. (Run several times.)

Putting state priors and semantics together, we can implement the behavior of the literal listener. If state priors are uniform, the literal listener will interpret messages by assigning probability 0 to each state of which the observed message is false, and the same uniform probability to each true state. Verify this with the following code.

~~~~
// code for state prior and semantics as before
///fold:
// possible states of the world
var statePrior = function() {
  return uniformDraw([0, 1, 2, 3])
};

// possible utterances
var utterancePrior = function() {
  return uniformDraw(['all', 'some', 'none']);
};

// meaning function to interpret the utterances
var literalMeanings = {
  all: function(state) { return state === 3; },
  some: function(state) { return state > 0; },
  none: function(state) { return state === 0; }
};
///

// literal listener
var literalListener = function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    var meaning = literalMeanings[utt]
    condition(meaning(state))
    return state
  }}
)}

display("literal listener's interpretation of 'some':")
viz(literalListener("some"))
~~~~

Let us then look at the speaker's behavior. Intuitively put, in the vanilla RSA model the speaker will never choose a false message and prefers to send one true message over another, if the former has a small extension than the latter (see [appendix](app-01-utilities.html)). Verify this with the following code.

~~~~
// code for state prior, semantics and literal listener as before
///fold:
// possible states of the world
var statePrior = function() {
  return uniformDraw([0, 1, 2, 3])
};

// possible utterances
var utterancePrior = function() {
  return uniformDraw(['all', 'some', 'none']);
};

// meaning function to interpret the utterances
var literalMeanings = {
  all: function(state) { return state === 3; },
  some: function(state) { return state > 0; },
  none: function(state) { return state === 0; }
};

// literal listener
var literalListener = function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    var meaning = literalMeanings[utt]
    condition(meaning(state))
    return state
  }}
)}
///

// set speaker optimality
var alpha = 1

// pragmatic speaker
var speaker = function(state) {
  return Infer({model: function(){
    var utt = utterancePrior()
    factor(alpha * literalListener(utt).score(state))
    return utt
  }})
}

display("speaker's production probabilities for state 3:")
viz(speaker(3))

~~~~

With this knowledge about the communication scenario---crucially, the availability of the "all" alternative utterance---a pragmatic listener is able to infer from the "some" utterance that a state in which the speaker would not have used the "all" utterance is more likely than one in which she would. We can verify this with the following complete code of a vanilla RSA model for scalar implicatures.

Technical note: Below, `cache` is used to save the results of the various Bayesian inferences being performed. This is used for computational efficiency when dealing with nested inferences.

~~~~
// possible states of the world
var statePrior = function() {
  return uniformDraw([0, 1, 2, 3])
};

// possible utterances
var utterancePrior = function() {
  return uniformDraw(['all', 'some', 'none']);
};

// meaning function to interpret the utterances
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

display("pragmatic listener's interpretation of 'some':")
viz(pragmaticListener('some'));

~~~~

> **Exercises:**

> 1. Explore what happens if you make the speaker *less* optimal.
> 2. Subtract one of the utterances. What changed?
> 3. Add a new utterance. What changed?
> 4. Check what would happen if 'some' literally meant some-but-not-all.
> 5. Change the relative prior probabilities of the various states.


#### Application 2: Scalar implicature and speaker knowledge

##### Setting the scene

Capturing scalar implicature within the RSA framework might not induce waves of excitement. However, by implementing implicature-calculation within a formal model of communication, we can also capture its interactions with other pragmatic factors. Goodman and Stuhlmüller (2013) explored what happens when the speaker possibly only has partial knowledge about the state of the world. Below, we explore this model, taking into account the listener's beliefs about the speaker's epistemic state: whether or not the speaker has full or partial knowledge about the state of the world.

In many traditional approaches to scalar implicature calculation, the listener's reasoning from an utterance containting *some* to the conclusion that "some but not all" proceeds along the following lines (e.g., what Geurts calls the **standard recipe** ):

1. the speaker used *some*
2. one reason why the speaker did not use *all* instead is that she does not know whether it is true
3. the speaker is assumed epistemically competent (i.e., she knows whether it is "all" or "some but not all") [**Competence Assumption**] 
4. so, she knows that the *all* sentence is actually false
5. if the speaker knows it, it must be true (by veridicality of knowledge)

Crucially, the standard recipe requires the Competence Assumption to derive a scalar implicature reading. Without the competence assumption, we only derive the *weak epistemic implicature*: that the speaker does not know that *all* is true.

From a probabilistic perspective, this is way to simple. Probabilistic modeling, aided by probabilistic programming tools, lets us explore a richer and more intuitive picture. In this picture, the listener may have probabilistic beliefs about the degree to which the speaker is in possession of the relevant facts. Hearing an utterance may dynamically change these beliefs. This is because the listener tries to infer the most likely epistemic state conditional on the obsersed utterance, given whatever representation of the utterance context he has. If a particular utterance is more likely to be observed by a well-informed speaker, then the listener might infer that the speaker is likely more knowledgable than initially assumed.


<img src="../images/scalar.png" alt="Fig. 3: Example communication scenario from Goodman and Stuhmüller." style="width: 500px;"/>
<center>Fig. 1: Example communication scenario from Goodman and Stuhmüller: How will the listener interpret the speaker’s utterance? How will this change if she knows that he can see only two of the objects?.</center>

reft:GoodmanStuhlmuller2013Impl explore a concrete scenario where such complex epistemic inferences can be studied systematically (Fig. 1 above). Suppose there are $$n$$ apples in total of which $$0 \le s \le n$$ are red. The speaker knows $$n$$ (as does the listener) but the speaker might only observe some of the apples' colors. Concretely, the speaker might only have access to $$0 \le a \le n$$ apples, of which she observes $$0 \le o \le a$$ to be red. If she communicates her observation with a statement like "Some of the apples are red," then, the listener makes a **joint inference** of the true world state $$s$$, the access $$a$$ and the observation $$o$$:

$$P_{L_{1}}(s, a, o \mid u) \propto P_{S_{1}}(u\mid a, o) \cdot P(s,a,o)$$

~~~~
// pragmatic listener
var pragmaticListener = function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    var access = uniformDraw(_.range(total_apples + 1 ))
    var observed = uniformDraw(_.range(total_apples + 1))
    factor(Math.log(hypergeometricPMF(observed, total_apples,
                                      state, access)))
    observe(speaker(access, observed), utt)
    return {state, access, observed}
  }})
}
~~~~

##### Modeling beliefs after partial observations

What does a speaker believe about the world state $$s$$ after, say, having access to $$a = 2$$ out of $$n = 3$$ apples and seeing that $$o = 1$$ the accessed apples is red? - This depends on the speakers prior beliefs about how likely red apples are in general. Let us assume that these prior beliefs are given by a binomial distribution with a fixed base rate of redness: intuitively put, each apple has a chance `base_rate` of being red; how many red apples do we expect given that we have `total_apples`?

~~~~
// total number of apples (known by speaker and listener)
var total_apples = 3

// red apple base rate
var base_rate_red = 0.8

// state = how many apples of 'total_apples' are red?
var statePrior = function() {
  binomial({p: base_rate_red, n: total_apples})
}
~~~~

A world state `state` (a single sample from the `statePrior`) gives the true, actual number of red apples. If the world state was known to the speaker, his beliefs for any pair of access `access` to apples and observations `observed` of red apples are given by a socalled [Hypergeometric distribution](https://en.wikipedia.org/wiki/Hypergeometric_distribution). The Hypergeometric distribution gives the probability of retrieving `observe` red balls when drawing `access` balls without replacement from an urn with `total_apples` balls in total of which `state` are red. (This distribution is not implemented in WebPPL, so we implement its probability mass function by hand.)

~~~~

var fact = function(x) {
  if (x < 0) {return "input to factorial function must be non-negative"}
  return x == 0 ? 1 : x * fact(x-1)
}

var binom = function(a, b) {
  var numerator = fact(a)
  var denominator = fact(a-b) *  fact(b)
  return numerator / denominator
}

// urn contains N balls of which K are black
// and N-K are white; we draw n balls at random
// without replacement; what's the probability
// of obtaining k black balls?
var hypergeometricPMF = function(k,N,K,n) {
  k > Math.min(n, K) ? 0 :
  k < n+K-N ? 0 :       
  binom(K,k) * binom(N-K, n-k) / binom(N,n)
}

var hypergeometricSample = function(N,K,n) {
  var support = _.range(N+1) // possible values 0, ..., N
  var PMF = map(function(k) {hypergeometricPMF(k,N,K,n)}, support)
  categorical({vs: support, ps: PMF })    
}

var total_apples = 3, state = 2, access = 1;
viz(repeat(1000, function() {hypergeometricSample(total_apples, state, access)}))

~~~~

The prior over states and the hypergeometric distribution must be combined to give the speaker's beliefs about world state $$s$$ given access $$a$$ and observation $$o$$, using Bayes rule (and knowledge of the total number of apples $$n$$):

$$P_S(s \mid a, o) \propto \text{Hypergeometric}(o \mid s, a, n) \ \text{Binomial}(s \mid \text{baserate}) $$

~~~~

// code for hypergeometric 
///fold:
var fact = function(x) {
  if (x < 0) {return "input to factorial function must be non-negative"}
  return x == 0 ? 1 : x * fact(x-1)
}

var binom = function(a, b) {
  var numerator = fact(a)
  var denominator = fact(a-b) *  fact(b)
  return numerator / denominator
}

// urn contains N balls of which K are black
// and N-K are white; we draw n balls at random
// without replacement; what's the probability
// of obtaining k black balls?
var hypergeometricPMF = function(k,N,K,n) {
  k > Math.min(n, K) ? 0 :
  k < n+K-N ? 0 :       
  binom(K,k) * binom(N-K, n-k) / binom(N,n)
}

var hypergeometricSample = function(N,K,n) {
  var support = _.range(N+1) // possible values 0, ..., N
  var PMF = map(function(k) {hypergeometricPMF(k,N,K,n)}, support)
  categorical({vs: support, ps: PMF })    
}
///

// total number of apples (known by speaker and listener)
var total_apples = 3

// red apple base rate
var base_rate_red = 0.8

// state = how many apples of 'total_apples' are red?
var statePrior = function() {
  binomial({p: base_rate_red, n: total_apples})
}

var belief = cache(function(access, observed){
  Infer({model: function() {
    var state = statePrior()
    var hyperg_sample = hypergeometricSample(total_apples,
                         state,
                         access)
    condition(hyperg_sample == observed)
    return state
  }}) 
})

viz(belief(2,1))
~~~~


> **Exercise:** 

> 1. See what happens when you change the red apple base rate.
> 2. See what happens when you increase the number of total apples.
> 3. See what happens when you give the speaker more access and different numbers of observed red apples.

##### Speaker production model 

We have to enrich the speaker model: first the speaker makes an observation $$o$$ of the true state $$s$$ with access $$a$$. On the basis of the observation and access, the speaker infers the true state.



The speaker then chooses an utterance $$u$$ to communicate the true state $$s$$ that likely generated the observation $$o$$ that the speaker made with access $$a$$.

$$P_{S_{1}}(u\mid o, a) \propto exp(\alpha\mathbb{E}_{P(s\mid o, a)}[U(u; s)])$$

~~~~
// pragmatic speaker
var speaker = cache(function(state, access) {
  return Infer({model: function(){
    var utterance = utterancePrior()
    var beliefState = belief(state, access)
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
var base_rate = 0.8

var sampleApple = function(){
  return flip(base_rate)
};

// state builder
var statePrior = function() {
  return repeat(3, sampleApple)
}

// speaker belief functions ////
// what to believe about a single apple
var beliefSingle = function(actualSingleApple, accessSingle) {
  return accessSingle ? actualSingleApple : sampleApple()
}
// what to believe about the set of apples
var belief = function(state, access) {
  return map2(beliefSingle, state, access);
}

// utterance prior
var utterancePrior = function() {
  uniformDraw(['all','some','none'])
}

// meaning function to interpret utterances
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
var speaker = cache(function(state, access) {
  return Infer({model: function(){
    var utt = utterancePrior()
    var beliefState = belief(state, access)
    factor(alpha * literalListener(utt).score(beliefState))
    return utt
  }})
});

// pragmatic listener
var pragmaticListener = cache(function(utt, access) {
  return Infer({model: function(){
    var state = statePrior()
    observe(speaker(state, access), utt)
    return numTrue(state)
  }})
});

print("pragmatic listener for a full-access speaker:")
viz(pragmaticListener('some', [true,true,true]))
print("pragmatic listener for a partial-access speaker:")
viz(pragmaticListener('some', [true,true,false]))

~~~~

> **Exercise:**

> 1. Check the predictions for the other possible knowledge states.
> 2. Compare the full-access predictions with the predictions from the simpler scalar implicature model above. Why are the predictions of the two models different? How can you get the model predictions to converge? (Hint: first try to align the predictions of the simpler model with those of the knowledge model, then try aligning the predictions of the knowledge model with those of the simpler model.)

We have seen how the RSA framework can implement the mechanism whereby utterance interpretations are strengthened. Through an interaction between what was said, what could have been said, and what all of those things literally mean, the model delivers scalar implicature. And by taking into account awareness of the speaker's knowledge, the model successfully *blocks* implicatures in those cases where listeners are unlikely to access them.

In RSA, speakers try to optimize information transmission. It seems like it would have nothing to say, then, about situations where speakers produce utterances that are *literally false*, as in  "I had to wait a million years to get a table last night!"
In the [next chapter](03-nonliteral.html), we'll see how expanding the range of communicative goals of the speaker can lead listeners to infer nonliteral interpretations of utterances.
