package com.fileini.storysizer.service.estimation.controller;

import com.fileini.storysizer.service.estimation.model.Estimation;
import com.fileini.storysizer.service.estimation.repository.EstimationRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/estimations")
public class EstimationController {

    private final EstimationRepository repository;

    public EstimationController(EstimationRepository repository) {
        this.repository = repository;
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
        estimation.setSize(22);
        return repository.save(estimation);
    }

    @PutMapping("/{id}")
    public Estimation updateEstimation(@PathVariable Long id, @RequestBody Estimation estimation) {
        estimation.setId(id);
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
