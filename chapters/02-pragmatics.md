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
}
statePrior() // sample a state
~~~~

> **Exercises:**

> 1. Try visualizing `statePrior()` by drawing many samples and plotting the output (hint: you'll need to use the `repeat()` function, which has a strange syntax that is documented [here](http://webppl.readthedocs.io/en/master/functions/arrays.html#repeat)).
> 2. Try visualizing `statePrior()` by wrapping it in `Infer` (à la our $$L_0$$ model) and using `{method: "forward", samples: 1000}`.

Next, assume that speakers may describe the current state of the world in one of three ways:

~~~~
// possible utterances
var utterancePrior = function() {
  return uniformDraw(['all', 'some', 'none'])
}

// meaning function to interpret the utterances
var literalMeanings = {
  all: function(state) { return state === 3; },
  some: function(state) { return state > 0; },
  none: function(state) { return state === 0; }
}

var utt = utterancePrior() // sample an utterance
var meaning = literalMeanings[utt] // get its meaning
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

Let us then look at the speaker's behavior. Intuitively put, in the vanilla RSA model the speaker will never choose a false message and prefers to send one true message over another, if the former has a smaller extension than the latter (see [appendix](app-01-utilities.html)). Verify this with the following code.

~~~~
// code for state prior, semantics and literal listener as before
///fold:
// possible states of the world
var statePrior = function() {
  return uniformDraw([0, 1, 2, 3])
}

// possible utterances
var utterancePrior = function() {
  return uniformDraw(['all', 'some', 'none'])
}

// meaning function to interpret the utterances
var literalMeanings = {
  all: function(state) { return state === 3; },
  some: function(state) { return state > 0; },
  none: function(state) { return state === 0; }
}

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
}

// possible utterances
var utterancePrior = function() {
  return uniformDraw(['all', 'some', 'none'])
}

// meaning function to interpret the utterances
var literalMeanings = {
  all: function(state) { return state === 3; },
  some: function(state) { return state > 0; },
  none: function(state) { return state === 0; }
}

// literal listener
var literalListener = cache(function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    var meaning = literalMeanings[utt]
    condition(meaning(state))
    return state
  }})
})

// set speaker optimality
var alpha = 1

// pragmatic speaker
var speaker = cache(function(state) {
  return Infer({model: function(){
    var utt = utterancePrior()
    factor(alpha * literalListener(utt).score(state))
    return utt
  }})
})

// pragmatic listener
var pragmaticListener = cache(function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    observe(speaker(state),utt)
    return state
  }})
})

display("pragmatic listener's interpretation of 'some':")
viz(pragmaticListener('some'))

~~~~

> **Exercises:**

> 1. Explore what happens if you make the speaker *less* optimal.
> 2. Subtract one of the utterances. What changed?
> 3. Add a new utterance. What changed?
<<<<<<< HEAD
> 4. Check what would happen if 'some' literally meant some-but-not-all.
> 5. Change the relative prior probabilities of the various states.
=======
> 4. Check what would happen if 'some' literally meant some-but-not-all (hint: use `!=` to assert that two values are not equal).
> 5. Change the relative probabilities of the various states and see what happens to model predictions.
>>>>>>> upstream/gh-pages


#### Application 2: Scalar implicature and speaker knowledge

##### Setting the scene

Capturing scalar implicature within the RSA framework might not induce waves of excitement. However, by implementing implicature-calculation within a formal model of communication, we can also capture its interactions with other pragmatic factors. reft:GoodmanStuhlmuller2013Impl explored what happens when the speaker possibly only has partial knowledge about the state of the world. Below, we explore this model, taking into account the listener's beliefs about the speaker's beliefs about the world, and the way these higher-order listener beliefs may change when hearing an utterance.

Many traditional approaches to scalar implicature calculation follow what reft:Geurts2010:Quantity-Implic calls the **standard recipe**:

1. the speaker used *some*
2. one reason why the speaker did not use *all* instead is that she does not know whether it is true
3. the speaker is assumed to be epistemically competent, i.e., she knows whether it is "all" or "some but not all" [**Competence Assumption**] 
4. so, she knows that the *all* sentence is actually false
5. if the speaker knows it, it must be true (by veridicality of knowledge)

Crucially, the standard recipe requires the Competence Assumption to derive a strong scalar implicature about the way the world is. Without the competence assumption, we only derive the *weak epistemic implicature*: that the speaker does not know that *all* is true.

