/*
 *  Sinusoidal Partials Tracking Algorithm using the Heuristic of the
 *  Minimal Frequency and Magnitude Difference
 */
#include "mex.h"
#include <stdlib.h>             /* qsort() */
#include <math.h>               /* fabs() */

struct ConfParm
{
    int FreqCond;
    int numFrames;
    int numBins;
    double mindB;
    double maxdB;
    double binFreq;
};

struct Partial
{
    double period[2];
    double *mag;
    double *freq;
    double *magIdx;
    double *freqIdx;
    double size;
    double *type;
    // 0: Not Selected, Active
    // 1: Selected
    // -1: Deactive
    int TracksStatus;
};

struct Peak
{
    double mag;
    double freq;
    double magIdx;
    double freqIdx;
    double type;
    int NotSelectedPeak;
    int SelectedTracks;
    int PartialsIdx;
};

int dBToMagLvl(double dB, double mindB, double maxdB)
{
    double Tlvl = 64;
    
    int MagLevel = (int)((dB-mindB)/(maxdB-mindB)*Tlvl)+1;
    
    if(MagLevel<1)
        MagLevel = 1;
    else if (MagLevel>Tlvl)
        MagLevel = (int)Tlvl;
    
    return MagLevel;
}

struct Peak *initPeaks(int numPeaks,double *mXdB,int *idxs,int numBins,int curFrame,double binFreq,double *vploc,double mindB,double maxdB)
{
    struct Peak *Peaks = malloc(sizeof(struct Peak)*numPeaks);
    
    int i, idx;
    for (i=0; i <numPeaks; i++)
    {
        idx = (curFrame*numBins) + idxs[i];
        
        Peaks[i].mag = mXdB[idx];
        Peaks[i].freq = idxs[i]*binFreq;
        Peaks[i].magIdx = dBToMagLvl(Peaks[i].mag, mindB, maxdB);
        Peaks[i].freqIdx = idxs[i];
        Peaks[i].type = vploc[idx];
        Peaks[i].NotSelectedPeak = 1;
    }
    
    return Peaks;
}

/* Descending Sort */
int cmpfunc (const void *val1, const void *val2)
{
    struct Peak *p1, *p2;
    p1 = (struct Peak*)val1;
    p2 = (struct Peak*)val2;
    
    if ( p2->mag <  p1->mag )
        return -1;
    if ( p2->mag >  p1->mag  )
        return 1;
    
    return 0;
}

int *findPeak(double *array, int numBins, int *numPeaks )
{
    int *idxs;
    int i,j;
    *numPeaks = 0;
    for(i=0; i<numBins; i++)
    {
        if (array[i] == 1)
            *numPeaks += 1;
    }
    
    idxs = malloc(sizeof(int)*(*numPeaks));
    j = 0;
    for(i=0; i<numBins; i++)
    {
        if (array[i] == 1)
        {
            idxs[j] = i;
            j += 1;
            
        }
    }
    
    return idxs;
}

int isAnyActiveTracks(struct Partial *Partials, int NumOfTracks)
{
    int i;
    for(i=0; i<NumOfTracks; i++)
    {
        if(Partials[i].TracksStatus == 0)
            return 1;
    }
    
    return 0;
}

struct Peak *getPrevPeaks(struct Partial *Partials, int NumOfTracks, int *numPrevPeaks)
{
    struct Peak *prevPeaks;
    int i,j, LastIdx;
    *numPrevPeaks = 0;
    
    for(i=0; i<NumOfTracks; i++)
    {
        if(Partials[i].TracksStatus == 0)
            *numPrevPeaks += 1;
    }
    
    j = 0;
    prevPeaks = malloc(sizeof(struct Peak)*(*numPrevPeaks));
    for(i=0; i<NumOfTracks; i++)
    {
        if(Partials[i].TracksStatus == 0)
        {
            LastIdx = (int)(Partials[i].size) - 1;
            prevPeaks[j].mag = Partials[i].mag[LastIdx];
            prevPeaks[j].freq = Partials[i].freq[LastIdx];
            prevPeaks[j].SelectedTracks = 0;
            prevPeaks[j].PartialsIdx = i;
            
            j += 1;
        }
    }
    
