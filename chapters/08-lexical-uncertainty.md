---
layout: chapter
title: Modeling semantic inference
description: "Lexical uncertainty"
---

### Chapter 8: Lexical uncertainty

## Embedded inferences

How can we capture what looks like an embedded implicature in "some or all of the apples are red"? The lexical uncertainty model of reft:bergenetal2016 derives this inference by assuming uncertainty at the level of atomic utterances (i.e., at the level of "some" and "all").


First we need possible worlds (i.e., the number of red apples), together with knowledge states. These knowledge states correspond to the worlds compatible with whatever observations have been made.

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

// possible worlds (i.e., number of red apples)
var worlds = [1,2,3]
var world_prior = function(){
  return uniformDraw(worlds)
}

// possible knowledge states (i.e., worlds compatible with observations);
// returns all the non-empty subsets of the set of worlds
var knowledge_states = filter(function(x){return x.length>0},powerset(worlds))
var knowledge_state_prior = function(){
  return uniformDraw(knowledge_states)
}
~~~~

> **Exercise:** Visualize the `world` and `knowledge_state` priors.

Next, we need some utterances to use to describe the world. We include atomic utterances (e.g., "some", "all"), as well as complex utterances formed via disjunction (e.g., "some or all").

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

// possible atomic utterances
var base_utterances = ['some','most','all']

// generate all possible utterances,
// including a null utterance, atomic utterances, 
// and all pairs (i.e., disjunctions) of atomic utterances
var utterances = ['null'].concat(
  filter(function(x){return x.length>0 && (x.length<3)}, 
         powerset(base_utterances)))


// determine utterance cost on the basis of utterance length
var utterance_cost = function(utterance){
  if(utterance=='null'){
    return 100
  }
  var base_utterance_cost =  utterance.length
  var cost = 0.1*base_utterance_cost
  return cost
}

var alpha = 5

// generate utterance prior on the basis of utterance costs
var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(-1 * alpha * utterance_cost(utterance))
    return utterance
  }})})
~~~~

> **Exercise:** Visualize the `utterance_prior`.

Next, we need a way of interpreting our utterances. We start by defining a basic semantics for our atomic utterances, then considering all possible refinements (i.e., logical strengthenings) of the base semantics.

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

// possible worlds (i.e., number of red apples)
var worlds = [1,2,3]
var world_prior = function(){
  return uniformDraw(worlds)
}

// possible atomic utterances
var base_utterances = ['some','most','all']

// generate all possible pairs utterances,
// including a null utterance, atomic utterances, 
// and all pairs (i.e., disjunctions) of atomic utterances
var utterances = ['null'].concat(
  filter(function(x){return x.length>0 && (x.length<3)}, 
         powerset(base_utterances)))

var array_dict_lookup = function(a,k){
  if(a[0][0]==k){
    return a[0][1]
  }
  else{
    return array_dict_lookup(a.slice(1),k)
  }
}
///

var base_utterance_semantics = function(utterance,world){
  if(utterance=='all'){
    return world == 3
  }
  else if (utterance=='some'){
    return world > 0
  }
  else if (utterance=='most'){
    return world > 1
  }
  else{
    return true
  }
}

// determine worlds compatible with base utterance semantics
var get_base_utterance_worlds = function(utterance){
  var condition_on_base_utterance = function(utterance){
    Infer({method:'enumerate',model(){
      var world = world_prior()
      var meaning = base_utterance_semantics(utterance,world)
      condition(meaning)
      return world
    }})}
  var world_sampler = condition_on_base_utterance(utterance)
  return world_sampler.support()
}

// determine worlds compatible with all possible refinements
// of the utterance semantics, where refinements
// are logical strengthenings
var get_possible_refinements = function(utterances){
  var possible_refinements = map(function(x){return filter(function(y){return y.length>0},
                                                           powerset(get_base_utterance_worlds(x)))},
                                 utterances)
  return zip(utterances,possible_refinements)
}
~~~~

>**Exercise:** What are the possible refinements of the `base_utterances`?

Our meaning function evaluates the truth of an utterance with respect to a specific `refinement` of its semantics; which refinement is considered will get determined by the pragmatic listener.

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