From a probabilistic perspective, this is way too simple. Probabilistic modeling, aided by probabilistic programming tools, lets us explore a richer and more intuitive picture. In this picture, the listener may have probabilistic beliefs about the degree to which the speaker is in possession of the relevant facts. While these gradient prior beliefs of the listener about the speaker's likely competence matter to the interpretation of an utterance, hearing an utterance may also dynamically change these beliefs.

<img src="../images/scalar.png" alt="Fig. 3: Example communication scenario from Goodman and Stuhmüller." style="width: 500px;"/>
<center>Fig. 1: Example communication scenario from Goodman and Stuhmüller: How will the listener interpret the speaker’s utterance? How will this change if she knows that he can see only two of the objects? What does the listener infer from an utterance about the likely number of apples the speaker has seen the color of?</center>

<<<<<<< HEAD
reft:GoodmanStuhlmuller2013Impl explore a concrete scenario where such complex epistemic inferences can be studied systematically (Fig. 1 above). Suppose there are $$n$$ apples in total of which $$0 \le s \le n$$ are red. The speaker knows $$n$$ (as does the listener) but the speaker might only observe some of the apples' colors. Concretely, the speaker might only have access to $$0 \le a \le n$$ apples, of which she observes $$0 \le o \le a$$ to be red. If she communicates her observation with a statement like "Some of the apples are red", the listener performs a **joint inference** of the true world state $$s$$, the access $$a$$ and the observation $$o$$:
=======
In the extended Scalar Implicature model, the pragmatic listener infers the true state of the world not only on the basis of the observed utterance, but also the speaker's epistemic access $$a$$.
>>>>>>> upstream/gh-pages

$$P_{L_{1}}(s, a, o \mid u) \propto P_{S_{1}}(u\mid a, o) \cdot P(s,a,o)$$

~~~~
// pragmatic listener
var pragmaticListener = function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    var access = accessPrior()
    var observed = observePrior()
    factor(Math.log(hypergeometricPMF(observed, total_apples,
                                      state, access)))
    observe(speaker(access, observed), utt)
    return {state, access, observed}
  }})
}
~~~~

##### Modeling beliefs after partial observations

What does a speaker believe about the world state $$s$$ after, say, having access to $$a$$ out of $$n$$ apples and seeing that $$o$$ of the accessed apples are red? - This depends on the speaker's prior beliefs about how likely red apples are in general. Let us assume that these prior beliefs are given by a binomial distribution with a fixed base rate of redness: intuitively put, each apple has a chance `base_rate` of being red; how many red apples do we expect given that we have `total_apples`?

~~~~
// total number of apples (known by speaker and listener)
var total_apples = 3

// red apple base rate
var base_rate_red = 0.8

// state = how many apples of 'total_apples' are red?
var statePrior = function() {
  binomial({p: base_rate_red, n: total_apples})
}

viz(Infer({model: statePrior, method: "forward", samples: 5000}))
~~~~

> Exercise: Play around with `total_apples` and `base_rate_red` to get good intuitions about the state prior for different parameters. (For which values of `total_apples` and `base_rate_red` would you better take more samples for a more precise visualization?)

