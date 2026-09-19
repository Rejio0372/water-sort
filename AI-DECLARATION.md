---
version: "0.1.2"
level: pair
processes:
  design: assist
  implementation: assist
  documentation: assist
  testing: pair
  review: none
  deployment: none
---

This format is based on [AI-DECLARATION.md](https://ai-declaration.md/en/0.1.2).

## Notes

- First to all , which llm was used , it is - Local LLM is used via [Ollama](https://ollama.com/) paired with [OpenCode](https://opencode.ai/). No online LLM was ever used in project development.

### What LLM/AI is used for

- Design - assist: LLM chooses colors for themes/skins , font size and font weight selection to fit all age groups preferences .
- Implementation - assist: LLM generates code suggestions which can be implemented to make logic better and also give new ideas to explore to do things differently which can shorten the level generation time and require less computing power so low end phones can have faster level generation and not crash due to hardware limitations .
- Testing - pair: LLM helps generate test cases based on human written code by stripping down the level generation file. Tests are executed by human , not LLM.
- Documentation - assist:  README was drafted with LLM and then edited by human for accuracy.
- Review - none:  No LLM used.
- Deployment - none:  No LLM used.

### Expectations for contributors

If you use AI to help write a contribution, **please just declare it first**. PR which can be done easily with simple logic will be rejected as LLM puts a lot of overthinking , which was never necessary for specific problem PR trying to solve. 

### My Thoughts

My thoughts on LLM is that i use LLM in area where i lack personally , I'm not a UI/UX designer : I can't bring the multiple best color pallate to app which removes customization barriers , I have maintained a flutter app for 4 years now , it had only two colors which are white and black , terrible design for years. Also I'm not native english speaker , A clear description on every button , a more familiar term being used on a button is what i want , I have tried doing it manually one time but it's not good. LLM helped me a lot in improving these two things personally. 