var member_of = function(x,s){
  var r = function(s_element,acc){
    return check_equality(x,s_element) || acc
  }
  return reduce(r,false,s)
}

var check_equality = function(a,b){
  return JSON.stringify(a) == JSON.stringify(b)
}

var array_dict_lookup = function(a,k){
  if(a[0][0]==k){
    return a[0][1]
  }
  else{
    return array_dict_lookup(a.slice(1),k)
  }
}

// possible worlds (i.e., number of red apples)
var worlds = [1,2,3]
var world_prior = function(){
  return uniformDraw(worlds)
}

// possible atomic utterances
var base_utterances = ['some','most','all']

// generate all possible pairs utterances,
// including a null utterance, atomic utterances, 
// and all pairs (i.e., disjunctions) of atomic utterances
var utterances = ['null'].concat(
  filter(function(x){return x.length>0 && (x.length<3)}, 
         powerset(base_utterances)))


// determine utterance cost on the basis of utterance length
var utterance_cost = function(utterance){
  if(utterance=='null'){
    return 100
  }
  var base_utterance_cost =  utterance.length
  var cost = 0.1*base_utterance_cost
  return cost
}

var alpha = 5

// generate utterance prior on the basis of utterance costs
var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(-1 * alpha * utterance_cost(utterance))
    return utterance
  }})})

var base_utterance_semantics = function(utterance,world){
  if(utterance=='all'){
    return world == 3
  }
  else if (utterance=='some'){
    return world > 0
  }
  else if (utterance=='most'){
    return world > 1
  }
  else{
    return true
  }
}

// determine worlds compatible with base utterance semantics
var get_base_utterance_worlds = function(utterance){
  var condition_on_base_utterance = function(utterance){
    Infer({method:'enumerate',model(){
      var world = world_prior()
      var meaning = base_utterance_semantics(utterance,world)
      condition(meaning)
      return world
    }})}
  var world_sampler = condition_on_base_utterance(utterance)
  return world_sampler.support()
}

// determine worlds compatible with all possible refinements
// of the utterance semantics, where refinements
// are logical strengthenings
var get_possible_refinements = function(utterances){
  var possible_refinements = map(function(x){return filter(function(y){return y.length>0},
                                                           powerset(get_base_utterance_worlds(x)))},
                                 utterances)
  return zip(utterances,possible_refinements)
}

///

// get refinements of atomic utterances
var base_utterance_refinements = get_possible_refinements(base_utterances)

// choose an utterance refinement at random
var sample_utterance_refinement = function(base_utterance){
  var refinements = array_dict_lookup(base_utterance_refinements, base_utterance)
  return uniformDraw(refinements)
}

// for each base utterance, 
// choose an utterance refinement at random
var sample_refinements = function(){
  var refinements = map(sample_utterance_refinement,base_utterances)
  return zip(base_utterances,refinements)
}

// semantics of disjunction
var eval_connective_truth = function(truth_vals){
  return any(function(t){t}, truth_vals) // check whether 'or' is true
}

// utterance meaning function
var utterance_meaning = function(utterance,refinements,world){
  if(utterance=='null'){
    return true
  }
  var current_base_utterances = utterance

  //  retrieve refinements of atomic utterances
  var base_utterance_refinements = map(
    function(x){return array_dict_lookup(refinements,x)},
    current_base_utterances
  )
  
  // calculate truth values for atomic utterances 
  // relative to possible refinements
  var base_utterance_truth_vals = map(
    function(x){return member_of(world,x)},
    base_utterance_refinements
  )

  return eval_connective_truth(base_utterance_truth_vals)
}

var utterance = sample(utterance_prior())
display(utterance)
var refinements = sample_refinements()
display(refinements)
utterance_meaning(utterance,refinements,3)
~~~~

Now we can define the base of RSA reasoning: the literal listener $$L_0$$. $$L_0$$ takes in an `utterance` and the relevant meaning `refinements` and returns a joint distribution of knowledge states and worlds compatible with the refined semantics.

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

var member_of = function(x,s){
  var r = function(s_element,acc){
    return check_equality(x,s_element) || acc
  }
  return reduce(r,false,s)
}