A world state `state` (a single sample from the `statePrior`) gives the true, actual number of red apples. If the world state was known to the speaker, his beliefs for any pair of access `access` to apples and observations `observed` of red apples are given by a so-called [Hypergeometric distribution](https://en.wikipedia.org/wiki/Hypergeometric_distribution). The Hypergeometric distribution gives the probability of retrieving `observed` red balls when drawing `access` balls without replacement from an urn which contains `total_apples` balls in total of which `state` are red. (This distribution is not implemented in WebPPL, so we implement its probability mass function by hand.)

~~~~

var factorial = function(x) {
  if (x < 0) {return "input to factorial function must be non-negative"}
  return x == 0 ? 1 : x * factorial(x-1)
}

var binom = function(a, b) {
  var numerator = factorial(a)
  var denominator = factorial(a-b) *  factorial(b)
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
viz(Infer({model: function() {hypergeometricSample(total_apples, state, access)},
           method: "forward",
           samples: 2500}))
~~~~

The prior over states and the hypergeometric distribution combine to give the speaker's beliefs about world state $$s$$ given access $$a$$ and observation $$o$$, using Bayes rule (and knowledge of the total number of apples $$n$$):

$$P_{S_1}(s \mid a, o) \propto \text{Hypergeometric}(o \mid s, a, n) \ \text{Binomial}(s \mid \text{baserate, n}) $$

~~~~

// code for hypergeometric 
///fold:
var factorial = function(x) {
  if (x < 0) {return "input to factorial function must be non-negative"}
  return x == 0 ? 1 : x * factorial(x-1)
}

var binom = function(a, b) {
  var numerator = factorial(a)
  var denominator = factorial(a-b) *  factorial(b)
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

Given potential uncertainty about the world state $$s$$, the speaker's probabilistic production rule has to be generalized. It is now no longer a function of the true $$s$$ (because it might not be known) but of the epistemic state of the speaker more generally. In the case at hand, the speaker's epistemic state $$P_{S_{1}}(\cdot \mid o,a) \in \Delta(S)$$ is given by access $$a$$, observation $$o$$ and the rational belief model introduced previously. reft:GoodmanStuhlmuller2013Impl give a straightforward extension of the speaker choice rule from the vanilla RSA model discussed in [chapter I](01-introduction.html). The speaker chooses an utterance based on the **expected utility**, given her belief state $$P_{S_{1}}(\cdot \mid o,a)$$:

$$P_{S_{1}}(u \mid o, a) \propto \exp(\alpha \ \mathbb{E}_{P(s \mid o, a)}[U(u; s)])$$

The speaker's utility function remains unchanged, so that utterances are chosen to minimize cost and maximize informativity.

$$U_{S_{1}}(u; s) = log(L_{0}(s\mid u)) - C(u)$$

~~~~
// expected utilities
var get_EUs = function(access, observed, utterance){
  var EUs = sum(map(function(s) {
      var eu_at_state = Math.exp(belief(access, observed).score(s)) *
          literalListener(utterance).score(s)
      _.isNaN(eu_at_state) ? 0 : eu_at_state // convention here: 0*-Inf=0
    }, _.range(total_apples + 1)))
  return EUs
}

// pragmatic speaker
var speaker = function(access, observed) {
  return Infer({model: function(){
    var utterance = utterancePrior()
    var EUs = get_EUs(access, observed, utterance)
    factor(alpha * EUs)
    return utterance
  }})
}
~~~~

An equivalently motivation for this speaker model is that the speaker chooses an utterance with the goal of minimizing the (Kullback-Leibler) divergence between her belief state $$P_{S_{1}}(\cdot \mid o,a)$$ and that of the literal listener $$P_{L_0}(\cdot \mid u)$$. Details are in [appendix chapter I](app-01-utilities.html).

There is one important bit to notice about this definition. In the vanilla RSA model of the previous chapter, the speaker will never say anything false. The present conservative extension makes it so that an uncertain speaker will never use an utterance whose truth the speaker is not absolutely convinced of. In other words, as long as $$P_{S_{1}}(\cdot \mid o,a)$$ puts positive probability on a state $$s$$ for which utterance $$u$$ is false, the speaker will *never* use $$u$$ in epistemic state $$\langle o, a \rangle$$. This is because $$\log P_{L_0}(s \mid u)$$ is negative infinity if $$u$$ is false of $$s$$ and so the expected utility (which is a weighted sum) will be negative infinity as well, unless $$P_{S_{1}}(s \mid o,a) = 0$$. As a consequence, we need to make sure in the model that the speaker always has something true to say for all pairs of $$a$$ and $$o$$. We do this by including a "null utterance", which is like saying nothing. (See also [chapter V](05-vagueness.html) and reft:PottsLassiter2016:Embedded-implic for a similar use of a "null utterance".) 

Adding a set of utterances, an utterance prior and the literal listener, we obtain a full speaker model.

~~~
// red apple base rate
var total_apples = 3
var base_rate_red = 0.8

// state = how many apples of 'total_apples' are red?
var statePrior = function() {
  binomial({p: base_rate_red, n: total_apples})
}

// binomial-hypergeometric belief model
///fold:
var factorial = function(x) {
  if (x < 0) {return "input to factorial function must be non-negative"}
  return x == 0 ? 1 : x * factorial(x-1)
}

var binom = function(a, b) {
  var numerator = factorial(a)
  var denominator = factorial(a-b) *  factorial(b)
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
///

// utterance prior
var utterancePrior = function() {
  categorical({vs: ['all','some','none','null'],
               ps: [1,1,1,0.0000001]})
}

// meaning function to interpret utterances
var literalMeanings = {
  all:  function(state) { state == total_apples },
  some: function(state) { state > 0 },
  none: function(state) { state == 0 },
  null: function(state) { state >= 0 }
}

// literal listener
var literalListener = cache(function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    var meaning = literalMeanings[utt]
    condition(meaning(state))
    return state
  }})
})

