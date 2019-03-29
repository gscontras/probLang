---
layout: chapter
title: Reasoning about semantic meaning
description: "Lexical uncertainty and intended lexical meanings"
hidden: true
---

### Chapter 8: Lexical uncertainty and intended lexical meanings

## Overview

Answers to the question "Who came to the party?", when it is contextually clear that the people we care about are Anne and Bob, can be pragmatically enriched in systemic ways (see, for instance, reft:GroenendijkStokhofThesis1984). The answer "Anne" suggests that only Anne came, but not Bob. The answer "Anne or Bob" suggests that the speaker doesn't know who came and that the speaker doesn't know that both Anne and Bob came. We will look at a model of these inferences in the first part of this chapter.

But what if the speaker says "Anne or both"? That answer suggests that the speaker considers two things possible, namely (i) that Anne came alone and that (ii) both Anne and Bob came together; the speaker appears to rule out the possibility that only Bob came. This seems straightforward enough but is actually rather tricky to explain. The reason is that, under standard assumptions, the answer "Anne" and "Anne or both" are semantically equivalent. And if two utterances are semantically equivalent, how can they be distinguished with pragmatic reasoning that builds only on top of this semantic meaning? The second part of this chapter will look at one possible solution to this problem, using reasoning about *lexical uncertainty* as discussed more systematically in reft:bergenetal2016, and a seemingly similar but a subtly different approach in terms of the speaker's *lexical intention* (i.e., the intended lexical meaning of word).

## Pragmatic interpretation of term answers

The starting point of this chapter is essentially the exact same model as the last model developed in [Chapter 2](02-pragmatics.html) where the pragmatic listener was reasoning about the true world state, the speaker's beliefs and the speaker's general level of knowledgeability. While [Chapter 2](02-pragmatics.html) applied this to reasoning about sentences like "Some of the apples are red", we apply the same set-up here to the interpretation of term answer to a WH-question.

For the example at hand, we distinguish three types of possible worlds, each of which determines who of Anne and Bob came to the party. A speaker's belief state is a non-empty set of possible worlds. Belief states contain all and only worlds compatible with the speaker's knowledge.

~~~~
///fold:
var powerset = function(set){
  if(set.length==0){
    return [set]
  }
  var r = powerset(set.slice(1)) // exlude first element
  var element = [set[0]] // first element
  var new_r = r.concat(map(function(x){ element.concat(x) }, r))
  return new_r
}
///

var worlds = ["A","B","AB"]

var belief_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

print(belief_states)
~~~~

> **Exercise:** Describe in your own words what a speaker in belief state "[A, B]" considers possible and what she rules out.

As in [Chapter 2](02-pragmatics.html), the pragmatic listener reasons about the speaker's belief state, which is unknown. The listener may nonetheless have certain prior beliefs about which belief states are more likely. The literature on exhaustive interpretation of term answers entertains the idea that interpretations depend on whether the listener believes the speaker to be knowledgeable (a.k.a. competent, an epistemic authority ...). Following this idea, we will similarly assume that the listener's prior beliefs about the speaker's likely belief state is influenced by general assumptions about the speaker's knowledgeability on the matter at hand. Belief states here are just sets of possible worlds. A speaker is then more knowledgeable if she can rule out more worlds. In the following, the `speaker_knowledgeability_level` is a numerical representation for how much more likely belief states are in which the speaker is more knowledgeable.

~~~~
///fold:
var powerset = function(set){
  if(set.length==0){
    return [set]
  }
  var r = powerset(set.slice(1)) // exlude first element
  var element = [set[0]] // first element
  var new_r = r.concat(map(function(x){ element.concat(x) }, r))
  return new_r
}

var worlds = ["A","B","AB"]

var belief_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)
///

var speaker_knowledgeability_states = [0, 1, 2, 3]

var knowledgeability_level_prior = function() {
  uniformDraw(speaker_knowledgeability_states)
}

var belief_state_prior = function(speaker_knowledgeability_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_knowledgeability_level * s.length)
    },
    belief_states
  )
  return categorical({vs: belief_states, ps: weights})
}

viz.hist(Infer({model: function(x) {belief_state_prior(3)}}))
~~~~

> **Exercise:** Explore the prior distributions over different speaker belief states for different levels of speaker knowledgeability. Is the speaker assumed to be more knowledgeable for speaker knowledgeability level 0 or for 3?

