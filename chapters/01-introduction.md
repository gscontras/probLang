---
layout: chapter
title: Introducing the Rational Speech Act framework
description: "An introduction to language understanding as Bayesian inference"
---

### Chapter 1: Language understanding as Bayesian inference

<!--   - Gricean pragmatics, probability theory, and utility functions 
  - The basic Rational Speech-Acts framework
  - Background knowledge in language understanding -->


<!-- One of the most remarkable aspects of natural language is its compositionality: speakers generate arbitrarily complex meanings by stitching together their smaller, meaning-bearing parts. The compositional nature of language has served as the bedrock of semantic (indeed, linguistic) theory since its modern inception; \cite{montague1973} builds this principle into the bones of his semantics, demonstrating with his fragment how meaning gets constructed from a lexicon and some rules of composition. Since then, compositionality has continued to guide semantic inquiry: what are the meaning of the parts, and what is the nature of the mechanism that composes them? Put differently, what are the representations of the language we use, and what is the nature of the computational system that manipulates them? -->

Much work in formal, compositional semantics follows the tradition of positing systematic but inflexible theories of meaning. However, in practice, the meaning we derive from language is heavily dependent on nearly all aspects of context, both linguistic and situational. To formally explain these nuanced aspects of meaning and better understand the compositional mechanism that delivers them, recent work in formal pragmatics recognizes semantics not as one of the final steps in meaning calculation, but rather as one of the first. Within the Bayesian Rational Speech Act framework refp:frankgoodman2012, speakers and listeners reason about each other's reasoning about the literal interpretation of utterances. The resulting interpretation necessarily depends on the literal interpretation of an utterance, but is not necessarily wholly determined by it. This move---reasoning about likely interpretations---provides ready explanations for complex phenomena ranging from metaphor refp:kaoetal2014metaphor and hyperbole refp:kaoetal2014 to the specification of thresholds in degree semantics refp:lassitergoodman2013.

The probabilistic pragmatics approach leverages the tools of structured probabilistic models formalized in a stochastic 𝞴-calculus to develop and refine a general theory of communication. The framework synthesizes the knowledge and approaches from diverse areas---formal semantics, Bayesian models of inference, formal theories of measurement, philosophy of language, etc.---into an articulated theory of language in practice. These new tools yield broader empirical coverage and richer explanations for linguistic phenomena through the recognition of language as a means of communication, not merely a vacuum-sealed formal system. By subjecting the heretofore off-limits land of pragmatics to articulated formal models, the rapidly growing body of research both informs pragmatic phenomena and enriches theories of semantics. In what follows, we consider the first foray into this framework.

#### Introducing the Rational Speech Act framework

The Rational Speech Act (RSA) framework views communication as recursive reasoning between a speaker and a listener. The listener interprets the speaker’s utterance by reasoning about a cooperative speaker trying to inform a naive listener about some state of affairs. Using Bayesian inference, the listener infers what the state of the world is likely to be given that a speaker produced some utterance, knowing that the speaker is reasoning about how a listener is most likely to interpret that utterance. Thus, we have (at least) three levels of inference. At the top, the sophisticated, **pragmatic listener**, $$L_{1}$$, reasons about the **pragmatic speaker**, $$S_{1}$$, and infers the state of the world $$s$$ given that the speaker chose to produce the utterance $$u$$. The speaker chooses $$u$$ by maximizing the probability that a naive, **literal listener**, $$L_{0}$$, would correctly infer the state of the world $$s$$ given the literal meaning of $$u$$.

At the base of this reasoning, the naive, literal listener $$L_{0}$$ interprets an utterance according to its meaning. That is, $$L_{0}$$ computes the probability of $$s$$ given $$u$$ according to the semantics of $$u$$ and the prior probability of $$s$$. A standard view of the semantic content of an utterance suffices: a mapping from states of the world to truth values.

<!-- <center>The literal listener: P<sub>L<sub>0</sub></sub>(s|u) ∝ ⟦u⟧(s) · P(s)</center> -->

$$P_{L_{0}}(s\mid u) \propto [\![u]\!](s) \cdot P(s)$$

<!-- \mid -->

~~~~
// possible objects of reference
var objectPrior = function() {
  uniformDraw([
    {shape: "square", color: "blue"},
    {shape: "circle", color: "blue"},
    {shape: "square", color: "green"}
  ])
}

// possible one-word utterances
var utterances = ["blue","green","square","circle"]

// meaning function to interpret the utterances
var meaning = function(utterance, obj){
  (utterance === "blue" || utterance === "green") ? utterance === obj.color :
  (utterance === "circle" || utterance === "square") ? utterance === obj.shape :
  true
}