var check_equality = function(a,b){
  return JSON.stringify(a) == JSON.stringify(b)
}

var array_dict_lookup = function(a,k){
  if(a[0][0]==k){
    return a[0][1]
  }
  else{
    return array_dict_lookup(a.slice(1),k)
  }
}

// possible worlds (i.e., number of red apples)
var worlds = [1,2,3]
var world_prior = function(){
  return uniformDraw(worlds)
}

// possible knowledge states (i.e., worlds compatible with observations);
// returns all the non-empty subsets of the set of worlds
var knowledge_states = filter(function(x){return x.length>0},powerset(worlds))
var knowledge_state_prior = function(){
  return uniformDraw(knowledge_states)
}

var sample_world_from_knowledge_state = function(knowledge_state){
  return uniformDraw(knowledge_state)
}

// possible atomic utterances
var base_utterances = ['some','most','all']

// generate all possible pairs utterances,
// including a null utterance, atomic utterances, 
// and all pairs (i.e., disjunctions) of atomic utterances
var utterances = ['null'].concat(
  filter(function(x){return x.length>0 && (x.length<3)}, 
         powerset(base_utterances)))


// determine utterance cost on the basis of utterance length
var utterance_cost = function(utterance){
  if(utterance=='null'){
    return 100
  }
  var base_utterance_cost =  utterance.length
  var cost = 0.1*base_utterance_cost
  return cost
}

var alpha = 5

// generate utterance prior on the basis of utterance costs
var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(-1 * alpha * utterance_cost(utterance))
    return utterance
  }})})

var base_utterance_semantics = function(utterance,world){
  if(utterance=='all'){
    return world == 3
  }
  else if (utterance=='some'){
    return world > 0
  }
  else if (utterance=='most'){
    return world > 1
  }
  else{
    return true
  }
}

// determine worlds compatible with base utterance semantics
var get_base_utterance_worlds = function(utterance){
  var condition_on_base_utterance = function(utterance){
    Infer({method:'enumerate',model(){
      var world = world_prior()
      var meaning = base_utterance_semantics(utterance,world)
      condition(meaning)
      return world
    }})}
  var world_sampler = condition_on_base_utterance(utterance)
  return world_sampler.support()
}

// determine worlds compatible with all possible refinements
// of the utterance semantics, where refinements
// are logical strengthenings
var get_possible_refinements = function(utterances){
  var possible_refinements = map(function(x){return filter(function(y){return y.length>0},
                                                           powerset(get_base_utterance_worlds(x)))},
                                 utterances)
  return zip(utterances,possible_refinements)
}

// get refinements of atomic utterances
var base_utterance_refinements = get_possible_refinements(base_utterances)

// choose an utterance refinement at random
var sample_utterance_refinement = function(base_utterance){
  var refinements = array_dict_lookup(base_utterance_refinements, base_utterance)
  return uniformDraw(refinements)
}

// for each base utterance, 
// choose an utterance refinement at random
var sample_refinements = function(){
  var refinements = map(sample_utterance_refinement,base_utterances)
  return zip(base_utterances,refinements)
}

// semantics of disjunction
var eval_connective_truth = function(truth_vals){
  return any(function(t){t}, truth_vals) // check whether 'or' is true
}

// utterance meaning function
var utterance_meaning = function(utterance,refinements,world){
  if(utterance=='null'){
    return true
  }
  var current_base_utterances = utterance

  //  retrieve refinements of atomic utterances
  var base_utterance_refinements = map(
    function(x){return array_dict_lookup(refinements,x)},
    current_base_utterances
  )
  
  // calculate truth values for atomic utterances 
  // relative to possible refinements
  var base_utterance_truth_vals = map(
    function(x){return member_of(world,x)},
    base_utterance_refinements
  )

  return eval_connective_truth(base_utterance_truth_vals)
}

///

var literal_listener = cache(function(utterance,refinements) {
  Infer({model: function() {
           var knowledge_state = knowledge_state_prior()
           var world = sample_world_from_knowledge_state(knowledge_state)
           var meaning = utterance_meaning(utterance,refinements,world)
           condition(meaning)
           return [knowledge_state,world]
         }})
})
~~~~

