---
layout: appendix
title: Introduction to WebPPL
description: "A brief introduction."
---

<!-- Yes, these chapters would be great. Maybe putting the most crucial basics of JS into the book as well? And maybe a shorter, more streamlined example of Bayesian conditioning than what is now in the second linked chapter? There is an example already in appendix chap 1 if that can be recycled, maybe?
I can also put hand to this, in about a week or two.
Cheers, m. -->

WebPPL is a probabilistic programming language based on Javascript. WebPPL can be used most easily through [webppl.org](http://webppl.org). It can also be [installed locally](http://webppl.readthedocs.io/en/dev/installation.html) and run from the [command line](http://webppl.readthedocs.io/en/dev/usage.html).

The deterministic part of WebPPL is a [subset of Javascript](http://dippl.org/chapters/02-webppl.html).

> New to functional programming or JavaScript? We will explain some of the constructs as they come up in WebPPL. For a slightly more substantial introduction, try this [short introduction to the deterministic parts of the language](http://probmods.org/chapters/13-appendix-js-basics.html).

The probabilistic aspects of WebPPL come from: [distributions](http://webppl.readthedocs.io/en/dev/distributions.html) and [sampling](http://webppl.readthedocs.io/en/dev/sample.html),
marginal [inference](http://webppl.readthedocs.io/en/dev/inference/index.html),
and [factors](http://webppl.readthedocs.io/en/dev/inference/index.html#factor).

> **Probabilistic model**: A mathematical mapping from a set of latent (unobservable) variables to a *probability distribution* of observable outcomes or data. A **probability distribution** is simply a mathematical mapping between outcomes and their associated probability of occurrence.

### Sampling with functions

Functions are procedures that return a value.
They (often) take as input some number of arguments, do some computation, and return an output.
You can define new functions in WebPPL, just as you would in JavaScript.

~~~~
var myNewFunction = function(args){
    return args[0] + args[1]
}
myNewFunction([2, 3])
~~~~

Above, `args` is the argument to the function `myNewFunction`; based on the body (content) of `myNewFunction`, `args` should be a list.
What the function `myNewFunction` does is add the 0th element of the list to the 1st element of the list (WebPPL is 0-indexed).
Try running `myNewFunction([2, 3, 5])`.
What happens?

The basic building block of probabilistic programs is *random primitives*.
Random primitives can be accessed with *sampling functions*.
Sampling functions, like other functions, take in some number of arguments (often, the parameters of a probability distribution), do some (probabilistic) computation, and return the output.
In their most basic form, sampling functions return a random value drawn from a known probability distribution.

~~~~
flip(0.6)
~~~~

`flip` is a function: it takes an argument and returns a value.
What makes `flip` special is that doesn't return the same value every time you run it, even with the same arguments: It is a probabilistic function.
Try running the code box above multiple times to see this.
`flip` essentially flips a coin whose probability of landing on heads is given by the parameter value (above: `0.6`).
(You can treat the value of `true` as "heads" and `false` as "tails").

#### Higher-order functions: Munging randomness

*Higher-order functions* are a key component of functional programming languages; they allow you to repeat computation (e.g., like you would want to do with a for-loop).
Two very useful higher-order functions are `repeat` and `map`.

~~~~
repeat(10, flip)
~~~~

`repeat()` has two arguments: a number `10` and a function `flip`.
It returns the outcome of repeating `n`(here, 10) calls to function (flipping a coin).
Notice that the function `flip` is being referred to by its name; the function `flip` is not being called (which you would achieve with: `flip()`) before it is passed to `repeat`.

**Exercise**: Try repeating `flip(0.6)`. What needs to change from the original code box? (Hint: `repeat()` wants to take a function as an argument. You can define new functions using the `function(arguments){body}` construction, as in `var newFn = function(){...}`` `)

Sometimes, we want to repeat a function but with different arguments. For this, we need `map`

~~~~
var weights = [0.1, 0.3, 0.5, 0.7, 0.9]
map(function(w){ w * 2 }, weights)
~~~~

`map` takes two arguments: a function and a list. `map` returns a list, which is the result of running the function over each element of the list.
If you are uncertain about the arguments to `repeat()`, `map()`, or other WebPPL functions, pop over to the [WebPPL docs](http://docs.webppl.org/en/master/functions/arrays.html#repeat) to get it all straight.

#### A brief aside for visualization

WebPPL (as accessed in the browser) provides basic visualization tools.
WebPPL-viz has a lot of functionality, the documentation for which can be found [here](https://github.com/probmods/webppl-viz).
The coolest thing about WebPPL-viz is the default `viz()` function, which will take whatever you pass it and try to construct a reasonable visualization automatically.
(This used to be called `viz.magic()`).

**Exercises:**

1. Try calling `viz()` on the output of the `repeat` code box above.
2. Run the code box several times. Does the output surprise you?
3. Try repeating the flip 1000 times, and run the code box several times. What has changed? Why?

### Distributions

Above, we looked at *samples* from probability distributions: the outcomes of randomly flipping coins (of a certain weight).
The probability distributions were *implicit* in those sampling functions; they specified the probability of the different return values (`true` or `false`).
When you repeatedly run the sampling function more and more times (for example: with `repeat`), you to approximate the underlying true distribution better and better.

WebPPL also represents probability distributions *explicitly*.
We call these explicit probability distributions: **distribution objects**.
Syntactically, this is denoted using a capitalized versions of the sampler functions.

~~~~
// bernoulli(0.6) // same as flip(0.6)
viz(Bernoulli( { p: 0.6 } ) )
~~~~

(Note: `flip()` is a cute way of referring to a sample from the `bernoulli()` distribution.)

**Exercise**: Try running the above box many times. Does it change? Why not?

Distributions have parameters. (And different distributions have different parameters.)
For example, the Bernoulli distribution has a single parameter.
In WebPPL, it is called `p` and refers to the probability of the coin landing on heads.
[Click here](http://docs.webppl.org/en/master/distributions.html) for a complete list of distributions and their parameters in WebPPL.
We can call the distributions by passing them objects with the parameter name(s) as keys and parameter value(s) as values (e.g., `{p: 0.6}`).
When a distribution is explicitly constructed, it can be sampled from by calling `sample()` on that distribution.

~~~~
var parameters = {p: 0.9}
var myDist = Bernoulli(parameters)
sample(myDist)
~~~~

**Exercise**: Line by line, describe what is happening in the above code box.

### Properties of distribution objects

We just saw how you can call `sample()` on a distribution, and it returns a value from that distribution (the value is sampled according to the its probability).
Distribution objects have two other properties that will be useful for us.

Sometimes, we want to know what possible values could be sampled from a distribution.
This is called the **support** of a distribution and it can be accessed by calling `myDist.support()`, where `myDist` is some distribution object.

~~~~
// the support of the distribution
Bernoulli( { p : 0.9 } ).support()
~~~~

Note that the support of many distributions will be a continuum, like a `Uniform({a, b})` distribution which is defined over the bounds `a` and `b`.

Another common computation relating to probability distributions comes when you have a sample from distribution and want to know how probable it was to get that sample.
This is sometimes called "scoring a sample", and it can be accessed by calling `myDist.score(mySample)`, where `myDist` is a distribution object and `mySample` is a value.
Note that for the score of sample to be defined; that is, the sample must be an element of the support of the distribution.
WebPPL returns not the probability of `mySample` under the distribution `myDist`, but the natural logarithm of the probability, or the log-probability.
To recover the probability, use the javascript function `Math.exp()`.


~~~~
// the log-probability of true (e.g., "heads")
Bernoulli( { p : 0.9 } ).score(true)
~~~~


**Exercises:**

1. Try changing the parameter value of the Bernoulli distribution in the first code chunk (for the support). Does the result change? Why or why not?
2. Try changing the parameter value of the Bernoulli distribution in the second code chunk (for the score). Does the result change? Why or why not?
3. Modify the second code chunk to return the probability of `true` (rather than the log-probability). What is the relation between the probability of `true` and the parameter to the Bernoulli distribution?


### Some restrictions

Variables can be defined, but (unlike in JavaScript) their values cannot be redefined. For example, the following does not work:

~~~~
var a = 0;
a = 1; // won't work
// var a = 1 // will work

var b = {x: 0};
b.x = 1; // won't work
// var b = {x: 1} // will work
~~~~

This also means looping constructs (such as `for`) are not available; we use functional programming constructs (like `map`) instead to operate on [arrays](http://webppl.readthedocs.io/en/dev/functions/arrays.html).
(Note that [tensors](http://webppl.readthedocs.io/en/dev/functions/tensors.html) are not arrays.)



## Challenge problem

~~~~
var geometricCoin = function(){
  ...
}

~~~~

**Exercises:**

1. Make a function (`geometricCoin`) that flips a coin (of whatever weight you'd like). If it comes up heads, you call that same function (`geometricCoin`) and add 1 to the result. If it comes up tails, you return the number 1.
2. Pass that function to repeat, repeat it many times, and create a picture using `viz()`

## Bayesian Inference in WebPPL

#### Learning about parameters from data

Having specified our *a priori* state of knowledge about the parameter of interest, and the generative process of the data given a particular value of the parameter, we are ready to make inferences about the likely value of the parameter given our observed data.
We do this via *Bayesian inference*, the mathematically correct way of reasoning about the underlying probability that generated our data.

So we run the experiment, and 15 out of 20 kids performed the helping behavior.
Thus, `numberOfHelpfulResponses == 15`.
How can we tell our model about this?

~~~~ norun
var sampleAndObserve = function(){
  var propensityToHelp = sample(PriorDistribution)
  var numberOfHelpfulResponses = binomial({
    p: propensityToHelp,
    n: numberOfKidsTested
  })
  var matchesOurData = (numberOfHelpfulResponses == 15)
  return ...
}
~~~~

What should we return?
We could return `matchesOurData`.
If we repeat this function many times, we will estimate how many `propensityToHelp`s under our prior (i.e., between 0 - 1) give rise to our observed data.
This is called the **likelihood of the data**, but is not immediately interpretable in isolation (though we will see it later in this course).

What if we returned `propensityToHelp`?
Well, that will just give us the same prior that we saw above, because there is no relationship in the program between `matchesOurData` and `propensityToHelp`.

What if we returned `propensityToHelp`, but only if `matchesOurData` is `true`?
In principle, any value `propensityToHelp` *could* give rise to our data, but intuitively some values are more likely to than others (e.g., a `propensityToHelp` = 0.2, would produce 15 out of 20 successes with probability proportional to $$0.2^{15} + 0.8^5$$, which is not as likely as a `propensityToHelp` = 0.8 would have in producing 15 out of 20 success).

It turns out, if you repeat that procedure many times, then the values that survive this "rejection" procedure, survive it in proportion to the actual *a posteriori* probability of those values given the observed data.
It is a mathematical manifestation of the quotation from Arthur Conan Doyle's *Sherlock Holmes*: "Once you eliminate the impossible, whatever remains, no matter how improbable, must be the truth."
Thus, we eliminate the impossible (and, implicitly, we penalize the improbable), and what we are left with is a distribution that reflects our state of knowledge after having observed the data we collected.


We'll use the `editor.put()` function to save our results so we can look at the them in different code boxes.

~~~~
var PriorDistribution = Uniform({a:0, b:1});
var numberOfKidsTested = 20;

var sampleAndObserve = function(){
  var propensityToHelp = sample(PriorDistribution)
  var numberOfHelpfulResponses = binomial({
    p: propensityToHelp,
    n: numberOfKidsTested
  })
  var matchesOurData = (numberOfHelpfulResponses == 15)
  return matchesOurData ? propensityToHelp : "reject"
}

var exampleOutput = repeat(10, sampleAndObserve)

display("___example output from function___")
display(exampleOutput)

// remove all the rejects
var posteriorSamples = filter(
  function(s){return s != "reject" },
  repeat(100000, sampleAndObserve)
)

// save results in browser cache to access them later
editor.put("posteriorSamples", posteriorSamples)

viz(posteriorSamples)
~~~~

Visualized from the code box above is the *posterior distribution* over the parameter `propensityToHelp`.
It represents our state of knowledge about the parameter after having observed the data (15 out of 20 success).

#### The inference algorithm

The procedure we implemented in the above code box is called [Rejection sampling](https://en.wikipedia.org/wiki/Rejection_sampling), and it is the simplest algorithm for [Bayesian inference](https://en.wikipedia.org/wiki/Bayesian_inference).

The algorithm can be written as:

1. Sample a parameter value from the prior (e.g., `p = uniform(0,1)`)
2. Make a prediction (i.e., generate a possible observed data), given that parameter value (e.g., `binomial( {n:20, p: p} )`)
+ If the prediction generates the observed data, record parameter value.
+ If the prediction doesn't generate the observed data, throw away that parameter value.
3. Repeat many times.

Just as we saw in the previous chapter, our ability to represent this distribution depends upon the number of samples we take.
Above, we have chosen to take 100000 samples in order to more accurately represent the posterior distribution.
The number of samples doesn't correspond to anything about our scientific question; it is a feature of the *inference algorithm*, not of our model.
We will describe inference algorithms in more detail in a later chapter.


### Abstracting away from the algorithm with `Infer`


~~~~
var priorDistribution = Uniform({a:0, b:1});
var numberOfKidsTested = 20;
var model = function() {
  var propensityToHelp = sample(priorDistribution)
  var numberOfHelpfulResponses = binomial({
    p: propensityToHelp,
    n: numberOfKidsTested
  })
  condition(numberOfHelpfulResponses == 15) // condition on data
  return { propensityToHelp }
}

var inferArgument = {
  model: model,
  method: "rejection",
  samples: 5000
}

var posteriorDistibution = Infer(inferArgument)

viz(posteriorDistibution)
~~~~


Intuitively, `condition()` here operates the same as the conditional return statement in the code box above this one.
It takes in a boolean value, and throws out the random choices for which that boolean is `false`.
Speaking more generally and technically, `condition()` *re-weights* the probabilities of the *program execution* (which includes all of the *random choices* that have been made up to that point in the program) in a binary way: If it's true, the probability of that program execution gets multiplied by 1 (which has no effect) and if the condition statement is false, the probability of that program execution gets multiplied by 0 (which completely destroys that program execution).

`condition()` is a special case of `factor()`, which directly (and continuously) re-weights the (log) probability of the program execution.
Whereas `condition()` can only take `true` or `false` as arguments, `factor()` takes a number.
The code above can be rewritten using factor in the following way:


~~~~
var priorDistribution = Uniform({a:0, b:1});

var model = function() {
  var propensityToHelp = sample(priorDistribution)
  // reweight based on log-prob of observing 15
  factor(Binomial( {n:20, p: propensityToHelp} ).score(15))
  return { propensityToHelp }
}

var posterior = Infer({model: model, method: "rejection", samples: 1000})
viz(posterior)
~~~~

Re-weighting the log-probabilities of a program execution by the (log) probability of a value under a given distribution, as is shown in the code box above, is true Bayesian updating. Because this updating procedure is so commonly used, it gets its own helper function: `observe()`.

~~~~
var model = function() {
  var propensityToHelp = uniform(0,1) // priors
  observe(Binomial( {n:20, p: propensityToHelp} ), 15) // observe 15 from the Binomial dist
  return { propensityToHelp }
}

var posterior = Infer({model: model, method: "rejection", samples: 1000})
viz(posterior)
~~~~


#### Observe, condition, and factor: distilled

The helper functions `condition()`, `observe()`, and `factor()` all have the same underlying purpose: Changing the probability of different program executions. For Bayesian data analysis, we want to do this in a way that computes the posterior distribution.

Imagine running a model function a single time.
In some lines of the model code, the program makes *random choices* (e.g., flipping a coin and it landing on heads, or tails).
The collection of all the random choices in an execution of every line of a program is referred to as the program execution.

Different random choices may have different (prior) probabilities (or perhaps, you have uninformed priors on all of the parameters, and then they each have equal probability).
What `observe`, `condition`, and `factor` do is change the probabilities of these different random choices.
For Bayesian data analysis, we use these terms to change the probabilities of these random choices to align with the true posterior probabilities.
For BDA, this is usually achived using `observe`.

`factor` is the most primitive of the three, and `observe` and `condition` are both special cases of `factor`.
`factor` directly re-weights the log-probability of program executions, and it takes in a single numerical argument (how much to re-weight the log-probabilities).
`observe` is a special case where you want to re-weight the probabilities by the probability of the observed data under some distribution. `observe` thus takes in two arguments: a distribution and an observed data point.

`condition` is a special case where you want to completely reject or rule out certain program executions.
`condition` takes in a single *boolean* argum

Here is a summary of the three statements.

~~~~ norun
factor(val)
observe(Dist, val) === factor(Dist.score(val))
                   === condition(sample(Dist) == val)
condition(bool) === factor(bool ? 0 : -Infinity)
~~~~
