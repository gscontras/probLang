---
layout: chapter
title: Expanding our ontology
description: "Plural predication"
---

### Chapter 6: Plural predication

Some knowledge about the world, which contains objects (which have weights):

~~~~
// possible object weights
var objects = [2,3,4];
var objectPrior = function() {
  uniformDraw(objects);
}

var numberObjects = 3

// build states with n many objects
var statePrior = function(nObjLeft,stateSoFar) {
  var stateSoFar = stateSoFar == undefined ? [] : stateSoFar
  if (nObjLeft == 0) {
    return stateSoFar
  } else {
    var newObj = objectPrior()
    var newState = stateSoFar.concat([newObj])
    return statePrior(nObjLeft - 1,newState)
  }
}
~~~~

> **Exercise:** Visualize the state prior.

Now, given that we're dealing with scalar adjective semantics, we'll also need to create a prior over threshold values. As before, these priors will be uniform over possible object weights. However, given that we can either talk about individual object weights or the weights of collections, we'll need two different threshold priors, one over possible individual object weights and another that scales up to possible collection weights.

~~~~
// possible object weights
  var objects = [2,3,4];
  var objectPrior = function() {
    uniformDraw(objects);
  }

  var numberObjects = 3

  // build states with n many objects
  var statePrior = function(nObjLeft,stateSoFar) {
    var stateSoFar = stateSoFar == undefined ? [] : stateSoFar
    if (nObjLeft == 0) {
      return stateSoFar
    } else {
      var newObj = objectPrior()
      var newState = stateSoFar.concat([newObj])
      return statePrior(nObjLeft - 1,newState)
    }
  }

  // threshold priors
  var distThetaPrior = function(){return objectPrior()};  
  var collThetaPrior = function(){return uniformDraw([2,3,4,5,6,7,8,9,10,11,12])};
~~~~

Now let's get some utterances and a meaning function that will let us interpret them. A speaker can use the ambiguous utterances, "The objects are heavy," which receives either a distributive or a collective interpretation. For a slightly higher cost, the speaker can use unambiguous utterances: "The objects each are heavy" or "The objects together are heavy." Lastly, the speaker has the option of saying nothing at all, the cheapest option of all.

~~~~
var utterances = [
  "null",
  "heavy",
  "each-heavy",
  "together-heavy"
];

// costs: null < ambiguous < unambiguous 
var utterancePrior = function() {
  return categorical([3,2,1,1],utterances)
};

// x > theta interpretations
var collInterpretation = function(state, collTheta,noise) {
  return sum(state) >= collTheta
}

var distInterpretation = function(state, distTheta) {
  return all(function(x){x >= distTheta}, state)
}

// meaning function
var meaning = function(utt,state,distTheta,collTheta,isCollective) {
  return  utt == "null" ? true :
  utt == "each-heavy" ? distInterpretation(state,distTheta) :
  utt == "together-heavy" ? collInterpretation(state,collTheta) :
  isCollective ? collInterpretation(state,collTheta,noise) :
  distInterpretation(state,distTheta)
}
~~~~

This model was designed to account for the possible noise in our estimation of collective properties. To model this noise, we must parameterize the `collectiveInterpretation` so that as noise increases our estimate of the collective property departs from the actual value.

~~~~
var utterances = [
  "null",
  "heavy",
  "each-heavy",
  "together-heavy"
];

// costs: null < ambiguous < unambiguous 
var utterancePrior = function() {
  return categorical([3,2,1,1],utterances)
};

// x > theta interpretations
var collInterpretation = function(state, collTheta,noise) {
  var weight = 1 - (0.5 * (1 + erf((collTheta - sum(state)) / 
                                   (noise * Math.sqrt(2)))))
  return flip(weight)
}

var distInterpretation = function(state, distTheta) {
  return all(function(x){x >= distTheta}, state)
}

// meaning function
var meaning = function(utt,state,distTheta,collTheta,isCollective,noise) {
  return  utt == "null" ? true :
  utt == "each-heavy" ? distInterpretation(state,distTheta) :
  utt == "together-heavy" ? collInterpretation(state,collTheta,noise) :
  isCollective ? collInterpretation(state,collTheta,noise) :
  distInterpretation(state,distTheta)
}
~~~~

~~~~
///fold: 

// helper functions
// exp
var exp = function(x){return Math.exp(x)}

// error function
var erf = function(x) {
  var a1 =  0.254829592;
  var a2 = -0.284496736;
  var a3 =  1.421413741;
  var a4 = -1.453152027;
  var a5 =  1.061405429;
  var p  =  0.3275911;
  var sign = x < 0 ? -1 : 1
  var z = Math.abs(x);
  var t = 1.0/(1.0 + p*z);
  var y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t*Math.exp(-z*z);
  var answer = sign*y
  return answer
}

// check array identity
var arraysEqual = function(a1,a2) {
  return JSON.stringify(a1)==JSON.stringify(a2);
}

// get probabilities from a distribution
var distProbs = function(dist, supp) {
  return map(function(s) {
    return Math.exp(dist.score(s))
  }, supp)
}