> **Exercise:** Generate predictions from the literal listener by first sampling an `utterance` and some `refinements`, then feeding these variables into the `literal_listener` function.

To continue the RSA recursion, we'll need a speaker who reasons about the literal listener. This reasoning depends crucially on the `speaker_utility` function, which evaluates the probability that the `listener` will arrive at the correct `knowledge_state`.

~~~~
// speaker utility function
var speaker_utility = function(knowledge_state,listener){
  var scores = map(
    function(x){return listener.score([knowledge_state,x])},
    knowledge_state)
  return (1/knowledge_state.length)*sum(scores)
}
~~~~

With `speaker_utility` defined, now we can implement the $$S_1$$ speaker, who observes some `knowledge_state` and chooses an utterance to communicate that `knowledge_state` to the `literal_listener`; this choice happens with respect to a specific set of meaning `refinements`, which is a lifted variable that will get resolved by the pragmatic listener.

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

var member_of = function(x,s){
  var r = function(s_element,acc){
    return check_equality(x,s_element) || acc
  }
  return reduce(r,false,s)
}

var check_equality = function(a,b){
  return JSON.stringify(a) == JSON.stringify(b)
}

var array_dict_lookup = function(a,k){
  if(a[0][0]==k){
    return a[0][1]
  }
  else{
    return array_dict_lookup(a.slice(1),k)
  }
}

// possible worlds (i.e., number of red apples)
var worlds = [1,2,3]
var world_prior = function(){
  return uniformDraw(worlds)
}

// possible knowledge states (i.e., worlds compatible with observations);
// returns all the non-empty subsets of the set of worlds
var knowledge_states = filter(function(x){return x.length>0},powerset(worlds))
var knowledge_state_prior = function(){
  return uniformDraw(knowledge_states)
}

var sample_world_from_knowledge_state = function(knowledge_state){
  return uniformDraw(knowledge_state)
}

// possible atomic utterances
var base_utterances = ['some','most','all']

// generate all possible pairs utterances,
// including a null utterance, atomic utterances, 
// and all pairs (i.e., disjunctions) of atomic utterances
var utterances = ['null'].concat(
  filter(function(x){return x.length>0 && (x.length<3)}, 
         powerset(base_utterances)))


// determine utterance cost on the basis of utterance length
var utterance_cost = function(utterance){
  if(utterance=='null'){
    return 100
  }
  var base_utterance_cost =  utterance.length
  var cost = 0.1*base_utterance_cost
  return cost
}

var alpha = 5

// generate utterance prior on the basis of utterance costs
var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(-1 * alpha * utterance_cost(utterance))
    return utterance
  }})})

var base_utterance_semantics = function(utterance,world){
  if(utterance=='all'){
    return world == 3
  }
  else if (utterance=='some'){
    return world > 0
  }
  else if (utterance=='most'){
    return world > 1
  }
  else{
    return true
  }
}

// determine worlds compatible with base utterance semantics
var get_base_utterance_worlds = function(utterance){
  var condition_on_base_utterance = function(utterance){
    Infer({method:'enumerate',model(){
      var world = world_prior()
      var meaning = base_utterance_semantics(utterance,world)
      condition(meaning)
      return world
    }})}
  var world_sampler = condition_on_base_utterance(utterance)
  return world_sampler.support()
}

// determine worlds compatible with all possible refinements
// of the utterance semantics, where refinements
// are logical strengthenings
var get_possible_refinements = function(utterances){
  var possible_refinements = map(function(x){return filter(function(y){return y.length>0},
                                                           powerset(get_base_utterance_worlds(x)))},
                                 utterances)
  return zip(utterances,possible_refinements)
}

// get refinements of atomic utterances
var base_utterance_refinements = get_possible_refinements(base_utterances)

// choose an utterance refinement at random
var sample_utterance_refinement = function(base_utterance){
  var refinements = array_dict_lookup(base_utterance_refinements, base_utterance)
  return uniformDraw(refinements)
}

// for each base utterance, 
// choose an utterance refinement at random
var sample_refinements = function(){
  var refinements = map(sample_utterance_refinement,base_utterances)
  return zip(base_utterances,refinements)
}