Next, we need some utterances to use to describe the world. We include atomic utterances (e.g., "Anne", "Bob"), as well as complex utterances formed via disjunction and conjunction. We start with a small set of alternatives and look at a larger set below.

~~~~
var utterances = [
  'Anne',
  'Bob',
  'Anne and Bob', 
  'Anne or Bob'
]

var cost_disjunction = 0.2
var cost_conjunction = 0.1

var utterance_cost = function(utterance){
  var utt_cost_table = {
    "Anne" : 0,
    'Bob' : 0,
    'Anne and Bob' : cost_conjunction, 
    'Anne or Bob' : cost_disjunction
  }
  utt_cost_table[utterance]
}

var alpha = 5

var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(- alpha * utterance_cost(utterance))
    return utterance
  }})})

~~~~

> **Exercise:** Visualize the `utterance_prior`.

Next, we need a way of interpreting our utterances. We define a function that returns the set of worlds in which each utterances is true. The literal listener just interprets utterances based on their regular semantic meaning, as usual.

~~~~
var worlds = ["A","B","AB"]

var utterance_meaning = function(utterance){
  var basic_meaning = {
    "Anne" : ["A", "AB"],
    "Bob" : ["B", "AB"],
    "Anne and Bob" : ["AB"],
    "Anne or Bob" : worlds
  }
  basic_meaning[utterance]
}

var literal_listener = cache(function(utterance, lexicon) {
  Infer({model: function() {
    var world = uniformDraw(utterance_meaning(utterance, lexicon))
    return world
  }})
})

viz.hist(literal_listener("Anne"))
viz.hist(literal_listener("Anne or Bob"))
~~~~

> **Exercise:** Are the interpretations of the literal listener for "Anne" and "Anne or Bob" what we would normally understand from these answers?

The speaker tends to send utterances that are informative about her belief state and that minimize utterance costs.

~~~~

///fold:
var powerset = function(set){
  if(set.length==0){
    return [set]
  }
  var r = powerset(set.slice(1)) // exlude first element
  var element = [set[0]] // first element
  var new_r = r.concat(map(function(x){ element.concat(x) }, r))
  return new_r
}

var worlds = ["A","B","AB"]

var belief_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

var speaker_knowledgeability_states = [0, 1, 2, 3]

var knowledgeability_level_prior = function() {
  uniformDraw(speaker_knowledgeability_states)
}

var belief_state_prior = function(speaker_knowledgeability_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_knowledgeability_level * s.length)
    },
    belief_states
  )
  return categorical({vs: belief_states, ps: weights})
}

var utterances = [
  'Anne',
  'Bob',
  'Anne and Bob', 
  'Anne or Bob'
]

var cost_disjunction = 0.2
var cost_conjunction = 0.1

var utterance_cost = function(utterance){
  var utt_cost_table = {
    "Anne" : 0,
    'Bob' : 0,
    'Anne and Bob' : cost_conjunction, 
    'Anne or Bob' : cost_disjunction
  }
  utt_cost_table[utterance]
}

var alpha = 5

var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(- alpha * utterance_cost(utterance))
    return utterance
  }})})

var utterance_meaning = function(utterance,belief_state){
  var basic_meaning = {
    "Anne" : ["A", "AB"],
    "Bob" : ["B", "AB"],
    "Anne and Bob" : ["AB"],
    "Anne or Bob" : worlds
  }
  _.min(map(
    function(s) {
      _.includes(basic_meaning[utterance], s) + 1
    },
    belief_state)) > 1
}

var literal_listener = cache(function(utterance, speaker_knowledgeability_level) {
  Infer({model: function() {
    var belief_state = belief_state_prior(speaker_knowledgeability_level)
    var meaning = utterance_meaning(utterance, belief_state)
    condition(meaning)
    return belief_state 
  }})
})

///

var speaker = cache(function(belief_state, knowledgeability){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance, knowledgeability)
           factor(alpha*listener.score(belief_state))
           return utterance
         }})})

viz(speaker(["A"], 0))
~~~~

> **Exercise:** Explore!

Finally, we add a pragmatic listener as usual.

