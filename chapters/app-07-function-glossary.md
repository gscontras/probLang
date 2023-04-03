---
layout: appendix
title: Glossary
description: "WebPPL functions used in this book"
---

- `==` (`===`): takes two arguments and determines whether they are identical

~~~~
var arg1 = "x"
var arg2 = "z"
arg1 == arg2
~~~~

- `_.includes()`: takes two arguments and determines whether the first contains the second

~~~~
var arg1 = "my name is Greg"
var arg2 = "Greg"
_.includes(arg1,arg2) 
~~~~

- `categorical`: takes either a single options argument with values specified for `ps` (i.e., a list of probabilities) and `vs` (i.e., a list of variables), or two lists (the first a list of probabilities, the second a list of variables); returns a sample from a categorical distribution. Note: `categorical` will renormalize a list of numbers into a list of probabilities

~~~~
categorical({ps:[1,2,3],vs:["a","b","c"]})

//categorical([1,2,3],["a","b","c"])
~~~~


- `map`
- `map2`
- `uniformDraw`
- `print`, `display`
- `condition`, `factor`, `observe`
- `Math.log`
- `binom`
- `Math.min`
- `Math.exp`
- `_.isNaN`
- `_.range`
- `binomial`
- `marginalize`
- `JSON.stringify`
- `Math.round`
- `marginalize`
- `viz.marginals`
- `.concat`
- `uniform`
- `object["string"]` and `object.string` syntax
- `x ? y : z` syntax


