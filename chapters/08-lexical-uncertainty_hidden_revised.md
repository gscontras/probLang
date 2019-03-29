---
layout: chapter
title: Reasoning about semantic meaning
description: "Lexical uncertainty and intended lexical meanings"
hidden: true
---

### Chapter 8: Lexical uncertainty and intended lexical meanings

## Overview

Answers to the question "Who came to the party?", when it is contextually clear that the people we care about are Anne and Bob, can be pragmatically enriched in systematic ways (see, for instance, reft:GroenendijkStokhofThesis1984). The answer "Anne" suggests that only Anne came, not Bob. The answer "Anne or Bob" suggests that the speaker doesn't know who came and that the speaker doesn't know that both Anne and Bob came. We will look at a model of these inferences in the first part of this chapter.

But what if the speaker answers with "Anne or both"? That answer suggests that the speaker considers two things possible, namely (i) that Anne came alone and that (ii) both Anne and Bob came together; the speaker appears to rule out the possibility that only Bob came. This intuition seems straightforward, but is actually rather tricky to explain. The reason is that, under standard assumptions, the answer "Anne" and "Anne or both" are semantically equivalent --- they are true of all the worlds in which Anne (and possibly anyone else) came to the party. If two utterances are semantically equivalent, how can they be distinguished with pragmatic reasoning that builds only on top of this truth-functional meaning? The second part of this chapter will look at one possible solution to this problem, using reasoning about *lexical uncertainty* as discussed more systematically in reft:bergenetal2016, as well as a seemingly similar but subtly different approach in terms of the speaker's *lexical intention* (i.e., the intended lexical meaning of word).

## Pragmatic interpretation of term answers

Our starting point is the last model developed in [Chapter 2](02-pragmatics.html), where the pragmatic listener was reasoning about the true world state, the speaker's beliefs, and the speaker's general level of knowledgeability. While [Chapter 2](02-pragmatics.html) applied this model to reasoning about sentences like "Some of the apples are red", here we apply the same set-up to the interpretation of answers to WH-questions like "Who came to the Party?".

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

As in [Chapter 2](02-pragmatics.html), the pragmatic listener reasons about the speaker's belief state, which is unknown. The listener may nonetheless have certain prior beliefs about which belief states are more likely. The literature on exhaustive interpretations of question answers entertains the idea that interpretations depend on whether the listener believes the speaker to be knowledgeable (i.e., competent, or an epistemic authority). Following this idea, we will  assume that the listener's prior beliefs about the speaker's likely belief state is influenced by general assumptions about the speaker's knowledgeability on the matter at hand. Belief states here are just sets of possible worlds. A speaker is more knowledgeable if she can rule out more worlds. In the following, the `speaker_knowledgeability_level` is a numerical representation of how much more likely belief states are in which the speaker is more knowledgeable.

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

> **Exercise:** Explore the prior distributions over different speaker belief states for different levels of speaker knowledgeability. Is the speaker assumed to be more knowledgeable for speaker knowledgeability level 0 or 3?

Next, we need some utterances to use to describe the world. We include atomic utterances (e.g., "Anne", "Bob"), as well as complex utterances formed via disjunction ("or") and conjunction ("and").

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

var literal_listener = cache(function(utterance) {
  Infer({model: function() {
    var world = uniformDraw(utterance_meaning(utterance))
    return world
  }})
})

print("L0's belief after hearing that 'Anne' came to the party")
viz.hist(literal_listener("Anne"))
print("L0's belief after hearing that 'Anne or Bob' came to the party")
viz.hist(literal_listener("Anne or Bob"))
~~~~

> **Exercise:** Are the interpretations of the literal listener for "Anne" and "Anne or Bob" what we would normally understand from these answers?

The speaker's utility of uttering $$u$$ is proportional to the divergence between the speaker's own belief state (about possible worlds) and the literal listener's beliefs (about possible worlds) after hearing $$u$$. 

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

var utterance_meaning = function(utterance){
  var basic_meaning = {
    "Anne" : ["A", "AB"],
    "Bob" : ["B", "AB"],
    "Anne and Bob" : ["AB"],
    "Anne or Bob" : worlds
  }
  basic_meaning[utterance]
}

var literal_listener = cache(function(utterance) {
  Infer({model: function() {
    var world = uniformDraw(utterance_meaning(utterance))
    return world
  }})
})
///

var utility = function(belief_state, utterance){
  var scores = map(
    function(x) {
      literal_listener(utterance).score(x)
    },
    belief_state
  )
  return (1/belief_state.length * sum(scores))
}

var speaker = cache(function(belief_state){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           factor(alpha*utility(belief_state, utterance))
           return utterance
         }})})

viz(speaker(["A"]))
~~~~