~~~~
///fold:
var powerset = function(set){
  if(set.length==0){
    return [set]
  }
  var r = powerset(set.slice(1)) // exlude first element
  var element = [set[0]] // first element
  var new_r = r.concat(map(function(x){ element.concat(x) }, r))
  return new_r
}

var worlds = ["A","B","AB"]

var belief_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

var speaker_knowledgeability_states = [0, 1, 2, 3]

var knowledgeability_level_prior = function() {
  uniformDraw(speaker_knowledgeability_states)
}

var belief_state_prior = function(speaker_knowledgeability_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_knowledgeability_level * s.length)
    },
    belief_states
  )
  return categorical({vs: belief_states, ps: weights})
}

var utterances = [
  'Anne',
  'Bob',
  'Anne and Bob', 
  'Anne or Bob'
]

var cost_disjunction = 0.2
var cost_conjunction = 0.1

var utterance_cost = function(utterance){
  var utt_cost_table = {
    "Anne" : 0,
    'Bob' : 0,
    'Anne and Bob' : cost_conjunction, 
    'Anne or Bob' : cost_disjunction
  }
  utt_cost_table[utterance]
}

var alpha = 5

var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(- alpha * utterance_cost(utterance))
    return utterance
  }})})

var utterance_meaning = function(utterance,belief_state){
  var basic_meaning = {
    "Anne" : ["A", "AB"],
    "Bob" : ["B", "AB"],
    "Anne and Bob" : ["AB"],
    "Anne or Bob" : worlds
  }
  _.min(map(
    function(s) {
      _.includes(basic_meaning[utterance], s) + 1
    },
    belief_state)) > 1
}

var literal_listener = cache(function(utterance, speaker_knowledgeability_level) {
  Infer({model: function() {
    var belief_state = belief_state_prior(speaker_knowledgeability_level)
    var meaning = utterance_meaning(utterance, belief_state)
    condition(meaning)
    return belief_state 
  }})
})

var speaker = cache(function(belief_state, knowledgeability){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance, knowledgeability)
           factor(alpha*listener.score(belief_state))
           return utterance
         }})})
///


var listener = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledgeability = knowledgeability_level_prior(speaker_knowledgeability_states)
           var belief_state = belief_state_prior(knowledgeability)
           var speaker = speaker(belief_state,knowledgeability)
           factor(speaker.score(utterance))
           return {belief_state, knowledgeability}
         }})})
         
viz(listener("Anne"))
// viz.hist(marginalize(listener("Anne or Bob"),"belief_state"))
~~~~

> **Exercise:** Check the pragmatic listener's interpretation of "Anne and Bob". Do you like it? Try whether other parameter values are better or worse.

## The problem of semantically equivalent term answers

Let's add some more utterances to the previous model. Concretely, we change these (and only these) ingredients:

~~~~
var utterances = [
  'Anne',
  'Bob',
  'both', 
  'Anne or Bob',
  'Anne or both',
  'Bob or both',
  'Anne or Bob or both'
]

var utterance_cost = function(utterance){
  var utt_cost_table = {
    "Anne" : 0,
    'Bob' : 0,
    'both' : cost_conjunction, 
    'Anne or Bob' : cost_disjunction,
    'Anne or both' : cost_disjunction + cost_conjunction,
    'Bob or both' : cost_disjunction + cost_conjunction,
    'Anne or Bob or both' : 2* cost_disjunction + cost_conjunction
  }
  utt_cost_table[utterance]
}

var utterance_meaning = function(utterance,belief_state){
  var basic_meaning = {
    "Anne" : ["A", "AB"],
    "Bob" : ["B", "AB"],
    "both" : ["AB"],
    "Anne or Bob" : worlds,
    "Anne or both" : ["A", "AB"],
    "Bob or both" : ["B", "AB"],
    'Anne or Bob or both' : worlds
  }
  _.min(map(
    function(s) {
      _.includes(basic_meaning[utterance], s) + 1
    },
    belief_state)) > 1
}
~~~~

Here is the full model:

~~~~
///fold:
var powerset = function(set){
  if(set.length==0){
    return [set]
  }
  var r = powerset(set.slice(1)) // exlude first element
  var element = [set[0]] // first element
  var new_r = r.concat(map(function(x){ element.concat(x) }, r))
  return new_r
}

var worlds = ["A","B","AB"]

var belief_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

