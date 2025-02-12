package com.fileini.storysizer.service.estimation.repository;

import com.example.estimations.model.Estimation;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EstimationRepository extends JpaRepository<Estimation, Long> {}
