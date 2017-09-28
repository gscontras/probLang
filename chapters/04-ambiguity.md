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

So far, the models we have considered operate at the level of full utterances.  These models assume conversational agents who reason over propositional content to arrive at enriched interpretations: "I want the blue one," "Some of the apples are red," "The electric kettle cost $10,000 dollars," etc. Now, let's approach meaning from the opposite direction: building the literal interpretations (and our model of the world that verifies them) from the bottom up: [semantic parsing](http://dippl.org/examples/semanticparsing.html). The model constructs literal interpretations and verifying worlds from the semantic atoms of sentences. However, whereas the model explicitly targets compositional semantics, it stops at the level of the literal listener, the base of RSA reasoning. In what follows, we consider a different approach to approximating compositional semantics within the RSA framework.

What we want is a way for our models of language understanding to target sub-propositional aspects of meaning. We might wind up going the route of the fully-compositional but admittedly-unwieldy CCG semantic parser, but for current purposes an easier path presents itself: parameterizing our meaning function so that conversational agents can reason jointly over utterance interpretations and the parameters that fix them. To see how this move serves our aims, we consider the following application.

#### Application: Quantifier scope ambiguities

Quantifier scope ambiguities have stood at the heart of linguistic inquiry for nearly as long as the enterprise has existed in its current form. reft:montague1973 builds the possibility for scope-shifting into the bones of his semantics. reft:may1977 proposes the rule of QR, which derives scope ambiguities syntactically. Either of these efforts ensures that when you combine quantifiers like *every* and *all* with other logical operators like negation, you get an ambiguous sentence; the ambiguities correspond to the relative scope of these operators within the logical form (LF) of the sentence (whence the name "scope ambiguities").

- *Every apple isn't red.*
	- surface scope: ∀ > ¬; paraphrase: "none"
	- inverse scope: ¬ > ∀; paraphrease: "not all"

Rather than modeling the relative scoping of operators directly in the semantic composition, we can capture the possible meanings of these sentences---and, crucially, the active reasoning of speakers and listeners *about* these possible meanings---by assuming that the meaning of the utterance is evalatuated relative to a scope interpretation parameter (surface vs. inverse). The meaning function thus takes an utterance, a world state, and an interpretation parameter `scope` (i.e., which interpretation the ambiguous utterance receives); it returns a truth value.

~~~~
// possible world states: how many apples are red
var states = [0,1,2,3];
var statePrior = function() {
  uniformDraw(states);
}

// possible utterances: saying nothing or asserting the ambiguous utterance
var utterances = ["null","every-not"];

// possible scopes
var scopePrior = function(){ 
  return uniformDraw(["surface", "inverse"])
}

// meaning function
var meaning = function(utterance, state, scope) {
  return utterance == "every-not" ? 
    scope == "surface" ? state == 0 :
  state < 3 : 
  true;
};

meaning("every-not", 1, "surface")

~~~~

The literal listener $$L_0$$ has prior uncertainty about the true state, *s*, and otherwise updates beliefs about *s* by conditioning on the meaning of *u* together with the intended scope:

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

The interpretation variable (`scope`) is lifted, so that it will be actively reasoned about by the pragmatic listener. The pragmatic listener resolves the interpretation of an ambiguous utterance (determining what the speaker likely intended) while inferring the true state of the world:

~~~~
// Pragmatic listener (L1)
var pragmaticListener = cache(function(utterance) {
  Infer({model: function(){
    var state = statePrior();
    var scope = scopePrior();
    observe(speaker(scope,state),utterance);
    return {state: state,
            scope: scope}
  }});
});
~~~~

The full model puts all of these pieces together:

~~~~
// Here is the code for the quantifier scope model

// possible utterances
var utterances = ["null","every-not"];

var utterancePrior = function() {
  uniformDraw(utterances)
}


// possible world states
var states = [0,1,2,3];
var statePrior = function() {
  uniformDraw(states);
}

// possible scopes
var scopePrior = function(){ 
  return uniformDraw(["surface", "inverse"])
}