var speaker_knowledgeability_states = [0, 1, 2, 3]

var knowledgeability_level_prior = function() {
  uniformDraw(speaker_knowledgeability_states)
}

var belief_state_prior = function(speaker_knowledgeability_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_knowledgeability_level * s.length)
    },
    belief_states
  )
  return categorical({vs: belief_states, ps: weights})
}

var utterances = [
  'Anne',
  'Bob',
  'both', 
  'Anne or Bob',
  'Anne or both',
  'Bob or both',
  'Anne or Bob or both'
]

var cost_disjunction = 0.2
var cost_conjunction = 0.1

var utterance_cost = function(utterance){
  var utt_cost_table = {
    "Anne" : 0,
    'Bob' : 0,
    'both' : cost_conjunction, 
    'Anne or Bob' : cost_disjunction,
    'Anne or both' : cost_disjunction + cost_conjunction,
    'Bob or both' : cost_disjunction + cost_conjunction,
    'Anne or Bob or both' : 2* cost_disjunction + cost_conjunction
  }
  utt_cost_table[utterance]
}

var alpha = 5

var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(- alpha * utterance_cost(utterance))
    return utterance
  }})})

var utterance_meaning = function(utterance,belief_state){
  var basic_meaning = {
    "Anne" : ["A", "AB"],
    "Bob" : ["B", "AB"],
    "both" : ["AB"],
    "Anne or Bob" : worlds,
    "Anne or both" : ["A", "AB"],
    "Bob or both" : ["B", "AB"],
    'Anne or Bob or both' : worlds
  }
  _.min(map(
    function(s) {
      _.includes(basic_meaning[utterance], s) + 1
    },
    belief_state)) > 1
}

var literal_listener = cache(function(utterance, speaker_knowledgeability_level) {
  Infer({model: function() {
    var belief_state = belief_state_prior(speaker_knowledgeability_level)
    var meaning = utterance_meaning(utterance, belief_state)
    condition(meaning)
    return belief_state 
  }})
})

var speaker = cache(function(belief_state, knowledgeability){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance, knowledgeability)
           factor(alpha*listener.score(belief_state))
           return utterance
         }})})
///


var listener = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledgeability = knowledgeability_level_prior(speaker_knowledgeability_states)
           var belief_state = belief_state_prior(knowledgeability)
           var speaker = speaker(belief_state,knowledgeability)
           factor(speaker.score(utterance))
           return {belief_state, knowledgeability}
         }})})
         
viz(listener("Anne"))
viz(listener("Anne or both"))
~~~~

The problem is that "Anne" and "Anne or both" are treated synonymously, and consequently receive the same pragmatic interpretation. 

## Lexical Uncertainty

One solution to this problem is to allow for reasoning about the speaker's lexical meaning of term answers "Anne" and "Bob". Here, we assume that the speaker could have a lexical meaning of "Anne" as "only Anne", for example. Another way of thinking about this is that the speaker might use term answers "Anne" and "Bob" with an exhaustive meaning *in situ*. To implement this idea, we add lexica, a lexicon priori and an updated semantic meaning function:

~~~~
///fold:
var worlds = ["A","B","AB"]
///


var lexica = [{ "Anne" : "only Anne", "Bob" : "only Bob"}, 
              {"Anne" : "Anne or more", "Bob" : "Bob or more"}]

var lexicon_prior = function() {
  uniformDraw(lexica)
}

var utterance_meaning = function(utterance, belief_state, lexicon){
  var basic_meaning = {
    "Anne" : lexicon["Anne"] == "only Anne" ? ["A"] : ["A", "AB"],
    "Bob"  : lexicon["Bob"] == "only Bob" ? ["B"] : ["B", "AB"],
    "both" : ["AB"],
    "Anne or Bob"  : lexicon["Anne"] == "only Anne" &  
      lexicon["Bob"] == "only Bob" ? ["A", "B"] : worlds,
    "Anne or both" : ["A", "AB"],
    "Bob or both"  : ["B", "AB"],
    'Anne or Bob or both' : worlds
  }
  _.min(map(
    function(s) {
      _.includes(basic_meaning[utterance], s) + 1
    },
    belief_state)) > 1
}

display(utterance_meaning("Anne", ["AB"], lexica[0]))
display(utterance_meaning("Anne", ["AB"], lexica[1]))
~~~~

