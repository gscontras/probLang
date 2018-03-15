# General stuff

## what changed

- added three appendix chapters
- changed layout/functionality to recognize and display appendix chapters
- updated libraries to the most recent KaTeX-versions
- added references in bib file
- added a template to insert figures that avoids type-overhead and ensures uniform layout
- all exercises in a visually set-off box


# Chapter 1

## what changed?

- restructured:
	- give example reference game in the beginning (so text is more self-contained)
	- introduce RSA components individually with a little more explanation for each
	- added a function to show the full conditional probability tables at once

## open issues

- is the reference to stochastic lambda-calculus adequate for webPPL (is it purely
  functional?) would we want to exclude non-functional probabilistic programming tools, like
  pyro (?), with this formulation?
- text says that literal listener uses salience priors, but that's *not* how the original
  science paper formalized it; and it gives *bad* empirical predictions (Appendix; Qing &
  Franke; also for data set of Degen & Franke); maybe reformulate more carefully here?

# Chapter 2

## what changed?

### first part

- first part: minor changes (typos etc); conservative merge of from upstream original and fork

### second part (extended Goodman Stuhlmueller model)

- first discuss the simpler model of Goodman & Stuhlmueller; then the extension to
  joint-inference
  - the way this is written should make it easy to move the last section to an appendix, but it
    we include a chapter on "probability expressions" (which I would like very much) this last
    part would be great to set the scene
- I left the original speaker choice function in the first part, but used the more complex one
  in the second
    - this way the chapter has a nice progression from simpler to complex
    - for clarity: the paper by Noah and Andreas describes the speaker choice behavior of (my)
      second part in both text and math; but the results shown in the figures clearly come from
      an implementation of the simpler model that is now in the first version in this chapter
      (just like before)
- changed explanations and formulas also in the old (simpler model) part, so as to make
  everything a bit more self-contained and, most importantly, less false 
- added a discussion question (last one in section 2) to pay attention to the conceptual
  spin-off of this "easier" speaker choice rule 

# Chapter 3

- conservative merge of changes from both sides

## what I changed

- typo in first speaker function hyperbole model
- added exercise at the end of hyperbole model
- line breaks in irony model (to fit code boxes)
- changed unnormalized priors for categorical distributions to integers
  in irony model (to prevent impression that these are mistakes)
- simplified 'literalInterpretation' in irony model
  ("utterance === state ? true : false" > "utterance === state")
- changed unnormalized priors for categorical distributions to integers
  in metaphor model (to prevent impression that these are mistakes)
- included comment about empirical measurement of feature priors
- simplified 'literalInterpretation' in metaphor model

# Chapter 4

- minor conservative merge
- I mostly only polished the code (white spaces etc.)

# Chapter 5

## what changed

- only conservative merge of minor fixes

# Chapter 6

- no changes in fork at all

# Chapter 7

- merged changes in both versions
- MH had changed prose and code
- GS made minor changes to code (e.g., more explicit naming of variables)

# Chapter 8 ::: NEW ::: lexical uncertainty

- new chapter from upstream fork (Greg) on lexical uncertainty
- no further changes

# Chapter 8/9 politeness

- both MH and Greg have made changes in parallel; Greg's were mostly typos and aesthetic fixes;
  Greg split introduction of literal listener and speaker;
  MH changed code etc.
- I kept all changes made in a maximally conservative merge;

# Appendix

- added new appendix chapter 01: introduction to Bayes etc.
- added new appendix chapter 03: more on costs and utterance priors
- renamed later appendix chapters
- added new draft chapter on quantifier production and approximate number sense
   - this could perhaps be intergrated in to the main text
   - the added value of this chapter is that it makes for a less contrived application of
     quantifier reasoning (bigger, fuzzier) and that it includes a non-language cognitive
     modeling component

# ToDo MF

- write general introduction chapter
- renumber chapters and fix references
- add appendix chapter on soft-max

# ToDo General (some possibilities)

- uniform use of pronouns for speakers and hearers: gender neutral "they"?
- math notation for product "\cdot", "\times" or nothing at all? spacing between factors?
- check uniform use of level of headings (number of "#"-s)
- make subsections in each chapter linkable? include small chapter-scope ToC at the beginning
  of each chapter?
- open links in new tabs so no code changes are lost (student suggestion)
  

