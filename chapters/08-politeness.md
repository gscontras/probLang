---
layout: chapter
title: Social reasoning about social reasoning
description: "Politeness"
---

### Chapter 8: Politeness

When using language, speakers aim to get listeners to believe the things that they believe.
But sometimes, we don't want listeners to know *exactly* how we feel.
Imagine your date bakes you a batch of flax seed, sugar-free, gluten-free cookies before your big presentation next week.
(What a sweetheart.)
You are grateful for them---something to take your mind off impending doom.
But then you bite into them, and you wonder if they actually qualify as cookies and not just seed fragments glued together.
Your date asks you what you think.
You look up and say "They're good."

Politeness violates a critical principle of cooperative communication: exchanging information efficiently and accurately.
If information transfer was the only currency in communication, a cooperative speaker would find polite utterances undesirable because they are potentially misleading.
But polite language use is critical to making sure your date doesn't charge out of the room before you can qualify what you meant by the more truthful and informative "These cookies are not good".

Brown and Levinson (1987) recast the notion of a cooperative speaker as one who has both an epistemic goal to improve the listener’s knowledge state as well as a social goal to minimize any potential damage to the hearer’s (and the speaker’s own) self-image, which they called *face*. [Yoon, Tessler, et al. (2016)](http://langcog.stanford.edu/papers_new/yoon-2016-cogsci.pdf) formalize a version of this idea in the RSA framework by introducing a new component to the speaker's utility function: social utility.

### A new speaker

The usual speaker utility from RSA is a surprisal-based, epistemic utility:

$$
U_{epistemic}(w; s) = \ln(P_{L_0}(s \mid w))
$$

Social utility is the expected subjective utility of the state the listener would infer given the utterance $$w$$:

$$
U_{social}(w; s) = \mathbb{E}_{P_{L_0}(s \mid w)}[V(s)]
$$

where $$V$$ is a value function that maps states to subjective utility values---this captures the affective consequences for the listener of being in state $s$.

Speaker utility is then a mixture of these components:

$$
U(w; s; \phi) = \phi \cdot U_{epistemic} + (1 - \phi) \cdot U_{social}
$$

Note that at this point, we do not differentiate state value to the listener from state value to the speaker, though in many situations these could in principle be different.
Also at this point, we do not allow for *deception* or *meanness*, which would be exact opposite of epistemic and social utilities, respectively --- though this could very naturally be incorporated. (In Yoon, Tessler, et al., 2016, they do investigate *meanness* by having independent weights on the two utilities. For simplicity, we adopt the notation of [Yoon et al. 2017](http://langcog.stanford.edu/papers_new/yoon-2017-cogsci.pdf), in which they describe utility as a simpler mixture-model.)

In WebPPL, this looks like the following:

~~~~ norun
var utility = {
  epistemic: literalListener.score(state),
  social: expectation(literalListener, valueFunction)
};
var speakerUtility = phi * utility.epistemic + (1 - phi) * utility.social
~~~~

`expectation` computes the expected value (or mean) of the distribution supplied to it as the first argument.
The second argument is an optional *projection function*, for when you want the expectation computed with respect to some transformation of the distribution (technically: a transformation of the support of the distribution).
Here, `valueFunction` projects the listener's distribution from world states onto subjective valuations of those world states (e.g., the subjective value of a listener believing the cookies they baked were a 4.5 out of 5 stars).

We consider a simplified case study of the example given at the beginning.
The listener has completed some task or product (e.g., baked some cookies) and solicits the speaker's feedback.
Performance on the task has some scale, ranging from 1 - 5 hearts (like an online review of a product: 5 hearts is the best the speaker could feel about it; 1 heart is the worst).
These are the states of the world that the speaker can be informative with respect to.
For example, the speaker may think the cookies deserve 2 out of 5 hearts.

At the same time, these states of the world also have some inherent subjective value: 5 hears is better than 3 hearts.
`phi` governs how much the speaker seeks to communicate information about the state vs. make the listener believe she is a highly valued state.

~~~~
var states = [1,2,3,4,5]
var utterances = ["terrible","bad","okay","good","amazing"]

// correspondence of utterances to states (empirically measured)
var literalSemantics = {
  "terrible":[.95,.85,.02,.02,.02],
  "bad":[.85,.95,.02,.02,.02],
  "okay":[0.02,0.25,0.95,.65,.35],
  "good":[.02,.05,.55,.95,.93],
  "amazing":[.02,.02,.02,.65,0.95]
}

// determine whether the utterance describes the state
// by flipping a coin with the literalSemantics weight
// ... state - 1 because of 0-indexing
var meaning = function(utterance, state){
  return flip(literalSemantics[utterance][state - 1]);
};

// value function scales social utility by a parameter lambda
var lambda = 1.25 // value taken from MAP estimate from Yoon, Tessler, et al. 2016
var valueFunction = function(s){
  return lambda * s
};

// literal listener
var listener0 = function(utterance) {
  Infer({model: function(){
    var state = uniformDraw(states);
    var m = meaning(utterance, state);
    condition(m);
    return state;
  }})
};

var alpha = 10; // MAP estimate from Yoon, Tessler, et al. 2016
var speaker1 = function(state, phi) {
  Infer({model: function(){

    var utterance = uniformDraw(utterances);
    var L0_posterior = listener0(utterance);

    var utility = {
      epistemic: L0_posterior.score(state),
      social: expectation(L0_posterior, valueFunction)
    };

    var speakerUtility = phi * utility.epistemic +
                        (1 - phi) * utility.social

    factor(alpha * speakerUtility);

    return utterance;
  }})
};

speaker1(1, 0.99)
~~~~

> **Exercises**:

> 1. What kind of speaker is assuming with the above function call (`speaker(1, 0.99)`)?
> 2. Change the call to the speaker to make it so that it only cares about making the listener feel good.
> 3. Change the call to the speaker to make it so that it cares about both making the listener feel good and conveying information.


### A listener who understands politeness

~~~~
///fold:
var states = [1,2,3,4,5]
var utterances = ["terrible","bad","okay","good","amazing"]

// correspondence of utterances to states (empirically measured)
var literalSemantics = {
  "terrible":[.95,.85,.02,.02,.02],
  "bad":[.85,.95,.02,.02,.02],
  "okay":[0.02,0.25,0.95,.65,.35],
  "good":[.02,.05,.55,.95,.93],
  "amazing":[.02,.02,.02,.65,0.95]
}

// determine whether the utterance describes the state
// by flipping a coin with the literalSemantics weight
// ... state - 1 because of 0-indexing
var meaning = function(utterance, state){
  return flip(literalSemantics[utterance][state - 1]);
};

// value function scales social utility by a parameter lambda
var lambda = 1.25 // value taken from MAP estimate from Yoon, Tessler, et al. 2016
var valueFunction = function(s){
  return lambda * s
};

// literal listener
var listener0 = cache(function(utterance) {
  Infer({model: function(){
    var state = uniformDraw(states);
    var m = meaning(utterance, state);
    condition(m);
    return state;
  }})
});

var alpha = 10; // MAP estimate from Yoon, Tessler, et al. 2016
var speaker1 = cache(function(state, phi) {
  Infer({model: function(){

    var utterance = uniformDraw(utterances);
    var L0_posterior = listener0(utterance);

    var utility = {
      epistemic: L0_posterior.score(state),
      social: expectation(L0_posterior, valueFunction)
    };

    var speakerUtility = phi * utility.epistemic +
                        (1 - phi) * utility.social

    factor(alpha * speakerUtility);

    return utterance;
  }})
});
///


var pragmaticListener = function(utterance) {
  Infer({model: function(){

    var state = uniformDraw(states)
    var phi = uniformDraw([0.1, 0.3, 0.5, 0.7, 0.9])
    var S1 = speaker1(state, phi)

    observe(S1, utterance)

    return { state, phi }

  }})
}

var listenerPosterior = pragmaticListener("good")

display("expected state = " +
        expectation(marginalize(listenerPosterior, "state")))
viz(marginalize(listenerPosterior, "state"))

display("expected phi = " +
        expectation(marginalize(listenerPosterior, "phi")))
viz.density(marginalize(listenerPosterior, "phi"))
~~~~

Above, we have a listener who hears that they did "good" and infers how well they actually did, as well as how much the speaker values honesty vs. kindness.

> **Exercises**:

> 1. Examine the marginal posteriors on `state`. Does this make sense? Compare it to what the `literalListener` would believe upon hearing the same.
> 2. Examine the marginal posterior on `phi`. Does this make sense? What utterance would make the `pragmaticListener` infer something different about `phi`? Test your knowledge by running that utterance through the `pragmaticListener`?
> 3. In Yoon, Tessler, et al. (2017), the authors ran an experiment testing participants' intuitions if they knew what kind of speaker they were dealing with (i.e., knew `phi`). Modify `pragmaticListener` so that she knows the speaker (a) wants the listener to feel good, (b) wants to convey information to the listener, and (c) both, and test the models on the utterance "good".
> 4. The authors also ran an experiment testing participants' intuitions if they knew what state of the world they were in. Modify `pragmaticListener` so that she knows what state of the world she is in. Come up with your own interesting situations (i.e., choose a state and an utterance) and show the model predictions. Are the predictions in accord with your intuitions? Why or why not?


### Indirect polite speech acts

...TO DO...

<!-- Here is the full politeness model from [Yoon et al. (2017)](http://langcog.stanford.edu/papers_new/yoon-2017-underrev.pdf): -->

~~~~
// helper function split utterances at "_" to find negation
var isNegation = function(utt){
  return (utt.split("_")[0] == "not")
};

// helper function to calculate marginal distribution
var marginalize = function(dist, key){
  return Infer({model: function(){ sample(dist)[key] }})
}

// helper function to round
var round = function(x){
  return Math.round(x * 100) / 100
}

// possible utterances (both positive and negative)
var utterances = [
  "yes_terrible","yes_bad","yes_okay","yes_good","yes_amazing",
  "not_terrible","not_bad","not_okay","not_good","not_amazing"
];

// utterance costs (negative utterance more expensive)
var cost_yes = 1;
var cost_neg = 2;

var uttCosts = map(function(u) {
  return isNegation(u) ? Math.exp(-cost_neg) : Math.exp(-cost_yes)
}, utterances)

// utterance prior
var utterancePrior = Infer({model: function(){
  return utterances[discrete(uttCosts)]
}});

// possible states of the world (cf. Yelp reviews)
var states = [1,2,3,4,5];

// info for epistemic vs. social utility prior;
// 1 corresponds to fully favoring epistemic utility
var weightBins = map(round, _.range(0,1, 0.05))
var phiWeights = repeat(weightBins.length, function(){1})


// pragmatic listener
// infers the state and the speaker's goals (i.e., phi)
var listener1 = cache(function(utterance) {
  Infer({model: function(){

    var speakerGoals = {
      // sample from speaker goal prior
      phi: categorical({vs: weightBins, ps: phiWeights})
    }
    var state = uniformDraw(states);

    var S1 = speaker1(state, speakerGoals)
    observe(S1, utterance)

    return {
      state: state,
      goals: speakerGoals
    }

  }})
}, 10000);

// pragmatic speaker
var speakerOptimality2 = 2;

var speaker2 = cache(function(state, informativeness) {
  Infer({model: function(){

    var utterance = sample(utterancePrior);
    var intendedGoals = {phi: informativeness}

    var L1 = listener1(utterance)
    var L1_state = marginalize(L1, "state");

    // align both the intended state and the intended goals (i.e., informativeness)
    factor(speakerOptimality2 * L1.score({"state":state, "goals":intendedGoals}))

    return isNegation(utterance) ? "negation" : "direct"

  }})
}, 10000);

display("listener hears 'it wasn't amazing'; how bad was it?")
var l1 = listener1("not_amazing")
viz(marginalize(l1, "state"))
display("how much was the speaker trying to be informative (vs kind)?")
viz(marginalize(l1, "goals"))

display("listener hears 'it was terrible'; how bad was it?")
var l1a = listener1("yes_terrible")
viz(marginalize(l1a, "state"))

display("how much was the speaker trying to be informative (vs kind)?")
viz(marginalize(l1a, "goals"))

display("speaker thinks it's terrible, tries to be nice")
var s2_nice  = speaker2(1, 0.05)
viz(s2_nice)

display("speaker thinks it's terrible, tries to be informative")
var s2_informative  = speaker2(1, 0.95)
viz(s2_informative)

display("speaker thinks it's terrible, tries to be both nice and informative")
var s2_both  = speaker2(1, 0.5)
viz(s2_both)

~~~~
