---
layout: chapter
title: Summary and outlook
description: "What have we done???"
---

### Day 5: Summary and outlook

What have we done???

> **Exercises:** 

> 1. Discuss.
> 2. Please tell us how you thought to course went by filling out this [short form](https://goo.gl/forms/yQFmjsoR9TwCpFT03).

Thank you!


<!-- ~~~~
// Here is the code for the determiners model

// worlds contain two individuals that can be blue and can be feps
var worldPrior = function(){
  return [{fep: flip(0.5), blue: flip(0.5)},
          {fep: flip(0.5), blue: flip(0.5)}]
}

// possible utterances
var utterances = ["the fep is blue", 
                  "a fep is blue", 
                  ""
                 ];

// utterance costs:
var cost = function(u) {
    return 1
}

// utterance prior choose utterances in proportion to their (negative) cost
var utterancePrior = function() {
  return utterances[discrete(map(function(u) {return Math.exp(-cost(u));}, 
                                 utterances))];
};  

//meaning function
var meaning = function(utterance, world) {
  if (utterance=="") return true
  var words = utterance.split(" ")
  var det = words[0]
  var cat = words[1]
  var prop = words[3]
  if (det==="the") {
    //sample a fep and check if it's blue
    var catMembers = filter(function(x){return x[cat]}, world)
    if (catMembers.length == 0) {return false}
    var sampledMember = uniformDraw(catMembers) 
    return sampledMember[prop]
  } else { //"a": check for blue feps
    return any(function(x){x[cat] & x[prop]}, world)
  }};

// literal listener infers world given utterance
var literalListener = cache(function(utterance) {
  return Infer({method : "enumerate"},
               function() {
    var world = worldPrior()
    condition(meaning(utterance, world))
    return world;
  })
})

// speaker chooses utterance given world
var speaker = cache(function(world) {
  return Infer({method : "enumerate"},
               function() {
    var utterance = utterancePrior();
    observe(literalListener(utterance),world)
    return utterance;
  });
});

// pragmatic listener infers worls given utterance
var pragmaticListener = cache(function(utterance) {
  return Infer({method : "enumerate"},
               function() {
    var world = worldPrior();
    observe(speaker(world),utterance)
    return world
  });
});

// pragmatic speaker chooses utterance given world
var speaker2 = cache(function(world) {
  return Infer({method : "enumerate"},
               function() {
    var utterance = utterancePrior();
    observe(pragmaticListener(utterance),world)
    return utterance;
  });
});

// two blue feps
var w_1111 = [{fep: true, blue: true},
              {fep: true, blue: true}]   
// one blue fep, one non-blue fep
var w_1112 = [{fep: true, blue: true},
              {fep: true, blue: false}]                              
// two non-blue feps
var w_1212 = [{fep: true, blue: false},
              {fep: true, blue: false}]   
// one blue fep, one blue other
var w_1121 = [{fep: true, blue: true},
              {fep: false, blue: true}]                   
// one blue fep, one non-blue other
var w_1122 = [{fep: true, blue: true},
              {fep: false, blue: false}]                   
// one non-blue fep, one blue other
var w_1221 = [{fep: true, blue: false},
              {fep: false, blue: true}]   
// one non-blue fep, one non-blue other
var w_1222 = [{fep: true, blue: false},
              {fep: false, blue: false}]   

print("pragmatic listeners's interpretation of 'the fep is blue':")
viz.auto(pragmaticListener("the fep is blue"))
print("pragmatic listeners's interpretation of 'a fep is blue':")
viz.auto(pragmaticListener("a fep is blue"))

print("pragmatic speaker's utterance choice for a world with two blue feps:")
viz.auto(speaker2(w_1111))

~~~~


~~~~
// worlds contain two individuals that can be blue and can be feps
var worldPrior = function(){
  return [{fep: flip(0.5), blue: flip(0.5)},
          {fep: flip(0.5), blue: flip(0.5)}]
}

// possible utterances
var utterances = ["the fep is blue", 
                  "a fep is blue", 
                  "the fep isnt blue", 
                  "a fep isnt blue", 
                  "",
                  "every thing is blue",
                  "every thing isnt blue"
                 ];

// utterance costs: negative utterances are twice as expensive
var cost = function(u) {
  var words = u.split(" ")
  var verb = words[2]
  if (verb==="isnt") {
    return 2
  } else {
    return 1
  }
}

// utterance prior choose utterances in proportion to their (negative) cost
var utterancePrior = function() {
  return utterances[discrete(map(function(u) {return Math.exp(-cost(u));}, 
                                 utterances))];
};  

//meaning function
var meaning = function(utterance, world) {
  if (utterance=="") return true
  var words = utterance.split(" ")
  var det = words[0]
  var cat = words[1]
  var verb = words[2]
  var prop = words[3]
  if (det==="every") {
    if (verb == "is") { //check that everything is blue
      return all(function(x){x[prop]}, world)
    } else { //check that nothing is blue
      return all(function(x){!x[prop]}, world)
    }
  }
  if (det==="the") {
    //sample a fep and check if it's blue
    var catMembers = filter(function(x){return x[cat]}, world)
    if (catMembers.length == 0) {return false}
    var sampledMember = uniformDraw(catMembers) 
    if (verb == "is") {return sampledMember[prop]
                      } else {return !sampledMember[prop]}
  } else { //"a": check for blue feps
    if (verb == "is") {return any(function(x){x[cat] & x[prop]}, world)
                      } else {return any(function(x){x[cat] & !x[prop]}, world)
                             }}};

// literal listener infers world given utterance
var literalListener = cache(function(utterance) {
  return Infer({method : "enumerate"},
               function() {
    var world = worldPrior()
    condition(meaning(utterance, world))
    return world;
  })
})

// speaker chooses utterance given world
var speaker = cache(function(world) {
  return Infer({method : "enumerate"},
               function() {
    var utterance = utterancePrior();
    observe(literalListener(utterance),world)
    return utterance;
  });
});

// pragmatic listener infers worls given utterance
var pragmaticListener = cache(function(utterance) {
  return Infer({method : "enumerate"},
               function() {
    var world = worldPrior();
    observe(speaker(world),utterance)
    return world
  });
});

// pragmatic speaker chooses utterance given world
var speaker2 = cache(function(world) {
  return Infer({method : "enumerate"},
               function() {
    var utterance = utterancePrior();
    observe(pragmaticListener(utterance),world)
    return utterance;
  });
});

// two blue feps
var w_1111 = [{fep: true, blue: true},
              {fep: true, blue: true}]   
// one blue fep, one non-blue fep
var w_1112 = [{fep: true, blue: true},
              {fep: true, blue: false}]                              
// two non-blue feps
var w_1212 = [{fep: true, blue: false},
              {fep: true, blue: false}]   
// one blue fep, one blue other
var w_1121 = [{fep: true, blue: true},
              {fep: false, blue: true}]                   
// one blue fep, one non-blue other
var w_1122 = [{fep: true, blue: true},
              {fep: false, blue: false}]                   
// one non-blue fep, one blue other
var w_1221 = [{fep: true, blue: false},
              {fep: false, blue: true}]   
// one non-blue fep, one non-blue other
var w_1222 = [{fep: true, blue: false},
              {fep: false, blue: false}]   

print("pragmatic listeners's interpretation of 'the fep is blue':")
viz.auto(pragmaticListener("the fep is blue"))
print("pragmatic listeners's interpretation of 'a fep is blue':")
viz.auto(pragmaticListener("a fep is blue"))

print("pragmatic speaker's utterance choice for a world with two blue feps:")
viz.auto(speaker2(w_1111))

~~~~

~~~~
// Here is the code for the modifiers model

~~~~ -->