// semantics of disjunction
var eval_connective_truth = function(truth_vals){
  return any(function(t){t}, truth_vals) // check whether 'or' is true
}

// utterance meaning function
var utterance_meaning = function(utterance,refinements,world){
  if(utterance=='null'){
    return true
  }
  var current_base_utterances = utterance

  //  retrieve refinements of atomic utterances
  var base_utterance_refinements = map(
    function(x){return array_dict_lookup(refinements,x)},
    current_base_utterances
  )

  // calculate truth values for atomic utterances 
  // relative to possible refinements
  var base_utterance_truth_vals = map(
    function(x){return member_of(world,x)},
    base_utterance_refinements
  )

  return eval_connective_truth(base_utterance_truth_vals)
}

///

var literal_listener = cache(function(utterance,refinements) {
  Infer({model: function() {
    var knowledge_state = knowledge_state_prior()
    var world = sample_world_from_knowledge_state(knowledge_state)
    var meaning = utterance_meaning(utterance,refinements,world)
    condition(meaning)
    return [knowledge_state,world]
  }})
})

// speaker utility function
var speaker_utility = function(knowledge_state,listener){
  var scores = map(
    function(x){return listener.score([knowledge_state,x])},
    knowledge_state)
  return (1/knowledge_state.length)*sum(scores)
}

// level 1 speaker
var speaker1 = cache(function(knowledge_state,refinements){
  Infer({method:'enumerate',
         model (){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance,refinements)
           factor(alpha*speaker_utility(knowledge_state,listener))
           return utterance
         }})})
~~~~

> **Exercise:** Sample a `knowledge_state` and some `refinements` and use them to generate predictions from `speaker1`.

The pragmatic listener, $$L_1$$, interprets an `utterance` to resolve the state of the `world` by reasoning about how `speaker1` would have generated that utterance.

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

var member_of = function(x,s){
  var r = function(s_element,acc){
    return check_equality(x,s_element) || acc
  }
  return reduce(r,false,s)
}

var check_equality = function(a,b){
  return JSON.stringify(a) == JSON.stringify(b)
}

var array_dict_lookup = function(a,k){
  if(a[0][0]==k){
    return a[0][1]
  }
  else{
    return array_dict_lookup(a.slice(1),k)
  }
}

// possible worlds (i.e., number of red apples)
var worlds = [1,2,3]
var world_prior = function(){
  return uniformDraw(worlds)
}

// possible knowledge states (i.e., worlds compatible with observations);
// returns all the non-empty subsets of the set of worlds
var knowledge_states = filter(function(x){return x.length>0},powerset(worlds))
var knowledge_state_prior = function(){
  return uniformDraw(knowledge_states)
}

var sample_world_from_knowledge_state = function(knowledge_state){
  return uniformDraw(knowledge_state)
}

// possible atomic utterances
var base_utterances = ['some','most','all']

// generate all possible pairs utterances,
// including a null utterance, atomic utterances, 
// and all pairs (i.e., disjunctions) of atomic utterances
var utterances = ['null'].concat(
  filter(function(x){return x.length>0 && (x.length<3)}, 
         powerset(base_utterances)))


// determine utterance cost on the basis of utterance length
var utterance_cost = function(utterance){
  if(utterance=='null'){
    return 100
  }
  var base_utterance_cost =  utterance.length
  var cost = 0.1*base_utterance_cost
  return cost
}

var alpha = 5

// generate utterance prior on the basis of utterance costs
var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(-1 * alpha * utterance_cost(utterance))
    return utterance
  }})})

var base_utterance_semantics = function(utterance,world){
  if(utterance=='all'){
    return world == 3
  }
  else if (utterance=='some'){
    return world > 0
  }
  else if (utterance=='most'){
    return world > 1
  }
  else{
    return true
  }
}

// determine worlds compatible with base utterance semantics
var get_base_utterance_worlds = function(utterance){
  var condition_on_base_utterance = function(utterance){
    Infer({method:'enumerate',model(){
      var world = world_prior()
      var meaning = base_utterance_semantics(utterance,world)
      condition(meaning)
      return world
    }})}
  var world_sampler = condition_on_base_utterance(utterance)
  return world_sampler.support()
}

