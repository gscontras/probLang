---
layout: chapter
title: Modeling semantic inference
description: "Lexical uncertainty"
hidden: true
---

### Chapter 8: Lexical uncertainty (Hidden version)

## Overview

Answers to the question "Who of Anne and Bob were at the party?" can be pragmatically enriched in systemic ways. The answer "Anne" suggests that only Anne came, but not Bob. The answer "Anne or Bob" came suggests that the speaker doesn't know who came and that the speaker doesn't know that both Anne and Bob came. We will look at a model of these inferences in the first part of this chapter.

But what if the speaker says "Anne or both"? That answer suggests that the speaker considers two things possible, namely (i) that Anne came alone and that (ii) both Anne and Bob came; the speaker appears to know that the possibility that only Bob came is ruled out. This seems straightforward enough but is actually rather tricky to explain. The reason is that, under standard assumptions, the answer "Anne" and "Anne or both" are semantically equivalent. And if two utterances are semantically equivalent, how can they be distinguished with pragmatic reasoning that builds only on top of this semantic meaning. The second part of this chapter will look at one possible solution to this problem, using reasoning about *lexical uncertainty* as discussed more systematically in reft:bergenetal2016.

## Pragmatic interpretation of term answers

We distinguish three types of possible worlds, each of which determines who of Anne and Bob came to the party. A speaker's knowledge state is a non-empty set of possible worlds. Knowledge states correspond contain all and only worlds compatible with the speaker's knowledge.

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

var knowledge_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

print(knowledge_states)
~~~~

> **Exercise:** Describe in your own words what a speaker in knowledge state "[A, B]" considers possible and what she rules out.

The listener might not know the speaker's knowledge state, but may have some prior beliefs about which one is most likely. Knowledge states differ by the amount of information the speaker has. The listener's prior beliefs might therefore depend on how knowledgeable, or how much of an expert on the matter at hand, the speaker is believed to be. Here's one way of modeling this.

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

var knowledge_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)
///

var speaker_expertise_states = [0, 1, 2, 3]

var expertise_prior = function() {
  uniformDraw(speaker_expertise_states)
}

var knowledge_state_prior = function(speaker_competence_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_competence_level * s.length)
    },
    knowledge_states
  )
  return categorical({vs: knowledge_states, ps: weights})
}

viz.hist(Infer({model: function(x) {knowledge_state_prior(3)}}))
~~~~

> **Exercise:** Explore the prior distributions over different speaker knowledge states for different levels of speaker competence. Is the speaker assumed to be more knowledgeable for speaker competence level 0 or for 3?

Next, we need some utterances to use to describe the world. We include atomic utterances (e.g., "Anne", "Bob"), as well as complex utterances formed via disjunction (e.g., "some or all").

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

Next, we need a way of interpreting our utterances. We start by defining a basic semantics for our atomic utterances, then extend this to say which knowledge states support which utterance. 

~~~~
var worlds = ["A","B","AB"]

var utterance_meaning = function(utterance,knowledge_state){
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
    knowledge_state)) > 1
}

display(utterance_meaning("Anne and Bob", ["A", "AB"]))
~~~~

> **Exercise:** Explore these semantics for different utterances and knowledge states.

The literal listener takes the speaker competence level as input.

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

var knowledge_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

var speaker_expertise_states = [0, 1, 2, 3]

var expertise_prior = function() {
  uniformDraw(speaker_expertise_states)
}

var knowledge_state_prior = function(speaker_competence_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_competence_level * s.length)
    },
    knowledge_states
  )
  return categorical({vs: knowledge_states, ps: weights})
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

var utterance_meaning = function(utterance,knowledge_state){
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
    knowledge_state)) > 1
}

///

var literal_listener = cache(function(utterance, speaker_competence_level) {
  Infer({model: function() {
    var knowledge_state = knowledge_state_prior(speaker_competence_level)
    var meaning = utterance_meaning(utterance, knowledge_state)
    condition(meaning)
    return knowledge_state 
  }})
})

viz.hist(literal_listener("Anne or Bob", 3))
~~~~

> **Exercise:** Are the interpretations of the literal listener for "Anne" and "Anne or Bob" what we would normally understand from these answers? How does the speaker competence level affect the literal listener's interpretation?

The speaker tends to send utterances that are informative about her knowledge state and that minimize utterance costs.

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

var knowledge_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

var speaker_expertise_states = [0, 1, 2, 3]

var expertise_prior = function() {
  uniformDraw(speaker_expertise_states)
}

var knowledge_state_prior = function(speaker_competence_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_competence_level * s.length)
    },
    knowledge_states
  )
  return categorical({vs: knowledge_states, ps: weights})
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