The full model is here, where we resolve uncertainty about the speaker's lexicon at the level of the pragmatic listener, as usual:

~~~~
///fold:
var powerset = function(set){
  if(set.length==0){
    return [set]
  }
  var r = powerset(set.slice(1)) // exlude first element
  var element = [set[0]] // first element
  var new_r = r.concat(map(function(x){ element.concat(x) }, r))
  return new_r
}

var worlds = ["A","B","AB"]

var belief_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

var speaker_knowledgeability_states = [0, 1, 2, 3]

var knowledgeability_level_prior = function() {
  uniformDraw(speaker_knowledgeability_states)
}

var belief_state_prior = function(speaker_knowledgeability_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_knowledgeability_level * s.length)
    },
    belief_states
  )
  return categorical({vs: belief_states, ps: weights})
}

var utterances = [
  'Anne',
  'Bob',
  'both', 
  'Anne or Bob',
  'Anne or both',
  'Bob or both',
  'Anne or Bob or both'
]

var cost_disjunction = 0.2
var cost_conjunction = 0.1

var utterance_cost = function(utterance){
  var utt_cost_table = {
    "Anne" : 0,
    'Bob' : 0,
    'both' : cost_conjunction, 
    'Anne or Bob' : cost_disjunction,
    'Anne or both' : cost_disjunction + cost_conjunction,
    'Bob or both' : cost_disjunction + cost_conjunction,
    'Anne or Bob or both' : 2* cost_disjunction + cost_conjunction
  }
  utt_cost_table[utterance]
}

var alpha = 5

var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(- alpha * utterance_cost(utterance))
    return utterance
  }})})

var lexica = [{ "Anne" : "only Anne", "Bob" : "only Bob"}, 
              {"Anne" : "Anne or more", "Bob" : "Bob or more"}]

var lexicon_prior = function() {
  uniformDraw(lexica)
}

var utterance_meaning = function(utterance, belief_state, lexicon){
  var basic_meaning = {
    "Anne" : lexicon["Anne"] == "only Anne" ? ["A"] : ["A", "AB"],
    "Bob"  : lexicon["Bob"] == "only Bob" ? ["B"] : ["B", "AB"],
    "both" : ["AB"],
    "Anne or Bob"  : lexicon["Anne"] == "only Anne" &  
      lexicon["Bob"] == "only Bob" ? ["A", "B"] : worlds,
    "Anne or both" : ["A", "AB"],
    "Bob or both"  : ["B", "AB"],
    'Anne or Bob or both' : worlds
  }
  _.min(map(
    function(s) {
      _.includes(basic_meaning[utterance], s) + 1
    },
    belief_state)) > 1
}

///

var literal_listener = cache(function(utterance, knowledgeability, lexicon) {
  Infer({model: function() {
    var belief_state = belief_state_prior(knowledgeability)
    var meaning = utterance_meaning(utterance, belief_state, lexicon)
    condition(meaning)
    return belief_state
  }})
})

var speaker = cache(function(belief_state, knowledgeability, lexicon){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance, knowledgeability, lexicon)
           factor(alpha*listener.score(belief_state))
           return utterance
         }})})

var listener = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledgeability = knowledgeability_level_prior(speaker_knowledgeability_states)
           var lexicon = lexicon_prior()
           var belief_state = belief_state_prior(knowledgeability)
           var speaker = speaker(belief_state,knowledgeability, lexicon)
           factor(speaker.score(utterance))
           return {belief_state}
         }})})

         
viz(listener("Anne"))
viz(listener("Anne or both"))
~~~~

## Speaker choice of lexical enrichment

The lexical uncertainty model of reft:bergenetal2016 assumes that the listener assumes that the speaker has a fixed lexical meaning for, say, "Anne". The speaker is considered to always (invariably) take "Anne" to mean "only Anne". An alternative approach is to think of the speaker as variably choosing a lexical interpretation of subsentential material. (Another way of thinking about this is that the speaker chooses which of several grammatically supplied local readings of a phrase she intends when producing an utterance; these local enrichments could come from a grammatical approach to quantity implicatures, for example, like proposed by reft:ChierchiaFox2012.) Here is the resulting model *local reading choice* model, side-by-side with the previous lexical uncertainty model:

