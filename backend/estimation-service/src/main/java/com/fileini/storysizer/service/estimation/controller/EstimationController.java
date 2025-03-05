package com.fileini.storysizer.service.estimation.controller;

import com.fileini.storysizer.service.estimation.model.Estimation;
import com.fileini.storysizer.service.estimation.repository.EstimationRepository;
import com.fileini.storysizer.service.estimation.service.EstimationService;

import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/estimations")
public class EstimationController {

    private final EstimationRepository repository;
    private final EstimationService estimationService;


    public EstimationController(EstimationRepository repository, EstimationService estimationService) {
        this.repository = repository;
        this.estimationService = estimationService;
    }

    @GetMapping
    public List<Estimation> getAllEstimations() {
        return repository.findAll();
    }
    @GetMapping("/owner/{owner}")
    public List<Estimation> getEstimationByOwner(@PathVariable String owner, @RequestParam(required = false) Long id, @RequestParam(required = false) Long storyId) {
        if (id == null){
            if (storyId == null){
                return repository.findAll()
                .parallelStream()
                .filter(e -> e.getOwner().equals(owner))
                .toList();} else
            return repository.findAll()
            .parallelStream()
            .filter(e -> e.getOwner().equals(owner))
            .filter(e -> e.getStoryId().equals(storyId))
            .toList();
        } else if (storyId == null){
            return repository.findAll()
            .parallelStream()
            .filter(e -> e.getOwner().equals(owner))
            .filter(e -> e.getId().equals(id))
            .toList();
        } else 
        return repository.findAll()
        .parallelStream()
        .filter(e -> e.getOwner().equals(owner))
        .filter(e -> e.getStoryId().equals(storyId))
        .filter(e -> e.getId().equals(id))
        .toList();
    }


    @GetMapping("/{id}")
    public Estimation getEstimationById(@PathVariable Long id) {
        return repository.findById(id).orElseThrow();
    }

    @PostMapping
    public Estimation createEstimation(@RequestBody Estimation estimation) {
        //maximum values
        if (estimation.getComplexity()>5){estimation.setComplexity(5);}  if (estimation.getComplexity()<1){estimation.setComplexity(1);} 
        if (estimation.getInteraction()>5){estimation.setInteraction(5);}if (estimation.getInteraction()<1){estimation.setInteraction(1);}
        if (estimation.getDimensions()>5){estimation.setDimensions(5);}if (estimation.getDimensions()<1){estimation.setDimensions(1);}
        if (estimation.getReach()>5){estimation.setReach(5);}if (estimation.getReach()<1){estimation.setReach(1);}
        if (estimation.getRisk()>5){estimation.setRisk(5);}if (estimation.getRisk()<1){estimation.setRisk(1);}

        estimation.setSize(estimationService.calculateSize(estimation));

        return repository.save(estimation);
    }

    @PutMapping("/{id}")//ancora da implementare gestione maxsize
    public Estimation updateEstimation(@PathVariable Long id, @RequestBody Estimation estimation) {
        estimation.setId(id);

         //maximum values
         if (estimation.getComplexity()>5){estimation.setComplexity(5);}  if (estimation.getComplexity()<1){estimation.setComplexity(1);} 
         if (estimation.getInteraction()>5){estimation.setInteraction(5);}if (estimation.getInteraction()<1){estimation.setInteraction(1);}
         if (estimation.getDimensions()>5){estimation.setDimensions(5);}if (estimation.getDimensions()<1){estimation.setDimensions(1);}
         if (estimation.getReach()>5){estimation.setReach(5);}if (estimation.getReach()<1){estimation.setReach(1);}
         if (estimation.getRisk()>5){estimation.setRisk(5);}if (estimation.getRisk()<1){estimation.setRisk(1);}

         estimation.setSize(estimationService.calculateSize(estimation));

        return repository.save(estimation);
    }

    @DeleteMapping("/{id}")
    public void deleteEstimationsById(@PathVariable Long id) {
        repository.deleteById(id);
    }

    @DeleteMapping("/story/{storyId}")
    public void deleteEstimationsByStoryAndOwner(@PathVariable Long storyId, @RequestParam(required = true) String owner) {
        List<Estimation> list = repository.findAll()
        .parallelStream()
        .filter(e -> e.getStoryId().equals(storyId))
        .filter(e -> e.getOwner().equals(owner))
        .toList();
        list.forEach(e -> repository.deleteById(e.getId()));
    }
}