> **Exercise:** Validate (by calling the `speaker` function for a number of appropriate belief states) that the speaker does not say anything that she lacks evidence for (i.e., that she does not believe to be true) and that she will prefer more informative utterances over less informative ones if she believes that both are true.

Finally, we add a pragmatic listener.

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

var utility = function(belief_state, utterance){
  var scores = map(
    function(x) {
      literal_listener(utterance).score(x)
    },
    belief_state
  )
  return (1/belief_state.length * sum(scores))
}

var speaker = cache(function(belief_state){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           factor(alpha*utility(belief_state, utterance))
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

> **Exercises:** 
> 1. Notice that the pragmatic listener performs a joined inference over the speaker's belief state and the speaker's general level of competence. For which utterances (if any) does the pragmatic listener consider the speaker to be generally more/less knowledgeable?
> 2. Check the pragmatic listener's interpretation of "Anne or Bob". Does it match your intuitions? See whether other parameter values would increase the extent to which we obtain an exclusive interpretation of the disjunction (i.e., either Anne or Bob, but not both).

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
  basic_meaning[utterance]
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
  basic_meaning[utterance]
}

var literal_listener = cache(function(utterance, lexicon) {
  Infer({model: function() {
    var world = uniformDraw(utterance_meaning(utterance, lexicon))
    return world
  }})
})

var utility = function(belief_state, utterance){
  var scores = map(
    function(x) {
      literal_listener(utterance).score(x)
    },
    belief_state
  )
  return (1/belief_state.length * sum(scores))
}

var speaker = cache(function(belief_state){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           factor(alpha*utility(belief_state, utterance))
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

One solution to this problem is to allow for reasoning about the speaker's lexical meaning of term answers "Anne" and "Bob". In effect, we assume that the speaker could have a lexical meaning of "Anne" as "only Anne". To implement this idea, we add lexica, a lexicon prior, and an updated semantic meaning function:

~~~~
///fold:
var worlds = ["A","B","AB"]
///


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

display(utterance_meaning("Anne", lexica[0]))
display(utterance_meaning("Anne", lexica[1]))
~~~~

In the full model, we resolve uncertainty about the speaker's lexicon at the level of the pragmatic listener:

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

var speaker = cache(function(belief_state, lexicon){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance, lexicon)
           factor(alpha*utility(belief_state, utterance, lexicon))
           return utterance
         }})})

var listener = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledgeability = knowledgeability_level_prior(speaker_knowledgeability_states)
           var lexicon = lexicon_prior()
           var belief_state = belief_state_prior(knowledgeability)
           var speaker = speaker(belief_state, lexicon)
           factor(speaker.score(utterance))
           return {belief_state, lexicon}
         }})})

viz(listener("Anne"))
viz(listener("Anne or both"))
~~~~

## Speaker choice of lexical enrichment

The lexical uncertainty model of reft:bergenetal2016 assumes that the listener takes the speaker to have a fixed lexical meaning for, say, "Anne" (e.g., the speaker is considered to invariably take "Anne" to mean "only Anne"). An alternative approach is to think of the speaker as variably choosing a lexical interpretation of subsentential material (i.e., single words like "Anne"). (Another way of thinking about this is that the speaker chooses which of several grammatically supplied local readings of a phrase she intends when producing an utterance; these local enrichments could come from a grammatical approach to quantity implicatures, for example, like that proposed by reft:ChierchiaFox2012.) Here is the resulting *local reading choice* model, side-by-side with the previous lexical uncertainty model. The main difference is that now the speaker *chooses* a lexicon in such a way that more informative lexical meanings are preferred over less informative ones. We may think of this move as an instantiation of the Maxim of Quantity applied to intended lexical meaning: "Use ambiguous sentential material with an intended (local) meaning that makes your utterances most informative!"

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

var speaker_LU = cache(function(belief_state, lexicon){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance, lexicon)
           factor(alpha*utility(belief_state, utterance, lexicon))
           return utterance
         }})})

var listener_LU = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledgeability = knowledgeability_level_prior(speaker_knowledgeability_states)
           var lexicon = lexicon_prior()
           var belief_state = belief_state_prior(knowledgeability)
           var speaker = speaker_LU(belief_state, lexicon)
           factor(speaker.score(utterance))
           return {belief_state, lexicon}
         }})})
         
// local enrichment choice (LEC) model (new stuff)       

var speaker_LEC = cache(function(belief_state){
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
           var speaker = speaker_LEC(belief_state)
           factor(speaker.score({utterance, lexicon}))
           return {belief_state, lexicon}
         }})})

viz(listener_LU("Anne or both"))
viz(listener_LEC("Anne or both"))

// viz(listener_LU("Anne"))
// viz(listener_LEC("Anne"))
~~~~
