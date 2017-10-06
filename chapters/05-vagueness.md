---
layout: chapter
title: Fixing free parameters
description: "Vagueness"
---

### Chapter 5: Vagueness

Sometimes our words themselves are imprecise, vague, and heavily dependent on context to fix their interpretations. Compositionality assumes semantic atoms with invariant meanings; context-dependent word interpretations pose a serious challenge to compositionality. Take the case of gradable adjectives: "expensive for a sweater" means something quite different from "expensive for a laptop." What, then, do we make of the contribution from the word "expensive"? Semanticists settle on the least common denominator: a threshold semantics by which the adjective asserts that holders of the relevant property surpass some point on the relevant scale (i.e., *expensive* means more expensive than *d* for some contextually-determined degree of price *d*). Whereas semanticists punt on the mechanism by which context fixes these aspects of meaning, the RSA framework is well-suited to meet the challenge.


#### Application 1: Gradable adjectives and vagueness resolution


reft:lassitergoodman2013 propose we parameterize the meaning function for sentences containing gradable adjectives so that their interpretations are underspecified. This interpretation-fixing parameter, the gradable threshold value *theta* (i.e., a degree), is something that conversational participants can use their prior knowledge to actively reason about and set. As with the ambiguity-resolving variable in the previous chapter, *theta* gets lifted to the level of the pragmatic listener, who jointly infers the gradable threshold (e.g., the point at which elements of the relevant domain count as expensive) and the true state (e.g., the indicated element's price). 

The model depends crucially on our prior knowledge of the world state. Let's start with a toy prior for the prices of books.

~~~~
var book = {
  "prices": [2, 6, 10, 14, 18, 22, 26, 30],
  "probabilities": [1, 2, 3, 4, 4, 3, 2, 1]
};

var statePrior = function() {
  return categorical(book.probabilities, book.prices);
};

~~~~

> **Exercise:** Visualize the `statePrior`.   

Next, we create a prior for the degree threshold *theta*. Since we're talking about *expensive* books, *theta* will be the price cutoff to count as expensive. But we want to be able to use *expensive* to describe anything with a price, so we'll set the `thetaPrior` to be uniform over the possible prices in our world.

~~~~
var book = {
  "prices": [2, 6, 10, 14, 18, 22, 26, 30],
  "probabilities": [1, 2, 3, 4, 4, 3, 2, 1]
};

var statePrior = function() {
  return categorical(book.probabilities, book.prices);
};

var thetaPrior = function() {
    return uniformDraw(book.prices);
}

~~~~

> **Exercise:** Visualize the `thetaPrior`.

We introduce two possible utterances: saying that a book is *expensive*, or saying nothing at all. The semantics of the *expensive* utterance checks the relevant item's price against the price cutoff.

~~~~
var book = {
  "prices": [2, 6, 10, 14, 18, 22, 26, 30],
  "probabilities": [1, 2, 3, 4, 4, 3, 2, 1]
};

var statePrior = function() {
  return categorical(book.probabilities, book.prices);
};

var thetaPrior = function() {
    return uniformDraw(book.prices);
};

var utterances = ["expensive", ""];
var cost = {
  "expensive": 1,
  "": 0
};
var utterancePrior = function() {
  var uttProbs = map(function(u) {return Math.exp(-cost[u]) }, utterances);
  return categorical(uttProbs, utterances);
};

var meaning = function(utterance, price, theta) {
  if (utterance == "expensive") {
    return price >= theta;
  } else {
    return true;
  }
};

var literalListener = cache(function(utterance, theta) {
  return Infer({method: "enumerate"}, function() {
    var price = statePrior();

    condition(meaning(utterance, price, theta))

    return price;
  })
})

~~~~

> **Exercise:** Check $$L_0$$'s predictions for various price cutoffs.

We get a full RSA model once we add $$S_1$$ and $$L_1$$; $$L_1$$ hears the gradable adjective and jointly infers the relevant item price and cutoff to count as expensive.

~~~~
///fold:
var marginalize = function(dist, key){
  return Infer({method: "enumerate"}, function(){
    return sample(dist)[key];
  })
}
///

var book = {
  "prices": [2, 6, 10, 14, 18, 22, 26, 30],
  "probabilities": [1, 2, 3, 4, 4, 3, 2, 1]
};

var statePrior = function() {
  return categorical(book.probabilities, book.prices);
};

var thetaPrior = function() {
    return uniformDraw(book.prices);
};

var alpha = 1; // rationality parameter

var utterances = ["expensive", ""];
var cost = {
  "expensive": 1,
  "": 0
};
var utterancePrior = function() {
  var uttProbs = map(function(u) {return Math.exp(-cost[u]) }, utterances);
  return categorical(uttProbs, utterances);
};

var meaning = function(utterance, price, theta) {
  if (utterance == "expensive") {
    return price >= theta;
  } else {
    return true;
  }
};

var literalListener = cache(function(utterance, theta) {
  return Infer({method: "enumerate"}, function() {
    var price = statePrior();

    condition(meaning(utterance, price, theta))

    return price;
  });
});

var speaker = cache(function(price, theta) {
  return Infer({method: "enumerate"}, function() {
    var utterance = utterancePrior();

    factor( alpha * literalListener(utterance, theta).score(price) );

    return utterance;
  });
});

var pragmaticListener = function(utterance) {
  return Infer({method: "enumerate"}, function() {
    var price = statePrior();
    var theta = thetaPrior();
    factor(speaker(price, theta).score(utterance));
    return { price: price, theta: theta };
  });
};

var expensiveBook = pragmaticListener("expensive", "book");
viz.auto(marginalize(expensiveBook, "price"));
viz.auto(marginalize(expensiveBook, "theta"));

~~~~

> **Exercises:** 

> 1. What happens when you make the `"expensive"` utterance more costly? Why?
> 2. Try altering the `statePrior` and see what happens to $$L_1$$'s inference.

In the actual model, rather than assuming prior knowledge (e.g., knowledge about domain-specific prices), Lassiter and Goodman measure it, then feed these measurements into the model as facts about the world. Doing so allows the model to make actual predictions about the behavior we expect to observe from listeners.

~~~~
///fold:
var marginalize = function(dist, key){
  return Infer({method: "enumerate"}, function(){
    return sample(dist)[key];
  })
}

// "price" refers to the midpoint of the bin that participants marked a slider for
// "probability" refers to the average of participants' responses, after normalizing responses for each person for each item
var coffee = {
  "prices": [2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58, 62, 66, 70, 74, 78, 82, 86, 90, 94, 98, 102, 106, 110, 114, 118, 122, 126, 130, 134, 138, 142, 146, 150, 154, 158, 162, 166, 170, 174, 178, 182, 186, 190, 194, 198, 202, 206, 210, 214, 218, 222, 226, 230, 234, 238, 242, 246, 250, 254, 258, 262, 266, 270],
  "probabilities": [0.00394425443541116, 0.00566290387321734, 0.00825676850536135, 0.0128170636252316, 0.016825062585583, 0.0252551834871954, 0.028468923991368, 0.0287662881619652, 0.0282906782393822, 0.0298574213919862, 0.0289804109562303, 0.0294934077950995, 0.0282267499972963, 0.027150810280172, 0.0263590035097067, 0.0281826763029633, 0.0279055635543465, 0.0278411275661919, 0.0278729305091271, 0.0260779123427457, 0.025504052957576, 0.0244726498427457, 0.0245886104865853, 0.0244622094919612, 0.0245026711395991, 0.0215246465554349, 0.018590665797836, 0.0178546907780941, 0.0171993717256383, 0.0162494284404094, 0.0160224797974072, 0.0153063570140879, 0.0146233597944038, 0.0137848051705444, 0.0143326737593802, 0.0134490255028661, 0.0135790032064503, 0.0138226943563312, 0.0131925119561275, 0.0126370445876965, 0.0106890591752964, 0.0106020628239155, 0.0101185949533398, 0.00911819843666944, 0.0106104999317876, 0.0109322919246626, 0.0107129834142186, 0.00837168284710854, 0.0080750721559225, 0.00804082264332751, 0.0067313619453682, 0.00627460791368519, 0.00589113687110393, 0.00540523790626922, 0.00552727879179031, 0.00550309276614945, 0.00523220007943591, 0.00511881990396121, 0.00512531318796172, 0.00518250532794681, 0.00363644079549071, 0.00358121922955672, 0.00340485508432679, 0.00300204070158435, 0.00285900767263514, 0.00307193123371249, 0.00265238954722026, 0.00259519926379722]
};
var headphones = {
  "prices": [3, 9, 15, 21, 27, 33, 39, 45, 51, 57, 63, 69, 75, 81, 87, 93, 99, 105, 111, 117, 123, 129, 135, 141, 147, 153, 159, 165, 171, 177, 183, 189, 195, 201, 207, 213, 219, 225, 231, 237, 243, 249, 255, 261, 267, 273, 279, 285, 291, 297, 303, 309, 315, 321, 327],
  "probabilities": [0.0100932350462178, 0.0170242011533158, 0.0239368832461044, 0.0287274552724317, 0.0335581038692007, 0.0340978261675896, 0.0343161232972866, 0.0360390185911639, 0.036657423324831, 0.0363628055611882, 0.0363696076759004, 0.0349562074307856, 0.034074002420704, 0.0319526478383908, 0.0310094760253021, 0.0310633591664631, 0.0306213012447122, 0.0267011137913525, 0.0258670033914898, 0.0258502350122376, 0.025023519418377, 0.023483875551852, 0.0220028560428636, 0.0214970268323533, 0.0208370797134518, 0.0179036695749784, 0.0171528323730662, 0.0146789727474624, 0.0151970966046565, 0.0144002087359724, 0.0133747582315602, 0.0123806405169515, 0.0120269613954518, 0.0114214380586013, 0.0119920388378585, 0.011383038780713, 0.0113361342839428, 0.0109751373856222, 0.00862772988748631, 0.00849834370871022, 0.00929436665963529, 0.00977137935316548, 0.00855300304060609, 0.00704341088484788, 0.00760242506144268, 0.0066676293070587, 0.00664151547908964, 0.00631842654192989, 0.00633866335810551, 0.00617281009506307, 0.00588389192288987, 0.00480853638779448, 0.00438645078845164, 0.00381072308793509, 0.00323537982338538]
};
var laptop = {
  "prices": [25, 75, 125, 175, 225, 275, 325, 375, 425, 475, 525, 575, 625, 675, 725, 775, 825, 875, 925, 975, 1025, 1075, 1125, 1175, 1225, 1275, 1325, 1375, 1425, 1475, 1525, 1575, 1625, 1675, 1725, 1775, 1825, 1875, 1925, 1975, 2025, 2075, 2125, 2175, 2225, 2275, 2325, 2375, 2425, 2475],
  "probabilities": [0.00143805356403561, 0.00271785465081783, 0.00606278580557322, 0.00969025393738191, 0.0148967448541453, 0.0198125393878057, 0.0241329166751748, 0.0295996079491818, 0.0330742235328304, 0.0361264464785417, 0.0401533300800443, 0.0409948060761354, 0.0413284234227614, 0.0403647740154393, 0.0401794950623575, 0.0389208352425967, 0.0381211282626673, 0.0380271843819898, 0.0337130710333348, 0.0320869893997556, 0.0303954589742173, 0.0290371975286599, 0.026737673556754, 0.0259385656770147, 0.0246868317621353, 0.0229019589247208, 0.0214921049215865, 0.0206506505418053, 0.0194727089077923, 0.0192606778139999, 0.016502461425033, 0.015779852769427, 0.014573698680051, 0.0141934767007475, 0.0128416097234241, 0.0124983882714321, 0.011580082968956, 0.0111057181921517, 0.0107390517842162, 0.0097877804629936, 0.00869628232285698, 0.00796157687645315, 0.00781439122831209, 0.0074127159955819, 0.00686298004874477, 0.00667898701991275, 0.00628316286073362, 0.00606433685126466, 0.00552579230999036, 0.00508236108646155]
};
var sweater = {
  "prices": [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5, 22.5, 25.5, 28.5, 31.5, 34.5, 37.5, 40.5, 43.5, 46.5, 49.5, 52.5, 55.5, 58.5, 61.5, 64.5, 67.5, 70.5, 73.5, 76.5, 79.5, 82.5, 85.5, 88.5, 91.5, 94.5, 97.5, 100.5, 103.5, 106.5, 109.5, 112.5, 115.5, 118.5, 121.5, 124.5, 127.5, 130.5, 133.5, 136.5, 139.5, 142.5, 145.5, 148.5, 151.5, 154.5, 157.5, 160.5, 163.5, 166.5, 169.5, 172.5, 175.5, 178.5, 181.5, 184.5, 187.5, 190.5, 193.5, 196.5, 199.5, 202.5, 205.5, 208.5, 211.5, 214.5, 217.5, 220.5, 223.5, 226.5, 229.5, 232.5, 235.5, 238.5],
  "probabilities": [0.00482838499944466, 0.00832934578733181, 0.0112952500492109, 0.0173774790108894, 0.0232006658974883, 0.0258422772579257, 0.0278986695293033, 0.0295289411585088, 0.0306833716679902, 0.0318318597751272, 0.0337834568516467, 0.0339921053872795, 0.0344439315108449, 0.033934432265521, 0.032462878943956, 0.031189466255733, 0.0308771801297135, 0.028870440122745, 0.0268081450723193, 0.0255858806436071, 0.0251329374896422, 0.0228478370318916, 0.0204321414255458, 0.0198885290723185, 0.018227461808914, 0.0175834655975716, 0.0162564776853142, 0.0157731201439098, 0.0152929182194243, 0.0150019091787104, 0.0149289099733278, 0.0141896849640091, 0.0139276040018639, 0.0134566451556076, 0.0121362548659773, 0.0108558348756676, 0.010613387912742, 0.010091436302254, 0.0098485635160309, 0.00934441306894098, 0.0085581357559821, 0.00679765980394746, 0.00693786098620408, 0.00696322949112243, 0.0070065216834756, 0.00642780104088309, 0.0064321559380608, 0.00656481702666307, 0.0062031359060876, 0.00687959185242292, 0.00510183619524203, 0.00519749642756681, 0.00498195289503402, 0.00463848039694862, 0.00446827225938831, 0.00434243838506282, 0.00454705086043589, 0.0045914966088052, 0.00451510979961212, 0.00443992782954235, 0.00329590488378491, 0.00349426470729333, 0.00329078051712042, 0.00323849270094039, 0.00302968185434419, 0.00294213735024183, 0.00335510797297302, 0.00328341117067163, 0.00329874147186505, 0.00306305447627786, 0.00262071902879654, 0.00274925007756808, 0.00246374710845232, 0.00262910011008071, 0.00248819809733968, 0.00211124548886266, 0.00204178897873852, 0.00208550762922333, 0.00204890779502054, 0.00228129283166782]
};
var watch = {
  "prices": [25, 75, 125, 175, 225, 275, 325, 375, 425, 475, 525, 575, 625, 675, 725, 775, 825, 875, 925, 975, 1025, 1075, 1125, 1175, 1225, 1275, 1325, 1375, 1425, 1475, 1525, 1575, 1625, 1675, 1725, 1775, 1825, 1875, 1925, 1975, 2025, 2075, 2125, 2175, 2225, 2275, 2325, 2375, 2425, 2475, 2525, 2575, 2625, 2675, 2725, 2775, 2825, 2875, 2925, 2975],
  "probabilities": [0.040844560268751, 0.0587099798246933, 0.0656194599591356, 0.0667642412698035, 0.0615953803048016, 0.0510809063784378, 0.0467203673419258, 0.0446735950187136, 0.040047421916613, 0.0350583957334483, 0.0297508215717606, 0.0256829651118227, 0.024135920250668, 0.0228891907259206, 0.021706684520276, 0.0186449440066946, 0.0187249266247728, 0.0179250744798993, 0.0173698811746238, 0.0165581725818319, 0.0160745066032247, 0.0127927305129066, 0.0113730680265067, 0.0109485307623827, 0.00923468422650943, 0.00899007751887508, 0.00880520147998275, 0.00838023585866885, 0.00841052411004918, 0.00828830635037619, 0.00834008093757411, 0.00750681534099784, 0.00724072133740109, 0.00717291664158004, 0.00682823777708754, 0.00646995193940331, 0.00697139732982518, 0.00711846547272734, 0.00698781312802354, 0.00732316558583701, 0.00594973158122097, 0.00557461443747403, 0.00541637601910211, 0.00518850469148531, 0.00572025848989677, 0.0051443557601358, 0.00510282169734075, 0.00493720252580643, 0.00560198932991028, 0.00519158715054485, 0.00473398797752786, 0.00540907722833213, 0.00494653421540979, 0.00495500420164643, 0.00494083025189895, 0.00481566268206312, 0.00442965937328148, 0.00441189688100535, 0.00415116538135834, 0.00361842012002631]
};
var data = {
  "coffee maker": coffee,
  "headphones": headphones,
  "laptop": laptop,
  "sweater": sweater,
  "watch": watch
};

var prior = function(item) {

  // midpoint of bin shown to participants
  var prices = data[item].prices;

  // average responses from participants, normalizing by item
  var probabilities = data[item].probabilities;

  return function() {
    return categorical(probabilities, prices);
  };
};

var theta_prior = function(item) {
  // midpoint of bin shown to participants
  var prices = data[item].prices;

  var bin_width = prices[1] - prices[0];

  var thetas = map(function(x) {return x - bin_width/2;}, prices);

  return function() {
    return uniformDraw(thetas);
  };
};
///

var alpha = 1; // rationality parameter

var utterances = ["expensive", ""];
var cost = {
  "expensive": 1,
  "": 0
};
var utterancePrior = function() {
  var uttProbs = map(function(u) {return Math.exp(-cost[u]) }, utterances);
  return categorical(uttProbs, utterances);
};

var meaning = function(utterance, price, theta) {
  if (utterance == "expensive") {
    return price >= theta;
  } else {
    return true;
  }
};

var literalListener = cache(function(utterance, theta, item) {
  return Infer({method: "enumerate"}, function() {
    var pricePrior = prior(item);
    var price = pricePrior()

    condition(meaning(utterance, price, theta))

    return price;
  });
});

var speaker = cache(function(price, theta, item) {

  return Infer({method: "enumerate"}, function() {

    var utterance = utterancePrior();
    
    factor( alpha * literalListener(utterance, theta, item).score(price) );

    return utterance;
  });
});

var pragmaticListener = function(utterance, item) {
  var pricePrior = prior(item);
  var thetaPrior = theta_prior(item);
  return Infer({method: "enumerate"}, 
  function() {
    var price = pricePrior();
    var theta = thetaPrior();
    factor( speaker(price, theta, item).score(utterance) );
    return { price: price, theta: theta };
  });
};

var expensiveWatch = pragmaticListener("expensive", "watch");
print("the listener's posterior over watch prices:")
viz.density(marginalize(expensiveWatch, "price"));
print("the listener's posterior over watch price thresholds:")
viz.density(marginalize(expensiveWatch, "theta"));

var expensiveSweater= pragmaticListener("expensive", "sweater");
print("the listener's posterior over sweater prices:")
viz.density(marginalize(expensiveSweater, "price"));
print("the listener's posterior over sweater price thresholds:")
viz.density(marginalize(expensiveSweater, "theta"));
~~~~

> **Exercises:** 

> 1. Visualize the various state priors.
> 2. Check $$L_1$$'s behavior for coffee makers and headphones and laptops.
> 3. Add an $$S_2$$ layer to the model and check its predictions.



#### Application 2: Inferring the comparison class

Implicit in the adjectives model from reft:lassitergoodman2013 is an awareness of the relevant comparison class: expensive for a watch vs. for a sweater. But what if we don't know what the relevant comparison class is? Take the adjective *tall*: if I tell you John is a basketball player and he is tall, you probably infer that the comparison class is the superordinate category of all people. Similarly, if I tell you that John is a gymnast and tall, you probably infer that he is short compared to all people. But if I tell you that John is a soccer player and tall/short, you might instead infer that John is tall/short just for the subordinate category of soccer players. In an attempt to formalize the reasoning that goes into this inference, [Tessler et al. (2017)](http://stanford.edu/~mtessler/papers/Tessler2017-cogsci-submitted.pdf) augment the basic adjectives model to include uncertainty about the relevant comparison class: superordinate (e.g., compared to all people) or subordinate (e.g., compared to gymnasts or soccer players or basketball players).

This reasoning depends crucially on our prior knowledge about the relevant categories. To model this knowledge, we'll need to intelligently simulate various categories: the heights of all people, the heights of gymnasts, the heights of soccer players, and the heights of basketball players.

~~~~
// helper function
var exp = function(x){return Math.exp(x)}

// for discretization
var binParam = 5; 

// information about the superordinate category prior
// e.g., the height distribution for all people
var superordinate = {mu: 0, sigma: 1};

// calculate the range in pre-defined steps;
// these values correspond to possible heights
var stateVals = _.range(superordinate.mu - 3 * superordinate.sigma,
          superordinate.mu + 3 * superordinate.sigma,
          superordinate.sigma/binParam)

// for each possible height, calculate its probability of occurrence
var stateProbs = cache(function(stateParams){
  return map(function(s){
    exp(Gaussian(stateParams).score(s))
  }, stateVals)
});

// generate a statePrior using the possible heights and their probabilities
var generateStatePrior = cache(function(stateParams) {
  return Infer({
    model: function(){ return categorical({vs: stateVals, ps: stateProbs(stateParams)}) }
  })
});

// information about the suberordinate category priors
var subParams = {
  low: {mu: -1, sigma: 0.5}, // gymnast heights
  middle: {mu: 0, sigma: 0.5}, // soccer player heights
  high: {mu: 1, sigma: 0.5} // basketball player heights
}

display("hypothetical height prior for all people")
viz.density(generateStatePrior(superordinate))
display("hypothetical height prior for gymnasts")
viz.density(generateStatePrior(subParams["low"]))
display("hypothetical height prior for soccer players")
viz.density(generateStatePrior(subParams["middle"]))
display("hypothetical height prior for basketball players")
viz.density(generateStatePrior(subParams["high"]))

~~~~

> **Exercise**: Try altering the `subParams` to generate different subordinate category priors.

We can add these state priors to the basic adjectives model, together with a lifted variable concerning the comparison class. Now, the pragmatic listener $$L_1$$ is told the relevant subordinate category (e.g., *John is a basketball player*) and hears the utterance with the scalar adjective (i.e., *John is tall*). On the basis of this information, $$L_1$$ jointly infers the state (i.e., John's height) and the relevant comparison class the speaker intended (e.g., *tall for all people* vs. *tall for a basketball player*).


~~~~
///fold:
// helper function
var exp = function(x){return Math.exp(x)}

// helper function
var marginalize = function(dist, key){
  return Infer({model: function(){sample(dist)[key]}})
}

// for discretization
var binParam = 5; 

// information about the superordinate category prior
// e.g., the height distribution for all people
var superordinate = {mu: 0, sigma: 1};

// calculate the range in pre-defined steps;
// these values correspond to possible heights
var stateVals = _.range(superordinate.mu - 3 * superordinate.sigma,
                        superordinate.mu + 3 * superordinate.sigma,
                        superordinate.sigma/binParam)

// for each possible height, calculate its probability of occurrence
var stateProbs = cache(function(stateParams){
  return map(function(s){
    exp(Gaussian(stateParams).score(s))
  }, stateVals)
});
///

// generate a statePrior using the possible heights and their probabilities
var generateStatePrior = cache(function(stateParams) {
  return Infer({
    model: function(){ return categorical({vs: stateVals, ps: stateProbs(stateParams)}) }
  })
});

// information about the superordinate category priors
var subParams = {
  low: {mu: -1, sigma: 0.5}, // gymnast heights
  middle: {mu: 0, sigma: 0.5}, // soccer player heights
  high: {mu: 1, sigma: 0.5} // basketball player heights
}


// generate the uniform threshold prior
var thresholdBins = cache(function(form, stateSupport){
  return map(function(x){
    return form == "positive" ? x - (1/(binParam*2)) : x + (1/(binParam*2));
  }, sort(stateSupport))
})
var thresholdPrior = cache(function(form, stateSupport){
  return Infer({
    model: function() { return uniformDraw(thresholdBins(form, stateSupport)) }
  });
});

// possible utterances can be either positive (tall) or negative (short)
// they can either mention the subordiate category (e.g., for a gymnast),
// the superordinate category (i.e., for a person), or no category
var utterances = {
  positive: ["positive_null", "positive_sub", "positive_super"],
  negative: ["negative_null", "negative_sub", "negative_super"]
}

// meaning function for utterances
var meaning = function(utterance, state, threshold) {
  utterance == "positive" ? state > threshold ? flip(0.9999) : flip(0.0001) :
  utterance == "negative" ? state < threshold ? flip(0.9999) : flip(0.0001) :
  true
}

// assume a uniform prior over comparison classes
var classPrior = Infer({
  model: function(){return uniformDraw(["sub", "super"])}
}); 

// set sepeaker optimality
var alpha = 5;

var literalListener = cache(
  function(u, threshold, comparisonClass, subordinate) {
    Infer({model: function(){
      var utterance =  u.split("_")[0], explicitCC =  u.split("_")[1]
      // if the comparison class is explicit in the utterance, use that
      // otherwise, use whatever the pragmaticListener model passes in
      var cc = explicitCC == "null" ? comparisonClass : explicitCC

      var state = sample(generateStatePrior(cc === "super" ? superordinate : subordinate));
      var m = meaning(utterance, state, threshold);
      condition(m);
      return state;
    }})
  }, 10000 // limit cache size
)

var speaker1 = cache(
  function(state, threshold, comparisonClass, form, subordinate) {
    Infer({model: function(){
      var utterance = uniformDraw(utterances[form]);
      var L0 = literalListener(utterance, threshold, comparisonClass, subordinate);
      factor( alpha * L0.score(state) );
      return utterance;
    }})
  }, 10000 // limit cache size
)

var pragmaticListener = cache(function(utterance, subordinate) {
  Infer({model: function(){
    var form = utterance.split("_")[0];
    var explicitCC = utterance.split("_")[1];

    var statePrior = generateStatePrior(
      subordinate
    );
    var state = sample(statePrior);
    var threshold = sample(thresholdPrior(form, statePrior.support()))
    // uncertainty about the comparison class (super vs. sub)
    var c = sample(classPrior)

    var S1 = speaker1(state, threshold, c, form, subordinate);
    observe(S1, utterance);
    return { comparisonClass: c, state: state }
  }})
}, 10000 // limit cache size
                             )

// the possible experiment conditions:
// you hear that someone is a member of a subordinate category
// then you are told that they are tall/short;
// the task is to figure out the implicit comparison class
var exptConditions = [
  {utt: "positive_null", form: "positive", sub: "high"}, 
  {utt: "negative_null", form: "negative", sub: "high"},
  {utt: "positive_null", form: "positive", sub: "middle"},
  {utt: "negative_null", form: "negative", sub: "middle"},
  {utt: "positive_null", form: "positive", sub: "low"},
  {utt: "negative_null", form: "negative", sub: "low"}
];

// generate structure predictions by mapping through the experiment conditions
var L1predictions = map(function(stim){
  var L1posterior = pragmaticListener(stim.utt, subParams[stim.sub])
  return {
    x: stim.form,
    y: exp(marginalize(L1posterior, "comparisonClass").score("super")),
    sub: stim.sub,
    model: "L1"
  }
}, exptConditions)

display("probability of superordinate comparison class (i.e., tall for all people)")
viz.bar(L1predictions, {groupBy: 'sub'})

~~~~



 While these "lifted-variable" RSA models do not model semantic composition directly, they do capture its effect on utterance interpretations, which allows us to more precisely identify and investigate the factors that ought to push interpretations around. In other words, these models open up semantics to the purview of computational and experimental pragmatics; and by formalizing and thereby isolating the contributions of pragmatics, we may more accurately access the semantics.
