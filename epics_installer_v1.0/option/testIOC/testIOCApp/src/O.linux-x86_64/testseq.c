/* C code for program testseq, generated by snc from ../testseq.stt */
#include <string.h>
#include <stddef.h>
#include <stdio.h>
#include <limits.h>

#include "seq_snc.h"

/* Variable declarations */
# line 3 "../testseq.stt"
static	int trig;
# line 4 "../testseq.stt"
static	int outp1;
# line 5 "../testseq.stt"
static	int outp2;
# line 13 "../testseq.stt"
static	int n;
# line 13 "../testseq.stt"
static	int i;


/* Function declarations */

#define seqg_var (*(struct seqg_vars *const *)seqg_env)

/* Program init func */
static void seqg_init(PROG_ID seqg_env)
{
}

/****** Code for state "init" in state set "scan" ******/

/* Event function for state "init" in state set "scan" */
static seqBool seqg_event_scan_0_init(SS_ID seqg_env, int *seqg_ptrn, int *seqg_pnst)
{
	if (TRUE)
	{
		*seqg_pnst = 1;
		*seqg_ptrn = 0;
		return TRUE;
	}
	return FALSE;
}

/* Action function for state "init" in state set "scan" */
static void seqg_action_scan_0_init(SS_ID seqg_env, int seqg_trn, int *seqg_pnst)
{
	switch(seqg_trn)
	{
	case 0:
		{
# line 21 "../testseq.stt"
			n = 0;
# line 22 "../testseq.stt"
			i = 0;
# line 23 "../testseq.stt"
			printf("Seq started...");
		}
		return;
	}
}

/****** Code for state "Scan_Start" in state set "scan" ******/

/* Event function for state "Scan_Start" in state set "scan" */
static seqBool seqg_event_scan_0_Scan_Start(SS_ID seqg_env, int *seqg_ptrn, int *seqg_pnst)
{
# line 29 "../testseq.stt"
	if (trig < 10)
	{
		*seqg_pnst = 1;
		*seqg_ptrn = 0;
		return TRUE;
	}
	return FALSE;
}

/* Action function for state "Scan_Start" in state set "scan" */
static void seqg_action_scan_0_Scan_Start(SS_ID seqg_env, int seqg_trn, int *seqg_pnst)
{
	switch(seqg_trn)
	{
	case 0:
		{
# line 31 "../testseq.stt"
			if (trig > 5)
			{
# line 33 "../testseq.stt"
				outp1 = 0;
# line 34 "../testseq.stt"
				outp2 = 1;
# line 35 "../testseq.stt"
				seq_pvPutTmo(seqg_env, 1/*outp1*/, DEFAULT, DEFAULT_TIMEOUT);
# line 36 "../testseq.stt"
				seq_pvPutTmo(seqg_env, 2/*outp2*/, DEFAULT, DEFAULT_TIMEOUT);
			}
# line 38 "../testseq.stt"
			if (trig <= 5)
			{
# line 40 "../testseq.stt"
				outp1 = 1;
# line 41 "../testseq.stt"
				outp2 = 0;
# line 42 "../testseq.stt"
				seq_pvPutTmo(seqg_env, 1/*outp1*/, DEFAULT, DEFAULT_TIMEOUT);
# line 43 "../testseq.stt"
				seq_pvPutTmo(seqg_env, 2/*outp2*/, DEFAULT, DEFAULT_TIMEOUT);
			}
		}
		return;
	}
}

#undef seqg_var

/************************ Tables ************************/

/* Channel table */
static seqChan seqg_chans[] = {
	/* chName, offset, varName, varType, count, eventNum, efId, monitored, queueSize, queueIndex */
	{"trigger", (size_t)&trig, "trig", P_INT, 1, 1, 0, 1, 0, 0},
	{"output1", (size_t)&outp1, "outp1", P_INT, 1, 2, 0, 0, 0, 0},
	{"output2", (size_t)&outp2, "outp2", P_INT, 1, 3, 0, 0, 0, 0},
};

/* Event masks for state set "scan" */
static const seqMask seqg_mask_scan_0_init[] = {
	0x00000000,
};
static const seqMask seqg_mask_scan_0_Scan_Start[] = {
	0x00000002,
};

/* State table for state set "scan" */
static seqState seqg_states_scan[] = {
	{
	/* state name */        "init",
	/* action function */   seqg_action_scan_0_init,
	/* event function */    seqg_event_scan_0_init,
	/* entry function */    0,
	/* exit function */     0,
	/* event mask array */  seqg_mask_scan_0_init,
	/* state options */     (0)
	},
	{
	/* state name */        "Scan_Start",
	/* action function */   seqg_action_scan_0_Scan_Start,
	/* event function */    seqg_event_scan_0_Scan_Start,
	/* entry function */    0,
	/* exit function */     0,
	/* event mask array */  seqg_mask_scan_0_Scan_Start,
	/* state options */     (0)
	},
};

/* State set table */
static seqSS seqg_statesets[] = {
	{
	/* state set name */    "scan",
	/* states */            seqg_states_scan,
	/* number of states */  2
	},
};

/* Program table (global) */
seqProgram testseq = {
	/* magic number */      2002006,
	/* program name */      "testseq",
	/* channels */          seqg_chans,
	/* num. channels */     3,
	/* state sets */        seqg_statesets,
	/* num. state sets */   1,
	/* user var size */     0,
	/* param */             "",
	/* num. event flags */  0,
	/* encoded options */   (0 | OPT_CONN | OPT_NEWEF),
	/* init func */         seqg_init,
	/* entry func */        0,
	/* exit func */         0,
	/* num. queues */       0
};

/* Register sequencer commands and program */
#include "epicsExport.h"
static void testseqRegistrar (void) {
    seqRegisterSequencerCommands();
    seqRegisterSequencerProgram (&testseq);
}
epicsExportRegistrar(testseqRegistrar);