// calculate KL divergence between two distributions
var KL = function(p, q) {
  var supp = sort(p.support());
  var P = distProbs(p, supp), Q = distProbs(q, supp);
  var diverge = function(xp,xq) {
    return xp == 0 ? 0 : (xp * Math.log(xp / xq) );
  };
  return sum(map2(diverge,P,Q));
};

///


// wrapper for plural predication model
var pluralPredication = function( collectiveNoise,
                                   knowledge
                                  ) {

  // possible object weights
  var objects = [2,3,4];
  var objectPrior = function() {
    uniformDraw(objects);
  }

  var numberObjects = 3

  // build states with n many objects
  var statePrior = function(nObjLeft,stateSoFar) {
    var stateSoFar = stateSoFar == undefined ? [] : stateSoFar
    if (nObjLeft == 0) {
      return stateSoFar
    } else {
      var newObj = objectPrior()
      var newState = stateSoFar.concat([newObj])
      return statePrior(nObjLeft - 1,newState)
    }
  }

  // threshold priors
  var distThetaPrior = function(){return objectPrior()};  
  var collThetaPrior = function(){return uniformDraw([2,3,4,5,6,7,8,9,10,11,12])};

  // noise variance
  var noiseVariance = collectiveNoise == "0-no" ? 0.01 :
  collectiveNoise == "1-low" ? 1 :
  collectiveNoise == "2-mid" ? 2 : 3

  var utterances = [
    "null",
    "heavy",
    "each-heavy",
    "together-heavy"
  ];

  // costs: null < ambiguous < unambiguous 
  var utterancePrior = function() {
    return categorical([3,2,1,1],utterances)
  };
  
  // x > theta interpretations
  var collInterpretation = function(state, collTheta,noise) {
    var weight = 1 - (0.5 * (1 + erf((collTheta - sum(state)) / 
                                     (noise * Math.sqrt(2)))))
    return flip(weight)
  }

  var distInterpretation = function(state, distTheta) {
    return all(function(x){x >= distTheta}, state)
  }

  // meaning function
  var meaning = function(utt,state,distTheta,collTheta,isCollective,noise) {
    return  utt == "null" ? true :
    utt == "each-heavy" ? distInterpretation(state,distTheta) :
    utt == "together-heavy" ? collInterpretation(state,collTheta,noise) :
    isCollective ? collInterpretation(state,collTheta,noise) :
    distInterpretation(state,distTheta)
  }

  var alpha = 10

  var literal = cache(function(utterance,distThetaPos,collThetaPos,isCollective) {
    Infer({method:"enumerate"}, function(){
      var state = statePrior(numberObjects);
      var noise = noiseVariance
      condition(meaning(utterance,state,distThetaPos,collThetaPos,isCollective,noise));
      return state;
    })
  });

  var speaker = cache(function(state,distThetaPos,collThetaPos,isCollective) {
    Infer({method:"enumerate"}, function(){
      var utterance = utterancePrior()
      factor(literal(utterance,distThetaPos,collThetaPos,isCollective).score(state))
      return utterance
    })
  });

  var listener = cache(function(utterance) {
    Infer({method:"enumerate"}, function(){
      var state = statePrior(numberObjects);
      var isCollective = flip(0.8)
      var distThetaPos = distThetaPrior();
      var collThetaPos = collThetaPrior();
      factor(alpha * 
             speaker(state,distThetaPos,collThetaPos,isCollective).score(utterance) 
            );
      return {coll: isCollective, state: state}
    });
  });

  return listener("heavy",knowledge)
}

var conditions = [
  {noise : "0-no", knowledge : true},
  {noise : "0-no", knowledge : false},
  {noise : "1-low", knowledge : true},
  {noise : "1-low", knowledge : false},
  {noise : "2-mid", knowledge : true},
  {noise : "2-mid", knowledge : false},
  {noise : "3-high", knowledge : true},
  {noise : "3-high", knowledge : false},
]

var L1predictions = map(function(stim) {
  var L1posterior = pluralPredication(stim.noise,stim.knowledge)
  return {
    x: stim.noise,
    y: exp(marginalize(L1posterior, "coll").score(true)),
  }
}, conditions)

viz.bar(L1predictions)
~~~~

Finally, we add in a speaker knowledge manipulation: the speaker either has full access to the individual weights in the world state (i.e., `knowledge == true`), or the speaker only has access to the total weight of the world state (i.e., `knowledge == false`).

~~~~
///fold: 

// helper functions
// exp
var exp = function(x){return Math.exp(x)}

// error function
var erf = function(x) {
  var a1 =  0.254829592;
  var a2 = -0.284496736;
  var a3 =  1.421413741;
  var a4 = -1.453152027;
  var a5 =  1.061405429;
  var p  =  0.3275911;
  var sign = x < 0 ? -1 : 1
  var z = Math.abs(x);
  var t = 1.0/(1.0 + p*z);
  var y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t*Math.exp(-z*z);
  var answer = sign*y
  return answer
}