// determine worlds compatible with all possible refinements
// of the utterance semantics, where refinements
// are logical strengthenings
var get_possible_refinements = function(utterances){
  var possible_refinements = map(function(x){return filter(function(y){return y.length>0},
                                                           powerset(get_base_utterance_worlds(x)))},
                                 utterances)
  return zip(utterances,possible_refinements)
}

// get refinements of atomic utterances
var base_utterance_refinements = get_possible_refinements(base_utterances)

// choose an utterance refinement at random
var sample_utterance_refinement = function(base_utterance){
  var refinements = array_dict_lookup(base_utterance_refinements, base_utterance)
  return uniformDraw(refinements)
}

// for each base utterance, 
// choose an utterance refinement at random
var sample_refinements = function(){
  var refinements = map(sample_utterance_refinement,base_utterances)
  return zip(base_utterances,refinements)
}

// semantics of disjunction
var eval_connective_truth = function(truth_vals){
  return any(function(t){t}, truth_vals) // check whether 'or' is true
}

// utterance meaning function
var utterance_meaning = function(utterance,refinements,world){
  if(utterance=='null'){
    return true
  }
  var current_base_utterances = utterance

  //  retrieve refinements of atomic utterances
  var base_utterance_refinements = map(
    function(x){return array_dict_lookup(refinements,x)},
    current_base_utterances
  )

  // calculate truth values for atomic utterances 
  // relative to possible refinements
  var base_utterance_truth_vals = map(
    function(x){return member_of(world,x)},
    base_utterance_refinements
  )

  return eval_connective_truth(base_utterance_truth_vals)
}

///

var literal_listener = cache(function(utterance,refinements) {
  Infer({model: function() {
    var knowledge_state = knowledge_state_prior()
    var world = sample_world_from_knowledge_state(knowledge_state)
    var meaning = utterance_meaning(utterance,refinements,world)
    condition(meaning)
    return [knowledge_state,world]
  }})
})

// speaker utility function
var speaker_utility = function(knowledge_state,listener){
  var scores = map(
    function(x){return listener.score([knowledge_state,x])},
    knowledge_state)
  return (1/knowledge_state.length)*sum(scores)
}

// level 1 speaker
var speaker1 = cache(function(knowledge_state,refinements){
  Infer({method:'enumerate',
         model (){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance,refinements)
           factor(alpha*speaker_utility(knowledge_state,listener))
           return utterance
         }})})

// level 1 pragmatic listener
var listener1 = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledge_state = knowledge_state_prior()
           var world = sample_world_from_knowledge_state(knowledge_state)
           var refinements = sample_refinements()
           var speaker = speaker1(knowledge_state,refinements)
           factor(speaker.score(utterance))
           return world
         }})})

listener1(['some'])
~~~~

> **Exercise:** Try `listener1` on the other utterances, including "some or all".

To get the full effect of the embedded inference, we'll need to increase the depth of reasoning by increasing the levels of recursion.

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

var member_of = function(x,s){
  var r = function(s_element,acc){
    return check_equality(x,s_element) || acc
  }
  return reduce(r,false,s)
}

var check_equality = function(a,b){
  return JSON.stringify(a) == JSON.stringify(b)
}

var array_dict_lookup = function(a,k){
  if(a[0][0]==k){
    return a[0][1]
  }
  else{
    return array_dict_lookup(a.slice(1),k)
  }
}

// possible worlds (i.e., number of red apples)
var worlds = [1,2,3]
var world_prior = function(){
  return uniformDraw(worlds)
}

// possible knowledge states (i.e., worlds compatible with observations);
// returns all the non-empty subsets of the set of worlds
var knowledge_states = filter(function(x){return x.length>0},powerset(worlds))
var knowledge_state_prior = function(){
  return uniformDraw(knowledge_states)
}

var sample_world_from_knowledge_state = function(knowledge_state){
  return uniformDraw(knowledge_state)
}

// possible atomic utterances
var base_utterances = ['some','most','all']

