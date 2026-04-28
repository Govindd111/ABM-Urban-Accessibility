# ABM-Urban-Accessibility

Pedestrian Accessibility ABM
Simulating mobility-impaired pedestrian movement on urban footpaths — Indian street context, NetLogo 6.3
Background
Footpaths in Indian cities — particularly along commercial streets — are frequently blocked by hawker stalls, parked vehicles, and construction material. For most pedestrians this is an inconvenience. For wheelchair users it can mean being unable to complete a journey at all, especially where kerb ramps are absent or poorly placed.

Standard accessibility assessments treat this as a checklist problem: is a ramp present, yes or no. What they miss is the dynamic, movement-level picture — how far a wheelchair user has to detour to find a ramp, whether that detour is blocked by obstacles, how the system behaves when multiple agents are competing for the same narrow crossing point.

This project uses agent-based modelling (ABM) to look at that dynamic picture. The model is simple by design. It is a proof-of-concept, not a predictive tool.

What the Model Does
Three types of agents move eastward across a footpath corridor toward a single kerb crossing:

•	General pedestrians move at 1.2 m/s and treat kerbs as passable
•	Wheelchair users move at 0.5 m/s and require a ramp to cross any kerb patch
•	Elderly pedestrians move at 0.8 m/s, slow down in crowds, and experience a partial speed penalty at kerbs

The environment is a grid of patches. Most are walkable. A proportion are set as obstacles. One column of patches forms the kerb. A user-controlled number of ramp patches are distributed evenly along the kerb.

When a wheelchair user reaches the kerb and finds no ramp within their search radius, they record a blockage event and attempt to navigate around. The model tracks blockages, travel times, and the gap between wheelchair and general pedestrian journey times across the full run.

Results
Five runs were completed, varying only the number of ramps. All other parameters were fixed.

Ramp count	Total blockages	% wheelchair blocked	Avg wheelchair time	Accessibility gap
0 	88	100%	112 ticks	55.6 ticks
5 	0	0%	135 ticks	77.2 ticks
10	0	0%	156 ticks	93.7 ticks
15	0	0%	131 ticks	69.0 ticks
20	0	0%	156 ticks	90.6 ticks

The main finding is the sharp transition between zero ramps and five ramps. At zero ramps every wheelchair user in the simulation was blocked. At five ramps none were. This threshold was not written into any agent rule — it emerged from how agent paths interact with ramp distribution across the kerb column.

A second finding is that even after blockages disappear, wheelchair users still take considerably longer than general pedestrians to complete the same corridor. The gap ranges from 69 to 94 ticks depending on ramp configuration. Ramps remove the barrier but do not close the mobility gap, which appears to be driven by both the lower agent speed and the detour distance required to reach ramp locations.

How to Run
You will need NetLogo 6.3, available free at https://ccl.northwestern.edu/netlogo/

1.	Open model/pedestrian_accessibility.nlogo
2.	In the Interface tab, add the following sliders:

Variable	Min	Max	Default
obstacle-density	0	0.4	0.2
ramp-count	0	20	5
ramp-search-radius	1	15	8
num-general	1	30	15
num-wheelchair	1	20	8
num-elderly	1	20	8

3.	Add monitors for: total-blocked-events, mean-travel-time-wheelchair, mean-travel-time-general, accessibility-gap, pct-wheelchair-blocked
4.	Click Setup, then Go

To replicate the sensitivity analysis, run the model five times changing only the ramp-count slider between runs (0, 5, 10, 15, 20).

Limitations
This is a conceptual model and should be read as such.

The grid environment is a significant simplification. Real footpaths are irregular, have varying widths, surface textures, gradients, and overhead obstructions that this model does not represent. Agent speeds are taken from the pedestrian simulation literature rather than measured from Indian pedestrians. All agents of the same type behave identically — there is no variation within types for things like assistive device, familiarity with the route, or physical condition. Social dynamics such as other pedestrians yielding to wheelchair users are absent.

Running each configuration once also means the results are a single stochastic realisation. A more rigorous study would run each configuration many times and report averages. The broad pattern — a threshold between zero and five ramps — is robust enough to appear in a single run, but the exact gap values should not be over-interpreted.

Policy Context
The Rights of Persons with Disabilities Act (2016) requires accessible public infrastructure in India. The AMRUT scheme and Accessible India Campaign both include pedestrian infrastructure components. A simulation like this could, at larger scale and with calibrated parameters, help identify which streets would benefit most from targeted ramp investment — a cheaper approach than uniform provision across an entire network.

Repository Structure
model/
  pedestrian_accessibility.nlogo    NetLogo model file

docs/
  ABM_PhD_MiniProject_Enhanced.docx    Full write-up in IMRAD format
  Sensitivity_Analysis_Report.docx     Detailed results and discussion
  Simulation_Results.docx              Clean results document
  CV_and_SOP.docx                      CV entry and SOP paragraph
  Interview_Prep.docx                  Interview Q&A guide

screenshots/
  01 through 10                        Model views and monitor readings

results/
  sensitivity_notes.md                 Data table and findings summary

References
Wilensky, U. (1999). NetLogo. Center for Connected Learning and Computer-Based Modeling, Northwestern University.

Ministry of Law and Justice (2016). The Rights of Persons with Disabilities Act. Government of India.

Ministry of Housing and Urban Affairs (2018). AMRUT Mission Guidelines. Government of India.

Bonabeau, E. (2002). Agent-based modeling: Methods and techniques for simulating human systems. Proceedings of the National Academy of Sciences, 99(3), 7280-7287.

About
This project was developed as a pre-PhD mini-project to explore agent-based modelling methods in the context of inclusive urban mobility. The author has a background in GIS, environmental change, and spatial analysis.


