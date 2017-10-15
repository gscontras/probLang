---
layout: appendix
title: More on speaker utility
description: "Derivation of suprisal-based utilities from KL-divergence"
---

### Appendix chapter 01: More on the speaker's utility function

*Author: Michael Franke*

The main text of [Chapter 1](01-introduction.html) introduced the utility function for the pragmatic speaker as:

$$U_{S_{1}}(u; s) = log(L_{0}(s\mid u)) - C(u)\,.$$

According to this definition, utterance $$u$$ is good for agent $$S_1$$ who knows that the true world state is $$s$$ to the extent that $$u$$ has _low_ costs $$C(u)$$ and to the extent that the literal listener assigns a _high_ probability to $$s$$ after updating with $$u$$. Since the literal listener updates his prior beliefs with the semantic meaning of $$u$$, the latter makes it so that any utterance $$u'$$ which is not true of $$s$$ will receive the lowest possible utility: negative infinitiy. Combined with a softmax-choice rule (on the assumption that for each $$s$$ there is at least one true utterance), this effectively implements Grice's **Maxim of Quality** which requires speakers not to say anything false refp:Grice1975:Logic-and-Conve. (Later chapters will show how this strong Truth-Only Regime can be untied by reasoning about other utility structures, in the form of flexible Questions Under Discussion.) Furthermore, if there are two messages $$u'$$ and $$u$$ both of which are true in $$s$$, then $$u$$ will be preferred over $$u'$$ whenever $$u$$ makes the true world state $$s$$ more likely after literal interpretation. This effectively implements Grice's **Maxim of Quantity** which requires speakers to strive towards maximimization of the (relevant) information conveyed by their utterances.

It is possible to make the relation with other formulations of Gricean Quantity from theoretical linguistics even more clear. If the set of states $$S$$ is finite and the literal listener's prior beliefs are uniform, i.e., if $$P(s) = P(s')$$ for all $$s$$ and $$s'$$, then whenever $$u'$$ and $$u$$ are both true in $$s$$, we get 

$$U_{S_1}(u;s) > U_{S_1}(u';s) \ \ \ \ \text{iff} \ \ \ \ |[\![u]\!]| < |[\![u']\!]| \,.$$ 

In words, the speaker prefers one true message $$u$$ over another true message $$u'$$, all else equal, iff $$u$$ is logically stronger than $$u'$$ (in the sense that $$u$$ rules out more possible states). ($$u$$ and $$u'$$ can still be logically independent; this is not a requirement that $$u$$ ought to imply $$u'$$.)

The above definition of utilities uses information theoretic surprisal to implement a probabilistic version of (something like) a Gricean Quantity Maxim. The surprisal-based notion can also be derived in a different way, which is interesting to look at because it justifies the choice of utility function in more complex models (TODO: insert reference). If the speaker knows the true world state $$s^*$$, she has a degenerate probabilistic belief about world states $$P_{S_1} \in \Delta(S)$$ which assigns probability 1 to the true $$s^*$$ and 0 to any other world state. After an utterance $$u$$, the literal listener also has a probability distribution over world states $$P_{L_0} \in \Delta(S)$$. One way of thinking about what happens in cooperative discourse that maximizes relevant information flow is that the speaker tries to choose utterances $$u$$ such that the listener's beliefs (changed by the utterance) is maximally similar to the belief of the speaker. In other words, speakers choose to say things that assimilate the listener's belief state to their own as much as possible. A notion of divergence between probability distribution is the Kullback-Leibler divergence. A defintion of utility in terms of minimization of KL-divergence derives the original suprisal-based definition, if the speaker's beliefs are degenerate:

$$U_{S_1}(P_{S_1}, P_{L_0}) = - \text{KL}(P_{S_1} \mid P_{L_0} )$$

$$  = - \sum_{s'} P_S(s) \ \log \frac{P_{S_1}(s)}{P_{L_0}(s)}    $$

$$ = - \log\frac{1}{P_{L_0}(s^*)} = \log P_{L_0}(s^*) $$