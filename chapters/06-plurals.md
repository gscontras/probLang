---
layout: chapter
title: Expanding our ontology
description: "Plural predication"
---

### Chapter 6: Plural predication

Our models so far have focused on identifying singular states of the world: a single object, a single price, or, in the case of the scalar implicature or scope ambiguity models, the single number corresponding to the numerosity of some state. Now, we extend our sights to pluralities: collections of objects. A plurality has members with properties (e.g., weights), but a plurality has collective properties of its own (e.g., total weight). To model the ambiguity inherent to plural predication---whether we are talking about the individual member properties or the collective property---we'll need to expand our ontology to include sets of objects.

We begin with some knowledge about the world, which contains objects (which have their own properties, e.g., weights). The `statePrior` recursively generates states with the appropriate number of objects; each state corresponds to a plurality.

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

Now, to talk about the weight of a plurality of obejcts, given that we're dealing with scalar adjective semantics, we'll need to create a prior over threshold values. As before, these priors will be uniform over possible object weights. However, given that we can either talk about individual object weights or the weights of collections, we'll need two different threshold priors, one over possible individual object weights and another that scales up to possible collective weights.

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

> **Exercise:** Visualize the threshold priors.


The final piece of knowledge we need concerns utterances and a meaning function that will let us interpret them. A speaker can use the ambiguous utterances, "The objects are heavy," which receives either a distributive or a collective interpretation. For a slightly higher cost, the speaker can use unambiguous utterances: "The objects each are heavy" (distributive) or "The objects together are heavy" (collective). Lastly, the speaker has the option of saying nothing at all, the cheapest option.

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
var collInterpretation = function(state, collTheta) {
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
  isCollective ? collInterpretation(state,collTheta) :
  distInterpretation(state,distTheta)
}
~~~~

> **Exercise:** Try out the meaning function on some utterances.

This model was designed to account for the possible noise in our estimation of collective properties. For example, when talking about the collective height of a plurality, our estimate of the collective property will depend on the physical arrangement of that property (i.e., how the objects are stacked); a listener might encounter the objects in a different arrangement that the speaker did, introducing noise in the estimation of the collective property. To model this noise, we parameterize the `collectiveInterpretation` so that as noise increases our estimate of the collective property departs from the actual value. The implementation of noise depends crucially on the [error function](https://en.wikipedia.org/wiki/Error_function), which we use to convert the difference between the collective property and the collective threshold into the probability that the collective property exceeds that threshold.

~~~~
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

The literal listener uses this meaning function to update beliefs about the world. In the following code box, we wrap the RSA model in a function that runs `literalListener` as a function of the noise in the collective interpretation.

~~~~
///fold: 

// helper functions

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

///

// wrapper for plural predication model, a function of noise
var pluralPredication = function(collectiveNoise) {

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
  var noiseVariance = collectiveNoise == "no" ? 0.01 :
  collectiveNoise == "low" ? 1 :
  collectiveNoise == "mid" ? 2 : 3

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


  var literal = cache(function(utterance,distTheta,collTheta,isCollective) {
    return Infer({model: function(){
      var state = statePrior(numberObjects);
      var noise = noiseVariance
      condition(meaning(utterance,state,distTheta,collTheta,isCollective,noise));
      return state;
    }})
  });

  // check predictions for the "heavy" utterance
  // with a distributive threshold of 3,
  // a collective threshold of 8, and
  // a collective interpretation
  return literal("heavy",3,8,true)

}

viz.hist(pluralPredication("no"))


~~~~

**Exercise:** Check the predictions for the other values for `collectiveNoise`.

You might have guessed that we are dealing with a lifted-variable variant of RSA: the various interpretation parameters (i.e., `distTheta`, `collTheta`, and `isCollective`) get resolved at the level of the pragmatic listener:

~~~~
var listener = cache(function(utterance) {
  return Infer({model: function(){
    var state = statePrior(numberObjects);
    var isCollective = flip(0.8) // collective interpretation baserate
    var distTheta = distThetaPrior();
    var collTheta = collThetaPrior();
    factor(alpha * 
           speaker(state,distTheta,collTheta,isCollective).score(utterance) 
          );
    return {coll: isCollective, state: state}
  }});
});

~~~~

**Exercise:** Copy the code from the literal listener code box above, add in a `speaker` layer, and generate predictions from the pragmatic `listener`.


The full model combines all of these ingredients in the RSA framework, with recursive reasoning about the likely state of the world:

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
var pluralPredication = function(collectiveNoise) {

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
    return Infer({model: function(){
      var state = statePrior(numberObjects);
      var noise = noiseVariance
      condition(meaning(utterance,state,distThetaPos,collThetaPos,isCollective,noise));
      return state;
    }})
  });

  var speaker = cache(function(state,distTheta,collTheta,isCollective) {
    return Infer({model: function(){
      var utterance = utterancePrior()
      factor(literal(utterance,distTheta,collTheta,isCollective).score(state))
      return utterance
    }})
  });

  var listener = cache(function(utterance) {
    return Infer({model: function(){
      var state = statePrior(numberObjects);
      var isCollective = flip(0.8)
      var distTheta = distThetaPrior();
      var collTheta = collThetaPrior();
      factor(alpha * 
             speaker(state,distTheta,collTheta,isCollective).score(utterance) 
            );
      return {coll: isCollective, state: state}
    }});
  });

  return listener("heavy")
}