    return prevPeaks;
}

struct Partial *PT_Algo_MQ_C(double *mXdB, double *ploc, double *vploc, struct ConfParm Parm, int *NumOfTracks)
{
    double FreqCond = Parm.FreqCond;
    int numFrames = Parm.numFrames;
    int numBins = Parm.numBins;
    double mindB = Parm.mindB;
    double maxdB = Parm.maxdB;
    double binFreq = Parm.binFreq;
    
    struct Partial *Partials;
    struct Peak *CurPeaks, *PrevPeaks;
    int *idxs;
    int numCurPeaks = 0;
    int i,j, k, LastIdx, NumNotAssignTrack, numPrevPeaks, tIdx, pIdx;
    double DiffFreq, minDiffFreq;
    *NumOfTracks = 0;
    for(i=0; i<numFrames; i++)
    {
        // Sort the peaks in descending order of magnitude
        numCurPeaks = 0;
        idxs = findPeak(ploc+(i*numBins), numBins, &numCurPeaks );
        if(idxs)
        {
            CurPeaks = initPeaks(numCurPeaks,mXdB,idxs,numBins,i,binFreq,vploc,mindB,maxdB);
            qsort(CurPeaks, numCurPeaks, sizeof(struct Peak), cmpfunc);
        }
        
        // Find a set of tracks which have a peak at frame i-1
        // Continue Active Tracks, if exist
        if(isAnyActiveTracks(Partials,*NumOfTracks))
        {
            // Active Tracks
            PrevPeaks = getPrevPeaks(Partials, *NumOfTracks, &numPrevPeaks);
            NumNotAssignTrack = numPrevPeaks;
            
            // For each sorted peak, we select a set of tracks which fulfill the heuristic criteria
            for(j=0; j<numCurPeaks; j++)
            {
                // If all active tracks are assigned, break!
                if(NumNotAssignTrack == 0)
                    break;
                
                // Find the most suitable tracks
                // First, find current peaks within Frequency and Magnitude Range
                minDiffFreq = 44100;
                
                tIdx = -1;
                for(k = 0; k<numPrevPeaks; k++)
                {
                    DiffFreq = fabs(CurPeaks[j].freq - PrevPeaks[k].freq);                    
                    if(DiffFreq<FreqCond & DiffFreq<minDiffFreq & PrevPeaks[k].SelectedTracks == 0)
                    {
                        minDiffFreq = DiffFreq;
                        tIdx = k;
                    }
                }
                if(tIdx == -1)
                    continue;
                
                // Must connect the current peak to the selected Partials
                // Within the intesect peaks, use the minimum frequency                
                pIdx = PrevPeaks[tIdx].PartialsIdx;
                LastIdx = (int)(Partials[pIdx].size);
                Partials[pIdx].size += 1;
                Partials[pIdx].mag = realloc(Partials[pIdx].mag, sizeof(double)*Partials[pIdx].size);
                Partials[pIdx].mag[LastIdx] = CurPeaks[j].mag;
                Partials[pIdx].freq = realloc(Partials[pIdx].freq, sizeof(double)*Partials[pIdx].size);
                Partials[pIdx].freq[LastIdx] = CurPeaks[j].freq;
                Partials[pIdx].magIdx = realloc(Partials[pIdx].magIdx, sizeof(double)*Partials[pIdx].size);
                Partials[pIdx].magIdx[LastIdx] = CurPeaks[j].magIdx;
                Partials[pIdx].freqIdx = realloc(Partials[pIdx].freqIdx, sizeof(double)*Partials[pIdx].size);
                Partials[pIdx].freqIdx[LastIdx] = CurPeaks[j].freqIdx;
                Partials[pIdx].type = realloc(Partials[pIdx].type, sizeof(double)*Partials[pIdx].size);
                Partials[pIdx].type[LastIdx] = CurPeaks[j].type;
                // Maintain the logistic for sinusoidal tracking
                CurPeaks[j].NotSelectedPeak = 0;
                PrevPeaks[tIdx].SelectedTracks = 1;
                Partials[pIdx].TracksStatus = 1;
                NumNotAssignTrack -= 1;
            }
            
            if(PrevPeaks)
                free(PrevPeaks);
        }
        
        // Deactive all non selected active tracks
        for(j=0; j<*NumOfTracks; j++)
        {
            if(Partials[j].TracksStatus == 0)
            {
                Partials[j].period[1] = i-1;
                Partials[j].TracksStatus = -1;
            }
        }
        
        // Music is ended, silent or at onset, deactivate all active track
        if(i == numFrames-1 || numCurPeaks == 0)
        {
            for(j=0; j<*NumOfTracks; j++)
            {
                if(Partials[j].TracksStatus == 1)
                {
                    if(i == numFrames-1)
                        Partials[j].period[1] = i;
                    else
                        Partials[j].period[1] = i-1;
                    
                    Partials[j].TracksStatus = -1;
                }
            }
        }

        //% Reinitialised
        if(idxs)
            free(idxs);
        for(j=0; j<*NumOfTracks; j++)
            if(Partials[j].TracksStatus == 1)
                Partials[j].TracksStatus = 0;

        // The remaining peaks prepare to form new tracks
        if(CurPeaks)
        {
            for(j=0; j<numCurPeaks; j++)
            {
                if(CurPeaks[j].NotSelectedPeak == 1)
                {
                    *NumOfTracks += 1;
                    if(*NumOfTracks == 1)
                        Partials = (struct Partial *)malloc(sizeof(struct Partial));
                    else
                        Partials = (struct Partial *)realloc( Partials, sizeof(struct Partial)*(*NumOfTracks) );
                    
                    if(Partials)
                    {
                        LastIdx = *NumOfTracks - 1;
                        Partials[LastIdx].period[0] = (double)i;
                        if(i == numFrames-1)
                            Partials[LastIdx].period[1] = (double)i;
                        
                        Partials[LastIdx].mag = malloc(sizeof(double));
                        Partials[LastIdx].mag[0] = CurPeaks[j].mag;
                        Partials[LastIdx].freq = malloc(sizeof(double));
                        Partials[LastIdx].freq[0] = CurPeaks[j].freq;
                        Partials[LastIdx].magIdx = malloc(sizeof(double));
                        Partials[LastIdx].magIdx[0] = CurPeaks[j].magIdx;
                        Partials[LastIdx].freqIdx = malloc(sizeof(double));
                        Partials[LastIdx].freqIdx[0] = CurPeaks[j].freqIdx;
                        Partials[LastIdx].size = 1;
                        Partials[LastIdx].type = malloc(sizeof(double));
                        Partials[LastIdx].type[0] = CurPeaks[j].type;
                        Partials[LastIdx].TracksStatus = 0;
                    }
                    else
                        mexErrMsgIdAndTxt("PT_Algo:MemError","Fail to allocate memory for new Track!");
                }
            }
            
            free(CurPeaks);
        }
    }
    
