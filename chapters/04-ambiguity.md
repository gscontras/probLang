---
layout: chapter
title: Combining RSA and compositional semantics
description: "Jointly inferring parameters and interpretations"
---

### Chapter 4: Jointly inferring parameters and interpretations

<!--   - Scope phenomena as uncertainty
  - Quantification and inference
  - Rational domain restriction -->



One of the most remarkable aspects of natural language is its compositionality: speakers generate arbitrarily complex meanings by stitching together their smaller, meaning-bearing parts. The compositional nature of language has served as the bedrock of semantic (indeed, linguistic) theory since its modern inception; Montague demonstrates with his fragment how meaning gets constructed from a lexicon and some rules of composition. Since then, compositionality has continued to guide semantic inquiry: what are the meanings of the parts, and what is the nature of the mechanism that composes them? Put differently, what are the representations of the language we use, and what is the nature of the computational system that manipulates them?

So far, the models we have considered operate at the level of full utterances.  These models assume conversational agents who reason over propositional content to arrive at enriched interpretations: "I want the blue one," "Some of the apples are red," "The electric kettle cost $10,000 dollars," etc. Now, let's approach meaning from the opposite direction: building the literal interpretations (and our model of the world that verifies them) from the bottom up: [semantic parsing](http://dippl.org/examples/semanticparsing.html). The model constructs literal interpretations and verifying worlds from the semantic atoms of sentences. However, whereas the model explicitly targets comositional semantics, it stops at the level of the literal listener, the base of RSA reasoning. In what follows, we consider a different approach to approximating compositional semantics within the RSA framework.

What we want is a way for our models of language understanding to target sub-propositional aspects of meaning. We might wind up going the route of the fully-compositional but admittedly-unwieldy CCG semantic parser, but for current purposes an easier path presents itself: parameterizing our meaning function so that conversational agents can reason jointly over utterance interpretations and the parameters that fix them. To see how this move serves our aims, we consider two applications.

#### Application 1: Quantifier scope ambiguities

Quantifier scope ambiguities have stood at the heart of linguistic inquiry for nearly as long as the enterprise has existed in its current form. reft:montague1973 builds the possibility for scope-shifting into the bones of his semantics. reft:may1977 proposes the rule of QR, which derives scope ambiguities syntactically. Either of these efforts ensures that when you combine quantifiers like *every* and *all* with other logical operators like negation, you get an ambiguous sentence; the ambiguities correspond to the relative scope of these operators within the logical form (LF) of the sentence (whence the name "scope ambiguities").

- *All of the apples aren't red.*
	- surface scope: ∀ > ¬; paraphrase: "none"
	- inverse scope: ¬ > ∀; paraphrease: "not all"

Rather than modeling the relative scoping of operators directly in the semantic composition, we can capture the possible meanings of these sentences---and, crucially, the active reasoning of speakers and listeners *about* these possible meanings---by assuming that the meaning of the utterance is evalatuated relative to a scope interpretation parameter (surface vs. inverse). The meaning function thus takes an utterance, a world state, and a scope interpretation parameter "inverse" (i.e., whether the utterance receives an inverse interpretation); it returns a truth value.

~~~~
// possible world states
var states = [0,1,2];
var statePrior = function() {
  uniformDraw(states);
}

// possible utterances
var utterances = ["null","all-not"];

// possible scopes
var scopePrior = function(){ 
  return uniformDraw(["surface", "inverse"])
}

// meaning function
var meaning = function(utterance, state, scope) {
  return utterance == "all-not" ? 
    scope == "surface" ? state == 0 :
  state < 2 : 
  true;
};

meaning("all-not", 1, "surface")

~~~~

The literal listener *L<sub>0</sub>* has prior uncertainty about the true state, *s*, and otherwise updates beliefs about *s* by conditioning on the meaning of *u* together with the intended scope:

~~~~
// Literal listener (L0)
var literalListener = cache(function(utterance, scope) {
  Infer({model: function(){
    var state = statePrior();
    condition(meaning(utterance,state,scope));
    return state;
  }});
});
~~~~

The interpretation variable (*scope*) is lifted, so that it will be actively reasoned about by the pragmatic listener. The pragmatic listener resolves the interpretation of an ambiguous utterance (determining what the speaker likely intended) while inferring the true state of the world:

~~~~
// Pragmatic listener (L1)
var pragmaticListener = cache(function(utterance) {
  Infer({model: function(){
    var state = statePrior();
    var scope = scopePrior();
    observe(speaker(scope,state),utterance);
    return [scope,state];
  }});
});
~~~~

The full model puts all of these pieces together:

~~~~
// Here is the code for the quantifier scope model

// possible utterances
var utterances = ["null","all-not"];
var cost = function(utterance) {
  return 1;
};
var utterancePrior = function() {
  return utterances[discrete(map(function(u) {
    return Math.exp(-cost(u));
  }, utterances))];
};

// possible world states
var states = [0,1,2];
var statePrior = function() {
  uniformDraw(states);
}

// possible scopes
var scopePrior = function(){ 
  return uniformDraw(["surface", "inverse"])
}

// meaning function
var meaning = function(utterance, state, scope) {
  return utterance == "all-not" ? 
    scope == "surface" ? state == 0 :
  state < 2 : 
  true;
};

// Literal listener (L0)
var literalListener = cache(function(utterance,scope) {
  return Infer({model: function(){
    var state = statePrior();
    condition(meaning(utterance,state,scope));
    return state;
  }});
});

// Speaker (S)
var speaker = cache(function(scope,state) {
  return Infer({model: function(){
    var utterance = utterancePrior();
    observe(literalListener(utterance,scope),state);
    return utterance;
  }});
});

// Pragmatic listener (L1)
var pragmaticListener = cache(function(utterance) {
  return Infer({model: function(){
    var state = statePrior();
    var scope = scopePrior();
    observe(speaker(scope,state),utterance);
    return {state: state,
            scope: scope}
  }});
});

var posterior = pragmaticListener("all-not")
viz.marginals(posterior);

~~~~

> **Exercises:**

> 1. The pragmatic listener believes the `inverse` interpretation is more likely. Why?
> 2. Add some more utterances and check what happens to the interpretation of the ambiguous utterance.

As in the non-literal language models from the previous chapter, here we can add uncertainty about the topic of conversation, or QUD. This move recognizes that "All of the apples aren't red" might be used to answer various questions. The listener might be interested to learn how many apples are red, or whether all of the apples are red, or whether none of them are, etc. Each question corresponds to a unique QUD; it's up to $$L_1$$ to decide which QUD is most likely given the utterance.

~~~~
// Here is the code for the quantifier scope model

// possible utterances
var utterances = ["null","all-not"];
var cost = function(utterance) {
  return 1;
};
var utterancePrior = function() {
  return utterances[discrete(map(function(u) {
    return Math.exp(-cost(u));
  }, utterances))];
};

// possible world states
var states = [0,1,2];
var statePrior = function() {
  uniformDraw(states);
}

// possible scopes
var scopePrior = function(){ 
  return uniformDraw(["surface", "inverse"])
}

// meaning function
var meaning = function(utterance, state, scope) {
  return utterance == "all-not" ? 
    scope == "surface" ? state == 0 :
  state < 2 : 
  true;
};

// QUDs
var QUDs = ["how many?","all red?"];
var QUDPrior = function() {
  uniformDraw(QUDs);
}
var QUDFun = function(QUD,state) {
  return QUD == "all red?" ? state == 2 :
  state;
};

// Literal listener (L0)
var literalListener = cache(function(utterance,scope,QUD) {
  Infer({model: function(){
    var state = statePrior();
    var qState = QUDFun(QUD,state)
    condition(meaning(utterance,state,scope));
    return qState;
  }});
});

// Speaker (S)
var speaker = cache(function(scope,state,QUD) {
  Infer({model: function(){
    var utterance = utterancePrior();
    var qState = QUDFun(QUD,state);
    observe(literalListener(utterance,scope,QUD),qState);
    return utterance;
  }});
});

// Pragmatic listener (L1)
var pragmaticListener = cache(function(utterance) {
  Infer({model: function(){
    var state = statePrior();
    var scope = scopePrior();
    var QUD = QUDPrior();
    observe(speaker(scope,state,QUD),utterance);
    return {state: state,
            scope: scope}
  }});
});

var posterior = pragmaticListener("all-not")
viz.marginals(posterior);

~~~~

> **Exercises:** 

> 1. What does the pragmatic listener infer about the QUD? Does this match your own intuitions? If not, how can you more closely align the model's predictions with your own?
> 2. Try adding a `none red?` QUD. What does this addition do to $$L_1$$'s inference about the state? Why?


Here we link to the [next chapter](05-vagueness.html).