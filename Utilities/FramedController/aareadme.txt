This is a two step framed controller.

Only one frame rate.  The general flow is

Wait for all models to have reported in and to me marked "ready" in the database then send an 
InitCase message to all subscribers...wait for all models to response with an InitCaseComplete

Then start a loop as follows untill an EndCase message is receivd:
Send AdvanceTime message to ALL subscribers...wait for TimeFrame messages from all the models that have a "non-zero" rate.
Send StartFrame message to ALL subscribers...wait for EndFrame messages from all the models that have a "non-zero" rate.

If there is another monte-carlo case to run, then start again with the InitCase message, if not send out an EndRun message to
all subscribers and wait for EndRunComplete from all and start the shutdown logic