    return Partials;
}

/* The gateway function */
void mexFunction(int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[])
{
    int i, j, k;
    
    /* Output Variables */
    struct Partial *Partials;
    int NumOfTracks, NumOfPartials;
    int dimsC[2];
    int dimsS[2] = {1,1};
    const char *fieldNames[] = {"period","mag","freq","magIdx","freqIdx","size","type"};
    mxArray *elm;
    mxArray *fieldValue;
    
    /* Input Variables */
    double *mXdB = mxGetPr(prhs[0]);
    double *ploc = mxGetPr(prhs[1]);
    double *vploc = mxGetPr(prhs[2]);
    
    double fs, N, minPartialLength;
    struct ConfParm Parm;
    Parm.FreqCond = (int)mxGetScalar(mxGetField(prhs[3],0,"FreqCond"));
    Parm.numFrames = (int)mxGetScalar(mxGetField(prhs[3],0,"numFrames"));
    Parm.numBins = (int)mxGetScalar(mxGetField(prhs[3],0,"numBins"));
    Parm.mindB = mxGetScalar(mxGetField(prhs[3],0,"mindB"));
    Parm.maxdB = mxGetScalar(mxGetField(prhs[3],0,"maxdB"));
    minPartialLength = mxGetScalar(mxGetField(prhs[3],0,"minPartialLength"));
    
    fs = mxGetScalar(mxGetField(prhs[3],0,"fs"));
    N = mxGetScalar(mxGetField(prhs[3],0,"N"));
    Parm.binFreq = fs/N;
    
    Partials = PT_Algo_MQ_C(mXdB, ploc, vploc, Parm, &NumOfTracks);
    
    /* create a 1x1 struct matrix for output  */
    NumOfPartials = 0;
    for(i=0; i<NumOfTracks; i++)
    {
        if(Partials[i].size >= minPartialLength)
            NumOfPartials += 1;
    }
    dimsC[0] = NumOfPartials;
    dimsC[1] = 1;
    plhs[0] = mxCreateCellArray(2,dimsC);
    /* Obtain Partials and pass to matlab code  */
    j = 0;
    for(i=0; i<NumOfTracks; i++)
    {
        if(Partials[i].size >= minPartialLength)
        {
            elm = mxCreateStructArray(2, dimsS, 7, fieldNames);
            
            // period
            fieldValue = mxCreateDoubleMatrix(1,2,mxREAL);
            *mxGetPr(fieldValue) = Partials[i].period[0]+1;
            *(mxGetPr(fieldValue)+1) = Partials[i].period[1]+1;
            mxSetFieldByNumber(elm,0,0,fieldValue);
            // mag
            fieldValue = mxCreateDoubleMatrix(1,Partials[i].size,mxREAL);
            for(k=0;k<Partials[i].size;k++)
                *(mxGetPr(fieldValue)+k) = Partials[i].mag[k];
            mxSetFieldByNumber(elm,0,1,fieldValue);
            // freq
            fieldValue = mxCreateDoubleMatrix(1,Partials[i].size,mxREAL);
            for(k=0;k<Partials[i].size;k++)
                *(mxGetPr(fieldValue)+k) = Partials[i].freq[k];
            mxSetFieldByNumber(elm,0,2,fieldValue);
            // magIdx
            fieldValue = mxCreateDoubleMatrix(1,Partials[i].size,mxREAL);
            for(k=0;k<Partials[i].size;k++)
                *(mxGetPr(fieldValue)+k) = Partials[i].magIdx[k];
            mxSetFieldByNumber(elm,0,3,fieldValue);
            // freqIdx
            fieldValue = mxCreateDoubleMatrix(1,Partials[i].size,mxREAL);
            for(k=0;k<Partials[i].size;k++)
                *(mxGetPr(fieldValue)+k) = Partials[i].freqIdx[k]+1;
            mxSetFieldByNumber(elm,0,4,fieldValue);
            // size
            fieldValue = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(fieldValue) = Partials[i].size;
            mxSetFieldByNumber(elm,0,5,fieldValue);
            // type
            fieldValue = mxCreateDoubleMatrix(1,Partials[i].size,mxREAL);
            for(k=0;k<Partials[i].size;k++)
                *(mxGetPr(fieldValue)+k) = Partials[i].type[k];
            mxSetFieldByNumber(elm,0,6,fieldValue);
            // SetCell
            mxSetCell(plhs[0], j, elm);
            
            j = j + 1;
        }
        
        free(Partials[i].mag);
        free(Partials[i].magIdx);
        free(Partials[i].freq);
        free(Partials[i].freqIdx);
        free(Partials[i].type);
    }
    if(Partials)
        free(Partials);
}