var utterance_meaning = function(utterance,knowledge_state){
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
    knowledge_state)) > 1
}

var literal_listener = cache(function(utterance, speaker_competence_level) {
  Infer({model: function() {
    var knowledge_state = knowledge_state_prior(speaker_competence_level)
    var meaning = utterance_meaning(utterance, knowledge_state)
    condition(meaning)
    return knowledge_state 
  }})
})

///

var speaker = cache(function(knowledge_state, expertise){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance, expertise)
           factor(alpha*listener.score(knowledge_state))
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

var knowledge_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

var speaker_expertise_states = [0, 1, 2, 3]

var expertise_prior = function() {
  uniformDraw(speaker_expertise_states)
}

var knowledge_state_prior = function(speaker_competence_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_competence_level * s.length)
    },
    knowledge_states
  )
  return categorical({vs: knowledge_states, ps: weights})
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

var utterance_meaning = function(utterance,knowledge_state){
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
    knowledge_state)) > 1
}

var literal_listener = cache(function(utterance, speaker_competence_level) {
  Infer({model: function() {
    var knowledge_state = knowledge_state_prior(speaker_competence_level)
    var meaning = utterance_meaning(utterance, knowledge_state)
    condition(meaning)
    return knowledge_state 
  }})
})

var speaker = cache(function(knowledge_state, expertise){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance, expertise)
           factor(alpha*listener.score(knowledge_state))
           return utterance
         }})})
///


var listener = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var expertise = expertise_prior(speaker_expertise_states)
           var knowledge_state = knowledge_state_prior(expertise)
           var speaker = speaker(knowledge_state,expertise)
           factor(speaker.score(utterance))
           return {knowledge_state, expertise}
         }})})
         
viz(listener("Anne"))
// viz.hist(marginalize(listener("Anne or Bob"),"knowledge_state"))
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

var utterance_meaning = function(utterance,knowledge_state){
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
    knowledge_state)) > 1
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

var knowledge_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

var speaker_expertise_states = [0, 1, 2, 3]

var expertise_prior = function() {
  uniformDraw(speaker_expertise_states)
}

var knowledge_state_prior = function(speaker_competence_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_competence_level * s.length)
    },
    knowledge_states
  )
  return categorical({vs: knowledge_states, ps: weights})
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

var utterance_meaning = function(utterance,knowledge_state){
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
    knowledge_state)) > 1
}

var literal_listener = cache(function(utterance, speaker_competence_level) {
  Infer({model: function() {
    var knowledge_state = knowledge_state_prior(speaker_competence_level)
    var meaning = utterance_meaning(utterance, knowledge_state)
    condition(meaning)
    return knowledge_state 
  }})
})

var speaker = cache(function(knowledge_state, expertise){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance, expertise)
           factor(alpha*listener.score(knowledge_state))
           return utterance
         }})})
///


var listener = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var expertise = expertise_prior(speaker_expertise_states)
           var knowledge_state = knowledge_state_prior(expertise)
           var speaker = speaker(knowledge_state,expertise)
           factor(speaker.score(utterance))
           return {knowledge_state, expertise}
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

var utterance_meaning = function(utterance, knowledge_state, lexicon){
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
    knowledge_state)) > 1
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

var knowledge_states = filter(
  function(x){return x.length>0},
  powerset(worlds)
)

var speaker_expertise_states = [0, 1, 2, 3]

var expertise_prior = function() {
  uniformDraw(speaker_expertise_states)
}

var knowledge_state_prior = function(speaker_competence_level){
  var weights = map(
    function(s) {
      Math.exp(- speaker_competence_level * s.length)
    },
    knowledge_states
  )
  return categorical({vs: knowledge_states, ps: weights})
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

var utterance_meaning = function(utterance, knowledge_state, lexicon){
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
    knowledge_state)) > 1
}

///

var literal_listener = cache(function(utterance, expertise, lexicon) {
  Infer({model: function() {
    var knowledge_state = knowledge_state_prior(expertise)
    var meaning = utterance_meaning(utterance, knowledge_state, lexicon)
    condition(meaning)
    return knowledge_state
  }})
})

var speaker = cache(function(knowledge_state, expertise, lexicon){
  Infer({method:'enumerate',
         model: function(){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance, expertise, lexicon)
           factor(alpha*listener.score(knowledge_state))
           return utterance
         }})})



var listener = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var expertise = expertise_prior(speaker_expertise_states)
           var lexicon = lexicon_prior()
           var knowledge_state = knowledge_state_prior(expertise)
           var speaker = speaker(knowledge_state,expertise, lexicon)
           factor(speaker.score(utterance))
           return {knowledge_state}
         }})})

         
viz(listener("Anne"))
viz(listener("Anne or both"))
~~~~
