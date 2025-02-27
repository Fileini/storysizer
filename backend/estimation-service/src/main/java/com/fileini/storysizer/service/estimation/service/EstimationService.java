package com.fileini.storysizer.service.estimation.service;

import org.springframework.stereotype.Service;

import com.fileini.storysizer.service.estimation.model.Estimation;

@Service
public class EstimationService {

    public int calculateSize(Estimation estimation) {
        
        int est = estimation.getComplexity()+estimation.getDimensions()+estimation.getInteraction()+estimation.getReach()+estimation.getRisk();

        return est-3; // sostituisci questo valore con il calcolo reale
    }
}