~~~~
///fold:
var powerset = function(set){
  if(set.length==0){
    return [set]
  }
  var r = powerset(set.slice(1)) // exlude first element
  var element = [set[0]] // first element
  var new_r = r.concat(map(function(x){ element.concat(x) }, r))
  return new_r
}

var worlds = ["A","B","AB"]

var belief_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

var speaker_knowledgeability_states = [0, 1, 2, 3]

var knowledgeability_level_prior = function() {
  uniformDraw(speaker_knowledgeability_states)
}

var belief_state_prior = function(speaker_knowledgeability_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_knowledgeability_level * s.length)
    },
    belief_states
  )
  return categorical({vs: belief_states, ps: weights})
}

var utterances = [
  'Anne',
  'Bob',
  'both', 
  'Anne or Bob',
  'Anne or both',
  'Bob or both',
  'Anne or Bob or both'
]

var cost_disjunction = 0.2
var cost_conjunction = 0.1

var utterance_cost = function(utterance){
  var utt_cost_table = {
    "Anne" : 0,
    'Bob' : 0,
    'both' : cost_conjunction, 
    'Anne or Bob' : cost_disjunction,
    'Anne or both' : cost_disjunction + cost_conjunction,
    'Bob or both' : cost_disjunction + cost_conjunction,
    'Anne or Bob or both' : 2* cost_disjunction + cost_conjunction
  }
  utt_cost_table[utterance]
}

var alpha = 5

var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(- alpha * utterance_cost(utterance))
    return utterance
  }})})

var lexica = [{ "Anne" : "only Anne", "Bob" : "only Bob"}, 
              {"Anne" : "Anne or more", "Bob" : "Bob or more"}]

var lexicon_prior = function() {
  uniformDraw(lexica)
}

var utterance_meaning = function(utterance, lexicon){
  var basic_meaning = {
    "Anne" : lexicon["Anne"] == "only Anne" ? ["A"] : ["A", "AB"],
    "Bob"  : lexicon["Bob"] == "only Bob" ? ["B"] : ["B", "AB"],
    "both" : ["AB"],
    "Anne or Bob"  : lexicon["Anne"] == "only Anne" &  
      lexicon["Bob"] == "only Bob" ? ["A", "B"] : worlds,
    "Anne or both" : ["A", "AB"],
    "Bob or both"  : ["B", "AB"],
    'Anne or Bob or both' : worlds
  }
  basic_meaning[utterance]
}



var literal_listener = cache(function(utterance, lexicon) {
  Infer({model: function() {
    var world = uniformDraw(utterance_meaning(utterance, lexicon))
    return world
  }})
})

var utility = function(belief_state, utterance, lexicon){
  var scores = map(
    function(x) {
      literal_listener(utterance, lexicon).score(x)
    },
    belief_state
  )
  return (1/belief_state.length * sum(scores))
}

///

// lexical uncertainty (LU) model (as before)

var speaker_LU = cache(function(belief_state, knowledgeability, lexicon){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance, knowledgeability, lexicon)
           factor(alpha*utility(belief_state, utterance, lexicon))
           return utterance
         }})})

var listener_LU = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledgeability = knowledgeability_level_prior(speaker_knowledgeability_states)
           var lexicon = lexicon_prior()
           var belief_state = belief_state_prior(knowledgeability)
           var speaker = speaker_LU(belief_state,knowledgeability, lexicon)
           factor(speaker.score(utterance))
           return {belief_state, lexicon}
         }})})
         
// local enrichment choice (LEC) model (new stuff)       

var speaker_LEC = cache(function(belief_state, knowledgeability){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var lexicon = lexicon_prior()
           factor(alpha*utility(belief_state, utterance, lexicon))
           return {utterance, lexicon}
         }})})

var listener_LEC= cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledgeability = knowledgeability_level_prior(speaker_knowledgeability_states)
           var lexicon = lexicon_prior()
           var belief_state = belief_state_prior(knowledgeability)
           var speaker = speaker_LEC(belief_state,knowledgeability)
           factor(speaker.score({utterance, lexicon}))
           return {belief_state, lexicon}
         }})})



viz(listener_LU("Anne or both"))
viz(listener_LEC("Anne or both"))

// viz(listener_LU("Anne"))
// viz(listener_LEC("Anne"))
~~~~
