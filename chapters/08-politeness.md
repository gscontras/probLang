---
layout: chapter
title: Social reasoning about social reasoning
description: "Politeness"
---

### Chapter 8: Politeness

When using language, speakers aim to get listeners to believe the things that they believe. But sometimes, we don't listeners to know *exactly* how we feel. Imagine your date bakes you a batch of flax seed, sugar-free, gluten-free cookies before your big presentation next week. (What a sweetheart.) You are grateful for them, something to take your mind off impending doom. But then you bite into them, and you wonder if they actually qualify as cookies and not just seed fragments glued together. Your date asks you what you think. You smile and say "They're good."

Politeness violates a critical principle of cooperative communication: exchanging information efficiently and accurately. If information transfer was the only currency in communication, a cooperative speaker would find polite utterances undesirable because they are potentially misleading. But polite language use is critical to making sure your date doesn't charge out of the room before you can qualify what you meant by the truthful and informative "These cookies are not good".

Brown and Levinson (1987) recast the notion of a cooperative speaker as one who has both an epistemic goal to improve the listener’s knowledge state as well as a social goal to minimize any potential damage to the hearer’s (and the speaker’s own) self-image, which they called *face*. [Yoon, Tessler, et al. (2016)](http://langcog.stanford.edu/papers_new/yoon-2016-cogsci.pdf) formalize this idea in the RSA framework by decomposing the speaker's utility function into two components: 1) epistemic utility and 2) social utility.

Epistemic utility is the normal surprisal-based utility from RSA.

$$
U_{epistemic}(w; s) = \ln(P_{L_0}(s \mid w))
$$

Social utility is the expected utility of the state the listener would infer given the utterance $$w$$:

$$
U_{social}(w; s) = \mathbb{E}_{P_{L_0}(s \mid w)}[V(s)]
$$

where $$V$$ is a value function that maps states to subjective utility values---this captures the affective consequences for the listener of being in state $s$.

Speaker utility is then a mixture of these components:

$$
U(w; s; \phi) = \phi \cdot U_{epistemic} + (1 - \phi) \cdot U_{social}
$$

Note that at this point, we do not differentiate state value to the listener from state value to the speaker, though in many situations these could in principle be different.
Also at this point, we do not allow for *deception* or *meanness*, which would be exact opposite of epistemic and social utilities, respectively --- though this could very naturally be incorporated. 

In WebPPL, this looks like the following:

~~~~ norun
var utility = {
  epistemic: literalListener.score(state),
  social: expectation(literalListener, valueFunction)
};
var speakerUtility = phi * utility.epistemic + (1 - phi) * utility.social
~~~~

where `valueFunction` projects the listener's distribution on world states onto subjective valuations of those world states (e.g., the subjective value of a listener believing the cookies they baked were a 4.5 out of 5 stars).


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

// probability an utterance describing a state
var literalSemantics = {
  "state": [1, 2, 3, 4, 5],
  "not_amazing": [0.9925, 0.9186, 0.7876, 0.2321, 0.042],
  "not_bad": [0.0075, 0.2897, 0.8514, 0.8694, 0.8483],
  "not_good": [0.9926, 0.8871, 0.1582, 0.0073, 0.0081],
  "not_okay": [0.9198, 0.7652, 0.1063, 0.0074, 0.1192],
  "not_terrible": [0.0415, 0.4363, 0.9588, 0.9225, 0.9116],
  "yes_amazing": [0.0077, 0.0077, 0.0426, 0.675, 0.9919],
  "yes_bad": [0.9921, 0.9574, 0.0078, 0.0078, 0.0079],
  "yes_good": [0.008, 0.0408, 0.8279, 0.9914, 0.993],
  "yes_okay": [0.0078, 0.286, 0.9619, 0.7776, 0.6122],
  "yes_terrible": [0.9593, 0.5217, 0.0753, 0.008, 0.044]
};

// determine whether the utterance describes the state
// by flipping a coin with the literalSemantics weight
var meaning = function(utterance, state){
  return flip(literalSemantics[utterance][state - 1]);
};

// literal listener
var listener0 = cache(function(utterance) {
  Infer({model: function(){
    var state = uniformDraw(states);
    var m = meaning(utterance, state);
    condition(m);
    return state;
  }})
}, 10000);

// speaker
var speakerOptimality = 5;

var speaker1 = cache(function(state, speakerGoals) {
  Infer({model: function(){

    var utterance = sample(utterancePrior);
    var L0 = listener0(utterance);

    var epistemicUtility = L0.score(state);
    var socialUtility = expectation(L0, function(s){return s});
    var eUtility = speakerGoals.phi*epistemicUtility;
    var sUtility = (1-speakerGoals.phi)*socialUtility;
    var speakerUtility = eUtility+sUtility;

    factor(speakerOptimality*speakerUtility);

    return utterance;
  }})
}, 10000);

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
