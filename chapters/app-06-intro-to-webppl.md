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

> New to functional programming or JavaScript? We will explain some of the constructs as they come up in WebPPL. For a slightly more substantial introduction, try this [short introduction to the deterministic parts of the language](http://probmods.org/chapters/appendix-js-basics.html).

The probabilistic aspects of WebPPL come from: [distributions](http://webppl.readthedocs.io/en/dev/distributions.html) and [sampling](http://webppl.readthedocs.io/en/dev/sample.html),
marginal [inference](http://webppl.readthedocs.io/en/dev/inference/index.html),
and [factors](http://webppl.readthedocs.io/en/dev/inference/index.html#factor).

> **Probabilistic model**: A mathematical mapping from a set of latent (unobservable) variables to a *probability distribution* of observable outcomes or data. A **probability distribution** is simply a mathematical mapping between outcomes and their associated probability of occurrence.

### Some restrictions

Being a probabilistic programming language, WebPPL is more restrictive than JavaScript. Variables can be defined, but (unlike in JavaScript) their values cannot be redefined. For example, the following does not work:

~~~~
var a = 0;
a = 1; // won't work
// var a = 1 // will work

var b = {x: 0};
b.x = 1; // won't work
// var b = {x: 1} // will work
~~~~

This also means looping constructs (such as `for`) are not available; we use functional programming constructs instead (like `map`, to be explained below) to operate on [arrays](http://webppl.readthedocs.io/en/dev/functions/arrays.html).
(Note that [tensors](http://webppl.readthedocs.io/en/dev/functions/tensors.html) are not arrays.)

### Building stochastic sampling functions

A function is a procedure that returns a value.
Functions (often) take as input some number of arguments.
You can define new functions in WebPPL, just as you would in JavaScript.

~~~~
var myNewFunction = function(args){
    return args[0] + args[1]
}
myNewFunction([2, 3])
~~~~

Above, `args` is the argument to the function `myNewFunction`; based on the body (content) of `myNewFunction`, `args` should be a list.
What the function `myNewFunction` does is add the 0th element of the list to the 1st element of the list (WebPPL is 0-indexed).

> **Exercise:**
> Try running `myNewFunction([2, 3, 5])`.
> What happens?

The above function is deterministic.
It returns the same outcome every time it is called for the same input.
To unfold the power of probabilistic programming, we also consider stochastic sampling functions.
Sampling functions, like other functions, take in some number of arguments (often, the parameters of a probability distribution), do some (probabilistic) computation, and return the output.
In their most basic form, sampling functions return a random value drawn from a known probability distribution.

~~~~
flip(0.6)
~~~~

`flip` is a function: it takes an argument and returns a value.
What makes `flip` special is that doesn't return the same value every time you run it, even with the same arguments: It is a probabilistic function.

> **Exericise:**
> Try running the code box above multiple times to see this.

`flip` essentially flips a coin whose probability of landing on heads is given by the parameter value (above: `0.6`).
(You can treat the value of `true` as "heads" and `false` as "tails").

By chaining various sampling functions together we can create more complex sampling functions. Here is a minimally more complex example:

~~~~
var two_coins = function(){
  var c1 = flip(0.5);
  var c2 = flip(0.5);
  return c1 + c2; // adding Booleans coerces them to integers
}
// sample outcome of two coin flips (added together)
two_coins()
~~~~

#### Built-in sampling functions

`flip()` is a the simplest stochastic sampling function, but there are many more in WebPPL.
Check out the [WebPPL documentation](https://webppl.readthedocs.io/en/master/distributions.html) on the available distributions.

~~~~
// returns a single sample from a standard normal
gaussian({mu: 0, sigma: 1})
~~~~

Notice that the sampling functions of built-in probability distributions all start with a lower-case letter (see below for explanation of *distribution objects* which are instantiated by using a capital letter).


#### Higher-order functions: Munging randomness

*Higher-order functions*, i.e., functions that take other functions as arguments, are a key component of functional programming languages; they allow you chain functions or to repeat a computation (e.g., like you would want to do with a for-loop).
Two very useful higher-order functions are `repeat` and `map`.

~~~~
repeat(10, flip)
~~~~

`repeat()` has two arguments: a number `10` and a function `flip`.
It returns the outcome of repeating `n`(here, 10) calls to function (flipping a coin).
Notice that the function `flip` is being referred to by its name; the function `flip` is not being called (which you would achieve with: `flip()`) before it is passed to `repeat`.

> **Exercise**: 
> Try repeating `flip(0.6)`. What needs to change from the original code box? (Hint: `repeat()` wants to take a function as an argument. You can define new functions using the `function(arguments){body}` construction, as in `var newFn = function(){...}`` `)

Sometimes, we want to repeat a function but with different arguments. For this, we need `map`. Here is an example of flipping five coins, each with a different bias:

~~~~
var weights = [0.1, 0.3, 0.5, 0.7, 0.9]
map(function(w){ flip(w) }, weights)
~~~~

`map` takes two arguments: a function and a list. `map` returns a list, which is the result of running the function over each element of the list.
If you are uncertain about the arguments to `repeat()`, `map()`, or other WebPPL functions, pop over to the [WebPPL docs](http://docs.webppl.org/en/master/functions/arrays.html#repeat) to get it all straight.

#### A brief aside for visualization

WebPPL (as accessed in the browser) provides basic visualization tools.
WebPPL-viz has a lot of functionality, the documentation for which can be found [here](https://github.com/probmods/webppl-viz).
The coolest thing about WebPPL-viz is the default `viz()` function, which will take whatever you pass it and try to construct a reasonable visualization automatically.
(This used to be called `viz.magic()`).

~~~~
// visualize the output of this higher-order function call
repeat(10, flip)
~~~~

> **Exercises:**
> 1. Try calling `viz()` on the output of the `repeat` code box above.
> 2. Run the code box several times. Does the output surprise you?
> 3. Try repeating the flip 1000 times, and run the code box several times. What has changed? Why?


#### Recursive functions

A recursive function is one that encodes a procedure in which the same function is called.
It is easy to get stuck in an infinite regress with recursive function, so it's often important to define a base case.

~~~~
var firstEven = function(lst){
  if ((first(lst) % 2) == 0) {
    return first(lst)
  } else {
    return firstEven(rest(lst))
  }
}
firstEven([1,3,2,4])
~~~~

`firstEven` takes in a list, checks to see if the first element is even, and returns that value if it is even, but otherwise calls itself using the rest of the list (everything except the first element) as the argument.


#### Challenge problem

We can also use recursive functions to build interesting stochastic functions.

~~~~
var geometricCoin = function(){
  ...
}

~~~~

> **Exercises:**
> 1. Make a function (`geometricCoin`) that flips a coin (of whatever weight you'd like). If it comes up heads, you call that same function (`geometricCoin`) and add 1 to the result. If it comes up tails, you return the number 1.
> 2. Pass that function to repeat, repeat it many times, and create a picture using `viz()`


### Distributions

So far, we looked at *sampling functions*, which produce single samples from probability distributions, e.g., the outcomes of randomly flipping coins (of a certain weight).
The probability distributions were *implicit* in those sampling functions; they specified the probability of the different return values (`true` or `false`).
When you repeatedly run the sampling function more and more times (for example: with `repeat`), you approximate the underlying true distribution better and better.

WebPPL also represents probability distributions *explicitly*.
We call these explicit probability distributions: **distribution objects**.
Syntactically, this is denoted using a capitalized versions of the sampler functions.

~~~~
// bernoulli(0.6) // same as flip(0.6); returns a single sample
var myDist = Bernoulli( { p: 0.6 } ) // create distribution object
viz( myDist )  // plot the distribution
~~~~

(Note: `flip()` is a cute way of referring to a sample from the `bernoulli()` distribution.)

> **Exercise**: 
> Try running the above box many times. Does it change? Why not?

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

> **Exercise**: Line by line, describe what is happening in the above code box.

### Properties of distribution objects

We just saw how you can call `sample()` on a distribution, and it returns a value from that distribution (the value is sampled according to the its probability).
Distribution objects have two other properties that will be useful for us.
We get a glimpse at how WebPPL represents probability distributions as first-order objects when we use the method `print`. (This example also show the difference between the brute `print()` and the elegant `display()`.)

~~~~
var myDist = Bernoulli( { p: 0.6 } ) // create distribution object
display( myDist )  // show high-level representation
print( myDist )  // show true underlying representation 
// (to see the last output you may have to run the code box twice (a glitch in "print"))
~~~~

(Notice: using `print` only works for discrete probability distributions (with finite support).)

We see that distribution objects are internally represented as a set of elements (the support) and the probability, or score (see below), of each element in the support.

Sometimes, we want to know what possible values could be sampled from a distribution.
This is called the **support** of a distribution and it can be accessed by calling `myDist.support()`, where `myDist` is some distribution object.

~~~~
var myDist = Bernoulli( { p: 0.6 } ) // create distribution object
myDist.support() // the support of the distribution 
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

> **Exercises:**
> 1. Try changing the parameter value of the Bernoulli distribution in the first code chunk (for the support). Does the result change? Why or why not?
> 2. Try changing the parameter value of the Bernoulli distribution in the second code chunk (for the score). Does the result change? Why or why not?
> 3. Modify the second code chunk to return the probability of `true` (rather than the log-probability). What is the relation between the probability of `true` and the parameter to the Bernoulli distribution?


## Bayesian Inference in WebPPL

#### Warm-up: Constructing distributions with Infer

Sampling functions and explicit representations of probability distributions are the basic building blocks of a probabilistic programs.
These constructs can be thought of as ways of generating data. For example, if you wanted to generate a sequence of flips of a coin, you could use `repeat(15, flip)`, like we saw above.

~~~~
repeat(15, flip)
~~~~

When you run the code-box above, the program returns to you one sample: a sample from the probability distribution defined by the program (a sequence of 15 flips).
What if we wanted more samples, to better understand the distribution? For example, how probable is it to get 14 heads in a series of 15 flips?
We could wrap the above code into a function, and call `repeat` on that.

~~~~
var repeat15flips = function(){ repeat(15, flip) }
repeat(3, repeat15flips)
~~~~

As you might imagine, it's going to be hard to get any intuition for this distribution by looking at many samples, because each sample is a list.
But we may not need to keep around the whole list for each sample. 
If we want to know how probable it is to get 14 heads in a series of 15 flips, then all we need to keep around from each sample is the number of heads (rather than the full sequence).
To get the number of heads, we can call `sum()` on the list of boolean values returned by `repeat15flips`.

~~~~
var sumRepeat15flips = function(){ sum(repeat(15, flip)) }
repeat(3, sumRepeat15flips)
~~~~

> **Exercise:**
> Try running 1000 samples, and wrap the output in a `viz``.

Presently, the data which results from the `repeat` function call is represented as a list, but the procedure implicitly defines a probability distribution.
We can reify the sampling function into a probability distribution using the built-in function `Infer()`.

~~~~
var sumRepeat15flips = function(){ sum(repeat(15, flip)) }
Infer(sumRepeat15flips)
~~~~

Turning the sampling function into a probability distribution has the advantage of being able to access properties of the distribution (like the score, support, and sampling; as described above). 
Think of `Infer` as a constructor, which takes as input a sampling function (no matter how complex) and returns a distribution object. 
In this way, probabilistic programming languages can powerfully create distributions comprised of distributions in a fully generative way.

> **Exercise:**: 
> Using the newly constructed distribution object from `Infer`, compute the probability of getting 14 heads from a series of 15 flips.

#### Bayesian inference

In science and life, we are often not interested in the question of how probable some data is but rather in the question of how probable a certain *hypothesis* may be given some data we have observed.
For example, imagine that you observe 14 heads from a series of 15 flips of a coin, but you're actually uncertain about the weight of the coin (i.e., you have reason to believe the coin may be biased towards landing on heads or tails, but you don't know which one and you don't know how biased it may be).
Given the observed data (14 heads out of 15 flips), you can use Bayesian inference to make judgment about the likely weight of the coin.

To do this in a WebPPL program, we need to make two changes to the code above: We need to specify the **prior distribution** over the parameters (in this case, the prior distribution over coin weights) and we need to tell WebPPL about the data we observed, e.g., using the `observe` function.

~~~~
var model = function(){
  var coin_weight = uniform(0, 1)
  var sumRepeat15flips = function(){ sum(repeat(15, function() {flip(coin_weight)})) }
  var myDist = Infer(sumRepeat15flips)
  observe(myDist, 14)
  return coin_weight
}
Infer(model)
~~~~

Unfortunately, this will take a very long time to run.
Instead, we'll take advantage of the fact that `Infer(sumRepeat15flips)` is a known probability distribution. It is the Binomial distribution.

~~~~
var model = function(){
  var coin_weight = uniform(0, 1)
  // var sumRepeat15flips = function(){ sum(repeat(15, flip)) }
  // observe(Infer(sumRepeat15flips), 14)
  observe(Binomial({n: 15, p: coin_weight}), 14)
  return coin_weight
}
Infer(model)
~~~~

#### Observe, condition, and factor: distilled

The helper functions `condition()`, `observe()`, and `factor()` all have the same underlying purpose: Changing the probability of different program executions. For Bayesian data analysis, we want to do this in a way that computes the posterior distribution.

Imagine running a model function a single time.
In some lines of the model code, the program makes *random choices* (e.g., flipping a coin and it landing on heads, or tails).
The collection of all the random choices in an execution of every line of a program is referred to as the *program execution*.

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
