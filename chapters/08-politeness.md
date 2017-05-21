---
layout: chapter
title: Social reasoning about social reasoning
description: "Politeness"
---

### Chapter 8: Politeness

When we speak, we simultaneously address many goals. Among those goals are the desires to be informative and polite. Unfortunately, being polite often conflicts with informativity, especially in sensitive situations. To address this conflict, [Yoon et al. (2017)](http://langcog.stanford.edu/papers_new/yoon-2017-underrev.pdf) developed the following model of polite indirect discourse, which decomposes the speaker's ulity function into two componets: 1) epistemic utility, and 2) social utility. 
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