// set speaker optimality
var alpha = 1

// expected utilities
var get_EUs = function(access, observed, utterance){
  var EUs = sum(map(function(s) {
      var eu_at_state = Math.exp(belief(access, observed).score(s)) *
          literalListener(utterance).score(s)
      _.isNaN(eu_at_state) ? 0 : eu_at_state // convention here: 0*-Inf=0
    }, _.range(total_apples + 1)))
  return EUs
}

// pragmatic speaker
var speaker = cache(function(access, observed) {
  return Infer({model: function(){
    var utterance = utterancePrior()
    var EUs = get_EUs(access, observed, utterance)
    factor(alpha * EUs)
    return utterance
  }})
})

viz(speaker(2,1))
~~~

> Exercises

> 1. Test the speaker model for different parameter values. Also change `total_apples` and `base_rate_red`.
> 2. When does the speaker use the "null" utterance?

##### Full model with pragmatic listener

###### Inference when access value is known

A key intuition (which Goodman and Stuhlmüller validate experimentally) is that in cases where the listener knows that the speaker has partial knowledge access (say, $$a = 2$$, i.e., she knows about only two out of three relevant apples), the listener will be less likely to calculate the implicature (because he knows that the speaker doesn't have the evidence to back up the strengthened meaning).

~~~~
// red apple base rate
var total_apples = 3
var base_rate_red = 0.8

// state = how many apples of 'total_apples' are red?
var statePrior = function() {
  binomial({p: base_rate_red, n: total_apples})
}

// binomial-hypergeometric belief model
///fold:
var factorial = function(x) {
  if (x < 0) {return "input to factorial function must be non-negative"}
  return x == 0 ? 1 : x * factorial(x-1)
}

var binom = function(a, b) {
  var numerator = factorial(a)
  var denominator = factorial(a-b) *  factorial(b)
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
///

// speaker model (as before)
///fold:

// utterance prior
var utterancePrior = function() {
  categorical({vs: ['all','some','none','null'],
               ps: [1,1,1,0.0000001]})
}

// meaning function to interpret utterances
var literalMeanings = {
  all:  function(state) { state == total_apples },
  some: function(state) { state > 0 },
  none: function(state) { state == 0 },
  null: function(state) { state >= 0 }
}

// literal listener
var literalListener = cache(function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    var meaning = literalMeanings[utt]
    condition(meaning(state))
    return state
  }})
})

// set speaker optimality
var alpha = 1

// expected utilities
var get_EUs = function(access, observed, utterance){
  var EUs = sum(map(function(s) {
      var eu_at_state = Math.exp(belief(access, observed).score(s)) *
          literalListener(utterance).score(s)
      _.isNaN(eu_at_state) ? 0 : eu_at_state // convention here: 0*-Inf=0
    }, _.range(total_apples + 1)))
  return EUs
}

// pragmatic speaker
var speaker = cache(function(access, observed) {
  return Infer({model: function(){
    var utterance = utterancePrior()
    var EUs = get_EUs(access, observed, utterance)
    factor(alpha * EUs)
    return utterance
  }})
})
///


var observePrior = function(){
  uniformDraw(_.range(total_apples + 1))
}

var pragmaticListener = cache(function(utt, access) {
  return Infer({method: "enumerate",
//                 strategy: "breadthFirst",
                model: function(){
    var state = statePrior()
    var observed = observePrior()
    factor(Math.log(hypergeometricPMF(observed, total_apples,
                                      state, access)))
    observe(speaker(access, observed), utt)
    return {state}
  }})
});

viz(pragmaticListener("some", 2))

~~~~

> **Exercise:**

> 1. Check the predictions for the other possible access values.
> 2. Compare the full-access predictions with the predictions from the simpler scalar implicature model above. Why are the predictions of the two models different? How can you get the model predictions to converge? (Hint: first try to align the predictions of the simpler model with those of the knowledge model, then try aligning the predictions of the knowledge model with those of the simpler model.)

