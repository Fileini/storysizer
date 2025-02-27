package com.fileini.storysizer.service.estimation.service;

import org.springframework.stereotype.Service;

import com.fileini.storysizer.service.estimation.model.Estimation;

@Service
public class EstimationService {

    public int calculateSize(Estimation estimation) {
        
        int[] fibonacci = {0,1,2,3,5,8};
        
        int mixingfactor = 
        estimation.getComplexity()>1 ? 1:0 +
        estimation.getDimensions()>1 ? 1:0 +
        estimation.getInteraction()>1 ? 1:0 +
        estimation.getReach()>1 ? 1:0 +
        estimation.getRisk()>1 ? 1:0 ;

        int est = estimation.getComplexity()+
        fibonacci[estimation.getDimensions()]+
        fibonacci[estimation.getInteraction()]+
        fibonacci[estimation.getReach()]+
        fibonacci[estimation.getRisk()];

        return est-3+fibonacci[mixingfactor]; // sostituisci questo valore con il calcolo reale
    }
}
