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

    @GetMapping("/{id}")
    public Estimation getEstimationById(@PathVariable Long id) {
        return repository.findById(id).orElseThrow();
    }

    @PostMapping
    public Estimation createEstimation(@RequestBody Estimation estimation) {
        return repository.save(estimation);
    }

    @PutMapping("/{id}")
    public Estimation updateEstimation(@PathVariable Long id, @RequestBody Estimation estimation) {
        estimation.setId(id);
        return repository.save(estimation);
    }

    @DeleteMapping("/{id}")
    public void deleteEstimation(@PathVariable Long id) {
        repository.deleteById(id);
    }
}