// generate all possible pairs utterances,
// including a null utterance, atomic utterances, 
// and all pairs (i.e., disjunctions) of atomic utterances
var utterances = ['null'].concat(
  filter(function(x){return x.length>0 && (x.length<3)}, 
         powerset(base_utterances)))


// determine utterance cost on the basis of utterance length
var utterance_cost = function(utterance){
  if(utterance=='null'){
    return 100
  }
  var base_utterance_cost =  utterance.length
  var cost = 0.1*base_utterance_cost
  return cost
}

var alpha = 5

// generate utterance prior on the basis of utterance costs
var utterance_prior = cache(function(){
  Infer({method:'enumerate',model(){
    var utterance = uniformDraw(utterances)
    factor(-1 * alpha * utterance_cost(utterance))
    return utterance
  }})})

var base_utterance_semantics = function(utterance,world){
  if(utterance=='all'){
    return world == 3
  }
  else if (utterance=='some'){
    return world > 0
  }
  else if (utterance=='most'){
    return world > 1
  }
  else{
    return true
  }
}

// determine worlds compatible with base utterance semantics
var get_base_utterance_worlds = function(utterance){
  var condition_on_base_utterance = function(utterance){
    Infer({method:'enumerate',model(){
      var world = world_prior()
      var meaning = base_utterance_semantics(utterance,world)
      condition(meaning)
      return world
    }})}
  var world_sampler = condition_on_base_utterance(utterance)
  return world_sampler.support()
}

// determine worlds compatible with all possible refinements
// of the utterance semantics, where refinements
// are logical strengthenings
var get_possible_refinements = function(utterances){
  var possible_refinements = map(function(x){return filter(function(y){return y.length>0},
                                                           powerset(get_base_utterance_worlds(x)))},
                                 utterances)
  return zip(utterances,possible_refinements)
}

// get refinements of atomic utterances
var base_utterance_refinements = get_possible_refinements(base_utterances)

// choose an utterance refinement at random
var sample_utterance_refinement = function(base_utterance){
  var refinements = array_dict_lookup(base_utterance_refinements, base_utterance)
  return uniformDraw(refinements)
}

// for each base utterance, 
// choose an utterance refinement at random
var sample_refinements = function(){
  var refinements = map(sample_utterance_refinement,base_utterances)
  return zip(base_utterances,refinements)
}

// semantics of disjunction
var eval_connective_truth = function(truth_vals){
  return any(function(t){t}, truth_vals) // check whether 'or' is true
}

// utterance meaning function
var utterance_meaning = function(utterance,refinements,world){
  if(utterance=='null'){
    return true
  }
  var current_base_utterances = utterance

  //  retrieve refinements of atomic utterances
  var base_utterance_refinements = map(
    function(x){return array_dict_lookup(refinements,x)},
    current_base_utterances
  )

  // calculate truth values for atomic utterances 
  // relative to possible refinements
  var base_utterance_truth_vals = map(
    function(x){return member_of(world,x)},
    base_utterance_refinements
  )

  return eval_connective_truth(base_utterance_truth_vals)
}

///

var literal_listener = cache(function(utterance,refinements) {
  Infer({model: function() {
    var knowledge_state = knowledge_state_prior()
    var world = sample_world_from_knowledge_state(knowledge_state)
    var meaning = utterance_meaning(utterance,refinements,world)
    condition(meaning)
    return [knowledge_state,world]
  }})
})

// speaker utility function
var speaker_utility = function(knowledge_state,listener){
  var scores = map(
    function(x){return listener.score([knowledge_state,x])},
    knowledge_state)
  return (1/knowledge_state.length)*sum(scores)
}

// level 1 speaker
var speaker1 = cache(function(knowledge_state,refinements){
  Infer({method:'enumerate',
         model (){
           var utterance = sample(utterance_prior())
           var listener = literal_listener(utterance,refinements)
           factor(alpha*speaker_utility(knowledge_state,listener))
           return utterance
         }})})

// level 1 pragmatic listener
var listener1 = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledge_state = knowledge_state_prior()
           var world = sample_world_from_knowledge_state(knowledge_state)
           var refinements = sample_refinements()
           var speaker = speaker1(knowledge_state,refinements)
           factor(speaker.score(utterance))
           return [knowledge_state, world]
         }})})