// meaning function
var meaning = function(utterance, state, scope) {
  return utterance == "every-not" ? 
    scope == "surface" ? state == 0 :
  state < 3 : 
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

var posterior = pragmaticListener("every-not")
viz.marginals(posterior);

~~~~

> **Exercises:**

> 1. The pragmatic listener believes the `inverse` interpretation is more likely. Why?
> 2. Add some more utterances and check what happens to the interpretation of the ambiguous utterance.

As in the non-literal language models from the previous chapter, here we can add uncertainty about the topic of conversation, or QUD. This move recognizes that "Every apple isn't red" might be used to answer various questions. The listener might be interested to learn how many apples are red, or whether all of the apples are red, or whether none of them are, etc. Each question corresponds to a unique QUD; it's up to $$L_1$$ to decide which QUD is most likely given the utterance.

~~~~
// Here is the code for the QUD quantifier scope model

// possible utterances
var utterances = ["null","every-not"];

var utterancePrior = function() {
  uniformDraw(utterances)
}


// possible world states
var states = [0,1,2,3];
var statePrior = function() {
  uniformDraw(states);
}

// possible scopes
var scopePrior = function(){ 
  return uniformDraw(["surface", "inverse"])
}

// meaning function
var meaning = function(utterance, state, scope) {
  return utterance == "every-not" ? 
    scope == "surface" ? state == 0 :
  state < 3 : 
  true;
};

// QUDs
var QUDs = ["how many?","all red?"];
var QUDPrior = function() {
  uniformDraw(QUDs);
}
var QUDFun = function(QUD,state) {
  return QUD == "all red?" ? state == 3 :
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

var posterior = pragmaticListener("every-not")
viz.marginals(posterior);

~~~~

> **Exercises:** 

> 1. What does the pragmatic listener infer about the QUD? Does this match your own intuitions? If not, how can you more closely align the model's predictions with your own?
> 2. Try adding a `none red?` QUD. What does this addition do to $$L_1$$'s inference about the state? Why?


Finally, we can add one more layer to our models: rather than predicting how a listener would interpret the ambiguous utterance, we can predict how a *speaker* would use it. In other words, we can derive predictions about whether the ambiguous utterance would be endorsed as a good description of a specific state of the world. A speaker might see that two out of three apples are red. In this scenario, is the ambiguous utterance a good description? To answer this question, the speaker should reason about how a listener would interpret the utterance. But our current speaker model isn't able to derive these predictions for us, given the variables that have been lifted to the level of $$L_1$$ (i.e., `scope` and `QUD`). In the case of lifted variables, we'll need another level of inference to model a *pragmatic* speaker, $$S_2$$.

This pragmatic speaker observes the state of the world and chooses an utterance that would best communicate this state to a pragmatic listener:

~~~~
// Pragmatic speaker (S2)
var pragmaticSpeaker = cache(function(state) {
  Infer({model: function(){
    var utterance = utterancePrior();
    factor(pragmaticListener(utterance).score(state))
    return utterance
  }})
})

~~~~

The full model simply adds $$S_2$$ as an additional layer of inference.

~~~~
// Here is the code for the quantifier scope model

// possible utterances
var utterances = ["null","every-not"];

var utterancePrior = function() {
  uniformDraw(utterances)
}

// possible world states
var states = [0,1,2,3];
var statePrior = function() {
  uniformDraw(states);
}

// possible scopes
var scopePrior = function(){ 
  return uniformDraw(["surface", "inverse"])
}

// meaning function
var meaning = function(utterance, state, scope) {
  return utterance == "every-not" ? 
    scope == "surface" ? state == 0 :
  state < 3 : 
  true;
};

// QUDs
var QUDs = ["how many?","all red?","none red?"];
var QUDPrior = function() {
  uniformDraw(QUDs);
}
var QUDFun = function(QUD,state) {
  QUD == "all red?" ? state == 3 :
  QUD == "none red?" ? state == 0 :
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

var alpha = 1

// Speaker (S)
var speaker = cache(function(scope,state,QUD) {
  Infer({model: function(){
    var utterance = utterancePrior();
    var qState = QUDFun(QUD,state);
    factor(alpha * literalListener(utterance,scope,QUD).score(qState));
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
    return state
  }});
});

// Pragmatic speaker (S2)
var pragmaticSpeaker = cache(function(state) {
  Infer({model: function(){
    var utterance = utterancePrior();
    factor(pragmaticListener(utterance).score(state))
    return utterance
  }})
})

// A speaker decides whether to endorse the ambiguous utterance as a 
// description of the not-all world state
pragmaticSpeaker(2)

~~~~

> **Exercise:** What changes can you make to the model to get the speaker's endorsement to increase? Why do these changes have this effect?



Here we link to the [next chapter](05-vagueness.html).