// check array identity
var arraysEqual = function(a1,a2) {
  return JSON.stringify(a1)==JSON.stringify(a2);
}

// get probabilities from a distribution
var distProbs = function(dist, supp) {
  return map(function(s) {
    return Math.exp(dist.score(s))
  }, supp)
}

// calculate KL divergence between two distributions
var KL = function(p, q) {
  var supp = sort(p.support());
  var P = distProbs(p, supp), Q = distProbs(q, supp);
  var diverge = function(xp,xq) {
    return xp == 0 ? 0 : (xp * Math.log(xp / xq) );
  };
  return sum(map2(diverge,P,Q));
};

///


// wrapper for plural predication model
var pluralPredication = function( collectiveNoise,
                                   knowledge
                                  ) {

  // possible object weights
  var objects = [2,3,4];
  var objectPrior = function() {
    uniformDraw(objects);
  }

  var numberObjects = 3

  // build states with n many objects
  var statePrior = function(nObjLeft,stateSoFar) {
    var stateSoFar = stateSoFar == undefined ? [] : stateSoFar
    if (nObjLeft == 0) {
      return stateSoFar
    } else {
      var newObj = objectPrior()
      var newState = stateSoFar.concat([newObj])
      return statePrior(nObjLeft - 1,newState)
    }
  }

  // threshold priors
  var distThetaPrior = function(){return objectPrior()};  
  var collThetaPrior = function(){return uniformDraw([2,3,4,5,6,7,8,9,10,11,12])};

  // noise variance
  var noiseVariance = collectiveNoise == "0-no" ? 0.01 :
  collectiveNoise == "1-low" ? 1 :
  collectiveNoise == "2-mid" ? 2 : 3

  var utterances = [
    "null",
    "heavy",
    "each-heavy",
    "together-heavy"
  ];

  // costs: null < ambiguous < unambiguous 
  var utterancePrior = function() {
    return categorical([3,2,1,1],utterances)
  };
  
  // x > theta interpretations
  var collInterpretation = function(state, collTheta,noise) {
    var weight = 1 - (0.5 * (1 + erf((collTheta - sum(state)) / 
                                     (noise * Math.sqrt(2)))))
    return flip(weight)
  }

  var distInterpretation = function(state, distTheta) {
    return all(function(x){x >= distTheta}, state)
  }

  // meaning function
  var meaning = function(utt,state,distTheta,collTheta,isCollective,noise) {
    return  utt == "null" ? true :
    utt == "each-heavy" ? distInterpretation(state,distTheta) :
    utt == "together-heavy" ? collInterpretation(state,collTheta,noise) :
    isCollective ? collInterpretation(state,collTheta,noise) :
    distInterpretation(state,distTheta)
  }

  var alpha = 10

  var literal = cache(function(utterance,distThetaPos,collThetaPos,isCollective) {
    Infer({method:"enumerate"}, function(){
      var state = statePrior(numberObjects);
      var noise = noiseVariance
      condition(meaning(utterance,state,distThetaPos,collThetaPos,isCollective,noise));
      return state;
    })
  });

  var speakerBelief = cache(function(state,speakerKnows) {
    Infer({method:"enumerate"}, function(){
      var obs = function(s) {
        return speakerKnows ? s : sum(s) 
      }
      var bState = statePrior(numberObjects)
      condition(arraysEqual(obs(bState),obs(state)))
      return bState
    })
  })

  var speaker = cache(function(state,distThetaPos,collThetaPos,isCollective,speakerKnows) {
    Infer({method:"enumerate"}, function(){
      var utterance = utterancePrior()
      var bDist = speakerBelief(state,speakerKnows)
      var lDist = literal(utterance,distThetaPos,collThetaPos,isCollective)
      factor(-1 *
             KL(bDist,
                lDist)
            )
      return utterance
    })
  });

  var listener = cache(function(utterance,speakerKnows) {
    Infer({method:"enumerate"}, function(){
      var state = statePrior(numberObjects);
      var isCollective = flip(0.8)
      var distThetaPos = distThetaPrior();
      var collThetaPos = collThetaPrior();
      factor(alpha * 
             speaker(state,distThetaPos,collThetaPos,isCollective,speakerKnows).score(utterance) 
            );
      return {coll: isCollective, state: state}
    });
  });

  return listener("heavy",knowledge)
}

var conditions = [
  {noise : "0-no", knowledge : true},
  {noise : "0-no", knowledge : false},
  {noise : "1-low", knowledge : true},
  {noise : "1-low", knowledge : false},
  {noise : "2-mid", knowledge : true},
  {noise : "2-mid", knowledge : false},
  {noise : "3-high", knowledge : true},
  {noise : "3-high", knowledge : false},
]

var L1predictions = map(function(stim) {
  var L1posterior = pluralPredication(stim.noise,stim.knowledge)
  return {
    x: stim.noise,
    y: exp(marginalize(L1posterior, "coll").score(true)),
    knowledge: stim.knowledge
  }
}, conditions)

viz.bar(L1predictions, {groupBy: 'knowledge'})
~~~~