///fold:
var speaker2 = cache(function(knowledge_state){
  Infer({method:'enumerate',
         model (){
           var utterance = sample(utterance_prior())
           var listener = listener1(utterance)
           factor(alpha*speaker_utility(knowledge_state,listener))
           return utterance
         }})})

var listener2 = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledge_state = knowledge_state_prior()
           var world = sample_world_from_knowledge_state(knowledge_state)
           var speaker = speaker2(knowledge_state)
           factor(speaker.score(utterance))
           return [knowledge_state,world]
         }})})

var speaker3 = cache(function(knowledge_state){
  Infer({method:'enumerate',
         model (){
           var utterance = sample(utterance_prior())
           var listener = listener2(utterance)
           factor(alpha*speaker_utility(knowledge_state,listener))
           return utterance
         }})})

var listener3 = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledge_state = knowledge_state_prior()
           var world = sample_world_from_knowledge_state(knowledge_state)
           var speaker = speaker3(knowledge_state)
           factor(speaker.score(utterance))
           return [knowledge_state,world]
         }})})

var speaker4 = cache(function(knowledge_state){
  Infer({method:'enumerate',
         model (){
           var utterance = sample(utterance_prior())
           var listener = listener3(utterance)
           factor(alpha*speaker_utility(knowledge_state,listener))
           return utterance
         }})})

var listener4 = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledge_state = knowledge_state_prior()
           var world = sample_world_from_knowledge_state(knowledge_state)
           var speaker = speaker4(knowledge_state)
           factor(speaker.score(utterance))
           return [knowledge_state,world]
         }})})

var speaker5 = cache(function(knowledge_state){
  Infer({method:'enumerate',
         model (){
           var utterance = sample(utterance_prior())
           var listener = listener4(utterance)
           factor(alpha*speaker_utility(knowledge_state,listener))
           return utterance
         }})})

var listener5 = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledge_state = knowledge_state_prior()
           var world = sample_world_from_knowledge_state(knowledge_state)
           var speaker = speaker5(knowledge_state)
           factor(speaker.score(utterance))
           return [knowledge_state,world]
         }})})

var speaker6 = cache(function(knowledge_state){
  Infer({method:'enumerate',
         model (){
           var utterance = sample(utterance_prior())
           var listener = listener5(utterance)
           factor(alpha*speaker_utility(knowledge_state,listener))
           return utterance
         }})})

var listener6 = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledge_state = knowledge_state_prior()
           var world = sample_world_from_knowledge_state(knowledge_state)
           var speaker = speaker6(knowledge_state)
           factor(speaker.score(utterance))
           return [knowledge_state,world]
         }})})

var speaker7 = cache(function(knowledge_state){
  Infer({method:'enumerate',
         model (){
           var utterance = sample(utterance_prior())
           var listener = listener6(utterance)
           factor(alpha*speaker_utility(knowledge_state,listener))
           return utterance
         }})})

var listener7 = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledge_state = knowledge_state_prior()
           var world = sample_world_from_knowledge_state(knowledge_state)
           var speaker = speaker7(knowledge_state)
           factor(speaker.score(utterance))
           return [knowledge_state,world]
         }})})
///         

var speaker8 = cache(function(knowledge_state){
  Infer({method:'enumerate',
         model (){
           var utterance = sample(utterance_prior())
           var listener = listener7(utterance)
           factor(alpha*speaker_utility(knowledge_state,listener))
           return utterance
         }})})

var listener8 = cache(function(utterance){
  Infer({method:'enumerate',
         model (){
           var knowledge_state = knowledge_state_prior()
           var world = sample_world_from_knowledge_state(knowledge_state)
           var speaker = speaker8(knowledge_state)
           factor(speaker.score(utterance))
           //            return [knowledge_state,world]
           return world
         }})})

map(function(x){display('')
                display(x)
                display(listener8(x))},utterances)
~~~~

> **Exercises:** 

> 1. Check the behavior of the intermediate listener levels.
> 2. See what happens when you add in additional atomic utterances.
