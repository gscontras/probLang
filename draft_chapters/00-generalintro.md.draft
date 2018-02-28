---
layout: chapter
title: Probabilities & pragmatics
description: "An quick and gentle introduction to probability and pragmatic reasoning"
---

### Chapter 0: Probabilities & pragmatics

##### Probabilistic reasoning

Jones is not a magician or a trickster, so you do not have to fear. He just likes probability puzzles. He shows you his deck of three cards. One is blue on both sides. A second is red on both sides. A third is blue on one and red on the other side. Jones shuffles his deck, draws a random card (without looking), selects a random side of it (without looking) and shows it to you. What you see is a blue side. What do you think the probability is that the other side, which you presently do not see, is blue as well?

Many people believe that the chance that the other side of the card is blue is .5; that there is a 50/50 chance of either color on the back. After all, there are six sides in total, half of which are blue, and since you do not know which side is on the back, the odds are equal for blue and red.

This is faulty reasoning. It just looks at the base rate of sides. It fails to take into account the **observation generating process**, i.e., the way in which Jones manipulates his cards and "generates an observation" for you. For the 3-cards problem, the observation generating process can be visualized as in Fig. 1.

<img src="../images/3-card-problem_process.png" alt="Fig. 1: The observation-generating process for the 3-card problem. Jones selects a random card, then chooses a random side of it" style="width: 400px;"/>
<center>Fig. 1: The observation-generating process for the 3-card problem. Jones selects a random card, then chooses a random side of it.</center>

The process tree in Fig. 1 also shows the probabilities with which events happen at each choice point during the observation-generating process. Each card is selected with equal probability $$\frac{1}{3}$$. The probability of showing a blue side is 1 for the blue-blue card, .5 for the blue-red card, and 0 for the red-red card. The leaves of the tree show the probabilities, obtained by multiplying all probabilities along the branches, of all 6 traversal of the tree (including the logically impossible ones, which naturally receive a probability of 0). 

If we combine our knowledge of the observation-generating process in Fig. 1 with the observation that the side shown was blue, we should eliminate the outcomes that are incompatible with it, as shown in Fig. 2. What remains are the probabilities assigned to branches that are compatible with our observation. But they do not sum to 1. If we therefore renormalize (here: dividing with .5), we end up believing that it is twice as likely for the side which we have not observed to be blue as well. The reason is because the blue-blue card is twice as likely to have generated what we observed than the blue-red card is.


<img src="../images/3-card-problem_elimination.png" alt="Fig. 2: The observation-generating process for the 3-card problem after eliminating outcomes incompatible with the observation 'blue'." style="width: 400px;"/>
<center>Fig. 2: The observation-generating process for the 3-card problem after eliminating outcomes incompatible with the observation "blue".</center>

The latter reasoning is actually an instance of Bayes rule. For our purposes, we can think of Bayes rule as a normatively correct way of forming (subjective) beliefs about which causes have likely generated an observed effect, i.e., a way of reasoning probabilistically and defeasibly about likely explanations for what has happened. In probabilistic pragmatics we will use Bayes rule to capture a listeners attempt of recovering what a speaker may have had in mind when she made a particular utterance. In other words, probabilistic pragmatics treats pragmatic interpretation as probabilistic 
inference to the best explanation of what worldly states of affairs, mental states and contextual factors would have caused the speaker to act in the manner observed.

You should now feel very uncomfortable. Did we not just say that most people fail at probabilistic reasoning tasks like the 3-card problem? (Other prominent examples would be the two-box problem or the [Monty Hall problem](https://en.wikipedia.org/wiki/Monty_Hall_problem).) If the problem with normatively correct probabilistic reasoning in the 3-card problem is a neglect of the precise nature of the observation-generating process, then there is a marked contrast between probability puzzles and natural language understanding. The process by which Jones selects his cards is nowhere near as intimately familiar to us as the utterance-generating process of natural language. We are speakers (samplers, 'observation-generators', ...) ourselves a good deal of the time. It is a hallmark of human language that we experience ourselves in the role of the producer (compare [Hockett's design features of language](https://en.wikipedia.org/wiki/Hockett%27s_design_features), in particular **total feedback**). On this construal, pragmatic interpretation is (in part) a simulation process of what we might have said to express such-and-such in such-and-such contextual conditions.

##### Bayes rule

Let's have a closer look at Bayes rule. The above observation-generating tree contains two types of variables: what type of card is chosen and which side of the chosen card is observed. We can represent this, together with the final branch probabilities also as in the following table:


|                    | observe blue     | observe red  |
|:-------------------|:----------------:|:------------:|
| **blue-blue** card |      1/3         |     0
| **blue-red**  card |       1/6        |    1/6
| **red-red**   card |         0        |     1/3




~~~~

var select_card_and_color = function() {
  // three cards; with blue or red on either side
  var cards = [["blue", "blue"],
               ["blue", "red"],
               ["red", "red"]]
  var card = uniformDraw(cards)
  var side = flip(0.5) ? 0 : 1
  var color = card[side]
  return {color, card}
}
select_card_and_color()

viz.table(Infer({method: "enumerate", 
                 model: function(){
                   var card_and_color = select_card_and_color()
                   condition(card_and_color.color == "red")
                   return(card_and_color.card)}}))
			 
~~~~





In the [next chapter](01-introduction.html), we will see a first full model of probabilistic pragmatic reasoning and its application to the use and interpretation of referential expressions.