var conditions = [
  {noise : "0-no"},
  {noise : "1-low"},
  {noise : "2-mid"},
  {noise : "3-high"},
]

var L1predictions = map(function(stim) {
  var L1posterior = pluralPredication(stim.noise)
  return {
    x: stim.noise,
    y: exp(marginalize(L1posterior, "coll").score(true)),
  }
}, conditions)

viz.bar(L1predictions)
~~~~

**Exercise:** Generate predictions from the $$S_1$$ speaker.

Finally, we add in a speaker knowledge manipulation: the speaker either has full access to the individual weights in the world state (i.e., `knowledge == true`), or the speaker only has access to the total weight of the world state (i.e., `knowledge == false`). On the basis of this knowledge, the speaker makes an observation of the world state, and generates a belief distribution of the states that could have led to the observation.

~~~~


// check array identity
var arraysEqual = function(a1,a2) {
  return JSON.stringify(a1)==JSON.stringify(a2);
}

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

var speakerBelief = cache(function(state,speakerKnows) {
  return Infer({model: function(){
    var obs = function(s) {
      return speakerKnows ? s : sum(s) 
    }
    var bState = statePrior(numberObjects)
    condition(arraysEqual(obs(bState),obs(state)))
    return bState
  }})
})

~~~~

> **Exercise:** Try out the `speakerBelief` function---how does it work?

The full model includes this belief manipulation so that the pragmatic listener takes into account the speaker's knowledge state while interpreting the speaker's utterance.

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
    return Infer({model: function(){
      var state = statePrior(numberObjects);
      var noise = noiseVariance
      condition(meaning(utterance,state,distThetaPos,collThetaPos,isCollective,noise));
      return state;
    }})
  });

  var speakerBelief = cache(function(state,speakerKnows) {
    return Infer({model: function(){
      var obs = function(s) {
        return speakerKnows ? s : sum(s) 
      }
      var bState = statePrior(numberObjects)
      condition(arraysEqual(obs(bState),obs(state)))
      return bState
    }})
    })
  

  var speaker = cache(function(state,distThetaPos,collThetaPos,isCollective,speakerKnows) {
    return Infer({model: function(){
      var utterance = utterancePrior()
      var bDist = speakerBelief(state,speakerKnows)
      var lDist = literal(utterance,distThetaPos,collThetaPos,isCollective)
      factor(-1 *
             KL(bDist,
                lDist)
            )
      return utterance
    }})
  });

  var listener = cache(function(utterance,speakerKnows) {
    return Infer({model: function(){
      var state = statePrior(numberObjects);
      var isCollective = flip(0.8)
      var distThetaPos = distThetaPrior();
      var collThetaPos = collThetaPrior();
      factor(alpha * 
             speaker(state,distThetaPos,collThetaPos,isCollective,speakerKnows).score(utterance) 
            );
      return {coll: isCollective, state: state}
    }});
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

> **Exercise:**  Add an $$S_2$$ layer to the model.