// literal listener
var literalListener = function(utterance){
  Infer({model: function(){
    var obj = objectPrior();
    var uttTruthVal = meaning(utterance, obj);
    condition(uttTruthVal == true)
    return obj
  }})
}

viz.table(literalListener("blue"))

~~~~

> **Exercises:**

> 1. Check what happens with the other utterances.
> 2. In the model above, `objectPrior()` returns a sample from a `uniformDraw` over the possible objects of reference. What happens when the listener's beliefs are not uniform over the possible objects of reference (e.g., the "green square" is very salient)? (Hint: use a `categorical` distribution by calling `categorical({ps: [list_of_probabilities], vs: [list_of_states]})`).

Fantastic! We now have a way of integrating a listener's prior beliefs about the world with the truth functional meaning of an utterance.

What about speakers? Speech acts are actions; thus, the speaker is modeled as a rational (Bayesian) actor. He chooses an action (e.g., an utterance) according to its utility. The speaker simulates taking an action, evaluates its utility, and chooses actions in proportion to their utility. This is called a *softmax* optimal agent; a fully optimal agent would choose the action with the highest utility all of the time. (This kind of model is called *action as inverse planning*; for more on this, see [agentmodels.org](http://agentmodels.org/chapters/3-agents-as-programs.html).)

In the code box below you'll see a generic softmax agent model. Note that in this model, `agent` uses `factor` (not `condition`). `factor` is a continuous (or, softer) version of `condition` that takes real numbers as arguments (instead of binary truth values). Higher numbers (here, utilities) upweight the probabilities of the actions associated with them.

~~~~
// define possible actions
var actions = ['a1', 'a2', 'a3'];

// define some utilities for the actions
var utility = function(action){
  var table = {
    a1: -1,
    a2: 6,
    a3: 8
  };
  return table[action];
};

// define actor optimality
var optimality = 1

// define a rational agent who chooses actions
// according to their expected utility
var agent = Infer({ model: function(){
    var action = uniformDraw(actions);
    factor(optimality * utility(action));
    return action;
}});

print("the probability that an agent will take various actions:")
viz(agent);

~~~~

> **Exercises:**

> 1. Explore what happens when you change the agent's optimality.
> 2. Explore what happens when you change the utilities.

In language understanding, the utility of an utterance is how well it communicates the state of the world $$s$$ to a listener. So, the speaker $$S_{1}$$ chooses utterances $$u$$ to communicate the state $$s$$ to the hypothesized literal listener $$L_{0}$$. Another way to think about this: $$S_{1}$$ wants to minimize the effort $$L_{0}$$ would need to arrive at $$s$$ from $$u$$, all while being efficient at communicating. $$S_{1}$$ thus seeks to minimize the surprisal of $$s$$ given $$u$$ for the literal listener $$L_{0}$$, while bearing in mind the utterance cost, $$C(u)$$. (This trade-off between efficacy and efficiency is not trivial: speakers could always use minimal ambiguity, but unambiguous utterances tend toward the unwieldy, and, very often, unnecessary. We will see this tension play out later in the course.)

Speakers act in accordance with the speaker’s utility function $$U_{S_{1}}$$: utterances are more useful at communicating about some state as surprisal and utterance cost decrease.

$$U_{S_{1}}(u; s) = log(L_{0}(s\mid u)) - C(u)$$

(In WebPPL, $$log(L_{0}(s\mid u))$$ can be accessed via `literalListener(u).score(s)`.)

With this utility function in mind, $$S_{1}$$ computes the probability of an utterance $$u$$ given some state $$s$$ in proportion to the speaker’s utility function $$U_{S_{1}}$$. The term $$\alpha > 0$$ controls the speaker’s optimality, that is, the speaker’s rationality in choosing utterances.

<!-- <center>The pragmatic speaker: P<sub>S<sub>1</sub></sub>(u|s) ∝ exp(αU<sub>S<sub>1</sub></sub>(u;s))</center> -->

$$P_{S_{1}}(u\mid s) \propto exp(\alpha U_{S_{1}}(u; s))$$

~~~~
// pragmatic speaker
var speaker = function(obj){
  Infer({model: function(){
    var utterance = utterancePrior();
    factor(alpha * literalListener(utterance).score(obj))
    return utterance
  }})
}
~~~~

> **Exercise:** Check the speaker's behavior for a blue square. (Hint: you'll need to add a few pieces to the model, for example the `literalListener()` and all its dependencies. You'll also need to define the `utterancePrior()`---try using a `uniformDraw()` over the possible `utterances`. Finally, you'll need to define the speaker optimality `alpha`---try setting `alpha` to 1.)

We now have a model of the generative process of an utterance. With this in hand, we can imagine a listener who thinks about this kind of speaker.

The pragmatic listener $$L_{1}$$ computes the probability of a state $$s$$ given some utterance $$u$$. By reasoning about the speaker $$S_{1}$$, this probability is proportional to the probability that $$S_{1}$$ would choose to utter $$u$$ to communicate about the state $$s$$, together with the prior probability of $$s$$ itself. In other words, to interpret an utterance, the pragmatic listener considers the process that *generated* the utterance in the first place. (Note that the listener model uses `observe`, which functions like `factor` with $$\alpha$$ set to $$1$$.)

<!-- <center>The pragmatic listener: P<sub>L<sub>1</sub></sub>(s|u) ∝ P<sub>S<sub>1</sub></sub>(u|s) · P(s)</center> -->

$$P_{L_{1}}(s\mid u) \propto P_{S_{1}}(u\mid s) \cdot P(s)$$

~~~~ 
// pragmatic listener
var pragmaticListener = function(utterance){
  Infer({model: function(){
    var obj = objectPrior();
    observe(speaker(obj), utterance)
    return obj
  }})
}
~~~~

Within the RSA framework, communication is thus modeled as in Fig. 1, where $$L_{1}$$ reasons about $$S_{1}$$’s reasoning about a hypothetical $$L_{0}$$.

<img src="../images/rsa_schema.png" alt="Fig. 1: Graphical representation of the Bayesian RSA model." style="width: 400px;"/>
<center>Fig. 1: Bayesian RSA schema.</center>




#### Application: Simple referential communication

In its initial formulation, reft:frankgoodman2012 use the basic RSA framework to model referent choice in efficient communication. To see the mechanism at work, imagine a referential communication game with three objects, as in Fig. 2.

<img src="../images/rsa_scene.png" alt="Fig. 2: Example referential communication scenario from Frank & Goodman (2012). Speakers choose a single word, $$u$$, to signal an object, $$s$$." style="width: 400px;"/>
<center>Fig. 2: Example referential communication scenario from Frank and Goodman. Speakers choose a single word, <i>u</i>, to signal an object, <i>s</i>.</center>

Suppose a speaker wants to signal an object, but only has a single word with which to do so. Applying the RSA model schematized in Fig. 1 to the communication scenario in Fig. 2, the speaker $$S_{1}$$ chooses a word $$u$$ to best signal an object $$s$$ to a literal listener $$L_{0}$$, who interprets $$u$$ in proportion to the prior probability of naming objects in the scenario (i.e., to an object’s salience, $$P(s)$$). The pragmatic listener $$L_{1}$$ reasons about the speaker’s reasoning, and interprets $$u$$ accordingly. By formalizing the contributions of salience and efficiency, the RSA framework provides an information-theoretic definition of informativeness in pragmatic inference. <!-- This definition will prove crucial in understanding the contribution of contextual pre- dictability of collective properties in the interpretation of plural predication. -->

~~~~
// Here is the code from the Frank and Goodman RSA model

// possible objects of reference
var objectPrior = function() {
  uniformDraw([
    {shape: "square", color: "blue"},
    {shape: "circle", color: "blue"},
    {shape: "square", color: "green"}
  ])
}

// possible one-word utterances
var utterances = ["blue","green","square","circle"]

// meaning function to interpret the utterances
var meaning = function(utterance, obj){
  (utterance === "blue" || utterance === "green") ? utterance === obj.color :
  (utterance === "circle" || utterance === "square") ? utterance === obj.shape :
  true
}

// literal listener
var literalListener = function(utterance){
  Infer({model: function(){
    var obj = objectPrior();
    condition(meaning(utterance, obj))
    return obj
  }})
}

// set speaker optimality
var alpha = 1

// pragmatic speaker
var speaker = function(obj){
  Infer({model: function(){
    var utterance = uniformDraw(utterances)
    factor(alpha * literalListener(utterance).score(obj))
    return utterance
  }})
}

// pragmatic listener
var pragmaticListener = function(utterance){
  Infer({model: function(){
    var obj = objectPrior()
    observe(speaker(obj),utterance)
    return obj
  }})
}

print("literal listener's interpretation of 'blue':")
viz.table(literalListener( "blue"))
print("speaker's utterance distribution for a blue circle:")
viz.table(speaker({shape:"circle", color: "blue"}))
print("pragmatic listener's interpretation of 'blue':")
viz.table(pragmaticListener("blue"))

~~~~

> **Exercises:**

> 1. Explore what happens if you make the speaker *more* optimal.
> 2. Add another object to the scenario.
> 3. Add a new multi-word utterance.
> 4. Check the behavior of the other possible utterances.



In the [next chapter](02-pragmatics.html), we'll see how RSA models have been developed to model more complex aspects of pragmatic reasoning and language understanding.