###### Joint inference of world state, access and observation

If the pragmatic listener does not know the number $$a$$ of apples that the speaker saw, the listener can nevertheless infer likely values for $$a$$, given an utterance. In fact, the listener can make a joint inference of $$s$$, $$a$$ and $$o$$, all of which are unknown to him, but all of which feed into the speaker's utterance probabilities. The posterior inference of $$a$$ is particularly interesting because it is a probabilistic inference of the speaker's competence, mediated by what the speaker said.

~~~~
// red apple base rate
var total_apples = 3
var base_rate_red = 0.8

// state = how many apples of 'total_apples' are red?
var statePrior = function() {
  binomial({p: base_rate_red, n: total_apples})
}

// binomial-hypergeometric belief model
///fold:
var factorial = function(x) {
  if (x < 0) {return "input to factorial function must be non-negative"}
  return x == 0 ? 1 : x * factorial(x-1)
}

var binom = function(a, b) {
  var numerator = factorial(a)
  var denominator = factorial(a-b) *  factorial(b)
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
///

// speaker model (as before)
///fold:

// utterance prior
var utterancePrior = function() {
  categorical({vs: ['all','some','none','null'],
               ps: [1,1,1,0.0000001]})
}

// meaning function to interpret utterances
var literalMeanings = {
  all:  function(state) { state == total_apples },
  some: function(state) { state > 0 },
  none: function(state) { state == 0 },
  null: function(state) { state >= 0 }
}

// literal listener
var literalListener = cache(function(utt) {
  return Infer({model: function(){
    var state = statePrior()
    var meaning = literalMeanings[utt]
    condition(meaning(state))
    return state
  }})
})

// set speaker optimality
var alpha = 1

// expected utilities
var get_EUs = function(access, observed, utterance){
  var EUs = sum(map(function(s) {
      var eu_at_state = Math.exp(belief(access, observed).score(s)) *
          literalListener(utterance).score(s)
      _.isNaN(eu_at_state) ? 0 : eu_at_state // convention here: 0*-Inf=0
    }, _.range(total_apples + 1)))
  return EUs
}

// pragmatic speaker
var speaker = cache(function(access, observed) {
  return Infer({model: function(){
    var utterance = utterancePrior()
    var EUs = get_EUs(access, observed, utterance)
    factor(alpha * EUs)
    return utterance
  }})
})
///

var observePrior = function(){
  uniformDraw(_.range(total_apples + 1))
}

var accessPrior = function(){
  uniformDraw(_.range(total_apples + 1))
}

var pragmaticListener = cache(function(utt) {
  return Infer({method: "enumerate",
//                 strategy: "breadthFirst",
                model: function(){
    var state = statePrior()
    var access = accessPrior()
    var observed = observePrior()
    factor(Math.log(hypergeometricPMF(observed, total_apples,
                                      state, access)))
    observe(speaker(access, observed), utt)
    return {state, access, observed}
  }})
});

var pl = pragmaticListener("some")
display("Marginal beliefs about the true world state:")
viz(marginalize(pl, 'state'))
display("Marginal beliefs about how many apples the speaker observed in total:")
viz(marginalize(pl, 'access'))
display("Marginal beliefs about how many apples the speaker observed to be red:")
viz(marginalize(pl, 'observed'))
~~~~

> Exercises.

> 1. Does a listener, after hearing "some", increase or decrease his belief in the speaker's competence?

#### Conclusion

We have seen how the RSA framework can implement the mechanism whereby utterance interpretations are strengthened. Through an interaction between what was said, what could have been said, and what all of those things literally mean, the model delivers scalar implicature. And by taking into account awareness of the speaker's knowledge, the model successfully *blocks* implicatures in those cases where listeners are unlikely to access them. Finally, by joint probabilistic inference, we can capture the complex interdependency of beliefs about the speaker's likely knowledgability, before and after hearing a message.

In RSA, speakers try to optimize information transmission. It seems like it would have nothing to say, then, about situations where speakers produce utterances that are *literally false*, as in  "I had to wait a million years to get a table last night!"
In the [next chapter](03-nonliteral.html), we'll see how expanding the range of communicative goals of the speaker can lead listeners to infer nonliteral interpretations of utterances.
